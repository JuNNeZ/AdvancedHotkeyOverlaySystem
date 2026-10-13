---@diagnostic disable: undefined-global
-- options/Overview.lua - what AHOS found and what it is doing, at a glance.
--
-- The top of the Status page, in place of a block of text:
-- a chip per bar addon with how many of its buttons AHOS found, in that
-- addon's colour (the one AHOS is drawing on is marked), how many buttons carry AHOS
-- text right now and how, and a warning chip when ElvUI is loaded and AHOS stands
-- back for it.
local addonName, ns = ...
local addon = ns.addon
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
if not Look then return end

local L = ns.L
local ipairs, unpack = ipairs, unpack

local Overview = {}
Kit.Overview = Overview

local PROVIDERS = { "Blizzard", "AzeriteUI", "Dominos", "Bartender4", "DiabolicUI3", "LUI", "Neuron" }
local PAD, CHIP_H, GAP, HEAD = 16, 26, 8, 38
local WARN = { 1, .62, .25 }

local control

local function Chip(index)
	local chip = control.chips[index]
	if chip then return chip end
	chip = CreateFrame("Frame", nil, control.card)
	chip:SetHeight(CHIP_H)
	chip.round = Look.Round(chip, 4, nil, nil, true)
	chip.dot = chip:CreateTexture(nil, "OVERLAY")
	chip.dot:SetSize(8, 8)
	chip.dot:SetPoint("LEFT", 10, 1)
	Kit.SetGlyph(chip.dot, "gem")
	chip.text = chip:CreateFontString(nil, "OVERLAY")
	chip.text:SetFontObject(Kit.GetFont(12))
	chip.text:SetPoint("LEFT", chip.dot, "RIGHT", 7, 0)
	chip.text:SetWordWrap(false)
	control.chips[index] = chip
	return chip
end

-- The chips to show, as { text, colour, marked }.
local function Collect()
	local list = {}
	local diagnostics = addon.Bars and addon.Bars.GetDiagnostics and addon.Bars:GetDiagnostics()
	local providers = diagnostics and diagnostics.providers or {}
	local detected = addon.GetDetectedProviderKey and addon:GetDetectedProviderKey() or "Blizzard"
	for _, key in ipairs(PROVIDERS) do
		local count = providers[key] or 0
		if count > 0 or key == detected then
			list[#list + 1] = {
				text = string.format("%s  |cffffffff%d|r", addon:GetProviderLabel(key), count),
				color = addon:GetProviderColor(key),
				marked = key == detected,
			}
		end
	end

	local drawn, native = 0, 0
	if addon.Display and addon.Display.GetOverlayCounts then drawn, native = addon.Display:GetOverlayCounts() end
	local enabled = addon.db and addon.db.profile and addon.db.profile.enabled
	if not enabled then
		list[#list + 1] = { text = L["Overlays off"], color = WARN }
	else
		list[#list + 1] = { text = string.format(L["%d with AHOS text"], drawn + native), color = Kit.TextSelected }
		if native > 0 then
			list[#list + 1] = { text = string.format(L["%d as native text"], native), color = Kit.TextNormal }
		end
	end
	if addon.IsElvUIConflictActive and addon:IsElvUIConflictActive() then
		local forced = addon.db and addon.db.profile and addon.db.profile.forceOverlaysWithElvUI
		list[#list + 1] = {
			text = forced and L["ElvUI loaded: AHOS draws anyway"] or L["ElvUI loaded: AHOS stands back"],
			color = WARN, warn = true,
		}
	end
	return list, diagnostics and diagnostics.total or 0
end

local function Build(parent)
	control = { kind = "overview", first = true, persistent = true, chips = {}, height = 100 }

	local frame = CreateFrame("Frame", nil, parent)
	control.frame = frame

	local card = CreateFrame("Frame", nil, frame)
	card:SetPoint("TOPLEFT", 0, -2)
	card:SetPoint("RIGHT", 0, 0)
	control.card = card
	control.round = Look.Round(card, 8)

	local label = card:CreateFontString(nil, "OVERLAY")
	label:SetFontObject(Kit.GetFont(11))
	label:SetPoint("TOPLEFT", PAD, -14)
	control.label = label

	local total = card:CreateFontString(nil, "OVERLAY")
	total:SetFontObject(Kit.GetFont(11))
	total:SetPoint("TOPRIGHT", -PAD, -14)
	total:SetJustifyH("RIGHT")
	control.total = total

	function control:Measure(width)
		self.width = width or self.width or 600
		local x, y = PAD, HEAD
		for _, chip in ipairs(self.chips) do
			if chip.shown then
				local w = chip.text:GetStringWidth() + 36
				if x > PAD and x + w > self.width - PAD then x, y = PAD, y + CHIP_H + GAP end
				chip:ClearAllPoints()
				chip:SetPoint("TOPLEFT", self.card, "TOPLEFT", x, -y)
				chip:SetWidth(w)
				x = x + w + GAP
			end
		end
		self.height = y + CHIP_H + PAD + 4
		self.card:SetHeight(self.height - 12)
		self.frame:SetHeight(self.height)
		return self.height
	end

	function control:GetHeight() return self.height end
	function control:SetLabel() end
	function control:SetCallback() end
	function control:SetOnRevert() end
	function control:SetModified() end

	function control:Update()
		local list, count = Collect()
		for _, chip in ipairs(self.chips) do chip.shown = false; chip:Hide() end
		for index, entry in ipairs(list) do
			local chip = Chip(index)
			chip.entry = entry
			chip.text:SetText(entry.text)
			chip.shown = true
			chip:Show()
		end
		self.label:SetText(L["WHAT AHOS FOUND"])
		self.total:SetText(string.format(L["%d action buttons"], count))
		self:Measure(self.width)
		self:Restyle()
	end

	function control:Restyle()
		self.round:SetFill(Kit.InsetColor)
		self.round:SetEdge(Kit.BorderIdle)
		self.label:SetTextColor(unpack(Kit.TextSelected))
		self.total:SetTextColor(unpack(Kit.TextDisabled))
		local back = Kit.BackdropColor
		for _, chip in ipairs(self.chips) do
			local entry = chip.entry
			if entry then
				local c = entry.color or Kit.TextNormal
				chip.round:SetFill(entry.warn and { c[1] * .3 + back[1] * .7, c[2] * .3 + back[2] * .7, c[3] * .3 + back[3] * .7, 1 } or back)
				chip.round:SetEdge(entry.marked and c or Kit.BorderIdle)
				chip.dot:SetVertexColor(c[1], c[2], c[3])
				chip.text:SetTextColor(unpack(Kit.TextNormal))
			end
		end
	end

	return control
end

function Overview:GetControl(parent)
	return control or Build(parent)
end

function Overview:Restyle()
	if control then control:Restyle() end
end
