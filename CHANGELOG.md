# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.1] - 2026-10-13

### Added (3.0.1)

- Hide the Range Dot (Display page): the dot the game puts on a button with no key while its action is in range is hidden, also while AHOS is turned off. Off by default.

### Changed (3.0.1)

- The controllers on the Controller tab are redrawn: the Xbox, DualSense and Switch Pro bodies follow the real controllers' outlines, the Steam Deck is taller with a trackpad under each stick, and every button sits where it does on that controller.

- Pulse now flashes in the Flash Colour too, as well as growing; the colour can be picked for either.

### Fixed (3.0.1)

- With Hide Original Hotkey Text on, a button with no key showed the range dot (●) that Blizzard and LibActionButton (AzeriteUI, Bartender4, DiabolicUI) put on it. It now shows nothing, also after the bar redraws it. A key AHOS cannot read still shows the button's own text.
- Pressing a key bound to a button on Blizzard's bars did not flash or pulse the text: the game runs those keys through ActionButtonDown and MultiActionButtonDown, which AHOS now listens to as well as clicks.
- Empty buttons on Blizzard's extra bars (bottom right, bottom left, right, left and bars 5-7) showed the main bar's key for their number: the sixth button showed "6", the twelfth "a-c-s-1". AHOS asked the button to redraw its label without saying which bar it is on, and Blizzard then reads the main bar's binding. AHOS now passes the bar's own binding type, as Blizzard does, so an empty button stays empty and turning AHOS off puts back each bar's own keys.

## [3.0.0] - 2026-10-13

First published as 2.6.0; renumbered to 3.0.0 because of how much changed. The content is the same.

### Added (3.0.0)

- Colour by Modifier (Keybinds page): Shift, Ctrl and Alt bindings each get their own colour, with a fourth for two or more modifiers. "Hide Modifier Letters" then shows "Q" in the Shift colour instead of "SQ". The live preview and the keyboard on the Abbreviations page show the colours too.
- Anchor Point is a 3x3 grid on a button in the options window.
- Changing a Display, Keybinds or Abbreviations setting in the options window briefly lights up the overlays on your real action bars, so you see the change on your own UI and not only in the preview.
- The Font list draws each font's name in that font.
- Controller Button Icons (Abbreviations page, on by default): gamepad buttons are drawn as your controller's own button icons, in the label style of the controller in use, instead of text. A gamepad button you gave an abbreviation of your own keeps it.
- A Bars page: give one bar its own text size, or leave it to its own hotkey text. Bars are found on Blizzard's bars and in AzeriteUI, Dominos, Bartender4 and DiabolicUI.
- An Inspector page: click Pick a Button and point at any action button to see which bar addon drew it, on which bar, the key that presses it, the text AHOS draws for it, the command and action on it, and why. It replaces needing the button's name for `/ahos inspect`, which still works.
- The Abbreviations keyboard is a full-size board with a mouse: function row, Print Screen, Scroll Lock and Pause, the navigation block with the arrow keys, and the numpad, plus a mouse with its wheel and side buttons. Extra mouse buttons 6-12 are always shown, higher ones and any other bound key (F13, a gamepad button) appear once bound. "Find a Key" picks the next key or mouse button you press, even one on neither model. On a narrow window the navigation block and numpad move under the main block.
- Keyboard layouts on the Abbreviations page: English (US), English (UK), Dansk, Norsk, Svenska / Suomi, Deutsch and Français, each with the keys that board has (Æ Ø Å, Ö Ä Ü ß, AZERTY) and the names printed on them, and the tall Enter of ISO boards. The layout follows the client's language until you pick one.
- Controller Icon Style (Abbreviations page): Automatic, Xbox, PlayStation, Nintendo Switch or Generic. Each draws the client's own glyphs for that controller (the KEY_ABBR_*_LTR, _SHP and _REV strings in SharedConstants.lua), on the Controller tab and on your bars alike.
- A Controller tab on the Abbreviations page: a gamepad with triggers, bumpers, sticks, D-pad and face buttons, named in the game's own glyphs or as Xbox, PlayStation or Nintendo Switch name them, with Shift, Ctrl and Alt to latch. It opens first when the gamepad is switched on.
- The Controller tab draws the controller you have: Xbox, PlayStation (DualSense, with its touchpad halves and mic button), Nintendo Switch Pro, Steam Deck (screen, trackpads, L4/L5/R4/R5) or Steam Controller (two trackpads), each in its own shape with its buttons where that brand puts them. Automatic picks the brand from the game's own glyph for the bottom face button. Button positions follow ConsolePort's device layouts; the drawings are AHOS's own.
- Hold Shift, Ctrl or Alt on the Abbreviations page and the keyboard shows that layer until you let go; a key you press lights up. Keys still reach the game, and listening stops in combat.
- A key bound only with another modifier says so in its tooltip, with what each combination does.
- The mouse is drawn as a mouse, right of the numpad. When the page narrows, keys shrink only to a comfortable size; then a block moves under the others and the keys grow back.
- A key's card opens in a slice docked beside the options window, on whichever side has room, so it stays in view at any UI scale instead of under the keyboard.
- Bind from the keyboard: a key's card on the Abbreviations page can bind the key to any action button, unbind it, or start LibKeyBound's hover-and-press mode where a bar addon brought it.
- A Status overview: a chip per bar addon with how many buttons AHOS found, in that addon's colour, how many buttons carry AHOS text, and a warning when ElvUI is loaded.
- Two themes: Keycap Backlit, a darker board where the selected page and every switch that is on glow softly, and Keycap Legend, cream keycaps with a brass edge.
- "Light Up My Bars" on the Window page turns the bars' flash off.
- The debug log, the exports and the inspector's details open in the options window's look, with Select All for copying. The log and an export can be open side by side.
- The options window and every new setting are translated into German, Spanish, French, Portuguese, Russian, Korean and Chinese (Simplified and Traditional). `Tools/MakeLocales.py` writes them from `Tools/translations.py`.
- Visibility rules (Display page): Fade Out of Combat, Only While a Modifier Is Held, a Faded Alpha and a Fade Time, and a Condition of Your Own, a Lua expression that can read the button, its bar, its key and the game's read-only state. Every rule you turn on must agree for the text to show.
- Show on Mouseover per bar (Bars page): that bar's text shows only while the mouse is over it.
- A Place of Its Own per bar (Bars page): an anchor and X and Y offsets for one bar.
- `/ahos edit` and Edit Positions on Your Bars: drag the hotkey text into place on your own bars. Shift-drag moves one bar, right-click gives it back to the profile, Save as Profile keeps the result as a new profile. It ends when combat starts.
- Combat Style (Display page): another colour and size for the text while you are in combat.
- When Pressed (Display page): the text flashes or pulses when you press its button.
- Background Plate (Display page): a plate behind the text, in a colour and padding of your choice.
- Shadow and Glow (Keybinds page): the shadow's colour and offset, and a glow in its own colour around the text.
- Show Both Keys (Keybinds page): a button bound to two keys shows both, with the text between them of your choice.
- Mouse Button Icons (Abbreviations page): mouse buttons and the wheel are drawn as small mouse icons in the text's colour; side buttons carry their number.
- Presets (Profiles page and `/ahos preset`): Blizzard Style, Big and Centered, Bottom Corner, Compact, and the Tank, Healer and Damage templates, laid over the current profile.
- Snapshots (Profiles page, `/ahos snapshot`, `/ahos rollback`): copies of a profile to go back to, kept for every character. One is taken by itself before every preset, import, reset and restore.
- `/ahos profile <name>` switches profile, making it from the current one when it is new; `/ahos profiles` lists them. Save as New Profile on the Profiles page does the same.
- Switch Profile By Itself can follow the talent loadout as well as the specialization.
- Leave This Button Alone (Inspector card, `/ahos ignore <ButtonName>`): AHOS leaves one button to its own hotkey text.
- LUI and Neuron support: LUI's bottom and side bars, and Neuron's action and pet bars, including the keys Neuron keeps on its buttons.
- Follow Masque Skin (Display page, with Masque loaded): on buttons Masque skins, the hotkey text goes where the skin puts the hotkey (corner, offset, width and alignment, read from the skin itself) and follows a skin change. The font and colour stay yours.
- Keyboard layouts on the Abbreviations page: Русская and Українська (ЙЦУКЕН), 한국어 (두벌식, with Hangul under each letter and the 한/영 and 한자 keys) and 繁體中文 (注音, with Zhuyin). The layout follows a Russian, Korean or Taiwanese client until you pick one.
- Cyrillic, Korean and Chinese key names are drawn in the game's own faces for them, on your bars and in the options window, so they no longer show as boxes on a client in another language. Cyrillic keys show in capitals, as the Nordic letters do.
- A test harness: `lua Tools/RunTests.lua` runs the options window, engine and translation suites against a mock client for every client TOC, and CI runs it on every push. The engine suite covers key detection on every supported bar addon and times a full update.

### Changed (3.0.0)

- Keycap Gold is the options window's default theme. A window you already opened keeps the theme it has; pick Keycap Gold on the Window page to switch.
- Sliders, switches and buttons are tighter: thinner tracks shaded to read as sunk, fills shaded to read as raised, and knobs with a ring and a shadow.
- Switches and sliders are redrawn sharp: a pill track and a round knob, sized in whole screen pixels for the UI scale and window scale they are drawn at (and again when either changes). A switch that is on fills its track with the accent; off, the track is a sunk inset with a one-pixel edge. The knob has a hard pixel of shadow instead of the blurred halo and ring, and slides over when clicked.

- Font Outline offers six choices. The two alias spellings (MonochromeOutline, MonochromeThickOutline) are no longer listed; profiles that still hold them show and keep working as Monochrome + Outline and Monochrome + Thick Outline.
- Colour by Modifier also colours native text mode, through a colour code, so nothing stays on the label when it gets its own text back.
- A burst of bar events (combat starting fires several) runs one series of refresh passes instead of one per event, and the later passes are skipped once the bars have settled.
- The list of action buttons is scanned at most twice a second outside full updates, and the font list is built once instead of for every overlay each time it is styled.
- Every overlay update goes through the batched update. The core file's second set of event handlers is gone: Core's handles all of them.
- `/ahoslog` no longer catches other addons' `print` output: AHOS no longer replaces the global `print`.
- Switching profile with the specialization is now a choice per character. It used to live in the profile it switched away from, so a new profile never switched back; it moves by itself. A profile it switches to for the first time starts as a copy of the one you were on instead of the defaults.
- A bar addon set up with more buttons than usual (Dominos past 200) has all of them found.
- For contributors: `modules/Display.lua` is four files (DisplayShared, Display, DisplayNative, DisplayStyle) and `modules/Options.lua` one file per page (OptionsStatus, OptionsDisplay, OptionsText, OptionsBars, OptionsProfiles); `types/AHOS.lua` describes AHOS's tables and modules for the Lua language server.

### Fixed (3.0.0)

- Hotkey text placed in the top-right corner (the Blizzard Style and Healer presets, or an anchor of your own) vanished: the search for a button's own hotkey label took AHOS's text for it, hid it, and kept hiding it after the next preset too. AHOS's own text is now never taken for a button's label.
- The Condition of Your Own field could not be typed in: the box inside it was one pixel tall, so neither text nor caret showed. It fills the field now, grows with the text, and the page no longer redraws under a field you are typing in.
- The Korean and Taiwanese keyboards cut each key's legend to "Q…": the Hangul or Zhuyin now sits in the key's other corner, as on the real keycap.
- Key names on the Abbreviations keyboard were cut short ("Ind…", "Pau…", the mouse's wheel): text too wide for its key is now drawn smaller instead, in every language. Chinese and Korean characters are drawn two sizes larger than Latin ones.
- Follow Masque Skin read the skin's own HotKey table, which most skins leave to Masque's defaults, so the text did not move with the skin. It now reads where Masque actually put the button's hotkey label, and the skin table is only the fallback.

- Core's own events never registered: they were queued before AHOS was ready, and the queue dropped every call. Leaving a vehicle, the pet bar, possess and stance changes now refresh the overlays as intended, and anything else queued at login runs.
- One action slot changing ran a full update of every button at once. It now updates the buttons on that slot, all of them when two bar addons show the same slot.
- Messages meant for you never reached the chat: `/ahos help` printed nothing, nor did imports, lock and unlock. Debug output still goes only to `/ahoslog`.
- A provider default that would have reset your X Offset, Y Offset and Scale at login is gone. It only stayed harmless because of the queue bug above.
- Every dropdown after the Font list was drawn in the fonts from that list: a reused row kept the font it was given.
- With a bar addon drawing (AzeriteUI, Dominos, Bartender4), the Bars page no longer lists the Blizzard bars that addon hides or fades to nothing.
- Keys with a letter like Æ, Ø, Å, Ö or É were missing from the Nordic, German and French boards and listed under "Other bound keys" instead: the game names them in lower case (æ, ø, å). The boards use those names now, Find a Key finds them, and your buttons show them in capitals.
- The layout list's arrow and the arrow keys' legends showed an empty box: the game's font has no such characters. The list now has a drawn chevron and the keys say Up, Down, Left and Right.
- "Leave This Bar Alone" on an AzeriteUI or Bartender4 bar left its buttons with no hotkey text: LibActionButton redraws its label through a function that is not on the button. AHOS now asks the button for its hotkey, or falls back to the game's own key text.
- The classic window now refreshes when the detected bar addon or the profile changes (it was told under the wrong name).
- Turning AHOS off, or leaving a bar alone, right after the first login could leave a button with no hotkey text until `/reload`: the bar had not filled in its label before AHOS drew, so there was nothing to put back. AHOS now writes the key text the label would show.
- Dominos', Bartender4's and LUI's keybind mode was not followed when LibKeyBound loaded after AHOS. AHOS now looks for it each time an addon loads.

### Removed (3.0.0)

- The classic window (the generated Ace3 options window) and the "Open the Classic Window" setting and button. Several new settings did not work in it, and the options window covers every setting. `/ahos classic` now opens the options window. AceGUI-3.0 and AceConfig-3.0 are no longer bundled.

- `modules/JUI.lua`, the earlier handmade options window, which nothing opened any more.
- A "hide in combat" path with no setting to turn it on, a second locale table nothing read, 58 unused strings in the locale files, and other dead code.

## [2.5.24] - 2026-10-10

### Added (2.5.24)

- A new options window, drawn in AHOS's own keycap art: a rail of pages with their own icons, one search box across every setting, a mark on every setting that differs from its default with a one-click revert, and four themes (Keycap, Keycap Gold, Class Color, Light) with opacity and scale.
- A live preview at the top of the Display and Keybinds pages: four action buttons labelled exactly as AHOS would label them, with your own bindings for action buttons 1-4.
- The Abbreviations page is a keyboard instead of 104 text boxes. Keys bound to an action button light up and show the text AHOS draws for them; Shift, Ctrl and Alt latch to show that layer. Clicking a key opens a card with its abbreviation, the command the game runs, any override an addon has put over it, and every action button (with its bar addon, spell and icon) that answers to the key, with a warning when two bar addons claim the same key.
- Every key can now carry an abbreviation of its own, not only the 104 with a built-in default.
- ESC > Options > AddOns > Advanced Hotkey Overlay System is now a landing page, as in AzeriteUI JuNNeZ Edition: the logo, the version, what AHOS is drawing on, and buttons into the options window or the classic one. Clients without the canvas Settings API keep the embedded Ace3 page.
- `/ahos classic` opens the previous Ace3 window, which stays available and shows the same settings.
- `Tools/TestPanel.lua` drives the options window against a mock client for every client TOC, and runs in CI.

### Changed (2.5.24)

- The Status page is now an overview: the quick switches and the minimap icon moved onto it, Debug Mode moved to Debugging, and Support joined About.

### Fixed (2.5.24)

- AHOS now ships AceDBOptions-3.0 itself. The Profiles page relied on another addon having loaded it, and the whole options table failed to build without one.
- The minimap icon setting no longer counts as changed on a fresh profile.
- Fonts shared through LibSharedMedia are only offered when their file actually loads, and a saved font that no longer loads falls back to the game's font instead of leaving the hotkey text blank.
- Importing a profile string (Profiles > Import Profile Data) and a debug string works again. Both were called with a colon, so they read the addon itself as the text to import and always reported that no string was given.

## [2.5.23] - 2026-10-10

### Added (2.5.23)

- WoW Forever support: new `AdvancedHotkeyOverlaySystem_Camelot.toc` (interface `16001`). Works with the Forever builds of Dominos and AzeriteUI JuNNeZ Edition, which keep their Retail folder and button names.

### Fixed (2.5.23)

- Display and keybind modules no longer treat WoW Forever as a Classic client; client detection now honours the TOC flavor and `WOW_PROJECT_ID` before the interface number.

## [2.5.22] - 2026-08-27

### Fixed (2.5.22)

- Updated Retail action-slot checks from the removed global `HasAction` fallback to `C_ActionBar.HasAction`.
- Replaced the removed `ActionButton_UpdateHotkeys` global hook with hooks on the live `UpdateHotkeys`/`SetHotkeys` button methods used by Retail 12.1.
- Added secret-value access guards for action attributes, frame visibility, names, text, hierarchy, anchors, and frame levels used by overlay discovery and diagnostics.
- Handled `ACTIONBAR_SLOT_CHANGED` slot `0` as a full action-bar invalidation, matching Blizzard's current event contract.
- Replaced deprecated specialization and raid-warning calls with `C_SpecializationInfo` and `RaidWarningUtil`.
- Fixed hotkeys disappearing when toggling **Mirror Native Hotkey Style** by restyling active overlays in place and isolating per-button native-style failures.
- Made full refreshes reconcile in place, preserving the last known-good overlay across transient empty scans and protected-button errors.
- Restored native hotkey labels reliably on disable, cleanup, ElvUI suppression, profile changes, and slash-command toggles.
- Prevented delayed visibility, fallback, and throttled update callbacks from recreating overlays after disable or cleanup.
- Prevented options-panel initialization and appearance-only controls from triggering destructive overlay rebuilds.
- Added a dedicated Abbreviations tab with profile-specific editors for modifiers, mouse buttons, numpad, function keys, special keys, and gamepad inputs.
- Added live abbreviation previews, per-entry default restoration, and a reset-all action without requiring `/reload`.
- Fixed bindings on the hyphen key losing their base key, which rendered `-` as a blank overlay and `CTRL--` as just `C`.
- Added abbreviations for the named gamepad tokens (d-pad, shoulders, triggers, stick clicks and directions, paddles, system buttons) so controller binds no longer show truncated raw tokens such as `CSPA`.
- Stopped recapturing AHOS's own overlay label as the "original" Blizzard hotkey text, which could make an abbreviation stick permanently to a button.
- Cleared pooled overlay labels on release so a recycled overlay can never show the previous button's keybind.

### Changed (2.5.22)

- Migrated add-on enumeration and metadata diagnostics to `C_AddOns`, with Classic-compatible fallbacks.
- Updated Retail TOC compatibility through Midnight 12.1.0 (`120100`).
- Bumped all TOC version metadata and README highlights to `2.5.22`.

## [2.5.21] - 2026-05-03

### Fixed (2.5.21)

- Fixed AzeriteUI dragonflying dismount transitions where several keybind overlays could disappear until combat or another bar-state refresh.
- Added AzeriteUI `:Keybind` click-route binding resolution so overlays follow AzeriteUI's dynamic dragon/bonus action bar routing.
- Made keybind caching state-aware for reused action button names during action, page, and binding-route swaps.
- Prevented transient empty action-slot reads from removing AzeriteUI overlays when a stable keybind still resolves.

### Changed (2.5.21)

- Added `UPDATE_BONUS_ACTIONBAR` refresh handling for dragonflying and bonus-bar state changes.
- Bumped all TOC version metadata to `2.5.21`.
- Updated README version highlights for `2.5.21`.

## [2.5.20] - 2026-04-26

### Fixed (2.5.20)

- Fixed Bartender4 detection and binding resolution so AHOS can discover all Retail Bartender action bars instead of only bar 1.
- Added LibActionButton binding target support for action bar addons that expose `GetBindingAction`, `keyBoundTarget`, or configured click-binding buttons.
- Added Retail extra-bar binding mappings for Blizzard/Dominos-style bars 5, 6, and 7.

### Changed (2.5.20)

- Expanded local compatibility coverage for Dominos Retail native-style buttons, AzeriteUI5 JuNNeZ Edition bars 1-8 plus pet/stance bars, DiabolicUI2/3 aliases, and GW2_UI-style native Blizzard bars.
- Bumped all TOC version metadata to `2.5.20`.
- Updated README and CurseForge compatibility notes for `2.5.20`.

## [2.5.19] - 2026-03-26

### Fixed (2.5.19)

- Removed invalid `PLAYER_BINDING_CHANGED`, `PLAYER_ENTERING_VEHICLE`, and `PLAYER_EXITING_VEHICLE` registrations that now error on WoW `12.0.1`.
- Fixed `LibKeyBound-1.0` callback registration in `modules/Core.lua` by using the correct `RegisterCallback` call form.

### Changed (2.5.19)

- Standardized binding and vehicle refresh logic on valid modern client events already supported by the addon.
- Bumped all TOC version metadata to `2.5.19`.
- Updated README version highlights for `2.5.19`.

## [2.5.18] - 2026-03-21

### Fixed (2.5.18)

- Fixed remaining missing keybind overlays when exiting DynamicCam mount camera mode directly into combat by retrying button recovery until the buttons become effectively visible again.

### Changed (2.5.18)

- Extended delayed combat and bar-state refresh passes to cover longer asynchronous mount-to-combat UI restores.
- Bumped all TOC version metadata to `2.5.18`.
- Updated README version highlights for `2.5.18`.

## [2.5.17] - 2026-03-07

### Fixed (2.5.17)

- Fixed intermittent missing overlay text after mount/combat transitions (with or without DynamicCam) by hooking action-button `OnShow` and reapplying overlays when buttons become visible again.

### Changed (2.5.17)

- Added per-button visibility recovery logic in `modules/Display.lua` with queued and delayed update passes after `OnShow`.
- Bumped all TOC version metadata to `2.5.17`.
- Updated README version highlights for `2.5.17`.

## [2.5.16] - 2026-03-07

### Fixed (2.5.16)

- Fixed a mount-to-combat refresh gap where overlays could miss some keys after DynamicCam-style UI hiding by triggering bar-state refresh passes on combat and mount display transitions.

### Changed (2.5.16)

- Extended `modules/Core.lua` bar-state event coverage with `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, and `PLAYER_MOUNT_DISPLAY_CHANGED`.
- Bumped all TOC version metadata to `2.5.16`.
- Updated README version highlights for `2.5.16`.

## [2.5.15] - 2026-03-07

### Fixed (2.5.15)

- Fixed overlays not returning automatically after possess/vehicle/override bar transitions by adding robust bar-state refresh handling with delayed passes.

### Changed (2.5.15)

- Added a consolidated `HandleBarStateChanged` refresh path in `modules/Core.lua`.
- Expanded event coverage for action-bar state swaps (`UPDATE_OVERRIDE_ACTIONBAR`, `UPDATE_VEHICLE_ACTIONBAR`, vehicle enter/exit events, and possess-related updates).
- Bumped all TOC version metadata to `2.5.15`.
- Updated README version highlights for `2.5.15`.

## [2.5.14] - 2026-03-07

### Fixed (2.5.14)

- Reworked overlay frame layering so Dominos/native-style overlays no longer force `TOOLTIP` strata or extreme frame-level bumps that could cover other addons (e.g., BetterBags).

### Changed (2.5.14)

- Added a new Display option: `Smart Frame Layering`.
- Made Smart Frame Layering opt-in (disabled by default) and treated unset legacy profiles as disabled.
- When Smart Frame Layering is enabled, overlays inherit parent-button strata and use a minimal frame-level offset to stay scoped to action bars.
- Manual strata/frame-level controls are now clearly marked as manual overrides and are disabled while Smart Frame Layering is enabled.
- Bumped all TOC version metadata to `2.5.14`.
- Updated README version highlights for `2.5.14`.

## [2.5.13] - 2026-03-07

### Added (2.5.13)

- Added provider-registry based integrations for Bartender4 and DiabolicUI, including button discovery and provider-aware diagnostics.
- Added a `verify-toc-targets` validation step to the GitHub release workflow.

### Fixed (2.5.13)

- Fixed a secure/secret string comparison taint error in `modules/Display.lua` hotkey-region anchor checks by guarding anchor comparisons.
- Fixed provider hotkey-refresh hooks to use each provider's configured update method instead of a Dominos-only path.

### Changed (2.5.13)

- Refactored UI detection, button scanning, keybind resolution, and options diagnostics around a shared provider model.
- Updated support messaging and settings visibility rules for provider-specific options.
- Bumped all TOC version metadata to `2.5.13`.
- Refreshed README and CurseForge release notes for the provider/taint-fix release.

## [2.5.12] - 2026-03-02

### Fixed (2.5.12)

- Fixed Dominos keybind resolution by preferring the button `commandName` and explicit Dominos hotkey bindings before generic Blizzard action remaps.
- Hooked Dominos button `UpdateHotkeys` refreshes so overlays reapply when Dominos rewrites native labels.
- Replaced another taint-prone top-right anchor heuristic in keybind label discovery with a protected-safe point check.

### Changed (2.5.12)

- Modernized the in-game options panel with new Status, Compatibility, Support, and Debugging sections and removed stale compatibility claims.
- Narrowed direct support messaging to Blizzard, AzeriteUI, and Dominos, with ElvUI kept as conflict-aware handling only.
- Updated package ignores to exclude development-only templates, tests, and library docs from release archives.
- Updated Retail TOCs to `110107, 110200, 120000, 120001`, Mists TOC to `50500, 50501, 50503`, and Vanilla TOC to `11508`.
- Bumped all TOC version metadata to `2.5.12`.
- Refreshed README and CurseForge release notes for the Dominos/options/TOC-target release.

## [2.5.11] - 2026-03-01

### Fixed (2.5.11)

- Added a taint-safe anchor helper in `modules/Display.lua` hotkey region heuristics.
- Replaced direct `GetPoint(1)` anchor string comparisons with protected-safe checks to prevent taint compare errors on secure buttons (e.g., `ExtraActionButton1`).

### Changed (2.5.11)

- Bumped all TOC version metadata to `2.5.11`.
- Refreshed README and CurseForge release notes for the taint-fix release.

## [2.5.10] - 2026-02-27

### Fixed (2.5.10)

- Corrected the GitHub release workflow PowerShell invocation so tag builds no longer fail on startup.
- Added the missing `verify-version.ps1` and `verify-changelog.ps1` scripts expected by the release workflow.

### Changed (2.5.10)

- Bumped all TOC version metadata to `2.5.10`.
- Refreshed README and CurseForge release notes for the packaging hotfix release.

## [2.5.9] - 2026-02-27

### Fixed (2.5.9)

- Restored the Retail and Mainline TOCs to WoW 12 compatibility by setting their interface target to `120000`.
- Preserved the explicit `CallbackHandler-1.0`, `LibDataBroker-1.1`, and real `LibDBIcon-1.0` load order required for packaged builds.

### Changed (2.5.9)

- Bumped all TOC version metadata to `2.5.9`.
- Refreshed README and CurseForge release notes for the WoW 12 compatibility package.

## [2.5.8] - 2026-02-27

### Fixed (2.5.8)

- Loaded `CallbackHandler-1.0` before AceConfig, AceEvent, and LibSharedMedia to stop startup failures in packaged builds.
- Loaded `LibDataBroker-1.1` and the real `LibDBIcon-1.0` implementation explicitly instead of relying on a later embed entrypoint.
- Restored addon initialization so Config, Options, and Core no longer fault after Ace library startup errors.

### Changed (2.5.8)

- Bumped all Retail, Mists, and Vanilla TOC versions to `2.5.8`.
- Refreshed release notes in README and CurseForge docs to match the current release contents.

## [2.5.3] - 2025-09-14

### Fixed (2.5.3)

- Locales: Prevent "attempt to index local 'addon' (a nil value)" by decoupling locale files from addon scope and using a shared global table consumed by the addon at init.
- Retail (AzeriteUI): Filter placeholder square/bullet glyphs on unbound buttons; strengthen native hotkey suppression safeguards.

### Changed (2.5.3)

- Tooling: Replaced failing `lua -p` VS Code task with a robust PowerShell-based sweep using `luac -p` or `assert(loadfile(...))` fallback. Set as default build lint task.
- Documentation: README highlights updated for 2.5.3.

## [2.5.2] - 2025-09-14

### Added (2.5.2)

- Options: Font outline styles (NONE/OUTLINE/THICKOUTLINE/MONOCHROME combos) with legacy fallback retained.

### Fixed (2.5.2)

- Classic: Avoid registering PLAYER_BINDING_CHANGED; gate the event to Retail only using WOW_PROJECT_ID with build fallback.

### Added

- Retail + Classic compatibility in one build; Classic-safe keybinding resolution for ActionButton, BonusActionButton, MultiBars, Stance, Pet, and Possess.
- Hooks to ActionButton_UpdateHotkeys and MultiActionBar_Update to keep native labels hidden while overlays are active.

### Changed

- Multiple delayed overlay refreshes after binding changes (Dominos/LibKeyBound) to avoid reload requirements.
- Simplified in-game settings UI by removing unused modules; retained single JUI module.

### Fixed

- Dominos keybinding mode no longer causes native hotkey text to reappear until reload on Classic.

## [2.5.1] - 2025-09-14

### Added (2.5.1)

- Deep scan for nested hotkey FontStrings (e.g., AzeriteUI TextOverlayContainer) to ensure reliable detection and suppression.
- New debug commands: `/ahos dumphotkey` and `/ahos dumplayers` for targeted troubleshooting.

### Changed (2.5.1)

- Overlay frame level bump to render above nested overlay containers and Masque/AzeriteUI skins.
- Refined native hotkey suppression hooks with safer Show/SetText guards.

### Fixed (2.5.1)

- Classic: Register `PLAYER_BINDING_CHANGED` on Retail only to prevent errors on Classic.
- Retail (AzeriteUI): Removed placeholder square/bullet glyphs on unbound buttons by disabling visual fallback on Retail and filtering fallback glyphs in the visual reader.
- Dominos: Improved overlay visibility without requiring reload; ensured native labels stay hidden when Dominos keybinding mode ends.

## [2.4.2] - 2025-09-03

### Fixed (2.4.2)

- Prevent duplicate Blizzard options category registration by stabilizing app name and checking existing entries.
- Avoid hard errors if AceConfigDialog loads late; /ahos always registers.

### Added (2.4.2)

- Embedded AceGUI-3.0 and wired AceConfig-3.0 Dialog when embedded libs are present.
- /ahos version command.

### Changed (2.4.2)

- Options/About panels now read Version from TOC metadata; removed hardcoded version strings.
- Clarified IconTexture path to media/logo.tga.

## [2.4.1] - 2025-06-24

### Added (2.4.1)

- Debug log window and `/ahoslog` command for viewing/copying all debug output.
- `/ahos inspect <ButtonName>` command to print debug info for any action button.
- Advanced profile management: export/import, auto-switch by spec, copy/reset, and print profile tools in the Profiles Management tab.

### Changed (2.4.1)

- Updated documentation and versioning for 2.4.1.
- Polished options panel and help sections for new features.

## [2.4.0] - 2025-06-24

### Added (2.4.0)

- In-game changelog and version info tab
- Debug export window and /ahos debugexport command
- LibSerialize/LibDeflate support for profile export
- Help & Debugging tab in options

### Changed (2.4.0)

- Updated documentation and versioning for 2.4.0
- Many bugfixes and polish

## [2.3.0] - 2025-06-23

### Modernization & Polish

- Modernized and cleaned up all options panel registration and naming logic
- No more color codes or icons in the options panel or .toc metadata
- Only one options panel is registered, with robust error handling
- Minimap/DataBroker icon and Blizzard options panel now always show the correct, user-friendly name
- ElvUI compatibility and user prompt logic improved
- Legacy and duplicate code removed for reliability
- All overlays and minimap icon logic now robust and error-free

## [2.2.0] - 2025-06-22

### Added (2.2.0)

- Full Ace3 profile management UI (copy, delete, switch, robust handling).
- Overlay settings (font, color, etc.) now update instantly on profile or option changes.
- Lock/unlock feature: `/ahos lock` greys out all options and prevents changes; attempting to change settings while locked shows a high-strata popup with unlock prompt.
- StaticPopup dialog for unlocking settings, with Yes/No options.
- Debug-only button to delete all profiles except the current one.

### Changed (2.2.0)

- Only Ace3 profile management UI is used (custom profile UI removed).
- Improved error handling for profile changes and minimap icon registration.
- Versioning and documentation updated for 2.2.0.

### Fixed (2.2.0)

- No more duplicate options panel errors.
- Profile deletion and switching is now robust and bug-free.
- Minimap icon unregister errors resolved.
- Settings lock now actually prevents changes in the options panel.

---

## [2.1.0] - 2025-06-22

### Added (2.1.0)

- Themed enable message with color-coded branding and version.
- Debug messages now only appear when debug mode is enabled.
- Improved overlay removal and Blizzard hotkey text restoration logic.
- Consistent debug/info/error print handling across all modules.

### Changed (2.1.0)

- Minimap icon logic and event handling improved for reliability.
- Codebase refactored for maintainability and extensibility.

### Fixed (2.1.0)

- Debug messages no longer spam chat in normal mode.
- Overlay and hotkey text restoration now works as expected on disable and minimap toggle.

---

## 2.0.0-alpha - 2025-06-22

### Major Overhaul

- Complete rewrite and modularization of the codebase for maintainability and extensibility.
- Robust event-driven overlay update logic restored and improved.
- ConsolePort-style keybind abbreviation logic: condensed, customizable separator, gamepad/mouse support.
- Overlay frame strata control and improved minimap icon handling.
- Options panel fully revamped: professional About/Credits, version display, and live UI detection.
- All taint, nil, and registration errors eliminated.
- Standardized AceConfig registration and config panel references.
- Added user option for modifier separator in abbreviations.
- Improved debug output and troubleshooting tools.
- Full support for Blizzard, AzeriteUI, and custom action bars.
- Titan Panel integration removed for simplicity; minimap icon is now the sole launcher.

### Fixed (2.0.0-alpha)

- Modifier parsing and abbreviation bugs.
- Overlay update and taint issues.
- Nil and registration errors.
- Keybinding detection for all supported UIs.

---

## 1.0.0 - 2024-06-17

### Added (1.0.0)

- Initial release of Advanced Hotkey Overlay System (AHOS).
- Basic overlay system for Blizzard action bars.
- Simple keybind abbreviation logic.
- Minimap icon and options panel access.

---

[2.4.1]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.1
[2.4.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.0
[2.3.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.3.0
[2.2.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.2.0
[2.1.0]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.1.0
[2.4.2]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.4.2
[2.5.1]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.1
[2.5.2]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.2
[2.5.3]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.3
[2.5.8]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.8
[2.5.9]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.9
[2.5.10]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.10
[2.5.11]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.11
[2.5.12]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.12
[2.5.13]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.13
[2.5.14]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.14
[2.5.15]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.15
[2.5.16]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.16
[2.5.17]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.17
[2.5.18]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.18
[2.5.19]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.19
[2.5.20]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.20
[2.5.21]: https://github.com/JuNNeZ/AdvancedHotkeyOverlaySystem/releases/tag/v2.5.21
