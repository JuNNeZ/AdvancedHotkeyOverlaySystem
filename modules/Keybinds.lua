---@diagnostic disable: undefined-global
--[[
Keybinds.lua - Advanced Hotkey Overlay System
---------------------------------------------------------
Manages keybinding detection, mapping, and abbreviation for overlays.
--]]

local addonName, privateScope = ...
local addon = privateScope.addon
local Keybinds = addon.Keybinds

function Keybinds:OnInitialize()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Keybinds module initialized.")
    end
end

local keybindCache = {}

-- Abbreviation logic (ConsolePort-style)
local abbreviations = {
    -- Modifiers (strict order: C, S, A)
    ["CTRL-"] = "C-",
    ["SHIFT-"] = "S-",
    ["ALT-"] = "A-",
    -- Mouse buttons
    ["MOUSEBUTTON1"] = "M1",
    ["MOUSEBUTTON2"] = "M2",
    ["MOUSEBUTTON3"] = "M3",
    ["MOUSEBUTTON4"] = "M4",
    ["MOUSEBUTTON5"] = "M5",
    ["BUTTON1"] = "M1",
    ["BUTTON2"] = "M2",
    ["BUTTON3"] = "M3",
    ["BUTTON4"] = "M4",
    ["BUTTON5"] = "M5",
    ["MOUSEWHEELUP"] = "WU",
    ["MOUSEWHEELDOWN"] = "WD",
    -- Numpad
    ["NUMPAD0"] = "N0",
    ["NUMPAD1"] = "N1",
    ["NUMPAD2"] = "N2",
    ["NUMPAD3"] = "N3",
    ["NUMPAD4"] = "N4",
    ["NUMPAD5"] = "N5",
    ["NUMPAD6"] = "N6",
    ["NUMPAD7"] = "N7",
    ["NUMPAD8"] = "N8",
    ["NUMPAD9"] = "N9",
    ["NUMPADDECIMAL"] = "N.",
    ["NUMPADDIVIDE"] = "N/",
    ["NUMPADMINUS"] = "N-",
    ["NUMPADMULTIPLY"] = "N*",
    ["NUMPADPLUS"] = "N+",
    -- Function keys
    ["F1"] = "F1",
    ["F2"] = "F2",
    ["F3"] = "F3",
    ["F4"] = "F4",
    ["F5"] = "F5",
    ["F6"] = "F6",
    ["F7"] = "F7",
    ["F8"] = "F8",
    ["F9"] = "F9",
    ["F10"] = "F10",
    ["F11"] = "F11",
    ["F12"] = "F12",
    -- Special keys
    ["ESCAPE"] = "Esc",
    ["ENTER"] = "Ent",
    ["BACKSPACE"] = "BS",
    ["TAB"] = "Tab",
    ["CAPSLOCK"] = "CL",
    ["PRINTSCREEN"] = "PrtSc",
    ["SCROLLLOCK"] = "SL",
    ["PAUSE"] = "Pau",
    ["NUMLOCK"] = "NL",
    ["PAGEUP"] = "PU",
    ["PAGEDOWN"] = "PD",
    ["SPACE"] = "Spc",
    ["INSERT"] = "Ins",
    ["DELETE"] = "Del",
    ["HOME"] = "Hm",
    ["END"] = "End",
    ["ARROWUP"] = "U",
    ["ARROWDOWN"] = "D",
    ["ARROWLEFT"] = "L",
    ["ARROWRIGHT"] = "R",
    ["LEFT"] = "L",
    ["RIGHT"] = "R",
    ["UP"] = "U",
    ["DOWN"] = "D",
    -- Gamepad (ConsolePort-style, if detected)
    ["PAD1"] = "A",
    ["PAD2"] = "B",
    ["PAD3"] = "X",
    ["PAD4"] = "Y",
    ["PAD5"] = "LB",
    ["PAD6"] = "RB",
    ["PAD7"] = "LT",
    ["PAD8"] = "RT",
    ["PAD9"] = "LS",
    ["PAD10"] = "RS",
    ["PAD11"] = "BACK",
    ["PAD12"] = "START",
}

-- Modifier normalization (ConsolePort-style: always C, S, A, in that order)
local function normalizeModifiers(key)
    local mods = {}
    -- Only match and remove full modifier prefixes
    if key:find("^CTRL%-") then table.insert(mods, "C") end
    if key:find("^SHIFT%-") then table.insert(mods, "S") end
    if key:find("^ALT%-") then table.insert(mods, "A") end
    -- Remove all leading modifiers (in any order)
    local base = key
    base = base:gsub("^CTRL%-", "")
    base = base:gsub("^SHIFT%-", "")
    base = base:gsub("^ALT%-", "")
    -- If multiple modifiers, repeat until all are gone
    while base:find("^CTRL%-") or base:find("^SHIFT%-") or base:find("^ALT%-") do
        base = base:gsub("^CTRL%-", "")
        base = base:gsub("^SHIFT%-", "")
        base = base:gsub("^ALT%-", "")
    end
    return table.concat(mods), base
end

function Keybinds:ClearCache()
    wipe(keybindCache)
end

function Keybinds:GetBinding(button)
    if not button or not button.GetName then return nil end
    local buttonName = button:GetName()
    if keybindCache[buttonName] then
        return keybindCache[buttonName]
    end

    local key
    -- AzeriteUI main bar mapping
    local azBar, azBtn = buttonName:match("^AzeriteActionBar(%d+)Button(%d+)$")
    if azBar and azBtn then
        azBar = tonumber(azBar)
        azBtn = tonumber(azBtn)
        if azBar == 1 then
            key = GetBindingKey("ACTIONBUTTON" .. azBtn)
        elseif azBar == 2 then
            key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. azBtn)
        elseif azBar == 3 then
            key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. azBtn)
        end
    end
    -- AzeriteUI stance bar mapping
    local stanceBtn = buttonName:match("^AzeriteStanceBarButton(%d+)$")
    if stanceBtn then
        key = GetBindingKey("SHAPESHIFTBUTTON" .. stanceBtn)
    end
    -- Try to resolve Blizzard action button bindings
    if not key then
        if button.action then
            -- For standard action buttons, use ACTIONBUTTON#
            if buttonName:find("ActionButton") then
                local slot = button.action
                key = GetBindingKey("ACTIONBUTTON" .. tostring(slot))
            -- For MultiBar buttons
            elseif buttonName:find("MultiBarBottomLeftButton") then
                local slot = button.action - 12
                key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. tostring(slot))
            elseif buttonName:find("MultiBarBottomRightButton") then
                local slot = button.action - 24
                key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. tostring(slot))
            elseif buttonName:find("MultiBarRightButton") then
                local slot = button.action - 36
                key = GetBindingKey("MULTIACTIONBAR3BUTTON" .. tostring(slot))
            elseif buttonName:find("MultiBarLeftButton") then
                local slot = button.action - 48
                key = GetBindingKey("MULTIACTIONBAR4BUTTON" .. tostring(slot))
            -- AzeriteUI and other custom bars: fallback to action slot if available
            elseif button.action then
                key = GetBindingKey("ACTIONBUTTON" .. tostring(button.action))
            end
        end
    end
    -- Fallback: try the button's global name
    if not key or key == "" then
        key = GetBindingKey(buttonName)
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Keybinds:GetBinding for button " .. buttonName .. " (action=" .. tostring(button.action) .. ") = " .. tostring(key))
    end
    if not key then
        keybindCache[buttonName] = ""
        return ""
    end
    local abbreviatedKey = self:Abbreviate(key)
    keybindCache[buttonName] = abbreviatedKey
    return abbreviatedKey
end

function Keybinds:Abbreviate(key)
    if not (addon.db and addon.db.profile and addon.db.profile.text and addon.db.profile.text.abbreviations) then
        return key
    end
    local newKey = string.upper(key)
    -- Custom user abbreviations first
    if addon.db.profile.text.customAbbreviations then
        for k, v in pairs(addon.db.profile.text.customAbbreviations) do
            newKey = newKey:gsub(string.upper(k), v)
        end
    end
    -- Normalize modifier order and split
    local mods, base = normalizeModifiers(newKey)
    -- Standard abbreviations
    for k, v in pairs(abbreviations) do
        base = base:gsub(k, v)
    end
    -- Option: separator between mods and key
    local sep = ""
    if addon.db.profile.text.modSeparator then
        sep = addon.db.profile.text.modSeparator
    end
    newKey = mods ~= "" and (mods .. sep .. base) or base
    -- Remove trailing separator if present
    newKey = newKey:gsub(sep .. "$", "")
    -- Limit length
    local maxLength = addon.db.profile.text.maxLength or 6
    if string.len(newKey) > maxLength then
        newKey = string.sub(newKey, 1, maxLength)
    end
    return newKey
end

-- Called when the addon profile changes.
function Keybinds:OnProfileChanged()
    self:ClearCache()
    -- Queue a full update to reflect any changes in abbreviation settings from the new profile.
    addon:SafeCall("Core", "FullUpdate")
end
