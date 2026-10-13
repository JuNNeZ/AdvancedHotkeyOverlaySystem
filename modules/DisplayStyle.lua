---@diagnostic disable: undefined-global
-- modules/DisplayStyle.lua - how an overlay looks.
--
-- Font, colour, shadow, glow, plate, anchor (the profile's, a bar's own, or a
-- Masque skin's), scale, alpha and layering; the flash when a setting changes.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSDisplay
local Display = addon.Display
local S = privateScope.DisplayShared
local activeOverlays, GetSafeFrameValue, GetSafeName, GetSafeText = S.activeOverlays, S.GetSafeFrameValue, S.GetSafeName, S.GetSafeText
local GetSafeObjects, GetSafeNumber, IsOverlayRenderingEnabled, NormalizeStrata = S.GetSafeObjects, S.GetSafeNumber, S.IsOverlayRenderingEnabled, S.NormalizeStrata
local GetStrataRank, NativeHotkeyRegion = S.GetStrataRank, S.NativeHotkeyRegion

-- The scale an overlay is drawn at: the profile's, the bar's own, and the combat
-- style's while in combat.
---@param parent Button
---@param db table the profile
---@return number
function Display:GetOverlayScale(parent, db)
    local barScale = addon.Bars.GetBarScale and addon.Bars:GetBarScale(GetSafeName(parent)) or 1
    local combatStyle = addon.Visibility and addon.Visibility.GetCombatStyle and addon.Visibility:GetCombatStyle()
    local combatScale = combatStyle and tonumber(combatStyle.scale) or 1
    local scale = (tonumber(db.display.scale) or 1) * barScale * combatScale
    return scale > 0 and scale or 1
end

-- Where Masque put this button's hotkey label. Masque keeps a skinned button's
-- config on it as _MSQ_CFG (whether it is skinned, the skin, the regions it anchors
-- to, its scale) and places the label each time it skins. A skin seldom spells out
-- every field of its HotKey (Masque fills the rest from its defaults), so the label
-- itself is read first: wherever Masque left it is the skin's answer. The skin's
-- own HotKey table is only the fallback, for a label that has no point yet. Masque
-- places the label but leaves its font alone, so only the place, width and
-- justification are taken; the font stays AHOS's. Nil for a button Masque does not skin.
local function Readable(...)
    for i = 1, select("#", ...) do
        if not addon:IsValueAccessible((select(i, ...))) then return false end
    end
    return true
end

---@param button Button
---@return AHOSMasqueLayout|nil
function Display:GetMasqueHotKeyLayout(button)
    local ok, cfg = pcall(function() return button._MSQ_CFG end)
    if not ok or type(cfg) ~= "table" or not cfg.Enabled then return nil end

    -- the label, as Masque placed it
    local region = NativeHotkeyRegion(button, GetSafeName(button))
    if region and GetSafeNumber(region, "GetNumPoints", 0) > 0 then
        local got, point, relTo, relPoint, x, y = pcall(region.GetPoint, region, 1)
        if got and Readable(point, relTo, relPoint, x, y) and type(point) == "string" then
            local width = GetSafeNumber(region, "GetWidth", 0)
            local justifyH = GetSafeFrameValue(region, "GetJustifyH")
            local justifyV = GetSafeFrameValue(region, "GetJustifyV")
            return {
                point = point,
                relPoint = type(relPoint) == "string" and relPoint or point,
                x = tonumber(x) or 0,
                y = tonumber(y) or 0,
                width = width > 0 and width or 0,
                justifyH = type(justifyH) == "string" and justifyH or nil,
                justifyV = type(justifyV) == "string" and justifyV or nil,
                anchor = type(relTo) == "table" and relTo or button,
            }
        end
    end

    -- the skin's own numbers
    local hotkey = type(cfg.Skin) == "table" and cfg.Skin.HotKey
    if type(hotkey) == "table" and type(cfg.GetTypeSkin) == "function" then
        local typed, typeSkin = pcall(cfg.GetTypeSkin, cfg, button, hotkey)
        if typed and type(typeSkin) == "table" then hotkey = typeSkin end
    end
    if type(hotkey) ~= "table" then return nil end
    local anchor = button
    if hotkey.Anchor and type(cfg.Regions) == "table" and type(cfg.Regions[hotkey.Anchor]) == "table" then
        anchor = cfg.Regions[hotkey.Anchor]
    end
    local xScale = 1
    if type(cfg.GetScale) == "function" then
        local scaled, xs = pcall(cfg.GetScale, cfg)
        if scaled and type(xs) == "number" and xs > 0 then xScale = xs end
    end
    local point = type(hotkey.Point) == "string" and hotkey.Point or "TOPRIGHT"
    return {
        point = point,
        relPoint = type(hotkey.RelPoint) == "string" and hotkey.RelPoint or point,
        x = tonumber(hotkey.OffsetX) or 0,
        y = tonumber(hotkey.OffsetY) or 0,
        width = (tonumber(hotkey.Width) or 0) * xScale,
        justifyH = type(hotkey.JustifyH) == "string" and hotkey.JustifyH or nil,
        justifyV = type(hotkey.JustifyV) == "string" and hotkey.JustifyV or nil,
        anchor = anchor,
    }
end

---@param overlay AHOSOverlay
---@param parent Button
---@param text string
function Display:StyleOverlay(overlay, parent, text)
    if not addon:IsReady() then return end
    if not addon.db or not addon.db.profile then return end
    if not addon:IsValueAccessible(text) then return end
    local db = addon.db.profile
    local smartStrata = self:UseSmartStrata()

    -- Sizing and Positioning
    overlay:SetAllPoints(parent)

    -- Decide whether to mirror native hotkey style (Dominos/Masque) or use configured style
    -- Opt-in to mirror native style; default is to use configured AHOS styling
    local followNative = (db.display and db.display.followNativeHotkeyStyle == true)
    local usedNative = false
    if followNative then
        local ok, applied = pcall(self.ApplyNativeHotkeyStyle, self, parent, overlay)
        usedNative = ok and applied == true
        if not ok and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Native hotkey style unavailable for " .. (GetSafeName(parent) or "<inaccessible>") .. ": " .. addon:SafeToString(applied, "unknown error"))
        end
    end

    local setFontResult = true
    if not usedNative then
        -- Text Styling (configured)
        local fontName = db.text.font or "Default"
        local fontPath = addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(fontName) or "Fonts\\FRIZQT__.TTF"
        -- a Cyrillic, Korean or Chinese key name is drawn in the game's face for it
        local scriptFont = addon.Config and addon.Config.GetScriptFont and addon.Config:GetScriptFont(text)
        if scriptFont then fontPath = scriptFont end
        -- Outline/flags: prefer outlineStyle; fallback to legacy boolean
        local outline = ""
        if db.text.outlineStyle and db.text.outlineStyle ~= "" then
            outline = db.text.outlineStyle
        elseif db.text.outline ~= nil then
            outline = db.text.outline and "OUTLINE" or "NONE"
        end
    if outline == "NONE" then outline = "" end
    -- Normalize alias flags
    if outline == "MONOCHROMEOUTLINE" then outline = "MONOCHROME,OUTLINE" end
    if outline == "MONOCHROMETHICKOUTLINE" then outline = "MONOCHROME,THICKOUTLINE" end
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] StyleOverlay (configured): font=", fontName, " path=", fontPath, " size=", db.text.fontSize, " outline=", outline)
            end
        setFontResult = overlay.text:SetFont(fontPath, db.text.fontSize, outline)
        -- A saved font that no longer loads (its addon was removed) must not leave
        -- the hotkey without a font: that draws nothing at all.
        if not setFontResult and not overlay.text:GetFont() then
            setFontResult = overlay.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", db.text.fontSize, outline)
        end
        local r,g,b,a = 1,1,1,1
        if db.text.color and type(db.text.color) == "table" then
            r = db.text.color[1] or r
            g = db.text.color[2] or g
            b = db.text.color[3] or b
            a = db.text.color[4] or a
        end
        overlay.text:SetTextColor(r,g,b,a)
        -- Reset justification that may have been inherited while native mirroring was enabled.
        if overlay.text.SetJustifyH then overlay.text:SetJustifyH("CENTER") end
        if overlay.text.SetJustifyV then overlay.text:SetJustifyV("MIDDLE") end
        -- Shadow settings
        if db.text.shadowEnabled then
            local sc = type(db.text.shadowColor) == "table" and db.text.shadowColor or {0, 0, 0, 1}
            overlay.text:SetShadowColor(sc[1] or 0, sc[2] or 0, sc[3] or 0, sc[4] or 1)
            local so = type(db.text.shadowOffset) == "table" and db.text.shadowOffset or {1, -1}
            overlay.text:SetShadowOffset(so[1] or 1, so[2] or -1)
        else
            overlay.text:SetShadowColor(0, 0, 0, 0)
        end
        -- Text Anchoring (configured): a bar with a place of its own wins, then a
        -- Masque skin's place for the hotkey (when asked to follow it), then the profile's.
        local anchor, x, y = db.display.anchor, db.display.xOffset, db.display.yOffset
        local barAnchor
        if addon.Bars.GetBarPosition then
            local barX, barY
            barAnchor, barX, barY = addon.Bars:GetBarPosition(GetSafeName(parent))
            if barAnchor then anchor, x, y = barAnchor, barX, barY end
        end
        local masque = not barAnchor and db.display.followMasque and self:GetMasqueHotKeyLayout(parent)
        overlay.text:ClearAllPoints()
        if masque then
            -- The skin's numbers are in the button's scale; the text is drawn at the
            -- overlay's own scale on top of it.
            local scale = self:GetOverlayScale(parent, db)
            overlay.text:SetPoint(masque.point, masque.anchor, masque.relPoint, masque.x / scale, masque.y / scale)
            if overlay.text.SetWidth then overlay.text:SetWidth(masque.width > 0 and masque.width / scale or 0) end
            if masque.justifyH and overlay.text.SetJustifyH then overlay.text:SetJustifyH(masque.justifyH) end
            if masque.justifyV and overlay.text.SetJustifyV then overlay.text:SetJustifyV(masque.justifyV) end
        else
            if overlay.text.SetWidth then overlay.text:SetWidth(0) end
            overlay.text:SetPoint(anchor, overlay, anchor, x, y)
        end
        -- Ensure overlay text draws above most skin layers
        if overlay.text.SetDrawLayer then
            overlay.text:SetDrawLayer("OVERLAY", 7)
        end
    end

    -- Colour by modifier wins over both the configured and the mirrored colour.
    local modifierColor = addon.Keybinds and addon.Keybinds.GetButtonModifierColor
        and addon.Keybinds:GetButtonModifierColor(parent)
    if modifierColor then
        overlay.text:SetTextColor(modifierColor[1] or 1, modifierColor[2] or 1, modifierColor[3] or 1, 1)
    end
    -- and the combat colour over that, while in combat.
    local combatStyle = addon.Visibility and addon.Visibility.GetCombatStyle and addon.Visibility:GetCombatStyle()
    if combatStyle and type(combatStyle.color) == "table" then
        overlay.text:SetTextColor(combatStyle.color[1] or 1, combatStyle.color[2] or 1, combatStyle.color[3] or 1, 1)
    end

    overlay.text:SetText(text)

    -- Force refresh: hide and show the FontString
    overlay.text:Hide()
    overlay.text:Show()

    self:StyleGlow(overlay, text, db)
    self:StyleBackground(overlay, db)

    if addon.db and addon.db.profile and addon.db.profile.debug then
        local layer = overlay.text.GetDrawLayer and select(1, overlay.text:GetDrawLayer()) or "OVERLAY"
        addon:Print("[AHOS DEBUG] StyleOverlay: usedNative=", tostring(usedNative), " setFont=", tostring(setFontResult), " layer=", tostring(layer), " overlay.text:IsShown()=", tostring(overlay.text:IsShown()), ", overlay:IsShown()=", tostring(overlay:IsShown()))
    end

    -- If we used native styling, we've already mirrored shadow/anchor

    -- Backdrop/Border
    if db.display.border ~= "none" then
        overlay:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = db.display.borderSize,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        overlay:SetBackdropColor(0,0,0,0) -- Transparent background
        overlay:SetBackdropBorderColor(unpack(db.display.borderColor))
    else
        overlay:SetBackdrop(nil)
    end

    -- Overall Alpha and Scale. The alpha is the profile's; the visibility rules
    -- (fade out of combat, mouseover, modifier) scale it from there.
    overlay._ahosBaseAlpha = tonumber(db.display.alpha) or 1
    overlay:SetScale(self:GetOverlayScale(parent, db))
    if addon.Visibility and addon.Visibility.Track then
        addon.Visibility:Track(overlay, parent)
    else
        overlay:SetAlpha(overlay._ahosBaseAlpha)
    end
    if addon.Editor and addon.Editor.Decorate then addon.Editor:Decorate(overlay, parent) end

    -- Frame layering: default to parent-based strata/level to avoid leaking above unrelated UI.
    local configuredStrata = NormalizeStrata(db.display and db.display.strata, "HIGH")
    local parentStrata = NormalizeStrata(parent and parent.GetFrameStrata and parent:GetFrameStrata(), configuredStrata)
    local targetStrata = smartStrata and parentStrata or configuredStrata
    overlay:SetFrameStrata(targetStrata)

    local configuredLevel = tonumber(db.display and db.display.frameLevel) or 10
    if configuredLevel < 1 then configuredLevel = 1 end
    local parentLevel = GetSafeNumber(parent, "GetFrameLevel", 0)
    local frameLevel
    if smartStrata then
        frameLevel = parentLevel + 1
    else
        frameLevel = math.max(configuredLevel, parentLevel + 1)
    end
    overlay:SetFrameLevel(frameLevel)

    -- If the bar skin adds a nested text container (e.g., AzeriteUI TextOverlayContainer), ensure we sit above it
    if parent and parent.GetChildren then
        local maxChildLevel, maxChildStrata
        for _, child in ipairs(GetSafeObjects(parent, "GetChildren")) do
            local cname = GetSafeName(child) or ""
            if cname and (cname:find("TextOverlay") or cname:find("OverlayFrame")) then
                local cl = GetSafeNumber(child, "GetFrameLevel", 0)
                if (not maxChildLevel) or cl > maxChildLevel then
                    maxChildLevel = cl
                    maxChildStrata = child.GetFrameStrata and child:GetFrameStrata() or nil
                end
            end
        end
        if maxChildLevel and overlay:GetFrameLevel() <= maxChildLevel then
            overlay:SetFrameLevel(maxChildLevel + 1)
            if not smartStrata and maxChildStrata and GetStrataRank(maxChildStrata) > GetStrataRank(overlay:GetFrameStrata()) then
                overlay:SetFrameStrata(NormalizeStrata(maxChildStrata, targetStrata))
            end
        end
    end

    -- Debug output for troubleshooting overlays
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: parent=" .. (GetSafeName(parent) or "nil") .. ", strata=" .. tostring(overlay:GetFrameStrata()) .. ", frameLevel=" .. tostring(overlay:GetFrameLevel()) .. ", text='" .. addon:SafeToString(text) .. "', usedNative=" .. tostring(usedNative) .. ", smartStrata=" .. tostring(smartStrata) .. ", alpha=" .. tostring(db.display.alpha) .. ", scale=" .. tostring(db.display.scale))
    end
end

-- A soft halo behind the text: a copy of it, a thick outline in the glow colour,
-- drawn one sublayer under it, so only the outline shows around the letters.
---@param overlay AHOSOverlay
---@param text string
---@param db AHOSProfile
function Display:StyleGlow(overlay, text, db)
    local glow = db.text and type(db.text.glow) == "table" and db.text.glow
    if not (glow and glow.enabled) then
        if overlay.glow then overlay.glow:Hide() end
        return
    end
    if not overlay.glow then
        overlay.glow = overlay:CreateFontString(nil, "OVERLAY")
        overlay.glow._ahosOwn = true
    end
    local fs = overlay.glow
    local path, size = overlay.text:GetFont()
    local flags = "THICKOUTLINE"
    if not (path and fs:SetFont(path, size or 14, flags)) then
        fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 14, flags)
    end
    local c = type(glow.color) == "table" and glow.color or {1, 0.82, 0.2, 0.8}
    fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 0.8)
    fs:SetShadowColor(c[1] or 1, c[2] or 1, c[3] or 1, (c[4] or 0.8) * 0.6)
    fs:SetShadowOffset(0, 0)
    if fs.SetDrawLayer then fs:SetDrawLayer("OVERLAY", 6) end
    if overlay.text.GetJustifyH and fs.SetJustifyH then fs:SetJustifyH(overlay.text:GetJustifyH() or "CENTER") end
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", overlay.text, "CENTER", 0, 0)
    fs:SetText(text)
    fs:Show()
end

-- A plate behind the text, padded around it.
---@param overlay AHOSOverlay
---@param db AHOSProfile
function Display:StyleBackground(overlay, db)
    local bg = db.display and type(db.display.background) == "table" and db.display.background
    if not (bg and bg.enabled) then
        if overlay.bg then overlay.bg:Hide() end
        return
    end
    if not overlay.bg then
        overlay.bg = overlay:CreateTexture(nil, "BORDER")
    end
    local pad = tonumber(bg.padding) or 2
    local c = type(bg.color) == "table" and bg.color or {0, 0, 0, 0.55}
    overlay.bg:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.55)
    overlay.bg:ClearAllPoints()
    overlay.bg:SetPoint("TOPLEFT", overlay.text, "TOPLEFT", -pad, pad)
    overlay.bg:SetPoint("BOTTOMRIGHT", overlay.text, "BOTTOMRIGHT", pad, -pad)
    overlay.bg:Show()
end

-- Briefly lights up every overlay on your bars, so a setting changed in the options
-- window is seen on your own buttons and not only in its preview. Each call restarts
-- the fade, so dragging a slider keeps them lit until you let go.
local FLASH_TIME, FLASH_ALPHA = 0.7, 0.4

local flashDriver, flashLeft = nil, 0

---@param color? AHOSColor
function Display:FlashOverlays(color)
    if not IsOverlayRenderingEnabled() then return end
    local r, g, b = 0, 0.83, 0.67
    if type(color) == "table" then r, g, b = color[1] or r, color[2] or g, color[3] or b end
    local any = false
    for _, overlay in pairs(activeOverlays) do
        if not overlay.flash then
            overlay.flash = overlay:CreateTexture(nil, "BACKGROUND")
            overlay.flash:SetAllPoints(overlay)
        end
        overlay.flash:SetColorTexture(r, g, b, 1)
        overlay.flash:SetAlpha(FLASH_ALPHA)
        overlay.flash:Show()
        any = true
    end
    if not any then return end
    flashLeft = FLASH_TIME
    if not flashDriver then
        flashDriver = CreateFrame("Frame")
        flashDriver:SetScript("OnUpdate", function(driver, elapsed)
            flashLeft = flashLeft - (elapsed or 0)
            local alpha = flashLeft > 0 and FLASH_ALPHA * flashLeft / FLASH_TIME or 0
            for _, overlay in pairs(activeOverlays) do
                if overlay.flash then
                    overlay.flash:SetAlpha(alpha)
                    if alpha <= 0 then overlay.flash:Hide() end
                end
            end
            if flashLeft <= 0 then driver:Hide() end
        end)
    end
    flashDriver:Show()
end

-- Add a helper to restyle all overlays (font, color, etc.)
function Display:UpdateAllOverlayStyles()
    if not IsOverlayRenderingEnabled() then
        self:RemoveAllOverlays()
        return
    end
    for buttonName, overlay in pairs(activeOverlays) do
        local button = GetSafeFrameValue(overlay, "GetParent") or _G[buttonName]
        if button and overlay then
            local bindingOk, overlayText = pcall(addon.Keybinds.GetBinding, addon.Keybinds, button)
            if not bindingOk or not overlayText or overlayText == "" then
                -- A transiently inaccessible binding must not erase an overlay that is
                -- already visible; preserve its current text while changing only style.
                overlayText = GetSafeText(overlay.text)
            end
            if overlayText and overlayText ~= "" then
                local ok, err = pcall(self.StyleOverlay, self, overlay, button, overlayText)
                if not ok and addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print("[AHOS DEBUG] Could not restyle " .. buttonName .. ": " .. addon:SafeToString(err, "unknown error"))
                end
            end
        end
    end
end
