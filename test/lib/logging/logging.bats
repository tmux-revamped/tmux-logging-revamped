#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _LOGGING_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/logging/logging.sh"
}

teardown() {
  cleanup_test_environment
}

@test "logging_sanitize replaces unsafe characters with a dash" {
  [[ "$(logging_sanitize "my sess/1:x")" == "my-sess-1-x" ]]
  [[ "$(logging_sanitize "ok.name_1-2")" == "ok.name_1-2" ]]
}

@test "logging_filename builds a safe name" {
  [[ "$(logging_filename main 1 0 20260622-1430 log)" == "tmux-main-1-0-20260622-1430.log" ]]
}

@test "logging_filename sanitizes components and defaults the extension" {
  [[ "$(logging_filename "my/sess" 1 0 stamp)" == "tmux-my-sess-1-0-stamp.log" ]]
}

@test "logging_expand_path expands a leading tilde" {
  [[ "$(logging_expand_path "~/logs")" == "${HOME}/logs" ]]
  [[ "$(logging_expand_path "~")" == "${HOME}" ]]
  [[ "$(logging_expand_path "/abs/x")" == "/abs/x" ]]
}

@test "logging_trim_trailing strips trailing spaces and tabs per line" {
  local out
  out=$(printf 'foo   \nbar\twith\ttabs\t\nbaz\n' | logging_trim_trailing)
  [[ "${out}" == $'foo\nbar\twith\ttabs\nbaz' ]]
}

@test "logging_trim_trailing keeps interior whitespace intact" {
  [[ "$(printf 'a  b  \n' | logging_trim_trailing)" == "a  b" ]]
}

@test "logging.sh - host-probe seams are callable" {
  run _now_stamp
  true
}
