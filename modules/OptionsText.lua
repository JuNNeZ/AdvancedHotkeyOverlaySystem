---@diagnostic disable: undefined-global
-- modules/OptionsText.lua - the Keybinds and Abbreviations pages.
--
-- Font, colour and outline; modifier colours; shadow and glow; buttons with two
-- keys; and every abbreviation (the options window edits those on its keyboard).
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
local getSafeProfile, RefreshOverlayStyles, OUTLINE_ALIASES, getModifierColors = H.getSafeProfile, H.RefreshOverlayStyles, H.OUTLINE_ALIASES, H.getModifierColors
local modifierColorOption, getSub, colorOption, RefreshAbbreviations = H.modifierColorOption, H.getSub, H.colorOption, H.RefreshAbbreviations

local function BuildAbbreviationOptions()
    local args = {
        intro = {
            type = "description",
            name = L.CUSTOM_ABBREVIATIONS_DESC or "Choose the text AHOS uses for every supported modifier and key. Values are saved per profile; clearing a field restores its default.",
            order = 1,
            width = "full",
        },
        enabled = {
            type = "toggle",
            name = L.ABBREVIATIONS or "Enable Abbreviations",
            desc = L.ABBREVIATIONS_DESC or "Use abbreviated keybind text.",
            order = 2,
            width = "half",
            get = function() local db = getSafeProfile() return db.text and db.text.abbreviations end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.abbreviations = value; RefreshAbbreviations() end
            end,
        },
        maxLength = {
            type = "range",
            name = L.MAX_LENGTH or "Max Length",
            desc = L.MAX_LENGTH_DESC or "Maximum length of the final abbreviated hotkey.",
            order = 3,
            min = 1, max = 24, step = 1,
            width = "half",
            get = function() local db = getSafeProfile() return db.text and db.text.maxLength or 6 end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.maxLength = value; RefreshAbbreviations() end
            end,
        },
        modSeparator = {
            type = "input",
            name = L.MOD_SEPARATOR or "Modifier Separator",
            desc = L.MOD_SEPARATOR_DESC or "Text inserted between multiple modifiers.",
            order = 4,
            width = "half",
            get = function() local db = getSafeProfile() return db.text and db.text.modSeparator or "" end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.modSeparator = value or ""; RefreshAbbreviations() end
            end,
        },
        gamepadIcons = {
            type = "toggle",
            name = L.GAMEPAD_ICONS or "Controller Button Icons",
            desc = L.GAMEPAD_ICONS_DESC or "Draw gamepad buttons as your controller's own button icons instead of text. A gamepad button you gave an abbreviation of your own keeps it.",
            order = 4.5,
            width = "full",
            get = function() local db = getSafeProfile() return db.text and db.text.gamepadIcons ~= false end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.gamepadIcons = value and true or false; RefreshAbbreviations() end
            end,
        },
        gamepadIconStyle = {
            type = "select",
            name = L.GAMEPAD_ICON_STYLE or "Controller Icon Style",
            desc = L.GAMEPAD_ICON_STYLE_DESC or "Which controller's button icons to draw. Automatic follows the controller the game sees.",
            order = 4.6,
            values = {
                auto = L.GAMEPAD_STYLE_AUTO or "Automatic",
                xbox = "Xbox",
                ps = "PlayStation",
                switch = "Nintendo Switch",
                generic = L.GAMEPAD_STYLE_GENERIC or "Generic",
            },
            sorting = { "auto", "xbox", "ps", "switch", "generic" },
            disabled = function() local db = getSafeProfile() return db.text and db.text.gamepadIcons == false end,
            get = function() local db = getSafeProfile() return db.text and db.text.gamepadIconStyle or "auto" end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.gamepadIconStyle = value; RefreshAbbreviations() end
            end,
        },
        mouseIcons = {
            type = "toggle",
            name = L.MOUSE_ICONS or "Mouse Button Icons",
            desc = L.MOUSE_ICONS_DESC or "Draw mouse buttons and the wheel as small mouse icons instead of text. A mouse button you gave an abbreviation of your own keeps it.",
            order = 4.7,
            width = "full",
            get = function() local db = getSafeProfile() return db.text and db.text.mouseIcons end,
            set = function(_, value)
                local db = getSafeProfile()
                if db.text then db.text.mouseIcons = value and true or false; RefreshAbbreviations() end
            end,
        },
        preview = {
            type = "description",
            name = function()
                local sample = addon.Keybinds and addon.Keybinds.Abbreviate
                    and addon.Keybinds:Abbreviate("CTRL-SHIFT-MOUSEBUTTON4") or "CSB4"
                return (L.ABBREVIATION_PREVIEW or "Preview") .. ": |cffffffff" .. tostring(sample) .. "|r"
            end,
            order = 5,
            width = "half",
        },
        reset = {
            type = "execute",
            name = L.RESET_ABBREVIATIONS or "Reset All Abbreviations",
            desc = L.RESET_ABBREVIATIONS_DESC or "Restore every abbreviation to its built-in default.",
            order = 6,
            width = "full",
            confirm = true,
            confirmText = L.RESET_ABBREVIATIONS_CONFIRM or "Reset every custom abbreviation in this profile?",
            func = function()
                if addon.Keybinds and addon.Keybinds.ResetCustomAbbreviations then
                    addon.Keybinds:ResetCustomAbbreviations()
                    RefreshAbbreviations()
                end
            end,
        },
    }

    return args
end

function Groups.text()
    return {
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
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.font = val; RefreshOverlayStyles() end end,
                    },
                    fontSize = {
                        type = "range",
                        name = L.FONT_SIZE or "Font Size",
                        desc = L.FONT_SIZE_DESC or "The size of the font.",
                        order = 2,
                        min = 6, max = 48, step = 1,
                        get = function() local db = getSafeProfile() return db.text and db.text.fontSize end,
                        set = function(info, val) local db = getSafeProfile() if db.text then db.text.fontSize = val; RefreshOverlayStyles() end end,
                    },
                    color = {
                        type = "color",
                        name = L.FONT_COLOR or "Font Color",
                        desc = L.FONT_COLOR_DESC or "The color of the font.",
                        order = 3,
                        hasAlpha = false,
                        get = function() local db = getSafeProfile() if db.text and db.text.color then return unpack(db.text.color) end end,
                        set = function(info, r, g, b) local db = getSafeProfile() if db.text then db.text.color = {r, g, b}; RefreshOverlayStyles() end end,
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
                        },
                        sorting = { "NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROME,OUTLINE", "MONOCHROME,THICKOUTLINE" },
                        get = function()
                            local db = getSafeProfile()
                            if db.text then
                                if db.text.outlineStyle and db.text.outlineStyle ~= "" then
                                    -- Older profiles may hold the alias spellings; show them as what they mean.
                                    return OUTLINE_ALIASES[db.text.outlineStyle] or db.text.outlineStyle
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
                                RefreshOverlayStyles()
                            end
                        end,
                    },
                    modifierColors = {
                        type = "group",
                        inline = true,
                        order = 5,
                        name = L.MODIFIER_COLORS or "Modifier Colours",
                        args = {
                            enabled = {
                                type = "toggle",
                                name = L.MODIFIER_COLORS_ENABLE or "Colour by Modifier",
                                desc = L.MODIFIER_COLORS_ENABLE_DESC or "Draw Shift, Ctrl and Alt bindings each in their own colour.",
                                order = 1,
                                width = "full",
                                get = function() return getModifierColors().enabled end,
                                set = function(_, val) getModifierColors().enabled = val and true or false; RefreshAbbreviations() end,
                            },
                            hideModifiers = {
                                type = "toggle",
                                name = L.MODIFIER_COLORS_HIDE or "Hide Modifier Letters",
                                desc = L.MODIFIER_COLORS_HIDE_DESC or "Show \"Q\" in the Shift colour instead of \"SQ\". The colour alone tells the modifiers apart.",
                                order = 2,
                                width = "full",
                                disabled = function() return not getModifierColors().enabled end,
                                get = function() return getModifierColors().hideModifiers end,
                                set = function(_, val) getModifierColors().hideModifiers = val and true or false; RefreshAbbreviations() end,
                            },
                            shift = modifierColorOption("shift", 3, L.MODIFIER_COLOR_SHIFT or "Shift"),
                            ctrl = modifierColorOption("ctrl", 4, L.MODIFIER_COLOR_CTRL or "Ctrl"),
                            alt = modifierColorOption("alt", 5, L.MODIFIER_COLOR_ALT or "Alt"),
                            multi = modifierColorOption("multi", 6, L.MODIFIER_COLOR_MULTI or "Two or More Modifiers"),
                        },
                    },
                    shadowGlow = {
                        type = "group",
                        inline = true,
                        order = 6,
                        name = L.SHADOW_AND_GLOW or "Shadow and Glow",
                        args = {
                            shadowEnabled = {
                                type = "toggle",
                                name = L.TEXT_SHADOW or "Shadow",
                                desc = L.TEXT_SHADOW_DESC or "Draw a drop shadow under the hotkey text.",
                                order = 1,
                                width = "full",
                                get = function() local db = getSafeProfile() return db.text and db.text.shadowEnabled end,
                                set = function(_, val) local db = getSafeProfile() if db.text then db.text.shadowEnabled = val and true or false; RefreshOverlayStyles() end end,
                            },
                            shadowColor = colorOption(2, L.TEXT_SHADOW_COLOR or "Shadow Colour", L.TEXT_SHADOW_COLOR_DESC or "The shadow's colour and strength.",
                                function() return getSafeProfile().text or {} end, "shadowColor", true,
                                function() local db = getSafeProfile() return not (db.text and db.text.shadowEnabled) end),
                            shadowX = {
                                type = "range",
                                name = L.TEXT_SHADOW_X or "Shadow X",
                                desc = L.TEXT_SHADOW_X_DESC or "How far right the shadow falls.",
                                order = 3,
                                min = -4, max = 4, step = 1,
                                disabled = function() local db = getSafeProfile() return not (db.text and db.text.shadowEnabled) end,
                                get = function() local db = getSafeProfile() local o = db.text and db.text.shadowOffset return type(o) == "table" and o[1] or 1 end,
                                set = function(_, val)
                                    local db = getSafeProfile()
                                    if not db.text then return end
                                    local o = type(db.text.shadowOffset) == "table" and db.text.shadowOffset or {1, -1}
                                    db.text.shadowOffset = { val, o[2] or -1 }
                                    RefreshOverlayStyles()
                                end,
                            },
                            shadowY = {
                                type = "range",
                                name = L.TEXT_SHADOW_Y or "Shadow Y",
                                desc = L.TEXT_SHADOW_Y_DESC or "How far up the shadow falls (negative is down).",
                                order = 4,
                                min = -4, max = 4, step = 1,
                                disabled = function() local db = getSafeProfile() return not (db.text and db.text.shadowEnabled) end,
                                get = function() local db = getSafeProfile() local o = db.text and db.text.shadowOffset return type(o) == "table" and o[2] or -1 end,
                                set = function(_, val)
                                    local db = getSafeProfile()
                                    if not db.text then return end
                                    local o = type(db.text.shadowOffset) == "table" and db.text.shadowOffset or {1, -1}
                                    db.text.shadowOffset = { o[1] or 1, val }
                                    RefreshOverlayStyles()
                                end,
                            },
                            glow = {
                                type = "toggle",
                                name = L.TEXT_GLOW or "Glow",
                                desc = L.TEXT_GLOW_DESC or "Draw a soft halo in its own colour around the hotkey text.",
                                order = 5,
                                width = "full",
                                get = function() return getSub("text", "glow").enabled end,
                                set = function(_, val) getSub("text", "glow").enabled = val and true or false; RefreshOverlayStyles() end,
                            },
                            glowColor = colorOption(6, L.TEXT_GLOW_COLOR or "Glow Colour", L.TEXT_GLOW_COLOR_DESC or "The halo's colour and strength.",
                                function() return getSub("text", "glow") end, "color", true,
                                function() return not getSub("text", "glow").enabled end),
                        },
                    },
                    bindings = {
                        type = "group",
                        inline = true,
                        order = 7,
                        name = L.TWO_KEYS or "Buttons with Two Keys",
                        args = {
                            showAllBindings = {
                                type = "toggle",
                                name = L.SHOW_ALL_BINDINGS or "Show Both Keys",
                                desc = L.SHOW_ALL_BINDINGS_DESC or "A button bound to two keys shows both, for example Q/SE.",
                                order = 1,
                                width = "full",
                                get = function() local db = getSafeProfile() return db.text and db.text.showAllBindings end,
                                set = function(_, val) local db = getSafeProfile() if db.text then db.text.showAllBindings = val and true or false; RefreshAbbreviations() end end,
                            },
                            bindingSeparator = {
                                type = "input",
                                name = L.BINDING_SEPARATOR or "Between the Keys",
                                desc = L.BINDING_SEPARATOR_DESC or "The text between the two keys.",
                                order = 2,
                                width = "half",
                                disabled = function() local db = getSafeProfile() return not (db.text and db.text.showAllBindings) end,
                                get = function() local db = getSafeProfile() return db.text and db.text.bindingSeparator or "/" end,
                                set = function(_, val) local db = getSafeProfile() if db.text then db.text.bindingSeparator = val or ""; RefreshAbbreviations() end end,
                            },
                        },
                    },
                },
    }
end

function Groups.abbreviations()
    return {
                type = "group",
                name = L.CUSTOM_ABBREVIATIONS or "Abbreviations",
                order = 2.5,
                args = BuildAbbreviationOptions(),
    }
end
