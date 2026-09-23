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

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **this plugin**, Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
