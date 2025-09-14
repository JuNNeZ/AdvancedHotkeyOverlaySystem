# Release Checklist

Use this checklist to ensure every release is consistent and complete.

## Pre-release (local)

1. Run the pre-release task in VS Code:
   - Tasks: "AHOS: Pre-Release (lint+docs+verify)"
   - This will:
     - Lint all Lua files
     - Sync README and CURSEFORGE versions from the TOC
     - Verify version consistency across TOCs, README, CHANGELOG, and CURSEFORGE
2. Review CHANGELOG.md and ensure the new version section is present and accurate.
3. Optional: Update release notes in GitHub (draft them now if you like).

## Tag and push

1. Commit any outstanding changes:
   - chore(release): bump version to x.y.z and update docs
2. Create a tag for the release:
   - vX.Y.Z
3. Push main and tags to GitHub.

## CI/CD


### Notes on packaging

- We ship three flavors: Mainline (Retail), Mists, and Vanilla. Each has its own suffixed TOC.
- The unsuffixed `AdvancedHotkeyOverlaySystem.toc` exists for local development convenience only.
   It is excluded from packaging via `.pkgmeta` and lacks upload target IDs, preventing a duplicate
   Retail upload. If you see multiple identical Retail uploads in a release, ensure both of these
   safeguards are present.

- Verify the release on CurseForge/WoWI/Wago.
- If needed, update CURSEFORGE.md Recent Updates with highlights.
