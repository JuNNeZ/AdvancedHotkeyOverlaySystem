---@diagnostic disable: undefined-global
-- modules/Bars.lua
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSBars
local Bars = addon.Bars

function Bars:OnInitialize()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Bars module initialized.")
    end
end

local trackedButtons = {}
local buttonToAction = {}
local addedNames = {}

local function GetSafeButtonName(button)
    if not button then return nil end
    local methodOk, getName = pcall(function() return button.GetName end)
    if not methodOk or type(getName) ~= "function" then return nil end
    local ok, name = pcall(getName, button)
    if not ok or not addon:IsValueAccessible(name) or type(name) ~= "string" or name == "" then
        return nil
    end
    return name
end

-- List of all possible action bars and their button names
local barDefinitions = {
    -- Blizzard bars
    { "ActionButton%d", 1, 12 },
    { "BonusActionButton%d", 1, 12 },
    { "MultiBarBottomLeftButton%d", 1, 12 },
    { "MultiBarBottomRightButton%d", 1, 12 },
    { "MultiBarRightButton%d", 1, 12 },
    { "MultiBarLeftButton%d", 1, 12 },
    { "MultiBar5Button%d", 1, 12 },
    { "MultiBar6Button%d", 1, 12 },
    { "MultiBar7Button%d", 1, 12 },
    { "StanceButton%d", 1, 10 },
    { "PetActionButton%d", 1, 10 },
    { "PossessButton%d", 1, 12 },
    { "ExtraActionButton1", 0, 0 },
    { "OverrideActionBarButton%d", 1, 12 },
    -- AzeriteUI Retail supports up to 8 bars, 12 buttons each.
    { "AzeriteActionBar%dButton%d", 1, 8, 1, 12 },
    { "AzeritePetBarButton%d", 1, 10 },
    { "AzeriteStanceBarButton%d", 1, 10 },
    -- Dominos (Retail/Classic): buttons are often named DominosActionButton<globalIndex>
    -- We'll also dynamically discover Dominos frames if loaded.
}

function Bars:OnEnable()
    addon:SafeCall("Bars", "UpdateTrackedButtons")
end

function Bars:UpdateTrackedButtons()
    wipe(trackedButtons)
    wipe(buttonToAction)
    wipe(addedNames)
    local function add(btn)
        local name = GetSafeButtonName(btn)
        if not name or addedNames[name] then return end
        -- Add regardless of current visibility; Display filters on visibility per-frame.
        table.insert(trackedButtons, btn)
        addedNames[name] = true
        local slot = addon:GetButtonActionSlot(btn)
        if slot then buttonToAction[name] = slot end
    end
    for _, def in ipairs(barDefinitions) do
        if #def == 3 then
            local nameFormat, startIdx, endIdx = unpack(def)
            if startIdx == 0 then -- Single button case
                local btn = _G[nameFormat]
                add(btn)
            else
                for i = startIdx, endIdx do
                    local btnName = nameFormat:format(i)
                    local btn = _G[btnName]
                    add(btn)
                end
            end
        elseif #def == 5 then
            -- AzeriteUI: { "AzeriteActionBar%dButton%d", barStart, barEnd, btnStart, btnEnd }
            local nameFormat, barStart, barEnd, btnStart, btnEnd = unpack(def)
            for bar = barStart, barEnd do
                for btn = btnStart, btnEnd do
                    local btnName = nameFormat:format(bar, btn)
                    local btnObj = _G[btnName]
                    add(btnObj)
                end
            end
        end
    end

    -- Dominos support: detect and include Dominos action buttons across all bars
    local function addButton(btn)
        add(btn)
    end
    local function scanContainer(prefix, count, matcher)
        for i = 1, count do
            local bar = _G[prefix .. i]
            if bar and bar.GetChildren then
                local kids = { pcall(bar.GetChildren, bar) }
                local ok = table.remove(kids, 1)
                if ok then
                    for _, child in ipairs(kids) do
                        if child and addon:IsValueAccessible(child) then
                            local cname = GetSafeButtonName(child)
                            if cname and cname:match(matcher) then
                                addButton(child)
                            end
                        end
                    end
                end
            end
        end
    end

    for _, provider in ipairs(addon:IterateScannableProviders()) do
        if addon:IsProviderLoaded(provider.key) then
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print(string.format("[AHOS DEBUG] %s detected - scanning custom buttons", provider.label))
            end
            for _, scanner in ipairs((provider.button_scanners and provider.button_scanners.globals) or {}) do
                for i = 1, scanner.max do
                    addButton(_G[scanner.prefix .. i])
                end
                -- `max` is what the addon makes by default; a bar addon set up with
                -- more bars (Dominos past 200 buttons) keeps numbering on.
                local i = scanner.max + 1
                while _G[scanner.prefix .. i] do
                    addButton(_G[scanner.prefix .. i])
                    i = i + 1
                end
            end
            for _, scanner in ipairs((provider.button_scanners and provider.button_scanners.containers) or {}) do
                scanContainer(scanner.prefix, scanner.count, scanner.matcher)
            end
        end
    end
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Tracked " .. #trackedButtons .. " visible action buttons.")
    end
end

-- A scan walks a few hundred globals and every bar addon's containers. A full update
-- always scans afresh (bar addons create buttons late); everything else (a single
-- slot changing, the options window) may reuse a scan made in the last half second.
local SCAN_TTL = 0.5
local lastScan

---@param fresh? boolean scan again even if a scan is under half a second old
---@return Button[]
function Bars:GetAllButtons(fresh)
    local now = GetTime and GetTime() or 0
    if fresh or not lastScan or now - lastScan >= SCAN_TTL or now < lastScan then
        self:UpdateTrackedButtons()
        lastScan = now
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Bars:GetAllButtons found " .. tostring(#trackedButtons) .. " buttons.")
        end
    end
    return trackedButtons
end

-- Every tracked button showing action `slot` (a Blizzard bar and a bar addon can
-- both show one).
---@param slot number
---@return Button[]
function Bars:GetButtonsBySlot(slot)
    local found = {}
    if not slot then return found end
    for _, btn in ipairs(self:GetAllButtons()) do
        if addon:GetButtonActionSlot(btn) == slot then
            found[#found + 1] = btn
        end
    end
    return found
end

function Bars:GetButtonBySlot(slot)
    return self:GetButtonsBySlot(slot)[1]
end

function Bars:GetDiagnostics()
    local providerCounts = {}
    local buttons = self:GetAllButtons()
    for _, btn in ipairs(buttons) do
        local name = GetSafeButtonName(btn)
        local provider = addon:GetProviderForButtonName(name)
        local key = provider and provider.key or "Blizzard"
        providerCounts[key] = (providerCounts[key] or 0) + 1
    end
    return {
        total = #buttons,
        providers = providerCounts,
    }
end

---------------------------------------------------------------------------
-- Bars, for settings per bar
---------------------------------------------------------------------------
-- Which bar a button belongs to, from its name: a stable key for the profile and a
-- name to show. Keys carry the provider, because Dominos reuses Blizzard's
-- MultiBar names for its own buttons.
local L = addon.L or {}
local BAR_PATTERNS = {
    { "^ActionButton%d+$", "1" }, { "^BonusActionButton%d+$", "1" },
    { "^MultiBarBottomLeft", "2" }, { "^MultiBarBottomRight", "3" },
    { "^MultiBarRight", "4" }, { "^MultiBarLeft", "5" },
    { "^MultiBar5", "6" }, { "^MultiBar6", "7" }, { "^MultiBar7", "8" },
    { "^StanceButton", "stance" }, { "^PetActionButton", "pet" }, { "^PossessButton", "possess" },
    { "^OverrideActionBarButton", "vehicle" }, { "^ExtraActionButton", "extra" },
    { "^AzeriteActionBar(%d+)Button" }, { "^AzeritePetBarButton", "pet" }, { "^AzeriteStanceBarButton", "stance" },
    { "^BT4PetButton", "pet" }, { "^BT4StanceButton", "stance" }, { "^BT4Button(%d+)$", nil, 12 },
    { "^DominosActionButton(%d+)$", nil, 12 },
    { "^DiabolicPetActionBarButton", "pet" }, { "^DiabolicStanceBarButton", "stance" },
    { "^DiabolicSmallActionBar(%d+)Button", nil, nil, "small" }, { "^DiabolicActionBar(%d+)Button" },
    { "^LUIBarBottom(%d+)Button" }, { "^LUIBar(Left%d+)Button" }, { "^LUIBar(Right%d+)Button" },
    { "^NeuronActionBar(%d+)_" }, { "^NeuronPetBar%d+_", "pet" },
}

local function BarLabel(id, small)
    if id == "pet" then return L.BAR_PET or "Pet Bar" end
    if id == "stance" then return L.BAR_STANCE or "Stance Bar" end
    if id == "possess" then return L.BAR_POSSESS or "Possess Bar" end
    if id == "vehicle" then return L.BAR_VEHICLE or "Vehicle Bar" end
    if id == "extra" then return L.BAR_EXTRA or "Extra Action Button" end
    local n = tonumber(id)
    if n then return string.format(small and (L.BAR_SMALL_N or "Small Bar %d") or (L.BAR_N or "Action Bar %d"), n) end
    -- LUI's side bars: Left1, Right2
    local side, sideN = tostring(id):match("^(%a+)(%d+)$")
    if side == "Left" then return string.format(L.BAR_LEFT_N or "Left Sidebar %d", tonumber(sideN)) end
    if side == "Right" then return string.format(L.BAR_RIGHT_N or "Right Sidebar %d", tonumber(sideN)) end
    return tostring(id)
end

-- key, label for the bar `buttonName` sits on.
---@param buttonName string
---@return string|nil key "Provider:id"
---@return string|nil label
function Bars:GetBarInfo(buttonName)
    if type(buttonName) ~= "string" or buttonName == "" then return nil end
    local provider = addon:GetProviderForButtonName(buttonName)
    local providerKey = provider and provider.key or "Blizzard"
    local id, small
    for _, pattern in ipairs(BAR_PATTERNS) do
        local captured = buttonName:match(pattern[1])
        if captured then
            id, small = pattern[2], pattern[4]
            if not id then
                local n = tonumber(captured)
                if n then
                    -- a global button index: twelve buttons to a bar
                    id = tostring(pattern[3] and math.ceil(n / pattern[3]) or n)
                elseif type(captured) == "string" then
                    id = captured -- a named bar (LUI's Left1)
                else
                    id = "1"
                end
            end
            break
        end
    end
    if not id then id = (buttonName:gsub("%d+$", "")) end
    if small then id = "small" .. id end
    local label = BarLabel(small and id:sub(6) or id, small)
    if providerKey ~= "Blizzard" then
        label = (provider and provider.label or providerKey) .. " · " .. label
    end
    return providerKey .. ":" .. id, label
end

-- The settings for one bar, or nil when it has none of its own.
---@param buttonName string
---@return AHOSBarSettings|nil
function Bars:GetBarSettings(buttonName)
    local bars = addon.db and addon.db.profile and addon.db.profile.bars
    if type(bars) ~= "table" or next(bars) == nil then return nil end
    local key = self:GetBarInfo(buttonName)
    local settings = key and bars[key]
    return type(settings) == "table" and settings or nil
end

-- AHOS leaves this bar's buttons to their own hotkey text.
---@param buttonName string
---@return boolean
function Bars:IsBarHidden(buttonName)
    local settings = self:GetBarSettings(buttonName)
    return settings and settings.hide and true or false
end

-- The scale this bar's text is drawn at, relative to the profile's.
---@param buttonName string
---@return number
function Bars:GetBarScale(buttonName)
    local settings = self:GetBarSettings(buttonName)
    local scale = settings and tonumber(settings.scale)
    return scale and scale > 0 and scale or 1
end

-- Where this bar puts its text: anchor, x, y of its own, or nil to follow the profile.
---@param buttonName string
---@return string|nil anchor
---@return number|nil x
---@return number|nil y
function Bars:GetBarPosition(buttonName)
    local settings = self:GetBarSettings(buttonName)
    if not (settings and settings.position) then return nil end
    local display = addon.db.profile.display or {}
    return settings.anchor or display.anchor or "TOP",
        tonumber(settings.xOffset) or 0, tonumber(settings.yOffset) or 0
end

-- This bar's text shows only while the mouse is over the bar.
---@param buttonName string
---@return boolean
function Bars:IsBarMouseover(buttonName)
    local settings = self:GetBarSettings(buttonName)
    return settings and settings.mouseover and true or false
end

-- A bar back at every default needs no entry of its own.
---@param key string
function Bars:PruneBarSettings(key)
    local bars = addon.db and addon.db.profile and addon.db.profile.bars
    local settings = type(bars) == "table" and bars[key]
    if type(settings) ~= "table" then return end
    if settings.hide or settings.mouseover or settings.position
        or (settings.scale ~= nil and settings.scale ~= 1) then return end
    bars[key] = nil
end

---------------------------------------------------------------------------
-- Single buttons AHOS is told to leave alone
---------------------------------------------------------------------------
local function ButtonSettings(create)
    local profile = addon.db and addon.db.profile
    if not profile then return nil end
    if type(profile.buttons) ~= "table" then
        if not create then return nil end
        profile.buttons = {}
    end
    return profile.buttons
end

---@param buttonName string
---@return boolean
function Bars:IsButtonIgnored(buttonName)
    local buttons = ButtonSettings(false)
    local settings = buttons and type(buttonName) == "string" and buttons[buttonName]
    return type(settings) == "table" and settings.hide and true or false
end

---@param buttonName string
---@param ignored boolean
---@return boolean
function Bars:SetButtonIgnored(buttonName, ignored)
    if type(buttonName) ~= "string" or buttonName == "" then return false end
    local buttons = ButtonSettings(true)
    if not buttons then return false end
    if ignored then
        buttons[buttonName] = { hide = true }
    else
        buttons[buttonName] = nil
    end
    return true
end

-- The names of every ignored button, sorted.
---@return string[]
function Bars:GetIgnoredButtons()
    local list = {}
    for name, settings in pairs(ButtonSettings(false) or {}) do
        if type(settings) == "table" and settings.hide then list[#list + 1] = name end
    end
    table.sort(list)
    return list
end

-- Every tracked button on the bar `key` (as GetBarInfo names it).
---@param key string
---@return Button[]
function Bars:GetButtonsOnBar(key)
    local found = {}
    for _, button in ipairs(self:GetAllButtons()) do
        if self:GetBarInfo(GetSafeButtonName(button)) == key then found[#found + 1] = button end
    end
    return found
end

-- Whether a player can see `button`: shown with all its parents, and not faded to
-- nothing. AzeriteUI hides Blizzard's bars by alpha as well as by hiding.
---@param button Button
---@return boolean
function Bars:IsSeen(button)
    if not addon:IsFrameVisibleSafe(button) then return false end
    local ok, alpha = pcall(function() return button:GetEffectiveAlpha() end)
    if ok and addon:IsValueAccessible(alpha) and type(alpha) == "number" then return alpha > 0 end
    return true
end

-- Every bar found now, plus any with settings of their own that is not loaded:
-- a list of { key, label, count } in name order.
--
-- A bar addon (AzeriteUI, Dominos, Bartender4) hides Blizzard's bars but leaves
-- their buttons in place, so with one drawing, a Blizzard bar is listed only while
-- one of its buttons is shown. On Blizzard's own bars all of them are listed, so a
-- pet bar can be set up without a pet out.
---@return AHOSBarEntry[]
function Bars:GetBarList()
    local byKey, list = {}, {}
    local barAddon = addon.GetDetectedProviderKey and addon:GetDetectedProviderKey() ~= "Blizzard"
    for _, button in ipairs(self:GetAllButtons()) do
        local key, label = self:GetBarInfo(GetSafeButtonName(button))
        local hiddenBlizzard = barAddon and key and key:find("^Blizzard:")
        if key then
            local entry = byKey[key]
            if not entry then
                entry = { key = key, label = label, count = 0, shown = not hiddenBlizzard }
                byKey[key] = entry
                list[#list + 1] = entry
            end
            entry.count = entry.count + 1
            if hiddenBlizzard and Bars:IsSeen(button) then entry.shown = true end
        end
    end
    local bars = addon.db and addon.db.profile and addon.db.profile.bars
    for i = #list, 1, -1 do
        local entry = list[i]
        if not entry.shown and not (type(bars) == "table" and bars[entry.key]) then
            byKey[entry.key] = nil
            table.remove(list, i)
        end
    end
    for key, settings in pairs(type(bars) == "table" and bars or {}) do
        if not byKey[key] and type(settings) == "table" then
            local entry = { key = key, label = settings.label or key, count = 0 }
            byKey[key] = entry
            list[#list + 1] = entry
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end
