-- A mock WoW client for the scripts in Tools/ (Lua 5.1). Run from the addon folder.
--
--   local Mock = dofile("Tools/Mock.lua")
--   local game = Mock.New({ toc = "AdvancedHotkeyOverlaySystem_Mainline.toc" })
--
-- Loads every file the TOC lists, in its order, with one shared namespace. The
-- pure-Lua Ace3 libraries (AceAddon, AceDB, AceDBOptions, AceEvent, AceTimer,
-- AceConsole, CallbackHandler, LibStub) are the real ones from Libs/; the ones that
-- draw frames (AceGUI, AceConfigDialog, LibDBIcon) are stand-ins. Frames record
-- their scripts, colours, textures and text, so tests can read what was drawn.
local Mock = {}

local ADDON = "AdvancedHotkeyOverlaySystem"

function Mock.New(opts)
  opts = opts or {}
  local game = { frames = {}, events = {}, timers = {}, time = 0, printed = {}, errors = {} }
  local frames, events = game.frames, game.events

  -------------------------------------------------------------------------
  -- Widgets
  -------------------------------------------------------------------------
  local Widget = {}
  function game.TextWidth(fs)
    local text = tostring(rawget(fs, "text") or "")
    local chars = #text:gsub("[\128-\191]", "")
    local size = 12
    local object = rawget(fs, "fontObject")
    local named = object and tonumber(tostring(rawget(object, "name") or ""):match("(%d+)$"))
    if named then size = named elseif rawget(fs, "font") then size = fs.font[2] or 12 end
    return chars * size / 2
  end
  local function NewWidget(kind, name, parent)
    local w = setmetatable({ kind = kind, name = name, parent = parent, shown = true, scripts = {},
      width = 600, height = 20, level = 1, text = "", points = {}, scale = 1, alpha = 1 }, Widget)
    frames[#frames + 1] = w
    if type(parent) == "table" and rawget(parent, "kind") then
      local list = (kind == "FontString" or kind == "Texture" or kind == "MaskTexture") and "regions" or "children"
      parent[list] = rawget(parent, list) or {}
      table.insert(parent[list], w)
    end
    return w
  end
  game.NewWidget = NewWidget
  local methods = {
    Show = function(self) local was = self.shown; self.shown = true; if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end,
    Hide = function(self) local was = self.shown; self.shown = false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end,
    SetShown = function(self, v) if v then self:Show() else self:Hide() end end,
    IsShown = function(self) return self.shown end,
    IsVisible = function(self) return self.shown end,
    SetScript = function(self, k, f) self.scripts[k] = f end,
    GetScript = function(self, k) return self.scripts[k] end,
    HookScript = function(self, k, f)
      local old = self.scripts[k]
      self.scripts[k] = function(...) if old then old(...) end f(...) end
    end,
    SetText = function(self, t) self.text = t end,
    GetText = function(self) return self.text end,
    SetFormattedText = function(self, f, ...) self.text = string.format(f, ...) end,
    GetStringHeight = function() return 13 end,
    -- about half the font's size per character (12 px text: 6 px a character), counted
    -- in characters, not UTF-8 bytes; a font object's size is the number its name ends in
    GetStringWidth = function(self) return game.TextWidth(self) end,
    GetUnboundedStringWidth = function(self) return game.TextWidth(self) end,
    GetNumLines = function() return 1 end,
    SetWidth = function(self, v) self.width = v end,
    SetHeight = function(self, v) self.height = v end,
    SetSize = function(self, w, h) self.width, self.height = w, h end,
    GetWidth = function(self) return self.width end,
    GetHeight = function(self) return self.height end,
    GetSize = function(self) return self.width, self.height end,
    GetCenter = function() return 100, 100 end,
    GetTop = function() return 500 end,
    GetBottom = function() return 100 end,
    GetLeft = function() return 100 end,
    GetRight = function() return 700 end,
    GetFrameLevel = function(self) return self.level end,
    SetFrameLevel = function(self, v) self.level = v end,
    GetFrameStrata = function(self) return self.strata or "MEDIUM" end,
    SetFrameStrata = function(self, v) self.strata = v end,
    CreateTexture = function(self, _, layer) local t = NewWidget("Texture", nil, self); t.layer = layer; return t end,
    CreateMaskTexture = function(self) return NewWidget("MaskTexture", nil, self) end,
    CreateFontString = function(self) return NewWidget("FontString", nil, self) end,
    CreateAnimationGroup = function(self) return NewWidget("AnimationGroup", nil, self) end,
    CreateAnimation = function(self) return NewWidget("Animation", nil, self) end,
    GetVerticalScrollRange = function() return 0 end,
    GetVerticalScroll = function() return 0 end,
    GetHorizontalScroll = function() return 0 end,
    GetPoint = function(self) local p = self.points[1]; if p then return unpack(p) end return "CENTER", nil, "CENTER", 0, 0 end,
    GetNumPoints = function(self) return #self.points end,
    GetParent = function(self) return self.parent end,
    SetParent = function(self, p) self.parent = p end,
    GetChildren = function(self) return unpack(rawget(self, "children") or {}) end,
    GetRegions = function(self) return unpack(rawget(self, "regions") or {}) end,
    EnableMouse = function(self, on) self.mouse = on and true or false end,
    IsMouseEnabled = function(self) return self.mouse == true end,
    IsMouseOver = function(self) return game.mouseOver == self end,
    GetEffectiveAlpha = function(self)
      local a, f = 1, self
      while f do a = a * (rawget(f, "alpha") or 1); f = rawget(f, "parent") end
      return a
    end,
    GetName = function(self) return self.name end,
    GetDebugName = function(self) return self.name or "?" end,
    -- a file with "Missing" in its path does not load, as a removed addon's font would not
    SetFont = function(self, file, size, flags)
      if type(file) ~= "string" or file:find("Missing", 1, true) then return false end
      self.font = { file, size, flags }; return true
    end,
    -- a font object made by CreateFont has no font until one loads; other widgets inherit one
    GetFont = function(self)
      local f = self.font
      if not f then
        if self.kind == "Font" then return nil end
        return "Fonts\\FRIZQT__.TTF", 12, ""
      end
      return f[1], f[2], f[3]
    end,
    SetFontObject = function(self, font) self.fontObject = font end,
    GetFontObject = function(self) return self.fontObject end,
    -- one box has the caret at a time, as in the client
    HasFocus = function(self) return game.keyboardFocus == self end,
    SetFocus = function(self) game.keyboardFocus = self end,
    ClearFocus = function(self) if game.keyboardFocus == self then game.keyboardFocus = nil end end,
    EnableKeyboard = function(self, on) self.keyboard = on and true or false end,
    GetEffectiveScale = function() return 1 end,
    GetScale = function(self) return self.scale end,
    SetScale = function(self, v) self.scale = v end,
    GetObjectType = function(self) return self.kind end,
    IsObjectType = function(self, kind) return self.kind == kind end,
    IsForbidden = function() return false end,
    Enable = function(self) self.disabled = false end,
    Disable = function(self) self.disabled = true end,
    IsEnabled = function(self) return not self.disabled end,
    SetVertexColor = function(self, r, g, b, a) self.vertex = { r, g, b, a } end,
    SetColorTexture = function(self, r, g, b, a) self.colorTexture = { r, g, b, a } end,
    SetTextColor = function(self, r, g, b, a) self.textColor = { r, g, b, a } end,
    GetTextColor = function(self) local c = self.textColor or {}; return c[1], c[2], c[3], c[4] end,
    SetAlpha = function(self, a) self.alpha = a end,
    GetAlpha = function(self) return self.alpha end,
    SetChecked = function(self, v) self.checked = v end,
    GetChecked = function(self) return self.checked end,
    SetPoint = function(self, ...) self.points[#self.points + 1] = { ... } end,
    SetAllPoints = function(self, to) self.points = { { "ALL", to } } end,
    ClearAllPoints = function(self) self.points = {} end,
    SetTexture = function(self, file) self.texture = file; return true end,
    GetTexture = function(self) return self.texture end,
    SetTexCoord = function(self, ...) self.texCoord = { ... } end,
    SetTextureSliceMargins = function(self, ...) self.slice = { ... } end,
    SetBackdrop = function(self, b) self.backdrop = b end,
    SetBackdropColor = function(self, ...) self.backdropColor = { ... } end,
    SetBackdropBorderColor = function(self, ...) self.backdropBorder = { ... } end,
    GetMinMaxValues = function(self) return self.min or 0, self.max or 1 end,
    SetMinMaxValues = function(self, a, b) self.min, self.max = a, b end,
    SetValue = function(self, v) self.value = v end,
    GetValue = function(self) return self.value or 0 end,
    SetValueStep = function(self, v) self.step = v end,
    GetStatusBarTexture = function(self) self.bar = self.bar or NewWidget("Texture", nil, self); return self.bar end,
    SetScrollChild = function(self, child) self.child = child end,
    GetScrollChild = function(self) return self.child end,
    RegisterEvent = function(self, event)
      events[event] = events[event] or {}
      for _, f in ipairs(events[event]) do if f == self then return end end
      table.insert(events[event], self)
    end,
    UnregisterEvent = function(self, event)
      local list = events[event] or {}
      for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
    end,
    UnregisterAllEvents = function(self)
      for _, list in pairs(events) do
        for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
      end
    end,
    IsEventRegistered = function(self, event)
      for _, f in ipairs(events[event] or {}) do if f == self then return true end end
      return false
    end,
  }
  methods.RegisterUnitEvent = methods.RegisterEvent
  -- Methods start with a capital; anything else is a data field the code set itself.
  Widget.__index = function(_, key)
    if methods[key] then return methods[key] end
    if type(key) == "string" and key:match("^%u") then return function() end end
  end

  -------------------------------------------------------------------------
  -- The client
  -------------------------------------------------------------------------
  local env = setmetatable({}, { __index = _G })
  env._G = env
  game.env = env

  env.CreateFrame = function(kind, name, parent)
    local w = NewWidget(kind, name, parent)
    if name then env[name] = w end
    return w
  end
  env.CreateFont = function(name) local f = NewWidget("Font", name); if name then env[name] = f end; return f end
  env.UIParent = NewWidget("Frame", "UIParent")
  env.UIParent.width, env.UIParent.height = 1920, 1080
  env.WorldFrame = NewWidget("Frame", "WorldFrame")
  for _, name in ipairs({ "GameFontNormal", "GameFontHighlight", "GameFontHighlightSmall", "GameFontNormalSmall", "NumberFontNormal" }) do
    env[name] = NewWidget("Font", name)
    env[name].font = { "Fonts\\FRIZQT__.TTF", 12, "" }
  end
  env.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
  env.GameTooltip = NewWidget("GameTooltip", "GameTooltip")
  env.GameTooltip.lines = {}
  env.GameTooltip.AddLine = function(self, text) table.insert(self.lines, text) end
  env.ColorPickerFrame = NewWidget("Frame", "ColorPickerFrame")
  env.ColorPickerFrame.shown = false
  env.ColorPickerFrame.SetupColorPickerAndShow = function(self, info) self.info = info; self.shown = true end
  env.ColorPickerFrame.GetExtraInfo = function(self) return self.info and self.info.extraInfo end
  env.ColorPickerFrame.GetColorRGB = function() return .1, .2, .3 end
  env.ColorPickerFrame.GetColorAlpha = function() return 1 end
  env.BackdropTemplateMixin = {}
  -- ESC > Options. opts.noSettings is a client without the canvas Settings API.
  env.SettingsPanel = NewWidget("Frame", "SettingsPanel")
  env.HideUIPanel = function(frame) frame:Hide() end
  env.ShowUIPanel = function(frame) frame:Show() end
  if not opts.noSettings then
    env.Settings = {
      RegisterCanvasLayoutCategory = function(frame, name) game.settingsPage = frame; return { name = name } end,
      RegisterAddOnCategory = function(category) game.settingsCategory = category end,
      OpenToCategory = function() end,
    }
  end
  env.UISpecialFrames = {}
  env.StaticPopupDialogs = {}
  game.popups = {}
  env.StaticPopup_Show = function(key, text)
    table.insert(game.popups, { key = key, text = text })
    local dialog = env.StaticPopupDialogs[key]
    if dialog and game.answer ~= false then
      if dialog.OnAccept then dialog.OnAccept({}) end
    elseif dialog and dialog.OnCancel then
      dialog.OnCancel()
    end
    return true
  end
  env.StaticPopup_Hide = function() end
  env.SlashCmdList = {}
  env.hash_SlashCmdList = {}
  env.PlaySound = function() end
  env.PlaySoundFile = function() end
  game.cursor = { 0, 0 }
  env.GetCursorPosition = function() return game.cursor[1], game.cursor[2] end
  env.GetTime = function() return game.time end
  env.GetTimePreciseSec = function() return game.time end
  env.debugprofilestop = function() return game.time * 1000 end
  env.InCombatLockdown = function() return game.lockdown and true or false end
  env.UnitAffectingCombat = function() return game.combat and true or false end
  env.IsLoggedIn = function() return game.loggedIn and true or false end
  env.GetLocale = function() return opts.locale or "enUS" end
  env.IsShiftKeyDown = function() return game.shift and true or false end
  env.GetCurrentKeyBoardFocus = function() return game.keyboardFocus end
  env.IsControlKeyDown = function() return game.ctrl and true or false end
  env.IsAltKeyDown = function() return game.alt and true or false end
  env.IsModifierKeyDown = function() return (game.shift or game.ctrl or game.alt) and true or false end
  env.time = function() return 1700000000 + math.floor(game.time) end
  env.date = os.date
  env.strtrim = function(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
  env.strsplit = function(sep, s, limit)
    local out, start = {}, 1
    while true do
      local i, j = string.find(s, sep, start, true)
      if not i or (limit and #out == limit - 1) then out[#out + 1] = s:sub(start); break end
      out[#out + 1] = s:sub(start, i - 1)
      start = j + 1
    end
    return unpack(out)
  end
  env.strjoin = function(sep, ...) return table.concat({ ... }, sep) end
  env.strmatch, env.strfind, env.strsub, env.strlower, env.strupper, env.format, env.gsub =
    string.match, string.find, string.sub, string.lower, string.upper, string.format, string.gsub
  env.strlen, env.strrep, env.strbyte, env.strchar = string.len, string.rep, string.byte, string.char
  env.tostringall = function(...) local t = { ... } for i = 1, select("#", ...) do t[i] = tostring(t[i]) end return unpack(t, 1, select("#", ...)) end
  env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  env.tinsert, env.tremove, env.tContains = table.insert, table.remove, function(t, v)
    for _, x in pairs(t) do if x == v then return true end end return false
  end
  env.floor, env.ceil, env.max, env.min, env.abs, env.mod = math.floor, math.ceil, math.max, math.min, math.abs, math.fmod
  -- WoW's xpcall passes extra arguments on; Lua 5.1's does not.
  env.xpcall = function(f, handler, ...)
    local n, args = select("#", ...), { ... }
    return xpcall(function() return f(unpack(args, 1, n)) end, handler)
  end
  env.geterrorhandler = function() return function(err) table.insert(game.errors, err) end end
  env.seterrorhandler = function() end
  env.securecallfunction = function(f, ...) return f(...) end
  env.secureexecuterange = function(t, f, ...) for k, v in pairs(t) do f(k, v, ...) end end
  env.issecretvalue = function() return false end
  env.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    table.insert(game.printed, table.concat(parts, " "))
  end
  env.DEFAULT_CHAT_FRAME = NewWidget("Frame", "ChatFrame1")
  env.DEFAULT_CHAT_FRAME.AddMessage = function(_, text) table.insert(game.printed, tostring(text)) end
  env.ChatTypeInfo = { RAID_WARNING = { r = 1, g = .3, b = .1 } }
  env.ReloadUI = function() end
  env.GetBuildInfo = function() return "12.1.0", "1", "", opts.interface or 120100 end
  env.WOW_PROJECT_ID, env.WOW_PROJECT_MAINLINE = 1, 1
  env.NORMAL_FONT_COLOR_CODE, env.HIGHLIGHT_FONT_COLOR_CODE, env.FONT_COLOR_CODE_CLOSE = "|cffffd200", "|cffffffff", "|r"
  env.RED_FONT_COLOR_CODE, env.GREEN_FONT_COLOR_CODE = "|cffff2020", "|cff20ff20"
  env.SAVE, env.CANCEL, env.YES, env.NO, env.ACCEPT, env.OKAY = "Save", "Cancel", "Yes", "No", "Accept", "Okay"
  env.RAID_CLASS_COLORS = { HUNTER = { r = .67, g = .83, b = .45, colorStr = "ffaad372" } }
  env.UnitClass = function() return "Hunter", "HUNTER", 3 end
  env.UnitName = function() return "Tester" end
  env.UnitRace = function() return "Human", "Human" end
  env.UnitFactionGroup = function() return "Alliance", "Alliance" end
  env.GetRealmName = function() return "Realm" end
  env.GetCurrentRegion = function() return 3 end
  env.GetCurrentRegionName = function() return "EU" end
  env.UnitGUID = function() return "Player-1-0001" end
  env.GetSpecialization = function() return 1 end
  env.GetSpecializationInfo = function() return 253, "Beast Mastery" end
  env.C_SpecializationInfo = { GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 253, "Beast Mastery" end }
  -- bindings: command -> key, or command -> { key1, key2 }
  game.bindings = opts.bindings or {}
  env.GetBindingKey = function(command)
    local v = game.bindings[command]
    if type(v) == "table" then return v[1], v[2] end
    return v
  end
  env.GetBindingAction = function(key)
    for command, v in pairs(game.bindings) do
      if v == key or (type(v) == "table" and (v[1] == key or v[2] == key)) then return command end
    end
    return ""
  end
  env.SetBinding = function(key, command)
    for c, v in pairs(game.bindings) do if v == key then game.bindings[c] = nil end end
    if command then game.bindings[command] = key end
    return true
  end
  env.SaveBindings = function() end
  env.GetCurrentBindingSet = function() return 1 end
  -- the game's short key text: "SHIFT-Q" reads "s-Q"
  env.GetBindingText = function(key) return (tostring(key or ""):gsub("SHIFT%-", "s-"):gsub("CTRL%-", "c-"):gsub("ALT%-", "a-")) end
  env.GetNumAddOns = function() return 0 end
  env.C_Timer = {
    After = function(_, f) table.insert(game.timers, f) end,
    NewTimer = function(_, f) local t = { Cancel = function(self) self.cancelled = true end }; table.insert(game.timers, function() if not t.cancelled then f(t) end end); return t end,
    NewTicker = function() return { Cancel = function() end } end,
  }
  env.C_AddOns = {
    GetAddOnMetadata = function(name, key)
      if name == ADDON and key == "Version" then return "2.5.23" end
      if name == ADDON and key == "X-Flavor" then return opts.flavor or "Mainline" end
    end,
    IsAddOnLoaded = function(name) return (opts.loaded or {})[name] and true or false end,
    GetNumAddOns = function() return 0 end,
  }
  env.Enum = { UITextureSliceMode = { Stretched = 0, Tiled = 1 } }
  -- game.actions[slot] = true puts something on an action slot
  game.actions = {}
  env.C_ActionBar = { HasAction = function(slot) return game.actions[slot] and true or false end }
  -- what the game's key bindings for Blizzard's action buttons run
  env.ActionButtonDown = function(id) end
  env.MultiActionButtonDown = function(bar, id) end
  env.hooksecurefunc = function(target, method, hook)
    if type(target) == "string" then target, method, hook = env, target, method end
    local original = target[method]
    if type(original) ~= "function" then return end
    rawset(target, method, function(...)
      local results = { original(...) }
      hook(...)
      return unpack(results)
    end)
  end

  -------------------------------------------------------------------------
  -- Libraries
  -------------------------------------------------------------------------
  local function run(path, ...)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    return chunk(...)
  end
  game.run = run

  -- The pure-Lua ones are real.
  local REAL = {
    ["Libs\\LibStub\\LibStub.lua"] = true,
  }
  local XML = {
    ["Libs\\LibDBIcon-1.0\\CallbackHandler-1.0\\CallbackHandler-1.0.lua"] = "Libs/LibDBIcon-1.0/CallbackHandler-1.0/CallbackHandler-1.0.lua",
    ["Libs\\AceAddon-3.0\\AceAddon-3.0.xml"] = "Libs/AceAddon-3.0/AceAddon-3.0.lua",
    ["Libs\\AceConsole-3.0\\AceConsole-3.0.xml"] = "Libs/AceConsole-3.0/AceConsole-3.0.lua",
    ["Libs\\AceDB-3.0\\AceDB-3.0.xml"] = "Libs/AceDB-3.0/AceDB-3.0.lua",
    ["Libs\\AceDBOptions-3.0\\AceDBOptions-3.0.xml"] = "Libs/AceDBOptions-3.0/AceDBOptions-3.0.lua",
    ["Libs\\AceEvent-3.0\\AceEvent-3.0.xml"] = "Libs/AceEvent-3.0/AceEvent-3.0.lua",
    ["Libs\\AceTimer-3.0\\AceTimer-3.0.xml"] = "Libs/AceTimer-3.0/AceTimer-3.0.lua",
    ["Libs\\LibSerialize-1.2.1\\lib.xml"] = "Libs/LibSerialize-1.2.1/LibSerialize.lua",
    ["Libs\\LibDeflate\\lib.xml"] = "Libs/LibDeflate/LibDeflate.lua",
  }

  local function Stubs()
    local LibStub = env.LibStub
    local function stub(name, t)
      local lib = LibStub:NewLibrary(name, 999999)
      if lib then for k, v in pairs(t) do lib[k] = v end end
    end
    game.dialog = { OpenFrames = {} }
    stub("AceConfigRegistry-3.0", { NotifyChange = function() game.notified = (game.notified or 0) + 1 end,
      RegisterOptionsTable = function() end, GetOptionsTable = function() end })
    stub("AceConfig-3.0", { RegisterOptionsTable = function(_, app, t) game.aceTable = { app = app, t = t } end })
    stub("AceConfigDialog-3.0", { OpenFrames = game.dialog.OpenFrames, BlizOptions = {},
      AddToBlizOptions = function() return NewWidget("Frame"), 1 end,
      Open = function(self, app) self.OpenFrames[app] = true; game.classicOpened = (game.classicOpened or 0) + 1 end,
      Close = function(self, app) self.OpenFrames[app] = nil end })
    stub("AceGUI-3.0", { Create = function() return NewWidget("Frame") end, RegisterAsContainer = function() end })
    stub("LibDataBroker-1.1", { NewDataObject = function(self, name, t) self.objects = self.objects or {}; self.objects[name] = t; return t end,
      GetDataObjectByName = function(self, name) return self.objects and self.objects[name] end })
    stub("LibDBIcon-1.0", { objects = {}, IsRegistered = function() return false end, Register = function() end,
      Show = function() end, Hide = function() end })
    stub("LibSharedMedia-3.0", { List = function() return { "Friz Quadrata TT" } end, Fetch = function() return nil end,
      Register = function() end, HashTable = function() return opts.sharedFonts or {} end, MediaType = { FONT = "font" } })
  end

  local ns = {}
  game.ns = ns
  local toc = assert(io.open(opts.toc or (ADDON .. "_Mainline.toc"), "r"))
  local stubbed = false
  for line in toc:lines() do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      if line:match("^Libs") then
        if REAL[line] then run((line:gsub("\\", "/")))
        elseif XML[line] then
          if not stubbed and env.LibStub then
            -- callbacks first: every Ace library asks for it
            run("Libs/LibDBIcon-1.0/CallbackHandler-1.0/CallbackHandler-1.0.lua")
          end
          run(XML[line])
        end
      else
        if not stubbed then Stubs(); stubbed = true end
        run((line:gsub("\\", "/")), ADDON, ns)
      end
    end
  end
  toc:close()

  function game.fire(event, ...)
    local list = { unpack(events[event] or {}) }
    for _, frame in ipairs(list) do
      if frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
    end
  end
  function game.flush(limit)
    local n = 0
    while #game.timers > 0 and n < (limit or 500) do
      n = n + 1
      table.remove(game.timers, 1)()
    end
  end
  function game.frame(name) return env[name] end

  -- An action button as Blizzard's template makes one: a HotKey label (also the
  -- global <name>HotKey), an action slot, and SetButtonState.
  function game.MakeButton(name, o)
    o = o or {}
    local parent = o.parent or env.UIParent
    local b = env.CreateFrame("CheckButton", name, parent)
    local hk = b:CreateFontString()
    hk.name = name .. "HotKey"
    env[name .. "HotKey"] = hk
    if o.hotkeyField ~= false then b[o.hotkeyField or "HotKey"] = hk end
    b.hotkey = hk
    if o.action then b.action = o.action; game.actions[o.action] = o.empty ~= true end
    b.SetButtonState = function(self, state) self.buttonState = state end
    return b
  end

  if not opts.noLogin then
    game.fire("ADDON_LOADED", ADDON)
    game.loggedIn = true
    game.fire("PLAYER_LOGIN")
    game.fire("PLAYER_ENTERING_WORLD", true, false)
    game.flush()
  end
  game.addon = ns.addon
  return game
end

return Mock
