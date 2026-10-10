---@diagnostic disable: undefined-global
-- options/Host.lua - what the options window reads from AHOS.
--
-- The window (Panel.lua) and the "changed from default" marks (Defaults.lua) ask
-- for the addon through these two tables, never through AHOS's modules directly,
-- so the kit stays the same kit AzUI Color Picker and JuNNeZ Edition run.
local addonName, ns = ...
local addon = ns.addon

-- Filled in by AdvancedHotkeyOverlaySystem.lua once AceDB exists.
ns.P = { DB = nil, defaults = nil }

local function Version()
	local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	return getMetadata and getMetadata(addonName, "Version") or ""
end

ns.Core = {
	appName = _G.AHOS_OPTIONS_PANEL_NAME or addonName,
	icon = "Interface\\AddOns\\" .. addonName .. "\\media\\logo.tga",
	version = Version(),
	Print = function(...) addon:Print(...) end,
	GetDB = function() return addon.db end,
	GetOptions = function()
		return addon.Options and addon.Options.GetPanelOptions and addon.Options:GetPanelOptions()
	end,
	OpenClassic = function()
		if addon.OpenClassicOptions then addon:OpenClassicOptions() end
	end,
	IsEnabled = function()
		return addon.db and addon.db.profile and addon.db.profile.enabled and true or false
	end,
	-- "Drawing on Dominos", in the provider's own colour.
	ProviderText = function()
		if not (addon.GetDetectedProviderText and addon.GetDetectedProviderKey) then return "" end
		local color = addon:GetProviderHexColor(addon:GetDetectedProviderKey()) or "ffffffff"
		return ns.L["Drawing on"] .. " |c" .. color .. addon:GetDetectedProviderText() .. "|r"
	end,
}
