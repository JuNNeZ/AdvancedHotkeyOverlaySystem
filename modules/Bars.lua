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
local addedNames = {}

-- List of all possible action bars and their button names
local barDefinitions = {
    -- Blizzard bars
    { "ActionButton%d", 1, 12 },
    { "BonusActionButton%d", 1, 12 },
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
    -- Detect Dominos, but do not exclude Blizzard bars. We overlay both and rely on
    -- HasAction() in Display to skip empty slots.
    local dominosActive = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Dominos"))
        or (IsAddOnLoaded and IsAddOnLoaded("Dominos"))
        or (addon and addon.detectedUI == "Dominos")
    local function add(btn)
        if not btn or not btn.GetName then return end
        local name = btn:GetName()
        if not name or addedNames[name] then return end
        -- Add regardless of current visibility; Display filters on visibility per-frame.
        table.insert(trackedButtons, btn)
        addedNames[name] = true
        local slot = btn.action or (btn.GetAttribute and btn:GetAttribute("action")) or nil
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

    if dominosActive then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Dominos detected - scanning for DominosActionButtons")
        end
        -- Attempt common global names: DominosActionButton1..200 (covers larger configs)
        for i = 1, 200 do
            local b = _G["DominosActionButton" .. i]
            if b then addButton(b) end
        end
        -- Fallback: scan Dominos bar frames for button children (DominosBar* and DominosFrame*)
        local function scanContainer(prefix, count)
            for i = 1, count do
                local bar = _G[prefix .. i]
                if bar and bar.GetChildren then
                    local kids = { bar:GetChildren() }
                    for _, child in ipairs(kids) do
                        if child and child.GetName then
                            local cname = child:GetName()
                            if cname and cname:match("^DominosActionButton%d+") then
                                addButton(child)
                            end
                        end
                    end
                end
            end
        end
        scanContainer("DominosBar", 20)
        scanContainer("DominosFrame", 20)
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] After Dominos scan, tracked buttons count: " .. tostring(#trackedButtons))
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
        local action = btn.action or (btn.GetAttribute and btn:GetAttribute("action"))
        if action == slot then
            return btn
        end
    end
    return nil
end
