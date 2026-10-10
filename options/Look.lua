---@diagnostic disable: undefined-global
-- options/Look.lua - the AHOS look.
--
-- The window is drawn like a keyboard. Raised things (buttons, the selected page,
-- cards) are keycaps: a face with a darker lip under it, as the AHOS logo is drawn.
-- Sunken things (text boxes, the search box, slider tracks) are flat insets. The
-- shapes are AHOS's own, white on transparent in media/panel, made by
-- Tools/MakePanelArt.py and tinted here from the kit's theme tables, so every theme
-- uses the same art. Rounded shapes are sliced with SetTextureSliceMargins, so their
-- corners keep their shape at any size.
local _, ns = ...
local Kit = ns.OptionsKit
if not Kit then return end

local Look = {}
Kit.Look = Look

local Media = ns.PanelMedia
local max, unpack = math.max, unpack

-- Colours that are not part of a theme: the lip under a keycap is always a darker
-- copy of its face, and the window edge is a cool steel.
Look.Steel = { .24, .28, .34, 1 }
Look.LipShade = .55

---------------------------------------------------------------------
-- Fonts
---------------------------------------------------------------------
-- The game's own face, so every locale (Cyrillic, Korean, Chinese) renders.
local fonts = {}
function Look.Font(size, kind)
	kind = kind or "body"
	local key = kind .. size
	if fonts[key] then return fonts[key] end
	local font = CreateFont("AHOSLookFont" .. key)
	local file = GameFontNormal:GetFont()
	font:SetFont(file, size, "")
	font:SetShadowOffset(0, -1)
	font:SetShadowColor(0, 0, 0, kind == "display" and .9 or .6)
	fonts[key] = font
	return font
end

---------------------------------------------------------------------
-- Surfaces
---------------------------------------------------------------------
local RADII = { 3, 4, 6, 8, 10 }
local function Radius(r)
	local best = RADII[1]
	for _, candidate in ipairs(RADII) do if candidate <= r then best = candidate end end
	return best
end

local function Sliced(texture, file, margin)
	texture:SetTexture(file)
	if texture.SetTextureSliceMargins then
		texture:SetTextureSliceMargins(margin, margin, margin, margin)
		if texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
			texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
		end
	end
end
Look.Sliced = Sliced

local function Shade(c, amount, a)
	return { c[1] * amount, c[2] * amount, c[3] * amount, a or c[4] or 1 }
end

-- A rounded fill and edge on `frame`. With `keycap`, the fill is drawn as a lip and
-- a face lifted off it, so it reads as a key. Returns SetFill, SetEdge, SetShown;
-- either colour can be nil to hide that part.
function Look.Round(frame, radius, thick, layer, keycap)
	local r = Radius(radius or 6)
	local margin = r + 2
	layer = layer or "BACKGROUND"

	local fill = frame:CreateTexture(nil, layer, nil, -6)
	Sliced(fill, Media("round" .. r .. "-fill"), margin)
	fill:SetAllPoints()

	local face
	if keycap then
		face = frame:CreateTexture(nil, layer, nil, -5)
		Sliced(face, Media("round" .. r .. "-face"), margin)
		face:SetAllPoints()
	end

	local edge = frame:CreateTexture(nil, layer, nil, -4)
	Sliced(edge, Media("round" .. r .. (thick and "-edge2" or "-edge")), margin)
	edge:SetAllPoints()

	local round = { fill = fill, face = face, edge = edge }
	function round:SetFill(c, a)
		if not c then
			self.fill:Hide()
			if self.face then self.face:Hide() end
			return
		end
		local alpha = a or c[4] or 1
		if self.face then
			local lip = Shade(c, Look.LipShade, alpha)
			self.fill:SetVertexColor(lip[1], lip[2], lip[3], lip[4])
			self.face:SetVertexColor(c[1], c[2], c[3], alpha)
			self.face:Show()
		else
			self.fill:SetVertexColor(c[1], c[2], c[3], alpha)
		end
		self.fill:Show()
	end
	function round:SetEdge(c, a)
		if not c then self.edge:Hide(); return end
		self.edge:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
		self.edge:Show()
	end
	function round:SetShown(shown)
		self.fill:SetShown(shown)
		if self.face then self.face:SetShown(shown) end
		self.edge:SetShown(shown)
	end
	return round
end

-- A soft shadow around `frame`, on a frame of its own just below it.
function Look.Shadow(frame, spread)
	spread = spread or 18
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", -spread, spread)
	holder:SetPoint("BOTTOMRIGHT", spread, -spread)
	holder:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
	local shadow = holder:CreateTexture(nil, "BACKGROUND", nil, -8)
	Sliced(shadow, Media("shadow"), 40)
	shadow:SetAllPoints()
	shadow:SetVertexColor(0, 0, 0, .85)
	return shadow
end

function Look.Glyph(texture, name)
	texture:SetTexture(Media("glyph-" .. name))
	texture:SetTexCoord(0, 1, 0, 1)
end

-- The page icons drawn for the rail, by option-table key.
Look.PageIcons = {
	status = "page-overview",
	display = "page-display",
	text = "page-keybinds",
	abbreviations = "page-abbreviations",
	profiles = "page-profiles",
	integration = "page-compatibility",
	debug = "page-debug",
	about = "page-about",
	window = "page-window",
}

-- A frame that answers SetBackdropColor and SetBackdropBorderColor like a backdrop
-- does, drawn with our surfaces. Kit.CreateBackdrop hands these out.
local function RoundBackdrop(parent, radius, inset, keycap)
	inset = inset or 0
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", -inset, inset)
	frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", inset, -inset)
	local level = parent:GetFrameLevel()
	frame:SetFrameLevel(level > 0 and level - 1 or 0)
	local round = Look.Round(frame, radius, nil, nil, keycap)
	frame.round = round
	frame.SetBackdrop = function() end
	frame.SetBackdropColor = function(_, r, g, b, a) round:SetFill({ r, g, b, a or 1 }) end
	frame.SetBackdropBorderColor = function(_, r, g, b, a) round:SetEdge({ r, g, b, a or 1 }) end
	return frame
end

---------------------------------------------------------------------
-- Pointing the kit at our art
---------------------------------------------------------------------
local GLYPHS = {
	check = "check", chevron = "chevron", cross = "cross", search = "search",
	revert = "undo", grip = "grip", dash = "plus", gem = "changed",
}

local applied = false
function Look.Apply()
	if applied then return end
	applied = true
	Kit.ArtStyle = "ahos"

	Kit.DrawSize = function(body, which)
		if which == "point_diamond" then return body * 0.62 end
		return body
	end
	Kit.SetGlyph = function(texture, name) Look.Glyph(texture, GLYPHS[name] or "check") end
	Kit.GetFont = function(size, outline) return Look.Font(size, outline and "bold" or "body") end

	-- Toggle and slider tracks are pills: a circle sliced down its middle keeps round
	-- ends at any width. Knobs are plain circles.
	ns.MediaOverride.point_diamond = Media("circle-fill")
	ns.MediaOverride.point_crystal = Media("circle-fill")
	ns.MediaOverride["bar-small"] = "Interface\\Buttons\\WHITE8X8"
	ns.MediaOverride.cast_back = Media("circle-fill")
	ns.MediaOverride.cast_bar = Media("circle-fill")
	for _, spec in ipairs({ Kit.Trough, Kit.Fill }) do
		spec.capSource, spec.bodyHeight = 32, 64
		spec.left, spec.mid, spec.right = { 0, .5, 0, 1 }, { .49, .51, 0, 1 }, { .5, 1, 0, 1 }
	end
	Kit.FillTopRatio, Kit.FillRatio, Kit.FillAlpha, Kit.FillOvershoot = 0.2, 0.6, 1, 0

	-- What still takes a plain backdrop (the dropdown list) gets a crisp 1px edge.
	-- The three are separate tables so CreateBackdrop can tell a button from an inset.
	local function Square()
		return { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1 } }
	end
	Kit.WindowBackdrop, Kit.ButtonBackdrop, Kit.InsetBackdrop = Square(), Square(), Square()
	Kit.CreateBackdrop = function(parent, backdrop, inset)
		local frame = RoundBackdrop(parent, 4, inset, backdrop == Kit.ButtonBackdrop)
		frame:SetBackdropColor(unpack(Kit.BackdropColor))
		frame:SetBackdropBorderColor(unpack(Kit.BorderIdle))
		return frame
	end
end
