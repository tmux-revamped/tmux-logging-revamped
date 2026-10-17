#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _LOGGING_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/logging.sh"
  _pane_var() { case "${1}" in session_name) echo main ;; window_index) echo 1 ;; pane_index) echo 0 ;; esac; }
  _now_stamp() { echo "STAMP"; }
  _message() { echo "$*" >> "${BATS_TEST_TMPDIR}/msg"; }
  _make_dir() { :; }
  _pipe_pane() { echo "PIPE:$*" >> "${BATS_TEST_TMPDIR}/pipe"; }
  _capture_pane() { echo "captured-content"; }
  set_tmux_option "@logging_revamped_path" "${BATS_TEST_TMPDIR}/logs"
}

teardown() {
  cleanup_test_environment
}

@test "logging.sh - functions are defined" {
  function_exists logging_toggle
  function_exists logging_save
  function_exists logging_screenshot
}

@test "logging.sh - toggle starts logging when the pane is not piped" {
  _pane_pipe() { echo "0"; }
  run main toggle
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == *"cat >>"* ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"logging to"* ]]
}

@test "logging.sh - toggle stops logging when the pane is piped" {
  _pane_pipe() { echo "1"; }
  run main toggle
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == "PIPE:" ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"stopped"* ]]
}

@test "logging.sh - save writes the scrollback to a file" {
  _make_dir() { mkdir -p "${1}"; }
  run main save
  local f="${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history"
  [[ -f "${f}" ]]
  [[ "$(cat "${f}")" == "captured-content" ]]
}

@test "logging.sh - screenshot writes the visible pane to a file" {
  _make_dir() { mkdir -p "${1}"; }
  run main screenshot
  [[ -f "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.screen" ]]
}

@test "logging.sh - save trims trailing whitespace from the capture" {
  _make_dir() { mkdir -p "${1}"; }
  _capture_pane() { printf 'line one   \nline two\t\n'; }
  run main save
  local f="${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history"
  [[ "$(cat "${f}")" == $'line one\nline two' ]]
}

@test "logging.sh - color flag is added when enabled" {
  set_tmux_option "@logging_revamped_color" "1"
  [[ "$(_capture_flags)" == "-e" ]]
  set_tmux_option "@logging_revamped_color" "0"
  [[ -z "$(_capture_flags)" ]]
}

@test "logging.sh - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "logging.sh - new action functions are defined" {
  function_exists logging_window
  function_exists logging_clear
  function_exists logging_tail
  function_exists logging_search
  function_exists logging_copy
  function_exists logging_compress
  function_exists logging_prune
  function_exists logging_status
  function_exists logging_menu
  function_exists logging_prompt_label
}

@test "logging.sh - toggle uses a rolling file when rolling is enabled" {
  _pane_pipe() { echo "0"; }
  set_tmux_option "@logging_revamped_rolling" "1"
  _make_dir() { :; }
  run main toggle
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == *"-session.log" ]]
}

@test "logging.sh - status prints the on glyph and exports the option when piped" {
  _pane_pipe() { echo "1"; }
  run main status
  [[ "${output}" == "*" ]]
  [[ "$(get_tmux_option @logging_status)" == "*" ]]
}

@test "logging.sh - status prints the off glyph when not piped" {
  _pane_pipe() { echo "0"; }
  run main status
  [[ -z "${output}" ]]
}

@test "logging.sh - status honours custom glyph options" {
  _pane_pipe() { echo "1"; }
  set_tmux_option "@logging_revamped_status_on" "REC"
  run main status
  [[ "${output}" == "REC" ]]
}

@test "logging.sh - label prompts through the tmux seam" {
  _tmux() { echo "$1" >> "${BATS_TEST_TMPDIR}/seam"; }
  run main label
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "command-prompt" ]]
}

@test "logging.sh - window logs every pane and skips blank lines" {
  _window_panes() { printf '%%1 main 1 0\n%%2 main 1 1\n\n'; }
  _pipe_pane() { echo "PIPE:$*" >> "${BATS_TEST_TMPDIR}/wpipe"; }
  run main window
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"2 panes"* ]]
  [[ "$(grep -c PIPE "${BATS_TEST_TMPDIR}/wpipe")" == "2" ]]
}

@test "logging.sh - window with no panes reports zero" {
  run main window
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"0 panes"* ]]
}

@test "logging.sh - clear runs clear-history through the seam" {
  _clear_history() { echo "CLEARED" >> "${BATS_TEST_TMPDIR}/cleared"; }
  run main clear
  [[ "$(cat "${BATS_TEST_TMPDIR}/cleared")" == "CLEARED" ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"cleared pane history"* ]]
}

@test "logging.sh - tail reports when the pane is not being logged" {
  _pane_var() { case "${1}" in pane_id) echo "%1" ;; esac; }
  run main tail
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"not being logged"* ]]
}

@test "logging.sh - tail opens a popup when the pane is logged" {
  _pane_var() { case "${1}" in pane_id) echo "%1" ;; esac; }
  set_tmux_option "$(logging_pane_file_opt "%1")" "/tmp/x.log"
  _tmux() { echo "$1" >> "${BATS_TEST_TMPDIR}/seam"; }
  run main tail
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "display-popup" ]]
}

@test "logging.sh - search with no pattern prompts through the seam" {
  _tmux() { echo "$1" >> "${BATS_TEST_TMPDIR}/seam"; }
  run main search
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "command-prompt" ]]
}

@test "logging.sh - search reports when there are no matches" {
  _grep() { return 0; }
  run main search needle
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"no matches for needle"* ]]
}

@test "logging.sh - search runs the picker inside a popup instead of the run-shell job" {
  # Arrange
  _grep() { printf '%s\n' "/logs/tmux-main-1-0-STAMP.history:12:the needle here"; }
  _fzf() { echo "FZF" >> "${BATS_TEST_TMPDIR}/fzf"; }
  _tmux() { printf '%s|' "$@" >> "${BATS_TEST_TMPDIR}/seam"; }

  # Act
  run main search needle

  # Assert
  [[ ! -f "${BATS_TEST_TMPDIR}/fzf" ]] || false
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "display-popup|-E|$(printf '%q' "${LOG_SELF}") pick|" ]] || false
  [[ "$(get_tmux_option "@logging_revamped_search_pattern")" == "needle" ]]
}

@test "logging.sh - pick opens the chosen match in the pager at its line" {
  # Arrange
  set_tmux_option "@logging_revamped_search_pattern" "needle"
  _grep() { printf '%s\n' "/logs/tmux-main-1-0-STAMP.history:12:the needle here"; }
  _fzf() { head -1; }
  _pager() { printf '%s|' "$@" >> "${BATS_TEST_TMPDIR}/pager"; }

  # Act
  run main pick

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/pager")" == "less|12|/logs/tmux-main-1-0-STAMP.history|" ]]
}

@test "logging.sh - pick does nothing when the picker is cancelled" {
  # Arrange
  set_tmux_option "@logging_revamped_search_pattern" "needle"
  _grep() { printf '%s\n' "/logs/a.history:1:hit"; }
  _fzf() { cat >/dev/null; }
  _pager() { echo "RAN" >> "${BATS_TEST_TMPDIR}/pager"; }

  # Act
  run main pick

  # Assert
  [[ ! -f "${BATS_TEST_TMPDIR}/pager" ]]
}

@test "logging.sh - pick does nothing without a stored pattern" {
  # Arrange
  _grep() { echo "GREP" >> "${BATS_TEST_TMPDIR}/grep"; }

  # Act
  run main pick

  # Assert
  [[ ! -f "${BATS_TEST_TMPDIR}/grep" ]]
}

@test "logging.sh - the pager seam passes the line and file to the pager" {
  # Arrange
  fakepager() { printf '%s|' "$@"; }

  # Act
  run _pager fakepager 7 "/logs/a b.log"

  # Assert
  [[ "${output}" == "+7|--|/logs/a b.log|" ]]
}

@test "logging.sh - copy reports when there are no logs" {
  _list_logs() { return 0; }
  run main copy
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"no logs to copy"* ]]
}

@test "logging.sh - copy sends the newest log to the clipboard" {
  mkdir -p "${BATS_TEST_TMPDIR}/logs"
  printf 'content\n' > "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history"
  _clip() { cat > "${BATS_TEST_TMPDIR}/clip"; }
  run main copy
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"copied tmux-main-1-0-STAMP.history"* ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/clip")" == "content" ]]
}

@test "logging.sh - compress gzips logs and skips already-compressed and blank entries" {
  _list_logs() { printf 'a.log\nb.gz\n\n'; }
  _gzip() { echo "GZIP:$*" >> "${BATS_TEST_TMPDIR}/gz"; }
  run main compress
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"compressed 1 logs"* ]]
  [[ "$(grep -c GZIP "${BATS_TEST_TMPDIR}/gz")" == "1" ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/gz")" == *"a.log"* ]]
}

@test "logging.sh - compress with no logs reports zero" {
  _list_logs() { return 0; }
  run main compress
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"compressed 0 logs"* ]]
}

@test "logging.sh - prune does nothing with default retention" {
  run main prune
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"pruned 0 logs"* ]]
}

@test "logging.sh - prune removes files older than the day threshold" {
  set_tmux_option "@logging_revamped_retain_days" "1"
  _find_old() { printf '%s\n\n' "/logs/old.history"; }
  _remove() { echo "RM:$*" >> "${BATS_TEST_TMPDIR}/rm"; }
  run main prune
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"pruned 1 logs"* ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/rm")" == *"old.history"* ]]
}

@test "logging.sh - prune trims to the max-count newest" {
  set_tmux_option "@logging_revamped_retain_max" "1"
  _list_logs() { printf 'a\nb\nc\n'; }
  _remove() { echo "RM:$*" >> "${BATS_TEST_TMPDIR}/rm"; }
  run main prune
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"pruned 2 logs"* ]]
}

@test "logging.sh - prune ignores non-numeric retention values" {
  set_tmux_option "@logging_revamped_retain_days" "soon"
  set_tmux_option "@logging_revamped_retain_max" "many"
  run main prune
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"pruned 0 logs"* ]]
}

@test "logging.sh - menu opens a display-menu through the seam" {
  _tmux() { echo "$1" >> "${BATS_TEST_TMPDIR}/seam"; }
  run main menu
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "display-menu" ]]
}

@test "logging.sh - doctor prints a capability report" {
  run main doctor
  [[ "${output}" == *"tmux-logging-revamped doctor"* ]]
}

@test "logging.sh - save folds a label into the filename" {
  _make_dir() { mkdir -p "${1}"; }
  run main save "my note"
  [[ -f "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP-my-note.history" ]]
}

@test "logging.sh - save strips prompt lines when output-only is on" {
  _make_dir() { mkdir -p "${1}"; }
  set_tmux_option "@logging_revamped_output_only" "1"
  _capture_pane() { printf '$ ls -la\nreal output\n'; }
  run main save
  [[ "$(cat "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history")" == "real output" ]]
}

@test "logging.sh - save honours a custom output-only pattern" {
  _make_dir() { mkdir -p "${1}"; }
  set_tmux_option "@logging_revamped_output_only" "1"
  set_tmux_option "@logging_revamped_prompt_pattern" "^DROP "
  _capture_pane() { printf 'DROP this\nkeep this\n'; }
  run main save
  [[ "$(cat "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history")" == "keep this" ]]
}

@test "logging.sh - screenshot strips prompt lines when output-only is on" {
  _make_dir() { mkdir -p "${1}"; }
  set_tmux_option "@logging_revamped_output_only" "1"
  _capture_pane() { printf '# id\nvisible line\n'; }
  run main screenshot
  [[ "$(cat "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.screen")" == "visible line" ]]
}

@test "logging.sh - tmux and history seams are callable" {
  run _tmux display-message hi
  [[ "${status}" -eq 0 ]]
  run _clear_history
  [[ "${status}" -eq 0 ]]
  run _window_panes
  [[ "${status}" -eq 0 ]]
  run _clip <<< "x"
  [[ "${status}" -eq 0 ]]
}

@test "logging.sh - file seams operate on a temp directory" {
  local d="${BATS_TEST_TMPDIR}/seamdir"
  mkdir -p "${d}"
  printf 'needle here\n' > "${d}/tmux-a.log"
  run _list_logs "${d}"
  [[ "${output}" == *"tmux-a.log"* ]]
  run _grep needle "${d}"
  [[ "${output}" == *"needle here"* ]]
  run _find_old "${d}" 0
  [[ "${status}" -eq 0 ]]
  _gzip -- "${d}/tmux-a.log"
  [[ -f "${d}/tmux-a.log.gz" ]]
  _remove "${d}/tmux-a.log.gz"
  [[ ! -f "${d}/tmux-a.log.gz" ]]
}

@test "logging.sh - probe seams are callable" {
  source "${BATS_TEST_DIRNAME}/../../../src/logging.sh"
  run _pane_pipe
  [[ "${status}" -eq 0 ]]
  run _pane_var pane_id
  [[ "${status}" -eq 0 ]]
  run _message "hi"
  [[ "${status}" -eq 0 ]]
  _make_dir "${BATS_TEST_TMPDIR}/probe"
  [[ -d "${BATS_TEST_TMPDIR}/probe" ]]
}

@test "logging.sh - the fzf seam routes input through fzf" {
  fzf() { cat; }
  run _fzf <<< "one"
  [[ "${output}" == "one" ]]
}

@test "logging.sh - prune by count deletes the oldest plugin logs and keeps foreign files" {
  # Arrange
  local d="${BATS_TEST_TMPDIR}/logs"
  mkdir -p "${d}"
  printf 'x\n' > "${d}/tmux-b.log"
  printf 'x\n' > "${d}/tmux-a.log"
  printf 'x\n' > "${d}/notes.txt"
  touch -t 202601010000 "${d}/tmux-b.log"
  touch -t 202601020000 "${d}/tmux-a.log"
  touch -t 202601030000 "${d}/notes.txt"
  set_tmux_option "@logging_revamped_retain_max" "1"

  # Act
  run main prune

  # Assert
  [[ ! -f "${d}/tmux-b.log" ]] || false
  [[ -f "${d}/tmux-a.log" ]] || false
  [[ -f "${d}/notes.txt" ]] || false
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"pruned 1 logs"* ]]
}

@test "logging.sh - copy picks the most recently modified log" {
  # Arrange
  local d="${BATS_TEST_TMPDIR}/logs"
  mkdir -p "${d}"
  printf 'old\n' > "${d}/tmux-z.history"
  printf 'new\n' > "${d}/tmux-a.history"
  touch -t 202601010000 "${d}/tmux-z.history"
  touch -t 202601020000 "${d}/tmux-a.history"
  _clip() { cat > "${BATS_TEST_TMPDIR}/clip"; }

  # Act
  run main copy

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/clip")" == "new" ]]
}

@test "logging.sh - compress only touches plugin log files" {
  # Arrange
  local d="${BATS_TEST_TMPDIR}/logs"
  mkdir -p "${d}"
  printf 'x\n' > "${d}/tmux-a.log"
  printf 'x\n' > "${d}/notes.txt"
  _gzip() { echo "GZIP:$*" >> "${BATS_TEST_TMPDIR}/gz"; }

  # Act
  run main compress

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/gz")" == "GZIP:-- ${d}/tmux-a.log" ]]
}

@test "logging.sh - toggle pipes into a file only the owner can read" {
  # Arrange
  _pane_pipe() { echo "0"; }

  # Act
  run main toggle

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/pipe")" == "PIPE:umask 077; exec cat >> $(printf '%q' "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.log")" ]]
}

@test "logging.sh - save writes a file only the owner can read" {
  # Arrange
  _make_dir() { mkdir -p "${1}"; }
  umask 022

  # Act
  run main save

  # Assert
  [[ "$(ls -l "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.history" | cut -c1-10)" == "-rw-------" ]]
}

@test "logging.sh - the log directory is created private to the owner" {
  # Arrange
  source "${BATS_TEST_DIRNAME}/../../../src/logging.sh"
  umask 022

  # Act
  _make_dir "${BATS_TEST_TMPDIR}/private"

  # Assert
  [[ "$(ls -ld "${BATS_TEST_TMPDIR}/private" | cut -c1-10)" == "drwx------" ]]
}

@test "logging.sh - the pipe command keeps a hash in the path literal" {
  # Arrange
  local file="/logs/a#b.log"

  # Act
  run _pipe_cmd "${file}"

  # Assert
  [[ "${output}" == "umask 077; exec cat >> /logs/a##b.log" ]]
}

@test "logging.sh - compress skips files that a pane is still logging to" {
  # Arrange
  local d="${BATS_TEST_TMPDIR}/logs"
  _piped_panes() { printf '1|%%1\n0|%%2\n'; }
  set_tmux_option "$(logging_pane_file_opt "%1")" "${d}/tmux-a.log"
  set_tmux_option "$(logging_pane_file_opt "%2")" "${d}/tmux-b.log"
  _list_logs() { printf 'tmux-a.log\ntmux-b.log\n'; }
  _gzip() { echo "GZIP:$*" >> "${BATS_TEST_TMPDIR}/gz"; }

  # Act
  run main compress

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/gz")" == "GZIP:-- ${d}/tmux-b.log" ]] || false
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == *"compressed 1 logs"* ]]
}

@test "logging.sh - the piped panes seam is callable" {
  # Arrange
  source "${BATS_TEST_DIRNAME}/../../../src/logging.sh"

  # Act
  run _piped_panes

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "logging.sh - label prompt relays the reply through an option with a quoted plugin path" {
  # Arrange
  LOG_SELF="/p a/it's/logging.sh"
  _tmux() { printf '%s|' "$@" >> "${BATS_TEST_TMPDIR}/seam"; }
  local expected
  expected="$(cat <<'EXPECTED'
command-prompt|-p|log label:|set-option -gq @logging_revamped_prompt "%%%" ; run-shell "/p\\ a/it\\'s/logging.sh label_reply"|
EXPECTED
)"

  # Act
  run main label

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == "${expected}" ]]
}

@test "logging.sh - search prompt relays the reply through an option" {
  # Arrange
  _tmux() { printf '%s|' "$@" >> "${BATS_TEST_TMPDIR}/seam"; }

  # Act
  run main search

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" != *"'%%'"* ]] || false
  [[ "$(cat "${BATS_TEST_TMPDIR}/seam")" == *'@logging_revamped_prompt "%%%" ; run-shell "'*'search_reply"|' ]]
}

@test "logging.sh - label reply saves with the prompted label and clears it" {
  # Arrange
  _make_dir() { mkdir -p "${1}"; }
  set_tmux_option "@logging_revamped_prompt" "it's \"done\""

  # Act
  run main label_reply

  # Assert
  [[ -f "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP-it-s--done-.history" ]] || false
  [[ -z "$(get_tmux_option "@logging_revamped_prompt")" ]]
}

@test "logging.sh - search reply searches for the prompted pattern" {
  # Arrange
  set_tmux_option "@logging_revamped_prompt" "a'b"
  _grep() { printf '%s\n' "${1}" >> "${BATS_TEST_TMPDIR}/grep"; }

  # Act
  run main search_reply

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/grep")" == "a'b" ]]
}

@test "logging.sh - an empty search reply does not prompt again" {
  # Arrange
  _tmux() { echo "$1" >> "${BATS_TEST_TMPDIR}/seam"; }

  # Act
  run main search_reply

  # Assert
  [[ ! -f "${BATS_TEST_TMPDIR}/seam" ]]
}

@test "logging.sh - the no-match message doubles hashes in the pattern" {
  # Arrange
  _grep() { return 0; }

  # Act
  run main search '#(id)'

  # Assert
  [[ "$(cat "${BATS_TEST_TMPDIR}/msg")" == "no matches for ##(id)" ]]
}

@test "logging.sh - window records each pane's file so tail can follow it" {
  # Arrange
  _window_panes() { printf '%%1 main 1 0\n%%2 main 1 1\n'; }

  # Act
  run main window

  # Assert
  [[ "$(get_tmux_option "$(logging_pane_file_opt "%1")")" == "${BATS_TEST_TMPDIR}/logs/tmux-main-1-0-STAMP.log" ]] || false
  [[ "$(get_tmux_option "$(logging_pane_file_opt "%2")")" == "${BATS_TEST_TMPDIR}/logs/tmux-main-1-1-STAMP.log" ]]
}

@test "logging.sh - menu items run the plugin through a quoted path" {
  # Arrange
  LOG_SELF="/p a/it's/logging.sh"
  _tmux() { printf '%s\n' "$@" >> "${BATS_TEST_TMPDIR}/seam"; }
  local toggle doctor
  toggle="$(cat <<'EXPECTED'
run-shell "/p\\ a/it\\'s/logging.sh toggle"
EXPECTED
)"
  doctor="$(cat <<'EXPECTED'
display-popup -E "/p\\ a/it\\'s/logging.sh doctor; read -r"
EXPECTED
)"

  # Act
  run main menu

  # Assert
  [[ "$(sed -n 6p "${BATS_TEST_TMPDIR}/seam")" == "${toggle}" ]] || false
  [[ "$(tail -n 1 "${BATS_TEST_TMPDIR}/seam")" == "${doctor}" ]]
}
