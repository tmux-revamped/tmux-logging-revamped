#!/bin/sh
# shellcheck disable=SC2034,SC2088

[ -n "${LOGGING_REVAMPED_STATE_LOADED:-}" ] && return 0
LOGGING_REVAMPED_STATE_LOADED=1

LOGGING_REVAMPED_SETTINGS='toggle_key	
save_key	
screenshot_key	
label_key	
window_key	
clear_key	
tail_key	
search_key	
menu_key	M-l
status_on	*
status_off	
path	~/.tmux/logs
rolling	0
color	0
output_only	0
prompt_pattern	
pager	less
retain_days	0
retain_max	0'
LOGGING_REVAMPED_NAMES='toggle_key save_key screenshot_key label_key window_key clear_key tail_key search_key menu_key status_on status_off path rolling color output_only prompt_pattern pager retain_days retain_max'
LOGGING_REVAMPED_CARRIED='status_on status_off path rolling color output_only prompt_pattern pager retain_days retain_max'
LOGGING_REVAMPED_ACTIONS='toggle	Toggle live log
save	Save scrollback
screenshot	Save screen
label	Labelled save
window	Log whole window
clear	Clear history
tail	Live tail
search	Search logs'
LOGGING_REVAMPED_MENU='toggle	Toggle live log
save	Save scrollback
screenshot	Save screen
label	Labelled save
window	Log whole window
clear	Clear history
tail	Live tail
search	Search logs
copy	Copy last log
compress	Compress logs
prune	Prune old logs'
LOGGING_REVAMPED_S_toggle_key=''
LOGGING_REVAMPED_S_save_key=''
LOGGING_REVAMPED_S_screenshot_key=''
LOGGING_REVAMPED_S_label_key=''
LOGGING_REVAMPED_S_window_key=''
LOGGING_REVAMPED_S_clear_key=''
LOGGING_REVAMPED_S_tail_key=''
LOGGING_REVAMPED_S_search_key=''
LOGGING_REVAMPED_S_menu_key='M-l'
LOGGING_REVAMPED_S_status_on='*'
LOGGING_REVAMPED_S_status_off=''
LOGGING_REVAMPED_S_path='~/.tmux/logs'
LOGGING_REVAMPED_S_rolling='0'
LOGGING_REVAMPED_S_color='0'
LOGGING_REVAMPED_S_output_only='0'
LOGGING_REVAMPED_S_prompt_pattern=''
LOGGING_REVAMPED_S_pager='less'
LOGGING_REVAMPED_S_retain_days='0'
LOGGING_REVAMPED_S_retain_max='0'
LOGGING_REVAMPED_S_piped=''
LOGGING_REVAMPED_S_pane=''
LOGGING_REVAMPED_S_session=''
LOGGING_REVAMPED_S_window=''
LOGGING_REVAMPED_S_index=''
LOGGING_REVAMPED_S_window_id=''
LOGGING_REVAMPED_S_file=''
LOGGING_REVAMPED_FILE=@logging_revamped_file
LOGGING_REVAMPED_PROMPT=@logging_revamped_prompt
LOGGING_REVAMPED_PATTERN=@logging_revamped_search_pattern
LOGGING_REVAMPED_PLACEHOLDER='#{logging_status}'
LOGGING_REVAMPED_DEFAULT_PROMPT='^[[:space:]]*[#$%>] '
LOGGING_REVAMPED_DAY=86400
LOGGING_REVAMPED_MAX_COPIES=99
LOGGING_REVAMPED_NOTES_SINCE=3.1
LOGGING_REVAMPED_TMUX=''
LOGGING_REVAMPED_NOTES=0
LOGGING_REVAMPED_TOOL=''
LOGGING_REVAMPED_KEYS=''
LOGGING_REVAMPED_SKIPPED=''
LOGGING_REVAMPED_PLAN=''
LOGGING_REVAMPED_DIR=''
LOGGING_REVAMPED_BOUND=''
LOGGING_REVAMPED_EMPTY='logging-revamped-empty-argument'
LOGGING_REVAMPED_DEFAULT_MENU_KEY='M-l'
LOGGING_REVAMPED_KINDS='rolling	1 0
color	1 0
output_only	1 0
retain_days	number
retain_max	number'
