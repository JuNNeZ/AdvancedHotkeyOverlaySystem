# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-3.0.2-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, with dedicated support for Blizzard bars, AzeriteUI, Bartender4, Dominos, DiabolicUI, LUI and Neuron.

## Version 3.0.2 Highlights

- When the hotkey text shows: fade it out of combat, show it only on mouseover per bar or while a modifier is held, or write a Lua condition of your own. A different colour and size in combat, and a flash or pulse when you press a button.
- `/ahos edit`: drag the hotkey text into place on your own bars; Shift-drag moves one bar. Bars can also have a place of their own.
- Presets and Tank, Healer and Damage templates, snapshots with `/ahos rollback`, `/ahos profile <name>`, and switching profile by specialization or talent loadout.
- Shadow colour, glow and a background plate; mouse button icons; both keys on a button with two; Follow Masque Skin.
- LUI and Neuron support; Russian, Ukrainian, Korean and Taiwanese keyboards, with their letters drawn in the game's own fonts on any client.
- Sharp new switches and sliders, Keycap Gold as the default theme, and the classic Ace3 window removed.

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
