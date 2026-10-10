--[[

	The MIT License (MIT)

	Copyright (c) 2026 Jonas "JuNNeZ" Andersen

--]]
-- Which settings differ from their defaults: the gem on a row, the dot beside a page
-- and the tally in the window.
--
-- JuNNeZ Edition looks a default up by the option's key. AzUI's getters read nested
-- settings (the Cast Bar list reads profile.cast.mode), so that cannot work here.
-- Instead the getter itself is asked twice: once with your profile, once with a fresh
-- copy of the defaults put in its place for that moment. A getter that does not read
-- the profile (the window's own look, a pet's name) answers the same both times and
-- is never marked; one that cannot answer from the defaults (a rule's colour) is
-- "unknown", which shows no gem either.
local Addon, ns = ...

local Kit = ns.OptionsKit
local Config = Kit and Kit.Config
local P = ns.P
if not (Config and P) then return end

local abs, pairs, pcall, rawset, select, type, unpack = math.abs, pairs, pcall, rawset, select, type, unpack

local Defaults = {}
Kit.Defaults = Defaults

local APP = Addon

-- Settings only; a typed-in line (the share string, a preset's name) is not one.
local SKIPPED = { group = true, header = true, description = true, execute = true, input = true, multiselect = true }

local function Copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do out[k] = Copy(v) end
  return out
end

-- Runs fn with the defaults standing in for your profile, and puts your profile back.
local function WithDefaults(fn)
  local db = P.DB
  if type(db) ~= "table" or type(P.defaults) ~= "table" then return false end
  local real = db.profile -- reading it makes AceDB build it, so there is one to put back
  rawset(db, "profile", Copy(P.defaults.profile))
  local ok, err = pcall(fn)
  rawset(db, "profile", real)
  return ok, err
end

local function Pack(...) return { n = select("#", ...), ... } end

-- Everything the getter answers, or nil when it cannot answer.
local function Read(option, options, path)
  local result = Pack(pcall(Config.GetValue, option, options, path, APP))
  if not result[1] then return end
  return { n = result.n - 1, select(2, unpack(result, 1, result.n)) }
end

-- Colours come back as four numbers that went through a colour picker, so a hair's
-- difference is no difference.
local function SameValue(a, b)
  if a == b then return true end
  if type(a) == "number" and type(b) == "number" then return abs(a - b) < 0.0005 end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, v in pairs(a) do if not SameValue(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function Same(a, b)
  local n = math.max(a.n, b.n)
  for i = 1, n do
    if not SameValue(a[i], b[i]) then return false end
  end
  return true
end
Defaults.Same = SameValue

-- An option can say for itself whether it differs (the family and specialization colours).
local function OwnAnswer(option)
  local meta = ns.PanelMeta and ns.PanelMeta[option]
  if meta and type(meta.modified) == "function" then
    local ok, modified = pcall(meta.modified)
    return true, ok and modified and true or false
  end
end

-- What the option would show with the defaults, or nil when that is unknown.
Defaults.Get = function(options, path)
  local option = type(path) == "table" and #path > 0 and Config.GetGroup(options, path)
  if type(option) ~= "table" or SKIPPED[option.type] then return end
  local value
  WithDefaults(function() value = Read(option, options, path) end)
  return value
end

-- true, false, or nil for "no idea": a setting whose default is unknown is not marked.
Defaults.IsModified = function(options, path)
  local option = type(path) == "table" and #path > 0 and Config.GetGroup(options, path)
  if type(option) ~= "table" or SKIPPED[option.type] then return end
  local answered, modified = OwnAnswer(option)
  if answered then return modified end
  local current = Read(option, options, path)
  local default = current and Defaults.Get(options, path)
  if not default then return end
  return not Same(current, default)
end

-- Puts one setting back, through its own setter, so whatever it updates is updated.
Defaults.Revert = function(options, path)
  local default = Defaults.Get(options, path)
  if not default then return false end
  local option = Config.GetGroup(options, path)
  return (pcall(Config.SetValue, option, options, path, APP, unpack(default, 1, default.n)))
end

-- How many settings under a group differ from their defaults.
Defaults.CountModified = function(options, path)
  local group = Config.GetGroup(options, path)
  if type(group) ~= "table" then return 0 end

  local leaves = {}
  local function Walk(node, nodePath)
    Config.ForEachChild(node, options, nodePath, APP, function(_, option, childPath)
      if option.type == "group" then return Walk(option, childPath) end
      if SKIPPED[option.type] then return end
      local copy = {}
      for i = 1, #childPath do copy[i] = childPath[i] end
      leaves[#leaves + 1] = { option = option, path = copy }
    end)
  end
  local start = {}
  for i = 1, #path do start[i] = path[i] end
  Walk(group, start)

  local count, asked = 0, {}
  for i, leaf in ipairs(leaves) do
    local answered, modified = OwnAnswer(leaf.option)
    if answered then
      if modified then count = count + 1 end
    else
      leaf.current = Read(leaf.option, options, leaf.path)
      if leaf.current then asked[#asked + 1] = leaf end
    end
    leaves[i] = leaf
  end
  -- every default in one go, with the defaults standing in once
  WithDefaults(function()
    for _, leaf in ipairs(asked) do leaf.default = Read(leaf.option, options, leaf.path) end
  end)
  for _, leaf in ipairs(asked) do
    if leaf.default and not Same(leaf.current, leaf.default) then count = count + 1 end
  end
  return count
end
