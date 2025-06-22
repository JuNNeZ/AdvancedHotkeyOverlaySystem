---@diagnostic disable: undefined-global
--[[
ModuleTemplate.lua - Advanced Hotkey Overlay System
-----------------------------------------------
Template for creating new modules with proper initialization 
and dependency handling.

Load Order Requirements:
1. Main addon file must be loaded
2. Core.lua must be loaded
3. Config.lua must be loaded
4. Any other required modules must be loaded first

Dependencies:
- Core module
- Config module
- AceEvent-3.0 (or other needed libraries)

Features:
- Safe initialization pattern
- Proper dependency checking
- Error handling integration
- Settings management
--]]

local addonName = "AdvancedHotkeyOverlaySystem"
local AHOS = _G[addonName]
local ModuleName = AHOS:NewModule("ModuleName", "AceEvent-3.0")

-- Cache frequently used globals
local C_Timer = C_Timer
local pairs = pairs
local string = string

-- Module state
ModuleName.enabled = false
ModuleName.ready = false

function ModuleName:OnEnable()
    if self.enabled then return end
    
    -- Wait for required modules
    local Core = AHOS:GetModule("Core")
    local Config = AHOS:GetModule("Config")
    
    if not Core.initialized or not Config.ready then
        C_Timer.After(0.1, function() self:OnEnable() end)
        return
    end
    
    -- Initialize module
    self:CompleteInitialization()
    self.enabled = true
end

function ModuleName:CompleteInitialization()
    -- Initialize settings
    self:InitializeSettings()
    
    -- Register events
    self:RegisterRequiredEvents()
    
    -- Set up any frames or UI elements
    self:SetupFrames()
    
    -- Signal ready state
    self.ready = true
    self:SendMessage("AHOS_MODULE_READY", "ModuleName")
end

function ModuleName:InitializeSettings()
    if not AHOS.db then
        C_Timer.After(0.1, function() self:InitializeSettings() end)
        return
    end
    
    -- Store reference to our settings
    self.db = AHOS.db.profile.modulename or {}
    AHOS.db.profile.modulename = self.db
    
    -- Set defaults if needed
    if not self.db.someOption then
        self.db.someOption = true
    end
end

function ModuleName:RegisterRequiredEvents()
    -- Register any events the module needs
    self:RegisterMessage("AHOS_CONFIG_UPDATED", "OnConfigUpdate")
    self:RegisterEvent("SOME_GAME_EVENT")
end

function ModuleName:SetupFrames()
    -- Create any frames or UI elements the module needs
end

-- Event handlers
function ModuleName:OnConfigUpdate()
    self:ApplySettings()
end

function ModuleName:SOME_GAME_EVENT()
    -- Handle game events
end

-- Settings application
function ModuleName:ApplySettings()
    if not self.ready then return end
    
    -- Apply settings from self.db
end

-- Public API
function ModuleName:IsReady()
    return self.ready
end

function ModuleName:GetSetting(key)
    return self.db[key]
end

-- Cleanup
function ModuleName:OnDisable()
    self.enabled = false
    self.ready = false
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
end
