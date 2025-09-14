---@diagnostic disable: undefined-global
-- modules/Core.lua
local addonName, privateScope = ...
local addon = privateScope.addon
local Core = addon.Core

-- Build gating utility: prefer project ID for accurate flavor detection, fallback to build
local function IsRetail()
    local pid = rawget(_G, "WOW_PROJECT_ID")
    local pm = rawget(_G, "WOW_PROJECT_MAINLINE")
    if type(pid) == "number" and type(pm) == "number" then
        return pid == pm
    end
    -- Fallback heuristic: Dragonflight+ builds >= 100000
    local build = select(4, GetBuildInfo()) or 0
    return build >= 100000
end
local isRetail = IsRetail()

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
        addon:Print("Core initialized, waiting for PLAYER_ENTERING_WORLD.")
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
    addon:SafeCall("Core", "UnregisterEvents")
    addon:SafeCall("Display", "RemoveAllOverlays") -- Remove overlays and restore original keybinds
end

function Core:RegisterEvents()
    if not addon.db.profile.enabled then return end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:RegisterEvents called.")
    end
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
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
    -- Run multiple delayed updates to override late hotkey text writes by Dominos/Blizzard
    self:FullUpdate()
    self:ScheduleTimer(function() self:FullUpdate() end, 0.2)
    self:ScheduleTimer(function() self:FullUpdate() end, 0.5)
    self:ScheduleTimer(function() self:FullUpdate() end, 1.0)
    end)
    -- Some UIs fire PLAYER_BINDING_CHANGED frequently while editing
    if isRetail then
      self:RegisterEvent("PLAYER_BINDING_CHANGED", function()
          if addon.Keybinds and addon.Keybinds.ClearCache then
              addon.Keybinds:ClearCache()
          end
          self:FullUpdate()
          self:ScheduleTimer(function() self:FullUpdate() end, 0.2)
          self:ScheduleTimer(function() self:FullUpdate() end, 0.5)
      end)
    else
      -- Classic: event not available, rely on UPDATE_BINDINGS
      if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Skipping PLAYER_BINDING_CHANGED on Classic.")
      end
    end
    self:RegisterEvent("ACTIONBAR_HIDEGRID", "FullUpdate")
    self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "FullUpdate")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateSpecificButton")
    self:RegisterEvent("PET_BAR_UPDATE", "FullUpdate")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "FullUpdate")
    self:RegisterEvent("UPDATE_POSSESS_BAR", "FullUpdate")
    -- self:RegisterEvent("VEHICLE_UI_SHOW", "FullUpdate") -- Event does not exist in modern WoW
    -- self:RegisterEvent("VEHICLE_UI_HIDE", "FullUpdate") -- Event does not exist in modern WoW
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "FullUpdate")

    if addon.db.profile.debug then
        addon:Print("Core enabled and events registered.")
    end

    -- Optional: listen for LibKeyBound callbacks if library is present (used by Dominos/Bartender keybind mode)
    local ok, KeyBound = pcall(LibStub, "LibKeyBound-1.0")
    if ok and KeyBound and KeyBound.RegisterCallback then
        KeyBound:RegisterCallback(self, "LIBKEYBOUND_ENABLED", function()
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] LibKeyBound: enabled; suppressing native hotkeys during binding.")
            end
            self:FullUpdate()
        end)
        KeyBound:RegisterCallback(self, "LIBKEYBOUND_DISABLED", function()
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] LibKeyBound: disabled; re-applying overlay suppression.")
            end
            -- Run a few delayed passes just like UPDATE_BINDINGS
            if addon.Keybinds and addon.Keybinds.ClearCache then
                addon.Keybinds:ClearCache()
            end
            self:FullUpdate()
            self:ScheduleTimer(function() self:FullUpdate() end, 0.2)
            self:ScheduleTimer(function() self:FullUpdate() end, 0.5)
            self:ScheduleTimer(function() self:FullUpdate() end, 1.0)
        end)
    end
end

function Core:UnregisterEvents()
    self:UnregisterAllEvents()
    addon:SafeCall("Display", "ClearAllOverlays")
    if addon.db.profile.debug then
        addon:Print("Core disabled, events unregistered, overlays cleared.")
    end
end

function Core:OnProfileChanged(event, db, newProfileKey)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        if newProfileKey then
            addon:Print("Profile changed to '" .. tostring(newProfileKey) .. "'. Reloading.")
        else
            addon:Print("Profile changed. Reloading.")
        end
    end
    self:FullUpdate()
end

function Core:OnPlayerLogin()
    addon:SafeCall("Config", "DetectUI")
    self:FullUpdate()
    if addon.db.profile.debug then
        addon:Print("PLAYER_LOGIN: UI detected as '" .. (addon.detectedUI or "None") .. "'. Full update triggered.")
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
        addon:Print("PLAYER_ENTERING_WORLD: Addon is now ready. Scheduled full update (1s and 3s).")
    end
end

function Core:UpdateSpecificButton(slot)
    if not addon.db.profile.enabled then return end
    local button = addon.Bars:GetButtonBySlot(slot)
    if button then
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
    if not addon.db.profile.enabled then
        addon:SafeCall("Display", "ClearAllOverlays")
        return
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:FullUpdate proceeding to Performance:QueueFullUpdate")
    end
    addon:SafeCall("Performance", "QueueFullUpdate")
    -- Also notify AceConfig to refresh all open option UIs (JUI/Pretty/Ace windows)
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then reg:NotifyChange(_G.AHOS_OPTIONS_PANEL_NAME or addonName) end
    -- If the handcrafted JUI is open, refresh its current section to reflect latest DB changes
    if addon.RefreshJUI then addon:RefreshJUI() end
end

-- Add a stub UpdateAllButtons to ensure overlays update and error is gone
function Core:UpdateAllButtons(...)
    -- Call Bars and Display overlay updates if they exist
    if addon.Bars and type(addon.Bars.UpdateAllButtons) == "function" then
        addon.Bars:UpdateAllButtons(...)
    end
    if addon.Display and type(addon.Display.UpdateAllButtons) == "function" then
        addon.Display:UpdateAllButtons(...)
    end
    -- You can add additional overlay update logic here if needed
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Core:UpdateAllButtons called.")
    end
end

function Core:ChatCommand(input)
    local args = {}
    for arg in string.gmatch(input, "[^%s]+") do
        table.insert(args, arg)
    end

    if #args == 0 then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    elseif args[1] == "refresh" then
        self:FullUpdate()
        addon:Print("Overlays refreshed.")
    elseif args[1] == "debug" then
        addon.db.profile.debug = not addon.db.profile.debug
        addon:Print("Debug mode " .. (addon.db.profile.debug and "enabled" or "disabled") .. ".")
    elseif args[1] == "detect" then
        addon.Config:DetectUI()
        addon:Print("UI re-detected as: " .. (addon.detectedUI or "Unknown"))
        self:FullUpdate()
    elseif args[1] == "inspect" and args[2] then
        local buttonName = string.upper(args[2])
        local button = _G[buttonName]
        if button then
            local info = addon.Keybinds:GetButtonDebugInfo(button)
            addon:Print(info)
        else
            addon:Print("Button '" .. tostring(args[2]) .. "' not found.")
        end
    elseif args[1] == "dumphotkey" and args[2] then
        local buttonName = string.upper(args[2])
        local button = _G[buttonName]
        if button and addon.Display and addon.Display.DumpHotkeyRegions then
            addon.Display:DumpHotkeyRegions(button)
        else
            addon:Print("Button '" .. tostring(args[2]) .. "' not found or Display missing.")
        end
    elseif args[1] == "dumplayers" and args[2] then
        local buttonName = string.upper(args[2])
        local button = _G[buttonName]
        if button and addon.Display and addon.Display.DumpButtonLayers then
            addon.Display:DumpButtonLayers(button)
        else
            addon:Print("Button '" .. tostring(args[2]) .. "' not found or Display missing.")
        end
    else
        addon:Print("Usage: /ahos [refresh|debug|detect|inspect <ButtonName>|dumphotkey <ButtonName>|dumplayers <ButtonName>]")
    end
end
