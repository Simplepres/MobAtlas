# MobAtlas delivery workflow

The user requests that future addon changes be installed in their WoW client and pushed to GitHub after validation. This authorization persists; do not ask again for routine updates within that scope.

- Development source: `/Users/brunotwin/Documents/Codex/2026-11-10/x20-2/work/MobAtlas`.
- Git repository: `/Users/brunotwin/Documents/Codex/2026-11-10/x20-2/publish/MobAtlas`.
- Installed addon: `/Users/brunotwin/Documents/World of Warcraft/_forever_/Interface/AddOns/MobAtlas`.
- GitHub: `Simplepres/MobAtlas`, branch `main`.

For runtime/data changes, keep source, repository addon folder and installed addon in sync; run appropriate tests, verify hashes, commit and push. Do not overwrite unrelated upstream changes. Preserve notices, source provenance, original user data and the Putnik addon. Never commit WTF/SavedVariables, credentials or personal observations.

Keep all three version strings synchronized (TOC, Core.lua and package tooling) when releasing a new addon build. Publish a versioned installable ZIP as a GitHub Release; validate its folder structure and public download. Retain existing released assets; do not silently replace runtime builds under an existing tag. Tell the user whether /reload or a full client restart is needed.

Documentation/screenshots-only changes need no runtime version bump or reinstall; confirm runtime/data files remain identical. Update GitHub README and relevant release descriptions. Preserve public installation documentation when syncing the development README, which contains historical notes.
