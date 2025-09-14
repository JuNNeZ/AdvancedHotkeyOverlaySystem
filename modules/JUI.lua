local addonName, scope = ...
local addon = scope.addon
local L = (addon and addon.L) or {}
local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

-- JuNNeZ UI (JUI) — handcrafted, native Blizzard UI for AHOS

local ANCHOR_VALUES = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local STRATA_VALUES = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" }

local function GetDB()
	return (addon and addon.db and addon.db.profile) or {}
end

local function SafeUpdate()
	if addon and addon.Core and addon.IsReady and addon:IsReady() and addon.Core.FullUpdate then
		addon.Core:FullUpdate()
	end
	local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if reg then
	reg:NotifyChange(_G.AHOS_OPTIONS_PANEL_NAME or addonName)
	end
end

local function CreateCheck(parent, label, tooltip, getter, setter)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb.text:SetText(label)
	if tooltip then cb.tooltipText = tooltip end
	cb:SetScript("OnShow", function(self) self:SetChecked(getter()) end)
	cb:SetScript("OnClick", function(self)
		setter(self:GetChecked() and true or false)
		SafeUpdate()
	end)
	return cb
end

local function CreateSlider(parent, label, minV, maxV, step, getter, setter)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(380, 56)
	local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOPLEFT", 2, -2)
	text:SetText(label)

	local s = CreateFrame("Slider", nil, f, "OptionsSliderTemplate")
	s:SetPoint("TOPLEFT", 0, -18)
	s:SetMinMaxValues(minV, maxV)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)
	s:SetWidth(360)
	_G[s:GetName() and (s:GetName() .. 'Low') or ''] = nil
	_G[s:GetName() and (s:GetName() .. 'High') or ''] = nil
	_G[s:GetName() and (s:GetName() .. 'Text') or ''] = nil

	local valText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	valText:SetPoint("TOPRIGHT", -2, -2)

	s:SetScript("OnShow", function(self)
		local v = getter()
		if v == nil then v = minV end
		self:SetValue(v)
		valText:SetText(string.format("%.2f", v))
	end)
	s:SetScript("OnValueChanged", function(self, v)
		setter(v)
		valText:SetText(string.format("%.2f", v))
		SafeUpdate()
	end)

	f.slider = s
	return f
end

local function CreateEditBox(parent, label, width, getter, setter)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(380, 44)
	local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOPLEFT", 2, -2)
	text:SetText(label)

	local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	eb:SetSize(width or 240, 24)
	eb:SetPoint("TOPLEFT", 0, -18)
	eb:SetAutoFocus(false)
	eb:SetScript("OnShow", function(self)
		local v = getter() or ""
		self:SetText(tostring(v))
		self:HighlightText(0, 0)
	end)
	eb:SetScript("OnEnterPressed", function(self)
		setter(self:GetText() or "")
		self:ClearFocus()
		SafeUpdate()
	end)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	f.editBox = eb
	return f
end

local function CreateCycle(parent, label, values, getter, setter)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(380, 40)
	local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("LEFT", 2, 0)
	text:SetText(label)

	local left = CreateFrame("Button", nil, f, "UIPanelSquareButton")
	left:SetPoint("RIGHT", -120, 0)
	left:SetSize(24, 24)
	SquareButton_SetIcon(left, "LEFT")

	local right = CreateFrame("Button", nil, f, "UIPanelSquareButton")
	right:SetPoint("LEFT", left, "RIGHT", 4, 0)
	right:SetSize(24, 24)
	SquareButton_SetIcon(right, "RIGHT")

	local valText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	valText:SetPoint("LEFT", right, "RIGHT", 8, 0)
	valText:SetText("")

	local function idxOf(val)
		for i, v in ipairs(values) do if v == val then return i end end
		return 1
	end

	local function apply(i)
		local v = values[i]
		setter(v)
		valText:SetText(v)
		SafeUpdate()
	end

	f:SetScript("OnShow", function()
		local i = idxOf(getter())
		valText:SetText(values[i])
		f._index = i
	end)

	left:SetScript("OnClick", function()
		local i = (f._index or 1) - 1
		if i < 1 then i = #values end
		f._index = i
		apply(i)
	end)
	right:SetScript("OnClick", function()
		local i = (f._index or 1) + 1
		if i > #values then i = 1 end
		f._index = i
		apply(i)
	end)

	return f
end

local function BuildSection_General(parent)
	local db = GetDB()
	local y = -8

	local row = CreateFrame("Frame", nil, parent)
	row:SetPoint("TOPLEFT", 8, -8)
	row:SetSize(1, 28)

	local enable = CreateCheck(parent, L.ENABLE_ADDON or "Enable Addon", nil,
		function() return db.enabled end,
		function(v) db.enabled = v if v then addon.Core:OnEnable() else addon.Core:OnDisable() end end)
	enable:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, y)
	y = y - 28

	local autodetect = CreateCheck(parent, L.AUTO_DETECT_UI or "Auto-Detect UI", nil,
		function() return db.autoDetectUI end,
		function(v) db.autoDetectUI = v end)
	autodetect:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, y)
	y = y - 28

	local debug = CreateCheck(parent, L.DEBUG_MODE or "Debug Mode", nil,
		function() return db.debug end,
		function(v) db.debug = v end)
	debug:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, y)
	y = y - 28

	local lock = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	lock:SetText((db.display and db.display.locked) and (L.UNLOCK_SETTINGS or "Unlock Settings") or (L.LOCK_SETTINGS or "Lock Settings"))
	lock:SetSize(140, 24)
	lock:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, y)
	lock:SetScript("OnClick", function()
		db.display = db.display or {}
		db.display.locked = not db.display.locked
	lock:SetText(db.display.locked and (L.UNLOCK_SETTINGS or "Unlock Settings") or (L.LOCK_SETTINGS or "Lock Settings"))
		SafeUpdate()
	end)
	y = y - 36

	local hideMM = CreateCheck(parent, L.HIDE_MINIMAP_ICON or "Hide Minimap Icon", nil,
		function() return (db.minimap and db.minimap.hide) end,
		function(v) db.minimap = db.minimap or {}; db.minimap.hide = v; if addon.SetupMinimapButton then addon:SetupMinimapButton() end end)
	hideMM:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, y)

	parent._height = 160
end

local function BuildSection_Display(parent)
	local db = GetDB()
	db.display = db.display or {}
	local d = db.display
	local y = -8

	local hideOrig = CreateCheck(parent, L.HIDE_ORIGINAL or "Hide Original Hotkey Text", nil,
		function() return d.hideOriginal end,
		function(v) d.hideOriginal = v end)
	hideOrig:SetPoint("TOPLEFT", 8, -8)
	y = -36

	local anchor = CreateCycle(parent, L.ANCHOR_POINT or "Anchor Point", ANCHOR_VALUES,
		function() return d.anchor or "TOP" end,
		function(v) d.anchor = v end)
	anchor:SetPoint("TOPLEFT", 8, y)
	y = y - 42

	local xoff = CreateSlider(parent, L.X_OFFSET or "X Offset", -50, 50, 1,
		function() return d.xOffset or 0 end,
		function(v) d.xOffset = math.floor(v + 0.5) end)
	xoff:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local yoff = CreateSlider(parent, L.Y_OFFSET or "Y Offset", -50, 50, 1,
		function() return d.yOffset or 0 end,
		function(v) d.yOffset = math.floor(v + 0.5) end)
	yoff:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local scale = CreateSlider(parent, L.SCALE or "Scale", 0.1, 2.0, 0.05,
		function() return d.scale or 1 end,
		function(v) d.scale = tonumber(string.format("%.2f", v)) end)
	scale:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local alpha = CreateSlider(parent, L.ALPHA or "Alpha", 0, 1, 0.05,
		function() return d.alpha or 1 end,
		function(v) d.alpha = tonumber(string.format("%.2f", v)) end)
	alpha:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local strata = CreateCycle(parent, L.OVERLAY_STRATA or "Overlay Frame Strata", STRATA_VALUES,
		function() return d.strata or "HIGH" end,
		function(v) d.strata = v end)
	strata:SetPoint("TOPLEFT", 8, y)
	y = y - 42

	local level = CreateSlider(parent, L.OVERLAY_LEVEL or "Overlay Frame Level", 1, 128, 1,
		function() return d.frameLevel or 10 end,
		function(v) d.frameLevel = math.floor(v + 0.5) end)
	level:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	parent._height = math.abs(y)
end

local function BuildSection_Keybinds(parent)
	local db = GetDB()
	db.text = db.text or {}
	local t = db.text
	local y = -8

	local outline = CreateCheck(parent, L.FONT_OUTLINE or "Font Outline", nil,
		function() return t.outline end,
		function(v) t.outline = v end)
	outline:SetPoint("TOPLEFT", 8, y)
	y = y - 28

	local abbr = CreateCheck(parent, L.ABBREVIATIONS or "Enable Abbreviations", nil,
		function() return t.abbreviations end,
		function(v) t.abbreviations = v end)
	abbr:SetPoint("TOPLEFT", 8, y)
	y = y - 36

	local maxLen = CreateSlider(parent, L.MAX_LENGTH or "Max Length", 1, 10, 1,
		function() return t.maxLength or 4 end,
		function(v) t.maxLength = math.floor(v + 0.5) end)
	maxLen:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local fontSize = CreateSlider(parent, L.FONT_SIZE or "Font Size", 6, 48, 1,
		function() return t.fontSize or 12 end,
		function(v) t.fontSize = math.floor(v + 0.5) end)
	fontSize:SetPoint("TOPLEFT", 8, y)
	y = y - 56

	local modSep = CreateEditBox(parent, L.MOD_SEPARATOR or "Modifier Separator", 160,
		function() return (t.modSeparator or "") end,
		function(v) t.modSeparator = v end)
	modSep:SetPoint("TOPLEFT", 8, y)
	y = y - 48

	local colorBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	colorBtn:SetText(L.PICK_FONT_COLOR or "Pick Font Color")
	colorBtn:SetSize(160, 22)
	colorBtn:SetPoint("TOPLEFT", 8, y+6)
	local preview = parent:CreateTexture(nil, "ARTWORK")
	preview:SetPoint("LEFT", colorBtn, "RIGHT", 8, 0)
	preview:SetSize(40, 16)
	preview:SetColorTexture(1,1,1,1)
	colorBtn:SetScript("OnShow", function()
		local r,g,b = 1,1,1
		if t.color then r,g,b = t.color[1] or 1, t.color[2] or 1, t.color[3] or 1 end
		preview:SetColorTexture(r,g,b,1)
	end)
	colorBtn:SetScript("OnClick", function()
		local r,g,b = 1,1,1
		if t.color then r,g,b = t.color[1] or 1, t.color[2] or 1, t.color[3] or 1 end
		local function apply()
			local nr,ng,nb = ColorPickerFrame:GetColorRGB()
			t.color = {nr,ng,nb}
			preview:SetColorTexture(nr,ng,nb,1)
			SafeUpdate()
		end
		if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow({ swatchFunc = apply, r = r, g = g, b = b, hasOpacity = false })
		else
			if ColorPickerFrame then
				ColorPickerFrame:Hide()
				ColorPickerFrame.hasOpacity = false
				ColorPickerFrame:SetColorRGB(r,g,b)
				ColorPickerFrame.func = apply
				ColorPickerFrame:Show()
			end
		end
	end)
	y = y - 40

	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if LSM and addon.Config and addon.Config.GetFontList then
		local list = addon.Config:GetFontList()
		if type(list) == "table" and #list > 0 then
			local cycle = CreateCycle(parent, L.FONT or "Font", list,
				function() return t.font or list[1] end,
				function(v) t.font = v end)
			cycle:SetPoint("TOPLEFT", 8, y)
			y = y - 42
		end
	end

	parent._height = math.abs(y)
end

local function BuildSection_Profiles(parent)
	local db = GetDB()
	local y = -8

	local current = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	current:SetPoint("TOPLEFT", 8, -8)
	local curName = addon.db and addon.db.GetCurrentProfile and addon.db:GetCurrentProfile() or (L.UNKNOWN or "Unknown")
	current:SetText((L.CURRENT_PROFILE or "Current Profile:") .. " |cffffd700" .. tostring(curName) .. "|r")
	y = y - 28

	local useGlobal = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	useGlobal:SetText(L.USE_GLOBAL_PROFILE or "Use Global Profile")
	useGlobal:SetSize(180, 24)
	useGlobal:SetPoint("TOPLEFT", 8, y)
	useGlobal:SetScript("OnClick", function()
		if not addon.db then return end
		StaticPopupDialogs["AHOS_CONFIRM_PROFILE_SWITCH"] = {
			text = L.CONFIRM_SWITCH_GLOBAL or "Switch to the global (Default) profile? This will overwrite your current settings.",
			button1 = L.YES or "Yes",
			button2 = L.NO or "No",
			OnAccept = function()
				addon.db:SetProfile("Default")
				SafeUpdate()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		StaticPopup_Show("AHOS_CONFIRM_PROFILE_SWITCH")
	end)

	local useChar = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	useChar:SetText(L.USE_CHARACTER_PROFILE or "Use Character Profile")
	useChar:SetSize(180, 24)
	useChar:SetPoint("LEFT", useGlobal, "RIGHT", 10, 0)
	useChar:SetScript("OnClick", function()
		if not addon.db then return end
		local charProfile = UnitName("player") .. " - " .. GetRealmName()
		StaticPopupDialogs["AHOS_CONFIRM_PROFILE_SWITCH_CHAR"] = {
			text = L.CONFIRM_SWITCH_CHARACTER or "Switch to the character-specific profile? This will overwrite your current settings.",
			button1 = L.YES or "Yes",
			button2 = L.NO or "No",
			OnAccept = function()
				addon.db:SetProfile(charProfile)
				SafeUpdate()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		StaticPopup_Show("AHOS_CONFIRM_PROFILE_SWITCH_CHAR")
	end)
	y = y - 36

	local copyRow = CreateFrame("Frame", nil, parent)
	copyRow:SetPoint("TOPLEFT", 8, -64)
	copyRow:SetSize(1, 1)
	local copyLbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	copyLbl:SetPoint("TOPLEFT", 8, -64)
	copyLbl:SetText(L.COPY_PROFILE_TO or "Copy Current Profile To…")
	local copyEB = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	copyEB:SetAutoFocus(false)
	copyEB:SetSize(220, 24)
	copyEB:SetPoint("TOPLEFT", copyLbl, "BOTTOMLEFT", 0, -6)
	local copyBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	copyBtn:SetText(L.COPY or "Copy")
	copyBtn:SetSize(80, 24)
	copyBtn:SetPoint("LEFT", copyEB, "RIGHT", 8, 0)
	copyBtn:SetScript("OnClick", function()
		local name = (copyEB:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if addon.db and name ~= "" then
			addon.db:CopyProfile(name)
			SafeUpdate()
		end
	end)
	y = y - 78

	local resetAll = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	resetAll:SetText(L.RESET_ALL_PROFILES or "Reset All Profiles")
	resetAll:SetSize(180, 24)
	resetAll:SetPoint("TOPLEFT", 8, -150)
	resetAll:SetScript("OnClick", function()
		if not addon.db then return end
		StaticPopupDialogs["AHOS_CONFIRM_RESET_ALL"] = {
			text = L.CONFIRM_RESET_ALL or "Reset ALL profiles to default? This cannot be undone!",
			button1 = L.YES or "Yes",
			button2 = L.NO or "No",
			OnAccept = function()
				addon.db:ResetDB("Default")
				SafeUpdate()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		StaticPopup_Show("AHOS_CONFIRM_RESET_ALL")
	end)

	local autoSwitch = CreateCheck(parent, L.AUTO_SWITCH_PROFILE or "Auto-Switch Profile by Spec", nil,
		function() return db.autoSwitchProfile end,
		function(v) db.autoSwitchProfile = v end)
	autoSwitch:SetPoint("LEFT", resetAll, "RIGHT", 16, 0)

	y = -190

	local exportBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	exportBtn:SetText(L.EXPORT_PROFILE or "Export Current Profile")
	exportBtn:SetSize(200, 24)
	exportBtn:SetPoint("TOPLEFT", 8, y)
	exportBtn:SetScript("OnClick", function()
		if addon.DebugExportTable and addon.db and addon.db.profile then
			addon:DebugExportTable(addon.db.profile)
		end
	end)

	local importLbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	importLbl:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -12)
	importLbl:SetText(L.IMPORT_PROFILE or "Import Profile String")
	local importEB = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	importEB:SetAutoFocus(false)
	importEB:SetSize(360, 24)
	importEB:SetPoint("TOPLEFT", importLbl, "BOTTOMLEFT", 0, -6)
	local importBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	importBtn:SetText(L.IMPORT or "Import")
	importBtn:SetSize(80, 24)
	importBtn:SetPoint("LEFT", importEB, "RIGHT", 8, 0)
	importBtn:SetScript("OnClick", function()
		local text = importEB:GetText() or ""
		if text ~= "" and addon.ImportProfileString then
			addon.ImportProfileString(text)
			SafeUpdate()
		end
	end)

	parent._height = 280
end

local function BuildSection_Help(parent)
	local y = -8
	local text = [[|cffFFD700]] .. (L.HOW_TO_REPORT_BUGS or "How to Report Bugs") .. [[|r
- Include WoW version, addon version, and description.
- For overlay issues, include a screenshot if possible.
- Export your profile/debug data with the buttons below or /ahos debugexport.

|cffFFD700]] .. (L.SLASH_COMMANDS or "Slash Commands") .. [[|r
/ahos show — Open options
/ahos lock|unlock — Lock/unlock settings
/ahos reset — Reset settings
/ahos toggle — Enable/disable overlays
/ahos reload|refresh — Reload overlays
/ahos cleanup — Clear overlays
/ahos debug — Toggle debug mode
/ahos detectui — Detect UI addon
/ahos inspect <ButtonName> — Debug a button
/ahos debugexport [tablepath] — Export profile/subtable
/ahoslog — Open the debug log window

|cffFFD700]] .. (L.DEBUGGING_TIPS or "Debugging Tips") .. [[|r
- Enable debug mode with /ahos debug to see extra output.
- Use /ahos debugexport to copy your profile or a subtable.
- Use /ahoslog to view/copy all debug output.
]]
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", 8, -8)
	fs:SetWidth(680)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetText(text)
	parent._height = math.max(260, math.floor(fs:GetStringHeight() + 32))
end

local function BuildSection_About(parent)
	local text = [[|cffFFD700]] .. (L.ADDON_NAME or "Advanced Hotkey Overlay System") .. [[|r

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

|cffFFD700]] .. (L.MADE_BY or "Made by:") .. [[|r JuNNeZ
|cffFFD700]] .. (L.LIBRARIES or "Libraries:") .. [[|r Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate.

Made with LOVE in Denmark.]]
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", 8, -8)
	fs:SetWidth(680)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetText(text)
	parent._height = math.max(220, math.floor(fs:GetStringHeight() + 32))
end

local function BuildSection_Changelog(parent)
	local ver = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "unknown"
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	header:SetPoint("TOPLEFT", 8, -8)
	header:SetText((L.CHANGELOG or "Changelog") .. " (" .. (L.CURRENT or "current") .. ": " .. ver .. ")")

	local body = [[
	|cffFFD700Latest|r
	- Retail (AzeriteUI): Removed placeholder square/bullet on unbound buttons; safer native label suppression with deep-scan.
	- Classic: Fixed invalid event registration by gating Retail-only events.
	- Dominos: Overlays visible immediately without reload; native labels stay hidden after binding mode.
	- Overlay layering: Bumped frame level above nested containers and skins (Masque/AzeriteUI).

|cffFFD7002.4.2|r
- Embedded AceGUI fixes and stable options registration.
- Icon path fixes and minimap/logo improvements.
- Misc robustness improvements and debug commands.

|cffFFD7002.4.0 (2025-06-24)|r
- Added in-game changelog and version info.
- Debug export window and /ahos debugexport.
- LibSerialize/LibDeflate profile import/export.
- New Help & Debugging tab and polish.

|cffFFD7002.3.0 (2025-06-23)|r
- Modernized options panel registration and naming.
- Ensured single options panel, improved ElvUI compatibility.
- Overlay/minimap logic robustness, instant updates on changes.
- Lock/unlock feature and unlock prompt.
]]
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", 8, -36)
	fs:SetWidth(680)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetText(body)
	parent._height = math.max(320, math.floor(36 + fs:GetStringHeight() + 24))
end

local function BuildSection_Integration(parent)
	local db = GetDB()
	local y = -8
	local elv = CreateCheck(parent, L.ENABLE_ELVUI or "Enable ElvUI Compatibility", nil,
		function() return db.forceOverlaysWithElvUI end,
		function(v) db.forceOverlaysWithElvUI = v end)
	elv:SetPoint("TOPLEFT", 8, y)
	y = y - 28

	local bt = CreateCheck(parent, L.ENABLE_BARTENDER or "Enable Bartender Compatibility", nil,
		function() return db.bartenderCompat end,
		function(v) db.bartenderCompat = v end)
	bt:SetPoint("TOPLEFT", 8, y)
	y = y - 28

	local dom = CreateCheck(parent, L.ENABLE_DOMINOS or "Enable Dominos Compatibility", nil,
		function() return db.dominosCompat end,
		function(v) db.dominosCompat = v end)
	dom:SetPoint("TOPLEFT", 8, y)
	y = y - 28

	parent._height = math.abs(y)
end

local function BuildSection_Advanced(parent)
	local db = GetDB()
	local y = -8
	local perf = CreateCheck(parent, L.SHOW_PERF_METRICS or "Show Performance Metrics", nil,
		function() return db.showPerfMetrics end,
		function(v) db.showPerfMetrics = v end)
	perf:SetPoint("TOPLEFT", 8, y)
	y = y - 36

	local openAce = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	openAce:SetText(L.OPEN_ACE_OPTIONS or "Open Classic Options (AceConfig)")
	openAce:SetSize(260, 24)
	openAce:SetPoint("TOPLEFT", 8, y)
	openAce:SetScript("OnClick", function()
		local ACD = LibStub and LibStub("AceConfigDialog-3.0", true)
		local appName = _G.AHOS_OPTIONS_PANEL_NAME or addonName
		if ACD then ACD:Open(appName) end
	end)
	y = y - 36

	parent._height = math.abs(y)
end

-- Build the main window (JuNNeZ UI)
function addon:OpenJUI(section)
	if self._jui and self._jui:IsShown() then
		self._jui:Hide()
		return
	end

	local db = GetDB()
	db.ui = db.ui or {}
	db.ui.jui = db.ui.jui or {}
	if db.ui.xui and not db.ui.jui.migrated then
		for k,v in pairs(db.ui.xui) do db.ui.jui[k] = v end
		db.ui.jui.migrated = true
	end
	local pref = db.ui.jui

	local frame = CreateFrame("Frame", nil, UIParent, "PortraitFrameTemplate")
	self._jui = frame
	frame:SetFrameStrata("HIGH")
	frame:SetSize(tonumber(pref.w) or 1000, tonumber(pref.h) or 650)
	frame:SetPoint(pref.point or "CENTER", UIParent, pref.relPoint or "CENTER", tonumber(pref.x) or 0, tonumber(pref.y) or 0)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint(1)
		pref.point, pref.relPoint, pref.x, pref.y = p, rp or p, x or 0, y or 0
		pref.w, pref.h = math.floor(self:GetWidth()+0.5), math.floor(self:GetHeight()+0.5)
	end)

	local titleText = frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText)
	if titleText then titleText:SetText(_G.AHOS_OPTIONS_PANEL_NAME or addonName) end
	-- Portrait handling: reusable applier that records the chosen path
	if frame.portrait then
		function frame:ApplyPortrait()
			local function tryPortrait(path)
				if not path or path == "" then return false end
				if SetPortraitToTexture then
					SetPortraitToTexture(self.portrait, path)
				else
					self.portrait:SetTexture(path)
				end
				if self.portrait:GetTexture() then self._portraitPath = path; return true end
				return false
			end
			local meta = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
				or (GetAddOnMetadata and GetAddOnMetadata(addonName, "IconTexture"))
			-- If metadata is a relative path (e.g., 'media/logo.tga'), expand to full Interface path
			if meta and meta ~= "" and not meta:lower():find("^interface[\\/]") then
				local rel = meta:gsub("/", "\\")
				meta = ("Interface\\AddOns\\%s\\%s"):format(addonName, rel)
			end
			local ok = tryPortrait(meta)
			if not ok then ok = tryPortrait("Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\media\\logo.tga") end
			if not ok then ok = tryPortrait("Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\media\\logo.blp") end
			if not ok then ok = tryPortrait("Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\logo.tga") end
			if not ok then ok = tryPortrait("Interface\\AddOns\\AdvancedHotkeyOverlaySystem\\logo.blp") end
			if not ok then
				tryPortrait("Interface\\Icons\\INV_Misc_QuestionMark")
				self._portraitPath = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
			if self.portrait.SetTexCoord then self.portrait:SetTexCoord(0, 1, 0, 1) end
		end
		frame:ApplyPortrait()

		-- Tooltip on hover to show the chosen icon path and a quick tip
		frame.portrait:EnableMouse(true)
		frame.portrait:SetScript("OnEnter", function()
			if not GameTooltip then return end
			GameTooltip:SetOwner(frame.portrait, "ANCHOR_RIGHT")
			local L = addon and addon.L or {}
			GameTooltip:AddLine(L.AHOS_PORTRAIT or "AHOS Portrait", 1, 0.82, 0)
			local meta = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "IconTexture")) or (GetAddOnMetadata and GetAddOnMetadata(addonName, "IconTexture"))
			if meta and meta ~= "" then GameTooltip:AddLine((L.TOC_ICON_TEXTURE or "TOC IconTexture:") .. " "..tostring(meta), 0.9, 0.9, 0.9, true) end
			GameTooltip:AddLine((L.USING_TEXTURE or "Using:") .. " "..tostring(frame._portraitPath or (L.NONE or "(none)")), 0.9, 0.9, 0.9, true)
			GameTooltip:AddLine(L.TIP_PORTRAIT_FORMAT or "Tip: Use 128x128 TGA (32-bit, uncompressed) or BLP.", 0.6, 0.6, 0.6, true)
			GameTooltip:Show()
		end)
		frame.portrait:SetScript("OnLeave", function()
			if GameTooltip and GameTooltip:GetOwner() == frame.portrait then GameTooltip:Hide() end
		end)
	end

	local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
	inset:SetPoint("TOPLEFT", 8, -68)
	inset:SetPoint("BOTTOMRIGHT", -8, 28)

	local footer = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	footer:SetPoint("BOTTOM", 0, 10)
	local function updateFooter()
		local ver = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
			or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version"))
			or "unknown"
		local ui = (addon and addon.detectedUI) or "Blizzard"
		local color = (AdvancedHotkeyOverlaySystem and AdvancedHotkeyOverlaySystem.UI_DETECTED_COLORS and AdvancedHotkeyOverlaySystem.UI_DETECTED_COLORS[ui]) or "ffffffff"
		footer:SetText(string.format("Version %s • UI: |c%s%s|r", tostring(ver), tostring(color), tostring(ui)))
	end
	updateFooter()
	frame:SetScript("OnShow", function()
		-- Re-apply portrait and footer when the frame shows
		if frame.portrait then
			frame:ApplyPortrait()
		end
		updateFooter()
	end)

	local nav = CreateFrame("Frame", nil, inset, "BackdropTemplate")
	nav:SetPoint("TOPLEFT", 8, -8)
	nav:SetPoint("BOTTOMLEFT", 8, 8)
	nav:SetWidth(220)

	local navBG = nav:CreateTexture(nil, "BACKGROUND")
	navBG:SetAllPoints(true)
	navBG:SetColorTexture(0, 0, 0, 0.35)

	local sections = {
		{ key = "general",  text = L.GENERAL or "General" },
		{ key = "display",  text = L.DISPLAY or "Display" },
		{ key = "keybinds", text = L.KEYBINDS or "Keybinds" },
		{ key = "profiles", text = L.PROFILES or "Profiles" },
		{ key = "integration", text = L.INTEGRATION or "Integration" },
		{ key = "advanced", text = L.ADVANCED or "Advanced" },
		{ key = "help", text = L.HELP or "Help" },
		{ key = "about", text = L.ABOUT or "About" },
		{ key = "changelog", text = L.CHANGELOG or "Changelog" },
	}

	local right = CreateFrame("Frame", nil, inset, "BackdropTemplate")
	right:SetPoint("TOPLEFT", nav, "TOPRIGHT", 8, 0)
	right:SetPoint("BOTTOMRIGHT", -8, 8)
	right:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 14,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})

	local header = right:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	header:SetPoint("TOPLEFT", 4, -4)
	header:SetText("")

	local scroll = CreateFrame("ScrollFrame", nil, right, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, -28)
	scroll:SetPoint("BOTTOMRIGHT", -28, 0)
	local content = CreateFrame("Frame", nil, scroll, "BackdropTemplate")
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)

	-- Ace host frame to mirror AceGUI settings directly when desired
	local aceHost = CreateFrame("Frame", nil, right)
	aceHost:SetPoint("TOPLEFT", 6, -28)
	aceHost:SetPoint("BOTTOMRIGHT", -6, 4)
	aceHost:Hide()
	local aceContainer -- AceGUI SimpleGroup to host ACD

	-- Helper: does the embedded Ace container currently have visible content?
	local function AceHasContent()
		if not aceContainer or not aceContainer.frame then return false end
		local f = aceContainer.frame
		-- Consider content present if there are children or regions created
		return (f.GetNumChildren and f:GetNumChildren() or 0) > 0 or (f.GetNumRegions and f:GetNumRegions() or 0) > 0
	end

	local frames = {}
	local navButtons = {}

	local function showNativeSection(key)
		for _, f in pairs(frames) do f:Hide() end
		local titles = {
			general = L.GENERAL or "General",
			display = L.DISPLAY or "Display",
			keybinds = L.KEYBINDS or "Keybinds",
			profiles = L.PROFILES or "Profiles",
			integration = L.INTEGRATION or "Integration",
			advanced = L.ADVANCED or "Advanced",
			help = L.HELP or "Help",
			about = L.ABOUT or "About",
			changelog = L.CHANGELOG or "Changelog",
		}
		header:SetText(titles[key] or (L.UNKNOWN or key:gsub("^%l", string.upper)))
		-- Always rebuild section to ensure values reflect latest DB state
		local old = frames[key]
		if old then old:Hide(); old:SetParent(nil); frames[key] = nil end
		local f = CreateFrame("Frame", nil, content, "BackdropTemplate")
		f:SetPoint("TOPLEFT", 0, 0)
		f:SetPoint("TOPRIGHT", 0, 0)
		f:SetHeight(1)
		frames[key] = f
		if key == "general" then
			BuildSection_General(f)
		elseif key == "display" then
			BuildSection_Display(f)
		elseif key == "keybinds" then
			BuildSection_Keybinds(f)
		elseif key == "integration" then
			BuildSection_Integration(f)
		elseif key == "advanced" then
			BuildSection_Advanced(f)
		elseif key == "help" then
			BuildSection_Help(f)
		elseif key == "about" then
			BuildSection_About(f)
		elseif key == "changelog" then
			BuildSection_Changelog(f)
		else
			local txt = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
			txt:SetPoint("TOPLEFT", 8, -8)
			txt:SetText(L.FUTURE_SECTION or "This section will be expanded in a future update.")
			f._height = 60
		end
		f:SetHeight(f._height or 400)
		f:Show()
		content:SetHeight((f._height or 400) + 10)
		scroll:UpdateScrollChildRect()
		local prefTbl = db.ui and db.ui.jui or {}
		prefTbl.section = key
		for _, b in ipairs(navButtons) do
			if b._key == key then b:Disable() else b:Enable() end
		end
	end

	local function showAceSection(key)
		if not (ACD and AceGUI) then return false end
		-- Map JUI keys to Ace options group paths
		local paths = {
			general = { "toggles" },
			display = { "display" },
			keybinds = { "text" },
			profiles = { "profiles" },
			integration = { "integration" },
			advanced = { "advanced" },
			help = { "help" },
			about = { "about" },
			changelog = { "changelog" },
		}
		local path = paths[key]
		if not path then return false end
		-- Switch UI areas: hide native scroll, show ace host
		for _, f in pairs(frames) do f:Hide() end
		scroll:Hide()
		aceHost:Show()
		local titles = {
			general = L.GENERAL or "General",
			display = L.DISPLAY or "Display",
			keybinds = L.KEYBINDS or "Keybinds",
			profiles = L.PROFILES or "Profiles",
			integration = L.INTEGRATION or "Integration",
			advanced = L.ADVANCED or "Advanced",
			help = L.HELP or "Help",
			about = L.ABOUT or "About",
			changelog = L.CHANGELOG or "Changelog",
		}
		header:SetText(titles[key] or (L.UNKNOWN or key:gsub("^%l", string.upper)))
		local appName = _G.AHOS_OPTIONS_PANEL_NAME or addonName
		-- Create an AceGUI container on demand
		if not aceContainer then
			aceContainer = AceGUI:Create("SimpleGroup")
			aceContainer:SetLayout("Fill")
			aceContainer.frame:SetParent(aceHost)
			aceContainer.frame:ClearAllPoints()
			aceContainer.frame:SetPoint("TOPLEFT", aceHost, "TOPLEFT", 0, 0)
			aceContainer.frame:SetPoint("BOTTOMRIGHT", aceHost, "BOTTOMRIGHT", 0, 0)
		end
		local function openAce()
			ACD:Open(appName, aceContainer)
			if path then ACD:SelectGroup(appName, unpack(path)) end
			-- Hide the Ace tree when embedded; we only want the right content panel.
			local dlg = ACD.OpenFrames and ACD.OpenFrames[appName]
			if dlg and dlg.frame then
				-- Known layout: dlg.tree is the left container; treeframe may exist depending on Ace version
				local tree = dlg.treeframe or dlg.tree
				if tree and tree.Hide then tree:Hide() end
				-- Expand the content area to the full width
				if dlg.content and dlg.content.SetPoint then
					dlg.content:ClearAllPoints()
					dlg.content:SetPoint("TOPLEFT", dlg.frame, "TOPLEFT", 0, -10)
					dlg.content:SetPoint("BOTTOMRIGHT", dlg.frame, "BOTTOMRIGHT", 0, 0)
				end
			end
		end
		openAce()
		-- Resilience: ensure content appears; if not, retry briefly, then fallback
		local function verifyOrFallback(retries)
			retries = retries or 0
			if AceHasContent() then return end
			if retries < 2 then
				if C_Timer and C_Timer.After then
					C_Timer.After(0.15, function() openAce(); verifyOrFallback(retries + 1) end)
				end
			else
				-- Fallback to native builder if Ace still empty
				aceHost:Hide(); scroll:Show(); showNativeSection(key)
			end
		end
		if C_Timer and C_Timer.After then C_Timer.After(0, function() verifyOrFallback(0) end) end
		local prefTbl = db.ui and db.ui.jui or {}
		prefTbl.section = key
		for _, b in ipairs(navButtons) do
			if b._key == key then b:Disable() else b:Enable() end
		end
		return true
	end

	local currentKey
	local function showSection(key)
		-- Render using native builders only (no embedded Ace UI)
		aceHost:Hide()
		scroll:Show()
		showNativeSection(key)
		currentKey = key
	end

	local last
	for _, info in ipairs(sections) do
		local b = CreateFrame("Button", nil, nav, "GameMenuButtonTemplate")
		b:SetText(info.text)
		b:SetSize(200, 24)
		if last then b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -6) else b:SetPoint("TOPLEFT", 10, -10) end
		b._key = info.key
		b:SetScript("OnClick", function() showSection(info.key) end)
		last = b
		table.insert(navButtons, b)
	end

	showSection(section or (db.ui and db.ui.jui and db.ui.jui.section) or "general")

	local close = frame.CloseButton or frame.close
	if close then
		close:SetScript("OnClick", function()
			local p, _, rp, x, y = frame:GetPoint(1)
			if p then pref.point, pref.relPoint, pref.x, pref.y = p, rp or p, x or 0, y or 0 end
			pref.w, pref.h = math.floor(frame:GetWidth()+0.5), math.floor(frame:GetHeight()+0.5)
			if ACD then ACD:Close(_G.AHOS_OPTIONS_PANEL_NAME or addonName) end
			if aceContainer and aceContainer.Release then aceContainer:Release() aceContainer = nil end
			frame:Hide()
		end)
	end

	-- If the frame becomes shown after being hidden (or UI reloads parts), re-render the current section
	frame:HookScript("OnShow", function()
		if currentKey then
			showSection(currentKey)
		end
	end)

	frame:HookScript("OnHide", function()
		-- Persist geometry and ensure AceDialog is properly closed to prevent empty embeds later
		local p, _, rp, x, y = frame:GetPoint(1)
		if p then pref.point, pref.relPoint, pref.x, pref.y = p, rp or p, x or 0, y or 0 end
		pref.w, pref.h = math.floor(frame:GetWidth()+0.5), math.floor(frame:GetHeight()+0.5)
		if ACD then ACD:Close(_G.AHOS_OPTIONS_PANEL_NAME or addonName) end
		if aceContainer and aceContainer.Release then aceContainer:Release(); aceContainer = nil end
	end)

	-- Expose a refresh method on the addon to sync UI with DB changes coming from elsewhere (e.g., Ace options)
	addon.RefreshJUI = function()
		if frame and frame:IsShown() and currentKey then
			showSection(currentKey)
		end
	end
end
