# AHOS Development Roadmap

**Current release:** 2.5.24 · **Next release:** everything under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md)

The roadmap written for 2.5.6 (November 2025) is done. This page records where each of its items landed, what was decided against and why, and what is left.

---

## Done

### Bugs and performance

- ✓ Overlays persist through dragonriding, vehicles, possess and override bars (2.5.5–2.5.6)
- ✓ Incremental updates: one changed action slot updates only the buttons showing it
- ✓ Debounced refreshes: a burst of bar events runs one series of passes, and passes stop once the bars settle
- ✓ Performance profiling: `Tools/TestCore.lua` times a full update over 300+ buttons on every run
- ✓ LibKeyBound keybind mode is followed even when LibKeyBound loads after AHOS (Known Issue 4)
- ✓ No blank hotkey text after the first login when AHOS lets go of a button before the bar filled its label (Known Issue 5)

### Bar addons

- ✓ Blizzard, AzeriteUI, Dominos, Bartender4, DiabolicUI
- ✓ LUI (bottom and side bars) and Neuron (action and pet bars, its own key lists)
- ✓ Dominos (and every scanned addon) past its usual button count
- ✓ Supported addons documented: [wiki/Supported-Addons.md](wiki/Supported-Addons.md)
- ✓ Bar addons' own fading (Bartender4, Dominos, ElvUI mouseover) carries the hotkey text with it

### Placement and look

- ✓ Per-bar anchor and offsets (Bars page: A Place of Its Own)
- ✓ Drag-to-place editor: `/ahos edit` (Shift-drag for one bar, Save as Profile)
- ✓ Live preview in the options window, and the real bars light up on a change
- ✓ Presets for common looks (Blizzard Style, Big and Centered, Bottom Corner, Compact)
- ✓ Mouse button icons, gamepad glyphs for every controller family
- ✓ Colour by modifier (Shift, Ctrl, Alt, several)
- ✓ Shadow colour and offset, glow, background plate
- ✓ Custom fonts through LibSharedMedia
- ✓ Press animation (flash or pulse)

### When the text shows

- ✓ Fade out of combat, with a faded alpha and fade time
- ✓ Mouseover per bar
- ✓ Only while a modifier is held
- ✓ A Lua condition of your own, in a sandbox
- ✓ A different colour and size in combat
- ✓ Empty slots show nothing
- ✓ Leave one button alone (Inspector card, `/ahos ignore`)
- ✓ Both keys on a button with two (Show Both Keys)

### Profiles

- ✓ Quick switching: `/ahos profile <name>`, `/ahos profiles`
- ✓ Role templates: Tank, Healer, Damage presets
- ✓ Snapshots and rollback (`/ahos snapshot`, `/ahos rollback`), taken by themselves before presets, imports, resets and restores
- ✓ Switching by specialization or by talent loadout, chosen per character
- ✓ Sharing through export and import strings

### Tooling and docs

- ✓ Follow Masque Skin: the overlay reads the skin's own place for the hotkey (`_MSQ_CFG.Skin.HotKey`) and follows a skin change
- ✓ `modules/Display.lua` split into DisplayShared, Display, DisplayNative and DisplayStyle; `modules/Options.lua` into one file per page
- ✓ Type annotations for the Lua language server (`types/AHOS.lua` and the public methods); warnings across the workspace down from 962 to about 400, most of them in the bundled libraries and the options window
- ✓ Russian and Ukrainian (ЙЦУКЕН), Korean (두벌식) and Taiwanese (注音) boards on the Abbreviations page; Cyrillic, Korean and Chinese text drawn in the game's own faces on any client

- ✓ Mock WoW client and test suites for the options window, the engine and the translations (`lua Tools/RunTests.lua`), run in CI for every client TOC
- ✓ Developer guide, module overview and SafeCall in [wiki/Contributing.md](wiki/Contributing.md)
- ✓ Options split across `options/` files (the window) and `modules/Options.lua` (the table both windows draw)
- ✓ Translations for German, Spanish, French, Portuguese, Russian, Korean and Chinese

### Clients

- ✓ Retail, WoW Forever, Mists of Pandaria Classic, Classic Era (Hardcore and Season of Discovery use Classic Era's bars). Cataclysm Classic has been replaced by Mists Classic.

---

## Decided against

| Item | Why |
|---|---|
| Cloud sync of profiles | Profiles are already account-wide (SavedVariables); the game gives addons no other storage. Export strings cover moving between accounts. |
| Plater integration | Plater draws nameplates, which have no key bindings. |
| TellMeWhen integration | TellMeWhen's icons are not action buttons and have no bindings to show. |
| OPie / BindPad integration | Their keys are not on action buttons. AHOS only draws on action buttons. |
| WeakAuras export and sync | WeakAuras is not an action bar. The Lua condition covers showing text by any state an aura would check. |
| Online preset repository, Discord bot | Not addon work; export strings can be shared anywhere. |

---

## Still open

- **In-game verification** of the 2.6 features on every client: the test harness runs against a mock client, not the game.

---

## Development principles

- All Lua passes `.vscode/scripts/lint-lua.ps1` and `lua Tools/RunTests.lua`
- No Lua errors or taint; nothing protected is touched in combat
- Every client TOC loads the same files (Camelot in sync with Mainline)
- `SafeCall` for cross-module calls during loading
- Debounce high-frequency events; pool frames

**Maintainer:** JuNNeZ · **License:** All Rights Reserved
