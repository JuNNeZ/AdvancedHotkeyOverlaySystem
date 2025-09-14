---@diagnostic disable: undefined-global
-- modules/Display.lua
local addonName, privateScope = ...
local addon = privateScope.addon
local Display = addon.Display

local overlayPool = {}
local activeOverlays = {}
local originalHotkeyTexts = {} -- Store original Blizzard hotkey text by button name
local squelchedByButton = {}    -- Track buttons currently squelched
local hookedHotkeyRegions = {}   -- Track fontstrings we have hooksecurefunc'ed
local guardSetText = setmetatable({}, { __mode = "k" }) -- Re-entrancy guard per FontString
local nativeRewriteButtons = {}  -- Per-button flag when we actively rewrite native FS
-- Simple build gate: Retail Dragonflight+ has build numbers >= 100000
local isRetail = (select(4, GetBuildInfo()) or 0) >= 100000

-- Whether we should reuse the native hotkey FontString (rewrite its text)
-- instead of drawing our own overlay text. Default: true (auto-skins with Dominos/Masque).
function Display:UseNativeRewrite()
    local db = addon and addon.db and addon.db.profile
    local v = db and db.display and db.display.nativeRewrite
    -- Default OFF to honor AHOS positioning/reskin settings
    if v == nil then return false end
    return v and true or false
end

-- Per-button policy: force rewrite for Dominos buttons by default for reliability
function Display:ShouldRewriteForButton(button)
    if not button or not button.GetName then return self:UseNativeRewrite() end
    local name = button:GetName() or ""
    local db = addon and addon.db and addon.db.profile
    local dominosPref = db and db.display and db.display.dominosRewrite
    if name:match("^DominosActionButton%d+$") then
    -- Default is overlays for Dominos; opt-in to rewrite if explicitly enabled
    if dominosPref == nil then return false end
        return dominosPref and true or false
    end
    return self:UseNativeRewrite()
end

-- Apply the native hotkey FontString's styling to our overlay text, if available.
-- Returns true if native style was applied; false otherwise.
function Display:ApplyNativeHotkeyStyle(button, overlay)
    if not button or not overlay or not overlay.text then return false end
    local regions = self:GetHotkeyRegions(button)
    local fs = regions and regions[1]
    -- If no obvious hotkey region matched, emit a brief diagnostic for Dominos buttons
    if not fs and addon.db and addon.db.profile and addon.db.profile.debug then
        local bn = (button.GetName and button:GetName()) or tostring(button)
        if bn and bn:find("DominosActionButton") then
            local countFS, samples = 0, {}
            if button.GetRegions then
                for _, r in ipairs({ button:GetRegions() }) do
                    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                        countFS = countFS + 1
                        if #samples < 4 then table.insert(samples, (r.GetName and r:GetName()) or "<anon>") end
                    end
                end
            end
            addon:Print(string.format("[AHOS DEBUG] No native hotkey FS detected on %s (FontStrings=%d) samples=%s", bn, countFS, table.concat(samples, ", ")))
        end
    end
    if not fs or not fs.GetFont then return false end
    -- Align draw layer to native to integrate with skin
    if fs.GetDrawLayer and overlay.text.SetDrawLayer then
        local layer, sub = fs:GetDrawLayer()
        overlay.text:SetDrawLayer(layer or "OVERLAY", (sub or 0) + 1)
    end
    local fontPath, nativeSize, fontFlags = fs:GetFont()
    local dbSize = (addon and addon.db and addon.db.profile and addon.db.profile.text and addon.db.profile.text.fontSize) or nativeSize
    if fontPath and dbSize then
        overlay.text:SetFont(fontPath, dbSize, fontFlags)
    else
        return false
    end
    if fs.GetTextColor then
        local r,g,b,a = fs:GetTextColor()
        -- Dominos/Masque may hide the native FS by setting alpha to 0; ensure our overlay stays visible
        local dbp = addon and addon.db and addon.db.profile
        local aOverride = (dbp and dbp.text and type(dbp.text.color) == "table" and dbp.text.color[4]) or 1
        overlay.text:SetTextColor(r or 1, g or 1, b or 1, aOverride)
    end
    if fs.GetShadowColor and fs.GetShadowOffset then
        local sr,sg,sb,sa = fs:GetShadowColor()
        local sx, sy = fs:GetShadowOffset()
        if sr and sg and sb then overlay.text:SetShadowColor(sr,sg,sb,sa or 1) end
        if sx and sy then overlay.text:SetShadowOffset(sx, sy) end
    end
    -- Mirror justification
    if fs.GetJustifyH then
        local h = fs:GetJustifyH()
        if h and overlay.text.SetJustifyH then overlay.text:SetJustifyH(h) end
    end
    if fs.GetJustifyV then
        local v = fs:GetJustifyV()
        if v and overlay.text.SetJustifyV then overlay.text:SetJustifyV(v) end
    end
    -- Mirror first anchor point; allow anchoring relative to the same frame for pixel-perfect match
    overlay.text:ClearAllPoints()
    if fs.GetPoint and fs.GetNumPoints and fs:GetNumPoints() > 0 then
        local p, _, rp, x, y = fs:GetPoint(1)
        overlay.text:SetPoint(p or "TOPRIGHT", overlay, rp or p or "TOPRIGHT", x or 0, y or 0)
    else
        overlay.text:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        local fp, fsiz, fflags = fs:GetFont()
        local p, rel, rp, x, y = "TOPRIGHT", overlay, "TOPRIGHT", 0, 0
        if fs.GetPoint then p, rel, rp, x, y = fs:GetPoint(1) end
        addon:Print(string.format("[AHOS DEBUG] ApplyNativeHotkeyStyle: %s font=%s size=%s flags=%s point=%s x=%.1f y=%.1f",
            tostring(button:GetName()), tostring(fp), tostring(fsiz), tostring(fflags), tostring(p or "TOPRIGHT"), tonumber(x or 0), tonumber(y or 0)))
    end
    return true
end

local function GetOverlayFromPool(parent)
    local overlay = table.remove(overlayPool)
    if not overlay then
        overlay = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        overlay.text = overlay:CreateFontString(nil, "OVERLAY")
        overlay:SetFrameLevel(parent:GetFrameLevel() + 5)
    if overlay.EnableMouse then overlay:EnableMouse(false) end
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
    wipe(nativeRewriteButtons)
    if addon:IsReady() and addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("All overlays cleared and returned to pool.")
    end
    -- Do NOT wipe originalHotkeyTexts here!
end

-- Helper: Returns true if the text is a Blizzard fallback glyph for unbound keys
local function IsFallbackHotkeyGlyph(text)
    if not text or text == "" then return false end
    -- Common placeholders across locales/skins: bullet, squares, replacement char
    return text == "●" or text == "\226\151\136" or text == "\u{25CF}" -- bullet
        or text == "■" or text == "\u{25A0}" -- black square
        or text == "□" or text == "\u{25A1}" -- white square
        or text == "◼" or text == "\u{25FC}" -- black medium square
        or text == "◻" or text == "\u{25FB}" -- white medium square
        or text == "�" -- replacement character
end

-- Recursively scan a frame and its children for FontStrings that likely represent hotkey labels.
-- This helps when UIs (e.g., AzeriteUI) wrap the hotkey text in a nested container such as
-- ButtonName.TextOverlayContainer.
local function DeepCollectHotkeyFontStrings(frame, button, out, depth, maxDepth)
    if not frame or not frame.GetObjectType then return end
    if depth > (maxDepth or 3) then return end
    -- Collect any FontString children that look like hotkey/keybind text
    if frame.GetRegions then
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = region.GetName and region:GetName() or ""
                local match = (rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")))
                if not match then
                    -- Heuristics: top-right anchored, small-ish font size, short text
                    local p1, _, p2 = region:GetPoint(1)
                    if (p1 == "TOPRIGHT" or p2 == "TOPRIGHT") then
                        match = true
                    end
                end
                if match then table.insert(out, region) end
            end
        end
    end
    -- Recurse into child frames (TextOverlayContainer, OverlayFrame, etc.)
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            if child and child ~= frame and child.GetObjectType then
                local ctype = child:GetObjectType()
                if ctype == "Frame" or ctype == "Button" or ctype == "Region" then
                    DeepCollectHotkeyFontStrings(child, button, out, depth + 1, maxDepth)
                end
            end
        end
    end
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
    -- Avoid drawing overlays on empty action slots. Works for Blizzard and many bar addons.
    local actionId = (button.action and tonumber(button.action)) or (button.GetAttribute and tonumber(button:GetAttribute("action")))
    if actionId and actionId > 0 and type(HasAction) == "function" then
        local ok, has = pcall(HasAction, actionId)
        if ok and has == false then
            -- Clear any existing overlay and ensure original hotkey regions are unsquelched
            local buttonName = button:GetName()
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
                    local hk = button.HotKey or _G[buttonName .. "HotKey"]
                    if hk and hk.SetText then hk:SetText("") end
                end
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Skipping empty action slot for " .. tostring(buttonName))
            end
            return
        end
    end
    local buttonName = button:GetName()
    local overlayText = addon.Keybinds:GetBinding(button)
    -- Manage original hotkey text (save, hide, or restore)
    local hotkeyTextRegion = button.HotKey or _G[buttonName .. "HotKey"]
    -- Dominos/Masque/Classic may use unnamed FontStrings; scan heuristically
    if not hotkeyTextRegion and button.GetRegions then
        local candidates = {}
    for _, region in ipairs({ button:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = region.GetName and region:GetName() or ""
                if rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")) then
                    table.insert(candidates, region)
                else
                    -- Heuristic: top-right anchored small fontstrings commonly used for keybinds
                    local p1, rel, p2, x, y = region:GetPoint(1)
                    if p1 == "TOPRIGHT" or p2 == "TOPRIGHT" then
                        local fs = region
                        local text = fs:GetText()
                        if text and text ~= "" and not tonumber(text) then
                            local fsize = select(2, fs:GetFont()) or 0
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
            addon:Print(string.format("[AHOS DEBUG] Deep-scan matched hotkey FS for %s: %s", buttonName, tostring(hotkeyTextRegion:GetName() or "<anon>")))
        end
    end
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
            -- If we're rewriting the native hotkey FS, don't squelch it; we'll write our text to it.
            local useNative = self:ShouldRewriteForButton(button)
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
    end
    -- If no keybind text for an overlay, remove any existing overlay and stop.
    if not overlayText or overlayText == "" then
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        nativeRewriteButtons[buttonName] = nil
        -- Restore or repopulate Blizzard hotkey if overlays are off or no overlay is shown
        local hotkeyTextRegion = button.HotKey or _G[buttonName .. "HotKey"]
        if not hotkeyTextRegion and button.GetRegions then
            for _, region in ipairs({ button:GetRegions() }) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                    local rname = region.GetName and region:GetName() or ""
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
    local useNative = self:ShouldRewriteForButton(button)
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
                    if button.UpdateHotkeys then button:UpdateHotkeys() end
                    local newText = hotkeyTextRegion:GetText()
                    if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                        originalHotkeyTexts[buttonName] = newText
                    end
                end
                if not hotkeyTextRegion:IsShown() then hotkeyTextRegion:Show() end
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
                            if button.UpdateHotkeys then button:UpdateHotkeys() end
                            local newText = hotkeyTextRegion:GetText()
                            if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                                originalHotkeyTexts[buttonName] = newText
                            else
                                hotkeyTextRegion:SetText("")
                            end
                        end
                        if not hotkeyTextRegion:IsShown() then hotkeyTextRegion:Show() end
                        return
                    end
                    if orig and not IsFallbackHotkeyGlyph(orig) then
                        hotkeyTextRegion:SetText(orig)
                    else
                        if button.UpdateHotkeys then button:UpdateHotkeys() end
                        local newText = hotkeyTextRegion:GetText()
                        if newText and newText ~= "" and not IsFallbackHotkeyGlyph(newText) then
                            originalHotkeyTexts[buttonName] = newText
                        else
                            -- If still no valid text, ensure it's empty
                            hotkeyTextRegion:SetText("")
                        end
                    end
                    if not hotkeyTextRegion:IsShown() then hotkeyTextRegion:Show() end
                end
            end
        end
        return
    end

    -- If configured to rewrite native hotkey text directly, do so instead of creating an overlay
    if self:ShouldRewriteForButton(button) and hotkeyTextRegion and overlayText and overlayText ~= "" then
        -- Ensure original hotkey region is not suppressed
        self:SquelchHotkeyRegions(button, false)
        -- Remove any existing overlay for this button to avoid duplicates
        if activeOverlays[buttonName] then
            ReleaseOverlayToPool(activeOverlays[buttonName])
            activeOverlays[buttonName] = nil
        end
        nativeRewriteButtons[buttonName] = true
        hotkeyTextRegion:SetText(overlayText)
        if not hotkeyTextRegion:IsShown() then hotkeyTextRegion:Show() end
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
            -- Re-evaluate visibility a moment later
            local hidden = (not overlay:IsVisible()) or (not overlay.text:IsVisible())
            local a1 = overlay:GetAlpha() or 1
            local a2 = overlay.text:GetAlpha() or 1
            if hidden or a1 <= 0 or a2 <= 0 then
                -- Try native button HotKey first; otherwise deep-scan to find a nested FS
                local hk = button.HotKey or _G[buttonName .. "HotKey"]
                if not hk then
                    local found = {}
                    DeepCollectHotkeyFontStrings(button, button, found, 1, 4)
                    hk = found[1]
                end
                if hk and hk.SetText then
                    self:SquelchHotkeyRegions(button, false)
                    nativeRewriteButtons[buttonName] = true
                    hk:SetText(overlayText)
                    if addon.db and addon.db.profile and addon.db.profile.debug then
                        addon:Print(string.format("[AHOS DEBUG] AutoFallback: rewrote native FS for %s", tostring(buttonName)))
                    end
                end
            end
        end, 0)
    end
end

-- Helper to find all hotkey/keybind fontstrings on a button
function Display:GetHotkeyRegions(button)
    local regions = {}
    if not button or not button.GetName then return regions end
    local buttonName = button:GetName()
    local r = button.HotKey or _G[buttonName .. "HotKey"]
    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
        table.insert(regions, r)
    end
    if button.GetRegions then
        for _, region in ipairs({ button:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = region.GetName and region:GetName() or ""
                local match = (rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")))
                if not match then
                    local p1, _, p2 = region:GetPoint(1)
                    if p1 == "TOPRIGHT" or p2 == "TOPRIGHT" then
                        match = true
                    end
                end
                if match then table.insert(regions, region) end
            end
        end
    end
    -- Deep scan children (covers AzeriteUI, ElvUI, etc.)
    DeepCollectHotkeyFontStrings(button, button, regions, 1, 4)
    return regions
end

-- Debug helper: dump all detected hotkey regions for a button
function Display:DumpHotkeyRegions(button)
    if not button or not button.GetName then return addon:Print("[AHOS] Dump: invalid button") end
    local name = button:GetName()
    local list = self:GetHotkeyRegions(button)
    addon:Print(string.format("[AHOS DEBUG] DumpHotkeyRegions for %s: %d candidates", name, #list))
    for i, fs in ipairs(list) do
        local fname = fs.GetName and fs:GetName() or "<anon>"
        local layer, sub = "OVERLAY", 0
        if fs.GetDrawLayer then layer, sub = fs:GetDrawLayer() end
        local text = fs.GetText and fs:GetText() or ""
        local shown = fs.IsShown and fs:IsShown() or false
        local a = fs.GetAlpha and fs:GetAlpha() or 1
        local font, size, flags = nil, nil, nil
        if fs.GetFont then font, size, flags = fs:GetFont() end
        local p1, r, p2, x, y = nil, nil, nil, 0, 0
        if fs.GetPoint then p1, r, p2, x, y = fs:GetPoint(1) end
        addon:Print(string.format("  #%d name=%s layer=%s(%s) shown=%s alpha=%.2f font=%s size=%s flags=%s point=%s/%s (%.0f,%.0f) text='%s'", i, tostring(fname), tostring(layer), tostring(sub), tostring(shown), a, tostring(font), tostring(size), tostring(flags), tostring(p1 or "?"), tostring(p2 or "?"), tonumber(x or 0), tonumber(y or 0), tostring(text)))
    end
end

-- Debug helper: dump child frames and their strata/levels (useful for nested overlay containers like AzeriteUI)
function Display:DumpButtonLayers(button)
    if not button or not button.GetName then return addon:Print("[AHOS] DumpLayers: invalid button") end
    local name = button:GetName()
    addon:Print(string.format("[AHOS DEBUG] DumpButtonLayers for %s: strata=%s level=%d", name, tostring(button:GetFrameStrata()), tonumber(button:GetFrameLevel() or 0)))
    if not button.GetChildren then return end
    local children = { button:GetChildren() }
    table.sort(children, function(a,b) return (a:GetFrameLevel() or 0) < (b:GetFrameLevel() or 0) end)
    for _, child in ipairs(children) do
        local cname = child.GetName and child:GetName() or "<anon>"
        addon:Print(string.format("  child=%s strata=%s level=%d visible=%s", tostring(cname), tostring(child:GetFrameStrata()), tonumber(child:GetFrameLevel() or 0), tostring(child:IsVisible())))
    end
end

-- Squelch/restore all hotkey fontstrings for a button using alpha to defeat late SetText calls
function Display:SquelchHotkeyRegions(button, squelch)
    if not button then return end
    local name = button.GetName and button:GetName() or tostring(button)
    local list = self:GetHotkeyRegions(button)
    -- When using native rewrite mode or per-button rewrite, do not suppress
    if self:ShouldRewriteForButton(button) or nativeRewriteButtons[name] then
        squelchedByButton[name] = nil
        return
    end
    if squelch then
        for _, fs in ipairs(list) do
            -- Install one-time hooks to keep this region suppressed against future updates
            if fs and not hookedHotkeyRegions[fs] and type(hooksecurefunc) == "function" then
                hookedHotkeyRegions[fs] = true
                fs._ahosButton = name
                pcall(hooksecurefunc, fs, "Show", function(self)
                    local db = addon and addon.db and addon.db.profile
                    if not db or not (db.display and db.display.hideOriginal) then return end
                    local btnName = rawget(self, "_ahosButton")
                    if nativeRewriteButtons[btnName] or Display:UseNativeRewrite() then return end
                    -- Determine if we should suppress: on Retail, suppress if overlay active OR current text is a fallback glyph.
                    -- On Classic, suppress whenever hideOriginal is enabled.
                    local suppress
                    if isRetail then
                        local overlayActive = (btnName and activeOverlays and activeOverlays[btnName] ~= nil) or false
                        local t = self.GetText and self:GetText() or ""
                        local isFallback = IsFallbackHotkeyGlyph(t)
                        suppress = overlayActive or isFallback
                    else
                        suppress = true
                    end
                    if not suppress then return end
                    if self.SetText then
                        local t = self.GetText and self:GetText()
                        if t and t ~= "" and not guardSetText[self] then
                            guardSetText[self] = true
                            self:SetText("")
                            guardSetText[self] = nil
                        end
                    end
                end)
                -- Guarded SetText hook to blank any non-empty text set later by Dominos/Blizzard
                pcall(hooksecurefunc, fs, "SetText", function(self, newText)
                    local db = addon and addon.db and addon.db.profile
                    if not db or not (db.display and db.display.hideOriginal) then return end
                    local btnName = rawget(self, "_ahosButton")
                    if nativeRewriteButtons[btnName] or Display:UseNativeRewrite() then return end
                    -- Determine suppression logic (Retail vs Classic)
                    local suppress
                    if isRetail then
                        local overlayActive = (btnName and activeOverlays and activeOverlays[btnName] ~= nil) or false
                        local isFallback = IsFallbackHotkeyGlyph(newText)
                        suppress = overlayActive or isFallback
                    else
                        suppress = true
                    end
                    if not suppress then return end
                    if newText and newText ~= "" and not guardSetText[self] and self.SetText then
                        guardSetText[self] = true
                        self:SetText("")
                        guardSetText[self] = nil
                    end
                end)
            end
            -- Apply immediate blanking only when suppression condition applies
            local doInitialBlank = true
            if isRetail then
                local overlayActive = (activeOverlays and activeOverlays[name] ~= nil) or false
                local current = fs.GetText and fs:GetText() or ""
                local isFallback = IsFallbackHotkeyGlyph(current)
                doInitialBlank = overlayActive or isFallback
            end
            if doInitialBlank and fs.SetText and not guardSetText[fs] then
                guardSetText[fs] = true
                fs:SetText("")
                guardSetText[fs] = nil
            end
        end
        squelchedByButton[name] = true
    else
        if squelchedByButton[name] then
            squelchedByButton[name] = nil
        end
    end
end

function Display:StyleOverlay(overlay, parent, text)
    if not addon:IsReady() then return end
    if not addon.db or not addon.db.profile then return end
    local db = addon.db.profile
    local parentName = parent and parent.GetName and parent:GetName() or ""
    local isDominos = parentName:match("^DominosActionButton%d+$") and true or false

    -- Sizing and Positioning
    overlay:SetAllPoints(parent)

    -- Decide whether to mirror native hotkey style (Dominos/Masque) or use configured style
    -- Opt-in to mirror native style; default is to use configured AHOS styling
    local followNative = (db.display and db.display.followNativeHotkeyStyle == true)
    local usedNative = false
    if followNative then
        usedNative = self:ApplyNativeHotkeyStyle(parent, overlay)
    end

    local setFontResult = true
    if not usedNative then
        -- Text Styling (configured)
        local fontName = db.text.font or "Default"
        local fontPath = addon.Config and addon.Config.GetFontPath and addon.Config:GetFontPath(fontName) or "Fonts\\FRIZQT__.TTF"
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
                addon:Print("[AHOS DEBUG] StyleOverlay (configured): font=", fontName, " path=", fontPath, " size=", db.text.fontSize, " outline=", outline)
            end
    setFontResult = overlay.text:SetFont(fontPath, db.text.fontSize, outline)
        local r,g,b,a = 1,1,1,1
        if db.text.color and type(db.text.color) == "table" then
            r = db.text.color[1] or r
            g = db.text.color[2] or g
            b = db.text.color[3] or b
            a = db.text.color[4] or a
        end
        overlay.text:SetTextColor(r,g,b,a)
        -- Shadow settings
        if db.text.shadowEnabled then
            overlay.text:SetShadowColor(0, 0, 0, 1)
            overlay.text:SetShadowOffset(unpack(db.text.shadowOffset))
        else
            overlay.text:SetShadowColor(0, 0, 0, 0)
        end
        -- Text Anchoring (configured)
        overlay.text:ClearAllPoints()
        overlay.text:SetPoint(db.display.anchor, overlay, db.display.anchor, db.display.xOffset, db.display.yOffset)
        -- Ensure overlay text draws above most skin layers
        if overlay.text.SetDrawLayer then
            overlay.text:SetDrawLayer("OVERLAY", 7)
        end
    end

    overlay.text:SetText(text)

    -- Force refresh: hide and show the FontString
    overlay.text:Hide()
    overlay.text:Show()

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

    -- Overall Alpha and Scale
    overlay:SetAlpha(db.display.alpha)
    overlay:SetScale(db.display.scale)

    -- Set overlay frame strata/level (raise when using native styling to avoid skin art above us)
    local strata = (addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.strata) or "HIGH"
    if strata == "MEDIUM" then strata = "HIGH" end
    if usedNative or isDominos then strata = "TOOLTIP" end
    overlay:SetFrameStrata(strata)
    -- Ensure we're well above the parent; native skins sometimes create art at high levels
    local configuredLevel = (addon.db and addon.db.profile and addon.db.profile.display and addon.db.profile.display.frameLevel) or 10
    local parentLevel = parent and parent.GetFrameLevel and parent:GetFrameLevel() or 0
    local bump = (usedNative or isDominos) and 50 or 1
    local frameLevel = math.max(configuredLevel, parentLevel + bump)
    overlay:SetFrameLevel(frameLevel)
    -- If the bar skin adds a nested text container (e.g., AzeriteUI TextOverlayContainer), ensure we sit above it
    if parent and parent.GetChildren then
        local maxChildLevel, maxChildStrata
        for _, child in ipairs({ parent:GetChildren() }) do
            local cname = child.GetName and child:GetName() or ""
            if cname and (cname:find("TextOverlay") or cname:find("OverlayFrame")) then
                local cl = child.GetFrameLevel and child:GetFrameLevel() or 0
                if (not maxChildLevel) or cl > maxChildLevel then
                    maxChildLevel = cl
                    maxChildStrata = child.GetFrameStrata and child:GetFrameStrata() or nil
                end
            end
        end
        if maxChildLevel and overlay:GetFrameLevel() <= maxChildLevel then
            overlay:SetFrameLevel(maxChildLevel + 1)
            if maxChildStrata then overlay:SetFrameStrata(maxChildStrata) end
        end
    end

    -- Debug output for troubleshooting overlays
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] StyleOverlay: parent=" .. tostring(parent and parent:GetName() or "nil") .. ", frameLevel=" .. tostring(overlay:GetFrameLevel()) .. ", text='" .. tostring(text) .. "', usedNative=" .. tostring(usedNative) .. ", alpha=" .. tostring(db.display.alpha) .. ", scale=" .. tostring(db.display.scale))
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
        -- Ensure any alpha squelch is removed now that overlays are going away
        self:SquelchHotkeyRegions(button, false)
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

-- Hook native hotkey update to keep original keybind text suppressed (Classic focus)
function Display:OnEnable()
    if self._hotkeyHooksInstalled then return end
    self._hotkeyHooksInstalled = true
    local display = self
    -- When Blizzard (or Dominos via Blizzard helpers) updates hotkey labels, re-suppress immediately
    if type(hooksecurefunc) == "function" and type(ActionButton_UpdateHotkeys) == "function" then
        hooksecurefunc("ActionButton_UpdateHotkeys", function(btn)
            if not addon or not addon.db or not addon.db.profile then return end
            if not btn or not btn.GetName then return end
            -- If using native rewrite, re-apply our text shortly after Blizzard/Dominos updates
            if Display:UseNativeRewrite() then
                if addon.Core and addon.Core.ScheduleTimer then
                    addon.Core:ScheduleTimer(function()
                        if addon.Display and addon.Display.UpdateOverlayForButton then
                            addon.Display:UpdateOverlayForButton(btn)
                        end
                    end, 0)
                end
                return
            end
            -- Otherwise, if hiding originals, keep them suppressed
            local db = addon.db.profile
            if not db.display or not db.display.hideOriginal then return end
            local text = addon.Keybinds and addon.Keybinds.GetBinding and addon.Keybinds:GetBinding(btn)
            if text and text ~= "" then
                display:SquelchHotkeyRegions(btn, true)
            end
        end)
    end
    -- As a safety net, after multi-bar updates, run an overlay refresh shortly after
    if type(hooksecurefunc) == "function" and type(MultiActionBar_Update) == "function" then
        hooksecurefunc("MultiActionBar_Update", function()
            if not addon or not addon.Core or not addon.Core.ScheduleTimer then return end
            addon.Core:ScheduleTimer(function()
                if addon.Display and addon.Display.UpdateAllOverlays then
                    addon.Display:UpdateAllOverlays()
                end
            end, 0.05)
        end)
    end
end
