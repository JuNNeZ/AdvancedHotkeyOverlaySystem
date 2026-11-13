-- Source-shaped fixtures for custom bars, run independently for every client.
local Mock = dofile("Tools/Mock.lua")
local checks = 0
local function check(value, message)
  if not value then error("FAILED: " .. message, 2) end
  checks = checks + 1
end
local function eq(actual, expected, message)
  check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local cases = {
  { key = "EllesmereUI", addon = "EllesmereUIActionBars", name = "EABButton1", bar = "1", field = "commandName", command = "ACTIONBUTTON1" },
  { key = "SpartanUI", addon = "SpartanUI", name = "SUI_ActionBar1Button1", bar = "1", command = "CLICK SUI_ActionBar1Button1:Keybind", config = true },
  { key = "DaylightUI", addon = "DaylightUI_ActionBars", name = "DaylightUIBar1Button1", bar = "1", field = "commandName", command = "ACTIONBUTTON1" },
  { key = "ForeverUI", addon = "ForeverUI", name = "ForeverUIbar1Button1", bar = "1", field = "fuiGameCommand", command = "ACTIONBUTTON1" },
  { key = "NDui", addon = "NDui", name = "NDui_ActionBar1Button1", bar = "1", field = "keyBoundTarget", command = "ACTIONBUTTON1", config = true },
  { key = "ElvUI", addon = "ElvUI", name = "ElvUI_Bar1Button1", bar = "1", field = "keyBoundTarget", command = "ACTIONBUTTON1", config = true },
  { key = "GW2_UI", addon = "GW2_UI", name = "ActionButton1", bar = "1", command = "ACTIONBUTTON1", provider = "Blizzard" },
}
for _, case in ipairs(cases) do
  local game = Mock.New({ toc = arg and arg[1], loaded = { [case.addon] = true }, bindings = { [case.command] = { "SHIFT-Q", "CTRL-Q" } } })
  local addon, env = game.addon, game.env
  local function update() addon.Core:FullUpdate(); game.flush() end
  local function overlay(b) return addon.Display:GetActiveOverlays()[b:GetName()] end
  eq(addon:DetectUI(), case.key, case.key .. " detected in isolation")
  local b = game.MakeButton(case.name, { action = 73 }) -- a paged main bar
  if case.provider == "Blizzard" then b.action = 1; game.actions[1] = true end
  if case.field then b[case.field] = case.command end
  if case.config then b.config = { keyBoundTarget = case.command, keyBoundClickButton = "Keybind" } end
  b.UpdateHotkeys = function(self) self.HotKey:SetText("native"); self.HotKey:Show() end
  update()
  eq(addon:GetProviderForButtonName(case.name).key, case.provider or case.key, case.key .. " button ownership")
  eq(addon.Bars:GetBarInfo(case.name), (case.provider or case.key) .. ":" .. case.bar, case.key .. " bar identity")
  eq(addon.Keybinds:GetBinding(b), "SQ", case.key .. " stable key through paging")
  eq(addon.Keybinds:GetSecondBindingText(b), "CTRL-Q", case.key .. " second binding")
  check(overlay(b), case.key .. " late-created button discovered")
  eq(overlay(b).text.text, "SQ", case.key .. " overlay text")
  b:UpdateHotkeys(); game.flush()
  eq(b.HotKey:GetText(), "", case.key .. " native redraw suppressed")
  game.bindings[case.command] = "ALT-E"
  game.fire("UPDATE_BINDINGS"); game.flush()
  eq(overlay(b).text.text, "AE", case.key .. " rebinding without reload")
  b:Hide(); update()
  check(not overlay(b) or not overlay(b):IsVisible(), case.key .. " hidden button has no visible overlay")
  b:Show(); update()
  check(overlay(b) and overlay(b):IsShown(), case.key .. " visible button recovers")

  if case.key == "EllesmereUI" then
    for _, item in ipairs({ {61, 2}, {145, 6}, {180, 8}, {13, 9}, {109, 10} }) do
      local name = "EABButton" .. item[1]
      local extra = game.MakeButton(name, { action = item[1] })
      extra.commandName = "EUI_BAR" .. item[2] .. "_BUTTON1"
      game.bindings[extra.commandName] = "F8"
      update()
      eq(addon.Bars:GetBarInfo(name), "EllesmereUI:" .. item[2], "EUI action-slot numbering")
      check(overlay(extra), "EUI extra/custom bar discovered")
      eq(addon.Keybinds:GetBinding(extra), "F8", "EUI custom binding command")
    end
  elseif case.key == "ForeverUI" then
    game.bindings["CLICK " .. case.name .. ":LeftButton"] = "F9"
    addon.Keybinds:ClearCache()
    eq(addon.Keybinds:GetBinding(b), "F9", "ForeverUI CLICK overrides game command")
    local pet = game.MakeButton("ForeverUIPetButton2", { action = 2, hotkeyField = "hotkey" })
    pet.fuiPetSlot = 2
    game.actions[2] = false -- must not query player action slot 2 for a pet order
    game.bindings.BONUSACTIONBUTTON2 = "CTRL-P"
    update()
    eq(addon:GetButtonActionSlot(pet), nil, "ForeverUI pet slot is not a player slot")
    eq(addon.Keybinds:GetBinding(pet), "CP", "ForeverUI pet binding")
    check(overlay(pet), "ForeverUI pet overlay when player slot is empty")
    eq(pet.hotkey:GetText(), "", "ForeverUI lower-case pet label suppressed")
  elseif case.key == "NDui" then
    local last = game.MakeButton("NDui_ActionBar8Button12", { action = 180 })
    last.keyBoundTarget = "MULTIACTIONBAR7BUTTON12"
    game.bindings.MULTIACTIONBAR7BUTTON12 = "F8"
    update()
    check(overlay(last), "NDui Forever eighth bar discovered")
    eq(addon.Bars:GetBarInfo(last:GetName()), "NDui:8", "NDui Forever bar identity")
    local old = game.MakeButton("NDui_ActionBarXButton1", { action = 85 })
    update()
    eq(addon.Bars:GetBarInfo(old:GetName()), "NDui:class", "older NDui class bar")
  elseif case.key == "ElvUI" then
    check(addon:ShouldShowOverlays(), "ElvUI enabled by default")
    addon.db.profile.forceOverlaysWithElvUI = false; update()
    check(not addon:ShouldShowOverlays() and not overlay(b), "ElvUI existing opt-out preserved")
    addon.db.profile.forceOverlaysWithElvUI = true; update()
    check(overlay(b), "ElvUI opt-in restores overlays")
  end
  addon.db.profile.enabled = false
  addon.Core:OnDisable(); game.flush()
  check(not overlay(b), case.key .. " overlays released on disable")
  eq(#game.errors, 0, case.key .. " no captured Lua errors")
end
print(string.format("TestCompatibility: %d checks passed (%s)", checks, tostring(arg and arg[1] or "default")))
