# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-2.5.24-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, with dedicated support for Blizzard bars, AzeriteUI, Bartender4, Dominos, and DiabolicUI.

## Version 2.5.24 Highlights

- A new options window in AHOS's own keycap art: search across every setting, a mark and one-click revert on anything changed from its default, four themes, and a live preview of the hotkey text.
- The Abbreviations page is a keyboard: click a key to change its abbreviation and see what it is bound to, which spell and bar answer to it, and which addons claim it.
- ESC > Options > AddOns opens a landing page into the new window; `/ahos classic` keeps the previous Ace3 window.
- Fixed profile import, missing AceDBOptions-3.0, and fonts that did not load leaving hotkey text blank.

## Features

- Profile-specific keybind abbreviations with editable modifier, mouse, numpad, special-key, function-key, and gamepad mappings
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
- Customize every supported abbreviation and the modifier separator in the dedicated Abbreviations tab.
- Use `/ahoslog` to open the debug log window and view/copy all debug output.
- Use `/ahos inspect <ButtonName>` to print debug info for any action button.
- No reload needed after binding changes in Dominos (Classic).

## Configuration

- All options are available in the in-game options panel (minimap icon or `/ahos`).
- Set your preferred modifier separator (or leave blank for condensed style).
- Adjust overlay frame strata and other display settings.
- Manage profiles with advanced tools: export/import, auto-switch by spec, copy/reset, and more.

## Advanced Profile Management

- Export or import profiles using the options panel or `/ahos debugexport`.
- Auto-switch profiles by specialization.
- Copy, reset, or print profiles from the Profiles Management tab.

## Debugging & Tools

- Debug log window: `/ahoslog` (view/copy all debug output)
- Inspect any button: `/ahos inspect <ButtonName>`
- Export debug/profile data: `/ahos debugexport [tablepath]`
- Help & Debugging tab in options for more info

## Credits

- Inspired by ConsolePort (by Munk) and the WoW UI community.
- Built with Ace3 libraries.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes.
