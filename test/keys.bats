#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

@test "keys - the toggle key starts a live log of what the pane prints, and stops it" {
  # Arrange
  setting toggle_key L
  load_plugin

  # Act
  press C-b L

  # Assert
  wait_for shows %0 '#{pane_pipe}' 1
  says hello-live-log
  wait_for log_holds log hello-live-log
  wait_for shows %0 '#{@logging_revamped_file}' "${FOUND}"
  press C-b L
  wait_for shows %0 '#{pane_pipe}' 0
  wait_for shows %0 '#{@logging_revamped_file}' ""
}

@test "keys - the save key writes the whole scrollback" {
  # Arrange
  setting save_key M-s
  load_plugin
  says saved-scrollback

  # Act
  press C-b M-s

  # Assert
  wait_for log_holds history saved-scrollback
  wait_for said "saved scrollback to ${FOUND}"
}

@test "keys - the screenshot key writes what the pane shows" {
  # Arrange
  setting screenshot_key M-p
  load_plugin
  says on-the-screen

  # Act
  press C-b M-p

  # Assert
  wait_for log_holds screen on-the-screen
}

@test "keys - the label key asks for a label and saves under it, quotes and all" {
  # Arrange
  setting label_key M-n
  load_plugin
  says labelled-text
  press C-b M-n
  wait_for host_shows 'log label:'

  # Act
  typed 'it"s mine'
  press Enter

  # Assert
  wait_for log_holds history labelled-text
  [[ "${FOUND}" == *"-it-s-mine.history" ]]
}

@test "keys - the window key logs every pane of the window" {
  # Arrange
  setting window_key M-w
  load_plugin
  tmux split-window -d -t test:0

  # Act
  press C-b M-w

  # Assert
  wait_for shows %0 '#{pane_pipe}' 1
  wait_for shows %1 '#{pane_pipe}' 1
  wait_for said 'logging 2 panes in this window'
}

@test "keys - the clear key empties the pane's history" {
  # Arrange
  setting clear_key M-c
  load_plugin
  tmux send-keys -t %0 'i=0; while [ $i -lt 80 ]; do echo row$i; i=$((i+1)); done' Enter
  wait_for pane_shows %0 row79

  # Act
  press C-b M-c

  # Assert
  wait_for shows %0 '#{history_size}' 0
}

@test "keys - the tail key follows the live log in a popup until Ctrl-C, which leaves no error, and says so when there is none" {
  # Arrange
  setting toggle_key L
  setting tail_key M-t
  load_plugin
  press C-b M-t
  wait_for said 'this pane is not being logged'
  press C-b L
  wait_for shows %0 '#{pane_pipe}' 1
  says shown-in-the-popup
  wait_for log_holds log shown-in-the-popup

  # Act
  press C-b M-t

  # Assert
  wait_for host_counts shown-in-the-popup 4
  press C-c
  wait_for host_counts shown-in-the-popup 2
  says after-the-tail
  wait_for log_holds log after-the-tail
  shows %0 '#{pane_in_mode}' 0
}

@test "keys - the search key asks for a pattern, offers the matches and opens the chosen one at its line" {
  # Arrange
  setting search_key M-f
  load_plugin
  mkdir -p "${LOGS}"
  printf 'one\ntwo needle\n' >"${LOGS}/tmux-test-0-0-20260102-030405.log"
  press C-b M-f
  wait_for host_shows 'search logs:'

  # Act
  typed needle
  press Enter

  # Assert
  wait_for file_holds "${BATS_TEST_TMPDIR}/viewed" "+2 -- ${LOGS}/tmux-test-0-0-20260102-030405.log"
  file_holds "${BATS_TEST_TMPDIR}/offered" 'tmux-test-0-0-20260102-030405.log:2:two needle'
}

@test "keys - the menu key opens the menu, and its first item starts a live log" {
  # Arrange
  load_plugin
  press C-b M-l
  wait_for host_shows 'Toggle live log'
  host_shows 'Prune old logs'

  # Act
  press Enter

  # Assert
  wait_for shows %0 '#{pane_pipe}' 1
}

@test "keys - the menu copies the newest log into a tmux buffer" {
  # Arrange
  local buffer
  load_plugin
  mkdir -p "${LOGS}"
  printf 'copied by the menu\n' >"${LOGS}/tmux-test-0-0-20260102-030405.log"
  press C-b M-l
  wait_for host_shows 'Copy last log'

  # Act
  press Down Down Down Down Down Down Down Down Enter

  # Assert
  wait_for said 'copied tmux-test-0-0-20260102-030405.log to clipboard'
  buffer=$(tmux show-buffer)
  [[ "${buffer}" == "copied by the menu" ]]
}

@test "keys - the menu's doctor item shows the report in a popup until a key is pressed" {
  # Arrange
  load_plugin
  press C-b M-l
  wait_for host_shows 'Doctor'

  # Act
  press Up Enter

  # Assert
  wait_for host_shows 'every key it binds is free or its own'
  host_shows 'gum'
  press Enter
  wait_for host_lacks 'Ready. Every tool'
}

@test "keys - the default menu key someone else holds keeps their command" {
  # Arrange
  tmux bind-key M-l set-option -g @mine yes
  load_plugin

  # Act
  press C-b M-l

  # Assert
  wait_for shows %0 '#{@mine}' yes
}
