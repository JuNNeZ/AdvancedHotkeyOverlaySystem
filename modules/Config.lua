---@diagnostic disable: undefined-global
--[[
Config.lua - Advanced Hotkey Overlay System
-----------------------------------------
Handles configuration management and UI detection.
This module MUST load after Core.lua but before other feature modules.

Load Order Requirements:
1. Main addon file must be loaded
2. Core.lua must be loaded
3. This file loads third
4. Feature modules depend on this one

Dependencies:
- Core module
- AceEvent-3.0

State Management:
- Initializes after Core module
- Provides UI detection results
- Manages default configurations
- Broadcasts AHOS_CONFIG_READY when ready

Other modules should:
1. Wait for AHOS_CONFIG_READY message
2. Access settings through their module.db reference
3. Use the safe initialization pattern
--]]

local addonName, privateScope = ...
local addon = privateScope.addon
local Config = addon.Config

-- Cache frequently used globals
local IsAddOnLoaded = select(4, GetBuildInfo()) >= 100000 and C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetBuildInfo = GetBuildInfo
local C_Timer = C_Timer
local pairs = pairs
local string = string

-- Module state
Config.ready = false
Config.uiDetected = false
Config._finalized = false

-- Font path fix
local DEFAULT_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local LibSharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)

function Config:GetAvailableFonts()
    local fonts = {
        ["Default"] = DEFAULT_FONT,
        ["FrizQT"] = "Fonts\\FRIZQT__.TTF",
        ["ArialN"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
    }
    if LibSharedMedia then
        for name, path in pairs(LibSharedMedia:HashTable("font")) do
            fonts[name] = path
        end
    end
    return fonts
end

function Config:GetFontList()
    local fonts = self:GetAvailableFonts()
    local list = {}
    for k, _ in pairs(fonts) do list[#list+1] = k end
    table.sort(list)
    return list
end

function Config:GetFontPath(name)
    return self:GetAvailableFonts()[name] or DEFAULT_FONT
end

function Config:GetDefaultProfile()
    return {
        enabled = true,
        autoDetectUI = true,
        display = {
            strata = "HIGH",            anchor = "TOP",
            xOffset = -22,
            yOffset = -3,
            scale = 0.95,
            alpha = 1,
            hideOriginal = true,
            smartPositioning = true,
            border = "none",
            borderColor = {0,0,0,1},
            borderSize = 1,
            locked = false,
            -- Overlay vs native text behavior
            nativeRewrite = false,         -- Global: rewrite native hotkey FS instead of overlay
            dominosRewrite = false,        -- Dominos-only override for rewrite (overlay is default)
            autoNativeFallback = true,     -- If overlay seems hidden, auto-fallback to native per-button
            followNativeHotkeyStyle = false, -- Let overlay mirror native hotkey font/positioning
            frameLevel = 10,               -- Base overlay frame level (fine-tune in Options)
        },
        text = {
            fontSize = 16,
            font = "Default",
            color = {1, 1, 1},
            shadowEnabled = true,
            shadowOffset = {1, -1},
            abbreviations = true,
            maxLength = 6,
            customAbbreviations = {},
            outline = true,               -- legacy boolean
            outlineStyle = "OUTLINE",    -- new style flags (NONE, OUTLINE, THICKOUTLINE, MONOCHROME, MONOCHROME,OUTLINE, MONOCHROME,THICKOUTLINE)
        },
        bars = {},
        performance = {},
        debug = false,
        troubleshootingTools = false,
    }
end

function Config:GetDynamicDefaults()
    local defaults = { profile = self:GetDefaultProfile() }
    -- UI detection will be set after PLAYER_LOGIN
    return defaults
end

function Config:OnEnable()
    -- Defer initialization until the addon is ready
    addon:SafeCall("Config", "Initialize")
end

function Config:Initialize()
    if self.ready then return end
    if addon.db.profile.debug then
        addon:Print("Config:Initialize running.")
    end

    -- Initialize state
    self.detectedUI = "Blizzard"  -- Default UI
    addon.detectedUI = self.detectedUI
    
    -- Register events
    self:RegisterMessage("AHOS_REFRESH_CONFIG", "OnConfigRefresh")
    -- Detect incrementally as addons load; finalize once when player logs in
    self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
    
    -- Initialize settings
    self:InitializeSettings()
    
    -- Signal ready state
    self:BroadcastConfigReady()
end

function Config:DetectUserInterface()
    if self._finalized then return end

    -- Debug: List all loaded addons if debug is enabled
    if self.db and self.db.profile and self.db.profile.debug then
        addon:Print("=== Provider Detection Debug ===")
        local loadedAddons = {}
        for i = 1, GetNumAddOns() do
            if IsAddOnLoaded(i) then
                local folderName = select(2, GetAddOnInfo(i)) or "Unknown"
                local title = GetAddOnMetadata(i, "Title") or folderName
                table.insert(loadedAddons, folderName .. " (" .. title .. ")")
            end
        end
        addon:Print("All loaded addons: " .. table.concat(loadedAddons, ", "))
    end

    self.detectedUI = addon:DetectUI() or "Blizzard"
    addon.detectedUI = self.detectedUI

    if self.db and self.db.profile and self.db.profile.debug then
        addon:Print("Final detected provider: " .. addon:GetDetectedProviderText())
        addon:Print("=== End Provider Detection Debug ===")
    end
end

function Config:OnAddonLoaded(_, name)
    if self._finalized then return end
    for key, provider in pairs(addon.ProviderRegistry or {}) do
        if provider.addon == name and not provider.conflict_only then
            self.detectedUI = key
            addon.detectedUI = key
            break
        end
    end
end

function Config:OnPlayerLogin()
    if self._finalized then return end
    -- Final pass in case ADDON_LOADED didn't pick a UI
    self:DetectUserInterface()
    self._finalized = true
    self:UnregisterEvent("ADDON_LOADED")
    self:UnregisterEvent("PLAYER_LOGIN")
end

function Config:InitializeSettings()
    -- Ensure we have access to the db (guaranteed by SafeCall)
    assert(addon.db and addon.db.profile, "addon.db not available in Config:InitializeSettings")
    
    -- Store reference to our settings
    self.db = addon.db.profile.config or {}
    addon.db.profile.config = self.db
    
    -- Apply UI-specific settings
    self:ApplyUISettings()
end

function Config:ApplyUISettings()    local db = addon.db.profile
    local provider = addon:GetProviderInfo(self.detectedUI)
    local offsets = provider and provider.defaultOffsets
    if offsets then
        db.display.xOffset = offsets.xOffset
        db.display.yOffset = offsets.yOffset
        db.display.scale = offsets.scale
    end
end

function Config:BroadcastConfigReady()
    self.ready = true
    self:SendMessage("AHOS_CONFIG_READY")
    if addon.db.profile.debug then
        addon:Print("Config ready. Broadcasting AHOS_CONFIG_READY.")
    end
end

function Config:OnConfigRefresh()
    self:DetectUserInterface()
    self:ApplyUISettings()
    self:SendMessage("AHOS_CONFIG_UPDATED")
end

-- API for other modules
function Config:GetDetectedUI()
    return self.detectedUI
end

function Config:IsUIDetected()
    return self.uiDetected
end

-- UI-specific color table for overlays
addon.UIColors = setmetatable({}, {
    __index = function(_, key)
        return addon:GetProviderColor(key)
    end,
})

-- Helper to get the color for the detected UI
function Config:GetUIColor()
    return addon.UIColors[addon.detectedUI or "Blizzard"] or {1, 1, 1}
end
