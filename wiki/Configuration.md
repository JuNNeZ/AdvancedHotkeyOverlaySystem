# Configuration

This page is a complete reference for every AHOS setting, organized by category. It also explains the three display modes in depth so you can choose the right one for your setup.

---

## Table of Contents

- [Opening the Options Panel](#opening-the-options-panel)
- [Display Modes](#display-modes)
  - [Overlay Mode](#overlay-mode)
  - [Native Rewrite Mode](#native-rewrite-mode)
  - [Auto-Fallback Mode](#auto-fallback-mode)
  - [Dominos: Native Text Override](#dominos-native-text-override)
  - [Choosing the Right Mode](#choosing-the-right-mode)
- [Core / General](#core--general)
- [Display](#display)
  - [Placement and Edit Mode](#placement-and-edit-mode)
  - [Visibility](#visibility)
  - [In Combat](#in-combat)
  - [Effects](#effects)
- [Font / Appearance](#font--appearance)
  - [Shadow and Glow](#shadow-and-glow)
  - [Buttons with Two Keys](#buttons-with-two-keys)
- [Keybind / Abbreviations](#keybind--abbreviations)
- [Bars](#bars)
- [Profile Management](#profile-management)
  - [Presets](#presets)
  - [Snapshots](#snapshots)
- [Minimap](#minimap)
- [Compatibility](#compatibility)
- [Inspector](#inspector)
- [Troubleshooting Tools](#troubleshooting-tools)

---

## Opening the Options Panel

There are three ways to open the AHOS settings:

- Type `/ahos` in the chat box
- Left-click the minimap icon
- Navigate to **Interface → AddOns → Advanced Hotkey Overlay System** in the Blizzard options

---

## Display Modes

AHOS offers three distinct modes for how it writes hotkey text onto your buttons. Understanding the difference is crucial if your overlays aren't appearing correctly with your UI skin.

### Overlay Mode

> **Default mode. Recommended for most users.**

AHOS creates a new, independent `FontString` frame and places it above each action button. The button's native `HotKey` element is untouched (though it can optionally be hidden via **Hide Original Hotkey Text**).

**Pros:**
- Completely non-destructive — the button itself is not modified
- Full control over position, scale, strata, and level
- Works across all supported addon providers

**Cons:**
- Some UI skins (e.g., ElvUI's skin engine) may clip or hide external frames placed on top of buttons, causing overlays to be invisible

**When to use:** The default. Use this unless you have a specific issue with visibility.

---

### Native Rewrite Mode

> Enable via: **Use Native Text** toggle (or **Dominos: Use Native Text** for Dominos specifically)

Instead of creating a new frame, AHOS takes over the button's built-in `HotKey` FontString and rewrites its text and style directly.

**Pros:**
- Immune to frame-clipping issues — the text lives inside the button itself
- Respects the skin's own strata/level management
- Ideal when your UI skin hides foreign frames placed over buttons

**Cons:**
- Slightly less positioning flexibility (the text lives where the native HotKey lives)
- When AHOS is disabled or unloaded, the native HotKey reverts to Blizzard defaults

**When to use:** When you see no overlays in Overlay Mode and suspect your skin is hiding them. Also ideal for users who prefer a zero-added-frames approach.

---

### Auto-Fallback Mode

> Enable via: **Auto Fallback to Native** toggle

AHOS starts in Overlay Mode. After each update cycle, it checks whether the overlay FontString is actually visible. If it detects the overlay is hidden (alpha is 0, parent is hidden, or the frame is off-screen), it automatically switches that button to Native Rewrite Mode.

**Pros:**
- Best of both worlds — tries Overlay first, falls back gracefully
- No manual mode-switching needed when mixing skinned and unskinned bars

**Cons:**
- The detection check adds a small amount of overhead per button per update cycle
- There can be a one-frame flicker on first login while the fallback triggers

**When to use:** When you have a mixed UI (some bars skinned, some not) or you're unsure which mode fits your setup.

---

### Dominos: Native Text Override

> Enable via: **Dominos: Use Native Text** toggle

A Dominos-specific variant of Native Rewrite Mode. Dominos manages its own keybind text via a separate system. This toggle integrates AHOS into that system, ensuring abbreviations are applied through Dominos' own keybind text pipeline rather than drawing on top of it.

**When to use:** Dominos users experiencing double-text or misaligned overlays.

---

### Choosing the Right Mode

| Your Setup | Recommended Mode |
|---|---|
| Default Blizzard UI | Overlay Mode |
| Dominos (no skin) | Overlay Mode or Dominos Native Text |
| Bartender4 (no skin) | Overlay Mode |
| ElvUI (with ElvUI skin) | Enable ElvUI Compatibility → Native Rewrite |
| Any heavily skinned UI | Native Rewrite or Auto-Fallback |
| Mixed skinned/unskinned bars | Auto-Fallback |

---

## Core / General

| Option | Type | Description |
|---|---|---|
| **Enable Addon** | Toggle | Master switch. Turning this off disables all overlays and hides the minimap icon. Equivalent to `/ahos toggle`. |
| **Auto-Detect UI** | Toggle | When enabled, AHOS scans for supported action bar addons on login and configures itself automatically. Disable if you want to pin a specific provider manually. |
| **Debug Mode** | Toggle | Prints verbose internal messages to the chat frame. Useful for diagnosing why a specific button isn't getting an overlay. See also `/ahos debug`. |
| **Lock Settings** | Toggle | Prevents accidental changes in the options panel. Use `/ahos lock` and `/ahos unlock` as an alternative. |

---

## Display

### Frame Layering

| Option | Type | Default | Description |
|---|---|---|---|
| **Smart Frame Layering** | Toggle | On | When enabled, overlay frames inherit the same frame strata as their parent button, ensuring they always appear above the button regardless of strata. Recommended to leave on. |
| **Overlay Frame Strata** | Dropdown | MEDIUM | Manually set the frame strata for overlays. Only relevant when Smart Frame Layering is **off**. Options: BACKGROUND, LOW, MEDIUM, HIGH, DIALOG, TOOLTIP. |
| **Overlay Frame Level** | Slider | 10 | The sub-level within the chosen strata. Higher numbers appear above lower numbers within the same strata. Range: 1–128. |

### Position & Size

| Option | Type | Default | Description |
|---|---|---|---|
| **Anchor Point** | Dropdown | TOPLEFT | Which corner/edge of the button the overlay text is anchored to. Options: TOPLEFT, TOP, TOPRIGHT, LEFT, CENTER, RIGHT, BOTTOMLEFT, BOTTOM, BOTTOMRIGHT. |
| **X Offset** | Slider | 2 | Horizontal offset in pixels from the anchor point. Positive = right, negative = left. Range: -50 to +50. |
| **Y Offset** | Slider | -2 | Vertical offset in pixels from the anchor point. Positive = up, negative = down. Range: -50 to +50. |
| **Scale** | Slider | 1.0 | Multiplier applied to the overlay text size. 0.5 = half size, 2.0 = double size. Range: 0.1–2.0. |
| **Alpha** | Slider | 1.0 | Transparency of the overlay text. 1.0 = fully opaque, 0.0 = invisible. Range: 0–1. |

### Native & Fallback Options

| Option | Type | Default | Description |
|---|---|---|---|
| **Use Native Text** | Toggle | Off | Switch to Native Rewrite Mode for all supported providers. See [Native Rewrite Mode](#native-rewrite-mode). |
| **Dominos: Use Native Text** | Toggle | Off | Native Rewrite Mode specifically for Dominos buttons. See [Dominos: Native Text Override](#dominos-native-text-override). |
| **Auto Fallback to Native** | Toggle | Off | Enable Auto-Fallback Mode. See [Auto-Fallback Mode](#auto-fallback-mode). |
| **Hide Original Hotkey Text** | Toggle | On | Hides the button's default `HotKey` FontString so it doesn't overlap with the AHOS overlay. Disable this only if using Native Rewrite Mode or if you want both texts visible simultaneously. |
| **Mirror Native Hotkey Style** | Toggle | Off | When enabled, AHOS copies the native hotkey FontString's font face, color, and position rather than using your custom AHOS settings. Useful for ensuring the overlay matches your skin's default style. |

---

### Follow Masque Skin

With Masque loaded, **Follow Masque Skin** (Display page, off by default) puts the hotkey text on Masque-skinned buttons where the skin puts the hotkey: its corner, offset, width and alignment, read from the skin itself. The font and colour stay yours. Picking another skin in Masque moves the text with it. A bar with a place of its own keeps that place. **Mirror Native Hotkey Style** is the other way to match a skin: it copies the label's font and colour too.

### Placement and Edit Mode

**Edit Positions on Your Bars** (or `/ahos edit`) lets you drag the hotkey text into place on your own bars:

| Action | Result |
|---|---|
| Drag a hotkey | Moves the text on every bar (the profile's X and Y Offset) |
| Shift-drag a hotkey | Moves the text on that bar only (gives the bar a place of its own) |
| Right-click a hotkey | Gives that bar back to the profile's position |
| **Done** | Ends edit mode; the positions are saved in the profile |
| **Save as Profile** | Saves the current settings as a new profile and switches to it |

While editing, the hotkey text takes the mouse, so your buttons cannot be clicked. Edit mode cannot start in combat and ends the moment combat starts. Offsets stay within the sliders' range (-50 to 50).

### Visibility

When the hotkey text shows. Every rule you turn on must agree; when one does not, the text fades.

| Option | Type | Default | Description |
|---|---|---|---|
| **Fade Out of Combat** | Toggle | Off | Shows the hotkey text only in combat. |
| **Only While a Modifier Is Held** | Toggle | Off | Shows the hotkey text only while Shift, Ctrl or Alt is held down. |
| **Faded Alpha** | Slider | 0% | How much of the text stays when a rule hides it. 0% hides it completely. |
| **Fade Time** | Slider | 0.25 s | How long the text takes to fade in or out. 0 is instant. |
| **Condition of Your Own (Lua)** | Text | Empty | Advanced: a Lua expression that must be true for the text to show. |

A bar can also show its text only while the mouse is over it: see **Show on Mouseover** on the [Bars](#bars) page.

The overlays are drawn on the buttons themselves, so a bar addon that fades its bars (Bartender4's or Dominos' fade and mouseover settings, ElvUI's mouseover) fades the hotkey text with them; nothing needs setting up for that.

**Writing a condition.** The text is one Lua expression (`return` is optional). It can read:

| Name | What it is |
|---|---|
| `button` | The button's frame name, e.g. `ActionButton3` |
| `bar` | The bar's key, e.g. `Blizzard:1`, `Dominos:4`, `LUI:Left1` |
| `key` | The full binding, e.g. `SHIFT-Q` |
| Game state | `InCombatLockdown`, `UnitAffectingCombat`, `IsMounted`, `IsFlying`, `IsStealthed`, `IsResting`, `IsInGroup`, `IsInRaid`, `IsInInstance`, `IsShiftKeyDown`, `IsControlKeyDown`, `IsAltKeyDown`, `IsModifierKeyDown`, `UnitExists`, `UnitIsDead`, `UnitCanAttack`, `UnitHealth`, `UnitPower`, `GetShapeshiftForm`, `GetSpecialization`, `HasAction`, `IsUsableAction` and a few more, plus `math` and `string` |

Examples:

```lua
UnitExists("target")                       -- only with a target
bar ~= "Blizzard:1" or InCombatLockdown()  -- bar 1 only in combat
not IsMounted()                            -- hide while mounted
key:find("SHIFT") == nil or IsShiftKeyDown()
```

The condition cannot reach anything else (no `_G`, `print`, `os`, `SetBinding`...). It is checked whenever the visibility is worked out and five times a second while one is set. A condition that errors shows the text and says so once in the chat.

### In Combat

| Option | Type | Default | Description |
|---|---|---|---|
| **Combat Style** | Toggle | Off | Draws the hotkey text in another colour and size while you are in combat. |
| **Combat Colour** | Colour | Red | The text colour in combat. |
| **Combat Size** | Slider | 115% | The text size in combat, relative to its size out of it. |

### Effects

| Option | Type | Default | Description |
|---|---|---|---|
| **When Pressed** | Dropdown | Nothing | What the text does when you press its button: **Flash** (a flash of colour) or **Pulse** (it grows and settles). |
| **Flash Colour** | Colour | Gold | The colour of the flash. |
| **Background Plate** | Toggle | Off | Draws a plate behind the text, so it reads on any icon. |
| **Plate Colour** | Colour | Black, 55% | The plate's colour and transparency. |
| **Plate Padding** | Slider | 2 | Space between the text and the plate's edge. |

---

## Font / Appearance

| Option | Type | Default | Description |
|---|---|---|---|
| **Font** | Dropdown | Default | The font face for overlay text. Includes all built-in WoW game fonts. If LibSharedMedia-3.0 is installed, all registered fonts are also available. |
| **Font Size** | Slider | 10 | Size of the overlay text in points. Range: 6–48. |
| **Font Color** | Color picker | Yellow | The color of the overlay text. Opens a standard WoW color picker with optional alpha support. |
| **Font Outline Style** | Dropdown | OUTLINE | How text outlines are rendered. Options: |

**Font Outline Style options:**

| Value | Description |
|---|---|
| `NONE` | No outline. Text may be hard to read over bright buttons. |
| `OUTLINE` | Standard thin black outline. |
| `THICKOUTLINE` | Thicker outline for better visibility at smaller sizes. |
| `MONOCHROME` | No anti-aliasing. Crisp pixel-art style at small sizes. |
| `MONOCHROME+OUTLINE` | Monochrome rendering with a thin outline. |
| `MONOCHROME+THICKOUTLINE` | Monochrome rendering with a thick outline. |

> **Tip:** `THICKOUTLINE` works best at small font sizes (8–12pt) on buttons with varied backgrounds. `OUTLINE` is usually fine at 12pt and above.

In the options window the Font list draws each font's name in that font.

**Modifier Colours** (on the Keybinds page):

| Option | Type | Default | Description |
|---|---|---|---|
| **Colour by Modifier** | Toggle | Off | Draws Shift, Ctrl and Alt bindings each in their own colour, with a fourth colour for two or more modifiers. Works in overlay and native text mode. |
| **Hide Modifier Letters** | Toggle | Off | Shows `Q` in the Shift colour instead of `SQ`: the colour alone tells the modifiers apart. |
| **Shift / Ctrl / Alt / Two or More Modifiers** | Color pickers | Blue / Gold / Green / Pink | The text colour for each. |

---

### Shadow and Glow

| Option | Type | Default | Description |
|---|---|---|---|
| **Shadow** | Toggle | On | A drop shadow under the hotkey text. |
| **Shadow Colour** | Colour | Black | The shadow's colour and strength. |
| **Shadow X / Shadow Y** | Slider | 1 / -1 | Where the shadow falls. |
| **Glow** | Toggle | Off | A soft halo in its own colour around the text. |
| **Glow Colour** | Colour | Gold | The halo's colour and strength. |

### Buttons with Two Keys

| Option | Type | Default | Description |
|---|---|---|---|
| **Show Both Keys** | Toggle | Off | A button bound to two keys shows both, for example `Q/SE`. |
| **Between the Keys** | Text | `/` | The text between the two keys. |

---

## Keybind / Abbreviations

| Option | Type | Default | Description |
|---|---|---|---|
| **Enable Abbreviations** | Toggle | On | Condenses modifier keys to single letters. `CTRL` → `C`, `SHIFT` → `S`, `ALT` → `A`. Mouse buttons become `B1`–`B3`. Disable to show the full raw keybind string. |
| **Max Length** | Slider | 6 | Maximum number of characters to display. If the abbreviated string exceeds this, it is truncated. Range: 1–10. |
| **Modifier Separator** | Text | *(empty)* | Character(s) inserted between each modifier letter and the key. Examples: `-` gives `C-S-A`, `·` gives `C·S·A`, empty gives `CSA`. |
| **Controller Button Icons** | Toggle | On | Draws gamepad buttons as your controller's own button icons (in the label style of the controller in use) instead of text. A gamepad button you gave an abbreviation of your own keeps it. |

In the options window the Abbreviations page is a keyboard. Click a key to change its abbreviation, see what it is bound to, and bind it: **Bind to...** lists every action button command by bar, **Unbind** clears the key, and **Hover Bind Mode** starts LibKeyBound where a bar addon brought it. Bindings cannot change in combat.

**Abbreviation reference:**

| Full String | Abbreviated |
|---|---|
| `CTRL` | `C` |
| `SHIFT` | `S` |
| `ALT` | `A` |
| `MOUSEBUTTON1` | `B1` |
| `MOUSEBUTTON2` | `B2` |
| `MOUSEBUTTON3` | `B3` |
| Number keys | As-is (`1`, `2`, etc.) |
| Function keys | As-is (`F1`, `F5`, etc.) |

---

### Keyboard Layouts

The keyboard on the Abbreviations page can be drawn as English (US), English (UK), Dansk, Norsk, Svenska / Suomi, Deutsch, Français, Русская, Українська, 한국어 (두벌식) or 繁體中文 (注音). Each board names its keys as the game names them on that layout: a Russian board's keys are Й, Ц, У and so on. The Korean and Taiwanese boards are the US board with the Hangul or Zhuyin printed under each letter, as on the real keys. The layout follows the client's language until you pick one. Cyrillic, Korean and Chinese text is drawn in the game's own faces for them, so it reads on a client in any language.

### Mouse Button Icons

With **Mouse Button Icons** on (Abbreviations page, off by default), mouse buttons and the wheel are drawn as small mouse icons in the text's colour: the left, right and middle buttons, the wheel up and down, and the side buttons with their number (`BUTTON4` shows the side-button icon and `4`). A mouse button you gave an abbreviation of your own keeps it.

---

## Bars

Settings for one bar on its own. Everything a bar does not set follows the profile.

| Option | Type | Default | Description |
|---|---|---|---|
| **Bar** | Dropdown | First bar found | The bar to change, from every bar AHOS found on Blizzard's bars and in your bar addon. Bars with settings of their own are marked `*`. |
| **Leave This Bar Alone** | Toggle | Off | AHOS draws nothing on this bar, and its buttons show their own hotkey text. |
| **Text Size on This Bar** | Slider | 100% | The hotkey text on this bar, relative to the size everywhere else. |
| **Show on Mouseover** | Toggle | Off | This bar's hotkey text shows only while the mouse is over the bar. Moving from one of its buttons to the next keeps it shown. |
| **A Place of Its Own** | Toggle | Off | Puts this bar's text somewhere else than on the other bars. |
| **Anchor / X Offset / Y Offset on This Bar** | Grid / Sliders | The profile's | Where the text sits on this bar. Shift-drag in [edit mode](#placement-and-edit-mode) does the same. |
| **Draw on Every Button Again** | Button | — | Forgets every single button AHOS was told to leave alone. Buttons are left alone from the [Inspector](#inspector) card or with `/ahos ignore <ButtonName>`. |
| **Reset Every Bar** | Button | — | Removes every bar's settings. |

---

## Profile Management

AHOS includes a complete profile system allowing different configurations per character, spec, or a shared global profile.

### Profile Types

| Profile Type | Scope | When to Use |
|---|---|---|
| **Global** | Shared across all characters | One unified look for all alts |
| **Character-specific** | Per character name + realm | Different styles per character |

### Profile Actions

| Action | Description |
|---|---|
| **Switch Profile** | Change the active profile (Global or any character profile) |
| **Copy Profile** | Copy all settings from the current profile to another profile |
| **Reset Current Profile** | Restore the active profile to default values |
| **Reset All Profiles** | Wipe all profiles and return to defaults |
| **Export Profile** | Serializes the current profile to a text string you can copy. Use this to back up settings or share them with others. |
| **Import Profile** | Pastes a previously exported string and loads those settings into the current profile. |

### Switch Profile By Itself

**Switch Profile By Itself** is a choice per character:

| Choice | Profile used |
|---|---|
| **Never** | Whatever you pick |
| **By Specialization** | `Name-Realm-Specialization` |
| **By Talent Loadout** | `Name-Realm-Specialization-Loadout` (Retail; elsewhere it follows the specialization) |

A profile that does not exist yet starts as a copy of the one you are on, so switching never resets your look. (Before 2.6 this setting lived inside the profile it switched away from; it moves to the character by itself.)

> **Example use case:** A Druid who uses aggressive abbreviations for Balance but larger, clearer text for Restoration.

**Save as New Profile** (or `/ahos profile <name>`) makes a profile of that name from the current one and switches to it.

### Presets

Presets are laid over the current profile; anything a preset does not set stays as it is. A [snapshot](#snapshots) is taken first, so `/ahos rollback` undoes one.

| Preset | What it does |
|---|---|
| **Blizzard Style** | Small text in the top-right corner, where the game puts it |
| **Big and Centered** | Large text in the middle of the button |
| **Bottom Corner** | Text in the bottom-right corner, clear of cooldown numbers |
| **Compact** | Small text along the top, at most four letters |
| **Tank** | Big, glowing text that turns red in combat |
| **Healer** | Bindings coloured by modifier with the letters dropped, on a dark plate |
| **Damage** | Text that pulses when pressed and dims out of combat |

### Snapshots

Copies of a profile to go back to, kept for all characters (the newest fifteen). One is taken by itself before every preset, import, reset and restore.

| Action | Description |
|---|---|
| **Take a Snapshot** | Keeps a copy of the profile as it is now (`/ahos snapshot [label]`) |
| **Snapshot** | Picks one; the newest is first (`/ahos snapshot list`) |
| **Restore** | Puts it into the profile you are on; what was there is kept as a snapshot first (`/ahos rollback [n]`) |
| **Delete** | Throws it away |

---

## Minimap

| Option | Description |
|---|---|
| **Hide Minimap Icon** | Hides or shows the AHOS launcher button on the minimap. Your settings are preserved; this only affects visibility of the button. |

**Minimap icon interactions:**

| Interaction | Action |
|---|---|
| Left-click | Open the AHOS options panel |
| Shift+Left-click | Open the debug log window |
| Right-click | Toggle AHOS enabled/disabled |

---

## Compatibility

| Option | Description |
|---|---|
| **Enable ElvUI Compatibility** | Forces AHOS overlays to render even when ElvUI is detected. By default, AHOS detects ElvUI and warns about potential conflicts. Enable this to proceed anyway. See [[Supported-Addons#elvui]] and [[Troubleshooting]] for details. |

---

## Inspector

In the options window, **Pick a Button** steps the window aside so you can point at any action button on your screen. A click keeps it, a right-click cancels. The card shows which bar addon drew the button and on which bar, the key that presses it, the text AHOS draws for it, the command and action on it, and why AHOS shows what it shows. **Copy Details** opens the same information as `/ahos inspect <ButtonName>`, ready to copy. `/ahos inspect <ButtonName>` prints it in the chat.

**Leave This Button Alone** on the card makes AHOS leave that one button to its own hotkey text; **Draw on This Button** undoes it. The same is `/ahos ignore <ButtonName>` and `/ahos unignore <ButtonName>`.

---

## Troubleshooting Tools

These options are for advanced diagnostics. Enable them only when investigating an issue.

| Option | Description |
|---|---|
| **Enable Troubleshooting Tools** | Activates the diagnostic subsystem, enabling the options below. |
| **Export Debug Data** | Serializes your current settings and diagnostic state to a string for sharing in bug reports. Equivalent to `/ahos debugexport`. |
| **Import Debug Data** | Load a debug data string (e.g., provided by a support volunteer) to replicate a configuration. |
| **Show Performance Metrics** | Displays per-button overlay update timing in the debug log. Useful for identifying performance-heavy update scenarios. |
| **Open Debug Log** | Opens the in-game scrollable debug log window. Equivalent to `/ahoslog`. |
