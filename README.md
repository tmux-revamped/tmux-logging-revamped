<div align="center">

# tmux-logging-revamped

<strong>Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![family](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/family.yml?branch=main&style=flat-square&label=family)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/family.yml)
[![tests](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#what-it-does">What it does</a> |
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#key-bindings">Key bindings</a> |
  <a href="#how-it-works">How it works</a>
</p>

</div>

**12** menu actions, **19** options, **1** key bound by default, tmux **3.2** or later.

---

## What it does

The plugin writes a tmux pane to a file in three ways: a live log that grows as output arrives, the full scrollback at once, or the visible screen. It can also follow, search, copy, compress and prune those files.

| Action | What it does |
|:-------|:-------------|
| Toggle live log | Starts or stops piping the active pane to a file with `pipe-pane` |
| Save scrollback | Writes the whole pane history to a `.history` file |
| Save screen | Writes the visible screen to a `.screen` file |
| Labelled save | Asks for a label, adds it to the file name, and saves the scrollback |
| Log whole window | Starts a live log for every pane in the current window |
| Clear history | Clears the active pane's scrollback |
| Live tail | Follows the active pane's live log with `tail -f` in a popup |
| Search logs | Greps the log directory, lets you pick a match in fzf, and opens it at that line in the pager |
| Copy last log | Loads the newest uncompressed log into a tmux buffer and the terminal clipboard |
| Compress logs | Runs `gzip` on every log that no pane is still writing to |
| Prune old logs | Deletes logs by age or by count, as the retention options set |
| Doctor | Shows the platform, the log path, whether it is writable, the mode options and which tools are found |

Every file name is built from the session, window and pane, a `YYYYmmdd-HHMMSS` timestamp and the kind, such as `tmux-main-1-0-20260622-143005.history`. Each part is reduced to letters, digits, `.`, `_` and `-`, so a session named `feature/login` stays inside the log directory.

## Requirements

| Requirement | Version |
|:------------|:--------|
| tmux | 3.2 or later |
| bash | 3.2 or later |
| fzf | any, only for search |
| gzip | any, only for compress |
| less | any, the default pager for search |

It runs on Linux and macOS with BSD, GNU or uutils coreutils. Live tail, search and doctor open in `display-popup`, and copy uses `load-buffer -w`; both need tmux 3.2.

## Installation

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

## Usage

Press `prefix + M-l` to open the logging menu. It lists all 12 actions.

Give the actions you use most a direct key, and show a marker in the status line while the active pane is logged:

```tmux
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_tail_key 'M-t'

set -g @logging_revamped_status_on 'REC'
set -g status-right '#{logging_status} %H:%M'
```

Keep logs for two weeks at most, and save scrollback without prompt lines:

```tmux
set -g @logging_revamped_path '~/logs/tmux'
set -g @logging_revamped_retain_days '14'
set -g @logging_revamped_output_only '1'
```

Pruning runs only when you pick "Prune old logs" from the menu.

## Configuration

### Behaviour

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@logging_revamped_path` | `~/.tmux/logs` | Directory for every file; created with mode 700 when first needed |
| `@logging_revamped_color` | `0` | `1` keeps the ANSI color sequences in saved scrollback and screens |
| `@logging_revamped_rolling` | `0` | `1` makes the live log append to one `tmux-<session>-session.log` per session |
| `@logging_revamped_output_only` | `0` | `1` drops lines matching the prompt pattern from saved scrollback and screens |
| `@logging_revamped_prompt_pattern` | `^[[:space:]]*[#$%>] ` | Extended regex for the lines that output-only mode drops |
| `@logging_revamped_retain_days` | `0` | Above `0`, prune deletes uncompressed logs older than this many days |
| `@logging_revamped_retain_max` | `0` | Above `0`, prune keeps only this many of the newest logs |
| `@logging_revamped_pager` | `less` | Pager a search match opens in, called as `<pager> +<line> -- <file>` |
| `@logging_revamped_status_on` | `*` | Text `#{logging_status}` shows while the active pane is logged |
| `@logging_revamped_status_off` | empty | Text `#{logging_status}` shows otherwise |

### Keys

Each key option takes a tmux key name. An empty value or `off` binds nothing.

| Option | Default | Action |
|:-------|:--------|:-------|
| `@logging_revamped_menu_key` | `M-l` | Logging menu |
| `@logging_revamped_toggle_key` | empty | Toggle live log |
| `@logging_revamped_save_key` | empty | Save scrollback |
| `@logging_revamped_screenshot_key` | empty | Save screen |
| `@logging_revamped_label_key` | empty | Labelled save |
| `@logging_revamped_window_key` | empty | Log whole window |
| `@logging_revamped_clear_key` | empty | Clear history |
| `@logging_revamped_tail_key` | empty | Live tail |
| `@logging_revamped_search_key` | empty | Search logs |

Copy, compress, prune and doctor have no key option and are reached from the menu.

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@logging_revamped_file_<pane>` | The file a live-logged pane writes to, keyed by its pane id with every character other than a letter or digit replaced by `_`, such as `_3` for `%3` |
| `@logging_revamped_search_pattern` | The search pattern, handed from the search prompt to the picker popup |
| `@logging_revamped_prompt` | The text typed at the label or search prompt, read once and then unset |
| `@logging_status` | The current status text, written only when `src/logging.sh status` runs; the status line does not read it |

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-l` | Logging menu | Bound |
| `@logging_revamped_<action>_key` | The action named in the key table | Unbound |

Version 2.0.0 moved the menu from `M-m` to `M-l` and unbound every other key. To restore the old layout:

```tmux
set -g @logging_revamped_menu_key 'M-m'
set -g @logging_revamped_toggle_key 'P'
set -g @logging_revamped_save_key 'M-p'
set -g @logging_revamped_screenshot_key 'M-P'
set -g @logging_revamped_label_key 'M-n'
set -g @logging_revamped_window_key 'M-w'
set -g @logging_revamped_clear_key 'M-c'
set -g @logging_revamped_tail_key 'M-t'
set -g @logging_revamped_search_key 'M-f'
```

## How it works

[`logging-revamped.tmux`](logging-revamped.tmux) runs once when tmux loads the plugin. It binds each configured key to `run-shell` with [`src/logging.sh`](src/logging.sh) and the action name, so nothing runs until you press a key.

It also replaces `#{logging_status}` in `status-left` and `status-right` with a `#{?pane_pipe,on,off}` format built from the two status options. tmux draws that format itself, so the indicator starts no process on each redraw. Set the status options before the plugin loads, or reload the config after changing them.

A live log is `pipe-pane` running `cat >>` into the file under umask 077. Scrollback and screen saves use `capture-pane` and strip trailing whitespace from every line. Label and search prompts pass the typed text through a plugin option with `%%%`, so quotes and `#()` in the reply reach neither a shell nor a format.

File naming, path expansion and the prune selection are pure functions in [`src/lib/logging/logging.sh`](src/lib/logging/logging.sh). The doctor report is in [`src/lib/logging/doctor.sh`](src/lib/logging/doctor.sh).

## Development

| Command | What it does |
|:--------|:-------------|
| `make test` | Runs the bats suite |
| `make lint` | Runs shellcheck on every shell file |
| `make coverage` | Measures line coverage with kcov on Linux and fails below 95% |

Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)

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
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **this plugin**, Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
