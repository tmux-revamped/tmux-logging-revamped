#!/usr/bin/env bash
#
# logging-revamped.tmux: TPM entry point.
#
# Binds the capture controls and replaces #{logging_status} in the status line
# with a call to the dispatcher. All work is done on demand by the dispatcher, so
# nothing runs in the background.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_CMD="${CURRENT_DIR}/src/logging.sh"

get_key() {
  local v
  v=$(tmux show-option -gqv "${1}")
  echo "${v:-${2}}"
}

chmod +x "${LOG_CMD}" 2>/dev/null || true

tmux bind-key "$(get_key "@logging_revamped_toggle_key" "P")" run-shell "${LOG_CMD} toggle"
tmux bind-key "$(get_key "@logging_revamped_save_key" "M-p")" run-shell "${LOG_CMD} save"
tmux bind-key "$(get_key "@logging_revamped_screenshot_key" "M-P")" run-shell "${LOG_CMD} screenshot"
tmux bind-key "$(get_key "@logging_revamped_label_key" "M-n")" run-shell "${LOG_CMD} label"
tmux bind-key "$(get_key "@logging_revamped_window_key" "M-w")" run-shell "${LOG_CMD} window"
tmux bind-key "$(get_key "@logging_revamped_clear_key" "M-c")" run-shell "${LOG_CMD} clear"
tmux bind-key "$(get_key "@logging_revamped_tail_key" "M-t")" run-shell "${LOG_CMD} tail"
tmux bind-key "$(get_key "@logging_revamped_search_key" "M-f")" run-shell "${LOG_CMD} search"
tmux bind-key "$(get_key "@logging_revamped_menu_key" "M-m")" run-shell "${LOG_CMD} menu"

placeholders=(
  "\#{logging_status}"
)

commands=(
  "#(${LOG_CMD} status)"
)

interpolate() {
  local value="${1}"
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
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
