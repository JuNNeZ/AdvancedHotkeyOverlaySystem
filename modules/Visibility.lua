---@diagnostic disable: undefined-global
-- modules/Visibility.lua - when the hotkey text shows, and what it does when pressed.
--
-- Display draws an overlay; this decides how visible it is. Every rule must agree
-- for the text to show, and when one does not it fades to the profile's faded
-- alpha (0 hides it):
--   * Fade Out of Combat - shown only in combat
--   * Only While a Modifier Is Held - shown while Shift, Ctrl or Alt is down
--   * Show on Mouseover (per bar) - shown while the mouse is over that bar
--   * a condition of your own, a Lua expression (see Compile below)
-- The overlays are the buttons' children, so a bar addon fading its bars (Bartender4,
-- Dominos, ElvUI's mouseover) fades the text with it; nothing here has to know.
--
-- Also here: the combat style (another colour and size while in combat) and the
-- press animation (the text flashes or pulses when its button is pressed).
--
-- Only AHOS's own overlay frames and the labels it writes into are touched, never a
-- protected frame, so all of it works in combat.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSVisibility
local Visibility = addon.Visibility

local tracked = setmetatable({}, { __mode = "k" })   -- overlay -> button
local natives = setmetatable({}, { __mode = "k" })   -- rewritten native label -> button
local anims = setmetatable({}, { __mode = "k" })     -- overlay -> running press animation
local hookedEnter = setmetatable({}, { __mode = "k" })
local hookedPress = setmetatable({}, { __mode = "k" })
local lastPress = setmetatable({}, { __mode = "k" })

local inCombat = false
local hoveredBar
local leaveToken = 0
local driver

local function Settings()
    local profile = addon.db and addon.db.profile
    return profile and type(profile.visibility) == "table" and profile.visibility or {}
end

local function GetName(frame)
    if not frame then return nil end
    local ok, name = pcall(function() return frame:GetName() end)
    if ok and addon:IsValueAccessible(name) and type(name) == "string" and name ~= "" then return name end
end

local function BarKey(button)
    local name = GetName(button)
    return name and addon.Bars.GetBarInfo and addon.Bars:GetBarInfo(name) or nil
end

---------------------------------------------------------------------------
-- A condition of your own
---------------------------------------------------------------------------
-- The text is a Lua expression ("return" is optional) that answers true to show:
--   InCombatLockdown() or IsMounted() == false
--   bar == "Blizzard:1" and UnitExists("target")
-- It sees `button` (the button's name), `bar` (its bar key), `key` (its binding,
-- "SHIFT-Q") and a fixed set of read-only game functions. It runs whenever the
-- visibility is worked out again, and five times a second while one is set. An
-- error shows the text and is said once in the chat.
local SAFE_FUNCTIONS = {
    "InCombatLockdown", "UnitAffectingCombat", "IsMounted", "IsFlying", "IsSwimming", "IsStealthed",
    "IsResting", "IsIndoors", "IsOutdoors", "IsInGroup", "IsInRaid", "IsInInstance",
    "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "IsModifierKeyDown",
    "UnitExists", "UnitIsDead", "UnitIsDeadOrGhost", "UnitCanAttack", "UnitIsFriend", "UnitIsPlayer",
    "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax", "UnitLevel", "UnitClass", "UnitName",
    "GetShapeshiftForm", "GetSpecialization", "GetTime", "HasAction", "IsUsableAction", "GetActionCooldown",
}

local compiled = { source = nil, fn = nil, err = nil }
local reportedError

local function BuildEnv()
    local env = { math = math, string = string, table = table, tonumber = tonumber, tostring = tostring,
        type = type, select = select, pairs = pairs, ipairs = ipairs }
    for _, name in ipairs(SAFE_FUNCTIONS) do
        local fn = rawget(_G, name)
        if type(fn) == "function" then env[name] = fn end
    end
    if C_ActionBar then env.C_ActionBar = { HasAction = C_ActionBar.HasAction } end
    return env
end

-- The compiled condition, or nil when there is none (or it does not compile).
---@param source string
---@return function|nil chunk
---@return string|nil err
function Visibility:Compile(source)
    source = type(source) == "string" and source:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if compiled.source == source then return compiled.fn, compiled.err end
    compiled.source, compiled.fn, compiled.err = source, nil, nil
    if source == "" then return nil end
    local body = source:find("^return[%s%(]") and source or ("return " .. source)
    local chunk, err = loadstring(body, "AHOS condition")
    if not chunk then
        chunk, err = loadstring(source, "AHOS condition")
    end
    if not chunk then
        compiled.err = err
        return nil, err
    end
    compiled.env = BuildEnv()
    setfenv(chunk, compiled.env)
    compiled.fn = chunk
    return chunk
end

-- true, false, or nil when there is no condition. Errors count as true.
---@param button Button
---@return boolean|nil
function Visibility:EvaluateCondition(button)
    local fn, err = self:Compile(Settings().condition)
    if err and reportedError ~= err then
        reportedError = err
        addon:Print((addon.L.VISIBILITY_CONDITION_ERROR or "AHOS: your visibility condition does not work: ") .. tostring(err))
    end
    if not fn then return nil end
    local env = compiled.env
    local name = GetName(button)
    env.button = name
    env.bar = BarKey(button)
    -- the binding is looked up only for a condition that asks for it
    env.key = ""
    if compiled.source:find("key", 1, true) then
        local okKey, full = pcall(addon.Keybinds.GetFullBindingText, addon.Keybinds, button)
        env.key = okKey and addon:IsValueAccessible(full) and full or ""
    end
    local ok, result = pcall(fn)
    if not ok then
        if reportedError ~= result then
            reportedError = result
            addon:Print((addon.L.VISIBILITY_CONDITION_ERROR or "AHOS: your visibility condition does not work: ") .. tostring(result))
        end
        return true
    end
    if not addon:IsValueAccessible(result) then return true end
    return result and true or false
end

-- Whether the text compiles: true, or false and the error.
---@param source string
---@return boolean ok
---@return string|nil err
function Visibility:CheckCondition(source)
    if type(source) ~= "string" or source:find("^%s*$") then return true end
    local body = source:find("^%s*return[%s%(]") and source or ("return " .. source)
    local chunk, err = loadstring(body, "AHOS condition")
    if not chunk then chunk, err = loadstring(source, "AHOS condition") end
    return chunk ~= nil, err
end

---------------------------------------------------------------------------
-- What each overlay should be
---------------------------------------------------------------------------
function Visibility:InCombat()
    return inCombat
end

local function ModifierDown()
    if IsModifierKeyDown then
        local ok, down = pcall(IsModifierKeyDown)
        if ok then return down and true or false end
    end
    return (IsShiftKeyDown and IsShiftKeyDown()) or (IsControlKeyDown and IsControlKeyDown())
        or (IsAltKeyDown and IsAltKeyDown()) or false
end

-- Whether the rules let `button`'s text show right now.
---@param button Button
---@return boolean
function Visibility:IsShownFor(button)
    if addon.Editor and addon.Editor.IsActive and addon.Editor:IsActive() then return true end
    local v = Settings()
    if v.fadeOutOfCombat and not inCombat then return false end
    if v.modifierOnly and not ModifierDown() then return false end
    local name = GetName(button)
    if name and addon.Bars.IsBarMouseover and addon.Bars:IsBarMouseover(name) then
        if hoveredBar == nil or hoveredBar ~= BarKey(button) then return false end
    end
    if self:EvaluateCondition(button) == false then return false end
    return true
end

-- How much of the profile's alpha the text gets: 1 shown, the faded alpha hidden.
---@param button Button
---@return number 1 shown, the faded alpha hidden
function Visibility:GetTargetFactor(button)
    if self:IsShownFor(button) then return 1 end
    local faded = tonumber(Settings().fadedAlpha) or 0
    if faded < 0 then faded = 0 elseif faded > 1 then faded = 1 end
    return faded
end

-- The style to draw in now, when the combat style is on and you are in combat.
---@return { enabled: boolean, color: AHOSColor, scale: number }|nil
function Visibility:GetCombatStyle()
    local style = Settings().combatStyle
    if inCombat and type(style) == "table" and style.enabled then return style end
    return nil
end

local function Apply(overlay)
    local base = overlay._ahosBaseAlpha or 1
    overlay:SetAlpha(base * (overlay._ahosVis or 1))
    overlay._ahosFaded = (overlay._ahosVisTarget or 1) < 1 or nil
end

local function ApplyNative(region)
    local button = natives[region]
    local name = GetName(button)
    -- A label AHOS no longer writes into goes back to its own alpha.
    if not name or not addon.Display.GetButtonState or addon.Display:GetButtonState(name) ~= "native" then
        natives[region] = nil
        pcall(region.SetAlpha, region, 1)
        return
    end
    pcall(region.SetAlpha, region, region._ahosVis or 1)
end

---------------------------------------------------------------------------
-- The driver: fades and press animations
---------------------------------------------------------------------------
local function Step(elapsed)
    local busy = false
    local duration = tonumber(Settings().fadeDuration) or 0.25
    local stepSize = duration > 0 and (elapsed / duration) or 1
    for overlay in pairs(tracked) do
        local target = overlay._ahosVisTarget or 1
        local current = overlay._ahosVis or target
        if current ~= target then
            if current < target then current = math.min(target, current + stepSize)
            else current = math.max(target, current - stepSize) end
            overlay._ahosVis = current
            Apply(overlay)
            if current ~= target then busy = true end
        end
    end
    for region in pairs(natives) do
        local target = region._ahosVisTarget or 1
        local current = region._ahosVis or target
        if current ~= target then
            if current < target then current = math.min(target, current + stepSize)
            else current = math.max(target, current - stepSize) end
            region._ahosVis = current
            ApplyNative(region)
            if current ~= target then busy = true end
        end
    end
    for overlay, anim in pairs(anims) do
        anim.t = anim.t + elapsed
        local p = math.min(1, anim.t / anim.duration)
        if anim.mode == "pulse" then
            overlay:SetScale(anim.scale * (1 + 0.35 * (1 - p)))
        else
            local c, n = anim.color, anim.normal
            overlay.text:SetTextColor(c[1] + (n[1] - c[1]) * p, c[2] + (n[2] - c[2]) * p, c[3] + (n[3] - c[3]) * p, n[4] or 1)
        end
        if p >= 1 then
            if anim.mode == "pulse" then overlay:SetScale(anim.scale) end
            anims[overlay] = nil
        else
            busy = true
        end
    end
    return busy
end
Visibility.Step = Step

local function Run()
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", function(self, elapsed)
            if not Step(elapsed or 0) then self:Hide() end
        end)
    end
    driver:Show()
end

---------------------------------------------------------------------------
-- Tracking
---------------------------------------------------------------------------
-- Called by Display each time it styles an overlay.
---@param overlay AHOSOverlay
---@param button Button
function Visibility:Track(overlay, button)
    tracked[overlay] = button
    local target = self:GetTargetFactor(button)
    overlay._ahosVisTarget = target
    -- a new overlay starts where it should be; a restyled one keeps fading
    if overlay._ahosVis == nil then overlay._ahosVis = target end
    Apply(overlay)
    if overlay._ahosVis ~= target then Run() end
    self:EnsureButtonHooks(button)
end

---@param overlay AHOSOverlay
function Visibility:Untrack(overlay)
    tracked[overlay] = nil
    anims[overlay] = nil
    overlay._ahosVis, overlay._ahosVisTarget, overlay._ahosFaded = nil, nil, nil
end

-- A native label AHOS writes into fades the same way.
---@param region AHOSHotkeyLabel
---@param button Button
function Visibility:TrackNative(region, button)
    if not region then return end
    natives[region] = button
    local target = self:GetTargetFactor(button)
    region._ahosVisTarget = target
    if region._ahosVis == nil then region._ahosVis = target end
    ApplyNative(region)
    if region._ahosVis ~= target then Run() end
    self:EnsureButtonHooks(button)
end

---@param region AHOSHotkeyLabel
function Visibility:RestoreNative(region)
    if not region or natives[region] == nil then return end
    natives[region] = nil
    region._ahosVis, region._ahosVisTarget = nil, nil
    pcall(region.SetAlpha, region, 1)
end

-- Works every target out again. `instant` skips the fade.
---@param instant? boolean skip the fade
function Visibility:Refresh(instant)
    local moving = false
    for overlay, button in pairs(tracked) do
        local target = self:GetTargetFactor(button)
        overlay._ahosVisTarget = target
        if instant then overlay._ahosVis = target end
        Apply(overlay)
        if overlay._ahosVis ~= target then moving = true end
    end
    for region, button in pairs(natives) do
        local target = self:GetTargetFactor(button)
        region._ahosVisTarget = target
        if instant then region._ahosVis = target end
        ApplyNative(region)
        if region._ahosVis ~= target then moving = true end
    end
    if moving then Run() end
end

-- How many overlays are tracked and how many are faded, for the harness and /ahos.
---@return number tracked
---@return number faded
function Visibility:GetCounts()
    local count, faded = 0, 0
    for overlay in pairs(tracked) do
        count = count + 1
        if (overlay._ahosVisTarget or 1) < 1 then faded = faded + 1 end
    end
    return count, faded
end

---------------------------------------------------------------------------
-- Mouseover and presses
---------------------------------------------------------------------------
function Visibility:OnButtonEnter(button)
    local key = BarKey(button)
    leaveToken = leaveToken + 1
    if key and key ~= hoveredBar then
        hoveredBar = key
        self:Refresh(false)
    end
end

-- Leaving one button for the next on the same bar must not fade the bar in between.
function Visibility:OnButtonLeave()
    leaveToken = leaveToken + 1
    local token = leaveToken
    local function leave()
        if token ~= leaveToken or hoveredBar == nil then return end
        hoveredBar = nil
        Visibility:Refresh(false)
    end
    if self.ScheduleTimer then self:ScheduleTimer(leave, 0.15) else leave() end
end

---@return string|nil key
function Visibility:GetHoveredBar()
    return hoveredBar
end

function Visibility:EnsureButtonHooks(button)
    if not button then return end
    -- Action buttons are protected: hook them out of combat only. The overlay is
    -- styled again after combat, which hooks it then.
    if InCombatLockdown and InCombatLockdown() then return end
    if not hookedEnter[button] and button.HookScript then
        hookedEnter[button] = true
        pcall(button.HookScript, button, "OnEnter", function(self) Visibility:OnButtonEnter(self) end)
        pcall(button.HookScript, button, "OnLeave", function(self) Visibility:OnButtonLeave(self) end)
    end
    if not hookedPress[button] then
        hookedPress[button] = true
        if type(hooksecurefunc) == "function" then
            local ok, method = pcall(function() return button.SetButtonState end)
            if ok and type(method) == "function" then
                pcall(hooksecurefunc, button, "SetButtonState", function(self, state)
                    if state == "PUSHED" then Visibility:Press(self) end
                end)
            end
        end
        if button.HookScript then
            pcall(button.HookScript, button, "PostClick", function(self) Visibility:Press(self) end)
        end
    end
end

-- The text answers its button being pressed: a flash of colour, or a pulse.
---@param button Button
function Visibility:Press(button)
    local profile = addon.db and addon.db.profile
    local mode = profile and profile.display and profile.display.pressAnimation
    if mode ~= "flash" and mode ~= "pulse" then return end
    -- one press fires both the state change and the click
    local now = GetTime and GetTime() or 0
    if lastPress[button] and now - lastPress[button] < 0.1 then return end
    lastPress[button] = now
    local name = GetName(button)
    local overlay = name and addon.Display.GetActiveOverlays and addon.Display:GetActiveOverlays()[name]
    if not overlay or not overlay.text then return end
    local running = anims[overlay]
    local anim = { t = 0, mode = mode, duration = mode == "pulse" and 0.3 or 0.4 }
    if mode == "pulse" then
        anim.scale = running and running.scale or overlay:GetScale() or 1
    else
        local r, g, b, a = overlay.text:GetTextColor()
        anim.normal = running and running.normal or { r or 1, g or 1, b or 1, a or 1 }
        local c = type(profile.display.pressColor) == "table" and profile.display.pressColor or {1, 0.82, 0.2}
        anim.color = { c[1] or 1, c[2] or 1, c[3] or 1 }
    end
    anims[overlay] = anim
    -- the first frame at once, so the press is seen on the frame it happens
    Step(0)
    Run()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ticker

function Visibility:UpdateTicker()
    local wants = (Settings().condition or "") ~= ""
    if wants and not ticker and self.ScheduleRepeatingTimer then
        ticker = self:ScheduleRepeatingTimer(function() Visibility:Refresh(false) end, 0.2)
    elseif not wants and ticker then
        self:CancelTimer(ticker)
        ticker = nil
    end
end

local function SetCombat(value)
    if inCombat == value then return end
    inCombat = value
    -- the combat style changes colour and size, which is a restyle
    local style = Settings().combatStyle
    if type(style) == "table" and style.enabled and addon.Display and addon.Display.UpdateAllOverlayStyles then
        addon.Display:UpdateAllOverlayStyles()
    end
    Visibility:Refresh(false)
end
Visibility.SetCombat = SetCombat

function Visibility:OnEnable()
    local ok, combat = pcall(function() return (UnitAffectingCombat and UnitAffectingCombat("player")) or (InCombatLockdown and InCombatLockdown()) end)
    inCombat = ok and combat and true or false
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() SetCombat(true) end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() SetCombat(false) end)
    self:RegisterEvent("MODIFIER_STATE_CHANGED", function()
        if Settings().modifierOnly then Visibility:Refresh(true) end
    end)
    self:UpdateTicker()
end

-- After any setting on the Display page changes.
function Visibility:OnSettingsChanged()
    compiled.source = nil
    reportedError = nil
    self:UpdateTicker()
    self:Refresh(true)
end

function Visibility:OnProfileChanged()
    self:OnSettingsChanged()
end

-- The rule names, for the options and the harness.
Visibility.SafeFunctions = SAFE_FUNCTIONS
