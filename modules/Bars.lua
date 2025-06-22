---@diagnostic disable: undefined-global
-- modules/Bars.lua
local addonName, privateScope = ...
local addon = privateScope.addon
local Bars = addon.Bars

function Bars:OnInitialize()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Bars module initialized.")
    end
end

local trackedButtons = {}
local buttonToAction = {}

-- List of all possible action bars and their button names
local barDefinitions = {
    -- Blizzard bars
    { "ActionButton%d", 1, 12 },
    { "MultiBarBottomLeftButton%d", 1, 12 },
    { "MultiBarBottomRightButton%d", 1, 12 },
    { "MultiBarRightButton%d", 1, 12 },
    { "MultiBarLeftButton%d", 1, 12 },
    { "StanceButton%d", 1, 10 },
    { "PetActionButton%d", 1, 10 },
    { "PossessButton%d", 1, 12 },
    { "ExtraActionButton1", 0, 0 },
    { "OverrideActionBarButton%d", 1, 12 },
    -- AzeriteUI bars (support up to 5 bars, 12 buttons each)
    { "AzeriteActionBar%dButton%d", 1, 5, 1, 12 },
    { "AzeriteStanceBarButton%d", 1, 10 },
}

function Bars:OnEnable()
    addon:SafeCall("Bars", "UpdateTrackedButtons")
end

function Bars:UpdateTrackedButtons()
    wipe(trackedButtons)
    wipe(buttonToAction)
    for _, def in ipairs(barDefinitions) do
        if #def == 3 then
            local nameFormat, startIdx, endIdx = unpack(def)
            if startIdx == 0 then -- Single button case
                local btn = _G[nameFormat]
                if btn and btn:IsVisible() then
                    table.insert(trackedButtons, btn)
                    if btn.action then buttonToAction[btn:GetName()] = btn.action end
                end
            else
                for i = startIdx, endIdx do
                    local btnName = nameFormat:format(i)
                    local btn = _G[btnName]
                    if btn and btn:IsVisible() then
                        table.insert(trackedButtons, btn)
                        if btn.action then buttonToAction[btnName] = btn.action end
                    end
                end
            end
        elseif #def == 5 then
            -- AzeriteUI: { "AzeriteActionBar%dButton%d", barStart, barEnd, btnStart, btnEnd }
            local nameFormat, barStart, barEnd, btnStart, btnEnd = unpack(def)
            for bar = barStart, barEnd do
                for btn = btnStart, btnEnd do
                    local btnName = nameFormat:format(bar, btn)
                    local btnObj = _G[btnName]
                    if btnObj and btnObj:IsVisible() then
                        table.insert(trackedButtons, btnObj)
                        if btnObj.action then buttonToAction[btnName] = btnObj.action end
                    end
                end
            end
        end
    end
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Tracked " .. #trackedButtons .. " visible action buttons.")
    end
end

function Bars:GetAllButtons()
    -- We refresh the list every time to catch visibility changes (e.g., bar paging)
    self:UpdateTrackedButtons()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Bars:GetAllButtons found " .. tostring(#trackedButtons) .. " buttons.")
    end
    return trackedButtons
end

function Bars:GetButtonBySlot(slot)
    if not slot then return nil end
    for _, btn in ipairs(self:GetAllButtons()) do
        if btn.action == slot then
            return btn
        end
    end
    return nil
end
