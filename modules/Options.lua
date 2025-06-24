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
            profiles = {
                type = "group",
                name = "Profiles",
                order = 100,
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
                        },
                    },
                },
            },
            toggles = {
                type = "group",
                inline = true,
                order = 1,
                name = "",
                args = {
                    enable = {
                        type = "toggle",
                        name = "|cff3399ffEnable Addon|r",
                        order = 1,
                        width = "third",
                        get = function()
                            local db = getSafeProfile()
                            return db.enabled
                        end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            db.enabled = val
                            if val then addon.Core:OnEnable() else addon.Core:OnDisable() end
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                    autodetect = {
                        type = "toggle",
                        name = "|cff3399ffAuto-Detect UI|r",
                        order = 2,
                        width = "third",
                        get = function()
                            local db = getSafeProfile()
                            return db.autoDetectUI
                        end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            db.autoDetectUI = val
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                    debug = {
                        type = "toggle",
                        name = "|cff3399ffDebug Mode|r",
                        order = 3,
                        width = "third",
                        get = function()
                            local db = getSafeProfile()
                            return db.debug
                        end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            db.debug = val
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                },
            },
            -- Info block after toggles
            about = {
                type = "description",
                name = "|cffffd700An action bar overlay and keybind enhancement for World of Warcraft.|r\n",
                fontSize = "large",
                order = 20,
                width = "full",
            },
            detectedUI = {
                type = "description",
                name = function()
                    local ahos = _G.AdvancedHotkeyOverlaySystem
                    if ahos and ahos.DetectUI then ahos:DetectUI() end
                    local ui = ahos and ahos.detectedUI or "Unknown"
                    local color = (ahos and ahos.UIColors and ahos.UIColors[ui]) or {0.2,0.6,1}
                    local hex = string.format("%02x%02x%02x", math.floor(color[1]*255), math.floor(color[2]*255), math.floor(color[3]*255))
                    return string.format("|cff888888Detected UI:|r |cff%s%s|r", hex, ui)
                end,
                fontSize = "medium",
                order = 21,
                width = "full",
            },
            version = {
                type = "description",
                name = "|cff888888Version:|r |cffffd7002.3.0|r",
                fontSize = "medium",
                order = 22,
                width = "full",
            },
            author = {
                type = "description",
                name = "|cff888888Author:|r |cffffd700JuNNeZ|r",
                fontSize = "medium",
                order = 23,
                width = "full",
            },
            credits = {
                type = "description",
                name = "|cffFFD700Credits:|r\n- Contributors: Github Copilot\n|cff888888Thank you for using this addon! Your feedback and support make continued development possible.|r\n|cffFFD700License: MIT (Open Source)|r",
                fontSize = "small",
                order = 24,
                width = "full",
            },
            spacer = {
                type = "description",
                name = " ",
                order = 25,
            },
            display = {
                type = "group",
                name = "Display",
                order = 2,
                args = {
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
                },
            },
            text = {
                type = "group",
                name = "Text",
                order = 3,
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
                    outline = {
                        type = "toggle",
                        name = "Font Outline",
                        desc = "Adds a black outline to the font.",
                        order = 4,
                        get = function() local db = getSafeProfile() return db.text and db.text.outline end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.outline = val; addon.Core:FullUpdate() end end,
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
            minimap = {
                type = "group",
                name = "Minimap Icon",
                order = 1.5,
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
            help = {
                type = "group",
                name = "Help & Debugging",
                order = 0,
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
                            "/ahos debugexport [tablepath] - Export profile or subtable for debugging\n\n" ..
                            "|cffFFD700Debugging Tips|r\n" ..
                            "- Enable debug mode with /ahos debug to see extra output.\n" ..
                            "- Use /ahos debugexport to copy your profile or a subtable for bug reports.\n" ..
                            "- Paste exported data in your bug report for faster help!\n\n" ..
                            "|cffFFD700Changelog & Version Info|r\n" ..
                            "- See the 'Changelog' tab for recent updates and version history.\n\n" ..
                            "|cffFFD700Addon Version:|r 2.4.0 (2025-06-24)",
                        order = 1,
                    },
                },
            },
            changelog = {
                type = "group",
                name = "Changelog",
                order = 100,
                args = {
                    changelogdesc = {
                        type = "description",
                        name = [[
|cffFFD700Advanced Hotkey Overlay System|r

|cff00D4AA2.4.0 (2025-06-24) - In-Game Changelog, Debug Export Window, and More|r
- In-game changelog and version info tab
- Debug export window and /ahos debugexport command
- LibSerialize/LibDeflate support for profile export
- Help & Debugging tab in options
- Many bugfixes and polish

|cff00D4AA2.3.0 (2025-06-23)|r
- Modernized and cleaned up all options panel registration and naming logic
- No more color codes or icons in the options panel or .toc metadata
- Only one options panel is registered, with robust error handling
- Minimap/DataBroker icon and Blizzard options panel now always show the correct, user-friendly name
- ElvUI compatibility and user prompt logic improved
- Legacy and duplicate code removed for reliability
- All overlays and minimap icon logic now robust and error-free

See README.md or CurseForge for full changelog.
                        ]],
                        order = 1,
                    },
                },
            },
        },
    }
end
