---@diagnostic disable: undefined-global
-- modules/DisplayNative.lua - the buttons' own hotkey labels.
--
-- Finding a button's hotkey label, rewriting it (native text mode), hiding it while
-- an overlay is drawn (and keeping it hidden against late writes), mirroring its
-- style, and the hooks that follow a bar addon redrawing it.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSDisplay
local Display = addon.Display
local S = privateScope.DisplayShared
local activeOverlays, squelchedByButton, hookedHotkeyRegions, guardSetText = S.activeOverlays, S.squelchedByButton, S.hookedHotkeyRegions, S.guardSetText
local nativeRewriteButtons, providerHotkeyHooks, providerHotkeyRefreshPending, isRetail = S.nativeRewriteButtons, S.providerHotkeyHooks, S.providerHotkeyRefreshPending, S.isRetail
local GetSafeName, GetSafeText, GetSafeObjects, GetSafeNumber = S.GetSafeName, S.GetSafeText, S.GetSafeObjects, S.GetSafeNumber
local IsOverlayRenderingEnabled, NativeHotkeyRegion, IsFallbackHotkeyGlyph, IsTopRightAnchor = S.IsOverlayRenderingEnabled, S.NativeHotkeyRegion, S.IsFallbackHotkeyGlyph, S.IsTopRightAnchor
local DeepCollectHotkeyFontStrings = S.DeepCollectHotkeyFontStrings

-- Whether we should reuse the native hotkey FontString (rewrite its text)
-- instead of drawing our own overlay text. Default: true (auto-skins with Dominos/Masque).
function Display:UseNativeRewrite()
    local db = addon and addon.db and addon.db.profile
    local v = db and db.display and db.display.nativeRewrite
    -- Default OFF to honor AHOS positioning/reskin settings
    if v == nil then return false end
    return v and true or false
end

function Display:UseSmartStrata()
    local db = addon and addon.db and addon.db.profile
    local v = db and db.display and db.display.smartStrata
    if v == nil then return false end
    return v and true or false
end

-- Per-button policy: force rewrite for Dominos buttons by default for reliability
function Display:ShouldRewriteForButton(button)
    if not button or not button.GetName then return self:UseNativeRewrite() end
    local name = GetSafeName(button) or ""
    local db = addon and addon.db and addon.db.profile
    local provider = addon and addon.GetProviderForButtonName and addon:GetProviderForButtonName(name)
    local rewriteSetting = provider and provider.rewrite_setting
    if rewriteSetting then
        local providerPref = db and db.display and db.display[rewriteSetting]
        if providerPref == nil then return false end
        return providerPref and true or false
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
        local bn = GetSafeName(button) or addon:SafeToString(button)
        if bn and bn:find("DominosActionButton") then
            local countFS, samples = 0, {}
            if button.GetRegions then
                for _, r in ipairs(GetSafeObjects(button, "GetRegions")) do
                    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                        countFS = countFS + 1
                        if #samples < 4 then table.insert(samples, GetSafeName(r) or "<anon>") end
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
    if fs.GetPoint and fs.GetNumPoints and GetSafeNumber(fs, "GetNumPoints", 0) > 0 then
        local ok, p, _, rp, x, y = pcall(fs.GetPoint, fs, 1)
        if ok and addon:IsValueAccessible(p) and addon:IsValueAccessible(rp)
            and addon:IsValueAccessible(x) and addon:IsValueAccessible(y) then
            overlay.text:SetPoint(p or "TOPRIGHT", overlay, rp or p or "TOPRIGHT", x or 0, y or 0)
        else
            overlay.text:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
        end
    else
        overlay.text:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        local fp, fsiz, fflags = fs:GetFont()
        local p, rel, rp, x, y = "TOPRIGHT", overlay, "TOPRIGHT", 0, 0
        if fs.GetPoint then
            local ok, safeP, safeRel, safeRP, safeX, safeY = pcall(fs.GetPoint, fs, 1)
            if ok then p, rel, rp, x, y = safeP, safeRel, safeRP, safeX, safeY end
        end
        addon:Print(string.format("[AHOS DEBUG] ApplyNativeHotkeyStyle: %s font=%s size=%s flags=%s point=%s x=%.1f y=%.1f",
            GetSafeName(button) or "<secret>", tostring(fp), tostring(fsiz), tostring(fflags), addon:SafeToString(p, "TOPRIGHT"),
            (addon:IsValueAccessible(x) and tonumber(x)) or 0, (addon:IsValueAccessible(y) and tonumber(y)) or 0))
    end
    return true
end

-- Helper to find all hotkey/keybind fontstrings on a button
---@param button Button
---@return FontString[]
function Display:GetHotkeyRegions(button)
    local regions = {}
    if not button or not button.GetName then return regions end
    local buttonName = GetSafeName(button)
    if not buttonName then return regions end
    local r = NativeHotkeyRegion(button, buttonName)
    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
        table.insert(regions, r)
    end
    if button.GetRegions then
        for _, region in ipairs(GetSafeObjects(button, "GetRegions")) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local rname = GetSafeName(region) or ""
                local match = (rname ~= "" and (rname:find("HotKey") or rname:find("Keybind") or rname:find("Hotkey")))
                if not match then
                    if IsTopRightAnchor(region) then
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
    local name = GetSafeName(button)
    if not name then return addon:Print("[AHOS] Dump: inaccessible button") end
    local list = self:GetHotkeyRegions(button)
    addon:Print(string.format("[AHOS DEBUG] DumpHotkeyRegions for %s: %d candidates", name, #list))
    for i, fs in ipairs(list) do
        local fname = GetSafeName(fs) or "<anon>"
        local layer, sub = "OVERLAY", 0
        if fs.GetDrawLayer then layer, sub = fs:GetDrawLayer() end
        local text = GetSafeText(fs) or "<secret>"
        local shown = addon:IsFrameShownSafe(fs)
        local a = fs.GetAlpha and fs:GetAlpha() or 1
        local font, size, flags = nil, nil, nil
        if fs.GetFont then font, size, flags = fs:GetFont() end
        local p1, r, p2, x, y = nil, nil, nil, 0, 0
        if fs.GetPoint then
            local ok, point, relativeTo, relativePoint, offsetX, offsetY = pcall(fs.GetPoint, fs, 1)
            if ok then
                p1, r, p2 = point, relativeTo, relativePoint
                x = addon:IsValueAccessible(offsetX) and offsetX or 0
                y = addon:IsValueAccessible(offsetY) and offsetY or 0
            end
        end
        addon:Print(string.format("  #%d name=%s layer=%s(%s) shown=%s alpha=%.2f font=%s size=%s flags=%s point=%s/%s (%.0f,%.0f) text='%s'", i, fname, tostring(layer), tostring(sub), tostring(shown), a, tostring(font), tostring(size), tostring(flags), addon:SafeToString(p1, "?"), addon:SafeToString(p2, "?"), (addon:IsValueAccessible(x) and tonumber(x)) or 0, (addon:IsValueAccessible(y) and tonumber(y)) or 0, text))
    end
end

-- Debug helper: dump child frames and their strata/levels (useful for nested overlay containers like AzeriteUI)
function Display:DumpButtonLayers(button)
    if not button or not button.GetName then return addon:Print("[AHOS] DumpLayers: invalid button") end
    local name = GetSafeName(button)
    if not name then return addon:Print("[AHOS] DumpLayers: inaccessible button") end
    addon:Print(string.format("[AHOS DEBUG] DumpButtonLayers for %s: strata=%s level=%d", name, tostring(button:GetFrameStrata()), GetSafeNumber(button, "GetFrameLevel", 0)))
    if not button.GetChildren then return end
    local children = GetSafeObjects(button, "GetChildren")
    table.sort(children, function(a,b) return GetSafeNumber(a, "GetFrameLevel", 0) < GetSafeNumber(b, "GetFrameLevel", 0) end)
    for _, child in ipairs(children) do
        local cname = GetSafeName(child) or "<anon>"
        addon:Print(string.format("  child=%s strata=%s level=%d visible=%s", cname, tostring(child:GetFrameStrata()), GetSafeNumber(child, "GetFrameLevel", 0), tostring(addon:IsFrameVisibleSafe(child))))
    end
end

-- Squelch/restore all hotkey fontstrings for a button using alpha to defeat late SetText calls
---@param button Button
---@param squelch boolean
function Display:SquelchHotkeyRegions(button, squelch)
    if not button then return end
    local name = GetSafeName(button) or addon:SafeToString(button)
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
                    if rawget(self, "_ahosOwn") then return end
                    local db = addon and addon.db and addon.db.profile
                    if not db or not (db.display and db.display.hideOriginal) then return end
                    if not IsOverlayRenderingEnabled() then return end
                    local btnName = rawget(self, "_ahosButton")
                    if not btnName or not squelchedByButton[btnName] then return end
                    if nativeRewriteButtons[btnName] or Display:UseNativeRewrite() then return end
                    -- Determine if we should suppress: on Retail, suppress if overlay active OR current text is a fallback glyph.
                    -- On Classic, suppress whenever hideOriginal is enabled.
                    local suppress
                    if isRetail then
                        local overlayActive = (btnName and activeOverlays and activeOverlays[btnName] ~= nil) or false
                        local t = GetSafeText(self) or ""
                        local isFallback = IsFallbackHotkeyGlyph(t)
                        suppress = overlayActive or isFallback
                    else
                        suppress = true
                    end
                    if not suppress then return end
                    if self.SetText then
                        local t = GetSafeText(self)
                        if t and t ~= "" and not guardSetText[self] then
                            guardSetText[self] = true
                            self:SetText("")
                            guardSetText[self] = nil
                        end
                    end
                end)
                -- Guarded SetText hook to blank any non-empty text set later by Dominos/Blizzard
                pcall(hooksecurefunc, fs, "SetText", function(self, newText)
                    if rawget(self, "_ahosOwn") then return end
                    local db = addon and addon.db and addon.db.profile
                    if not db or not (db.display and db.display.hideOriginal) then return end
                    if not IsOverlayRenderingEnabled() then return end
                    local btnName = rawget(self, "_ahosButton")
                    if not btnName or not squelchedByButton[btnName] then return end
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
                    if addon:IsValueAccessible(newText) and newText and newText ~= "" and not guardSetText[self] and self.SetText then
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
                local current = GetSafeText(fs) or ""
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

-- Retail 12.1 updates Blizzard hotkeys through ActionBarActionButtonMixin:UpdateHotkeys;
-- the old global ActionButton_UpdateHotkeys hook no longer exists. Hook the actual
-- button method instead, which also works for supported third-party providers.
function Display:EnsureButtonHotkeyHook(btn)
    if not btn or type(hooksecurefunc) ~= "function" then return end
    local name = GetSafeName(btn)
    if not name then return end

    local provider = addon and addon.GetProviderForButtonName and addon:GetProviderForButtonName(name)
    if not provider then return end

    local methodNames = provider.hotkey_update_methods
    if not methodNames then
        methodNames = provider.hotkey_update_method and { provider.hotkey_update_method } or {}
    end

    local hookedMethods = providerHotkeyHooks[btn]
    if not hookedMethods then
        hookedMethods = {}
        providerHotkeyHooks[btn] = hookedMethods
    end

    for _, methodName in ipairs(methodNames) do
        local method
        local readable = pcall(function() method = btn[methodName] end)
        if readable and not hookedMethods[methodName] and type(method) == "function" then
            local ok = pcall(hooksecurefunc, btn, methodName, function(self)
                if providerHotkeyRefreshPending[self] then return end
                if not addon or not addon.Core or not addon.Core.ScheduleTimer then return end
                if S.restoringNativeHotkeys or not IsOverlayRenderingEnabled() then return end
                providerHotkeyRefreshPending[self] = true
                local scheduledEpoch = S.overlayEpoch
                addon.Core:ScheduleTimer(function()
                    if scheduledEpoch ~= S.overlayEpoch or not IsOverlayRenderingEnabled() then
                        providerHotkeyRefreshPending[self] = nil
                        return
                    end
                    if addon.Display and addon.Display.UpdateOverlayForButton then
                        local updated, err
                        if addon.Display.SafeUpdateOverlayForButton then
                            updated, err = addon.Display:SafeUpdateOverlayForButton(self)
                        else
                            updated, err = pcall(addon.Display.UpdateOverlayForButton, addon.Display, self)
                        end
                        if not updated and addon.db and addon.db.profile and addon.db.profile.debug then
                            addon:Print("[AHOS DEBUG] Deferred hotkey refresh failed: " .. addon:SafeToString(err, "unknown error"))
                        end
                    end
                    providerHotkeyRefreshPending[self] = nil
                end, 0)
            end)
            if ok then hookedMethods[methodName] = true end
        end
    end
    self:EnsureMasqueHook(btn)
end

-- Masque places the hotkey label each time it skins a button (a skin picked, the
-- button's hotkeys redrawn). With Follow Masque Skin on, the overlay is put where
-- the label went, a moment later, once per burst.
local masqueHooked = setmetatable({}, { __mode = "k" })
local masquePending = setmetatable({}, { __mode = "k" })
function Display:EnsureMasqueHook(btn)
    if masqueHooked[btn] or type(hooksecurefunc) ~= "function" then return end
    local ok, cfg = pcall(function() return btn._MSQ_CFG end)
    if not ok or type(cfg) ~= "table" then return end
    local region = NativeHotkeyRegion(btn, GetSafeName(btn))
    if not region then return end
    masqueHooked[btn] = true
    pcall(hooksecurefunc, region, "SetPoint", function()
        local db = addon.db and addon.db.profile
        if masquePending[btn] or not (db and db.display and db.display.followMasque) then return end
        if not (addon.Core and addon.Core.ScheduleTimer) then return end
        masquePending[btn] = true
        addon.Core:ScheduleTimer(function()
            masquePending[btn] = nil
            local name = GetSafeName(btn)
            local overlay = name and activeOverlays[name]
            local text = overlay and GetSafeText(overlay.text)
            if text and text ~= "" then pcall(Display.StyleOverlay, Display, overlay, btn, text) end
        end, 0)
    end)
end
