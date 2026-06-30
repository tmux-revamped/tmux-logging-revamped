#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _LOGGING_REVAMPED_DOCTOR_LOADED
  unset _LOGGING_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/logging/doctor.sh"
}

teardown() {
  cleanup_test_environment
}

@test "doctor.sh - functions are defined" {
  function_exists logging_doctor
  function_exists _doctor_tool
  function_exists _logging_path_writable
}

@test "doctor.sh - _doctor_tool reports found and not found" {
  has_command() { [[ "$1" == "gzip" ]]; }
  run _doctor_tool gzip
  [[ "${output}" == *"gzip: found"* ]]
  run _doctor_tool nope
  [[ "${output}" == *"nope: not found"* ]]
}

@test "doctor.sh - _logging_path_writable is true for a writable directory" {
  _logging_path_writable "${TEST_TMPDIR}"
}

@test "doctor.sh - _logging_path_writable creates a missing directory" {
  _logging_path_writable "${TEST_TMPDIR}/new/deep"
  [[ -d "${TEST_TMPDIR}/new/deep" ]]
}

@test "doctor.sh - _logging_path_writable is false for an unwritable directory" {
  local dir="${TEST_TMPDIR}/ro"
  mkdir -p "${dir}"
  chmod 000 "${dir}"
  run _logging_path_writable "${dir}"
  chmod 755 "${dir}"
  [[ "${status}" -ne 0 ]]
}

@test "doctor.sh - logging_doctor reports the path and a writable directory" {
  has_command() { return 0; }
  set_tmux_option "@logging_revamped_path" "${TEST_TMPDIR}/logs"
  run logging_doctor
  [[ "${output}" == *"tmux-logging-revamped doctor"* ]]
  [[ "${output}" == *"log path: ${TEST_TMPDIR}/logs"* ]]
  [[ "${output}" == *"writable: yes"* ]]
  [[ "${output}" == *"gzip: found"* ]]
  [[ "${output}" == *"clipboard: tmux load-buffer"* ]]
}

@test "doctor.sh - logging_doctor reports a missing tool" {
  has_command() { return 1; }
  set_tmux_option "@logging_revamped_path" "${TEST_TMPDIR}/logs"
  run logging_doctor
  [[ "${output}" == *"fzf: not found"* ]]
}

@test "doctor.sh - logging_doctor reports an unwritable path" {
  has_command() { return 0; }
  local dir="${TEST_TMPDIR}/ro2"
  mkdir -p "${dir}"
  chmod 000 "${dir}"
  set_tmux_option "@logging_revamped_path" "${dir}"
  run logging_doctor
  chmod 755 "${dir}"
  [[ "${output}" == *"writable: no"* ]]
}

@test "doctor.sh - logging_doctor reflects the on settings" {
  has_command() { return 0; }
  set_tmux_option "@logging_revamped_path" "${TEST_TMPDIR}/logs"
  set_tmux_option "@logging_revamped_color" "1"
  set_tmux_option "@logging_revamped_rolling" "1"
  set_tmux_option "@logging_revamped_output_only" "1"
  run logging_doctor
  [[ "${output}" == *"color: on"* ]]
  [[ "${output}" == *"rolling: on"* ]]
  [[ "${output}" == *"output-only: on"* ]]
}

@test "doctor.sh - logging_doctor reflects the off settings" {
  has_command() { return 0; }
  set_tmux_option "@logging_revamped_path" "${TEST_TMPDIR}/logs"
  run logging_doctor
  [[ "${output}" == *"color: off"* ]]
  [[ "${output}" == *"rolling: off"* ]]
  [[ "${output}" == *"output-only: off"* ]]
}
