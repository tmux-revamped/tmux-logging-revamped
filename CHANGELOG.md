# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
