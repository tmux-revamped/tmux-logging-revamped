# tmux-logging-revamped

Guidance for anyone, human or agent, changing tmux-logging-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-logging-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`logging-revamped.tmux`](logging-revamped.tmux) | The entry point TPM runs: it runs `bin/logging-revamped apply` |
| [`bin/logging-revamped`](bin/logging-revamped) | The command: `apply`, `list`, every action, `doctor`, `version`, `help` and the menu. `apply` and the actions run without loading the interface modules |
| [`lib/logging.sh`](lib/logging.sh) | Reading the settings and the pane, the bindings, the status indicator, and every action |
| [`lib/state.sh`](lib/state.sh) | Every global, including `LOGGING_REVAMPED_SETTINGS`, the table of setting names and defaults, and the two tables of actions the keys and the menu are built from |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/logging.bats`](test/logging.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The library, the bindings and every command, against a stand-in tmux from [`test/logging_helpers.bash`](test/logging_helpers.bash) that expands a format from a file of variables |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with every action key, both prompts, the tail popup, the search picker and the menu pressed through a second tmux attached to it; both share [`test/server_helpers.bash`](test/server_helpers.bash) |
| [`screens/`](screens) | The tapes and the recording's tmux config, which sets the action keys the tapes press |

## Names

- Settings are the tmux options `@logging_revamped_<setting>` listed in `LOGGING_REVAMPED_SETTINGS`, the long options with dashes, such as `--retain-days`, and the environment variables `LOGGING_REVAMPED_<SETTING>`.
- The pane option `@logging_revamped_file` holds the file a logged pane writes to, and the global `@logging_revamped_prompt` and `@logging_revamped_search_pattern` carry a typed reply to the tool; all three are state, never settings.
- The placeholder is `#{logging_status}`.
- The version constant is `LOGGING_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.
- `label-reply`, `search-reply` and `pick` are commands a binding runs for itself; the help page leaves them out.

## Behaviour

- `apply` reads every setting and the pane with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends every binding in one tmux call. When that call fails, it sends each command alone, so one invalid key leaves the others bound and `apply` exits 1.
- The menu key is bound to `display-menu` itself, so opening the menu starts no process; each item runs the tool with its action.
- A key set to `off` or left empty binds nothing. Only the default menu key, `M-l`, is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it. Two actions set to one key bind it for the first and the clash is named.
- `#{logging_status}` in `status-left` or `status-right` becomes a `#{?pane_pipe,on,off}` format tmux draws itself, with a comma in either glyph escaped. A string without the placeholder is not written, so loading twice changes nothing.
- A setting `apply` got from the command line or the environment rides, as an option, on every binding; `LOGGING_REVAMPED_CARRIED` lists the ones that ride.
- Each action reads the settings and the pane once, then sends its tmux commands and its message in one call.
- The entry point clears every inherited `REVAMPED_` variable except the test switches, and every `LOGGING_REVAMPED_*_LOADED` guard; every other global is assigned outright in the state file.

## Domain rules

- A file is named `tmux-<session>-<window>-<pane>-<stamp>[-<label>].<kind>`, each part with every character outside letters, digits, `.`, `_` and `-` written as `-`, built by one `awk` call for one pane or for every pane of a window. A rolling log is `tmux-<session>-session.log`.
- A live log is `pipe-pane` running `umask 077; exec cat >>` into the file. The file is quoted for `sh`, and every `#` is doubled, since `pipe-pane` expands formats.
- A save is `capture-pane` through `sed`, which strips trailing blanks, into a temporary file beside the target, then `mv -f`. It never replaces a file: a name that exists takes `-2` to `-99` before its extension.
- With output only, lines matching `@logging_revamped_prompt_pattern` are dropped first; the default pattern is a line that starts with `#`, `$`, `%` or `>`.
- A prompt reply reaches the tool through `@logging_revamped_prompt` with `%%%`, so quotes and `#()` in it reach neither a shell nor a format, and it is read once and unset.
- A popup's command carries no `#`: the tool's path and the tailed file are single-quoted with each `#` written as `"$(printf '%b' '\0043')"`. Inside the menu, where the command sits in a tmux string, backslashes, double quotes and dollars are escaped once more.
- The tail popup runs `tail -f` under `exec sh -c` with a trap that exits 0 on an interrupt. A popup whose command dies from Ctrl-C hands the signal number to `tmux display-popup` as its status, the tool returns it, and the key's `run-shell` then puts `returned 2` over the pane in view mode.
- Logs are found with the glob `tmux-*` in the log folder, and a name with any character a log never has is skipped. Their times come from one `stat` call, `-c '%Y %n'` first and `-f '%m %N'` where `stat` is BSD's.
- Search runs `grep -n` on the plain logs by name, from inside the folder, with `/dev/null` added so a single file still prints its name. It uses neither `-r` nor `-I`, which BusyBox lacks, and never reads a `.gz`.
- A log a pane is writing, read from every pane's `pane_pipe` and `@logging_revamped_file` in one `list-panes` call, is never compressed or pruned. `compress` and `prune` each run their tool once for every file.
- `prune` takes plain logs more than `@logging_revamped_retain_days` whole days old, then the oldest logs beyond `@logging_revamped_retain_max`, compressed ones included.
- The command list keeps an empty argument, which `display-menu` needs for an item with no key, as the marker in `LOGGING_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `LOGGING_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17, none.
