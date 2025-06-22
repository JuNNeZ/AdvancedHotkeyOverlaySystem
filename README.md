# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-2.1.0-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

## Version 2.1.0 Highlights

- Minor bug fixes and performance improvements
- Improved support for new Blizzard action bar features
- See [CHANGELOG.md](CHANGELOG.md) for full details

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
