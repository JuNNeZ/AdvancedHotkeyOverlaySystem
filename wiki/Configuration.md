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
- [Font / Appearance](#font--appearance)
- [Keybind / Abbreviations](#keybind--abbreviations)
- [Profile Management](#profile-management)
- [Minimap](#minimap)
- [Compatibility](#compatibility)
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

---

## Keybind / Abbreviations

| Option | Type | Default | Description |
|---|---|---|---|
| **Enable Abbreviations** | Toggle | On | Condenses modifier keys to single letters. `CTRL` → `C`, `SHIFT` → `S`, `ALT` → `A`. Mouse buttons become `B1`–`B3`. Disable to show the full raw keybind string. |
| **Max Length** | Slider | 6 | Maximum number of characters to display. If the abbreviated string exceeds this, it is truncated. Range: 1–10. |
| **Modifier Separator** | Text | *(empty)* | Character(s) inserted between each modifier letter and the key. Examples: `-` gives `C-S-A`, `·` gives `C·S·A`, empty gives `CSA`. |

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

### Auto-Switch by Spec

When **Auto-Switch by Spec** is enabled, AHOS automatically activates a different profile when you change your specialization. Configure which profile maps to which spec in the profile options.

> **Example use case:** A Druid who uses aggressive abbreviations for Balance but larger, clearer text for Restoration.

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

## Troubleshooting Tools

These options are for advanced diagnostics. Enable them only when investigating an issue.

| Option | Description |
|---|---|
| **Enable Troubleshooting Tools** | Activates the diagnostic subsystem, enabling the options below. |
| **Export Debug Data** | Serializes your current settings and diagnostic state to a string for sharing in bug reports. Equivalent to `/ahos debugexport`. |
| **Import Debug Data** | Load a debug data string (e.g., provided by a support volunteer) to replicate a configuration. |
| **Show Performance Metrics** | Displays per-button overlay update timing in the debug log. Useful for identifying performance-heavy update scenarios. |
| **Open Debug Log** | Opens the in-game scrollable debug log window. Equivalent to `/ahoslog`. |
