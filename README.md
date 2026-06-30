<div align="center">

<h1>tmux-logging-revamped</h1>

**Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot.**

[![Tests](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)

</div>

**14** actions · **status indicator** · **live tail + search** · **tmux 1.9 to 3.5** · **99** tests · **95%+** coverage

Logs a tmux pane to a file. Toggle live logging on a pane, dump the entire scrollback at once, or save the visible screen. Filenames are built from the session, window, pane, and a timestamp, with every component sanitized so a session named `feature/login` never breaks the path.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Three captures</strong><br>Live pipe logging, full scrollback, and a visible-screen snapshot, each on its own key.</td>
<td><strong>Safe filenames</strong><br>Session, window, and pane names are sanitized, so slashes and spaces never escape the path.</td>
</tr>
<tr>
<td><strong>On demand</strong><br>Nothing runs in the background. Each capture is a single tmux command, no daemon, no temp file.</td>
<td><strong>Color or plain</strong><br>Strip ANSI by default, or keep colors in the capture with one option.</td>
</tr>
</table>

## Controls

| Key | Action |
|-----|--------|
| `prefix + P` | start or stop live logging of the active pane |
| `prefix + M-p` | save the full scrollback to a file |
| `prefix + M-P` | save the visible screen to a file |
| `prefix + M-n` | save the scrollback with a labelled note in the filename |
| `prefix + M-w` | start logging every pane in the current window |
| `prefix + M-c` | clear the active pane's history |
| `prefix + M-t` | follow the current pane's log in a popup |
| `prefix + M-f` | search saved logs and open a match at its line |
| `prefix + M-m` | open the control menu of every action |

Every key is configurable. The menu also reaches the copy, compress, prune, and
doctor actions, which have no default key of their own.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@logging_revamped_path` | `~/.tmux/logs` | directory where captures are written, created on demand |
| `@logging_revamped_color` | `0` | set to `1` to keep ANSI colors in saved captures |
| `@logging_revamped_rolling` | `0` | set to `1` so live logging appends to one growing per-session file |
| `@logging_revamped_output_only` | `0` | set to `1` to drop prompt and command-echo lines from saves |
| `@logging_revamped_prompt_pattern` | `^[[:space:]]*[#$%>] ` | regex for the lines output-only mode strips |
| `@logging_revamped_retain_days` | `0` | prune deletes logs older than this many days when above `0` |
| `@logging_revamped_retain_max` | `0` | prune keeps only this many newest logs when above `0` |
| `@logging_revamped_pager` | `less` | pager a search match opens in |
| `@logging_revamped_status_on` | `*` | glyph shown by `#{logging_status}` while a pane is logged |
| `@logging_revamped_status_off` | empty | glyph shown when the active pane is not logged |
| `@logging_revamped_toggle_key` | `P` | live-logging toggle key |
| `@logging_revamped_save_key` | `M-p` | save-scrollback key |
| `@logging_revamped_screenshot_key` | `M-P` | save-screen key |
| `@logging_revamped_label_key` | `M-n` | labelled-save key |
| `@logging_revamped_window_key` | `M-w` | log-whole-window key |
| `@logging_revamped_clear_key` | `M-c` | clear-history key |
| `@logging_revamped_tail_key` | `M-t` | live-tail key |
| `@logging_revamped_search_key` | `M-f` | search-logs key |
| `@logging_revamped_menu_key` | `M-m` | control-menu key |

Files are named `tmux-<session>-<window>-<pane>-<timestamp>.<kind>`, for example `tmux-main-1-0-20260622-1430.history`.

## Status line

Add a logging indicator to the status line. The glyph appears while the active
pane is being logged:

```tmux
set -g status-right "#{logging_status} %H:%M"
```

The same value is exported as the `@logging_status` option, so a theme can read
it directly. Run `prefix + M-m` for the control menu, which lists every action
including the keyless copy, compress, prune, and `doctor` commands.

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). It uses only `pipe-pane` and `capture-pane`, both core tmux commands.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

Filename building and path expansion live in [`src/lib/logging/logging.sh`](src/lib/logging/logging.sh) as pure functions, with the pane captures behind seams so the tests touch no real pane and write no real file.

## License

[MIT](LICENSE), copyright Gustavo Franco.
