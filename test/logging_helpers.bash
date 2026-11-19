#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v LOGGING_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  LOGS="${BATS_TEST_TMPDIR}/logs"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE LOGS
  mkdir -p "${HOME}" "${FAKE}" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  pane %1 work 2 0 @5
  var @logging_revamped_path "${LOGS}"
  fake_tmux
  quiet date 'printf "%s\n" "${FAKE_NOW:-20260102-030405}"'
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

pane() {
  var pane_id "$1"
  var session_name "$2"
  var window_index "$3"
  var pane_index "$4"
  var window_id "$5"
  var pane_pipe "${6:-0}"
}

option() {
  var "@logging_revamped_$1" "$2"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -F '\t' -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } FS = "\001" }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        if (name ~ /^[?]/) { out = out substr(line, 1, at + stop - 1); line = substr(line, at + stop); continue }
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  awk -F '\t' -v want="\$3" '\$1 == want { print \$2 }' "${FAKE}/vars"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-panes)
  [ ! -f "${FAKE}/panes" ] || cat "${FAKE}/panes"
  ;;
capture-pane)
  [ ! -f "${FAKE}/screen" ] || cat "${FAKE}/screen"
  ;;
load-buffer)
  cat >"${FAKE}/buffer"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run logging "${1:-}"'logging_revamped_plan; logging_revamped_lines'
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

said() {
  grep '^display-message [^-]' "${FAKE}/log" | sed 's/^display-message //' || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/logging-revamped" "$@"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

log_file() {
  mkdir -p "${LOGS}"
  printf '%s\n' "${2:-line}" >"${LOGS}/$1"
  [[ -z "${3:-}" ]] || touch -t "$3" "${LOGS}/$1"
}

logs() {
  (cd "${LOGS}" && set -- tmux-* && printf '%s\n' "$*")
}
