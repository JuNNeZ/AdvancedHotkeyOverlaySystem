# Installation

This page covers every method of installing, updating, and verifying the Advanced Hotkey Overlay System (AHOS) for all supported WoW versions.

---

## Table of Contents

- [Requirements](#requirements)
- [Choosing the Right WoW Version Folder](#choosing-the-right-wow-version-folder)
- [Install via CurseForge App](#install-via-curseforge-app)
- [Install via Wago App](#install-via-wago-app)
- [Install Manually (ZIP)](#install-manually-zip)
- [Install from GitHub Releases](#install-from-github-releases)
- [File Structure](#file-structure)
- [Updating AHOS](#updating-ahos)
- [Verifying the Installation](#verifying-the-installation)
- [Uninstalling](#uninstalling)

---

## Requirements

- World of Warcraft (any supported version — see below)
- No additional dependencies required
- Optional: **LibSharedMedia-3.0** (for additional font choices)
- Optional: **LibKeyBound-1.0** (for Dominos/Bartender4 keybind mode integration)

AHOS bundles its own copies of required libraries; you do not need to install them separately.

---

## Choosing the Right WoW Version Folder

WoW stores each game version in a separate folder. Install AHOS in the correct location:

| WoW Version | AddOns Folder Path |
|---|---|
| Retail (Mainline) | `World of Warcraft\_retail_\Interface\AddOns\` |
| Mists of Pandaria Classic | `World of Warcraft\_classic_\Interface\AddOns\` |
| Vanilla / Classic Era | `World of Warcraft\_classic_era_\Interface\AddOns\` |

> **Note:** On macOS, the path uses forward slashes and lives under `Applications/World of Warcraft/`.

---

## Install via CurseForge App

This is the easiest method and handles automatic updates.

1. Open the [CurseForge App](https://www.curseforge.com/download/app).
2. Select **World of Warcraft** and choose your game version (Retail, Classic, etc.).
3. Click **Browse** or use the search bar and search for `Advanced Hotkey Overlay System`.
4. Click **Install**.
5. Launch WoW — AHOS will be ready on your next login.

**Project ID:** `1289540` (use this if the search doesn't surface it immediately).

---

## Install via Wago App

1. Open the [Wago App](https://addons.wago.io/download).
2. Select your WoW version.
3. Search for `Advanced Hotkey Overlay System` and install.

---

## Install Manually (ZIP)

1. Go to the [CurseForge project page](https://www.curseforge.com/wow/addons/advanced-hotkey-overlay-system) or [WoWInterface](https://www.wowinterface.com/downloads/info-advanced-hotkey-overlay-system).
2. Click **Download** to get the latest ZIP file.
3. **Extract** the ZIP. You should see a folder named `AdvancedHotkeyOverlaySystem`.
4. Move (or copy) that folder into your WoW `AddOns` directory.

   **Example (Retail):**
   ```
   World of Warcraft\_retail_\Interface\AddOns\AdvancedHotkeyOverlaySystem\
   ```

5. Make sure you are copying the **folder itself**, not the contents directly into `AddOns`.

   ✅ Correct:
   ```
   AddOns\
   └── AdvancedHotkeyOverlaySystem\
       ├── AdvancedHotkeyOverlaySystem.lua
       ├── AdvancedHotkeyOverlaySystem.toc
       └── ...
   ```

   ❌ Incorrect:
   ```
   AddOns\
   ├── AdvancedHotkeyOverlaySystem.lua   ← wrong, files directly in AddOns
   └── AdvancedHotkeyOverlaySystem.toc
   ```

6. Start or **Reload** WoW (`/reload` in the chat box if already logged in).

---

## Install from GitHub Releases

For the absolute latest release or pre-release builds:

1. Go to the [GitHub Releases page](https://github.com/junnez/advancedhotkeyoverlaysystem/releases).
2. Download the ZIP asset from the most recent release (not the "Source code" ZIP — use the packaged release artifact).
3. Follow the same extraction steps as [Install Manually](#install-manually-zip).

> **Tip:** The GitHub source code ZIP includes the raw repo structure, which may differ from the packaged release. Always prefer the packaged release artifact.

---

## File Structure

After a correct install, your `AdvancedHotkeyOverlaySystem` folder should look like this:

```
AdvancedHotkeyOverlaySystem/
├── AdvancedHotkeyOverlaySystem.lua             ← Main addon file
├── AdvancedHotkeyOverlaySystem.toc             ← Shared TOC (loaded by all versions)
├── AdvancedHotkeyOverlaySystem_Mainline.toc    ← Retail-specific TOC
├── AdvancedHotkeyOverlaySystem_Mists.toc       ← MoP Classic TOC
├── AdvancedHotkeyOverlaySystem_Vanilla.toc     ← Classic Era TOC
├── Libs/                                        ← Bundled libraries
│   └── ...
├── locales/                                     ← Localization strings
│   └── ...
├── media/                                       ← Textures, fonts, etc.
│   └── ...
└── modules/                                     ← Feature modules
    └── ...
```

---

## Updating AHOS

### Via CurseForge / Wago App
Click **Update** next to the addon listing. Settings are preserved automatically.

### Manually
1. Download the new version ZIP.
2. **Delete** the old `AdvancedHotkeyOverlaySystem` folder from your `AddOns` directory.
3. Extract and copy the new folder in its place.
4. Your saved settings are stored in `WTF/`, **not** inside the addon folder, so they will not be affected by replacing the addon files.

> ⚠️ **Never** merge/overwrite an old install by extracting on top of it. Always delete the old folder first to avoid leftover files from previous versions.

---

## Verifying the Installation

After logging in:

1. Open the **AddOns** list on the character select screen — `AdvancedHotkeyOverlaySystem` should appear with a checkmark.
2. Log in to a character. You should immediately see abbreviated hotkey labels on your action buttons.
3. Type `/ahos` in chat — the options panel should open.

If the addon is listed but disabled:
- Make sure **"Load out of date AddOns"** is checked on the character select AddOns screen (only needed if using a very new WoW patch before AHOS has been updated).

---

## Uninstalling

1. Delete the `AdvancedHotkeyOverlaySystem` folder from your `AddOns` directory.
2. Optionally, remove saved settings by deleting the following from your `WTF/` folder:
   - `WTF/Account/<AccountName>/SavedVariables/AdvancedHotkeyOverlaySystem.lua`
   - `WTF/Account/<AccountName>/<RealmName>/<CharacterName>/SavedVariables/AdvancedHotkeyOverlaySystem.lua`
