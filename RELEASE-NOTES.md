# MobAtlas 0.7.0 — Beta

Rare tracking is here: alerts on client-visible rare nameplates/targets/mouseover, map and minimap markers, loot inspection, and softer spawn-area shading for selected creatures. The bundled reference catalog includes **346 rare NPCs**.

Open **/mobatlas rares** or right-click the minimap book → **Rare creatures…**. Toggle alerts, sound, map/minimap markers, distance and shading separately.

The distance option requests nameplate range up to **80** and enables enemy nameplates outside combat. Actual range is limited by the client. Disable the option to restore your previous values if they have not since changed.

Reference spawn markers do not mean a rare is alive. Confirmed positions are highlighted only when the client supplies NPC coordinates. If it does not, known locations stay explicitly marked as reference data. Player coordinates are never substituted for an NPC's. Repeated sightings of the same spawn do not spam alerts.

**Fully restart WoW** after installing **MobAtlas-0.7.0.zip** into `Interface/AddOns/` to load the new modules.

## На русском

Добавлены редкие мобы: уведомления при обнаружении, метки на карте и миникарте, просмотр добычи. Для выбранного моба — мягкая подсветка известных мест появления, без яркой сплошной заливки. В справочнике **346 редких NPC**.

Настройки: **/mobatlas rares** или ПКМ по книжке → **«Редкие мобы…»**. Звук, уведомления, метки, дальность и подсветку можно менять отдельно.

Опция дальности запрашивает до **80** и включает имена врагов вне боя. Фактический предел задаёт WoW; выключение опции возвращает прежние значения, если они не менялись. При недоступных координатах моба аддон показывает только справочные места с соответствующей подписью. Точка из базы не означает живого NPC. Позиция игрока вместо моба не подставляется.

**Полностью перезапусти WoW** после обновления. Это бета; тесты используют симулятор WoW API, нужна проверка в живом клиенте. RareScanner не требуется, его код и база не копировались.

Вопросы и баги / Feedback: [Telegram @brunotwin](https://t.me/brunotwin) · [Threads @teur_person](https://www.threads.com/@teur_person).
