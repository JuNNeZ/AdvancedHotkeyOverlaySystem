---@diagnostic disable: undefined-global
-- modules/OptionsBars.lua - the Bars page.
--
-- Settings for one bar: leave it alone, its text size, mouseover, a place of its
-- own; and the single buttons AHOS is told to leave alone.
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
local getSafeProfile, RefreshOverlayStyles, RefreshVisibility = H.getSafeProfile, H.RefreshOverlayStyles, H.RefreshVisibility

-- Settings per bar. The bar being edited is the window's state, not the profile's.
local function getBarList()
    return addon.Bars and addon.Bars.GetBarList and addon.Bars:GetBarList() or {}
end

local function getSelectedBar()
    local list = getBarList()
    for _, entry in ipairs(list) do
        if entry.key == Options.selectedBar then return entry end
    end
    Options.selectedBar = list[1] and list[1].key or nil
    return list[1]
end

-- The selected bar's settings; `create` makes them for a bar that has none.
local function getBarSettings(create)
    local entry = getSelectedBar()
    local db = getSafeProfile()
    if not entry or type(db.bars) ~= "table" then return nil, entry end
    local settings = db.bars[entry.key]
    if not settings and create then
        settings = { label = entry.label }
        db.bars[entry.key] = settings
    end
    return settings, entry
end

-- A bar back at every default needs no entry of its own.
local function pruneBarSettings()
    local _, entry = getBarSettings(false)
    if entry and addon.Bars.PruneBarSettings then addon.Bars:PruneBarSettings(entry.key) end
end

local function barPositionDisabled()
    local settings = getBarSettings(false)
    return getSelectedBar() == nil or not (settings and settings.position) or (settings and settings.hide) or false
end

function Groups.bars()
    return {
                type = "group",
                name = L.BARS or "Bars",
                order = 2.7,
                args = {
                    intro = {
                        type = "description",
                        order = 0,
                        name = L.BARS_DESC or "Give one bar its own text size, or leave it to its own hotkey text. Everything else follows the profile.",
                    },
                    bar = {
                        type = "select",
                        name = L.BAR or "Bar",
                        desc = L.BAR_SELECT_DESC or "The bar to change. Bars with settings of their own are marked with *.",
                        order = 1,
                        width = "full",
                        values = function()
                            local values, db = {}, getSafeProfile()
                            for _, entry in ipairs(getBarList()) do
                                local own = type(db.bars) == "table" and db.bars[entry.key]
                                values[entry.key] = (own and "* " or "") .. entry.label
                                    .. (entry.count > 0 and string.format("  (%d)", entry.count) or "")
                            end
                            return values
                        end,
                        sorting = function()
                            local order = {}
                            for _, entry in ipairs(getBarList()) do order[#order + 1] = entry.key end
                            return order
                        end,
                        get = function() local entry = getSelectedBar() return entry and entry.key end,
                        set = function(_, value) Options.selectedBar = value end,
                    },
                    hide = {
                        type = "toggle",
                        name = L.BAR_HIDE or "Leave This Bar Alone",
                        desc = L.BAR_HIDE_DESC or "AHOS draws nothing on this bar, and its buttons show their own hotkey text.",
                        order = 2,
                        width = "full",
                        disabled = function() return getSelectedBar() == nil end,
                        get = function() local settings = getBarSettings(false) return settings and settings.hide or false end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if not settings then return end
                            settings.hide = value and true or nil
                            pruneBarSettings()
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                    scale = {
                        type = "range",
                        name = L.BAR_SCALE or "Text Size on This Bar",
                        desc = L.BAR_SCALE_DESC or "The hotkey text on this bar, relative to the size everywhere else. 100% follows the profile.",
                        order = 3,
                        min = 0.5, max = 2, step = 0.05, isPercent = true,
                        disabled = function()
                            local settings = getBarSettings(false)
                            return getSelectedBar() == nil or (settings and settings.hide) or false
                        end,
                        get = function() local settings = getBarSettings(false) return settings and settings.scale or 1 end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if not settings then return end
                            settings.scale = value
                            pruneBarSettings()
                            RefreshOverlayStyles()
                        end,
                    },
                    mouseover = {
                        type = "toggle",
                        name = L.BAR_MOUSEOVER or "Show on Mouseover",
                        desc = L.BAR_MOUSEOVER_DESC or "This bar's hotkey text shows only while the mouse is over the bar.",
                        order = 4,
                        width = "full",
                        disabled = function()
                            local settings = getBarSettings(false)
                            return getSelectedBar() == nil or (settings and settings.hide) or false
                        end,
                        get = function() local settings = getBarSettings(false) return settings and settings.mouseover or false end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if not settings then return end
                            settings.mouseover = value and true or nil
                            pruneBarSettings()
                            RefreshVisibility()
                        end,
                    },
                    position = {
                        type = "toggle",
                        name = L.BAR_POSITION or "A Place of Its Own",
                        desc = L.BAR_POSITION_DESC or "Put this bar's hotkey text somewhere else than on the other bars.",
                        order = 5,
                        width = "full",
                        disabled = function()
                            local settings = getBarSettings(false)
                            return getSelectedBar() == nil or (settings and settings.hide) or false
                        end,
                        get = function() local settings = getBarSettings(false) return settings and settings.position or false end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if not settings then return end
                            if value then
                                local display = getSafeProfile().display or {}
                                settings.position = true
                                settings.anchor = settings.anchor or display.anchor
                                settings.xOffset = settings.xOffset or display.xOffset
                                settings.yOffset = settings.yOffset or display.yOffset
                            else
                                settings.position, settings.anchor, settings.xOffset, settings.yOffset = nil, nil, nil, nil
                            end
                            pruneBarSettings()
                            RefreshOverlayStyles()
                        end,
                    },
                    anchor = {
                        type = "select",
                        name = L.BAR_ANCHOR or "Anchor on This Bar",
                        desc = L.BAR_ANCHOR_DESC or "The point on this bar's buttons the text is anchored to.",
                        order = 6,
                        values = {
                            TOPLEFT = L.ANCHOR_TOPLEFT or "Top Left", TOP = L.ANCHOR_TOP or "Top", TOPRIGHT = L.ANCHOR_TOPRIGHT or "Top Right",
                            LEFT = L.ANCHOR_LEFT or "Left", CENTER = L.ANCHOR_CENTER or "Center", RIGHT = L.ANCHOR_RIGHT or "Right",
                            BOTTOMLEFT = L.ANCHOR_BOTTOMLEFT or "Bottom Left", BOTTOM = L.ANCHOR_BOTTOM or "Bottom", BOTTOMRIGHT = L.ANCHOR_BOTTOMRIGHT or "Bottom Right",
                        },
                        sorting = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
                        disabled = barPositionDisabled,
                        get = function()
                            local settings = getBarSettings(false)
                            local display = getSafeProfile().display or {}
                            return settings and settings.anchor or display.anchor
                        end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if settings then settings.anchor = value; RefreshOverlayStyles() end
                        end,
                    },
                    xOffset = {
                        type = "range",
                        name = L.BAR_X_OFFSET or "X Offset on This Bar",
                        desc = L.X_OFFSET_DESC or "Horizontal offset from the anchor point.",
                        order = 7,
                        min = -50, max = 50, step = 1,
                        disabled = barPositionDisabled,
                        get = function()
                            local settings = getBarSettings(false)
                            local display = getSafeProfile().display or {}
                            return settings and settings.xOffset or display.xOffset or 0
                        end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if settings then settings.xOffset = value; RefreshOverlayStyles() end
                        end,
                    },
                    yOffset = {
                        type = "range",
                        name = L.BAR_Y_OFFSET or "Y Offset on This Bar",
                        desc = L.Y_OFFSET_DESC or "Vertical offset from the anchor point.",
                        order = 8,
                        min = -50, max = 50, step = 1,
                        disabled = barPositionDisabled,
                        get = function()
                            local settings = getBarSettings(false)
                            local display = getSafeProfile().display or {}
                            return settings and settings.yOffset or display.yOffset or 0
                        end,
                        set = function(_, value)
                            local settings = getBarSettings(true)
                            if settings then settings.yOffset = value; RefreshOverlayStyles() end
                        end,
                    },
                    ignored = {
                        type = "description",
                        order = 11,
                        name = function()
                            local list = addon.Bars.GetIgnoredButtons and addon.Bars:GetIgnoredButtons() or {}
                            if #list == 0 then
                                return L.IGNORED_NONE or "No single buttons are left alone. Pick one on the Inspector page, or type /ahos ignore <ButtonName>."
                            end
                            return (L.IGNORED_LIST or "Buttons left to their own hotkey text: ") .. table.concat(list, ", ")
                        end,
                    },
                    clearIgnored = {
                        type = "execute",
                        name = L.IGNORED_CLEAR or "Draw on Every Button Again",
                        desc = L.IGNORED_CLEAR_DESC or "Forget every single button AHOS was told to leave alone.",
                        order = 12,
                        width = "full",
                        disabled = function() return #(addon.Bars.GetIgnoredButtons and addon.Bars:GetIgnoredButtons() or {}) == 0 end,
                        func = function()
                            for _, name in ipairs(addon.Bars:GetIgnoredButtons()) do addon.Bars:SetButtonIgnored(name, false) end
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                    reset = {
                        type = "execute",
                        name = L.BAR_RESET or "Reset Every Bar",
                        desc = L.BAR_RESET_DESC or "Remove the settings of every bar, so all of them follow the profile again.",
                        order = 10,
                        width = "full",
                        disabled = function() local db = getSafeProfile() return type(db.bars) ~= "table" or next(db.bars) == nil end,
                        func = function()
                            local db = getSafeProfile()
                            if type(db.bars) == "table" then wipe(db.bars) end
                            if addon:IsReady() then addon.Core:FullUpdate() end
                        end,
                    },
                },
    }
end
