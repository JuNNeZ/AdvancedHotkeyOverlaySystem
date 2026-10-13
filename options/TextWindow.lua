---@diagnostic disable: undefined-global
-- options/TextWindow.lua - a window of text to read and copy.
--
-- The debug log (/ahoslog), the profile and debug exports, and the inspector's
-- details all show text someone needs to copy into a bug report. They are drawn in
-- the options window's own keycap look: a rounded window, a sunken box of text that
-- scrolls, and a button that selects all of it, since the game only copies what is
-- selected. One window per kind, so the log can stay open beside an export.
local addonName, ns = ...
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
local Controls = Kit and Kit.Controls
if not (Look and Controls) then return end

local L = ns.L
local max, min, unpack = math.max, math.min, unpack

local TextWindow = {}
Kit.TextWindow = TextWindow

local W, H, PAD, HEAD_H, FOOT_H = 640, 420, 14, 40, 40
local windows = {}

local function Restyle(window)
	window.round:SetFill(Kit.WindowColor)
	window.round:SetEdge(Kit.EdgeColor)
	window.title:SetTextColor(unpack(Kit.TextHighlight))
	window.cross:SetVertexColor(unpack(Kit.TextDisabled))
	window.hint:SetTextColor(unpack(Kit.TextDisabled))
	window.box:SetBackdropColor(unpack(Kit.InsetColor))
	Kit.SetBorderColor(window.box, Kit.BorderIdle)
	window.edit:SetTextColor(unpack(Kit.TextNormal))
	window.selectAll:Restyle()
	window.close:Restyle()
end

local function Build(key)
	Look.Apply()
	local name = "AHOSTextWindow" .. key:gsub("%W", "")
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetSize(W, H)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:Hide()
	tinsert(UISpecialFrames, name) -- Escape closes it

	local window = { frame = frame }
	Look.Shadow(frame, 18)
	window.round = Look.Round(frame, 10, true)

	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", 8, -6)
	header:SetPoint("TOPRIGHT", -8, -6)
	header:SetHeight(HEAD_H - 6)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function() frame:StartMoving() end)
	header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

	local title = header:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(Look.Font(16, "display"))
	title:SetPoint("LEFT", 8, 0)
	title:SetJustifyH("LEFT")
	window.title = title

	local closeX = CreateFrame("Button", nil, header)
	closeX:SetSize(24, 24)
	closeX:SetPoint("RIGHT", -2, 0)
	local cross = closeX:CreateTexture(nil, "ARTWORK")
	cross:SetSize(18, 18)
	cross:SetPoint("CENTER")
	Look.Glyph(cross, "cross")
	window.cross = cross
	closeX:SetScript("OnClick", function() frame:Hide() end)
	closeX:SetScript("OnEnter", function() cross:SetVertexColor(1, 1, 1) end)
	closeX:SetScript("OnLeave", function() cross:SetVertexColor(unpack(Kit.TextDisabled)) end)

	-- The sunken box the text scrolls in
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", PAD, -HEAD_H)
	holder:SetPoint("BOTTOMRIGHT", -PAD, FOOT_H + 4)
	window.box = Kit.CreateBackdrop(holder, Kit.InsetBackdrop, 0)

	local scroll = CreateFrame("ScrollFrame", nil, holder)
	scroll:SetPoint("TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", -8, 8)
	scroll:SetClipsChildren(true)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFontObject(Kit.GetFont(12))
	edit:SetWidth(W - PAD * 2 - 16)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); frame:Hide() end)
	-- read-only: anything typed is put back
	edit:SetScript("OnTextChanged", function(self, userInput)
		if userInput and window.text then self:SetText(window.text) end
	end)
	-- the box grows with its text, and the scroll follows the caret
	edit:SetScript("OnCursorChanged", function(_, _, y, _, height)
		local top = -(y or 0)
		local view = scroll:GetHeight() or 0
		local at = scroll:GetVerticalScroll() or 0
		if top < at then scroll:SetVerticalScroll(top)
		elseif top + (height or 0) > at + view then scroll:SetVerticalScroll(max(0, top + (height or 0) - view)) end
	end)
	scroll:SetScrollChild(edit)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		self:SetVerticalScroll(min(range, max(0, (self:GetVerticalScroll() or 0) - delta * 40)))
	end)
	scroll:SetScript("OnSizeChanged", function(_, width) if width and width > 0 then edit:SetWidth(width) end end)
	-- a click anywhere in the box puts the caret in it
	holder:EnableMouse(true)
	holder:SetScript("OnMouseDown", function() edit:SetFocus() end)
	window.scroll, window.edit = scroll, edit

	window.selectAll = Controls.CreateBareButton(frame, L["Select All"], function()
		edit:SetFocus()
		edit:HighlightText()
	end)
	window.selectAll:SetPoint("BOTTOMLEFT", PAD, 10)
	window.close = Controls.CreateBareButton(frame, L["Close"], function() frame:Hide() end)
	window.close:SetPoint("BOTTOMRIGHT", -PAD, 10)

	local hint = frame:CreateFontString(nil, "OVERLAY")
	hint:SetFontObject(Kit.GetFont(11))
	hint:SetPoint("LEFT", window.selectAll, "RIGHT", 12, 0)
	hint:SetPoint("RIGHT", window.close, "LEFT", -12, 0)
	hint:SetJustifyH("LEFT")
	hint:SetText(L["Select All, then Ctrl+C to copy."])
	window.hint = hint

	frame:SetScript("OnShow", function() Restyle(window) end)
	windows[key] = window
	return window
end

-- Shows `text` under `title` in the window kept for `key`, scrolled to the top or,
-- with `toEnd`, to the end (a log reads from the bottom).
function TextWindow:Show(key, title, text, toEnd)
	local window = windows[key] or Build(key)
	window.title:SetText(title or "")
	self:SetText(key, text, toEnd)
	window.frame:Show()
	window.frame:Raise()
	return window
end

-- Replaces the text of a window, scrolled to the top or, with `toEnd`, the end.
function TextWindow:SetText(key, text, toEnd)
	local window = windows[key]
	if not window then return end
	window.text = text or ""
	window.edit:SetText(window.text)
	if toEnd then
		window.edit:SetCursorPosition(#window.text)
		window.scroll:SetVerticalScroll(window.scroll:GetVerticalScrollRange() or 0)
	else
		window.edit:SetCursorPosition(0)
		window.scroll:SetVerticalScroll(0)
	end
end

function TextWindow:IsShown(key)
	local window = windows[key]
	return window and window.frame:IsShown() or false
end

function TextWindow:Get(key)
	return windows[key]
end
