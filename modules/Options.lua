-- modules/Options.lua
---@diagnostic disable: undefined-global
local addonName, privateScope = ...
local addon = privateScope.addon
local L = addon.L or {}
local Options = addon.Options

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
    for _, key in ipairs({ "Dominos", "Bartender4", "DiabolicUI3" }) do
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
    for _, key in ipairs({ "Blizzard", "AzeriteUI", "Dominos", "Bartender4", "DiabolicUI3" }) do
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

local function isSmartStrataEnabled()
    local db = getSafeProfile()
    if not db.display then return false end
    if db.display.smartStrata == nil then return false end
    return db.display.smartStrata and true or false
end

function Options:GetOptions()
    -- If the database isn't ready, provide a placeholder options table.
    local db_check = getSafeProfile()
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
            toggles = {
                type = "group",
                inline = true,
                order = 0,
                name = "",
                args = {
                    enable = {
                        type = "toggle",
                        name = "|cff3399ff" .. (L.ENABLE_ADDON or "Enable Addon") .. "|r",
                        desc = L.ENABLE_ADDON_DESC or "Enable or disable the addon.",
                        order = 1,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.enabled end,
                        set = function(_, val) local db = getSafeProfile() db.enabled = val if val then addon.Core:OnEnable() else addon.Core:OnDisable() end if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    autodetect = {
                        type = "toggle",
                        name = "|cff3399ff" .. (L.AUTO_DETECT_UI or "Auto-Detect UI") .. "|r",
                        desc = L.AUTO_DETECT_UI_DESC or "Automatically detect your action bar UI.",
                        order = 2,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.autoDetectUI end,
                        set = function(_, val) local db = getSafeProfile() db.autoDetectUI = val if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    debug = {
                        type = "toggle",
                        name = "|cff3399ff" .. (L.DEBUG_MODE or "Debug Mode") .. "|r",
                        desc = L.DEBUG_MODE_DESC or "Enable verbose debug logging.",
                        order = 3,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.debug end,
                        set = function(_, val) local db = getSafeProfile() db.debug = val if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    lock = {
                        type = "execute",
                        name = function() local db = getSafeProfile() return db.display and db.display.locked and (L.UNLOCK_SETTINGS or "Unlock Settings") or (L.LOCK_SETTINGS or "Lock Settings") end,
                        desc = L.LOCK_SETTINGS_DESC or "Lock or unlock all settings to prevent accidental changes.",
                        order = 4,
                        disabled = false, -- Always enabled, even when locked
                        func = function()
                            local db = getSafeProfile()
                            db.display = db.display or {}
                            db.display.locked = not db.display.locked
                            addon:Print(db.display.locked and (L.MSG_SETTINGS_LOCKED or "|cffFFD700Settings locked|r - |cff888888protected from changes|r") or (L.MSG_SETTINGS_UNLOCKED or "|cff4A9EFFSettings unlocked|r - |cff888888you can now modify settings|r"))
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                },
            },
            status = {
                type = "group",
                name = L.STATUS or "Status",
                order = 0.5,
                args = {
                    summary = {
                        type = "description",
                        order = 1,
                        name = function()
                            local db = getSafeProfile()
                            local enabled = db.enabled and "Enabled" or "Disabled"
                            local mode = (db.display and db.display.nativeRewrite) and "Native text rewrite" or "Overlay"
                            return table.concat({
                                "Version: " .. getVersionString(),
                                "Detected provider: " .. getDetectedUIText(),
                                "Render mode: " .. mode,
                                "Addon state: " .. enabled,
                                getDiagnosticsSummary(),
                            }, "\n")
                        end,
                    },
                    refresh = {
                        type = "execute",
                        name = L.REFRESH_OVERLAYS or "Refresh Overlays",
                        desc = L.REFRESH_OVERLAYS_DESC or "Run a full overlay refresh now.",
                        order = 2,
                        width = "full",
                        func = function()
                            if addon and addon.Core and addon.Core.FullUpdate then
                                addon.Core:FullUpdate()
                            end
                        end,
                    },
                    detect = {
                        type = "execute",
                        name = L.DETECT_UI_NOW or "Re-Detect UI Now",
                        desc = L.DETECT_UI_NOW_DESC or "Run UI detection again and refresh overlays.",
                        order = 3,
                        width = "full",
                        func = function()
                            if addon and addon.DetectUI then
                                addon:DetectUI()
                            end
                            if addon and addon.Core and addon.Core.FullUpdate then
                                addon.Core:FullUpdate()
                            end
                        end,
                    },
                },
            },
            display = {
                type = "group",
                name = L.DISPLAY or "Display",
                order = 1,
                args = {
                    modeHeader = {
                        type = "description",
                        name = L.RENDER_MODE_INFO or "Choose whether AHOS draws its own overlay text or rewrites the button's native hotkey text.",
                        order = 0.4,
                    },
                    nativeRewrite = {
                        type = "toggle",
                        name = L.USE_NATIVE_REWRITE or "Use Native Text",
                        desc = L.USE_NATIVE_REWRITE_DESC or "Rewrite the button's native hotkey text instead of drawing a separate overlay.",
                        order = 0.5,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.nativeRewrite end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.nativeRewrite = val; addon.Core:FullUpdate() end end,
                    },
                    dominosRewrite = {
                        type = "toggle",
                        name = L.DOMINOS_USE_NATIVE or "Dominos: Use Native Text",
                        desc = L.DOMINOS_USE_NATIVE_DESC or "For Dominos buttons, rewrite the native hotkey text (overlay is default).",
                        order = 0.6,
                        width = "full",
                        hidden = function() return not isProviderLoaded("Dominos") end,
                        get = function() local db = getSafeProfile() return db.display and db.display.dominosRewrite end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.dominosRewrite = val; addon.Core:FullUpdate() end end,
                    },
                    autoNativeFallback = {
                        type = "toggle",
                        name = L.AUTO_NATIVE_FALLBACK or "Auto Fallback to Native",
                        desc = L.AUTO_NATIVE_FALLBACK_DESC or "If an overlay appears hidden by a skin, automatically rewrite the native hotkey for that button.",
                        order = 0.7,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.autoNativeFallback end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.autoNativeFallback = val; addon.Core:FullUpdate() end end,
                    },
                    hideOriginal = {
                        type = "toggle",
                        name = L.HIDE_ORIGINAL or "Hide Original Hotkey Text",
                        desc = L.HIDE_ORIGINAL_DESC or "Hides the default hotkey text on action buttons.",
                        order = 1,
                        get = function()
                            local db = getSafeProfile()
                            return db.display and db.display.hideOriginal
                        end,
                        set = function(info, val)
                            local db = getSafeProfile()
                            if db.display then
                                db.display.hideOriginal = val
                                addon.Core:FullUpdate()
                            end
                        end,
                    },
                    anchor = {
                        type = "select",
                        name = L.ANCHOR_POINT or "Anchor Point",
                        desc = L.ANCHOR_POINT_DESC or "The point on the button where the text is anchored.",
                        order = 2,
                        values = { TOPLEFT = "TOPLEFT", TOP = "TOP", TOPRIGHT = "TOPRIGHT", LEFT = "LEFT", CENTER = "CENTER", RIGHT = "RIGHT", BOTTOMLEFT = "BOTTOMLEFT", BOTTOM = "BOTTOM", BOTTOMRIGHT = "BOTTOMRIGHT" },
                        get = function() local db = getSafeProfile() return db.display and db.display.anchor end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.anchor = val; addon.Core:FullUpdate() end end,
                    },
                    xOffset = {
                        type = "range",
                        name = L.X_OFFSET or "X Offset",
                        desc = L.X_OFFSET_DESC or "Horizontal offset from the anchor point.",
                        order = 3,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.xOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.xOffset = val; addon.Core:FullUpdate() end end,
                    },
                    yOffset = {
                        type = "range",
                        name = L.Y_OFFSET or "Y Offset",
                        desc = L.Y_OFFSET_DESC or "Vertical offset from the anchor point.",
                        order = 4,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.yOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.yOffset = val; addon.Core:FullUpdate() end end,
                    },
                    scale = {
                        type = "range",
                        name = L.SCALE or "Scale",
                        desc = L.SCALE_DESC or "The scale of the overlay text.",
                        order = 5,
                        min = 0.1, max = 2, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.scale end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.scale = val; addon.Core:FullUpdate() end end,
                    },
                    alpha = {
                        type = "range",
                        name = L.ALPHA or "Alpha",
                        desc = L.ALPHA_DESC or "The transparency of the overlay text.",
                        order = 6,
                        min = 0, max = 1, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.alpha end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.alpha = val; addon.Core:FullUpdate() end end,
                    },
                    smartStrata = {
                        type = "toggle",
                        name = L.SMART_STRATA or "Smart Frame Layering",
                        desc = L.SMART_STRATA_DESC or "Keeps overlays on the same strata as their parent buttons to avoid overlapping unrelated UI (for example bags). Disable to use manual strata and frame level overrides.",
                        order = 7,
                        width = "full",
                        get = isSmartStrataEnabled,
                        set = function(_, val)
                            local db = getSafeProfile()
                            if db.display then
                                db.display.smartStrata = val and true or false
                                addon.Core:FullUpdate()
                            end
                        end,
                    },
                    strata = {
                        type = "select",
                        name = L.OVERLAY_STRATA or "Overlay Frame Strata",
                        desc = L.OVERLAY_STRATA_DESC or "Manual override: sets the drawing layer for overlays when Smart Frame Layering is disabled.",
                        order = 8,
                        values = {
                            BACKGROUND = "Background",
                            LOW = "Low",
                            MEDIUM = "Medium",
                            HIGH = "High",
                            DIALOG = "Dialog",
                            TOOLTIP = "Tooltip",
                        },
                        disabled = isSmartStrataEnabled,
                        get = function() local db = getSafeProfile() return db.display and db.display.strata or "HIGH" end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.strata = val; addon.Core:FullUpdate() end end,
                    },
                    frameLevel = {
                        type = "range",
                        name = L.OVERLAY_LEVEL or "Overlay Frame Level",
                        desc = L.OVERLAY_LEVEL_DESC or "Manual override: fine-tune overlay stacking within the chosen strata when Smart Frame Layering is disabled.",
                        order = 9,
                        min = 1, max = 128, step = 1,
                        disabled = isSmartStrataEnabled,
                        get = function() local db = getSafeProfile() return db.display and db.display.frameLevel or 10 end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.frameLevel = val; addon.Core:FullUpdate() end end,
                    },
                    followNativeHotkeyStyle = {
                        type = "toggle",
                        name = L.MIRROR_NATIVE_STYLE or "Mirror Native Hotkey Style",
                        desc = L.MIRROR_NATIVE_STYLE_DESC or "Overlay text will mirror the native hotkey font, color, and position when available.",
                        order = 10,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.followNativeHotkeyStyle end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.followNativeHotkeyStyle = val; addon.Core:FullUpdate() end end,
                    },
                },
            },
            text = {
                type = "group",
                name = L.KEYBINDS or "Keybinds",
                order = 2,
                args = {
                    font = {
                        type = "select",
                        name = L.FONT or "Font",
                        desc = L.FONT_DESC or "The font for the overlay text.",
                        order = 1,
                        values = function()
                            if addon.Config and addon.Config.GetFontList then
                                local list = addon.Config:GetFontList()
                                local out = {}
                                for _, name in ipairs(list) do
                                    out[name] = name
                                end
                                return out
                            end
                            return { ["Default"] = "Default" }
                        end,
                        get = function() local db = getSafeProfile() return db.text and db.text.font end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.font = val; addon.Core:FullUpdate() end end,
                    },
                    fontSize = {
                        type = "range",
                        name = L.FONT_SIZE or "Font Size",
                        desc = L.FONT_SIZE_DESC or "The size of the font.",
                        order = 2,
                        min = 6, max = 48, step = 1,
                        get = function() local db = getSafeProfile() return db.text and db.text.fontSize end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.fontSize = val; addon.Core:FullUpdate() end end,
                    },
                    color = {
                        type = "color",
                        name = L.FONT_COLOR or "Font Color",
                        desc = L.FONT_COLOR_DESC or "The color of the font.",
                        order = 3,
                        hasAlpha = false,
                        get = function() local db = getSafeProfile() if db.text and db.text.color then return unpack(db.text.color) end end,
                        set = function(info, r, g, b) local db = getSafeProfile() if db.text then db.text.color = {r, g, b}; addon.Core:FullUpdate() end end,
                    },
                    outlineStyle = {
                        type = "select",
                        name = L.FONT_OUTLINE or "Font Outline",
                        desc = L.FONT_OUTLINE_DESC or "Choose font outline and monochrome options.",
                        order = 4,
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                            ["MONOCHROME,OUTLINE"] = "Monochrome + Outline",
                            ["MONOCHROME,THICKOUTLINE"] = "Monochrome + Thick Outline",
                            ["MONOCHROMEOUTLINE"] = "MonochromeOutline (alias)",
                            ["MONOCHROMETHICKOUTLINE"] = "MonochromeThickOutline (alias)",
                        },
                        get = function()
                            local db = getSafeProfile()
                            if db.text then
                                if db.text.outlineStyle and db.text.outlineStyle ~= "" then
                                    return db.text.outlineStyle
                                end
                                -- Legacy fallback: boolean outline => OUTLINE/NONE
                                if db.text.outline ~= nil then
                                    return db.text.outline and "OUTLINE" or "NONE"
                                end
                            end
                            return "OUTLINE"
                        end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            if db.text then
                                db.text.outlineStyle = val
                                -- keep legacy key for backward compat off by default
                                db.text.outline = (val == "OUTLINE" or val == "THICKOUTLINE" or val:find("OUTLINE", 1, true) ~= nil)
                                addon.Core:FullUpdate()
                            end
                        end,
                    },
                    abbreviations = {
                        type = "toggle",
                        name = L.ABBREVIATIONS or "Enable Abbreviations",
            desc = L.ABBREVIATIONS_DESC or "Abbreviate keybind text (e.g., SHIFT -> S).",
                        order = 5,
                        get = function() local db = getSafeProfile() return db.text and db.text.abbreviations end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.abbreviations = val; addon.Core:FullUpdate() end end,
                    },
                    maxLength = {
                        type = "range",
                        name = L.MAX_LENGTH or "Max Length",
            desc = L.MAX_LENGTH_DESC or "Maximum length of the abbreviated text.",
                        order = 6,
                        min = 1, max = 10, step = 1,
                        get = function() local db = getSafeProfile() return db.text and db.text.maxLength end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.maxLength = val; addon.Core:FullUpdate() end end,
                    },
                    modSeparator = {
                        order = 20,
                        type = "input",
                        name = L.MOD_SEPARATOR or "Modifier Separator",
            desc = L.MOD_SEPARATOR_DESC or "String to insert between modifiers and key (leave empty for none, e.g. SM4).",
                        width = "half",
                        get = function() return addon.db.profile.text.modSeparator or "" end,
                        set = function(_, val)
                            addon.db.profile.text.modSeparator = val
                            addon:SafeCall("Core", "FullUpdate")
                        end,
                    },
                },
            },
            profiles = {
                type = "group",
        name = L.PROFILES or "Profiles Management",
                order = 3,
                args = {
                    aceProfiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
                    profileTools = {
                        type = "group",
            name = L.PROFILE_MANAGEMENT or "Profile Tools",
                        order = 2,
                        args = {
                            currentProfile = {
                                type = "description",
                                name = function()
                                    if addon.db and addon.db:GetCurrentProfile() then
                    return (L.CURRENT_PROFILE_LABEL or "|cff4A9EFFCurrent Profile:|r ") .. "|cffffd700" .. addon.db:GetCurrentProfile() .. "|r"
                                    else
                    return (L.CURRENT_PROFILE_LABEL or "|cff4A9EFFCurrent Profile:|r ") .. "|cffffd700" .. (L.UNKNOWN or "Unknown") .. "|r"
                                    end
                                end,
                                order = 0.5,
                                width = "full",
                            },
                            profileInfo = {
                                type = "description",
                                order = 1,
                                name = "Use the Ace3 profile controls above for switching, copying, and resetting profiles.",
                            },
                            exportProfile = {
                                type = "execute",
                name = L.EXPORT_PROFILE or "Export Current Profile",
                desc = L.EXPORT_PROFILE_DESC or "Export the current profile for support or backup.",
                                order = 2,
                                func = function()
                                    if addon.DebugExportTable and addon.db and addon.db.profile then
                                        addon:DebugExportTable(addon.db.profile)
                                    end
                                end,
                            },
                            importProfile = {
                                type = "input",
                name = L.IMPORT_PROFILE_DATA or "Import Profile Data",
                desc = L.IMPORT_PROFILE_DATA_DESC or "Paste a profile export string here to import settings.",
                                order = 3,
                                get = function() return "" end,
                                set = function(_, val) if addon.ImportProfileString then addon:ImportProfileString(val) else addon:Print(L.IMPORT_NOT_IMPLEMENTED or "Import feature not yet implemented.") end end,
                            },
                            autoSwitch = {
                                type = "toggle",
                name = L.AUTO_SWITCH_PROFILE or "Auto-Switch Profile by Spec",
                desc = L.AUTO_SWITCH_PROFILE_DESC or "Automatically switch profiles when changing specialization.",
                                order = 4,
                                get = function() local db = getSafeProfile() return db.autoSwitchProfile end,
                                set = function(_, val) local db = getSafeProfile() db.autoSwitchProfile = val end,
                            },
                        },
                    },
                },
            },
            minimap = {
                type = "group",
        name = L.MINIMAP_ICON or "Minimap Icon",
                order = 4,
                inline = true,
                args = {
                    hide = {
                        type = "toggle",
            name = L.HIDE_MINIMAP_ICON or "Hide Minimap Icon",
            desc = L.HIDE_MINIMAP_ICON_DESC or "Hide or show the minimap icon.",
                        get = function()
                            local db = getSafeProfile()
                            return db.minimap and db.minimap.hide
                        end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            db.minimap = db.minimap or {}
                            db.minimap.hide = val
                            if addon.SetupMinimapButton then addon:SetupMinimapButton() end
                        end,
                    },
                },
            },
            integration = {
                type = "group",
        name = L.INTEGRATION_COMPAT or "Compatibility",
                order = 5,
                args = {
                    summary = {
                        type = "description",
                        order = 0,
                        name = function()
                            return getSupportBlurb()
                        end,
                    },
                    elvui = {
                        type = "toggle",
            name = L.ENABLE_ELVUI_COMPAT or "ElvUI Compatibility",
            desc = L.ENABLE_ELVUI_COMPAT_DESC or "Force overlays even if ElvUI is loaded (may cause conflicts).",
                        order = 1,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.forceOverlaysWithElvUI end,
                        set = function(_, val) local db = getSafeProfile() db.forceOverlaysWithElvUI = val; addon.Core:FullUpdate() end,
                    },
                    dominosHint = {
                        type = "description",
                        order = 2,
                        name = L.DOMINOS_COMPAT_NOTE or "Dominos is supported directly. If a skin hides overlays on some bars, try 'Dominos: Use Native Text' in Display.",
                    },
                },
            },
            debug = {
                type = "group",
        name = L.DEBUGGING or "Debugging",
                order = 6,
                args = {
                    info = {
                        type = "description",
                        order = 0,
                        name = L.DEBUGGING_INFO or "Use these tools only when troubleshooting. Normal setup should not require them.",
                    },
                    enableTroubleshooting = {
                        type = "toggle",
                        name = L.ENABLE_TROUBLESHOOTING_TOOLS or "Enable Troubleshooting Tools",
                        desc = L.ENABLE_TROUBLESHOOTING_TOOLS_DESC or "Show import/export and profiling tools used for support and debugging.",
                        order = 1,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.troubleshootingTools end,
                        set = function(_, val) local db = getSafeProfile() db.troubleshootingTools = val end,
                    },
                    debugExport = {
                        type = "execute",
            name = L.EXPORT_DEBUG_DATA or "Export Debug Data",
            desc = L.EXPORT_DEBUG_DATA_DESC or "Export current settings or table for debugging.",
                        order = 2,
                        hidden = function() local db = getSafeProfile() return not db.troubleshootingTools end,
            func = function() if addon.DebugExportTable then addon:DebugExportTable(addon.db and addon.db.profile) else addon:Print(L.DEBUG_EXPORT_NOT_AVAILABLE or "Debug export not available.") end end,
                    },
                    debugImport = {
                        type = "input",
            name = L.IMPORT_DEBUG_DATA or "Import Debug Data",
            desc = L.IMPORT_DEBUG_DATA_DESC or "Paste a debug export string to import settings or data.",
                        order = 3,
                        hidden = function() local db = getSafeProfile() return not db.troubleshootingTools end,
                        get = function() return "" end,
            set = function(_, val) if addon.DebugImportString then addon:DebugImportString(val) else addon:Print(L.DEBUG_IMPORT_NOT_IMPLEMENTED or "Debug import not yet implemented.") end end,
                    },
                    perfMetrics = {
                        type = "toggle",
            name = L.SHOW_PERF_METRICS or "Show Performance Metrics",
            desc = L.SHOW_PERF_METRICS_DESC or "Show overlay update times and enable performance logging.",
                        order = 4,
                        hidden = function() local db = getSafeProfile() return not db.troubleshootingTools end,
                        get = function() local db = getSafeProfile() return db.showPerfMetrics end,
                        set = function(_, val) local db = getSafeProfile() db.showPerfMetrics = val end,
                    },
                    openLog = {
                        type = "execute",
                        name = L.OPEN_DEBUG_LOG or "Open Debug Log",
                        desc = L.OPEN_DEBUG_LOG_DESC or "Open the in-game debug log window.",
                        order = 5,
                        hidden = function() local db = getSafeProfile() return not db.troubleshootingTools end,
                        func = function()
                            if addon and addon.ShowDebugLogWindow then
                                addon:ShowDebugLogWindow()
                            end
                        end,
                    },
                },
            },
            support = {
                type = "group",
        name = L.HELP_AND_DEBUGGING or "Support",
                order = 97,
                args = {
                    supportDesc = {
                        type = "description",
            name = (L.HELP_AND_DEBUGGING_TEXT or "When reporting an issue, include your WoW flavor, AHOS version, bar addon, and whether you use skins like Masque.\n\nUseful commands:\n/ahos show\n/ahos reload\n/ahos detectui\n/ahos inspect <ButtonName>\n/ahos debug\n/ahos debugexport [tablepath]\n/ahoslog\n\nIf a third-party bar addon uses its own private binding system and does not expose stable button commands or hotkey update hooks, AHOS should not claim direct support for it.")
                .. "\n\nVersion: " .. getVersionString(),
                        order = 1,
                    },
                },
            },
            about = {
                type = "group",
        name = L.ABOUT_AND_CREDITS or "About & Credits",
                order = 98,
                args = {
                    aboutDesc = {
                        type = "description",
                        order = 1,
                        fontSize = "medium",
            name = L.ABOUT_TEXT or [[
|cffFFD700Advanced Hotkey Overlay System|r

A modular hotkey overlay system for World of Warcraft action bars with dedicated support for Blizzard, AzeriteUI, Dominos, Bartender4, and DiabolicUI.

|cffFFD700Made by:|r JuNNeZ
|cffFFD700Libraries:|r Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate.

For support, please visit the CurseForge or GitHub project pages.
Thank you for using AHOS!
            ]]
                    }
                }
            },
        },
    }
end
