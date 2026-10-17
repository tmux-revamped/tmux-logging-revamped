#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../../src/lib/utils/constants.sh"
}

teardown() {
  cleanup_test_environment
}

@test "constants.sh - exposes the plugin version" {
  # Arrange
  local expected="2.0.0"

  # Act
  local actual="${LOGGING_REVAMPED_VERSION}"

  # Assert
  [[ "${actual}" == "${expected}" ]]
}

@test "constants.sh - defines the shared template constants" {
  variable_exists TMUX_PLUGIN_DEFAULT_MAX_AGE
  variable_exists TMUX_PLUGIN_PENDING
  [[ "${TMUX_PLUGIN_PENDING}" == "..." ]]
}
