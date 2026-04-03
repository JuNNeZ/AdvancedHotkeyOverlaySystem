# Frequently Asked Questions

Common questions and answers about the Advanced Hotkey Overlay System.

---

## Table of Contents

- [Installation & Setup](#installation--setup)
- [Overlays Not Showing](#overlays-not-showing)
- [Display & Appearance](#display--appearance)
- [Abbreviations & Keybinds](#abbreviations--keybinds)
- [Addon Compatibility](#addon-compatibility)
- [Profiles & Settings](#profiles--settings)
- [Performance](#performance)
- [Commands & Controls](#commands--controls)

---

## Installation & Setup

### Q: Do I need any other addons for AHOS to work?

No. AHOS has no hard dependencies. It bundles its own copies of any required libraries. Optional enhancements include:

- **LibSharedMedia-3.0** — Unlocks additional font choices in the font dropdown
- **LibKeyBound-1.0** — Enables real-time updates during Dominos/Bartender4 interactive keybind mode (usually ships with those addons)

---

### Q: Which WoW versions are supported?

AHOS supports:

- **Retail (Mainline):** WoW 11.0.7 through 12.x
- **Mists of Pandaria Classic:** WoW 5.0.x
- **Vanilla / Classic Era:** WoW 1.15.x

---

### Q: I installed AHOS but it doesn't appear in my AddOns list. What do I do?

1. Double-check the folder is named **exactly** `AdvancedHotkeyOverlaySystem` (no extra characters, no trailing `-main` from a GitHub ZIP download).
2. Verify it is inside the correct version folder:
   - Retail: `_retail_\Interface\AddOns\`
   - Classic Era: `_classic_era_\Interface\AddOns\`
   - MoP Classic: `_classic_\Interface\AddOns\`
3. On the character select screen, click **AddOns** and ensure "Load out of date AddOns" is checked if you're on a very recent WoW patch.

---

### Q: After updating AHOS, my settings changed / were lost. Why?

Settings are stored in `WTF/` and are never touched by addon updates. However, occasionally a major AHOS version bump will change the settings structure, and AHOS may reset certain options to their new defaults. Check the [CHANGELOG](https://github.com/junnez/advancedhotkeyoverlaysystem/blob/main/CHANGELOG.md) for notes on breaking changes in the version you updated to.

---

## Overlays Not Showing

### Q: I installed AHOS but I see no overlays on my buttons. What should I check first?

Work through these steps in order:

1. Confirm AHOS is enabled: type `/ahos` and check that **Enable Addon** is toggled on.
2. Check if you have a supported action bar addon. Type `/ahos detectui` to re-run detection.
3. Confirm your buttons actually have keybinds assigned. AHOS only shows text when a keybind exists for that slot.
4. Try `/ahos reload` to force a full rescan of all buttons.
5. If you use ElvUI, see [ElvUI question below](#q-i-use-elvui-and-my-overlays-are-invisible-how-do-i-fix-this).

---

### Q: Overlays show on some buttons but not others. Why?

The most common reasons:

- **No keybind assigned** — Buttons without a keybind show nothing (by design).
- **Button not detected** — The button uses a frame name AHOS doesn't recognize. Run `/ahos inspect <ButtonName>` for that button to see if AHOS is tracking it.
- **Newly added bar** — If you added a new action bar after login, run `/ahos reload` to pick up the new buttons.
- **Frame layering issue** — The overlay exists but is hidden behind the button skin. Enable **Smart Frame Layering** or increase **Overlay Frame Level**.

---

### Q: My overlays disappeared after I changed my UI or reloaded. How do I get them back?

Type `/ahos reload`. This forces AHOS to re-scan all buttons and redraw all overlays from scratch. If that doesn't help, try `/ahos toggle` twice (off then on) or do a full UI reload (`/reload`).

---

## Display & Appearance

### Q: The overlay text is too small / too large. How do I resize it?

Open `/ahos` → **Font / Appearance → Font Size**. The slider ranges from 6 to 48 points. You can also use the **Scale** slider under **Display** to apply a multiplier on top of the font size.

---

### Q: The overlay text is in the wrong position on my buttons. How do I fix it?

Go to `/ahos` → **Display**:

- **Anchor Point** — Set which corner/edge the text is anchored to (e.g., `TOPLEFT`, `CENTER`, `BOTTOMRIGHT`)
- **X Offset** — Move left/right
- **Y Offset** — Move up/down

For most users, `TOPLEFT` with X=2, Y=-2 works well, which are the defaults.

---

### Q: The text is hard to read against my button background. What should I do?

Try these adjustments:

- Increase **Font Outline Style** to `THICKOUTLINE` — this adds a strong border around each letter.
- Change **Font Color** to a more contrasting color (white with `THICKOUTLINE` works universally).
- Slightly increase **Font Size**.
- Use `MONOCHROME+THICKOUTLINE` for a crisp, retro appearance that stands out on any background.

---

### Q: The overlay appears behind my action button skin instead of on top of it.

Enable **Smart Frame Layering** (default: on). If it's already enabled and overlays still appear behind, try increasing **Overlay Frame Level** (e.g., from 10 to 20 or 30).

If the problem persists, your button skin is using an unusual strata. Try switching to **Native Rewrite Mode** (**Use Native Text**), which places text inside the button frame itself and bypasses this issue entirely.

---

### Q: I can see both the AHOS overlay text AND the original game hotkey text. How do I hide the original?

Enable **Hide Original Hotkey Text** in `/ahos` → **Display**. This is on by default. If it appears off, toggle it on.

Note: If you're using **Native Rewrite Mode**, AHOS is rewriting the native text directly — there is no separate overlay, and the **Hide Original Hotkey Text** option is not applicable.

---

## Abbreviations & Keybinds

### Q: Why does my keybind show as `CSA` with no separators instead of `C-S-A`?

The **Modifier Separator** field is empty by default, which produces `CSA`. Set it to `-` (a dash) under `/ahos` → **Keybind / Abbreviations → Modifier Separator** to get `C-S-A`.

---

### Q: My keybind label is being cut off. How do I show the full text?

Increase the **Max Length** slider under **Keybind / Abbreviations**. The default is 6 characters. You can increase it up to 10. Alternatively, disable **Enable Abbreviations** entirely to show the raw full keybind string (though this may be quite long for multi-modifier binds).

---

### Q: A button shows a keybind label but I never set a bind for it. Why?

Some action slots have default Blizzard keybinds set before you customize anything (e.g., `1`–`0` for the main bar). AHOS reports whatever binding is active for that slot, including defaults. Use Blizzard's key binding interface (or your action bar addon's) to clear or change those binds.

---

## Addon Compatibility

### Q: I use ElvUI and my overlays are invisible. How do I fix this?

ElvUI's skin engine clips external frames placed on buttons. Do the following:

1. Go to `/ahos` → **Compatibility** → enable **ElvUI Compatibility**.
2. Enable **Use Native Text** (Native Rewrite Mode) OR enable **Auto Fallback to Native**.
3. Run `/ahos reload`.

If overlays are still invisible, also check that ElvUI's own hotkey display is enabled in ElvUI settings (`ElvUI → ActionBars → Hotkeys`) — AHOS' Native Rewrite Mode needs that FontString to exist.

---

### Q: I use Dominos and I see duplicate keybind text (both Dominos' text and AHOS overlay). How do I fix it?

Enable **Dominos: Use Native Text** in `/ahos` settings. This routes AHOS through Dominos' own keybind text pipeline, eliminating the duplicate.

---

### Q: I switched from Bartender4 to Dominos mid-session. Now overlays are broken.

Run `/ahos detectui` to force re-detection of your action bar addon, then `/ahos reload` to rescan buttons.

---

### Q: Does AHOS work with [X addon]?

If the addon isn't listed in [[Supported-Addons]], it's not guaranteed to work. AHOS will attempt to fall back to Blizzard button detection, which may or may not cover buttons created by the addon. See [[Supported-Addons#requesting-support-for-a-new-addon]] to request support.

---

## Profiles & Settings

### Q: How do I use different settings on different characters?

In `/ahos` → **Profile Management**, create or switch to a character-specific profile. Any changes you make while that profile is active only affect that character. Other characters using the Global profile remain unaffected.

---

### Q: How do I back up or share my AHOS settings?

Use `/ahos debugexport` or go to `/ahos` → **Profile Management → Export Profile**. Copy the text string that appears and save it (or paste it to a friend). They can import it via **Import Profile**.

---

### Q: I reset my settings by accident. Can I undo it?

Unfortunately, AHOS does not maintain a backup before reset. Going forward, use **Export Profile** regularly to keep a string-based backup of your settings.

---

## Performance

### Q: Does AHOS affect game performance?

AHOS is designed to be event-driven rather than tick-driven. It updates overlays only when specific events fire (binding changes, bar page changes, specialization changes, etc.) rather than on every frame. For most users, the performance impact is negligible.

If you notice performance issues, enable **Show Performance Metrics** under **Troubleshooting Tools** and review the debug log to identify which events are triggering frequent updates.

---

### Q: I have hundreds of action buttons (e.g., with Dominos). Will AHOS slow down my UI?

AHOS scales to large button counts, but the initial `reload` scan (which touches every button) does more work with more buttons. Subsequent event-driven updates are incremental. If you notice lag on login or after `/ahos reload`, it is typically brief and does not recur during normal play.

---

## Commands & Controls

### Q: Is there a way to quickly toggle overlays on/off without opening the settings panel?

Yes — right-click the minimap icon, or type `/ahos toggle`.

### Q: How do I open the debug log?

Type `/ahoslog` or Shift+Left-click the minimap icon.
