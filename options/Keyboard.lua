---@diagnostic disable: undefined-global
-- options/Keyboard.lua - the abbreviations, as a keyboard.
--
-- Drawn at the top of the Abbreviations page in place of the long list of text
-- boxes (which the classic window still shows). Every key is a keycap. Keys bound
-- to an action button light up and show the text AHOS draws for them; Shift, Ctrl
-- and Alt latch, so the keyboard can show any layer of bindings. Clicking a key
-- opens a card under the keyboard: its abbreviation, ready to change, the command
-- the game runs for it, an override an addon put over it, and every action button,
-- from every bar addon, that answers to it.
local addonName, ns = ...
local addon = ns.addon
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
local Controls = Kit and Kit.Controls
if not (Look and Controls) then return end

local L = ns.L
local floor, max, min = math.floor, math.max, math.min
local ipairs, unpack = ipairs, unpack

local Keyboard = {}
Kit.Keyboard = Keyboard

local MODIFIERS = { SHIFT = true, CTRL = true, ALT = true }

-- The main block, in key units. A key is { token, legend, width }.
local ROWS = {
	{ { "ESCAPE", "Esc" }, { false, nil, .5 }, { "F1" }, { "F2" }, { "F3" }, { "F4" }, { false, nil, .5 },
	  { "F5" }, { "F6" }, { "F7" }, { "F8" }, { false, nil, .5 }, { "F9" }, { "F10" }, { "F11" }, { "F12" } },
	{ { "`" }, { "1" }, { "2" }, { "3" }, { "4" }, { "5" }, { "6" }, { "7" }, { "8" }, { "9" }, { "0" },
	  { "-" }, { "=" }, { "BACKSPACE", "Bksp", 2 } },
	{ { "TAB", "Tab", 1.5 }, { "Q" }, { "W" }, { "E" }, { "R" }, { "T" }, { "Y" }, { "U" }, { "I" }, { "O" },
	  { "P" }, { "[" }, { "]" }, { "\\", nil, 1.5 } },
	{ { "CAPSLOCK", "Caps", 1.75 }, { "A" }, { "S" }, { "D" }, { "F" }, { "G" }, { "H" }, { "J" }, { "K" },
	  { "L" }, { ";" }, { "'" }, { "ENTER", "Enter", 2.25 } },
	{ { "SHIFT", "Shift", 2.25 }, { "Z" }, { "X" }, { "C" }, { "V" }, { "B" }, { "N" }, { "M" }, { "," },
	  { "." }, { "/" }, { "SHIFT", "Shift", 2.75 } },
	{ { "CTRL", "Ctrl", 1.5 }, { false, nil, 1 }, { "ALT", "Alt", 1.5 }, { "SPACE", "Space", 7 },
	  { "ALT", "Alt", 1.5 }, { false, nil, 1 }, { "CTRL", "Ctrl", 1.5 } },
}
local MAIN_UNITS = 15

local GROUPS = {
	{ label = "Mouse", keys = { { "BUTTON1", "M1" }, { "BUTTON2", "M2" }, { "BUTTON3", "M3" }, { "BUTTON4", "M4" },
	  { "BUTTON5", "M5" }, { "MOUSEWHEELUP", "WhUp" }, { "MOUSEWHEELDOWN", "WhDn" } } },
	{ label = "Navigation", keys = { { "INSERT", "Ins" }, { "HOME", "Home" }, { "PAGEUP", "PgUp" }, { "DELETE", "Del" },
	  { "END", "End" }, { "PAGEDOWN", "PgDn" }, { "UP", "Up" }, { "DOWN", "Dn" }, { "LEFT", "Lt" }, { "RIGHT", "Rt" } } },
	{ label = "Numpad", keys = { { "NUMPAD7", "7" }, { "NUMPAD8", "8" }, { "NUMPAD9", "9" }, { "NUMPAD4", "4" },
	  { "NUMPAD5", "5" }, { "NUMPAD6", "6" }, { "NUMPAD1", "1" }, { "NUMPAD2", "2" }, { "NUMPAD3", "3" },
	  { "NUMPAD0", "0" }, { "NUMPADDECIMAL", "." }, { "NUMPADDIVIDE", "/" }, { "NUMPADMULTIPLY", "*" },
	  { "NUMPADMINUS", "-" }, { "NUMPADPLUS", "+" } } },
}

local GAP, PAD = 4, 14
local MIN_UNIT, MAX_UNIT = 24, 38
local LAYER_H, GROUP_LABEL_H = 30, 18

local control

local function Keybinds() return addon.Keybinds end

-- The full binding for a key in the current layer, in the game's own order.
local function FullKey(token)
	if MODIFIERS[token] then return token end
	local mods = control.mods
	return (mods.ALT and "ALT-" or "") .. (mods.CTRL and "CTRL-" or "") .. (mods.SHIFT and "SHIFT-" or "") .. token
end

local function HasCustom(token)
	local kb = Keybinds()
	if not (kb and kb.GetConfiguredAbbreviation) then return false end
	return kb:GetConfiguredAbbreviation(token) ~= kb:GetKeyDefault(token)
end

local function Relayout()
	local panel = Kit.Panel
	if panel and panel.page and panel.page.Layout then panel.page:Layout() end
end

local function AfterAbbreviationChange()
	local kb = Keybinds()
	if kb and kb.ClearCache then kb:ClearCache() end
	if addon.IsReady and addon:IsReady() and addon.Core and addon.Core.FullUpdate then addon.Core:FullUpdate() end
	if Kit.Panel and Kit.Panel.Refresh then Kit.Panel:Refresh() else control:Update() end
end

---------------------------------------------------------------------------
-- Keys
---------------------------------------------------------------------------
local function StyleKey(key)
	local token = key.token
	local selected = control.selected == token
	local latched = MODIFIERS[token] and control.mods[token]
	local back, accent = Kit.BackdropColor, Kit.TextSelected
	local fill
	if latched then
		fill = { accent[1] * .55, accent[2] * .55, accent[3] * .55, 1 }
	elseif key.buttons then
		fill = { back[1] + (accent[1] - back[1]) * .28, back[2] + (accent[2] - back[2]) * .28, back[3] + (accent[3] - back[3]) * .28, 1 }
	elseif key.command then
		fill = { min(1, back[1] * 1.45 + .02), min(1, back[2] * 1.45 + .02), min(1, back[3] * 1.45 + .02), 1 }
	else
		fill = { back[1], back[2], back[3], .85 }
	end
	key.round:SetFill(fill)
	key.round:SetEdge(selected and Kit.BorderFocus or (key.hovered and Kit.BorderHover) or Kit.BorderIdle)
	local legendColour = (key.buttons or key.command or latched) and Kit.TextNormal or Kit.TextDisabled
	key.legend:SetTextColor(legendColour[1], legendColour[2], legendColour[3])
	key.shown:SetTextColor(unpack(Kit.TextHighlight))
	key.dot:SetVertexColor(unpack(Kit.TextSelected))
end

local function KeyTooltip(key)
	GameTooltip:SetOwner(key.frame, "ANCHOR_TOP")
	local full = FullKey(key.token)
	GameTooltip:AddLine(full, unpack(Kit.TextHighlight))
	if MODIFIERS[key.token] then
		GameTooltip:AddLine(L["Click to show the bindings with this modifier held."], Kit.TextNormal[1], Kit.TextNormal[2], Kit.TextNormal[3], true)
	elseif key.label then
		GameTooltip:AddLine(key.label, Kit.TextNormal[1], Kit.TextNormal[2], Kit.TextNormal[3], true)
	else
		GameTooltip:AddLine(L["Not bound."], unpack(Kit.TextDisabled))
	end
	GameTooltip:Show()
end

local function CreateKey(parent)
	local key = {}
	local frame = CreateFrame("Button", nil, parent)
	key.frame = frame
	key.round = Look.Round(frame, 4, nil, nil, true)

	local legend = frame:CreateFontString(nil, "OVERLAY")
	legend:SetFontObject(Kit.GetFont(10))
	legend:SetPoint("TOPLEFT", 4, -3)
	legend:SetPoint("RIGHT", -3, 0)
	legend:SetJustifyH("LEFT")
	legend:SetWordWrap(false)
	key.legend = legend

	-- what AHOS would draw on a button bound to this key
	local shown = frame:CreateFontString(nil, "OVERLAY")
	shown:SetFontObject(Kit.GetFont(12))
	shown:SetPoint("BOTTOMRIGHT", -4, 5)
	shown:SetPoint("LEFT", 3, 0)
	shown:SetJustifyH("RIGHT")
	shown:SetWordWrap(false)
	key.shown = shown

	local dot = frame:CreateTexture(nil, "OVERLAY")
	dot:SetSize(6, 6)
	dot:SetPoint("TOPRIGHT", -3, -3)
	Kit.SetGlyph(dot, "gem")
	key.dot = dot

	frame:SetScript("OnClick", function()
		PlaySound(852)
		local token = key.token
		if MODIFIERS[token] then control.mods[token] = not control.mods[token] end
		control.selected = token
		control:Update()
		Relayout()
	end)
	frame:SetScript("OnEnter", function() key.hovered = true; StyleKey(key); KeyTooltip(key) end)
	frame:SetScript("OnLeave", function() key.hovered = nil; StyleKey(key); GameTooltip:Hide() end)
	return key
end

---------------------------------------------------------------------------
-- The card under the keyboard
---------------------------------------------------------------------------
local LINE_H = 20

local function CreateCard(parent)
	local card = { lines = {} }
	local frame = CreateFrame("Frame", nil, parent)
	card.frame = frame
	card.round = Look.Round(frame, 8)

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(Look.Font(18, "display"))
	title:SetPoint("TOPLEFT", PAD, -12)
	title:SetJustifyH("LEFT")
	card.title = title

	local shownAs = frame:CreateFontString(nil, "OVERLAY")
	shownAs:SetFontObject(Kit.GetFont(12))
	shownAs:SetPoint("LEFT", title, "RIGHT", 12, -1)
	shownAs:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	shownAs:SetJustifyH("LEFT")
	shownAs:SetWordWrap(false)
	card.shownAs = shownAs

	-- One of the panel's own rows, so editing looks and behaves like every other box.
	local input = Controls.CreateInput(frame)
	input.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -38)
	input.frame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
	input.rule:Hide()
	card.input = input

	local heading = frame:CreateFontString(nil, "OVERLAY")
	heading:SetFontObject(Kit.GetFont(11))
	heading:SetJustifyH("LEFT")
	card.heading = heading
	return card
end

local function CardLine(card, index)
	local line = card.lines[index]
	if line then return line end
	line = {}
	line.icon = card.frame:CreateTexture(nil, "ARTWORK")
	line.icon:SetSize(16, 16)
	line.icon:SetTexCoord(.07, .93, .07, .93)
	line.text = card.frame:CreateFontString(nil, "OVERLAY")
	line.text:SetFontObject(Kit.GetFont(12))
	line.text:SetJustifyH("LEFT")
	line.text:SetWordWrap(false)
	card.lines[index] = line
	return line
end

-- Fills the card for the selected key and returns its height.
local function FillCard(card, width)
	local token = control.selected
	local kb = Keybinds()
	card.frame:SetWidth(width)
	for _, line in ipairs(card.lines) do line.icon:Hide(); line.text:Hide() end
	if not (token and kb) then
		card.frame:Hide()
		return 0
	end
	card.frame:Show()

	local full = FullKey(token)
	local isModifier = MODIFIERS[token]
	card.title:SetText(full)
	if isModifier then
		card.shownAs:SetText(L["Every binding with this modifier starts with its abbreviation."])
	else
		local shown = kb:Abbreviate(full)
		card.shownAs:SetText(L["Shown on buttons as"] .. "  |cffffffff" .. (shown ~= "" and shown or "-") .. "|r")
	end

	local input = card.input
	local default = kb:GetKeyDefault(token)
	input:SetLabel(string.format(L["Abbreviation for %s"], token))
	input:SetHelp(string.format(L["Default: %s. Clear the box to go back to it."], default))
	input:SetValue(kb:GetConfiguredAbbreviation(token))
	input:SetModified(HasCustom(token))
	input:SetCallback(function(_, value)
		if kb:SetCustomAbbreviation(token, value) then AfterAbbreviationChange() end
	end)
	input:SetOnRevert(function()
		if kb:SetCustomAbbreviation(token, "") then AfterAbbreviationChange() end
	end)
	input:Measure(width)
	input:Restyle()
	local y = 38 + input:GetHeight() + 8

	if isModifier then return y + 6 end

	local report = kb:DescribeKey(full, control.bound)
	local lines = {}
	if report.override then
		lines[#lines + 1] = { text = string.format(L["%s  |cffff9f40(an addon has put this over %s)|r"],
			kb:GetCommandLabel(report.override) or report.override, kb:GetCommandLabel(report.command) or L["nothing"]) }
	elseif report.label then
		lines[#lines + 1] = { text = report.label }
	end
	for _, button in ipairs(report.buttons) do
		local action = button.action
		local what = action and action.name or (button.slot and string.format(L["slot %d, empty"], button.slot)) or ""
		lines[#lines + 1] = {
			icon = action and action.icon,
			text = "|c" .. button.color .. button.providerLabel .. "|r  " .. button.name .. (what ~= "" and ("  ·  " .. what) or ""),
		}
	end
	if #report.providers > 1 then
		lines[#lines + 1] = { text = "|cffff9f40" .. string.format(L["%d bar addons answer to this key: %s"],
			#report.providers, table.concat(report.providers, ", ")) .. "|r" }
	end

	card.heading:ClearAllPoints()
	card.heading:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD, -y)
	card.heading:SetText(#lines > 0 and L["BOUND TO"] or L["Not bound in this layer."])
	card.heading:Show()
	y = y + GROUP_LABEL_H

	for i, info in ipairs(lines) do
		local line = CardLine(card, i)
		line.icon:ClearAllPoints()
		line.icon:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD, -y - 2)
		line.icon:SetTexture(info.icon)
		line.icon:SetShown(info.icon ~= nil)
		line.text:ClearAllPoints()
		line.text:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD + (info.icon and 22 or 0), -y - 3)
		line.text:SetPoint("RIGHT", card.frame, "RIGHT", -PAD, 0)
		line.text:SetText(info.text)
		line.text:Show()
		y = y + LINE_H
	end
	return y + 10
end

---------------------------------------------------------------------------
-- The control
---------------------------------------------------------------------------
local function Build(parent)
	control = { kind = "keyboard", first = true, persistent = true, keys = {}, labels = {},
		mods = { SHIFT = false, CTRL = false, ALT = false }, width = 640, height = 300 }

	local frame = CreateFrame("Frame", nil, parent)
	control.frame = frame

	local board = CreateFrame("Frame", nil, frame)
	board:SetPoint("TOPLEFT", 0, -2)
	board:SetPoint("RIGHT", 0, 0)
	control.board = board
	control.round = Look.Round(board, 8)

	local layer = board:CreateFontString(nil, "OVERLAY")
	layer:SetFontObject(Kit.GetFont(11))
	layer:SetPoint("TOPLEFT", PAD, -11)
	layer:SetPoint("RIGHT", -PAD, 0)
	layer:SetJustifyH("LEFT")
	control.layer = layer

	local count = 0
	local function AddKey(spec)
		count = count + 1
		local key = control.keys[count] or CreateKey(board)
		control.keys[count] = key
		key.token, key.legendText, key.units = spec[1], spec[2] or spec[1], spec[3] or 1
		key.legend:SetText(key.legendText)
		return key
	end
	for _, row in ipairs(ROWS) do
		for _, spec in ipairs(row) do
			if spec[1] then AddKey(spec) end
		end
	end
	for _, group in ipairs(GROUPS) do
		for _, spec in ipairs(group.keys) do AddKey(spec) end
		local label = board:CreateFontString(nil, "OVERLAY")
		label:SetFontObject(Kit.GetFont(10))
		label:SetText(L[group.label])
		control.labels[#control.labels + 1] = label
	end

	control.card = CreateCard(frame)

	-- Lays every key out for `width` and returns the keyboard's height.
	function control:Place(width)
		local unit = max(MIN_UNIT, min(MAX_UNIT, floor((width - PAD * 2 - GAP * (MAIN_UNITS - 1)) / MAIN_UNITS)))
		local function Span(units) return unit * units + GAP * (units - 1) end
		local index, y = 0, 34
		for _, row in ipairs(ROWS) do
			local x = PAD
			for _, spec in ipairs(row) do
				local units = spec[3] or 1
				if spec[1] then
					index = index + 1
					local key = self.keys[index]
					key.frame:ClearAllPoints()
					key.frame:SetPoint("TOPLEFT", self.board, "TOPLEFT", x, -y)
					key.frame:SetSize(Span(units), unit)
				end
				x = x + Span(units) + GAP
			end
			y = y + unit + GAP
			if row == ROWS[1] then y = y + GAP * 2 end
		end

		-- mouse, navigation and numpad flow along under the main block
		y = y + 10
		local x, lineTop, lineHeight = PAD, y, 0
		for g, group in ipairs(GROUPS) do
			local groupWidth = #group.keys * (unit + GAP) - GAP
			if x > PAD and x + groupWidth > width - PAD then
				x, lineTop = PAD, lineTop + lineHeight + 10
			end
			local label = self.labels[g]
			label:ClearAllPoints()
			label:SetPoint("TOPLEFT", self.board, "TOPLEFT", x, -lineTop)
			local kx, ky = x, lineTop + GROUP_LABEL_H
			for _ = 1, #group.keys do
				index = index + 1
				if kx + unit > width - PAD then kx, ky = x, ky + unit + GAP end
				local key = self.keys[index]
				key.frame:ClearAllPoints()
				key.frame:SetPoint("TOPLEFT", self.board, "TOPLEFT", kx, -ky)
				key.frame:SetSize(unit, unit)
				kx = kx + unit + GAP
			end
			lineHeight = max(lineHeight, ky + unit - lineTop)
			x = x + groupWidth + GAP * 6
		end
		return lineTop + lineHeight + PAD
	end

	function control:Measure(width)
		self.width = width or self.width
		local boardHeight = self:Place(self.width)
		self.board:SetHeight(boardHeight)
		local cardHeight = FillCard(self.card, self.width)
		self.card.frame:ClearAllPoints()
		self.card.frame:SetPoint("TOPLEFT", self.board, "BOTTOMLEFT", 0, -10)
		self.card.frame:SetHeight(max(1, cardHeight))
		self.height = 2 + boardHeight + (cardHeight > 0 and (cardHeight + 10) or 0) + 14
		self.frame:SetHeight(self.height)
		return self.height
	end

	function control:GetHeight() return self.height end
	function control:SetLabel() end
	function control:SetCallback() end
	function control:SetOnRevert() end
	function control:SetModified() end

	-- Reads the bindings and abbreviations again.
	function control:Update()
		local kb = Keybinds()
		if not kb then return end
		self.bound = kb.GetBoundButtons and kb:GetBoundButtons() or {}
		for _, key in ipairs(self.keys) do
			local token = key.token
			local full = FullKey(token)
			key.buttons, key.command, key.label = nil, nil, nil
			if not MODIFIERS[token] then
				key.buttons = self.bound[full]
				local ok, command = pcall(GetBindingAction, full, true)
				if ok and command and command ~= "" and addon:IsValueAccessible(command) then
					key.command = command
					key.label = kb:GetCommandLabel(command)
				end
			end
			key.shown:SetText(key.buttons and kb:Abbreviate(full) or "")
			key.dot:SetShown(HasCustom(token))
		end
		local held = {}
		for _, mod in ipairs({ "ALT", "CTRL", "SHIFT" }) do
			if self.mods[mod] then held[#held + 1] = mod end
		end
		self.layer:SetText(#held > 0 and string.format(L["SHOWING THE %s LAYER  ·  click a key to change its abbreviation"], table.concat(held, " + "))
			or L["NO MODIFIER  ·  click Shift, Ctrl or Alt to see that layer, or any key to change its abbreviation"])
		self:Measure(self.width)
		self:Restyle()
	end

	function control:Restyle()
		self.round:SetFill(Kit.InsetColor)
		self.round:SetEdge(Kit.BorderIdle)
		self.layer:SetTextColor(unpack(Kit.TextSelected))
		for _, label in ipairs(self.labels) do label:SetTextColor(unpack(Kit.TextDisabled)) end
		for _, key in ipairs(self.keys) do StyleKey(key) end
		local card = self.card
		card.round:SetFill(Kit.BackdropColor)
		card.round:SetEdge(Kit.BorderIdle)
		card.title:SetTextColor(unpack(Kit.TextHighlight))
		card.shownAs:SetTextColor(unpack(Kit.TextNormal))
		card.heading:SetTextColor(unpack(Kit.TextSelected))
		for _, line in ipairs(card.lines) do line.text:SetTextColor(unpack(Kit.TextNormal)) end
		card.input:Restyle()
	end

	return control
end

function Keyboard:GetControl(parent)
	return control or Build(parent)
end

function Keyboard:Restyle()
	if control then control:Restyle() end
end
