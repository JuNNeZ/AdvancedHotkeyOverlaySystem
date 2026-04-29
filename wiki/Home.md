# Advanced Hotkey Overlay System (AHOS)

> **Displays clean, abbreviation-style keybind labels on your action buttons — across every major action bar addon and every supported WoW version.**

[![CurseForge](https://img.shields.io/badge/CurseForge-1289540-orange)](https://www.curseforge.com/wow/addons/advanced-hotkey-overlay-system)
[![WoWInterface](https://img.shields.io/badge/WoWInterface-advanced--hotkey--overlay--system-blue)](https://www.wowinterface.com/downloads/info-advanced-hotkey-overlay-system)
[![GitHub](https://img.shields.io/badge/GitHub-junnez%2Fadvancedhotkeyoverlaysystem-lightgrey)](https://github.com/junnez/advancedhotkeyoverlaysystem)
[![Version](https://img.shields.io/badge/version-2.5.18-green)]()

---

## What is AHOS?

The **Advanced Hotkey Overlay System** replaces WoW's default verbose hotkey labels (e.g., `CTRL-SHIFT-A`) with compact, ConsolePort-style abbreviations (e.g., `C-S-A`) displayed as clean overlays directly on your action buttons.

Instead of cluttered multi-word labels eating up half your button space, you get short, readable keybind hints that stay out of the way while still giving you exactly the information you need at a glance.

**Key highlights:**

- 🎯 **ConsolePort-style abbreviations** — `CTRL+SHIFT+A` becomes `C-S-A`
- 🔌 **Broad addon compatibility** — Blizzard, Dominos, Bartender4, AzeriteUI, DiabolicUI3
- 🖥️ **Multi-version support** — Retail, Mists of Pandaria Classic, and Vanilla (Classic Era)
- 🎨 **Fully customizable** — Font, color, size, position, outline, alpha, and more
- 🔄 **Three display modes** — Overlay, Native Rewrite, and Auto-Fallback
- 👤 **Profile system** — Global, per-character, and per-spec profile switching
- ⚡ **Event-driven** — Overlays update automatically when bindings change

---

## Quick Start

1. **Install** — Drop the `AdvancedHotkeyOverlaySystem` folder into your `AddOns` directory.
2. **Log in** — AHOS auto-detects your action bar addon and displays overlays immediately.
3. **Open settings** — Type `/ahos` in chat or left-click the minimap icon.
4. **Customize** — Adjust font, size, color, position, and abbreviation style to taste.

That's it. No configuration required to get started. See [[Installation]] for full details.

---

## Game Version Support

| WoW Version | Interface Version | Notes |
|---|---|---|
| Retail (Mainline) | 11.0.7 – 12.x | Full feature support |
| Mists of Pandaria Classic | 5.0.x | Full feature support |
| Vanilla / Classic Era | 1.15.x | Full feature support |

---

## Supported Action Bar Addons

| Addon | Support Level |
|---|---|
| **Blizzard** (default UI) | ✅ Full |
| **Dominos** | ✅ Full (including native text mode) |
| **Bartender4** | ✅ Full |
| **AzeriteUI** | ✅ Full |
| **DiabolicUI3** | ✅ Full |
| **ElvUI** | ⚠️ Detected — enable compatibility option if needed |

See [[Supported-Addons]] for details on each integration.

---

## Wiki Pages

| Page | Description |
|---|---|
| [[Installation]] | How to install, update, and set up AHOS for all WoW versions |
| [[Configuration]] | Every setting explained — display modes, fonts, profiles, and more |
| [[Slash-Commands]] | Full list of `/ahos` commands with examples |
| [[Supported-Addons]] | Addon-specific notes, quirks, and integration details |
| [[FAQ]] | Answers to the most common questions |
| [[Troubleshooting]] | Step-by-step fixes for common issues |
| [[Contributing]] | How to report bugs, request features, and contribute code |

---

## Display Modes at a Glance

```
Overlay Mode (default)         Native Rewrite Mode           Auto-Fallback
─────────────────────          ───────────────────           ─────────────────
Draws a new FontString         Rewrites the button's         Starts in Overlay Mode.
on top of the button.          built-in HotKey text.         If the overlay is hidden
Does not modify native         Best when your skin           by a skin, automatically
button elements.               hides external frames.        switches to Native Rewrite.
```

---

## Abbreviation Engine

AHOS converts full keybind strings into short, readable labels:

| Raw Keybind | AHOS Display |
|---|---|
| `CTRL-SHIFT-A` | `C-S-A` |
| `ALT-1` | `A-1` |
| `SHIFT-F3` | `S-F3` |
| `CTRL-ALT-MOUSEBUTTON2` | `C-A-B2` |
| `F5` | `F5` |

The separator between modifiers is configurable (default: none), and the maximum label length is capped at 6 characters by default (configurable from 1–10).

---

## Author & Links

- **Author:** JuNNeZ
- **Version:** 2.5.18
- **GitHub:** https://github.com/junnez/advancedhotkeyoverlaysystem
- **CurseForge:** https://www.curseforge.com/wow/addons/advanced-hotkey-overlay-system (Project ID: 1289540)
- **WoWInterface:** https://www.wowinterface.com/downloads/info-advanced-hotkey-overlay-system
- **Issues / Bug reports:** [GitHub Issues](https://github.com/junnez/advancedhotkeyoverlaysystem/issues)
