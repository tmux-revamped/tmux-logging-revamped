# shellcheck shell=bash
# shellcheck disable=SC2207

_logging_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  --rolling)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --color)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --output-only)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --menu-key | --toggle-key | --save-key | --screenshot-key | --label-key | --window-key | --clear-key | --tail-key | --search-key | --path | --prompt-pattern | --pager | --retain-days | --retain-max | --status-on | --status-off)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list toggle save screenshot label window clear tail search copy compress prune status doctor version help --json --theme --menu-key --toggle-key --save-key --screenshot-key --label-key --window-key --clear-key --tail-key --search-key --path --rolling --color --output-only --prompt-pattern --pager --retain-days --retain-max --status-on --status-off" -- "${cur}"))
}

complete -F _logging_revamped logging-revamped
