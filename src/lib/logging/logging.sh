#!/usr/bin/env bash

[[ -n "${_LOGGING_REVAMPED_LOADED:-}" ]] && return 0
_LOGGING_REVAMPED_LOADED=1

logging_sanitize() {
  printf '%s' "${1}" | tr -c 'A-Za-z0-9._-' '-'
}

logging_filename() {
  local s w p stamp ext
  s="$(logging_sanitize "${1}")"
  w="$(logging_sanitize "${2}")"
  p="$(logging_sanitize "${3}")"
  stamp="$(logging_sanitize "${4}")"
  ext="$(logging_sanitize "${5:-log}")"
  printf 'tmux-%s-%s-%s-%s.%s' "${s}" "${w}" "${p}" "${stamp}" "${ext}"
}

logging_filename_labeled() {
  local label
  label="$(logging_sanitize "${5}")"
  if [[ -n "${label}" && "${label}" != "-" ]]; then
    logging_filename "${1}" "${2}" "${3}" "${4}-${label}" "${6:-log}"
  else
    logging_filename "${1}" "${2}" "${3}" "${4}" "${6:-log}"
  fi
}

logging_rolling_filename() {
  printf 'tmux-%s-session.log' "$(logging_sanitize "${1}")"
}

logging_pane_file_opt() {
  local id
  id="$(printf '%s' "${1}" | tr -c 'A-Za-z0-9' '_')"
  printf '@logging_revamped_file_%s' "${id}"
}

# shellcheck disable=SC2088 # the ~ patterns are matched literally, not shell-expanded
logging_expand_path() {
  case "${1}" in
    "~") printf '%s' "${HOME}" ;;
    "~/"*) printf '%s/%s' "${HOME}" "${1#\~/}" ;;
    *) printf '%s' "${1}" ;;
  esac
}

logging_trim_trailing() {
  sed 's/[[:space:]]*$//'
}

logging_strip_prompts() {
  local re="${1}"
  [[ -z "${re}" ]] && re='^[[:space:]]*[#$%>] '
  grep -vE "${re}" || true
}

logging_prune_excess() {
  local max="${1:-0}" lines total
  [[ "${max}" =~ ^[0-9]+$ ]] || max=0
  lines="$(cat)"
  [[ -z "${lines}" ]] && return 0
  total="$(printf '%s\n' "${lines}" | wc -l | tr -d ' ')"
  (( total > max )) || return 0
  printf '%s\n' "${lines}" | head -n "$(( total - max ))"
}

logging_grep_file() {
  printf '%s' "${1%%:*}"
}

logging_grep_line() {
  local rest="${1#*:}"
  printf '%s' "${rest%%:*}"
}

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
export -f _now_stamp
export -f _pipe_pane
export -f _capture_pane
