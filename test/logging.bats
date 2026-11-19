#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/logging_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/logging_helpers.bash"

@test "logging - a file name carries the session, window, pane, time and label, with anything else as a dash" {
  # Arrange
  local script='printf "%%1\tmy sess\t2\t0\t20260102-030405\t\tlog\n%%2\tweb/api\t10\t3\t20260102-030405\tbefore deploy!\thistory\n%%3\ts\t1\t1\tt\t-\tscreen\n%%4\ts\t1\t1\tt\t???\tscreen\n" | logging_revamped_names'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${lines[0]}" == $'%1\ttmux-my-sess-2-0-20260102-030405.log' ]]
  [[ "${lines[1]}" == $'%2\ttmux-web-api-10-3-20260102-030405-before-deploy-.history' ]]
  [[ "${lines[2]}" == $'%3\ttmux-s-1-1-t.screen' ]]
  [[ "${lines[3]}" == $'%4\ttmux-s-1-1-t----.screen' ]]
}

@test "logging - this pane's name comes from the settings read, and a rolling log is named after the session" {
  # Arrange
  pane %7 "dev ops" 4 1 @2
  local script='logging_revamped_load; logging_revamped_name 20260102-030405 note log; logging_revamped_rolling_name'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == $'tmux-dev-ops-4-1-20260102-030405-note.log\ntmux-dev-ops-session.log' ]]
}

@test "logging - the log folder expands a leading tilde and nothing else" {
  # Arrange
  local script='for value in "~" "~/logs/tmux" "/var/log/tmux" "~user/x"; do LOGGING_REVAMPED_S_path="${value}"; logging_revamped_dir; done'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "${HOME}"$'\n'"${HOME}/logs/tmux"$'\n'"/var/log/tmux"$'\n'"~user/x" ]]
}

@test "logging - a name that exists gets the first free number before its extension" {
  # Arrange
  mkdir -p "${LOGS}"
  : >"${LOGS}/a.history"
  : >"${LOGS}/a-2.history"
  local script='logging_revamped_free "'"${LOGS}"'/a.history"; logging_revamped_free "'"${LOGS}"'/b.history"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "${LOGS}/a-3.history"$'\n'"${LOGS}/b.history" ]]
}

@test "logging - the pipe command quotes the file for sh and doubles every hash" {
  # Arrange
  local script='logging_revamped_pipe_command "/a b/it'"'"'s #1/x.log"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "umask 077; exec cat >> '/a b/it'\\''s ##1/x.log'" ]]
}

@test "logging - a literal is single-quoted with no hash left in it" {
  # Arrange
  local script='logging_revamped_literal "/a b/it'"'"'s #1/tool"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "'/a b/it'\\''s '\"\$(printf '%b' '\\0043')\"'1/tool'" ]]
  run sh -c "printf '%s' ${output}"
  [[ "${output}" == "/a b/it's #1/tool" ]]
}

@test "logging - the indicator is a format tmux draws, with a comma in a glyph escaped" {
  # Arrange
  local script='LOGGING_REVAMPED_S_status_on="REC,1" LOGGING_REVAMPED_S_status_off="-"; logging_revamped_status_format; logging_revamped_replaced "a #{logging_status} b #{logging_status}" "<X>"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == '#{?pane_pipe,REC#,1,-}'$'\n''a <X> b <X>' ]]
}

@test "logging - a saved file loses trailing blanks, and prompt lines too when only output is wanted" {
  # Arrange
  local script='text() { printf "$ make  \nok   \n# note\n> more\nplain\n"; }
    text | logging_revamped_filter | tr "\n" "|"; printf "\n"
    LOGGING_REVAMPED_S_output_only=1; text | logging_revamped_filter | tr "\n" "|"; printf "\n"
    LOGGING_REVAMPED_S_prompt_pattern="^ok"; text | logging_revamped_filter | tr "\n" "|"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${lines[0]}" == '$ make|ok|# note|> more|plain|' ]]
  [[ "${lines[1]}" == 'ok|plain|' ]]
  [[ "${lines[2]}" == '$ make|# note|> more|plain|' ]]
}

@test "logging - pruning takes plain logs past the days, then the oldest beyond the count" {
  # Arrange
  local script='rows() { printf "%s\n" "100 old.log" "200 old.log.gz" "86400 mid.log" "700000 new.log" "800000 newest.log"; }
    rows | logging_revamped_victims 864000 5 0 | tr "\n" " "; printf "|"
    rows | logging_revamped_victims 864000 0 2 | tr "\n" " "; printf "|"
    rows | logging_revamped_victims 864000 5 1 | tr "\n" " "; printf "|"
    rows | logging_revamped_victims 864000 x "" | tr "\n" " "; printf "|"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "old.log mid.log |old.log old.log.gz mid.log |old.log old.log.gz mid.log new.log ||" ]]
}

@test "logging - a file a pane is writing is left out" {
  # Arrange
  local script='printf "%s\n" a.log b.log "5 c.log" | logging_revamped_idle "b.log
c.log" | tr "\n" " "'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "a.log " ]]
}

@test "logging - the active logs come from every pane that pipes, in one call" {
  # Arrange
  printf '1\t%s/tmux-a.log\n0\t%s/tmux-b.log\n1\t\n1\t/elsewhere/tmux-c.log\n' "${LOGS}" "${LOGS}" >"${FAKE}/panes"

  # Act
  lib_run logging 'logging_revamped_active | tr "\n" " "'

  # Assert
  [[ "${output}" == "tmux-a.log tmux-c.log " ]]
  run sent '^list-panes'
  [[ "${output}" == "1" ]]
}

@test "logging - a key someone else holds in the prefix table is listed, and the plugin's own never" {
  # Arrange
  cat >"${FAKE}/keys" <<'KEYS'
bind-key    -T prefix       M-l               display-message mine
bind-key -r -T prefix       Up                select-pane -U
bind-key    -T prefix       L                 run-shell "'/x/bin/logging-revamped' toggle"
bind-key    -T prefix       M-k               display-menu -T Logging a "" b
bind-key    -T prefix       \#                list-buffers
KEYS

  # Act
  lib_run logging 'logging_revamped_held'

  # Assert
  [[ "${output}" == "M-l Up # " ]]
}

@test "logging - a list keeps an empty argument, as text and as JSON, and counts the bindings" {
  # Arrange
  local script='LOGGING_REVAMPED_PLAN=""; logging_revamped_emit bind-key M-l display-menu -T Logging "Toggle live log" "" "run-shell \"x\""; logging_revamped_emit set-option -gq status-right "a b"; logging_revamped_lines; logging_revamped_json; logging_revamped_bindings'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${lines[0]}" == 'bind-key M-l display-menu -T Logging Toggle live log "" run-shell "x"' ]]
  [[ "${lines[1]}" == 'set-option -gq status-right a b' ]]
  [[ "${lines[2]}" == '{"bindings":[["bind-key","M-l","display-menu","-T","Logging","Toggle live log","","run-shell \"x\""],["set-option","-gq","status-right","a b"]]}' ]]
  [[ "${lines[3]}" == "1" ]]
}

@test "logging - an empty argument reaches tmux as an empty argument" {
  # Arrange
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"
  quiet tmux 'for word in "$@"; do printf "[%s]" "${word}"; done >>"'"${BATS_TEST_TMPDIR}"'/argv"'
  local script='LOGGING_REVAMPED_PLAN=""; logging_revamped_emit display-menu a "" b; logging_revamped_emit display-message c; logging_revamped_send; logging_revamped_send_each'

  # Act
  lib_run logging "${script}"

  # Assert
  run cat "${BATS_TEST_TMPDIR}/argv"
  [[ "${output}" == "[display-menu][a][][b][;][display-message][c][display-menu][a][][b][display-message][c]" ]]
}

@test "logging - versions compare by number and a setting name comes from its long option" {
  # Arrange
  local script='for pair in "3.6 3.1" "3.1 3.1" "3.0 3.1" "3.10 3.9" "x 3.1"; do set -- ${pair}; if logging_revamped_version_ge "$1" "$2"; then printf y; else printf n; fi; done; printf "[%s]" "$(logging_revamped_parse_version "tmux next-3.7")" "$(logging_revamped_setting_name --retain-days)" "$(logging_revamped_setting_name --nope)"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "yynyn[3.7][retain_days][]" ]]
}

@test "logging - a setting comes from the environment, then the tmux option, then its default" {
  # Arrange
  option pager "bat -p"
  option rolling 1
  export LOGGING_REVAMPED_ROLLING=0
  local script='logging_revamped_load; printf "[%s]" "${LOGGING_REVAMPED_S_pager}" "${LOGGING_REVAMPED_S_rolling}" "${LOGGING_REVAMPED_S_menu_key}" "${LOGGING_REVAMPED_S_status_on}" "${LOGGING_REVAMPED_S_pane}" "${LOGGING_REVAMPED_S_session}" "${LOGGING_REVAMPED_S_window_id}"'

  # Act
  lib_run logging "${script}"

  # Assert
  [[ "${output}" == "[bat -p][0][M-l][*][%1][work][@5]" ]]
  run sent '^display-message -p'
  [[ "${output}" == "1" ]]
}
