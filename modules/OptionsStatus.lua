---@diagnostic disable: undefined-global
-- modules/OptionsStatus.lua - the Status, Compatibility, Inspector, Debugging and About pages.
--
-- One part of the option table modules/Options.lua puts together; the helpers
-- every part shares are Options.Helpers.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSOptions
local Options = addon.Options
local L = addon.L or {}
local Groups = Options.Groups
local H = Options.Helpers
local getVersionString, getDetectedUIText, getDiagnosticsSummary, getSupportBlurb = H.getVersionString, H.getDetectedUIText, H.getDiagnosticsSummary, H.getSupportBlurb
local getSafeProfile = H.getSafeProfile

function Groups.status()
    return {
                type = "group",
                name = L.STATUS or "Status",
                order = 0.5,
                args = {
                    toggles = {
                        type = "group",
                        inline = true,
                        order = 0.1,
                        name = L.QUICK_SWITCHES or "Quick Switches",
                        args = {
                            enable = {
                                type = "toggle",
                                name = L.ENABLE_ADDON or "Enable Addon",
                                desc = L.ENABLE_ADDON_DESC or "Enable or disable the addon.",
                                order = 1,
                                width = "third",
                                get = function() local db = getSafeProfile() return db.enabled end,
                                set = function(_, val) local db = getSafeProfile() db.enabled = val if val then addon.Core:OnEnable() else addon.Core:OnDisable() end end,
                            },
                            autodetect = {
                                type = "toggle",
                                name = L.AUTO_DETECT_UI or "Auto-Detect UI",
                                desc = L.AUTO_DETECT_UI_DESC or "Automatically detect your action bar UI.",
                                order = 2,
                                width = "third",
                                get = function() local db = getSafeProfile() return db.autoDetectUI end,
                                set = function(_, val) local db = getSafeProfile() db.autoDetectUI = val if addon:IsReady() then addon.Core:FullUpdate() end end,
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
                                end,
                            },
                        },
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
                    minimap = {
                        type = "group",
                name = L.MINIMAP_ICON or "Minimap Icon",
                        order = 10,
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
                },
    }
end

function Groups.integration()
    return {
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
    }
end

function Groups.inspector()
    return {
                type = "group",
                name = L.INSPECTOR or "Inspector",
                order = 5.5,
                args = {
                },
    }
end

function Groups.debug()
    return {
                type = "group",
        name = L.DEBUGGING or "Debugging",
                order = 6,
                args = {
                    info = {
                        type = "description",
                        order = 0,
                        name = L.DEBUGGING_INFO or "Use these tools only when troubleshooting. Normal setup should not require them.",
                    },
                    debug = {
                        type = "toggle",
                        name = L.DEBUG_MODE or "Debug Mode",
                        desc = L.DEBUG_MODE_DESC or "Enable verbose debug logging.",
                        order = 0.5,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.debug end,
                        set = function(_, val) local db = getSafeProfile() db.debug = val end,
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
    }
end

function Groups.about()
    return {
                type = "group",
        name = L.ABOUT_AND_SUPPORT or "About & Support",
                order = 98,
                args = {
                    supportDesc = {
                        type = "description",
            name = (L.HELP_AND_DEBUGGING_TEXT or "When reporting an issue, include your WoW flavor, AHOS version, bar addon, and whether you use skins like Masque.\n\nUseful commands:\n/ahos show\n/ahos reload\n/ahos detectui\n/ahos inspect <ButtonName>\n/ahos debug\n/ahos debugexport [tablepath]\n/ahoslog\n\nIf a third-party bar addon uses its own private binding system and does not expose stable button commands or hotkey update hooks, AHOS should not claim direct support for it.")
                .. "\n\nVersion: " .. getVersionString(),
                        order = 2,
                    },
                    aboutDesc = {
                        type = "description",
                        order = 1,
                        fontSize = "medium",
            name = L.ABOUT_TEXT or [[
|cffFFD700Advanced Hotkey Overlay System|r

A modular hotkey overlay system for World of Warcraft action bars with dedicated support for Blizzard, AzeriteUI, Dominos, Bartender4, DiabolicUI, LUI and Neuron.

|cffFFD700Made by:|r JuNNeZ
|cffFFD700Libraries:|r Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate.

For support, please visit the CurseForge or GitHub project pages.
Thank you for using AHOS!
            ]]
                    }
                }
    }
end
