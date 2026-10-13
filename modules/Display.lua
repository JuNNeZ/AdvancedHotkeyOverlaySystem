---@diagnostic disable: undefined-global
-- modules/Display.lua - the overlay update flow.
--
-- Which buttons get an overlay, which keep or get back their own label, and the
-- bookkeeping around that: updates (all or one), releasing a button, putting every
-- label back. How an overlay looks is DisplayStyle.lua's; the buttons' own labels
-- are DisplayNative.lua's; shared state and helpers are DisplayShared.lua's.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSDisplay
local Display = addon.Display
local S = privateScope.DisplayShared
local activeOverlays, originalHotkeyTexts, squelchedByButton, nativeRewriteButtons = S.activeOverlays, S.originalHotkeyTexts, S.squelchedByButton, S.nativeRewriteButtons
local providerHotkeyRefreshPending, buttonVisibilityHooks, visibilityRecoveryDelays, buttonUpdateGeneration = S.providerHotkeyRefreshPending, S.buttonVisibilityHooks, S.visibilityRecoveryDelays, S.buttonUpdateGeneration
local isRetail, GetSafeFrameValue, GetSafeName, GetSafeText = S.isRetail, S.GetSafeFrameValue, S.GetSafeName, S.GetSafeText
local GetSafeObjects, IsOverlayRenderingEnabled, RefreshNativeHotkey, NativeHotkeyRegion = S.GetSafeObjects, S.IsOverlayRenderingEnabled, S.RefreshNativeHotkey, S.NativeHotkeyRegion
local IsFallbackHotkeyGlyph, DerivedNativeText, GetOverlayFromPool, ReleaseOverlayToPool = S.IsFallbackHotkeyGlyph, S.DerivedNativeText, S.GetOverlayFromPool, S.ReleaseOverlayToPool
local RemoveOverlayFromPool, PlainText, NativeText, IsTopRightAnchor = S.RemoveOverlayFromPool, S.PlainText, S.NativeText, S.IsTopRightAnchor
local DeepCollectHotkeyFontStrings = S.DeepCollectHotkeyFontStrings

function Display:ClearAllOverlays()
    S.overlayEpoch = S.overlayEpoch + 1
    for _, overlay in pairs(activeOverlays) do
        ReleaseOverlayToPool(overlay)
    end
    wipe(activeOverlays)
    wipe(nativeRewriteButtons)
    wipe(squelchedByButton)
    wipe(buttonUpdateGeneration)
    self:ClearReleased()
    wipe(providerHotkeyRefreshPending)
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] All overlays cleared and returned to pool.")
    end
    -- Do NOT wipe originalHotkeyTexts here!
end

function Display:EnsureButtonVisibilityHook(button)
    if not button or not button.HookScript or buttonVisibilityHooks[button] then return end
    buttonVisibilityHooks[button] = true

    button:HookScript("OnShow", function(self)
        if not addon or not addon.IsReady or not addon:IsReady() then return end
        if not addon.db or not addon.db.profile or not addon.db.profile.enabled then return end

        -- Some UI hiders/showers (e.g., DynamicCam) restore bars asynchronously.
        -- OnShow can fire before the button becomes effectively visible, so keep retrying
        -- until the parent bar has actually finished restoring.
        if addon.Core and addon.Core.ScheduleTimer and addon.Display and addon.Display.UpdateOverlayForButton then
            local scheduledEpoch = S.overlayEpoch
            for _, delay in ipairs(visibilityRecoveryDelays) do
                addon.Core:ScheduleTimer(function()
                    if scheduledEpoch ~= S.overlayEpoch or not IsOverlayRenderingEnabled() then return end
                    if not self or not addon:IsFrameShownSafe(self) then return end
                    if addon.Performance and addon.Performance.QueueButtonUpdate then
                        addon.Performance:QueueButtonUpdate(self)
                    end
                    if addon:IsFrameVisibleSafe(self) then
                        if addon.Display.SafeUpdateOverlayForButton then
                            addon.Display:SafeUpdateOverlayForButton(self)
                        else
                            pcall(addon.Display.UpdateOverlayForButton, addon.Display, self)
                        end
                    end
                end, delay)
            end
        end
    end)
end

function Display:UpdateAllOverlays()
    if not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays: Not ready")
        end
        return
    end
    if not IsOverlayRenderingEnabled() then
        self:RemoveAllOverlays()
        return
    end

    local buttons = addon.Bars:GetAllButtons(true)
    if not buttons or #buttons == 0 then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays: No buttons found; preserving existing overlays for the next scan.")
        end
        return
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:UpdateAllOverlays processing " .. tostring(#buttons) .. " buttons.")
    end
    -- When overlays are toggled off or 'hide original' is toggled off, force Blizzard to repopulate and capture the original hotkey text for ALL buttons
    if addon.db and addon.db.profile and addon.db.profile.display and not addon.db.profile.display.hideOriginal then
        for _, button in ipairs(buttons) do
            local buttonName = GetSafeName(button)
            if buttonName then
                local hotkeyTextRegion = NativeHotkeyRegion(button, buttonName)
                if hotkeyTextRegion then
                    RefreshNativeHotkey(button)
                    local blizzText = GetSafeText(hotkeyTextRegion)
                    -- Native rewrite / auto-fallback may have written our own label here.
                    -- Recapturing it would make the abbreviation permanent, so skip it.
                    local ourText = addon.Keybinds and addon.Keybinds.GetBinding and addon.Keybinds:GetBinding(button)
                    if blizzText and blizzText ~= "" and PlainText(blizzText) ~= ourText and not IsFallbackHotkeyGlyph(blizzText) then
                        originalHotkeyTexts[buttonName] = blizzText
                        if addon.db and addon.db.profile and addon.db.profile.debug then
                            addon:Print("[AHOS DEBUG] Recaptured original Blizzard hotkey for " .. buttonName .. ": '" .. tostring(blizzText) .. "'")
                        end
                    end
                end
            end
        end
    end
    local seenButtons = {}
    for _, button in ipairs(buttons) do
        local buttonName = GetSafeName(button)
        if buttonName then seenButtons[buttonName] = true end
        self:EnsureButtonVisibilityHook(button)
        self:EnsureButtonHotkeyHook(button)
        local ok, err = self:SafeUpdateOverlayForButton(button)
        if not ok and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Could not update " .. (GetSafeName(button) or "<inaccessible>") .. ": " .. addon:SafeToString(err, "unknown error"))
        end
    end

    -- Reconcile stale entries only after every current button had a chance to update.
    -- This keeps a transient scan/update failure from blanking unrelated buttons.
    local staleNames = {}
    for buttonName in pairs(activeOverlays) do
        if not seenButtons[buttonName] then staleNames[#staleNames + 1] = buttonName end
    end
    for _, buttonName in ipairs(staleNames) do
        ReleaseOverlayToPool(activeOverlays[buttonName])
        activeOverlays[buttonName] = nil
        nativeRewriteButtons[buttonName] = nil
        squelchedByButton[buttonName] = nil
        buttonUpdateGeneration[buttonName] = nil
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Updated all overlays for " .. #buttons .. " buttons.")
    end
end

-- Takes AHOS off one button: no overlay, no rewrite, the native label shown with
-- its own text.
local releasedButtons = {}

---@param button Button
function Display:ReleaseButton(button)
    local buttonName = GetSafeName(button)
    if not buttonName or releasedButtons[buttonName] then return end
    releasedButtons[buttonName] = true
    if activeOverlays[buttonName] then
        ReleaseOverlayToPool(activeOverlays[buttonName])
        activeOverlays[buttonName] = nil
    end
    nativeRewriteButtons[buttonName] = nil
    self:SquelchHotkeyRegions(button, false)
    local hotkeyTextRegion = NativeHotkeyRegion(button, buttonName)
    if not hotkeyTextRegion then return end
    if addon.Visibility and addon.Visibility.RestoreNative then addon.Visibility:RestoreNative(hotkeyTextRegion) end
    local refreshed = RefreshNativeHotkey(button)
    local current = GetSafeText(hotkeyTextRegion)
    if refreshed and current and current ~= "" and not IsFallbackHotkeyGlyph(current) then
        if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
        return
    end
    -- The button would not redraw its own label: LibActionButton's UpdateHotkeys
    -- (AzeriteUI, Bartender4) is not a method on the button, and AHOS may never
    -- have seen an original to put back. Ask the button what it shows instead,
    -- then the text saved before AHOS drew, then the game's own short key text.
    local text
    local getHotkey = GetSafeFrameValue(button, "GetHotkey")
    if type(getHotkey) == "string" and getHotkey ~= "" and not IsFallbackHotkeyGlyph(getHotkey) then text = getHotkey end
    local orig = originalHotkeyTexts[buttonName]
    if not text and orig and not IsFallbackHotkeyGlyph(orig) then text = orig end
    if not text then text = DerivedNativeText(button) end
    if text then
        hotkeyTextRegion:SetText(text)
        if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
    end
end

-- A released button is left alone until AHOS takes it back (or every button is
-- reset), so its native label is refreshed once, not on every pass.
function Display:ClearReleased(buttonName)
    if buttonName then releasedButtons[buttonName] = nil else wipe(releasedButtons) end
end

-- What AHOS is doing on one button, for the inspector: "overlay", "native" (its
-- own label rewritten), "released" (a bar left alone), or "none".
---@param buttonName string
---@return "overlay"|"native"|"released"|"ignored"|"none"
function Display:GetButtonState(buttonName)
    if not buttonName then return "none" end
    if releasedButtons[buttonName] then
        return addon.Bars.IsButtonIgnored and addon.Bars:IsButtonIgnored(buttonName) and "ignored" or "released"
    end
    if nativeRewriteButtons[buttonName] then return "native" end
    local overlay = activeOverlays[buttonName]
    if overlay and addon:IsFrameShownSafe(overlay) then return "overlay" end
    return "none"
end

-- How many buttons carry AHOS text right now: as an overlay, and as rewritten
-- native labels.
---@return number drawn
---@return number native
function Display:GetOverlayCounts()
    local drawn, native = 0, 0
    for _, overlay in pairs(activeOverlays) do
        if addon:IsFrameShownSafe(overlay) then drawn = drawn + 1 end
    end
    for _ in pairs(nativeRewriteButtons) do native = native + 1 end
    return drawn, native
end

-- How many tracked buttons are shown and how many overlays are drawn. Two refresh
-- passes that see the same answer mean the bars have settled (Core.ScheduleRefreshPasses).
function Display:GetStateSignature()
    local shown, drawn = 0, 0
    for _, button in ipairs(addon.Bars:GetAllButtons()) do
        if addon:IsFrameVisibleSafe(button) then shown = shown + 1 end
    end
    for _, overlay in pairs(activeOverlays) do
        if addon:IsFrameShownSafe(overlay) then drawn = drawn + 1 end
    end
    return shown .. ":" .. drawn
end

-- Keep the last known-good overlay if a protected/third-party button throws
-- halfway through an update. A later event can retry without leaving the bind blank.
---@param button Button
---@return boolean ok
---@return any err
function Display:SafeUpdateOverlayForButton(button)
    local buttonName = GetSafeName(button)
    if not buttonName then return false, "button name unavailable" end

    local previousOverlay = activeOverlays[buttonName]
    local previousShown = previousOverlay and addon:IsFrameShownSafe(previousOverlay)
    local previousRewriteState = nativeRewriteButtons[buttonName]
    local previousSquelchState = squelchedByButton[buttonName]
    local previousGeneration = buttonUpdateGeneration[buttonName]
    local ok, err = pcall(self.UpdateOverlayForButton, self, button)
    if ok then return true end

    local currentOverlay = activeOverlays[buttonName]
    if currentOverlay and currentOverlay ~= previousOverlay then
        ReleaseOverlayToPool(currentOverlay)
    end
    activeOverlays[buttonName] = nil

    if previousOverlay then
        RemoveOverlayFromPool(previousOverlay)
        pcall(previousOverlay.SetParent, previousOverlay, button)
        if previousShown then
            pcall(previousOverlay.Show, previousOverlay)
        else
            pcall(previousOverlay.Hide, previousOverlay)
        end
        activeOverlays[buttonName] = previousOverlay
    end
    nativeRewriteButtons[buttonName] = previousRewriteState
    squelchedByButton[buttonName] = previousSquelchState
    buttonUpdateGeneration[buttonName] = previousGeneration
    return false, err
end

---@param button Button
function Display:UpdateOverlayForButton(button)
    local buttonName = GetSafeName(button)
    if not button or not buttonName or not addon:IsReady() then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Skipping button: " .. (buttonName or "<inaccessible>"))
        end
        return
    end
    if not IsOverlayRenderingEnabled() then
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        nativeRewriteButtons[buttonName] = nil
        squelchedByButton[buttonName] = nil
        buttonUpdateGeneration[buttonName] = nil
        return
    end
    if not addon:IsFrameVisibleSafe(button) then return end

    -- A bar set to keep its own hotkey text, or a single button told the same:
    -- AHOS steps back and gives it its label.
    if (addon.Bars.IsBarHidden and addon.Bars:IsBarHidden(buttonName))
        or (addon.Bars.IsButtonIgnored and addon.Bars:IsButtonIgnored(buttonName)) then
        self:ReleaseButton(button)
        return
    end
    self:ClearReleased(buttonName)

    buttonUpdateGeneration[buttonName] = (buttonUpdateGeneration[buttonName] or 0) + 1
    local updateGeneration = buttonUpdateGeneration[buttonName]
    local updateEpoch = S.overlayEpoch

    local displaySettings = addon.db and addon.db.profile and addon.db.profile.display
    local autoFallbackEnabled = not displaySettings or displaySettings.autoNativeFallback ~= false
    local configuredNativeRewrite = self:ShouldRewriteForButton(button)
    local rewriteState = nativeRewriteButtons[buttonName]
    if configuredNativeRewrite then
        nativeRewriteButtons[buttonName] = "configured"
    elseif rewriteState == "configured" or (rewriteState == "fallback" and not autoFallbackEnabled) then
        nativeRewriteButtons[buttonName] = nil
    end

    local provider = addon.GetProviderForButtonName and addon:GetProviderForButtonName(buttonName)
    local overlayText = addon.Keybinds:GetBinding(button)

    -- Avoid drawing overlays on empty action slots. Works for Blizzard and many bar addons.
    -- AzeriteUI can briefly report state-swapped dragon/bonus action slots as empty while the
    -- stable button binding is still valid, so keep its overlay when the binding resolved.
    local actionId = addon:GetButtonActionSlot(button)
    local hasActionAPI = C_ActionBar and C_ActionBar.HasAction
    if not hasActionAPI and not isRetail then hasActionAPI = HasAction end
    if actionId and actionId > 0 and type(hasActionAPI) == "function" then
        local ok, has = pcall(hasActionAPI, actionId)
        if not addon:IsValueAccessible(has) then ok = false end
        local keepBoundDynamicButton = provider and provider.key == "AzeriteUI" and overlayText and overlayText ~= ""
        if ok and has == false and not keepBoundDynamicButton then
            -- Clear any existing overlay and ensure original hotkey regions are unsquelched
            if activeOverlays[buttonName] then
                ReleaseOverlayToPool(activeOverlays[buttonName])
                activeOverlays[buttonName] = nil
            end
            nativeRewriteButtons[buttonName] = nil
                -- If user wants original hotkeys hidden, keep them hidden even when empty.
                local hideOrig = addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.hideOriginal
                self:SquelchHotkeyRegions(button, hideOrig and true or false)
                -- As a hard fallback on Classic, directly blank the primary hotkey region for Blizzard buttons
                if hideOrig and not isRetail then
                    local hk = NativeHotkeyRegion(button, buttonName)
                    if hk and hk.SetText then hk:SetText("") end
                end
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Skipping empty action slot for " .. tostring(buttonName))
            end
            return
        end
    end

    -- Manage original hotkey text (save, hide, or restore)
    local hotkeyTextRegion = NativeHotkeyRegion(button, buttonName)
    -- Dominos/Masque/Classic may use unnamed FontStrings; scan heuristically
    if not hotkeyTextRegion and button.GetRegions then
        local candidates = {}
        for _, region in ipairs(GetSafeObjects(button, "GetRegions")) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = GetSafeName(region) or ""
                if rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")) then
                    table.insert(candidates, region)
                else
                    -- Heuristic: top-right anchored small fontstrings commonly used for keybinds
                    if IsTopRightAnchor(region) then
                        local fs = region
                        local text = GetSafeText(fs)
                        if text and text ~= "" and not tonumber(text) then
                            local fontOk, _, fsize = pcall(fs.GetFont, fs)
                            fsize = fontOk and addon:IsValueAccessible(fsize) and tonumber(fsize) or 0
                            if fsize <= 16 then
                                table.insert(candidates, region)
                            end
                        end
                    end
                end
            end
        end
        hotkeyTextRegion = candidates[1]
    end
    -- As a final attempt (covers AzeriteUI), deep-scan for nested FontStrings
    if not hotkeyTextRegion then
        local found = {}
        DeepCollectHotkeyFontStrings(button, button, found, 1, 4)
        hotkeyTextRegion = found[1]
        -- Optional debug trace
        if addon.db and addon.db.profile and addon.db.profile.debug and hotkeyTextRegion then
            addon:Print(string.format("[AHOS DEBUG] Deep-scan matched hotkey FS for %s: %s", buttonName, GetSafeName(hotkeyTextRegion) or "<anon>"))
        end
    end
    if hotkeyTextRegion then
        local currentText = GetSafeText(hotkeyTextRegion) or ""
        if currentText == nil or currentText == "" or currentText == "\0" or IsFallbackHotkeyGlyph(currentText) then
            currentText = ""
        end
        local overlayAbbrev = addon.Keybinds:GetBinding(button)
        -- Only save the original ONCE, before any overlays or hiding, and only if it's not blank/null/overlay/fallback glyph
        if originalHotkeyTexts[buttonName] == nil and currentText ~= "" and currentText ~= "\0" and PlainText(currentText) ~= overlayAbbrev and not IsFallbackHotkeyGlyph(currentText) then
            originalHotkeyTexts[buttonName] = currentText
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Saved original hotkey text for " .. buttonName .. ": '" .. tostring(currentText) .. "'")
            end
        end
            -- If we're rewriting the native hotkey FS, don't squelch it; we'll write our text to it.
            local useNative = configuredNativeRewrite
            if addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.hideOriginal and not useNative then
                -- Always hide Blizzard/Dominos hotkey text when the user enabled 'hide original',
                -- regardless of whether an overlay is shown or the slot is empty.
                self:SquelchHotkeyRegions(button, true)
        else
            -- Show Blizzard hotkey text if overlays are off or hideOriginal is off
            self:SquelchHotkeyRegions(button, false)
            local orig = originalHotkeyTexts[buttonName]
            if hotkeyTextRegion then
                if orig and not IsFallbackHotkeyGlyph(orig) then
                    hotkeyTextRegion:SetText(orig)
                else
                    -- Try to force Blizzard to update the hotkey text
                    RefreshNativeHotkey(button)
                    -- After update, try to save the new original
                    local newText = GetSafeText(hotkeyTextRegion)
                    if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                        originalHotkeyTexts[buttonName] = newText
                    else
                        -- The first login can find the label never filled in.
                        local derived = DerivedNativeText(button)
                        if derived then hotkeyTextRegion:SetText(derived) end
                    end
                end
                if not addon:IsFrameShownSafe(hotkeyTextRegion) then
                    hotkeyTextRegion:Show()
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
        nativeRewriteButtons[buttonName] = nil
        -- Restore or repopulate Blizzard hotkey if overlays are off or no overlay is shown
        local hotkeyTextRegion = NativeHotkeyRegion(button, buttonName)
        if not hotkeyTextRegion and button.GetRegions then
            for _, region in ipairs(GetSafeObjects(button, "GetRegions")) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                    local rname = GetSafeName(region) or ""
                    if rname and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")) then
                        hotkeyTextRegion = region; break
                    end
                end
            end
        end
        if not hotkeyTextRegion then
            local found = {}
            DeepCollectHotkeyFontStrings(button, button, found, 1, 4)
            hotkeyTextRegion = found[1]
        end
    -- Respect user choice globally; Retail vs Classic behavior differs when no overlay is shown
    local hideOrig = addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.hideOriginal
    local useNative = configuredNativeRewrite
    -- When using native rewrite, do not squelch; we'll restore/show native text below
    if not useNative then
        self:SquelchHotkeyRegions(button, hideOrig and true or false)
    else
        self:SquelchHotkeyRegions(button, false)
    end
        if hotkeyTextRegion then
            if hideOrig and isRetail and not useNative then
                -- Retail: with no overlay text, do NOT suppress native labels; restore/show original
                self:SquelchHotkeyRegions(button, false)
                local orig = originalHotkeyTexts[buttonName]
                if orig and not IsFallbackHotkeyGlyph(orig) then
                    hotkeyTextRegion:SetText(orig)
                else
                    RefreshNativeHotkey(button)
                    local newText = GetSafeText(hotkeyTextRegion)
                    if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                        originalHotkeyTexts[buttonName] = newText
                    end
                end
                if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
            else
                -- Classic (or hideOriginal off): Classic keeps empties hidden when requested; otherwise restore
                local orig = originalHotkeyTexts[buttonName]
                if hideOrig and not isRetail and not useNative then
                    -- Classic + hideOriginal: keep empty slots blank
                    hotkeyTextRegion:SetText("")
                    if addon.db and addon.db.profile and addon.db.profile.debug then
                        addon:Print("[AHOS DEBUG] Set hotkey text to empty for unbound or fallback: " .. buttonName)
                    end
                else
                    -- Native rewrite: restore original text when no overlay text is present
                    if useNative then
                        nativeRewriteButtons[buttonName] = nil
                        if orig and not IsFallbackHotkeyGlyph(orig) then
                            hotkeyTextRegion:SetText(orig)
                        else
                            RefreshNativeHotkey(button)
                            local newText = GetSafeText(hotkeyTextRegion)
                            if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                                originalHotkeyTexts[buttonName] = newText
                            else
                                hotkeyTextRegion:SetText("")
                            end
                        end
                        if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
                        return
                    end
                    if orig and not IsFallbackHotkeyGlyph(orig) then
                        hotkeyTextRegion:SetText(orig)
                    else
                        RefreshNativeHotkey(button)
                        local newText = GetSafeText(hotkeyTextRegion)
                        if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                            originalHotkeyTexts[buttonName] = newText
                        else
                            -- If still no valid text, ensure it's empty
                            hotkeyTextRegion:SetText("")
                        end
                    end
                    if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
                end
            end
        end
        return
    end

    -- If configured to rewrite native hotkey text directly, do so instead of creating an overlay
    if configuredNativeRewrite and hotkeyTextRegion and overlayText and overlayText ~= "" then
        -- Ensure original hotkey region is not suppressed
        self:SquelchHotkeyRegions(button, false)
        -- Remove any existing overlay for this button to avoid duplicates
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        nativeRewriteButtons[buttonName] = "configured"
        hotkeyTextRegion:SetText(NativeText(button, overlayText))
        if not addon:IsFrameShownSafe(hotkeyTextRegion) then hotkeyTextRegion:Show() end
        if addon.Visibility and addon.Visibility.TrackNative then addon.Visibility:TrackNative(hotkeyTextRegion, button) end
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print(string.format("[AHOS DEBUG] NativeRewrite applied for %s => '%s'", tostring(buttonName), tostring(overlayText)))
        end
        return
    end
    -- Get or create the overlay frame
    local overlay = activeOverlays[buttonName]
    if not overlay then
        overlay = GetOverlayFromPool(button)
        activeOverlays[buttonName] = overlay
    end
    -- On Retail, we only suppress native labels when an overlay exists. Now that it does, enforce suppression.
    if addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.hideOriginal and isRetail then
        self:SquelchHotkeyRegions(button, true)
    end
    -- Configure and style the overlay with the correct text
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print(string.format("[AHOS DEBUG] Styling overlay for button: %s with text: %s", tostring(buttonName), tostring(overlayText)))
    end
    self:StyleOverlay(overlay, button, overlayText)

    -- Auto fallback to native rewrite if overlay seems invisible (alpha 0 or hidden)
    local db = addon and addon.db and addon.db.profile
    local autoFallback = db and db.display and db.display.autoNativeFallback
    if autoFallback == nil then autoFallback = true end
    if autoFallback and addon.Core and addon.Core.ScheduleTimer then
        addon.Core:ScheduleTimer(function()
            if updateEpoch ~= S.overlayEpoch or buttonUpdateGeneration[buttonName] ~= updateGeneration then return end
            if activeOverlays[buttonName] ~= overlay or not IsOverlayRenderingEnabled() then return end
            -- Alpha zero is a deliberate user choice, not a skin failure; so is text
            -- the visibility rules faded out.
            if db and db.display and (tonumber(db.display.alpha) or 1) <= 0 then return end
            if overlay._ahosFaded then return end

            -- Re-evaluate visibility a moment later
            local hidden = (not addon:IsFrameVisibleSafe(overlay)) or (not addon:IsFrameVisibleSafe(overlay.text))
            local a1 = overlay:GetAlpha() or 1
            local a2 = overlay.text:GetAlpha() or 1
            if hidden or a1 <= 0 or a2 <= 0 then
                -- Try native button HotKey first; otherwise deep-scan to find a nested FS
                local hk = NativeHotkeyRegion(button, buttonName)
                if not hk then
                    local found = {}
                    DeepCollectHotkeyFontStrings(button, button, found, 1, 4)
                    hk = found[1]
                end
                if hk and hk.SetText then
                    self:SquelchHotkeyRegions(button, false)
                    nativeRewriteButtons[buttonName] = "fallback"
                    hk:SetText(NativeText(button, overlayText))
                    if addon.db and addon.db.profile and addon.db.profile.debug then
                        addon:Print(string.format("[AHOS DEBUG] AutoFallback: rewrote native FS for %s", tostring(buttonName)))
                    end
                end
            elseif nativeRewriteButtons[buttonName] == "fallback" then
                -- The overlay became viable again; stop showing the fallback native label.
                nativeRewriteButtons[buttonName] = nil
                if db and db.display and db.display.hideOriginal then
                    self:SquelchHotkeyRegions(button, true)
                end
            end
        end, 0)
    end
end

-- Every overlay AHOS is drawing, by button name (for the visibility rules and the editor).
---@return table<string, AHOSOverlay>
function Display:GetActiveOverlays()
    return activeOverlays
end

-- Called on profile change to re-apply all settings
function Display:OnProfileChanged()
    if addon.Keybinds and addon.Keybinds.ClearCache then addon.Keybinds:ClearCache() end
    addon:SafeCall("Display", "UpdateAllOverlays")
end

function Display:RemoveAllOverlays()
    local activeCount = 0
    for _ in pairs(activeOverlays) do activeCount = activeCount + 1 end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Display:RemoveAllOverlays called. activeOverlays count: " .. tostring(activeCount))
    end

    -- Release overlays before restoring native labels. SetText hooks consult
    -- activeOverlays, so restoring in the opposite order immediately blanks them again.
    local buttons = {}
    if addon.Bars and addon.Bars.GetAllButtons then
        local ok, result = pcall(addon.Bars.GetAllButtons, addon.Bars)
        if ok and type(result) == "table" then
            for _, button in ipairs(result) do buttons[#buttons + 1] = button end
        end
    end
    -- A provider scan can be transiently empty during a bar/page transition. Recover
    -- button references from our own state so disable/cleanup can still restore labels.
    local knownButtons = {}
    for _, button in ipairs(buttons) do
        local buttonName = GetSafeName(button)
        if buttonName then knownButtons[buttonName] = true end
    end
    for buttonName, overlay in pairs(activeOverlays) do
        if not knownButtons[buttonName] then
            local button = GetSafeFrameValue(overlay, "GetParent") or _G[buttonName]
            if button then
                buttons[#buttons + 1] = button
                knownButtons[buttonName] = true
            end
        end
    end
    for buttonName in pairs(nativeRewriteButtons) do
        if not knownButtons[buttonName] and _G[buttonName] then
            buttons[#buttons + 1] = _G[buttonName]
            knownButtons[buttonName] = true
        end
    end
    for buttonName in pairs(squelchedByButton) do
        if not knownButtons[buttonName] and _G[buttonName] then
            buttons[#buttons + 1] = _G[buttonName]
            knownButtons[buttonName] = true
        end
    end
    self:ClearAllOverlays()

    S.restoringNativeHotkeys = true
    for _, button in ipairs(buttons) do
        local ok, err = pcall(function()
            local buttonName = GetSafeName(button)
            if not buttonName then return end
            self:SquelchHotkeyRegions(button, false)
            local refreshed = RefreshNativeHotkey(button)
            local hotkeyTextRegion = NativeHotkeyRegion(button, buttonName)
            if not hotkeyTextRegion then
                hotkeyTextRegion = self:GetHotkeyRegions(button)[1]
            end
            local orig = originalHotkeyTexts[buttonName]
            local current = hotkeyTextRegion and GetSafeText(hotkeyTextRegion)
            local needsFallback = not refreshed or not current or current == "" or IsFallbackHotkeyGlyph(current)
            if needsFallback and hotkeyTextRegion and orig ~= nil and not IsFallbackHotkeyGlyph(orig) then
                hotkeyTextRegion:SetText(orig)
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print("[AHOS DEBUG] Restored hotkey text for " .. buttonName .. ": '" .. tostring(orig) .. "'")
                end
            elseif needsFallback and hotkeyTextRegion and orig ~= nil and IsFallbackHotkeyGlyph(orig) then
                hotkeyTextRegion:SetText("")
                if addon.db and addon.db.profile and addon.db.profile.debug then
                    addon:Print("[AHOS DEBUG] Suppressed fallback glyph for " .. buttonName)
                end
            elseif needsFallback and hotkeyTextRegion and orig == nil then
                -- Nothing was ever captured (AHOS drew before the bar filled its
                -- label on the first login): write what the label would say.
                local derived = DerivedNativeText(button)
                if derived then hotkeyTextRegion:SetText(derived) end
            end
            -- A label faded by the visibility rules gets its own alpha back.
            if hotkeyTextRegion and addon.Visibility and addon.Visibility.RestoreNative then
                addon.Visibility:RestoreNative(hotkeyTextRegion)
            end
            if hotkeyTextRegion and not addon:IsFrameShownSafe(hotkeyTextRegion) then
                hotkeyTextRegion:Show()
            end
        end)
        if not ok and addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Native hotkey restore failed: " .. addon:SafeToString(err, "unknown error"))
        end
    end
    S.restoringNativeHotkeys = false
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] All overlays removed and original keybinds restored.")
    end
end

-- Hook native hotkey updates to keep replacement text synchronized.
function Display:OnEnable()
    if self._hotkeyHooksInstalled then return end
    self._hotkeyHooksInstalled = true
    if addon and addon.Bars and addon.Bars.GetAllButtons then
        for _, btn in ipairs(addon.Bars:GetAllButtons()) do
            self:EnsureButtonHotkeyHook(btn)
        end
    end
    -- As a safety net, after multi-bar updates, run an overlay refresh. Through
    -- Core:FullUpdate, which batches: Blizzard calls this several times in a row.
    if type(hooksecurefunc) == "function" and type(MultiActionBar_Update) == "function" then
        hooksecurefunc("MultiActionBar_Update", function()
            if addon and addon.Core and addon.Core.FullUpdate and addon:IsReady() then
                addon.Core:FullUpdate()
            end
        end)
    end
end
