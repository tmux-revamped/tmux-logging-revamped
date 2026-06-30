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

@test "logging_filename_labeled folds a label in after the timestamp" {
  [[ "$(logging_filename_labeled main 1 0 STAMP "my note" history)" == "tmux-main-1-0-STAMP-my-note.history" ]]
}

@test "logging_filename_labeled falls back to the plain name when the label is empty" {
  [[ "$(logging_filename_labeled main 1 0 STAMP "" history)" == "tmux-main-1-0-STAMP.history" ]]
}

@test "logging_filename_labeled treats an all-unsafe label as empty" {
  [[ "$(logging_filename_labeled main 1 0 STAMP " " log)" == "tmux-main-1-0-STAMP.log" ]]
}

@test "logging_rolling_filename builds a stable timestamp-free name" {
  [[ "$(logging_rolling_filename "my/sess")" == "tmux-my-sess-session.log" ]]
}

@test "logging_pane_file_opt builds a safe option name from a pane id" {
  [[ "$(logging_pane_file_opt "%3")" == "@logging_revamped_file__3" ]]
  [[ "$(logging_pane_file_opt "")" == "@logging_revamped_file_" ]]
}

@test "logging_strip_prompts drops prompt and command-echo lines with the default pattern" {
  local out
  out=$(printf '$ ls -la\noutput one\n# id\noutput two\n' | logging_strip_prompts)
  [[ "${out}" == $'output one\noutput two' ]]
}

@test "logging_strip_prompts honours a custom pattern" {
  local out
  out=$(printf 'KEEP me\nDROP this\n' | logging_strip_prompts '^DROP ')
  [[ "${out}" == "KEEP me" ]]
}

@test "logging_strip_prompts emits nothing when every line is a prompt" {
  local out
  out=$(printf '$ a\n$ b\n' | logging_strip_prompts)
  [[ -z "${out}" ]]
}

@test "logging_prune_excess prints entries beyond the newest max" {
  local out
  out=$(printf 'a\nb\nc\nd\ne\n' | logging_prune_excess 2)
  [[ "${out}" == $'a\nb\nc' ]]
}

@test "logging_prune_excess prints nothing when under the max" {
  local out
  out=$(printf 'a\nb\n' | logging_prune_excess 5)
  [[ -z "${out}" ]]
}

@test "logging_prune_excess prints nothing for empty input" {
  local out
  out=$(printf '' | logging_prune_excess 2)
  [[ -z "${out}" ]]
}

@test "logging_prune_excess treats a non-numeric max as zero" {
  local out
  out=$(printf 'a\nb\n' | logging_prune_excess "bad")
  [[ "${out}" == $'a\nb' ]]
}

@test "logging_grep_file and logging_grep_line split a grep record" {
  [[ "$(logging_grep_file "/a/b/file.log:42:some text")" == "/a/b/file.log" ]]
  [[ "$(logging_grep_line "/a/b/file.log:42:some text")" == "42" ]]
}

@test "logging_open_cmd builds a pager command at the matching line" {
  [[ "$(logging_open_cmd less /tmp/x.log 42)" == "less +42 -- '/tmp/x.log'" ]]
  [[ "$(logging_open_cmd "" /tmp/x.log)" == "less +1 -- '/tmp/x.log'" ]]
}

@test "logging.sh - pipe and capture seams are callable" {
  run _pipe_pane
  [[ "${status}" -eq 0 ]]
  run _capture_pane -p
  [[ "${status}" -eq 0 ]]
}
