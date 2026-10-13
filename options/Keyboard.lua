---@diagnostic disable: undefined-global
-- options/Keyboard.lua - the abbreviations, on a keyboard, a mouse and a controller.
--
-- Drawn at the top of the Abbreviations page in place of a long list of text
-- boxes, one per key. Two tabs:
--
--   Keyboard & Mouse: a full-size keyboard (function row, navigation block with the
--   arrows, numpad) in the layout of your country, with its own legends, and a
--   mouse beside it. Nordic, German and French boards have the keys those
--   keyboards have (Æ Ø Å, Ö Ä Ü ß, the AZERTY number row).
--
--   Controller: a gamepad, its buttons named the way Xbox, PlayStation or Switch
--   names them, or with the game's own glyphs.
--
-- Keys bound to an action button light up and show the text AHOS draws for them;
-- Shift, Ctrl and Alt latch, so the board can show any layer of bindings.
--
-- The game cannot list the keys a keyboard or mouse has, only the ones that are
-- bound, so groups under the models hold the extra buttons a gaming mouse brings
-- (always 6-12, more when one is bound) and every bound key that is on no model.
-- "Find a Key" catches the next key or mouse button you press, so a key on none
-- can be picked too.
--
-- Clicking a key opens its card in a slice docked beside the window, so it stays
-- in view however small the window or large the UI scale.
local _, ns = ...
local addon = ns.addon
local Kit = ns.OptionsKit
local Look = Kit and Kit.Look
local Controls = Kit and Kit.Controls
if not (Look and Controls) then return end

local L = ns.L
local floor, max, min = math.floor, math.max, math.min
local ipairs, pairs, unpack = ipairs, pairs, unpack

local Keyboard = {}
Kit.Keyboard = Keyboard

local MODIFIERS = { SHIFT = true, CTRL = true, ALT = true }

---------------------------------------------------------------------------
-- Keyboard layouts
---------------------------------------------------------------------------
-- The game names a key by what it types on the layout Windows or macOS uses, so a
-- Danish board's key right of L is "Æ", and an AZERTY board's 1 is "&". Each
-- layout lists, row by row, what its keys report, and the names printed on them
-- where those differ from the English ones. `iso` boards have the tall Enter and
-- the extra key beside the left Shift.
local LAYOUTS = {
	us = { name = "English (US)", order = 1,
		r1 = { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]" }, r2end = "\\",
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'" },
		r4 = { "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/" } },
	uk = { name = "English (UK)", order = 2, iso = true,
		r1 = { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]" },
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "#" },
		r4 = { "\\", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/" } },
	da = { name = "Dansk", order = 3, numDecimal = ",", iso = true,
		r1 = { "½", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", "´" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "å", "¨" },
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", "æ", "ø", "'" },
		r4 = { "<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-" },
		legends = { SPACE = "Mellemrum", BACKSPACE = "Tilbage", SHIFT = "Skift", DELETE = "Slet", INSERT = "Indsæt", ALTGR = "Alt Gr" } },
	no = { name = "Norsk", order = 4, numDecimal = ",", iso = true,
		r1 = { "|", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", "\\" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "å", "¨" },
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", "ø", "æ", "'" },
		r4 = { "<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-" },
		legends = { SPACE = "Mellomrom", BACKSPACE = "Tilbake", SHIFT = "Skift", DELETE = "Slett", INSERT = "Sett inn", ALTGR = "Alt Gr" } },
	sv = { name = "Svenska / Suomi", order = 5, numDecimal = ",", iso = true,
		r1 = { "§", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", "´" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "å", "¨" },
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", "ö", "ä", "'" },
		r4 = { "<", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "-" },
		legends = { SPACE = "Mellanslag", SHIFT = "Skift", ALTGR = "Alt Gr" } },
	de = { name = "Deutsch", order = 6, numDecimal = ",", iso = true,
		r1 = { "^", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "ß", "´" },
		r2 = { "Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "ü", "+" },
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", "ö", "ä", "#" },
		r4 = { "<", "Y", "X", "C", "V", "B", "N", "M", ",", ".", "-" },
		legends = { CAPSLOCK = "Feststell", SHIFT = "Umschalt", CTRL = "Strg", BACKSPACE = "Rück", ENTER = "Enter",
			INSERT = "Einfg", DELETE = "Entf", HOME = "Pos1", END = "Ende", PAGEUP = "Bild auf", PAGEDOWN = "Bild ab",
			PRINTSCREEN = "Druck", SCROLLLOCK = "Rollen", SPACE = "Leertaste", ALTGR = "Alt Gr" } },
	fr = { name = "Français", order = 7, iso = true,
		r1 = { "²", "&", "é", "\"", "'", "(", "-", "è", "_", "ç", "à", ")", "=" },
		r2 = { "A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P", "^", "$" },
		r3 = { "Q", "S", "D", "F", "G", "H", "J", "K", "L", "M", "ù", "*" },
		r4 = { "<", "W", "X", "C", "V", "B", "N", ",", ";", ":", "!" },
		legends = { ESCAPE = "Échap", CAPSLOCK = "Verr Maj", SHIFT = "Maj", BACKSPACE = "Retour", ENTER = "Entrée",
			INSERT = "Inser", DELETE = "Suppr", HOME = "Début", END = "Fin", PAGEUP = "Pg Préc", PAGEDOWN = "Pg Suiv",
			PRINTSCREEN = "Impr", SCROLLLOCK = "Arrêt", SPACE = "Espace", NUMLOCK = "Verr Num", ALTGR = "Alt Gr" } },
	-- Cyrillic boards: the game names these keys by the Cyrillic letter they type,
	-- in lower case like the Nordic letters, and they are printed in capitals.
	ru = { name = "Русская", order = 8, numDecimal = ",",
		r1 = { "ё", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х", "ъ" }, r2end = "\\",
		r3 = { "ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э" },
		r4 = { "я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "." },
		legends = { SPACE = "Пробел" } },
	ua = { name = "Українська", order = 9, numDecimal = ",",
		r1 = { "'", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х", "ї" }, r2end = "\\",
		r3 = { "ф", "і", "в", "а", "п", "р", "о", "л", "д", "ж", "є" },
		r4 = { "я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "." },
		legends = { SPACE = "Пробіл" } },
	-- Korean and Taiwanese boards are the US board with a second alphabet printed on
	-- the keys: the game names the keys as on the US board (the input method is off
	-- while you play), and the Hangul or Zhuyin is shown under the Latin letter.
	ko = { name = "한국어 (두벌식)", order = 10,
		r1 = { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]" }, r2end = "\\",
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'" },
		r4 = { "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/" },
		sub = { Q = "ㅂ", W = "ㅈ", E = "ㄷ", R = "ㄱ", T = "ㅅ", Y = "ㅛ", U = "ㅕ", I = "ㅑ", O = "ㅐ", P = "ㅔ",
			A = "ㅁ", S = "ㄴ", D = "ㅇ", F = "ㄹ", G = "ㅎ", H = "ㅗ", J = "ㅓ", K = "ㅏ", L = "ㅣ",
			Z = "ㅋ", X = "ㅌ", C = "ㅊ", V = "ㅍ", B = "ㅠ", N = "ㅜ", M = "ㅡ" },
		rightAlt = "한/영", rightCtrl = "한자" },
	zh = { name = "繁體中文 (注音)", order = 11,
		r1 = { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
		r2 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]" }, r2end = "\\",
		r3 = { "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'" },
		r4 = { "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/" },
		sub = { ["1"] = "ㄅ", ["2"] = "ㄉ", ["3"] = "ˇ", ["4"] = "ˋ", ["5"] = "ㄓ", ["6"] = "ˊ", ["7"] = "˙",
			["8"] = "ㄚ", ["9"] = "ㄞ", ["0"] = "ㄢ", ["-"] = "ㄦ",
			Q = "ㄆ", W = "ㄊ", E = "ㄍ", R = "ㄐ", T = "ㄔ", Y = "ㄗ", U = "ㄧ", I = "ㄛ", O = "ㄟ", P = "ㄣ",
			A = "ㄇ", S = "ㄋ", D = "ㄎ", F = "ㄑ", G = "ㄕ", H = "ㄘ", J = "ㄨ", K = "ㄜ", L = "ㄠ", [";"] = "ㄤ",
			Z = "ㄈ", X = "ㄌ", C = "ㄏ", V = "ㄒ", B = "ㄖ", N = "ㄙ", M = "ㄩ", [","] = "ㄝ", ["."] = "ㄡ", ["/"] = "ㄥ" },
		legends = { SPACE = "空白鍵" } },
}

local ENGLISH = {
	ESCAPE = "Esc", TAB = "Tab", CAPSLOCK = "Caps", SHIFT = "Shift", CTRL = "Ctrl", ALT = "Alt", ALTGR = "Alt",
	SPACE = "Space", ENTER = "Enter", BACKSPACE = "Bksp", PRINTSCREEN = "PrtSc", SCROLLLOCK = "ScrLk", PAUSE = "Pause",
	INSERT = "Ins", DELETE = "Del", HOME = "Home", END = "End", PAGEUP = "PgUp", PAGEDOWN = "PgDn",
	UP = "Up", DOWN = "Down", LEFT = "Left", RIGHT = "Right", NUMLOCK = "Num",
}

-- The game reports letters with an accent or a ring, and Cyrillic letters, as they
-- are typed, in lower case (å, ø, ö, é, й), while A-Z come in capitals. Keys are
-- printed in capitals (the table is Keybinds', which shows them that way on bars).
local CAPITAL = (ns.addon and ns.addon.Keybinds and ns.addon.Keybinds.CapitalLetters) or {
	["å"] = "Å", ["æ"] = "Æ", ["ø"] = "Ø", ["ä"] = "Ä", ["ö"] = "Ö", ["ü"] = "Ü",
	["é"] = "É", ["è"] = "È", ["ç"] = "Ç", ["à"] = "À", ["ù"] = "Ù",
}

local function DefaultLayout()
	local locale = GetLocale and GetLocale() or "enUS"
	if locale == "deDE" then return "de" end
	if locale == "frFR" then return "fr" end
	if locale == "enGB" then return "uk" end
	if locale == "ruRU" then return "ru" end
	if locale == "koKR" then return "ko" end
	if locale == "zhTW" then return "zh" end
	return "us"
end

---------------------------------------------------------------------------
-- The models, as blocks of keys
---------------------------------------------------------------------------
-- A key is { token, legend, x, y, w, h, shape } in key units within its block.
-- Blocks sit side by side when the page is wide enough and wrap when it is not.

local function MainBlock(layout)
	local keys = {}
	local legends = layout.legends or {}
	local function Legend(token) return legends[token] or ENGLISH[token] or token end
	local function Row(y, x, list)
		for _, k in ipairs(list) do
			local w = k[3] or 1
			if k[1] then keys[#keys + 1] = { k[1], k[2] or Legend(k[1]), x, y, w, k[4] or 1, sub = k.sub } end
			x = x + w
		end
	end
	-- A key's legend: the letter in capitals, and the second alphabet printed on the
	-- key (Hangul, Zhuyin) in its other corner, as on the real keycap.
	local sub = layout.sub or {}
	local function Plain(tokens)
		local out = {}
		for i, t in ipairs(tokens) do out[i] = { t, CAPITAL[t], sub = sub[t] } end
		return out
	end
	local function Join(...)
		local out = {}
		for i = 1, select("#", ...) do
			for _, k in ipairs((select(i, ...))) do out[#out + 1] = k end
		end
		return out
	end

	Row(0, 0, { { "ESCAPE" }, { false, nil, 1 }, { "F1" }, { "F2" }, { "F3" }, { "F4" }, { false, nil, .5 },
		{ "F5" }, { "F6" }, { "F7" }, { "F8" }, { false, nil, .5 }, { "F9" }, { "F10" }, { "F11" }, { "F12" } })
	Row(1.25, 0, Join(Plain(layout.r1), { { "BACKSPACE", nil, 2 } }))
	if layout.iso then
		Row(2.25, 0, Join({ { "TAB", nil, 1.5 } }, Plain(layout.r2)))
		keys[#keys + 1] = { "ENTER", Legend("ENTER"), 13.75, 2.25, 1.25, 2 }
		Row(3.25, 0, Join({ { "CAPSLOCK", nil, 1.75 } }, Plain(layout.r3)))
		Row(4.25, 0, Join({ { "SHIFT", nil, 1.25 } }, Plain(layout.r4), { { "SHIFT", nil, 2.75 } }))
	else
		Row(2.25, 0, Join({ { "TAB", nil, 1.5 } }, Plain(layout.r2), { { layout.r2end, nil, 1.5 } }))
		Row(3.25, 0, Join({ { "CAPSLOCK", nil, 1.75 } }, Plain(layout.r3), { { "ENTER", nil, 2.25 } }))
		Row(4.25, 0, Join({ { "SHIFT", nil, 2.25 } }, Plain(layout.r4), { { "SHIFT", nil, 2.75 } }))
	end
	-- the right Alt is Alt Gr on most European boards; the game reports it as Alt
	Row(5.25, 0, { { "CTRL", nil, 1.5 }, { false, nil, 1 }, { "ALT", nil, 1.5 }, { "SPACE", nil, 7 },
		{ "ALT", layout.rightAlt or (layout.iso and Legend("ALTGR") or Legend("ALT")), 1.5 }, { false, nil, 1 },
		{ "CTRL", layout.rightCtrl or Legend("CTRL"), 1.5 } })
	return { key = "main", w = 15, h = 6.25, keys = keys }
end

local function NavBlock(layout)
	local legends = layout.legends or {}
	local function K(token, x, y) return { token, legends[token] or ENGLISH[token] or token, x, y, 1, 1 } end
	return { key = "nav", w = 3, h = 6.25, keys = {
		K("PRINTSCREEN", 0, 0), K("SCROLLLOCK", 1, 0), K("PAUSE", 2, 0),
		K("INSERT", 0, 1.25), K("HOME", 1, 1.25), K("PAGEUP", 2, 1.25),
		K("DELETE", 0, 2.25), K("END", 1, 2.25), K("PAGEDOWN", 2, 2.25),
		K("UP", 1, 4.25), K("LEFT", 0, 5.25), K("DOWN", 1, 5.25), K("RIGHT", 2, 5.25),
	} }
end

local function NumBlock(layout)
	local legends = layout.legends or {}
	return { key = "num", w = 4, h = 6.25, keys = {
		{ "NUMLOCK", legends.NUMLOCK or "Num", 0, 1.25, 1, 1 }, { "NUMPADDIVIDE", "/", 1, 1.25, 1, 1 },
		{ "NUMPADMULTIPLY", "*", 2, 1.25, 1, 1 }, { "NUMPADMINUS", "-", 3, 1.25, 1, 1 },
		{ "NUMPAD7", "7", 0, 2.25, 1, 1 }, { "NUMPAD8", "8", 1, 2.25, 1, 1 }, { "NUMPAD9", "9", 2, 2.25, 1, 1 },
		{ "NUMPADPLUS", "+", 3, 2.25, 1, 2 },
		{ "NUMPAD4", "4", 0, 3.25, 1, 1 }, { "NUMPAD5", "5", 1, 3.25, 1, 1 }, { "NUMPAD6", "6", 2, 3.25, 1, 1 },
		{ "NUMPAD1", "1", 0, 4.25, 1, 1 }, { "NUMPAD2", "2", 1, 4.25, 1, 1 }, { "NUMPAD3", "3", 2, 4.25, 1, 1 },
		-- the game reports the numpad's Enter as Enter
		{ "ENTER", "Ent", 3, 4.25, 1, 2 },
		{ "NUMPAD0", "0", 0, 5.25, 2, 1 }, -- the decimal key prints the comma where the language writes one (Danish, German, Russian)
		{ "NUMPADDECIMAL", layout.numDecimal or ".", 2, 5.25, 1, 1 },
	} }
end

-- A mouse seen from above: two big buttons cut from its front, the wheel in the
-- channel between them, and the two thumb buttons on its left side. The button
-- shapes (media/panel/mouse-left, -right) are cut from the body's own outline, at
-- these positions: body pixels 4-29 and 35-60 across, 4-46 down, of 64 x 104.
local MOUSE_BLOCK = { key = "mouse", body = { .5, 0, 4, 6.25 }, w = 4.6, h = 6.25, keys = {
	{ "BUTTON1", "M1", .75, .24, 1.5625, 2.52, "mouse-left" },
	{ "BUTTON2", "M2", 2.6875, .24, 1.5625, 2.52, "mouse-right" },
	{ "MOUSEWHEELUP", "WU", 2.24, .45, .52, .6 },
	{ "BUTTON3", "M3", 2.24, 1.1, .52, .85 },
	{ "MOUSEWHEELDOWN", "WD", 2.24, 2.0, .52, .6 },
	{ "BUTTON4", "M4", 0, 2.95, .85, .85 },
	{ "BUTTON5", "M5", 0, 3.9, .85, .85 },
} }

-- The controllers, one per brand, in key units. Button positions follow
-- ConsolePort's layouts for the same devices (Model/Gamepad/*.lua), scaled to
-- these units; the bodies are AHOS's own (Tools/MakePanelArt.py, pad-*), drawn in
-- the same units so the details (touchpad, screen, trackpads) line up. A key is
-- placed by its centre: C(token, x, y, w, h).
local function C(token, x, y, w, h) return { token, nil, x - w / 2, y - h / 2, w, h } end
local function Shoulders(left, right)
	return { C("PADLTRIGGER", left, .35, 2.6, .7), C("PADRTRIGGER", right, .35, 2.6, .7),
		C("PADLSHOULDER", left, 1.15, 2.6, .7), C("PADRSHOULDER", right, 1.15, 2.6, .7) }
end
local function Dpad(x, y, size, step)
	return { C("PADDUP", x, y - step, size, size), C("PADDDOWN", x, y + step, size, size),
		C("PADDLEFT", x - step, y, size, size), C("PADDRIGHT", x + step, y, size, size) }
end
-- face buttons: PAD4 on top, PAD2 right, PAD1 bottom, PAD3 left, on every brand
local function Face(x, y, size, step)
	return { C("PAD4", x, y - step, size, size), C("PAD2", x + step, y, size, size),
		C("PAD1", x, y + step, size, size), C("PAD3", x - step, y, size, size) }
end
-- Keys and groups of keys (Shoulders, Dpad, Face) as one list.
local function Keys(...)
	local out = {}
	for i = 1, select("#", ...) do
		local item = select(i, ...)
		if type(item[1]) == "table" then
			for _, spec in ipairs(item) do out[#out + 1] = spec end
		else
			out[#out + 1] = item
		end
	end
	return out
end

local PAD_DEVICES = {
	-- offset sticks, the guide button on top, View and Menu beside it
	xbox = { name = "Xbox", order = 1, style = "xbox", art = "pad-xbox", w = 13, h = 8, body = { .3, 1.65, 12.4, 6.35 },
		keys = Keys(Shoulders(2.6, 10.4),
			C("PADLSTICK", 2.85, 3.0, 1.4, 1.4), Dpad(4.6, 5.3, .85, .9),
			Face(10.55, 3.3, .95, .95), C("PADRSTICK", 8.4, 5.2, 1.4, 1.4),
			C("PADBACK", 5.3, 2.75, .8, .55), C("PADFORWARD", 7.7, 2.75, .8, .55),
			C("PADSYSTEM", 6.5, 2.0, .9, .6), C("PADSOCIAL", 6.5, 3.5, .7, .45)) },
	-- DualSense: D-pad and face buttons up top, sticks side by side below, the
	-- touchpad between Create and Options (its halves are two buttons), PS and mic below
	ps = { name = "PlayStation", order = 2, style = "ps", art = "pad-ps", w = 13.4, h = 8.2, body = { .2, 1.6, 13, 6.6 },
		keys = Keys(Shoulders(2.4, 11.0),
			Dpad(2.6, 3.4, .8, .85), Face(10.8, 3.4, .95, .9),
			C("PADBACK", 5.92, 2.6, 1.5, 1.25), C("PAD6", 7.48, 2.6, 1.5, 1.25),
			C("PADSOCIAL", 4.4, 2.05, .5, .75), C("PADFORWARD", 9.0, 2.05, .5, .75),
			C("PADLSTICK", 4.6, 5.3, 1.3, 1.3), C("PADRSTICK", 8.8, 5.3, 1.3, 1.3),
			C("PADSYSTEM", 6.7, 4.6, .75, .55), C("PAD5", 6.7, 5.35, .75, .42)) },
	-- Switch Pro: like Xbox in shape, with − and + and Capture and Home in the middle
	switch = { name = "Nintendo Switch", order = 3, style = "switch", art = "pad-switch", w = 13, h = 8, body = { .3, 1.65, 12.4, 6.35 },
		keys = Keys(Shoulders(2.6, 10.4),
			C("PADLSTICK", 2.85, 3.05, 1.35, 1.35), Dpad(4.5, 5.25, .85, .9),
			Face(10.55, 3.3, .95, .95), C("PADRSTICK", 8.35, 5.2, 1.35, 1.35),
			C("PADBACK", 5.1, 2.3, .6, .6), C("PADFORWARD", 7.9, 2.3, .6, .6),
			C("PADSOCIAL", 5.7, 3.3, .6, .6), C("PADSYSTEM", 7.3, 3.3, .6, .6)) },
	-- Steam Deck: the screen in the middle, D-pad and stick on the left, face
	-- buttons and stick on the right, a trackpad under each thumb; L4, L5, R4 and
	-- R5 on the back are the paddles
	deck = { name = "Steam Deck", order = 4, style = "xbox", art = "pad-deck", w = 16.4, h = 7, body = { 0, 1.6, 16.4, 5.4 },
		legends = { PADPADDLE1 = "L4", PADPADDLE2 = "L5", PADPADDLE3 = "R4", PADPADDLE4 = "R5" },
		keys = Keys(Shoulders(1.9, 14.5),
			Dpad(1.55, 3.05, .75, .75), C("PADLSTICK", 3.45, 2.85, 1.1, 1.1),
			Face(14.85, 3.05, .75, .75), C("PADRSTICK", 12.95, 2.85, 1.1, 1.1),
			C("PADBACK", 3.5, 1.95, .7, .38), C("PADFORWARD", 12.9, 1.95, .7, .38),
			C("PADSYSTEM", 1.0, 6.45, .8, .4), C("PADSOCIAL", 15.4, 6.45, .8, .4)) },
	-- Steam Controller: two round trackpads up top (the left one clicks as a
	-- D-pad, the right one as the right stick), one stick low on the left
	steam = { name = "Steam Controller", order = 5, style = "xbox", art = "pad-steam", w = 13.4, h = 8.4, body = { .2, 1.6, 13, 6.8 },
		legends = { PADPADDLE1 = "LG", PADPADDLE2 = "RG" },
		keys = Keys(Shoulders(2.4, 11.0),
			Dpad(3.4, 3.6, .7, .85), C("PADRSTICK", 10.0, 3.6, .9, .9),
			C("PADLSTICK", 4.9, 6.15, 1.1, 1.1), Face(8.4, 6.1, .6, .65),
			C("PADBACK", 5.6, 3.75, .6, .4), C("PADSYSTEM", 6.7, 3.25, .75, .75), C("PADFORWARD", 7.8, 3.75, .6, .4)) },
}

local PAD_EXTRA = { "PAD5", "PAD6", "PADSYSTEM", "PADSOCIAL", "PADPADDLE1", "PADPADDLE2", "PADPADDLE3", "PADPADDLE4",
	"PADLSTICKUP", "PADLSTICKDOWN", "PADLSTICKLEFT", "PADLSTICKRIGHT",
	"PADRSTICKUP", "PADRSTICKDOWN", "PADRSTICKLEFT", "PADRSTICKRIGHT" }

-- How each kind of controller names its buttons. "auto" asks the game for the
-- glyph of the controller in use.
local PAD_STYLES = {
	xbox = { name = "Xbox", order = 2, labels = {
		PAD1 = "A", PAD2 = "B", PAD3 = "X", PAD4 = "Y", PADLSHOULDER = "LB", PADRSHOULDER = "RB",
		PADLTRIGGER = "LT", PADRTRIGGER = "RT", PADLSTICK = "LS", PADRSTICK = "RS", PADBACK = "View",
		PADFORWARD = "Menu", PADSYSTEM = "Xbox", PADSOCIAL = "Share" } },
	ps = { name = "PlayStation", order = 3, labels = {
		PAD1 = "Cross", PAD2 = "Circle", PAD3 = "Square", PAD4 = "Triangle", PADLSHOULDER = "L1", PADRSHOULDER = "R1",
		PADLTRIGGER = "L2", PADRTRIGGER = "R2", PADLSTICK = "L3", PADRSTICK = "R3", PADBACK = "Create",
		PADFORWARD = "Options", PADSYSTEM = "PS", PADSOCIAL = "Touch" } },
	switch = { name = "Nintendo Switch", order = 4, labels = {
		PAD1 = "B", PAD2 = "A", PAD3 = "Y", PAD4 = "X", PADLSHOULDER = "L", PADRSHOULDER = "R",
		PADLTRIGGER = "ZL", PADRTRIGGER = "ZR", PADLSTICK = "LS", PADRSTICK = "RS", PADBACK = "−",
		PADFORWARD = "+", PADSYSTEM = "Home", PADSOCIAL = "Capture" } },
}
local PAD_COMMON = { PADDUP = "↑", PADDDOWN = "↓", PADDLEFT = "←", PADDRIGHT = "→", PAD5 = "P5", PAD6 = "P6",
	PADPADDLE1 = "Pdl1", PADPADDLE2 = "Pdl2", PADPADDLE3 = "Pdl3", PADPADDLE4 = "Pdl4",
	PADLSTICKUP = "LS↑", PADLSTICKDOWN = "LS↓", PADLSTICKLEFT = "LS←", PADLSTICKRIGHT = "LS→",
	PADRSTICKUP = "RS↑", PADRSTICKDOWN = "RS↓", PADRSTICKLEFT = "RS←", PADRSTICKRIGHT = "RS→" }

-- A button's legend: the client's glyph for that controller where it has one,
-- else the name that controller prints on it.
local function PadLegend(token, style, size, device)
	local own = device and device.legends and device.legends[token]
	if own then return own end
	local kb = addon.Keybinds
	local glyph = kb and kb.GetGamePadGlyph and kb:GetGamePadGlyph(token, style, size or 16)
	if glyph then return glyph end
	local labels = (PAD_STYLES[style] and PAD_STYLES[style].labels) or PAD_STYLES.xbox.labels
	return labels[token] or PAD_COMMON[token] or token
end

local EXTRA_MOUSE_FIRST, EXTRA_MOUSE_SHOWN, EXTRA_MOUSE_LAST = 6, 12, 31

local GAP, PAD = 4, 14
local MIN_UNIT, PREF_UNIT, MAX_UNIT = 20, 30, 40
local BLOCK_GAP, ROW_GAP = .5, .7
local HEAD_H, GROUP_LABEL_H = 66, 18
local SLICE_W = 300

local control, slice, catcher

local function Keybinds() return addon.Keybinds end

local function Settings()
	local panel = Kit.Panel and Kit.Panel.Settings and Kit.Panel.Settings()
	return type(panel) == "table" and panel or {}
end

local function Device()
	local settings = Settings()
	if settings.keyboardDevice then return settings.keyboardDevice end
	local ok, enabled = pcall(function() return C_GamePad and C_GamePad.IsEnabled and C_GamePad.IsEnabled() end)
	return (ok and enabled) and "controller" or "keyboard"
end

local function LayoutKey()
	local key = Settings().keyboardLayout
	return LAYOUTS[key] and key or DefaultLayout()
end

-- The controller drawn on the Controller tab. "auto" reads the game's own glyph
-- for the bottom face button: a cross means PlayStation, a reversed B Nintendo.
local function PadDeviceKey()
	local key = Settings().padDevice
	if PAD_DEVICES[key] then return key end
	local style = addon.Keybinds and addon.Keybinds.GetGamePadStyle and addon.Keybinds:GetGamePadStyle()
	if style == "ps" or style == "switch" then return style end
	local ok, glyph = pcall(function() return GetBindingText and GetBindingText("PAD1", 1) end)
	if ok and type(glyph) == "string" and addon:IsValueAccessible(glyph) then
		if glyph:find("Gamepad_Shp", 1, true) then return "ps" end
		if glyph:find("Gamepad_Rev", 1, true) then return "switch" end
	end
	return "xbox"
end

local function PadDevice() return PAD_DEVICES[PadDeviceKey()] end

-- The glyphs drawn on the Controller tab: the device's own, unless the profile
-- asks for one style everywhere.
local function PadStyle()
	local kb = addon.Keybinds
	local style = kb and kb.GetGamePadStyle and kb:GetGamePadStyle()
	if style and style ~= "auto" then return style end
	return PadDevice().style
end

-- A modifier is in the layer when it is latched, or held down right now.
local function ModOn(mod)
	return control.mods[mod] or (control.held and control.held[mod]) or false
end

-- The full binding for a key in the current layer, in the game's own order.
local function FullKey(token)
	if MODIFIERS[token] then return token end
	return (ModOn("ALT") and "ALT-" or "") .. (ModOn("CTRL") and "CTRL-" or "") .. (ModOn("SHIFT") and "SHIFT-" or "") .. token
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

-- The blocks the current tab draws.
local function Blocks()
	if Device() == "controller" then
		local device = PadDevice()
		return { { key = "pad", art = device.art, w = device.w, h = device.h, body = device.body, keys = device.keys, device = device } }
	end
	local layout = LAYOUTS[LayoutKey()]
	return { MainBlock(layout), NavBlock(layout), NumBlock(layout), MOUSE_BLOCK }
end

-- The key a binding ends in ("CTRL-SHIFT-F13" -> "F13").
local function BaseKey(binding)
	local rest = binding
	while true do
		local mod, remainder = rest:match("^(%u+)%-(.+)$")
		if not (mod and MODIFIERS[mod]) then break end
		rest = remainder
	end
	return rest
end

-- The extra buttons to show (mouse 6-12 always and more when bound, or the
-- controller's paddles and stick directions), and every bound key on no model.
-- The game lists bindings, never the hardware.
local function ExtraKeys(onModel, found, device)
	local extra, other, seen = {}, {}, {}
	local highestMouse = EXTRA_MOUSE_SHOWN
	local function Consider(base)
		local n = tonumber(base:match("^BUTTON(%d+)$"))
		if n and n >= EXTRA_MOUSE_FIRST then
			highestMouse = max(highestMouse, min(n, EXTRA_MOUSE_LAST))
		elseif not onModel[base] and not MODIFIERS[base] and not seen[base] then
			seen[base] = true
			other[#other + 1] = base
		end
	end
	local count = GetNumBindings and GetNumBindings() or 0
	for i = 1, count do
		local ok, results = pcall(function() return { GetBinding(i) } end)
		if ok then
			for j = 3, #results do
				local binding = results[j]
				if type(binding) == "string" and binding ~= "" and addon:IsValueAccessible(binding) then
					Consider(BaseKey(binding))
				end
			end
		end
	end
	for token in pairs(found or {}) do Consider(token) end
	if device == "controller" then
		for _, token in ipairs(PAD_EXTRA) do
			if not onModel[token] then extra[#extra + 1] = token end
		end
	else
		for n = EXTRA_MOUSE_FIRST, highestMouse do extra[#extra + 1] = "BUTTON" .. n end
	end
	table.sort(other)
	return extra, other
end

---------------------------------------------------------------------------
-- Keys
---------------------------------------------------------------------------
local function StyleKey(key)
	local token = key.token
	local selected = control.selected == token
	local latched = MODIFIERS[token] and ModOn(token)
	local back, accent = Kit.BackdropColor, Kit.TextSelected
	local fill
	if control.pressed and control.pressed[token] then
		-- a key you are pressing right now
		fill = { accent[1] * .8, accent[2] * .8, accent[3] * .8, 1 }
	elseif latched then
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
	key.second:SetTextColor(Kit.TextDisabled[1], Kit.TextDisabled[2], Kit.TextDisabled[3])
	key.shown:SetTextColor(unpack(key.tint or Kit.TextHighlight))
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
		GameTooltip:AddLine(L["Not bound in this layer."], unpack(Kit.TextDisabled))
	end
	-- what the key does with other modifiers held
	local kb = Keybinds()
	local others = 0
	for _, prefix in ipairs({ "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }) do
		local binding = prefix .. key.token
		if binding ~= full and not MODIFIERS[key.token] then
			local ok, command = pcall(GetBindingAction, binding, true)
			if ok and type(command) == "string" and command ~= "" and addon:IsValueAccessible(command) then
				if others == 0 then GameTooltip:AddLine(" ") end
				others = others + 1
				GameTooltip:AddDoubleLine(binding, kb and kb:GetCommandLabel(command) or command,
					Kit.TextSelected[1], Kit.TextSelected[2], Kit.TextSelected[3], Kit.TextNormal[1], Kit.TextNormal[2], Kit.TextNormal[3])
			end
		end
	end
	GameTooltip:Show()
end

local Select

-- Text on a key is made smaller rather than cut: "Indsæt", "Pause" and a long
-- abbreviation read whole, in a size that fits the key, in every language.
-- Chinese, Japanese and Korean start two sizes up: at Latin sizes their strokes
-- run together. (UTF-8 lead bytes E3-ED: Hangul, Bopomofo and the ideographs.)
local CJK = "[\227-\237][\128-\191][\128-\191]"
local MIN_TEXT = 6

local function TextWidth(fs)
	local width = (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()) or (fs.GetStringWidth and fs:GetStringWidth())
	return tonumber(width) or 0
end

local function FitText(fs, text, base, room)
	text = text or ""
	if text:find(CJK) then base = base + 2 end
	fs:SetFontObject(Kit.GetFont(base))
	fs:SetText(text)
	if text == "" or not room or room <= 0 then return base end
	local size = base
	local width = TextWidth(fs)
	-- a first guess from the ratio, then a step at a time, since glyphs do not
	-- shrink in exact proportion
	if width > room then
		size = max(MIN_TEXT, floor(base * room / width))
		fs:SetFontObject(Kit.GetFont(size))
		while size > MIN_TEXT and TextWidth(fs) > room do
			size = size - 1
			fs:SetFontObject(Kit.GetFont(size))
		end
	end
	return size
end

-- Sizes a key's texts to the key: the legend in the top-left (beside the second
-- alphabet, when the key has one), what AHOS draws in the bottom-right.
local function FitKey(key)
	local width = key.width or 40
	local pad = 7
	if key.shape and key.shape ~= "" then
		FitText(key.legend, key.legendText, 10, width - 4)
		FitText(key.shown, key.shownText, 12, width - 4)
		return
	end
	local secondRoom = 0
	if key.secondText and key.secondText ~= "" then
		FitText(key.second, key.secondText, 10, floor(width / 2))
		secondRoom = TextWidth(key.second) + 12
	else
		key.second:SetText("")
	end
	FitText(key.legend, key.legendText, 10, width - pad - secondRoom)
	FitText(key.shown, key.shownText, 12, width - pad)
end

local function CreateKey(parent, shape)
	local key = { shape = shape or "" }
	local frame = CreateFrame("Button", nil, parent)
	key.frame = frame
	key.round = shape and Look.Shape(frame, shape, true) or Look.Round(frame, 4, nil, nil, true)

	local legend = frame:CreateFontString(nil, "OVERLAY")
	legend:SetFontObject(Kit.GetFont(10))
	legend:SetWordWrap(false)
	key.legend = legend

	-- the second alphabet a Korean or Taiwanese keycap carries (ㅂ, ㄅ)
	local second = frame:CreateFontString(nil, "OVERLAY")
	second:SetFontObject(Kit.GetFont(10))
	second:SetWordWrap(false)
	second:SetJustifyH("RIGHT")
	second:SetPoint("TOPRIGHT", -10, -3)
	key.second = second

	-- what AHOS would draw on a button bound to this key
	local shown = frame:CreateFontString(nil, "OVERLAY")
	shown:SetFontObject(Kit.GetFont(12))
	shown:SetWordWrap(false)
	key.shown = shown

	-- One point each, never two: a text held between two points is cut to "Ind…"
	-- when it is too wide. FitText makes it smaller instead.
	if shape then
		-- a shaped key (the mouse's buttons): both centred, clear of its curved edge
		legend:SetPoint("CENTER", frame, "CENTER", 0, 8)
		legend:SetJustifyH("CENTER")
		shown:SetPoint("CENTER", frame, "CENTER", 0, -8)
		shown:SetJustifyH("CENTER")
	else
		legend:SetPoint("TOPLEFT", 4, -3)
		legend:SetJustifyH("LEFT")
		shown:SetPoint("BOTTOMRIGHT", -4, 5)
		shown:SetJustifyH("RIGHT")
	end

	local dot = frame:CreateTexture(nil, "OVERLAY")
	dot:SetSize(6, 6)
	dot:SetPoint("TOPRIGHT", -3, -3)
	Kit.SetGlyph(dot, "gem")
	key.dot = dot

	frame:SetScript("OnClick", function()
		PlaySound(852)
		Select(key.token)
	end)
	frame:SetScript("OnEnter", function() key.hovered = true; StyleKey(key); KeyTooltip(key) end)
	frame:SetScript("OnLeave", function() key.hovered = nil; StyleKey(key); GameTooltip:Hide() end)
	return key
end

---------------------------------------------------------------------------
-- The key's card, in a slice beside the window
---------------------------------------------------------------------------
local LINE_H = 20

-- After a key was bound or unbound from its card.
local function AfterBindingChange(ok, reason)
	if not ok then
		if reason and addon.Print then addon:Print(reason) end
		if reason and UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(reason, 1, .3, .3) end
		return
	end
	if addon.IsReady and addon:IsReady() and addon.Core and addon.Core.FullUpdate then addon.Core:FullUpdate() end
	control:Update()
end

-- The list a key's "Bind to" button opens: every action button command, by bar.
local function OpenBindList(card, full)
	local kb = Keybinds()
	local list, order = {}, {}
	for _, entry in ipairs(kb:GetBindableCommands()) do
		list[entry.command] = entry.label
		order[#order + 1] = entry.command
	end
	local owner = card.bindOwner or {}
	card.bindOwner = owner
	owner.box, owner.listWidth = card.bind, 300
	owner.list, owner.order = list, order
	local okAction, current = pcall(GetBindingAction, full)
	owner.value = okAction and addon:IsValueAccessible(current) and current or nil
	owner.SetValue = function(self, value) self.value = value end
	owner.Fire = function(_, command) AfterBindingChange(kb:SetKeyBinding(full, command)) end
	Controls.OpenList(owner)
end

local function AfterAbbreviationChange()
	local kb = Keybinds()
	if kb and kb.ClearCache then kb:ClearCache() end
	if addon.IsReady and addon:IsReady() and addon.Core and addon.Core.FullUpdate then addon.Core:FullUpdate() end
	if Kit.Panel and Kit.Panel.Refresh then Kit.Panel:Refresh() else control:Update() end
end

local function CreateCard(parent)
	local card = { lines = {} }
	local frame = CreateFrame("Frame", nil, parent)
	card.frame = frame

	local eyebrow = frame:CreateFontString(nil, "OVERLAY")
	eyebrow:SetFontObject(Kit.GetFont(11))
	eyebrow:SetPoint("TOPLEFT", PAD, -14)
	eyebrow:SetText(L["KEY"])
	card.eyebrow = eyebrow

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(Look.Font(18, "display"))
	title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
	title:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	title:SetJustifyH("LEFT")
	title:SetWordWrap(false)
	card.title = title

	local shownAs = frame:CreateFontString(nil, "OVERLAY")
	shownAs:SetFontObject(Kit.GetFont(12))
	shownAs:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	shownAs:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	shownAs:SetJustifyH("LEFT")
	shownAs:SetWordWrap(true)
	card.shownAs = shownAs

	-- One of the panel's own rows, stacked to fit the slice.
	local input = Controls.CreateInput(frame)
	input:SetStacked()
	input.rule:Hide()
	card.input = input

	-- Binding the key from here: to any action button, off again, or through the
	-- hover-and-press mode of LibKeyBound where a bar addon brought it.
	card.bind = Controls.CreateBareButton(frame, L["Bind to..."], function()
		OpenBindList(card, FullKey(control.selected))
	end)
	card.unbind = Controls.CreateBareButton(frame, L["Unbind"], function()
		AfterBindingChange(Keybinds():SetKeyBinding(FullKey(control.selected), nil))
	end)
	card.keybound = Controls.CreateBareButton(frame, L["Hover Bind Mode"], function()
		local KeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
		if not KeyBound then return end
		if Kit.Panel and Kit.Panel.Close then Kit.Panel:Close() end
		KeyBound:Activate()
	end)
	card.unbind:SetPoint("LEFT", card.bind, "RIGHT", 8, 0)

	local heading = frame:CreateFontString(nil, "OVERLAY")
	heading:SetFontObject(Kit.GetFont(11))
	heading:SetJustifyH("LEFT")
	card.heading = heading

	local hint = frame:CreateFontString(nil, "OVERLAY")
	hint:SetFontObject(Kit.GetFont(12))
	hint:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -10)
	hint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	hint:SetJustifyH("LEFT")
	hint:SetWordWrap(true)
	hint:SetText(L["Click a key on the keyboard or the mouse to see what it does, change its abbreviation or bind it."])
	card.hint = hint
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
	line.text:SetJustifyV("TOP")
	line.text:SetWordWrap(true)
	card.lines[index] = line
	return line
end

local function TextHeight(fontstring, width)
	local measured = Controls.MeasureText and Controls.MeasureText(Kit.GetFont(12), fontstring:GetText() or "", width)
	return max(LINE_H - 6, measured or 0)
end

-- Fills the card for the selected key and returns its height.
local function FillCard(card, width)
	local token = control.selected
	local kb = Keybinds()
	card.frame:SetWidth(width)
	for _, line in ipairs(card.lines) do line.icon:Hide(); line.text:Hide() end
	local inner = width - PAD * 2
	local isModifier = token and MODIFIERS[token]
	local pieces = { card.title, card.shownAs, card.input.frame, card.bind, card.unbind, card.keybound, card.heading }
	if not (token and kb) then
		for _, piece in ipairs(pieces) do piece:Hide() end
		card.hint:Show()
		return 90
	end
	card.hint:Hide()
	for _, piece in ipairs(pieces) do piece:Show() end

	local full = FullKey(token)
	card.title:SetText(full)
	if isModifier then
		card.shownAs:SetText(L["Every binding with this modifier starts with its abbreviation."])
	else
		local shown = kb:Abbreviate(full)
		card.shownAs:SetText(L["Shown on buttons as"] .. "  |cffffffff" .. (shown ~= "" and shown or "-") .. "|r")
	end
	local y = 14 + 11 + 6 + 22 + 6 + TextHeight(card.shownAs, inner) + 8

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
	input.frame:ClearAllPoints()
	input.frame:SetPoint("TOPLEFT", card.frame, "TOPLEFT", 0, -y)
	input.frame:SetWidth(width)
	y = y + input:GetHeight() + 8

	local bindingButtons = { card.bind, card.unbind, card.keybound }
	for _, button in ipairs(bindingButtons) do button:SetShown(not isModifier) end
	if isModifier then
		card.heading:Hide()
		return y + 6
	end

	local report = kb:DescribeKey(full, control.bound)
	card.bind:ClearAllPoints()
	card.bind:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD, -y)
	card.unbind:SetDisabled(not report.command or report.command == "")
	local hasKeyBound = LibStub and LibStub("LibKeyBound-1.0", true) ~= nil
	card.keybound:SetShown(hasKeyBound and true or false)
	card.keybound:ClearAllPoints()
	card.keybound:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD, -(y + 22 + 6))
	for _, button in ipairs(bindingButtons) do button:Restyle() end
	y = y + 22 + 12 + (hasKeyBound and 28 or 0)

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
		local indent = info.icon and 22 or 0
		line.icon:ClearAllPoints()
		line.icon:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD, -y - 2)
		line.icon:SetTexture(info.icon)
		line.icon:SetShown(info.icon ~= nil)
		line.text:ClearAllPoints()
		line.text:SetPoint("TOPLEFT", card.frame, "TOPLEFT", PAD + indent, -y - 3)
		line.text:SetWidth(inner - indent)
		line.text:SetText(info.text)
		line.text:Show()
		y = y + TextHeight(line.text, inner - indent) + 6
	end
	return y + 10
end

-- The slice: a narrow panel docked to the window's right edge, or its left when
-- the right would run off the screen. It holds the card, scrolled if it is long.
local function BuildSlice()
	slice = CreateFrame("Frame", nil, UIParent)
	slice:SetWidth(SLICE_W)
	slice:EnableMouse(true)
	slice:Hide()
	slice.shadow = Look.Shadow(slice, 16)
	slice.round = Look.Round(slice, 10, true)

	local scroll = CreateFrame("ScrollFrame", nil, slice)
	scroll:SetPoint("TOPLEFT", 4, -4)
	scroll:SetPoint("BOTTOMRIGHT", -4, 4)
	scroll:SetClipsChildren(true)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(SLICE_W - 8, 1)
	scroll:SetScrollChild(child)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		self:SetVerticalScroll(min(range, max(0, (self:GetVerticalScroll() or 0) - delta * 40)))
	end)
	slice.scroll, slice.child = scroll, child
	return slice
end

local function Dock()
	local window = Kit.Panel and Kit.Panel.GetWindow and Kit.Panel:GetWindow()
	if not (slice and window) then return end
	slice:SetParent(window)
	slice:SetFrameStrata(window:GetFrameStrata())
	slice:SetFrameLevel(window:GetFrameLevel() + 1)
	slice:ClearAllPoints()
	local scale = window:GetEffectiveScale() or 1
	local right = (window:GetRight() or 0) * scale
	local room = (UIParent:GetRight() or 0) * (UIParent:GetEffectiveScale() or 1) - right
	if room >= (SLICE_W + 12) * scale then
		slice:SetPoint("TOPLEFT", window, "TOPRIGHT", 6, -40)
		slice:SetPoint("BOTTOMLEFT", window, "BOTTOMRIGHT", 6, 40)
	else
		slice:SetPoint("TOPRIGHT", window, "TOPLEFT", -6, -40)
		slice:SetPoint("BOTTOMRIGHT", window, "BOTTOMLEFT", -6, 40)
	end
end

local function RefreshCard()
	if not (slice and control) then return end
	local height = FillCard(control.card, SLICE_W - 8)
	control.card.frame:SetHeight(max(1, height))
	slice.child:SetHeight(max(1, height))
	control.card.frame:Show()
end

---------------------------------------------------------------------------
-- Find a Key: the next key or mouse button pressed
---------------------------------------------------------------------------
local MOUSE_NAMES = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3" }
local SIDED = { LSHIFT = "SHIFT", RSHIFT = "SHIFT", LCTRL = "CTRL", RCTRL = "CTRL", LALT = "ALT", RALT = "ALT" }

local function StopFinding()
	if catcher then
		catcher:Hide()
		if catcher.EnableKeyboard then catcher:EnableKeyboard(false) end
	end
end

local function Found(token)
	StopFinding()
	if not token or token == "" then return end
	control.found[token] = true
	-- a gamepad button found while the keyboard shows is shown on the controller
	if token:find("^PAD") and Device() ~= "controller" then Settings().keyboardDevice = "controller" end
	Select(token)
end

local function BuildCatcher()
	catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN_DIALOG")
	catcher:EnableMouse(true)
	catcher:EnableMouseWheel(true)
	catcher:Hide()
	local shade = catcher:CreateTexture(nil, "BACKGROUND")
	shade:SetAllPoints()
	shade:SetColorTexture(0, 0, 0, .55)
	local text = catcher:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(Look.Font(18, "display"))
	text:SetPoint("CENTER", 0, 40)
	text:SetText(L["Press the key or mouse button you want to find."])
	catcher.text = text
	local sub = catcher:CreateFontString(nil, "OVERLAY")
	sub:SetFontObject(Kit.GetFont(12))
	sub:SetPoint("TOP", text, "BOTTOM", 0, -10)
	sub:SetText(L["Any key, any mouse button, or the wheel. Click Cancel to stop."])
	catcher.sub = sub
	catcher.cancel = Controls.CreateBareButton(catcher, L["Cancel"], function() StopFinding() end)
	catcher.cancel:SetPoint("TOP", sub, "BOTTOM", 0, -16)
	catcher.cancel:SetFrameLevel(catcher:GetFrameLevel() + 5)

	catcher:SetScript("OnKeyDown", function(_, key)
		if type(key) ~= "string" or key == "" then return end
		Found(SIDED[key] or key)
	end)
	catcher:SetScript("OnGamePadButtonDown", function(_, button)
		if type(button) == "string" and button ~= "" then Found(button) end
	end)
	catcher:SetScript("OnMouseDown", function(_, button)
		local n = type(button) == "string" and button:match("^Button(%d+)$")
		Found(MOUSE_NAMES[button] or (n and ("BUTTON" .. n)))
	end)
	catcher:SetScript("OnMouseWheel", function(_, delta)
		Found(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
	end)
	-- the game takes the keyboard back in combat
	catcher:RegisterEvent("PLAYER_REGEN_DISABLED")
	catcher:SetScript("OnEvent", StopFinding)
end

function Keyboard:StartFinding()
	if InCombatLockdown and InCombatLockdown() then return false end
	if not catcher then BuildCatcher() end
	catcher.text:SetTextColor(unpack(Kit.TextHighlight))
	catcher.sub:SetTextColor(unpack(Kit.TextNormal))
	catcher.cancel:Restyle()
	catcher:Show()
	if catcher.EnableKeyboard then catcher:EnableKeyboard(true) end
	if catcher.EnableGamePadButton then pcall(catcher.EnableGamePadButton, catcher, true) end
	if catcher.SetPropagateKeyboardInput then catcher:SetPropagateKeyboardInput(false) end
	return true
end

function Keyboard:IsFinding()
	return catcher and catcher:IsShown() or false
end

---------------------------------------------------------------------------
-- Laying the blocks out
---------------------------------------------------------------------------
-- Keys stay at a comfortable size: when the page narrows they shrink only to
-- PREF_UNIT, then a block wraps under the others and the keys grow back to fill
-- the row. Below the main block's width at PREF_UNIT they shrink to MIN_UNIT.
local function Arrange(blocks, width)
	local avail = width - PAD * 2 + GAP
	local total, widest = -BLOCK_GAP, 0
	for _, b in ipairs(blocks) do
		total = total + b.w + BLOCK_GAP
		widest = max(widest, b.w)
	end

	local unit
	local rows = {}
	if avail / total - GAP >= PREF_UNIT then
		rows[1] = { blocks = blocks, w = total }
		unit = min(MAX_UNIT, floor(avail / total - GAP))
	else
		unit = max(MIN_UNIT, min(PREF_UNIT, floor(avail / widest - GAP)))
		local fit = avail / (unit + GAP)
		local row
		for _, b in ipairs(blocks) do
			if row and row.w + BLOCK_GAP + b.w <= fit then
				row.blocks[#row.blocks + 1] = b
				row.w = row.w + BLOCK_GAP + b.w
			else
				row = { blocks = { b }, w = b.w }
				rows[#rows + 1] = row
			end
		end
		local rowMax = 0
		for _, r in ipairs(rows) do rowMax = max(rowMax, r.w) end
		unit = min(MAX_UNIT, max(unit, floor(avail / rowMax - GAP)))
	end

	local placed, y = {}, 0
	for i, r in ipairs(rows) do
		local x, h = 0, 0
		for _, b in ipairs(r.blocks) do
			placed[#placed + 1] = { block = b, x = x, y = y }
			x = x + b.w + BLOCK_GAP
			h = max(h, b.h)
		end
		y = y + h + (i < #rows and ROW_GAP or 0)
	end
	return placed, unit, y
end

---------------------------------------------------------------------------
-- The control
---------------------------------------------------------------------------
local function Build(parent)
	control = { kind = "keyboard", first = true, persistent = true, keys = {}, pools = {}, labels = {},
		mods = { SHIFT = false, CTRL = false, ALT = false }, found = {}, width = 640, height = 300 }

	local frame = CreateFrame("Frame", nil, parent)
	control.frame = frame

	local board = CreateFrame("Frame", nil, frame)
	board:SetPoint("TOPLEFT", 0, -2)
	board:SetPoint("RIGHT", 0, 0)
	control.board = board
	control.round = Look.Round(board, 8)

	-- the two tabs, the layout or label style, and Find a Key
	local function Tab(device, label)
		local tab = Controls.CreateBareButton(board, label, function()
			Settings().keyboardDevice = device
			control.selected = nil
			control:Update()
			Relayout()
		end)
		tab.device = device
		return tab
	end
	control.tabKeyboard = Tab("keyboard", L["Keyboard & Mouse"])
	control.tabController = Tab("controller", L["Controller"])
	control.tabKeyboard:SetPoint("TOPLEFT", board, "TOPLEFT", PAD, -8)
	control.tabController:SetPoint("LEFT", control.tabKeyboard, "RIGHT", 4, 0)

	control.find = Controls.CreateBareButton(board, L["Find a Key"], function() Keyboard:StartFinding() end)
	control.find:SetPoint("TOPRIGHT", board, "TOPRIGHT", -PAD, -8)

	control.picker = Controls.CreateBareButton(board, "", function(self)
		local owner = control.pickerOwner or {}
		control.pickerOwner = owner
		local list, order, sorted = {}, {}, {}
		local isPad = Device() == "controller"
		local source = isPad and PAD_DEVICES or LAYOUTS
		for key, info in pairs(source) do sorted[#sorted + 1] = { key = key, order = info.order } end
		table.sort(sorted, function(a, b) return a.order < b.order end)
		if isPad then
			list.auto, order[1] = L["Automatic"], "auto"
		end
		for _, entry in ipairs(sorted) do
			list[entry.key] = source[entry.key].name
			order[#order + 1] = entry.key
		end
		owner.box, owner.listWidth, owner.list, owner.order = self, 190, list, order
		owner.value = isPad and (Settings().padDevice or "auto") or LayoutKey()
		owner.SetValue = function(o, value) o.value = value end
		owner.Fire = function(_, value)
			if isPad then
				-- the controller you pick is the one whose glyphs your bars show too
				Settings().padDevice = value ~= "auto" and value or nil
				local text = addon.db and addon.db.profile and addon.db.profile.text
				if text then text.gamepadIconStyle = value == "auto" and "auto" or PAD_DEVICES[value].style end
				local kb = Keybinds()
				if kb and kb.ClearCache then kb:ClearCache() end
				if addon.IsReady and addon:IsReady() and addon.Core then addon.Core:FullUpdate() end
			else
				Settings().keyboardLayout = value
			end
			control:Update()
			Relayout()
		end
		Controls.OpenList(owner)
	end)
	control.picker:SetPoint("RIGHT", control.find, "LEFT", -8, 0)
	control.picker:SetChevron(true)

	local layer = board:CreateFontString(nil, "OVERLAY")
	layer:SetFontObject(Kit.GetFont(11))
	layer:SetPoint("TOPLEFT", PAD, -42)
	layer:SetJustifyH("LEFT")
	layer:SetWordWrap(false)
	control.layer = layer

	-- On the controller there are no Shift, Ctrl and Alt keys to latch, so they sit here.
	control.latches = {}
	for i, mod in ipairs({ "ALT", "CTRL", "SHIFT" }) do
		local latch = Controls.CreateBareButton(board, ENGLISH[mod], function() Select(mod) end)
		latch.mod = mod
		control.latches[i] = latch
	end
	control.latches[3]:SetPoint("TOPRIGHT", board, "TOPRIGHT", -PAD, -38)
	control.latches[2]:SetPoint("RIGHT", control.latches[3], "LEFT", -4, 0)
	control.latches[1]:SetPoint("RIGHT", control.latches[2], "LEFT", -4, 0)
	layer:SetPoint("RIGHT", board, "RIGHT", -PAD, 0)

	-- the bodies the mouse and the controllers' keys sit on, one per drawing
	control.bodies = {}
	function control:Body(art)
		local body = self.bodies[art]
		if body then return body end
		body = CreateFrame("Frame", nil, board)
		body.surface = Look.Shape(body, art)
		if art ~= "mouse" then
			-- the touchpad, the screen, the trackpads: sunk into the body
			body.detail = body:CreateTexture(nil, "BACKGROUND", nil, -5)
			body.detail:SetTexture(Look.Media(art .. "-detail"))
			body.detail:SetAllPoints()
		end
		body:Hide()
		self.bodies[art] = body
		return body
	end

	for _, text in ipairs({ L["More mouse buttons"], L["Other bound keys"] }) do
		local label = board:CreateFontString(nil, "OVERLAY")
		label:SetFontObject(Kit.GetFont(10))
		label:SetText(text)
		control.labels[#control.labels + 1] = label
	end

	-- A key from the pool for its shape; the pool keeps keys across layouts.
	function control:TakeKey(shape)
		local poolKey = shape or ""
		local pool = self.pools[poolKey] or { free = {}, all = {} }
		self.pools[poolKey] = pool
		local key = table.remove(pool.free)
		if not key then
			key = CreateKey(board, shape)
			pool.all[#pool.all + 1] = key
		end
		self.keys[#self.keys + 1] = key
		key.frame:Show()
		return key
	end

	function control:ReleaseKeys()
		for _, pool in pairs(self.pools) do
			pool.free = {}
			for _, key in ipairs(pool.all) do
				key.frame:Hide()
				key.spec = nil
				pool.free[#pool.free + 1] = key
			end
		end
		self.keys = {}
	end

	-- Puts every key of the current tab on the board for `width`, and returns
	-- the board's height.
	function control:Place(width)
		self:ReleaseKeys()
		local device = Device()
		local isPad = device == "controller"
		local style = PadStyle()
		local placed, unit, heightUnits = Arrange(Blocks(), width)
		local pitch = unit + GAP
		local function Px(units) return floor(units * pitch + .5) end
		local function Size(units) return max(1, floor(units * pitch - GAP + .5)) end

		local onModel = {}
		for _, body in pairs(self.bodies) do body:Hide() end
		for _, at in ipairs(placed) do
			local block = at.block
			if block.body then
				local body = self:Body(block.art or "mouse")
				local b = block.body
				body:ClearAllPoints()
				body:SetPoint("TOPLEFT", self.board, "TOPLEFT", PAD + Px(at.x + b[1]), -(HEAD_H + Px(at.y + b[2])))
				body:SetSize(Px(b[3]), Px(b[4]))
				body:SetFrameLevel(self.board:GetFrameLevel() + 1)
				body:Show()
			end
			for _, spec in ipairs(block.keys) do
				local key = self:TakeKey(spec[7])
				key.spec = spec
				key.token = spec[1]
				key.legendText = spec[2] or (isPad and PadLegend(spec[1], style, max(14, floor(min(spec[5], spec[6]) * pitch * .55)), block.device)) or spec[1]
				key.secondText = spec.sub or ""
				key.frame:ClearAllPoints()
				key.frame:SetPoint("TOPLEFT", self.board, "TOPLEFT", PAD + Px(at.x + spec[3]), -(HEAD_H + Px(at.y + spec[4])))
				key.width = Size(spec[5])
				key.frame:SetSize(key.width, Size(spec[6]))
				FitKey(key)
				-- the wheel and the thumb buttons sit on the mouse's big buttons
				key.frame:SetFrameLevel(self.board:GetFrameLevel() + (spec[7] and 2 or 4))
				onModel[spec[1]] = true
			end
		end
		if not isPad then
			onModel.MOUSEBUTTON1, onModel.MOUSEBUTTON2, onModel.MOUSEBUTTON3 = true, true, true
			onModel.MOUSEBUTTON4, onModel.MOUSEBUTTON5 = true, true
		end
		self.extra, self.otherKeys = ExtraKeys(onModel, self.found, device)

		-- the groups under the models, flowing across the board
		local y = HEAD_H + Px(heightUnits) + 14
		local left, right = PAD, width - PAD
		local function Flow(label, tokens)
			label:SetShown(#tokens > 0)
			if #tokens == 0 then return end
			label:ClearAllPoints()
			label:SetPoint("TOPLEFT", self.board, "TOPLEFT", left, -y)
			local kx, ky = left, y + GROUP_LABEL_H
			for _, token in ipairs(tokens) do
				local key = self:TakeKey()
				key.token = token
				local n = token:match("^BUTTON(%d+)$")
				key.legendText = n and ("M" .. n) or (token:find("^PAD") and PadLegend(token, style, nil, isPad and PadDevice() or nil)) or token
				key.secondText = ""
				local keyWidth = max(unit, min(unit * 3, floor((#key.legendText * 7) + 10)))
				if kx > left and kx + keyWidth > right then kx, ky = left, ky + unit + GAP end
				key.frame:ClearAllPoints()
				key.frame:SetPoint("TOPLEFT", self.board, "TOPLEFT", kx, -ky)
				key.width = keyWidth
				key.frame:SetSize(keyWidth, unit)
				FitKey(key)
				key.frame:SetFrameLevel(self.board:GetFrameLevel() + 4)
				kx = kx + keyWidth + GAP
			end
			y = ky + unit + 12
		end
		self.labels[1]:SetText(isPad and L["More controller buttons"] or L["More mouse buttons"])
		Flow(self.labels[1], self.extra)
		Flow(self.labels[2], self.otherKeys)
		return y + PAD - 12
	end

	function control:Measure(width)
		self.width = width or self.width
		local boardHeight = self:Place(self.width)
		self:Fill()
		self.board:SetHeight(boardHeight)
		self.height = 2 + boardHeight + 14
		self.frame:SetHeight(self.height)
		RefreshCard()
		return self.height
	end

	function control:GetHeight() return self.height end
	function control:SetLabel() end
	function control:SetCallback() end
	function control:SetOnRevert() end
	function control:SetModified() end

	-- Reads every placed key's binding and abbreviation.
	function control:Fill()
		local kb = Keybinds()
		if not kb then return end
		for _, key in ipairs(self.keys) do
			local token = key.token
			local full = FullKey(token)
			key.buttons, key.command, key.label = nil, nil, nil
			if token and not MODIFIERS[token] then
				key.buttons = self.bound[full]
				local ok, command = pcall(GetBindingAction, full, true)
				if ok and command and command ~= "" and addon:IsValueAccessible(command) then
					key.command = command
					key.label = kb:GetCommandLabel(command)
				end
			end
			key.shownText = key.buttons and kb:Abbreviate(full) or ""
			FitKey(key)
			key.tint = kb.GetModifierColor and kb:GetModifierColor(full) or nil
			key.dot:SetShown(token and HasCustom(token) or false)
		end
	end

	-- Reads the bindings and abbreviations again.
	function control:Update()
		local kb = Keybinds()
		if not kb then return end
		self.bound = kb.GetBoundButtons and kb:GetBoundButtons() or {}
		local isPad = Device() == "controller"
		local held = {}
		for _, mod in ipairs({ "ALT", "CTRL", "SHIFT" }) do
			if ModOn(mod) then held[#held + 1] = mod end
		end
		self.layer:SetText(#held > 0 and string.format(L["SHOWING THE %s LAYER  ·  click a key to change its abbreviation"], table.concat(held, " + "))
			or (isPad and L["NO MODIFIER  ·  click Shift, Ctrl or Alt to see that layer, or any button to change its abbreviation"]
				or L["NO MODIFIER  ·  click Shift, Ctrl or Alt to see that layer, or any key to change its abbreviation"]))
		self.picker:SetLabel(isPad and (Settings().padDevice and PadDevice().name or (L["Automatic"] .. ": " .. PadDevice().name))
			or LAYOUTS[LayoutKey()].name)
		for _, latch in ipairs(self.latches) do latch:SetShown(isPad) end
		self.layer:ClearAllPoints()
		self.layer:SetPoint("TOPLEFT", self.board, "TOPLEFT", PAD, -42)
		self.layer:SetPoint("RIGHT", isPad and self.latches[1] or self.board, isPad and "LEFT" or "RIGHT", isPad and -12 or -PAD, 0)
		self:Measure(self.width)
		self:Restyle()
		if self.frame:IsVisible() then Keyboard:SetDocked(true) end
	end

	function control:Restyle()
		self.round:SetFill(Kit.InsetColor)
		self.round:SetEdge(Kit.BorderIdle)
		for _, body in pairs(self.bodies) do
			body.surface:SetFill(Kit.WindowColor)
			body.surface:SetEdge(Kit.BorderIdle)
			if body.detail then body.detail:SetVertexColor(unpack(Kit.InsetColor)) end
		end
		self.layer:SetTextColor(unpack(Kit.TextSelected))
		local device = Device()
		for _, button in ipairs({ self.find, self.picker, self.tabKeyboard, self.tabController }) do button:Restyle() end
		-- the open tab and the latched modifiers read as pressed keys
		for _, tab in ipairs({ self.tabKeyboard, self.tabController }) do
			if tab.device == device then
				tab.backdrop:SetBackdropColor(unpack(Kit.InsetColor))
				Kit.SetBorderColor(tab.backdrop, Kit.BorderFocus)
			end
		end
		for _, latch in ipairs(self.latches) do
			latch:Restyle()
			if ModOn(latch.mod) then
				local accent = Kit.TextSelected
				latch.backdrop:SetBackdropColor(accent[1] * .55, accent[2] * .55, accent[3] * .55, 1)
				Kit.SetBorderColor(latch.backdrop, Kit.BorderFocus)
			end
		end
		for _, label in ipairs(self.labels) do label:SetTextColor(unpack(Kit.TextDisabled)) end
		for _, key in ipairs(self.keys) do StyleKey(key) end
		local card = self.card
		card.eyebrow:SetTextColor(unpack(Kit.TextSelected))
		card.hint:SetTextColor(unpack(Kit.TextNormal))
		card.title:SetTextColor(unpack(Kit.TextHighlight))
		card.shownAs:SetTextColor(unpack(Kit.TextNormal))
		card.heading:SetTextColor(unpack(Kit.TextSelected))
		for _, line in ipairs(card.lines) do line.text:SetTextColor(unpack(Kit.TextNormal)) end
		card.input:Restyle()
		card.bind:Restyle()
		card.unbind:Restyle()
		card.keybound:Restyle()
		if slice then
			slice.round:SetFill(Kit.WindowColor)
			slice.round:SetEdge(Kit.EdgeColor)
		end
	end

	control.card = CreateCard(UIParent)

	-- A latch for a modifier, the card for anything else.
	Select = function(token)
		if MODIFIERS[token] then control.mods[token] = not control.mods[token] end
		control.selected = token
		control:Update()
		Relayout()
	end

	-- What you hold while the page is open: a held Shift, Ctrl or Alt shows that
	-- layer, as a latched one does, and a key you press lights up. The listener
	-- hands every key on to the game, so you can still move and play; it stops in
	-- combat, where the game will not let an addon pass keys on.
	control.held = { SHIFT = false, CTRL = false, ALT = false }
	control.pressed = {}
	local listener = CreateFrame("Frame", nil, frame)
	control.listener = listener
	listener.elapsed = 0
	listener:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + (elapsed or 0)
		if self.elapsed < .05 then return end
		self.elapsed = 0
		local now = {
			SHIFT = IsShiftKeyDown and IsShiftKeyDown() and true or false,
			CTRL = IsControlKeyDown and IsControlKeyDown() and true or false,
			ALT = IsAltKeyDown and IsAltKeyDown() and true or false,
		}
		local was = control.held
		if now.SHIFT ~= was.SHIFT or now.CTRL ~= was.CTRL or now.ALT ~= was.ALT then
			control.held = now
			control:Update()
		end
	end)
	local function Press(key, down)
		local token = type(key) == "string" and (SIDED[key] or key)
		if not token or MODIFIERS[token] then return end
		control.pressed[token] = down or nil
		for _, k in ipairs(control.keys) do
			if k.token == token then StyleKey(k) end
		end
	end
	listener:SetScript("OnKeyDown", function(_, key) Press(key, true) end)
	listener:SetScript("OnKeyUp", function(_, key) Press(key, false) end)
	local function Listen(on)
		if on and InCombatLockdown and InCombatLockdown() then on = false end
		if not on then
			wipe(control.pressed)
			control.held = { SHIFT = false, CTRL = false, ALT = false }
		end
		listener:SetShown(on)
		if listener.EnableKeyboard then listener:EnableKeyboard(on) end
		if on and listener.SetPropagateKeyboardInput then listener:SetPropagateKeyboardInput(true) end
	end
	control.Listen = Listen
	local events = CreateFrame("Frame", nil, frame)
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript("OnEvent", function(_, event)
		Listen(event == "PLAYER_REGEN_ENABLED" and frame:IsVisible())
	end)

	-- the slice follows the keyboard: shown with the Abbreviations page, gone with it
	frame:SetScript("OnShow", function() Keyboard:SetDocked(true); Listen(true) end)
	frame:SetScript("OnHide", function() Keyboard:SetDocked(false); Listen(false) end)
	return control
end

function Keyboard:GetControl(parent)
	return control or Build(parent)
end

function Keyboard:Restyle()
	if control then control:Restyle() end
end

-- Shows or hides the key's card beside the window.
function Keyboard:SetDocked(shown)
	if not control then return end
	if not shown then
		if slice then slice:Hide() end
		if Controls.CloseDropdown then Controls.CloseDropdown() end
		return
	end
	if not slice then BuildSlice() end
	local card = control.card
	card.frame:SetParent(slice.child)
	card.frame:ClearAllPoints()
	card.frame:SetPoint("TOPLEFT", slice.child, "TOPLEFT", 0, 0)
	Dock()
	slice:Show()
	RefreshCard()
	control:Restyle()
end

-- Puts the slice on the side of the window with room, after it moved or resized.
function Keyboard:Redock()
	if slice and slice:IsShown() then Dock() end
end

-- Selects `token` as if its key was clicked (a modifier latches).
function Keyboard:Select(token)
	if control and token then Select(token) end
end

-- The layouts and controller styles, for the tests and anything that lists them.
Keyboard.Layouts, Keyboard.PadStyles, Keyboard.PadDevices = LAYOUTS, PAD_STYLES, PAD_DEVICES
