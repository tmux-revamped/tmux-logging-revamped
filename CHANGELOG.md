# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-30

### Added

- Status indicator. `#{logging_status}` shows a glyph while the active pane is
  being logged, also exported as `@logging_status` for a theme to read.
- Live tail. Follow the file the current pane is logging to in a popup, without
  leaving the pane.
- Search saved logs. Grep across the log directory, pick a match in fzf, and
  open it at the matching line.
- Clear pane history, the one upstream action that was missing.
- Log the whole window. Start logging every pane in the current window at once.
- Labelled captures. Prompt for a note that is folded into the filename.
- Rolling session log. Append live logging to one growing file per session via
  `@logging_revamped_rolling`.
- Output-only capture. Drop prompt and command-echo lines for clean bug reports
  via `@logging_revamped_output_only`, with a configurable prompt pattern.
- Retention prune. Delete logs older than `@logging_revamped_retain_days` and
  trim the directory to `@logging_revamped_retain_max` newest files.
- Compress logs with gzip and copy the newest log to the terminal clipboard.
- A control menu for discoverability and a `doctor` capability report covering
  path writability and the optional tools each action needs.

## [1.1.0] - 2026-06-23

### Added

- Saved scrollback and screenshots now trim trailing whitespace from every
  line, so logs no longer carry a ragged right edge (upstream tmux-logging #43).

### Changed

- Reviewed the upstream `tmux-plugins/tmux-logging` issues. Session and window
  names with spaces are already sanitized into safe filenames (#65), the log
  path is configurable via `@logging_revamped_path` (#62), and ANSI escapes are
  filtered out by default with color as an opt-in (#67).

## [1.0.0] - 2026-06-22

### Added

- Toggle live logging of the active pane to a file via prefix + P.
- Save the full scrollback (prefix + M-p) or the visible screen (prefix + M-P).
- Safe filenames built from session, window, pane, and timestamp, every
  component sanitized so slashes and spaces never break the path.
- Configurable log directory, optional ANSI color retention, and configurable
  keys. No background process and no temp files.
