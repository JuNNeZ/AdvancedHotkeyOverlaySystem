# Advanced Hotkey Overlay System

Readable, styled hotkey text on every action bar, with a keyboard you can see, visibility rules, and drag-and-drop placement.

## What does this addon do?

AHOS replaces the hotkey text on your action buttons with text you style yourself: font, size, colour, outline, shadow, glow, a plate behind it, and where it sits on the button. It works on the default Blizzard bars and on AzeriteUI, Bartender4, Dominos, DiabolicUI, LUI and Neuron, and steps aside when ElvUI is loaded.

It runs on Retail, WoW Forever and Classic.

## New in 3.0

- **A new options window** in AHOS's own keycap art, with a page rail, a search box across every setting, and one-click revert on anything you changed. Your real bars light up when you change a setting.
- **See your binds on a keyboard.** The Abbreviations page is a full keyboard and mouse. Keys you have bound light up, and Shift, Ctrl and Alt show their layer. Click a key to set its abbreviation, or to bind and unbind it right there.
- **Controller support** for Xbox, PlayStation, Nintendo Switch Pro, Steam Deck and Steam Controller, each drawn as the pad you have. Gamepad buttons show as their real button icons on your bars.
- **Visibility rules**: fade the text out of combat, show it only on mouseover per bar or while a modifier is held, or write a Lua condition of your own.
- **`/ahos edit`**: drag the hotkey text into place on your own bars. Shift-drag moves a single bar.
- **Presets and templates**: Blizzard Style, Big and Centered, Bottom Corner, Compact, plus Tank, Healer and Damage. Snapshots are taken automatically, and `/ahos rollback` takes you back.
- **Inspector**: point at any action button to see which bar addon drew it, the key that presses it, and why AHOS shows the text it does.

## Features

### Looks

- Font, size, colour, outline, shadow colour and offset, and glow
- A background plate behind the text
- Colour by modifier: Shift, Ctrl and Alt bindings each get their own colour
- A combat style, and a flash or pulse when you press a button
- Mouse button icons, and both keys on a button bound to two
- Follow Masque Skin: the text goes where your Masque skin puts the hotkey

### Placement

- Anchor on a 3×3 grid, with X and Y offsets
- Per bar: text size, show on mouseover, and a position of its own
- Drag and drop on your real bars with `/ahos edit`

### Abbreviations

- Every key can have its own abbreviation
- Keyboard layouts: English (US and UK), Danish, Norwegian, Swedish/Finnish, German, French, Russian, Ukrainian, Korean and Taiwanese
- Cyrillic, Korean and Chinese key names are drawn in the game's own fonts on any client

### Profiles

- Per-character and shared profiles, with import and export
- Switch profile by specialization or talent loadout
- `/ahos profile <name>` switches profile, making it if it does not exist yet

### Languages

The options window is in English, German, Spanish, French, Portuguese, Russian, Korean and Chinese (Simplified and Traditional).

## Slash Commands

- `/ahos` opens the options window
- `/ahos edit` drags the text into place on your bars
- `/ahos preset` applies a preset or template
- `/ahos profile <name>` and `/ahos profiles` switch and list profiles
- `/ahos snapshot` and `/ahos rollback` save and restore a copy of your profile
- `/ahos ignore <ButtonName>` leaves one button to its own hotkey text
- `/ahos inspect` shows how AHOS reads a button
- `/ahos toggle` turns the overlays on and off
- `/ahos lock` and `/ahos unlock` lock the settings
- `/ahos reset` resets the profile
- `/ahos help` lists every command

## Troubleshooting

**Overlays not showing?**

- Check that AHOS is on with `/ahos toggle`
- Run `/ahos refresh` to find your bars again
- Open the Status page in the options window to see which bar addons AHOS found and how many buttons it draws on

**A button shows the wrong text?**

- Open the Inspector page, click Pick a Button and point at it

**Wrong UI detected?**

- Run `/ahos detectui`

## Requirements

- World of Warcraft Retail, WoW Forever or Classic (current patches)
- All libraries are included

---

**Readable hotkeys that fit your UI, on any bar addon.**
