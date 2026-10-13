---@diagnostic disable: undefined-global
-- AdvancedHotkeyOverlaySystem.lua
local addonName, addonScope = ...
---@class AHOS
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addonScope.addon = addon
-- Localization table (loaded from locales/*.lua); ensure a table exists
addon.L = _G.AHOS_L or addon.L or {}
_G.AHOS_L = addon.L
-- Back-compat global for options panel title
_G.AHOS_OPTIONS_PANEL_NAME = _G.AHOS_OPTIONS_PANEL_NAME or addon.L.OPTIONS_PANEL_NAME or "AHOS Options"

-- Remove any global AdvancedHotkeyOverlaySystem table creation (orphaned/legacy)
_G["AdvancedHotkeyOverlaySystem"] = nil

-- Ensure the main addon table is available globally for legacy code
_G.AdvancedHotkeyOverlaySystem = addon

-- Register modules in the correct order so dependencies are always available
addon.Config = addon:NewModule("Config", "AceEvent-3.0") --[[@as AHOSConfig]]
addon.Options = addon:NewModule("Options") --[[@as AHOSOptions]]
addon.Core = addon:NewModule("Core", "AceEvent-3.0", "AceTimer-3.0") --[[@as AHOSCore]]
addon.Bars = addon:NewModule("Bars") --[[@as AHOSBars]]
addon.Keybinds = addon:NewModule("Keybinds") --[[@as AHOSKeybinds]]
addon.Display = addon:NewModule("Display", "AceEvent-3.0") --[[@as AHOSDisplay]]
addon.Performance = addon:NewModule("Performance", "AceTimer-3.0") --[[@as AHOSPerformance]]
addon.UI = addon:NewModule("UI", "AceEvent-3.0") --[[@as AHOSUI]]
addon.Visibility = addon:NewModule("Visibility", "AceEvent-3.0", "AceTimer-3.0") --[[@as AHOSVisibility]]
addon.Editor = addon:NewModule("Editor", "AceEvent-3.0") --[[@as AHOSEditor]]
addon.Profiles = addon:NewModule("Profiles", "AceEvent-3.0", "AceTimer-3.0") --[[@as AHOSProfiles]]

-- Compatibility helper for checking if an addon is loaded
local function IsAddOnLoadedCompat(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

-- WoW Forever (TOC suffix _Camelot, interface 16xxx) runs the Mainline engine and
-- reports WOW_PROJECT_MAINLINE, but its interface numbers sit below Retail's, so a
-- plain "build >= 100000" gate would misclassify it as Classic. Ask the selected
-- TOC first, then fall back to the project ID and the interface range.
local function DetectClient()
    local interface = select(4, GetBuildInfo()) or 0
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or rawget(_G, "GetAddOnMetadata")
    local flavor = getMetadata and getMetadata(addonName, "X-Flavor")
    local pid = rawget(_G, "WOW_PROJECT_ID")
    local pm = rawget(_G, "WOW_PROJECT_MAINLINE")
    local mainline
    if type(pid) == "number" and type(pm) == "number" then
        mainline = pid == pm
    else
        mainline = interface >= 100000
    end
    local forever = flavor == "Forever" or (mainline and interface >= 16000 and interface < 17000)
    return (mainline or forever) and true or false, forever and true or false
end
addon.IsMainlineClient, addon.IsForeverClient = DetectClient()

-- Retail 12.x can return values that addon code is not allowed to inspect.
-- Keep all action-button consumers behind the same access checks so a secret
-- attribute or frame aspect cannot be compared, converted, or logged.
function addon:IsValueAccessible(value)
    local accessChecker = rawget(_G, "canaccessvalue")
    if type(accessChecker) == "function" then
        local ok, accessible = pcall(accessChecker, value)
        return ok and accessible == true
    end

    local secretChecker = rawget(_G, "issecretvalue")
    if type(secretChecker) == "function" then
        local ok, isSecret = pcall(secretChecker, value)
        return not (ok and isSecret == true)
    end

    return true
end

function addon:SafeToString(value, fallback)
    if not self:IsValueAccessible(value) then
        return fallback or "<secret>"
    end
    local ok, text = pcall(tostring, value)
    return ok and text or (fallback or "<unavailable>")
end

function addon:GetButtonActionSlot(button)
    if not button then return nil end

    local ok, action = pcall(function() return button.action end)
    if not ok or not self:IsValueAccessible(action) then
        action = nil
    end

    local methodOk, getAttribute = pcall(function() return button.GetAttribute end)
    if action == nil and methodOk and type(getAttribute) == "function" then
        ok, action = pcall(getAttribute, button, "action")
        if not ok or not self:IsValueAccessible(action) then
            action = nil
        end
    end

    if type(action) == "number" then
        return action
    elseif type(action) == "string" then
        local convertOk, numericAction = pcall(tonumber, action)
        if convertOk then return numericAction end
    end
    return nil
end

local function ReadFrameBoolean(frame, methodName)
    if not frame then return true end
    local methodOk, method = pcall(function() return frame[methodName] end)
    if not methodOk or type(method) ~= "function" then return true end
    local ok, value = pcall(method, frame)
    if not ok or not addon:IsValueAccessible(value) then
        -- A secret Shown aspect must not prevent a display-only overlay from
        -- inheriting its parent's visibility.
        return true
    end
    return value ~= false
end

function addon:IsFrameShownSafe(frame)
    return ReadFrameBoolean(frame, "IsShown")
end

function addon:IsFrameVisibleSafe(frame)
    return ReadFrameBoolean(frame, "IsVisible")
end

local PROVIDER_ORDER = {
    "AzeriteUI",
    "Dominos",
    "Bartender4",
    "DiabolicUI3",
    "LUI",
    "Neuron",
    "Blizzard",
}

addon.ProviderRegistry = {
    Blizzard = {
        key = "Blizzard",
        label = "Blizzard",
        color_hex = "ffb4e0ff",
        color_rgb = {0.71, 0.88, 1.0},
        supported = true,
        hotkey_update_methods = { "UpdateHotkeys", "SetHotkeys" },
    },
    AzeriteUI = {
        key = "AzeriteUI",
        label = "AzeriteUI",
        addon = "AzeriteUI",
        addons = { "AzeriteUI", "AzeriteUI5_JuNNeZ_Edition" },
        globals = { "AzeriteUI" },
        color_hex = "ffe6c200",
        color_rgb = {0.90, 0.76, 0.00},
        supported = true,
        button_patterns = {
            "^AzeriteActionBar%d+Button%d+$",
            "^AzeritePetBarButton%d+$",
            "^AzeriteStanceBarButton%d+$",
        },
        binding_rules = {
            { matcher = "^AzeriteActionBar%d+Button%d+$", suffixes = { ":Keybind" } },
        },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "UpdateHotkeys",
    },
    Dominos = {
        key = "Dominos",
        label = "Dominos",
        addon = "Dominos",
        globals = { "Dominos" },
        color_hex = "ffb6ff00",
        color_rgb = {0.71, 1.0, 0.0},
        supported = true,
        rewrite_setting = "dominosRewrite",
        compatibility_note = "Dominos is supported directly. If a skin hides overlays on some bars, try 'Dominos: Use Native Text' in Display.",
        button_patterns = {
            "^DominosActionButton%d+$",
            "^MultiBarRightActionButton%d+$",
            "^MultiBarLeftActionButton%d+$",
            "^MultiBarBottomRightActionButton%d+$",
            "^MultiBarBottomLeftActionButton%d+$",
            "^MultiBar5ActionButton%d+$",
            "^MultiBar6ActionButton%d+$",
            "^MultiBar7ActionButton%d+$",
        },
        button_scanners = {
            globals = {
                { prefix = "DominosActionButton", max = 200 },
                { prefix = "MultiBarRightActionButton", max = 12 },
                { prefix = "MultiBarLeftActionButton", max = 12 },
                { prefix = "MultiBarBottomRightActionButton", max = 12 },
                { prefix = "MultiBarBottomLeftActionButton", max = 12 },
                { prefix = "MultiBar5ActionButton", max = 12 },
                { prefix = "MultiBar6ActionButton", max = 12 },
                { prefix = "MultiBar7ActionButton", max = 12 },
            },
            containers = {
                { prefix = "DominosBar", count = 20, matcher = "ActionButton%d+$" },
                { prefix = "DominosFrame", count = 20, matcher = "ActionButton%d+$" },
            },
        },
        binding_rules = {
            { matcher = "^DominosActionButton%d+$", suffixes = { ":HOTKEY", ":LeftButton", ":Button1", ":AnyUp", ":AnyDown", ":RightButton", ":Button2", ":MiddleButton", ":Button3" } },
            { matcher = "^MultiBar.+ActionButton%d+$", suffixes = { ":HOTKEY", ":LeftButton", ":Button1", ":AnyUp", ":AnyDown", ":RightButton", ":Button2", ":MiddleButton", ":Button3" } },
        },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "UpdateHotkeys",
    },
    Bartender4 = {
        key = "Bartender4",
        label = "Bartender4",
        addon = "Bartender4",
        color_hex = "fff69528",
        color_rgb = {0.96, 0.59, 0.16},
        supported = true,
        compatibility_note = "Bartender4 is supported directly through BT4 button discovery, LibActionButton binding targets, and :Keybind bindings.",
        button_patterns = {
            "^BT4Button%d+$",
            "^BT4PetButton%d+$",
            "^BT4StanceButton%d+$",
        },
        button_scanners = {
            globals = {
                { prefix = "BT4Button", max = 180 },
                { prefix = "BT4PetButton", max = 10 },
                { prefix = "BT4StanceButton", max = 10 },
            },
            containers = {
                { prefix = "BT4Bar", count = 15, matcher = "^BT4Button%d+" },
            },
        },
        binding_rules = {
            { matcher = "^BT4Button%d+$", suffixes = { ":Keybind" } },
            { matcher = "^BT4PetButton%d+$", suffixes = { ":LeftButton" } },
            { matcher = "^BT4StanceButton%d+$", suffixes = { ":LeftButton" } },
        },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "UpdateHotkeys",
    },
    DiabolicUI3 = {
        key = "DiabolicUI3",
        label = "DiabolicUI",
        addon = "DiabolicUI3",
        addons = { "DiabolicUI3", "DiabolicUI2" },
        color_hex = "ffdb3930",
        color_rgb = {0.86, 0.22, 0.19},
        supported = true,
        compatibility_note = "DiabolicUI support relies on the current Arahort edition button naming and action-button library.",
        button_patterns = {
            "^DiabolicActionBar%d+Button%d+$",
            "^DiabolicSmallActionBar%d+Button%d+$",
            "^DiabolicPetActionBarButton%d+$",
            "^DiabolicStanceBarButton%d+$",
        },
        button_scanners = {
            globals = {
                { prefix = "DiabolicActionBar1Button", max = 12 },
                { prefix = "DiabolicActionBar2Button", max = 12 },
                { prefix = "DiabolicActionBar3Button", max = 12 },
                { prefix = "DiabolicSmallActionBar1Button", max = 12 },
                { prefix = "DiabolicSmallActionBar2Button", max = 12 },
                { prefix = "DiabolicSmallActionBar3Button", max = 12 },
                { prefix = "DiabolicSmallActionBar4Button", max = 12 },
                { prefix = "DiabolicSmallActionBar5Button", max = 12 },
                { prefix = "DiabolicSmallActionBar6Button", max = 12 },
                { prefix = "DiabolicPetActionBarButton", max = 10 },
                { prefix = "DiabolicStanceBarButton", max = 10 },
            },
        },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "UpdateHotkeys",
    },
    -- LUI builds its bars from ActionBarButtonTemplate (LUIBarBottom1Button1,
    -- LUIBarLeft1Button1) and binds them as CLICK <button>:LeftButton; its pet and
    -- stance bars are Blizzard's own buttons.
    LUI = {
        key = "LUI",
        label = "LUI",
        addon = "LUI",
        color_hex = "ff3fa9f5",
        color_rgb = {0.25, 0.66, 0.96},
        supported = true,
        compatibility_note = "LUI is supported through its LUIBar buttons and their CLICK bindings.",
        button_patterns = {
            "^LUIBar%a+%d+Button%d+$",
        },
        button_scanners = {
            globals = {
                { prefix = "LUIBarBottom1Button", max = 12 },
                { prefix = "LUIBarBottom2Button", max = 12 },
                { prefix = "LUIBarBottom3Button", max = 12 },
                { prefix = "LUIBarBottom4Button", max = 12 },
                { prefix = "LUIBarBottom5Button", max = 12 },
                { prefix = "LUIBarBottom6Button", max = 12 },
                { prefix = "LUIBarLeft1Button", max = 12 },
                { prefix = "LUIBarLeft2Button", max = 12 },
                { prefix = "LUIBarRight1Button", max = 12 },
                { prefix = "LUIBarRight2Button", max = 12 },
            },
        },
        binding_rules = {
            { matcher = "^LUIBar%a+%d+Button%d+$", suffixes = { ":LeftButton" } },
        },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "UpdateHotkeys",
    },
    -- Neuron names its buttons <bar>_<type><n> (NeuronActionBar1_ActionButton3) and
    -- binds them with override bindings, which GetBindingKey cannot see: the keys are
    -- kept on the button as ":Q:SHIFT-E:" in button.keys.hotKeys, and its label is
    -- button.Hotkey (lower-case k), redrawn by ApplyBindings.
    Neuron = {
        key = "Neuron",
        label = "Neuron",
        addon = "Neuron",
        globals = { "Neuron" },
        color_hex = "ffa78bfa",
        color_rgb = {0.65, 0.55, 0.98},
        supported = true,
        compatibility_note = "Neuron is supported through its own key list on each button (it binds with override bindings).",
        button_patterns = {
            "^NeuronActionBar%d+_ActionButton%d+$",
            "^NeuronPetBar%d+_PetButton%d+$",
        },
        button_scanners = {
            containers = {
                { prefix = "NeuronActionBar", count = 30, matcher = "^NeuronActionBar%d+_ActionButton%d+$" },
                { prefix = "NeuronPetBar", count = 4, matcher = "^NeuronPetBar%d+_PetButton%d+$" },
            },
        },
        bound_keys_path = { "keys", "hotKeys" },
        hotkey_fields = { "Hotkey" },
        command_fields = { "commandName", "keyBoundTarget" },
        hotkey_update_method = "ApplyBindings",
    },
    ElvUI = {
        key = "ElvUI",
        label = "ElvUI",
        addon = "ElvUI",
        globals = { "ElvUI" },
        color_hex = "ff1784d1",
        color_rgb = {0.09, 0.52, 0.82},
        supported = false,
        conflict_only = true,
    },
}

function addon:GetProviderInfo(key)
    return self.ProviderRegistry[key or "Blizzard"] or self.ProviderRegistry.Blizzard
end

function addon:GetProviderLabel(key)
    return self:GetProviderInfo(key).label or tostring(key or "Blizzard")
end

function addon:GetProviderHexColor(key)
    return self:GetProviderInfo(key).color_hex or self.ProviderRegistry.Blizzard.color_hex
end

function addon:GetProviderColor(key)
    return self:GetProviderInfo(key).color_rgb or self.ProviderRegistry.Blizzard.color_rgb
end

function addon:IsProviderLoaded(key)
    if key == "Blizzard" then return true end
    local provider = self:GetProviderInfo(key)
    for _, globalName in ipairs(provider.globals or {}) do
        if rawget(_G, globalName) ~= nil then
            return true
        end
    end
    for _, addonName in ipairs(provider.addons or {}) do
        if IsAddOnLoadedCompat(addonName) then
            return true
        end
    end
    if provider.addon then
        return IsAddOnLoadedCompat(provider.addon)
    end
    return false
end

function addon:IsElvUIConflictActive()
    return self:IsProviderLoaded("ElvUI")
end

function addon:GetDetectedProviderKey()
    return self.detectedUI or "Blizzard"
end

function addon:GetDetectedProviderLabel()
    return self:GetProviderLabel(self:GetDetectedProviderKey())
end

function addon:GetDetectedProviderText()
    local label = self:GetDetectedProviderLabel()
    if self:IsElvUIConflictActive() and self:GetDetectedProviderKey() ~= "ElvUI" then
        return label .. " + ElvUI"
    end
    return label
end

function addon:IterateScannableProviders()
    local providers = {}
    for _, key in ipairs(PROVIDER_ORDER) do
        local provider = self.ProviderRegistry[key]
        if provider and provider.button_scanners then
            providers[#providers + 1] = provider
        end
    end
    return providers
end

function addon:GetProviderForButtonName(buttonName)
    if not buttonName then return nil end
    for _, key in ipairs(PROVIDER_ORDER) do
        local provider = self.ProviderRegistry[key]
        for _, pattern in ipairs(provider.button_patterns or {}) do
            if buttonName:match(pattern) then
                return provider
            end
        end
    end
    return self.ProviderRegistry.Blizzard
end

-- Every overlay update goes through Core:FullUpdate, which batches them (Performance.lua)
-- and takes the overlays down when AHOS is off or standing back for ElvUI.
function addon:UpdateAllButtons()
    if self.Core and self.Core.FullUpdate then self.Core:FullUpdate() end
end

-- Global reference for the options panel display name (keep this stable; do not include version)
_G.AHOS_OPTIONS_PANEL_NAME = "Advanced Hotkey Overlay System"

-- The options window (options/Panel.lua). It is the only one: the generated Ace3
-- window that used to sit beside it is gone.
_G.OpenAHOSOptionsPanel = function()
    local Kit = addonScope.OptionsKit
    local Panel = Kit and Kit.Panel
    if not Panel then
        addon:Print((addon.L and addon.L.OPTIONS_PANEL_NOT_AVAILABLE) or "[AHOS] The options window could not be loaded.")
        return
    end
    if Panel:IsShown() then Panel:Close(); return end
    Panel:Open()
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
        self:Print(string.format("[AHOS DEBUG] Processing %d queued calls.", #self.callQueue))
    end
    -- Taken off first: a queued call may queue another, which runs next time.
    local queue = self.callQueue
    self.callQueue = {}
    for _, call in ipairs(queue) do
        local module = self[call.moduleName]
        local func = type(call.func) == "string" and module and module[call.func] or call.func
        if module and type(func) == "function" then
            local ok, err = pcall(func, module, unpack(call.args, 1, call.args.n))
            if not ok then self:Print("|cffff0000Error:|r " .. call.moduleName .. ": " .. self:SafeToString(err, "unknown error")) end
        end
    end
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
        -- Queued until ready; the same call without arguments is queued once.
        local count = select("#", ...)
        if count == 0 then
            for _, call in ipairs(self.callQueue) do
                if call.moduleName == moduleName and call.func == func and call.args.n == 0 then return end
            end
        end
        table.insert(self.callQueue, { moduleName = moduleName, func = func, args = { n = count, ... } })
    end
end

-- Mark the addon as ready and process the call queue
function addon:SetReady()
    if self.ready then return end
    self.ready = true
    if self.db and self.db.profile.debug then
        self:Print("[AHOS DEBUG] Addon is now ready. Processing call queue.")
    end
    self:ProcessCallQueue()
    -- After the queue is processed, do a final full update to ensure UI is correct.
    self:SafeCall("Core", "FullUpdate")
    -- Bindings, combat, paging and vehicles are Core's (Core:RegisterEvents). A new
    -- zone can bring different bars (a vehicle, a scenario), so it refreshes too.
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        if self.db.profile.debug then self:Print("[AHOS DEBUG] ZONE_CHANGED_NEW_AREA: Updating overlays.") end
        self:UpdateAllButtons()
    end)
end

-- Called when the addon is initialized
function addon:OnInitialize()
    -- Initialize the database
    local defaults = self.Config:GetDynamicDefaults()
    self.db = LibStub("AceDB-3.0"):New("AdvancedHotkeyOverlaySystemDB", defaults, true) --[[@as AHOSDB]]
    -- The options window marks settings that differ from these.
    if addonScope.P then
        addonScope.P.DB = self.db
        addonScope.P.defaults = defaults
    end

    -- ESC > Options > AddOns: a landing page with a button into the options window.
    if addonScope.RegisterSettingsPage then addonScope.RegisterSettingsPage() end

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
            self:Print("[AHOS DEBUG] PLAYER_LOGIN detected. Running immediate and delayed overlay updates.")
        end
        self:DetectUI()
        self:SetReady() -- Mark as ready BEFORE any overlay updates
        -- Late bar addons are caught by Core's passes after PLAYER_ENTERING_WORLD.
        self:UpdateAllButtons()
    end)
    -- Setup minimap icon after DB is ready
    self:SetupMinimapButton()
    -- Remove overlay update event registrations from here
    if self.db.profile.debug then
        self:Print("[AHOS DEBUG] Addon initialized and all overlay update events registered.")
    end
    -- Show a popup if ElvUI is detected and overlays are not forced
    C_Timer.After(2, function() self:MaybeShowElvUIWarningOnLoad() end)
end

-- Called when the addon is enabled
function addon:OnEnable()
    if self.db and self.db.profile.enabled then
        self:SafeCall("Core", "OnEnable")
        if self.db.profile.debug then
            self:Print("[AHOS DEBUG] Addon enabled.")
        end
    end
end

-- Called when the addon is disabled
function addon:OnDisable()
    if self.db then
        self:SafeCall("Core", "OnDisable")
        if self.db.profile.debug then
            self:Print("[AHOS DEBUG] Addon disabled.")
        end
    end
end

-- Handle profile changes
function addon:OnProfileChanged(_, _, newProfileKey)
    if self.db.profile.debug then
        self:Print("[AHOS DEBUG] Profile changed to", newProfileKey)
    end
    -- Notify all modules of the profile change
    for name, module in self:IterateModules() do
        if module.OnProfileChanged then
            self:SafeCall(name, module.OnProfileChanged)
        end
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

-- Slash Command Handler
function AdvancedHotkeyOverlaySystem:SlashHandler(input)
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = (cmd and cmd:lower()) or ""
    local Loc = self and self.L or {}

    -- "classic" opened the old generated window, which is gone; it opens this one
    if cmd == "" or cmd == "show" or cmd == "options" or cmd == "ui" or cmd == "config" or cmd == "settings" or cmd == "classic" then
        if type(_G.OpenAHOSOptionsPanel) == "function" then
            _G.OpenAHOSOptionsPanel()
        else
            print(Loc.OPTIONS_PANEL_NOT_AVAILABLE or "[AHOS] Options panel function not available.")
        end

    elseif cmd == "lock" then
        self.db.profile.display.locked = true
        self.Core:FullUpdate()
        self:Print(Loc.MSG_SETTINGS_LOCKED or "|cffFFD700Settings locked|r - |cff888888protected from changes|r")

    elseif cmd == "unlock" then
        self.db.profile.display.locked = false
        self.Core:FullUpdate()
        self:Print(Loc.MSG_SETTINGS_UNLOCKED or "|cff4A9EFF Settings unlocked|r - |cff888888you can now modify settings|r")

    elseif cmd == "reset" then
        if self.Profiles and self.Profiles.TakeSnapshot then self.Profiles:TakeSnapshot(Loc.SNAPSHOT_BEFORE_RESET or "Before reset") end
        self.db:ResetProfile()
        self.Core:FullUpdate()
        self:Print(Loc.MSG_SETTINGS_RESET or "|cffFFD700Settings reset|r |cff888888to default values|r")

    elseif cmd == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        if self.db.profile.enabled then
            self.Core:OnEnable()
        else
            self.Core:OnDisable()
        end
        self:Print("Overlay " .. (self.db.profile.enabled and "|cff4A9EFFenabled|r" or "|cffFF6B6Bdisabled|r"))

    elseif cmd == "reload" or cmd == "refresh" then
        self.Core:FullUpdate()
        self:Print(Loc.MSG_OVERLAYS_RELOADED or "|cff4A9EFFOverlays reloaded|r |cff888888and refreshed|r")

    elseif cmd == "update" then
        if not self:IsReady() and UnitAffectingCombat("player") == false and IsLoggedIn() then
            self:Print(Loc.MSG_FORCE_READY or "[AHOS] Forcing addon ready state for update (player is in world).")
            self:SetReady()
        end
        self.Core:FullUpdate()
        self:Print(Loc.MSG_OVERLAYS_UPDATED or "|cff4A9EFFOverlays updated|r |cff888888(full update triggered)|r")

    elseif cmd == "cleanup" then
        self.Display:RemoveAllOverlays()
        self:Print(Loc.MSG_OVERLAYS_TEMP_CLEARED or "|cffFFD700Overlays temporarily cleared|r - |cff888888use Smart Refresh or change settings to restore|r")

    elseif cmd == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print((Loc.DEBUG_MODE_LABEL or "|cffFFD700Debug mode|r ") .. (self.db.profile.debug and (Loc.DEBUG_ENABLED or "|cff4A9EFFenabled|r") or (Loc.DEBUG_DISABLED or "|cffFF6B6Bdisabled|r")))

    elseif cmd == "detectui" then
        self:Print(Loc.MSG_MANUAL_DETECT_UI or "|cff4A9EFFManually detecting UI...|r")
        self:DetectUI()
        local providerKey = self:GetDetectedProviderKey()
        local color = self:GetProviderHexColor(providerKey) or "FFFFFFFF"
        local label = self:GetDetectedProviderText()
        self:Print((Loc.MSG_CURRENT_DETECTED_UI or "|cffFFD700Current detected UI:|r ") .. "|c" .. color .. label .. "|r")

    elseif cmd == "debugexport" then
        local path = rest and rest:match("^(%S+)")
        local tbl = addon.db and addon.db.profile
        if path and path ~= "" then
            for key in string.gmatch(path, "[^%.]+") do
                if tbl and type(tbl) == "table" then tbl = tbl[key] else tbl = nil; break end
            end
        end
        self:DebugExportTable(tbl)

    elseif cmd == "profile" or cmd == "profiles" then
        self.Profiles:SlashProfile(cmd == "profiles" and "" or rest)

    elseif cmd == "snapshot" then
        self.Profiles:SlashSnapshot(rest)

    elseif cmd == "rollback" or cmd == "undo" then
        self.Profiles:SlashRollback(rest)

    elseif cmd == "preset" or cmd == "presets" then
        self.Profiles:SlashPreset(cmd == "presets" and "" or rest)

    elseif cmd == "edit" then
        self.Editor:Toggle()

    elseif cmd == "ignore" or cmd == "unignore" then
        local buttonName = rest and rest:match("^(%S+)")
        if not buttonName or buttonName == "" then
            self:Print(Loc.USAGE_IGNORE or "|cffFF6B6BUsage:|r |cffFFD700/ahos ignore <ButtonName>|r, |cffFFD700/ahos unignore <ButtonName>|r")
        else
            self.Bars:SetButtonIgnored(buttonName, cmd == "ignore")
            self.Core:FullUpdate()
            self:Print(string.format(cmd == "ignore" and (Loc.MSG_BUTTON_IGNORED or "AHOS leaves %s alone.")
                or (Loc.MSG_BUTTON_UNIGNORED or "AHOS draws on %s again."), buttonName))
        end

    elseif cmd == "help" then
        self:Print(Loc.SLASH_HEADER or "|cffFFD700Advanced Hotkey Overlay System|r |cff4A9EFF- Commands:|r")
        self:Print(Loc.SLASH_SHOW or "|cffFFD700/ahos show|r - |cff888888Open options panel|r")
        self:Print(Loc.SLASH_LOCK or "|cffFFD700/ahos lock|r - |cff888888Lock overlay settings|r")
        self:Print(Loc.SLASH_UNLOCK or "|cffFFD700/ahos unlock|r - |cff888888Unlock overlay settings|r")
        self:Print(Loc.SLASH_RESET or "|cffFFD700/ahos reset|r - |cff888888Reset all settings to default|r")
        self:Print(Loc.SLASH_TOGGLE or "|cffFFD700/ahos toggle|r - |cff888888Enable/disable overlays|r")
        self:Print(Loc.SLASH_RELOAD or "|cffFFD700/ahos reload|r - |cff888888Reload and refresh overlays|r")
        self:Print(Loc.SLASH_REFRESH or "|cffFFD700/ahos refresh|r - |cff888888Smart refresh of overlays (same as UI button)|r")
        self:Print(Loc.SLASH_CLEANUP or "|cffFFD700/ahos cleanup|r - |cff888888Temporarily clear all overlays (same as UI button)|r")
        self:Print(Loc.SLASH_DEBUG or "|cffFFD700/ahos debug|r - |cff888888Toggle debug mode|r")
        self:Print(Loc.SLASH_DETECTUI or "|cffFFD700/ahos detectui|r - |cff888888Manually detect UI addon|r")
        self:Print(Loc.SLASH_EDIT or "|cffFFD700/ahos edit|r - |cff888888Drag the hotkey text into place on your bars|r")
        self:Print(Loc.SLASH_PROFILE or "|cffFFD700/ahos profile [name]|r - |cff888888List profiles, or switch to one (made from this one if new)|r")
        self:Print(Loc.SLASH_PRESET or "|cffFFD700/ahos preset [name]|r - |cff888888List the presets, or apply one|r")
        self:Print(Loc.SLASH_SNAPSHOT or "|cffFFD700/ahos snapshot [label]|r - |cff888888Save a copy of this profile to go back to|r")
        self:Print(Loc.SLASH_ROLLBACK or "|cffFFD700/ahos rollback [n]|r - |cff888888Put back the latest (or n-th) snapshot|r")
        self:Print(Loc.SLASH_IGNORE or "|cffFFD700/ahos ignore <ButtonName>|r - |cff888888Leave one button to its own hotkey text (unignore to undo)|r")
        self:Print(Loc.SLASH_HELP or "|cffFFD700/ahos help|r - |cff888888Show this help message|r")

    elseif cmd == "junnez" then
        self:Print(Loc.EASTER_EGG_JUNNEZ or "|cffFFD700Junnez is the secret overlord of hotkeys! |cff4A9EFF All your binds are belong to Junnez! |r")
        for i = 1, 3 do
            C_Timer.After(i * 0.5, function()
                local message = Loc.PRAISE_JUNNEZ or "Praise Junnez!"
                local color = ChatTypeInfo["RAID_WARNING"]
                if RaidWarningUtil and RaidWarningUtil.AddMessage then
                    RaidWarningUtil.AddMessage(message, color)
                elseif RaidWarningFrame and RaidWarningFrame.AddMessage then
                    RaidWarningFrame:AddMessage(message, color)
                end
            end)
        end
        PlaySound(12867)

    elseif cmd == "inspect" then
        local buttonName = rest and rest:match("^(%S+)")
        if not buttonName or buttonName == "" then
            self:Print(Loc.USAGE_INSPECT or "|cffFF6B6BUsage:|r |cffFFD700/ahos inspect <ButtonName>|r")
        else
            local button = _G[buttonName]
            if button then
                if self.Keybinds and self.Keybinds.GetButtonDebugInfo then
                    local info = self.Keybinds:GetButtonDebugInfo(button)
                    self:Print(info)
                else
                    self:Print(Loc.KEYBINDS_NOT_AVAILABLE or "|cffFF6B6BKeybinds module not available.|r")
                end
            else
                self:Print((Loc.BUTTON_NOT_FOUND_PREFIX or "|cffFF6B6BButton not found:|r ") .. "|cffFFD700" .. buttonName .. "|r")
            end
        end

    else
        self:Print((Loc.UNKNOWN_COMMAND_PREFIX or "|cffFF6B6BUnknown command:|r ") .. "|cffFFD700" .. cmd .. "|r")
        self:Print(Loc.TYPE_HELP_SUFFIX or "|cff888888Type|r |cffFFD700/ahos help|r |cff888888for available commands|r")
    end
end

-- The bar addon AHOS draws on: the first loaded one in PROVIDER_ORDER, else Blizzard.
function AdvancedHotkeyOverlaySystem:DetectUI()
    local detectedUI = "Blizzard"
    for _, key in ipairs(PROVIDER_ORDER) do
        if key ~= "Blizzard" and self:IsProviderLoaded(key) then
            detectedUI = key
            break
        end
    end

    self.detectedUI = detectedUI
    if self.db and self.db.profile and self.db.profile.debug then
        self:Print("[AHOS DEBUG] Detected provider: " .. (self:GetDetectedProviderText() or "None"))
    end
    -- the options window shows what AHOS draws on
    if addonScope.OnOptionsChanged then addonScope.OnOptionsChanged() end
    return detectedUI
end

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

-- Show a popup if ElvUI is detected and overlays are not forced
function addon:ShowElvUIOverlayWarning()
    if not self.elvuiDetected or (self.db and self.db.profile and self.db.profile.forceOverlaysWithElvUI) then return end
    if not StaticPopupDialogs["AHOS_ELVUI_WARNING"] then
        local L = addon and addon.L or {}
        StaticPopupDialogs["AHOS_ELVUI_WARNING"] = {
            text = L.ELVUI_WARNING_TEXT or "ElvUI detected! Both ElvUI and Advanced Hotkey Overlay System provide keybind overlays.\n\nDo you want to disable AHO overlays (recommended)?",
            button1 = L.ELVUI_WARNING_ACCEPT or "Yes (Disable AHO Overlays)",
            button2 = L.ELVUI_WARNING_CANCEL or "No (Keep Both)",
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
    if self.db and self.db.profile and self.db.profile.debug then
        self:Print("[AHOS DEBUG] ElvUI detected:", tostring(self.elvuiDetected), "forceOverlaysWithElvUI:", tostring(self.db.profile.forceOverlaysWithElvUI))
    end
    if self.elvuiDetected and self.db and self.db.profile and self.db.profile.forceOverlaysWithElvUI == nil then
        self:ShowElvUIOverlayWarning()
    end
end

local LibSerialize = LibStub and LibStub("LibSerialize", true)
local LibDeflate = LibStub and LibStub("LibDeflate", true)

-- Text to read and copy (the exports, the debug log, the inspector's details), in
-- the options window's look (options/TextWindow.lua). Should that have failed to
-- load, a plain frame does the same job.
local plainWindows = {}
local function PlainTextWindow(key, title, text)
    local f = plainWindows[key]
    if not f then
        f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetSize(640, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -36)
        scroll:SetPoint("BOTTOMRIGHT", -30, 44)
        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(580)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)
        local L = addon.L or {}
        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetText(L.CLOSE or "Close")
        close:SetSize(90, 22)
        close:SetPoint("BOTTOMRIGHT", -20, 12)
        close:SetScript("OnClick", function() f:Hide() end)
        local copy = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        copy:SetText(L.COPY_ALL or "Copy All")
        copy:SetSize(90, 22)
        copy:SetPoint("BOTTOMLEFT", 20, 12)
        copy:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText() end)
        f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.label:SetPoint("TOP", 0, -12)
        f.EditBox = eb
        plainWindows[key] = f
    end
    f.label:SetText(title or "")
    f.EditBox:SetText(text or "")
    f:Show()
end

-- Shows `text` in the window kept for `key` (one per kind, so the log can stay open
-- beside an export). `toEnd` scrolls to the bottom, as a log reads.
function addon:ShowTextWindow(title, text, key, toEnd)
    key = key or "text"
    local kit = addonScope.OptionsKit
    local ok = kit and kit.TextWindow and pcall(kit.TextWindow.Show, kit.TextWindow, key, title, text, toEnd)
    if not ok then PlainTextWindow(key, title, text) end
end

function addon:IsTextWindowShown(key)
    local kit = addonScope.OptionsKit
    if kit and kit.TextWindow and kit.TextWindow:IsShown(key) then return true end
    local plain = plainWindows[key]
    return plain and plain:IsShown() or false
end

function addon:ShowDebugExportWindow(data)
    local L = addon.L or {}
    self:ShowTextWindow(L.DEBUG_EXPORT_TITLE or "AHOS Debug Export", data or "[No data]", "export")
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

-- debugexport handled inside SlashHandler above

function addon.ImportProfileString(...)
    -- Called both as addon.ImportProfileString(text) and addon:ImportProfileString(text); with the colon the
    -- first argument is the addon itself, which used to be read as the string.
    local val = ...
    if val == addon then val = select(2, ...) end
    local str = val
    if type(val) == "table" then
        str = val.text or val.value or ""
    end
    local L = addon and addon.L or {}
    if not str or str == "" then addon:Print(L.NO_IMPORT_STRING or "No import string provided."); return end
    if not LibDeflate or not LibSerialize then addon:Print(L.ERR_LIBS_MISSING or "LibDeflate/LibSerialize missing."); return end
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then addon:Print(L.ERR_DECODE_FAILED or "Failed to decode string."); return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then addon:Print(L.ERR_DECOMPRESS_FAILED or "Failed to decompress string."); return end
    local success, tbl = LibSerialize:Deserialize(decompressed)
    if not success or type(tbl) ~= "table" then addon:Print(L.ERR_DESERIALIZE_FAILED or "Failed to deserialize string."); return end
    if addon.db and addon.db.profile then
        if addon.Profiles and addon.Profiles.TakeSnapshot then addon.Profiles:TakeSnapshot(L.SNAPSHOT_BEFORE_IMPORT or "Before import") end
        for k, v in pairs(tbl) do addon.db.profile[k] = v end
    addon:Print(L.PROFILE_IMPORTED_OK or "Profile imported successfully. Reload UI to apply all changes.")
        addon.Core:FullUpdate()
    end
end

function addon.DebugImportString(...)
    -- Called both as addon.DebugImportString(text) and addon:DebugImportString(text); with the colon the
    -- first argument is the addon itself, which used to be read as the string.
    local val = ...
    if val == addon then val = select(2, ...) end
    local str = val
    if type(val) == "table" then
        str = val.text or val.value or ""
    end
    local L = addon and addon.L or {}
    if not str or str == "" then addon:Print(L.NO_DEBUG_IMPORT_STRING or "No debug import string provided."); return end
    if not LibDeflate or not LibSerialize then addon:Print(L.ERR_LIBS_MISSING or "LibDeflate/LibSerialize missing."); return end
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then addon:Print(L.ERR_DECODE_FAILED or "Failed to decode string."); return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then addon:Print(L.ERR_DECOMPRESS_FAILED or "Failed to decompress string."); return end
    local success, tbl = LibSerialize:Deserialize(decompressed)
    if not success then addon:Print(L.ERR_DESERIALIZE_FAILED or "Failed to deserialize string."); return end
    addon:ShowDebugExportWindow(tbl and addon:TableToPrettyString(tbl) or "[No data]")
end

-- Utility: Pretty-print a table as a string for debug window
function addon:TableToPrettyString(tbl, indent)
    indent = indent or 0
    if type(tbl) ~= "table" then return tostring(tbl) end
    local str = ""
    for k, v in pairs(tbl) do
        str = str .. string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            str = str .. "\n" .. self:TableToPrettyString(v, indent + 1)
        else
            str = str .. tostring(v) .. "\n"
        end
    end
    return str
end

-- Switching profiles by specialization or talent loadout is modules/Profiles.lua's.

-- Performance Metrics
addon.perfMetrics = {}
function addon:LogPerfMetric(name, duration)
    self.perfMetrics[name] = duration
    if self.db and self.db.profile and self.db.profile.showPerfMetrics then
        self:Print(string.format("[Perf] %s: %.2f ms", name, duration * 1000))
    end
end

-- Debug Log Window
addon.debugLogBuffer = addon.debugLogBuffer or {}
function addon:LogDebug(msg)
    if not msg then return end
    table.insert(self.debugLogBuffer, tostring(msg))
    if #self.debugLogBuffer > 200 then table.remove(self.debugLogBuffer, 1) end -- keep last 200 lines
    self:UpdateDebugLogWindow()
end

function addon:ShowDebugLogWindow()
    local L = self.L or {}
    self:ShowTextWindow(L.DEBUG_LOG_TITLE or "AHOS Debug Log", table.concat(self.debugLogBuffer, "\n"), "log", true)
end

function addon:UpdateDebugLogWindow()
    if not self:IsTextWindowShown("log") then return end
    self:ShowDebugLogWindow()
end

-- addon:Print keeps everything in the debug log (/ahoslog). What is said to you
-- (command replies, imports, warnings) also goes to the chat; debug lines, which
-- all start with [AHOS DEBUG] (or [Perf]), stay in the log so chat is not flooded.
addon._origPrint = addon._origPrint or addon.Print
local function IsDebugLine(msg)
    return msg:find("^%[AHOS DEBUG%]") or msg:find("^%[Perf%]")
end
function addon:Print(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = self:SafeToString(select(i, ...))
    end
    local msg = table.concat(parts, " ")
    self:LogDebug(msg)
    if not IsDebugLine(msg) and self._origPrint then
        self:_origPrint(msg)
    end
end

-- Slash command to open debug log window
SLASH_AHOSDEBUGLOG1 = "/ahoslog"
SlashCmdList["AHOSDEBUGLOG"] = function()
    addon:ShowDebugLogWindow()
end
