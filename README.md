# ⚡ Advanced Hotkey Overlay System

**Advanced Hotkey Overlay System for World of Warcraft** - **Version 1.3.2**

## ✨ What's New in v1.3.2

- **🐛 Critical Bug Fix**: Resolved options panel loading error that prevented addon initialization
- **🎛️ Smart Options Management**: Master toggle now automatically hides/shows all other options for a cleaner interface
- **🎨 Streamlined Layout**: Moved master toggle to top, removed redundant header, integrated profile selector with status bar
- **🔒 Improved Stability**: Added proper type checking to prevent runtime errors

## 🌟 Key Features

- **⚡ Live updating hotkey overlays** with ConsolePort-style abbreviations
- **🎨 Real-time configuration**: All changes apply instantly (font, color, position, scale, etc.)
- **🔒 Smart lock system**: Prevent accidental changes during gameplay
- **👤 Profile management**: Per-character and global profiles
- **🎭 Advanced customization**: Comprehensive font, color, shadow, outline, and positioning options
- **🤖 Intelligent UI detection**: Automatically adapts to AzeriteUI, ElvUI, Bartender4, Dominos, and Blizzard UI
- **🎛️ Smart options management**: Master toggle hides irrelevant options when disabled
- **⚙️ Full Ace3 integration**: Robust addon framework with sophisticated configuration system
- **💬 Enhanced slash commands**: Comprehensive help and debugging tools
- **🗺️ Minimap integration**: Click to toggle the configuration panel
- **📊 Titan Panel support**: Status display with quick access
- **🎯 Optimized defaults**: Perfect settings for immediate usability across all UI addons

## 🎮 How to Use

### Slash Commands (Enhanced)

- `/ahos` or `/advancedhotkeyoverlaysystem` — Main command
  - `show` — Open the configuration panel
  - `lock` 🔒 — Lock overlays
  - `unlock` 🔓 — Unlock overlays
  - `reset` ⚠️ — Reset settings to defaults
  - `toggle` ✓/✗ — Enable/disable overlays
  - `reload` 🔄 — Smart refresh of all overlays
  - `help` 📚 — Show help with all commands
  - `debug` 🐛 — Toggle debug mode for troubleshooting
  - `detectui` 🔍 — Manually trigger UI detection

### Interface Features

- **🗺️ Minimap button**: Click to toggle the options panel
- **⚡ Live updates**: All settings change instantly
- **🎛️ Smart options management**: Master toggle automatically hides/shows all options for a cleaner interface
- **🔒 Lock protection**: Prevent accidental changes during combat or gameplay
- **📱 Organized settings**: Grouped into logical sections:
  - **Master Toggle**: Enable/disable the entire addon
  - **Status & Profile Bar**: UI detection, version info, and profile selector
  - **Quick Actions**: Smart Refresh and Temporary Clear tools
  - **Position Controls**: Precise positioning options
  - **Visual Properties**: Scale, transparency, and frame layer settings
  - **Font & Text Style**: Complete typography control
  - **Security & Lock**: Protection settings

## 📋 Requirements

- **Ace3 libraries** (bundled with addon)
- **LibSharedMedia-3.0** (bundled or via SharedMedia addon)
- **LibDBIcon-1.0** (bundled for minimap button functionality)
- **Titan Panel** (optional, for integration and status display)
- **World of Warcraft Retail** (Interface version 100207+)

## 🔧 Installation & Setup

1. **Download & Install**: Extract to your `Interface\AddOns` folder
2. **Launch WoW**: The addon will auto-detect your UI and apply optimal defaults
3. **Configure**: Use `/ahos` to open the options panel
4. **Enjoy**: Your hotkeys are now enhanced with intelligent overlays!

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
- **⚠️ Options panel error**: Restart WoW if you encounter loading issues (fixed in v1.3.2)

### Debug Information

Debug mode (`/ahos debug`) provides comprehensive information about:

- All loaded addon detection and compatibility
- UI detection logic with step-by-step results
- Addon loading status and library dependencies
- Current configuration state and profile information
- Real-time overlay creation and management status

## 📈 Recent Changes

**Latest Version: 1.3.2** - See [CHANGELOG.md](CHANGELOG.md) for complete update history.

### What's New

- **Critical bug fix**: Resolved options panel loading error
- **Smart interface management**: Master toggle now hides irrelevant options when disabled
- **Streamlined layout**: Optimized space usage with integrated status and profile bar
- **Enhanced stability**: Improved error handling and type checking

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

**⚡ Advanced Hotkey Overlay System v1.3.2** - *Making WoW hotkeys beautiful, one overlay at a time!*
