#!/usr/bin/env bash
#
# logging.sh: command dispatcher for tmux-logging-revamped.
#
# Usage: logging.sh toggle | save [label] | screenshot [label] | label | window |
#                   clear | tail | search [pattern] | copy | compress | prune |
#                   status | menu | doctor
#
# toggle starts or stops piping the active pane to a log file. save writes the
# full scrollback, screenshot the visible pane. Filenames are built from the
# session, window, pane, and a timestamp. All pane captures, popups, the picker,
# and the clipboard sit behind seams so the suite touches no real pane, launches
# no popup or fzf, and writes only inside a temp directory.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_SELF="${BASH_SOURCE[0]}"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/logging/logging.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/logging/doctor.sh"

# Host-probe seams. Tests override these.
_pane_pipe() { tmux display-message -p '#{pane_pipe}' 2>/dev/null; }
_pane_var() { tmux display-message -p "#{${1}}" 2>/dev/null; }
_message() { tmux display-message "${1}" 2>/dev/null; }
_make_dir() { mkdir -p "${1}" 2>/dev/null; }

# Interactive and external seams. Tests override these so no real popup, menu,
# fzf, gzip, find, rm, or clipboard call is ever made.
_tmux() { tmux "$@"; }
_clear_history() { tmux clear-history 2>/dev/null; }
_window_panes() { tmux list-panes -F '#{pane_id} #{session_name} #{window_index} #{pane_index}' 2>/dev/null; }
_fzf() { fzf --no-sort --reverse --height=100% 2>/dev/null; }
_gzip() { gzip "$@" 2>/dev/null; }
_grep() { grep -rnI -- "${1}" "${2}" 2>/dev/null; }
_find_old() { find "${1}" -type f -name 'tmux-*' ! -name '*.gz' -mtime +"${2}" 2>/dev/null; }
_remove() { rm -f -- "$@" 2>/dev/null; }
_list_logs() { ls -1 "${1}" 2>/dev/null; }
_clip() { tmux load-buffer -w - 2>/dev/null; }

logging_dir() {
  # shellcheck disable=SC2088 # ~ is a literal default expanded by logging_expand_path
  logging_expand_path "$(get_tmux_option "@logging_revamped_path" "~/.tmux/logs")"
}

# _log_file EXT [LABEL] -> a full path in the log directory, created on demand.
_log_file() {
  local dir
  dir="$(logging_dir)"
  _make_dir "${dir}"
  printf '%s/%s' "${dir}" "$(logging_filename_labeled "$(_pane_var session_name)" "$(_pane_var window_index)" "$(_pane_var pane_index)" "$(_now_stamp)" "${2:-}" "${1}")"
}

# _start_file -> the path live logging appends to: a stable rolling file when
# @logging_revamped_rolling is 1, otherwise a fresh timestamped file.
_start_file() {
  if [[ "$(get_tmux_option "@logging_revamped_rolling" "0")" == "1" ]]; then
    local dir
    dir="$(logging_dir)"
    _make_dir "${dir}"
    printf '%s/%s' "${dir}" "$(logging_rolling_filename "$(_pane_var session_name)")"
  else
    _log_file log
  fi
}

_capture_flags() {
  [[ "$(get_tmux_option "@logging_revamped_color" "0")" == "1" ]] && printf '%s' "-e"
  return 0
}

# _output_filter -> the capture filter pipeline: trailing whitespace is always
# trimmed; prompt and command-echo lines are dropped when output-only is on.
_output_filter() {
  if [[ "$(get_tmux_option "@logging_revamped_output_only" "0")" == "1" ]]; then
    logging_strip_prompts "$(get_tmux_option "@logging_revamped_prompt_pattern" "")" | logging_trim_trailing
  else
    logging_trim_trailing
  fi
}

logging_toggle() {
  if [[ "$(_pane_pipe)" == "1" ]]; then
    _pipe_pane
    unset_tmux_option "$(logging_pane_file_opt "$(_pane_var pane_id)")"
    _message "tmux logging stopped"
  else
    local file
    file="$(_start_file)"
    _pipe_pane "cat >> '${file}'"
    set_tmux_option "$(logging_pane_file_opt "$(_pane_var pane_id)")" "${file}"
    _message "tmux logging to ${file}"
  fi
}

logging_save() {
  local file flags
  file="$(_log_file history "${1:-}")"
  flags="$(_capture_flags)"
  # shellcheck disable=SC2086
  _capture_pane ${flags} -S - -p | _output_filter > "${file}"
  _message "saved scrollback to ${file}"
}

logging_screenshot() {
  local file flags
  file="$(_log_file screen "${1:-}")"
  flags="$(_capture_flags)"
  # shellcheck disable=SC2086
  _capture_pane ${flags} -p | _output_filter > "${file}"
  _message "saved screen to ${file}"
}

# logging_prompt_label -> ask for a note, then save the scrollback with the note
# folded into the filename.
logging_prompt_label() {
  _tmux command-prompt -p "log label:" "run-shell \"${LOG_SELF} save '%%'\""
}

# logging_window -> start logging every pane in the current window at once.
logging_window() {
  local dir stamp id s w p file count=0
  dir="$(logging_dir)"
  _make_dir "${dir}"
  stamp="$(_now_stamp)"
  while IFS=' ' read -r id s w p; do
    [[ -z "${id}" ]] && continue
    file="${dir}/$(logging_filename "${s}" "${w}" "${p}" "${stamp}" log)"
    _pipe_pane -t "${id}" "cat >> '${file}'"
    count=$(( count + 1 ))
  done <<< "$(_window_panes)"
  _message "logging ${count} panes in this window"
}

logging_clear() {
  _clear_history
  _message "cleared pane history"
}

# logging_tail -> open a popup that follows the file this pane is logging to.
logging_tail() {
  local file
  file="$(get_tmux_option "$(logging_pane_file_opt "$(_pane_var pane_id)")" "")"
  if [[ -z "${file}" ]]; then
    _message "this pane is not being logged"
    return 0
  fi
  _tmux display-popup -E "tail -f -- '${file}'"
}

# logging_search [PATTERN] -> with no pattern, prompt for one; with a pattern,
# grep the saved logs, pick a match in fzf, and open it at the matching line.
logging_search() {
  local pattern="${1:-}"
  if [[ -z "${pattern}" ]]; then
    _tmux command-prompt -p "search logs:" "run-shell \"${LOG_SELF} search '%%'\""
    return 0
  fi
  local dir results choice file line
  dir="$(logging_dir)"
  results="$(_grep "${pattern}" "${dir}")"
  if [[ -z "${results}" ]]; then
    _message "no matches for ${pattern}"
    return 0
  fi
  choice="$(printf '%s\n' "${results}" | _fzf)"
  [[ -z "${choice}" ]] && return 0
  file="$(logging_grep_file "${choice}")"
  line="$(logging_grep_line "${choice}")"
  _tmux display-popup -E "$(logging_open_cmd "$(get_tmux_option "@logging_revamped_pager" "less")" "${file}" "${line}")"
}

# logging_copy -> send the most recent saved log to the terminal clipboard.
logging_copy() {
  local dir last
  dir="$(logging_dir)"
  last="$(_list_logs "${dir}" | tail -n 1)"
  if [[ -z "${last}" ]]; then
    _message "no logs to copy"
    return 0
  fi
  _clip < "${dir}/${last}"
  _message "copied ${last} to clipboard"
}

# logging_compress -> gzip every uncompressed log in the directory.
logging_compress() {
  local dir f count=0
  dir="$(logging_dir)"
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    case "${f}" in *.gz) continue ;; esac
    _gzip -- "${dir}/${f}"
    count=$(( count + 1 ))
  done <<< "$(_list_logs "${dir}")"
  _message "compressed ${count} logs"
}

# logging_prune -> delete logs older than @logging_revamped_retain_days and trim
# the directory to @logging_revamped_retain_max newest files.
logging_prune() {
  local dir days max removed=0 f victims
  dir="$(logging_dir)"
  days="$(get_tmux_option "@logging_revamped_retain_days" "0")"
  max="$(get_tmux_option "@logging_revamped_retain_max" "0")"
  if [[ "${days}" =~ ^[0-9]+$ ]] && (( days > 0 )); then
    while IFS= read -r f; do
      [[ -z "${f}" ]] && continue
      _remove "${f}"
      removed=$(( removed + 1 ))
    done <<< "$(_find_old "${dir}" "${days}")"
  fi
  if [[ "${max}" =~ ^[0-9]+$ ]] && (( max > 0 )); then
    victims="$(_list_logs "${dir}" | logging_prune_excess "${max}")"
    while IFS= read -r f; do
      [[ -z "${f}" ]] && continue
      _remove "${dir}/${f}"
      removed=$(( removed + 1 ))
    done <<< "${victims}"
  fi
  _message "pruned ${removed} logs"
}

# logging_status -> a glyph in the status line when the active pane is logged,
# also exported as @logging_status for a theme to read.
logging_status() {
  local glyph
  if [[ "$(_pane_pipe)" == "1" ]]; then
    glyph="$(get_tmux_option "@logging_revamped_status_on" "*")"
  else
    glyph="$(get_tmux_option "@logging_revamped_status_off" "")"
  fi
  set_tmux_option "@logging_status" "${glyph}"
  printf '%s' "${glyph}"
}

# logging_menu -> a discoverable control menu of every action, via the _tmux seam.
logging_menu() {
  _tmux display-menu -T "Logging" \
    "Toggle live log" "" "run-shell \"${LOG_SELF} toggle\"" \
    "Save scrollback" "" "run-shell \"${LOG_SELF} save\"" \
    "Save screen" "" "run-shell \"${LOG_SELF} screenshot\"" \
    "Labelled save" "" "run-shell \"${LOG_SELF} label\"" \
    "Log whole window" "" "run-shell \"${LOG_SELF} window\"" \
    "Clear history" "" "run-shell \"${LOG_SELF} clear\"" \
    "Live tail" "" "run-shell \"${LOG_SELF} tail\"" \
    "Search logs" "" "run-shell \"${LOG_SELF} search\"" \
    "Copy last log" "" "run-shell \"${LOG_SELF} copy\"" \
    "Compress logs" "" "run-shell \"${LOG_SELF} compress\"" \
    "Prune old logs" "" "run-shell \"${LOG_SELF} prune\"" \
    "Doctor" "" "display-popup -E \"${LOG_SELF} doctor; read -r\""
}

main() {
  case "${1:-}" in
    toggle)     logging_toggle ;;
    save)       logging_save "${2:-}" ;;
    screenshot) logging_screenshot "${2:-}" ;;
    label)      logging_prompt_label ;;
    window)     logging_window ;;
    clear)      logging_clear ;;
    tail)       logging_tail ;;
    search)     logging_search "${2:-}" ;;
    copy)       logging_copy ;;
    compress)   logging_compress ;;
    prune)      logging_prune ;;
    status)     logging_status ;;
    menu)       logging_menu ;;
    doctor)     logging_doctor ;;
    *)          return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
