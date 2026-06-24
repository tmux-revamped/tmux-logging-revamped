<div align="center">

<h1>tmux-logging-revamped</h1>

**Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot.**

[![Tests](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)

</div>

**3** actions · **safe filenames** · **tmux 1.9 to 3.5** · **38** tests · **95%+** coverage

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

All three keys are configurable.

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
| `@logging_revamped_toggle_key` | `P` | live-logging toggle key |
| `@logging_revamped_save_key` | `M-p` | save-scrollback key |
| `@logging_revamped_screenshot_key` | `M-P` | save-screen key |

Files are named `tmux-<session>-<window>-<pane>-<timestamp>.<kind>`, for example `tmux-main-1-0-20260622-1430.history`.

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
