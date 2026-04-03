# Slash Commands

AHOS is fully controllable from the chat box. All commands use `/ahos` or the long-form alias `/advancedhotkeyoverlaysystem`.

---

## Table of Contents

- [Primary Commands](#primary-commands)
- [Command Reference](#command-reference)
- [Examples](#examples)
- [Minimap Icon Interactions](#minimap-icon-interactions)
- [Debug Log Window](#debug-log-window)

---

## Primary Commands

| Alias | Notes |
|---|---|
| `/ahos` | Short form — recommended |
| `/advancedhotkeyoverlaysystem` | Full form — identical behavior |

Both aliases accept the same sub-commands.

---

## Command Reference

### General

| Command | Description |
|---|---|
| `/ahos` | Open the AHOS options panel (same as `/ahos show`) |
| `/ahos show` | Open the AHOS options panel |
| `/ahos help` | Print a summary of available commands to the chat frame |

### State Control

| Command | Description |
|---|---|
| `/ahos toggle` | Enable or disable all AHOS overlays. Toggles the master on/off switch. |
| `/ahos lock` | Lock settings to prevent accidental changes in the UI. |
| `/ahos unlock` | Unlock settings. |
| `/ahos reset` | Reset **all** settings to their factory defaults. This affects the current profile. |

### Overlay Management

| Command | Description |
|---|---|
| `/ahos reload` | Force a full re-initialization: re-scans all buttons, re-creates overlay frames, and redraws all text. Use this after major UI changes. |
| `/ahos refresh` | Smart refresh — updates overlay text for all currently tracked buttons without re-creating frames. Faster than `reload`; use this after binding changes. |
| `/ahos cleanup` | Temporarily hides and clears all overlays without disabling AHOS. Useful for screenshots. Overlays reappear on the next `refresh` or `/reload`. |

### UI Detection

| Command | Description |
|---|---|
| `/ahos detectui` | Manually re-run the action bar addon detection logic. Use this if you switched action bar addons mid-session or if AHOS picked the wrong provider on login. |

### Debug & Diagnostics

| Command | Description |
|---|---|
| `/ahos debug` | Toggle debug mode. When on, verbose internal messages print to the chat frame on every overlay update. |
| `/ahos inspect <ButtonName>` | Print detailed diagnostic information for a specific button by its frame name. See [Examples](#examples). |
| `/ahos debugexport [tablepath]` | Export current settings (and optionally a specific data table) as a serialized string. Paste this in a bug report. |
| `/ahoslog` | Open the AHOS debug log window — a scrollable in-game window showing all debug output. |

---

## Examples

### Open the options panel
```
/ahos
```

### Quickly disable and re-enable overlays
```
/ahos toggle
/ahos toggle
```

### Re-detect your action bar addon after switching from Bartender4 to Dominos
```
/ahos detectui
```

### Reload overlays after installing a new action bar addon
```
/ahos reload
```

### Inspect why ActionButton1 isn't getting an overlay
```
/ahos inspect ActionButton1
```

**Output example:**
```
[AHOS] Inspect: ActionButton1
  Provider:    Blizzard
  HasAction:   true
  HotkeyText:  "C-S-A"
  OverlayFrame: AHOSBL_ActionButton1 (MEDIUM/10)
  Visible:     true
  Position:    TOPLEFT (+2, -2)
```

### Inspect a Dominos button
```
/ahos inspect DominosActionButton3
```

### Export your profile for sharing or backup
```
/ahos debugexport
```

### Reset everything to defaults (confirm in the options panel)
```
/ahos reset
```

### Quickly suppress overlays for a screenshot
```
/ahos cleanup
```
Then restore:
```
/ahos refresh
```

---

## Minimap Icon Interactions

The AHOS minimap button provides quick access without opening chat.

| Interaction | Action |
|---|---|
| **Left-click** | Open the AHOS options panel |
| **Shift+Left-click** | Open the debug log window (equivalent to `/ahoslog`) |
| **Right-click** | Toggle AHOS enabled/disabled (equivalent to `/ahos toggle`) |

To hide the minimap icon without disabling AHOS, go to **Options → Minimap → Hide Minimap Icon**.

---

## Debug Log Window

The debug log window (`/ahoslog` or Shift+Left-click the minimap icon) is a scrollable, in-game window that captures all AHOS debug output in real time.

Use this when:
- Overlays appear on some buttons but not others
- You want to trace exactly when and why an overlay is being updated
- Preparing a detailed bug report
- Checking performance metrics (enable **Show Performance Metrics** in Troubleshooting Tools first)

The window can be dragged and resized. Output is cleared when you close the window or reload the UI.
