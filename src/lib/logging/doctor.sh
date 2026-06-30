#!/usr/bin/env bash
#
# doctor.sh: a capability report explaining what this host can and cannot do for
# logging: where logs are written, whether that path is writable, and which
# optional tools back the compress, search, and live-tail actions.

[[ -n "${_LOGGING_REVAMPED_DOCTOR_LOADED:-}" ]] && return 0
_LOGGING_REVAMPED_DOCTOR_LOADED=1

_LOGGING_DOCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_LOGGING_DOCTOR_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_LOGGING_DOCTOR_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_LOGGING_DOCTOR_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_LOGGING_DOCTOR_DIR}/logging.sh"

# _doctor_tool NAME -> "  NAME: found" or "  NAME: not found".
_doctor_tool() {
  if has_command "${1}"; then
    printf '  %s: found\n' "${1}"
  else
    printf '  %s: not found\n' "${1}"
  fi
}

# _logging_path_writable DIR -> 0 when DIR can be written to or created.
_logging_path_writable() {
  local dir="${1}"
  if [[ -d "${dir}" ]]; then
    [[ -w "${dir}" ]]
  else
    mkdir -p "${dir}" 2>/dev/null
  fi
}

# logging_doctor -> a human readable report of the log path and detected tools.
logging_doctor() {
  local dir
  # shellcheck disable=SC2088 # ~ is a literal default expanded by logging_expand_path
  dir="$(logging_expand_path "$(get_tmux_option "@logging_revamped_path" "~/.tmux/logs")")"
  printf 'tmux-logging-revamped doctor\n'
  printf 'platform: %s\n' "$(platform_os)"
  printf 'log path: %s\n' "${dir}"
  if _logging_path_writable "${dir}"; then
    printf 'writable: yes\n'
  else
    printf 'writable: no\n'
  fi
  printf 'color: %s\n' "$([[ "$(get_tmux_option "@logging_revamped_color" "0")" == "1" ]] && echo on || echo off)"
  printf 'rolling: %s\n' "$([[ "$(get_tmux_option "@logging_revamped_rolling" "0")" == "1" ]] && echo on || echo off)"
  printf 'output-only: %s\n' "$([[ "$(get_tmux_option "@logging_revamped_output_only" "0")" == "1" ]] && echo on || echo off)"
  printf 'tools\n'
  _doctor_tool sed
  _doctor_tool gzip
  _doctor_tool fzf
  _doctor_tool tail
  _doctor_tool find
  printf 'clipboard: tmux load-buffer -w (requires tmux 3.2+)\n'
  return 0
}

export -f _doctor_tool
export -f _logging_path_writable
export -f logging_doctor
