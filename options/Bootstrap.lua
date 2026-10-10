---@diagnostic disable: undefined-global
-- options/Bootstrap.lua
--
-- What the options kit expects from the addon it lives in. The kit came from
-- AzeriteUI JuNNeZ Edition and AzUI Color Picker, where it can borrow the installed
-- AzeriteUI's art. AHOS never does: every texture is its own, from media/panel
-- (Tools/MakePanelArt.py), so nothing here looks for another addon.
local addonName, ns = ...
local addon = ns.addon

-- Strings: AHOS's locale table first, then the English text the kit was written in.
ns.L = setmetatable({}, {
	__index = function(_, key)
		local localized = addon and addon.L and rawget(addon.L, key)
		if type(localized) == "string" then return localized end
		return key
	end,
})

ns.BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

-- The AHOS gold, from the logo's letter and the title.
ns.Colors = { normal = { 1, .84, 0 }, offwhite = { .89, .91, .93 }, highlight = { 1, 1, 1 }, class = {} }
for class, color in pairs(RAID_CLASS_COLORS or {}) do
	ns.Colors.class[class] = { color.r, color.g, color.b }
end

local PANEL_MEDIA = "Interface\\AddOns\\" .. addonName .. "\\media\\panel\\"
local PLAIN = "Interface\\Buttons\\WHITE8X8"

function ns.PanelMedia(name)
	return PANEL_MEDIA .. name .. ".tga"
end

-- Look.lua points the names the kit asks for at our art. Anything it does not
-- know falls back to Blizzard's, so a missing name never draws a green square.
ns.MediaOverride = {}

local fonts = {}
ns.API = {
	GetMedia = function(name)
		if ns.MediaOverride[name] then return ns.MediaOverride[name] end
		if name == "plain" then return PLAIN end
		if name:find("border", 1, true) then return "Interface\\Tooltips\\UI-Tooltip-Border" end
		return PLAIN
	end,
	GetFont = function(size, outline)
		local key = tostring(size) .. tostring(outline)
		if not fonts[key] then
			local font = CreateFont("AHOSOptionsFont" .. key)
			local file = GameFontNormal:GetFont()
			font:SetFont(file, size, outline and "OUTLINE" or "")
			fonts[key] = font
		end
		return fonts[key]
	end,
}
