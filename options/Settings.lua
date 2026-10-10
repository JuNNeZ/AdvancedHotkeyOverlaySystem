---@diagnostic disable: undefined-global
-- options/Settings.lua - ESC > Options > AddOns.
--
-- As AzeriteUI JuNNeZ Edition and AzUI Color Picker do it: Blizzard's Settings get
-- a landing page with the logo, the version and a button into the options window,
-- rather than the whole option list squeezed into Blizzard's frame. A client without
-- the canvas Settings API keeps the embedded Ace3 page (see EnsureBlizOptionsRegistered
-- in the core file).
local addonName, ns = ...
local addon = ns.addon
local L = ns.L

local NAME = _G.AHOS_OPTIONS_PANEL_NAME or "Advanced Hotkey Overlay System"

local function FontObject(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if _G[name] then return name end
	end
end

-- Leaves Blizzard's Settings first, so the window does not open underneath it.
function ns.OpenFromSettings(classic)
	if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
	local Panel = ns.OptionsKit and ns.OptionsKit.Panel
	if classic then
		if Panel then Panel:Close() end
		addon:OpenClassicOptions()
		return
	end
	if Panel and Panel:IsShown() then return end
	if not (Panel and Panel:Open()) then addon:OpenClassicOptions() end
end

-- Returns true once the landing page is registered, false when this client needs
-- the Ace3 page instead.
function ns.RegisterSettingsPage()
	if ns.settingsCategory then return true end
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return false end

	local page = CreateFrame("Frame")

	local logo = page:CreateTexture(nil, "ARTWORK")
	logo:SetSize(72, 72)
	logo:SetPoint("CENTER", page, "CENTER", 0, 130)
	logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\media\\logo.tga")

	-- The title as the TOC writes it
	local title = page:CreateFontString(nil, "ARTWORK", FontObject("GameFontNormalHuge3", "GameFontNormalHuge", "GameFontNormalLarge"))
	title:SetPoint("CENTER", page, "CENTER", 0, 70)
	title:SetText("|cff00D4AAAdvanced|r |cffffd700Hotkey|r |cffffffffOverlay|r |cffffd700System|r")

	local version = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	version:SetPoint("TOP", title, "BOTTOM", 0, -8)
	local v = ns.Core and ns.Core.version or ""
	version:SetText("|cff999999" .. L["Version"] .. " " .. v .. "|r")

	local about = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	about:SetPoint("TOP", version, "BOTTOM", 0, -18)
	about:SetWidth(520)
	about:SetText(L["Open the AHOS options with /ahos or the button below."])

	local function Button(text, scale, onClick)
		local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
		button:SetText(text)
		local label = button:GetFontString()
		local width = label and (label.GetUnboundedStringWidth and label:GetUnboundedStringWidth() or label:GetStringWidth()) or 0
		button:SetSize(math.max(180, math.ceil(width + 40)), 24)
		button:SetScale(scale)
		button:SetScript("OnClick", onClick)
		return button
	end
	local open = Button(L["Open AHOS Options"], 1.6, function() ns.OpenFromSettings() end)
	open:SetPoint("TOP", about, "BOTTOM", 0, -16)
	local classic = Button(L["Open the Classic Window"], 1, function() ns.OpenFromSettings(true) end)
	classic:SetPoint("TOP", open, "BOTTOM", 0, -14)

	-- What AHOS is drawing on right now, refreshed whenever the page is shown
	local provider = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	provider:SetPoint("TOP", classic, "BOTTOM", 0, -18)
	provider:SetWidth(520)
	page:SetScript("OnShow", function()
		provider:SetText(ns.Core and ns.Core.ProviderText and ns.Core.ProviderText() or "")
	end)

	local creditsHead = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	creditsHead:SetPoint("BOTTOM", page, "BOTTOM", 0, 74)
	creditsHead:SetText(L["Credits"])
	local credits = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	credits:SetPoint("TOP", creditsHead, "BOTTOM", 0, -4)
	credits:SetWidth(520)
	credits:SetText("|cff00D4AAJuNNeZ|r|cff999999 - " .. L["Author"] .. "|r\n"
		.. "|cff999999Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate|r")

	-- Settings asks a canvas page for these
	page.OnCommit = function() end
	page.OnDefault = function() end
	page.OnRefresh = function() end

	local category = Settings.RegisterCanvasLayoutCategory(page, NAME)
	category.ID = NAME
	Settings.RegisterAddOnCategory(category)
	page.open, page.classic, page.provider = open, classic, provider
	ns.settingsCategory, ns.settingsPage = category, page
	return true
end
