-- Run from the addon folder: lua Tools/TestLocales.lua (Lua 5.1).
--
-- Every locale file loads on its own client, every string the modules ask for
-- by name (L.SOME_KEY or "English") is in enUS, and every translated string keeps
-- the %s and %d of its English one, in order.
local checks = 0
local function check(value, message)
  if not value then error("FAILED: " .. message, 2) end
  checks = checks + 1
end

local LOCALES = { "enUS", "deDE", "esES", "esMX", "frFR", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }
-- Strings the modules have always carried in English only; new ones may not join them.
local ENGLISH_ONLY = {
  EASTER_EGG_JUNNEZ = true, PRAISE_JUNNEZ = true, SLASH_CLASSIC = true,
}

local function read(path)
  local f = assert(io.open(path, "rb"))
  local text = f:read("*a")
  f:close()
  return text
end

-- Loads enUS and then `locale`, as the client would on that locale.
local function Load(locale)
  local env = setmetatable({ GetLocale = function() return locale end }, { __index = _G })
  env._G = env
  for _, name in ipairs({ "enUS", locale }) do
    if name ~= "enUS" or locale == "enUS" or true then
      local chunk = assert(loadfile("locales/" .. name .. ".lua"))
      setfenv(chunk, env)
      local ok, err = pcall(chunk)
      check(ok, name .. ".lua loads: " .. tostring(err))
      if name == locale then break end
    end
  end
  return env.AHOS_L
end

local function Specs(s)
  local out = {}
  for spec in tostring(s):gmatch("%%[sd]") do out[#out + 1] = spec end
  return table.concat(out)
end

local english = Load("enUS")
check(type(english) == "table", "enUS makes the table")

-- Every key the modules ask for.
-- every module file the Mainline TOC loads, so a new one is never missed
local sources = { "AdvancedHotkeyOverlaySystem.lua" }
for line in read("AdvancedHotkeyOverlaySystem_Mainline.toc"):gmatch("[^\r\n]+") do
  local file = line:match("^modules\\(.+%.lua)$")
  if file then sources[#sources + 1] = "modules/" .. file end
end
check(#sources > 15, "the module files are read from the TOC: " .. #sources)
local used = {}
for _, path in ipairs(sources) do
  local text = read(path)
  for key in text:gmatch("[%w_%.]*L%.([A-Z][A-Z0-9_]+)%s+or%s") do used[key] = true end
end
local missing = {}
for key in pairs(used) do
  if english[key] == nil and not ENGLISH_ONLY[key] then missing[#missing + 1] = key end
end
table.sort(missing)
check(#missing == 0, "strings asked for but not in enUS (add them to Tools/translations_roadmap.py): " .. table.concat(missing, ", "))

-- Every other locale has every generated string, with the same format specs.
local generated = {}
local en = read("locales/enUS.lua")
local block = en:match("%-%- BEGIN options window strings %(generated%)(.-)%-%- END options window strings")
check(block, "enUS has the generated block")
for key in block:gmatch("\nL%.([A-Z][A-Z0-9_]+) =") do generated[#generated + 1] = key end
check(#generated > 100, "the generated block has the module strings: " .. #generated)

for _, locale in ipairs(LOCALES) do
  if locale ~= "enUS" then
    local L = Load(locale)
    for _, key in ipairs(generated) do
      local text = rawget(L, key)
      check(type(text) == "string" and text ~= "", locale .. " translates " .. key)
      check(Specs(text) == Specs(english[key]), locale .. " keeps the format of " .. key .. ": " .. tostring(text))
    end
  end
end

print(string.format("TestLocales: %d checks passed (%d locales, %d strings)", checks, #LOCALES, #generated))
