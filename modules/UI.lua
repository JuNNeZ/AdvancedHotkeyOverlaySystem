---@diagnostic disable: undefined-global
--[[
UI.lua - Advanced Hotkey Overlay System
------------------------------------
This module handles the minimap icon for the Advanced Hotkey Overlay System addon.
--]]

local addonName, privateScope = ...
local addon = privateScope.addon
local UI = addon.UI

local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
local libDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

function UI:OnEnable()
    addon:SafeCall("UI", "EnsureMinimapIcon")
    -- Register for PLAYER_LOGIN to guarantee icon after login
    if not self._loginRegistered then
        self._loginRegistered = true
        UI:RegisterEvent("PLAYER_LOGIN", function()
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS] PLAYER_LOGIN: Ensuring minimap icon...")
            end
            -- Show colored version string on normal enable
            local version = "2.1.0" -- keep in sync with TOC
            local msg = "|cff00D4AAAdvanced |cffffd700Hotkey |cffffffffOverlay |cffffd700System|r v.|cff00ffff" .. version .. "|r |cffffffffenabled.|r"
            if not (addon.db and addon.db.profile and addon.db.profile.debug) then
                addon:Print(msg)
            end
            addon:SafeCall("UI", "EnsureMinimapIcon")
        end)
    end
end

function UI:EnsureMinimapIcon()
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] EnsureMinimapIcon called.")
    end
    if not ldb then addon:Print("[AHOS ERROR] LibDataBroker missing!"); return end
    if not libDBIcon then addon:Print("[AHOS ERROR] LibDBIcon missing!"); return end
    if not addon.db or not addon.db.profile then addon:Print("[AHOS ERROR] DB not ready!"); return end
    if not addon.db.profile.minimap then
        addon.db.profile.minimap = { hide = false }
    end
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] minimap.hide = " .. tostring(addon.db.profile.minimap.hide))
    end
    local iconName = addonName .. ".icon"
    -- Always ensure the LDB object exists
    if not ldb:GetDataObjectByName(addonName) then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Creating LDB object for minimap icon.")
        end
        local displayName = "Advanced Hotkey Overlay System"
        ldb:NewDataObject(addonName, {
            type = "launcher",
            text = displayName,
            icon = "Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\media\\small-logo.tga",
            OnClick = function(_, button)
                if type(_G.OpenAHOSOptionsPanel) == "function" and button == "LeftButton" then
                    _G.OpenAHOSOptionsPanel()
                elseif button == "RightButton" then
                    local db = addon.db.profile
                    db.enabled = not db.enabled
                    addon:Print(displayName .. (db.enabled and " enabled." or " disabled."))
                    if db.enabled then
                        addon.Core:OnEnable()
                    else
                        addon.Core:OnDisable()
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then return end
                tooltip:AddLine(displayName)
                tooltip:AddLine("|cffeda55fLeft-click|r to open settings.")
                tooltip:AddLine("|cffeda55fRight-click|r to toggle addon.")
            end,
        })
    else
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] LDB object already exists.")
        end
    end
    -- Unregister any previous/legacy minimap icons
    local legacyNames = {
        addonName .. "MinimapIcon",
        addonName .. ".icon",
        addonName .. "Minimap.icon",
        "AdvancedHotkeyOverlayMinimap.icon",
        "AdvancedHotkeyOverlaySystemMinimapIcon",
        "AdvancedHotkeyOverlaySystemMinimap.icon",
        "AdvancedHotkeyOverlayMinimapIcon"
    }
    for _, name in ipairs(legacyNames) do
        if name ~= iconName and libDBIcon.IsRegistered and libDBIcon:IsRegistered(name) then
            if addon.db and addon.db.profile and addon.db.profile.debug then
                addon:Print("[AHOS DEBUG] Unregistering legacy minimap icon: " .. name)
            end
            if libDBIcon.Unregister then
                libDBIcon:Unregister(name)
            end
        end
    end
    -- Register only the desired icon name
    if addon.db and addon.db.profile and addon.db.profile.debug then
        addon:Print("[AHOS DEBUG] Registering minimap icon with LibDBIcon as " .. iconName)
    end
    -- Only register if not already registered
    if not (libDBIcon.objects and libDBIcon.objects[iconName]) then
        libDBIcon:Register(iconName, ldb:GetDataObjectByName(addonName), addon.db.profile.minimap)
    else
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Minimap icon '" .. iconName .. "' already registered, skipping.")
        end
    end
    if addon.db.profile.minimap.hide then
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Hiding minimap icon (profile setting).")
        end
        libDBIcon:Hide(iconName)
    else
        if addon.db and addon.db.profile and addon.db.profile.debug then
            addon:Print("[AHOS DEBUG] Showing minimap icon.")
        end
        libDBIcon:Show(iconName)
    end
end

function UI:OnProfileChanged()
    addon:SafeCall("UI", "EnsureMinimapIcon")
end
