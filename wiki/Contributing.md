# Contributing

Thank you for your interest in contributing to the Advanced Hotkey Overlay System! Contributions of all kinds are welcome — bug reports, feature requests, code, documentation, and localization.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)
- [Setting Up a Development Environment](#setting-up-a-development-environment)
- [Pull Requests](#pull-requests)
- [Adding Support for a New Action Bar Addon (Provider)](#adding-support-for-a-new-action-bar-addon-provider)
- [Localization](#localization)
- [Project Structure](#project-structure)
- [Coding Conventions](#coding-conventions)

---

## Code of Conduct

Be respectful and constructive. This is a community project maintained in the contributor's free time. Issues and PRs that are dismissive or demanding will be closed without response.

---

## Reporting Bugs

A good bug report is the single most valuable contribution you can make. Before opening a new issue:

1. **Search existing issues** — the bug may already be reported.
2. **Check the [[Troubleshooting]] page** — the issue may have a known fix.
3. **Update AHOS** — confirm the bug exists in the latest release.

### What to Include

Open a [GitHub Issue](https://github.com/junnez/advancedhotkeyoverlaysystem/issues) with:

| Field | Details |
|---|---|
| **AHOS version** | Found in the options panel title or the `.toc` file |
| **WoW version** | e.g., Retail 11.0.7, Classic Era 1.15.3 |
| **Action bar addon** | Dominos 10.x, Bartender4, Blizzard, etc. |
| **Other UI addons** | Especially ElvUI, DynamicCam, any UI replacements |
| **Steps to reproduce** | Numbered, specific steps |
| **Expected behavior** | What should happen |
| **Actual behavior** | What actually happens |
| **Debug export** | Output of `/ahos debugexport` — paste the full string |
| **Lua errors** | If you see a Lua error popup, include the full text |

### Lua Errors

Install [BugSack](https://www.curseforge.com/wow/addons/bugsack) or [!BugGrabber](https://www.curseforge.com/wow/addons/bug-grabber) to capture Lua errors reliably. Paste the full error including the stack trace.

---

## Requesting Features

Feature requests are welcome. Before submitting:

- Check that the feature isn't already implemented (see [[Configuration]] for the full option list)
- Check open issues to avoid duplicates

### Good Feature Request Format

```
## Feature Request: <Short Title>

**What problem does this solve?**
<Describe the gap or limitation>

**Proposed solution**
<What you'd like to see, as specifically as possible>

**Alternatives considered**
<Other approaches you thought of>

**WoW versions affected**
<Retail / MoP Classic / Classic Era / All>
```

---

## Setting Up a Development Environment

AHOS is a pure Lua WoW addon — no build system or compilation is needed.

### Requirements

- World of Warcraft installed (any supported version)
- A text editor (VS Code with the [WoW Lua extension](https://marketplace.visualstudio.com/items?itemName=ketho.wow-api) is recommended)
- Git

### Setup

1. **Fork** the repository on GitHub.

2. **Clone** your fork into your WoW AddOns directory:

   ```bash
   cd "World of Warcraft/_retail_/Interface/AddOns/"
   git clone https://github.com/<your-username>/AdvancedHotkeyOverlaySystem.git
   ```

3. **Create a branch** for your change:

   ```bash
   git checkout -b feature/my-feature-name
   ```

4. Make your changes in the Lua/TOC files.

5. **Test in-game:**
   - Log in to WoW
   - After each change, type `/reload` in-game to reload the UI and pick up your edits

6. Enable **Debug Mode** (`/ahos debug`) to see verbose output while testing.

### Iterating Quickly

After editing a `.lua` file, type `/reload` in WoW to pick up changes immediately. You do not need to restart the game client.

For TOC changes or new file additions, you must fully restart WoW (or at minimum, disable and re-enable the addon from the character select screen).

---

## Pull Requests

### Before Submitting

- Test your change in-game on at least one WoW version (Retail preferred)
- If your change affects multiple providers (Blizzard, Dominos, etc.), test each
- Ensure you haven't introduced any Lua errors (`/reload` with BugSack installed is a good check)
- Keep PRs focused — one logical change per PR

### PR Checklist

- [ ] Describe what the PR does and why
- [ ] Reference any related issues (`Closes #123`)
- [ ] Tested in-game without Lua errors
- [ ] Does not break existing behavior
- [ ] Follows existing code style (see [Coding Conventions](#coding-conventions))
- [ ] Updated relevant wiki pages if behavior changed

### PR Title Format

```
[Feature] Add support for XYZ addon
[Fix] Overlays not appearing on ExtraActionButton after vehicle exit
[Chore] Clean up deprecated API calls
[Docs] Update Troubleshooting page
```

---

## Adding Support for a New Action Bar Addon (Provider)

Adding a new action bar provider is the most impactful type of contribution. Here's what's involved:

### Step 1 — Identify the Button Frames

Use `/fstack` (WoW frame inspector) or a UI debugging addon to find the frame names of the action buttons created by the addon. You need:

- The frame name prefix (e.g., `DominosActionButton`)
- The naming convention (e.g., `Prefix1` through `PrefixN`, or a nested structure)
- Any special parent frames

### Step 2 — Understand the Keybind API

Determine how the addon reports keybinds:

- Does it use the standard `GetBindingKey("ACTIONBUTTON1")` etc.?
- Does it have its own keybind table or API (like Dominos)?
- Is LibKeyBound-1.0 involved?

### Step 3 — Implement the Provider Module

Look at the existing provider modules in the `modules/` directory for patterns to follow. A provider module typically:

1. Detects whether the addon is loaded (`C_AddOns.IsAddOnLoaded("AddonName")` or equivalent)
2. Returns a list of button frame references to track
3. Implements a keybind resolver function for its buttons (if the standard API doesn't suffice)
4. Hooks any addon-specific events that indicate button/binding changes

### Step 4 — Register the Provider

Register the new provider with the AHOS core provider registry. Follow the pattern of existing provider registrations in the main addon file.

### Step 5 — Test

- Test with at least the provider's most common configuration
- Test adding/removing bars mid-session
- Test `/ahos reload` and `/ahos detectui`
- Test with debug mode on (`/ahos debug`) to verify events fire correctly

### Step 6 — Submit a PR

Include in the PR description:
- The addon name and CurseForge link
- WoW versions you tested on
- Any known limitations

---

## Localization

AHOS uses locale files in the `locales/` directory. Each locale file corresponds to a language code (e.g., `enUS.lua`, `deDE.lua`, `frFR.lua`).

### Adding or Updating Translations

1. Find or create the locale file for your language in `locales/`.
2. Add or update the string entries following the existing format.
3. Test in-game with that locale set (change your WoW client language in Battle.net settings).
4. Submit a PR with your changes.

### String Format

```lua
-- locales/deDE.lua
local L = LibStub("AceLocale-3.0"):NewLocale("AdvancedHotkeyOverlaySystem", "deDE")
if not L then return end

L["Enable Addon"] = "Addon aktivieren"
L["Font Size"] = "Schriftgröße"
-- etc.
```

Strings that have not been translated fall back to the `enUS` (English) base locale automatically.

### Priority Languages

The following languages are most commonly used by the WoW playerbase and are high priority for localization:
`enUS`, `deDE`, `frFR`, `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `koKR`, `ptBR`

---

## Project Structure

```
AdvancedHotkeyOverlaySystem/
├── AdvancedHotkeyOverlaySystem.lua             ← Core: initialization, event handling, overlay engine
├── AdvancedHotkeyOverlaySystem.toc             ← Shared addon metadata
├── AdvancedHotkeyOverlaySystem_Mainline.toc    ← Retail-specific interface version
├── AdvancedHotkeyOverlaySystem_Mists.toc       ← MoP Classic interface version
├── AdvancedHotkeyOverlaySystem_Vanilla.toc     ← Classic Era interface version
├── Libs/                                        ← Bundled libraries (do not edit)
├── locales/                                     ← Locale strings per language
├── media/                                       ← Textures, embedded fonts, other assets
└── modules/                                     ← Feature modules
    ├── providers/                               ← One file per supported action bar addon
    ├── options/                                 ← Options panel UI definition
    ├── profiles/                                ← Profile management logic
    └── abbreviations/                           ← Keybind abbreviation engine
```

---

## Coding Conventions

AHOS follows standard WoW Lua conventions:

- **Indentation:** Tabs (not spaces)
- **Naming:**
  - Local variables and functions: `camelCase`
  - Module-level or global references: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
- **Nil checks:** Always guard against nil before calling methods on potentially-nil values
- **API compatibility:** Use version-safe API calls where Retail and Classic APIs differ. Use `C_AddOns` where available, with fallback to `IsAddOnLoaded` for older versions.
- **No global pollution:** All AHOS code should be namespaced under the `AHOS` table or within local scope
- **Comments:** Add comments for non-obvious logic, especially around WoW API quirks

### WoW API Version Compatibility

When using APIs that differ between Retail and Classic:

```lua
-- Good practice: version-safe addon detection
local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded)("SomeAddon")
```

Check the [WoWpedia API reference](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API) for API availability by version.
