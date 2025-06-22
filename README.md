# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-2.2.0-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

## Version 2.2.0 Highlights

- Full Ace3 profile management UI (copy, delete, switch, robust handling)
- Overlay settings (font, color, etc.) now update instantly on profile or option changes
- Lock/unlock feature: `/ahos lock` greys out all options and prevents changes; attempting to change settings while locked shows a high-strata popup with unlock prompt
- StaticPopup dialog for unlocking settings, with Yes/No options
- Debug-only button to delete all profiles except the current one
- Only Ace3 profile management UI is used (custom profile UI removed)
- Improved error handling for profile changes and minimap icon registration
- No more duplicate options panel errors
- Profile deletion and switching is now robust and bug-free
- Minimap icon unregister errors resolved
- Settings lock now actually prevents changes in the options panel

## Features

- ConsolePort-style keybind abbreviations (condensed, customizable separator, gamepad/mouse support)
- Minimap icon and options panel access
- Overlay frame strata control
- Modular, event-driven updates
- No taint, nil, or registration errors

## Installation

1. Download or clone this repository into your `Interface/AddOns` folder.
2. Restart World of Warcraft or reload your UI.

## Usage

- Overlays will appear automatically on supported action bars.
- Access the options panel via the minimap icon or `/ahos` slash command.
- Customize keybind abbreviation style and modifier separator in the options panel.

## Configuration

- All options are available in the in-game options panel (minimap icon or `/ahos`).
- Set your preferred modifier separator (or leave blank for condensed style).
- Adjust overlay frame strata and other display settings.

## Credits

- Inspired by ConsolePort (by Munk) and the WoW UI community.
- Built with Ace3 libraries.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes.
