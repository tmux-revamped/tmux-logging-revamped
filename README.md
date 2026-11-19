<div align="center">

# tmux-logging-revamped

<strong>Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-logging-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-logging-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-logging-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-logging-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-logging-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-logging-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-logging-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="logging-revamped starting a live log from its menu, following it in a popup and saving the scrollback under a label" width="800">
</p>

```console
$ logging-revamped save before-deploy
$ ls ~/.tmux/logs
tmux-main-0-0-20261117-092106-before-deploy.history
```

The plugin writes a tmux pane to a file in three ways: a live log that grows as output arrives, the full scrollback at once, or the visible screen. It can also follow, search, copy, compress and prune those files.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor: popups, pane options and `%%%` in prompts |
| fzf | optional | picks a search match |
| gzip | optional | `compress` |
| a pager | optional | opens a search match; `less` by default |
| gum | optional | the menu, tables and colours of `logging-revamped`; without it every command prints plain text |

### Install

```tmux
set -g @plugin 'tmux-revamped/tmux-logging-revamped'
```

Then press `prefix + I`. Without TPM, clone the repository and run its entry point from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-logging-revamped ~/.tmux/plugins/tmux-logging-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-logging-revamped/logging-revamped.tmux
```

`make install` in the clone also puts `logging-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-logging-revamped/bin/logging-revamped doctor
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

Pruning never runs by itself: pick "Prune old logs" from the menu or run `logging-revamped prune`.

| Command | What it does |
|:--------|:-------------|
| `logging-revamped apply` | Binds the keys and the status indicator now; the entry point runs it when tmux loads the plugin |
| `logging-revamped list` | Prints every command `apply` would send and changes nothing; `--json` prints one object |
| `logging-revamped toggle` | Starts or stops piping the active pane to a file with `pipe-pane` |
| `logging-revamped save [LABEL]` | Writes the whole pane history to a `.history` file |
| `logging-revamped screenshot [LABEL]` | Writes the visible screen to a `.screen` file |
| `logging-revamped label` | Asks for a label, adds it to the file name, and saves the scrollback |
| `logging-revamped window` | Starts a live log for every pane in the current window |
| `logging-revamped clear` | Clears the active pane's scrollback |
| `logging-revamped tail` | Follows the active pane's live log with `tail -f` in a popup |
| `logging-revamped search [PATTERN]` | Greps the log directory, lets you pick a match in fzf, and opens it at that line in the pager |
| `logging-revamped copy` | Loads the newest uncompressed log into a tmux buffer and the terminal clipboard |
| `logging-revamped compress` | Runs `gzip` on every log that no pane is still writing to |
| `logging-revamped prune` | Deletes logs by age or by count, as the retention options set |
| `logging-revamped status` | Prints the indicator text for this pane |
| `logging-revamped doctor` | One row per dependency: the log folder, gzip, fzf and any key left alone |
| `logging-revamped version` | The version, then the tmux version |
| `logging-revamped help` | The help page; `man logging-revamped` documents the same commands and settings |
| `logging-revamped` | On a terminal, a menu |

Every file name is built from the session, window and pane, a `YYYYmmdd-HHMMSS` timestamp and the kind, such as `tmux-main-1-0-20260622-143005.history`. Each part is reduced to letters, digits, `.`, `_` and `-`, so a session named `feature/login` stays inside the log directory.

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

Every option is also a command option with dashes, such as `--path ~/logs`, and an environment variable, such as `LOGGING_REVAMPED_PATH`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. `doctor` names any setting that holds a value the plugin does not know. One given to `apply` rides on every binding.

The plugin writes three options itself: the pane option `@logging_revamped_file`, the file a logged pane writes to, and the global `@logging_revamped_prompt` and `@logging_revamped_search_pattern`, which carry a typed reply to the tool.

<a id="how-it-works"></a>

## How it works

[`logging-revamped.tmux`](logging-revamped.tmux) runs `bin/logging-revamped apply` once when tmux loads the plugin. It binds each configured key to `run-shell` with the tool and the action name, and the menu key to the menu itself, in one tmux call, so nothing runs until you press a key.

It also replaces `#{logging_status}` in `status-left` and `status-right` with a `#{?pane_pipe,on,off}` format built from the two status options. tmux draws that format itself, so the indicator starts no process on each redraw. Set the status options before the plugin loads, or reload the config after changing them.

A live log is `pipe-pane` running `cat >>` into the file under umask 077. Scrollback and screen saves use `capture-pane` and strip trailing whitespace from every line. Label and search prompts pass the typed text through a plugin option with `%%%`, so quotes and `#()` in the reply reach neither a shell nor a format.

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/logging-menu.png" alt="logging-revamped: prefix M-l opens the logging menu"><br><sub><code>prefix M-l</code> opens the logging menu, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/live.png" alt="logging-revamped: A live log starts and the status line says so"><br><sub>A live log starts and the status line says so, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/tail.png" alt="logging-revamped: prefix M-t follows the live log in a popup"><br><sub><code>prefix M-t</code> follows the live log in a popup, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/saved.png" alt="logging-revamped: save writes the scrollback under a label"><br><sub><code>save</code> writes the scrollback under a label, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="logging-revamped: The menu"><br><sub>The menu, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="logging-revamped: doctor"><br><sub><code>doctor</code>, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/label.png" alt="logging-revamped: The label key asks for a label"><br><sub>The label key asks for a label, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/search.png" alt="logging-revamped: The search key offers every match"><br><sub>The search key offers every match, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/match.png" alt="logging-revamped: The chosen match opens in the pager at its line"><br><sub>The chosen match opens in the pager at its line, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/window.png" alt="logging-revamped: The window key logs every pane"><br><sub>The window key logs every pane, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/screenshot.png" alt="logging-revamped: Save screen, from the menu"><br><sub>Save screen, from the menu, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clear.png" alt="logging-revamped: Clear history, from the menu"><br><sub>Clear history, from the menu, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="logging-revamped: Copy last log, from the menu"><br><sub>Copy last log, from the menu, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/compress.png" alt="logging-revamped: Compress logs, from the menu"><br><sub>Compress logs, from the menu, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/prune.png" alt="logging-revamped: Prune old logs, from the menu"><br><sub>Prune old logs, from the menu, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="logging-revamped: list prints every binding"><br><sub><code>list</code> prints every binding, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="logging-revamped: status"><br><sub><code>status</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="logging-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="logging-revamped: doctor from the menu"><br><sub><code>doctor</code> from the menu, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="logging-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="logging-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="logging-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="logging-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="logging-revamped: An accent from LOGGING_REVAMPED_ACCENT"><br><sub>An accent from <code>LOGGING_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

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
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | **this plugin**, Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
