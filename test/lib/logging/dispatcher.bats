#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _LOGGING_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/logging.sh"
  _pane_var() { case "${1}" in session_name) echo main ;; window_index) echo 1 ;; pane_index) echo 0 ;; esac; }
  _now_stamp() { echo "STAMP"; }
  _message() { echo "$*" >> "${BATS_TEST_TMPDIR}/msg"; }
  _make_dir() { :; }
  _pipe_pane() { echo "PIPE:$*" >> "${BATS_TEST_TMPDIR}/pipe"; }
  _capture_pane() { echo "captured-content"; }
  set_tmux_option "@logging_revamped_path" "${BATS_TEST_TMPDIR}/logs"
}

teardown() {
  cleanup_test_environment
}

@test "logging.sh - functions are defined" {
  function_exists logging_toggle
  function_exists logging_save
  function_exists logging_screenshot
}

@test "logging.sh - toggle starts logging when the pane is not piped" {
  _pane_pipe() { echo "0"; }
  run main toggle
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == *"cat >>"* ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"logging to"* ]]
}

@test "logging.sh - toggle stops logging when the pane is piped" {
  _pane_pipe() { echo "1"; }
  run main toggle
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == "PIPE:" ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"stopped"* ]]
}

@test "logging.sh - save writes the scrollback to a file" {
  _make_dir() { mkdir -p "${1}"; }
  run main save
  local f="${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history"
  [[ -f "${f}" ]]
  [[ "$(cat "${f}")" == "captured-content" ]]
}

@test "logging.sh - screenshot writes the visible pane to a file" {
  _make_dir() { mkdir -p "${1}"; }
  run main screenshot
  [[ -f "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.screen" ]]
}

@test "logging.sh - color flag is added when enabled" {
  set_tmux_option "@logging_revamped_color" "1"
  [[ "$(_capture_flags)" == "-e" ]]
  set_tmux_option "@logging_revamped_color" "0"
  [[ -z "$(_capture_flags)" ]]
}

@test "logging.sh - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
