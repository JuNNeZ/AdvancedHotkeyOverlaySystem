---@diagnostic disable: undefined-global
-- modules/Core.lua
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSCore
local Core = addon.Core

-- Mainline engine: Retail and WoW Forever (see DetectClient in the core file)
local isRetail = addon.IsMainlineClient
local eventsRegistered = false
local keyBoundCallbacksRegistered = false

-- Bars, bindings and skins settle over about a second after a state change: bar
-- addons page late, and other addons write the native hotkey text after us. So a
-- change is followed by a few more passes. They are one series, though: an event
-- that arrives while a series is running starts it again instead of adding a second
-- one, so a burst of events (combat start fires several) costs one series. And a
-- follow-up pass only runs while the bars are still changing: once a pass finds the
-- same buttons shown and drawn as the one before it, the rest are dropped.
local REFRESH_PASSES = { 0.2, 0.5, 1.0 }
local refreshTimers = {}
local refreshSignature

local function CancelRefreshPasses(core)
    for i = #refreshTimers, 1, -1 do
        if core.CancelTimer then pcall(core.CancelTimer, core, refreshTimers[i], true) end
        refreshTimers[i] = nil
    end
end

---@param reason string for the debug log
function Core:ScheduleRefreshPasses(reason)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] " .. tostring(reason) .. " -> overlay refresh passes.")
    end
    CancelRefreshPasses(self)
    refreshSignature = nil
    self:FullUpdate()
    for index, delay in ipairs(REFRESH_PASSES) do
        refreshTimers[#refreshTimers + 1] = self:ScheduleTimer(function()
            local signature = addon.Display and addon.Display.GetStateSignature and addon.Display:GetStateSignature()
            -- The first follow-up always runs; later ones only while something moved.
            if index > 1 and signature and signature == refreshSignature then
                CancelRefreshPasses(self)
                return
            end
            refreshSignature = signature
            self:FullUpdate()
        end, delay)
    end
end

function Core:HandleBarStateChanged(eventName)
    self:ScheduleRefreshPasses("Bar state event: " .. tostring(eventName))
end

function Core:OnInitialize()
    -- Register with AceDB
    if not LibStub("AceDB-3.0") then
        print("|cFFFF0000[AHOS]|r Critical library AceDB-3.0 missing!")
        return
    end
    -- Do not assert for addon.Config here; wait until OnEnable
    -- Do not set addon.db here; let the main file handle DB setup
    -- Do not set up options here; let the main file handle options
    -- Only print debug info
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core initialized, waiting for PLAYER_ENTERING_WORLD.")
    end
end

function Core:OnEnable()
    -- Now it's safe to reference Config and Options
    assert(addon.Config, "Core module requires Config module to be loaded first.")
    assert(addon.Options, "Core module requires Options module to be loaded first.")
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:OnEnable called.")
    end
    addon:SafeCall("Core", "RegisterEvents")
    self:FullUpdate() -- Ensure overlays are restored on enable
end

function Core:OnDisable()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:OnDisable called.")
    end
    if addon.Performance and addon.Performance.CancelPendingUpdates then
        addon.Performance:CancelPendingUpdates()
    end
    CancelRefreshPasses(self)
    if self.CancelAllTimers then
        pcall(self.CancelAllTimers, self)
    end
    addon:SafeCall("Core", "UnregisterEvents")
    addon:SafeCall("Display", "RemoveAllOverlays") -- Remove overlays and restore original keybinds
end

function Core:RegisterEvents()
    if not addon.db.profile.enabled then return end
    if eventsRegistered then return end
    eventsRegistered = true
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:RegisterEvents called.")
    end
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(...)
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] RegisterEvents: PLAYER_ENTERING_WORLD event fired.")
        end
        addon:SafeCall("Core", "HandlePlayerEnteringWorld", ...)
    end)
    -- self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled") -- Combat ends (handler removed)
    self:RegisterEvent("ACTIONBAR_SHOWGRID", function(...)
        if not addon:IsReady() then
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] ACTIONBAR_SHOWGRID: Forcing SetReady due to bar grid shown.")
            end
            addon:SetReady()
        end
        self:FullUpdate()
    end)
    self:RegisterEvent("UPDATE_BINDINGS", function(...)
        if not addon:IsReady() then
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] UPDATE_BINDINGS: Forcing SetReady due to bindings update.")
            end
            addon:SetReady()
        end
        if addon.Keybinds and addon.Keybinds.ClearCache then
            addon.Keybinds:ClearCache()
        end
        -- Follow-up passes override late hotkey text writes by Dominos/Blizzard
        self:ScheduleRefreshPasses("UPDATE_BINDINGS")
    end)
    -- Retail 12.0.1 no longer exposes PLAYER_BINDING_CHANGED; rely on UPDATE_BINDINGS.
    if addon.db and addon.db.profile and addon.db.profile.debug and isRetail then
        addon:Print("[AHOS DEBUG] Using UPDATE_BINDINGS for binding refreshes on Retail.")
    end
    self:RegisterEvent("ACTIONBAR_HIDEGRID", "FullUpdate")
    self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "FullUpdate")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateSpecificButton")
    -- Dynamic visibility setups (e.g., DynamicCam mount hide) can restore bars right as combat starts.
    -- Run state refresh passes on combat and mount-display transitions so overlays re-attach when bars return.
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self:HandleBarStateChanged("PLAYER_REGEN_DISABLED") end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() self:HandleBarStateChanged("PLAYER_REGEN_ENABLED") end)
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function() self:HandleBarStateChanged("PLAYER_MOUNT_DISPLAY_CHANGED") end)
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", function() self:HandleBarStateChanged("UPDATE_BONUS_ACTIONBAR") end)
    self:RegisterEvent("PET_BAR_UPDATE", function() self:HandleBarStateChanged("PET_BAR_UPDATE") end)
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() self:HandleBarStateChanged("UPDATE_SHAPESHIFT_FORM") end)
    self:RegisterEvent("UPDATE_POSSESS_BAR", function() self:HandleBarStateChanged("UPDATE_POSSESS_BAR") end)
    -- Possess/vehicle/override transitions can restore normal action bars asynchronously.
    -- Listen to all relevant state transitions and run a few delayed refresh passes.
    self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", function() self:HandleBarStateChanged("UPDATE_OVERRIDE_ACTIONBAR") end)
    self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", function() self:HandleBarStateChanged("UPDATE_VEHICLE_ACTIONBAR") end)
    self:RegisterEvent("UNIT_ENTERED_VEHICLE", function(_, unit)
        if unit == "player" then self:HandleBarStateChanged("UNIT_ENTERED_VEHICLE") end
    end)
    self:RegisterEvent("UNIT_EXITED_VEHICLE", function(_, unit)
        if unit == "player" then self:HandleBarStateChanged("UNIT_EXITED_VEHICLE") end
    end)
    -- self:RegisterEvent("VEHICLE_UI_SHOW", "FullUpdate") -- Event does not exist in modern WoW
    -- self:RegisterEvent("VEHICLE_UI_HIDE", "FullUpdate") -- Event does not exist in modern WoW
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "FullUpdate")

    if addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core enabled and events registered.")
    end

    -- LibKeyBound comes with the bar addon that uses it, and may load after AHOS
    -- (on demand, or a bar addon enabled later): try now, and again as addons load.
    self:HookKeyBound()
    self:RegisterEvent("ADDON_LOADED", function() self:HookKeyBound() end)
end

-- Dominos', Bartender4's and LUI's keybind mode. A key bound in it fires
-- UPDATE_BINDINGS like any other; when the mode ends, the bars settle with passes.
---@return boolean hooked
function Core:HookKeyBound()
    if keyBoundCallbacksRegistered then return true end
    local KeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
    if not (KeyBound and KeyBound.RegisterCallback) then return false end
    keyBoundCallbacksRegistered = true
    KeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED", function()
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] LibKeyBound: enabled; suppressing native hotkeys during binding.")
        end
        self:FullUpdate()
    end)
    KeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED", function()
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] LibKeyBound: disabled; re-applying overlay suppression.")
        end
        -- Run a few delayed passes just like UPDATE_BINDINGS
        if addon.Keybinds and addon.Keybinds.ClearCache then
            addon.Keybinds:ClearCache()
        end
        self:ScheduleRefreshPasses("LIBKEYBOUND_DISABLED")
    end)
    return true
end

---@return boolean
function Core:IsKeyBoundHooked()
    return keyBoundCallbacksRegistered
end

function Core:UnregisterEvents()
    self:UnregisterAllEvents()
    eventsRegistered = false
    if addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core disabled, events unregistered, overlays cleared.")
    end
end

function Core:OnProfileChanged(event, db, newProfileKey)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        if newProfileKey then
            addon:Print("[AHOS DEBUG] Profile changed to '" .. tostring(newProfileKey) .. "'. Reloading.")
        else
            addon:Print("[AHOS DEBUG] Profile changed. Reloading.")
        end
    end
    if addon.db and addon.db.profile and addon.db.profile.enabled then
        self:RegisterEvents()
        self:FullUpdate()
    else
        self:OnDisable()
    end
end

function Core:HandlePlayerEnteringWorld(...)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:HandlePlayerEnteringWorld called. Setting addon.ready = true")
    end
    -- Database and critical modules are now ready
    addon.ready = true
    addon:ProcessCallQueue()
    -- Schedule two full updates: one after 1s, another after 3s to catch late-loading buttons
    self:ScheduleTimer(function() self:FullUpdate() end, 1)
    self:ScheduleTimer(function() self:FullUpdate() end, 3)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] PLAYER_ENTERING_WORLD: Addon is now ready. Scheduled full update (1s and 3s).")
    end
end

---@param event string
---@param slot number 0 means every slot
function Core:UpdateSpecificButton(_, slot)
    if not addon.db.profile.enabled then return end
    -- Retail uses slot 0 to signal that every action slot changed.
    if slot == 0 then
        addon.Performance:QueueFullUpdate()
        return
    end
    -- Two bar addons can show the same slot; both need the update.
    for _, button in ipairs(addon.Bars:GetButtonsBySlot(slot)) do
        addon.Performance:QueueButtonUpdate(button)
    end
end

function Core:FullUpdate(...)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:FullUpdate called. IsReady:", addon:IsReady())
    end
    if not addon:IsReady() then
        addon:SafeCall("Core", "FullUpdate")
        return
    end
    if not addon.db.profile.enabled or (addon.ShouldShowOverlays and not addon:ShouldShowOverlays()) then
        addon:SafeCall("Display", "RemoveAllOverlays")
        -- Turning overlays off is a change the options window should show too.
        if privateScope.OnOptionsChanged then privateScope.OnOptionsChanged() end
        return
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:FullUpdate proceeding to Performance:QueueFullUpdate")
    end
    addon:SafeCall("Performance", "QueueFullUpdate")
    -- The options window redraws its open page once, on the next frame.
    if privateScope.OnOptionsChanged then privateScope.OnOptionsChanged() end
end

