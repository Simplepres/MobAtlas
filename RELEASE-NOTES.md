# MobAtlas 0.7.4 — Beta

Habitat highlights now distinguish an explicit pin from ordinary navigation focus. Closing a temporary loot card clears its area; background map updates cannot restore it. Pinned habitats remain until unpinned. Group lists no longer paint the habitats of every NPC at once.

Replaced blurred spawn halos with translucent, crisp outlined patches built from actual spawn coordinates. Distant camps are not joined. Drawing reuses a bounded pool; removed redundant habitat rendering when refreshing a pinned loot card.

Lua mock checks cover preview close with/without a pin, idle refresh, unpin, combat navigation and dungeon compatibility. A 100-new-item loot check triggers zero full atlas rebuilds. Performance timings are development measurements, not in-game FPS or a guarantee of no stutters.

## На русском

Исправлена повторная отрисовка области после закрытия добычи: обычный выбор источника больше не считается закреплением. Подсветка остаётся только при просмотре конкретного моба или явном закреплении. Список группы не выделяет сразу всех мобов.

Вместо размытого свечения — полупрозрачные области с чёткой границей по местам появления. Удалённые лагеря не соединяются. Убрана лишняя повторная отрисовка закреплённой карточки, элементы переиспользуются.

Обновление уже можно применить через **/reload**. Замеры выполнены в Lua-симуляторе; работу и FPS в клиенте ещё нужно проверить.
