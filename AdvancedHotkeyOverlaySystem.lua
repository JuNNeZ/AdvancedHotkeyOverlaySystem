---@diagnostic disable: undefined-global
--[[
Advanced Hotkey Overlay System - Advanced Hotkey Overlay System
==========================================

Description:
------------
This module provides the Advanced Hotkey Overlay System for World of Warcraft action bars. 
It addresses several issues found in previous implementations, including:

- Proper restoration of original hotkey text when the overlay is cleaned up.
- Improved abbreviation system for hotkey labels (e.g., "SHIFT-BUTTON3" is now abbreviated as "SMB3" instead of "SMMB").
- Accurate detection and handling of ActionBar1 and ActionBar3.
- Fixes for memory leaks and ensures overlays are properly restored.

Usage:
------
Place this file in your AddOn's directory and ensure it is loaded by your AddOn's .toc file.
The system will automatically manage hotkey overlays and abbreviations for supported action bars.
--]]

-------------------------------------------------------------------------------
-- 1. Addon Initialization and Library Setup
-------------------------------------------------------------------------------
local ADDON_NAME = "AdvancedHotkeyOverlay"
local ADDON_VERSION = "1.3.2"
local AdvancedHotkeyOverlaySystem = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

-------------------------------------------------------------------------------
-- 2. Module Tables
-------------------------------------------------------------------------------
AdvancedHotkeyOverlaySystem.Display = {}
AdvancedHotkeyOverlaySystem.Keybinds = {}
AdvancedHotkeyOverlaySystem.Bars = {}
AdvancedHotkeyOverlaySystem.Performance = {}

-------------------------------------------------------------------------------
-- 3. Memory Management
-------------------------------------------------------------------------------
local trackedButtons = setmetatable({}, { __mode = "k" })
local originalSetTextFunctions = setmetatable({}, { __mode = "k" })
local originalHotkeyText = setmetatable({}, { __mode = "k" })
-- local eventBatchQueue = {}
local lastUpdateTime = 0

-------------------------------------------------------------------------------
-- 4. Keybind Abbreviation System
-------------------------------------------------------------------------------
local KEYBIND_ABBREVIATIONS = {
    -- Full mouse button names (do these first)
    ['Middle Mouse'] = 'MB3',
    ['Mouse Button 4'] = 'MB4',
    ['Mouse Button 5'] = 'MB5',
    ['Mouse Wheel Up'] = 'MWU',
    ['Mouse Wheel Down'] = 'MWD',
    
    -- Short mouse button names  
    ['BUTTON1'] = 'MB1',
    ['BUTTON2'] = 'MB2',
    ['BUTTON3'] = 'MB3',
    ['BUTTON4'] = 'MB4',
    ['BUTTON5'] = 'MB5',
    ['MOUSEWHEELUP'] = 'MWU',
    ['MOUSEWHEELDOWN'] = 'MWD',
    
    -- Modifiers (do these after mouse buttons)
    ['SHIFT%-'] = 'S',
    ['CTRL%-'] = 'C',
    ['ALT%-'] = 'A',
    
    -- Special keys
    ['SPACE'] = 'SPC',
    ['NUMPADENTER'] = 'NE',
    ['ENTER'] = 'ENT',
    ['ESCAPE'] = 'ESC',
    
    -- Function keys remain as-is
    ['F1'] = 'F1', ['F2'] = 'F2', ['F3'] = 'F3', ['F4'] = 'F4',
    ['F5'] = 'F5', ['F6'] = 'F6', ['F7'] = 'F7', ['F8'] = 'F8',
    ['F9'] = 'F9', ['F10'] = 'F10', ['F11'] = 'F11', ['F12'] = 'F12',
}

-------------------------------------------------------------------------------
-- 5. Font Handling
-------------------------------------------------------------------------------
-- Font path fix
local DEFAULT_FONT = STANDARD_TEXT_FONT or "Fonts/FRIZQT__.TTF"

local LibSharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetAvailableFonts()
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

local function GetFontList()
    local fonts = GetAvailableFonts()
    local list = {}
    for k, _ in pairs(fonts) do list[#list+1] = k end
    table.sort(list)
    return list
end

local function GetFontPath(name)
    return GetAvailableFonts()[name] or DEFAULT_FONT
end

-------------------------------------------------------------------------------
-- 6. Default Profile and Dynamic Defaults
-------------------------------------------------------------------------------
local function GetDefaultProfile()
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
        debug = false,  -- Can be enabled via /ahos debug command
    }
end

-- Patch GetDynamicDefaults to use GetDefaultProfile
local function GetDynamicDefaults()
    local defaults = { profile = GetDefaultProfile() }
    -- UI detection will be set after PLAYER_LOGIN
    return defaults
end

function AdvancedHotkeyOverlaySystem:DetectUI()
    local debugEnabled = self.db and self.db.profile and self.db.profile.debug
      -- Debug: List all loaded addons if debug is enabled
    if debugEnabled then
        self:Print("=== UI Detection Debug ===")
        
        -- Check if specific UI detection indicators are present
        self:Print("Checking UI indicators:")
        self:Print("- AzeriteUI loaded: " .. tostring(IsAddOnLoaded("AzeriteUI")))
        self:Print("- Azerite loaded: " .. tostring(IsAddOnLoaded("Azerite")))
        self:Print("- AzUI loaded: " .. tostring(IsAddOnLoaded("AzUI")))
        self:Print("- AzUI_Color_Picker loaded: " .. tostring(IsAddOnLoaded("AzUI_Color_Picker")))
        self:Print("- ElvUI loaded: " .. tostring(IsAddOnLoaded("ElvUI")))
        self:Print("- Global AzeriteUI exists: " .. tostring(rawget(_G, "AzeriteUI") ~= nil))
        self:Print("- Global ElvUI exists: " .. tostring(rawget(_G, "ElvUI") ~= nil))
        
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
        self:Print("All loaded addons: " .. table.concat(loadedAddons, ", "))
    end
      -- Check for AzeriteUI with multiple possible names and detection methods
    if IsAddOnLoaded("AzeriteUI") or IsAddOnLoaded("Azerite") or IsAddOnLoaded("AzUI") or 
       rawget(_G, "AzeriteUI") or rawget(_G, "Azerite") or rawget(_G, "AzUI") or
       IsAddOnLoaded("AzUI_Color_Picker") then  -- Detect via related addons
        self.detectedUI = "AzeriteUI"
        if debugEnabled then
            self:Print("UI Detected: AzeriteUI")
        end
    elseif IsAddOnLoaded("ElvUI") or rawget(_G, "ElvUI") then
        self.detectedUI = "ElvUI"
        if debugEnabled then
            self:Print("UI Detected: ElvUI")
        end
    elseif IsAddOnLoaded("Tukui") or rawget(_G, "Tukui") then
        self.detectedUI = "Tukui"
        if debugEnabled then
            self:Print("UI Detected: Tukui")
        end
    elseif IsAddOnLoaded("LUI") or rawget(_G, "LUI") then
        self.detectedUI = "LUI"
        if debugEnabled then
            self:Print("UI Detected: LUI")
        end
    elseif IsAddOnLoaded("SpartanUI") or rawget(_G, "SpartanUI") then
        self.detectedUI = "SpartanUI"
        if debugEnabled then
            self:Print("UI Detected: SpartanUI")
        end
    elseif IsAddOnLoaded("SyncUI") or rawget(_G, "SyncUI") then
        self.detectedUI = "SyncUI"
        if debugEnabled then
            self:Print("UI Detected: SyncUI")
        end
    elseif IsAddOnLoaded("SuperVillainUI") or rawget(_G, "SuperVillainUI") then
        self.detectedUI = "SuperVillainUI"
        if debugEnabled then
            self:Print("UI Detected: SuperVillainUI")
        end
    elseif IsAddOnLoaded("GW2_UI") or rawget(_G, "GW2_UI") then
        self.detectedUI = "GW2_UI"
        if debugEnabled then
            self:Print("UI Detected: GW2_UI")
        end  
    elseif IsAddOnLoaded("Bartender4") or rawget(_G, "Bartender4") then
        self.detectedUI = "Bartender4"
        if debugEnabled then
            self:Print("UI Detected: Bartender4")
        end
    elseif IsAddOnLoaded("Dominos") or rawget(_G, "Dominos") then
        self.detectedUI = "Dominos"
        if debugEnabled then
            self:Print("UI Detected: Dominos")
        end
    else
        self.detectedUI = "Blizzard"
        if debugEnabled then
            self:Print("UI Detected: Blizzard (default)")
        end
    end
    
    if debugEnabled then
        self:Print("Final detected UI: " .. (self.detectedUI or "None"))
        self:Print("=== End UI Detection Debug ===")
    end
end

-- UI-specific color table for overlays
AdvancedHotkeyOverlaySystem.UIColors = {
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
function AdvancedHotkeyOverlaySystem:GetUIColor()
    return self.UIColors[self.detectedUI or "Blizzard"] or {1, 1, 1}
end

-------------------------------------------------------------------------------
-- 7. Keybinds Module
-------------------------------------------------------------------------------
--[[
MODULE: Keybinds - Fixed abbreviation system
]]
function AdvancedHotkeyOverlaySystem.Keybinds:AbbreviateKeybind(keybind)
    if not keybind or keybind == "" then return "" end
    if not AdvancedHotkeyOverlaySystem.db or not AdvancedHotkeyOverlaySystem.db.profile.text.abbreviations then return keybind end

    local abbreviated = keybind:upper()

    -- ConsolePort-style mouse button abbreviations
    abbreviated = abbreviated:gsub("BUTTON3", "B3")
    abbreviated = abbreviated:gsub("BUTTON4", "B4")
    abbreviated = abbreviated:gsub("BUTTON5", "B5")
    abbreviated = abbreviated:gsub("MOUSE BUTTON 3", "B3")
    abbreviated = abbreviated:gsub("MOUSE BUTTON 4", "B4")
    abbreviated = abbreviated:gsub("MOUSE BUTTON 5", "B5")
    abbreviated = abbreviated:gsub("MIDDLE MOUSE", "B3")
    abbreviated = abbreviated:gsub("MOUSEWHEELUP", "MWU")
    abbreviated = abbreviated:gsub("MOUSEWHEELDOWN", "MWD")

    -- Modifiers: remove dashes and collapse order
    abbreviated = abbreviated:gsub("SHIFT%-", "S")
    abbreviated = abbreviated:gsub("CTRL%-", "C")
    abbreviated = abbreviated:gsub("ALT%-", "A")

    -- Collapse multiple modifiers (e.g., SCA3)
    abbreviated = abbreviated:gsub("^([SCA]+)([B%dFMW]+)", "%1%2")

    -- Special keys
    abbreviated = abbreviated:gsub("SPACE", "SPC")
    abbreviated = abbreviated:gsub("NUMPADENTER", "NE")
    abbreviated = abbreviated:gsub("ENTER", "ENT")
    abbreviated = abbreviated:gsub("ESCAPE", "ESC")

    -- Remove any remaining dashes
    abbreviated = abbreviated:gsub("%-", "")

    -- Truncate if needed
    local maxLength = AdvancedHotkeyOverlaySystem.db.profile.text.maxLength
    if #abbreviated > maxLength and maxLength > 0 then
        abbreviated = abbreviated:sub(1, maxLength)
    end

    return abbreviated
end

function AdvancedHotkeyOverlaySystem.Keybinds:GetButtonBindingCommand(button)
    local buttonName = button:GetName()
    if not buttonName then return nil end
    
    -- Complete binding map for all action bars
    local bindingMap = {
        -- Main action bar (ActionButton1-12)
        ActionButton1 = "ACTIONBUTTON1", ActionButton2 = "ACTIONBUTTON2",
        ActionButton3 = "ACTIONBUTTON3", ActionButton4 = "ACTIONBUTTON4",
        ActionButton5 = "ACTIONBUTTON5", ActionButton6 = "ACTIONBUTTON6",
        ActionButton7 = "ACTIONBUTTON7", ActionButton8 = "ACTIONBUTTON8",
        ActionButton9 = "ACTIONBUTTON9", ActionButton10 = "ACTIONBUTTON10",
        ActionButton11 = "ACTIONBUTTON11", ActionButton12 = "ACTIONBUTTON12",        
        -- AzeriteUI Main Action Bar (maps to same bindings as ActionButton)
        AzeriteActionBar1Button1 = "ACTIONBUTTON1", AzeriteActionBar1Button2 = "ACTIONBUTTON2",
        AzeriteActionBar1Button3 = "ACTIONBUTTON3", AzeriteActionBar1Button4 = "ACTIONBUTTON4",
        AzeriteActionBar1Button5 = "ACTIONBUTTON5", AzeriteActionBar1Button6 = "ACTIONBUTTON6",
        AzeriteActionBar1Button7 = "ACTIONBUTTON7", AzeriteActionBar1Button8 = "ACTIONBUTTON8",
        AzeriteActionBar1Button9 = "ACTIONBUTTON9", AzeriteActionBar1Button10 = "ACTIONBUTTON10",
        AzeriteActionBar1Button11 = "ACTIONBUTTON11", AzeriteActionBar1Button12 = "ACTIONBUTTON12",
        
        -- Legacy naming (keep for compatibility)
        AzeriteActionBarButton1 = "ACTIONBUTTON1", AzeriteActionBarButton2 = "ACTIONBUTTON2",
        AzeriteActionBarButton3 = "ACTIONBUTTON3", AzeriteActionBarButton4 = "ACTIONBUTTON4",
        AzeriteActionBarButton5 = "ACTIONBUTTON5", AzeriteActionBarButton6 = "ACTIONBUTTON6",
        AzeriteActionBarButton7 = "ACTIONBUTTON7", AzeriteActionBarButton8 = "ACTIONBUTTON8",
        AzeriteActionBarButton9 = "ACTIONBUTTON9", AzeriteActionBarButton10 = "ACTIONBUTTON10",
        AzeriteActionBarButton11 = "ACTIONBUTTON11", AzeriteActionBarButton12 = "ACTIONBUTTON12",
        
        -- Bottom Left Bar (MultiBarBottomLeft - this is ActionBar3 in the interface)
        MultiBarBottomLeftButton1 = "MULTIACTIONBAR1BUTTON1",
        MultiBarBottomLeftButton2 = "MULTIACTIONBAR1BUTTON2",
        MultiBarBottomLeftButton3 = "MULTIACTIONBAR1BUTTON3",
        MultiBarBottomLeftButton4 = "MULTIACTIONBAR1BUTTON4",
        MultiBarBottomLeftButton5 = "MULTIACTIONBAR1BUTTON5",
        MultiBarBottomLeftButton6 = "MULTIACTIONBAR1BUTTON6",
        MultiBarBottomLeftButton7 = "MULTIACTIONBAR1BUTTON7",
        MultiBarBottomLeftButton8 = "MULTIACTIONBAR1BUTTON8",
        MultiBarBottomLeftButton9 = "MULTIACTIONBAR1BUTTON9",
        MultiBarBottomLeftButton10 = "MULTIACTIONBAR1BUTTON10",
        MultiBarBottomLeftButton11 = "MULTIACTIONBAR1BUTTON11",
        MultiBarBottomLeftButton12 = "MULTIACTIONBAR1BUTTON12",
        
        -- AzeriteUI ActionBar2 (maps to MultiActionBar1)
        AzeriteActionBar2Button1 = "MULTIACTIONBAR1BUTTON1",
        AzeriteActionBar2Button2 = "MULTIACTIONBAR1BUTTON2",
        AzeriteActionBar2Button3 = "MULTIACTIONBAR1BUTTON3",
        AzeriteActionBar2Button4 = "MULTIACTIONBAR1BUTTON4",
        AzeriteActionBar2Button5 = "MULTIACTIONBAR1BUTTON5",
        AzeriteActionBar2Button6 = "MULTIACTIONBAR1BUTTON6",
        AzeriteActionBar2Button7 = "MULTIACTIONBAR1BUTTON7",
        AzeriteActionBar2Button8 = "MULTIACTIONBAR1BUTTON8",
        AzeriteActionBar2Button9 = "MULTIACTIONBAR1BUTTON9",
        AzeriteActionBar2Button10 = "MULTIACTIONBAR1BUTTON10",
        AzeriteActionBar2Button11 = "MULTIACTIONBAR1BUTTON11",
        AzeriteActionBar2Button12 = "MULTIACTIONBAR1BUTTON12",
        
        -- Bottom Right Bar (MultiBarBottomRight - this is ActionBar2 in the interface)
        MultiBarBottomRightButton1 = "MULTIACTIONBAR2BUTTON1",
        MultiBarBottomRightButton2 = "MULTIACTIONBAR2BUTTON2",
        MultiBarBottomRightButton3 = "MULTIACTIONBAR2BUTTON3",
        MultiBarBottomRightButton4 = "MULTIACTIONBAR2BUTTON4",
        MultiBarBottomRightButton5 = "MULTIACTIONBAR2BUTTON5",
        MultiBarBottomRightButton6 = "MULTIACTIONBAR2BUTTON6",
        MultiBarBottomRightButton7 = "MULTIACTIONBAR2BUTTON7",
        MultiBarBottomRightButton8 = "MULTIACTIONBAR2BUTTON8",
        MultiBarBottomRightButton9 = "MULTIACTIONBAR2BUTTON9",
        MultiBarBottomRightButton10 = "MULTIACTIONBAR2BUTTON10",
        MultiBarBottomRightButton11 = "MULTIACTIONBAR2BUTTON11",
        MultiBarBottomRightButton12 = "MULTIACTIONBAR2BUTTON12",
        
        -- AzeriteUI ActionBar3 (maps to MultiActionBar2)
        AzeriteActionBar3Button1 = "MULTIACTIONBAR2BUTTON1",
        AzeriteActionBar3Button2 = "MULTIACTIONBAR2BUTTON2",
        AzeriteActionBar3Button3 = "MULTIACTIONBAR2BUTTON3",
        AzeriteActionBar3Button4 = "MULTIACTIONBAR2BUTTON4",
        AzeriteActionBar3Button5 = "MULTIACTIONBAR2BUTTON5",
        AzeriteActionBar3Button6 = "MULTIACTIONBAR2BUTTON6",
        AzeriteActionBar3Button7 = "MULTIACTIONBAR2BUTTON7",
        AzeriteActionBar3Button8 = "MULTIACTIONBAR2BUTTON8",
        AzeriteActionBar3Button9 = "MULTIACTIONBAR2BUTTON9",
        AzeriteActionBar3Button10 = "MULTIACTIONBAR2BUTTON10",
        AzeriteActionBar3Button11 = "MULTIACTIONBAR2BUTTON11",
        AzeriteActionBar3Button12 = "MULTIACTIONBAR2BUTTON12",
        
        -- Right Bar (MultiBarRight - this is ActionBar4 in the interface)
        MultiBarRightButton1 = "MULTIACTIONBAR3BUTTON1",
        MultiBarRightButton2 = "MULTIACTIONBAR3BUTTON2",
        MultiBarRightButton3 = "MULTIACTIONBAR3BUTTON3",
        MultiBarRightButton4 = "MULTIACTIONBAR3BUTTON4",
        MultiBarRightButton5 = "MULTIACTIONBAR3BUTTON5",
        MultiBarRightButton6 = "MULTIACTIONBAR3BUTTON6",
        MultiBarRightButton7 = "MULTIACTIONBAR3BUTTON7",
        MultiBarRightButton8 = "MULTIACTIONBAR3BUTTON8",
        MultiBarRightButton9 = "MULTIACTIONBAR3BUTTON9",
        MultiBarRightButton10 = "MULTIACTIONBAR3BUTTON10",
        MultiBarRightButton11 = "MULTIACTIONBAR3BUTTON11",
        MultiBarRightButton12 = "MULTIACTIONBAR3BUTTON12",
        
        -- AzeriteUI ActionBar4 (maps to MultiActionBar3)
        AzeriteActionBar4Button1 = "MULTIACTIONBAR3BUTTON1",
        AzeriteActionBar4Button2 = "MULTIACTIONBAR3BUTTON2",
        AzeriteActionBar4Button3 = "MULTIACTIONBAR3BUTTON3",
        AzeriteActionBar4Button4 = "MULTIACTIONBAR3BUTTON4",
        AzeriteActionBar4Button5 = "MULTIACTIONBAR3BUTTON5",
        AzeriteActionBar4Button6 = "MULTIACTIONBAR3BUTTON6",
        AzeriteActionBar4Button7 = "MULTIACTIONBAR3BUTTON7",
        AzeriteActionBar4Button8 = "MULTIACTIONBAR3BUTTON8",
        AzeriteActionBar4Button9 = "MULTIACTIONBAR3BUTTON9",
        AzeriteActionBar4Button10 = "MULTIACTIONBAR3BUTTON10",
        AzeriteActionBar4Button11 = "MULTIACTIONBAR3BUTTON11",
        AzeriteActionBar4Button12 = "MULTIACTIONBAR3BUTTON12",
        
        -- Left Bar (MultiBarLeft - this is ActionBar5 in the interface)
        MultiBarLeftButton1 = "MULTIACTIONBAR4BUTTON1",
        MultiBarLeftButton2 = "MULTIACTIONBAR4BUTTON2",
        MultiBarLeftButton3 = "MULTIACTIONBAR4BUTTON3",
        MultiBarLeftButton4 = "MULTIACTIONBAR4BUTTON4",
        MultiBarLeftButton5 = "MULTIACTIONBAR4BUTTON5",
        MultiBarLeftButton6 = "MULTIACTIONBAR4BUTTON6",
        MultiBarLeftButton7 = "MULTIACTIONBAR4BUTTON7",
        MultiBarLeftButton8 = "MULTIACTIONBAR4BUTTON8",
        MultiBarLeftButton9 = "MULTIACTIONBAR4BUTTON9",
        MultiBarLeftButton10 = "MULTIACTIONBAR4BUTTON10",
        MultiBarLeftButton11 = "MULTIACTIONBAR4BUTTON11",
        MultiBarLeftButton12 = "MULTIACTIONBAR4BUTTON12",
        
        -- AzeriteUI ActionBar5 (maps to MultiActionBar4)
        AzeriteActionBar5Button1 = "MULTIACTIONBAR4BUTTON1",
        AzeriteActionBar5Button2 = "MULTIACTIONBAR4BUTTON2",
        AzeriteActionBar5Button3 = "MULTIACTIONBAR4BUTTON3",
        AzeriteActionBar5Button4 = "MULTIACTIONBAR4BUTTON4",
        AzeriteActionBar5Button5 = "MULTIACTIONBAR4BUTTON5",
        AzeriteActionBar5Button6 = "MULTIACTIONBAR4BUTTON6",
        AzeriteActionBar5Button7 = "MULTIACTIONBAR4BUTTON7",
        AzeriteActionBar5Button8 = "MULTIACTIONBAR4BUTTON8",
        AzeriteActionBar5Button9 = "MULTIACTIONBAR4BUTTON9",
        AzeriteActionBar5Button10 = "MULTIACTIONBAR4BUTTON10",
        AzeriteActionBar5Button11 = "MULTIACTIONBAR4BUTTON11",
        AzeriteActionBar5Button12 = "MULTIACTIONBAR4BUTTON12",
    }
    
    return bindingMap[buttonName]
end

-------------------------------------------------------------------------------
-- 8. Bars Module
-------------------------------------------------------------------------------
--[[
MODULE: Bars - Fixed button detection
]]
function AdvancedHotkeyOverlaySystem.Bars:ShouldIncludeBar(barType)
    return AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile and AdvancedHotkeyOverlaySystem.db.profile.bars and AdvancedHotkeyOverlaySystem.db.profile.bars[barType] ~= false
end

function AdvancedHotkeyOverlaySystem.Bars:GetActionButtons()
    local buttons = {}
      if AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile.debug then
        AdvancedHotkeyOverlaySystem:Print("Starting button detection...")
    end
      -- Try to detect AzeriteUI action bars first (these may override standard bars)
    local azeriteButtons = {
        -- AzeriteUI Main Action Bar (this is the bottom bar we see)
        {"AzeriteActionBar1Button", 1, 12, "AzeriteActionBar"},
        {"AzeriteActionBar2Button", 1, 12, "AzeriteActionBar2"},
        {"AzeriteActionBar3Button", 1, 12, "AzeriteActionBar3"},
        {"AzeriteActionBar4Button", 1, 12, "AzeriteActionBar4"},
        {"AzeriteActionBar5Button", 1, 12, "AzeriteActionBar5"},
    }
    
    -- Check AzeriteUI bars first
    for _, info in ipairs(azeriteButtons) do
        local prefix, startNum, endNum, barType = info[1], info[2], info[3], info[4]
        if self:ShouldIncludeBar(barType) then
            for i = startNum, endNum do
                local buttonName = prefix .. i
                local button = _G[buttonName]
                if button and button.HotKey then
                    table.insert(buttons, button)                    if AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile.debug then
                        AdvancedHotkeyOverlaySystem:Print("Found AzeriteUI button:", buttonName)
                    end
                end
            end
        end
    end
    
    -- Standard Blizzard bars (fallback if AzeriteUI bars not found)
    local standardButtons = {
        -- Main Action Bar (ActionButton1-12)
        {"ActionButton", 1, 12, "ActionButton"},
        -- Bottom Left Bar (MultiBarBottomLeft)
        {"MultiBarBottomLeftButton", 1, 12, "MultiBarBottomLeft"},
        -- Bottom Right Bar (MultiBarBottomRight)
        {"MultiBarBottomRightButton", 1, 12, "MultiBarBottomRight"},
        -- Right Bar (MultiBarRight)
        {"MultiBarRightButton", 1, 12, "MultiBarRight"},
        -- Left Bar (MultiBarLeft)
        {"MultiBarLeftButton", 1, 12, "MultiBarLeft"},
        -- Pet Action Bar
        {"PetActionButton", 1, 10, "PetAction"},
        -- Stance Bar
        {"StanceButton", 1, 10, "Stance"},
    }
    
    -- Check standard bars
    for _, info in ipairs(standardButtons) do
        local prefix, startNum, endNum, barType = info[1], info[2], info[3], info[4]
        if self:ShouldIncludeBar(barType) then
            for i = startNum, endNum do
                local buttonName = prefix .. i
                local button = _G[buttonName]
                if button and button.HotKey then
                    -- Check if we already added this button (avoid duplicates)
                    local found = false
                    for _, existingButton in ipairs(buttons) do
                        if existingButton == button then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(buttons, button)                        if AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile.debug then
                            AdvancedHotkeyOverlaySystem:Print("Found standard button:", buttonName)
                        end
                    end
                end
            end
        end
    end
      if AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile.debug then
        AdvancedHotkeyOverlaySystem:Print("Total buttons found:", #buttons)
    end
    
    return buttons
end

-------------------------------------------------------------------------------
-- 9. Performance Module
-------------------------------------------------------------------------------
--[[
MODULE: Performance - Event handling
]]
function AdvancedHotkeyOverlaySystem.Performance:ShouldThrottleUpdate()
    if not AdvancedHotkeyOverlaySystem.db or not AdvancedHotkeyOverlaySystem.db.profile or (not AdvancedHotkeyOverlaySystem.db.profile.performance or not AdvancedHotkeyOverlaySystem.db.profile.performance.throttleUpdates) then
        return false
    end
    
    local now = GetTime()
    local interval = AdvancedHotkeyOverlaySystem.db.profile.performance.updateInterval or 0.1
    
    if now - lastUpdateTime < interval then
        return true
    end
    
    lastUpdateTime = now
    return false
end

function AdvancedHotkeyOverlaySystem.Performance:IsInCombatOptimization()
    return AdvancedHotkeyOverlaySystem.db and AdvancedHotkeyOverlaySystem.db.profile and AdvancedHotkeyOverlaySystem.db.profile.performance and AdvancedHotkeyOverlaySystem.db.profile.performance.combatOptimization and InCombatLockdown()
end

-------------------------------------------------------------------------------
-- 10. Display Module
-------------------------------------------------------------------------------
--[[
MODULE: Display - Fixed overlay creation and cleanup
]]
-- UI-specific colors
local UI_COLORS = {
    AzeriteUI = {1, 0.8, 0.2},      -- gold
    ElvUI = {0.2, 0.8, 1},         -- cyan
    Bartender4 = {0.6, 0.2, 1},    -- purple
    Dominos = {0.2, 1, 0.4},       -- green
    Blizzard = {1, 1, 1},          -- white (default)
}

-- UI-specific colors for detected UI text
local UI_DETECTED_COLORS = {
    AzeriteUI = "fff2c100",   -- gold
    ElvUI = "ff33cfff",      -- cyan
    Bartender4 = "ffb266ff", -- purple
    Dominos = "ff33ff66",    -- green
    Blizzard = "ffffffff",   -- white (default)
}

function AdvancedHotkeyOverlaySystem.Display:CreateButtonOverlay(button)
    if not button or not button.HotKey or trackedButtons[button] then return end
    if AdvancedHotkeyOverlaySystem.Performance:IsInCombatOptimization() then return end
    if not originalHotkeyText[button] then
        originalHotkeyText[button] = button.HotKey:GetText() or ""
    end    local config = AdvancedHotkeyOverlaySystem.db.profile
    -- Use user-configured text color for hotkeys, not UI-detected color
    local fontColor = config.text.color or {1, 1, 1}
    
    -- Hide original hotkey text immediately if hideOriginal is enabled
    if config.display.hideOriginal and button.HotKey and button.HotKey.SetText then
        pcall(function() button.HotKey:SetText("") end)
    end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetFrameStrata(config.display.strata)
    overlay:SetFrameLevel(button:GetFrameLevel() + 10)
    overlay:SetScale(config.display.scale)
    overlay:SetAlpha(config.display.alpha)
    -- Font
    local font, size, flags = button.HotKey:GetFont()
    local fontPath = GetFontPath(config.text.font)
    local fontFlags = tostring(flags or "")
    if config.text.outline then
        fontFlags = fontFlags:find("OUTLINE") and fontFlags or (fontFlags .. " OUTLINE")
    else
        fontFlags = fontFlags:gsub("OUTLINE", "")
    end
    local newHotkey = overlay:CreateFontString(nil, "OVERLAY")
    newHotkey:SetFont(fontPath, config.text.fontSize > 0 and config.text.fontSize or size, fontFlags)
    newHotkey:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
    -- Shadow toggle
    if config.text.shadowEnabled then
        newHotkey:SetShadowColor(0, 0, 0, 1)
        newHotkey:SetShadowOffset(2, -2)
    else
        newHotkey:SetShadowColor(0, 0, 0, 0)
        newHotkey:SetShadowOffset(0, 0)
    end
    self:SetBasicPosition(newHotkey, button, config)
    -- Store original SetText function before replacing (avoid recursion)
    if not originalSetTextFunctions[button] and button.HotKey and button.HotKey.SetText then
        local mt = getmetatable(button.HotKey)
        local idx = mt and mt.__index
        if type(idx) == "table" and idx.SetText then
            originalSetTextFunctions[button] = idx.SetText
        else
            originalSetTextFunctions[button] = button.HotKey.SetText
        end
    end
    button.HotKey.SetText = function(hotkeySelf, text)
        if config.display.hideOriginal then
            if originalSetTextFunctions[button] then
                originalSetTextFunctions[button](hotkeySelf, "")
            else
                hotkeySelf:SetText("")
            end
        else
            if originalSetTextFunctions[button] then
                originalSetTextFunctions[button](hotkeySelf, text)
            else
                hotkeySelf:SetText(text)
            end
        end
        if text and text ~= "" and text ~= "●" then
            local abbreviatedText = AdvancedHotkeyOverlaySystem.Keybinds:AbbreviateKeybind(text)
            newHotkey:SetText(abbreviatedText)
            newHotkey:Show()
            overlay:Show()
        else
            newHotkey:Hide()
            overlay:Hide()
        end
    end
    trackedButtons[button] = {
        overlay = overlay,
        hotkey = newHotkey,
        originalSetText = originalSetTextFunctions[button]
    }
    local bindingCommand = AdvancedHotkeyOverlaySystem.Keybinds:GetButtonBindingCommand(button)
    if bindingCommand then
        local binding = GetBindingKey(bindingCommand)
        if binding then
            local bindingText = GetBindingText(binding)        if AdvancedHotkeyOverlaySystem.db.profile.debug then
            AdvancedHotkeyOverlaySystem:Print("Setting binding for", button:GetName(), ":", bindingText)
        end
            button.HotKey:SetText(bindingText)
        else        if AdvancedHotkeyOverlaySystem.db.profile.debug then
            AdvancedHotkeyOverlaySystem:Print("No binding found for", button:GetName())
        end
            button.HotKey:SetText("")
        end
    else
        local currentText = button.HotKey:GetText()
        if currentText and currentText ~= "" and currentText ~= "●" then
            button.HotKey:SetText(currentText)
        end
    end    if AdvancedHotkeyOverlaySystem.db.profile.debug then
        AdvancedHotkeyOverlaySystem:Print("Created overlay for:", button:GetName())
    end
end

function AdvancedHotkeyOverlaySystem.Display:SetBasicPosition(fontString, button, config)
    local baseOffsets = {
        TOPLEFT = {-2, -2}, TOP = {0, -2}, TOPRIGHT = {2, -2},
        LEFT = {-2, 0}, CENTER = {0, 0}, RIGHT = {2, 0},
        BOTTOMLEFT = {-2, 2}, BOTTOM = {0, 2}, BOTTOMRIGHT = {2, 2},
    }
    
    local baseOffset = baseOffsets[config.display.anchor] or {0, -2}
    -- Clear all points first for live updates
    fontString:ClearAllPoints()
    fontString:SetPoint(config.display.anchor, button, config.display.anchor,
        baseOffset[1] + config.display.xOffset,
        baseOffset[2] + config.display.yOffset)
end

-- FIXED cleanup function that properly restores original state
function AdvancedHotkeyOverlaySystem.Display:CleanupButtonOverlay(button)
    if not button then return false end
    local tracked = trackedButtons[button]
    if not tracked then return false end
    if tracked.overlay then
        tracked.overlay:Hide()
        tracked.overlay:SetParent(nil)
    end
    if tracked.hotkey then tracked.hotkey:Hide() end
    if tracked.originalSetText then
        if button.HotKey then
            button.HotKey.SetText = tracked.originalSetText
            -- Restore original hotkey text
            local originalText = originalHotkeyText[button]
            if originalText then
                button.HotKey:SetText(originalText)
            end
        end
    end
    trackedButtons[button] = nil
    originalHotkeyText[button] = nil
    return true
end

function AdvancedHotkeyOverlaySystem.Display:UpdateAllOverlayStyles()
    local config = AdvancedHotkeyOverlaySystem.db.profile
    for button, tracked in pairs(trackedButtons) do
        if tracked and tracked.hotkey and tracked.overlay then
            -- Update font
            local fontPath = GetFontPath(config.text.font)
            local size = config.text.fontSize > 0 and config.text.fontSize or select(2, tracked.hotkey:GetFont())
            local fontFlags = config.text.outline and "OUTLINE" or ""
            tracked.hotkey:SetFont(fontPath, size, fontFlags)
            -- Update color
            local fontColor = config.text.color or {1, 1, 1}
            tracked.hotkey:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
            -- Update shadow
            if config.text.shadowEnabled then
                tracked.hotkey:SetShadowColor(0, 0, 0, 1)
                tracked.hotkey:SetShadowOffset(2, -2)
            else
                tracked.hotkey:SetShadowColor(0, 0, 0, 0)
                tracked.hotkey:SetShadowOffset(0, 0)
            end
            -- Update overlay properties
            tracked.overlay:SetFrameStrata(config.display.strata)
            tracked.overlay:SetScale(config.display.scale)
            tracked.overlay:SetAlpha(config.display.alpha)
            -- Update position
            AdvancedHotkeyOverlaySystem.Display:SetBasicPosition(tracked.hotkey, button, config)
        end
    end
end

-------------------------------------------------------------------------------
-- 11. Main Addon Functions
-------------------------------------------------------------------------------
function AdvancedHotkeyOverlaySystem:OnInitialize()
    -- Set up database with dynamic defaults
    local dynamicDefaults = GetDynamicDefaults()
    self.db = AceDB:New("AdvancedHotkeyOverlaySystemDB", dynamicDefaults, true)
    -- Register events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("UPDATE_BINDINGS")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:SetupOptions()
    self:SetupMinimapButton()
    self:SetupTitanPanel()    -- Register slash commands for custom handler
    self:RegisterChatCommand("ahos", "SlashHandler")
    self:RegisterChatCommand("advancedhotkeyoverlaysystem", "SlashHandler")
end

function AdvancedHotkeyOverlaySystem:OnEnable()
    self:Print("|cffFFD700Loaded! Version:|r " .. (ADDON_VERSION or "?") .. " |cff888888| Commands:|r |cff4A9EFF/ahos|r |cff888888(options)|r |cff4A9EFF/ahos help|r |cff888888(help)|r")
    self:ScheduleTimer(function()
        self:UpdateAllButtons()
    end, 1)
end

function AdvancedHotkeyOverlaySystem:OnDisable()
    self:CleanupAllOverlays()
end

-- Event handlers
function AdvancedHotkeyOverlaySystem:PLAYER_LOGIN()
    self:DetectUI()
    -- Re-detect UI after a delay in case some UIs load later
    self:ScheduleTimer(function()
        self:DetectUI()
        self:UpdateAllButtons()
    end, 3)
end

function AdvancedHotkeyOverlaySystem:UPDATE_BINDINGS()
    if not self.Performance:ShouldThrottleUpdate() then
        self:RefreshAllBindings()
        self:UpdateAllButtons()
    end
end

function AdvancedHotkeyOverlaySystem:ACTIONBAR_SLOT_CHANGED()
    if not InCombatLockdown() then
        self:UpdateAllButtons()
    end
end

function AdvancedHotkeyOverlaySystem:PLAYER_REGEN_ENABLED()
    self:ScheduleTimer(function()
        self:UpdateAllButtons()
    end, 1)
end

function AdvancedHotkeyOverlaySystem:UpdateAllButtons()
    if not self.db or not self.db.profile or not self.db.profile.enabled then return end
    
    local buttons = self.Bars:GetActionButtons()
      if self.db.profile.debug then
        AdvancedHotkeyOverlaySystem:Print("Found " .. #buttons .. " action buttons")
    end
    
    for _, btn in ipairs(buttons) do
        self.Display:CreateButtonOverlay(btn)
    end
end

function AdvancedHotkeyOverlaySystem:CleanupAllOverlays()
    local cleaned = 0
    for btn, _ in pairs(trackedButtons) do
        if self.Display:CleanupButtonOverlay(btn) then
            cleaned = cleaned + 1
        end
    end
    
    -- Clear the tracked buttons table completely
    wipe(trackedButtons)
    
    if self.db and self.db.profile and self.db.profile.debug then
        self:Print("Cleaned up " .. cleaned .. " overlays and cleared tracking")
    end
end

function AdvancedHotkeyOverlaySystem:RefreshAllBindings()
    for button, tracked in pairs(trackedButtons) do
        if button and button.HotKey then
            local bindingCommand = self.Keybinds:GetButtonBindingCommand(button)
            if bindingCommand then
                local binding = GetBindingKey(bindingCommand)
                if binding then
                    local bindingText = GetBindingText(binding)
                    if self.db.profile.debug then
                        self:Print("Refreshing binding for", button:GetName(), ":", bindingText)
                    end
                    button.HotKey:SetText(bindingText)
                else
                    button.HotKey:SetText("")
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 12. Live Update Options Patching
-------------------------------------------------------------------------------
-- Helper to patch all config set functions for live update (no custom fields in options)
local livePatchedOptions = setmetatable({}, {__mode = "k"})
local function PatchLiveUpdateOptions(options)
    for _, group in pairs(options.args) do
        if type(group) == "table" and group.args then
            for key, opt in pairs(group.args) do
                if opt.set and type(opt.set) == "function" and not livePatchedOptions[opt] then
                    local oldSet = opt.set
                    opt.set = function(...)
                        oldSet(...)
                        if AdvancedHotkeyOverlaySystem and AdvancedHotkeyOverlaySystem.CleanupAllOverlays and AdvancedHotkeyOverlaySystem.UpdateAllButtons then
                            AdvancedHotkeyOverlaySystem:CleanupAllOverlays()
                            AdvancedHotkeyOverlaySystem:UpdateAllButtons()
                        end
                    end
                    livePatchedOptions[opt] = true
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 13. Lock System and Options Setup
-------------------------------------------------------------------------------

-- Register the unlock confirmation popup dialog
StaticPopupDialogs["AHOS_UNLOCK_CONFIRMATION"] = {
    text = "|TInterface\\ICONS\\INV_Misc_Key_03:32:32:0:0|t\n\n|cffFF6B6BSettings are currently locked|r\n\nWould you like to unlock them to make changes?\n\n|cff888888This will allow you to modify all overlay settings.|r",    button1 = "|cff4A9EFFYes, Unlock|r",
    button2 = "|cffFFD700Keep Locked|r",
    OnAccept = function(self, data)
        AdvancedHotkeyOverlaySystem.db.profile.display.locked = false
        AdvancedHotkeyOverlaySystem:Print("Settings unlocked - you can now make changes.")
        if data then
            data()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Helper function to show unlock confirmation popup
function AdvancedHotkeyOverlaySystem:ShowUnlockConfirmation(callback)
    StaticPopup_Show("AHOS_UNLOCK_CONFIRMATION", nil, nil, callback)
end

-- Helper function to create a locked-aware setter
local function CreateLockedSetter(originalSetter)
    return function(info, val1, val2, val3, val4)
        if AdvancedHotkeyOverlaySystem.db.profile.display.locked then
            AdvancedHotkeyOverlaySystem:ShowUnlockConfirmation(function()
                originalSetter(info, val1, val2, val3, val4)
            end)
        else
            originalSetter(info, val1, val2, val3, val4)
        end
    end
end

-- Main options panel setup function
function AdvancedHotkeyOverlaySystem:SetupOptions()
    local options = {
        name = "Advanced Hotkey Overlay System",
        handler = self,
        type = "group",
        args = {
            -- Master Toggle - at the very top for immediate access
            enable = {
                type = "toggle",
                name = "|TInterface\\ICONS\\Ability_Rogue_Preparation:20:20:0:0|t Master Toggle",
                desc = "|cff4A9EFFEnable or disable the Advanced Hotkey Overlay System addon.|r\n\n|cffFFD700When enabled:|r Shows custom hotkey overlays on action buttons\n|cffFF6B6BWhen disabled:|r Restores original UI hotkeys and hides all other options",
                get = function() return self.db.profile.enabled end,
                set = function(_, value)
                    if value then
                        -- Re-enabling: first enable, then cleanup and refresh
                        self.db.profile.enabled = value
                        self:Enable()
                        -- Force cleanup of all existing overlays
                        self:CleanupAllOverlays()
                        -- Immediately refresh everything
                        self:DetectUI()  -- Re-detect UI in case it changed
                        self:UpdateAllButtons()
                        self:Print("Overlays refreshed and re-enabled.")
                    else
                        -- Disabling: cleanup first, then disable
                        self:CleanupAllOverlays()
                        self.db.profile.enabled = value
                        self:Disable()
                        self:Print("Overlays disabled and cleaned up.")
                    end
                    
                    -- Refresh the options panel to reflect the disabled state
                    if LibStub("AceConfigRegistry-3.0", true) then
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("AdvancedHotkeyOverlaySystem")
                    end
                end,
                order = 0,
                width = "full",
            },
            
            spacer1 = {
                type = "description",
                name = " ",
                order = 0.1,
            },
            
            -- Status and Profile section combined
            statusGroup = {
                type = "group",
                name = "",
                inline = true,
                order = 0.2,
                args = {            
                    uiDetected = {
                        type = "description",
                        name = function()
                            local ui = AdvancedHotkeyOverlaySystem and AdvancedHotkeyOverlaySystem.detectedUI or "Blizzard"
                            local color = UI_DETECTED_COLORS[ui] or UI_DETECTED_COLORS["Blizzard"]
                            return string.format("|TInterface\\ICONS\\INV_Misc_Gear_02:16:16:0:0|t |cff888888Detected UI:|r |c%s%s|r    |TInterface\\ICONS\\Trade_Engineering:16:16:0:0|t |cff888888Version:|r |cffFFD700%s|r", color, ui, (ADDON_VERSION or "?"))
                        end,
                        fontSize = "medium",
                        order = 1,
                        width = "full",
                    },
                    credits = {
                        type = "description",
                        name = "|TInterface\\ICONS\\Achievement_Guildperk_EverybodysFriend:16:16:0:0|t |cff888888Created by:|r |cffFFD700JuNNeZ|r |cff888888with AI assistance|r",
                        fontSize = "small",
                        order = 2,
                        width = 1.5,
                    },
                    
                    -- Profile selector moved here to the right
                    profileSelector = {
                        type = "select",
                        name = "|TInterface\\ICONS\\Achievement_Character_Human_Male:16:16:0:0|t Profile",
                        desc = "Select which profile to use for your settings",
                        get = function() 
                            return self.db:GetCurrentProfile()
                        end,
                        set = function(_, value) 
                            self.db:SetProfile(value)
                            self:UpdateAllButtons()
                            self:UpdateAllOverlayStyles()
                            self:Print("|cffFFD700Profile changed to:|r " .. value)
                        end,
                        values = function() 
                            return self.db:GetProfiles() 
                        end,
                        order = 3,
                        width = 1.2,
                    },                },
            },
            
            spacer2 = {
                type = "description",
                name = " ",
                order = 0.3,
            },
            
            -- Left Column - Controls            leftColumn = {
                type = "group",
                name = "Controls",
                order = 1,
                disabled = function() return not self.db.profile.enabled end,
                args = {
                    -- Utilities section
                    utilities = {
                        type = "group",
                        name = "|TInterface\\ICONS\\Trade_Engineering:20:20:0:0|t Quick Actions",
                        desc = "Essential tools for maintaining and troubleshooting your overlays",
                        inline = true,
                        order = 1,
                        args = {
                            utilityHeader = {
                                type = "description",                        
                                name = "|cff888888Perfect for when things go wrong or you want to test changes|r",
                                order = 0,
                            },
                            
                            refresh = {
                                type = "execute",
                                name = "|TInterface\\ICONS\\Spell_Holy_PrayerOfHealing02:16:16:0:0|t Smart Refresh",
                                desc = "|cff4A9EFFPerforms a comprehensive refresh of all overlays.|r\n\n|cffFFD700This will:|r\n• Re-detect your current UI addon\n• Re-scan all action bars for new buttons\n• Update all keybind assignments\n• Refresh overlay positions and styles\n• Clear any visual glitches or desyncs\n\n|cffFF6B6BUse this when:|r UI addons change, new action bars appear, or overlays seem out of sync.",
                                func = function() 
                                    self:CleanupAllOverlays()  -- Clear any old overlays first
                                    self:DetectUI()  -- Re-detect UI in case it changed
                                    self:ScheduleTimer(function()  -- Small delay to ensure cleanup is complete
                                        self:UpdateAllButtons()
                                        self:Print("Smart refresh completed - UI re-detected and all overlays updated.")
                                    end, 0.1)
                                end,
                                order = 1,
                                width = "normal",
                            },
                            cleanup = {
                                type = "execute",
                                name = "|TInterface\\ICONS\\Spell_Frost_Stun:16:16:0:0|t Temporary Clear",
                                desc = "|cff4A9EFFTemporarily removes all overlays without disabling the addon.|r\n\n|cffFFD700Useful for:|r\n• Comparing original hotkeys vs overlay appearance\n• Troubleshooting display issues\n• Taking screenshots without overlays\n• Testing if issues are caused by this addon\n\n|cffFF6B6BNote:|r Overlays will return when you change settings, reload UI, or use Smart Refresh.",
                                func = function() 
                                    self:CleanupAllOverlays()
                                    self:Print("Overlays temporarily cleared. Use Smart Refresh or change any setting to restore them.")
                                end,
                                order = 2,
                                width = "normal",
                            },
                        },
                    },
                    
                    spacer3 = {
                        type = "description",
                        name = " ",
                        order = 1.5,
                    },                    
                    spacer4 = {
                        type = "description",
                        name = " ",
                        order = 2.5,
                    },
                    
                    -- Enhanced lock settings
                    securitySection = {
                        type = "group",
                        name = "|TInterface\\ICONS\\INV_Misc_Key_03:20:20:0:0|t Security & Lock",
                        desc = "Protect your settings from accidental changes",
                        inline = true,
                        order = 3,
                        args = {
                            lockHeader = {
                                type = "description",
                                name = "|cff888888Prevent accidental setting changes during combat or gameplay|r",
                                order = 0,
                            },
                            
                            locked = {
                                type = "toggle",
                                name = function()
                                    local locked = self.db.profile.display.locked
                                    return locked and "|TInterface\\ICONS\\INV_Misc_Key_03:16:16:0:0|t Settings Locked" or "|TInterface\\ICONS\\INV_Misc_Key_04:16:16:0:0|t Settings Unlocked"
                                end,
                                desc = function()
                                    local locked = self.db.profile.display.locked
                                    if locked then
                                        return "|cffFF6B6BSETTINGS ARE CURRENTLY LOCKED|r\n\n|cffFFD700When locked:|r\n• All settings are protected from changes\n• Clicking locked settings shows unlock confirmation\n• Perfect for preventing misclicks during gameplay\n• Great for raids, dungeons, or PvP\n\n|cffFF6B6BTo make changes:|r Toggle this setting to unlock"
                                    else
                                        return "|cff00D4AASETTINGS ARE CURRENTLY UNLOCKED|r\n\n|cffFFD700When unlocked:|r\n• All settings can be modified normally\n• Changes apply immediately with live updates\n• Full access to all customization options\n\n|cffFF6B6BRecommendation:|r Lock settings during important content to prevent accidents!"
                                    end
                                end,
                                get = function() return self.db.profile.display.locked end,
                                set = function(_, val) 
                                    self.db.profile.display.locked = val
                                    if not val then
                                        -- When unlocking, apply current settings
                                        self:UpdateAllButtons()
                                        AdvancedHotkeyOverlaySystem.Display:UpdateAllOverlayStyles()
                                        self:Print("Settings unlocked - you can now make changes.")
                                    else
                                        self:Print("Settings locked - protected from accidental changes.")
                                    end                        
                                end,
                                order = 1,
                                width = "full",
                            },
                        },
                    },
                },
            },            -- Right Column - Position & Appearance (Full Width)
            position = {
                type = "group",
                name = "|TInterface\\ICONS\\INV_Misc_Map_01:20:20:0:0|t Position & Appearance",
                desc = "Customize how and where your hotkey overlays appear",
                order = 2,
                disabled = function() return not self.db.profile.enabled end,
                args = {
                    appearanceHeader = {
                        type = "description",
                        name = "|cff888888Fine-tune the look and placement of your overlay text|r",
                        order = 0,
                    },
                    
                    -- Position Controls
                    positionGroup = {
                        type = "group",
                        name = "|TInterface\\ICONS\\Ability_Hunter_Aspectofthehawk:16:16:0:0|t Position Controls",
                        inline = true,
                        order = 1,
                        args = {
                            anchor = {
                                type = "select",
                                name = "Anchor Point",
                                desc = "|cff4A9EFFChoose where the hotkey text appears on each action button.|r\n\n|cffFFD700Position Options:|r\n• |cffFFFFFFTop/Bottom:|r Text appears above/below button\n• |cffFFFFFFLeft/Right:|r Text appears beside button\n• |cffFFFFFFCenter:|r Text appears in middle of button\n• |cffFFFFFFCorners:|r Text appears in button corners\n\n|cffFF6B6BRecommended:|r TOP for most UI addons, CENTER for minimal look",
                                values = {
                                    TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
                                    LEFT = "Left", CENTER = "Center", RIGHT = "Right",
                                    BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
                                },
                                get = function() return self.db.profile.display.anchor end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.anchor = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 1,
                            },
                            
                            offsetHeader = {
                                type = "description",
                                name = "|cff888888Fine-tune positioning with pixel-perfect adjustments|r",
                                order = 1.5,
                            },
                            
                            xOffset = {                                type = "range",
                                name = "X Offset",
                                desc = "|cff4A9EFFHorizontal positioning adjustment.|r Push text left (negative) or right (positive) from the anchor point.",
                                min = -50, max = 50, step = 1,
                                get = function() return self.db.profile.display.xOffset end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.xOffset = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 2,
                            },
                            yOffset = {
                                type = "range",
                                name = "Y Offset",
                                desc = "|cff4A9EFFVertical positioning adjustment.|r Push text down (negative) or up (positive) from the anchor point.",
                                min = -50, max = 50, step = 1,
                                get = function() return self.db.profile.display.yOffset end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.yOffset = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 3,
                            },
                        },
                    },
                    
                    -- Visual Controls
                    visualGroup = {
                        type = "group",
                        name = "|TInterface\\ICONS\\INV_Enchant_EssenceCosmicGreater:16:16:0:0|t Visual Properties",
                        inline = true,
                        order = 2,
                        args = {                    
                            scale = {
                                type = "range",
                                name = "Scale",
                                desc = "|cff00D4AAAdjust the overall size of hotkey text relative to the button.|r\n\n|cffFFD700Size Guide:|r\n• |cffFFFFFF0.5:|r Very small text (50% of normal)\n• |cffFFFFFF1.0:|r Normal size text\n• |cffFFFFFF1.5:|r Large text (150% of normal)\n• |cffFFFFFF2.0:|r Very large text (200% of normal)\n\n|cffFF6B6BDefault (0.95) works well for most setups|r",
                                min = 0.5, max = 2, step = 0.01,
                                get = function() return self.db.profile.display.scale end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.scale = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 4,
                            },
                            
                            alpha = {
                                type = "range",                                name = "Transparency",
                                desc = "|cff00D4AAAdjust text transparency.|r 0 = invisible, 1 = fully opaque",
                                min = 0, max = 1, step = 0.01,
                                get = function() return self.db.profile.display.alpha end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.alpha = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 6,
                            },
                            
                            strata = {
                                type = "select",
                                name = "Frame Layer",
                                desc = "|cff00D4AAControls which UI layer the text appears on.|r Higher layers appear above lower ones.",
                                values = { 
                                    BACKGROUND = "Background", 
                                    LOW = "Low", 
                                    MEDIUM = "Medium", 
                                    HIGH = "High", 
                                    DIALOG = "Dialog", 
                                    FULLSCREEN = "Fullscreen", 
                                    FULLSCREEN_DIALOG = "Fullscreen Dialog", 
                                    TOOLTIP = "Tooltip" 
                                },
                                get = function() return self.db.profile.display.strata end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.display.strata = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 5,
                            },
                        },
                    },
                    
                    -- Font & Text Controls
                    fontGroup = {
                        type = "group",
                        name = "|TInterface\\ICONS\\INV_Inscription_Papyrus:16:16:0:0|t Font & Text Style",
                        inline = true,                        order = 3,
                        args = {
                            color = {
                                type = "color",
                                name = "Text Color",
                                desc = "|cff00D4AAChoose the color of your hotkey text.|r Click to open the color picker.",
                                hasAlpha = false,
                                get = function()
                                    local c = self.db.profile.text.color
                                    return c[1], c[2], c[3]
                                end,
                                set = CreateLockedSetter(function(_, r, g, b)
                                    local c = self.db.profile.text.color
                                    c[1], c[2], c[3] = r, g, b
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 7,
                            },
                            font = {
                                type = "select",
                                name = "Font Family",
                                desc = "|cff00D4AAChoose the font for hotkey text.|r Different fonts can improve readability or match your UI theme.",
                                values = function()
                                    local out = {}
                                    for _, name in ipairs(GetFontList()) do out[name] = name end
                                    return out
                                end,
                                get = function() return self.db.profile.text.font end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.text.font = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 8,
                            },

                            fontSize = {
                                type = "range",
                                name = "Font Size",
                                desc = "|cff00D4AASet the font size for hotkey text in pixels.|r\n\n|cffFFD700Common sizes:|r\n• |cffFFFFFF10-12:|r Small, subtle text\n• |cffFFFFFF14-16:|r Medium, balanced text (recommended)\n• |cffFFFFFF18-20:|r Large, prominent text\n• |cffFFFFFF22+:|r Extra large for visibility\n\n|cffFF6B6BNote:|r This works together with Scale setting",
                                min = 6, max = 32, step = 1,
                                get = function() return self.db.profile.text.fontSize end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.text.fontSize = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 8.1,
                            },
                            
                            styleHeader = {
                                type = "description",
                                name = "|cff888888Text enhancement options for better visibility|r",
                                order = 8.15,
                            },
                            
                            outline = {
                                type = "toggle",
                                name = "Text Outline",
                                desc = "|cff00D4AAShow an outline around the hotkey text.|r Improves readability over complex backgrounds.",
                                get = function() return self.db.profile.text.outline end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.text.outline = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 8.2,
                            },
                            shadowEnabled = {
                                type = "toggle",
                                name = "Text Shadow",
                                desc = "|cff00D4AAShow a shadow behind the hotkey text.|r Adds depth and improves visibility.",
                                get = function() return self.db.profile.text.shadowEnabled end,
                                set = CreateLockedSetter(function(_, val) 
                                    self.db.profile.text.shadowEnabled = val
                                    self:ApplyUpdatesIfNotLocked()
                                end),
                                disabled = function() return self.db.profile.display.locked end,
                                order = 8.3,
                            },
                        },                    },
                },
            },
        }
    
    
    -- Register options and slash commands with AceConfig
    AceConfig:RegisterOptionsTable("Advanced Hotkey Overlay System", options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("Advanced Hotkey Overlay System", "Advanced Hotkey Overlay System")
    -- Patch options after creation
    PatchLiveUpdateOptions(options)
end

-------------------------------------------------------------------------------
-- 14. UI Detection and Slash Command Handling
-------------------------------------------------------------------------------

-- Minimap/DataBroker Integration
local LDB = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local minimapIconName = "AdvancedHotkeyOverlayMinimap"

-- Register DataBroker object for minimap button
if LDB then
    if not LDB:GetDataObjectByName(minimapIconName) then
        LDB:NewDataObject(minimapIconName, {
            type = "launcher",
            text = "AHO",
            icon = "Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\media\\small-logo.tga",
            OnClick = function(self, button)
                -- Toggle options panel for any click
                local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
                if AceConfigDialog then
                    if AceConfigDialog.OpenFrames["Advanced Hotkey Overlay System"] then
                        -- Panel is open, close it
                        AceConfigDialog:Close("Advanced Hotkey Overlay System")
                    else
                        -- Panel is closed, open it
                        AceConfigDialog:Open("Advanced Hotkey Overlay System")
                    end
                elseif InterfaceOptionsFrame_OpenToCategory then
                    -- Fallback for older versions
                    InterfaceOptionsFrame_OpenToCategory("Advanced Hotkey Overlay System")
                    InterfaceOptionsFrame_OpenToCategory("Advanced Hotkey Overlay System")
                end
            end,            OnTooltipShow = function(tooltip)
                tooltip:AddLine("AdvancedHotkeyOverlay")
                tooltip:AddLine("Click: Toggle Options Panel")
            end,
        })
    end
end

function AdvancedHotkeyOverlaySystem:SetupMinimapButton()
    if LibDBIcon and type(LibDBIcon.Register) == "function" and LDB then
        self.db.profile.minimap = self.db.profile.minimap or { hide = false }
        LibDBIcon:Register(minimapIconName, LDB:GetDataObjectByName(minimapIconName), self.db.profile.minimap)
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

-- TitanPanel Integration
function AdvancedHotkeyOverlaySystem:SetupTitanPanel()
    if not TitanPanelButton_UpdateButton then return end
    local buttonName = "TitanPanelAdvancedHotkeyOverlayButton"
    _G[buttonName] = {
        id = buttonName,
        category = "Interface",
        version = ADDON_VERSION,
        menuText = "AdvancedHotkeyOverlay",
        buttonTextFunction = function()
            local status = self.db and self.db.profile and self.db.profile.enabled and "|cff00ff00On|r" or "|cffff0000Off|r"
            return "AHO: " .. status
        end,
        tooltipTitle = "AdvancedHotkeyOverlay",
        tooltipTextFunction = function()
            return "Left-click: " .. L.SHOW_OPTIONS .. "\nRight-click: " .. L.HELP
        end,
        icon = "Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\media\\small-logo.tga",
        OnClick = function(self, button)
            if button == "LeftButton" then
                -- Toggle options panel
                local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
                if AceConfigDialog then
                    if AceConfigDialog.OpenFrames["Advanced Hotkey Overlay System"] then
                        -- Panel is open, close it
                        AceConfigDialog:Close("Advanced Hotkey Overlay System")
                    else
                        -- Panel is closed, open it
                        AceConfigDialog:Open("Advanced Hotkey Overlay System")
                    end
                elseif InterfaceOptionsFrame_OpenToCategory then
                    -- Fallback for older versions
                    InterfaceOptionsFrame_OpenToCategory("Advanced Hotkey Overlay System")
                    InterfaceOptionsFrame_OpenToCategory("Advanced Hotkey Overlay System")
                end
            elseif button == "RightButton" then
                print("/aho help")
            end
        end,
    }
    TitanPanelButton_UpdateButton(buttonName)
end

-- Slash Command Handler
function AdvancedHotkeyOverlaySystem:SlashHandler(input)
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower() or ""
    
    if cmd == "" or cmd == "show" or cmd == "options" then
        -- Open options using AceConfigDialog
        AceConfigDialog:Open("Advanced Hotkey Overlay System")    elseif cmd == "lock" then
        self.db.profile.display.locked = true
        self:UpdateAllButtons()
        self:Print("|cffFFD700Settings locked|r - |cff888888protected from changes|r")
    elseif cmd == "unlock" then
        self.db.profile.display.locked = false
        self:UpdateAllButtons()
        self:Print("|cff4A9EFF Settings unlocked|r - |cff888888you can now modify settings|r")
    elseif cmd == "reset" then
        self.db:ResetProfile()
        self:UpdateAllButtons()
        self:Print("|cffFFD700Settings reset|r |cff888888to default values|r")
    elseif cmd == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        self:UpdateAllButtons()
        self:Print("Overlay " .. (self.db.profile.enabled and "|cff4A9EFFenabled|r" or "|cffFF6B6Bdisabled|r"))
    elseif cmd == "reload" then
        self:UpdateAllButtons()
        self:Print("|cff4A9EFFOverlays reloaded|r |cff888888and refreshed|r")    elseif cmd == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print("|cffFFD700Debug mode|r " .. (self.db.profile.debug and "|cff4A9EFFenabled|r" or "|cffFF6B6Bdisabled|r"))
    elseif cmd == "detectui" then
        self:Print("|cff4A9EFFManually detecting UI...|r")
        self:DetectUI()
        local ui = self.detectedUI or "None"
        local color = UI_DETECTED_COLORS[ui] or UI_DETECTED_COLORS["Blizzard"]
        self:Print("|cffFFD700Current detected UI:|r |c" .. color .. ui .. "|r")    elseif cmd == "refresh" then
        -- Smart refresh command - same as UI button
        self:CleanupAllOverlays()
        self:DetectUI()
        self:ScheduleTimer(function()
            self:UpdateAllButtons()
            self:Print("|cff4A9EFFSmart refresh completed|r - |cffFFD700UI re-detected|r |cff888888and all overlays updated|r")
        end, 0.1)
    elseif cmd == "cleanup" then
        -- Temporary clear command - same as UI button
        self:CleanupAllOverlays()
        self:Print("|cffFFD700Overlays temporarily cleared|r - |cff888888use Smart Refresh or change settings to restore|r")    elseif cmd == "help" then
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
    else
        self:Print("|cffFF6B6BUnknown command:|r |cffFFD700" .. cmd .. "|r")
        self:Print("|cff888888Type|r |cffFFD700/ahos help|r |cff888888for available commands|r")
    end
end

-- Helper method for applying updates when not locked
function AdvancedHotkeyOverlaySystem:ApplyUpdatesIfNotLocked()
    if not self.db.profile.display.locked then
        self:UpdateAllButtons()
        self.Display:UpdateAllOverlayStyles()
    end
end

-------------------------------------------------------------------------------
-- End of Advanced Hotkey Overlay System
-------------------------------------------------------------------------------
