# Advanced Hotkey Overlay System

Enhanced hotkey overlays for all action bar addons with intelligent UI detection and real-time customization

## What does this addon do?

Advanced Hotkey Overlay System replaces the default hotkey text on your action buttons with fully customizable overlays. It currently has dedicated support for the default Blizzard interface, AzeriteUI, and Dominos, with conflict-aware handling for ElvUI.

## Key Features

### Universal Compatibility

- Automatically detects Blizzard UI, AzeriteUI, Dominos, and ElvUI conflict state
- Focused support for the action bar addons the codebase explicitly targets
- Intelligent button detection for new and custom action bars

### Real-Time Customization

- All settings apply instantly—no UI reload needed
- Live preview of font, color, position, and scale changes
- ConsolePort-style hotkey abbreviations (e.g., Ctrl → C, Shift → S)

### Complete Visual Control

- Choose font family, size, color, and transparency
- Text shadows and outlines for maximum readability
- Pixel-perfect positioning and multiple anchor points

### Smart Protection System

- Lock settings to prevent accidental changes during gameplay
- Confirmation dialogs for protected options
- Master toggle to hide all overlays and options when disabled

### Profile Management

- Per-character and global profiles via Ace3
- Effortless switching between configurations
- Import/export settings for easy sharing

### Advanced Tools

- Comprehensive debug mode and in-game inspection commands
- Smart refresh to re-detect UI changes
- Temporary overlay clearing for screenshots
- Minimap and Titan Panel integration

## How to Use

1. **Install and Enable**: Extract to your AddOns folder and enable in-game.
2. **Automatic Setup**: The addon detects your UI and applies optimal defaults.
3. **Configure**: Use `/ahos` or click the minimap button to open settings.
4. **Customize**: Adjust position, appearance, and behavior to your liking.

## Slash Commands

- `/ahos` — Open configuration panel
- `/ahos toggle` — Enable/disable overlays
- `/ahos lock` — Lock settings to prevent changes
- `/ahos reset` — Reset to default settings
- `/ahos debug` — Enable debug mode for troubleshooting
- `/ahos help` — Show all available commands

## Troubleshooting

**Overlays not appearing?**

- Check if the addon is enabled with `/ahos toggle`
- Try `/ahos reload` to refresh detection
- Use `/ahos debug` for detailed troubleshooting

**Wrong UI detected?**

- Use `/ahos detectui` to manually re-detect your interface
- Check debug output to see which addons were found

**Settings not saving?**

- Ensure the addon loaded properly by testing `/ahos`
- Make sure settings aren’t locked (unlock with `/ahos unlock`)

## Requirements

- World of Warcraft Retail or Classic (current patches)
- Ace3 libraries (included)
- LibSharedMedia-3.0 (included)
- LibDBIcon-1.0 (included)

## Recent Updates (v2.5.12)
- Fixed Dominos binding resolution by preferring addon-provided command names and hotkey refresh hooks.
- Modernized the in-game options layout around status, compatibility, support, and debugging.
- Updated Retail, Mists, and Vanilla TOC targets for current client builds while keeping Retail `120000` compatibility.

---

**Perfect for players who want readable, customizable hotkeys that work with any UI setup!**
