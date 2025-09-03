---@diagnostic disable: undefined-global
-- modules/Display.lua
local addonName, privateScope = ...
local addon = privateScope.addon
local Display = addon.Display

local overlayPool = {}
local activeOverlays = {}
local originalHotkeyTexts = {} -- Store original Blizzard hotkey text by button name

local function GetOverlayFromPool(parent)
    local overlay = table.remove(overlayPool)
    if not overlay then
        overlay = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        overlay.text = overlay:CreateFontString(nil, "OVERLAY")
        overlay:SetFrameLevel(parent:GetFrameLevel() + 5)
    end
    overlay:SetParent(parent)
    overlay:Show()
    return overlay
end

local function ReleaseOverlayToPool(overlay)
    overlay:Hide()
    overlay:ClearAllPoints()
    overlay:SetParent(UIParent) -- Reparent to avoid being destroyed with parent
    table.insert(overlayPool, overlay)
end

function Display:ClearAllOverlays()
    for buttonName, overlay in pairs(activeOverlays) do
        ReleaseOverlayToPool(overlay)
    end
    wipe(activeOverlays)
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("All overlays cleared and returned to pool.")
    end
    -- Do NOT wipe originalHotkeyTexts here!
end

-- Helper: Returns true if the text is a Blizzard fallback glyph for unbound keys
local function IsFallbackHotkeyGlyph(text)
    return text == "●" or text == "\226\151\136" or text == "\u{25CF}" -- covers UTF-8 and Lua representations
end

function Display:UpdateAllOverlays()
    if not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays: Not ready")
        end
        return
    end
    self:ClearAllOverlays()
    local buttons = addon.Bars:GetAllButtons()
    if not buttons or #buttons == 0 then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays: No buttons found, skipping overlay logic.")
        end
        return
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays processing " .. tostring(#buttons) .. " buttons.")
    end
    -- When overlays are toggled off or 'hide original' is toggled off, force Blizzard to repopulate and capture the original hotkey text for ALL buttons
    if addon.db and addon.db.profile and addon.db.profile.display and not addon.db.profile.display.hideOriginal then
        for _, button in ipairs(buttons) do
            local buttonName = button:GetName()
            local hotkeyTextRegion = _G[buttonName .. "HotKey"]
            if hotkeyTextRegion then
                if button.UpdateHotkeys then
                    button:UpdateHotkeys()
                end
                local blizzText = hotkeyTextRegion:GetText()
                if blizzText and blizzText ~= "" and not IsFallbackHotkeyGlyph(blizzText) then
                    originalHotkeyTexts[buttonName] = blizzText
                    if addon.db and addon.db.profile and addon.db.profile.debug then
                        addon:Print("[AHOS DEBUG] Recaptured original Blizzard hotkey for " .. buttonName .. ": '" .. tostring(blizzText) .. "'")
                    end
                end
            end
        end
    end
    for _, button in ipairs(buttons) do
        self:UpdateOverlayForButton(button)
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Updated all overlays for " .. #buttons .. " buttons.")
    end
end

function Display:UpdateOverlayForButton(button)
    if not button or not button:IsVisible() or not button.GetName or not button:GetName() or not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Skipping button: " .. tostring(button and button.GetName and button:GetName() or "nil"))
        end
        return
    end
    local buttonName = button:GetName()
    local overlayText = addon.Keybinds:GetBinding(button)
    -- Manage original hotkey text (save, hide, or restore)
    local hotkeyTextRegion = _G[buttonName .. "HotKey"]
    if hotkeyTextRegion then
        local currentText = hotkeyTextRegion:GetText()
        if currentText == nil or currentText == "" or currentText == "\0" or IsFallbackHotkeyGlyph(currentText) then
            currentText = ""
        end
        local overlayAbbrev = addon.Keybinds:GetBinding(button)
        -- Only save the original ONCE, before any overlays or hiding, and only if it's not blank/null/overlay/fallback glyph
        if originalHotkeyTexts[buttonName] == nil and currentText ~= "" and currentText ~= "\0" and currentText ~= overlayAbbrev and not IsFallbackHotkeyGlyph(currentText) then
            originalHotkeyTexts[buttonName] = currentText
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Saved original hotkey text for " .. buttonName .. ": '" .. tostring(currentText) .. "'")
            end
        end
        if addon.db.profile.display.hideOriginal and overlayText and overlayText ~= "" then
            -- Hide Blizzard hotkey text if overlays are present and hideOriginal is on
            if hotkeyTextRegion:GetText() ~= "" then
                hotkeyTextRegion:SetText("")
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print("[AHOS DEBUG] Hiding Blizzard hotkey text for " .. buttonName)
                end
            end
        else
            -- Show Blizzard hotkey text if overlays are off or hideOriginal is off
            local orig = originalHotkeyTexts[buttonName]
            if orig and not IsFallbackHotkeyGlyph(orig) then
                hotkeyTextRegion:SetText(orig)
            else
                -- Try to force Blizzard to update the hotkey text
                if button.UpdateHotkeys then
                    button:UpdateHotkeys()
                end
                -- After update, try to save the new original
                local newText = hotkeyTextRegion:GetText()
                if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                    originalHotkeyTexts[buttonName] = newText
                end
            end
            if not hotkeyTextRegion:IsShown() then
                hotkeyTextRegion:Show()
            end
        end
    end
    -- If no keybind text for an overlay, remove any existing overlay and stop.
    if not overlayText or overlayText == "" then
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        -- Restore or repopulate Blizzard hotkey if overlays are off or no overlay is shown
        local hotkeyTextRegion = _G[buttonName .. "HotKey"]
        local orig = originalHotkeyTexts[buttonName]
        if hotkeyTextRegion then
            -- Always set to empty if unbound or fallback glyph
            if not orig or orig == "" or IsFallbackHotkeyGlyph(orig) then
                hotkeyTextRegion:SetText("")
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print("[AHOS DEBUG] Set hotkey text to empty for unbound or fallback: " .. buttonName)
                end
            elseif orig and not IsFallbackHotkeyGlyph(orig) then
                hotkeyTextRegion:SetText(orig)
            else
                if button.UpdateHotkeys then
                    button:UpdateHotkeys()
                end
                local newText = hotkeyTextRegion:GetText()
                if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                    originalHotkeyTexts[buttonName] = newText
                elseif not newText or newText == "" or IsFallbackHotkeyGlyph(newText) then
                    hotkeyTextRegion:SetText("")
                    if addon.db and addon.db.profile and addon.db.profile.debug then
                        addon:Print("[AHOS DEBUG] Set hotkey text to empty after Blizzard update for unbound: " .. buttonName)
                    end
                end
            end
        end
        return
    end
    -- Get or create the overlay frame
    local overlay = activeOverlays[buttonName]
    if not overlay then
        overlay = GetOverlayFromPool(button)
        activeOverlays[buttonName] = overlay
    end
    -- Configure and style the overlay with the correct text
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print(string.format("[AHOS DEBUG] Styling overlay for button: %s with text: %s", tostring(buttonName), tostring(overlayText)))
    end
    self:StyleOverlay(overlay, button, overlayText)
end

function Display:StyleOverlay(overlay, parent, text)
    if not addon:IsReady() then return end
    if not addon.db or not addon.db.profile then return end
    local db = addon.db.profile

    -- Sizing and Positioning
    overlay:SetAllPoints(parent)

    -- Text Styling
    local fontName = db.text.font or "Default"
    local fontPath = addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(fontName) or "Fonts\\FRIZQT__.TTF"
    local outline = db.text.outline and "OUTLINE" or ""

    -- Check font existence if using LibSharedMedia
    local fontExists = true
    local LibSharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LibSharedMedia and fontName and fontName ~= "Default" then
        local fetched = LibSharedMedia:Fetch("font", fontName, true)
        fontExists = fetched and true or false
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] LibSharedMedia:Fetch font '", fontName, "' existence:", tostring(fontExists), " path:", tostring(fetched))
        end
        if fontExists then
            fontPath = fetched
        end
    end

    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: fontName=", fontName, "fontPath=", fontPath, "fontSize=", db.text.fontSize, "outline=", outline)
    end
    
    -- Set the font and force refresh
    local setFontResult = overlay.text:SetFont(fontPath, db.text.fontSize, outline)
    overlay.text:SetText(text)
    overlay.text:SetTextColor(unpack(db.text.color))

    -- Force refresh: hide and show the FontString
    overlay.text:Hide()
    overlay.text:Show()

    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: SetFont result:", tostring(setFontResult), " overlay.text:IsShown()=", tostring(overlay.text:IsShown()), ", overlay:IsShown()=", tostring(overlay:IsShown()))
    end

    if db.text.shadowEnabled then
        overlay.text:SetShadowColor(0, 0, 0, 1)
        overlay.text:SetShadowOffset(unpack(db.text.shadowOffset))
    else
        overlay.text:SetShadowColor(0, 0, 0, 0)
    end

    -- Text Anchoring
    overlay.text:ClearAllPoints()
    overlay.text:SetPoint(db.display.anchor, overlay, db.display.anchor, db.display.xOffset, db.display.yOffset)

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

    -- Overall Alpha and Scale
    overlay:SetAlpha(db.display.alpha)
    overlay:SetScale(db.display.scale)

    -- Set overlay frame strata from options
    local strata = (addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.strata) or "HIGH"
    overlay:SetFrameStrata(strata)
    -- Set overlay frame level from options (default 10)
    local frameLevel = (addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.frameLevel) or 10
    overlay:SetFrameLevel(frameLevel)

    -- Debug output for troubleshooting overlays
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: parent=" .. tostring(parent and parent:GetName() or "nil") .. ", overlay framelevel=" .. tostring(overlay:GetFrameLevel()) .. ", text='" .. tostring(text) .. "', fontPath=" .. tostring(fontPath) .. ", fontSize=" .. tostring(db.text.fontSize) .. ", outline=" .. tostring(outline))
    end
end

function Display:SetOverlaysVisibility(visible)
    for _, overlay in pairs(activeOverlays) do
        if visible then
            overlay:Show()
        else
            overlay:Hide()
        end
    end
end

function Display:OnCombatStart()
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.performance and addon.db.profile.performance.hideInCombat then
        self:SetOverlaysVisibility(false)
    end
end

function Display:OnCombatEnd()
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.performance and addon.db.profile.performance.hideInCombat then
        self:SetOverlaysVisibility(true)
    end
end

-- Called on profile change to re-apply all settings
function Display:OnProfileChanged()
    -- Always clear overlays before updating on profile change
    self:ClearAllOverlays()
    addon:SafeCall("Display", "UpdateAllOverlays")
    -- Also restyle overlays in case font or color changed
    if self.UpdateAllOverlayStyles then
        self:UpdateAllOverlayStyles()
    end
end

-- Add a helper to restyle all overlays (font, color, etc.)
function Display:UpdateAllOverlayStyles()
    for buttonName, overlay in pairs(activeOverlays) do
        local button = _G[buttonName]
        if button and overlay then
            local overlayText = addon.Keybinds:GetBinding(button)
            self:StyleOverlay(overlay, button, overlayText)
        end
    end
end

function Display:UpdateAllButtons()
    -- Alias for UpdateAllOverlays to ensure overlays are updated on all events
    return self:UpdateAllOverlays()
end

function Display:RemoveAllOverlays()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:RemoveAllOverlays called. activeOverlays count: " .. tostring(activeOverlays and table.getn(activeOverlays) or 0))
    end
    -- Restore original Blizzard hotkey text for all tracked buttons
    local buttons = addon.Bars:GetAllButtons()
    for _, button in ipairs(buttons) do
        local buttonName = button:GetName()
        local hotkeyTextRegion = _G[buttonName .. "HotKey"]
        local orig = originalHotkeyTexts[buttonName]
        if hotkeyTextRegion and orig ~= nil and not IsFallbackHotkeyGlyph(orig) then
            hotkeyTextRegion:SetText(orig)
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Restored hotkey text for " .. buttonName .. ": '" .. tostring(orig) .. "'")
            end
        elseif hotkeyTextRegion and orig ~= nil and IsFallbackHotkeyGlyph(orig) then
            hotkeyTextRegion:SetText("")
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Suppressed fallback glyph for " .. buttonName)
            end
        elseif hotkeyTextRegion then
            -- If we never saved a valid original, try to force Blizzard to redraw
            hotkeyTextRegion:SetText("")
            hotkeyTextRegion:Hide()
            hotkeyTextRegion:Show()
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Forced Blizzard redraw for missing original hotkey text on " .. buttonName)
            end
        end
    end
    wipe(activeOverlays)
    -- wipe(originalHotkeyTexts) -- Do not clear originals; needed for restoration across toggles
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] All overlays removed and original keybinds restored.")
    end
end
