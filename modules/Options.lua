-- modules/Options.lua
---@diagnostic disable: undefined-global
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
local L = addon.L or {}
---@class AHOSOptions
local Options = addon.Options
local Groups

Options.selectedProfile = nil

local function getVersionString()
    return ((C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
        or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version"))
        or "unknown")
end

local function getDisplayUIName(name)
    if addon and addon.GetProviderLabel then
        return addon:GetProviderLabel(name)
    end
    return tostring(name or "Blizzard")
end

local function getDetectedUIName()
    return (addon and addon.GetDetectedProviderKey and addon:GetDetectedProviderKey())
        or (addon.Config and addon.Config.GetDetectedUI and addon.Config:GetDetectedUI())
        or addon.detectedUI
        or "Blizzard"
end

local function getDetectedUIText()
    return (addon and addon.GetDetectedProviderText and addon:GetDetectedProviderText())
        or getDisplayUIName(getDetectedUIName())
end

local function isProviderLoaded(key)
    return addon and addon.IsProviderLoaded and addon:IsProviderLoaded(key)
end

local function getLoadedProviderNotes()
    local notes = {}
    for _, key in ipairs({ "Dominos", "Bartender4", "DiabolicUI3", "LUI", "Neuron" }) do
        local provider = addon and addon.GetProviderInfo and addon:GetProviderInfo(key)
        if provider and provider.compatibility_note and isProviderLoaded(key) then
            notes[#notes + 1] = "- " .. provider.compatibility_note
        end
    end
    if #notes == 0 then
        notes[#notes + 1] = "- No direct third-party provider is currently loaded."
    end
    return table.concat(notes, "\n")
end

local function getDiagnosticsSummary()
    local diagnostics = addon and addon.Bars and addon.Bars.GetDiagnostics and addon.Bars:GetDiagnostics()
    if not diagnostics then
        return "Detected buttons: unavailable"
    end

    local parts = { "Detected buttons: " .. tostring(diagnostics.total or 0) }
    local providerParts = {}
    for _, key in ipairs({ "Blizzard", "AzeriteUI", "Dominos", "Bartender4", "DiabolicUI3", "LUI", "Neuron" }) do
        local count = diagnostics.providers and diagnostics.providers[key]
        if count and count > 0 then
            providerParts[#providerParts + 1] = string.format("%s %d", getDisplayUIName(key), count)
        end
    end
    if #providerParts > 0 then
        parts[#parts + 1] = "By provider: " .. table.concat(providerParts, ", ")
    end
    return table.concat(parts, "\n")
end

local function getSupportBlurb()
    return table.concat({
        "AHOS only adds direct integrations for bar providers that expose stable button names, binding commands, and hotkey refresh hooks.",
        "",
        "Dedicated support:",
        "- Blizzard action bars",
        "- AzeriteUI",
        "- Dominos",
        "- Bartender4",
        "- DiabolicUI",
        "- LUI",
        "- Neuron",
        "",
        "Conflict-aware handling:",
        "- ElvUI",
        "",
        "Current detected provider: " .. getDetectedUIText(),
        "",
        getLoadedProviderNotes(),
    }, "\n")
end

local function getSafeProfile()
    if addon and addon.db and addon.db.profile then
        return addon.db.profile
    end
    return setmetatable({}, { __index = function() return nil end })
end

local function isLocked()
    local db = getSafeProfile()
    return db.display and db.display.locked
end

local function RefreshOverlayStyles()
    if addon and addon.IsReady and addon:IsReady()
        and addon.Display and addon.Display.UpdateAllOverlayStyles then
        addon.Display:UpdateAllOverlayStyles()
    end
end

local OUTLINE_ALIASES = {
    MONOCHROMEOUTLINE = "MONOCHROME,OUTLINE",
    MONOCHROMETHICKOUTLINE = "MONOCHROME,THICKOUTLINE",
}

-- profile.text.modifierColors, made if an old profile has none.
local function getModifierColors()
    local db = getSafeProfile()
    if type(db.text) ~= "table" then return {} end
    if type(db.text.modifierColors) ~= "table" then db.text.modifierColors = {} end
    return db.text.modifierColors
end

local function modifierColorOption(kind, order, name)
    return {
        type = "color",
        name = name,
        desc = L.MODIFIER_COLOR_DESC or "The text colour for bindings with this modifier.",
        order = order,
        hasAlpha = false,
        disabled = function() return not getModifierColors().enabled end,
        get = function()
            local color = getModifierColors()[kind]
            if type(color) == "table" then return color[1], color[2], color[3] end
        end,
        set = function(_, r, g, b)
            getModifierColors()[kind] = { r, g, b }
            RefreshOverlayStyles()
        end,
    }
end

-- profile.<section>.<name> as a table, made if an old profile has none.
local function getSub(section, name)
    local db = getSafeProfile()
    if type(db[section]) ~= "table" then return {} end
    if type(db[section][name]) ~= "table" then db[section][name] = {} end
    return db[section][name]
end

local function getVisibility()
    local db = getSafeProfile()
    if type(db.visibility) ~= "table" then db.visibility = {} end
    return db.visibility
end

local function RefreshVisibility()
    if addon.Visibility and addon.Visibility.OnSettingsChanged then addon.Visibility:OnSettingsChanged() end
    RefreshOverlayStyles()
end

-- A colour option on a table at `get()`'s key `key`.
local function colorOption(order, name, desc, getTable, key, hasAlpha, disabled, after)
    return {
        type = "color",
        name = name,
        desc = desc,
        order = order,
        hasAlpha = hasAlpha and true or false,
        disabled = disabled,
        get = function()
            local color = getTable()[key]
            if type(color) == "table" then return color[1], color[2], color[3], color[4] end
        end,
        set = function(_, r, g, b, a)
            getTable()[key] = hasAlpha and { r, g, b, a } or { r, g, b }
            ;(after or RefreshOverlayStyles)()
        end,
    }
end

local function RefreshAbbreviations()
    if addon.Keybinds and addon.Keybinds.ClearCache then
        addon.Keybinds:ClearCache()
    end
    if addon.IsReady and addon:IsReady() and addon.Core and addon.Core.FullUpdate then
        addon.Core:FullUpdate()
    end
end

local function isSmartStrataEnabled()
    local db = getSafeProfile()
    if not db.display then return false end
    if db.display.smartStrata == nil then return false end
    return db.display.smartStrata and true or false
end

-- The pages are built by modules/Options*.lua into Options.Groups; the helpers
-- they share are here.
Options.Groups = Options.Groups or {}
Options.Helpers = {
    getVersionString = getVersionString,
    getDisplayUIName = getDisplayUIName,
    getDetectedUIName = getDetectedUIName,
    getDetectedUIText = getDetectedUIText,
    isProviderLoaded = isProviderLoaded,
    getLoadedProviderNotes = getLoadedProviderNotes,
    getDiagnosticsSummary = getDiagnosticsSummary,
    getSupportBlurb = getSupportBlurb,
    getSafeProfile = getSafeProfile,
    isLocked = isLocked,
    RefreshOverlayStyles = RefreshOverlayStyles,
    OUTLINE_ALIASES = OUTLINE_ALIASES,
    getModifierColors = getModifierColors,
    modifierColorOption = modifierColorOption,
    getSub = getSub,
    getVisibility = getVisibility,
    RefreshVisibility = RefreshVisibility,
    colorOption = colorOption,
    RefreshAbbreviations = RefreshAbbreviations,
    isSmartStrataEnabled = isSmartStrataEnabled,
}

-- The options window needs one table for as long as it is open: the "changed from
-- default" marks and the rows it binds are keyed by the option tables themselves.
-- GetOptions builds a fresh one each time it is called.
function Options:GetPanelOptions()
    if not self.panelOptions and addon.db and addon.db.profile then
        self.panelOptions = self:GetOptions()
        local args = self.panelOptions.args or {}
        local font = args.text and args.text.args and args.text.args.font
        local anchor = args.display and args.display.args and args.display.args.anchor
        privateScope.PanelMeta = privateScope.PanelMeta or setmetatable({}, { __mode = "k" })
        if font then
            -- The window draws each font's name in that font.
            privateScope.PanelMeta[font] = {
                rowFont = function(name)
                    return addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(name)
                end,
            }
        end
        if anchor then
            -- and the anchor point as a 3x3 grid on a button.
            privateScope.PanelMeta[anchor] = { anchorGrid = true }
        end
        local barAnchor = args.bars and args.bars.args and args.bars.args.anchor
        if barAnchor then privateScope.PanelMeta[barAnchor] = { anchorGrid = true } end
    end
    return self.panelOptions
end

function Options:GetOptions()
    Groups = Options.Groups
    -- If the database isn't ready, provide a placeholder options table.
    if not addon.db or not addon.db.profile then
    return {
            type = "group",
        name = _G.AHOS_OPTIONS_PANEL_NAME or L.OPTIONS_PANEL_NAME or "AHOS Options",
            args = {
                info = {
                    type = "description",
            name = L.ADDON_INITIALIZING or "Addon is initializing. Please close and reopen this window in a few seconds.",
                    order = 1,
                },
            },
        }
    end

    return {
        type = "group",
    name = _G.AHOS_OPTIONS_PANEL_NAME or L.OPTIONS_PANEL_NAME or "AHOS Options",
        disabled = isLocked,
        get = function(info)
            local db = getSafeProfile()
            return db[info[#info]]
        end,
        set = function(info, value)
            local db = getSafeProfile()
            if db.display and db.display.locked then
                if not StaticPopupDialogs["AHOS_UNLOCK_SETTINGS"] then
                    StaticPopupDialogs["AHOS_UNLOCK_SETTINGS"] = {
                        text = L.UNLOCK_SETTINGS_PROMPT or "The settings are locked. Do you want to unlock?",
                        button1 = L.YES or "Yes",
                        button2 = L.NO or "No",
                        OnAccept = function()
                            db.display.locked = false
                            addon:Print(L.MSG_SETTINGS_UNLOCKED or "|cff4A9EFFSettings unlocked|r - |cff888888you can now modify settings|r")
                            -- Re-apply the change
                            Options.lastSet(info, value)
                        end,
                        OnCancel = function() end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                end
                Options.lastSet = function(i, v)
                    local db2 = getSafeProfile()
                    db2[i[#i]] = v
                    if addon:IsReady() then addon.Core:FullUpdate() end
                end
                StaticPopup_Show("AHOS_UNLOCK_SETTINGS")
                return
            end
            db[info[#info]] = value
            if addon:IsReady() then
                addon.Core:FullUpdate()
            end
        end,
        args = {
            status = Groups.status(),
            display = Groups.display(),
            text = Groups.text(),
            abbreviations = Groups.abbreviations(),
            bars = Groups.bars(),
            profiles = Groups.profiles(),
            integration = Groups.integration(),
            inspector = Groups.inspector(),
            debug = Groups.debug(),
            about = Groups.about(),
        },
    }
end
