# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-3.1.1-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, with dedicated support for Blizzard bars, AzeriteUI, Bartender4, Dominos, DiabolicUI, LUI, Neuron, MelloUI, EllesmereUI, SpartanUI, DaylightUI, ForeverUI, NDui, GW2 UI and ElvUI.

## Version 3.1.1 Highlights

- AHOS batches action-slot updates and groups related bar events during changes such as Druid shapeshifting on WoW Forever. This reduces repeated overlay work while the action bars settle.

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
