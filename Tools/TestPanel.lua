-- Run from the addon folder: lua Tools/TestPanel.lua [toc] (Lua 5.1).
--
-- Loads AHOS against the mock client in Tools/Mock.lua and drives the options
-- window: opening it, every page, every row bound, the live preview, the "changed
-- from default" marks and their revert, search, the window's own settings, and the
-- classic window as a fallback.
local checks = 0
local function check(value, message)
  if not value then error("FAILED: " .. message, 2) end
  checks = checks + 1
end

local Mock = dofile("Tools/Mock.lua")
local toc = arg and arg[1]
local game = Mock.New({ toc = toc, bindings = { ACTIONBUTTON1 = "SHIFT-Q" },
  -- one font another addon shares, and one whose addon is gone
  sharedFonts = { Expressway = "Interface\\AddOns\\SharedMedia\\Expressway.ttf", Gone = "Interface\\AddOns\\Removed\\Missing.ttf" } })
local env, ns, addon = game.env, game.ns, game.addon

check(#game.errors == 0, "AHOS loads and logs in without errors: " .. tostring(game.errors[1]))
check(addon.db and ns.P.DB == addon.db and ns.P.defaults.profile, "the window knows the database and its defaults")
local Kit = ns.OptionsKit
check(Kit and Kit.Panel and Kit.Look and Kit.HotkeyPreview and Kit.Defaults, "every options file loaded")

---------------------------------------------------------------------------
-- Opening
---------------------------------------------------------------------------
local Panel = Kit.Panel
env.OpenAHOSOptionsPanel()
check(Panel:IsShown(), "/ahos opens the options window")
check(not game.classicOpened, "and not the classic one")
check(Kit.ArtStyle == "ahos", "drawn with AHOS's own art")

-- Nothing the window draws comes from another addon's folder.
for _, w in ipairs(game.frames) do
  if type(w.texture) == "string" and w.texture:find("AddOns", 1, true) then
    check(w.texture:find("AddOns\\AdvancedHotkeyOverlaySystem\\media\\", 1, true), "art is AHOS's own: " .. w.texture)
  end
end

local keys = {}
for _, info in ipairs(Panel.pages) do keys[#keys + 1] = info.key end
local expected = { "status", "display", "text", "abbreviations", "profiles", "integration", "debug", "about", "window" }
check(table.concat(keys, ",") == table.concat(expected, ","), "rail: " .. table.concat(keys, ","))
for _, info in ipairs(Panel.pages) do
  check(type(info.label) == "string" and info.label ~= "", "page " .. info.key .. " has a name")
  check(Kit.Look.PageIcons[info.key], "page " .. info.key .. " has its own icon")
end

---------------------------------------------------------------------------
-- Every page draws every setting
---------------------------------------------------------------------------
local function rows(kind)
  local found = {}
  for _, control in ipairs(Panel.page:GetControls()) do
    if control.frame.shown and (not kind or control.kind == kind) then found[#found + 1] = control end
  end
  return found
end
local function row(label)
  for _, control in ipairs(rows()) do
    if control.labelText == label then return control end
  end
end

for _, info in ipairs(Panel.pages) do
  Panel:SelectPage(info.key)
  check(Panel.selected == info.key, "page opens: " .. info.key)
  check(#rows() > 0, info.key .. " is not empty")
  for _, control in ipairs(rows()) do
    local label = tostring(control.labelText or "")
    check(not label:find("cannot draw", 1, true), info.key .. ": every setting has a control (" .. label .. ")")
    check(not label:find("(failed)", 1, true), info.key .. ": every row binds (" .. label .. ")")
  end
  local hasPreview = Panel.page:GetControls()[1] == Kit.HotkeyPreview:GetControl()
  check(hasPreview == (Kit.HotkeyPreview.Pages[info.key] or false), info.key .. ": the preview shows exactly where it should")
end
check(#game.errors == 0, "no page errored: " .. tostring(game.errors[1]))

---------------------------------------------------------------------------
-- The live preview
---------------------------------------------------------------------------
Panel:SelectPage("text")
local preview = Kit.HotkeyPreview:GetControl()
check(preview.slots[1].caption.text == "SHIFT-Q", "the preview shows your own binding for action button 1")
check(preview.slots[1].text.text == "SQ", "abbreviated exactly as AHOS would: " .. tostring(preview.slots[1].text.text))
check(preview.slots[3].caption.text == "CTRL-MOUSEBUTTON4", "and a typical one where you have none")

local size = row("Font Size")
check(size and size.kind == "range", "Font Size is a slider")
size.callback(size, 22)
check(addon.db.profile.text.fontSize == 22, "moving the slider sets the font size")
check(preview.slots[1].text.font[2] == 22, "and the preview follows at once")

---------------------------------------------------------------------------
-- Changed from default, and back
---------------------------------------------------------------------------
Panel:UpdateCounts()
check(Panel.changedByPage.text == 1, "one setting on Keybinds differs from its default")
check(Panel.count:IsShown() and Panel.count.text.text:find("1 setting", 1, true), "the tally says so")
size = row("Font Size")
check(size.modified, "the row carries the changed mark")
size.onRevert(size)
check(addon.db.profile.text.fontSize == 16, "revert puts the shipped value back")
Panel:UpdateCounts()
check(Panel.changedByPage.text == 0 and not Panel.count:IsShown(), "and the mark and tally go away")

local fontRow = row("Font")
local fontNames = env.LibStub("AceConfigRegistry-3.0") and addon.Config:GetFontList()
local listed = {}
for _, name in ipairs(fontNames) do listed[name] = true end
check(listed.Expressway and listed.Default, "fonts other addons share are offered")
check(not listed.Gone, "a font whose file does not load is left out of the list")
check(fontRow and fontRow.kind == "select", "Font is a list")
-- a profile still naming a font whose addon was removed since
local realPath = addon.Config.GetFontPath
addon.Config.GetFontPath = function() return "Interface\\AddOns\\Removed\\Missing.ttf" end
local hotkey = game.NewWidget("FontString")
hotkey.GetFont = function(self) if self.font then return unpack(self.font) end end -- a fresh FontString has none
local overlay = game.NewWidget("Frame")
overlay.text = hotkey
addon.Display:StyleOverlay(overlay, game.NewWidget("Button", "ActionButton1"), "SQ")
addon.Config.GetFontPath = realPath
check(hotkey.font and hotkey.font[1] == "Fonts\\FRIZQT__.TTF" and hotkey.font[2] == addon.db.profile.text.fontSize,
  "a saved font that no longer loads falls back to the game's font instead of drawing nothing")

local outline = row("Font Outline")
check(outline and (outline.kind == "select"), "Font Outline is a list")

---------------------------------------------------------------------------
-- Toggles go through the addon's own setters
---------------------------------------------------------------------------
Panel:SelectPage("display")
local layering = row("Smart Frame Layering")
local strata = row("Overlay Frame Strata")
check(layering and strata, "layering rows are drawn")
check(not strata.disabled, "manual strata is open while Smart Frame Layering is off")
layering.callback(layering, true)
check(addon.db.profile.display.smartStrata == true, "the toggle writes the profile")
strata = row("Overlay Frame Strata")
check(strata.disabled, "and greys out the manual strata at once")
layering = row("Smart Frame Layering")
layering.callback(layering, false)

---------------------------------------------------------------------------
-- The keyboard on the Abbreviations page
---------------------------------------------------------------------------
-- Two bars answer to SHIFT-Q (Bartender4 and Blizzard's own), and an addon has put
-- an override binding over Q.
local bindings = { ["SHIFT-Q"] = "ACTIONBUTTON3", Q = "MOVEFORWARD", ["CTRL-1"] = "ACTIONBUTTON1" }
env.GetBindingAction = function(key, checkOverride)
  if checkOverride and key == "Q" then return "CLICK SomeAddonButton:LeftButton" end
  return bindings[key] or ""
end
env.BINDING_NAME_ACTIONBUTTON3 = "Action Button 3"
env.BINDING_NAME_MOVEFORWARD = "Move Forward"
env.GetActionInfo = function(slot) if slot == 3 then return "spell", 133 end end
env.GetActionTexture = function(slot) if slot == 3 then return 135812 end end
env.C_Spell = { GetSpellName = function(id) return id == 133 and "Fireball" or nil end }
local fakeButtons = {
  { name = "BT4Button3", action = 3, key = "SHIFT-Q" },
  { name = "ActionButton3", action = 3, key = "SHIFT-Q" },
}
for _, b in ipairs(fakeButtons) do b.GetName = function(self) return self.name end end
addon.Bars.GetAllButtons = function() return fakeButtons end
local realFull = addon.Keybinds.GetFullBindingText
addon.Keybinds.GetFullBindingText = function(_, button) return button.key end

Panel:SelectPage("abbreviations")
local keyboard = Kit.Keyboard:GetControl()
check(Panel.page:GetControls()[1] == keyboard, "the Abbreviations page opens with the keyboard")
check(not row("Numpad 5") and not row("Shift"), "the long list of boxes is gone from this window")
check(row("Enable Abbreviations") and row("Max Length"), "the page's other settings stay")
check(#keyboard.keys > 90, "every key is drawn: " .. #keyboard.keys)

local function key(token)
  for _, k in ipairs(keyboard.keys) do if k.token == token then return k end end
end
local q, shift = key("Q"), key("SHIFT")
check(q and shift and key("NUMPAD5") and key("MOUSEWHEELUP") and key("-"), "letters, modifiers, numpad, mouse and punctuation")
check(q.command == "CLICK SomeAddonButton:LeftButton" and not q.buttons, "Q without a modifier: an override, no action button")

shift.frame.scripts.OnClick(shift.frame)
check(keyboard.mods.SHIFT, "clicking Shift shows the Shift layer")
check(q.buttons and #q.buttons == 2, "Shift-Q is pressed by two action buttons")
check(q.shown.text == "SQ", "and shows the text AHOS draws for it: " .. tostring(q.shown.text))

q.frame.scripts.OnClick(q.frame)
local card = keyboard.card
check(card.frame:IsShown() and card.title.text == "SHIFT-Q", "clicking Q opens its card for SHIFT-Q")
local text = {}
for _, line in ipairs(card.lines) do if line.text.shown then text[#text + 1] = line.text.text end end
local all = table.concat(text, "\n")
check(all:find("Action Button 3", 1, true), "the card names the command")
check(all:find("Bartender4", 1, true) and all:find("BT4Button3", 1, true) and all:find("Fireball", 1, true),
  "and every button that answers, with its addon and spell")
check(all:find("2 bar addons answer to this key", 1, true), "and warns when two bar addons claim the key")
local icons = 0
for _, line in ipairs(card.lines) do if line.icon.shown and line.icon.texture == 135812 then icons = icons + 1 end end
check(icons == 2, "each button shows its spell's icon")

-- a letter gets its own abbreviation now, not only the 104 built-in keys
card.input.callback(card.input, "Kew")
check(addon.Keybinds:GetConfiguredAbbreviation("Q") == "Kew", "Q takes an abbreviation of its own")
q = key("Q")
check(q.shown.text == "SKew" and q.dot.shown, "the key shows it at once, with the changed mark")
check(card.input.modified, "and the card marks it changed")
card.input.onRevert(card.input)
check(addon.Keybinds:GetConfiguredAbbreviation("Q") == "Q" and not key("Q").dot.shown, "revert gives Q back its own name")
check(not addon.Keybinds:SetCustomAbbreviation("CTRL-Q", "x"), "a whole binding is not a key and cannot be abbreviated")

key("SHIFT").frame.scripts.OnClick(key("SHIFT").frame)
check(not keyboard.mods.SHIFT and card.title.text == "SHIFT", "clicking Shift again leaves the layer, and shows Shift's own card")
check(#game.errors == 0, "the keyboard did not error: " .. tostring(game.errors[1]))
addon.Keybinds.GetFullBindingText = realFull

---------------------------------------------------------------------------
-- A profile exported and imported again, through the Profiles page
---------------------------------------------------------------------------
local LibSerialize, LibDeflate = env.LibStub("LibSerialize"), env.LibStub("LibDeflate")
addon.db.profile.text.fontSize = 31
local exported = LibDeflate:EncodeForPrint(LibDeflate:CompressDeflate(LibSerialize:Serialize(addon.db.profile)))
addon.db.profile.text.fontSize = 12
Panel:SelectPage("profiles")
local import = row("Import Profile Data")
check(import and import.kind == "input", "the Profiles page has an import box")
import.callback(import, exported)
check(addon.db.profile.text.fontSize == 31, "importing a profile string brings its settings back")
addon.db.profile.text.fontSize = 16

---------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------
Panel:ShowResults("minimap")
check(Panel.searching, "typing searches")
check(Panel.pageDesc.text:find("match", 1, true), "results are counted")
Panel:ShowResults("outline")
Panel:OpenResult({ page = "text" })
check(Panel.selected == "text" and not Panel.searching, "a result opens its page")

---------------------------------------------------------------------------
-- The window's own settings
---------------------------------------------------------------------------
Panel:SelectPage("window")
local theme = row("Theme")
check(theme, "the Window page has a theme")
for _, key in ipairs({ "gold", "class", "light", "ahos" }) do
  theme.callback(theme, key)
  check(addon.db.global.panel.theme == key and Kit.GetTheme() == key, "theme switches without a reload: " .. key)
end
local classic = row("Open the Classic Window")
classic.callback(classic, true)
Panel:Close()
check(not Panel:IsShown(), "closing hides the window")
env.OpenAHOSOptionsPanel()
check(game.classicOpened == 1 and not Panel:IsShown(), "with Classic chosen, /ahos opens the classic window")
addon.db.global.panel.classic = false
for app in pairs(game.dialog.OpenFrames) do game.dialog.OpenFrames[app] = nil end

env.SlashCmdList.ACECONSOLE_AHOS("classic")
check(game.classicOpened == 2, "/ahos classic always opens the classic window")
env.SlashCmdList.ACECONSOLE_AHOS("")
check(Panel:IsShown(), "and /ahos opens this one again")
env.OpenAHOSOptionsPanel()
check(not Panel:IsShown(), "a second /ahos closes it")

---------------------------------------------------------------------------
-- ESC > Options > AddOns
---------------------------------------------------------------------------
check(game.settingsCategory and game.settingsCategory.name == "Advanced Hotkey Overlay System",
  "AHOS has a page under ESC > Options > AddOns")
check(game.settingsCategory.ID == "Advanced Hotkey Overlay System", "with a stable category ID")
local landing = game.settingsPage
check(landing.open and landing.classic and landing.OnCommit and landing.OnDefault and landing.OnRefresh,
  "the landing page has its buttons and the callbacks Settings asks a canvas for")
Panel:Close()
env.SettingsPanel:Show()
landing.open.scripts.OnClick(landing.open)
check(Panel:IsShown() and not env.SettingsPanel:IsShown(), "its button closes Blizzard's Settings and opens the options window")
landing.open.scripts.OnClick(landing.open)
check(Panel:IsShown(), "and a second click leaves the window open rather than closing it")
local classicBefore = game.classicOpened or 0
for app in pairs(game.dialog.OpenFrames) do game.dialog.OpenFrames[app] = nil end
landing.classic.scripts.OnClick(landing.classic)
check(not Panel:IsShown() and game.classicOpened == classicBefore + 1, "the second button opens the classic window instead")
landing.scripts.OnShow(landing)
check(landing.provider.text:find("Drawing on", 1, true), "the page says what AHOS is drawing on")

---------------------------------------------------------------------------
-- Settings changed elsewhere redraw the open page
---------------------------------------------------------------------------
env.OpenAHOSOptionsPanel()
Panel:SelectPage("status")
addon.db.profile.enabled = false
addon.Core:FullUpdate()
game.flush()
check(Panel.subtitle.text:find("Overlays off", 1, true), "the header notices overlays were turned off")
addon.db.profile.enabled = true

check(#game.errors == 0, "nothing errored: " .. tostring(game.errors[1]))
print(string.format("TestPanel: %d checks passed (%s)", checks, toc or "Mainline"))
