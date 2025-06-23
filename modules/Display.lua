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

function Display:UpdateAllOverlays()
    if not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays: Not ready")
        end
        return
    end
    self:ClearAllOverlays()
    local buttons = addon.Bars:GetAllButtons()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays processing " .. tostring(#buttons) .. " buttons.")
    end
    for _, button in ipairs(buttons) do
        self:UpdateOverlayForButton(button)
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("Updated all overlays for " .. #buttons .. " buttons.")
    end
end

function Display:UpdateOverlayForButton(button)
    if not button or not button:IsVisible() or not button:GetName() or not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Skipping button: " .. tostring(button and button.GetName and button:GetName() or "nil"))
        end
        return
    end

    local buttonName = button:GetName()
    local overlayText = addon.Keybinds:GetBinding(button) -- This is the (potentially) abbreviated text for our overlay.

    -- Manage original hotkey text (save, hide, or restore)
    local hotkeyTextRegion = _G[buttonName .. "HotKey"]
    if hotkeyTextRegion then
        -- Save the original text if we haven't already.
        if originalHotkeyTexts[buttonName] == nil then
            -- First, get the raw, canonical keybinding (e.g., "SHIFT-MOUSEBUTTON5")
            local fullBindingKey = addon.Keybinds:GetFullBindingText(button)

            if fullBindingKey and fullBindingKey ~= "" then
                -- Next, convert that raw key into the text Blizzard would actually display (e.g., "S-M5")
                local displayBindingText = GetBindingText(fullBindingKey, "HOTKEY")
                originalHotkeyTexts[buttonName] = displayBindingText or ""
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print(string.format("[AHOS DEBUG] Saved original Blizzard display text for %s: '%s' (from raw key '%s')", buttonName, tostring(displayBindingText), tostring(fullBindingKey)))
                end
            else
                -- No binding found, save an empty string to prevent re-checking
                originalHotkeyTexts[buttonName] = ""
            end
        end

        -- Now, either hide the text or restore the original we just saved.
        if addon.db.profile.display.hideOriginal then
            -- Hide if it's not already hidden
            if hotkeyTextRegion:GetText() ~= "" then
                hotkeyTextRegion:SetText("")
            end
        else
            -- Restore if it's not already showing the correct original text
            local originalText = originalHotkeyTexts[buttonName]
            if originalText and hotkeyTextRegion:GetText() ~= originalText then
                hotkeyTextRegion:SetText(originalText)
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print(string.format("[AHOS DEBUG] Restoring original hotkey text for %s: '%s'", buttonName, tostring(originalText)))
                end
            end
        end
    end

    -- If no keybind text for an overlay, remove any existing overlay and stop.
    if not overlayText or overlayText == "" then
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
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
    -- Always update overlays and restyle overlays on profile change
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
        if hotkeyTextRegion and originalHotkeyTexts[buttonName] ~= nil then
            hotkeyTextRegion:SetText(originalHotkeyTexts[buttonName])
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Restored hotkey text for " .. buttonName .. ": " .. tostring(originalHotkeyTexts[buttonName]))
            end
        end
    end
    wipe(activeOverlays)
    wipe(originalHotkeyTexts)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] All overlays removed and original keybinds restored.")
    end
end
