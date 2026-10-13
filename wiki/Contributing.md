# Contributing

Thank you for your interest in contributing to the Advanced Hotkey Overlay System! Contributions of all kinds are welcome — bug reports, feature requests, code, documentation, and localization.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)
- [Setting Up a Development Environment](#setting-up-a-development-environment)
- [Running the Tests](#running-the-tests)
- [How the Modules Work Together](#how-the-modules-work-together)
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

## Running the Tests

AHOS has a test harness that loads the addon against a mock WoW client, so most changes can be checked without starting the game. You need Lua 5.1 (`lua5.1` on Linux, [LuaBinaries](https://luabinaries.sourceforge.net/) or Lua for Windows).

From the addon folder:

```bash
lua Tools/RunTests.lua             # every suite, against every client TOC
lua Tools/RunTests.lua TestCore    # one suite
lua Tools/TestCore.lua AdvancedHotkeyOverlaySystem_Vanilla.toc   # one suite, one client
```

| File | What it does |
|---|---|
| `Tools/Mock.lua` | The mock client. Loads every file a TOC lists, in order, with the real pure-Lua Ace3 libraries and stand-ins for the ones that draw. Frames record their text, colours, points and scripts, so a test can read what was drawn. `game.MakeButton(name, { action = n })` makes an action button; `game.bindings`, `game.actions`, `game.combat`, `game.shift`, `game.cursor` and `game.lockdown` set the client's state; `game.fire(event, ...)` fires an event and `game.flush()` runs pending timers. |
| `Tools/TestPanel.lua` | The options window: every page, every row bound, the preview, the changed-from-default marks, search, the landing page under ESC > Options > AddOns, the multi-line field. |
| `Tools/TestCore.lua` | The engine: key detection on Blizzard, Dominos, Bartender4, LUI and Neuron buttons, abbreviations and mouse icons, overlays, per-bar placement, glow and plate, ignored buttons, the visibility rules, combat style, press animations, the editor, presets, snapshots, profile switching, the LibKeyBound hook, the slash commands, and a timing of a full update over 300+ buttons. |
| `Tools/TestLocales.lua` | Every locale loads; every string the modules ask for is in enUS; every translation keeps its `%s` and `%d`. |
| `Tools/RunTests.lua` | Runs each suite in its own process for each client TOC and exits non-zero on a failure. |

CI runs `lua5.1 Tools/RunTests.lua` on every push and pull request (`.github/actions/verify`), after the Lua syntax, TOC and version checks.

**Translations.** Module strings are named constants (`L.SOME_KEY or "English"`). New ones go in `Tools/translations_roadmap.py` (English plus de, es, fr, pt, ru, ko, zhCN, zhTW); the options window's own strings are keyed by their English text in `Tools/translations.py`. Then run `python Tools/MakeLocales.py <file with the options/*.lua text>` to write them into `locales/`. `TestLocales` fails if a new string has no entry.

**Art.** `python Tools/MakePanelArt.py` draws the options window's art and `python Tools/MakeGlyphs.py` the mouse icons (both need Pillow).

---

## How the Modules Work Together

Every module is an AceAddon module created in `AdvancedHotkeyOverlaySystem.lua` and filled in by its file under `modules/`:

| Module | Job |
|---|---|
| **Config** | The default profile (`GetDefaultProfile`) and the font list |
| **Core** | Events: bindings, paging, vehicles, combat. Batches refreshes into one series of passes (`ScheduleRefreshPasses`) and hooks LibKeyBound |
| **Performance** | The update queue: `QueueFullUpdate` and `QueueButtonUpdate`, processed together 0.1 s later |
| **Bars** | Finds the buttons (`GetAllButtons`), names their bars (`GetBarInfo`), and keeps per-bar and per-button settings |
| **Keybinds** | The key on a button (`GetFullBindingText`), its abbreviation (`GetBinding`), glyphs and icons |
| **Display** | Draws the overlays or rewrites the native labels, and gives the labels back. Four files: `DisplayShared.lua` (state and helpers, shared as `privateScope.DisplayShared`), `Display.lua` (the update flow), `DisplayNative.lua` (the buttons' own labels), `DisplayStyle.lua` (font, place, Masque, glow, plate, scale) |
| **Visibility** | Fades the overlays by the visibility rules, the combat style, press animations |
| **Editor** | `/ahos edit` |
| **Profiles** | Presets, snapshots, switching profiles |
| **Options** | The option table, in AceConfig's format, which the options window (`options/`) reads and draws. `Options.lua` puts it together from one file per page (`OptionsStatus`, `OptionsDisplay`, `OptionsText`, `OptionsBars`, `OptionsProfiles`), which share `Options.Helpers` |

A change flows: an event → `Core:FullUpdate()` → `Performance:QueueFullUpdate()` → `Display:UpdateAllOverlays()` → for each button `Keybinds:GetBinding()` and `Display:StyleOverlay()` → `Visibility:Track()`.

**Types.** `types/AHOS.lua` describes the profile, the providers, overlays, snapshots and every module for the Lua language server (it is not loaded by the game or packaged). Each module file declares its class where it takes its module (`---@class AHOSDisplay` above `local Display = addon.Display`), so methods defined there are known everywhere. Check the workspace with the language server's `--check` mode.

**SafeCall.** Until the player is in the world, `addon:SafeCall(moduleName, method, ...)` queues the call (the same call without arguments only once) and runs the queue when `addon:SetReady()` is called on `PLAYER_LOGIN`. After that it calls straight through. Use it for any cross-module call that can happen during loading.

**Bar addons** are data, not code: each is an entry in `addon.ProviderRegistry` in the core file (see [Adding Support for a New Action Bar Addon](#adding-support-for-a-new-action-bar-addon-provider)).

---

## Pull Requests

### Before Submitting

- Run `lua Tools/RunTests.lua` and make sure every run passes
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

### Step 3 — Describe the Provider

A provider is an entry in `addon.ProviderRegistry` in `AdvancedHotkeyOverlaySystem.lua`, plus its key in `PROVIDER_ORDER`. The fields:

| Field | What it says |
|---|---|
| `addon` / `addons` / `globals` | How to tell the addon is loaded |
| `button_patterns` | Lua patterns that match its button names |
| `button_scanners.globals` | `{ prefix, max }`: buttons named `prefix1`..`prefixN` (scanning goes on past `max` while names continue) |
| `button_scanners.containers` | `{ prefix, count, matcher }`: bar frames whose children are the buttons |
| `binding_rules` | `{ matcher, suffixes }`: the key is found on `CLICK <button><suffix>` |
| `bound_keys_path` | For addons that bind with override bindings: where on the button its own key list is (Neuron: `{ "keys", "hotKeys" }`) |
| `hotkey_fields` | The button's label field when it is not `HotKey` (Neuron: `Hotkey`) |
| `hotkey_update_method(s)` | The method that redraws the label, hooked so AHOS rewrites after it |

Then add the bar names to `BAR_PATTERNS` in `modules/Bars.lua`, so the Bars page names its bars.

### Step 4 — Add It to the Tests

Make a few of its buttons in `Tools/TestCore.lua` with `game.MakeButton`, give them bindings in the `bindings` table at the top, and check what `Keybinds:GetBinding` and `Bars:GetBarInfo` answer (the LUI and Neuron checks are the pattern).

### Step 5 — Test In Game

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
├── AdvancedHotkeyOverlaySystem.lua             ← Modules, provider registry, SafeCall, slash commands
├── AdvancedHotkeyOverlaySystem.toc             ← Development TOC (not packaged)
├── AdvancedHotkeyOverlaySystem_Mainline.toc    ← Retail
├── AdvancedHotkeyOverlaySystem_Camelot.toc     ← WoW Forever (keep its file list in sync with Mainline)
├── AdvancedHotkeyOverlaySystem_Mists.toc       ← MoP Classic
├── AdvancedHotkeyOverlaySystem_Vanilla.toc     ← Classic Era
├── Libs/                                        ← Bundled libraries (do not edit)
├── locales/                                     ← Strings per language (generated blocks from Tools/)
├── media/                                       ← Logo, options window art (panel/), mouse icons (glyphs/)
├── modules/                                     ← The engine (see How the Modules Work Together)
├── options/                                     ← The options window
├── Tools/                                       ← Test harness, locale and art generators (not packaged)
└── wiki/                                        ← This wiki (published on push)
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
