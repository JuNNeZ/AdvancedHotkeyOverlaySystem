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

-- Known UI addons to check
local uiAddons = {
    ["ElvUI"] = "ElvUI",
    ["AzeriteUI"] = "AzeriteUI",
    ["GW2_UI"] = "GW2 UI",
    ["KkthnxUI"] = "KkthnxUI",
    ["SpartanUI"] = "SpartanUI",
    ["TukUI"] = "TukUI"
}

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
            outline = true,
        },
        bars = {},
        performance = {},
        debug = false,
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
    
    -- Detect UI addons
    self:DetectUserInterface()
    
    -- Initialize settings
    self:InitializeSettings()
    
    -- Signal ready state
    self:BroadcastConfigReady()
end

function Config:DetectUserInterface()
    if self.uiDetected then return end
    
    -- Check for known UI addons
    for addonName, uiName in pairs(uiAddons) do
        if IsAddOnLoaded(addonName) then
            self.detectedUI = uiName
            addon.detectedUI = uiName
            addon:Print(string.format("Detected UI: %s", uiName))
            break
        end
    end
    
    -- Debug: List all loaded addons if debug is enabled
    if self.db and self.db.profile and self.db.profile.debug then
        addon:Print("=== UI Detection Debug ===")
        
        -- Check if specific UI detection indicators are present
        addon:Print("Checking UI indicators:")
        addon:Print("- AzeriteUI loaded: " .. tostring(IsAddOnLoaded("AzeriteUI")))
        addon:Print("- Azerite loaded: " .. tostring(IsAddOnLoaded("Azerite")))
        addon:Print("- AzUI loaded: " .. tostring(IsAddOnLoaded("AzUI")))
        addon:Print("- AzUI_Color_Picker loaded: " .. tostring(IsAddOnLoaded("AzUI_Color_Picker")))
        addon:Print("- ElvUI loaded: " .. tostring(IsAddOnLoaded("ElvUI")))
        addon:Print("- Global AzeriteUI exists: " .. tostring(rawget(_G, "AzeriteUI") ~= nil))
        addon:Print("- Global ElvUI exists: " .. tostring(rawget(_G, "ElvUI") ~= nil))
        
        local loadedAddons = {}
        for i = 1, GetNumAddOns() do
            if IsAddOnLoaded(i) then
                local folderName = select(2, GetAddOnInfo(i)) or "Unknown"
                local title = GetAddOnMetadata(i, "Title") or folderName
                if folderName:lower():find("azer") or folderName:lower():find("azui") or 
                   title:lower():find("azer") or title:lower():find("azui") then
                    table.insert(loadedAddons, folderName .. " (" .. title .. ") [AZERITE RELATED]")
                else
                    table.insert(loadedAddons, folderName .. " (" .. title .. ")")
                end
            end
        end
        addon:Print("All loaded addons: " .. table.concat(loadedAddons, ", "))
    end
    
    -- Check for AzeriteUI with multiple possible names and detection methods
    if IsAddOnLoaded("AzeriteUI") or IsAddOnLoaded("Azerite") or IsAddOnLoaded("AzUI") or 
       rawget(_G, "AzeriteUI") or rawget(_G, "Azerite") or rawget(_G, "AzUI") or
       IsAddOnLoaded("AzUI_Color_Picker") then  -- Detect via related addons
        self.detectedUI = "AzeriteUI"
        addon.detectedUI = "AzeriteUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: AzeriteUI")
        end
    elseif IsAddOnLoaded("ElvUI") or rawget(_G, "ElvUI") then
        self.detectedUI = "ElvUI"
        addon.detectedUI = "ElvUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: ElvUI")
        end
    elseif IsAddOnLoaded("Tukui") or rawget(_G, "Tukui") then
        self.detectedUI = "Tukui"
        addon.detectedUI = "Tukui"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: Tukui")
        end
    elseif IsAddOnLoaded("LUI") or rawget(_G, "LUI") then
        self.detectedUI = "LUI"
        addon.detectedUI = "LUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: LUI")
        end
    elseif IsAddOnLoaded("SpartanUI") or rawget(_G, "SpartanUI") then
        self.detectedUI = "SpartanUI"
        addon.detectedUI = "SpartanUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: SpartanUI")
        end
    elseif IsAddOnLoaded("SyncUI") or rawget(_G, "SyncUI") then
        self.detectedUI = "SyncUI"
        addon.detectedUI = "SyncUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: SyncUI")
        end
    elseif IsAddOnLoaded("SuperVillainUI") or rawget(_G, "SuperVillainUI") then
        self.detectedUI = "SuperVillainUI"
        addon.detectedUI = "SuperVillainUI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: SuperVillainUI")
        end
    elseif IsAddOnLoaded("GW2_UI") or rawget(_G, "GW2_UI") then
        self.detectedUI = "GW2_UI"
        addon.detectedUI = "GW2_UI"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: GW2_UI")
        end  
    elseif IsAddOnLoaded("Bartender4") or rawget(_G, "Bartender4") then
        self.detectedUI = "Bartender4"
        addon.detectedUI = "Bartender4"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: Bartender4")
        end
    elseif IsAddOnLoaded("Dominos") or rawget(_G, "Dominos") then
        self.detectedUI = "Dominos"
        addon.detectedUI = "Dominos"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: Dominos")
        end
    else
        self.detectedUI = "Blizzard"
        addon.detectedUI = "Blizzard"
        if self.db and self.db.profile and self.db.profile.debug then
            addon:Print("UI Detected: Blizzard (default)")
        end
    end
    
    if self.db and self.db.profile and self.db.profile.debug then
        addon:Print("Final detected UI: " .. (addon.detectedUI or "None"))
        addon:Print("=== End UI Detection Debug ===")
    end
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

    -- Apply settings based on detected UI
    if self.detectedUI == "AzeriteUI" then
        db.display.xOffset = -18  -- Adjusted for AzeriteUI button positioning
        db.display.yOffset = -2
        db.display.scale = 0.9
    elseif self.detectedUI == "ElvUI" then
        db.display.xOffset = -20
        db.display.yOffset = -4
        db.display.scale = 0.85
    end
    
    -- Note: Changes are automatically saved since db is a reference to the profile
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
addon.UIColors = {
    AzeriteUI = {0.25, 0.78, 0.92},      -- Cyan
    ElvUI = {0.51, 0.85, 0.98},         -- Light blue
    Tukui = {1.00, 0.60, 0.00},         -- Orange
    LUI = {0.60, 0.20, 0.80},           -- Purple
    SpartanUI = {0.20, 0.80, 0.20},     -- Green
    SyncUI = {0.90, 0.90, 0.90},        -- Light gray
    SuperVillainUI = {1.00, 0.85, 0.00},-- Yellow
    GW2_UI = {0.80, 0.10, 0.10},        -- Red
    Bartender4 = {0.00, 0.60, 1.00},    -- Blue
    Dominos = {0.00, 0.80, 0.60},       -- Teal
    Blizzard = {1.00, 1.00, 1.00},      -- White
}

-- Helper to get the color for the detected UI
function Config:GetUIColor()
    return addon.UIColors[addon.detectedUI or "Blizzard"] or {1, 1, 1}
end
