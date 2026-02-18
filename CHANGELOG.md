# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.6] - 2025-11-08

### Fixed (2.5.6)

- Critical fix for overlay disappearance during dragonriding mount transitions affecting secondary action bars.
- Resolved issue where OverrideActionBar activation caused MultiBar button overlays to be cleared and not recreated.
- Fixed visibility state evaluation to preserve existing overlays during action bar page changes and vehicle/mount transitions.
- Corrected overlay lifecycle management to prevent unnecessary destruction and recreation during bar state changes.

### Changed (2.5.6)

- Refactored overlay update pipeline to preserve existing overlay frames during bar transitions.
- Enhanced visibility check logic to differentiate between new overlay creation and existing overlay updates.
- Improved overlay cleanup to only remove overlays for truly removed buttons, not temporarily hidden ones.
- Optimized UpdateAllOverlays to eliminate full overlay clearing on bar events (UPDATE_SHAPESHIFT_FORM, ACTIONBAR_PAGE_CHANGED).

## [2.5.5] - 2025-11-07

### Fixed (2.5.5)

- Resolved overlay persistence issue affecting secondary action bars (MultiBar) during combat mount transitions.
- Fixed visibility state detection logic to preserve overlays during temporary parent frame state changes.
- Corrected differential behavior between primary ActionBar and MultiBar frame hierarchies.
- Improved combat-aware visibility validation with frame existence checking.

### Changed (2.5.5)

- Refactored button visibility evaluation in overlay update pipeline to distinguish combat and non-combat states.
- Enhanced overlay rendering to maintain frame integrity during shapeshifting and mount form changes.
- Optimized visibility check bypass mechanism for active overlays in combat lockdown scenarios.

## [2.5.4] - 2025-11-07

### Fixed (2.5.4)

- Critical fix for overlay persistence during combat lockdown transitions.
- Resolved issue where overlays could disappear and remain hidden after combat events.
- Improved animation ticker lifecycle management with proper cleanup on combat state changes.
- Enhanced overlay restoration queue to defer frame manipulation until combat lockdown ends.
- Fixed race condition in visual effect system that could interfere with combat-sensitive frame updates.

### Changed (2.5.4)

- Refactored temporal animation system to register combat state monitoring.
- Added automatic cancellation of active animation timers when entering combat.
- Implemented deferred restoration pattern for overlay state recovery post-combat.

## [2.5.3] - 2025-11-07

### Added (2.5.3)

- Advanced visual overlay transformation engine with HSV color space support for enhanced rendering pipeline.
- Dynamic text manipulation system with per-frame interpolation for improved responsiveness.
- Extended slash command handler with enhanced debug output routing and chat window separation logic.

### Changed (2.5.3)

- Refactored debug logging system: introduced dedicated `DebugPrint` method for internal diagnostics, separating debug output from user-facing messages.
- Optimized overlay frame lifecycle management with improved state restoration callbacks.
- Enhanced temporal effect scheduling with precision timer management for overlay animations.

### Fixed (2.5.3)

- Resolved chat window spam from debug messages by routing internal diagnostics to debug log window exclusively.
- Improved overlay state persistence during combat lockdown transitions.
- Fixed overlay text color restoration after transient visual effects.

## [2.4.2] - 2025-09-03

## [2.5.0] - 2025-09-14

## [2.5.1] - 2025-09-14

### Added (2.5.1)

- Deep scan for nested hotkey FontStrings (e.g., AzeriteUI TextOverlayContainer) to ensure reliable detection and suppression.
- New debug commands: `/ahos dumphotkey` and `/ahos dumplayers` for targeted troubleshooting.

### Changed (2.5.1)

- Overlay frame level bump to render above nested overlay containers and Masque/AzeriteUI skins.
- Refined native hotkey suppression hooks with safer Show/SetText guards.

### Fixed (2.5.1)

- Classic: Register `PLAYER_BINDING_CHANGED` on Retail only to prevent errors on Classic.
- Retail (AzeriteUI): Removed placeholder square/bullet glyphs on unbound buttons by disabling visual fallback on Retail and filtering fallback glyphs in the visual reader.
- Dominos: Improved overlay visibility without requiring reload; ensured native labels stay hidden when Dominos keybinding mode ends.

## [2.5.2] - 2025-09-14

### Added (2.5.2)

- Options: Font outline styles (NONE/OUTLINE/THICKOUTLINE/MONOCHROME combos) with legacy fallback retained.

### Fixed (2.5.2)

- Classic: Avoid registering PLAYER_BINDING_CHANGED; gate the event to Retail only using WOW_PROJECT_ID with build fallback.

### Added

- Retail + Classic compatibility in one build; Classic-safe keybinding resolution for ActionButton, BonusActionButton, MultiBars, Stance, Pet, and Possess.
- Hooks to ActionButton_UpdateHotkeys and MultiActionBar_Update to keep native labels hidden while overlays are active.

### Changed

- Multiple delayed overlay refreshes after binding changes (Dominos/LibKeyBound) to avoid reload requirements.
- Simplified in-game settings UI by removing unused modules; retained single JUI module.

### Fixed

- Dominos keybinding mode no longer causes native hotkey text to reappear until reload on Classic.

### Fixed (2.4.2)

- Prevent duplicate Blizzard options category registration by stabilizing app name and checking existing entries.
- Avoid hard errors if AceConfigDialog loads late; /ahos always registers.

### Added (2.4.2)

- Embedded AceGUI-3.0 and wired AceConfig-3.0 Dialog when embedded libs are present.
- /ahos version command.

### Changed (2.4.2)

- Options/About panels now read Version from TOC metadata; removed hardcoded version strings.
- Clarified IconTexture path to media/logo.tga.

## [2.4.1] - 2025-06-24

### Added (2.4.1)

- Debug log window and `/ahoslog` command for viewing/copying all debug output.
- `/ahos inspect <ButtonName>` command to print debug info for any action button.
- Advanced profile management: export/import, auto-switch by spec, copy/reset, and print profile tools in the Profiles Management tab.

### Changed (2.4.1)

- Updated documentation and versioning for 2.4.1.
- Polished options panel and help sections for new features.

## [2.4.0] - 2025-06-24

### Added (2.4.0)

- In-game changelog and version info tab
- Debug export window and /ahos debugexport command
- LibSerialize/LibDeflate support for profile export
- Help & Debugging tab in options

### Changed (2.4.0)

- Updated documentation and versioning for 2.4.0
- Many bugfixes and polish

## [2.3.0] - 2025-06-23

### Modernization & Polish

- Modernized and cleaned up all options panel registration and naming logic
- No more color codes or icons in the options panel or .toc metadata
- Only one options panel is registered, with robust error handling
- Minimap/DataBroker icon and Blizzard options panel now always show the correct, user-friendly name
- ElvUI compatibility and user prompt logic improved
- Legacy and duplicate code removed for reliability
- All overlays and minimap icon logic now robust and error-free

## [2.2.0] - 2025-06-22

### Added (2.2.0)

- Full Ace3 profile management UI (copy, delete, switch, robust handling).
- Overlay settings (font, color, etc.) now update instantly on profile or option changes.
- Lock/unlock feature: `/ahos lock` greys out all options and prevents changes; attempting to change settings while locked shows a high-strata popup with unlock prompt.
- StaticPopup dialog for unlocking settings, with Yes/No options.
- Debug-only button to delete all profiles except the current one.

### Changed (2.2.0)

- Only Ace3 profile management UI is used (custom profile UI removed).
- Improved error handling for profile changes and minimap icon registration.
- Versioning and documentation updated for 2.2.0.

### Fixed (2.2.0)

- No more duplicate options panel errors.
- Profile deletion and switching is now robust and bug-free.
- Minimap icon unregister errors resolved.
- Settings lock now actually prevents changes in the options panel.

---

## [2.1.0] - 2025-06-22

### Added (2.1.0)

- Themed enable message with color-coded branding and version.
- Debug messages now only appear when debug mode is enabled.
- Improved overlay removal and Blizzard hotkey text restoration logic.
- Consistent debug/info/error print handling across all modules.

### Changed (2.1.0)

- Minimap icon logic and event handling improved for reliability.
- Codebase refactored for maintainability and extensibility.

### Fixed (2.1.0)

- Debug messages no longer spam chat in normal mode.
- Overlay and hotkey text restoration now works as expected on disable and minimap toggle.

---

## 2.0.0-alpha - 2025-06-22

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

### Fixed (2.0.0-alpha)

- Modifier parsing and abbreviation bugs.
- Overlay update and taint issues.
- Nil and registration errors.
- Keybinding detection for all supported UIs.

---

## 1.0.0 - 2024-06-17

### Added (1.0.0)

- Initial release of Advanced Hotkey Overlay System (AHOS).
- Basic overlay system for Blizzard action bars.
- Simple keybind abbreviation logic.
- Minimap icon and options panel access.

---

[2.4.1]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.1
[2.4.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.0
[2.3.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.3.0
[2.2.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.2.0
[2.1.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.1.0
[2.4.2]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.2
[2.5.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.0
[2.5.1]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.1
[2.5.2]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.2
