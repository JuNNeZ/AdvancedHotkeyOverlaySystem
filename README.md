# ⚡ Advanced Hotkey Overlay System

**Advanced Hotkey Overlay System for World of Warcraft** - **Version 1.3.2**

## ✨ What's New in v1.3.0

- **🎨 Complete Visual Overhaul**: Stunning new options panel with modern styling, icons, and professional organization
- **⚡ Enhanced User Experience**: Intuitive layout with grouped sections, comprehensive tooltips, and visual feedback
- **🎯 Smart Interface Design**: Dynamic elements that change based on state, full-width buttons, and consistent branding
- **� Professional Polish**: Enhanced confirmation dialogs, color-coded status messages, and improved visual hierarchy
- **📱 Modern Layout System**: Logical grouping of all settings with clear visual separators and emoji indicators

## 🌟 Key Features

- **⚡ Live updating hotkey overlays** with ConsolePort-style abbreviations
- **🎨 Real-time configuration**: All changes apply instantly (font, color, position, scale, etc.)
- **🔒 Smart lock system**: Prevent accidental changes with beautiful confirmation dialogs
- **👤 Enhanced profile management**: Per-character and global profiles with modern UI
- **🎭 Advanced customization**: Comprehensive font, color, shadow, outline, and positioning options
- **🤖 Intelligent UI detection**: Automatically adapts to AzeriteUI, ElvUI, Bartender4, Dominos, and Blizzard UI
- **🎛️ Beautifully organized options**: Professional interface with grouped settings, icons, and visual hierarchy
- **⚙️ Full Ace3 integration**: Robust addon framework with sophisticated configuration system
- **💬 Enhanced slash commands**: Colored output with emoji status indicators and comprehensive help
- **🗺️ Minimap integration**: Click to toggle the stunning configuration panel
- **📊 Titan Panel support**: Status display with quick access and visual indicators
- **🎯 Optimized defaults**: Perfect settings for immediate usability across all UI addons
- **🌍 Localization ready**: Professional structure prepared for multiple languages

## 🎮 How to Use

### Slash Commands (Enhanced)

- `/ahos` or `/advancedhotkeyoverlaysystem` — Main command with beautiful colored output
  - `show` — Open the sleek configuration panel
  - `lock` 🔒 — Lock overlays (with visual confirmation)
  - `unlock` 🔓 — Unlock overlays (with visual confirmation)
  - `reset` ⚠️ — Reset settings to optimized defaults
  - `toggle` ✓/✗ — Enable/disable overlays with status
  - `reload` 🔄 — Smart refresh of all overlays
  - `help` 📚 — Show formatted help with all commands
  - `debug` 🐛 — Toggle debug mode for troubleshooting
  - `detectui` 🔍 — Manually trigger UI detection with results

### Interface Features

- **🗺️ Minimap button**: Click to toggle the beautiful, redesigned options panel
- **⚡ Live updates**: All settings change instantly with sophisticated visual feedback
- **🎛️ Smart options management**: Master toggle automatically hides/shows all options for a cleaner interface
- **🔒 Lock protection**: Smart system with elegant confirmation dialogs prevents accidental changes
- **📱 Professional organization**: Settings grouped into logical sections with clear visual hierarchy:
  - 📊 **Status Information**: Real-time UI detection and version display
  - ⚡ **Master Toggle**: Enhanced main control with comprehensive descriptions
  - 🔧 **Quick Actions**: Smart Refresh and Temporary Clear with detailed tooltips
  - 🗺️ **Position Controls**: Precise positioning with directional arrow indicators
  - ✨ **Visual Properties**: Scale, transparency, and frame layer management
  - 📝 **Font & Text Style**: Complete typography control with visual previews
  - � **Profile Management**: Character-specific and global profile system
  - 🔒 **Security & Lock**: Intelligent protection with dynamic state display

## 🎨 Visual Design Features

### Modern Interface Elements

- **Consistent Branding**: Turquoise (#00D4AA) color scheme with lightning bolt (⚡) identity
- **Professional Icons**: Relevant icons and emojis for every major function and section
- **Enhanced Tooltips**: Comprehensive descriptions with visual separators and practical examples
- **Dynamic UI**: Elements that change appearance based on current state and settings

### Smart User Experience

- **Full-Width Buttons**: No more text truncation - all buttons properly sized
- **Visual Separators**: Clear section divisions with consistent spacing
- **Color-Coded Feedback**: Status messages with appropriate colors and emoji indicators
- **Intuitive Navigation**: Logical flow from basic to advanced settings

### Professional Polish

- **Enhanced Confirmation Dialogs**: Beautiful popups with proper styling and clear actions
- **Real-Time Feedback**: Immediate visual confirmation for all setting changes
- **Consistent Typography**: Professional text hierarchy throughout the interface
- **Modern Layout**: Clean, organized presentation that matches current WoW addon standards

## 📋 Requirements

- **Ace3 libraries** (bundled with addon)
- **LibSharedMedia-3.0** (bundled or via SharedMedia addon)
- **LibDBIcon-1.0** (bundled for minimap button functionality)
- **Titan Panel** (optional, for integration and status display)
- **World of Warcraft Retail** (Interface version 100207+)

## 🔧 Installation & Setup

1. **Download & Install**: Extract to your `Interface\AddOns` folder
2. **Verify Files**: Ensure `AdvancedHotkeyOverlaySystem.toc` is present and is the only .toc file
3. **Launch WoW**: The addon will auto-detect your UI and apply optimal defaults
4. **Configure**: Use `/ahos` to open the beautiful options panel
5. **Enjoy**: Your hotkeys are now beautifully enhanced with intelligent overlays!

## 🐛 Troubleshooting & Support

### UI Detection Issues

If the addon doesn't detect your UI correctly:

1. **Enable debug mode**: `/ahos debug` for detailed output
2. **Manual detection**: `/ahos detectui` to force re-detection
3. **Check results**: Review chat output for loaded addons and detection logic
4. **Verify coverage**: The addon will list all detected UI-related addons

### Common Solutions

- **❌ Overlays not appearing**: Check if enabled with `/ahos toggle`
- **💾 Settings not saving**: Verify addon loaded properly (test `/ahos` command)
- **📐 Positioning issues**: Use `/ahos unlock` to adjust settings safely
- **🔍 Wrong UI detected**: Run `/ahos detectui` to manually re-detect your interface
- **🔒 Can't change settings**: Check if settings are locked (look for lock icon in options)

### Debug Information

Debug mode (`/ahos debug`) provides comprehensive information about:

- All loaded addon detection and compatibility
- UI detection logic with step-by-step results
- Addon loading status and library dependencies
- Current configuration state and profile information
- Real-time overlay creation and management status

## 📈 Recent Changes

**Latest Version: 1.3.0** - See [CHANGELOG.md](CHANGELOG.md) for complete update history.

### What's New

- Complete visual overhaul with modern interface design
- Professional organization with grouped settings and visual hierarchy
- Enhanced user experience with comprehensive tooltips and feedback
- Dynamic UI elements that adapt to current state
- Improved accessibility and usability across all features

## 🌍 Localization Support

The addon includes a robust localization framework ready for translation:

- **Structure**: Professional localization table system
- **Contributing**: Edit the localization table in the main Lua file
- **Languages**: Currently supports English (enUS) with framework for additional languages
- **Help Wanted**: Translations welcome for all WoW-supported languages!

## 🙏 Credits & Acknowledgments

- **JuNNeZ** - Primary author and maintainer
- **GitHub Copilot** - AI development assistant for advanced features
- **Ace3 Team** - Foundational addon framework (AceAddon, AceConfig, AceDB, etc.)
- **LibSharedMedia Team** - Font and media management system
- **LibDBIcon Team** - Minimap button integration
- **Titan Panel Team** - Panel integration support
- **WoW Addon Community** - Inspiration, feedback, and continuous improvement

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

---

**⚡ Advanced Hotkey Overlay System v1.3.0** - *Making WoW hotkeys beautiful, one overlay at a time!*
