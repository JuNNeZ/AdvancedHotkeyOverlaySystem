---@diagnostic disable: undefined-global
-- modules/DisplayShared.lua - what the Display files share.
--
-- The overlay engine is four files: this one (state and helpers), Display.lua (the
-- update flow), DisplayNative.lua (the buttons' own hotkey labels) and
-- DisplayStyle.lua (how an overlay looks). They share their state and helpers
-- through privateScope.DisplayShared, which this file fills and the others read.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSDisplay
local Display = addon.Display

local overlayPool = {}

local activeOverlays = {}

local originalHotkeyTexts = {} -- Store original Blizzard hotkey text by button name

local squelchedByButton = {}    -- Track buttons currently squelched

local hookedHotkeyRegions = {}   -- Track fontstrings we have hooksecurefunc'ed

local guardSetText = setmetatable({}, { __mode = "k" }) -- Re-entrancy guard per FontString

local nativeRewriteButtons = {}  -- Per-button flag when we actively rewrite native FS

local providerHotkeyHooks = setmetatable({}, { __mode = "k" })

local providerHotkeyRefreshPending = setmetatable({}, { __mode = "k" })

local buttonVisibilityHooks = setmetatable({}, { __mode = "k" })

local visibilityRecoveryDelays = { 0, 0.05, 0.2, 0.5, 1.0 }

local buttonUpdateGeneration = {}

-- Mainline engine: Retail and WoW Forever (see DetectClient in the core file)
local isRetail = addon.IsMainlineClient

local function GetSafeFrameValue(frame, methodName, ...)
    if not frame then return nil end
    local methodOk, method = pcall(function() return frame[methodName] end)
    if not methodOk or type(method) ~= "function" then return nil end
    local ok, value = pcall(method, frame, ...)
    if ok and addon:IsValueAccessible(value) then return value end
    return nil
end

local function GetSafeName(object)
    local name = GetSafeFrameValue(object, "GetName")
    return type(name) == "string" and name ~= "" and name or nil
end

local function GetSafeText(fontString)
    local text = GetSafeFrameValue(fontString, "GetText")
    return type(text) == "string" and text or nil
end

local function GetSafeObjects(frame, methodName)
    if not frame then return {} end
    local methodOk, method = pcall(function() return frame[methodName] end)
    if not methodOk or type(method) ~= "function" then return {} end
    local values = { pcall(method, frame) }
    local ok = table.remove(values, 1)
    if not ok then return {} end

    local accessible = {}
    for _, value in ipairs(values) do
        if addon:IsValueAccessible(value) then
            accessible[#accessible + 1] = value
        end
    end
    return accessible
end

local function GetSafeNumber(frame, methodName, fallback)
    local value = GetSafeFrameValue(frame, methodName)
    return type(value) == "number" and value or (fallback or 0)
end

local function IsOverlayRenderingEnabled()
    local profile = addon and addon.db and addon.db.profile
    if not profile or not profile.enabled then return false end
    if addon.ShouldShowOverlays and not addon:ShouldShowOverlays() then return false end
    return true
end

local function RefreshNativeHotkey(button)
    if not button then return false end
    local name = GetSafeName(button)
    local provider = name and addon.GetProviderForButtonName and addon:GetProviderForButtonName(name)
    local methodNames = provider and provider.hotkey_update_methods
    if not methodNames then
        methodNames = provider and provider.hotkey_update_method and { provider.hotkey_update_method }
            or { "UpdateHotkeys", "SetHotkeys" }
    end
    -- Blizzard's UpdateHotkeys(actionButtonType) reads "ACTIONBUTTON" .. id when it
    -- is given no type, so a bottom-right bar button would show the main bar's key.
    -- Blizzard passes the button's own buttonType; so must we.
    local typeOk, buttonType = pcall(function() return button.buttonType end)
    if not typeOk or type(buttonType) ~= "string" or not addon:IsValueAccessible(buttonType) then buttonType = nil end

    for _, methodName in ipairs(methodNames) do
        local methodOk, method = pcall(function() return button[methodName] end)
        if methodOk and type(method) == "function" then
            local ok = pcall(method, button, buttonType)
            if ok then return true end
        end
    end
    return false
end

-- The button's own hotkey label: HotKey on Blizzard's template, a field the bar
-- addon names (Neuron's Hotkey), or the global <name>HotKey.
local function NativeHotkeyRegion(button, buttonName)
    if not button then return nil end
    local ok, region = pcall(function() return button.HotKey end)
    if ok and type(region) == "table" then return region end
    local provider = buttonName and addon:GetProviderForButtonName(buttonName)
    for _, field in ipairs(provider and provider.hotkey_fields or {}) do
        local found, value = pcall(function() return button[field] end)
        if found and type(value) == "table" then return value end
    end
    return buttonName and _G[buttonName .. "HotKey"] or nil
end

local IsFallbackHotkeyGlyph

-- The text a button's own label would show for its key, worked out without the
-- button's help: what the button says it shows, then the game's short key text.
-- On the first login a bar can be drawn before its label was ever filled, so
-- there is no original to put back; this is what stands in for it.
local function DerivedNativeText(button)
    local getHotkey = GetSafeFrameValue(button, "GetHotkey")
    if type(getHotkey) == "string" and getHotkey ~= "" and not IsFallbackHotkeyGlyph(getHotkey) then return getHotkey end
    if addon.Keybinds and addon.Keybinds.GetFullBindingText then
        local ok, full = pcall(addon.Keybinds.GetFullBindingText, addon.Keybinds, button)
        if ok and type(full) == "string" and full ~= "" and addon:IsValueAccessible(full) then
            local okText, short = pcall(GetBindingText, full, 1)
            if okText and type(short) == "string" and short ~= "" and addon:IsValueAccessible(short) then return short end
            return full
        end
    end
    return nil
end
Display.DerivedNativeText = DerivedNativeText

local strataOrder = {
    BACKGROUND = 1,
    LOW = 2,
    MEDIUM = 3,
    HIGH = 4,
    DIALOG = 5,
    FULLSCREEN = 6,
    FULLSCREEN_DIALOG = 7,
    TOOLTIP = 8,
}

local function NormalizeStrata(strata, fallback)
    local value = type(strata) == "string" and string.upper(strata) or nil
    if value and strataOrder[value] then
        return value
    end
    local fallbackValue = type(fallback) == "string" and string.upper(fallback) or "MEDIUM"
    if strataOrder[fallbackValue] then
        return fallbackValue
    end
    return "MEDIUM"
end

local function GetStrataRank(strata)
    return strataOrder[NormalizeStrata(strata, "MEDIUM")] or strataOrder.MEDIUM
end

local function GetOverlayFromPool(parent)
    local overlay = table.remove(overlayPool)
    if not overlay then
        overlay = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        -- AHOS's own: the search for a button's hotkey label must never take it
        -- for one (with the text in the top-right corner it would, and blank it).
        overlay._ahosOverlay = true
        overlay.text = overlay:CreateFontString(nil, "OVERLAY")
        overlay.text._ahosOwn = true
        overlay:SetFrameLevel(GetSafeNumber(parent, "GetFrameLevel", 0) + 5)
    if overlay.EnableMouse then overlay:EnableMouse(false) end
    end
    overlay._ahosInPool = nil
    overlay:SetParent(parent)
    overlay:Show()
    return overlay
end

local function ReleaseOverlayToPool(overlay)
    if not overlay or overlay._ahosInPool then return end
    overlay._ahosInPool = true
    -- Drop the label so a reused frame can never flash the previous button's bind.
    if overlay.text and overlay.text.SetText then overlay.text:SetText("") end
    if overlay.flash then overlay.flash:Hide() end
    if overlay.glow then overlay.glow:SetText(""); overlay.glow:Hide() end
    if overlay.bg then overlay.bg:Hide() end
    if addon.Visibility and addon.Visibility.Untrack then addon.Visibility:Untrack(overlay) end
    if addon.Editor and addon.Editor.Undecorate then addon.Editor:Undecorate(overlay) end
    overlay:Hide()
    overlay:ClearAllPoints()
    overlay:SetParent(UIParent) -- Reparent to avoid being destroyed with parent
    table.insert(overlayPool, overlay)
end

local function RemoveOverlayFromPool(overlay)
    if not overlay or not overlay._ahosInPool then return end
    for index = #overlayPool, 1, -1 do
        if overlayPool[index] == overlay then
            table.remove(overlayPool, index)
            break
        end
    end
    overlay._ahosInPool = nil
end

-- Helper: Returns true if the text is a Blizzard fallback glyph for unbound keys
-- Text without colour codes, to compare a native label with AHOS's own text.
local function PlainText(text)
    if type(text) ~= "string" then return text end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- The text AHOS writes into a native hotkey label: coloured by its modifier when
-- that is on. A colour code rather than SetTextColor, so nothing is left on the
-- label when it gets its own text back.
local function NativeText(button, text)
    local color = addon.Keybinds and addon.Keybinds.GetButtonModifierColor and addon.Keybinds:GetButtonModifierColor(button)
    if not color or type(text) ~= "string" or text == "" then return text end
    return string.format("|cff%02x%02x%02x%s|r", math.floor((color[1] or 1) * 255 + .5),
        math.floor((color[2] or 1) * 255 + .5), math.floor((color[3] or 1) * 255 + .5), text)
end

function IsFallbackHotkeyGlyph(text)
    if not addon:IsValueAccessible(text) or not text or text == "" then return false end
    -- Common placeholders across locales/skins: bullet, squares, replacement char
    return text == "●" or text == "\226\151\136" -- bullet
        or text == "■" -- black square
        or text == "□" -- white square
        or text == "◼" -- black medium square
        or text == "◻" -- white medium square
        or text == "�" -- replacement character
end

-- Taint-safe anchor check used by hotkey region heuristics.
-- Some protected regions can return secure/secret strings for points.
local function IsTopRightAnchor(region)
    if not region or not region.GetPoint then return false end
    local ok, p1, _, p2 = pcall(region.GetPoint, region, 1)
    if not ok then return false end
    if not addon:IsValueAccessible(p1) or not addon:IsValueAccessible(p2) then return false end
    return p1 == "TOPRIGHT" or p2 == "TOPRIGHT"
end

-- Recursively scan a frame and its children for FontStrings that likely represent hotkey labels.
-- This helps when UIs (e.g., AzeriteUI) wrap the hotkey text in a nested container such as
-- ButtonName.TextOverlayContainer.
local function DeepCollectHotkeyFontStrings(frame, button, out, depth, maxDepth)
    if not frame or not frame.GetObjectType then return end
    if depth > (maxDepth or 3) then return end
    -- Collect any FontString children that look like hotkey/keybind text
    if frame.GetRegions then
        for _, region in ipairs(GetSafeObjects(frame, "GetRegions")) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" and not rawget(region, "_ahosOwn") then
                local rname = GetSafeName(region) or ""
                local match = (rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")))
                if not match then
                    -- Heuristics: top-right anchored, small-ish font size, short text
                    if IsTopRightAnchor(region) then
                        match = true
                    end
                end
                if match then table.insert(out, region) end
            end
        end
    end
    -- Recurse into child frames (TextOverlayContainer, OverlayFrame, etc.)
    if frame.GetChildren then
        for _, child in ipairs(GetSafeObjects(frame, "GetChildren")) do
            -- AHOS's own overlays are not the button's label
            if child and child ~= frame and child.GetObjectType and not rawget(child, "_ahosOverlay") then
                local ctype = child:GetObjectType()
                if ctype == "Frame" or ctype == "Button" or ctype == "Region" then
                    DeepCollectHotkeyFontStrings(child, button, out, depth + 1, maxDepth)
                end
            end
        end
    end
end

-- Everything the other Display files use. overlayEpoch counts ClearAllOverlays (a
-- timer from before it does nothing), restoringNativeHotkeys is set while labels
-- are put back.
---@class AHOSDisplayShared
local S = {
    overlayEpoch = 0,
    restoringNativeHotkeys = false,
    overlayPool = overlayPool,
    activeOverlays = activeOverlays,
    originalHotkeyTexts = originalHotkeyTexts,
    squelchedByButton = squelchedByButton,
    hookedHotkeyRegions = hookedHotkeyRegions,
    guardSetText = guardSetText,
    nativeRewriteButtons = nativeRewriteButtons,
    providerHotkeyHooks = providerHotkeyHooks,
    providerHotkeyRefreshPending = providerHotkeyRefreshPending,
    buttonVisibilityHooks = buttonVisibilityHooks,
    visibilityRecoveryDelays = visibilityRecoveryDelays,
    buttonUpdateGeneration = buttonUpdateGeneration,
    isRetail = isRetail,
    GetSafeFrameValue = GetSafeFrameValue,
    GetSafeName = GetSafeName,
    GetSafeText = GetSafeText,
    GetSafeObjects = GetSafeObjects,
    GetSafeNumber = GetSafeNumber,
    IsOverlayRenderingEnabled = IsOverlayRenderingEnabled,
    RefreshNativeHotkey = RefreshNativeHotkey,
    NativeHotkeyRegion = NativeHotkeyRegion,
    IsFallbackHotkeyGlyph = IsFallbackHotkeyGlyph,
    DerivedNativeText = DerivedNativeText,
    strataOrder = strataOrder,
    NormalizeStrata = NormalizeStrata,
    GetStrataRank = GetStrataRank,
    GetOverlayFromPool = GetOverlayFromPool,
    ReleaseOverlayToPool = ReleaseOverlayToPool,
    RemoveOverlayFromPool = RemoveOverlayFromPool,
    PlainText = PlainText,
    NativeText = NativeText,
    IsTopRightAnchor = IsTopRightAnchor,
    DeepCollectHotkeyFontStrings = DeepCollectHotkeyFontStrings,
}
privateScope.DisplayShared = S
