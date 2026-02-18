# AHOS Development Roadmap

**Current Version:** 2.5.6 (November 8, 2025)

## Recent Accomplishments ✓

### v2.5.3 - v2.5.6 (November 2025)
- ✓ Separated debug output (DebugPrint) from user messages
- ✓ Added 9 easter egg commands with visual effects
- ✓ Fixed combat lockdown overlay persistence
- ✓ Fixed dragonriding/vehicle bar transition overlay loss
- ✓ Optimized overlay lifecycle to prevent unnecessary clearing

---

## Immediate Priorities (v2.5.7 - v2.6.0)

### 🔴 Critical Bugs
**Priority: HIGH | Timeline: Next patch**

1. **Test dragonriding fix thoroughly**
   - Verify overlays persist across all mount types
   - Test with different UI addons (ElvUI, Bartender4, Dominos)
   - Confirm no memory leaks from overlay preservation
   - Test vehicle UI transitions (tanks, drakes, etc.)

2. **Performance optimization needed**
   - Current `UpdateAllOverlays()` processes ALL buttons on every bar event
   - Implement incremental updates for specific buttons only
   - Add Performance:QueueFullUpdate() debouncing/throttling
   - Profile overlay creation/update performance with large button sets

### 🟡 Quality of Life Improvements
**Priority: MEDIUM | Timeline: v2.6.0**

1. **Enhanced UI addon detection**
   - Add support for newer action bar addons (NeuronBars, LUI)
   - Improve Dominos button detection beyond 200 buttons
   - Add Plater/TellMeWhen integration for custom bars
   - Document which addons are officially supported

2. **Overlay positioning refinements**
   - Per-bar anchor/offset customization (not just global)
   - Interactive overlay positioning mode (drag to adjust)
   - Visual preview when adjusting position settings
   - Preset layouts for common UI configurations

3. **Keybind display enhancements**
   - Mouse button icon support (🖱️ visual indicators)
   - Gamepad button glyph support (Xbox/PS controllers)
   - Custom color rules per modifier (Shift=blue, Ctrl=red, etc.)
   - Font shadow/glow effects for better readability

---

## Short-Term Features (v2.6.x - v2.7.0)

### 📦 New Functionality
**Priority: MEDIUM | Timeline: 1-2 months**

1. **Action bar fade system**
   - Option to fade/hide overlays out of combat
   - Mouseover show/hide for specific bars
   - Integrate with ElvUI/Bartender fade settings
   - Custom fade alpha and duration controls

2. **Conditional overlay display**
   - Hide overlays for empty slots (currently just skips creation)
   - Show only when modifier key held (advanced users)
   - Per-spec overlay profiles (auto-switch on spec change)
   - Combat/non-combat different styles

3. **Improved profile management**
   - Quick profile switcher slash command
   - Profile templates (tank, healer, DPS layouts)
   - Cloud sync via WoW account data (cross-character)
   - Profile versioning and rollback

### 🔧 Technical Debt
**Priority: LOW-MEDIUM | Timeline: Ongoing**

1. **Code modernization**
   - Refactor large modules (Display.lua is 1200+ lines)
   - Split Options.lua into separate files per category
   - Standardize error handling across all modules
   - Add type annotations for better IDE support

2. **Testing infrastructure**
   - Create automated test suite for keybind detection
   - Mock WoW API for unit testing
   - Add integration tests for UI addon compatibility
   - Performance benchmarking framework

3. **Documentation improvements**
   - API documentation for module interactions
   - Add inline code comments for complex logic
   - Create developer setup guide
   - Document SafeCall pattern for contributors

---

## Long-Term Vision (v3.0.0+)

### 🚀 Major Features
**Priority: LOW | Timeline: 3-6 months**

1. **Multi-language hotkey support**
   - Non-Latin keyboard layouts (Cyrillic, Asian)
   - Custom keybind symbols/abbreviations per locale
   - Unicode glyph support for international players

2. **Advanced customization**
   - LUA snippet conditions for overlay visibility
   - Custom font support (SharedMedia integration)
   - Texture backgrounds for overlays
   - Animation on button press (flash, pulse effects)

3. **WeakAuras integration**
   - Export overlay settings as WeakAura
   - Sync overlay positions with WA custom bars
   - Conditional display based on WA triggers

4. **Click-through editor mode**
   - `/ahos edit` - Visual overlay editor
   - Drag overlays to new positions
   - Preview different fonts/colors live
   - Save as new profile

### 🌐 Ecosystem Support
**Priority: LOW | Timeline: 6+ months**

1. **WoW Classic Hardcore support**
   - Test compatibility with Classic Era
   - Add Season of Discovery bar patterns
   - Ensure no performance impact on lower-end systems

2. **Cataclysm Classic preparation**
   - Update bar definitions for Cata action bars
   - Test with Cata talent system changes
   - Verify combat lockdown behavior

3. **Community features**
   - Profile sharing via string export/import
   - Online profile repository (wago.io integration?)
   - Community-contributed UI presets
   - Discord bot for profile sharing

---

## Known Issues & Limitations

### 🐛 Tracked Bugs
1. ~~Overlays disappear during dragonriding mount~~ **FIXED v2.5.6**
2. ~~Combat mount transitions clear MultiBar overlays~~ **FIXED v2.5.5**
3. ~~Debug spam in chat window~~ **FIXED v2.5.3**
4. Some LibKeyBound modes may not trigger overlay updates properly
5. Original hotkey text capture can fail on first login (requires `/reload`)

### ⚠️ Design Limitations
1. Cannot modify overlays during combat lockdown (WoW API restriction)
2. Some custom action bar addons use non-standard button templates
3. Gamepad/controller detection requires ConsolePort addon
4. Profile auto-switching only supports spec changes, not talent loadouts

### 📝 Enhancement Requests from Users
- Better Masque skin integration (outline/border matching)
- Per-button overlay toggle (disable specific buttons)
- Overlay stacking for macro conditionals (show all possible binds)
- Integration with OPie/BindPad custom bindings

---

## Development Principles

### Code Quality Standards
- ✓ All Lua files must pass lint (luacheck/lua-language-server)
- ✓ No nil errors or taint in production
- ✓ Combat lockdown aware (InCombatLockdown checks)
- ✓ Backward compatibility with Classic/Vanilla TOC files
- ✓ SafeCall pattern for inter-module communication

### Performance Guidelines
- Target: < 1ms frame time impact during overlay updates
- Maximum 0.5MB memory footprint
- Debounce high-frequency events (UPDATE_BINDINGS)
- Use frame pooling to reduce garbage collection

### User Experience Goals
- Zero configuration for 80% of users (works out of box)
- Options panel should be intuitive without documentation
- Debug mode available but hidden from casual users
- Easter eggs remain hidden unless discovered

---

## How to Contribute

1. **Bug Reports:** Open GitHub issue with `/ahos debugexport` output
2. **Feature Requests:** Discuss in GitHub Discussions first
3. **Code Contributions:** Follow `.github/copilot-instructions.md` patterns
4. **Testing:** Report compatibility with different UI addons

### Current Development Needs
- [ ] Testers for Dominos/Bartender4/LUI configurations
- [ ] Classic Era overlay pattern contributors
- [ ] Performance profiling on low-end systems
- [ ] Localization translators (non-English)

---

## Version Numbering

**Format:** `MAJOR.MINOR.PATCH`
- **MAJOR:** Breaking changes, major rewrites (v3.0.0)
- **MINOR:** New features, significant improvements (v2.6.0)
- **PATCH:** Bug fixes, small tweaks (v2.5.7)

**Release Schedule:**
- Patches: As needed (critical fixes)
- Minor: Monthly (feature updates)
- Major: Yearly or WoW expansion cycles

---

**Last Updated:** November 8, 2025  
**Maintainer:** JuNNeZ  
**License:** All Rights Reserved
