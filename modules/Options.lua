-- modules/Options.lua
---@diagnostic disable: undefined-global
local addonName, privateScope = ...
local addon = privateScope.addon
local Options = addon.Options

Options.selectedProfile = nil

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

function Options:GetOptions()
    -- If the database isn't ready, provide a placeholder options table.
    local db_check = getSafeProfile()
    if not addon.db or not addon.db.profile then
        return {
            type = "group",
            name = _G.AHOS_OPTIONS_PANEL_NAME,
            args = {
                info = {
                    type = "description",
                    name = "Addon is initializing. Please close and reopen this window in a few seconds.",
                    order = 1,
                },
            },
        }
    end

    return {
        type = "group",
        name = _G.AHOS_OPTIONS_PANEL_NAME,
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
                        text = "The settings are locked. Do you want to unlock?",
                        button1 = "Yes",
                        button2 = "No",
                        OnAccept = function()
                            db.display.locked = false
                            addon:Print("|cff4A9EFFSettings unlocked|r - |cff888888you can now modify settings|r")
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
                        name = "|cff3399ffEnable Addon|r",
                        order = 1,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.enabled end,
                        set = function(_, val) local db = getSafeProfile() db.enabled = val if val then addon.Core:OnEnable() else addon.Core:OnDisable() end if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    autodetect = {
                        type = "toggle",
                        name = "|cff3399ffAuto-Detect UI|r",
                        order = 2,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.autoDetectUI end,
                        set = function(_, val) local db = getSafeProfile() db.autoDetectUI = val if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    debug = {
                        type = "toggle",
                        name = "|cff3399ffDebug Mode|r",
                        order = 3,
                        width = "third",
                        get = function() local db = getSafeProfile() return db.debug end,
                        set = function(_, val) local db = getSafeProfile() db.debug = val if addon:IsReady() then addon.Core:FullUpdate() end end,
                    },
                    lock = {
                        type = "execute",
                        name = function() local db = getSafeProfile() return db.display and db.display.locked and "Unlock Settings" or "Lock Settings" end,
                        desc = "Lock or unlock all settings to prevent accidental changes.",
                        order = 4,
                        disabled = false, -- Always enabled, even when locked
                        func = function()
                            local db = getSafeProfile()
                            db.display = db.display or {}
                            db.display.locked = not db.display.locked
                            addon:Print(db.display.locked and "|cffFFD700Settings locked|r - |cff888888protected from changes|r" or "|cff4A9EFFSettings unlocked|r - |cff888888you can now modify settings|r")
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                },
            },
            display = {
                type = "group",
                name = "Display",
                order = 1,
                args = {
                    nativeRewrite = {
                        type = "toggle",
                        name = "Use Native Text (Rewrite)",
                        desc = "Rewrite the button's native hotkey text instead of drawing an overlay.",
                        order = 0.5,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.nativeRewrite end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.nativeRewrite = val; addon.Core:FullUpdate() end end,
                    },
                    dominosRewrite = {
                        type = "toggle",
                        name = "Dominos: Use Native Text",
                        desc = "For Dominos buttons, rewrite the native hotkey text (overlay is default).",
                        order = 0.6,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.dominosRewrite end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.dominosRewrite = val; addon.Core:FullUpdate() end end,
                    },
                    autoNativeFallback = {
                        type = "toggle",
                        name = "Auto Fallback to Native",
                        desc = "If an overlay appears hidden by a skin, automatically rewrite the native hotkey for that button.",
                        order = 0.7,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.autoNativeFallback end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.autoNativeFallback = val; addon.Core:FullUpdate() end end,
                    },
                    hideOriginal = {
                        type = "toggle",
                        name = "Hide Original Hotkey Text",
                        desc = "Hides the default hotkey text on action buttons.",
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
                        name = "Anchor Point",
                        desc = "The point on the button where the text is anchored.",
                        order = 2,
                        values = { TOPLEFT = "TOPLEFT", TOP = "TOP", TOPRIGHT = "TOPRIGHT", LEFT = "LEFT", CENTER = "CENTER", RIGHT = "RIGHT", BOTTOMLEFT = "BOTTOMLEFT", BOTTOM = "BOTTOM", BOTTOMRIGHT = "BOTTOMRIGHT" },
                        get = function() local db = getSafeProfile() return db.display and db.display.anchor end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.anchor = val; addon.Core:FullUpdate() end end,
                    },
                    xOffset = {
                        type = "range",
                        name = "X Offset",
                        desc = "Horizontal offset from the anchor point.",
                        order = 3,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.xOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.xOffset = val; addon.Core:FullUpdate() end end,
                    },
                    yOffset = {
                        type = "range",
                        name = "Y Offset",
                        desc = "Vertical offset from the anchor point.",
                        order = 4,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.yOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.yOffset = val; addon.Core:FullUpdate() end end,
                    },
                    scale = {
                        type = "range",
                        name = "Scale",
                        desc = "The scale of the overlay text.",
                        order = 5,
                        min = 0.1, max = 2, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.scale end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.scale = val; addon.Core:FullUpdate() end end,
                    },
                    alpha = {
                        type = "range",
                        name = "Alpha",
                        desc = "The transparency of the overlay text.",
                        order = 6,
                        min = 0, max = 1, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.alpha end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.alpha = val; addon.Core:FullUpdate() end end,
                    },
                    strata = {
                        type = "select",
                        name = "Overlay Frame Strata",
                        desc = "Sets the drawing layer for the overlays. Use a higher value (like DIALOG or TOOLTIP) if overlays are hidden behind other UI elements.",
                        order = 8,
                        values = {
                            BACKGROUND = "Background",
                            LOW = "Low",
                            MEDIUM = "Medium",
                            HIGH = "High",
                            DIALOG = "Dialog",
                            TOOLTIP = "Tooltip",
                        },
                        get = function() local db = getSafeProfile() return db.display and db.display.strata or "HIGH" end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.strata = val; addon.Core:FullUpdate() end end,
                    },
                    frameLevel = {
                        type = "range",
                        name = "Overlay Frame Level",
                        desc = "Fine-tune overlay stacking within the chosen strata. Higher values appear above lower ones in the same strata.",
                        order = 9,
                        min = 1, max = 128, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.frameLevel or 10 end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.frameLevel = val; addon.Core:FullUpdate() end end,
                    },
                    followNativeHotkeyStyle = {
                        type = "toggle",
                        name = "Mirror Native Hotkey Style",
                        desc = "Overlay text will mirror the native hotkey font, color, and position when available.",
                        order = 10,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.followNativeHotkeyStyle end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.followNativeHotkeyStyle = val; addon.Core:FullUpdate() end end,
                    },
                },
            },
            text = {
                type = "group",
                name = "Keybinds",
                order = 2,
                args = {
                    font = {
                        type = "select",
                        name = "Font",
                        desc = "The font for the overlay text.",
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
                        name = "Font Size",
                        desc = "The size of the font.",
                        order = 2,
                        min = 6, max = 48, step = 1,
                        get = function() local db = getSafeProfile() return db.text and db.text.fontSize end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.fontSize = val; addon.Core:FullUpdate() end end,
                    },
                    color = {
                        type = "color",
                        name = "Font Color",
                        desc = "The color of the font.",
                        order = 3,
                        hasAlpha = false,
                        get = function() local db = getSafeProfile() if db.text and db.text.color then return unpack(db.text.color) end end,
                        set = function(info, r, g, b) local db = getSafeProfile() if db.text then db.text.color = {r, g, b}; addon.Core:FullUpdate() end end,
                    },
                    outlineStyle = {
                        type = "select",
                        name = "Font Outline",
                        desc = "Choose font outline and monochrome options.",
                        order = 4,
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                            ["MONOCHROME,OUTLINE"] = "Monochrome + Outline",
                            ["MONOCHROME,THICKOUTLINE"] = "Monochrome + Thick Outline",
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
                        name = "Enable Abbreviations",
                        desc = "Abbreviate keybind text (e.g., SHIFT -> S).",
                        order = 5,
                        get = function() local db = getSafeProfile() return db.text and db.text.abbreviations end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.abbreviations = val; addon.Core:FullUpdate() end end,
                    },
                    maxLength = {
                        type = "range",
                        name = "Max Length",
                        desc = "Maximum length of the abbreviated text.",
                        order = 6,
                        min = 1, max = 10, step = 1,
                        get = function() local db = getSafeProfile() return db.text and db.text.maxLength end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.maxLength = val; addon.Core:FullUpdate() end end,
                    },
                    modSeparator = {
                        order = 20,
                        type = "input",
                        name = "Modifier Separator",
                        desc = "String to insert between modifiers and key (leave empty for none, e.g. SM4).",
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
                name = "Profiles Management",
                order = 3,
                args = {
                    aceProfiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
                    customProfileManagement = {
                        type = "group",
                        name = "Profile Management",
                        order = 2,
                        args = {
                            currentProfile = {
                                type = "description",
                                name = function()
                                    if addon.db and addon.db:GetCurrentProfile() then
                                        return "|cff4A9EFFCurrent Profile:|r |cffffd700" .. addon.db:GetCurrentProfile() .. "|r"
                                    else
                                        return "|cff4A9EFFCurrent Profile:|r |cffffd700Unknown|r"
                                    end
                                end,
                                order = 0.5,
                                width = "full",
                            },
                            useGlobal = {
                                type = "execute",
                                name = "Use Global Profile",
                                desc = "Switch to the global (Default) profile.",
                                order = 1,
                                func = function()
                                    if addon.db then
                                        StaticPopupDialogs["AHOS_CONFIRM_PROFILE_SWITCH"] = {
                                            text = "Switch to the global (Default) profile? This will overwrite your current settings.",
                                            button1 = "Yes",
                                            button2 = "No",
                                            OnAccept = function()
                                                addon.db:SetProfile("Default")
                                                addon:Print("|cff4A9EFFSwitched to global profile:|r Default")
                                            end,
                                            OnCancel = function() end,
                                            timeout = 0,
                                            whileDead = true,
                                            hideOnEscape = true,
                                            preferredIndex = 3,
                                        }
                                        StaticPopup_Show("AHOS_CONFIRM_PROFILE_SWITCH")
                                    end
                                end,
                            },
                            useCharacter = {
                                type = "execute",
                                name = "Use Character Profile",
                                desc = "Switch to a character-specific profile.",
                                order = 2,
                                func = function()
                                    if addon.db then
                                        local charProfile = UnitName("player") .. " - " .. GetRealmName()
                                        StaticPopupDialogs["AHOS_CONFIRM_PROFILE_SWITCH_CHAR"] = {
                                            text = "Switch to the character-specific profile? This will overwrite your current settings.",
                                            button1 = "Yes",
                                            button2 = "No",
                                            OnAccept = function()
                                                addon.db:SetProfile(charProfile)
                                                addon:Print("|cff4A9EFFSwitched to character profile:|r " .. charProfile)
                                            end,
                                            OnCancel = function() end,
                                            timeout = 0,
                                            whileDead = true,
                                            hideOnEscape = true,
                                            preferredIndex = 3,
                                        }
                                        StaticPopup_Show("AHOS_CONFIRM_PROFILE_SWITCH_CHAR")
                                    end
                                end,
                            },
                            copyProfile = {
                                type = "input",
                                name = "Copy Current Profile To...",
                                desc = "Enter a new profile name to copy current settings.",
                                order = 3,
                                get = function() return "" end,
                                set = function(_, val)
                                    if addon.db and val and val ~= "" then
                                        addon.db:CopyProfile(val)
                                        addon:Print("|cff4A9EFFCopied current profile to:|r " .. val)
                                    end
                                end,
                            },
                            resetAll = {
                                type = "execute",
                                name = "Reset All Profiles",
                                desc = "Reset all profiles to default settings (advanced).",
                                order = 4,
                                func = function()
                                    if addon.db then
                                        StaticPopupDialogs["AHOS_CONFIRM_RESET_ALL"] = {
                                            text = "Reset ALL profiles to default? This cannot be undone!",
                                            button1 = "Yes",
                                            button2 = "No",
                                            OnAccept = function()
                                                addon.db:ResetDB("Default")
                                                addon:Print("|cffff0000All profiles reset to default!|r")
                                            end,
                                            OnCancel = function() end,
                                            timeout = 0,
                                            whileDead = true,
                                            hideOnEscape = true,
                                            preferredIndex = 3,
                                        }
                                        StaticPopup_Show("AHOS_CONFIRM_RESET_ALL")
                                    end
                                end,
                            },
                            printProfile = {
                                type = "execute",
                                name = "Print Current Profile Data",
                                desc = "Prints the current profile data to the chat for debugging.",
                                order = 5,
                                func = function()
                                    if addon.db and addon.db.profile then
                                        local serialized = LibSerialize and LibSerialize:Serialize(addon.db.profile)
                                        if serialized and LibDeflate then
                                            local compressed = LibDeflate:CompressDeflate(serialized)
                                            local encoded = LibDeflate:EncodeForPrint(compressed)
                                            addon:Print("|cffFFD700Current Profile Data (compressed):|r\n" .. ("\n" .. ("|cff888888" .. encoded .. "|r")))
                                        elseif serialized then
                                            addon:Print("|cffFFD700Current Profile Data:|r\n" .. ("\n" .. ("|cff888888" .. serialized .. "|r")))
                                        else
                                            addon:Print("[Serialization not available]")
                                        end
                                    end
                                end,
                            },
                            importProfile = {
                                type = "input",
                                name = "Import Profile Data",
                                desc = "Paste a profile export string here to import settings.",
                                order = 99,
                                get = function() return "" end,
                                set = function(_, val) if addon.ImportProfileString then addon:ImportProfileString(val) else addon:Print("Import feature not yet implemented.") end end,
                            },
                            autoSwitch = {
                                type = "toggle",
                                name = "Auto-Switch Profile by Spec",
                                desc = "Automatically switch profiles when changing specialization.",
                                order = 100,
                                get = function() local db = getSafeProfile() return db.autoSwitchProfile end,
                                set = function(_, val) local db = getSafeProfile() db.autoSwitchProfile = val end,
                            },
                        },
                    },
                },
            },
            minimap = {
                type = "group",
                name = "Minimap Icon",
                order = 4,
                inline = true,
                args = {
                    hide = {
                        type = "toggle",
                        name = "Hide Minimap Icon",
                        desc = "Hide or show the minimap icon.",
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
                name = "Integration/Compatibility",
                order = 5,
                args = {
                    elvui = {
                        type = "toggle",
                        name = "Enable ElvUI Compatibility",
                        desc = "Force overlays even if ElvUI is loaded (may cause conflicts).",
                        order = 1,
                        get = function() local db = getSafeProfile() return db.forceOverlaysWithElvUI end,
                        set = function(_, val) local db = getSafeProfile() db.forceOverlaysWithElvUI = val; addon.Core:FullUpdate() end,
                    },
                    bartender = {
                        type = "toggle",
                        name = "Enable Bartender Compatibility",
                        desc = "Enable overlays for Bartender action bars.",
                        order = 2,
                        get = function() local db = getSafeProfile() return db.bartenderCompat end,
                        set = function(_, val) local db = getSafeProfile() db.bartenderCompat = val; addon.Core:FullUpdate() end,
                    },
                    dominos = {
                        type = "toggle",
                        name = "Enable Dominos Compatibility",
                        desc = "Enable overlays for Dominos action bars.",
                        order = 3,
                        get = function() local db = getSafeProfile() return db.dominosCompat end,
                        set = function(_, val) local db = getSafeProfile() db.dominosCompat = val; addon.Core:FullUpdate() end,
                    },
                },
            },
            advanced = {
                type = "group",
                name = "Advanced",
                order = 6,
                args = {
                    debugExport = {
                        type = "execute",
                        name = "Export Debug Data",
                        desc = "Export current settings or table for debugging.",
                        order = 1,
                        func = function() if addon.DebugExportTable then addon:DebugExportTable(addon.db and addon.db.profile) else addon:Print("Debug export not available.") end end,
                    },
                    debugImport = {
                        type = "input",
                        name = "Import Debug Data",
                        desc = "Paste a debug export string to import settings or data.",
                        order = 2,
                        get = function() return "" end,
                        set = function(_, val) if addon.DebugImportString then addon:DebugImportString(val) else addon:Print("Debug import not yet implemented.") end end,
                    },
                    perfMetrics = {
                        type = "toggle",
                        name = "Show Performance Metrics",
                        desc = "Show overlay update times and enable performance logging.",
                        order = 3,
                        get = function() local db = getSafeProfile() return db.showPerfMetrics end,
                        set = function(_, val) local db = getSafeProfile() db.showPerfMetrics = val end,
                    },
                },
            },
            help = {
                type = "group",
                name = "Help & Debugging",
                order = 97, -- Moved to 97 to make space for About
                args = {
                    helpdesc = {
                        type = "description",
                        name = "|cffFFD700How to Report Bugs|r\n" ..
                            "- Please include your WoW version, addon version, and a description of the issue.\n" ..
                            "- For UI or overlay issues, include a screenshot if possible.\n" ..
                            "- You can export your profile or debug data using the options below or the /ahos debugexport command.\n\n" ..
                            "|cffFFD700Available Slash Commands|r\n" ..
                            "/ahos show - Open options panel\n" ..
                            "/ahos lock|unlock - Lock/unlock settings\n" ..
                            "/ahos reset - Reset all settings\n" ..
                            "/ahos toggle - Enable/disable overlays\n" ..
                            "/ahos reload|refresh - Reload overlays\n" ..
                            "/ahos cleanup - Clear overlays\n" ..
                            "/ahos debug - Toggle debug mode\n" ..
                            "/ahos detectui - Manually detect UI\n" ..
                            "/ahos inspect <ButtonName> - Print debug info for a button\n" ..
                            "/ahos debugexport [tablepath] - Export profile or subtable for debugging\n" ..
                            "/ahoslog - Open the debug log window\n\n" ..
                            "|cffFFD700Debugging Tips|r\n" ..
                            "- Enable debug mode with /ahos debug to see extra output.\n" ..
                            "- Use /ahos debugexport to copy your profile or a subtable for bug reports.\n" ..
                            "- Use /ahoslog to view/copy all debug output.\n" ..
                            "- Paste exported data in your bug report for faster help!\n\n" ..
                            "|cffFFD700Changelog & Version Info|r\n" ..
                            "- See the 'Changelog' tab for recent updates and version history.\n\n" ..
                            "|cffFFD700Addon Version:|r " .. ((C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "unknown"),
                        order = 1,
                    },
                },
            },
            about = {
                type = "group",
                name = "About & Credits",
                order = 98,
                args = {
                    aboutDesc = {
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                        name = [[
|cffFFD700Advanced Hotkey Overlay System|r

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

|cffFFD700Made by:|r JuNNeZ
|cffFFD700Libraries:|r Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate.

For support, please visit the CurseForge or GitHub project pages.
Thank you for using AHOS!
                        ]]
                    }
                }
            },
            changelog = {
                type = "group",
                name = "Changelog",
                order = 99,
                args = {
                    changelogHeader = {
                        type = "description",
                        name = "Changelog for Advanced Hotkey Overlay System\n\n",
                        order = 1,
                        fontSize = "medium",
                    },
                    -- Latest changes
                    version251 = {
                        type = "group",
                        name = function()
                            local v = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
                                or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version"))
                                or "unknown"
                            return "Version " .. tostring(v)
                        end,
                        order = 2,
                        args = {
                            details = {
                                type = "description",
                                name = "- Retail (AzeriteUI): Removed placeholder square/bullet on unbound buttons; safer native label suppression with deep-scan.\n- Classic: Fixed invalid event registration by gating Retail-only events.\n- Dominos: Overlays visible immediately without reload; native labels stay hidden after binding mode.\n- Overlay layering: Bumped frame level to sit above nested containers and skins (Masque/AzeriteUI).",
                                order = 1,
                            },
                        },
                    },
                    version242 = {
                        type = "group",
                        name = "Version 2.4.2",
                        order = 3,
                        args = {
                            details = {
                                type = "description",
                                name = "- Embedded AceGUI-3.0 and wired AceConfigDialog to prevent missing library issues.\n- Stabilized options panel name to avoid duplicate Blizzard options categories.\n- Minimap icon and addon logo path fixes.\n- Misc robustness improvements and debug commands.",
                                order = 1,
                            },
                        },
                    },
                    version240 = {
                        type = "group",
                        name = "Version 2.4.0 (2025-06-24)",
                        order = 4,
                        args = {
                            details = {
                                type = "description",
                                name = "- Added in-game changelog and version info tab.\n- Implemented debug export window and /ahos debugexport command for easy profile/table export.\n- Integrated LibSerialize/LibDeflate support for profile export/import and debug tools.\n- New Help & Debugging tab in options for easier access to support information.\n- Many bugfixes and polish, including overlay logic, minimap icon, and options panel structure.",
                                order = 1,
                            },
                        },
                    },
                    version230 = {
                        type = "group",
                        name = "Version 2.3.0 (2025-06-23)",
                        order = 4,
                        args = {
                            details = {
                                type = "description",
                                name = "- Modernized and cleaned up all options panel registration and naming logic.\n- Removed color codes and icons in the options panel and .toc metadata.\n- Ensured only one options panel is registered, with robust error handling.\n- Minimap/DataBroker icon and Blizzard options panel now always show the correct, user-friendly name.\n- Improved ElvUI compatibility and user prompt logic.\n- Removed legacy and duplicate code for reliability.\n- Ensured all overlays and minimap icon logic are robust and error-free.\n- Overlay settings now update instantly on profile or option changes.\n- Implemented lock/unlock feature: `/ahos lock` greys out all options and prevents changes; attempting to change settings while locked shows a high-strata popup with unlock prompt.\n- Added StaticPopup dialog for unlocking settings, with Yes/No options.\n- Added debug-only button to delete all profiles except the current one.\n- Improved error handling for profile changes and minimap icon registration.\n- Ensured profile deletion and switching is robust and bug-free.\n- Resolved minimap icon unregister errors.\n- Settings lock now effectively prevents changes in the options panel.\n- Eliminated duplicate options panel errors.",
                                order = 1,
                            },
                        },
                    },
                },
            },
        },
    }
end
