# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-06-22

### Added

- Themed enable message with color-coded branding and version.
- Debug messages now only appear when debug mode is enabled.
- Improved overlay removal and Blizzard hotkey text restoration logic.
- Consistent debug/info/error print handling across all modules.

### Changed

- Minimap icon logic and event handling improved for reliability.
- Codebase refactored for maintainability and extensibility.

### Fixed

- Debug messages no longer spam chat in normal mode.
- Overlay and hotkey text restoration now works as expected on disable and minimap toggle.

---

## [2.0.0-alpha] - 2025-06-22

### Major Overhaul

- Complete rewrite and modularization of the codebase for maintainability and extensibility.
- Robust event-driven overlay update logic restored and improved.
- ConsolePort-style keybind abbreviation logic: condensed, customizable separator, gamepad/mouse support.
- Overlay frame strata control and improved minimap icon handling.
- Options panel fully revamped: professional About/Credits, version display, and live UI detection.
- All taint, nil, and registration errors eliminated.
- Standardized AceConfig registration and config panel references.
- Added user option for modifier separator in abbreviations.
- Improved debug output and troubleshooting tools.
- Full support for Blizzard, AzeriteUI, and custom action bars.
- Titan Panel integration removed for simplicity; minimap icon is now the sole launcher.

### Fixed

- Modifier parsing and abbreviation bugs.
- Overlay update and taint issues.
- Nil and registration errors.
- Keybinding detection for all supported UIs.

---

## [1.0.0] - 2024-XX-XX

### Added

- Initial release of Advanced Hotkey Overlay System (AHOS).
- Basic overlay system for Blizzard action bars.
- Simple keybind abbreviation logic.
- Minimap icon and options panel access.

---
