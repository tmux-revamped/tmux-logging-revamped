#!/bin/sh

[ -n "${LOGGING_REVAMPED_LOGGING_LOADED:-}" ] && return 0
LOGGING_REVAMPED_LOGGING_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"

logging_revamped_format() {
  printf '%s\n' "${LOGGING_REVAMPED_SETTINGS}" | awk -F '\t' -v file="${LOGGING_REVAMPED_FILE}" '{ printf "%s#{@logging_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { printf "\t#{pane_pipe}\t#{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{window_id}\t#{%s}", file }'
}

logging_revamped_resolve() {
  env | LOGGING_REVAMPED_ROWS="${LOGGING_REVAMPED_SETTINGS}" LOGGING_REVAMPED_LIVE="$1" awk '
    BEGIN {
      count = split(ENVIRON["LOGGING_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["LOGGING_REVAMPED_LIVE"], live, "\t")
      for (i = 1; i <= count; i++) {
        split(rows[i], field, "\t")
        name[i] = field[1]
        value[i] = (live[i] != "") ? live[i] : field[2]
        want["LOGGING_REVAMPED_" toupper(field[1])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) { value[want[key]] = substr($0, at + 1) }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      print "piped\t" live[count + 1]
      print "pane\t" live[count + 2]
      print "session\t" live[count + 3]
      print "window\t" live[count + 4]
      print "index\t" live[count + 5]
      print "window_id\t" live[count + 6]
      print "file\t" live[count + 7]
    }
  '
}

logging_revamped_setting_rows() {
  logging_revamped_setting_rows_format=$(logging_revamped_format)
  logging_revamped_setting_rows_live=$(tmux display-message -p "${logging_revamped_setting_rows_format}" 2>/dev/null) || logging_revamped_setting_rows_live=""
  logging_revamped_resolve "${logging_revamped_setting_rows_live}"
}

logging_revamped_load() {
  logging_revamped_load_values=$(logging_revamped_setting_rows)
  while IFS='	' read -r logging_revamped_load_name logging_revamped_load_value; do
    IFS= read -r "LOGGING_REVAMPED_S_${logging_revamped_load_name}" <<EOF
${logging_revamped_load_value}
EOF
  done <<EOF
${logging_revamped_load_values}
EOF
}

logging_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

logging_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  logging_revamped_version_ge_have="${1%%.*}"
  logging_revamped_version_ge_want="${2%%.*}"
  [ "${logging_revamped_version_ge_have}" -gt "${logging_revamped_version_ge_want}" ] && return 0
  [ "${logging_revamped_version_ge_have}" -eq "${logging_revamped_version_ge_want}" ] || return 1
  logging_revamped_version_ge_have="${1#*.}"
  logging_revamped_version_ge_want="${2#*.}"
  [ "${logging_revamped_version_ge_have%%.*}" -ge "${logging_revamped_version_ge_want%%.*}" ]
}

logging_revamped_emit() {
  for logging_revamped_emit_arg in "$@"; do
    LOGGING_REVAMPED_PLAN="${LOGGING_REVAMPED_PLAN}${logging_revamped_emit_arg:-${LOGGING_REVAMPED_EMPTY}}
"
  done
  LOGGING_REVAMPED_PLAN="${LOGGING_REVAMPED_PLAN}
"
}

logging_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

logging_revamped_tmux_string() {
  printf '%s\n' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g'
}

logging_revamped_doubled() {
  printf '%s\n' "$1" | sed 's/#/##/g'
}

logging_revamped_say() {
  logging_revamped_say_text=$(logging_revamped_doubled "$1")
  logging_revamped_emit display-message "${logging_revamped_say_text}"
}

logging_revamped_carried() {
  logging_revamped_carried_out=""
  for logging_revamped_carried_name in ${LOGGING_REVAMPED_CARRIED}; do
    logging_revamped_carried_upper=$(printf '%s\n' "${logging_revamped_carried_name}" | tr '[:lower:]' '[:upper:]')
    env | grep "^LOGGING_REVAMPED_${logging_revamped_carried_upper}=" >/dev/null || continue
    logging_revamped_carried_value=$(logging_revamped_setting "${logging_revamped_carried_name}")
    logging_revamped_carried_flag=$(printf '%s\n' "${logging_revamped_carried_name}" | tr '_' '-')
    logging_revamped_carried_out="${logging_revamped_carried_out} --${logging_revamped_carried_flag} $(logging_revamped_literal "${logging_revamped_carried_value}")"
  done
  printf '%s' "${logging_revamped_carried_out}"
}

logging_revamped_setting() {
  case "$1" in
  status_on) printf '%s\n' "${LOGGING_REVAMPED_S_status_on}" ;;
  status_off) printf '%s\n' "${LOGGING_REVAMPED_S_status_off}" ;;
  path) printf '%s\n' "${LOGGING_REVAMPED_S_path}" ;;
  rolling) printf '%s\n' "${LOGGING_REVAMPED_S_rolling}" ;;
  color) printf '%s\n' "${LOGGING_REVAMPED_S_color}" ;;
  output_only) printf '%s\n' "${LOGGING_REVAMPED_S_output_only}" ;;
  prompt_pattern) printf '%s\n' "${LOGGING_REVAMPED_S_prompt_pattern}" ;;
  pager) printf '%s\n' "${LOGGING_REVAMPED_S_pager}" ;;
  retain_days) printf '%s\n' "${LOGGING_REVAMPED_S_retain_days}" ;;
  *) printf '%s\n' "${LOGGING_REVAMPED_S_retain_max}" ;;
  esac
}

logging_revamped_key_of() {
  case "$1" in
  toggle) printf '%s\n' "${LOGGING_REVAMPED_S_toggle_key}" ;;
  save) printf '%s\n' "${LOGGING_REVAMPED_S_save_key}" ;;
  screenshot) printf '%s\n' "${LOGGING_REVAMPED_S_screenshot_key}" ;;
  label) printf '%s\n' "${LOGGING_REVAMPED_S_label_key}" ;;
  window) printf '%s\n' "${LOGGING_REVAMPED_S_window_key}" ;;
  clear) printf '%s\n' "${LOGGING_REVAMPED_S_clear_key}" ;;
  tail) printf '%s\n' "${LOGGING_REVAMPED_S_tail_key}" ;;
  *) printf '%s\n' "${LOGGING_REVAMPED_S_search_key}" ;;
  esac
}

logging_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "logging-revamped") == 0 && index(rest, "-T Logging") == 0) { printf "%s ", key }
    }
  '
}

logging_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  case " ${LOGGING_REVAMPED_BOUND} " in
  *" $1 "*)
    LOGGING_REVAMPED_SKIPPED="${LOGGING_REVAMPED_SKIPPED}${LOGGING_REVAMPED_SKIPPED:+ }$1"
    return 0
    ;;
  *) ;;
  esac
  LOGGING_REVAMPED_BOUND="${LOGGING_REVAMPED_BOUND} $1"
  logging_revamped_bind_key="$1" logging_revamped_bind_note="$2"
  shift 2
  set -- "${logging_revamped_bind_key}" "$@"
  [ "${LOGGING_REVAMPED_NOTES}" != 1 ] || set -- -N "${logging_revamped_bind_note}" "$@"
  logging_revamped_emit bind-key "$@"
}

logging_revamped_plan_keys() {
  while IFS='	' read -r logging_revamped_plan_keys_action logging_revamped_plan_keys_note; do
    logging_revamped_plan_keys_key=$(logging_revamped_key_of "${logging_revamped_plan_keys_action}")
    logging_revamped_bind "${logging_revamped_plan_keys_key}" "${logging_revamped_plan_keys_note}" run-shell "${LOGGING_REVAMPED_TOOL} ${logging_revamped_plan_keys_action}"
  done <<EOF
${LOGGING_REVAMPED_ACTIONS}
EOF
}

logging_revamped_plan_menu() {
  logging_revamped_plan_menu_tool=$(logging_revamped_tmux_string "${LOGGING_REVAMPED_TOOL}")
  set -- display-menu -T Logging
  while IFS='	' read -r logging_revamped_plan_menu_action logging_revamped_plan_menu_label; do
    set -- "$@" "${logging_revamped_plan_menu_label}" "" "run-shell \"${logging_revamped_plan_menu_tool} ${logging_revamped_plan_menu_action}\""
  done <<EOF
${LOGGING_REVAMPED_MENU}
EOF
  set -- "$@" Doctor "" "display-popup -E -w 90% -h 90% \"${logging_revamped_plan_menu_tool} doctor; read -r logging_revamped_wait\""
  case "${LOGGING_REVAMPED_S_menu_key}: ${LOGGING_REVAMPED_KEYS} " in
  "${LOGGING_REVAMPED_DEFAULT_MENU_KEY}:"*" ${LOGGING_REVAMPED_DEFAULT_MENU_KEY} "*)
    LOGGING_REVAMPED_SKIPPED="${LOGGING_REVAMPED_SKIPPED}${LOGGING_REVAMPED_SKIPPED:+ }${LOGGING_REVAMPED_DEFAULT_MENU_KEY}"
    return 0
    ;;
  *) ;;
  esac
  logging_revamped_bind "${LOGGING_REVAMPED_S_menu_key}" "Logging menu" "$@"
}

logging_revamped_status_format() {
  printf '%s\n%s\n' "${LOGGING_REVAMPED_S_status_on}" "${LOGGING_REVAMPED_S_status_off}" | sed 's/,/#,/g' | awk 'NR == 1 { on = $0 } NR == 2 { printf "#{?pane_pipe,%s,%s}\n", on, $0 }'
}

logging_revamped_replaced() {
  printf '%s\n' "$1" | LOGGING_REVAMPED_PUT="$2" awk -v find="${LOGGING_REVAMPED_PLACEHOLDER}" '
    {
      out = ""
      line = $0
      while ((at = index(line, find)) > 0) {
        out = out substr(line, 1, at - 1) ENVIRON["LOGGING_REVAMPED_PUT"]
        line = substr(line, at + length(find))
      }
      print out line
    }
  '
}

logging_revamped_plan_status() {
  logging_revamped_plan_status_format=$(logging_revamped_status_format)
  for logging_revamped_plan_status_option in status-left status-right; do
    logging_revamped_plan_status_now=$(tmux show-option -gqv "${logging_revamped_plan_status_option}" 2>/dev/null) || logging_revamped_plan_status_now=""
    case "${logging_revamped_plan_status_now}" in
    *"${LOGGING_REVAMPED_PLACEHOLDER}"*) ;;
    *) continue ;;
    esac
    logging_revamped_plan_status_new=$(logging_revamped_replaced "${logging_revamped_plan_status_now}" "${logging_revamped_plan_status_format}")
    logging_revamped_emit set-option -gq "${logging_revamped_plan_status_option}" "${logging_revamped_plan_status_new}"
  done
}

logging_revamped_plan() {
  logging_revamped_load
  logging_revamped_plan_raw=$(tmux -V 2>/dev/null) || logging_revamped_plan_raw=""
  LOGGING_REVAMPED_TMUX=$(logging_revamped_parse_version "${logging_revamped_plan_raw}")
  LOGGING_REVAMPED_NOTES=0
  ! logging_revamped_version_ge "${LOGGING_REVAMPED_TMUX}" "${LOGGING_REVAMPED_NOTES_SINCE}" || LOGGING_REVAMPED_NOTES=1
  logging_revamped_plan_path=$(logging_revamped_literal "${REVAMPED_LIB%/lib}/bin/logging-revamped")
  LOGGING_REVAMPED_TOOL="${logging_revamped_plan_path}$(logging_revamped_carried)"
  LOGGING_REVAMPED_KEYS=$(logging_revamped_held)
  LOGGING_REVAMPED_PLAN="" LOGGING_REVAMPED_SKIPPED="" LOGGING_REVAMPED_BOUND=""
  logging_revamped_plan_keys
  logging_revamped_plan_menu
  logging_revamped_plan_status
}

logging_revamped_send() {
  set --
  logging_revamped_send_sep=""
  while IFS= read -r logging_revamped_send_line; do
    if [ -z "${logging_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || logging_revamped_send_sep=";"
      continue
    fi
    [ -z "${logging_revamped_send_sep}" ] || set -- "$@" "${logging_revamped_send_sep}"
    logging_revamped_send_sep=""
    [ "${logging_revamped_send_line}" != "${LOGGING_REVAMPED_EMPTY}" ] || logging_revamped_send_line=""
    set -- "$@" "${logging_revamped_send_line}"
  done <<PLAN
${LOGGING_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

logging_revamped_send_each() {
  logging_revamped_send_each_status=0
  set --
  while IFS= read -r logging_revamped_send_each_line; do
    if [ -n "${logging_revamped_send_each_line}" ]; then
      [ "${logging_revamped_send_each_line}" != "${LOGGING_REVAMPED_EMPTY}" ] || logging_revamped_send_each_line=""
      set -- "$@" "${logging_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || logging_revamped_send_each_status=1
    set --
  done <<PLAN
${LOGGING_REVAMPED_PLAN}
PLAN
  return "${logging_revamped_send_each_status}"
}

logging_revamped_deliver() {
  ! logging_revamped_send || return 0
  logging_revamped_send_each
}

logging_revamped_apply() {
  logging_revamped_plan
  logging_revamped_deliver
}

logging_revamped_lines() {
  printf '%s' "${LOGGING_REVAMPED_PLAN}" | awk -v empty="${LOGGING_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

logging_revamped_json() {
  printf '%s' "${LOGGING_REVAMPED_PLAN}" | awk -v empty="${LOGGING_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

logging_revamped_bindings() {
  printf '%s' "${LOGGING_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

logging_revamped_setting_name() {
  logging_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${LOGGING_REVAMPED_NAMES} " in
  *" ${logging_revamped_setting_name_raw} "*) printf '%s\n' "${logging_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

logging_revamped_dir() {
  case "${LOGGING_REVAMPED_S_path}" in
  \~) printf '%s\n' "${HOME}" ;;
  \~/*) printf '%s/%s\n' "${HOME}" "${LOGGING_REVAMPED_S_path#??}" ;;
  *) printf '%s\n' "${LOGGING_REVAMPED_S_path}" ;;
  esac
}

logging_revamped_ready() {
  umask 077
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  [ -d "${LOGGING_REVAMPED_DIR}" ] || mkdir -p "${LOGGING_REVAMPED_DIR}" 2>/dev/null || :
}

logging_revamped_stamp() {
  date +%Y%m%d-%H%M%S
}

logging_revamped_names() {
  awk -F '\t' '
    function clean(text) { gsub(/[^A-Za-z0-9._-]/, "-", text); return text }
    {
      label = clean($6)
      stamp = clean($5)
      if (label != "" && label != "-") { stamp = stamp "-" label }
      printf "%s\ttmux-%s-%s-%s-%s.%s\n", $1, clean($2), clean($3), clean($4), stamp, clean($7)
    }
  '
}

logging_revamped_name() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${LOGGING_REVAMPED_S_pane}" "${LOGGING_REVAMPED_S_session}" "${LOGGING_REVAMPED_S_window}" "${LOGGING_REVAMPED_S_index}" "$1" "$2" "$3" | logging_revamped_names | cut -f 2
}

logging_revamped_rolling_name() {
  printf '%s\n' "${LOGGING_REVAMPED_S_session}" | awk '{ gsub(/[^A-Za-z0-9._-]/, "-"); printf "tmux-%s-session.log\n", $0 }'
}

logging_revamped_free() {
  [ -e "$1" ] || {
    printf '%s\n' "$1"
    return 0
  }
  logging_revamped_free_base="${1%.*}" logging_revamped_free_ext="${1##*.}" logging_revamped_free_at=2
  while [ "${logging_revamped_free_at}" -le "${LOGGING_REVAMPED_MAX_COPIES}" ] && [ -e "${logging_revamped_free_base}-${logging_revamped_free_at}.${logging_revamped_free_ext}" ]; do
    logging_revamped_free_at=$((logging_revamped_free_at + 1))
  done
  printf '%s-%s.%s\n' "${logging_revamped_free_base}" "${logging_revamped_free_at}" "${logging_revamped_free_ext}"
}

logging_revamped_pipe_command() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e "1s/^/umask 077; exec cat >> '/" -e "\$s/\$/'/"
}

logging_revamped_start_file() {
  if [ "${LOGGING_REVAMPED_S_rolling}" = 1 ]; then
    logging_revamped_start_file_name=$(logging_revamped_rolling_name)
  else
    logging_revamped_start_file_stamp=$(logging_revamped_stamp)
    logging_revamped_start_file_name=$(logging_revamped_name "${logging_revamped_start_file_stamp}" "" log)
  fi
  printf '%s/%s\n' "${LOGGING_REVAMPED_DIR}" "${logging_revamped_start_file_name}"
}

logging_revamped_toggle() {
  logging_revamped_load
  LOGGING_REVAMPED_PLAN=""
  if [ "${LOGGING_REVAMPED_S_piped}" = 1 ]; then
    logging_revamped_emit pipe-pane -t "${LOGGING_REVAMPED_S_pane}"
    logging_revamped_emit set-option -pqu -t "${LOGGING_REVAMPED_S_pane}" "${LOGGING_REVAMPED_FILE}"
    logging_revamped_say "tmux logging stopped"
    logging_revamped_deliver
    return 0
  fi
  logging_revamped_ready
  logging_revamped_toggle_file=$(logging_revamped_start_file)
  logging_revamped_toggle_command=$(logging_revamped_pipe_command "${logging_revamped_toggle_file}")
  logging_revamped_emit pipe-pane -t "${LOGGING_REVAMPED_S_pane}" "${logging_revamped_toggle_command}"
  logging_revamped_emit set-option -pq -t "${LOGGING_REVAMPED_S_pane}" "${LOGGING_REVAMPED_FILE}" "${logging_revamped_toggle_file}"
  logging_revamped_say "tmux logging to ${logging_revamped_toggle_file}"
  logging_revamped_deliver
}

logging_revamped_filter() {
  if [ "${LOGGING_REVAMPED_S_output_only}" = 1 ]; then
    grep -vE -- "${LOGGING_REVAMPED_S_prompt_pattern:-${LOGGING_REVAMPED_DEFAULT_PROMPT}}" | sed 's/[[:space:]]*$//'
    return 0
  fi
  sed 's/[[:space:]]*$//'
}

logging_revamped_capture() {
  logging_revamped_load
  logging_revamped_ready
  logging_revamped_capture_stamp=$(logging_revamped_stamp)
  logging_revamped_capture_name=$(logging_revamped_name "${logging_revamped_capture_stamp}" "$3" "$1")
  logging_revamped_capture_file=$(logging_revamped_free "${LOGGING_REVAMPED_DIR}/${logging_revamped_capture_name}")
  set -- "$1" "$2" -p -t "${LOGGING_REVAMPED_S_pane}"
  [ "${LOGGING_REVAMPED_S_color}" != 1 ] || set -- "$@" -e
  [ "$1" != history ] || set -- "$@" -S -
  logging_revamped_capture_what="$2"
  shift 2
  tmux capture-pane "$@" 2>/dev/null | logging_revamped_filter >"${logging_revamped_capture_file}.tmp"
  mv -f "${logging_revamped_capture_file}.tmp" "${logging_revamped_capture_file}"
  LOGGING_REVAMPED_PLAN=""
  logging_revamped_say "saved ${logging_revamped_capture_what} to ${logging_revamped_capture_file}"
  logging_revamped_deliver
}

logging_revamped_save() {
  logging_revamped_capture history scrollback "${1:-}"
}

logging_revamped_screenshot() {
  logging_revamped_capture screen screen "${1:-}"
}

logging_revamped_ask() {
  logging_revamped_plan_tool
  logging_revamped_ask_tool=$(logging_revamped_tmux_string "${LOGGING_REVAMPED_TOOL}")
  tmux command-prompt -p "$1" "set-option -gq ${LOGGING_REVAMPED_PROMPT} \"%%%\" ; run-shell \"${logging_revamped_ask_tool} $2\""
}

logging_revamped_plan_tool() {
  logging_revamped_load
  logging_revamped_plan_tool_path=$(logging_revamped_literal "${REVAMPED_LIB%/lib}/bin/logging-revamped")
  LOGGING_REVAMPED_TOOL="${logging_revamped_plan_tool_path}$(logging_revamped_carried)"
}

logging_revamped_reply() {
  logging_revamped_reply_text=$(tmux show-option -gqv "${LOGGING_REVAMPED_PROMPT}" 2>/dev/null) || logging_revamped_reply_text=""
  tmux set-option -gqu "${LOGGING_REVAMPED_PROMPT}" 2>/dev/null || :
  printf '%s\n' "${logging_revamped_reply_text}"
}

logging_revamped_label() {
  logging_revamped_ask "log label:" label-reply
}

logging_revamped_label_reply() {
  logging_revamped_label_reply_text=$(logging_revamped_reply)
  logging_revamped_save "${logging_revamped_label_reply_text}"
}

logging_revamped_window() {
  logging_revamped_load
  logging_revamped_ready
  logging_revamped_window_stamp=$(logging_revamped_stamp)
  logging_revamped_window_rows=$(tmux list-panes -t "${LOGGING_REVAMPED_S_window_id}" -F "#{pane_id}	#{session_name}	#{window_index}	#{pane_index}	${logging_revamped_window_stamp}		log" 2>/dev/null | logging_revamped_names)
  LOGGING_REVAMPED_PLAN=""
  logging_revamped_window_count=0
  while IFS='	' read -r logging_revamped_window_pane logging_revamped_window_name; do
    [ -n "${logging_revamped_window_pane}" ] || continue
    logging_revamped_window_command=$(logging_revamped_pipe_command "${LOGGING_REVAMPED_DIR}/${logging_revamped_window_name}")
    logging_revamped_emit pipe-pane -t "${logging_revamped_window_pane}" "${logging_revamped_window_command}"
    logging_revamped_emit set-option -pq -t "${logging_revamped_window_pane}" "${LOGGING_REVAMPED_FILE}" "${LOGGING_REVAMPED_DIR}/${logging_revamped_window_name}"
    logging_revamped_window_count=$((logging_revamped_window_count + 1))
  done <<EOF
${logging_revamped_window_rows}
EOF
  logging_revamped_say "logging ${logging_revamped_window_count} panes in this window"
  logging_revamped_deliver
}

logging_revamped_clear() {
  logging_revamped_load
  LOGGING_REVAMPED_PLAN=""
  logging_revamped_emit clear-history -t "${LOGGING_REVAMPED_S_pane}"
  logging_revamped_say "cleared pane history"
  logging_revamped_deliver
}

logging_revamped_tail() {
  logging_revamped_load
  LOGGING_REVAMPED_PLAN=""
  if [ -z "${LOGGING_REVAMPED_S_file}" ]; then
    logging_revamped_say "this pane is not being logged"
    logging_revamped_deliver
    return 0
  fi
  logging_revamped_tail_file=$(logging_revamped_literal "${LOGGING_REVAMPED_S_file}")
  tmux display-popup -E "exec sh -c 'trap \"exit 0\" INT; tail -f -- \"\$1\"' sh ${logging_revamped_tail_file}"
}

logging_revamped_files() {
  for logging_revamped_files_path in "${LOGGING_REVAMPED_DIR}"/tmux-*; do
    [ -f "${logging_revamped_files_path}" ] || continue
    case "${logging_revamped_files_path##*/}" in
    *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*) continue ;;
    *) printf '%s\n' "${logging_revamped_files_path##*/}" ;;
    esac
  done
}

logging_revamped_plain_files() {
  logging_revamped_files | grep -v '\.gz$' || :
}

logging_revamped_matches() {
  logging_revamped_matches_files=$(logging_revamped_plain_files)
  [ -n "${logging_revamped_matches_files}" ] || return 0
  (
    cd "${LOGGING_REVAMPED_DIR}" || exit 0
    # shellcheck disable=SC2086
    grep -n -- "$1" ${logging_revamped_matches_files} /dev/null 2>/dev/null || :
  )
}

logging_revamped_search() {
  if [ -z "${1:-}" ]; then
    logging_revamped_ask "search logs:" search-reply
    return 0
  fi
  logging_revamped_plan_tool
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  logging_revamped_search_found=$(logging_revamped_matches "$1")
  LOGGING_REVAMPED_PLAN=""
  if [ -z "${logging_revamped_search_found}" ]; then
    logging_revamped_say "no matches for $1"
    logging_revamped_deliver
    return 0
  fi
  tmux set-option -gq "${LOGGING_REVAMPED_PATTERN}" "$1"
  tmux display-popup -E -w 90% -h 80% "${LOGGING_REVAMPED_TOOL} pick"
}

logging_revamped_search_reply() {
  logging_revamped_search_reply_text=$(logging_revamped_reply)
  [ -n "${logging_revamped_search_reply_text}" ] || return 0
  logging_revamped_search "${logging_revamped_search_reply_text}"
}

logging_revamped_pick() {
  logging_revamped_load
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  logging_revamped_pick_pattern=$(tmux show-option -gqv "${LOGGING_REVAMPED_PATTERN}" 2>/dev/null) || logging_revamped_pick_pattern=""
  [ -n "${logging_revamped_pick_pattern}" ] || return 0
  logging_revamped_pick_found=$(logging_revamped_matches "${logging_revamped_pick_pattern}")
  [ -n "${logging_revamped_pick_found}" ] || return 0
  logging_revamped_pick_choice=$(printf '%s\n' "${logging_revamped_pick_found}" | fzf --no-sort --reverse --height=100% 2>/dev/null) || logging_revamped_pick_choice=""
  [ -n "${logging_revamped_pick_choice}" ] || return 0
  logging_revamped_pick_file="${logging_revamped_pick_choice%%:*}"
  logging_revamped_pick_line="${logging_revamped_pick_choice#*:}"
  set -f
  # shellcheck disable=SC2086
  set -- ${LOGGING_REVAMPED_S_pager}
  set +f
  "$@" "+${logging_revamped_pick_line%%:*}" -- "${LOGGING_REVAMPED_DIR}/${logging_revamped_pick_file}"
}

logging_revamped_times() {
  logging_revamped_times_files=$(logging_revamped_files)
  [ -n "${logging_revamped_times_files}" ] || return 0
  (
    cd "${LOGGING_REVAMPED_DIR}" || exit 0
    # shellcheck disable=SC2086
    stat -c '%Y %n' -- ${logging_revamped_times_files} 2>/dev/null || stat -f '%m %N' -- ${logging_revamped_times_files} 2>/dev/null || :
  ) | sort -k 1,1n -k 2
}

logging_revamped_copy() {
  logging_revamped_load
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  logging_revamped_copy_last=$(logging_revamped_times | awk '$2 !~ /\.gz$/ { last = $2 } END { print last }')
  LOGGING_REVAMPED_PLAN=""
  if [ -z "${logging_revamped_copy_last}" ]; then
    logging_revamped_say "no logs to copy"
    logging_revamped_deliver
    return 0
  fi
  tmux load-buffer -w - <"${LOGGING_REVAMPED_DIR}/${logging_revamped_copy_last}" 2>/dev/null || tmux load-buffer - <"${LOGGING_REVAMPED_DIR}/${logging_revamped_copy_last}" 2>/dev/null || :
  logging_revamped_say "copied ${logging_revamped_copy_last} to clipboard"
  logging_revamped_deliver
}

logging_revamped_active() {
  tmux list-panes -a -F "#{pane_pipe}	#{${LOGGING_REVAMPED_FILE}}" 2>/dev/null | awk -F '\t' '$1 == 1 && $2 != "" { name = $2; sub(/.*\//, "", name); print name }'
}

logging_revamped_idle() {
  LOGGING_REVAMPED_ACTIVE="$1" awk '
    BEGIN { count = split(ENVIRON["LOGGING_REVAMPED_ACTIVE"], row, "\n"); for (i = 1; i <= count; i++) { busy[row[i]] = 1 } }
    !($NF in busy)
  '
}

logging_revamped_say_count() {
  if [ "$2" -eq 1 ]; then
    logging_revamped_say "$1 1 log"
  else
    logging_revamped_say "$1 $2 logs"
  fi
}

logging_revamped_compress() {
  logging_revamped_load
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  logging_revamped_compress_active=$(logging_revamped_active)
  logging_revamped_compress_files=$(logging_revamped_plain_files | logging_revamped_idle "${logging_revamped_compress_active}")
  logging_revamped_compress_count=0
  if [ -n "${logging_revamped_compress_files}" ]; then
    logging_revamped_compress_count=$(printf '%s\n' "${logging_revamped_compress_files}" | grep -c '')
    (
      cd "${LOGGING_REVAMPED_DIR}" || exit 0
      # shellcheck disable=SC2086
      gzip -- ${logging_revamped_compress_files} 2>/dev/null || :
    )
  fi
  LOGGING_REVAMPED_PLAN=""
  logging_revamped_say_count compressed "${logging_revamped_compress_count}"
  logging_revamped_deliver
}

logging_revamped_victims() {
  awk -v now="$1" -v days="$2" -v max="$3" -v day="${LOGGING_REVAMPED_DAY}" '
    { stamp[NR] = $1; name[NR] = $2 }
    END {
      if (days !~ /^[0-9]+$/) { days = 0 }
      if (max !~ /^[0-9]+$/) { max = 0 }
      kept = 0
      for (i = 1; i <= NR; i++) {
        if (days > 0 && name[i] !~ /\.gz$/ && int((now - stamp[i]) / day) > days) { gone[i] = 1 } else { kept++ }
      }
      extra = (max > 0) ? kept - max : 0
      for (i = 1; i <= NR && extra > 0; i++) { if (!gone[i]) { gone[i] = 1; extra-- } }
      for (i = 1; i <= NR; i++) { if (gone[i]) { print name[i] } }
    }
  '
}

logging_revamped_prune() {
  logging_revamped_load
  LOGGING_REVAMPED_DIR=$(logging_revamped_dir)
  logging_revamped_prune_now=$(date +%s)
  logging_revamped_prune_active=$(logging_revamped_active)
  logging_revamped_prune_files=$(logging_revamped_times | logging_revamped_idle "${logging_revamped_prune_active}" | logging_revamped_victims "${logging_revamped_prune_now}" "${LOGGING_REVAMPED_S_retain_days}" "${LOGGING_REVAMPED_S_retain_max}")
  logging_revamped_prune_count=0
  if [ -n "${logging_revamped_prune_files}" ]; then
    logging_revamped_prune_count=$(printf '%s\n' "${logging_revamped_prune_files}" | grep -c '')
    (
      cd "${LOGGING_REVAMPED_DIR}" || exit 0
      # shellcheck disable=SC2086
      rm -f -- ${logging_revamped_prune_files}
    )
  fi
  LOGGING_REVAMPED_PLAN=""
  logging_revamped_say_count pruned "${logging_revamped_prune_count}"
  logging_revamped_deliver
}

logging_revamped_status() {
  logging_revamped_load
  if [ "${LOGGING_REVAMPED_S_piped}" = 1 ]; then
    printf '%s\n' "${LOGGING_REVAMPED_S_status_on}"
    return 0
  fi
  printf '%s\n' "${LOGGING_REVAMPED_S_status_off}"
}
