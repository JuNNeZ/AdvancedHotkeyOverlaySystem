-- Run from the addon folder: lua Tools/TestCore.lua [toc] (Lua 5.1).
--
-- Loads AHOS against the mock client in Tools/Mock.lua with action buttons from
-- every bar addon AHOS supports, and drives the engine: which key each button
-- shows (keybind detection per provider), the overlays drawn for them, the
-- visibility rules, the editor, presets, snapshots and profile switching, the
-- LibKeyBound hook, the slash commands, and a timing of a full update.
local checks = 0
local function check(value, message)
  if not value then error("FAILED: " .. message, 2) end
  checks = checks + 1
end
local function eq(actual, expected, message)
  check(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local Mock = dofile("Tools/Mock.lua")
local toc = arg and arg[1]
local game = Mock.New({
  toc = toc,
  loaded = { Dominos = true, Bartender4 = true, LUI = true, Neuron = true },
  bindings = {
    ACTIONBUTTON1 = "SHIFT-Q",
    ACTIONBUTTON2 = { "E", "CTRL-E" },        -- two keys on one button
    ACTIONBUTTON3 = "BUTTON4",                -- a mouse side button
    ACTIONBUTTON4 = "BUTTON1",
    ACTIONBUTTON5 = "MOUSEWHEELUP",
    MULTIACTIONBAR1BUTTON3 = "CTRL-3",
    MULTIACTIONBAR3BUTTON2 = "CTRL-W",
    ["CLICK DominosActionButton5:HOTKEY"] = "ALT-SHIFT-5",
    ["CLICK DominosActionButton205:HOTKEY"] = "F7",
    ["CLICK BT4Button13:Keybind"] = "SHIFT-F",
    ["CLICK LUIBarBottom2Button4:LeftButton"] = "ALT-4",
    ["CLICK LUIBarLeft1Button1:LeftButton"] = "NUMPAD1",
  },
})
local env, addon = game.env, game.addon
check(#game.errors == 0, "AHOS loads and logs in without errors: " .. tostring(game.errors[1]))
for _, name in ipairs({ "Visibility", "Editor", "Profiles", "Display", "Keybinds", "Bars", "Core" }) do
  check(addon[name], "module " .. name .. " is there")
end
local profile = addon.db.profile
local Display, Keybinds, Bars, Visibility, Editor, Profiles = addon.Display, addon.Keybinds, addon.Bars, addon.Visibility, addon.Editor, addon.Profiles

---------------------------------------------------------------------------
-- Buttons from every provider
---------------------------------------------------------------------------
local B = {}
B.ab1 = game.MakeButton("ActionButton1", { action = 1 })
B.ab2 = game.MakeButton("ActionButton2", { action = 2 })
B.ab3 = game.MakeButton("ActionButton3", { action = 3 })
B.ab4 = game.MakeButton("ActionButton4", { action = 4 })
B.ab5 = game.MakeButton("ActionButton5", { action = 5 })
B.ab6 = game.MakeButton("ActionButton6", { action = 6, empty = true })     -- empty slot
B.bl3 = game.MakeButton("MultiBarBottomLeftButton3", { action = 63 })
B.r2 = game.MakeButton("MultiBarRightButton2", { action = 26 })
B.dom5 = game.MakeButton("DominosActionButton5", { action = 5 })
-- Dominos set up with more bars numbers on past its usual 200
for i = 201, 204 do game.MakeButton("DominosActionButton" .. i, { action = i - 100 }) end
B.dom205 = game.MakeButton("DominosActionButton205", { action = 105 })
B.bt13 = game.MakeButton("BT4Button13", { action = 13 })
B.lui = game.MakeButton("LUIBarBottom2Button4", { action = 16 })
B.luiLeft = game.MakeButton("LUIBarLeft1Button1", { action = 40 })
local neuronBar = env.CreateFrame("Frame", "NeuronActionBar1", env.UIParent)
B.neuron = game.MakeButton("NeuronActionBar1_ActionButton3", { parent = neuronBar, action = 90, hotkeyField = "Hotkey" })
B.neuron.keys = { hotKeys = ":F:SHIFT-G:" }
env.Neuron = {}

local function update()
  addon.Core:FullUpdate()
  game.flush()
end
local function overlays() return Display:GetActiveOverlays() end
local function overlay(button) return overlays()[button:GetName()] end
update()

---------------------------------------------------------------------------
-- Keybind detection, per provider
---------------------------------------------------------------------------
eq(Keybinds:GetBinding(B.ab1), "SQ", "Blizzard bar 1 by action slot")
eq(Keybinds:GetBinding(B.bl3), "C3", "Blizzard bottom-left bar by action slot")
eq(Keybinds:GetBinding(B.dom5), "AS5", "Dominos through its CLICK :HOTKEY binding")
eq(Keybinds:GetBinding(B.bt13), "SF", "Bartender4 through its CLICK :Keybind binding")
eq(Keybinds:GetBinding(B.lui), "A4", "LUI through its CLICK :LeftButton binding")
eq(Keybinds:GetBinding(B.luiLeft), "N1", "LUI side bar")
eq(Keybinds:GetBinding(B.neuron), "F", "Neuron through the key list on the button")
eq(Keybinds:GetSecondBindingText(B.neuron), "SHIFT-G", "Neuron's second key")
eq(Keybinds:GetSecondBindingText(B.ab2), "CTRL-E", "a command's second key")
eq(Keybinds:GetSecondBindingText(B.ab1), nil, "one key, no second")

local tracked = {}
for _, b in ipairs(Bars:GetAllButtons(true)) do tracked[b:GetName()] = true end
for key, button in pairs(B) do check(tracked[button:GetName()], "tracked: " .. key) end
eq(addon:GetProviderForButtonName("LUIBarRight2Button7").key, "LUI", "LUI button names")
eq(addon:GetProviderForButtonName("NeuronPetBar1_PetButton2").key, "Neuron", "Neuron pet button names")

local key, label = Bars:GetBarInfo("LUIBarBottom2Button4")
eq(key, "LUI:2", "LUI bottom bar key")
key, label = Bars:GetBarInfo("LUIBarLeft1Button1")
eq(key, "LUI:Left1", "LUI side bar key")
check(label:find("Left Sidebar 1", 1, true), "LUI side bar label: " .. tostring(label))
eq((Bars:GetBarInfo("NeuronActionBar2_ActionButton7")), "Neuron:2", "Neuron bar key")
eq((Bars:GetBarInfo("DominosActionButton205")), "Dominos:18", "Dominos bar from the global index")

-- Abbreviations
profile.text.mouseIcons = true
Keybinds:ClearCache()
local side = Keybinds:GetBinding(B.ab3)
check(side:find("mouse-side", 1, true) and side:sub(-1) == "4", "a side button is an icon and its number: " .. side)
check(Keybinds:GetBinding(B.ab4):find("mouse-left", 1, true), "the left button is an icon")
check(Keybinds:GetBinding(B.ab5):find("mouse-wheelup", 1, true), "the wheel is an icon")
check(side:find(":255:255:255|t", 1, true), "the icon is tinted to the text colour")
Keybinds:SetCustomAbbreviation("BUTTON4", "M4")
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab3), "M4", "an abbreviation of your own beats the icon")
Keybinds:SetCustomAbbreviation("BUTTON4", "")
profile.text.mouseIcons = false
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab3), "B4", "without icons a mouse button is text")

profile.text.showAllBindings = true
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab2), "E/CE", "both keys of a button")
eq(Keybinds:GetBinding(B.neuron), "F/SG", "both of Neuron's keys")
profile.text.bindingSeparator = " "
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab2), "E CE", "the separator is yours")
profile.text.showAllBindings, profile.text.bindingSeparator = false, "/"
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab2), "E", "one key again")

---------------------------------------------------------------------------
-- Overlays
---------------------------------------------------------------------------
update()
check(overlay(B.ab1), "an overlay on a bound button")
eq(overlay(B.ab1).text.text, "SQ", "the overlay shows the abbreviation")
check(not overlay(B.ab6), "no overlay on an empty slot")
check(overlay(B.neuron), "an overlay on a Neuron button")
eq(B.ab1.hotkey.text, "", "the button's own label is hidden")
local pt = overlay(B.ab1).text.points[#overlay(B.ab1).text.points]
eq(pt[1], profile.display.anchor, "anchored where the profile says")

-- A bar with a place of its own
profile.bars["Blizzard:1"] = { position = true, anchor = "BOTTOM", xOffset = 3, yOffset = 4 }
Display:UpdateAllOverlayStyles()
pt = overlay(B.ab1).text.points[#overlay(B.ab1).text.points]
check(pt[1] == "BOTTOM" and pt[4] == 3 and pt[5] == 4, "bar 1 uses its own place")
pt = overlay(B.bl3).text.points[#overlay(B.bl3).text.points]
eq(pt[1], profile.display.anchor, "another bar keeps the profile's place")
profile.bars["Blizzard:1"] = nil
Bars:PruneBarSettings("Blizzard:1")

-- Shadow, glow and plate
profile.text.shadowEnabled = true
profile.text.shadowColor = { 0.2, 0.3, 0.4, 0.5 }
profile.text.glow = { enabled = true, color = { 1, 0, 0, 0.7 } }
profile.display.background = { enabled = true, color = { 0, 0, 1, 0.5 }, padding = 3 }
Display:UpdateAllOverlayStyles()
local o = overlay(B.ab1)
check(o.glow and o.glow.shown and o.glow.text == "SQ", "the glow is a copy of the text")
eq(o.glow.font and o.glow.font[3], "THICKOUTLINE", "the glow is a thick outline")
check(o.bg and o.bg.shown and o.bg.colorTexture[3] == 1, "the plate is drawn in its colour")
profile.text.glow.enabled, profile.display.background.enabled = false, false
Display:UpdateAllOverlayStyles()
check(not o.glow.shown and not o.bg.shown, "glow and plate go when turned off")

-- One button left alone
Bars:SetButtonIgnored("ActionButton1", true)
update()
check(not overlay(B.ab1), "no overlay on an ignored button")
eq(Display:GetButtonState("ActionButton1"), "ignored", "the inspector sees it is ignored")
eq(B.ab1.hotkey.text, "s-Q", "an ignored button shows its own key text")
check(Bars:GetIgnoredButtons()[1] == "ActionButton1", "listed as ignored")
Bars:SetButtonIgnored("ActionButton1", false)
update()
check(overlay(B.ab1), "drawn on again")

-- First login: the label was never filled, so there is no original to put back.
check(overlay(B.r2), "an overlay on the right bar")
addon.db.profile.enabled = false
addon.Core:OnDisable()
game.flush()
eq(B.r2.hotkey.text, "c-W", "turning AHOS off writes the key text the label never had")
addon.db.profile.enabled = true
addon.Core:OnEnable()
update()
check(overlay(B.r2), "overlays back on")

-- Blizzard's UpdateHotkeys(actionButtonType) reads "ACTIONBUTTON" .. id when it is
-- given no type. An empty button on the bottom-right bar must not show the main
-- bar's key for its number.
game.bindings.ACTIONBUTTON7 = "SHIFT-E"
local br7 = game.MakeButton("MultiBarBottomRightButton7", { action = 55 })
br7.buttonType = "MULTIACTIONBAR2BUTTON"
br7.GetID = function() return 7 end
br7.UpdateHotkeys = function(self, actionButtonType)
  local key = env.GetBindingKey((actionButtonType or "ACTIONBUTTON") .. self:GetID())
  -- no key: Blizzard writes RANGE_INDICATOR, the dot it shows while in range
  self.HotKey:SetText(key and env.GetBindingText(key, 1) or "\226\151\143")
end
update()
check(not overlay(br7), "no overlay on an unbound bottom-right button")
check(br7.hotkey.text ~= "s-E", "its label does not show the main bar's key: " .. tostring(br7.hotkey.text))
eq(br7.hotkey.text, "", "nor the range dot")
br7:UpdateHotkeys(br7.buttonType)
eq(br7.hotkey.text, "", "not even when Blizzard redraws it")
addon.db.profile.enabled = false
addon.Core:OnDisable()
game.flush()
check(br7.hotkey.text ~= "s-E", "nor with AHOS off: " .. tostring(br7.hotkey.text))
eq(br7.hotkey.text, "\226\151\143", "with AHOS off the button shows the game's own range dot")
-- Hide the Range Dot works with AHOS off too
profile.display.hideRangeDot = true
addon.Core:FullUpdate()
game.flush()
eq(br7.hotkey.text, "", "Hide the Range Dot blanks it with AHOS off")
br7:UpdateHotkeys(br7.buttonType)
eq(br7.hotkey.text, "", "and keeps it blank when the game redraws it")
profile.display.hideRangeDot = false
br7:UpdateHotkeys(br7.buttonType)
eq(br7.hotkey.text, "\226\151\143", "turned off, the dot is back")
addon.db.profile.enabled = true
addon.Core:OnEnable()
game.bindings.ACTIONBUTTON7 = nil
Keybinds:ClearCache()
update()

---------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------
local vis = profile.visibility
vis.fadeOutOfCombat = true
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 0, "faded out of combat")
local count, faded = Visibility:GetCounts()
check(count > 0 and faded == count, "every overlay is faded")
game.combat = true
game.fire("PLAYER_REGEN_DISABLED")
check(Visibility:InCombat(), "combat seen")
Visibility.Step(0.1)
local mid = overlay(B.ab1):GetAlpha()
check(mid > 0 and mid < 1, "fading in: " .. tostring(mid))
Visibility.Step(1)
eq(overlay(B.ab1):GetAlpha(), 1, "shown in combat")
game.combat = false
game.fire("PLAYER_REGEN_ENABLED")
Visibility.Step(1)
eq(overlay(B.ab1):GetAlpha(), 0, "faded again after combat")
vis.fadedAlpha = 0.4
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 0.4, "the faded alpha is yours")
game.flush()
check(Display:GetButtonState("ActionButton1") == "overlay", "a faded overlay never falls back to the native label")
vis.fadeOutOfCombat, vis.fadedAlpha = false, 0

vis.modifierOnly = true
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 0, "hidden until a modifier is held")
game.shift = true
game.fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
eq(overlay(B.ab1):GetAlpha(), 1, "shown while Shift is held")
game.shift = false
game.fire("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
eq(overlay(B.ab1):GetAlpha(), 0, "hidden when it is let go")
vis.modifierOnly = false
Visibility:OnSettingsChanged()

-- Mouseover per bar
profile.bars["Blizzard:1"] = { mouseover = true }
Visibility:Refresh(true)
eq(overlay(B.ab1):GetAlpha(), 0, "a mouseover bar is hidden")
eq(overlay(B.bl3):GetAlpha(), 1, "other bars are not")
B.ab2.scripts.OnEnter(B.ab2)
Visibility.Step(1)
eq(overlay(B.ab1):GetAlpha(), 1, "the mouse over any button shows the whole bar")
eq(Visibility:GetHoveredBar(), "Blizzard:1", "the hovered bar")
B.ab2.scripts.OnLeave(B.ab2)
B.ab1.scripts.OnEnter(B.ab1)        -- on to the next button: no fade between
game.flush()
eq(Visibility:GetHoveredBar(), "Blizzard:1", "moving along the bar keeps it shown")
B.ab1.scripts.OnLeave(B.ab1)
game.flush()
Visibility.Step(1)
eq(overlay(B.ab1):GetAlpha(), 0, "hidden again when the mouse leaves")
profile.bars["Blizzard:1"] = nil

-- A condition of your own
vis.condition = 'bar == "Blizzard:1"'
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 1, "the condition shows bar 1")
eq(overlay(B.bl3):GetAlpha(), 0, "and hides the others")
vis.condition = 'return key == "CTRL-3"'
Visibility:OnSettingsChanged()
eq(overlay(B.bl3):GetAlpha(), 1, "the condition can read the key")
check(Visibility:CheckCondition("UnitExists('target')"), "a good condition checks")
check(not Visibility:CheckCondition("bar ==="), "a broken one does not")
local printed = #game.printed
vis.condition = 'error("boom")'
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 1, "a condition that errors shows the text")
eq(#game.printed, printed + 1, "and says so once")
vis.condition = 'os ~= nil or print ~= nil or _G ~= nil'
Visibility:OnSettingsChanged()
eq(overlay(B.ab1):GetAlpha(), 0, "the condition cannot reach os, print or _G")
vis.condition = ""
Visibility:OnSettingsChanged()
Visibility:CancelAllTimers()

-- Combat style
vis.combatStyle = { enabled = true, color = { 1, 0, 0 }, scale = 1.5 }
local scaleBefore = overlay(B.ab1):GetScale()
game.fire("PLAYER_REGEN_DISABLED")
o = overlay(B.ab1)
check(o.text.textColor[1] == 1 and o.text.textColor[2] == 0, "the combat colour")
check(math.abs(o:GetScale() - scaleBefore * 1.5) < 1e-6, "the combat size")
game.fire("PLAYER_REGEN_ENABLED")
check(math.abs(o:GetScale() - scaleBefore) < 1e-6, "back to size after combat")
vis.combatStyle.enabled = false

-- Pressing a button
profile.display.pressAnimation = "flash"
Display:UpdateAllOverlayStyles()
B.ab1:SetButtonState("PUSHED")
o = overlay(B.ab1)
check(o.text.textColor[1] == 1 and o.text.textColor[2] == 0.82, "a press flashes the text")
Visibility.Step(1)
check(o.text.textColor[2] == 1, "and it fades back")
profile.display.pressAnimation = "pulse"
game.time = game.time + 1
B.ab1:SetButtonState("PUSHED")
check(o:GetScale() > scaleBefore, "a pulse grows the text")
check(o.text.textColor[2] == 0.82, "in the press colour")
Visibility.Step(1)
check(math.abs(o:GetScale() - scaleBefore) < 1e-6, "and it settles")
check(o.text.textColor[2] == 1, "and its colour")
-- A key bound to a Blizzard button runs ActionButtonDown / MultiActionButtonDown.
profile.display.pressAnimation = "flash"
game.time = game.time + 1
env.ActionButtonDown(1)
check(o.text.textColor[2] == 0.82, "a key press on the main bar flashes the text")
Visibility.Step(1)
env.MultiActionButtonDown("MultiBarRight", 2)
check(overlay(B.r2).text.textColor[2] == 0.82, "and one on another Blizzard bar")
Visibility.Step(1)
-- A key press goes down, then clicks when let go: one press, one flash.
game.time = game.time + 1
env.ActionButtonDown(1)
Visibility.Step(1)
game.time = game.time + 0.4
B.ab1:GetScript("PostClick")(B.ab1)
check(o.text.textColor[2] == 1, "letting the key go does not flash again")
-- A mouse click, with no down before it, flashes on the click.
game.time = game.time + 1
B.ab1:GetScript("PostClick")(B.ab1)
check(o.text.textColor[2] == 0.82, "a mouse click flashes")
Visibility.Step(1)
game.time = game.time + 0.3
B.ab1:GetScript("PostClick")(B.ab1)
check(o.text.textColor[2] == 0.82, "and so does the next click soon after")
Visibility.Step(1)
profile.display.pressAnimation = "none"

---------------------------------------------------------------------------
-- The editor
---------------------------------------------------------------------------
game.lockdown = true
check(not Editor:Start(), "no editing in combat")
game.lockdown = false
check(Editor:Start(), "edit mode starts")
check(Editor:IsActive() and Editor:GetStrip().shown, "with its strip")
o = overlay(B.ab1)
check(o.mouse and o.scripts.OnMouseDown, "an overlay takes the mouse while editing")
local x0, y0 = profile.display.xOffset, profile.display.yOffset
game.cursor = { 100, 100 }
o.scripts.OnMouseDown(o, "LeftButton")
game.cursor = { 110, 95 }
o.scripts.OnUpdate(o, 0.1)
o.scripts.OnMouseUp(o, "LeftButton")
eq(profile.display.xOffset, x0 + 10, "a drag moves the text right")
eq(profile.display.yOffset, y0 - 5, "and down")
game.shift = true
o.scripts.OnMouseDown(o, "LeftButton")
game.cursor = { 130, 95 }
o.scripts.OnMouseUp(o, "LeftButton")
game.shift = false
local barSettings = profile.bars["Blizzard:1"]
check(barSettings and barSettings.position and barSettings.xOffset == x0 + 30, "Shift-drag moves one bar")
eq(profile.display.xOffset, x0 + 10, "and leaves the others")
o.scripts.OnMouseDown(o, "RightButton")
check(profile.bars["Blizzard:1"] == nil, "right-click gives the bar back to the profile")
game.cursor = { 0, 0 }
o.scripts.OnMouseDown(o, "LeftButton")
game.cursor = { 10000, 0 }
o.scripts.OnMouseUp(o, "LeftButton")
eq(profile.display.xOffset, 50, "offsets stay within the sliders' range")
profile.display.xOffset, profile.display.yOffset = x0, y0
vis.fadeOutOfCombat = true
Visibility:Refresh(true)
eq(overlay(B.ab1):GetAlpha(), 1, "everything shows while editing")
game.fire("PLAYER_REGEN_DISABLED")
check(not Editor:IsActive(), "combat ends edit mode")
check(not o.mouse and not o.scripts.OnMouseDown, "and gives the mouse back")
game.fire("PLAYER_REGEN_ENABLED")
vis.fadeOutOfCombat = false
Visibility:OnSettingsChanged()

---------------------------------------------------------------------------
-- Presets, snapshots, profiles
---------------------------------------------------------------------------
local db = addon.db
local snapshots = #Profiles:GetSnapshots()
local anchorBefore = profile.display.anchor
check(Profiles:ApplyPreset("centered"), "a preset applies")
eq(db.profile.display.anchor, "CENTER", "the preset's anchor")
eq(db.profile.text.fontSize, 20, "the preset's size")
eq(#Profiles:GetSnapshots(), snapshots + 1, "a snapshot is taken first")
check(Profiles:RestoreSnapshot(1), "rollback")
eq(db.profile.display.anchor, anchorBefore, "rollback puts the anchor back")
eq(db.profile.text.fontSize, 16, "and the size")
-- Every preset, back to back, keeps the text. With the text in the top-right corner
-- the search for a button's own label used to take the overlay's text for one and
-- blank it, for good.
update()
for _, preset in ipairs(Profiles.Presets) do
  Profiles:ApplyPreset(preset.key)
  game.flush()
  local shownText = overlay(B.ab1) and overlay(B.ab1).text.text
  check(shownText and shownText ~= "", "after the " .. preset.label .. " preset the text is still there: " .. tostring(shownText))
  Profiles:RestoreSnapshot(1)
  game.flush()
end
profile = db.profile
profile.display.anchor = "TOPRIGHT"
update()
eq(overlay(B.ab1).text.text, "SQ", "text in the top-right corner is not taken for the button's own label")
check(not B.ab1.hotkey._ahosOwn and overlay(B.ab1).text._ahosOwn, "the overlay's text is marked as AHOS's own")
profile.display.anchor = anchorBefore
update()
check(Profiles:ApplyPreset("Healer"), "presets answer to their label too")
check(db.profile.text.modifierColors.enabled and db.profile.text.modifierColors.hideModifiers, "the healer template colours by modifier")
check(db.profile.text.modifierColors.shift, "a preset keeps what it does not set")
check(not Profiles:ApplyPreset("nope"), "an unknown preset")
Profiles:RestoreSnapshot(1)
check(not db.profile.text.modifierColors.enabled, "undone")
check(Profiles:TakeSnapshot("mine"), "a snapshot of your own")
eq(Profiles:GetSnapshots()[1].label, "mine", "newest first")
for i = 1, 20 do Profiles:TakeSnapshot("n" .. i) end
eq(#Profiles:GetSnapshots(), 15, "at most fifteen are kept")
check(Profiles:DeleteSnapshot(1) and Profiles:GetSnapshots()[1].label == "n19", "one deleted")
check(Profiles:DescribeSnapshot(1):find("n19", 1, true), "described")

db.profile.text.fontSize = 22
check(Profiles:SaveAs("Raid"), "save as a new profile")
eq(db:GetCurrentProfile(), "Raid", "switched to it")
eq(db.profile.text.fontSize, 22, "a copy of the one before")
addon:SlashHandler("profile Default")
eq(db:GetCurrentProfile(), "Default", "/ahos profile switches")
addon:SlashHandler("profiles")
check(game.printed[#game.printed]:find("Raid", 1, true) or game.printed[#game.printed - 1]:find("Raid", 1, true), "/ahos profiles lists them")
db.profile.text.fontSize = 16

-- Switching by itself
db.char.autoSwitch = "spec"
check(Profiles:AutoSwitch(), "switches by specialization")
eq(db:GetCurrentProfile(), "Tester-Realm-Beast Mastery", "the specialization's profile")
check(not Profiles:AutoSwitch(), "and not again")
env.C_ClassTalents = { GetLastSelectedSavedConfigID = function(spec) return spec == 253 and 77 or nil end }
env.C_Traits = { GetConfigInfo = function(id) return id == 77 and { name = "Raid ST" } or nil end }
db.char.autoSwitch = "loadout"
check(Profiles:AutoSwitch(), "switches by loadout")
eq(db:GetCurrentProfile(), "Tester-Realm-Beast Mastery-Raid ST", "the loadout's profile")
db.char.autoSwitch = "off"
check(not Profiles:AutoSwitch(), "off is off")
db:SetProfile("Default")
db.char.autoSwitch = "loadout"
db.profile.autoSwitchProfile = true
Profiles:OnEnable()
eq(db.char.autoSwitch, "loadout", "an existing choice is kept")
db.char.autoSwitch = "off"
db.profile.autoSwitchProfile = true
Profiles:OnEnable()
eq(db.char.autoSwitch, "spec", "the old per-profile switch moves to the character")
eq(db.profile.autoSwitchProfile, nil, "and leaves the profile")
db.char.autoSwitch = "off"
update()

---------------------------------------------------------------------------
-- LibKeyBound arriving late
---------------------------------------------------------------------------
check(not addon.Core:IsKeyBoundHooked(), "no LibKeyBound yet")
local KB = env.LibStub:NewLibrary("LibKeyBound-1.0", 1)
local callbacks = {}
KB.RegisterCallback = function(owner, event, fn) callbacks[event] = fn end
game.fire("ADDON_LOADED", "Dominos")
check(addon.Core:IsKeyBoundHooked(), "hooked when the bar addon that brings it loads")
check(callbacks.LIBKEYBOUND_ENABLED and callbacks.LIBKEYBOUND_DISABLED, "both callbacks")
callbacks.LIBKEYBOUND_DISABLED()
game.flush()
check(#game.errors == 0, "leaving keybind mode refreshes cleanly")

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
for _, command in ipairs({ "help", "presets", "preset compact", "snapshot test", "snapshot list", "rollback",
  "ignore ActionButton2", "unignore ActionButton2", "ignore", "edit", "edit", "refresh" }) do
  local ok, err = pcall(addon.SlashHandler, addon, command)
  check(ok, "/ahos " .. command .. ": " .. tostring(err))
end
game.flush()
check(not Bars:IsButtonIgnored("ActionButton2"), "/ahos unignore")

---------------------------------------------------------------------------
-- Masque: the overlay follows the skin's place for the hotkey
---------------------------------------------------------------------------
local icon = env.CreateFrame("Frame", nil, B.bl3)
B.bl3._MSQ_CFG = {
  Enabled = true,
  Regions = { Icon = icon },
  Skin = { HotKey = { Anchor = "Icon", Point = "BOTTOMLEFT", RelPoint = "BOTTOMLEFT", OffsetX = 4, OffsetY = 2,
    Width = 30, JustifyH = "LEFT", JustifyV = "BOTTOM" } },
  GetScale = function() return 1, 1 end,
  GetTypeSkin = function(_, _, skin) return skin end,
}
profile.display.followMasque = true
update()
o = overlay(B.bl3)
local scale = Display:GetOverlayScale(B.bl3, profile)
pt = o.text.points[#o.text.points]
check(pt[1] == "BOTTOMLEFT" and pt[2] == icon and pt[3] == "BOTTOMLEFT", "the text sits where the skin puts the hotkey, on the icon")
check(math.abs(pt[4] - 4 / scale) < 1e-6 and math.abs(pt[5] - 2 / scale) < 1e-6, "at the skin's offsets, in the overlay's scale")
eq(o.text.width, 30 / scale, "as wide as the skin's hotkey")
pt = overlay(B.ab1).text.points[#overlay(B.ab1).text.points]
eq(pt[1], profile.display.anchor, "a button Masque does not skin keeps the profile's place")
profile.bars["Blizzard:2"] = { position = true, anchor = "CENTER", xOffset = 0, yOffset = 0 }
Display:UpdateAllOverlayStyles()
pt = o.text.points[#o.text.points]
eq(pt[1], "CENTER", "a bar with a place of its own keeps it over the skin")
profile.bars["Blizzard:2"] = nil
-- a skin picked in Masque places the label again; the overlay follows
B.bl3._MSQ_CFG.Skin.HotKey.Point, B.bl3._MSQ_CFG.Skin.HotKey.RelPoint = "TOPLEFT", "TOPLEFT"
B.bl3.hotkey:SetPoint("TOPLEFT", B.bl3, "TOPLEFT", 0, 0)
game.flush()
pt = o.text.points[#o.text.points]
eq(pt[1], "TOPLEFT", "a new skin moves the overlay with it")
-- where Masque put the label wins over the skin's table (skins leave most of it to defaults)
B.bl3.hotkey.points = {}
B.bl3.hotkey:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 3)
game.flush()
pt = o.text.points[#o.text.points]
check(pt[1] == "BOTTOMRIGHT" and pt[2] == icon and math.abs(pt[4] - -1 / scale) < 1e-6,
  "the overlay goes where Masque left the label, not where the skin table says")
profile.display.followMasque = false
Display:UpdateAllOverlayStyles()
pt = o.text.points[#o.text.points]
eq(pt[1], profile.display.anchor, "off, the profile's place again")
eq(o.text.width, 0, "and the text sizes to itself")

-- Cyrillic keys show in capitals on the bars
game.bindings.ACTIONBUTTON1 = "SHIFT-й"
Keybinds:ClearCache()
eq(Keybinds:GetBinding(B.ab1), "SЙ", "a Cyrillic key in capitals")
update()
eq(overlay(B.ab1).text.font[1], "Fonts\\FRIZQT___CYR.TTF", "drawn in the game's Cyrillic face")
eq(addon.Config:GetScriptFont("A3"), nil, "Latin text keeps the profile's font")
eq(addon.Config:GetScriptFont("ㅂ"), "Fonts\\2002.TTF", "Hangul uses the Korean face")
eq(addon.Config:GetScriptFont("ㄅ"), "Fonts\\blei00d.TTF", "Zhuyin uses the Traditional Chinese face")
eq(addon.Config:GetScriptFont("|TInterface\\x:14|tя"), "Fonts\\FRIZQT___CYR.TTF", "markup is not read as letters")
game.bindings.ACTIONBUTTON1 = "SHIFT-Q"
Keybinds:ClearCache()

---------------------------------------------------------------------------
-- Timing: a full update over a large set of bars
---------------------------------------------------------------------------
for i = 1, 300 do
  local b = game.MakeButton("DominosActionButton" .. (205 + i), { action = 200 + i })
  game.bindings["CLICK " .. b:GetName() .. ":HOTKEY"] = "CTRL-SHIFT-" .. (i % 10)
end
local start = os.clock()
local passes = 5
for _ = 1, passes do Display:UpdateAllOverlays() end
local ms = (os.clock() - start) * 1000 / passes
local drawn = 0
for _ in pairs(overlays()) do drawn = drawn + 1 end
check(drawn > 300, "every button drawn: " .. drawn)
check(ms < 500, string.format("a full update stays quick (%.1f ms)", ms))
start = os.clock()
for _ = 1, 20 do Visibility:Refresh(true) end
local visMs = (os.clock() - start) * 1000 / 20
check(#game.errors == 0, "no errors at the end: " .. tostring(game.errors[1]))

print(string.format("TestCore: %d checks passed (%s)  |  full update of %d buttons: %.1f ms, visibility pass: %.2f ms",
  checks, toc or "Mainline", drawn, ms, visMs))
