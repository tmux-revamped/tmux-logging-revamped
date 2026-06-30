#!/usr/bin/env bash
#
# logging.sh: pure helpers for tmux-logging-revamped.
#
# Filename building, path expansion, and the capture filters are pure. The pane
# captures sit behind seams the tests override, so no pane is touched and no file
# is written in tests.

[[ -n "${_LOGGING_REVAMPED_LOADED:-}" ]] && return 0
_LOGGING_REVAMPED_LOADED=1

# logging_sanitize TEXT -> TEXT with anything outside [A-Za-z0-9._-] turned into a
# dash, so a session or window name is always a safe filename component.
logging_sanitize() {
  printf '%s' "${1}" | tr -c 'A-Za-z0-9._-' '-'
}

# logging_filename SESSION WINDOW PANE STAMP EXT -> a safe log filename like
# tmux-main-1-0-20260622-1430.log.
logging_filename() {
  local s w p stamp ext
  s="$(logging_sanitize "${1}")"
  w="$(logging_sanitize "${2}")"
  p="$(logging_sanitize "${3}")"
  stamp="$(logging_sanitize "${4}")"
  ext="$(logging_sanitize "${5:-log}")"
  printf 'tmux-%s-%s-%s-%s.%s' "${s}" "${w}" "${p}" "${stamp}" "${ext}"
}

# logging_filename_labeled SESSION WINDOW PANE STAMP LABEL EXT -> a safe filename
# with the user note folded in after the timestamp, or the plain name when the
# label is empty.
logging_filename_labeled() {
  local label
  label="$(logging_sanitize "${5}")"
  if [[ -n "${label}" && "${label}" != "-" ]]; then
    logging_filename "${1}" "${2}" "${3}" "${4}-${label}" "${6:-log}"
  else
    logging_filename "${1}" "${2}" "${3}" "${4}" "${6:-log}"
  fi
}

# logging_rolling_filename SESSION -> a stable, timestamp-free name so a rolling
# session log appends to one growing file.
logging_rolling_filename() {
  printf 'tmux-%s-session.log' "$(logging_sanitize "${1}")"
}

# logging_pane_file_opt PANE_ID -> the option name that records which file a pane
# is being logged to, so the live tail knows where to look.
logging_pane_file_opt() {
  local id
  id="$(printf '%s' "${1}" | tr -c 'A-Za-z0-9' '_')"
  printf '@logging_revamped_file_%s' "${id}"
}

# logging_expand_path PATH -> PATH with a leading ~ expanded to $HOME.
# shellcheck disable=SC2088 # the ~ patterns are matched literally, not shell-expanded
logging_expand_path() {
  case "${1}" in
    "~") printf '%s' "${HOME}" ;;
    "~/"*) printf '%s/%s' "${HOME}" "${1#\~/}" ;;
    *) printf '%s' "${1}" ;;
  esac
}

# logging_trim_trailing -> copy stdin to stdout with trailing spaces and tabs
# removed from every line, so a saved capture has no ragged right edge. The
# bracket class is portable across BSD and GNU sed.
logging_trim_trailing() {
  sed 's/[[:space:]]*$//'
}

# logging_strip_prompts [REGEX] -> copy stdin to stdout dropping lines that look
# like shell prompts and echoed commands, for an output-only bug report. The
# default pattern matches a leading $, #, %, or > followed by a space.
logging_strip_prompts() {
  local re="${1}"
  [[ -z "${re}" ]] && re='^[[:space:]]*[#$%>] '
  grep -vE "${re}" || true
}

# logging_prune_excess MAX -> from a newline list on stdin sorted oldest first,
# print the entries beyond the newest MAX, i.e. the ones to delete.
logging_prune_excess() {
  local max="${1:-0}" lines total
  [[ "${max}" =~ ^[0-9]+$ ]] || max=0
  lines="$(cat)"
  [[ -z "${lines}" ]] && return 0
  total="$(printf '%s\n' "${lines}" | wc -l | tr -d ' ')"
  (( total > max )) || return 0
  printf '%s\n' "${lines}" | head -n "$(( total - max ))"
}

# logging_grep_file LINE -> the file part of a grep "file:line:text" record.
logging_grep_file() {
  printf '%s' "${1%%:*}"
}

# logging_grep_line LINE -> the line-number part of a grep "file:line:text" record.
logging_grep_line() {
  local rest="${1#*:}"
  printf '%s' "${rest%%:*}"
}

# logging_open_cmd PAGER FILE LINE -> the command string a popup runs to open a
# saved log at the matching line.
logging_open_cmd() {
  printf "%s +%s -- '%s'" "${1:-less}" "${3:-1}" "${2}"
}

# Host-probe seams. Tests override these.
_now_stamp() { date +%Y%m%d-%H%M%S 2>/dev/null; }
_pipe_pane() { tmux pipe-pane "$@"; }
_capture_pane() { tmux capture-pane "$@"; }

export -f logging_sanitize
export -f logging_filename
export -f logging_filename_labeled
export -f logging_rolling_filename
export -f logging_pane_file_opt
export -f logging_expand_path
export -f logging_trim_trailing
export -f logging_strip_prompts
export -f logging_prune_excess
export -f logging_grep_file
export -f logging_grep_line
export -f logging_open_cmd
export -f _now_stamp
export -f _pipe_pane
export -f _capture_pane
