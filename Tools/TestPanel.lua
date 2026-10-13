-- Run from the addon folder: lua Tools/TestPanel.lua [toc] (Lua 5.1).
--
-- Loads AHOS against the mock client in Tools/Mock.lua and drives the options
-- window: opening it, every page, every row bound, the live preview, the "changed
-- from default" marks and their revert, search, the window's own settings, and the
-- landing page under ESC > Options > AddOns.
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
check(not env.LibStub("AceConfigDialog-3.0", true) or not game.classicOpened, "and nothing else")
check(not env.LibStub("AceGUI-3.0", true) or env.LibStub("AceGUI-3.0", true).Create, "no Ace3 window is loaded for it")
check(Kit.ArtStyle == "ahos", "drawn with AHOS's own art")
check(Kit.GetTheme() == "gold" and addon.db.global.panel.theme == "gold", "Keycap Gold is the theme a new install opens in")

-- Nothing the window draws comes from another addon's folder.
for _, w in ipairs(game.frames) do
  if type(w.texture) == "string" and w.texture:find("AddOns", 1, true) then
    check(w.texture:find("AddOns\\AdvancedHotkeyOverlaySystem\\media\\", 1, true), "art is AHOS's own: " .. w.texture)
  end
end

local keys = {}
for _, info in ipairs(Panel.pages) do keys[#keys + 1] = info.key end
local expected = { "status", "display", "text", "abbreviations", "bars", "profiles", "integration", "inspector", "debug", "about", "window" }
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
check(#outline.order == 6 and not outline.list.MONOCHROMEOUTLINE, "of six outlines, without the old alias spellings")
check(outline.order[1] == "NONE" and outline.order[2] == "OUTLINE", "in the order they thicken, not alphabetically")
addon.db.profile.text.outlineStyle = "MONOCHROMEOUTLINE"
Panel.page:Refresh()
check(row("Font Outline").value == "MONOCHROME,OUTLINE", "an old profile's alias shows as what it means")
addon.db.profile.text.outlineStyle = "OUTLINE"
Panel.page:Refresh()

-- each font in the list is drawn in that font
fontRow = row("Font")
check(type(fontRow.rowFont) == "function", "the font list knows each font's file")
Kit.Controls.OpenList(fontRow)
local drawnIn
for _, w in ipairs(game.frames) do
  if w.text == "Expressway" and w.font and w.font[1]:find("Expressway.ttf", 1, true) then drawnIn = true end
end
check(drawnIn, "and Expressway is drawn in Expressway")
Kit.Controls.CloseDropdown()

---------------------------------------------------------------------------
-- Colour by modifier
---------------------------------------------------------------------------
local colorToggle = row("Colour by Modifier")
check(colorToggle and colorToggle.kind == "toggle" and not colorToggle.value, "Colour by Modifier is a switch, off by default")
check(row("Hide Modifier Letters").disabled and row("Shift").disabled, "and its other rows wait for it")
check(row("Two or More Modifiers"), "with a colour for Shift, Ctrl, Alt and combinations")
colorToggle.callback(colorToggle, true)
check(addon.db.profile.text.modifierColors.enabled, "the switch writes the profile")
local shiftColor = addon.db.profile.text.modifierColors.shift
local tint = { preview.slots[1].text:GetTextColor() }
check(math.abs(tint[1] - shiftColor[1]) < 0.001 and math.abs(tint[3] - shiftColor[3]) < 0.001, "Shift-Q in the preview takes the Shift colour")
check(addon.Keybinds:GetModifierKind("CTRL-SHIFT-1") == "multi" and addon.Keybinds:GetModifierKind("ALT-F") == "alt"
  and addon.Keybinds:GetModifierKind("F") == nil and addon.Keybinds:GetModifierKind("CTRL--") == "ctrl", "modifiers are read off the front of a binding")
local hide = row("Hide Modifier Letters")
check(not hide.disabled, "turning it on opens the other rows")
hide.callback(hide, true)
check(preview.slots[1].text.text == "Q", "hiding the letters leaves the colour to say Shift: " .. tostring(preview.slots[1].text.text))
local real = game.NewWidget("Button", "ActionButton1")
local restyled = game.NewWidget("Frame")
restyled.text = game.NewWidget("FontString")
local realFullText = addon.Keybinds.GetFullBindingText
addon.Keybinds.GetFullBindingText = function() return "ALT-2" end
addon.Keybinds:ClearCache()
addon.Display:StyleOverlay(restyled, real, "2")
addon.Keybinds.GetFullBindingText = realFullText
local altColor = addon.db.profile.text.modifierColors.alt
check(restyled.text.textColor and math.abs(restyled.text.textColor[1] - altColor[1]) < 0.001, "the overlay on a real button takes its modifier's colour")
row("Hide Modifier Letters").callback(row("Hide Modifier Letters"), false)
colorToggle = row("Colour by Modifier")
colorToggle.callback(colorToggle, false)
addon.Keybinds:ClearCache()
check(preview.slots[1].text.text == "SQ", "and switching it off puts the letters back")
Panel:UpdateCounts()
check(Panel.changedByPage.text == 0, "leaving nothing marked as changed")

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

-- The anchor point is a 3x3 grid on a button
local anchorRow = row("Anchor Point")
check(anchorRow and anchorRow.anchorGrid and #anchorRow.cells == 9, "Anchor Point is a 3x3 grid")
check(anchorRow:GetHeight() > Kit.Controls.RowHeight, "on a row tall enough to hold it")
check(anchorRow.value == "TOP" and anchorRow.text.text == "Top", "showing the current point by name")
anchorRow.cells[9].scripts.OnClick(anchorRow.cells[9])
check(addon.db.profile.display.anchor == "BOTTOMRIGHT", "clicking a corner sets that anchor")
anchorRow = row("Anchor Point")
check(anchorRow.modified, "and marks it changed")
anchorRow.onRevert(anchorRow)
check(addon.db.profile.display.anchor == "TOP", "revert puts it back")

-- A change in the window lights up the overlays on your bars
check(Kit.Preview and Kit.Preview:Request(nil, { "display", "anchor" }) == true, "a display change asks the bars to flash")
check(Kit.Preview:Request(nil, { "profiles", "x" }) == false, "a profile change does not")

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

-- binding the key from its card
local bound = {}
env.SetBinding = function(k, command) bound[#bound + 1] = { k, command }; bindings[k] = command; return true end
local saved = 0
env.SaveBindings = function() saved = saved + 1 end
env.GetCurrentBindingSet = function() return 1 end
check(card.bind:IsShown() and card.unbind:IsShown(), "the card offers to bind and unbind the key")
card.bind.scripts.OnClick(card.bind)
local owner = card.bindOwner
check(owner and owner.list.ACTIONBUTTON3 and owner.value == "ACTIONBUTTON3", "Bind to lists the action buttons, with the current one ticked")
owner:Fire("ACTIONBUTTON3")
check(bound[1] and bound[1][1] == "SHIFT-Q" and bound[1][2] == "ACTIONBUTTON3" and saved == 1, "choosing one binds Shift-Q to it and saves the bindings")
game.lockdown = true
owner:Fire("ACTIONBUTTON3")
check(#bound == 1, "not in combat, where the game forbids it")
game.lockdown = false
card.unbind.scripts.OnClick(card.unbind)
check(bound[2] and bound[2][1] == "SHIFT-Q" and bound[2][2] == nil, "Unbind clears the key")
bindings["SHIFT-Q"] = "ACTIONBUTTON3"
env.SetBinding, env.SaveBindings, env.GetCurrentBindingSet = nil, nil, nil
Kit.Controls.CloseDropdown()

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

-- a full-size board and a mouse
for _, token in ipairs({ "UP", "DOWN", "LEFT", "RIGHT", "PRINTSCREEN", "NUMLOCK", "NUMPADPLUS", "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5", "MOUSEWHEELDOWN" }) do
  check(key(token), "the board has " .. token)
end
check(key("BUTTON6") and key("BUTTON12") and not key("BUTTON13"), "the extra mouse buttons 6-12 are always there, no more")
-- what the game says is bound adds the rest: a high mouse button, a key on neither model
env.GetNumBindings = function() return 2 end
env.GetBinding = function(i)
  if i == 1 then return "ACTIONBUTTON11", "ACTIONBAR", "BUTTON15" end
  return "ACTIONBUTTON12", "ACTIONBAR", "CTRL-F13"
end
keyboard:Update()
check(key("BUTTON15") and key("BUTTON13") and key("F13"), "bound keys on neither model join it: mouse buttons up to the highest bound, and F13")
env.GetNumBindings, env.GetBinding = nil, nil

-- the card sits in a slice beside the window, not under the keyboard
key("Q").frame.scripts.OnClick(key("Q").frame)
local window = Panel:GetWindow()
local slice = card.frame:GetParent() and card.frame:GetParent():GetParent() and card.frame:GetParent():GetParent():GetParent()
check(slice and slice:GetParent() == window and slice:IsShown(), "the key's card is docked beside the window")
check(card.title.text == "Q" and card.input.stacked, "with the key's card in it, its box under the label to fit")
local heightWithQ = keyboard:GetHeight()
key("SPACE").frame.scripts.OnClick(key("SPACE").frame)
check(keyboard:GetHeight() == heightWithQ, "the keyboard does not grow or shrink with the card")
key("Q").frame.scripts.OnClick(key("Q").frame)
Panel:SelectPage("display")
check(not slice:IsShown(), "and the slice goes when the page does")
Panel:SelectPage("abbreviations")
check(slice:IsShown(), "and comes back with it")

-- Find a Key: the next key pressed is selected, even one on neither model
check(Kit.Keyboard:StartFinding() and Kit.Keyboard:IsFinding(), "Find a Key waits for a key")
local catcherFrame
for _, w in ipairs(game.frames) do if w.scripts and w.scripts.OnKeyDown and w.strata == "FULLSCREEN_DIALOG" then catcherFrame = w end end
catcherFrame = catcherFrame or (function() for _, w in ipairs(game.frames) do if w.scripts and w.scripts.OnKeyDown then return w end end end)()
catcherFrame.scripts.OnKeyDown(catcherFrame, "F17")
check(not Kit.Keyboard:IsFinding() and keyboard.selected == "F17" and key("F17"), "pressing F17 picks it and puts it on the board")
Kit.Keyboard:StartFinding()
catcherFrame.scripts.OnMouseDown(catcherFrame, "Button9")
check(keyboard.selected == "BUTTON9", "a mouse button is caught too")
Kit.Keyboard:StartFinding()
catcherFrame.scripts.OnMouseWheel(catcherFrame, -1)
check(keyboard.selected == "MOUSEWHEELDOWN", "and the wheel")
key("SHIFT").frame.scripts.OnClick(key("SHIFT").frame)
key("SHIFT").frame.scripts.OnClick(key("SHIFT").frame)
check(not keyboard.mods.SHIFT, "Shift latches and unlatches")

-- the layout of your country, with its own keys and names
local panelSettings = Panel.Settings()
check(keyboard.picker.text.text:find("English (US)", 1, true), "the US layout is the default on an English client")
keyboard.picker.scripts.OnClick(keyboard.picker)
local layoutList = keyboard.pickerOwner
check(layoutList and layoutList.list.da == "Dansk" and layoutList.list.de == "Deutsch" and layoutList.list.fr == "Français",
  "the layouts are named in their own language")
layoutList:Fire("da")
check(panelSettings.keyboardLayout == "da" and key("æ") and key("ø") and key("å") and key("<") and not key(";"),
  "Dansk has æ, ø, å (as the game names them) and the key left of Z, and no semicolon key")
check(key("æ").legend.text == "Æ", "printed in capitals, as on the key")
check(key("NUMPADDECIMAL").legend.text == ",", "a Danish numpad prints a comma on its decimal key")
local space = key("SPACE")
check(space and space.legend.text == "Mellemrum", "and Danish names on its keys")
local enters = 0
for _, k in ipairs(keyboard.keys) do if k.token == "ENTER" and k.spec and k.spec[6] == 2 then enters = enters + 1 end end
check(enters == 2, "an ISO board's Enter and the numpad's Enter are both two rows tall")
layoutList:Fire("fr")
check(key("&") and key("é") and key("A") and key("Z"), "Français is AZERTY, with & on the 1 key")
check(key("NUMPADDECIMAL").legend.text == ".", "and a French one a point")
-- Cyrillic and Asian boards
check(layoutList.list.ru == "Русская" and layoutList.list.ua == "Українська" and layoutList.list.ko and layoutList.list.zh,
  "Russian, Ukrainian, Korean and Taiwanese boards are listed")
layoutList:Fire("ru")
check(key("й") and key("ё") and key("э") and key("ъ") and not key("Q"), "Русская is ЙЦУКЕН, named as the game names the keys")
check(key("й").legend.text == "Й", "a Cyrillic key is printed in capitals")
check(key("SPACE").legend.text == "Пробел", "and Russian names on its keys")
layoutList:Fire("ua")
check(key("і") and key("ї") and key("є") and not key("ы"), "Українська has і, ї and є")
layoutList:Fire("ko")
check(key("Q") and key("Q").legend.text == "Q" and key("Q").second.text == "ㅂ",
  "Korean keys are the US keys, with their Hangul in the other corner (not cut to Q...)")
local hangulKey = false
for _, k in ipairs(keyboard.keys) do if k.token == "ALT" and k.legend.text == "한/영" then hangulKey = true end end
check(hangulKey, "the right Alt is the Hangul/English key")
local function fontSize(fs) return tonumber(tostring(fs.fontObject and fs.fontObject.name or ""):match("(%d+)$")) end
check(fontSize(key("Q").second) == 12 and fontSize(key("Q").legend) == 10, "Hangul is drawn two sizes up: " .. tostring(fontSize(key("Q").second)))
local hanja
for _, k in ipairs(keyboard.keys) do if k.legend.text == "한자" then hanja = k end end
check(hanja and fontSize(hanja.legend) and fontSize(hanja.legend) >= 10, "a Hangul legend is not drawn smaller than a Latin one")
layoutList:Fire("da")
-- nothing is cut short: a legend too wide for its key is drawn smaller instead
local ins = key("INSERT")
check(ins.legend.text == "Indsæt", "the whole word is on the key, not Ind...")
check(#ins.legend.points == 1, "the legend has one point, so it is never held to a width and cut")
check(fontSize(ins.legend) < 10, "and is drawn smaller to fit: " .. tostring(fontSize(ins.legend)))
check(fontSize(key("Q").legend) == 10, "a legend that fits keeps its size")
layoutList:Fire("zh")
check(key("1").legend.text == "1" and key("1").second.text == "ㄅ" and key("/").second.text == "ㄥ", "Taiwanese keys carry their Zhuyin")
layoutList:Fire("us")
check(key("Q").second.text == "", "a US board has no second alphabet")
layoutList:Fire("us")
check(Kit.Look.ScriptFonts and #Kit.Look.ScriptFonts == 4, "the window's font has Cyrillic, Korean and Chinese faces")
check(addon.Keybinds:GetKeyDefault("й") == "Й" and addon.Keybinds:GetKeyDefault("ґ") == "Ґ", "bars show Cyrillic keys in capitals too")
Kit.Controls.CloseDropdown()

-- keys stay a comfortable size: blocks wrap before they shrink below it
keyboard:Measure(1400)
local wideTop = select(5, key("BUTTON1").frame:GetPoint(1))
local mainTop = select(5, key("ESCAPE").frame:GetPoint(1))
check(math.abs(wideTop - mainTop) < 12 and select(4, key("BUTTON1").frame:GetPoint(1)) > select(4, key("NUMPAD9").frame:GetPoint(1)),
  "on a wide page the mouse sits right of the numpad")
keyboard:Measure(700)
local qWidth = key("Q").frame:GetWidth()
check(qWidth >= 30, "on a narrow page the keys stay at least 30px: " .. qWidth)
check(select(5, key("NUMPAD7").frame:GetPoint(1)) < select(5, key("Z").frame:GetPoint(1)) - 100, "and the numpad wraps under the main block")
keyboard:Measure(keyboard.width)

-- the controller, named the way your controller names its buttons
keyboard.tabController.scripts.OnClick(keyboard.tabController)
check(panelSettings.keyboardDevice == "controller" and key("PAD1") and key("PADLTRIGGER") and key("PADDUP") and not key("Q"),
  "the Controller tab shows a gamepad instead of the keyboard")
check(key("PADPADDLE1") and key("PADLSTICKUP"), "with its paddles and stick directions beside it")
check(keyboard.latches[3]:IsShown(), "and Shift, Ctrl and Alt to latch, since a gamepad has no such keys")
keyboard.picker.scripts.OnClick(keyboard.picker)
keyboard.pickerOwner:Fire("ps")
check(key("PAD1").legend.text == "Cross" and key("PADLTRIGGER").legend.text == "L2", "PlayStation names: Cross, L2")
keyboard.pickerOwner:Fire("xbox")
check(key("PAD1").legend.text == "A" and key("PADRSHOULDER").legend.text == "RB", "Xbox names: A, RB")
keyboard.pickerOwner:Fire("switch")
check(key("PAD1").legend.text == "B" and key("PADLTRIGGER").legend.text == "ZL", "Switch names: B at the bottom, ZL")
Kit.Controls.CloseDropdown()
keyboard.latches[3].scripts.OnClick(keyboard.latches[3])
check(keyboard.mods.SHIFT, "a latch shows the Shift layer on the controller too")
keyboard.latches[3].scripts.OnClick(keyboard.latches[3])
keyboard.tabKeyboard.scripts.OnClick(keyboard.tabKeyboard)
check(key("Q") and not key("PAD1"), "and the Keyboard & Mouse tab brings the board back")
addon.db.profile.text.gamepadIconStyle = "auto"

-- the list buttons carry a drawn chevron, not a character the game's font lacks
check(keyboard.picker.chevron and keyboard.picker.chevron:IsShown() and not keyboard.picker.text.text:find("\226\150\190", 1, true),
  "the layout list opens from a drawn chevron")
for _, k in ipairs(keyboard.keys) do
  check(not tostring(k.legend.text):find("\226\134", 1, true), "no arrow characters the font cannot draw: " .. tostring(k.token))
end

-- holding Shift shows the Shift layer, and a pressed key lights up
check(not keyboard.mods.SHIFT and key("Q").shown.text == "", "Q shows nothing without a modifier")
game.shift = true
keyboard.listener.elapsed = 1
keyboard.listener.scripts.OnUpdate(keyboard.listener, 1)
check(key("Q").shown.text == "SQ" and keyboard.layer.text:find("SHIFT", 1, true), "holding Shift shows the Shift layer")
game.shift = false
keyboard.listener.scripts.OnUpdate(keyboard.listener, 1)
check(key("Q").shown.text == "" and not keyboard.mods.SHIFT, "letting go goes back, without latching")
keyboard.listener.scripts.OnKeyDown(keyboard.listener, "W")
check(keyboard.pressed.W, "a key you press lights up")
keyboard.listener.scripts.OnKeyUp(keyboard.listener, "W")
check(not keyboard.pressed.W, "and goes dark when you let go")

-- an accented letter key reads in capitals on your buttons
check(addon.Keybinds:Abbreviate("SHIFT-æ") == "SÆ", "the game's æ is drawn Æ")

-- every brand of controller, with the buttons that brand has
keyboard.tabController.scripts.OnClick(keyboard.tabController)
keyboard.picker.scripts.OnClick(keyboard.picker)
local devices = keyboard.pickerOwner
check(devices.list.auto and devices.list.xbox and devices.list.ps and devices.list.switch and devices.list.deck and devices.list.steam,
  "Automatic, Xbox, PlayStation, Switch, Steam Deck and Steam Controller")
devices:Fire("ps")
check(key("PAD6") and key("PADBACK") and key("PAD5"), "the DualSense has its touchpad halves and the mic button on it")
check(addon.db.profile.text.gamepadIconStyle == "ps", "and picking it draws PlayStation glyphs on your bars")
devices:Fire("deck")
local deckExtra = {}
for _, k in ipairs(keyboard.keys) do if k.token:find("^PADPADDLE") then deckExtra[k.token] = k.legend.text end end
check(deckExtra.PADPADDLE1 == "L4" and deckExtra.PADPADDLE4 == "R5", "the Steam Deck's back buttons are L4, L5, R4, R5")
check(keyboard.bodies["pad-deck"]:IsShown() and not keyboard.bodies["pad-xbox"]:IsShown(), "drawn as a Deck")
devices:Fire("steam")
check(key("PADDUP") and key("PADRSTICK") and keyboard.bodies["pad-steam"]:IsShown(), "the Steam Controller, its trackpads clicking as D-pad and stick")
-- Automatic follows the controller the game sees, by its glyph for the bottom button
devices:Fire("auto")
env.GetBindingText = function(k, abbr) if abbr and k == "PAD1" then return "|A:Gamepad_Shp_Cross_32:14:14|a" end return k end
keyboard:Update()
check(keyboard.bodies["pad-ps"]:IsShown(), "Automatic draws a PlayStation controller when the game shows a cross")
env.GetBindingText = nil
Kit.Controls.CloseDropdown()
keyboard.tabKeyboard.scripts.OnClick(keyboard.tabKeyboard)
Panel.Settings().keyboardDevice, Panel.Settings().padDevice = nil, nil
addon.db.profile.text.gamepadIconStyle = "auto"
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
check(not row("Open the Classic Window"), "the classic window is gone from the Window page")
Panel:Close()
check(not Panel:IsShown(), "closing hides the window")
check(not addon.OpenClassicOptions, "and from the addon")
env.SlashCmdList.ACECONSOLE_AHOS("classic")
check(Panel:IsShown() and not game.classicOpened, "/ahos classic opens this window now")
Panel:Close()
env.SlashCmdList.ACECONSOLE_AHOS("")
check(Panel:IsShown(), "and /ahos opens it")
env.OpenAHOSOptionsPanel()
check(not Panel:IsShown(), "a second /ahos closes it")

---------------------------------------------------------------------------
-- ESC > Options > AddOns
---------------------------------------------------------------------------
check(game.settingsCategory and game.settingsCategory.name == "Advanced Hotkey Overlay System",
  "AHOS has a page under ESC > Options > AddOns")
check(game.settingsCategory.ID == "Advanced Hotkey Overlay System", "with a stable category ID")
local landing = game.settingsPage
check(landing.open and not landing.classic and landing.OnCommit and landing.OnDefault and landing.OnRefresh,
  "the landing page has its one button and the callbacks Settings asks a canvas for")
Panel:Close()
env.SettingsPanel:Show()
landing.open.scripts.OnClick(landing.open)
check(Panel:IsShown() and not env.SettingsPanel:IsShown(), "its button closes Blizzard's Settings and opens the options window")
landing.open.scripts.OnClick(landing.open)
check(Panel:IsShown(), "and a second click leaves the window open rather than closing it")
landing.scripts.OnShow(landing)
check(landing.provider.text:find("Drawing on", 1, true), "the page says what AHOS is drawing on")

---------------------------------------------------------------------------
-- Settings changed elsewhere redraw the open page
---------------------------------------------------------------------------
if not Panel:IsShown() then env.OpenAHOSOptionsPanel() end
Panel:SelectPage("status")
addon.db.profile.enabled = false
addon.Core:FullUpdate()
game.flush()
check(Panel.subtitle.text:find("Overlays off", 1, true), "the header notices overlays were turned off")
addon.db.profile.enabled = true

---------------------------------------------------------------------------
-- Controller button icons
---------------------------------------------------------------------------
env.GetBindingText = function(k, abbreviated)
  if abbreviated and k == "PAD1" then return "|A:Gamepad_Ltr_A_32:14:14|a" end
  return k
end
local kb = addon.Keybinds
check(kb:Abbreviate("SHIFT-PAD1") == "S|A:Gamepad_Ltr_A_32:16:16|a", "a gamepad button is drawn as the controller's glyph, at the text's size: " .. kb:Abbreviate("SHIFT-PAD1"))
check(kb:Abbreviate("SHIFT-Q") == "SQ", "a keyboard key stays text")
kb:SetCustomAbbreviation("PAD1", "Jump")
check(kb:Abbreviate("PAD1") == "Jump", "a gamepad button with your own abbreviation keeps it")
kb:SetCustomAbbreviation("PAD1", "")
addon.db.profile.text.gamepadIcons = false
check(kb:Abbreviate("PAD1") == "A", "and with icons off it is text again")
addon.db.profile.text.gamepadIcons = true
env.GetBindingText = nil

-- Each controller's own glyphs, from the strings the client defines for them
-- (SharedConstants.lua: KEY_ABBR_<button>_LTR / _SHP / _REV, and the generic set)
env.KEY_ABBR_PAD1 = "|A:Gamepad_Gen_1_32:14:14|a"
env.KEY_ABBR_PAD1_LTR = "|A:Gamepad_Ltr_A_32:14:14|a"
env.KEY_ABBR_PAD1_SHP = "|A:Gamepad_Shp_Cross_32:14:14|a"
env.KEY_ABBR_PAD1_REV = "|A:Gamepad_Rev_B_32:14:14|a"
env.KEY_ABBR_PADDUP = "|A:Gamepad_Gen_Up_32:14:14|a"
env.KEY_ABBR_PADDUP_LTR = "|A:Gamepad_Ltr_Up_32:14:14|a"
check(kb:GetGamePadGlyph("PAD1", "ps", 16) == "|A:Gamepad_Shp_Cross_32:16:16|a", "PlayStation draws the cross")
check(kb:GetGamePadGlyph("PAD1", "xbox", 16):find("Gamepad_Ltr_A_32", 1, true), "Xbox draws A")
check(kb:GetGamePadGlyph("PAD1", "switch", 16):find("Gamepad_Rev_B_32", 1, true), "Nintendo draws B on the bottom button")
check(kb:GetGamePadGlyph("PADDUP", "switch", 16):find("Gamepad_Ltr_Up_32", 1, true), "a glyph Nintendo lacks falls back to the letters' one")
check(kb:GetGamePadGlyph("PAD1", "generic", 16):find("Gamepad_Gen_1_32", 1, true), "and the generic set is there too")
addon.db.profile.text.gamepadIconStyle = "ps"
check(kb:Abbreviate("SHIFT-PAD1"):find("Gamepad_Shp_Cross_32", 1, true), "the style chosen draws on your bars too")
Panel:SelectPage("abbreviations")
local styleRow = row("Controller Icon Style")
check(styleRow and styleRow.value == "ps", "the Abbreviations page has the style, from the profile")
styleRow.callback(styleRow, "auto")
check(addon.db.profile.text.gamepadIconStyle == "auto", "and sets it")
for _, name in ipairs({ "KEY_ABBR_PAD1", "KEY_ABBR_PAD1_LTR", "KEY_ABBR_PAD1_SHP", "KEY_ABBR_PAD1_REV", "KEY_ABBR_PADDUP", "KEY_ABBR_PADDUP_LTR" }) do env[name] = nil end

---------------------------------------------------------------------------
-- Refresh passes: a burst of bar events is one series, and stops once settled
---------------------------------------------------------------------------
game.flush()
local realUpdate, updates = addon.Core.FullUpdate, 0
addon.Core.FullUpdate = function(self, ...) updates = updates + 1; return realUpdate(self, ...) end
for _ = 1, 5 do addon.Core:HandleBarStateChanged("TEST") end
game.flush()
check(updates == 6, "five bar events and settled bars cost one update each and one follow-up, not twenty: " .. updates)
addon.Core.FullUpdate = realUpdate

---------------------------------------------------------------------------
-- Bars
---------------------------------------------------------------------------
local Bars = addon.Bars
local function barOf(name) return (Bars:GetBarInfo(name)) end
check(barOf("ActionButton3") == "Blizzard:1" and select(2, Bars:GetBarInfo("ActionButton3")) == "Action Bar 1", "Blizzard's first bar")
check(barOf("MultiBarBottomLeftButton2") == "Blizzard:2" and barOf("PetActionButton1") == "Blizzard:pet", "its other bars")
check(barOf("BT4Button25") == "Bartender4:3" and barOf("DominosActionButton13") == "Dominos:2", "bar addons that number buttons across bars")
check(barOf("AzeriteActionBar4Button7") == "AzeriteUI:4", "AzeriteUI's bars")
Panel:SelectPage("bars")
local barRow = row("Bar")
check(barRow and barRow.list["Blizzard:1"] and barRow.list["Bartender4:1"], "the Bars page lists the bars found")
barRow.callback(barRow, "Bartender4:1")
local hideRow = row("Leave This Bar Alone")
hideRow.callback(hideRow, true)
check(addon.db.profile.bars["Bartender4:1"].hide and Bars:IsBarHidden("BT4Button3") and not Bars:IsBarHidden("ActionButton3"),
  "a bar can be left to its own hotkey text, and only that bar")
check(row("Text Size on This Bar").disabled, "a bar AHOS leaves alone has no text size")
check(row("Leave This Bar Alone").modified and Panel.changedByPage.bars == 1, "and it shows as changed")
row("Leave This Bar Alone").onRevert(row("Leave This Bar Alone"))
check(addon.db.profile.bars["Bartender4:1"] == nil, "revert removes the bar's entry once it is back at every default")
local sizeRow = row("Text Size on This Bar")
sizeRow.callback(sizeRow, 0.8)
check(Bars:GetBarScale("BT4Button3") == 0.8 and Bars:GetBarScale("ActionButton3") == 1, "one bar's text can be smaller")
row("Reset Every Bar").callback(row("Reset Every Bar"))
check(next(addon.db.profile.bars) == nil, "and Reset Every Bar puts them all back")

-- A bar left alone gets its own label back, even from LibActionButton, whose
-- UpdateHotkeys is not a method on the button (AzeriteUI, Bartender4)
do
  local labButton = game.NewWidget("Button", "AzeriteActionBar1Button1")
  labButton.HotKey = game.NewWidget("FontString")
  labButton.HotKey:SetText("")
  labButton.GetHotkey = function() return "S1" end
  addon.Display:ClearReleased()
  addon.Display:ReleaseButton(labButton)
  check(labButton.HotKey.text == "S1" and labButton.HotKey:IsShown(), "a released LibActionButton button shows its own hotkey again")
  addon.Display:ClearReleased()

  -- a Blizzard bar AzeriteUI fades to nothing is not offered either
  local faded = game.NewWidget("Button", "MultiBarBottomLeftButton1")
  faded.IsVisible = function() return true end
  faded.GetEffectiveAlpha = function() return 0 end
  check(not Bars:IsSeen(faded), "a button faded to alpha 0 counts as hidden")
  faded.GetEffectiveAlpha = function() return 1 end
  check(Bars:IsSeen(faded), "and one at full alpha as seen")
end

-- With a bar addon drawing, Blizzard's hidden bars are not offered
local realDetected = addon.detectedUI
addon.detectedUI = "Bartender4"
for _, b in ipairs(fakeButtons) do if b.name:find("^ActionButton") then b.IsVisible = function() return false end end end
local listed = {}
for _, entry in ipairs(Bars:GetBarList()) do listed[entry.key] = true end
check(listed["Bartender4:1"] and not listed["Blizzard:1"], "with Bartender4 drawing, the Blizzard bar it hides is not listed")
addon.detectedUI = realDetected
for _, b in ipairs(fakeButtons) do b.IsVisible = nil end

-- Every dropdown is drawn in the window's font again after the font list
Panel:SelectPage("text")
local fontList = row("Font")
Kit.Controls.OpenList(fontList)
Kit.Controls.CloseDropdown()
Panel:SelectPage("window")
local themeRow = row("Theme")
Kit.Controls.OpenList(themeRow)
local strayFont
for _, w in ipairs(game.frames) do
  if w.shown and w.text == "Keycap Gold" and w.font and tostring(w.font[1]):find("Expressway", 1, true) then strayFont = true end
end
check(not strayFont, "a list opened after the font list is not drawn in that list's fonts")
Kit.Controls.CloseDropdown()

---------------------------------------------------------------------------
-- The inspector
---------------------------------------------------------------------------
Panel:SelectPage("inspector")
local inspector = Kit.Inspector:GetControl()
check(Panel.page:GetControls()[1] == inspector, "the Inspector page is its picker card")
check(inspector.title.text == "No button picked yet" and inspector.copy.disabled, "with nothing picked yet")
local target = game.NewWidget("Button", "ActionButton1")
target.IsMouseOver = function() return true end
target.IsVisible = function() return true end
addon.Bars.GetAllButtons = function() return { target } end
Kit.Inspector:StartPicking()
check(Kit.Inspector:IsPicking() and not Panel:IsShown(), "picking steps the window aside")
check(Kit.Inspector.ButtonUnderMouse() == target, "and finds the button under the mouse")
Kit.Inspector.button = target
Kit.Inspector.StopPicking(true)
check(not Kit.Inspector:IsPicking() and Panel:IsShown() and Panel.selected == "inspector", "a click keeps it and brings the window back")
inspector:Update()
check(inspector.title.text == "ActionButton1", "the card names the button")
local said = {}
for _, line in ipairs(inspector.lines) do if line.shown then said[#said + 1] = line.text.text end end
local saidText = table.concat(said, "\n")
check(saidText:find("SHIFT-Q", 1, true) and saidText:find("SQ", 1, true), "the key that presses it and what AHOS draws for it: " .. saidText)
inspector.copy.scripts.OnClick(inspector.copy)
check(Kit.TextWindow:IsShown("text"), "Copy Details opens the details to copy")
addon.Bars.GetAllButtons = function() return fakeButtons end

---------------------------------------------------------------------------
-- The debug log and exports in the window's own look
---------------------------------------------------------------------------
addon:LogDebug("a line for the log")
addon:ShowDebugLogWindow()
local logWindow = Kit.TextWindow:Get("log")
check(logWindow and logWindow.frame:IsShown() and logWindow.text:find("a line for the log", 1, true), "/ahoslog opens in the kit's window")
addon:LogDebug("another line")
check(logWindow.text:find("another line", 1, true), "and follows new lines while open")
addon:DebugExportTable({ a = 1 })
check(Kit.TextWindow:IsShown("export") and Kit.TextWindow:IsShown("log"), "an export opens beside the log, not over it")

---------------------------------------------------------------------------
-- The overview on the Status page
---------------------------------------------------------------------------
Panel:SelectPage("status")
local overview = Kit.Overview:GetControl()
check(Panel.page:GetControls()[1] == overview, "the Status page opens with the overview")
local chips = {}
for _, chip in ipairs(overview.chips) do if chip.shown then chips[#chips + 1] = chip.text.text end end
local chipText = table.concat(chips, " | ")
check(chipText:find("Bartender4", 1, true) and chipText:find("with AHOS text", 1, true), "a chip per bar addon, and what AHOS draws: " .. chipText)

---------------------------------------------------------------------------
-- The two new themes, and lighting up the bars
---------------------------------------------------------------------------
Panel:SelectPage("window")
theme = row("Theme")
theme.callback(theme, "backlit")
check(Kit.Backlit, "Backlit lights the keys that are on")
local lit = 0
for _, w in ipairs(game.frames) do if w.texture and tostring(w.texture):find("underglow", 1, true) and w.shown then lit = lit + 1 end end
check(lit >= 1, "the selected page glows")
theme.callback(theme, "legend")
check(not Kit.Backlit and Kit.EdgeColor[1] > Kit.EdgeColor[3], "Legend: no glow, a brass edge")
theme.callback(theme, "ahos")
local flash = row("Light Up My Bars")
flash.callback(flash, false)
check(Kit.Preview:Request(nil, { "display", "anchor" }) == false, "lighting up the bars can be turned off")
flash.callback(flash, true)

check(#game.errors == 0, "nothing errored: " .. tostring(game.errors[1]))

---------------------------------------------------------------------------
-- Startup and events
---------------------------------------------------------------------------
do
  local fresh = Mock.New({ toc = toc, noLogin = true })
  -- a profile saved last session, with offsets of your own
  fresh.env.AdvancedHotkeyOverlaySystemDB = {
    profileKeys = { ["Player - Realm"] = "Default" },
    profiles = { Default = { display = { xOffset = 7, yOffset = 9, scale = 1.4 } } },
  }
  fresh.fire("ADDON_LOADED", "AdvancedHotkeyOverlaySystem")
  fresh.loggedIn = true
  fresh.fire("PLAYER_LOGIN")
  fresh.fire("PLAYER_ENTERING_WORLD", true, false)
  fresh.flush()
  local a = fresh.ns.addon
  local d = a.db.profile.display
  check(d.xOffset == 7 and d.yOffset == 9 and d.scale == 1.4, "your own offsets survive logging in")
  check(#a.callQueue == 0, "everything queued before AHOS was ready has run")

  local full, all = 0, 0
  local realFull, realAll = a.Core.FullUpdate, a.Display.UpdateAllOverlays
  a.Core.FullUpdate = function(self, ...) full = full + 1; return realFull(self, ...) end
  a.Display.UpdateAllOverlays = function(self, ...) all = all + 1; return realAll(self, ...) end
  fresh.fire("UPDATE_VEHICLE_ACTIONBAR")
  check(full >= 1, "leaving a vehicle refreshes the overlays (Core's events are live)")
  full, all = 0, 0
  fresh.fire("ACTIONBAR_SLOT_CHANGED", 5)
  check(all == 0 and full == 0, "one slot changing updates that slot, not every button at once")
  a.Core.FullUpdate, a.Display.UpdateAllOverlays = realFull, realAll

  -- replies reach the chat; debug output stays in the log
  local said = {}
  a._origPrint = function(_, msg) said[#said + 1] = msg end
  fresh.env.SlashCmdList.ACECONSOLE_AHOS("help")
  check(#said > 5 and said[1]:find("Advanced Hotkey Overlay System", 1, true), "/ahos help prints its commands in the chat")
  local before = #said
  a:Print("[AHOS DEBUG] noise")
  check(#said == before and a.debugLogBuffer[#a.debugLogBuffer]:find("noise", 1, true), "a debug line goes to /ahoslog, not the chat")
  a.db.profile.debug = true
  fresh.env.SlashCmdList.ACECONSOLE_AHOS("refresh")
  check(#said == before + 1, "and a command still answers in the chat with debug mode on")
  a.db.profile.debug = false
  check(#fresh.errors == 0, "startup did not error: " .. tostring(fresh.errors[1]))
end

---------------------------------------------------------------------------
-- Another language: every page still draws, in that language
---------------------------------------------------------------------------
for _, locale in ipairs({ "deDE", "zhCN" }) do
  local other = Mock.New({ toc = toc, locale = locale, bindings = { ACTIONBUTTON1 = "SHIFT-Q" } })
  local otherKit = other.ns.OptionsKit
  other.env.OpenAHOSOptionsPanel()
  for _, info in ipairs(otherKit.Panel.pages) do otherKit.Panel:SelectPage(info.key) end
  check(#other.errors == 0, locale .. ": every page draws: " .. tostring(other.errors[1]))
  local label = otherKit.Panel.pages[#otherKit.Panel.pages].label
  check(label == (locale == "deDE" and "Fenster" or "窗口"), locale .. ": the window speaks it: " .. tostring(label))
end

---------------------------------------------------------------------------
-- Switches and sliders in whole screen pixels
---------------------------------------------------------------------------
if not Panel:IsShown() then env.OpenAHOSOptionsPanel() end
-- a 1080p screen at UI scale 1: one physical pixel is 768/1080 of a unit
env.GetPhysicalScreenSize = function() return 1920, 1080 end
local px = 768 / 1080
local function whole(v) return math.abs(v / px - math.floor(v / px + .5)) < 1e-6 end
Panel:SelectPage("display")
local switch
for _, c in ipairs(rows("toggle")) do if not c.disabled then switch = c; break end end
check(switch and switch.track and switch.knob, "a switch has a track and a knob")
switch:Restyle()
check(whole(switch.w) and whole(switch.h) and whole(switch.knobSize), "the switch's sizes are whole screen pixels")
check(math.floor(switch.h / px + .5) % 2 == 0 and math.floor(switch.knobSize / px + .5) % 2 == 0, "with even heights, so the knob is centred on a pixel")
check(switch.knob.texture.width == switch.knobSize and switch.knob.texture.height == switch.knobSize, "the knob is drawn at that size, round")
check(not switch.knobRing and not switch.knobShadow and not switch.gemOn, "no ring, no blurred shadow, no gem on the knob")
local was = switch.value
switch:SetValue(false)
local offX = select(4, switch.knob.texture:GetPoint(1))
check(math.abs(offX - (switch.h - switch.knobSize) / 2) < 1e-6, "off, the knob rests as far from the left end as from top and bottom")
check(not switch.knob.lip.shown, "and casts no shadow")
switch.box.scripts.OnClick(switch.box)
check(switch.value and switch.knobHost.scripts.OnUpdate, "a click slides the knob over")
switch.knobHost.scripts.OnUpdate(switch.knobHost, 1)
local onX = select(4, switch.knob.texture:GetPoint(1))
check(math.abs(onX - (switch.w - (switch.h - switch.knobSize) / 2 - switch.knobSize)) < 1e-6 and not switch.knobHost.scripts.OnUpdate,
  "and it stops at the right end, the same distance in")
check(switch.knob.lip.shown, "on, a hard pixel of shadow under the knob")
local accent = Kit.TextSelected
check(switch.track.inner[2].vertex[1] == accent[1] and switch.track.outer[2].vertex[1] == accent[1], "on, the whole track is the accent")
switch:SetValue(false)
check(switch.track.outer[2].vertex[1] == Kit.BorderIdle[1] and switch.track.inner[2].vertex[1] == Kit.InsetColor[1], "off, a sunk inset with a one-pixel edge")
check(math.abs(select(4, switch.track.inner[1]:GetPoint(1)) - px) < 1e-6, "the edge is exactly one screen pixel")
switch:SetDisabled(true)
check(switch.box.alpha == .45, "disabled, the whole switch is dimmed")
switch:SetDisabled(false)
switch.box.scripts.OnClick(switch.box)
switch.box.scripts.OnClick(switch.box)
if switch.value ~= was then switch.box.scripts.OnClick(switch.box) end
switch.knobHost.scripts.OnUpdate = nil

Panel:SelectPage("text")
local slider = row("Font Size")
slider:Restyle()
check(whole(slider.rail.height) and slider.knob.texture.width and whole(slider.knob.texture.width), "a slider's rail and knob are whole screen pixels")
slider:SetSliderValues(6, 48, 1)
slider:SetValue(6)
slider:Restyle()
check(not slider.fill.inner[2].shown, "at its minimum a slider shows no fill, even after a restyle")
slider:SetValue(addon.db.profile.text.fontSize)
slider:Restyle()
check(slider.fill.inner[2].shown, "above it, the fill shows")
env.GetPhysicalScreenSize = nil

---------------------------------------------------------------------------
-- A multi-line field you can click into and type in
---------------------------------------------------------------------------
env.OpenAHOSOptionsPanel()
if not Panel:IsShown() then env.OpenAHOSOptionsPanel() end
Panel:SelectPage("display")
local field = row("Condition of Your Own (Lua)")
check(field and field.multiline and field.edit, "the condition is a multi-line field")
field.box.scripts.OnMouseDown(field.box)
check(field.edit:HasFocus(), "a click anywhere in the field gives it the caret")
check(field.edit:GetWidth() > 1 and field.edit:GetHeight() >= 14,
  "the edit box fills the field, so text and caret show: " .. field.edit:GetWidth() .. "x" .. field.edit:GetHeight())
field.edit:SetText("UnitExists(\"target\")")
field.edit.scripts.OnTextChanged(field.edit, true)
ns.OnOptionsChanged()
game.flush()
check(row("Condition of Your Own (Lua)") == field and field.edit:GetText() == "UnitExists(\"target\")" and field.edit:HasFocus(),
  "a redraw asked for while typing waits, and keeps what is typed")
check(Panel.pendingRefresh, "the redraw is held until the caret leaves")
field.accept.scripts.OnClick(field.accept)
check(addon.db.profile.visibility.condition == "UnitExists(\"target\")", "the tick saves the condition: " .. tostring(addon.db.profile.visibility.condition))
field = row("Condition of Your Own (Lua)")
check(field and field.edit:GetText() == "UnitExists(\"target\")", "and the field shows it after the redraw")
addon.db.profile.visibility.condition = ""

---------------------------------------------------------------------------
-- A page that runs past the window shows a scrollbar
---------------------------------------------------------------------------
do
  local scroll, bar = Panel.contentScroll, Panel.contentScrollbar
  check(scroll and bar, "the page has a scrollbar")
  local at, range = 0, 600
  scroll.GetVerticalScrollRange = function() return range end
  scroll.GetVerticalScroll = function() return at end
  scroll.SetVerticalScroll = function(self, v)
    at = v
    if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self, v) end
  end
  scroll:SetHeight(400)
  bar:SetHeight(400)
  scroll.scripts.OnScrollRangeChanged(scroll)
  check(bar:IsShown(), "the bar shows while the page runs past the window")
  check(bar.thumb:GetHeight() == 160, "the thumb is as long as the share in view: " .. tostring(bar.thumb:GetHeight()))
  scroll:SetVerticalScroll(600)
  local point = bar.thumb.points[#bar.thumb.points]
  check(point and point[5] == -240, "at the bottom the thumb sits at the bottom: " .. tostring(point and point[5]))
  -- dragging the thumb up by half its free travel scrolls half the page back
  game.cursor = { 0, 300 }
  bar.thumb.scripts.OnMouseDown(bar.thumb)
  game.cursor = { 0, 420 }
  bar.thumb.scripts.OnUpdate(bar.thumb)
  bar.thumb.scripts.OnMouseUp(bar.thumb)
  check(at == 300, "dragging the thumb scrolls the page: " .. tostring(at))
  check(not bar.thumb.scripts.OnUpdate, "and lets go")
  -- a click on the track above the thumb pages up
  game.cursor = { 0, 900 }
  bar.scripts.OnMouseDown(bar)
  check(at == 0, "a click above the thumb pages up: " .. tostring(at))
  -- nothing to scroll, no bar
  range = 0
  scroll.scripts.OnScrollRangeChanged(scroll)
  check(not bar:IsShown(), "no bar when the page fits")
  scroll.GetVerticalScrollRange, scroll.GetVerticalScroll, scroll.SetVerticalScroll = nil, nil, nil
end

print(string.format("TestPanel: %d checks passed (%s)", checks, toc or "Mainline"))
