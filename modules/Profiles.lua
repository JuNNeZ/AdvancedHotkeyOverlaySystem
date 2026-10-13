---@diagnostic disable: undefined-global
-- modules/Profiles.lua - presets, snapshots and switching profiles.
--
--   * Presets: named looks (Blizzard Style, Big and Centered, ...) and role
--     templates (Tank, Healer, Damage) laid over the current profile.
--   * Snapshots: copies of a profile to go back to, kept for every character
--     (db.global). One is taken before every preset, import, reset and restore,
--     so any of them can be undone with /ahos rollback.
--   * Switching: /ahos profile <name>, and switching by itself when the
--     specialization or the talent loadout changes (a choice per character).
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSProfiles
local Profiles = addon.Profiles
local L = addon.L or {}

local MAX_SNAPSHOTS = 15

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = DeepCopy(v) end
    return out
end
Profiles.DeepCopy = DeepCopy

-- Lays `source` over `dest`: tables are walked into, so a table AceDB made keeps
-- its defaults; everything else is replaced.
local function Merge(dest, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(dest[k]) == "table" and not (#v > 0) then
            Merge(dest[k], v)
        else
            dest[k] = DeepCopy(v)
        end
    end
end
Profiles.Merge = Merge

local function Now()
    local clock = rawget(_G, "time")
    return type(clock) == "function" and clock() or 0
end

local function Refresh()
    if addon.Keybinds and addon.Keybinds.ClearCache then addon.Keybinds:ClearCache() end
    if addon.Visibility and addon.Visibility.OnSettingsChanged then addon.Visibility:OnSettingsChanged() end
    if addon.Core and addon.Core.FullUpdate then addon.Core:FullUpdate() end
end

---------------------------------------------------------------------------
-- Presets
---------------------------------------------------------------------------
Profiles.Presets = {
    { key = "blizzard", label = L.PRESET_BLIZZARD or "Blizzard Style",
      desc = L.PRESET_BLIZZARD_DESC or "Small text in the top-right corner, where the game puts it.",
      values = { display = { anchor = "TOPRIGHT", xOffset = -2, yOffset = -3, scale = 1 },
                 text = { fontSize = 12, outlineStyle = "OUTLINE", outline = true } } },
    { key = "centered", label = L.PRESET_CENTERED or "Big and Centered",
      desc = L.PRESET_CENTERED_DESC or "Large text in the middle of the button, easy to read at a glance.",
      values = { display = { anchor = "CENTER", xOffset = 0, yOffset = 0, scale = 1 },
                 text = { fontSize = 20, outlineStyle = "THICKOUTLINE", outline = true } } },
    { key = "corner", label = L.PRESET_CORNER or "Bottom Corner",
      desc = L.PRESET_CORNER_DESC or "Text in the bottom-right corner, clear of cooldown numbers.",
      values = { display = { anchor = "BOTTOMRIGHT", xOffset = -2, yOffset = 2, scale = 1 },
                 text = { fontSize = 13, outlineStyle = "OUTLINE", outline = true } } },
    { key = "compact", label = L.PRESET_COMPACT or "Compact",
      desc = L.PRESET_COMPACT_DESC or "Small text along the top, at most four letters.",
      values = { display = { anchor = "TOP", xOffset = 0, yOffset = -2, scale = 1 },
                 text = { fontSize = 11, maxLength = 4, outlineStyle = "OUTLINE", outline = true } } },
    { key = "tank", label = L.PRESET_TANK or "Tank",
      desc = L.PRESET_TANK_DESC or "Big, glowing text that turns red in combat: the keys you need now stand out.",
      values = { display = { anchor = "TOP", xOffset = 0, yOffset = -2, scale = 1 },
                 text = { fontSize = 18, outlineStyle = "THICKOUTLINE", outline = true, glow = { enabled = true } },
                 visibility = { combatStyle = { enabled = true, color = {1, 0.35, 0.3}, scale = 1.15 } } } },
    { key = "healer", label = L.PRESET_HEALER or "Healer",
      desc = L.PRESET_HEALER_DESC or "Bindings coloured by modifier with the letters dropped, on a dark plate: Shift, Ctrl and Alt layers read at a glance.",
      values = { display = { anchor = "TOPRIGHT", xOffset = -2, yOffset = -2, scale = 1,
                             background = { enabled = true, color = {0, 0, 0, 0.55}, padding = 2 } },
                 text = { fontSize = 13, outlineStyle = "OUTLINE", outline = true,
                          modifierColors = { enabled = true, hideModifiers = true } } } },
    { key = "dps", label = L.PRESET_DPS or "Damage",
      desc = L.PRESET_DPS_DESC or "Text that pulses when pressed and dims out of combat, so your rotation is what you see.",
      values = { display = { anchor = "TOP", xOffset = 0, yOffset = -3, scale = 1, pressAnimation = "pulse" },
                 text = { fontSize = 16, outlineStyle = "OUTLINE", outline = true },
                 visibility = { fadeOutOfCombat = true, fadedAlpha = 0.35 } } },
}

---@param key string a preset's key or label
---@return AHOSPreset|nil
function Profiles:GetPreset(key)
    if type(key) ~= "string" then return nil end
    key = key:lower()
    for _, preset in ipairs(self.Presets) do
        if preset.key == key or preset.label:lower() == key then return preset end
    end
end

---@param key string
---@return boolean
function Profiles:ApplyPreset(key)
    local preset = self:GetPreset(key)
    local profile = addon.db and addon.db.profile
    if not (preset and profile) then return false end
    self:TakeSnapshot(string.format(L.SNAPSHOT_BEFORE_PRESET or "Before preset %s", preset.label))
    Merge(profile, preset.values)
    Refresh()
    addon:Print(string.format(L.MSG_PRESET_APPLIED or "Preset applied: %s. /ahos rollback puts back what you had.", preset.label))
    return true
end

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
local function Store()
    local global = addon.db and addon.db.global
    if not global then return {} end
    if type(global.snapshots) ~= "table" then global.snapshots = {} end
    return global.snapshots
end

-- Newest first.
---@return AHOSSnapshot[] newest first
function Profiles:GetSnapshots()
    return Store()
end

---@param label? string
---@return AHOSSnapshot|nil
function Profiles:TakeSnapshot(label)
    if not (addon.db and addon.db.profile) then return nil end
    local list = Store()
    local snapshot = {
        label = (type(label) == "string" and label ~= "") and label or (L.SNAPSHOT_MANUAL or "Snapshot"),
        profile = addon.db:GetCurrentProfile(),
        time = Now(),
        data = DeepCopy(addon.db.profile),
    }
    table.insert(list, 1, snapshot)
    while #list > MAX_SNAPSHOTS do table.remove(list) end
    return snapshot
end

---@param index number
---@return string|nil
function Profiles:DescribeSnapshot(index)
    local snapshot = Store()[index]
    if not snapshot then return nil end
    local when = ""
    local stamp = rawget(_G, "date")
    if snapshot.time and snapshot.time > 0 and type(stamp) == "function" then
        when = stamp("%Y-%m-%d %H:%M", snapshot.time) .. "  "
    end
    return string.format("%d. %s%s  (%s)", index, when, snapshot.label or "?", snapshot.profile or "?")
end

-- Puts snapshot `index` (1 is the newest) into the current profile. What was
-- there is kept as a snapshot of its own first, so a restore can be undone too.
---@param index? number 1 is the newest
---@return boolean
function Profiles:RestoreSnapshot(index)
    index = tonumber(index) or 1
    local snapshot = Store()[index]
    if not (snapshot and type(snapshot.data) == "table" and addon.db) then return false end
    local data = DeepCopy(snapshot.data)
    self:TakeSnapshot(string.format(L.SNAPSHOT_BEFORE_RESTORE or "Before restoring %s", snapshot.label or "?"))
    addon.db:ResetProfile(false, true)
    Merge(addon.db.profile, data)
    if addon.OnProfileChanged then addon:OnProfileChanged(nil, nil, addon.db:GetCurrentProfile()) end
    Refresh()
    return true
end

---@param index number
---@return boolean
function Profiles:DeleteSnapshot(index)
    local list = Store()
    index = tonumber(index)
    if not (index and list[index]) then return false end
    table.remove(list, index)
    return true
end

---------------------------------------------------------------------------
-- Switching
---------------------------------------------------------------------------
local function ProfileExists(name)
    for _, existing in ipairs(addon.db:GetProfiles()) do
        if existing == name then return true end
    end
    return false
end

-- Switches to profile `name`, made as a copy of this one when it is new.
---@param name string
---@param quiet? boolean
---@return boolean ok
---@return boolean|nil isNew
function Profiles:SaveAs(name, quiet)
    if type(name) ~= "string" then return false end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" or not addon.db then return false end
    local current = addon.db:GetCurrentProfile()
    if name == current then return true end
    local isNew = not ProfileExists(name)
    addon.db:SetProfile(name)
    if isNew then addon.db:CopyProfile(current) end
    if not quiet then
        addon:Print(string.format(isNew and (L.MSG_PROFILE_CREATED or "Profile %s made from %s.")
            or (L.MSG_PROFILE_SWITCHED or "Switched to profile %s."), name, current))
    end
    return true, isNew
end

function Profiles:SlashProfile(rest)
    local name = type(rest) == "string" and rest:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then
        local current = addon.db:GetCurrentProfile()
        addon:Print(L.MSG_PROFILE_LIST or "Profiles (/ahos profile <name> to switch):")
        for _, existing in ipairs(addon.db:GetProfiles()) do
            addon:Print((existing == current and "  |cff00d4aa> " or "    ") .. existing .. (existing == current and "|r" or ""))
        end
        return
    end
    self:SaveAs(name)
end

function Profiles:SlashPreset(rest)
    local key = type(rest) == "string" and rest:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if key == "" then
        addon:Print(L.MSG_PRESET_LIST or "Presets (/ahos preset <name>):")
        for _, preset in ipairs(self.Presets) do
            addon:Print("  |cffffd700" .. preset.key .. "|r - " .. preset.label .. ": " .. preset.desc)
        end
        return
    end
    if not self:ApplyPreset(key) then
        addon:Print(string.format(L.MSG_PRESET_UNKNOWN or "No preset called %s. /ahos presets lists them.", key))
    end
end

function Profiles:SlashSnapshot(rest)
    local label = type(rest) == "string" and rest:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if label == "list" then
        local list = Store()
        if #list == 0 then addon:Print(L.MSG_NO_SNAPSHOTS or "No snapshots yet."); return end
        for i = 1, #list do addon:Print("  " .. self:DescribeSnapshot(i)) end
        return
    end
    self:TakeSnapshot(label)
    addon:Print(L.MSG_SNAPSHOT_TAKEN or "Snapshot saved. /ahos rollback puts it back; /ahos snapshot list shows them all.")
end

function Profiles:SlashRollback(rest)
    local index = tonumber(type(rest) == "string" and rest:match("%d+")) or 1
    if self:RestoreSnapshot(index) then
        -- the restore itself pushed one snapshot in front of the one it put back
        addon:Print(string.format(L.MSG_SNAPSHOT_RESTORED or "Put back: %s", self:DescribeSnapshot(index + 1) or "?"))
    else
        addon:Print(L.MSG_NO_SNAPSHOTS or "No snapshots yet.")
    end
end

---------------------------------------------------------------------------
-- Switching with the specialization or talent loadout
---------------------------------------------------------------------------
local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    if not addon:IsValueAccessible(a) then a = nil end
    if not addon:IsValueAccessible(b) then b = nil end
    return a, b
end

-- The specialization's id and name.
---@return number|nil specID
---@return string|nil name
function Profiles:GetSpec()
    local api = C_SpecializationInfo
    local index = Call(api and api.GetSpecialization or GetSpecialization)
    if not index then return nil end
    local id, name = Call(api and api.GetSpecializationInfo or GetSpecializationInfo, index)
    return id, name
end

-- The name of the talent loadout in use, where the client has loadouts.
---@param specID number
---@return string|nil
function Profiles:GetLoadoutName(specID)
    if not (specID and C_ClassTalents and C_Traits) then return nil end
    local configID = Call(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
    if not configID then return nil end
    local info = Call(C_Traits.GetConfigInfo, configID)
    return type(info) == "table" and type(info.name) == "string" and info.name ~= "" and info.name or nil
end

-- The profile this character should be on, or nil when it switches by nothing.
---@return string|nil
function Profiles:GetAutoProfileName()
    local mode = addon.db and addon.db.char and addon.db.char.autoSwitch
    if mode ~= "spec" and mode ~= "loadout" then return nil end
    local specID, specName = self:GetSpec()
    if not specName then return nil end
    local name = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?") .. "-" .. specName
    if mode == "loadout" then
        local loadout = self:GetLoadoutName(specID)
        if loadout then name = name .. "-" .. loadout end
    end
    return name
end

---@return boolean switched
function Profiles:AutoSwitch()
    local name = self:GetAutoProfileName()
    if not name or name == addon.db:GetCurrentProfile() then return false end
    self:SaveAs(name, true)
    addon:Print(string.format(L.MSG_AUTO_SWITCHED or "Auto-switched to profile: %s", name))
    return true
end

local pending
function Profiles:QueueAutoSwitch()
    if pending then return end
    pending = self:ScheduleTimer(function()
        pending = nil
        Profiles:AutoSwitch()
    end, 0.5)
end

local eventFrame
function Profiles:OnEnable()
    -- The setting used to live in the profile it switched away from, so a new
    -- profile never switched back. It is the character's now.
    local profile = addon.db and addon.db.profile
    if profile and profile.autoSwitchProfile then
        if addon.db.char.autoSwitch == "off" then addon.db.char.autoSwitch = "spec" end
        profile.autoSwitchProfile = nil
    end
    -- Not every client has these events; one it does not know would be an error.
    eventFrame = eventFrame or CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_COMBAT_CONFIG_CHANGED", "TRAIT_CONFIG_UPDATED", "PLAYER_ENTERING_WORLD" }) do
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
        Profiles:QueueAutoSwitch()
    end)
end
