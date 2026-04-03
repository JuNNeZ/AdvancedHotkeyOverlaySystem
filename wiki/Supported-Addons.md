# Supported Addons

AHOS integrates with the following action bar addons. This page describes how each integration works, what buttons are covered, and any known quirks or configuration notes.

---

## Table of Contents

- [Blizzard (Default UI)](#blizzard-default-ui)
- [Dominos](#dominos)
- [Bartender4](#bartender4)
- [AzeriteUI](#azeriteui)
- [DiabolicUI3](#diabolicui3)
- [ElvUI](#elvui)
- [LibKeyBound-1.0 Integration](#libkeybound-10-integration)
- [Unsupported Addons](#unsupported-addons)
- [Requesting Support for a New Addon](#requesting-support-for-a-new-addon)

---

## Blizzard (Default UI)

**Status:** ✅ Full support

AHOS covers all standard Blizzard action button types out of the box.

### Covered Button Prefixes

| Button Type | Frame Name Pattern |
|---|---|
| Main action bar | `ActionButton1`–`ActionButton12` |
| Bonus action bar | `BonusActionButton1`–`BonusActionButton12` |
| Multi-bar (bottom left) | `MultiBarBottomLeftButton1`–`12` |
| Multi-bar (bottom right) | `MultiBarBottomRightButton1`–`12` |
| Multi-bar (right) | `MultiBarRightButton1`–`12` |
| Multi-bar (left) | `MultiBarLeftButton1`–`12` |
| Stance / Shapeshift bar | `StanceButton1`–`10` |
| Pet action bar | `PetActionButton1`–`10` |
| Possess bar | `PossessButton1`–`2` |
| Extra action button | `ExtraActionButton1` |

### Notes

- The vehicle/possess/override bar is handled automatically. When you enter a vehicle or possess a target, overlays update to reflect the new button set.
- `ExtraActionButton1` (the zone-ability button) is supported and displays its keybind overlay correctly.
- If you use the default Blizzard UI with no additional action bar addons, no configuration is needed — AHOS works immediately.

---

## Dominos

**Status:** ✅ Full support (including native text mode and LibKeyBound integration)

Dominos is a popular action bar replacement that provides highly configurable, repositionable bars. AHOS has dedicated Dominos support with a custom keybind resolution path.

### Covered Button Prefixes

| Button Type | Frame Name Pattern |
|---|---|
| Action buttons | `DominosActionButton1`–`N` |

### How It Works

Dominos uses its own internal keybind system that differs from the standard Blizzard binding API. AHOS includes a dedicated keybind resolver for Dominos that reads bindings through Dominos' API rather than the standard `GetBindingKey()` call. This ensures abbreviations accurately reflect what Dominos reports as the active binding.

### Native Text Mode for Dominos

Enable **Dominos: Use Native Text** in settings to route AHOS through Dominos' own keybind text pipeline. This is recommended if:
- You see double text (Dominos keybind text and AHOS overlay text simultaneously)
- AHOS overlay text appears misaligned relative to Dominos' own text positioning

### LibKeyBound-1.0

If **LibKeyBound-1.0** is installed (it ships with some versions of Dominos), AHOS detects it and hooks into keybind-mode events. This means overlays update correctly when you use Dominos' interactive keybind mode (the "KB" mode where you hover and press a key).

### Known Quirks

- When using Dominos Profiles (Dominos' own bar layout profiles, distinct from AHOS profiles), run `/ahos reload` after switching profiles to re-scan buttons.
- Some Dominos bar hide/show animations can briefly cause overlays to appear over hidden bars. This resolves itself within one update tick.

---

## Bartender4

**Status:** ✅ Full support (including LibKeyBound integration)

Bartender4 is one of the most widely used action bar replacements. AHOS covers all Bartender4 button types.

### Covered Button Prefixes

| Button Type | Frame Name Pattern |
|---|---|
| Action buttons | `BT4Button1`–`N` |
| Pet action buttons | `BT4PetButton1`–`10` |
| Stance/Shapeshift buttons | `BT4StanceButton1`–`10` |

### LibKeyBound-1.0

AHOS detects LibKeyBound-1.0 when it is present (Bartender4 ships it). Overlays update in real time while you use Bartender4's interactive keybind mode.

### Known Quirks

- When creating or deleting Bartender4 bars mid-session, run `/ahos reload` to pick up the new buttons.
- Bartender4's "hide keybinds" option in its own settings will conflict with AHOS' **Hide Original Hotkey Text** toggle. If you use Bartender4's hide option, AHOS' overlay still renders; the native text suppression becomes redundant.

---

## AzeriteUI

**Status:** ✅ Full support

AzeriteUI is an all-in-one UI replacement with its own action bar system.

### Covered Button Prefixes

| Button Type | Frame Name Pattern |
|---|---|
| Main action buttons | `AzeriteActionBar` series |
| Stance bar buttons | `AzeriteStanceBarButton` series |

### Notes

- AzeriteUI applies aggressive frame styling. **Overlay Mode** works correctly with AzeriteUI's default skin.
- If overlays appear behind AzeriteUI's button skin, try enabling **Smart Frame Layering** (default: on) or increase **Overlay Frame Level**.

---

## DiabolicUI3

**Status:** ✅ Full support

DiabolicUI3 provides a complete UI replacement including multiple styled action bar types.

### Covered Button Prefixes

| Button Type | Frame Name Pattern |
|---|---|
| Main action bar | `DiabolicActionBar` series |
| Small action bar | `DiabolicSmallActionBar` series |
| Pet action bar | `DiabolicPetActionBar` series |
| Stance bar | `DiabolicStanceBar` series |

### Notes

- DiabolicUI3 has its own frame strata management. If overlays appear behind buttons, enable **Smart Frame Layering** or manually raise the **Overlay Frame Level**.
- DiabolicUI3's compact "small action bar" variant is fully supported and receives overlays the same as the main bar.

---

## ElvUI

**Status:** ⚠️ Detected — use with caution

ElvUI is a comprehensive UI replacement that aggressively reskins action buttons. By default, AHOS detects ElvUI's presence and displays a warning, because ElvUI's skinning engine frequently hides external frames drawn on top of buttons.

### Why ElvUI is Tricky

ElvUI replaces Blizzard's action buttons with its own styled frames and controls frame strata/level within those frames. Frames placed on top of ElvUI buttons from external addons are often clipped by ElvUI's own overlay system, making AHOS overlays invisible.

### How to Use AHOS with ElvUI

1. Enable **ElvUI Compatibility** in **Options → Compatibility**.
2. Switch to **Native Rewrite Mode** (**Use Native Text** toggle) or enable **Auto-Fallback to Native**.
3. Adjust font size and positioning if needed, as the native HotKey position is determined by ElvUI's skin.

### Known Issues

- ElvUI updates (especially major version bumps) may reset or re-skin buttons in ways that temporarily break AHOS overlays. Run `/ahos reload` after updating ElvUI.
- ElvUI's own "Hotkeys" option in ElvUI settings (`ElvUI → ActionBars → Hotkeys`) must be enabled for Native Rewrite Mode to have a FontString to rewrite. If ElvUI's own hotkeys are fully disabled (hidden), there is nothing for AHOS to rewrite.
- Full compatibility cannot be guaranteed due to the scope of ElvUI's modifications. If issues persist, consider using ElvUI's built-in keybind text styling instead.

---

## LibKeyBound-1.0 Integration

**LibKeyBound-1.0** is a library used by some action bar addons (notably Dominos and Bartender4) to provide an interactive keybind assignment mode.

When AHOS detects LibKeyBound-1.0 is loaded, it registers for LibKeyBound's `LIBKEYBOUND_MODE_CHANGED` and key-set events. This means:

- Overlays update in real time as you assign new keybinds via the LibKeyBound interactive mode
- There is no need to run `/ahos refresh` after changing binds with LibKeyBound mode

This integration is automatic and requires no configuration.

---

## Unsupported Addons

The following addons are **not** currently supported. Using them alongside AHOS may result in no overlays, misaligned overlays, or errors.

- **Neuron** — Uses a non-standard button naming convention
- **ButtonForge** — Custom button implementation not yet mapped
- **Any addon not listed above** — AHOS will not detect it and will fall back to Blizzard buttons only

If you want support for an unsupported addon, see [Requesting Support for a New Addon](#requesting-support-for-a-new-addon).

---

## Requesting Support for a New Addon

To request support for a currently unsupported action bar addon:

1. Open a [GitHub Issue](https://github.com/junnez/advancedhotkeyoverlaysystem/issues) with the title: `[Feature Request] Support for <AddonName>`
2. Include:
   - The addon's name and CurseForge/GitHub link
   - The button frame name prefix (e.g., what does `ActionButton1` look like in that addon? You can use `/fstack` or `/framestack` to find it)
   - The WoW version(s) you use it on

See [[Contributing]] for details on implementing support yourself.
