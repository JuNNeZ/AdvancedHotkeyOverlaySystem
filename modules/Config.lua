---@diagnostic disable: undefined-global
-- modules/Config.lua - the default profile and the fonts.
--
-- The shipped settings (GetDefaultProfile, which AceDB and the options window's
-- "changed from default" marks both read) and the font list, with every font that
-- will not load left out. Which bar addon AHOS draws on is DetectUI's, in the core file.

local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSConfig
local Config = addon.Config

-- Font path fix
local DEFAULT_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local LibSharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Whether the client can load a font file. LibSharedMedia lists whatever other
-- addons registered, and a path that does not load leaves the hotkey text in its
-- old font, or with none at all. Each file is tried once on a fresh font object,
-- which has no font until one loads, so GetFont answers for that file alone.
local fontLoads, probeCount = {}, 0
local function FontLoads(path)
    if type(path) ~= "string" or path == "" then return false end
    if fontLoads[path] ~= nil then return fontLoads[path] end
    if not CreateFont then return true end
    probeCount = probeCount + 1
    local probe = CreateFont("AHOSFontProbe" .. probeCount)
    local ok = pcall(probe.SetFont, probe, path, 12, "")
    local loaded = ok and probe:GetFont() ~= nil
    fontLoads[path] = loaded and true or false
    return fontLoads[path]
end
Config.FontLoads = FontLoads

-- Built once and kept: every overlay asks for its font path each time it is
-- styled, and the list walks every font LibSharedMedia knows. A font registered
-- later (an addon loading on demand) clears it.
local availableFonts
if LibSharedMedia and LibSharedMedia.RegisterCallback then
    LibSharedMedia.RegisterCallback(Config, "LibSharedMedia_Registered", function(_, mediaType)
        if mediaType == "font" then availableFonts = nil end
    end)
end

---@return table<string, string> name -> file
function Config:GetAvailableFonts()
    if availableFonts then return availableFonts end
    local fonts = {
        ["Default"] = DEFAULT_FONT,
        ["FrizQT"] = "Fonts\\FRIZQT__.TTF",
        ["ArialN"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
    }
    if LibSharedMedia then
        for name, path in pairs(LibSharedMedia:HashTable("font")) do
            if FontLoads(path) then fonts[name] = path end
        end
    end
    availableFonts = fonts
    return fonts
end

---@return string[]
function Config:GetFontList()
    local fonts = self:GetAvailableFonts()
    local list = {}
    for k, _ in pairs(fonts) do list[#list+1] = k end
    table.sort(list)
    return list
end

---@param name string
---@return string
function Config:GetFontPath(name)
    return self:GetAvailableFonts()[name] or DEFAULT_FONT
end

-- A Cyrillic, Korean or Chinese key name (a Russian board's Й) has no letters in a
-- Latin font, so it would draw as boxes. The game ships a face for each on every
-- client; text with such letters is drawn in it. Decided by the UTF-8 lead bytes:
-- Cyrillic is U+0400-04FF (D0-D3), Hangul syllables U+AC00-D7A3 (EA-ED), Hangul
-- letters and Bopomofo U+3100-318F (E3 84-86), CJK ideographs U+4E00-9FFF (E4 B8 - E9).
local SCRIPT_FONT_FILES = {
    russian = "Fonts\\FRIZQT___CYR.TTF",
    korean = "Fonts\\2002.TTF",
    simplifiedchinese = "Fonts\\ARKai_T.ttf",
    traditionalchinese = "Fonts\\blei00d.TTF",
}
Config.ScriptFontFiles = SCRIPT_FONT_FILES

local function Script(text)
    if type(text) ~= "string" or not text:find("[\128-\255]") then return nil end
    local plain = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    if plain:find("[\208-\211][\128-\191]") then return "russian" end
    if plain:find("[\234-\237][\128-\191][\128-\191]") then return "korean" end
    if plain:find("\227[\132-\134][\128-\191]") then
        -- Bopomofo (U+3100-312F) is Taiwan's; the rest of the block is Hangul letters
        if plain:find("\227\132[\128-\175]") then return "traditionalchinese" end
        return "korean"
    end
    if plain:find("\228[\184-\191][\128-\191]") or plain:find("[\229-\233][\128-\191][\128-\191]") then
        return (GetLocale and GetLocale() == "zhTW") and "traditionalchinese" or "simplifiedchinese"
    end
    return nil
end

---@param text string
---@return string|nil file
function Config:GetScriptFont(text)
    local script = Script(text)
    local file = script and SCRIPT_FONT_FILES[script]
    if file and FontLoads(file) then return file end
    return nil
end

---@return AHOSProfile
function Config:GetDefaultProfile()
    return {
        enabled = true,
        autoDetectUI = true,
        display = {
            strata = "HIGH",            anchor = "TOP",
            xOffset = -22,
            yOffset = -3,
            scale = 0.95,
            alpha = 1,
            hideOriginal = true,
            smartPositioning = true,
            border = "none",
            borderColor = {0,0,0,1},
            borderSize = 1,
            locked = false,
            -- Overlay vs native text behavior
            nativeRewrite = false,         -- Global: rewrite native hotkey FS instead of overlay
            dominosRewrite = false,        -- Dominos-only override for rewrite (overlay is default)
            autoNativeFallback = true,     -- If overlay seems hidden, auto-fallback to native per-button
            followNativeHotkeyStyle = false, -- Let overlay mirror native hotkey font/positioning
            followMasque = false,          -- Put the text where a Masque skin puts the hotkey
            smartStrata = false,           -- Opt-in: keep overlays in the parent button layer
            frameLevel = 10,               -- Base overlay frame level (fine-tune in Options)
            -- A plate behind the text, sized to it.
            background = { enabled = false, color = {0, 0, 0, 0.55}, padding = 2 },
            -- What the text does when its button is pressed: none, flash or pulse.
            pressAnimation = "none",
            pressColor = {1, 0.82, 0.2},
        },
        -- When the text is shown. Every condition must agree for it to show; when one
        -- does not, the text fades to fadedAlpha. Bars can also ask for mouseover
        -- (profile.bars[key].mouseover).
        visibility = {
            fadeOutOfCombat = false,
            modifierOnly = false,
            fadedAlpha = 0,
            fadeDuration = 0.25,
            condition = "",               -- a Lua expression; see modules/Visibility.lua
            combatStyle = { enabled = false, color = {1, 0.35, 0.3}, scale = 1.15 },
        },
        text = {
            fontSize = 16,
            font = "Default",
            color = {1, 1, 1},
            shadowEnabled = true,
            shadowOffset = {1, -1},
            shadowColor = {0, 0, 0, 1},
            -- a soft halo in its own colour behind the text
            glow = { enabled = false, color = {1, 0.82, 0.2, 0.8} },
            mouseIcons = false,           -- draw mouse buttons and the wheel as small icons
            showAllBindings = false,      -- a button bound to two keys shows both
            bindingSeparator = "/",
            abbreviations = true,
            maxLength = 6,
            modSeparator = "",
            customAbbreviations = {},
            outline = true,               -- legacy boolean
            outlineStyle = "OUTLINE",    -- new style flags (NONE, OUTLINE, THICKOUTLINE, MONOCHROME, MONOCHROME,OUTLINE, MONOCHROME,THICKOUTLINE)
            gamepadIcons = true,          -- draw gamepad buttons as the controller's own glyphs
            gamepadIconStyle = "auto",    -- auto (the controller in use), xbox, ps, switch or generic
            -- Colour the text by its modifier, so Shift, Ctrl and Alt read at a glance.
            -- "multi" is any binding with more than one modifier.
            modifierColors = {
                enabled = false,
                hideModifiers = false,   -- drop the modifier letters and let the colour say it
                shift = {0.36, 0.74, 1},
                ctrl = {1, 0.82, 0.2},
                alt = {0.55, 1, 0.45},
                multi = {1, 0.5, 0.86},
            },
        },
        minimap = { hide = false },
        bars = {},
        buttons = {},                     -- per button: { hide = true } leaves it alone
        performance = {},
        debug = false,
        troubleshootingTools = false,
    }
end

function Config:GetDynamicDefaults()
    local defaults = {
        profile = self:GetDefaultProfile(),
        -- Copies of profiles to go back to (modules/Profiles.lua), across characters.
        global = { snapshots = {} },
        -- Switching profile with the specialization or talent loadout is a choice per
        -- character: it cannot live in the profile it switches away from.
        char = { autoSwitch = "off" },
    }
    -- UI detection will be set after PLAYER_LOGIN
    return defaults
end

-- The bar addon AHOS is drawing on.
function Config:GetDetectedUI()
    return addon.detectedUI or "Blizzard"
end
