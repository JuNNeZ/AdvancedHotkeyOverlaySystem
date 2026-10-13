---@diagnostic disable: undefined-global
-- options/Inspector.lua - point at an action button and see what AHOS knows about it.
--
-- The Inspector page in place of /ahos inspect <ButtonName>, which needs the
-- button's name. "Pick a Button" steps the window aside and lays a catcher over the
-- screen: the action button under the mouse is outlined and described as you move,
-- a click keeps it, a right-click goes back to the one before. The card says which
-- bar addon drew the button, the command and the action on it, the key that presses
-- it, the text AHOS draws for that, and why.
local addonName, ns = ...
local addon = ns.addon
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
local Controls = Kit and Kit.Controls
if not (Look and Controls) then return end

local L = ns.L
local ipairs, max, unpack = ipairs, math.max, unpack

local Inspector = {}
Kit.Inspector = Inspector

local PAD, LINE_H, LABEL_W = 16, 20, 110
local PICK_INTERVAL = 0.05

local control, picker, marker

---------------------------------------------------------------------------
-- What to say about a button
---------------------------------------------------------------------------
local STATE_TEXT = {
	overlay = L["AHOS draws its own text over this button."],
	native = L["AHOS writes its text into the button's own hotkey label."],
	released = L["This bar is left to its own hotkey text (see the Bars page)."],
	ignored = L["You told AHOS to leave this button alone."],
	none = L["AHOS draws nothing on this button."],
}

-- Why the button shows what it shows, in one sentence.
local function Reason(info, state)
	if state == "released" or state == "ignored" then return STATE_TEXT[state] end
	if not info.key or info.key == "" then
		return L["No key is bound to this button, so there is nothing to show."]
	end
	if state == "none" then
		if info.slot and not info.action then return L["Its action slot is empty, so AHOS leaves it blank."] end
		return L["The button is hidden, or AHOS is turned off."]
	end
	return string.format(L["%s presses this button, and AHOS shortens it to %s."], info.key,
		(info.shown and info.shown ~= "") and info.shown or "-")
end

-- The lines of the card for `button`, as { label, text, icon }.
local function Describe(button)
	local kb = addon.Keybinds
	local info = button and kb and kb.DescribeButton and kb:DescribeButton(button)
	if not info then return nil end
	local state = addon.Display and addon.Display.GetButtonState and addon.Display:GetButtonState(info.name) or "none"
	local action = info.action
	local what = action and action.name
		or (info.slot and string.format(L["slot %d, empty"], info.slot)) or L["none"]
	return {
		title = info.name,
		subtitle = "|c" .. info.color .. info.providerLabel .. "|r" .. (info.bar and ("  ·  " .. info.bar) or ""),
		lines = {
			{ L["Key"], (info.key ~= "" and info.key) or L["not bound"] },
			{ L["Shown as"], (info.shown ~= "" and ("|cffffffff" .. info.shown .. "|r")) or "-" },
			{ L["Command"], info.command and (kb:GetCommandLabel(info.command) .. "  |cff8c949f" .. info.command .. "|r") or L["none"] },
			{ L["Action"], what, action and action.icon },
			{ L["AHOS"], STATE_TEXT[state] or STATE_TEXT.none },
			{ L["Why"], Reason(info, state) },
		},
		button = button,
	}
end
Inspector.Describe = Describe

---------------------------------------------------------------------------
-- Picking a button off the screen
---------------------------------------------------------------------------
local function ButtonUnderMouse()
	local bars = addon.Bars
	if not (bars and bars.GetAllButtons) then return nil end
	for _, button in ipairs(bars:GetAllButtons()) do
		if addon:IsFrameVisibleSafe(button) then
			local ok, over = pcall(button.IsMouseOver, button)
			if ok and over then return button end
		end
	end
end

local function Mark(button)
	if not marker then
		marker = CreateFrame("Frame", nil, UIParent)
		marker:SetFrameStrata("TOOLTIP")
		marker.round = Look.Round(marker, 4, true, "OVERLAY")
	end
	if not button then marker:Hide(); return end
	marker:ClearAllPoints()
	marker:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
	marker:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
	local accent = Kit.TextSelected
	marker.round:SetFill(accent, .18)
	marker.round:SetEdge(accent, 1)
	marker:Show()
end

local function StopPicking(keep)
	if not (picker and picker:IsShown()) then return end
	picker:Hide()
	Mark(nil)
	if not keep then Inspector.button = picker.before end
	picker.before = nil
	local panel = Kit.Panel
	if panel and panel.Open then panel:Open("inspector") end
	if control then control:Update() end
end
Inspector.StopPicking = StopPicking

local function BuildPicker()
	picker = CreateFrame("Button", nil, UIParent)
	picker:SetAllPoints(UIParent)
	picker:SetFrameStrata("FULLSCREEN_DIALOG")
	picker:EnableMouse(true)
	picker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	picker:Hide()

	local hint = picker:CreateFontString(nil, "OVERLAY")
	hint:SetFontObject(Look.Font(16, "display"))
	hint:SetPoint("TOP", picker, "TOP", 0, -90)
	picker.hint = hint

	picker.elapsed = 0
	picker:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + (elapsed or 0)
		if self.elapsed < PICK_INTERVAL then return end
		self.elapsed = 0
		local button = ButtonUnderMouse()
		if button ~= self.hovered then
			self.hovered = button
			Mark(button)
			if button then Inspector.button = button end
		end
	end)
	picker:SetScript("OnClick", function(self, mouse)
		StopPicking(mouse ~= "RightButton" and self.hovered ~= nil)
	end)
	-- combat gives the screen back
	picker:RegisterEvent("PLAYER_REGEN_DISABLED")
	picker:SetScript("OnEvent", function() StopPicking(true) end)
end

function Inspector:StartPicking()
	if not picker then BuildPicker() end
	picker.before = self.button
	picker.hovered = nil
	picker.elapsed = PICK_INTERVAL
	picker.hint:SetText(L["Point at an action button and click it.  Right-click to cancel."])
	picker.hint:SetTextColor(unpack(Kit.TextHighlight))
	-- the window would cover the bars
	if Kit.Panel and Kit.Panel.Close then Kit.Panel:Close() end
	picker:Show()
end

function Inspector:IsPicking()
	return picker and picker:IsShown() or false
end

-- The button under the mouse while picking, for anything that wants to ask.
Inspector.ButtonUnderMouse = ButtonUnderMouse

---------------------------------------------------------------------------
-- The card
---------------------------------------------------------------------------
local function Line(index)
	local line = control.lines[index]
	if line then return line end
	local card = control.card
	line = {}
	line.label = card:CreateFontString(nil, "OVERLAY")
	line.label:SetFontObject(Kit.GetFont(11))
	line.label:SetJustifyH("LEFT")
	line.icon = card:CreateTexture(nil, "ARTWORK")
	line.icon:SetSize(16, 16)
	line.icon:SetTexCoord(.07, .93, .07, .93)
	line.text = card:CreateFontString(nil, "OVERLAY")
	line.text:SetFontObject(Kit.GetFont(12))
	line.text:SetJustifyH("LEFT")
	line.text:SetJustifyV("TOP")
	line.text:SetWordWrap(true)
	control.lines[index] = line
	return line
end

local function Build(parent)
	control = { kind = "inspector", first = true, persistent = true, lines = {}, height = 140 }

	local frame = CreateFrame("Frame", nil, parent)
	control.frame = frame

	local card = CreateFrame("Frame", nil, frame)
	card:SetPoint("TOPLEFT", 0, -2)
	card:SetPoint("RIGHT", 0, 0)
	control.card = card
	control.round = Look.Round(card, 8)

	local title = card:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(Look.Font(18, "display"))
	title:SetPoint("TOPLEFT", PAD, -14)
	title:SetJustifyH("LEFT")
	control.title = title

	local subtitle = card:CreateFontString(nil, "OVERLAY")
	subtitle:SetFontObject(Kit.GetFont(12))
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	subtitle:SetJustifyH("LEFT")
	control.subtitle = subtitle

	control.pick = Controls.CreateBareButton(card, L["Pick a Button"], function() Inspector:StartPicking() end)
	control.pick:SetPoint("TOPRIGHT", card, "TOPRIGHT", -PAD, -14)
	control.copy = Controls.CreateBareButton(card, L["Copy Details"], function()
		local button = Inspector.button
		if button and addon.Keybinds and addon.Keybinds.GetButtonDebugInfo and addon.ShowTextWindow then
			local text = addon.Keybinds:GetButtonDebugInfo(button):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			addon:ShowTextWindow(L["AHOS Inspect"], text)
		end
	end)
	control.copy:SetPoint("RIGHT", control.pick, "LEFT", -8, 0)
	-- One button AHOS should leave to its own hotkey text (profile.buttons).
	control.ignore = Controls.CreateBareButton(card, L["Leave This Button Alone"], function()
		local name = Inspector.button and addon.Bars and Inspector.button:GetName()
		if not name then return end
		addon.Bars:SetButtonIgnored(name, not addon.Bars:IsButtonIgnored(name))
		if addon.Core then addon.Core:FullUpdate() end
		control:Update()
	end)
	control.ignore:SetPoint("RIGHT", control.copy, "LEFT", -8, 0)

	function control:Measure(width)
		self.width = width or self.width or 600
		local textWidth = max(120, self.width - PAD * 2 - LABEL_W)
		local y = 62
		for _, line in ipairs(self.lines) do
			if line.shown then
				line.label:ClearAllPoints()
				line.label:SetPoint("TOPLEFT", self.card, "TOPLEFT", PAD, -y - 2)
				line.label:SetWidth(LABEL_W - 8)
				line.icon:ClearAllPoints()
				line.icon:SetPoint("TOPLEFT", self.card, "TOPLEFT", PAD + LABEL_W, -y)
				line.text:ClearAllPoints()
				line.text:SetPoint("TOPLEFT", self.card, "TOPLEFT", PAD + LABEL_W + (line.hasIcon and 22 or 0), -y - 1)
				line.text:SetWidth(textWidth - (line.hasIcon and 22 or 0))
				local lines = Controls.MeasureText and Controls.MeasureText(Kit.GetFont(12), line.text:GetText() or "", textWidth) or LINE_H
				y = y + max(LINE_H, lines + 6)
			end
			line.label:SetShown(line.shown)
			line.text:SetShown(line.shown)
			line.icon:SetShown(line.shown and line.hasIcon or false)
		end
		self.height = y + 14
		self.card:SetHeight(self.height - 6)
		self.frame:SetHeight(self.height)
		return self.height
	end

	function control:GetHeight() return self.height end
	function control:SetLabel() end
	function control:SetCallback() end
	function control:SetOnRevert() end
	function control:SetModified() end

	function control:Update()
		local described = Describe(Inspector.button)
		for _, line in ipairs(self.lines) do line.shown = false end
		if described then
			self.title:SetText(described.title)
			self.subtitle:SetText(described.subtitle)
			for index, entry in ipairs(described.lines) do
				local line = Line(index)
				line.label:SetText(string.upper(entry[1]))
				line.text:SetText(entry[2])
				line.icon:SetTexture(entry[3])
				line.hasIcon = entry[3] ~= nil
				line.shown = true
			end
		else
			self.title:SetText(L["No button picked yet"])
			self.subtitle:SetText(L["Click Pick a Button, then point at any action button on your screen."])
		end
		self.copy:SetDisabled(described == nil)
		local name = described and described.title
		local ignored = name and addon.Bars.IsButtonIgnored and addon.Bars:IsButtonIgnored(name)
		self.ignore:SetLabel(ignored and L["Draw on This Button"] or L["Leave This Button Alone"])
		self.ignore:SetDisabled(described == nil)
		self:Measure(self.width)
		self:Restyle()
	end

	function control:Restyle()
		self.round:SetFill(Kit.BackdropColor)
		self.round:SetEdge(Kit.BorderIdle)
		self.title:SetTextColor(unpack(Kit.TextHighlight))
		self.subtitle:SetTextColor(unpack(Kit.TextNormal))
		for _, line in ipairs(self.lines) do
			line.label:SetTextColor(unpack(Kit.TextSelected))
			line.text:SetTextColor(unpack(Kit.TextNormal))
		end
		self.pick:Restyle()
		self.copy:Restyle()
		self.ignore:Restyle()
	end

	return control
end

function Inspector:GetControl(parent)
	return control or Build(parent)
end

function Inspector:Restyle()
	if control then control:Restyle() end
end

-- Shows `button` in the card, as a pick would.
function Inspector:Inspect(button)
	self.button = button
	if control then control:Update() end
end
