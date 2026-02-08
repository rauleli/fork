# Changelog

All notable changes to this project will be documented in this file.

## [0.2] - 2026-02-08

### Added
- Signal handling via `::fork::listen_signals` (SIGTERM, SIGINT, SIGQUIT).
- Broadcast messaging to all children via `::fork::broadcast`.
- Background process monitoring via `::fork::monitor`.
- Library state statistics via `::fork::stats`.
- Comprehensive technical manual in `MANUAL.md`.
- Method `stats` to retrieve active children count.

### Changed
- Refactored internal cleaning logic for better reliability.
- Improved handle destruction cleanup.

## [0.1] - 2017-04-26

### Added
- Initial release with basic fork/pipe management.
- Object-oriented interface for process control.
- Event-driven message handling.
