# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-22

### Added

- Toggle live logging of the active pane to a file via prefix + P.
- Save the full scrollback (prefix + M-p) or the visible screen (prefix + M-P).
- Safe filenames built from session, window, pane, and timestamp, every
  component sanitized so slashes and spaces never break the path.
- Configurable log directory, optional ANSI color retention, and configurable
  keys. No background process and no temp files.
