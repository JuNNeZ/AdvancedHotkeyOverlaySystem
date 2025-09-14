# Advanced Hotkey Overlay System (AHOS)

![Version](https://img.shields.io/badge/version-2.5.1-cyan)

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

2.5.1
- Retail (AzeriteUI): Removed placeholder square/bullet on unbound buttons; safer native label suppression with deep-scan.
- Classic: Fixed invalid event registration by gating Retail-only events.
- Dominos: Overlays show immediately without reload; native labels remain hidden after binding mode.
- Overlay layering: Frame level bump above nested overlay containers; better with Masque/AzeriteUI.

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
