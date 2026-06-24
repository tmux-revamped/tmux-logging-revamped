#!/usr/bin/env bash
#
# logging.sh: command dispatcher for tmux-logging-revamped.
#
# Usage: logging.sh toggle | save | screenshot
#
# toggle starts or stops piping the active pane to a log file. save writes the
# full scrollback, screenshot writes the visible pane. Filenames are built from
# the session, window, pane, and a timestamp; no temp file is involved.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/logging/logging.sh"

# Host-probe seams. Tests override these.
_pane_pipe() { tmux display-message -p '#{pane_pipe}' 2>/dev/null; }
_pane_var() { tmux display-message -p "#{${1}}" 2>/dev/null; }
_message() { tmux display-message "${1}" 2>/dev/null; }
_make_dir() { mkdir -p "${1}" 2>/dev/null; }

logging_dir() {
  # shellcheck disable=SC2088 # ~ is a literal default expanded by logging_expand_path
  logging_expand_path "$(get_tmux_option "@logging_revamped_path" "~/.tmux/logs")"
}

# _log_file EXT -> a full path in the log directory, which is created on demand.
_log_file() {
  local dir
  dir="$(logging_dir)"
  _make_dir "${dir}"
  printf '%s/%s' "${dir}" "$(logging_filename "$(_pane_var session_name)" "$(_pane_var window_index)" "$(_pane_var pane_index)" "$(_now_stamp)" "${1}")"
}

_capture_flags() {
  [[ "$(get_tmux_option "@logging_revamped_color" "0")" == "1" ]] && printf '%s' "-e"
  return 0
}

logging_toggle() {
  if [[ "$(_pane_pipe)" == "1" ]]; then
    _pipe_pane
    _message "tmux logging stopped"
  else
    local file
    file="$(_log_file log)"
    _pipe_pane "cat >> '${file}'"
    _message "tmux logging to ${file}"
  fi
}

logging_save() {
  local file flags
  file="$(_log_file history)"
  flags="$(_capture_flags)"
  # shellcheck disable=SC2086
  _capture_pane ${flags} -S - -p | logging_trim_trailing > "${file}"
  _message "saved scrollback to ${file}"
}

logging_screenshot() {
  local file flags
  file="$(_log_file screen)"
  flags="$(_capture_flags)"
  # shellcheck disable=SC2086
  _capture_pane ${flags} -p | logging_trim_trailing > "${file}"
  _message "saved screen to ${file}"
}

main() {
  case "${1:-}" in
    toggle)     logging_toggle ;;
    save)       logging_save ;;
    screenshot) logging_screenshot ;;
    *)          return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
