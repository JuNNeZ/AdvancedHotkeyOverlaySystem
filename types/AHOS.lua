---@meta
-- Type definitions for the Lua language server (LuaLS / sumneko). Not loaded by the
-- game and not packaged: this file only tells the editor what AHOS's tables hold, so
-- a misspelt setting or a wrong argument is underlined as you type.
--
-- The modules are typed where the core file creates them, and every module file
-- types its `addon` local as AHOS, so `Display:`, `Keybinds:` and the rest complete.

---------------------------------------------------------------------------
-- The addon and its modules
---------------------------------------------------------------------------

---@class AHOSModule: AceModule, AceEvent-3.0, AceTimer-3.0
---@field OnProfileChanged? fun(self)

---@class AHOS: AceAddon, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
---@field SlashHandler fun(self, input: string)
---@field DetectUI fun(self): string
---@field OnProfileChanged fun(self, event?: string, db?: table, profileKey?: string)
---@field db AHOSDB
---@field L table<string, string>
---@field ready boolean
---@field detectedUI string the provider key AHOS draws on
---@field IsMainlineClient boolean Retail or WoW Forever
---@field IsForeverClient boolean
---@field ProviderRegistry table<string, AHOSProvider>
---@field Config AHOSConfig
---@field Options AHOSOptions
---@field Core AHOSCore
---@field Bars AHOSBars
---@field Keybinds AHOSKeybinds
---@field Display AHOSDisplay
---@field Performance AHOSPerformance
---@field UI AHOSUI
---@field Visibility AHOSVisibility
---@field Editor AHOSEditor
---@field Profiles AHOSProfiles
---@field Print fun(self, ...)
---@field IsReady fun(self): boolean
---@field SafeCall fun(self, moduleName: string, func: string|function, ...)
---@field IsValueAccessible fun(self, value: any): boolean
---@field SafeToString fun(self, value: any, fallback?: string): string
---@field GetButtonActionSlot fun(self, button: Frame): number|nil
---@field IsFrameShownSafe fun(self, frame: Frame): boolean
---@field IsFrameVisibleSafe fun(self, frame: Frame): boolean
---@field GetProviderInfo fun(self, key?: string): AHOSProvider
---@field GetProviderForButtonName fun(self, buttonName: string): AHOSProvider|nil
---@field IsProviderLoaded fun(self, key: string): boolean
---@field GetDetectedProviderKey fun(self): string
---@field ShouldShowOverlays fun(self): boolean
---@field UpdateAllButtons fun(self)
---@field ShowTextWindow fun(self, title: string, text: string, key?: string, toEnd?: boolean)

---@class AHOSPrivate the addon's private namespace (the second value of `...`)
---@field addon AHOS
---@field DisplayShared AHOSDisplayShared
---@field OptionsKit table the options window (options/)
---@field PanelMeta table<table, table> what the options window is told about an option
---@field OnOptionsChanged? fun()

---------------------------------------------------------------------------
-- Bar addons
---------------------------------------------------------------------------

---@class AHOSScanner
---@field prefix string buttons are named prefix1, prefix2, ...
---@field max? number how many to look for (scanning goes on while names continue)
---@field count? number containers: how many bar frames prefix1..prefixN
---@field matcher? string containers: a pattern a child's name must match

---@class AHOSBindingRule
---@field matcher string a pattern for the button's name
---@field suffixes string[] the key is found on CLICK <button><suffix>

---@class AHOSProvider
---@field key string
---@field label string
---@field addon? string
---@field addons? string[]
---@field globals? string[]
---@field color_hex string
---@field color_rgb number[]
---@field supported boolean
---@field conflict_only? boolean
---@field compatibility_note? string
---@field rewrite_setting? string a profile.display key that turns native text on for this provider
---@field button_patterns? string[]
---@field button_scanners? { globals?: AHOSScanner[], containers?: AHOSScanner[] }
---@field binding_rules? AHOSBindingRule[]
---@field bound_keys_path? string[] where the button keeps its own ":Q:SHIFT-E:" key list
---@field hotkey_fields? string[] the label's field when it is not HotKey
---@field command_fields? string[]
---@field hotkey_update_method? string
---@field hotkey_update_methods? string[]

---------------------------------------------------------------------------
-- The saved variables
---------------------------------------------------------------------------

---@alias AHOSColor number[] { r, g, b } or { r, g, b, a }, 0-1

---@class AHOSDisplaySettings
---@field strata string
---@field anchor string
---@field xOffset number
---@field yOffset number
---@field scale number
---@field alpha number
---@field hideOriginal boolean
---@field border string
---@field borderColor AHOSColor
---@field borderSize number
---@field locked boolean
---@field nativeRewrite boolean
---@field dominosRewrite boolean
---@field autoNativeFallback boolean
---@field followNativeHotkeyStyle boolean
---@field followMasque boolean
---@field smartStrata boolean
---@field frameLevel number
---@field background { enabled: boolean, color: AHOSColor, padding: number }
---@field pressAnimation "none"|"flash"|"pulse"
---@field pressColor AHOSColor

---@class AHOSModifierColors
---@field enabled? boolean
---@field hideModifiers? boolean
---@field shift? AHOSColor
---@field ctrl? AHOSColor
---@field alt? AHOSColor
---@field multi? AHOSColor

---@class AHOSTextSettings
---@field fontSize number
---@field font string a name from Config:GetFontList()
---@field color AHOSColor
---@field shadowEnabled boolean
---@field shadowOffset number[]
---@field shadowColor AHOSColor
---@field glow { enabled: boolean, color: AHOSColor }
---@field mouseIcons boolean
---@field showAllBindings boolean
---@field bindingSeparator string
---@field abbreviations boolean
---@field maxLength number
---@field modSeparator string
---@field customAbbreviations table<string, string>
---@field outline boolean legacy
---@field outlineStyle string
---@field gamepadIcons boolean
---@field gamepadIconStyle "auto"|"xbox"|"ps"|"switch"|"generic"
---@field modifierColors AHOSModifierColors

---@class AHOSVisibilitySettings
---@field fadeOutOfCombat? boolean
---@field modifierOnly? boolean
---@field fadedAlpha? number
---@field fadeDuration? number
---@field condition? string a Lua expression; see modules/Visibility.lua
---@field combatStyle? { enabled: boolean, color: AHOSColor, scale: number }

---@class AHOSBarSettings
---@field label? string
---@field hide? boolean
---@field scale? number
---@field mouseover? boolean
---@field position? boolean
---@field anchor? string
---@field xOffset? number
---@field yOffset? number

---@class AHOSProfile
---@field enabled boolean
---@field autoDetectUI boolean
---@field display AHOSDisplaySettings
---@field text AHOSTextSettings
---@field visibility AHOSVisibilitySettings
---@field minimap { hide: boolean }
---@field bars table<string, AHOSBarSettings> by bar key ("Blizzard:1", "Dominos:4")
---@field buttons table<string, { hide: boolean }> by button name
---@field debug boolean
---@field troubleshootingTools boolean
---@field forceOverlaysWithElvUI? boolean
---@field showPerfMetrics? boolean
---@field autoSwitchProfile? boolean legacy, moved to char.autoSwitch

---@class AHOSSnapshot
---@field label string
---@field profile string the profile it was taken from
---@field time number
---@field data AHOSProfile

---@class AHOSDB: AceDBObject-3.0
---@field profile AHOSProfile
---@field global { snapshots: AHOSSnapshot[] }
---@field char { autoSwitch: "off"|"spec"|"loadout" }

---------------------------------------------------------------------------
-- Things the modules hand around
---------------------------------------------------------------------------

---@class AHOSOverlay: Frame, BackdropTemplate an overlay AHOS draws over one button
---@field text FontString
---@field glow? FontString
---@field bg? Texture
---@field flash? Texture
---@field editFrame? Texture
---@field _ahosInPool? boolean
---@field _ahosBaseAlpha? number the profile's alpha, before the visibility rules
---@field _ahosVis? number how visible it is now, 0-1
---@field _ahosVisTarget? number how visible it is fading to
---@field _ahosFaded? boolean a rule hides it (the native fallback leaves it alone)
---@field _ahosEditButton? Button
---@field _ahosEditHooked? boolean

---@class AHOSMasqueLayout where a Masque skin puts a button's hotkey label
---@field point string
---@field relPoint string
---@field x number
---@field y number
---@field width number 0 sizes the text to itself
---@field justifyH? string
---@field justifyV? string
---@field anchor Frame|Region the button, or the region the skin anchors to

---@class AHOSBarEntry
---@field key string
---@field label string
---@field count number
---@field shown? boolean

---@class AHOSPreset
---@field key string
---@field label string
---@field desc string
---@field values table laid over the profile (Profiles.Merge)

---@class AHOSButtonInfo what the inspector shows for one button
---@field name string
---@field provider string
---@field providerLabel string
---@field color string
---@field bar? string
---@field command? string
---@field slot? number
---@field action? { type: string, name?: string, icon?: number|string }
---@field key string the full binding, "SHIFT-Q"
---@field shown string the text AHOS draws

---------------------------------------------------------------------------
-- Module classes (methods are added by the module files)
---------------------------------------------------------------------------

---@class AHOSConfig: AHOSModule
---@field FontLoads fun(path: string): boolean

---@class AHOSOptions: AHOSModule
---@field Groups table<string, fun(): table> the option pages, built by modules/Options*.lua
---@field Helpers table the helpers the pages share
---@field selectedBar? string
---@field selectedSnapshot? number

---@class AHOSCore: AHOSModule
---@class AHOSPerformance: AHOSModule
---@class AHOSBars: AHOSModule

---@class AHOSKeybinds: AHOSModule
---@field CapitalLetters table<string, string> lower case letter -> capital
---@field MouseIcons table<string, string> key -> icon file
---@field GamePadStyles string[]
---@field IsGamePadKey fun(key: string): boolean

---@class AHOSDisplay: AHOSModule
---@field DerivedNativeText fun(button: Button): string|nil

---@class AHOSDisplayShared the state and helpers the Display files share
---@field overlayEpoch number
---@field restoringNativeHotkeys boolean
---@field activeOverlays table<string, AHOSOverlay>
---@field originalHotkeyTexts table<string, string>
---@field nativeRewriteButtons table<string, "configured"|"fallback">
---@field squelchedByButton table<string, boolean>

---@class AHOSVisibility: AHOSModule
---@field SafeFunctions string[] the game functions a condition can call
---@field Step fun(elapsed: number): boolean
---@field SetCombat fun(inCombat: boolean)

---@class AHOSEditor: AHOSModule

---@class AHOSUI: AHOSModule
---@field EnsureMinimapIcon fun(self)
---@field minimapIconRegistered? boolean
---@field _loginRegistered? boolean

---@class AHOSHotkeyLabel: FontString a bar's own hotkey label AHOS writes into or hides
---@field _ahosButton? string the button it belongs to
---@field _ahosVis? number
---@field _ahosVisTarget? number

---@class AHOSProfiles: AHOSModule
---@field Presets AHOSPreset[]
---@field DeepCopy fun(value: any): any
---@field Merge fun(dest: table, source: table)
