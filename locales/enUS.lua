local L = _G.AHOS_L or {}
_G.AHOS_L = L

-- Base locale (enUS)
L.ADDON_NAME = "Advanced Hotkey Overlay System"
L.OPTIONS_PANEL_NAME = "AHOS Options"

-- General
L.ENABLE_ADDON = "Enable Addon"
L.AUTO_DETECT_UI = "Auto-Detect UI"
L.DEBUG_MODE = "Debug Mode"
L.LOCK_SETTINGS = "Lock Settings"
L.UNLOCK_SETTINGS = "Unlock Settings"
L.HIDE_MINIMAP_ICON = "Hide Minimap Icon"
L.ENABLED = "enabled."
L.DISABLED = "disabled."
L.MINIMAP_LEFT_CLICK_OPEN_SETTINGS = "|cffeda55fLeft-click|r to open settings."
L.MINIMAP_SHIFT_LEFT_CLICK_OPEN_LOG = "|cffeda55fShift+Left-click|r to open AHOS debug log."
L.MINIMAP_RIGHT_CLICK_TOGGLE = "|cffeda55fRight-click|r to toggle addon."
L.ERR_LDB_MISSING = "[AHOS ERROR] LibDataBroker missing!"
L.ERR_LDBICON_MISSING = "[AHOS ERROR] LibDBIcon missing!"
L.ERR_DB_NOT_READY = "[AHOS ERROR] DB not ready!"

-- Display
L.DISPLAY = "Display"
L.USE_NATIVE_REWRITE = "Use Native Text (Rewrite)"
L.DOMINOS_USE_NATIVE = "Dominos: Use Native Text"
L.AUTO_NATIVE_FALLBACK = "Auto Fallback to Native"
L.HIDE_ORIGINAL = "Hide Original Hotkey Text"
L.ANCHOR_POINT = "Anchor Point"
L.X_OFFSET = "X Offset"
L.Y_OFFSET = "Y Offset"
L.SCALE = "Scale"
L.ALPHA = "Alpha"
L.OVERLAY_STRATA = "Overlay Frame Strata"
L.OVERLAY_LEVEL = "Overlay Frame Level"
L.MIRROR_NATIVE_STYLE = "Mirror Native Hotkey Style"

-- Keybinds
L.KEYBINDS = "Keybinds"
L.FONT = "Font"
L.FONT_SIZE = "Font Size"
L.FONT_COLOR = "Font Color"
L.FONT_OUTLINE = "Font Outline"
L.ABBREVIATIONS = "Enable Abbreviations"
L.MAX_LENGTH = "Max Length"
L.MOD_SEPARATOR = "Modifier Separator"
L.PICK_FONT_COLOR = "Pick Font Color"

-- Profiles
L.PROFILES = "Profiles Management"
L.UNKNOWN = "Unknown"
L.CURRENT_PROFILE = "Current Profile:"
L.USE_GLOBAL_PROFILE = "Use Global Profile"
L.CONFIRM_SWITCH_GLOBAL = "Switch to the global (Default) profile? This will overwrite your current settings."
L.YES = "Yes"
L.NO = "No"
L.USE_CHARACTER_PROFILE = "Use Character Profile"
L.CONFIRM_SWITCH_CHARACTER = "Switch to the character-specific profile? This will overwrite your current settings."
L.COPY_PROFILE_TO = "Copy Current Profile To…"
L.COPY = "Copy"
L.RESET_ALL_PROFILES = "Reset All Profiles"
L.CONFIRM_RESET_ALL = "Reset ALL profiles to default? This cannot be undone!"
L.EXPORT_PROFILE = "Export Current Profile"
L.IMPORT_PROFILE = "Import Profile String"
L.IMPORT = "Import"

-- Sections
L.GENERAL = "General"
L.INTEGRATION = "Integration"
L.ADVANCED = "Advanced"
L.HELP = "Help"
L.ABOUT = "About"
L.CHANGELOG = "Changelog"
L.CURRENT = "current"

-- Integration/Advanced
L.ENABLE_ELVUI = "Enable ElvUI Compatibility"
L.ENABLE_BARTENDER = "Enable Bartender Compatibility"
L.ENABLE_DOMINOS = "Enable Dominos Compatibility"
L.SHOW_PERF_METRICS = "Show Performance Metrics"
L.OPEN_ACE_OPTIONS = "Open Classic Options (AceConfig)"

-- Help/About
L.HOW_TO_REPORT_BUGS = "How to Report Bugs"
L.SLASH_COMMANDS = "Slash Commands"
L.DEBUGGING_TIPS = "Debugging Tips"
L.MADE_BY = "Made by:"
L.LIBRARIES = "Libraries:"
L.FUTURE_SECTION = "This section will be expanded in a future update."

-- JUI portrait tooltip
L.AHOS_PORTRAIT = "AHOS Portrait"
L.TOC_ICON_TEXTURE = "TOC IconTexture:"
L.USING_TEXTURE = "Using:"
L.NONE = "(none)"
L.TIP_PORTRAIT_FORMAT = "Tip: Use 128x128 TGA (32-bit, uncompressed) or BLP."

-- ElvUI popup
L.ELVUI_WARNING_TEXT = "ElvUI detected! Both ElvUI and Advanced Hotkey Overlay System provide keybind overlays.\n\nDo you want to disable AHO overlays (recommended)?"
L.ELVUI_WARNING_ACCEPT = "Yes (Disable AHO Overlays)"
L.ELVUI_WARNING_CANCEL = "No (Keep Both)"

-- Import/Export messages
L.NO_IMPORT_STRING = "No import string provided."
L.NO_DEBUG_IMPORT_STRING = "No debug import string provided."
L.ERR_LIBS_MISSING = "LibDeflate/LibSerialize missing."
L.ERR_DECODE_FAILED = "Failed to decode string."
L.ERR_DECOMPRESS_FAILED = "Failed to decompress string."
L.ERR_DESERIALIZE_FAILED = "Failed to deserialize string."
L.PROFILE_IMPORTED_OK = "Profile imported successfully. Reload UI to apply all changes."

-- Slash/help and status messages
L.OPTIONS_PANEL_NOT_AVAILABLE = "[AHOS] Options panel function not available."
L.MSG_SETTINGS_LOCKED = "|cffFFD700Settings locked|r - |cff888888protected from changes|r"
L.MSG_SETTINGS_UNLOCKED = "|cff4A9EFF Settings unlocked|r - |cff888888you can now modify settings|r"
L.MSG_SETTINGS_RESET = "|cffFFD700Settings reset|r |cff888888to default values|r"
L.MSG_OVERLAYS_RELOADED = "|cff4A9EFFOverlays reloaded|r |cff888888and refreshed|r"
L.MSG_FORCE_READY = "[AHOS] Forcing addon ready state for update (player is in world)."
L.MSG_OVERLAYS_UPDATED = "|cff4A9EFFOverlays updated|r |cff888888(full update triggered)|r"
L.MSG_OVERLAYS_TEMP_CLEARED = "|cffFFD700Overlays temporarily cleared|r - |cff888888use Smart Refresh or change settings to restore|r"
L.DEBUG_MODE_LABEL = "|cffFFD700Debug mode|r "
L.DEBUG_ENABLED = "|cff4A9EFFenabled|r"
L.DEBUG_DISABLED = "|cffFF6B6Bdisabled|r"
L.MSG_MANUAL_DETECT_UI = "|cff4A9EFFManually detecting UI...|r"
L.MSG_CURRENT_DETECTED_UI = "|cffFFD700Current detected UI:|r "

-- Slash commands help
L.SLASH_HEADER = "|cffFFD700Advanced Hotkey Overlay System|r |cff4A9EFF- Commands:|r"
L.SLASH_SHOW = "|cffFFD700/ahos show|r - |cff888888Open options panel|r"
L.SLASH_LOCK = "|cffFFD700/ahos lock|r - |cff888888Lock overlay settings|r"
L.SLASH_UNLOCK = "|cffFFD700/ahos unlock|r - |cff888888Unlock overlay settings|r"
L.SLASH_RESET = "|cffFFD700/ahos reset|r - |cff888888Reset all settings to default|r"
L.SLASH_TOGGLE = "|cffFFD700/ahos toggle|r - |cff888888Enable/disable overlays|r"
L.SLASH_RELOAD = "|cffFFD700/ahos reload|r - |cff888888Reload and refresh overlays|r"
L.SLASH_REFRESH = "|cffFFD700/ahos refresh|r - |cff888888Smart refresh of overlays (same as UI button)|r"
L.SLASH_CLEANUP = "|cffFFD700/ahos cleanup|r - |cff888888Temporarily clear all overlays (same as UI button)|r"
L.SLASH_DEBUG = "|cffFFD700/ahos debug|r - |cff888888Toggle debug mode|r"
L.SLASH_DETECTUI = "|cffFFD700/ahos detectui|r - |cff888888Manually detect UI addon|r"
L.SLASH_HELP = "|cffFFD700/ahos help|r - |cff888888Show this help message|r"
L.SLASH_VERSION = "|cffFFD700/ahos version|r - |cff888888Show addon version|r"

-- Errors and usage
L.USAGE_INSPECT = "|cffFF6B6BUsage:|r |cffFFD700/ahos inspect <ButtonName>|r"
L.KEYBINDS_NOT_AVAILABLE = "|cffFF6B6BKeybinds module not available.|r"
L.BUTTON_NOT_FOUND_PREFIX = "|cffFF6B6BButton not found:|r "
L.UNKNOWN_COMMAND_PREFIX = "|cffFF6B6BUnknown command:|r "
L.TYPE_HELP_SUFFIX = "|cff888888Type|r |cffFFD700/ahos help|r |cff888888for available commands|r"
L.DISPLAY_MISSING_SUFFIX = " or Display missing."
L.USAGE_AHOS = "Usage: /ahos [refresh|debug|detect|inspect <ButtonName>|dumphotkey <ButtonName>|dumplayers <ButtonName>]"

-- Debug windows
L.CLOSE = "Close"
L.COPY_ALL = "Copy All"
L.DEBUG_LOG_TITLE = "AHOS Debug Log"
L.DEBUG_EXPORT_TITLE = "AHOS Debug Export"

-- Additional UI/Options localization
L.MINIMAP_ICON = "Minimap Icon"
L.HIDE_MINIMAP_ICON_DESC = "Hide or show the minimap icon."
L.ADDON_INITIALIZING = "Addon is initializing. Please close and reopen this window in a few seconds."
L.ENABLE_ADDON_DESC = "Enable or disable the addon."
L.AUTO_DETECT_UI_DESC = "Automatically detect your action bar UI."
L.DEBUG_MODE_DESC = "Enable verbose debug logging."
L.LOCK_SETTINGS_DESC = "Lock or unlock all settings to prevent accidental changes."
L.UNLOCK_SETTINGS_PROMPT = "The settings are locked. Do you want to unlock?"

-- Display descs
L.USE_NATIVE_REWRITE_DESC = "Rewrite the button's native hotkey text instead of drawing an overlay."
L.DOMINOS_USE_NATIVE_DESC = "For Dominos buttons, rewrite the native hotkey text (overlay is default)."
L.AUTO_NATIVE_FALLBACK_DESC = "If an overlay appears hidden by a skin, automatically rewrite the native hotkey for that button."
L.HIDE_ORIGINAL_DESC = "Hides the default hotkey text on action buttons."
L.ANCHOR_POINT_DESC = "The point on the button where the text is anchored."
L.X_OFFSET_DESC = "Horizontal offset from the anchor point."
L.Y_OFFSET_DESC = "Vertical offset from the anchor point."
L.SCALE_DESC = "The scale of the overlay text."
L.ALPHA_DESC = "The transparency of the overlay text."
L.OVERLAY_STRATA_DESC = "Sets the drawing layer for the overlays. Use a higher value (like DIALOG or TOOLTIP) if overlays are hidden behind other UI elements."
L.OVERLAY_LEVEL_DESC = "Fine-tune overlay stacking within the chosen strata. Higher values appear above lower ones in the same strata."
L.MIRROR_NATIVE_STYLE_DESC = "Overlay text will mirror the native hotkey font, color, and position when available."

-- Text/Keybinds descs
L.FONT_DESC = "The font for the overlay text."
L.FONT_SIZE_DESC = "The size of the font."
L.FONT_COLOR_DESC = "The color of the font."
L.FONT_OUTLINE_DESC = "Choose font outline and monochrome options."
L.ABBREVIATIONS_DESC = "Abbreviate keybind text (e.g., SHIFT -> S)."
L.MAX_LENGTH_DESC = "Maximum length of the abbreviated text."
L.MOD_SEPARATOR_DESC = "String to insert between modifiers and key (leave empty for none, e.g. SM4)."

-- Profiles management
L.PROFILE_MANAGEMENT = "Profile Management"
L.CURRENT_PROFILE_LABEL = "|cff4A9EFFCurrent Profile:|r "
L.USE_GLOBAL_PROFILE_DESC = "Switch to the global (Default) profile."
L.USE_CHARACTER_PROFILE_DESC = "Switch to a character-specific profile."
L.COPY_PROFILE_TO_DESC = "Enter a new profile name to copy current settings."
L.ALL_PROFILES_RESET = "All profiles reset to default!"
L.SWITCHED_TO_GLOBAL_PROFILE = "|cff4A9EFFSwitched to global profile:|r Default"
L.SWITCHED_TO_CHARACTER_PROFILE = "|cff4A9EFFSwitched to character profile:|r %s"
L.COPIED_PROFILE_TO = "|cff4A9EFFCopied current profile to:|r %s"
L.PRINT_CURRENT_PROFILE_DATA = "Print Current Profile Data"
L.PRINT_CURRENT_PROFILE_DATA_DESC = "Prints the current profile data to the chat for debugging."
L.CURRENT_PROFILE_DATA_COMPRESSED = "|cffFFD700Current Profile Data (compressed):|r"
L.CURRENT_PROFILE_DATA = "|cffFFD700Current Profile Data:|r"
L.SERIALIZATION_NOT_AVAILABLE = "[Serialization not available]"
L.IMPORT_PROFILE_DATA = "Import Profile Data"
L.IMPORT_PROFILE_DATA_DESC = "Paste a profile export string here to import settings."
L.IMPORT_NOT_IMPLEMENTED = "Import feature not yet implemented."
L.AUTO_SWITCH_PROFILE = "Auto-Switch Profile by Spec"
L.AUTO_SWITCH_PROFILE_DESC = "Automatically switch profiles when changing specialization."

-- Integration/Compatibility
L.INTEGRATION_COMPAT = "Integration/Compatibility"
L.ENABLE_ELVUI_COMPAT = "Enable ElvUI Compatibility"
L.ENABLE_ELVUI_COMPAT_DESC = "Force overlays even if ElvUI is loaded (may cause conflicts)."
L.ENABLE_BARTENDER_COMPAT = "Enable Bartender Compatibility"
L.ENABLE_BARTENDER_COMPAT_DESC = "Enable overlays for Bartender action bars."
L.ENABLE_DOMINOS_COMPAT = "Enable Dominos Compatibility"
L.ENABLE_DOMINOS_COMPAT_DESC = "Enable overlays for Dominos action bars."
L.SHOW_PERF_METRICS_DESC = "Show overlay update times and enable performance logging."

-- Advanced/Debug windows and actions
L.EXPORT_DEBUG_DATA = "Export Debug Data"
L.EXPORT_DEBUG_DATA_DESC = "Export current settings or table for debugging."
L.DEBUG_EXPORT_NOT_AVAILABLE = "Debug export not available."
L.IMPORT_DEBUG_DATA = "Import Debug Data"
L.IMPORT_DEBUG_DATA_DESC = "Paste a debug export string to import settings or data."
L.DEBUG_IMPORT_NOT_IMPLEMENTED = "Debug import not yet implemented."

-- Help/About
L.HELP_AND_DEBUGGING = "Help & Debugging"
L.HELP_AND_DEBUGGING_TEXT = "|cffFFD700How to Report Bugs|r\n- Please include your WoW version, addon version, and a description of the issue.\n- For UI or overlay issues, include a screenshot if possible.\n- You can export your profile or debug data using the options or /ahos debugexport.\n\n|cffFFD700Available Slash Commands|r\n/ahos show - Open options panel\n/ahos lock|unlock - Lock/unlock settings\n/ahos reset - Reset all settings\n/ahos toggle - Enable/disable overlays\n/ahos reload|refresh - Reload overlays\n/ahos cleanup - Clear overlays\n/ahos debug - Toggle debug mode\n/ahos detectui - Manually detect UI\n/ahos inspect <ButtonName> - Print debug info for a button\n/ahos debugexport [tablepath] - Export profile or subtable for debugging\n/ahoslog - Open the debug log window\n\n|cffFFD700Debugging Tips|r\n- Enable debug mode with /ahos debug to see extra output.\n- Use /ahos debugexport to copy your profile or a subtable for bug reports.\n- Use /ahoslog to view/copy all debug output.\n- Paste exported data in your bug report for faster help!\n\n|cffFFD700Changelog & Version Info|r\n- See the 'Changelog' tab for recent updates and version history.\n\n|cffFFD700Addon Version:|r "
L.ABOUT_AND_CREDITS = "About & Credits"
L.ABOUT_TEXT = [[
|cffFFD700Advanced Hotkey Overlay System|r

A modular, robust hotkey overlay system for World of Warcraft action bars, supporting Blizzard, AzeriteUI, and ConsolePort-style keybind abbreviations.

|cffFFD700Made by:|r JuNNeZ
|cffFFD700Libraries:|r Ace3, LibDBIcon-1.0, LibSharedMedia-3.0, LibSerialize, LibDeflate.

For support, please visit the CurseForge or GitHub project pages.
Thank you for using AHOS!
]]
L.CHANGELOG_FOR = "Changelog for Advanced Hotkey Overlay System"
L.VERSION_LABEL = "Version "

return L
