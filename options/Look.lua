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
Look.Media = Media
local max, unpack = math.max, unpack

-- Colours that are not part of a theme: the lip under a keycap is always a darker
-- copy of its face, and the window edge is a cool steel.
Look.Steel = { .24, .28, .34, 1 }
Look.LipShade = .55

---------------------------------------------------------------------
-- Fonts
---------------------------------------------------------------------
-- The game's own face, as a font family: the client's Latin face, and the faces
-- the game ships for Cyrillic, Korean and Chinese on every client, so a Russian key
-- name or a Hangul legend renders on an English client too (the window's text was
-- one font file, which on an English client has none of those letters).
local SCRIPT_FONTS = {
	{ "russian", "Fonts\\FRIZQT___CYR.TTF" },
	{ "korean", "Fonts\\2002.TTF" },
	{ "simplifiedchinese", "Fonts\\ARKai_T.ttf" },
	{ "traditionalchinese", "Fonts\\blei00d.TTF" },
}
Look.ScriptFonts = SCRIPT_FONTS

local fonts = {}
function Look.Font(size, kind)
	kind = kind or "body"
	local key = kind .. size
	if fonts[key] then return fonts[key] end
	local file = GameFontNormal:GetFont()
	local font
	if CreateFontFamily then
		local members = { { alphabet = "roman", file = file, height = size, flags = "" } }
		for _, script in ipairs(SCRIPT_FONTS) do
			members[#members + 1] = { alphabet = script[1], file = script[2], height = size, flags = "" }
		end
		local ok, family = pcall(CreateFontFamily, "AHOSLookFont" .. key, members)
		if ok and family then font = family end
	end
	if not font then
		font = CreateFont("AHOSLookFont" .. key)
		font:SetFont(file, size, "")
	end
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

	return Look.Surface(fill, face, edge)
end

-- A shape drawn at its frame's own size and aspect (the mouse, its buttons, the
-- controller): -fill, -face and -edge files as for Look.Round, not sliced.
function Look.Shape(frame, name, keycap, layer)
	layer = layer or "BACKGROUND"
	local fill = frame:CreateTexture(nil, layer, nil, -6)
	fill:SetTexture(Media(name .. "-fill"))
	fill:SetAllPoints()
	local face
	if keycap then
		face = frame:CreateTexture(nil, layer, nil, -5)
		face:SetTexture(Media(name .. "-face"))
		face:SetAllPoints()
	end
	local edge = frame:CreateTexture(nil, layer, nil, -4)
	edge:SetTexture(Media(name .. "-edge"))
	edge:SetAllPoints()
	return Look.Surface(fill, face, edge)
end

-- What Look.Round and Look.Shape hand back: SetFill, SetEdge and SetShown over a
-- fill, an optional keycap face and an edge.
function Look.Surface(fill, face, edge)
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

-- The Backlit theme's light under a key: a soft glow spilling out from under
-- `frame`'s bottom edge. Hidden until shown; tinted by the caller.
function Look.Underglow(frame)
	local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	Sliced(glow, Media("underglow"), 24)
	glow:SetPoint("TOPLEFT", frame, "TOPLEFT", -12, -4)
	glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 12, -16)
	glow:SetBlendMode("ADD")
	glow:Hide()
	return glow
end

-- Shows `glow` in the accent when the theme is backlit and `on`; kept faint, since
-- it draws over the game world.
function Look.SetGlow(glow, on)
	if not glow then return end
	if on and Kit.Backlit then
		local accent = Kit.TextSelected
		glow:SetVertexColor(accent[1], accent[2], accent[3], .22)
		glow:Show()
	else
		glow:Hide()
	end
end

---------------------------------------------------------------------
-- Whole pixels
---------------------------------------------------------------------
-- The UI scale (often 0.64-0.75) and the window's own scale put a 20-unit control
-- on 12.8 physical pixels, so an edge drawn at a size in UI units lands between
-- pixels and smears. Small controls (switches, slider knobs) are sized here in
-- whole physical pixels instead.

-- One physical screen pixel, in `frame`'s units.
function Look.PixelSize(frame)
	local height = GetPhysicalScreenSize and select(2, GetPhysicalScreenSize())
	local scale = frame and frame.GetEffectiveScale and frame:GetEffectiveScale()
	if not (height and height > 0 and scale and scale > 0) then return 1 end
	return 768 / height / scale
end

-- `units` rounded to whole physical pixels (at least one); `even` keeps the
-- count even, so a circle or pill has a centre on a pixel boundary.
function Look.Snap(frame, units, even)
	local px = Look.PixelSize(frame)
	local count = units / px
	if even then
		count = max(2, math.floor(count / 2 + .5) * 2)
	else
		count = max(1, math.floor(count + .5))
	end
	return count * px, px
end

-- A texture that stays clean drawn far below its file's size: mipmapped
-- (TRILINEAR) where the client takes a filter mode.
function Look.SmoothTexture(texture, file)
	if not pcall(texture.SetTexture, texture, file, "CLAMP", "CLAMP", "TRILINEAR") then
		texture:SetTexture(file)
	end
end

local PLAIN = "Interface\\Buttons\\WHITE8X8"

-- One row of a pill: round caps cut from the circle art, a flat middle.
local function PillLayer(parent, layer, sublevel)
	local left = parent:CreateTexture(nil, layer, nil, sublevel)
	Look.SmoothTexture(left, Media("circle-fill"))
	left:SetTexCoord(0, .5, 0, 1)
	local right = parent:CreateTexture(nil, layer, nil, sublevel)
	Look.SmoothTexture(right, Media("circle-fill"))
	right:SetTexCoord(.5, 1, 0, 1)
	local mid = parent:CreateTexture(nil, layer, nil, sublevel)
	mid:SetTexture(PLAIN)
	return { left, mid, right }
end

local function PlacePill(parts, anchor, height, inset)
	local left, mid, right = parts[1], parts[2], parts[3]
	local cap = height / 2
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset, -inset)
	left:SetSize(cap, height)
	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -inset, -inset)
	right:SetSize(cap, height)
	-- between the caps, by anchors: a pill narrower than its two caps draws no middle
	mid:ClearAllPoints()
	mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
	mid:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)
end

-- Colour only: whether a pill shows is SetShown's (a slider at its minimum hides
-- its fill, and a restyle must not bring it back).
local function ColorParts(parts, c, a)
	for _, t in ipairs(parts) do
		t:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
	end
end

-- A pill on `frame` (filling it) with a one-pixel edge: an outer pill in the edge
-- colour and an inner one, a pixel in, in the fill colour. Flat colours only; a
-- gradient across a few pixels only reads as blur.
--   pill:Layout(height, px)   height and pixel size in `frame`'s units
--   pill:SetColors(fill, edge) edge nil: the fill reaches the outside edge
function Look.Pill(frame, layer, sublevel)
	layer = layer or "ARTWORK"
	local pill = { frame = frame, outer = PillLayer(frame, layer, sublevel or 0), inner = PillLayer(frame, layer, (sublevel or 0) + 1) }
	function pill:Layout(height, px)
		self.height, self.px = height, px
		PlacePill(self.outer, self.frame, height, 0)
		PlacePill(self.inner, self.frame, max(px, height - 2 * px), px)
	end
	function pill:SetColors(fill, edge, alpha)
		ColorParts(self.outer, edge or fill, alpha)
		ColorParts(self.inner, fill, alpha)
	end
	function pill:SetShown(shown)
		for _, t in ipairs(self.outer) do t:SetShown(shown) end
		for _, t in ipairs(self.inner) do t:SetShown(shown) end
	end
	return pill
end

-- A round knob with a hard one-pixel lip under it in place of a blurred shadow.
--   knob:Layout(size, px)  knob:SetColor(c)  knob:SetLip(shown)
--   knob.texture is what gets anchored
function Look.Knob(frame, layer)
	layer = layer or "OVERLAY"
	local knob = {}
	local lip = frame:CreateTexture(nil, layer, nil, 1)
	Look.SmoothTexture(lip, Media("circle-fill"))
	lip:SetVertexColor(0, 0, 0, .35)
	local face = frame:CreateTexture(nil, layer, nil, 2)
	Look.SmoothTexture(face, Media("circle-fill"))
	lip:SetPoint("TOP", face, "TOP", 0, -1)
	knob.texture, knob.lip = face, lip
	function knob:Layout(size, px)
		self.size = size
		face:SetSize(size, size)
		lip:SetSize(size, size)
		lip:ClearAllPoints()
		lip:SetPoint("TOP", face, "TOP", 0, -px)
	end
	function knob:SetColor(c, a) face:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1) end
	function knob:SetLip(shown) lip:SetShown(shown and true or false) end
	return knob
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
	bars = "page-bars",
	inspector = "page-inspector",
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
