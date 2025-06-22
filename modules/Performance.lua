---@diagnostic disable: undefined-global
-- modules/Performance.lua
local addonName, privateScope = ...
local addon = privateScope.addon
local Performance = addon.Performance

local updateQueue = {}
local fullUpdateScheduled = false
local updateTimer = nil

-- Default settings
local THROTTLE_INTERVAL = 0.1 -- seconds

function Performance:QueueButtonUpdate(button)
    if not button or not button:GetName() then return end
    updateQueue[button:GetName()] = button
    self:ScheduleUpdate()
end

function Performance:QueueFullUpdate()
    fullUpdateScheduled = true
    self:ScheduleUpdate()
end

function Performance:ScheduleUpdate()
    if not updateTimer then
        updateTimer = self:ScheduleTimer("ProcessQueue", THROTTLE_INTERVAL)
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("Update scheduled.")
        end
    end
end

function Performance:ProcessQueue()
    updateTimer = nil

    if not addon:IsReady() then
        self:ScheduleUpdate() -- Re-schedule if not ready
        return
    end

    if fullUpdateScheduled then
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("Processing full update.")
        end
        fullUpdateScheduled = false
        wipe(updateQueue)
        addon.Keybinds:ClearCache()
        addon.Display:UpdateAllOverlays()
    else
        if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
            local count = 0
            for _ in pairs(updateQueue) do count = count + 1 end
            addon:Print("Processing partial update for " .. count .. " buttons.")
        end
        for _, button in pairs(updateQueue) do
            addon.Display:UpdateOverlayForButton(button)
        end
        wipe(updateQueue)
    end
end
