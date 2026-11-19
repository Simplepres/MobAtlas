<p align="center"><img src="docs/images/icon.png" width="96" alt="MobAtlas"></p>

# MobAtlas · Следопыт

**Find an item. Discover its sources. Track them on your map.**

An offline loot atlas for World of Warcraft: Forever, with creature and vendor map markers, searchable items and dungeon quest preparation. Early test release **0.6.2**, targeting Interface **16001**.

[Download the addon](https://github.com/Simplepres/MobAtlas/releases/latest) · [Report a bug](https://github.com/Simplepres/MobAtlas/issues) · [Русский](#на-русском)

## What it does

- Search by English or Russian item name, item ID, or an item link pasted into the search field.
- Browse known creature drops and vendor inventories, then highlight the available source locations on the world map.
- Explore grouped map markers, inspect NPCs and items, and explicitly pin or unpin a selection.
- Filter by multiple item qualities, class, level and profession materials. Give rare and special loot priority.
- See known loot in creature tooltips while playing.
- Prepare for a dungeon with known quests, prerequisite steps and pickup locations. Includes quest associations for the nine new Forever dungeons, including The Hall of Thanes.
- Keep personal loot finds and visited merchant inventories locally to improve your own reference data.

No separate Questie installation, account, API key or background application is required to use the addon. Bundled reference data works offline.

## Screenshots / Скриншоты

Captured in the player's WoW Forever client on November 19, 2026. MobAtlas appears alongside other enabled addons; the surrounding unit frames, action bars, quest tracker and quest map overlays are not all features of MobAtlas.

### 1. Creature loot tooltip / Добыча при наведении на моба

![MobAtlas loot added to the in-world Leech Stalker tooltip](docs/images/creature-loot-tooltip.png)

Hovering **Leech Stalker** shows MobAtlas's known loot beneath the normal creature information: item icons, rarity-colored names and source labels. The list distinguishes Classic reference percentages from an unknown Forever chance.

**На русском:** при наведении на паука Leech Stalker в обычной подсказке появляется список известной добычи. Видны иконки, цвет редкости и источник данных. Неизвестный шанс не подменяется процентом из Classic.

### 2. Searchable item atlas / Атлас вещей и фильтры

![MobAtlas equipment list with current-level and known-source filters](docs/images/item-atlas-filters.png)

The atlas shows equipment with **My level** and **Known source** enabled. Each row includes an icon, rarity, required level and source count. **Карта** opens source navigation when map coordinates are available; a known source can still lack coordinates, leaving that button disabled. Category and source dropdowns narrow the list.

**На русском:** список экипировки отфильтрован по уровню персонажа и наличию известного источника. В строке указаны требуемый уровень и число источников. Активная кнопка «Карта» ведёт к источникам с координатами; серая означает, что подходящей точки пока нет. Категории и поиск помогают сузить список.

### 3. Dungeon preparation / Подготовка к подземелью

![MobAtlas dungeon preparation list for a level 22 character](docs/images/dungeon-preparation.png)

The preparation window lists nearby or level-relevant dungeons for a **level 22** character. Counts separate quests shown for the current level from later ones. Open a dungeon to inspect its known quests and prerequisite steps. The bottom reminders report free bag space and equipment repair status.

**На русском:** раздел «Перед походом в данж» показывает подходящие подземелья, количество заданий сейчас и на будущее. После выбора открывается список известных квестов и шагов цепочек. Внизу — напоминания о месте в сумках и ремонте. Справочные условия ещё требуют сверки в игре.

### 4. Map markers and loot inspection / Карта и просмотр добычи

![MobAtlas creature markers and Moss hide Mongrel loot card with an item tooltip](docs/images/map-loot-inspection.png)

Creature markers are shown on the Wetlands map, while the **Mosshide Mongrel** card displays its level, creature type and paginated known loot. Hovering **Sealed Journeyman's Writ** opens the game's item tooltip. **Закрепить** keeps the inspected source selected; **К группе мобов** returns to the group. Existing quest overlays remain visible alongside the addon.

**На русском:** на карте Болотины видны метки мобов и карточка Mosshide Mongrel: уровень, тип существа, добыча и страницы списка. Наведение на вещь открывает игровые характеристики. «Закрепить» сохраняет выбранный источник, «К группе мобов» возвращает к списку группы. Синие квестовые области и трекер справа относятся к остальному игровому интерфейсу.

## Install

1. Download **MobAtlas-0.6.2.zip** from [Releases](https://github.com/Simplepres/MobAtlas/releases/latest). Use this asset rather than GitHub's automatic “Source code” ZIP.
2. Extract the **MobAtlas** folder into your Forever client's `Interface/AddOns/` folder.
3. Check that the path ends in `Interface/AddOns/MobAtlas/MobAtlas.toc`.
4. Restart WoW and enable **MobAtlas** in the AddOns list.

For the client layout used during development, the installation folder is `_forever_/Interface/AddOns/MobAtlas/`.

## Quick start

| Action | How |
| --- | --- |
| Open the atlas | Left-click the minimap book or type `/mobatlas` |
| Search directly | `/mobatlas <item name or ID>` |
| Prepare for a dungeon | `/mobatlas prep` or **Перед данжем** |
| Open tracking controls | Right-click the minimap book |
| Open full settings | `/mobatlas settings` |
| Inspect a map group | Hover, then click and choose an NPC |
| Keep a selection on the map | **Закрепить** |
| Return to the map overview | **Открепить** / clear the selection |

The current custom interface is primarily Russian; item names and tooltips can follow your game client. Full English UI localization is not yet complete.

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

Third-party data and fonts retain their own terms; the bundled dataset is not presented as our original work or relicensed under one blanket license. See [license scope](LICENSE.md), [source details](MobAtlas/SOURCES.md) and [upstream notices](MobAtlas/Licenses/). QuestieDB's historical-contributor licensing caveat is preserved. AHledger's published terms include changes effective December 10, 2026; review them before rebuilding, redistributing or monetizing its data after that date.

Independent community project. Not affiliated with Blizzard Entertainment or the upstream data projects. World of Warcraft and its game assets belong to their respective owners.

## Development

The repository includes addon Lua files, generators, tests and the source snapshots used for this build. Source history is separate from personal SavedVariables.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python tests/run_mobatlas.py
.venv/bin/python tests/check_mobatlas_catalog.py
.venv/bin/python tests/check_mobatlas_data.py
.venv/bin/python tests/check_mobatlas_atlas.py
.venv/bin/python tests/check_mobatlas_preparation.py
```

Build an installable ZIP with `python3 tools/package.py`. See [development notes](docs/DEVELOPMENT-NOTES.ru.md) for data generation history and known limitations. Network refreshes are optional and may be rate-limited; offline snapshots are retained when an update fails validation.

## На русском

**Следопыт — атлас добычи для WoW Forever.** Найди вещь, посмотри источники и выдели известных мобов или продавцов на карте.

Аддон объединяет мобов в группы, показывает добычу с иконками и цветом редкости, позволяет закрепить выбранный источник и отфильтровать вещи под класс, уровень и профессии. Раздел **«Перед данжем»** помогает найти известные задания и первые шаги цепочек, включая The Hall of Thanes.

**Установка:** скачай `MobAtlas-0.6.2.zip` в [Releases](https://github.com/Simplepres/MobAtlas/releases/latest), распакуй папку `MobAtlas` в `Interface/AddOns/` клиента Forever и перезапусти игру. Questie отдельно устанавливать не нужно.

**Управление:** `/mobatlas` — атлас, `/mobatlas prep` — подготовка к подземелью, `/mobatlas settings` — настройки. ЛКМ по книжке у миникарты открывает атлас, ПКМ — управление отображением. В карточке нажми **«Закрепить»**, на карте — **«Открепить»**, чтобы вернуться к обзору.

Это ранняя тестовая версия. База неполная: неизвестные шансы, условия заданий и координаты не заменяются выдуманными значениями. Данные Classic и наблюдения Forever различаются. Личные находки сохраняются только на твоём компьютере.

Об ошибках пиши в [Issues](https://github.com/Simplepres/MobAtlas/issues): что делал, что ожидал, что произошло; добавь зону, название вещи/моба и текст ошибки, если они известны.
