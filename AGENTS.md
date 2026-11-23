# MobAtlas delivery workflow

Keep future addon changes installed in the local WoW client after validation. Commit, push, and publish validated bug fixes to GitHub without waiting for a separate request. Other changes require explicit publication authorization. Keep the local publish working copy synchronized.

- Development source: `/Users/brunotwin/Documents/Codex/2026-11-10/x20-2/work/MobAtlas`.
- Git repository: `/Users/brunotwin/Documents/Codex/2026-11-10/x20-2/publish/MobAtlas`.
- Installed addon: `/Users/brunotwin/Documents/World of Warcraft/_forever_/Interface/AddOns/MobAtlas`.
- GitHub: `Simplepres/MobAtlas`, branch `main`.

For runtime/data changes, keep source, repository addon folder and installed addon in sync; run appropriate tests, verify hashes. Do not overwrite unrelated upstream changes. Preserve notices, source provenance, original user data and the Putnik addon. Never commit WTF/SavedVariables, credentials or personal observations.

Keep all three version strings synchronized (TOC, Core.lua and package tooling) when releasing a new addon build. When publication is authorized, publish a versioned installable ZIP as a GitHub Release; validate its folder structure and public download. Retain existing released assets; do not silently replace runtime builds under an existing tag. Tell the user whether /reload or a full client restart is needed.

Documentation/screenshots-only changes need no runtime version bump or reinstall; confirm runtime/data files remain identical. Prepare README and relevant release descriptions locally; publish them with a bug-fix release or when explicitly requested. Preserve public installation documentation when syncing the development README, which contains historical notes.
