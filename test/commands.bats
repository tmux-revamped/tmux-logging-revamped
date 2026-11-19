#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/logging_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/logging_helpers.bash"

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' -e '^capture-pane' "${FAKE}/log" || :
}

@test "toggle - it starts a live log, records its file on the pane and says so, in one tmux call" {
  # Arrange
  local file="${LOGS}/tmux-work-2-0-20260102-030405.log"

  # Act
  tool toggle

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -d "${LOGS}" ]]
  run sends
  [[ "${output}" == "pipe-pane -t %1 umask 077; exec cat >> '${file}' ; set-option -pq -t %1 @logging_revamped_file ${file} ; display-message tmux logging to ${file}" ]]
}

@test "toggle - a pane already logged is stopped and its file forgotten" {
  # Arrange
  pane %1 work 2 0 @5 1

  # Act
  tool toggle

  # Assert
  run sends
  [[ "${output}" == "pipe-pane -t %1 ; set-option -pqu -t %1 @logging_revamped_file ; display-message tmux logging stopped" ]]
}

@test "toggle - a rolling log is one file per session, and a hash in the folder is doubled for tmux" {
  # Arrange
  option rolling 1
  option path "${BATS_TEST_TMPDIR}/logs #1"

  # Act
  tool toggle

  # Assert
  run sends
  [[ "${output}" == "pipe-pane -t %1 umask 077; exec cat >> '${BATS_TEST_TMPDIR}/logs ##1/tmux-work-session.log' ; set-option -pq -t %1 @logging_revamped_file ${BATS_TEST_TMPDIR}/logs #1/tmux-work-session.log ; display-message tmux logging to ${BATS_TEST_TMPDIR}/logs ##1/tmux-work-session.log" ]]
}

@test "toggle - when tmux refuses the one call each command is sent alone" {
  # Arrange
  : >"${FAKE}/refused"

  # Act
  tool toggle

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '^pipe-pane -t %1 umask 077; exec cat >> '
  [[ "${output}" == "2" ]]
  run sent '^display-message tmux logging to '
  [[ "${output}" == "1" ]]
}

@test "save - the whole scrollback goes to a history file, trimmed, through a temporary file" {
  # Arrange
  printf '$ make   \nok\t\n' >"${FAKE}/screen"

  # Act
  tool save

  # Assert
  [[ "${status}" -eq 0 ]]
  run cat "${LOGS}/tmux-work-2-0-20260102-030405.history"
  [[ "${output}" == $'$ make\nok' ]]
  run logs
  [[ "${output}" == "tmux-work-2-0-20260102-030405.history" ]]
  run sent '^capture-pane -p -t %1 -S -$'
  [[ "${output}" == "1" ]]
  run said
  [[ "${output}" == "saved scrollback to ${LOGS}/tmux-work-2-0-20260102-030405.history" ]]
}

@test "save - a label joins the name, colour keeps the escapes, and only output drops the prompts" {
  # Arrange
  printf '$ make\nok\n' >"${FAKE}/screen"
  option color 1
  option output_only 1

  # Act
  tool save "before deploy"

  # Assert
  run cat "${LOGS}/tmux-work-2-0-20260102-030405-before-deploy.history"
  [[ "${output}" == "ok" ]]
  run sent '^capture-pane -p -t %1 -e -S -$'
  [[ "${output}" == "1" ]]
}

@test "save - a second save in the same second never replaces the first" {
  # Arrange
  printf 'first\n' >"${FAKE}/screen"
  tool save
  printf 'second\n' >"${FAKE}/screen"

  # Act
  tool save

  # Assert
  run cat "${LOGS}/tmux-work-2-0-20260102-030405.history" "${LOGS}/tmux-work-2-0-20260102-030405-2.history"
  [[ "${output}" == $'first\nsecond' ]]
}

@test "screenshot - only what the pane shows goes to a screen file" {
  # Arrange
  printf 'visible\n' >"${FAKE}/screen"

  # Act
  tool screenshot shot

  # Assert
  run cat "${LOGS}/tmux-work-2-0-20260102-030405-shot.screen"
  [[ "${output}" == "visible" ]]
  run sent '^capture-pane -p -t %1$'
  [[ "${output}" == "1" ]]
  run said
  [[ "${output}" == "saved screen to ${LOGS}/tmux-work-2-0-20260102-030405-shot.screen" ]]
}

@test "label - it asks for the label in a prompt that hands the reply to the tool unparsed" {
  # Arrange
  local t="'${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped'"

  # Act
  tool label

  # Assert
  run sends
  [[ "${output}" == "command-prompt -p log label: set-option -gq @logging_revamped_prompt \"%%%\" ; run-shell \"${t} label-reply\"" ]]
}

@test "label-reply - it takes the reply once and saves the scrollback under it" {
  # Arrange
  var @logging_revamped_prompt 'it"s #(x)'
  printf 'text\n' >"${FAKE}/screen"

  # Act
  tool label-reply

  # Assert
  run logs
  [[ "${output}" == "tmux-work-2-0-20260102-030405-it-s---x-.history" ]]
  run sent '^set-option -gqu @logging_revamped_prompt$'
  [[ "${output}" == "1" ]]
}

@test "window - every pane of the window gets a live log, in one tmux call" {
  # Arrange
  printf '%%1\twork\t2\t0\t20260102-030405\t\tlog\n%%2\twork\t2\t1\t20260102-030405\t\tlog\n' >"${FAKE}/panes"

  # Act
  tool window

  # Assert
  run sends
  [[ "${output}" == "pipe-pane -t %1 umask 077; exec cat >> '${LOGS}/tmux-work-2-0-20260102-030405.log' ; set-option -pq -t %1 @logging_revamped_file ${LOGS}/tmux-work-2-0-20260102-030405.log ; pipe-pane -t %2 umask 077; exec cat >> '${LOGS}/tmux-work-2-1-20260102-030405.log' ; set-option -pq -t %2 @logging_revamped_file ${LOGS}/tmux-work-2-1-20260102-030405.log ; display-message logging 2 panes in this window" ]]
  run sent '^list-panes -t @5 '
  [[ "${output}" == "1" ]]
}

@test "clear - it clears this pane's history and says so" {
  # Arrange
  local expected="clear-history -t %1 ; display-message cleared pane history"

  # Act
  tool clear

  # Assert
  run sends
  [[ "${output}" == "${expected}" ]]
}

@test "tail - a pane with no live log says so, and one with a log follows it in a popup with no hash" {
  # Arrange
  tool tail
  var @logging_revamped_file "${LOGS}/a #1.log"

  # Act
  tool tail

  # Assert
  run sends
  [[ "${lines[0]}" == "display-message this pane is not being logged" ]]
  [[ "${lines[1]}" == "display-popup -E exec sh -c 'trap \"exit 0\" INT; tail -f -- \"\$1\"' sh '${LOGS}/a '\"\$(printf '%b' '\\0043')\"'1.log'" ]]
}

@test "search - with no pattern it asks for one" {
  # Arrange
  local t="'${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped'"

  # Act
  tool search

  # Assert
  run sends
  [[ "${output}" == "command-prompt -p search logs: set-option -gq @logging_revamped_prompt \"%%%\" ; run-shell \"${t} search-reply\"" ]]
}

@test "search - a pattern found in a plain log opens the picker in a popup, and one found nowhere says so" {
  # Arrange
  local t="'${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped'"
  log_file tmux-a.log 'needle here'
  log_file tmux-b.log.gz 'needle packed'
  tool search 'no #such'

  # Act
  tool search needle

  # Assert
  run sends
  [[ "${lines[0]}" == "display-message no matches for no ##such" ]]
  [[ "${lines[1]}" == "set-option -gq @logging_revamped_search_pattern needle" ]]
  [[ "${lines[2]}" == "display-popup -E -w 90% -h 80% ${t} pick" ]]
}

@test "search-reply - an empty reply does nothing and a typed one is searched for" {
  # Arrange
  log_file tmux-a.log 'needle here'
  tool search-reply
  var @logging_revamped_prompt needle

  # Act
  tool search-reply

  # Assert
  run sent '^display-popup -E '
  [[ "${output}" == "1" ]]
}

@test "pick - the chosen match opens in the pager at its line" {
  # Arrange
  log_file tmux-a.log $'one\ntwo needle\nthree'
  var @logging_revamped_search_pattern needle
  option pager "viewer -R"
  quiet fzf 'cat >"'"${BATS_TEST_TMPDIR}"'/offered"; head -n 1 "'"${BATS_TEST_TMPDIR}"'/offered"'
  quiet viewer 'printf "%s\n" "$*" >"'"${BATS_TEST_TMPDIR}"'/viewed"'

  # Act
  tool pick

  # Assert
  [[ "${status}" -eq 0 ]]
  run cat "${BATS_TEST_TMPDIR}/offered" "${BATS_TEST_TMPDIR}/viewed"
  [[ "${output}" == "tmux-a.log:2:two needle"$'\n'"-R +2 -- ${LOGS}/tmux-a.log" ]]
}

@test "pick - with no pattern, no match or nothing chosen it opens nothing" {
  # Arrange
  log_file tmux-a.log 'one'
  quiet fzf 'cat >/dev/null'
  quiet less 'printf opened >"'"${BATS_TEST_TMPDIR}"'/viewed"'
  tool pick
  var @logging_revamped_search_pattern absent
  tool pick
  var @logging_revamped_search_pattern one

  # Act
  tool pick

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${BATS_TEST_TMPDIR}/viewed" ]]
}

@test "copy - the newest plain log goes to a tmux buffer and the clipboard" {
  # Arrange
  log_file tmux-old.log 'old' 202601010000
  log_file tmux-new.log 'newest' 202601020000
  log_file tmux-packed.log.gz 'x' 202601030000

  # Act
  tool copy

  # Assert
  run cat "${FAKE}/buffer"
  [[ "${output}" == "newest" ]]
  run said
  [[ "${output}" == "copied tmux-new.log to clipboard" ]]
}

@test "copy - with no log it says so" {
  # Arrange
  mkdir -p "${LOGS}"

  # Act
  tool copy

  # Assert
  run said
  [[ "${output}" == "no logs to copy" ]]
}

@test "compress - every plain log no pane is writing is gzipped in one call" {
  # Arrange
  log_file tmux-a.log
  log_file tmux-b.log
  log_file tmux-live.log
  log_file tmux-c.history.gz
  log_file "other file.txt"
  printf '1\t%s/tmux-live.log\n' "${LOGS}" >"${FAKE}/panes"
  quiet gzip 'printf "%s\n" "$*" >>"'"${BATS_TEST_TMPDIR}"'/gzip.calls"'

  # Act
  tool compress

  # Assert
  run cat "${BATS_TEST_TMPDIR}/gzip.calls"
  [[ "${output}" == "-- tmux-a.log tmux-b.log" ]]
  run said
  [[ "${output}" == "compressed 2 logs" ]]
}

@test "compress - one packed log is counted in the singular" {
  # Arrange
  log_file tmux-a.log
  quiet gzip ':'

  # Act
  tool compress

  # Assert
  run said
  [[ "${output}" == "compressed 1 log" ]]
}

@test "compress - with nothing to pack it runs nothing and says zero" {
  # Arrange
  log_file tmux-c.history.gz
  quiet gzip 'printf called >"'"${BATS_TEST_TMPDIR}"'/gzip.calls"'

  # Act
  tool compress

  # Assert
  [[ ! -e "${BATS_TEST_TMPDIR}/gzip.calls" ]]
  run said
  [[ "${output}" == "compressed 0 logs" ]]
}

@test "prune - logs past the days and beyond the count are deleted, never one a pane is writing" {
  # Arrange
  log_file tmux-ancient.log x 202501010000
  log_file tmux-live.log x 202501020000
  log_file tmux-b.log x 202601010000
  log_file tmux-c.log x 202601020000
  log_file tmux-d.log x 202601030000
  printf '1\t%s/tmux-live.log\n' "${LOGS}" >"${FAKE}/panes"
  option retain_days 30
  option retain_max 2
  export FAKE_NOW=1767571200

  # Act
  tool prune

  # Assert
  run logs
  [[ "${output}" == "tmux-c.log tmux-d.log tmux-live.log" ]]
  run said
  [[ "${output}" == "pruned 2 logs" ]]
}

@test "prune - one deleted log is counted in the singular" {
  # Arrange
  log_file tmux-b.log x 202601010000
  log_file tmux-c.log x 202601020000
  option retain_max 1
  export FAKE_NOW=1767571200

  # Act
  tool prune

  # Assert
  run logs
  [[ "${output}" == "tmux-c.log" ]]
  run said
  [[ "${output}" == "pruned 1 log" ]]
}

@test "prune - with no retention set it deletes nothing" {
  # Arrange
  log_file tmux-ancient.log x 202501010000

  # Act
  tool prune

  # Assert
  run logs
  [[ "${output}" == "tmux-ancient.log" ]]
  run said
  [[ "${output}" == "pruned 0 logs" ]]
}

@test "status - it prints the glyph for this pane's state" {
  # Arrange
  option status_off idle
  tool status
  local off="${output}"
  pane %1 work 2 0 @5 1

  # Act
  tool status

  # Assert
  [[ "${off}:${output}" == "idle:*" ]]
}

@test "apply - every binding goes to tmux in one call, and a refused call is sent again one by one" {
  # Arrange
  option toggle_key L
  tool apply
  local first
  first=$(sent '^bind-key .* ; bind-key ')
  : >"${FAKE}/refused"

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${first}" == "1" ]]
  run sent '^bind-key -N Toggle live log L run-shell '
  [[ "${output}" == "3" ]]
  run sent '^bind-key -N Logging menu M-l display-menu '
  [[ "${output}" == "1" ]]
}

@test "apply - a binding tmux refuses fails the run and leaves the others bound" {
  # Arrange
  option toggle_key Bogus
  local t="'${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped'"
  printf 'bind-key -N Toggle live log Bogus run-shell %s toggle\n' "${t}" >"${FAKE}/refused"

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^bind-key -N Logging menu M-l display-menu '
  [[ "${output}" == "1" ]]
}

@test "list - it prints the bindings as lines or as one JSON object and sends nothing" {
  # Arrange
  option menu_key off
  option toggle_key L
  tool list
  local text="${output}"

  # Act
  tool --json list

  # Assert
  [[ "${text}" == "bind-key -N Toggle live log L run-shell '${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped' toggle" ]]
  [[ "${output}" == "{\"bindings\":[[\"bind-key\",\"-N\",\"Toggle live log\",\"L\",\"run-shell\",\"'${REVAMPED_TESTS_DIR%/test}/bin/logging-revamped' toggle\"]]}" ]]
  run sent '^bind-key'
  [[ "${output}" == "0" ]]
}

@test "commands - a setting option reaches the action, in both forms" {
  # Arrange
  printf 'x\n' >"${FAKE}/screen"

  # Act
  tool --path "${BATS_TEST_TMPDIR}/other" --color=1 screenshot

  # Assert
  [[ -f "${BATS_TEST_TMPDIR}/other/tmux-work-2-0-20260102-030405.screen" ]]
  run sent '^capture-pane -p -t %1 -e$'
  [[ "${output}" == "1" ]]
}

@test "commands - usage errors name the problem" {
  # Arrange
  local hint="run 'logging-revamped help' for usage."

  # Act
  tool --json toggle

  # Assert
  [[ "${output}" == "logging-revamped: option '--json' works only with list. ${hint}" ]]
  tool --nope
  [[ "${output}" == "logging-revamped: unknown option '--nope'. ${hint}" ]]
  tool --path
  [[ "${output}" == "logging-revamped: option '--path' needs a value. ${hint}" ]]
  tool frobnicate
  [[ "${output}" == "logging-revamped: unknown command 'frobnicate'. ${hint}" ]]
}

@test "doctor - it names the log folder, gzip, fzf and the keys" {
  # Arrange
  quiet gzip 'exit 0'
  quiet fzf 'exit 0'

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"log folder"*"ok"*"${LOGS}, made on the first log"* ]]
  [[ "${output}" =~ gzip\ +ok ]]
  [[ "${output}" =~ fzf\ +ok ]]
  [[ "${output}" =~ keys\ +ok\ +every\ key\ it\ binds\ is\ free\ or\ its\ own ]]
}

@test "doctor - it warns about a missing tool, a folder it cannot write and a key left alone" {
  # Arrange
  harness_hide gzip fzf
  : >"${BATS_TEST_TMPDIR}/a-file"
  option path "${BATS_TEST_TMPDIR}/a-file/logs"
  printf 'bind-key    -T prefix       M-l               display-message mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"log folder"*"warn"*"${BATS_TEST_TMPDIR}/a-file/logs is not writable"* ]]
  [[ "${output}" =~ gzip\ +warn\ +compress\ needs\ it ]]
  [[ "${output}" =~ fzf\ +warn\ +search\ needs\ it\ to\ pick\ a\ match ]]
  [[ "${output}" =~ keys\ +warn\ +already\ bound\ and\ left\ alone:\ M-l ]]
}

@test "doctor - a log folder that exists is named alone, and one still to be made says so" {
  # Arrange
  local made="log folder +ok +${LOGS}\$" later="log folder +ok +${LOGS}/deep/er, made on the first log"
  mkdir -p "${LOGS}"
  tool doctor
  [[ "${lines[1]}" =~ ${made} ]]
  option path "${LOGS}/deep/er"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${later} ]]
}

@test "options - a double dash ends the options, and a short option nobody defined is refused" {
  # Arrange
  local hint="run 'logging-revamped help' for usage."
  tool -- --weird
  [[ "${output}" == "logging-revamped: unknown command '--weird'. ${hint}" ]]

  # Act
  tool -x list

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "logging-revamped: unknown option '-x'. ${hint}" ]]
}

@test "version - it prints the tool's version and tmux's" {
  # Arrange
  local version
  version=$(sed -n 's/^readonly LOGGING_REVAMPED_VERSION="\(.*\)"$/\1/p' "${REVAMPED_TESTS_DIR}/../lib/core.sh")

  # Act
  tool version

  # Assert
  [[ "${output}" == "logging-revamped ${version}"$'\n'"tmux: 3.6" ]]
}
