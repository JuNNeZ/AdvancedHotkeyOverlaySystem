-- Runs every test suite against every client the addon ships for (Lua 5.1).
-- Run from the addon folder:
--
--   lua Tools/RunTests.lua              all suites, all clients
--   lua Tools/RunTests.lua TestCore     one suite, all clients
--
-- Each suite runs in a process of its own, so one client's globals never leak
-- into the next. Exits non-zero when anything fails, for CI.
local SUITES = { "TestPanel", "TestCore", "TestLocales" }
local TOCS = {
  "AdvancedHotkeyOverlaySystem_Mainline.toc",
  "AdvancedHotkeyOverlaySystem_Camelot.toc",
  "AdvancedHotkeyOverlaySystem_Mists.toc",
  "AdvancedHotkeyOverlaySystem_Vanilla.toc",
}
-- suites that do not load a client
local ONCE = { TestLocales = true }

local lua = arg and arg[-1] or "lua"
local only = arg and arg[1]
local windows = package.config:sub(1, 1) == "\\"

local function quote(s)
  if windows then return '"' .. s .. '"' end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local failed, ran = 0, 0
for _, suite in ipairs(SUITES) do
  if not only or only == suite then
    for i, toc in ipairs(TOCS) do
      if not ONCE[suite] or i == 1 then
        local command = quote(lua) .. " " .. quote("Tools/" .. suite .. ".lua") .. (ONCE[suite] and "" or (" " .. toc))
        if windows then command = '"' .. command .. '"' end
        local pipe = io.popen(command .. " 2>&1")
        local output = pipe:read("*a")
        local ok = pipe:close()
        -- Lua 5.1's close does not say how the process ended; a passing suite
        -- always ends with its summary line.
        local passed = output:find("checks passed") and not output:find("FAILED")
        ran = ran + 1
        if passed then
          io.write("ok    ", output:match("[^\n]*checks passed[^\n]*") or suite, "\n")
        else
          failed = failed + 1
          io.write("FAIL  ", suite, " (", toc, ")\n", output, "\n")
        end
      end
    end
  end
end

io.write(string.format("\n%d of %d runs passed\n", ran - failed, ran))
os.exit(failed == 0 and 0 or 1)
