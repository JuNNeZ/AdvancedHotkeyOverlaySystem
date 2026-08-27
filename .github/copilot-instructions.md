# AI Coding Agent Instructions for AHOS

## Project Overview
This is a **World of Warcraft addon** using the Ace3 framework that provides customizable hotkey overlays for action bars. It supports multiple WoW versions (Retail, Classic, Mists) and various UI addons (ElvUI, Bartender4, Dominos, etc.).

## Critical Architecture Patterns

### File Load Order Dependencies (CRITICAL)
**Never modify TOC file order without understanding dependencies.** The `.toc` files define strict loading sequences:
1. Libraries (`Libs/` - Ace3, LibStub, etc.)
2. Locales (`locales/`)  
3. Main addon file (`AdvancedHotkeyOverlaySystem.lua`)
4. Modules in dependency order (`modules/Config.lua` → `modules/Core.lua` → others)

Breaking this order causes `nil` errors and addon failures.

### SafeCall Initialization Pattern
Modules use `addon:SafeCall(moduleName, func, ...)` to handle initialization dependencies:
```lua
-- Queue calls if addon not ready, execute immediately if ready
addon:SafeCall("Core", "FullUpdate")
addon:SafeCall("Config", "DetectUI")
```

### Module Template Structure
New modules must follow the pattern in `modules/ModuleTemplate.lua`:
- Register with `addon:NewModule("ModuleName", "AceEvent-3.0")`
- Use `OnEnable()` with dependency checking
- Wait for `AHOS_CONFIG_READY` message before accessing settings
- Store settings in `self.db` referencing `addon.db.profile.modulename`

## WoW-Specific Patterns

### Combat Lockdown Handling
**Always check combat state before UI modifications:**
```lua
if InCombatLockdown() then
    if self.db.profile.debug then self:Print("Action deferred during combat.") end
    return
end
```

### UI Detection System
The `Config` module detects active UI addons (ElvUI, Bartender4, etc.) and applies appropriate settings. Access via `addon.detectedUI` or `addon.Config:GetDetectedUI()`.

### TOC Multi-Flavor System
Three TOC files support different WoW versions:
- `AdvancedHotkeyOverlaySystem_Mainline.toc` (Retail)
- `AdvancedHotkeyOverlaySystem_Mists.toc` (MoP Classic)  
- `AdvancedHotkeyOverlaySystem_Vanilla.toc` (Classic Era)

The base `.toc` is for development only (excluded from packaging).

## Development Workflow

### Linting and Validation
Use the VS Code task: `"AHOS: Lint Lua"` or run:
```powershell
pwsh -NoProfile -File .vscode/scripts/lint-lua.ps1
```

### Debug Tools
- `/ahoslog` - Opens debug log window
- `/ahos debug` - Toggle debug mode
- `/ahos inspect <ButtonName>` - Debug specific buttons
- `/ahos debugexport` - Export profile data

### Version Management
Version is defined in TOC metadata. Use `GetAddOnMetadata(addonName, "Version")` to read programmatically.

## Key Integration Points

### Options System
Options use AceConfig with the pattern:
```lua
local function getSafeProfile()
    return (addon and addon.db and addon.db.profile) or {}
end

-- All option getters/setters use getSafeProfile()
get = function() local db = getSafeProfile() return db.someField end
set = function(_, val) local db = getSafeProfile() db.someField = val end
```

### Event Registration
Use the modular event pattern:
```lua
function Module:OnEnable()
    self:RegisterEvent("SOME_EVENT", "HandlerMethod")
    self:RegisterMessage("AHOS_CONFIG_READY", "OnConfigReady") 
end
```

### Localization
Locales populate `_G.AHOS_L` which becomes `addon.L`. Always provide fallbacks:
```lua
local L = addon and addon.L or {}
text = L.SOME_KEY or "Default English Text"
```

## Common Pitfalls to Avoid

1. **Don't** modify module load order in TOC files without understanding dependencies
2. **Don't** access `addon.db` before checking if it exists (use `getSafeProfile()`)
3. **Don't** perform UI operations during combat lockdown
4. **Don't** register events in module constructors - use `OnEnable()`
5. **Don't** hardcode version numbers - read from TOC metadata
6. **Always** use `SafeCall` for cross-module communication during initialization

## Release Process
Automated via GitHub Actions on version tags. Packages three flavors and uploads to CurseForge/WoWInterface/Wago. See `RELEASE.md` for full checklist.