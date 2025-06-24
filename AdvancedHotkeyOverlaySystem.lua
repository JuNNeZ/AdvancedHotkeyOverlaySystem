---@diagnostic disable: undefined-global
-- AdvancedHotkeyOverlaySystem.lua
local addonName, addonScope = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addonScope.addon = addon

-- Remove any global AdvancedHotkeyOverlaySystem table creation (orphaned/legacy)
_G["AdvancedHotkeyOverlaySystem"] = nil

-- Ensure the main addon table is available globally for legacy code
_G.AdvancedHotkeyOverlaySystem = addon

-- Register modules in the correct order so dependencies are always available
addon.Config = addon:NewModule("Config", "AceEvent-3.0")
addon.Options = addon:NewModule("Options")
addon.Core = addon:NewModule("Core", "AceEvent-3.0", "AceTimer-3.0")
addon.Bars = addon:NewModule("Bars")
addon.Keybinds = addon:NewModule("Keybinds")
addon.Display = addon:NewModule("Display", "AceEvent-3.0")
addon.Performance = addon:NewModule("Performance", "AceTimer-3.0")
addon.UI = addon:NewModule("UI", "AceEvent-3.0")

-- Compatibility helper for checking if an addon is loaded
local function IsAddOnLoadedCompat(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

-- Wrapper to call the correct module's UpdateAllButtons
function addon:UpdateAllButtons(...)
    if not self:ShouldShowOverlays() or not (self.db and self.db.profile and self.db.profile.enabled) then
        if self.Display and self.Display.ClearAllOverlays then
            self.Display:ClearAllOverlays()
        end
        return
    end
    if self.Core and type(self.Core.UpdateAllButtons) == "function" then
        return self.Core:UpdateAllButtons(...)
    elseif self.Bars and type(self.Bars.UpdateAllButtons) == "function" then
        return self.Bars:UpdateAllButtons(...)
    elseif self.Display and type(self.Display.UpdateAllButtons) == "function" then
        return self.Display:UpdateAllButtons(...)
    else
        self:Print("|cffff0000Error:|r No UpdateAllButtons method found in any module.")
    end
end

-- Global reference for the options panel display name
_G.AHOS_OPTIONS_PANEL_NAME = "Advanced Hotkey Overlay System"

-- SAFETY: Update OpenAHOSOptionsPanel to use the plain config category
_G.OpenAHOSOptionsPanel = function()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    local appName = _G.AHOS_OPTIONS_PANEL_NAME
    if AceConfigDialog then
        if AceConfigDialog.OpenFrames[appName] then
            AceConfigDialog:Close(appName)
        else
            AceConfigDialog:Open(appName)
            -- SAFETY: Do not set custom title, let Ace3/Blizzard handle it
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(appName)
        InterfaceOptionsFrame_OpenToCategory(appName)
    end
end

-- Addon state
addon.ready = false
addon.callQueue = {}

-- Check if the addon is fully initialized and ready
function addon:IsReady()
    -- The addon is ready once the player is in the world and the Core has signaled readiness.
    return self.ready
end

-- Process the queue of deferred function calls
function addon:ProcessCallQueue()
    if not self:IsReady() then return end
    if self.db.profile.debug then
        self:Print(string.format("Processing %d queued calls.", #self.callQueue))
    end
    for _, call in ipairs(self.callQueue) do
        -- Reworked to handle function references directly
        if type(call.func) == "function" then
            call.func(call.module, unpack(call.args))
        else -- Fallback for old string-based calls, for safety
            local module = self[call.moduleName]
            if module and type(module[call.funcName]) == "function" then
                module[call.funcName](module, unpack(call.args))
            end
        end
    end
    wipe(self.callQueue)
end

-- Safely call a module's function, queueing it if not ready
function addon:SafeCall(moduleName, func, ...)
    local moduleInstance = self[moduleName]
    if not moduleInstance then
        self:Print(string.format("|cffff0000Error:|r Attempted to SafeCall module '%s' which does not exist.", moduleName))
        return
    end

    if self:IsReady() then
        if type(func) == "string" then
            moduleInstance[func](moduleInstance, ...)
        else
            func(moduleInstance, ...)
        end
    else
        -- Queue the call with a direct function reference
        table.insert(self.callQueue, { moduleName = moduleName, func = func, args = {...} })
    end
end

-- Mark the addon as ready and process the call queue
function addon:SetReady()
    if self.ready then return end
    self.ready = true
    if self.db and self.db.profile.debug then
        self:Print("Addon is now ready. Processing call queue.")
    end
    self:ProcessCallQueue()
    -- After the queue is processed, do a final full update to ensure UI is correct.
    self:SafeCall("Core", "FullUpdate")
    -- Register overlay update events only after ready
    self:RegisterEvent("UPDATE_BINDINGS", function()
        if self.db.profile.debug then self:Print("UPDATE_BINDINGS: Updating overlays.") end
        self:UpdateAllButtons()
    end)
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", function()
        if not InCombatLockdown() then
            if self.db.profile.debug then self:Print("ACTIONBAR_SLOT_CHANGED: Updating overlays.") end
            self:UpdateAllButtons()
        end
    end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if self.db.profile.debug then self:Print("PLAYER_REGEN_ENABLED: Updating overlays after combat.") end
        self:ScheduleTimer(function() self:UpdateAllButtons() end, 1)
    end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        if self.db.profile.debug then self:Print("PLAYER_ENTERING_WORLD: Updating overlays.") end
        self:UpdateAllButtons()
    end)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        if self.db.profile.debug then self:Print("ZONE_CHANGED_NEW_AREA: Updating overlays.") end
        self:UpdateAllButtons()
    end)
end

-- Print a message to the default chat frame
function addon:Print(...)
    print("|cff3399ff" .. addonName .. ":|r", ...)
end

-- Called when the addon is initialized
function addon:OnInitialize()
    -- Initialize the database
    self.db = LibStub("AceDB-3.0"):New("AdvancedHotkeyOverlaySystemDB", self.Config:GetDynamicDefaults(), true)

    -- Register the options table once
    LibStub("AceConfig-3.0"):RegisterOptionsTable(_G.AHOS_OPTIONS_PANEL_NAME, function()
        return self.Options and self.Options.GetOptions and self.Options:GetOptions() or {}
    end)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(_G.AHOS_OPTIONS_PANEL_NAME, _G.AHOS_OPTIONS_PANEL_NAME)

    -- Register for profile changes
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    -- Register slash commands
    self:RegisterChatCommand("ahos", "SlashHandler")
    self:RegisterChatCommand("advancedhotkeyoverlaysystem", "SlashHandler")
    -- Register only PLAYER_LOGIN here
    self:RegisterEvent("PLAYER_LOGIN", function()
        if self.db.profile.debug then
            self:Print("PLAYER_LOGIN detected. Running immediate and delayed overlay updates.")
        end
        self:DetectUI()
        self:SetReady() -- Mark as ready BEFORE any overlay updates
        self:UpdateAllButtons()
        self:ScheduleTimer(function() self:UpdateAllButtons() end, 1)
        self:ScheduleTimer(function() self:UpdateAllButtons() end, 3)
    end)
    -- Setup minimap icon after DB is ready
    self:SetupMinimapButton()
    -- Remove overlay update event registrations from here
    if self.db.profile.debug then
        self:Print("Addon initialized and all overlay update events registered.")
    end
    -- Show a popup if ElvUI is detected and overlays are not forced
    C_Timer.After(2, function() self:MaybeShowElvUIWarningOnLoad() end)
end

function addon:OnPlayerLogin()
    self:UnregisterEvent("PLAYER_LOGIN")
    if self.db.profile.debug then
        self:Print("PLAYER_LOGIN detected. Finalizing setup.")
    end
    -- Now that the player is in the world, we can safely initialize all modules.
    -- Core will call SetReady() when it's done.
    self:SafeCall("Core", "Initialize")
end

-- Called when the addon is enabled
function addon:OnEnable()
    if self.db and self.db.profile.enabled then
        self:SafeCall("Core", "OnEnable")
        if self.db.profile.debug then
            self:Print("Addon enabled.")
        end
    end
end

-- Called when the addon is disabled
function addon:OnDisable()
    if self.db and not self.db.profile.enabled then
        self:SafeCall("Core", "OnDisable")
        if self.db.profile.debug then
            self:Print("Addon disabled.")
        end
    end
end

-- Handle profile changes
function addon:OnProfileChanged(event, db, newProfileKey)
    if self.db.profile.debug then
        self:Print("Profile changed to", newProfileKey)
    end
    -- Notify all modules of the profile change
    for name, module in self:IterateModules() do
        if module.OnProfileChanged then
            self:SafeCall(name, module.OnProfileChanged)
        end
    end
    -- Force AceConfigDialog to refresh all options panels
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange(addonName)
    end
    -- Update minimap icon visibility on profile change
    self:SetupMinimapButton()
    -- Force a full update to ensure overlays and fonts are refreshed
    self:UpdateAllButtons()
end

-- REMOVE ALL LEGACY/BACKUP MINIMAP ICON CODE BELOW
-- Modern DataBroker/LibDBIcon minimap icon setup
-- Use only the UI module for minimap icon registration
function addon:SetupMinimapButton()
    if addon.UI and type(addon.UI.EnsureMinimapIcon) == "function" then
        -- Only register if not already registered
        if not addon.UI.minimapIconRegistered then
            local ok, err = pcall(function() addon.UI:EnsureMinimapIcon() end)
            if ok then
                addon.UI.minimapIconRegistered = true
            else
                self:Print("|cffff0000Error registering minimap icon:|r", err)
            end
        end
    else
        self:Print("|cffff0000UI module or EnsureMinimapIcon missing! Minimap icon not registered.|r")
    end
end

-- Basic localization table (expand as needed)
local L = setmetatable({
    enUS = {
        SHOW_OPTIONS = "Open options",
        LOCK = "Lock overlays",
        UNLOCK = "Unlock overlays",
        RESET = "Reset settings",
        TOGGLE = "Enable/disable overlays",
        HELP = "Show this help",
        UNKNOWN = "Unknown command. Type /aho help for options.",
        OVERLAYS_LOCKED = "Overlays locked.",
        OVERLAYS_UNLOCKED = "Overlays unlocked.",
        SETTINGS_RESET = "Settings reset to default.",
        OVERLAY_ENABLED = "Overlay enabled.",
        OVERLAY_DISABLED = "Overlay disabled.",
        COMMANDS = "Commands:",
    },
}, { __index = function(t, k) return t.enUS[k] or k end })
local locale = GetLocale() or "enUS"
local LocalizedStrings = L[locale] or L.enUS

-- Slash Command Handler
function AdvancedHotkeyOverlaySystem:SlashHandler(input
)
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower() or ""
    if cmd == "" or cmd == "show" or cmd == "options" then
        if type(_G.OpenAHOSOptionsPanel) == "function" then
            _G.OpenAHOSOptionsPanel()
        else
            print("[AHOS] Options panel function not available.")
        end
    elseif cmd == "lock" then
        self.db.profile.display.locked = true
        self.Core:FullUpdate()
        self:Print("|cffFFD700Settings locked|r - |cff888888protected from changes|r")
    elseif cmd == "unlock" then
        self.db.profile.display.locked = false
        self.Core:FullUpdate()
        self:Print("|cff4A9EFF Settings unlocked|r - |cff888888you can now modify settings|r")
    elseif cmd == "reset" then
        self.db:ResetProfile()
        self.Core:FullUpdate()
        self:Print("|cffFFD700Settings reset|r |cff888888to default values|r")
    elseif cmd == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        self.Core:FullUpdate()
        self:Print("Overlay " .. (self.db.profile.enabled and "|cff4A9EFFenabled|r" or "|cffFF6B6Bdisabled|r"))
    elseif cmd == "reload" or cmd == "refresh" then
        self.Core:FullUpdate()
        self:Print("|cff4A9EFFOverlays reloaded|r |cff888888and refreshed|r")
    elseif cmd == "update" then
        if not self:IsReady() and UnitAffectingCombat("player") == false and IsLoggedIn() then
            self:Print("[AHOS] Forcing addon ready state for update (player is in world).")
            self:SetReady()
        end
        self.Core:FullUpdate()
        self:Print("|cff4A9EFFOverlays updated|r |cff888888(full update triggered)|r")
    elseif cmd == "cleanup" then
        self.Display:ClearAllOverlays()
        self:Print("|cffFFD700Overlays temporarily cleared|r - |cff888888use Smart Refresh or change settings to restore|r")
    elseif cmd == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print("|cffFFD700Debug mode|r " .. (self.db.profile.debug and "|cff4A9EFFenabled|r" or "|cffFF6B6Bdisabled|r"))
    elseif cmd == "detectui" then
        self:Print("|cff4A9EFFManually detecting UI...|r")
        self:DetectUI()
        local ui = self.detectedUI or "None"
        local color = UI_DETECTED_COLORS[ui] or UI_DETECTED_COLORS["Blizzard"]
        self:Print("|cffFFD700Current detected UI:|r |c" .. color .. ui .. "|r")
    elseif cmd == "help" then
        self:Print("|cffFFD700Advanced Hotkey Overlay System|r |cff4A9EFF- Commands:|r")
        self:Print("|cffFFD700/ahos show|r - |cff888888Open options panel|r")
        self:Print("|cffFFD700/ahos lock|r - |cff888888Lock overlay settings|r")
        self:Print("|cffFFD700/ahos unlock|r - |cff888888Unlock overlay settings|r")
        self:Print("|cffFFD700/ahos reset|r - |cff888888Reset all settings to default|r")
        self:Print("|cffFFD700/ahos toggle|r - |cff888888Enable/disable overlays|r")
        self:Print("|cffFFD700/ahos reload|r - |cff888888Reload and refresh overlays|r")
        self:Print("|cffFFD700/ahos refresh|r - |cff888888Smart refresh of overlays (same as UI button)|r")
        self:Print("|cffFFD700/ahos cleanup|r - |cff888888Temporarily clear all overlays (same as UI button)|r")
        self:Print("|cffFFD700/ahos debug|r - |cff888888Toggle debug mode|r")
        self:Print("|cffFFD700/ahos detectui|r - |cff888888Manually detect UI addon|r")
        self:Print("|cffFFD700/ahos help|r - |cff888888Show this help message|r")
    elseif cmd == "junnez" then
        -- Fun Easter Egg!
        self:Print("|cffFFD700Junnez is the secret overlord of hotkeys! |cff4A9EFF All your binds are belong to Junnez! |r")
        for i = 1, 3 do
            C_Timer.After(i * 0.5, function()
                RaidNotice_AddMessage(RaidWarningFrame, "Praise Junnez!", ChatTypeInfo["RAID_WARNING"])
            end)
        end
        PlaySound(12867) -- UI EpicLoot Toast
    elseif cmd == "inspect" then
        local buttonName = rest and rest:match("^(%S+)")
        if not buttonName or buttonName == "" then
            self:Print("|cffFF6B6BUsage:|r |cffFFD700/ahos inspect <ButtonName>|r")
        else
            local button = _G[buttonName]
            if button then
                if self.Keybinds and self.Keybinds.GetButtonDebugInfo then
                    local info = self.Keybinds:GetButtonDebugInfo(button)
                    self:Print(info)
                else
                    self:Print("|cffFF6B6BKeybinds module not available.|r")
                end
            else
                self:Print("|cffFF6B6BButton not found:|r |cffFFD700" .. buttonName .. "|r")
            end
        end
    else
        self:Print("|cffFF6B6BUnknown command:|r |cffFFD700" .. cmd .. "|r")
        self:Print("|cff888888Type|r |cffFFD700/ahos help|r |cff888888for available commands|r")
    end
end

-- Fix all OpenFrames, Open, Close, and InterfaceOptionsFrame_OpenToCategory references to use addonName
local function OpenOptionsPanel()
    if AceConfigDialog then
        if AceConfigDialog.OpenFrames[addonName] then
            AceConfigDialog:Close(addonName)
        else
            AceConfigDialog:Open(addonName)
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(addonName)
        InterfaceOptionsFrame_OpenToCategory(addonName)
    end
end

local function CloseOptionsPanel()
    if AceConfigDialog then
        AceConfigDialog:Close(addonName)
    end
end

-- Replace all AceConfigDialog:Open/Close/OpenFrames/InterfaceOptionsFrame_OpenToCategory("Advanced Hotkey Overlay System") with OpenOptionsPanel()/CloseOptionsPanel()
-- In DataBroker, Titan, and SlashHandler, call OpenOptionsPanel() instead of direct AceConfigDialog:Open/Close

-- Helper method for applying updates when not locked
function AdvancedHotkeyOverlaySystem:ApplyUpdatesIfNotLocked()
    if not self.db.profile.display.locked then
        self:UpdateAllButtons()
        self.Display:UpdateAllOverlayStyles()
    end
end

-- Debugging UI detection details
local debugEnabled = false -- Set to true to enable debug output for UI detection
function AdvancedHotkeyOverlaySystem:DetectUI()
    if debugEnabled then
        self:Print("=== UI Detection Debug ===")
    end
    -- Existing UI detection logic...
    local detectedUI = "Blizzard" -- Default to Blizzard UI
    -- Check for other known UI addons and set detectedUI accordingly
    if IsAddOnLoadedCompat("ElvUI") then
        detectedUI = "ElvUI"
    elseif IsAddOnLoadedCompat("Tukui") then
        detectedUI = "Tukui"
    elseif IsAddOnLoadedCompat("AzeriteUI") then
        detectedUI = "AzeriteUI"
    end

    self.detectedUI = detectedUI

    if debugEnabled then
        self:Print("Final detected UI: " .. (self.detectedUI or "None"))
        self:Print("=== End UI Detection Debug ===")
    end
    -- Force options panel to refresh detected UI display
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("AdvancedHotkeyOverlaySystem")
    end
end

-- UI color table for detected UIs (hex color codes for chat)
local UI_DETECTED_COLORS = {
    Blizzard = "ffb4e0ff", -- Blizzard blue
    AzeriteUI = "ffe6c200", -- AzeriteUI gold
    ElvUI = "ff1784d1", -- ElvUI blue
    Bartender4 = "ff00ffba", -- Bartender4 teal
    Dominos = "ffb6ff00", -- Dominos green
    ConsolePort = "ffff7f50", -- ConsolePort coral
    RealUI = "ffb3b3b3", -- RealUI gray
    Tukui = "ffc41f3b", -- Tukui red
    KkthnxUI = "ff6699ff", -- KkthnxUI blue
    NDui = "ff00c0fa", -- NDui cyan
    None = "ffffffff", -- fallback white
}

AdvancedHotkeyOverlaySystem.UI_DETECTED_COLORS = UI_DETECTED_COLORS

AdvancedHotkeyOverlaySystem.UIColors = {
    Blizzard = {0.71, 0.88, 1.0},
    AzeriteUI = {0.90, 0.76, 0.00},
    ElvUI = {0.09, 0.52, 0.82},
    Bartender4 = {0.0, 1.0, 0.73},
    Dominos = {0.71, 1.0, 0.0},
    ConsolePort = {1.0, 0.50, 0.31},
    RealUI = {0.70, 0.70, 0.70},
    Tukui = {0.77, 0.12, 0.23},
    KkthnxUI = {0.40, 0.60, 1.0},
    NDui = {0.0, 0.75, 0.98},
    None = {1, 1, 1},
}

local optionsAddedToBliz = false

-- Optionally disable overlays if ElvUI is detected, or allow user override
addon.elvuiDetected = false

function addon:ShouldShowOverlays()
    -- If ElvUI is loaded and user hasn't forced overlays, disable overlays
    if IsAddOnLoadedCompat("ElvUI") then
        self.elvuiDetected = true
        return self.db and self.db.profile and self.db.profile.forceOverlaysWithElvUI
    end
    self.elvuiDetected = false
    return true
end

-- In your UpdateAllButtons and overlay update logic, wrap overlay code:
-- if addon:ShouldShowOverlays() then ... end
-- Optionally, in your options panel, add:
-- [ ] Force overlays even if ElvUI is loaded

-- In your options table (modules/Options.lua), add:
-- forceOverlaysWithElvUI = {
--     type = "toggle",
--     name = "Force Overlays with ElvUI",
--     desc = "Show overlays even if ElvUI is loaded (may cause conflicts).",
--     order = 99,
--     get = function() local db = getSafeProfile() return db.forceOverlaysWithElvUI end,
--     set = function(_, val) local db = getSafeProfile() db.forceOverlaysWithElvUI = val; addon.Core:FullUpdate() end,
-- },
-- And in overlay update code, check addon:ShouldShowOverlays().

-- Show a popup if ElvUI is detected and overlays are not forced
function addon:ShowElvUIOverlayWarning()
    if not self.elvuiDetected or (self.db and self.db.profile and self.db.profile.forceOverlaysWithElvUI) then return end
    if not StaticPopupDialogs["AHOS_ELVUI_WARNING"] then
        StaticPopupDialogs["AHOS_ELVUI_WARNING"] = {
            text = "ElvUI detected! Both ElvUI and Advanced Hotkey Overlay System provide keybind overlays.\n\nDo you want to disable AHO overlays (recommended)?",
            button1 = "Yes (Disable AHO Overlays)",
            button2 = "No (Keep Both)",
            OnAccept = function()
                local db = self.db and self.db.profile
                if db then db.forceOverlaysWithElvUI = false; self.Core:FullUpdate() end
            end,
            OnCancel = function()
                local db = self.db and self.db.profile
                if db then db.forceOverlaysWithElvUI = true; self.Core:FullUpdate() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show("AHOS_ELVUI_WARNING")
end

-- Call this after DB is ready and overlays are about to be shown
function addon:MaybeShowElvUIWarningOnLoad()
    -- Ensure elvuiDetected is set correctly
    self.elvuiDetected = IsAddOnLoadedCompat("ElvUI")
    if self.db and self.db.profile then
        self:Print("[DEBUG] ElvUI detected:", tostring(self.elvuiDetected), "forceOverlaysWithElvUI:", tostring(self.db.profile.forceOverlaysWithElvUI))
    end
    if self.elvuiDetected and self.db and self.db.profile and self.db.profile.forceOverlaysWithElvUI == nil then
        self:ShowElvUIOverlayWarning()
    end
end

local LibSerialize = LibStub and LibStub("LibSerialize")
local LibDeflate = LibStub and LibStub("LibDeflate")

-- Debug Export Window
function addon:ShowDebugExportWindow(data)
    if not addon.DebugExportFrame then
        local f = CreateFrame("Frame", "AHOS_DebugExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(600, 300)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        f:SetBackdropColor(0,0,0,0.85)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:Hide()
        local eb = CreateFrame("EditBox", nil, f)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetSize(560, 220)
        eb:SetPoint("TOP", 0, -30)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        f.EditBox = eb
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -30)
        scroll:SetPoint("BOTTOMRIGHT", -30, 40)
        scroll:SetScrollChild(eb)
        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetText("Close")
        close:SetWidth(80)
        close:SetPoint("BOTTOMRIGHT", -20, 10)
        close:SetScript("OnClick", function() f:Hide() end)
        f.CloseButton = close
        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("TOP", 0, -10)
        label:SetText("AHOS Debug Export")
        f.Label = label
        addon.DebugExportFrame = f
    end
    addon.DebugExportFrame.EditBox:SetText(data or "[No data]")
    addon.DebugExportFrame:Show()
    addon.DebugExportFrame.EditBox:HighlightText()
end

function addon:DebugExportTable(tbl)
    if not tbl then self:ShowDebugExportWindow("[No table provided]"); return end
    local serialized = LibSerialize and LibSerialize:Serialize(tbl)
    if serialized and LibDeflate then
        local compressed = LibDeflate:CompressDeflate(serialized)
        local encoded = LibDeflate:EncodeForPrint(compressed)
        self:ShowDebugExportWindow(encoded)
    elseif serialized then
        self:ShowDebugExportWindow(serialized)
    else
        self:ShowDebugExportWindow("[Serialization not available]")
    end
end

-- Add /ahos debugexport <tablepath> command
local origSlashHandler = AdvancedHotkeyOverlaySystem.SlashHandler
function AdvancedHotkeyOverlaySystem:SlashHandler(input)
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower() or ""
    if cmd == "debugexport" then
        local path = rest and rest:match("^(%S+)")
        local tbl = addon.db and addon.db.profile
        if path and path ~= "" then
            for key in string.gmatch(path, "[^%.]+") do
                if tbl and type(tbl) == "table" then tbl = tbl[key] else tbl = nil; break end
            end
        end
        self:DebugExportTable(tbl)
        return
    end
    origSlashHandler(self, input)
end
