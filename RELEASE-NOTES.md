# MobAtlas 0.7.1 — Beta

Gray Fox was in the reference catalog but hidden by a faction filter. Neutral creatures are no longer excluded merely for an AH flag; service NPCs remain filtered. Client-confirmed attackability can correct reference flags locally.

- Refreshed the QuestieDB snapshot and retained outdoor metadata for new NPCs even when their loot is not known.
- Added the player's **Gray Fox → Sharp Canine** report, explicitly labeled **player report / unknown chance**. No rate is invented.
- Hover loot now indicates that more items are available beyond the top few shown.
- Loot learning retains exact API-provided NPC sources, uses reference geometry, and resolves uncached item metadata without rebuilding the full index.

New Forever mobs and loot associations are included; **full loot tables are not available for every new creature**. A player report is distinct from a direct API observation or a measured drop rate.

Install **MobAtlas-0.7.1.zip** in `Interface/AddOns/`, then **/reload**. No new TOC files in this patch.

## На русском

**Gray Fox уже был в базе**, но скрывался из-за фильтра дружественных NPC. Исправили правило для нейтральных существ, сохранив фильтрацию служебных NPC. Данные клиента о возможности атаковать моба могут исправлять справочную пометку локально.

Добавлены **Sharp Canine у Gray Fox** как сообщение игрока с неизвестным шансом и счётчик оставшейся добычи в подсказке. Обновлён снимок QuestieDB, расширены метаданные новых NPC. Личные находки и отложенная загрузка свойств предмета обрабатываются точечно, без полной пересборки базы.

Новые мобы и связи с лутом в аддоне есть, но **полных таблиц для всех новых мобов пока нет**. Источники и ограничения указаны в SOURCES.md. После установки достаточно **/reload**; если пропустил 0.7.0, полностью перезапусти WoW.

Вопросы и баги / Feedback: [Telegram @brunotwin](https://t.me/brunotwin) · [Threads @teur_person](https://www.threads.com/@teur_person).
