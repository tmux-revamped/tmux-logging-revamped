#!/usr/bin/env bash
#
# logging-revamped.tmux: TPM entry point.
#
# Binds the capture controls. All work is done on demand by the dispatcher, so
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
