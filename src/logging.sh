#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_SELF="${BASH_SOURCE[0]}"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/logging/logging.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/logging/doctor.sh"

_pane_pipe() { tmux display-message -p '#{pane_pipe}' 2>/dev/null; }
_pane_var() { tmux display-message -p "#{${1}}" 2>/dev/null; }
_message() { tmux display-message "${1}" 2>/dev/null; }
_make_dir() { [[ -d "${1}" ]] || (umask 077 && mkdir -p "${1}" 2>/dev/null); }

_tmux() { tmux "$@"; }
_clear_history() { tmux clear-history 2>/dev/null; }
_piped_panes() { tmux list-panes -a -F '#{pane_pipe}|#{pane_id}' 2>/dev/null; }
_window_panes() { tmux list-panes -F '#{pane_id} #{session_name} #{window_index} #{pane_index}' 2>/dev/null; }
_fzf() { fzf --no-sort --reverse --height=100% 2>/dev/null; }
_gzip() { gzip "$@" 2>/dev/null; }
_grep() { grep -rnI -- "${1}" "${2}" 2>/dev/null; }
_find_old() { find "${1}" -type f -name 'tmux-*' ! -name '*.gz' -mtime +"${2}" 2>/dev/null; }
_remove() { rm -f -- "$@" 2>/dev/null; }
_list_logs() { (cd "${1}" 2>/dev/null && ls -1tr -- tmux-* 2>/dev/null); }
_clip() { tmux load-buffer -w - 2>/dev/null; }
# shellcheck disable=SC2086
_pager() { ${1} "+${2}" -- "${3}"; }

publish_escape() {
  local hash="#"
  printf '%s' "${1//"${hash}"/${hash}${hash}}"
}

_self_cmd() {
  shopt -u patsub_replacement 2>/dev/null || true
  local cmd hash="#" bs='\' dq='"' dl='$' ebs='\\' edq='\"' edl='\$'
  cmd="$(printf '%q %s' "${LOG_SELF}" "${1}")"
  cmd="${cmd//"${hash}"/${hash}${hash}}"
  cmd="${cmd//"${bs}"/${ebs}}"
  cmd="${cmd//"${dq}"/${edq}}"
  printf '%s' "${cmd//"${dl}"/${edl}}"
}

_prompt_template() {
  printf 'set-option -gq @logging_revamped_prompt "%%%%%%" ; run-shell "%s"' "$(_self_cmd "${1}")"
}

_take_prompt_reply() {
  get_tmux_option "@logging_revamped_prompt" ""
  unset_tmux_option "@logging_revamped_prompt"
}

logging_dir() {
  # shellcheck disable=SC2088 # ~ is a literal default expanded by logging_expand_path
  logging_expand_path "$(get_tmux_option "@logging_revamped_path" "~/.tmux/logs")"
}

_log_file() {
  local dir
  dir="$(logging_dir)"
  _make_dir "${dir}"
  printf '%s/%s' "${dir}" "$(logging_filename_labeled "$(_pane_var session_name)" "$(_pane_var window_index)" "$(_pane_var pane_index)" "$(_now_stamp)" "${2:-}" "${1}")"
}

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

_pipe_cmd() {
  local hash="#" cmd
  cmd="umask 077; exec cat >> $(printf '%q' "${1}")"
  printf '%s' "${cmd//"${hash}"/${hash}${hash}}"
}

_capture_flags() {
  [[ "$(get_tmux_option "@logging_revamped_color" "0")" == "1" ]] && printf '%s' "-e"
  return 0
}

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
    _pipe_pane "$(_pipe_cmd "${file}")"
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

logging_prompt_label() {
  _tmux command-prompt -p "log label:" "$(_prompt_template label_reply)"
}

logging_window() {
  local dir stamp id s w p file count=0
  dir="$(logging_dir)"
  _make_dir "${dir}"
  stamp="$(_now_stamp)"
  while IFS=' ' read -r id s w p; do
    [[ -z "${id}" ]] && continue
    file="${dir}/$(logging_filename "${s}" "${w}" "${p}" "${stamp}" log)"
    _pipe_pane -t "${id}" "$(_pipe_cmd "${file}")"
    set_tmux_option "$(logging_pane_file_opt "${id}")" "${file}"
    count=$(( count + 1 ))
  done <<< "$(_window_panes)"
  _message "logging ${count} panes in this window"
}

logging_clear() {
  _clear_history
  _message "cleared pane history"
}

logging_tail() {
  local file
  file="$(get_tmux_option "$(logging_pane_file_opt "$(_pane_var pane_id)")" "")"
  if [[ -z "${file}" ]]; then
    _message "this pane is not being logged"
    return 0
  fi
  _tmux display-popup -E "tail -f -- '${file}'"
}

logging_search() {
  local pattern="${1:-}"
  if [[ -z "${pattern}" ]]; then
    _tmux command-prompt -p "search logs:" "$(_prompt_template search_reply)"
    return 0
  fi
  if [[ -z "$(_grep "${pattern}" "$(logging_dir)")" ]]; then
    _message "no matches for $(publish_escape "${pattern}")"
    return 0
  fi
  set_tmux_option "@logging_revamped_search_pattern" "${pattern}"
  _tmux display-popup -E "$(printf '%q pick' "${LOG_SELF}")"
}

logging_search_reply() {
  local pattern
  pattern="$(_take_prompt_reply)"
  [[ -z "${pattern}" ]] && return 0
  logging_search "${pattern}"
}

logging_pick() {
  local pattern results choice
  pattern="$(get_tmux_option "@logging_revamped_search_pattern" "")"
  [[ -z "${pattern}" ]] && return 0
  results="$(_grep "${pattern}" "$(logging_dir)")"
  [[ -z "${results}" ]] && return 0
  choice="$(printf '%s\n' "${results}" | _fzf)"
  [[ -z "${choice}" ]] && return 0
  _pager "$(get_tmux_option "@logging_revamped_pager" "less")" "$(logging_grep_line "${choice}")" "$(logging_grep_file "${choice}")"
}

logging_copy() {
  local dir last
  dir="$(logging_dir)"
  last="$(_list_logs "${dir}" | grep -v '\.gz$' | tail -n 1)"
  if [[ -z "${last}" ]]; then
    _message "no logs to copy"
    return 0
  fi
  _clip < "${dir}/${last}"
  _message "copied ${last} to clipboard"
}

_active_logs() {
  local pipe id
  while IFS='|' read -r pipe id; do
    [[ "${pipe}" == "1" && -n "${id}" ]] || continue
    get_tmux_option "$(logging_pane_file_opt "${id}")" ""
  done <<< "$(_piped_panes)"
}

logging_compress() {
  local dir f active count=0
  dir="$(logging_dir)"
  active="$(_active_logs)"
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    case "${f}" in *.gz) continue ;; esac
    printf '%s\n' "${active}" | grep -Fqx -- "${dir}/${f}" && continue
    _gzip -- "${dir}/${f}"
    count=$(( count + 1 ))
  done <<< "$(_list_logs "${dir}")"
  _message "compressed ${count} logs"
}

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

logging_menu() {
  _tmux display-menu -T "Logging" \
    "Toggle live log" "" "run-shell \"$(_self_cmd toggle)\"" \
    "Save scrollback" "" "run-shell \"$(_self_cmd save)\"" \
    "Save screen" "" "run-shell \"$(_self_cmd screenshot)\"" \
    "Labelled save" "" "run-shell \"$(_self_cmd label)\"" \
    "Log whole window" "" "run-shell \"$(_self_cmd window)\"" \
    "Clear history" "" "run-shell \"$(_self_cmd clear)\"" \
    "Live tail" "" "run-shell \"$(_self_cmd tail)\"" \
    "Search logs" "" "run-shell \"$(_self_cmd search)\"" \
    "Copy last log" "" "run-shell \"$(_self_cmd copy)\"" \
    "Compress logs" "" "run-shell \"$(_self_cmd compress)\"" \
    "Prune old logs" "" "run-shell \"$(_self_cmd prune)\"" \
    "Doctor" "" "display-popup -E \"$(_self_cmd 'doctor; read -r')\""
}

main() {
  umask 077
  case "${1:-}" in
    toggle)     logging_toggle ;;
    save)       logging_save "${2:-}" ;;
    screenshot) logging_screenshot "${2:-}" ;;
    label)      logging_prompt_label ;;
    label_reply) logging_save "$(_take_prompt_reply)" ;;
    window)     logging_window ;;
    clear)      logging_clear ;;
    tail)       logging_tail ;;
    search)     logging_search "${2:-}" ;;
    pick)       logging_pick ;;
    search_reply) logging_search_reply ;;
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
