#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/logging_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/logging_helpers.bash"

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/logging-revamped"
}

lacks() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" != *"$1"* ]] || return 1
  done
}

@test "plan - by default only the menu key is bound, to a menu of every action that starts no process" {
  # Arrange
  local t
  t=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${lines[0]}" == "bind-key -N Logging menu M-l display-menu -T Logging Toggle live log \"\" run-shell \"${t} toggle\" Save scrollback \"\" run-shell \"${t} save\" Save screen \"\" run-shell \"${t} screenshot\" Labelled save \"\" run-shell \"${t} label\" Log whole window \"\" run-shell \"${t} window\" Clear history \"\" run-shell \"${t} clear\" Live tail \"\" run-shell \"${t} tail\" Search logs \"\" run-shell \"${t} search\" Copy last log \"\" run-shell \"${t} copy\" Compress logs \"\" run-shell \"${t} compress\" Prune old logs \"\" run-shell \"${t} prune\" Doctor \"\" display-popup -E -w 90% -h 90% \"${t} doctor; read -r logging_revamped_wait\"" ]]
}

@test "plan - before tmux 3.1 a binding carries no note" {
  # Arrange
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "bind-key M-l display-menu -T Logging Toggle live log "* ]]
}

@test "plan - each action key runs its command, and off or empty binds nothing" {
  # Arrange
  local t
  t=$(tool_path)
  option toggle_key L
  option save_key M-s
  option screenshot_key M-p
  option label_key M-n
  option window_key M-w
  option clear_key M-c
  option tail_key M-t
  option search_key off
  option menu_key off

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "bind-key -N Toggle live log L run-shell ${t} toggle" ]]
  [[ "${lines[1]}" == "bind-key -N Save scrollback M-s run-shell ${t} save" ]]
  [[ "${lines[2]}" == "bind-key -N Save screen M-p run-shell ${t} screenshot" ]]
  [[ "${lines[3]}" == "bind-key -N Labelled save M-n run-shell ${t} label" ]]
  [[ "${lines[4]}" == "bind-key -N Log whole window M-w run-shell ${t} window" ]]
  [[ "${lines[5]}" == "bind-key -N Clear history M-c run-shell ${t} clear" ]]
  [[ "${lines[6]}" == "bind-key -N Live tail M-t run-shell ${t} tail" ]]
  [[ "${#lines[@]}" -eq 7 ]]
}

@test "plan - the default menu key someone else holds is left alone and named" {
  # Arrange
  printf 'bind-key    -T prefix       M-l               display-message mine\n' >"${FAKE}/keys"
  local script='logging_revamped_plan; logging_revamped_lines; printf "[%s]" "${LOGGING_REVAMPED_SKIPPED}"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "[M-l]" ]]
}

@test "plan - the menu key the plugin bound before is bound again, and a key the person names is bound whoever holds it" {
  # Arrange
  printf '%s\n' 'bind-key    -T prefix       M-l               display-menu -T Logging a "" b' 'bind-key    -T prefix       L                 switch-client -l' >"${FAKE}/keys"
  option toggle_key L
  local script='logging_revamped_plan; logging_revamped_lines | cut -c1-40; printf "[%s]" "${LOGGING_REVAMPED_SKIPPED}"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${lines[0]}" == "bind-key -N Toggle live log L run-shell "* ]]
  [[ "${lines[1]}" == "bind-key -N Logging menu M-l display-men" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "plan - two actions set to one key bind it for the first and name the clash" {
  # Arrange
  option toggle_key M-x
  option save_key M-x
  local script='logging_revamped_plan; logging_revamped_lines | grep -c " M-x "; printf "[%s]" "${LOGGING_REVAMPED_SKIPPED}"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == $'1\n[M-x]' ]]
}

@test "plan - the placeholder in either status string becomes a format, once" {
  # Arrange
  var status-left '[#S] #{logging_status}'
  var status-right '#{logging_status} %H:%M #{logging_status}'
  option status_on REC
  option status_off idle
  option menu_key off

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == 'set-option -gq status-left [#S] #{?pane_pipe,REC,idle}' ]]
  [[ "${lines[1]}" == 'set-option -gq status-right #{?pane_pipe,REC,idle} %H:%M #{?pane_pipe,REC,idle}' ]]
}

@test "plan - a status string without the placeholder is not written" {
  # Arrange
  var status-left '[#S]'
  var status-right '#{?pane_pipe,*,} %H:%M'
  option menu_key off

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a setting from the environment rides on a binding with nothing else said, since the environment is read to the end" {
  # Arrange
  option toggle_key L
  option menu_key off
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  cat >"${BATS_TEST_TMPDIR}/stubs/env" <<'STUB'
#!/bin/sh
{ set +x; } 2>/dev/null
trap '' PIPE
printf 'LOGGING_REVAMPED_PATH=/tmp/logs\n'
count=0
while [ "${count}" -lt 4000 ]; do
  printf 'FILLER_%s=%0100d\n' "${count}" 0 || exit 1
  count=$((count + 1))
done
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/env"

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == *"/bin/logging-revamped' --path '/tmp/logs' toggle" ]]
  [[ "${#lines[@]}" -eq 1 ]]
}

@test "plan - a setting given on the command line or in the environment rides on every binding, and a tmux option does not" {
  # Arrange
  option pager most
  option toggle_key L
  option menu_key off
  export LOGGING_REVAMPED_PATH="/tmp/my logs" LOGGING_REVAMPED_ROLLING=1

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == *"/bin/logging-revamped' --path '/tmp/my logs' --rolling '1' toggle" ]]
  lacks "--pager"
}

@test "plan - every setting that can ride does, each under its own option" {
  # Arrange
  option toggle_key L
  option menu_key off
  export LOGGING_REVAMPED_STATUS_ON=on LOGGING_REVAMPED_STATUS_OFF=off LOGGING_REVAMPED_COLOR=1 LOGGING_REVAMPED_OUTPUT_ONLY=1
  export LOGGING_REVAMPED_PROMPT_PATTERN='^x' LOGGING_REVAMPED_PAGER=most LOGGING_REVAMPED_RETAIN_DAYS=7 LOGGING_REVAMPED_RETAIN_MAX=9

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == *"/bin/logging-revamped' --status-on 'on' --status-off 'off' --color '1' --output-only '1' --prompt-pattern '^x' --pager 'most' --retain-days '7' --retain-max '9' toggle" ]]
}

@test "plan - a log whose name holds anything but letters, digits, dots, dashes and underscores is not listed" {
  # Arrange
  mkdir -p "${LOGS}"
  : >"${LOGS}/tmux-work-1.log"
  : >"${LOGS}/tmux-bad name.log"
  : >"${LOGS}/tmux-old.log.gz"
  local script='LOGGING_REVAMPED_DIR="'"${LOGS}"'"; logging_revamped_files | tr "\n" " "'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "tmux-old.log.gz tmux-work-1.log " ]]
}

@test "plan - a log whose name holds an accented letter is not listed, in a UTF-8 locale too" {
  # Arrange
  local locale=C.UTF-8
  [[ "${OSTYPE}" != darwin* ]] || locale=en_US.UTF-8
  mkdir -p "${LOGS}"
  : >"${LOGS}/tmux-work-1.log"
  : >"${LOGS}/tmux-z"$'\xc3\xbc'"rich.log"
  local script='LOGGING_REVAMPED_DIR="'"${LOGS}"'"; logging_revamped_files | tr "\n" " "'

  # Act
  LC_ALL="${locale}" lib_run logging "${script}"

  # Assert
  [[ "${output}" == "tmux-work-1.log " ]]
}

@test "plan - a checkout path with a space, a quote and a hash is quoted for sh in a key and escaped again inside the menu" {
  # Arrange
  option toggle_key L
  local script='REVAMPED_LIB="/a b/it'"'"'s #1 \"x\"/lib"; logging_revamped_plan; logging_revamped_lines | cut -c1-200'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${lines[0]}" == "bind-key -N Toggle live log L run-shell '/a b/it'\\''s '\"\$(printf '%b' '\\0043')\"'1 \"x\"/bin/logging-revamped' toggle" ]]
  [[ "${lines[1]}" == "bind-key -N Logging menu M-l display-menu -T Logging Toggle live log \"\" run-shell \"'/a b/it'\\\\''s '\\\"\\\$(printf '%b' '\\\\0043')\\\"'1 \\\"x\\\"/bin/logging-revamped' toggle\" Save scrollback"* ]]
}
