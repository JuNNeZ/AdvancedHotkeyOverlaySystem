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

-- Helper function to get the correct binding command string from a Blizzard action ID.
function Keybinds:GetBindingCommandFromAction(actionID)
    if not actionID or actionID < 1 then return nil end
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

-- Abbreviation logic (ConsolePort-style)
local abbreviations = {
    -- Modifiers (no separator)
    ["CTRL-"] = "C",
    ["SHIFT-"] = "S",
    ["ALT-"] = "A",
    -- Mouse buttons
    ["MOUSEBUTTON1"] = "B1",
    ["MOUSEBUTTON2"] = "B2",
    ["MOUSEBUTTON3"] = "B3",
    ["MOUSEBUTTON4"] = "B4",
    ["MOUSEBUTTON5"] = "B5",
    ["BUTTON1"] = "B1",
    ["BUTTON2"] = "B2",
    ["BUTTON3"] = "B3",
    ["BUTTON4"] = "B4",
    ["BUTTON5"] = "B5",
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

-- Modifier normalization: always A, C, S, in that order, no separators.
local function normalizeModifiers(key)
    if not key or key == "" then return "", "" end

    local parts = {}
    for part in key:gmatch("([^-]+)") do
        table.insert(parts, part)
    end

    local modsAbbr = {}
    local baseKey = ""

    local modMap = {
        ALT = "A",
        CTRL = "C",
        SHIFT = "S",
    }

    -- Find the base key (the first part that isn't a modifier)
    for i, part in ipairs(parts) do
        if modMap[part] then
            table.insert(modsAbbr, modMap[part])
        else
            baseKey = part
        end
    end

    -- The canonical order is Alt, Ctrl, Shift.
    local sortOrder = { A = 1, C = 2, S = 3 }
    table.sort(modsAbbr, function(a, b)
        return sortOrder[a] < sortOrder[b]
    end)

    -- Use the configured separator from options, default to none
    local sep = addon.db and addon.db.profile and addon.db.profile.text and addon.db.profile.text.modSeparator or ""
    return table.concat(modsAbbr, sep), baseKey
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

    local fullKey = self:GetFullBindingText(button)

    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Keybinds:GetBinding for button " .. buttonName .. " found full key: " .. tostring(fullKey))
    end

    if not fullKey or fullKey == "" then
        keybindCache[buttonName] = ""
        return ""
    end

    local abbreviatedKey = self:Abbreviate(fullKey)
    keybindCache[buttonName] = abbreviatedKey
    return abbreviatedKey
end

function Keybinds:Abbreviate(key)
    if not key or key == "" then return "" end
    if not addon.db.profile.text.abbreviations then return key end

    local mods, base = normalizeModifiers(key)

    -- Abbreviate the base key if a mapping exists.
    if abbreviations[base] then
        base = abbreviations[base]
    end

    -- Combine modifiers and the base key without a separator.
    local result = mods .. base

    -- Truncate to max length if needed.
    if addon.db.profile.text.maxLength and #result > addon.db.profile.text.maxLength then
        return result:sub(1, addon.db.profile.text.maxLength)
    end

    return result
end

function Keybinds:GetFullBindingText(button)
    if not button or not button.GetName then return "" end
    local buttonName = button:GetName()
    local key

    -- First, try to get the binding via the button's action ID, as this is the most reliable method.
    if button.action and tonumber(button.action) and button.action > 0 then
        local command = self:GetBindingCommandFromAction(button.action)
        if command then
            key = GetBindingKey(command)
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] Keybinds:GetFullBindingText found key '%s' for %s via button.action %d (command: %s)", tostring(key), buttonName, button.action, command))
            end
        end
    end

    -- If that failed (e.g., no .action property), fall back to name matching for specific UIs.
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
            end
            if command then key = GetBindingKey(command) end
        end

        -- AzeriteUI stance bar mapping
        local stanceBtn = buttonName:match("^AzeriteStanceBarButton(%d+)$")
        if stanceBtn then
            key = GetBindingKey("SHAPESHIFTBUTTON" .. stanceBtn)
        end
    end

    -- Final fallback: try the button's global name. This works for some buttons like StanceButton1.
    if not key or key == "" then
        key = GetBindingKey(buttonName)
    end

    -- WoW's GetBindingKey can return nil, an empty string, or even a null character for unbound keys.
    -- We normalize all of these to a simple empty string to prevent issues downstream.
    if not key or key == "" or key == "\0" then
        return ""
    end

    return key
end

function Keybinds:GetButtonDebugInfo(button)
    if not button or not button:GetName() then return "Invalid button provided." end
    local buttonName = button:GetName()
    local hotkeyRegion = _G[buttonName .. "HotKey"]
    local currentHotkeyText = hotkeyRegion and hotkeyRegion:GetText() or "N/A"
    local storedOriginalText = (addon.db.profile.originalHotkeys and addon.db.profile.originalHotkeys[buttonName]) or "Not stored"

    local info = {
        string.format("|cFF00FF00[AHOS Inspect: %s]|r", buttonName),
        "--------------------------------------------------",
        string.format("  - Button Name: |cFFFFFF00%s|r", buttonName),
        string.format("  - Button Action: |cFFFFFF00%s|r", tostring(button.action)),
        string.format("  - Current Hotkey Text: |cFFFFFF00%s|r", tostring(currentHotkeyText)),
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
    local directBinding = GetBindingKey(buttonName)
    info[#info + 1] = string.format("  - GetBindingKey('%s'): |cFFFFFF00%s|r", buttonName, tostring(directBinding))

    if button.action then
        local actionBinding = GetBindingKey("ACTIONBUTTON" .. button.action)
        info[#info + 1] = string.format("  - GetBindingKey('ACTIONBUTTON%s'): |cFFFFFF00%s|r", button.action, tostring(actionBinding))
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
