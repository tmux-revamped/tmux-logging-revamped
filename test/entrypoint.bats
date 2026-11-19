#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- logging-revamped.tmux bin/logging-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the menu key and turns the placeholder into a format" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{logging_status} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-l' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == '#{?pane_pipe,*,} end' ]]
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{logging_status} end'
  setting toggle_key L
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${after}" == "${before}" ]]
}

@test "entrypoint - the indicator shows on the status line only while the pane is logged" {
  # Arrange
  tmux set-option -g status-right 'log[#{logging_status}]'
  tmux set-option -g status-interval 1
  setting status_on REC
  setting toggle_key L
  load_plugin
  wait_for host_shows 'log[]'

  # Act
  press C-b L

  # Assert
  wait_for host_shows 'log[REC]'
}

@test "entrypoint - a checkout path with a space, a quote and a hash still logs from its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 dir"
  mkdir -p "${copy}"
  cp -Rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/logging-revamped.tmux" "${copy}/"
  setting toggle_key L
  load_plugin "${copy}"

  # Act
  press C-b L

  # Assert
  wait_for shows %0 '#{pane_pipe}' 1
  says from-a-strange-path
  wait_for log_holds log from-a-strange-path
}
