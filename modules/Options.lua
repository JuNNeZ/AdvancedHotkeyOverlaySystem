-- modules/Options.lua
---@diagnostic disable: undefined-global
local addonName, privateScope = ...
local addon = privateScope.addon
local Options = addon.Options

local function getSafeProfile()
    if addon and addon.db and addon.db.profile then
        return addon.db.profile
    end
    return setmetatable({}, { __index = function() return nil end })
end

function Options:GetOptions()
    -- If the database isn't ready, provide a placeholder options table.
    local db_check = getSafeProfile()
    if not addon.db or not addon.db.profile then
        return {
            type = "group",
            name = addonName,
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
        name = addonName,
        get = function(info)
            local db = getSafeProfile()
            return db[info[#info]]
        end,
        set = function(info, value)
            local db = getSafeProfile()
            db[info[#info]] = value
            if addon:IsReady() then
                addon.Core:FullUpdate()
            end
        end,
        args = {
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
                name = "|cff888888Version:|r |cffffd7002.0.0-alpha|r",
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
                                return addon.Config:GetFontList()
                            end
                            return { "Default" }
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
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
        },
    }
end
