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
    local keybindText = addon.Keybinds:GetBinding(button)
    local abbreviated = addon.Keybinds:Abbreviate(keybindText)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Button " .. buttonName .. " keybind: " .. tostring(keybindText) .. ", abbreviated: " .. tostring(abbreviated))
    end

    -- Hide original hotkey text if desired
    local hotkeyTextRegion = _G[buttonName .. "HotKey"]
    if hotkeyTextRegion then
        -- Save the original text if not already saved
        if originalHotkeyTexts[buttonName] == nil then
            originalHotkeyTexts[buttonName] = hotkeyTextRegion:GetText()
        end
        if addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.hideOriginal then
            hotkeyTextRegion:SetText("")
        else
            -- If not hiding, attempt to restore the original text.
            -- Note: GetBindingText is a protected Blizzard function.
            local success, originalText = pcall(GetBindingText, buttonName, "HOTKEY")
            if success and originalText then
                hotkeyTextRegion:SetText(originalText)
            end
        end
    end

    -- If no keybind, remove any existing overlay
    if not keybindText or keybindText == "" then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] No keybind for button: " .. tostring(buttonName))
        end
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        return
    end

    -- Get or create overlay
    local overlay = activeOverlays[buttonName]
    if not overlay then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Creating overlay for button: " .. tostring(buttonName))
        end
        overlay = GetOverlayFromPool(button)
        activeOverlays[buttonName] = overlay
    end

    -- Configure and style the overlay
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Styling overlay for button: " .. tostring(buttonName) .. " with text: " .. tostring(abbreviated))
    end
    self:StyleOverlay(overlay, button, abbreviated)
end

function Display:StyleOverlay(overlay, parent, text)
    if not addon:IsReady() then return end
    if not addon.db or not addon.db.profile then return end
    local db = addon.db.profile

    -- Sizing and Positioning
    overlay:SetAllPoints(parent)

    -- Text Styling
    local fontPath = addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(db.text.font) or "Fonts\\FRIZQT__.TTF"
    local outline = db.text.outline and "OUTLINE" or ""
    overlay.text:SetFont(fontPath, db.text.fontSize, outline)
    overlay.text:SetText(text)
    overlay.text:SetTextColor(unpack(db.text.color))

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

    -- Debug output for troubleshooting overlays
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: parent=" .. tostring(parent and parent:GetName() or "nil") .. ", overlay framelevel=" .. tostring(overlay:GetFrameLevel()) .. ", text='" .. tostring(text) .. "', fontPath=" .. tostring(fontPath) .. ", fontSize=" .. tostring(db.text.fontSize) .. ", outline=" .. tostring(outline))
        addon:Print("[AHOS DEBUG] StyleOverlay: overlay.text:IsShown()=" .. tostring(overlay.text:IsShown()) .. ", overlay:IsShown()=" .. tostring(overlay:IsShown()))
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
    addon:SafeCall("Display", "UpdateAllOverlays")
end

function Display:UpdateAllButtons(...)
    -- Alias for UpdateAllOverlays to ensure overlays are updated on all events
    return self:UpdateAllOverlays(...)
end

function Display:RemoveAllOverlays()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:RemoveAllOverlays called. activeOverlays count: " .. tostring(self.activeOverlays and table.getn(self.activeOverlays) or 0))
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
    wipe(self.activeOverlays)
    wipe(originalHotkeyTexts)
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] All overlays removed and original keybinds restored.")
    end
end
