---@diagnostic disable: undefined-global
-- modules/Editor.lua - /ahos edit: drag the hotkey text into place on your own bars.
--
-- While editing, every overlay takes the mouse and shows a frame around itself:
--   * drag one to move the text on every bar (the profile's X and Y Offset)
--   * Shift-drag to move it on that bar only (a position of the bar's own)
--   * right-click one to give its bar back to the profile's position
-- A strip at the top of the screen says so, and has Done and Save as Profile.
-- Taking the mouse would keep clicks from your buttons, so editing ends the moment
-- combat starts and cannot begin in it. Only AHOS's own frames are touched.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSEditor
local Editor = addon.Editor
local L = addon.L or {}

local active = false
local strip
local drag
local OFFSET_LIMIT = 50
local MOVE_INTERVAL = 0.03

local function Profile() return addon.db and addon.db.profile end

local function GetName(frame)
    if not frame then return nil end
    local ok, name = pcall(function() return frame:GetName() end)
    if ok and addon:IsValueAccessible(name) and type(name) == "string" and name ~= "" then return name end
end

local function Clamp(v)
    v = math.floor(v + 0.5)
    if v < -OFFSET_LIMIT then return -OFFSET_LIMIT end
    if v > OFFSET_LIMIT then return OFFSET_LIMIT end
    return v
end

---@return boolean
function Editor:IsActive()
    return active
end

local function Restyle()
    if addon.Display and addon.Display.UpdateAllOverlayStyles then addon.Display:UpdateAllOverlayStyles() end
end

---------------------------------------------------------------------------
-- Moving the text
---------------------------------------------------------------------------
-- Where a drag writes: the bar's own position, or the profile's.
local function Target(button, perBar)
    local profile = Profile()
    local name = GetName(button)
    if perBar and name and addon.Bars.GetBarInfo then
        local key, label = addon.Bars:GetBarInfo(name)
        if key then
            profile.bars = type(profile.bars) == "table" and profile.bars or {}
            local settings = profile.bars[key]
            if not settings then
                settings = { label = label }
                profile.bars[key] = settings
            end
            if not settings.position then
                settings.position = true
                settings.anchor = profile.display.anchor
                settings.xOffset, settings.yOffset = profile.display.xOffset, profile.display.yOffset
            end
            return settings, label
        end
    end
    return profile.display, nil
end

function Editor:BeginDrag(overlay, button)
    local perBar = IsShiftKeyDown and IsShiftKeyDown() and true or false
    local target, label = Target(button, perBar)
    local x, y = GetCursorPosition()
    drag = {
        overlay = overlay, target = target, label = label,
        cursorX = x, cursorY = y,
        startX = tonumber(target.xOffset) or 0, startY = tonumber(target.yOffset) or 0,
        scale = (overlay.GetEffectiveScale and overlay:GetEffectiveScale()) or 1,
        elapsed = MOVE_INTERVAL,
    }
    self:SetHint(label and string.format(L.EDITOR_MOVING_BAR or "Moving the text on %s", label)
        or (L.EDITOR_MOVING_ALL or "Moving the text on every bar"))
end

-- Moves the text by the cursor's travel since the drag began.
---@param cursorX number
---@param cursorY number
function Editor:MoveTo(cursorX, cursorY)
    if not drag then return end
    local scale = drag.scale > 0 and drag.scale or 1
    local nx = Clamp(drag.startX + (cursorX - drag.cursorX) / scale)
    local ny = Clamp(drag.startY + (cursorY - drag.cursorY) / scale)
    if nx == drag.target.xOffset and ny == drag.target.yOffset then return end
    drag.target.xOffset, drag.target.yOffset = nx, ny
    Restyle()
end

function Editor:EndDrag()
    if not drag then return end
    local x, y = GetCursorPosition()
    self:MoveTo(x, y)
    drag = nil
    self:SetHint()
    if privateScope.OnOptionsChanged then privateScope.OnOptionsChanged() end
end

-- Right-click: the bar follows the profile's position again.
---@param button Button
---@return boolean
function Editor:ResetBar(button)
    local name = GetName(button)
    local key = name and addon.Bars.GetBarInfo and addon.Bars:GetBarInfo(name)
    local profile = Profile()
    local settings = key and type(profile.bars) == "table" and profile.bars[key]
    if type(settings) ~= "table" or not settings.position then return false end
    settings.position, settings.anchor, settings.xOffset, settings.yOffset = nil, nil, nil, nil
    if addon.Bars.PruneBarSettings then addon.Bars:PruneBarSettings(key) end
    Restyle()
    return true
end

---------------------------------------------------------------------------
-- Overlays while editing
---------------------------------------------------------------------------
---@param overlay AHOSOverlay
---@param button Button
function Editor:Decorate(overlay, button)
    if not active or not overlay then return end
    overlay._ahosEditButton = button
    if not overlay.editFrame then
        local edge = overlay:CreateTexture(nil, "BACKGROUND")
        edge:SetAllPoints(overlay)
        overlay.editFrame = edge
    end
    overlay.editFrame:SetColorTexture(0, 0.83, 0.67, 0.25)
    overlay.editFrame:Show()
    if overlay.EnableMouse then overlay:EnableMouse(true) end
    if overlay._ahosEditHooked then return end
    overlay._ahosEditHooked = true
    overlay:SetScript("OnMouseDown", function(self, mouse)
        if not active then return end
        if mouse == "RightButton" then
            Editor:ResetBar(self._ahosEditButton)
        else
            Editor:BeginDrag(self, self._ahosEditButton)
        end
    end)
    overlay:SetScript("OnMouseUp", function() Editor:EndDrag() end)
    overlay:SetScript("OnUpdate", function(self, elapsed)
        if not drag or drag.overlay ~= self then return end
        drag.elapsed = drag.elapsed + (elapsed or 0)
        if drag.elapsed < MOVE_INTERVAL then return end
        drag.elapsed = 0
        Editor:MoveTo(GetCursorPosition())
    end)
    overlay:SetScript("OnEnter", function(self)
        local name = GetName(self._ahosEditButton)
        local _, label = nil, nil
        if name and addon.Bars.GetBarInfo then _, label = addon.Bars:GetBarInfo(name) end
        if not drag then Editor:SetHint(label) end
    end)
    overlay:SetScript("OnLeave", function() if not drag then Editor:SetHint() end end)
end

---@param overlay AHOSOverlay
function Editor:Undecorate(overlay)
    if not overlay or not overlay._ahosEditHooked then return end
    overlay._ahosEditHooked = nil
    overlay._ahosEditButton = nil
    if overlay.EnableMouse then overlay:EnableMouse(false) end
    for _, script in ipairs({ "OnMouseDown", "OnMouseUp", "OnUpdate", "OnEnter", "OnLeave" }) do
        overlay:SetScript(script, nil)
    end
    if overlay.editFrame then overlay.editFrame:Hide() end
end

---------------------------------------------------------------------------
-- The strip at the top of the screen
---------------------------------------------------------------------------
local function BuildStrip()
    strip = CreateFrame("Frame", "AHOSEditorStrip", UIParent, "BackdropTemplate")
    strip:SetSize(560, 64)
    strip:SetPoint("TOP", UIParent, "TOP", 0, -60)
    strip:SetFrameStrata("DIALOG")
    if strip.SetBackdrop then
        strip:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        strip:SetBackdropColor(0.05, 0.07, 0.09, 0.92)
        strip:SetBackdropBorderColor(0, 0.83, 0.67, 1)
    end
    strip.title = strip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    strip.title:SetPoint("TOPLEFT", 14, -10)
    strip.title:SetText(L.EDITOR_TITLE or "AHOS: Edit Mode")
    strip.hint = strip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    strip.hint:SetPoint("TOPLEFT", strip.title, "BOTTOMLEFT", 0, -6)
    strip.hint:SetPoint("RIGHT", strip, "RIGHT", -230, 0)
    strip.hint:SetJustifyH("LEFT")

    local done = CreateFrame("Button", nil, strip, "UIPanelButtonTemplate")
    done:SetSize(80, 22)
    done:SetPoint("RIGHT", strip, "RIGHT", -12, 0)
    done:SetText(L.EDITOR_DONE or "Done")
    done:SetScript("OnClick", function() Editor:Stop() end)
    strip.done = done

    local save = CreateFrame("Button", nil, strip, "UIPanelButtonTemplate")
    save:SetSize(120, 22)
    save:SetPoint("RIGHT", done, "LEFT", -6, 0)
    save:SetText(L.EDITOR_SAVE_AS or "Save as Profile")
    save:SetScript("OnClick", function() Editor:AskSaveAs() end)
    strip.save = save
    strip:Hide()
end

function Editor:SetHint(text)
    if not strip then return end
    strip.hint:SetText(text or (L.EDITOR_HINT or "Drag a hotkey to move the text on every bar. Shift-drag moves one bar. Right-click gives a bar back to the profile."))
end

function Editor:GetStrip() return strip end

function Editor:AskSaveAs()
    if not StaticPopupDialogs["AHOS_SAVE_AS_PROFILE"] then
        StaticPopupDialogs["AHOS_SAVE_AS_PROFILE"] = {
            text = L.EDITOR_SAVE_AS_PROMPT or "Save these settings as a new profile named:",
            -- the game's own, translated words
            button1 = SAVE or "Save",
            button2 = CANCEL or "Cancel",
            hasEditBox = true,
            OnAccept = function(dialog)
                local box = dialog and (dialog.editBox or dialog.EditBox)
                local name = box and box:GetText()
                if addon.Profiles and addon.Profiles.SaveAs then addon.Profiles:SaveAs(name) end
            end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
    end
    StaticPopup_Show("AHOS_SAVE_AS_PROFILE")
end

---------------------------------------------------------------------------
-- On and off
---------------------------------------------------------------------------
---@return boolean started
function Editor:Start()
    if active then return true end
    if InCombatLockdown and InCombatLockdown() then
        addon:Print(L.EDITOR_COMBAT or "AHOS: edit mode is not available in combat.")
        return false
    end
    if not (addon.db and addon.db.profile and addon.db.profile.enabled) then
        addon:Print(L.EDITOR_DISABLED or "AHOS: turn the overlays on first (/ahos toggle).")
        return false
    end
    active = true
    if not strip then BuildStrip() end
    self:SetHint()
    strip:Show()
    for name, overlay in pairs(addon.Display:GetActiveOverlays()) do
        self:Decorate(overlay, overlay._ahosEditButton or (overlay.GetParent and overlay:GetParent()) or _G[name])
    end
    if addon.Visibility and addon.Visibility.Refresh then addon.Visibility:Refresh(true) end
    -- the options window would cover the bars
    local kit = privateScope.OptionsKit
    if kit and kit.Panel and kit.Panel.IsShown and kit.Panel:IsShown() then kit.Panel:Close() end
    addon:Print(L.EDITOR_STARTED or "AHOS: edit mode. Drag the hotkey text into place, then click Done.")
    return true
end

---@param reason? string what to say instead of the usual line
function Editor:Stop(reason)
    if not active then return end
    active = false
    drag = nil
    for _, overlay in pairs(addon.Display:GetActiveOverlays()) do self:Undecorate(overlay) end
    if strip then strip:Hide() end
    if addon.Visibility and addon.Visibility.Refresh then addon.Visibility:Refresh(true) end
    if privateScope.OnOptionsChanged then privateScope.OnOptionsChanged() end
    addon:Print(reason or (L.EDITOR_STOPPED or "AHOS: edit mode ended; the positions are saved in this profile."))
end

function Editor:Toggle()
    if active then self:Stop() else self:Start() end
end

function Editor:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        if active then Editor:Stop(L.EDITOR_COMBAT_ENDED or "AHOS: combat started, so edit mode ended.") end
    end)
end

function Editor:OnProfileChanged()
    if active then Restyle() end
end
