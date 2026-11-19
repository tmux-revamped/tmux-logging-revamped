export PS1='$ '
export PATH="/Users/Shared/demo/tmux-logging-revamped/bin:${PATH}"
export TZ=UTC
unset FZF_DEFAULT_OPTS FZF_DEFAULT_COMMAND
unset KODOUGU_THEME KODOUGU_ACCENT LOGGING_REVAMPED_THEME LOGGING_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear
