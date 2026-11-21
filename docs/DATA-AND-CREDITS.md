# Data, privacy and credits

## Data and accuracy

MobAtlas combines reference catalogs with local observations. It is **not a live creature radar** and is not a complete or fully verified database of the current Forever build.

- Map markers are recorded spawn locations or known dungeon entrances, not guaranteed current spawns.
- Classic reference percentages are labeled separately from Forever observations. An unknown chance remains unknown.
- Shared world-drop pools are hidden by default; a large potential loot table does not mean every item is a unique drop from that NPC.
- Some quest requirements, giver coordinates, entrances and dungeon sources are incomplete. Indoor quest markers show an entrance with an explanation, not an invented indoor NPC position.
- Quest associations exist for all nine announced new Forever dungeons; this is not a claim that every quest, prerequisite or drop is covered. Five later dungeons currently lack verified entrance coordinates in this build.
- Filters can hide items. Try other quality, class, level or source filters when investigating a missing result.

The test suite uses simulated WoW APIs. In-game compatibility and visual checks still need player testing. Please include your client build, zone, NPC/item ID if known, active filters and error text when reporting problems. Never upload your entire WTF folder or account information.

## Privacy

The addon does not make network requests or upload your gameplay. Settings, personal loot observations and merchant visits are stored in the local `MobAtlasDB` SavedVariables table. Data refresh scripts run separately, outside the game.

## Credits and licensing

Data sources include QuestieDB/Questie contributors, Everloot contributors, Classic reference datasets, WoW Forever KB and AHledger. **Item metadata from [AHledger](https://ahledger.com)**; no auction prices are claimed here. Noto Sans is distributed under the SIL Open Font License.

Third-party data and fonts retain their own terms; the bundled dataset is not presented as our original work or relicensed under one blanket license. See [license scope](../LICENSE.md), [source details](../MobAtlas/SOURCES.md) and [upstream notices](../MobAtlas/Licenses/). QuestieDB's historical-contributor licensing caveat is preserved. AHledger's published terms include changes effective December 10, 2026; review them before rebuilding, redistributing or monetizing its data after that date.

Independent community project. Not affiliated with Blizzard Entertainment or the upstream data projects. World of Warcraft and its game assets belong to their respective owners.


Local preview map overlay data: adapted from [ForeverPlusPlus](https://github.com/xIGBClutchIx/ForeverPlusPlus), MIT, copyright 2026 Cameron Weaver. Source and pinned provenance in vendor/map-reveal; license in MobAtlas/Licenses/MapReveal-MIT.txt. File identifiers reference Blizzard game assets; no map textures are redistributed.
