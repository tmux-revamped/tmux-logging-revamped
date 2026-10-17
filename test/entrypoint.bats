#!/usr/bin/env bats

setup() {
  ENTRY_OPTS="${BATS_TEST_TMPDIR}/opts"
  mkdir -p "${ENTRY_OPTS}"
  export ENTRY_OPTS
  tmux() {
    local verb="${1}"
    shift
    case "${verb}" in
      show-option) [[ -f "${ENTRY_OPTS}/${*: -1}" ]] && cat "${ENTRY_OPTS}/${*: -1}"; return 0 ;;
      set-option) printf '%s' "${3}" > "${ENTRY_OPTS}/${2}" ;;
      bind-key) echo "${1}" >> "${ENTRY_OPTS}/bindings" ;;
      *) return 0 ;;
    esac
  }
  export -f tmux
  ENTRY="${BATS_TEST_DIRNAME}/../logging-revamped.tmux"
}

@test "entrypoint - the status placeholder becomes a pane_pipe format with no shell job" {
  # Arrange
  printf '%s' '#{logging_status} %H:%M' > "${ENTRY_OPTS}/status-right"

  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/status-right")" != *"#("* ]] || false
  [[ "$(cat "${ENTRY_OPTS}/status-right")" == '#{?pane_pipe,*,} %H:%M' ]]
}

@test "entrypoint - custom glyphs keep commas and ampersands literal" {
  # Arrange
  printf '%s' '#{logging_status}' > "${ENTRY_OPTS}/status-left"
  printf '%s' '#[fg=red,bold]REC&' > "${ENTRY_OPTS}/@logging_revamped_status_on"
  printf '%s' 'idle' > "${ENTRY_OPTS}/@logging_revamped_status_off"

  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/status-left")" == '#{?pane_pipe,#[fg=red#,bold]REC&,idle}' ]]
}

@test "entrypoint - a line without the placeholder is left unchanged" {
  # Arrange
  printf '%s' '%H:%M' > "${ENTRY_OPTS}/status-right"

  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/status-right")" == '%H:%M' ]]
}

@test "entrypoint - only the menu is bound by default, on M-l" {
  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/bindings")" == "M-l" ]]
}

@test "entrypoint - the toggle and every other action stay unbound by default" {
  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/bindings")" != *"P"* ]] || false
  [[ "$(cat "${ENTRY_OPTS}/bindings")" != *"M-p"* ]]
}

@test "entrypoint - a set action key binds that action" {
  # Arrange
  printf '%s' 'P' > "${ENTRY_OPTS}/@logging_revamped_toggle_key"

  # Act
  run bash "${ENTRY}"

  # Assert
  [[ "$(cat "${ENTRY_OPTS}/bindings")" == "P"$'\n'"M-l" ]]
}

@test "entrypoint - a menu key of off binds nothing" {
  # Arrange
  printf '%s' 'off' > "${ENTRY_OPTS}/@logging_revamped_menu_key"

  # Act
  run bash "${ENTRY}"

  # Assert
  [[ ! -f "${ENTRY_OPTS}/bindings" ]]
}

@test "entrypoint - the bound command runs the plugin from a path with a space and a quote" {
  # Arrange
  local root="${BATS_TEST_TMPDIR}/it's a dir"
  mkdir -p "${root}/src"
  cp "${ENTRY}" "${root}/logging-revamped.tmux"
  printf '#!/bin/sh\nprintf %%s "$1" > "$RAN_FILE"\n' > "${root}/src/logging.sh"
  RAN_FILE="${BATS_TEST_TMPDIR}/ran"
  export RAN_FILE
  tmux() { [[ "${1}" == "bind-key" ]] && printf '%s' "${4}" > "${ENTRY_OPTS}/bound"; return 0; }
  export -f tmux
  bash "${root}/logging-revamped.tmux"

  # Act
  run sh -c "$(cat "${ENTRY_OPTS}/bound")"

  # Assert
  [ "${status}" -eq 0 ]
  [[ "$(cat "${RAN_FILE}")" == "menu" ]]
}
