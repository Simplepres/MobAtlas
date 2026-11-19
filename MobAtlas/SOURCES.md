# Источники

NPC, предметы, прямые таблицы лута, общие пулы и мировые координаты: WoW Forever Friends, https://www.wowforeverfriends.org/library/sources/ . Это Classic-reference snapshot из CMaNGOS Classic-DB. Лицензия GPL-3.0 находится в Licenses/ReferenceSources-GPL-3.0.txt. Трансформация сохраняет фактические поля и явно отмечает неизвестную общую вероятность; тексты квестов и комментарии не импортируются.

Структурированные входы: /library/data/npcs.json, /items/items.json, /assets/library/npc-data/{id}.json. Таблицы лута извлечены из /npcs/{id}/, содержимое общих пулов — только из раздела Pool contents на /library/loot/{id}/. Обратный список Sources that select this pool не используется как содержимое пула.

Границы карт, классовые ограничения и реагенты: https://github.com/Everloot/everloot/tree/main/web/src/data/game-data , клиент 1.60.1.70888. Game data © Blizzard Entertainment, Inc., not under Everloot's code licence. Names of columns from WoWDBDefs, CC BY-SA 4.0. Преобразование JSON → Lua; преобразование мировых XY в проценты карты, выбор самого маленького подходящего прямоугольника зоны. Код Everloot не используется.

Шрифт Noto Sans: https://github.com/notofonts/noto-fonts , SIL OFL 1.1, текст в Licenses/NotoSans-OFL.txt.

Data.lua — преобразованный слой GPL-3.0. Исходный архив содержит генератор, входные снимки и кэш загруженных таблиц для воспроизводимости. Дата сборки: 2026-11-15.

## Forever 0.2.0

https://everloot.app/api/rollups/drops — публичные наблюдения NPC/предмет, CC BY-SA 4.0, Data from Everloot (https://everloot.app). Снимок dataAsOf 2026-11-15T06:40:14.545Z. Скачаны все 4 страницы, выбран только sourceNpcId (объекты не превращаются в мобов). 1647 связей с public=true и reporters>=3. kills в схеме означает окна добычи, не убийства. Способ добычи не разделён. Преобразование: rate × 100, сохранение drops/kills/reporters, отдельный метод 4, без подмены Classic-записей или создания координат. Лицензия: https://creativecommons.org/licenses/by-sa/4.0/ . Изменённый слой наблюдений распространяется по той же лицензии.

https://everloot.app/api/edges/client-layer — актуальная классификация предметов и связи реагентов, клиент 1.60.1.70938. Game data © Blizzard Entertainment, Inc.; not under Everloot's licence. Column names from WoWDBDefs (https://github.com/wowdev/WoWDBDefs), CC BY-SA 4.0. JSON содержит собственные credit/build/label. Данные из файлов клиента не подтверждают выпадение.

Документация API: https://everloot.app/docs/api . Обновление: update_mobatlas_forever.py. Не загружаем данные игрока и не используем закрытые endpoints.

Принципы отображения 0.2.2 изучены по Questie: https://github.com/Questie/Questie/blob/master/Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua (AREA_POI, scaling limits), Modules/FramePool/QuestieFrame.lua (texture/frame ordering). Код и ресурсы Questie не включены; независимая реализация для MobAtlas.

## 0.3.0 — замена геометрии, продавцы, аудит

Предыдущие описания выбора карты по прямоугольнику относятся только к 0.1–0.2. В 0.3 этот алгоритм удалён. Источник: https://github.com/Questie/QuestieDB , ревизия/хэши в Catalog-BUILD.json. Используются data/Forever/foreverNpcDB.lua, foreverItemDB.lua и support/Forever/Zones/areaIdToUiMapId.lua. Явный AreaID, без выбора по охватывающим прямоугольникам; снимок raw, без полного стека corrections. Условия использования и оговорки авторов сохранены в Licenses/QuestieDB-LICENSE.md, полный GPLv3 — QuestieDB-gpl-3.0.md; происхождение — QuestieDB-PROVENANCE.md. Преобразованный слой Catalog.lua распространяется на условиях GPLv3, оригинальные исходники включены в source.zip. Название и логотип Questie не заимствуются.

Наблюдения Forever обновлены: dataAsOf 2026-11-15T17:40:15.265Z, 1724 публичных NPC/item записей. У каждого источника — счётчики, не гарантия дропа. Полные JSON включены. Личные наблюдения продавцов не публикуются и не выдаются за общественно подтверждённые факты.

Семантика C_MerchantFrame.GetItemInfo проверена по Blizzard_APIDocumentationGenerated/MerchantFrameDocumentation.lua (WoW UI source mirror Gethe/wow-ui-source) и адаптеру API в Everloot; реализация сборщика независимая. Чтение цен/ассортимента не вызывает покупки или продажи.

## 0.4.0 refresh, 2026-11-18
QuestieDB master 4a73dc6513f05714101cfc93eda147947b75574a; raw Forever tables + generated NPC/item traces + Russian item names. Full authored/character-dependent corrections are not evaluated. Reference drop associations have unknown rates. Dungeon entrance geometry remains separate from NPC spawns; legacy dungeon map overrides are not floor geometry. See Catalog-BUILD.json for input hashes.
Everloot refresh on 2026-11-18 returned an empty feed. Retained the fully reproducible 2026-11-15T17:40:15.265Z snapshot from the previous source archive (1724 NPC/item observations); do not describe it as live/current completeness.

## Повторная проверка источников 2026-11-18
- Клиент C_Item/GetItemInfo: актуальное название/качество/характеристики доступного предмета; не таблица всех возможных источников. GetLootSourceInfo: связь слота окна добычи с GUID, используем для личных находок без выдуманного процента.
- QuestieDB Forever + traces: открытый воспроизводимый базовый справочник источников и геометрии; полнота и полный стек corrections ограничены, версия закреплена в Catalog-BUILD.json. https://github.com/Questie/QuestieDB/blob/master/docs/forever.md
- Everloot: публичный API, датированные снимки, счётчики и лицензия; подтверждение 3 установками означает, что редкие/новые находки могут ещё отсутствовать. Новая документация уточняет: актуальный rollup исключает skinning; для него нужен типизированный corpus. Старый сохранённый снимок не переименовываем задним числом. https://everloot.app/docs/addon-authors
- Wowhead Forever: подходит для ручной сверки конкретного ID/источника; открытая страница требует JS, готовый лицензированный полный JSON/API здесь не подтверждён. https://www.wowhead.com/forever
- AzerDex: наблюдения, явно опубликованные дата и покрытие. При проверке показаны 150 предметов/139 источников/5 зон, публикация 9 ноября; не замена полному каталогу. https://azerdex.com/
Правило обновления: сохранить дату/версию, различать справочник, личную находку и агрегированную частоту; не смешивать kill/skinning/pickpocket и не стирать непустую базу пустой выдачей. Новые внешние сайты не импортируются массово без подтверждённых формата и условий использования.

## 0.5.0 expansion, 2026-11-18
https://github.com/gBlaku/wow-forever-kb / static JSON API: generated 2026-11-17T15:59:40Z, client 1.60.1.70959; includes Blizzard client metadata, QuestieDB quest/vendor references and vMaNGOS Classic loot. Each source kind is preserved. Classic percentages are never relabeled as Forever rates. Hidden/junk flags are checked when present; items with unknown acquisition stay searchable but are not useful-source recommendations.
https://ahledger.com/api/catalog?class=… : 12 explicit item-class catalogs, item metadata only. Initial 429 was followed by successful public endpoint requests, no bypass. Credit AHledger (ahledger.com) is added to item evidence. The API rows do not themselves carry a build date, so fetch date and the site's advertised build must not be mistaken for individually observed facts. Terms in Licenses/AHledger-Attribution.txt; future cache/commercial restrictions need review before distribution.
Quest preparation uses QuestieDB raw Forever quest/object/NPC tables and generated quest traces, with RU quest titles. Dungeon membership uses explicit area tags, dungeon objective creatures and quest-class objective item sources. Generic material drops are excluded from dungeon membership. Full authored/character-dependent correction stack is not reproduced, so availability is tentative pending the game's quest giver. Counts/hashes: Expansion-BUILD.json.

## 0.6.2 Forever dungeon preparation audit, 2026-11-18
Curated explicit quest ID memberships in vendor/extra/dungeon-overrides.json fill missing upstream dungeon associations for all nine announced Forever dungeons. Hall of Thanes uses upstream AreaID 16919 and QuestieDB entrance coordinates (the portal under Old Ironforge, distinct from the High Seat approach). NPC positions come from QuestieDB traces; indoor quests map only the entrance and explain pickup inside. Dark Iron Map prerequisite navigates its recorded creature sources, never a guessed point. Hall quest minimum levels and chain checked against https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards and https://www.wowhead.com/forever/item=274268/dark-iron-map . General dungeon level ranges from https://news.blizzard.com/en-gb/article/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever . Missing quest minimum levels remain unknown; recommended dungeon ranges only guide list filtering, not claimed eligibility. Five later dungeons use private negative atlas identities, with no invented entrances. Known quest membership is not a completeness claim; absent giver coordinates and authored prerequisites remain gaps.
