# Advanced Hotkey Overlay System Changelog

## 1.3.1 (2025-06-18)

### 🎛️ Master Toggle Enhancement

- **Smart Options Management**: When the master toggle is disabled, all other configuration options are automatically hidden/disabled
- **Cleaner Interface**: Disabled state provides a cleaner, less cluttered options panel when the addon is turned off
- **Improved User Experience**: Only shows relevant controls based on the addon's active state
- **Automatic Refresh**: Options panel automatically updates when toggling the master switch

### 🎨 Interface Layout Improvements  

- **Streamlined Header**: Removed redundant "Advanced Hotkey Overlay System" header (already shown in window title)
- **Master Toggle Priority**: Moved master toggle to the very top for immediate access and visibility
- **Compact Status Bar**: Moved profile selector inline with detected UI and version information for space efficiency
- **Optimized Layout**: Better use of horizontal space with profile management positioned to the right of status info

### 🔧 Interface Improvements

- **Enhanced Master Toggle**: Updated description to clarify that disabling will hide other options
- **Instant Feedback**: Options panel immediately reflects the enabled/disabled state without requiring manual refresh

---

## 1.3.0 (2025-06-18)

### 🎨 Complete Visual & UX Overhaul

- **Beautiful Options Panel Redesign**: Complete interface transformation with modern styling
- **Enhanced Visual Hierarchy**: Professional organization with icons, emojis, and consistent branding
- **Smart Layout System**: Grouped settings into logical sections with clear visual separation
- **Brand Identity**: Consistent turquoise (#00D4AA) theme with lightning bolt (⚡) branding throughout

### ✨ Major Interface Improvements

- **Dynamic UI Elements**:
  - Lock/unlock button changes appearance and description based on state
  - Status section with gear icons showing detected UI and version info
  - Enhanced profile selector with emoji indicators for different profile types
  - Directional arrows (↖↗⬆⬇) for anchor point selection

- **Professional Section Organization**:
  - 📊 Status Information (UI detection, version, credits)
  - ⚡ Master Toggle (enhanced with full-width layout and detailed descriptions)
  - 🔧 Quick Actions (Smart Refresh, Temporary Clear with comprehensive tooltips)
  - 🗺️ Position Controls (anchor points, pixel-perfect offsets)
  - ✨ Visual Properties (scale, transparency, frame layering)
  - 📝 Font & Text Style (color picker, font selection, text enhancements)
  - 👤 Profile Management (character-specific and global profiles)
  - 🔒 Security & Lock (intelligent protection system)

### 🚀 Enhanced User Experience

- **Comprehensive Tooltips**: Every option now includes detailed descriptions with:
  - Visual separators for better readability
  - Practical usage examples and recommendations  
  - Status indicators and emoji symbols
  - Technical details and best practices

- **Improved Button & Layout System**:
  - Full-width buttons prevent text truncation
  - Consistent spacing and visual alignment
  - Enhanced confirmation dialogs with modern styling
  - Color-coded status messages throughout

- **Smart Visual Feedback**:
  - Enhanced slash command output with colored status indicators
  - Real-time visual updates for all settings
  - Dynamic lock system with beautiful confirmation popups
  - Professional branding consistency across all interfaces

### 🔧 Technical Polish

- **Enhanced .toc Metadata**: Improved addon list appearance with better styling
- **Modernized Confirmation Dialogs**: Beautiful unlock confirmation with icons and styled buttons
- **Improved Status Display**: Real-time UI detection with color-coded visual indicators
- **Professional Documentation**: Updated all help text and descriptions

## 1.2.0 (2025-06-18)

### 🎉 Major Features

- **Live Configuration Updates**: All settings now update instantly without requiring cleanup/refresh
- **Lock System**: Added working lock toggle to prevent accidental changes during configuration
- **Minimap & TitanPanel Icons**: Fixed icons now display properly with proper DataBroker integration

### 🔧 Technical Improvements

- Fixed Blizzard UI dependencies loading (no more EasyMenu errors)
- Improved library loading using proper .toc and embeds.xml structure
- Added proper LibDataBroker-1.1 integration for minimap/TitanPanel compatibility
- Enhanced position updating with ClearAllPoints() for accurate anchor changes

### 🎨 User Experience

- Updated default settings for better out-of-box experience:
  - Anchor: TOP, X Offset: -22, Y Offset: -3, Scale: 0.95, Alpha: 1.0
  - Font Size: 16, Outline: enabled
- All configuration changes now apply live (font, color, shadow, position, scale, etc.)
- Lock toggle prevents live updates when enabled, allows testing without visual disruption

### 🐛 Bug Fixes

- Fixed AddOn list icon display (64x64 format, proper IconTexture directive)
- Fixed minimap icon not appearing (proper LibDBIcon-1.0 loading)
- Fixed right-click menu errors by removing deprecated EasyMenu dependency
- Fixed live updates not working for anchor points and offsets
- Fixed lock functionality that was previously non-functional

## 1.1.1 (2025-06-17)

- Renamed addon to **Advanced Hotkey Overlay System** (formerly Advanced Hotkey Overlay)
- All files, folders, commands, and UI updated to new naming
- Main files are now `AdvancedHotkeyOverlaySystem.toc` and `AdvancedHotkeyOverlaySystem.lua`
- Removed unused libraries: AceComm-3.0 and AceGUI-3.0 for a cleaner addon
- Added `/ahos reload` command to refresh overlays instantly
- Improved user feedback: now prints messages when overlays are reloaded, locked, unlocked, or settings are reset
- Addon version is now printed on load
- Added lock/unlock toggle to the options UI
- Updated slash command help text
- Fixed slash commands to work properly with AceConsole
- Fixed original hotkey hiding when hideOriginal is enabled
- Fixed options panel opening in modern WoW versions

## 1.1.0 (2025-06-17)

- Improved slash commands: `/aho show`, `lock`, `unlock`, `reset`, `toggle`, `help`
- Added minimap button (LibDBIcon-1.0) with left/right click actions and tooltips
- Titan Panel integration: status display and quick access
- Basic localization structure for future multi-language support
- UI detected text in options now supports unique color per UI

## 1.0.1 (2025-06-17)

- Renamed .toc file to `AdvancedHotkeyOverlay.toc` to match the old addon name.

## 1.0.0 (2025-06-17)

- Initial stable release
- Live updating hotkey overlays with ConsolePort-style abbreviations
- Per-character and global profiles
- Font selection (including SharedMedia support)
- Built-in outline and shadow options
- UI detection (AzeriteUI, ElvUI, Bartender4, Blizzard)
- Clean config panel with credits and version display
- Full Ace3 integration
