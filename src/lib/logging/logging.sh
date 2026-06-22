#!/usr/bin/env bash
#
# logging.sh: pure helpers for tmux-logging-revamped.
#
# Filename building and path expansion are pure. The pane captures sit behind
# seams the tests override, so no pane is touched and no file is written in tests.

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

# logging_expand_path PATH -> PATH with a leading ~ expanded to $HOME.
# shellcheck disable=SC2088 # the ~ patterns are matched literally, not shell-expanded
logging_expand_path() {
  case "${1}" in
    "~") printf '%s' "${HOME}" ;;
    "~/"*) printf '%s/%s' "${HOME}" "${1#\~/}" ;;
    *) printf '%s' "${1}" ;;
  esac
}

# Host-probe seams. Tests override these.
_now_stamp() { date +%Y%m%d-%H%M%S 2>/dev/null; }
_pipe_pane() { tmux pipe-pane "$@"; }
_capture_pane() { tmux capture-pane "$@"; }

export -f logging_sanitize
export -f logging_filename
export -f logging_expand_path
export -f _now_stamp
export -f _pipe_pane
export -f _capture_pane
