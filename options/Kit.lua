--[[

	The MIT License (MIT)

	Copyright (c) 2026 Jonas "JuNNeZ" Andersen

--]]
-- The shared art layer for the custom options panel.
--
-- Everything here is measurement and texture setup. No frames are created and
-- no libraries are touched, so this file is safe to load before AceGUI exists.
--
-- The measurements below describe the sculpted art the kit was first drawn with
-- in AzeriteUI JuNNeZ Edition. AHOS replaces that art with its own keycap shapes
-- in Look.lua, which re-points every one of these at media/panel.
local Addon, ns = ...

local L = ns.L

-- Lua API
local floor = math.floor
local ipairs = ipairs
local max, min = math.max, math.min
local pairs = pairs
local pcall = pcall
local table_sort = table.sort
local type = type
local unpack = unpack

-- GLOBALS: CreateFrame, UnitClass

local API = ns.API
local GetFont = API.GetFont
local GetMedia = API.GetMedia
local Colors = ns.Colors

local Kit = {}
ns.OptionsKit = Kit

-- Widget type names are namespaced with the full addon name. AceGUI's widget
-- registry and its object pools are global and shared with every other Ace3
-- addon, so a generic name here would hand our widgets to somebody else's
-- window, and theirs to ours.
Kit.Prefix = Addon .. "-"

--------------------------------------------------------------------------
-- Glyphs
--------------------------------------------------------------------------
-- options-glyphs.tga is a 256x128 sheet of 4x2 cells, 64px each.
local glyphCells = {
	check   = { 0, 0 },
	dash    = { 1, 0 }, -- tristate
	chevron = { 2, 0 },
	search  = { 3, 0 },
	revert  = { 0, 1 },
	cross   = { 1, 1 },
	gem     = { 2, 1 }, -- changed marker
	grip    = { 3, 1 }
}

-- Returns the four texcoords for a named glyph cell.
Kit.GetGlyphCoords = function(name)
	local cell = glyphCells[name]
	if (not cell) then return 0, 1, 0, 1 end
	local col, row = cell[1], cell[2]
	return col / 4, (col + 1) / 4, row / 2, (row + 1) / 2
end

-- Points an existing texture at a named glyph cell.
Kit.SetGlyph = function(texture, name)
	texture:SetTexture(GetMedia("options-glyphs"))
	texture:SetTexCoord(Kit.GetGlyphCoords(name))
end

--------------------------------------------------------------------------
-- Opaque bodies
--------------------------------------------------------------------------
-- Several of the sculpted textures carry a soft drop shadow, so the opaque
-- body is a good deal smaller than the file. Sizing a texture by its file
-- dimensions makes it read as a sliver floating in empty space.
--
-- Measured off the shipping TGAs at alpha >= 128:
--   point_block    56x56 of 128x128
--   point_diamond  58x71 of 128x128
--   point_plate    60x61 of 128x128
--   options-close  60x61 of 128x128 (derived from point_plate)
local bodyRatio = {
	point_block = 56 / 128,
	point_diamond = 58 / 128,
	point_plate = 60 / 128,
	options_close = 60 / 128,
	icon_combat = 60 / 128
}

-- Returns the size to draw a texture at so its opaque body measures `body`.
Kit.DrawSize = function(body, which)
	local ratio = bodyRatio[which] or 1
	return body / ratio
end

-- Sizes a texture so that its opaque body measures `body` pixels square.
Kit.SizeToBody = function(texture, body, which)
	local size = Kit.DrawSize(body, which)
	texture:SetSize(size, size)
end

--------------------------------------------------------------------------
-- Bar crops
--------------------------------------------------------------------------
-- cast_back is 256x128 with an opaque body of 184x48 at +33+39. Sliders crop
-- to that body and three-slice it, so the sculpted ends keep their shape at
-- any width while the middle stretches.
Kit.TrackLeft, Kit.TrackRight = 33 / 256, 217 / 256
Kit.TrackTop, Kit.TrackBottom = 39 / 128, 87 / 128

-- Each end cap is 22 source pixels of the 184-wide body, which is the slice
-- the roadmap artifact settled on. Everything between them stretches, so the
-- chamfered ends hold their shape at any slider width.
Kit.TrackCap = 22
Kit.TrackBodyW, Kit.TrackBodyH = 184, 48
Kit.TrackCapU = 22 / 256

-- Texcoords for the three slices, left to right.
Kit.TrackSliceL = { 33 / 256, 55 / 256, 39 / 128, 87 / 128 }
Kit.TrackSliceM = { 55 / 256, 195 / 256, 39 / 128, 87 / 128 }
Kit.TrackSliceR = { 195 / 256, 217 / 256, 39 / 128, 87 / 128 }

Kit.Trough = {
	media = "cast_back",
	capSource = 22, bodyHeight = 48,
	left = { 33 / 256, 55 / 256, 39 / 128, 87 / 128 },
	mid = { 55 / 256, 195 / 256, 39 / 128, 87 / 128 },
	right = { 195 / 256, 217 / 256, 39 / 128, 87 / 128 }
}

-- cast_bar, measured: 256x32, a 13px chamfer at each end and a middle that
-- is uniform in height but carries a gentle lengthwise sheen, luminance 141
-- rising to 162 and back. Stretching the whole texture into the filled width
-- is what made the fill look wrong in game: the chamfers grew into long
-- wedges at high values and shrank to nothing at low ones.
--
-- So the fill is three-sliced as well. The caps are 16 source pixels, which
-- covers the 13px chamfer with a little margin, and the middle is taken from
-- x=120..136 where the sheen is near constant, so stretching it smears
-- nothing. The chamfers are then the same size at every value.
-- How a fill sits inside its trough, taken from the roadmap artifact's own
-- rules: `top: 24%; bottom: 32%` of the track, at 0.85 opacity, starting a
-- pixel outside the left edge so it tucks under the trough's chamfer rather
-- than floating as a separate shape at low values.
--
-- The fill is a slim bar in a deeper groove, not a slab filling it. Drawing it
-- at half the track height or more is what made the toggles read as solid gold
-- blocks rather than switches.
Kit.FillTopRatio = 0.24
Kit.FillRatio = 0.44
Kit.FillAlpha = 0.85
Kit.FillOvershoot = 1

-- The width of one of the trough's chamfered end caps, on screen. The fill
-- lives between the two of them.
Kit.TroughCapWidth = function(trackHeight)
	return Kit.Trough.capSource * trackHeight / Kit.Trough.bodyHeight
end

-- How far in from each end of a trough the fill starts: inside the caps,
-- lapping a pixel over them so the two chamfers meet instead of one sitting
-- on top of the other.
Kit.FillInset = function(trackHeight)
	return Kit.TroughCapWidth(trackHeight) - Kit.FillOvershoot
end

-- Returns the fill's height, and the insets from the track's top and bottom.
Kit.FillMetrics = function(trackHeight)
	local height = floor(trackHeight * Kit.FillRatio + 0.5)
	local top = floor(trackHeight * Kit.FillTopRatio + 0.5)
	return height, top, trackHeight - height - top
end

Kit.Fill = {
	media = "cast_bar",
	capSource = 16, bodyHeight = 32,
	left = { 0, 16 / 256, 0, 1 },
	mid = { 120 / 256, 136 / 256, 0, 1 },
	right = { 240 / 256, 1, 0, 1 }
}

--------------------------------------------------------------------------
-- Backdrops
--------------------------------------------------------------------------
-- The window follows the game menu's own backdrop so the two read as one
-- interface. See Components/Misc/GameMenu.lua.
Kit.WindowBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = GetMedia("border-tooltip"),
	edgeSize = 24,
	insets = { left = 7, right = 7, top = 7, bottom = 7 }
}

-- The options window's fill and casing, drawn the way AzeriteUI draws its own
-- window: the fill on the window, the sculpted casing as a frame of its own that
-- hangs outside it and sits above everything the window holds. The numbers are
-- AzeriteUI's (Options/Kit/Kit.lua), measured off border-tooltip.tga.
Kit.WindowOutset = { left = 10, right = 10, top = 18, bottom = 18 }
Kit.WindowOverhang = 2

Kit.WindowFill = {
	bgFile = GetMedia("plain"),
	insets = {
		left = -Kit.WindowOverhang, right = -Kit.WindowOverhang,
		top = -Kit.WindowOverhang, bottom = -Kit.WindowOverhang
	}
}

Kit.WindowCasing = {
	edgeFile = GetMedia("border-tooltip"),
	edgeSize = 32
}

-- Untinted, as AzeriteUI draws it; a tint turns the bronze muddy.
Kit.WindowCasingColor = { 1, 1, 1, 1 }

-- The addon's own tooltip border, drawn small enough to sit on a button. At
-- the game menu's edgeSize of 16 with 5px insets the corners take up the whole
-- height of a 26px button and clip its label; the same art at 12 with 4px
-- insets reads correctly at that size.
Kit.ButtonBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = GetMedia("border-tooltip"),
	edgeSize = 12,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Text inputs, the search box and dropdown boxes use the lighter aura border.
Kit.InsetBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = GetMedia("border-aura"),
	edgeSize = 10,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Live previews should read as a light cast over the affected object, not as
-- another tooltip window. The glow art is white and takes its gold from the
-- fixed colour below; unlike BorderFocus, it deliberately does not follow the
-- selected panel theme or the player's class.
Kit.PreviewGlowBackdrop = {
	edgeFile = GetMedia("border-glow"),
	edgeSize = 18
}

Kit.PreviewGlowLabelBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = GetMedia("border-glow"),
	edgeSize = 12,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

Kit.PreviewGold = {
	Colors.normal[1], Colors.normal[2], Colors.normal[3], 1
}

--------------------------------------------------------------------------
-- Themes
--------------------------------------------------------------------------
-- Every colour the kit draws with lives in one of the tables below, and those
-- tables are *mutated in place* when the theme changes rather than replaced.
-- That matters: textures and fontstrings capture the table by reference when a
-- widget is built, and a widget taken from AceGUI's pool is not rebuilt. Keeping
-- the identity stable means a theme change reaches everything that ever read it,
-- once each widget re-applies on acquire.
Kit.BorderIdle = {}
Kit.BorderHover = {}
Kit.BorderFocus = {}
Kit.BackdropColor = {}
Kit.WindowColor = {}
Kit.InsetColor = {}
Kit.TrackColor = {}

Kit.TextNormal = {}
Kit.TextHighlight = {}
Kit.TextSelected = {}
Kit.TextDisabled = {}

-- AHOS's own palettes. All of them draw on the same keycap art (Look.lua); only
-- the colours change, so switching never needs a reload.
local themes = {
	-- The default: slate keycaps, AHOS teal for what is on or selected.
	ahos = {
		order = 1,
		accent = { 0, .83, .67 },
		text = { .89, .91, .93 },
		bright = { 1, 1, 1 },
		muted = { .55, .58, .64 },
		border = { .18, .21, .26, 1 },
		window = { .059, .071, .086, .98 },
		backdrop = { .102, .118, .145, 1 },
		inset = { .043, .051, .063, 1 },
		track = { .18, .21, .26, 1 }
	},
	-- The logo's gold on the same slate.
	gold = {
		order = 2,
		inherit = "ahos",
		accent = { 1, .84, 0 }
	},
	-- Same shell, accent in the player's class colour.
	class = {
		order = 3,
		inherit = "ahos",
		classAccent = true
	},
	-- Light keycaps. The art is tinted, not painted, so it lights up cleanly.
	light = {
		order = 4,
		accent = { 0, .52, .42 },
		text = { .13, .15, .18 },
		bright = { 0, 0, 0 },
		muted = { .38, .41, .46 },
		border = { .70, .73, .78, 1 },
		window = { .90, .91, .93, .98 },
		backdrop = { .97, .97, .98, 1 },
		inset = { .84, .86, .89, 1 },
		track = { .74, .77, .81, 1 }
	}
}

local themeLabels = {
	ahos = L["Keycap"],
	gold = L["Keycap Gold"],
	class = L["Class Color"],
	light = L["Light"]
}

-- Other files may add themes of their own.
Kit.AddTheme = function(key, theme, label)
	themes[key] = theme
	themeLabels[key] = label or key
end

local currentTheme = "ahos"

-- How solid the panel is drawn.
--
-- A theme stays in charge of how solid its surfaces are *relative to each
-- other* - the window behind, the raised backdrops on it, the sunken insets in
-- those - so the slider scales them together rather than setting each one.
--
-- But it is normalised against the most solid of them, so that 100% means
-- **opaque**: the window's own fill reaches alpha 1 and nothing of the world
-- shows through it. A slider that stops at the theme's 0.95 and still lets the
-- ground show is not a slider anyone reads as 100%.
--
-- Only the fills are scaled. Borders keep their own alpha, because a
-- half-transparent border stops reading as an edge and the whole window
-- loses its shape.
local opacity = 1

Kit.MinOpacity = 0.2

local CopyInto = function(target, source, alpha)
	target[1], target[2], target[3] = source[1], source[2], source[3]
	target[4] = alpha or source[4]
end

local GetClassAccent = function()
	local _, classFile = UnitClass("player")
	local color = classFile and Colors.class and Colors.class[classFile]
	if (color) then
		return { color[1], color[2], color[3] }
	end
	return themes.ahos.accent
end

-- Applies a theme by name. Unknown names fall back to ahos rather than
-- leaving the kit half-coloured.
Kit.SetTheme = function(key)
	local theme = themes[key]
	if (not theme) then
		key, theme = "ahos", themes.ahos
	end
	currentTheme = key

	local base = theme.inherit and themes[theme.inherit] or theme
	local accent = theme.classAccent and GetClassAccent() or (theme.accent or base.accent)

	CopyInto(Kit.TextSelected, accent)
	CopyInto(Kit.TextNormal, theme.text or base.text)
	CopyInto(Kit.TextHighlight, theme.bright or base.bright)
	CopyInto(Kit.TextDisabled, theme.muted or base.muted)

	CopyInto(Kit.BorderIdle, theme.border or base.border)
	CopyInto(Kit.BorderHover, theme.bright or base.bright, 1)
	CopyInto(Kit.BorderFocus, accent, 1)

	CopyInto(Kit.WindowColor, theme.window or base.window)
	CopyInto(Kit.BackdropColor, theme.backdrop or base.backdrop)
	CopyInto(Kit.InsetColor, theme.inset or base.inset)
	CopyInto(Kit.TrackColor, theme.track or base.track)

	-- Fills only, normalised against the most solid of them. See the note on
	-- `opacity` above.
	local fills = { Kit.WindowColor, Kit.BackdropColor, Kit.InsetColor }

	local top = 0
	for _, fill in ipairs(fills) do
		top = max(top, fill[4] or 1)
	end

	if (top > 0) then
		for _, fill in ipairs(fills) do
			fill[4] = (fill[4] or 1) / top * opacity
		end
	end
end

Kit.GetTheme = function()
	return currentTheme
end

-- Re-applies the current theme, which is what turns the new multiplier into
-- colours. Clamped, because a panel you cannot see is not a setting anyone
-- wants to be one click away from.
Kit.SetOpacity = function(value)
	if (type(value) ~= "number") then return end

	opacity = min(1, max(Kit.MinOpacity, value))
	Kit.SetTheme(currentTheme)
end

Kit.GetOpacity = function()
	return opacity
end

-- Ordered list for the options dropdown, as { key = label }, plus the order.
Kit.GetThemeChoices = function()
	local values, order = {}, {}
	local sorted = {}
	for key, theme in pairs(themes) do
		sorted[#sorted + 1] = { key = key, order = theme.order or 99 }
	end
	table_sort(sorted, function(a, b) return a.order < b.order end)

	for _, entry in ipairs(sorted) do
		values[entry.key] = themeLabels[entry.key] or entry.key
		order[#order + 1] = entry.key
	end
	return values, order
end

Kit.SetTheme(currentTheme)

--------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------
-- Creates a backdrop frame behind a widget. Widgets that are Buttons or
-- EditBoxes cannot carry a backdrop of their own on every client, and giving
-- them a sibling keeps the border independent of the widget's own states.
Kit.CreateBackdrop = function(parent, backdrop, inset)
	inset = inset or 0

	local frame = CreateFrame("Frame", nil, parent, ns.BackdropTemplate)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", -inset, inset)
	frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", inset, -inset)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(unpack(Kit.BackdropColor))
	frame:SetBackdropBorderColor(unpack(Kit.BorderIdle))

	local level = parent:GetFrameLevel()
	frame:SetFrameLevel(level > 0 and level - 1 or 0)

	return frame
end

-- Builds a horizontal bar out of three textures: fixed end caps and a middle
-- that stretches between them. Anything with a shaped end has to be built
-- this way, because a single stretched texture distorts those ends in
-- proportion to its width.
--
-- `anchor` is what the three pieces pin themselves to. For a trough that is
-- the frame itself; for a fill it is the status bar texture the engine
-- resizes, which keeps the caps travelling with the fill edge without any
-- arithmetic of ours.
Kit.CreateSliceBar = function(parent, layer, spec, height, anchor, sublevel)
	anchor = anchor or parent

	local capWidth = spec.capSource * height / spec.bodyHeight
	local media = GetMedia(spec.media)

	local left = parent:CreateTexture(nil, layer, nil, sublevel)
	left:SetTexture(media)
	left:SetTexCoord(unpack(spec.left))
	left:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0)
	left:SetWidth(capWidth)

	local right = parent:CreateTexture(nil, layer, nil, sublevel)
	right:SetTexture(media)
	right:SetTexCoord(unpack(spec.right))
	right:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(capWidth)

	-- Anchored between the caps rather than given a width, so when the bar is
	-- narrower than both caps the anchors simply cross and nothing is drawn,
	-- instead of erroring on a negative width.
	local mid = parent:CreateTexture(nil, layer, nil, sublevel)
	mid:SetTexture(media)
	mid:SetTexCoord(unpack(spec.mid))
	mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
	mid:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)

	local bar = { left = left, mid = mid, right = right, capWidth = capWidth }

	bar.SetVertexColor = function(self, r, g, b, a)
		self.left:SetVertexColor(r, g, b, a)
		self.mid:SetVertexColor(r, g, b, a)
		self.right:SetVertexColor(r, g, b, a)
	end

	bar.SetColor = function(self, color)
		self:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
	end

	bar.SetShown = function(self, shown)
		self.left:SetShown(shown)
		self.mid:SetShown(shown)
		self.right:SetShown(shown)
	end

	return bar
end

Kit.SetBorderColor = function(frame, color)
	if (frame and frame.SetBackdropBorderColor) then
		frame:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
	end
end

--------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------
-- FontStyles.xml defines plain, un-outlined faces at sizes 11 and 12 only.
-- Everything from 13 upwards exists in the outlined set alone.
--
-- This matters because Assets.lua's font cache answers *any* size with a bare
-- CreateFont() object when the named global is missing (Core/API/Assets.lua:42-58).
-- That object has no font file, and setting text on it throws
-- "FontString:SetText(): Font not set" rather than failing quietly. So every
-- request the kit makes is checked, and stepped down to a face that exists.
local FontExists = function(font)
	if (not font or not font.GetFont) then return false end

	local ok, file = pcall(font.GetFont, font)
	return (ok and file) and true or false
end

Kit.GetFont = function(size, outline, type)
	local font = GetFont(size, outline, type)
	if (FontExists(font)) then return font end

	-- The set is outline-heavy, so the outlined twin is the nearest match.
	if (not outline) then
		font = GetFont(size, true, type)
		if (FontExists(font)) then return font end
	end

	-- Then the sizes known to be defined in both styles.
	for _, fallback in ipairs({ 12, 11 }) do
		font = GetFont(fallback, outline, type)
		if (FontExists(font)) then return font end

		font = GetFont(fallback, true, type)
		if (FontExists(font)) then return font end
	end

	return _G.GameFontNormal
end

Kit.GetMedia = GetMedia

--------------------------------------------------------------------------
-- Asking before something irreversible
--------------------------------------------------------------------------
-- An option table can say `confirm`, as Flicker, deleting a rule or a profile and
-- an import do. Blizzard's own popup asks, as in AzeriteUI's panel; nothing is
-- changed if the popup cannot be shown.
local CONFIRM_KEY = "AHOS_OPTIONS_CONFIRM"

Kit.Confirm = function(question, onAccept, onCancel)
	if (type(onAccept) ~= "function") then return false end

	if (not StaticPopupDialogs or not StaticPopup_Show) then
		onAccept()
		return true
	end

	StaticPopupDialogs[CONFIRM_KEY] = {
		text = "%s",
		button1 = _G.ACCEPT or "Accept",
		button2 = _G.CANCEL or "Cancel",
		OnAccept = function() onAccept() end,
		OnCancel = function() if (onCancel) then onCancel() end end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}

	local shown = StaticPopup_Show(CONFIRM_KEY, tostring(question or ""))
	if (not shown) then
		if (onCancel) then onCancel() end
		return false
	end
	return true
end
