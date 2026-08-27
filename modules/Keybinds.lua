---@diagnostic disable: undefined-global
--[[
Keybinds.lua - Advanced Hotkey Overlay System
---------------------------------------------------------
Manages keybinding detection, mapping, and abbreviation for overlays.
--]]

local addonName, privateScope = ...
local addon = privateScope.addon
local Keybinds = addon.Keybinds
local GetButtonCommandName

function Keybinds:OnInitialize()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Keybinds module initialized.")
    end
end

local keybindCache = {}
-- Utility: return the first non-empty keybinding from GetBindingKey (which may return up to two values)
local function FirstBindingKey(command)
    if not command then return nil end
    local k1, k2 = GetBindingKey(command)
    if not addon:IsValueAccessible(k1) then k1 = nil end
    if not addon:IsValueAccessible(k2) then k2 = nil end
    if k1 and k1 ~= "" and k1 ~= "\0" then return k1 end
    if k2 and k2 ~= "" and k2 ~= "\0" then return k2 end
    return nil
end

local function SafeFrameValue(frame, methodName, ...)
    if not frame then return nil end
    local methodOk, method = pcall(function() return frame[methodName] end)
    if not methodOk or type(method) ~= "function" then return nil end
    local ok, value = pcall(method, frame, ...)
    if ok and addon:IsValueAccessible(value) then return value end
    return nil
end

local function SafeObjectValue(object, key)
    if not object then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok and addon:IsValueAccessible(value) then return value end
    return nil
end

local function GetSafeButtonName(button)
    local name = SafeFrameValue(button, "GetName")
    if type(name) == "string" and name ~= "" then return name end
    return nil
end

local function GetBindingCacheKey(button, provider)
    local buttonName = GetSafeButtonName(button) or ""
    local actionId = addon:GetButtonActionSlot(button) or ""
    local state = SafeObjectValue(button, "state") or SafeFrameValue(button, "GetAttribute", "state") or ""
    local parent = SafeFrameValue(button, "GetParent")
    local parentState = SafeFrameValue(parent, "GetAttribute", "state") or SafeFrameValue(parent, "GetAttribute", "state-page") or ""
    local route = SafeObjectValue(button, "__AzeriteUI_BindingRoute") or ""
    local mode = SafeObjectValue(button, "__AzeriteUI_BindingMode") or ""
    local command = GetButtonCommandName(button, provider) or ""

    return table.concat({
        addon:SafeToString(buttonName, ""),
        addon:SafeToString(actionId, ""),
        addon:SafeToString(state, ""),
        addon:SafeToString(parentState, ""),
        addon:SafeToString(route, ""),
        addon:SafeToString(mode, ""),
        addon:SafeToString(command, ""),
    }, "|")
end


-- Simple build gate: Retail Dragonflight+ has build numbers >= 100000
local isRetail = (select(4, GetBuildInfo()) or 0) >= 100000

local function GetButtonProvider(buttonName)
    return addon and addon.GetProviderForButtonName and addon:GetProviderForButtonName(buttonName) or addon.ProviderRegistry.Blizzard
end

function GetButtonCommandName(button, provider)
    if not button then return nil end
    local getBindingAction = SafeObjectValue(button, "GetBindingAction")
    if type(getBindingAction) == "function" then
        local ok, cmd = pcall(getBindingAction, button)
        if ok and addon:IsValueAccessible(cmd) and cmd and cmd ~= "" then return cmd end
    end
    local config = SafeObjectValue(button, "config")
    if config then
        local cmd = SafeObjectValue(config, "keyBoundTarget")
        if addon:IsValueAccessible(cmd) and cmd and cmd ~= "" then return cmd end
        local clickButton = SafeObjectValue(config, "keyBoundClickButton")
        if addon:IsValueAccessible(clickButton) and clickButton and clickButton ~= "" then
            local buttonName = GetSafeButtonName(button)
            if buttonName and buttonName ~= "" then
                return "CLICK " .. buttonName .. ":" .. clickButton
            end
        end
    end
    local fields = (provider and provider.command_fields) or { "commandName", "keyBoundTarget" }
    for _, field in ipairs(fields) do
        local cmd = SafeObjectValue(button, field)
        if cmd and cmd ~= "" then return cmd end
        cmd = SafeFrameValue(button, "GetAttribute", field)
        if cmd and cmd ~= "" then return cmd end
    end
    return nil
end

local function ResolveProviderExplicitBinding(buttonName, provider)
    if not buttonName or not provider or not provider.binding_rules then return nil end
    for _, rule in ipairs(provider.binding_rules) do
        if buttonName:match(rule.matcher) then
            for _, suffix in ipairs(rule.suffixes or {}) do
                local key = FirstBindingKey("CLICK " .. buttonName .. suffix)
                if key and key ~= "" then
                    return key
                end
            end
        end
    end
    return nil
end

local function IsTopRightAnchor(region)
    if not region or not region.GetPoint then return false end
    local ok, p1, _, p2 = pcall(region.GetPoint, region, 1)
    if not ok then return false end
    if not addon:IsValueAccessible(p1) or not addon:IsValueAccessible(p2) then return false end
    return p1 == "TOPRIGHT" or p2 == "TOPRIGHT"
end

-- Get the on-screen hotkey text from a button's FontString before we hide it
local function IsFallbackHotkeyGlyph(text)
    if not text or text == "" then return false end
    return text == "●" or text == "\226\151\136" or text == "\u{25CF}" -- bullet
        or text == "■" or text == "\u{25A0}" -- black square
        or text == "□" or text == "\u{25A1}" -- white square
        or text == "◼" or text == "\u{25FC}" -- black medium square
        or text == "◻" or text == "\u{25FB}" -- white medium square
        or text == "�"
end

local function GetVisualHotkeyText(button)
    if not button then return nil end
    local name = GetSafeButtonName(button)
    if not name then return nil end
    local fs = SafeObjectValue(button, "HotKey") or _G[name .. "HotKey"]
    local getRegions = SafeObjectValue(button, "GetRegions")
    if not fs and type(getRegions) == "function" then
        local values = { pcall(getRegions, button) }
        local ok = table.remove(values, 1)
        for _, region in ipairs(ok and values or {}) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = GetSafeButtonName(region) or ""
                if (rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey"))) then
                    fs = region; break
                end
                if IsTopRightAnchor(region) then
                    fs = region; break
                end
            end
        end
    end
    local t = SafeFrameValue(fs, "GetText")
    if t and t ~= "" and t ~= "\0" and not IsFallbackHotkeyGlyph(t) then return t end
    return nil
end

-- Helper: resolve binding command directly from button name (Classic-safe)
local function GetBindingCommandFromButtonName(buttonName)
    if not buttonName or type(buttonName) ~= "string" then return nil end
    -- Blizzard default bars
    local n
    n = buttonName:match("^ActionButton(%d+)$")
    if n then return "ACTIONBUTTON" .. n end
    n = buttonName:match("^BonusActionButton(%d+)$")
    if n then return "ACTIONBUTTON" .. n end
    n = buttonName:match("^MultiBarBottomLeftButton(%d+)$")
    if n then return "MULTIACTIONBAR1BUTTON" .. n end
    n = buttonName:match("^MultiBarBottomRightButton(%d+)$")
    if n then return "MULTIACTIONBAR2BUTTON" .. n end
    n = buttonName:match("^MultiBarRightButton(%d+)$")
    if n then return "MULTIACTIONBAR3BUTTON" .. n end
    n = buttonName:match("^MultiBarLeftButton(%d+)$")
    if n then return "MULTIACTIONBAR4BUTTON" .. n end
    n = buttonName:match("^MultiBar5Button(%d+)$")
    if n then return "MULTIACTIONBAR5BUTTON" .. n end
    n = buttonName:match("^MultiBar6Button(%d+)$")
    if n then return "MULTIACTIONBAR6BUTTON" .. n end
    n = buttonName:match("^MultiBar7Button(%d+)$")
    if n then return "MULTIACTIONBAR7BUTTON" .. n end
    n = buttonName:match("^MultiBarRightActionButton(%d+)$")
    if n then return "MULTIACTIONBAR3BUTTON" .. n end
    n = buttonName:match("^MultiBarLeftActionButton(%d+)$")
    if n then return "MULTIACTIONBAR4BUTTON" .. n end
    n = buttonName:match("^MultiBarBottomRightActionButton(%d+)$")
    if n then return "MULTIACTIONBAR2BUTTON" .. n end
    n = buttonName:match("^MultiBarBottomLeftActionButton(%d+)$")
    if n then return "MULTIACTIONBAR1BUTTON" .. n end
    n = buttonName:match("^MultiBar5ActionButton(%d+)$")
    if n then return "MULTIACTIONBAR5BUTTON" .. n end
    n = buttonName:match("^MultiBar6ActionButton(%d+)$")
    if n then return "MULTIACTIONBAR6BUTTON" .. n end
    n = buttonName:match("^MultiBar7ActionButton(%d+)$")
    if n then return "MULTIACTIONBAR7BUTTON" .. n end
    -- Stance/Shapeshift & Pet & Possess bars
    n = buttonName:match("^StanceButton(%d+)$")
    if n then return "SHAPESHIFTBUTTON" .. n end
    n = buttonName:match("^PetActionButton(%d+)$")
    if n then return "PETACTIONBUTTON" .. n end
    n = buttonName:match("^PossessButton(%d+)$")
    if n then return "POSSESSBUTTON" .. n end
    -- Extra Action Button (Retail; harmless if absent)
    if buttonName == "ExtraActionButton1" then return "EXTRAACTIONBUTTON1" end
    -- AzeriteUI custom bars
    local azBar, azBtn = buttonName:match("^AzeriteActionBar(%d+)Button(%d+)$")
    if azBar and azBtn then
        azBar = tonumber(azBar); azBtn = tonumber(azBtn)
        if azBar == 1 then return "ACTIONBUTTON" .. azBtn
        elseif azBar == 2 then return "MULTIACTIONBAR1BUTTON" .. azBtn
        elseif azBar == 3 then return "MULTIACTIONBAR2BUTTON" .. azBtn
        elseif azBar == 4 then return "MULTIACTIONBAR3BUTTON" .. azBtn
        elseif azBar == 5 then return "MULTIACTIONBAR4BUTTON" .. azBtn
        elseif azBar == 6 then return "MULTIACTIONBAR5BUTTON" .. azBtn
        elseif azBar == 7 then return "MULTIACTIONBAR6BUTTON" .. azBtn
        elseif azBar == 8 then return "MULTIACTIONBAR7BUTTON" .. azBtn end
    end
    local stanceBtn = buttonName:match("^AzeriteStanceBarButton(%d+)$")
    if stanceBtn then return "SHAPESHIFTBUTTON" .. stanceBtn end
    local petBtn = buttonName:match("^AzeritePetBarButton(%d+)$")
    if petBtn then return "BONUSACTIONBUTTON" .. petBtn end
    return nil
end

-- Helper function to get the correct binding command string from a Blizzard action ID.
function Keybinds:GetBindingCommandFromAction(actionID)
    if not actionID or actionID < 1 then return nil end
    if isRetail then
        if actionID >= 1 and actionID <= 12 then
            return "ACTIONBUTTON" .. actionID
        elseif actionID >= 25 and actionID <= 36 then
            return "MULTIACTIONBAR3BUTTON" .. (actionID - 24)
        elseif actionID >= 37 and actionID <= 48 then
            return "MULTIACTIONBAR4BUTTON" .. (actionID - 36)
        elseif actionID >= 49 and actionID <= 60 then
            return "MULTIACTIONBAR2BUTTON" .. (actionID - 48)
        elseif actionID >= 61 and actionID <= 72 then
            return "MULTIACTIONBAR1BUTTON" .. (actionID - 60)
        elseif actionID >= 133 and actionID <= 144 then
            return "MULTIACTIONBAR5BUTTON" .. (actionID - 132)
        elseif actionID >= 145 and actionID <= 156 then
            return "MULTIACTIONBAR6BUTTON" .. (actionID - 144)
        elseif actionID >= 157 and actionID <= 168 then
            return "MULTIACTIONBAR7BUTTON" .. (actionID - 156)
        end
        return nil
    end
    if actionID >= 1 and actionID <= 12 then
        return "ACTIONBUTTON" .. actionID
    elseif actionID >= 13 and actionID <= 24 then
        return "MULTIACTIONBAR1BUTTON" .. (actionID - 12)
    elseif actionID >= 25 and actionID <= 36 then
        return "MULTIACTIONBAR2BUTTON" .. (actionID - 24)
    elseif actionID >= 37 and actionID <= 48 then
        return "MULTIACTIONBAR3BUTTON" .. (actionID - 36)
    elseif actionID >= 49 and actionID <= 60 then
        return "MULTIACTIONBAR4BUTTON" .. (actionID - 48)
    -- Other ranges like pet bar, stance bar etc. can be added here if needed
    end
    return nil
end

-- Abbreviation logic (ConsolePort-style). Definitions are also consumed by the
-- options UIs, while user overrides live in the current AceDB profile.
local abbreviationCategories = {
    { key = "modifiers", label = "Modifiers" },
    { key = "mouse", label = "Mouse" },
    { key = "numpad", label = "Numpad" },
    { key = "functionKeys", label = "Function Keys" },
    { key = "special", label = "Special Keys" },
    { key = "gamepad", label = "Gamepad" },
}

local abbreviationDefinitions = {
    { key = "ALT", label = "Alt", default = "A", category = "modifiers" },
    { key = "CTRL", label = "Ctrl", default = "C", category = "modifiers" },
    { key = "SHIFT", label = "Shift", default = "S", category = "modifiers" },

    { key = "MOUSEBUTTON1", label = "Mouse Button 1", default = "B1", category = "mouse" },
    { key = "MOUSEBUTTON2", label = "Mouse Button 2", default = "B2", category = "mouse" },
    { key = "MOUSEBUTTON3", label = "Mouse Button 3", default = "B3", category = "mouse" },
    { key = "MOUSEBUTTON4", label = "Mouse Button 4", default = "B4", category = "mouse" },
    { key = "MOUSEBUTTON5", label = "Mouse Button 5", default = "B5", category = "mouse" },
    { key = "BUTTON1", label = "Button 1 (alias)", default = "B1", category = "mouse" },
    { key = "BUTTON2", label = "Button 2 (alias)", default = "B2", category = "mouse" },
    { key = "BUTTON3", label = "Button 3 (alias)", default = "B3", category = "mouse" },
    { key = "BUTTON4", label = "Button 4 (alias)", default = "B4", category = "mouse" },
    { key = "BUTTON5", label = "Button 5 (alias)", default = "B5", category = "mouse" },
    { key = "MOUSEWHEELUP", label = "Mouse Wheel Up", default = "WU", category = "mouse" },
    { key = "MOUSEWHEELDOWN", label = "Mouse Wheel Down", default = "WD", category = "mouse" },

    { key = "NUMPAD0", label = "Numpad 0", default = "N0", category = "numpad" },
    { key = "NUMPAD1", label = "Numpad 1", default = "N1", category = "numpad" },
    { key = "NUMPAD2", label = "Numpad 2", default = "N2", category = "numpad" },
    { key = "NUMPAD3", label = "Numpad 3", default = "N3", category = "numpad" },
    { key = "NUMPAD4", label = "Numpad 4", default = "N4", category = "numpad" },
    { key = "NUMPAD5", label = "Numpad 5", default = "N5", category = "numpad" },
    { key = "NUMPAD6", label = "Numpad 6", default = "N6", category = "numpad" },
    { key = "NUMPAD7", label = "Numpad 7", default = "N7", category = "numpad" },
    { key = "NUMPAD8", label = "Numpad 8", default = "N8", category = "numpad" },
    { key = "NUMPAD9", label = "Numpad 9", default = "N9", category = "numpad" },
    { key = "NUMPADDECIMAL", label = "Numpad Decimal", default = "N.", category = "numpad" },
    { key = "NUMPADDIVIDE", label = "Numpad Divide", default = "N/", category = "numpad" },
    { key = "NUMPADMINUS", label = "Numpad Minus", default = "N-", category = "numpad" },
    { key = "NUMPADMULTIPLY", label = "Numpad Multiply", default = "N*", category = "numpad" },
    { key = "NUMPADPLUS", label = "Numpad Plus", default = "N+", category = "numpad" },

    { key = "F1", label = "F1", default = "F1", category = "functionKeys" },
    { key = "F2", label = "F2", default = "F2", category = "functionKeys" },
    { key = "F3", label = "F3", default = "F3", category = "functionKeys" },
    { key = "F4", label = "F4", default = "F4", category = "functionKeys" },
    { key = "F5", label = "F5", default = "F5", category = "functionKeys" },
    { key = "F6", label = "F6", default = "F6", category = "functionKeys" },
    { key = "F7", label = "F7", default = "F7", category = "functionKeys" },
    { key = "F8", label = "F8", default = "F8", category = "functionKeys" },
    { key = "F9", label = "F9", default = "F9", category = "functionKeys" },
    { key = "F10", label = "F10", default = "F10", category = "functionKeys" },
    { key = "F11", label = "F11", default = "F11", category = "functionKeys" },
    { key = "F12", label = "F12", default = "F12", category = "functionKeys" },

    { key = "ESCAPE", label = "Escape", default = "Esc", category = "special" },
    { key = "ENTER", label = "Enter", default = "Ent", category = "special" },
    { key = "BACKSPACE", label = "Backspace", default = "BS", category = "special" },
    { key = "TAB", label = "Tab", default = "Tab", category = "special" },
    { key = "CAPSLOCK", label = "Caps Lock", default = "CL", category = "special" },
    { key = "PRINTSCREEN", label = "Print Screen", default = "PrtSc", category = "special" },
    { key = "SCROLLLOCK", label = "Scroll Lock", default = "SL", category = "special" },
    { key = "PAUSE", label = "Pause", default = "Pau", category = "special" },
    { key = "NUMLOCK", label = "Num Lock", default = "NL", category = "special" },
    { key = "PAGEUP", label = "Page Up", default = "PU", category = "special" },
    { key = "PAGEDOWN", label = "Page Down", default = "PD", category = "special" },
    { key = "SPACE", label = "Space", default = "Spc", category = "special" },
    { key = "INSERT", label = "Insert", default = "Ins", category = "special" },
    { key = "DELETE", label = "Delete", default = "Del", category = "special" },
    { key = "HOME", label = "Home", default = "Hm", category = "special" },
    { key = "END", label = "End", default = "End", category = "special" },
    { key = "ARROWUP", label = "Arrow Up", default = "U", category = "special" },
    { key = "ARROWDOWN", label = "Arrow Down", default = "D", category = "special" },
    { key = "ARROWLEFT", label = "Arrow Left", default = "L", category = "special" },
    { key = "ARROWRIGHT", label = "Arrow Right", default = "R", category = "special" },
    { key = "LEFT", label = "Left", default = "L", category = "special" },
    { key = "RIGHT", label = "Right", default = "R", category = "special" },
    { key = "UP", label = "Up", default = "U", category = "special" },
    { key = "DOWN", label = "Down", default = "D", category = "special" },

    { key = "PAD1", label = "Gamepad 1", default = "A", category = "gamepad" },
    { key = "PAD2", label = "Gamepad 2", default = "B", category = "gamepad" },
    { key = "PAD3", label = "Gamepad 3", default = "X", category = "gamepad" },
    { key = "PAD4", label = "Gamepad 4", default = "Y", category = "gamepad" },
    { key = "PAD5", label = "Gamepad 5", default = "LB", category = "gamepad" },
    { key = "PAD6", label = "Gamepad 6", default = "RB", category = "gamepad" },
    { key = "PAD7", label = "Gamepad 7", default = "LT", category = "gamepad" },
    { key = "PAD8", label = "Gamepad 8", default = "RT", category = "gamepad" },
    { key = "PAD9", label = "Gamepad 9", default = "LS", category = "gamepad" },
    { key = "PAD10", label = "Gamepad 10", default = "RS", category = "gamepad" },
    { key = "PAD11", label = "Gamepad 11", default = "BACK", category = "gamepad" },
    { key = "PAD12", label = "Gamepad 12", default = "START", category = "gamepad" },
    { key = "PADDUP", label = "D-Pad Up", default = "DU", category = "gamepad" },
    { key = "PADDDOWN", label = "D-Pad Down", default = "DD", category = "gamepad" },
    { key = "PADDLEFT", label = "D-Pad Left", default = "DL", category = "gamepad" },
    { key = "PADDRIGHT", label = "D-Pad Right", default = "DR", category = "gamepad" },
    { key = "PADLSHOULDER", label = "Left Shoulder", default = "LB", category = "gamepad" },
    { key = "PADRSHOULDER", label = "Right Shoulder", default = "RB", category = "gamepad" },
    { key = "PADLTRIGGER", label = "Left Trigger", default = "LT", category = "gamepad" },
    { key = "PADRTRIGGER", label = "Right Trigger", default = "RT", category = "gamepad" },
    { key = "PADLSTICK", label = "Left Stick Click", default = "LS", category = "gamepad" },
    { key = "PADRSTICK", label = "Right Stick Click", default = "RS", category = "gamepad" },
    { key = "PADLSTICKUP", label = "Left Stick Up", default = "LSU", category = "gamepad" },
    { key = "PADLSTICKDOWN", label = "Left Stick Down", default = "LSD", category = "gamepad" },
    { key = "PADLSTICKLEFT", label = "Left Stick Left", default = "LSL", category = "gamepad" },
    { key = "PADLSTICKRIGHT", label = "Left Stick Right", default = "LSR", category = "gamepad" },
    { key = "PADRSTICKUP", label = "Right Stick Up", default = "RSU", category = "gamepad" },
    { key = "PADRSTICKDOWN", label = "Right Stick Down", default = "RSD", category = "gamepad" },
    { key = "PADRSTICKLEFT", label = "Right Stick Left", default = "RSL", category = "gamepad" },
    { key = "PADRSTICKRIGHT", label = "Right Stick Right", default = "RSR", category = "gamepad" },
    { key = "PADPADDLE1", label = "Paddle 1", default = "P1", category = "gamepad" },
    { key = "PADPADDLE2", label = "Paddle 2", default = "P2", category = "gamepad" },
    { key = "PADPADDLE3", label = "Paddle 3", default = "P3", category = "gamepad" },
    { key = "PADPADDLE4", label = "Paddle 4", default = "P4", category = "gamepad" },
    { key = "PADFORWARD", label = "Forward (Start)", default = "FWD", category = "gamepad" },
    { key = "PADBACK", label = "Back (Select)", default = "BCK", category = "gamepad" },
    { key = "PADSYSTEM", label = "System (Guide)", default = "SYS", category = "gamepad" },
    { key = "PADSOCIAL", label = "Social (Share)", default = "SOC", category = "gamepad" },
}

local abbreviationDefaults = {}
for _, definition in ipairs(abbreviationDefinitions) do
    abbreviationDefaults[definition.key] = definition.default
end

local function GetCustomAbbreviationTable(create)
    local text = addon.db and addon.db.profile and addon.db.profile.text
    if not text then return nil end
    if create and type(text.customAbbreviations) ~= "table" then
        text.customAbbreviations = {}
    end
    return type(text.customAbbreviations) == "table" and text.customAbbreviations or nil
end

local function GetConfiguredAbbreviation(key)
    local custom = GetCustomAbbreviationTable(false)
    local value = custom and custom[key]
    -- Accept the unused pre-2.5.22 modifier key shape if a profile already contains it.
    if value == nil and custom and (key == "ALT" or key == "CTRL" or key == "SHIFT") then
        value = custom[key .. "-"]
    end
    if type(value) == "string" and value ~= "" then return value end
    return abbreviationDefaults[key] or key
end

function Keybinds:GetAbbreviationCategories()
    return abbreviationCategories
end

function Keybinds:GetAbbreviationDefinitions()
    return abbreviationDefinitions
end

function Keybinds:GetDefaultAbbreviation(key)
    return abbreviationDefaults[key]
end

function Keybinds:GetConfiguredAbbreviation(key)
    return GetConfiguredAbbreviation(key)
end

function Keybinds:SetCustomAbbreviation(key, value)
    if type(key) ~= "string" or not abbreviationDefaults[key] then return false end
    local custom = GetCustomAbbreviationTable(true)
    if not custom then return false end
    value = type(value) == "string" and value or ""
    value = value:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or value == abbreviationDefaults[key] then
        custom[key] = nil
    else
        custom[key] = value
    end
    if key == "ALT" or key == "CTRL" or key == "SHIFT" then
        custom[key .. "-"] = nil
    end
    self:ClearCache()
    return true
end

function Keybinds:ResetCustomAbbreviations()
    local custom = GetCustomAbbreviationTable(true)
    if custom then wipe(custom) end
    self:ClearCache()
end

-- Modifier normalization: always A, C, S, in that order, no separators.
-- Modifiers are peeled off the front of the binding instead of splitting on every
-- hyphen, so a base key that is itself a hyphen survives (e.g. "CTRL--" => "C-").
local function normalizeModifiers(key)
    if not key or key == "" then return "", "" end

    local sortOrder = { ALT = 1, CTRL = 2, SHIFT = 3 }
    local modifierKeys = {}
    local baseKey = key

    while true do
        local modifier, remainder = baseKey:match("^(%u+)%-(.+)$")
        if not modifier or not sortOrder[modifier] then break end
        table.insert(modifierKeys, modifier)
        baseKey = remainder
    end

    -- The canonical order is Alt, Ctrl, Shift.
    table.sort(modifierKeys, function(a, b)
        return sortOrder[a] < sortOrder[b]
    end)

    -- Use the configured separator from options, default to none
    local sep = addon.db and addon.db.profile and addon.db.profile.text and addon.db.profile.text.modSeparator or ""
    local modifierText = {}
    for _, modifierKey in ipairs(modifierKeys) do
        modifierText[#modifierText + 1] = GetConfiguredAbbreviation(modifierKey)
    end
    return table.concat(modifierText, sep), baseKey
end

function Keybinds:ClearCache()
    wipe(keybindCache)
end

function Keybinds:ClearButtonCache(buttonOrName)
    local buttonName = buttonOrName
    if buttonOrName and type(buttonOrName) ~= "string" then
        buttonName = GetSafeButtonName(buttonOrName)
    end
    if not addon:IsValueAccessible(buttonName) or type(buttonName) ~= "string" or buttonName == "" then return end

    local prefix = buttonName .. "|"
    for cacheKey in pairs(keybindCache) do
        if cacheKey == buttonName or cacheKey:sub(1, #prefix) == prefix then
            keybindCache[cacheKey] = nil
        end
    end
end

function Keybinds:GetBinding(button)
    if not button then return nil end
    local buttonName = GetSafeButtonName(button)
    if not buttonName then return nil end
    local provider = GetButtonProvider(buttonName)
    local cacheKey = GetBindingCacheKey(button, provider)
    if keybindCache[cacheKey] ~= nil then
        return keybindCache[cacheKey]
    end

    local fullKey = self:GetFullBindingText(button)

    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Keybinds:GetBinding for button " .. buttonName .. " found full key: " .. addon:SafeToString(fullKey))
    end

    if not fullKey or fullKey == "" then
        keybindCache[cacheKey] = ""
        return ""
    end
    -- Always abbreviate (yields Dominos-like labels such as ACS1, B4)
    local abbreviatedKey = self:Abbreviate(fullKey)
    keybindCache[cacheKey] = abbreviatedKey
    return abbreviatedKey
end

function Keybinds:Abbreviate(key)
    if not addon:IsValueAccessible(key) or not key or key == "" then return "" end
    if not addon.db.profile.text.abbreviations then return key end

    local mods, base = normalizeModifiers(key)

    -- Abbreviate the base key if a mapping exists.
    base = GetConfiguredAbbreviation(base)

    -- Combine modifiers and the base key without a separator.
    local result = mods .. base

    -- Truncate to max length if needed.
    if addon.db.profile.text.maxLength and #result > addon.db.profile.text.maxLength then
        return result:sub(1, addon.db.profile.text.maxLength)
    end

    return result
end

function Keybinds:GetFullBindingText(button)
    if not button then return "" end
    local buttonName = GetSafeButtonName(button)
    if not buttonName then return "" end
    local provider = GetButtonProvider(buttonName)
    local key

    -- Prefer mapping by button name to avoid bar paging mismatches (Classic only)
    if not isRetail then
        local nameCommand = GetBindingCommandFromButtonName(buttonName)
        if nameCommand then
            key = FirstBindingKey(nameCommand)
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] Name-based binding for %s => %s (%s)", tostring(buttonName), tostring(key), nameCommand))
            end
        end
    end

    if (not key or key == "") and provider then
        key = ResolveProviderExplicitBinding(buttonName, provider)
        if addon.db and addon.db.profile and addon.db.profile.debug and key and key ~= "" then
            addon:Print(string.format("[AHOS DEBUG] Provider binding for %s => %s (%s)", tostring(buttonName), tostring(key), tostring(provider.label or provider.key)))
        end
    end

    -- Then try to get the binding via the button's action ID (reliable for Blizzard bars)
    -- For custom bars, allow this as a fallback only if addon-native bindings did not resolve.
    if (not key or key == "") then
        local commandName = GetButtonCommandName(button, provider)
        if commandName then
            key = FirstBindingKey(commandName)
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] Command binding fallback for %s => %s (%s)", tostring(buttonName), tostring(key), tostring(commandName)))
            end
        end
        local actionId = addon:GetButtonActionSlot(button)
        if (not key or key == "") and actionId and actionId > 0 then
            local command = self:GetBindingCommandFromAction(actionId)
            if command then
                key = FirstBindingKey(command)
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print(string.format("[AHOS DEBUG] ActionID-based binding for %s => %s via actionId %d (command: %s)", tostring(buttonName), tostring(key), actionId, command))
                end
            end
        end
    end

    -- If that failed, fall back to stable button-name mappings.
    if not key or key == "" then
        local nameCommand = GetBindingCommandFromButtonName(buttonName)
        if nameCommand then
            key = FirstBindingKey(nameCommand)
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] Name-based binding fallback for %s => %s (%s)", tostring(buttonName), tostring(key), nameCommand))
            end
        end
    end

    -- If that failed (e.g., no .action property), fall back to legacy UI-specific matching.
    if not key or key == "" then
        -- AzeriteUI main bar mapping
        local azBar, azBtn = buttonName:match("^AzeriteActionBar(%d+)Button(%d+)$")
        if azBar and azBtn then
            azBar = tonumber(azBar)
            azBtn = tonumber(azBtn)
            local command
            if azBar == 1 then command = "ACTIONBUTTON" .. azBtn
            elseif azBar == 2 then command = "MULTIACTIONBAR1BUTTON" .. azBtn
            elseif azBar == 3 then command = "MULTIACTIONBAR2BUTTON" .. azBtn
            elseif azBar == 4 then command = "MULTIACTIONBAR3BUTTON" .. azBtn
            elseif azBar == 5 then command = "MULTIACTIONBAR4BUTTON" .. azBtn
            elseif azBar == 6 then command = "MULTIACTIONBAR5BUTTON" .. azBtn
            elseif azBar == 7 then command = "MULTIACTIONBAR6BUTTON" .. azBtn
            elseif azBar == 8 then command = "MULTIACTIONBAR7BUTTON" .. azBtn
            end
            if command then key = FirstBindingKey(command) end
        end

        -- AzeriteUI stance bar mapping
        local stanceBtn = buttonName:match("^AzeriteStanceBarButton(%d+)$")
        if stanceBtn then
            key = FirstBindingKey("SHAPESHIFTBUTTON" .. stanceBtn)
        end

        local petBtn = buttonName:match("^AzeritePetBarButton(%d+)$")
        if petBtn then
            key = FirstBindingKey("BONUSACTIONBUTTON" .. petBtn)
        end
    end

    -- Final fallback: try the button's global name. This works for some buttons like StanceButton1.
    if not key or key == "" then
        key = FirstBindingKey(buttonName)
    end

    -- Removed actionId modulo fallback to avoid misleading labels (e.g., showing '1' when not bound).

    -- Generic CLICK fallback (Bartender/Dominos/others) when name/action mapping didn't resolve
    if (not key or key == "") and buttonName then
        local suffixes = {
            ":LeftButton", ":Button1", ":AnyUp", ":AnyDown",
            ":RightButton", ":Button2", ":MiddleButton", ":Button3",
        }
        for _, sfx in ipairs(suffixes) do
            key = FirstBindingKey("CLICK " .. buttonName .. sfx)
            if key and key ~= "" then break end
        end
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print(string.format("[AHOS DEBUG] CLICK binding fallback for %s => %s", tostring(buttonName), tostring(key)))
        end
    end

    -- As a last resort for other addons, use the current on-screen hotkey label.
    if (not key or key == "") and (not provider or provider.key ~= "Dominos") then
        -- On Retail, avoid using visual fallback entirely (skins may show placeholder glyphs)
        local allowVisual = not isRetail
        local visual = allowVisual and GetVisualHotkeyText(button) or nil
        if visual and visual ~= "" then
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] Visual label fallback for %s => %s", tostring(buttonName), tostring(visual)))
            end
            key = visual
        end
    end

    -- WoW's GetBindingKey can return nil, an empty string, or even a null character for unbound keys.
    -- We normalize all of these to a simple empty string to prevent issues downstream.
    if not key or key == "" or key == "\0" then
        return ""
    end

    return key
end

function Keybinds:GetButtonDebugInfo(button)
    local buttonName = GetSafeButtonName(button)
    if not buttonName then return "Invalid or inaccessible button provided." end
    local provider = GetButtonProvider(buttonName)
    local hotkeyRegion = _G[buttonName .. "HotKey"]
    local currentHotkeyText = hotkeyRegion and SafeFrameValue(hotkeyRegion, "GetText") or "N/A"
    local storedOriginalText = (addon.db.profile.originalHotkeys and addon.db.profile.originalHotkeys[buttonName]) or "Not stored"
    local commandName = GetButtonCommandName(button, provider) or "N/A"

    local info = {
        string.format("|cFF00FF00[AHOS Inspect: %s]|r", buttonName),
        "--------------------------------------------------",
        string.format("  - Button Name: |cFFFFFF00%s|r", buttonName),
        string.format("  - Provider: |cFFFFFF00%s|r", tostring(provider and provider.label or "Blizzard")),
        string.format("  - Command Field: |cFFFFFF00%s|r", tostring(commandName)),
        string.format("  - Button Action: |cFFFFFF00%s|r", addon:SafeToString(addon:GetButtonActionSlot(button), "N/A")),
        string.format("  - Current Hotkey Text: |cFFFFFF00%s|r", addon:SafeToString(currentHotkeyText, "<secret>")),
        string.format("  - IsAbbreviation(current): |cFFFFFF00%s|r", tostring(self:IsAbbreviation(currentHotkeyText))),
        "--------------------------------------------------",
        string.format("  - Stored Original Text: |cFFFFFF00%s|r", tostring(storedOriginalText)),
        string.format("  - IsAbbreviation(stored): |cFFFFFF00%s|r", tostring(self:IsAbbreviation(storedOriginalText))),
        "--------------------------------------------------",
        string.format("  - GetFullBindingText(): |cFFFFFF00%s|r", tostring(self:GetFullBindingText(button))),
        string.format("  - GetBinding() (abbrev): |cFFFFFF00%s|r", tostring(self:GetBinding(button))),
        "--------------------------------------------------",
    }

    -- Also try to get bindings directly
    local directBinding = FirstBindingKey(buttonName)
    info[#info + 1] = string.format("  - GetBindingKey('%s'): |cFFFFFF00%s|r", buttonName, addon:SafeToString(directBinding))

    local actionSlot = addon:GetButtonActionSlot(button)
    if actionSlot then
        local actionBinding = FirstBindingKey("ACTIONBUTTON" .. actionSlot)
        info[#info + 1] = string.format("  - GetBindingKey('ACTIONBUTTON%s'): |cFFFFFF00%s|r", actionSlot, addon:SafeToString(actionBinding))
    end

    return table.concat(info, "\n")
end

-- Checks if a given text is likely an abbreviation created by this addon.
-- This is a heuristic used to avoid saving our own abbreviated text as the
-- original Blizzard hotkey text when the addon reloads or updates.
function Keybinds:IsAbbreviation(text)
    if not text or text == "" then return false end

    -- If it contains a hyphen, it's very likely a standard Blizzard keybind (e.g., "SHIFT-1").
    -- Our default abbreviations do not contain hyphens unless the user configures it.
    if text:find("-") then
        return false
    end

    -- If it's purely a number, it's the original hotkey text.
    if tonumber(text) then
        return false
    end

    -- Our abbreviations must contain at least one uppercase letter (from a modifier or key).
    if not text:match("[A-Z]") then
        return false
    end

    -- If the text is longer than the configured max length, it's unlikely to be our abbreviation.
    -- Add a small buffer to be safe.
    local maxLength = (addon.db and addon.db.profile and addon.db.profile.text and addon.db.profile.text.maxLength) or 4
    if #text > (maxLength + 1) then
        return false
    end

    -- If it has a mix of numbers and letters and is short, it's very likely one of our abbreviations (e.g., "S1", "M4").
    -- This is still a guess, but it's much safer than the previous implementation.
    return true
end

-- Called when the addon profile changes.
function Keybinds:OnProfileChanged()
    self:ClearCache()
    -- Queue a full update to reflect any changes in abbreviation settings from the new profile.
    addon:SafeCall("Core", "FullUpdate")
end
