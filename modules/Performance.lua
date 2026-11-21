---@diagnostic disable: undefined-global
-- modules/Performance.lua
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSPerformance
local Performance = addon.Performance

local updateQueue = {}
local pendingSlots = {}
local fullUpdateScheduled = false
local updateTimer = nil

-- Default settings
local THROTTLE_INTERVAL = 0.1 -- seconds

local function AddButtonToQueue(button)
    if not button then return end
    local ok, name = pcall(function()
        return button.GetName and button:GetName()
    end)
    if not ok or not addon:IsValueAccessible(name) or type(name) ~= "string" or name == "" then return end
    updateQueue[name] = button
    return true
end

---@param button Button
function Performance:QueueButtonUpdate(button)
    if not addon.db or not addon.db.profile or not addon.db.profile.enabled then return end
    if AddButtonToQueue(button) then self:ScheduleUpdate() end
end

function Performance:QueueFullUpdate()
    if not addon.db or not addon.db.profile or not addon.db.profile.enabled then return end
    fullUpdateScheduled = true
    self:ScheduleUpdate()
end

---@param slot number
function Performance:QueueSlotUpdate(slot)
    if not addon.db or not addon.db.profile or not addon.db.profile.enabled then return end
    if not addon:IsValueAccessible(slot) or type(slot) ~= "number" then return end
    -- Slot zero means every action slot changed.
    if slot == 0 then
        self:QueueFullUpdate()
    elseif not fullUpdateScheduled then
        pendingSlots[slot] = true
        self:ScheduleUpdate()
    end
end

function Performance:CancelPendingUpdates()
    if updateTimer and self.CancelTimer then
        pcall(self.CancelTimer, self, updateTimer, true)
    end
    updateTimer = nil
    fullUpdateScheduled = false
    wipe(updateQueue)
    wipe(pendingSlots)
end

function Performance:ScheduleUpdate()
    if not updateTimer then
        updateTimer = self:ScheduleTimer("ProcessQueue", THROTTLE_INTERVAL)
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Update scheduled.")
        end
    end
end

function Performance:ProcessQueue()
    updateTimer = nil

    if not addon.db or not addon.db.profile or not addon.db.profile.enabled
        or (addon.ShouldShowOverlays and not addon:ShouldShowOverlays()) then
        fullUpdateScheduled = false
        wipe(updateQueue)
        wipe(pendingSlots)
        if addon.Display and addon.Display.RemoveAllOverlays then
            addon.Display:RemoveAllOverlays()
        end
        return
    end

    if not addon:IsReady() then
        self:ScheduleUpdate() -- Re-schedule if not ready
        return
    end

    if fullUpdateScheduled then
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Processing full update.")
        end
        fullUpdateScheduled = false
        wipe(updateQueue)
        wipe(pendingSlots)
        addon.Keybinds:ClearCache()
        addon.Display:UpdateAllOverlays()
    else
        -- Resolve the current slots once after paging settles. Multiple bar
        -- addons can show the same slot, so include every matching button.
        if next(pendingSlots) then
            for _, button in ipairs(addon.Bars:GetAllButtons()) do
                local slot = addon:GetButtonActionSlot(button)
                if slot and pendingSlots[slot] then
                    AddButtonToQueue(button)
                end
            end
            wipe(pendingSlots)
        end
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            local count = 0
            for _ in pairs(updateQueue) do count = count + 1 end
            addon:Print("[AHOS DEBUG] Processing partial update for " .. count .. " buttons.")
        end
        for _, button in pairs(updateQueue) do
            if addon.Keybinds and addon.Keybinds.ClearButtonCache then
                addon.Keybinds:ClearButtonCache(button)
            end
            local ok, err
            if addon.Display.SafeUpdateOverlayForButton then
                ok, err = addon.Display:SafeUpdateOverlayForButton(button)
            else
                ok, err = pcall(addon.Display.UpdateOverlayForButton, addon.Display, button)
            end
            if not ok and addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Partial overlay update failed: " .. addon:SafeToString(err, "unknown error"))
            end
        end
        wipe(updateQueue)
    end
end
