#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'pane:\n'
  tmux capture-pane -p -t %0 || :
  printf 'logs:\n'
  ls -la "${LOGS}" 2>/dev/null || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

shows() {
  local now
  now=$(tmux display-message -p -t "$1" "$2" 2>/dev/null)
  [[ "${now}" == "$3" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"$1"* ]]
}

host_counts() {
  local screen count
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  count=$(grep -c -- "$1" <<<"${screen}")
  [[ "${count}" == "$2" ]]
}

host_lacks() {
  ! host_shows "$1"
}

pane_shows() {
  local screen
  screen=$(tmux capture-pane -p -t "$1")
  [[ "${screen}" == *"$2"* ]]
}

one_log() {
  local found
  found=$(cd "${LOGS}" 2>/dev/null && set -- *."$1" && [[ -f "$1" ]] && printf '%s\n' "$@")
  [[ -n "${found}" ]] || return 1
  FOUND="${LOGS}/${found%%$'\n'*}"
}

log_holds() {
  one_log "$1" || return 1
  grep -qF -- "$2" "${FOUND}"
}

file_holds() {
  [[ -f "$1" ]] || return 1
  grep -qF -- "$2" "$1"
}

everything() {
  tmux show-options -g
  tmux list-keys
}

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  LOGS="${BATS_TEST_TMPDIR}/logs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  printf '#!/bin/sh\ncat >"%s"\nhead -n 1 "%s"\n' "${BATS_TEST_TMPDIR}/offered" "${BATS_TEST_TMPDIR}/offered" >"${STUBS}/fzf"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >"%s"\n' "${BATS_TEST_TMPDIR}/viewed" >"${STUBS}/viewer"
  chmod +x "${STUBS}/fzf" "${STUBS}/viewer"
  PATH="${STUBS}:${PATH}"
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  tmux set-option -g @logging_revamped_path "${LOGS}"
  tmux set-option -g @logging_revamped_pager viewer
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 100 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/logging-revamped.tmux'"
}

setting() {
  set_option "@logging_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

typed() {
  command tmux -S "${HOST}" send-keys -t host -l "$1"
}

says() {
  tmux send-keys -t %0 "echo $1" Enter
  wait_for pane_shows %0 $'\n'"$1"
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}
