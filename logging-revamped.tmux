#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_CMD="${CURRENT_DIR}/src/logging.sh"

get_key() {
  local v
  v=$(tmux show-option -gqv "${1}")
  echo "${v:-${2}}"
}

chmod +x "${LOG_CMD}" 2>/dev/null || true

bind_action() {
  local key
  key="$(get_key "${1}" "${2}")"
  [[ -z "${key}" || "${key}" == "off" ]] && return 0
  tmux bind-key "${key}" run-shell "$(printf '%q %s' "${LOG_CMD}" "${3}")"
}

bind_action "@logging_revamped_toggle_key" "" toggle
bind_action "@logging_revamped_save_key" "" save
bind_action "@logging_revamped_screenshot_key" "" screenshot
bind_action "@logging_revamped_label_key" "" label
bind_action "@logging_revamped_window_key" "" window
bind_action "@logging_revamped_clear_key" "" clear
bind_action "@logging_revamped_tail_key" "" tail
bind_action "@logging_revamped_search_key" "" search
bind_action "@logging_revamped_menu_key" "M-l" menu

shopt -u patsub_replacement 2>/dev/null || true

status_format() {
  local on off comma="," escaped="#,"
  on="$(get_key "@logging_revamped_status_on" "*")"
  off="$(tmux show-option -gqv "@logging_revamped_status_off")"
  printf '#{?pane_pipe,%s,%s}' "${on//"${comma}"/${escaped}}" "${off//"${comma}"/${escaped}}"
}

placeholders=(
  "\#{logging_status}"
)

commands=(
  "$(status_format)"
)

interpolate() {
  local value="${1}"
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value=${value//${placeholders[i]}/"${commands[i]}"}
  done
  echo "${value}"
}

update_option() {
  local option="${1}" current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

update_option "status-left"
update_option "status-right"
