---@diagnostic disable: undefined-global
-- modules/OptionsDisplay.lua - the Display page.
--
-- Render mode, anchor, size and layering; placement and edit mode; the
-- visibility rules; the combat style; press animations and the plate.
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
local isProviderLoaded, getSafeProfile, RefreshOverlayStyles, getSub = H.isProviderLoaded, H.getSafeProfile, H.RefreshOverlayStyles, H.getSub
local getVisibility, RefreshVisibility, colorOption, isSmartStrataEnabled = H.getVisibility, H.RefreshVisibility, H.colorOption, H.isSmartStrataEnabled

function Groups.display()
    return {
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
                    hideRangeDot = {
                        type = "toggle",
                        name = L.HIDE_RANGE_DOT or "Hide the Range Dot",
                        desc = L.HIDE_RANGE_DOT_DESC or "The game puts a dot on a button with no key while its action is in range. Hide it, also while AHOS is turned off.",
                        order = 1.1,
                        get = function() local db = getSafeProfile() return db.display and db.display.hideRangeDot end,
                        set = function(_, val) local db = getSafeProfile() if db.display then db.display.hideRangeDot = val; addon.Core:FullUpdate() end end,
                    },
                    anchor = {
                        type = "select",
                        name = L.ANCHOR_POINT or "Anchor Point",
                        desc = L.ANCHOR_POINT_DESC or "The point on the button where the text is anchored.",
                        order = 2,
                        values = {
                            TOPLEFT = L.ANCHOR_TOPLEFT or "Top Left", TOP = L.ANCHOR_TOP or "Top", TOPRIGHT = L.ANCHOR_TOPRIGHT or "Top Right",
                            LEFT = L.ANCHOR_LEFT or "Left", CENTER = L.ANCHOR_CENTER or "Center", RIGHT = L.ANCHOR_RIGHT or "Right",
                            BOTTOMLEFT = L.ANCHOR_BOTTOMLEFT or "Bottom Left", BOTTOM = L.ANCHOR_BOTTOM or "Bottom", BOTTOMRIGHT = L.ANCHOR_BOTTOMRIGHT or "Bottom Right",
                        },
                        sorting = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
                        get = function() local db = getSafeProfile() return db.display and db.display.anchor end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.anchor = val; RefreshOverlayStyles() end end,
                    },
                    xOffset = {
                        type = "range",
                        name = L.X_OFFSET or "X Offset",
                        desc = L.X_OFFSET_DESC or "Horizontal offset from the anchor point.",
                        order = 3,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.xOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.xOffset = val; RefreshOverlayStyles() end end,
                    },
                    yOffset = {
                        type = "range",
                        name = L.Y_OFFSET or "Y Offset",
                        desc = L.Y_OFFSET_DESC or "Vertical offset from the anchor point.",
                        order = 4,
                        min = -50, max = 50, step = 1,
                        get = function() local db = getSafeProfile() return db.display and db.display.yOffset end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.yOffset = val; RefreshOverlayStyles() end end,
                    },
                    scale = {
                        type = "range",
                        name = L.SCALE or "Scale",
                        desc = L.SCALE_DESC or "The scale of the overlay text.",
                        order = 5,
                        min = 0.1, max = 2, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.scale end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.scale = val; RefreshOverlayStyles() end end,
                    },
                    alpha = {
                        type = "range",
                        name = L.ALPHA or "Alpha",
                        desc = L.ALPHA_DESC or "The transparency of the overlay text.",
                        order = 6,
                        min = 0, max = 1, step = 0.05,
                        get = function() local db = getSafeProfile() return db.display and db.display.alpha end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.alpha = val; RefreshOverlayStyles() end end,
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
                                RefreshOverlayStyles()
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
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.strata = val; RefreshOverlayStyles() end end,
                    },
                    frameLevel = {
                        type = "range",
                        name = L.OVERLAY_LEVEL or "Overlay Frame Level",
                        desc = L.OVERLAY_LEVEL_DESC or "Manual override: fine-tune overlay stacking within the chosen strata when Smart Frame Layering is disabled.",
                        order = 9,
                        min = 1, max = 128, step = 1,
                        disabled = isSmartStrataEnabled,
                        get = function() local db = getSafeProfile() return db.display and db.display.frameLevel or 10 end,
                        set = function(info, val) local db = getSafeProfile() if db.display then db.display.frameLevel = val; RefreshOverlayStyles() end end,
                    },
                    followNativeHotkeyStyle = {
                        type = "toggle",
                        name = L.MIRROR_NATIVE_STYLE or "Mirror Native Hotkey Style",
                        desc = L.MIRROR_NATIVE_STYLE_DESC or "Overlay text will mirror the native hotkey font, color, and position when available.",
                        order = 10,
                        width = "full",
                        get = function() local db = getSafeProfile() return db.display and db.display.followNativeHotkeyStyle end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            if not db.display then return end
                            db.display.followNativeHotkeyStyle = val
                            -- This only changes appearance. Restyle active overlays in place so
                            -- native labels are never left blank by an unnecessary full rebuild.
                            RefreshOverlayStyles()
                        end,
                    },
                    followMasque = {
                        type = "toggle",
                        name = L.FOLLOW_MASQUE or "Follow Masque Skin",
                        desc = L.FOLLOW_MASQUE_DESC or "On buttons Masque skins, put the hotkey text where the skin puts the hotkey: its corner, offset, width and alignment, read from the skin itself. The font and colour stay yours. A bar with a place of its own keeps that.",
                        order = 11,
                        width = "full",
                        hidden = function() return not isProviderLoaded("Masque") and not (LibStub and LibStub("Masque", true)) end,
                        get = function() local db = getSafeProfile() return db.display and db.display.followMasque end,
                        set = function(_, val)
                            local db = getSafeProfile()
                            if not db.display then return end
                            db.display.followMasque = val and true or false
                            RefreshOverlayStyles()
                        end,
                    },
                    placement = {
                        type = "group",
                        inline = true,
                        order = 20,
                        name = L.PLACEMENT or "Placement",
                        args = {
                            edit = {
                                type = "execute",
                                name = L.EDIT_ON_BARS or "Edit Positions on Your Bars",
                                desc = L.EDIT_ON_BARS_DESC or "Drag the hotkey text into place on your own bars. Shift-drag moves one bar. Same as /ahos edit.",
                                order = 1,
                                width = "full",
                                func = function() if addon.Editor then addon.Editor:Toggle() end end,
                            },
                        },
                    },
                    visibility = {
                        type = "group",
                        inline = true,
                        order = 21,
                        name = L.VISIBILITY or "Visibility",
                        args = {
                            intro = {
                                type = "description",
                                order = 0,
                                name = L.VISIBILITY_DESC or "When the hotkey text shows. Every rule you turn on must agree; otherwise the text fades. A bar can also show its text only on mouseover (Bars page).",
                            },
                            fadeOutOfCombat = {
                                type = "toggle",
                                name = L.FADE_OUT_OF_COMBAT or "Fade Out of Combat",
                                desc = L.FADE_OUT_OF_COMBAT_DESC or "Show the hotkey text only in combat.",
                                order = 1,
                                width = "full",
                                get = function() return getVisibility().fadeOutOfCombat end,
                                set = function(_, val) getVisibility().fadeOutOfCombat = val and true or false; RefreshVisibility() end,
                            },
                            modifierOnly = {
                                type = "toggle",
                                name = L.MODIFIER_ONLY or "Only While a Modifier Is Held",
                                desc = L.MODIFIER_ONLY_DESC or "Show the hotkey text only while Shift, Ctrl or Alt is held down.",
                                order = 2,
                                width = "full",
                                get = function() return getVisibility().modifierOnly end,
                                set = function(_, val) getVisibility().modifierOnly = val and true or false; RefreshVisibility() end,
                            },
                            fadedAlpha = {
                                type = "range",
                                name = L.FADED_ALPHA or "Faded Alpha",
                                desc = L.FADED_ALPHA_DESC or "How much of the text stays when a rule hides it. 0% hides it completely.",
                                order = 3,
                                min = 0, max = 1, step = 0.05, isPercent = true,
                                get = function() return getVisibility().fadedAlpha or 0 end,
                                set = function(_, val) getVisibility().fadedAlpha = val; RefreshVisibility() end,
                            },
                            fadeDuration = {
                                type = "range",
                                name = L.FADE_DURATION or "Fade Time",
                                desc = L.FADE_DURATION_DESC or "Seconds the text takes to fade in or out. 0 is instant.",
                                order = 4,
                                min = 0, max = 2, step = 0.05,
                                get = function() return getVisibility().fadeDuration or 0.25 end,
                                set = function(_, val) getVisibility().fadeDuration = val end,
                            },
                            condition = {
                                type = "input",
                                multiline = 3,
                                name = L.VISIBILITY_CONDITION or "Condition of Your Own (Lua)",
                                desc = L.VISIBILITY_CONDITION_DESC or "Advanced: a Lua expression that must be true for the text to show, for example: UnitExists(\"target\") or bar == \"Blizzard:1\". It can read button, bar and key, and the game's read-only state (combat, mounted, modifiers, units). Leave empty to turn it off.",
                                order = 5,
                                width = "full",
                                get = function() return getVisibility().condition or "" end,
                                validate = function(_, val)
                                    if not addon.Visibility then return true end
                                    local ok, err = addon.Visibility:CheckCondition(val)
                                    if ok then return true end
                                    return (L.VISIBILITY_CONDITION_INVALID or "That condition is not valid Lua: ") .. tostring(err)
                                end,
                                set = function(_, val)
                                    getVisibility().condition = type(val) == "string" and val or ""
                                    RefreshVisibility()
                                end,
                            },
                        },
                    },
                    combat = {
                        type = "group",
                        inline = true,
                        order = 22,
                        name = L.COMBAT_STYLE or "In Combat",
                        args = {
                            enabled = {
                                type = "toggle",
                                name = L.COMBAT_STYLE_ENABLE or "Combat Style",
                                desc = L.COMBAT_STYLE_ENABLE_DESC or "Draw the hotkey text in another colour and size while you are in combat.",
                                order = 1,
                                width = "full",
                                get = function() return getSub("visibility", "combatStyle").enabled end,
                                set = function(_, val) getSub("visibility", "combatStyle").enabled = val and true or false; RefreshOverlayStyles() end,
                            },
                            color = colorOption(2, L.COMBAT_STYLE_COLOR or "Combat Colour", L.COMBAT_STYLE_COLOR_DESC or "The text colour in combat.",
                                function() return getSub("visibility", "combatStyle") end, "color", false,
                                function() return not getSub("visibility", "combatStyle").enabled end),
                            scale = {
                                type = "range",
                                name = L.COMBAT_STYLE_SCALE or "Combat Size",
                                desc = L.COMBAT_STYLE_SCALE_DESC or "The text size in combat, relative to its size out of it.",
                                order = 3,
                                min = 0.5, max = 2, step = 0.05, isPercent = true,
                                disabled = function() return not getSub("visibility", "combatStyle").enabled end,
                                get = function() return getSub("visibility", "combatStyle").scale or 1 end,
                                set = function(_, val) getSub("visibility", "combatStyle").scale = val; RefreshOverlayStyles() end,
                            },
                        },
                    },
                    effects = {
                        type = "group",
                        inline = true,
                        order = 23,
                        name = L.EFFECTS or "Effects",
                        args = {
                            pressAnimation = {
                                type = "select",
                                name = L.PRESS_ANIMATION or "When Pressed",
                                desc = L.PRESS_ANIMATION_DESC or "What the hotkey text does when you press its button.",
                                order = 1,
                                values = {
                                    none = L.PRESS_NONE or "Nothing",
                                    flash = L.PRESS_FLASH or "Flash",
                                    pulse = L.PRESS_PULSE or "Pulse",
                                },
                                sorting = { "none", "flash", "pulse" },
                                get = function() local db = getSafeProfile() return db.display and db.display.pressAnimation or "none" end,
                                set = function(_, val) local db = getSafeProfile() if db.display then db.display.pressAnimation = val end end,
                            },
                            pressColor = colorOption(2, L.PRESS_COLOR or "Flash Colour", L.PRESS_COLOR_DESC or "The colour the text flashes when its button is pressed.",
                                function() return getSafeProfile().display or {} end, "pressColor", false,
                                function() local db = getSafeProfile() local mode = db.display and db.display.pressAnimation return mode ~= "flash" and mode ~= "pulse" end,
                                function() end),
                            background = {
                                type = "toggle",
                                name = L.TEXT_BACKGROUND or "Background Plate",
                                desc = L.TEXT_BACKGROUND_DESC or "Draw a plate behind the hotkey text, so it reads on any icon.",
                                order = 3,
                                width = "full",
                                get = function() return getSub("display", "background").enabled end,
                                set = function(_, val) getSub("display", "background").enabled = val and true or false; RefreshOverlayStyles() end,
                            },
                            backgroundColor = colorOption(4, L.TEXT_BACKGROUND_COLOR or "Plate Colour", L.TEXT_BACKGROUND_COLOR_DESC or "The plate's colour and transparency.",
                                function() return getSub("display", "background") end, "color", true,
                                function() return not getSub("display", "background").enabled end),
                            backgroundPadding = {
                                type = "range",
                                name = L.TEXT_BACKGROUND_PADDING or "Plate Padding",
                                desc = L.TEXT_BACKGROUND_PADDING_DESC or "Space between the text and the plate's edge.",
                                order = 5,
                                min = 0, max = 8, step = 1,
                                disabled = function() return not getSub("display", "background").enabled end,
                                get = function() return getSub("display", "background").padding or 2 end,
                                set = function(_, val) getSub("display", "background").padding = val; RefreshOverlayStyles() end,
                            },
                        },
                    },
                },
    }
end
