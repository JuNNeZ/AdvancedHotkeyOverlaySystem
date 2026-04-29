# Troubleshooting

This guide walks through the most common AHOS issues with step-by-step fixes. If your issue isn't covered here, check the [[FAQ]] or open a [GitHub Issue](https://github.com/junnez/advancedhotkeyoverlaysystem/issues).

---

## Table of Contents

- [Before You Start](#before-you-start)
- [Overlays Not Showing at All](#overlays-not-showing-at-all)
- [Overlays Show on Some Buttons but Not Others](#overlays-show-on-some-buttons-but-not-others)
- [Overlays in the Wrong Position](#overlays-in-the-wrong-position)
- [Text Too Small or Hard to Read](#text-too-small-or-hard-to-read)
- [Double Text (AHOS + Native)](#double-text-ahos--native)
- [Overlays Behind the Button Skin](#overlays-behind-the-button-skin)
- [ElvUI Conflict](#elvui-conflict)
- [Dominos Issues](#dominos-issues)
- [DynamicCam Issues](#dynamiccam-issues)
- [Button Not Detected](#button-not-detected)
- [Overlays Disappeared After UI Reload](#overlays-disappeared-after-ui-reload)
- [Settings Not Saving](#settings-not-saving)
- [Preparing a Bug Report](#preparing-a-bug-report)

---

## Before You Start

Run these basic checks before diving into specific issues:

1. **Confirm AHOS is enabled:**
   ```
   /ahos
   ```
   Check that **Enable Addon** is toggled on.

2. **Force a full reload:**
   ```
   /ahos reload
   ```

3. **Enable debug mode** to get verbose output:
   ```
   /ahos debug
   ```
   Then open the debug log:
   ```
   /ahoslog
   ```

4. **Check what provider AHOS detected:**
   ```
   /ahos detectui
   ```
   The chat frame will print which action bar addon was detected.

---

## Overlays Not Showing at All

**Symptom:** You log in, AHOS appears to be enabled, but no overlay text appears on any button.

### Step 1 — Confirm buttons have keybinds

AHOS only shows text when a keybind is assigned. Open your key bindings and verify at least a few buttons have bindings. If you use an action bar addon's own keybind mode, make sure those binds are registered.

### Step 2 — Re-run detection

```
/ahos detectui
/ahos reload
```

Check the chat frame for the detected provider name. If it says `None` or `Unknown`, AHOS did not recognize your action bar addon. See [[Supported-Addons]] for the list of supported addons.

### Step 3 — Check frame layering

Overlays may be rendering but hidden behind your UI skin:

1. Enable **Smart Frame Layering** in `/ahos` → **Display** (should be on by default).
2. Increase **Overlay Frame Level** to `50` or higher as a test.
3. If overlays appear, lower the level gradually until you find the right threshold.

### Step 4 — Try Native Rewrite Mode

```
/ahos
```
Go to **Display → Use Native Text** and enable it. Then:
```
/ahos reload
```

If overlays appear now, your skin was hiding the overlay frames. Keep Native Rewrite Mode enabled (or use Auto-Fallback).

### Step 5 — Check for conflicting addons

Disable all other addons except AHOS and reload. If overlays appear, re-enable your addons one by one to find the conflict.

---

## Overlays Show on Some Buttons but Not Others

**Symptom:** Most buttons work, but specific buttons or bars show no overlay.

### Check 1 — Keybinds

The missing buttons may simply have no keybind assigned. Hover over each button in-game and check the tooltip for a listed keybind.

### Check 2 — Inspect the specific button

Use the inspect command with the exact frame name of the button:

```
/ahos inspect ActionButton1
```

If AHOS doesn't know that button name, the output will say so. Use `/fstack` (Blizzard's built-in frame stack tool, or a UI inspector addon) to get the exact frame name of the button.

### Check 3 — Recently added bars

If you added a new bar in Dominos, Bartender4, or another addon after logging in:

```
/ahos reload
```

AHOS scans for buttons at login. New bars added mid-session aren't automatically detected until a reload.

### Check 4 — Vehicle / possession bars

When in a vehicle, pet battle, or using a possess/override bar, AHOS should automatically update. If it doesn't, try:

```
/ahos refresh
```

---

## Overlays in the Wrong Position

**Symptom:** Overlay text appears outside the button, overlapping adjacent buttons, or in a corner you didn't intend.

### Fix

Go to `/ahos` → **Display**:

| Setting | Recommended Starting Point |
|---|---|
| **Anchor Point** | `TOPLEFT` |
| **X Offset** | `2` |
| **Y Offset** | `-2` |

Adjust **X Offset** and **Y Offset** until the text sits where you want it. Positive X = right, negative X = left. Positive Y = up, negative Y = down.

> **Tip:** Use **Center** anchor with X=0, Y=0 for a perfectly centered label.

### Mirror Native Hotkey Style

If you want the overlay to sit exactly where the native hotkey text was:

Enable **Mirror Native Hotkey Style** in **Display**. AHOS will copy the position, font, and color from the native `HotKey` FontString.

---

## Text Too Small or Hard to Read

**Symptom:** Overlay text is visible but too small, or blends into button art.

### Fix — Size

- `/ahos` → **Font / Appearance → Font Size** — try 11–14pt as a starting point
- **Scale** slider under **Display** — increase above 1.0 for a multiplier

### Fix — Readability

| Problem | Solution |
|---|---|
| Text blends with button art | Change **Font Color** to white; set **Font Outline Style** to `THICKOUTLINE` |
| Text looks fuzzy at small sizes | Switch to `MONOCHROME` or `MONOCHROME+THICKOUTLINE` |
| Text too faint | Increase **Alpha** to 1.0 (fully opaque) |

---

## Double Text (AHOS + Native)

**Symptom:** You see two sets of hotkey text on buttons — the AHOS abbreviation and the original game text.

### Fix

Enable **Hide Original Hotkey Text** in `/ahos` → **Display**. This is on by default; if you see double text it has been disabled.

### Dominos-Specific

If you use Dominos and see Dominos' own keybind text alongside the AHOS overlay:

Enable **Dominos: Use Native Text** in `/ahos` → **Display**. This replaces Dominos' text with AHOS' abbreviated text rather than drawing on top of it.

---

## Overlays Behind the Button Skin

**Symptom:** Overlays exist (you can see them in `/ahos inspect`) but appear behind your button skin's border or artwork.

### Fix 1 — Smart Frame Layering

Ensure **Smart Frame Layering** is enabled (default: on). This makes overlay frames inherit the same frame strata as their parent button, keeping them on top.

### Fix 2 — Manual Frame Level

Disable **Smart Frame Layering** and manually set:
- **Overlay Frame Strata** → `HIGH` or `DIALOG`
- **Overlay Frame Level** → `50` or higher

### Fix 3 — Native Rewrite

Switch to **Native Rewrite Mode** (**Use Native Text**). The text will live inside the button's own frame hierarchy, making it immune to external frame ordering issues.

---

## ElvUI Conflict

**Symptom:** AHOS appears to be running but overlays are invisible, or AHOS shows a warning about ElvUI.

ElvUI's skin engine clips external frames placed on action buttons. This is the most common reason overlays are invisible on an ElvUI setup.

### Step 1 — Enable ElvUI Compatibility

Go to `/ahos` → **Compatibility → Enable ElvUI Compatibility**.

### Step 2 — Switch to Native Rewrite Mode

Go to `/ahos` → **Display → Use Native Text** and enable it.
```
/ahos reload
```

### Step 3 — Confirm ElvUI has hotkeys enabled

In the ElvUI config (`/elvui`):
- Go to **ActionBars**
- Ensure **Hotkeys** is checked/enabled

AHOS' Native Rewrite needs ElvUI's HotKey FontString to exist. If ElvUI itself is hiding hotkeys, there is nothing for AHOS to rewrite.

### Step 4 — After ElvUI updates

Major ElvUI updates can re-skin buttons in ways that require AHOS to re-initialize. After updating ElvUI:
```
/ahos reload
```

---

## Dominos Issues

### Dominos keybinds not showing correctly

Dominos uses its own keybind resolution. If AHOS shows wrong or missing keybinds for Dominos buttons:

1. Run `/ahos detectui` — confirm Dominos is detected as the provider.
2. Run `/ahos reload`.
3. Check that your keybinds are set via Dominos' own binding interface (or in the standard Blizzard binding UI — Dominos reads from both).

### After switching Dominos profiles (bar layouts)

```
/ahos reload
```

AHOS needs to rescan the button list after Dominos rearranges its bars.

### Double text with Dominos

Enable **Dominos: Use Native Text** in AHOS settings. See [[Configuration#dominos-native-text-override]].

---

## DynamicCam Issues

**Symptom:** When mounting up or entering combat (transitioning states DynamicCam animates), overlays briefly disappear or appear in the wrong place.

This is caused by DynamicCam's mount-to-combat transition modifying the camera and UI scale in ways that temporarily affect frame anchoring.

### Fix

AHOS includes built-in DynamicCam compatibility logic that triggers a refresh on these transitions. If you still experience issues:

1. Ensure you are on the latest version of AHOS.
2. Try enabling **Auto Fallback to Native** — Native Rewrite Mode is not affected by frame anchoring changes in the same way overlay frames are.
3. Run `/ahos refresh` manually after the transition if it's a one-time occurrence.

---

## Button Not Detected

**Symptom:** A button on your screen clearly exists and has a keybind, but AHOS shows no overlay for it, and `/ahos inspect` says the button is unknown.

### Find the Button's Frame Name

Use WoW's built-in frame inspector:
1. Type `/fstack` in chat (if using Blizzard's default UI debugger, or a UI inspector addon).
2. Hover over the button — the frame name will appear in the tooltip or print to chat.
3. Note the full frame name (e.g., `DominosActionButton5`).

### Inspect the Button

```
/ahos inspect DominosActionButton5
```

If AHOS returns "unknown button", the button prefix is not in AHOS' detection list.

### Report It

Open a [GitHub Issue](https://github.com/junnez/advancedhotkeyoverlaysystem/issues) with:
- The frame name
- Which action bar addon provides it
- Your WoW version

See [[Contributing]] if you want to implement support yourself.

---

## Overlays Disappeared After UI Reload

**Symptom:** After typing `/reload`, overlays don't reappear until you do something.

This is expected. AHOS initializes on login events and rescans buttons on the first available event after login. If the overlays don't appear within a few seconds of logging in:

```
/ahos reload
```

---

## Settings Not Saving

**Symptom:** You change a setting, do `/reload`, and the setting has reverted.

### Check 1 — Lock Mode

Ensure settings are not locked: `/ahos unlock`

### Check 2 — Profile

Confirm you are saving to the correct profile. If you have a character-specific profile active, changes save to that profile only.

### Check 3 — AddOns folder permissions

On some systems, the `WTF/` folder may be read-only. Check folder permissions for:
```
World of Warcraft\WTF\Account\<AccountName>\SavedVariables\
```

---

## Preparing a Bug Report

When opening a [GitHub Issue](https://github.com/junnez/advancedhotkeyoverlaysystem/issues), include:

1. **AHOS version** — shown in `/ahos` options panel title or in the TOC file
2. **WoW version** — e.g., Retail 11.0.7, Classic Era 1.15.3
3. **Action bar addon** — Dominos, Bartender4, Blizzard, etc. (and its version)
4. **Other relevant addons** — especially ElvUI, DynamicCam, or other UI replacements
5. **Debug export:**
   ```
   /ahos debugexport
   ```
   Copy the output and paste it into the issue.
6. **Steps to reproduce** — exactly what you do to trigger the problem
7. **Expected behavior** — what you expected to see
8. **Actual behavior** — what actually happened

The more detail you provide, the faster the issue can be diagnosed and fixed.
