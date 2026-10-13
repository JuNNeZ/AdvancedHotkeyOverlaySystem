---@diagnostic disable: undefined-global
-- options/Preview.lua - a live preview of the hotkey text.
--
-- Four action buttons drawn at the top of the Display, Keybinds and Abbreviations
-- pages, labelled exactly as AHOS would label them: the same font, outline, colour,
-- anchor, offsets, alpha and scale as Display:StyleOverlay, and the same
-- abbreviation as Keybinds:Abbreviate. They show your own bindings for action
-- buttons 1-4 where you have them, and typical ones where you do not. Every page
-- refresh calls Update, so a setting moved is a preview changed.
local addonName, ns = ...
local addon = ns.addon
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
if not Look then return end

local L = ns.L
local unpack = unpack

local Preview = {}
Kit.HotkeyPreview = Preview

-- Pages that show it, by option-table key.
-- (Abbreviations has the keyboard instead, which shows the same text per key.)
Preview.Pages = { display = true, text = true }

local BUTTON, GAP, PAD = 46, 26, 16
local HEIGHT = 136

local ICONS = {
	"Interface\\Icons\\Spell_Nature_Lightning",
	"Interface\\Icons\\Ability_Rogue_Sprint",
	"Interface\\Icons\\Spell_Frost_FrostBolt02",
	"Interface\\Icons\\INV_Misc_Bag_08",
}
local SAMPLES = { "1", "SHIFT-2", "CTRL-MOUSEBUTTON4", "ALT-NUMPAD5" }

local function Profile()
	return addon and addon.db and addon.db.profile
end

-- Your binding for action button `i`, or a typical one.
local function Binding(i)
	local key = GetBindingKey and GetBindingKey("ACTIONBUTTON" .. i)
	if type(key) == "string" and key ~= "" and addon:IsValueAccessible(key) then return key, true end
	return SAMPLES[i], false
end

local function Outline(text)
	local outline = ""
	if text.outlineStyle and text.outlineStyle ~= "" then
		outline = text.outlineStyle
	elseif text.outline ~= nil then
		outline = text.outline and "OUTLINE" or "NONE"
	end
	if outline == "NONE" then outline = "" end
	if outline == "MONOCHROMEOUTLINE" then outline = "MONOCHROME,OUTLINE" end
	if outline == "MONOCHROMETHICKOUTLINE" then outline = "MONOCHROME,THICKOUTLINE" end
	return outline
end

local function FontPath(name)
	return addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(name) or "Fonts\\FRIZQT__.TTF"
end

local control

local function CreateSlot(parent, index)
	local slot = CreateFrame("Frame", nil, parent)
	slot:SetSize(BUTTON, BUTTON)

	local icon = slot:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture(ICONS[index])
	icon:SetTexCoord(.07, .93, .07, .93)

	local frameEdge = Look.Round(slot, 4, true, "OVERLAY")
	frameEdge:SetFill(nil)
	slot.edge = frameEdge

	-- Stands in for the overlay frame: all points of the button, then scaled.
	local overlay = CreateFrame("Frame", nil, slot)
	overlay:SetAllPoints(slot)
	overlay:SetFrameLevel(slot:GetFrameLevel() + 2)
	local text = overlay:CreateFontString(nil, "OVERLAY", nil, 7)
	text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	slot.overlay, slot.text = overlay, text

	local caption = parent:CreateFontString(nil, "OVERLAY")
	caption:SetFontObject(Kit.GetFont(11))
	caption:SetPoint("TOP", slot, "BOTTOM", 0, -8)
	caption:SetWidth(BUTTON + GAP - 4)
	caption:SetWordWrap(false)
	slot.caption = caption
	return slot
end

local function Build(parent)
	control = { kind = "preview", first = true, persistent = true }

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetHeight(HEIGHT)
	control.frame = frame

	-- the card sits inside the row with a little air under it
	local card = CreateFrame("Frame", nil, frame)
	card:SetPoint("TOPLEFT", 0, -2)
	card:SetPoint("BOTTOMRIGHT", 0, 12)
	control.round = Look.Round(card, 8)

	local label = card:CreateFontString(nil, "OVERLAY")
	label:SetFontObject(Kit.GetFont(11))
	label:SetPoint("TOPLEFT", PAD, -12)
	label:SetText(L["LIVE PREVIEW"])
	control.label = label

	local note = card:CreateFontString(nil, "OVERLAY")
	note:SetFontObject(Kit.GetFont(11))
	note:SetPoint("TOPRIGHT", -PAD, -12)
	note:SetJustifyH("RIGHT")
	control.note = note

	control.slots = {}
	for i = 1, #ICONS do
		local slot = CreateSlot(card, i)
		slot:SetPoint("TOPLEFT", card, "TOPLEFT", PAD + (i - 1) * (BUTTON + GAP), -36)
		control.slots[i] = slot
	end

	function control:GetHeight() return HEIGHT end
	function control:Measure() end
	function control:SetLabel() end
	function control:SetCallback() end
	function control:SetOnRevert() end
	function control:SetModified() end

	function control:Restyle()
		self.round:SetFill(Kit.InsetColor)
		self.round:SetEdge(Kit.BorderIdle)
		self.label:SetTextColor(unpack(Kit.TextSelected))
		self.note:SetTextColor(unpack(Kit.TextDisabled))
		for _, slot in ipairs(self.slots) do
			slot.edge:SetEdge({ 0, 0, 0, 1 })
			slot.caption:SetTextColor(unpack(Kit.TextDisabled))
		end
	end

	function control:Update()
		local db = Profile()
		if not (db and db.text and db.display) then return end
		local text, display = db.text, db.display
		local path, size, outline = FontPath(text.font or "Default"), text.fontSize or 14, Outline(text)
		local color = type(text.color) == "table" and text.color or { 1, 1, 1, 1 }
		local anyReal = false
		for i, slot in ipairs(self.slots) do
			local binding, real = Binding(i)
			anyReal = anyReal or real
			local shown = addon.Keybinds and addon.Keybinds.Abbreviate and addon.Keybinds:Abbreviate(binding) or binding
			local loads = addon.Config and addon.Config.FontLoads
			if loads and not loads(path) then path = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
			slot.text:SetFont(path, size, outline)
			local tint = addon.Keybinds and addon.Keybinds.GetModifierColor and addon.Keybinds:GetModifierColor(binding) or color
			slot.text:SetTextColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1)
			if text.shadowEnabled and type(text.shadowOffset) == "table" then
				slot.text:SetShadowColor(0, 0, 0, 1)
				slot.text:SetShadowOffset(unpack(text.shadowOffset))
			else
				slot.text:SetShadowColor(0, 0, 0, 0)
			end
			slot.text:ClearAllPoints()
			local anchor = display.anchor or "TOPRIGHT"
			slot.text:SetPoint(anchor, slot.overlay, anchor, display.xOffset or 0, display.yOffset or 0)
			slot.text:SetText(shown)
			slot.overlay:SetAlpha(display.alpha or 1)
			slot.overlay:SetScale(display.scale or 1)
			slot.caption:SetText(binding)
		end
		self.note:SetText(anyReal and L["Your bindings for action buttons 1-4"] or L["Example bindings"])
		self:Restyle()
	end

	return control
end

-- Renderer calls Kit.Preview:Request for every change made in the window. A change
-- to how the hotkey text looks also lights up the overlays on your real bars.
local FLASHED = { display = true, text = true, abbreviations = true }
Kit.Preview = {
	Request = function(_, options, path)
		if not (type(path) == "table" and FLASHED[path[1]]) then return false end
		if not (addon.Display and addon.Display.FlashOverlays) then return false end
		local settings = Kit.Panel and Kit.Panel.Settings and Kit.Panel.Settings()
		if settings and settings.flashBars == false then return false end
		addon.Display:FlashOverlays(Kit.TextSelected)
		return true
	end,
}

function Preview:GetControl(parent)
	return control or Build(parent)
end

function Preview:Restyle()
	if control then control:Restyle() end
end
