## MobAtlas 0.7.17 Beta

- Одинаковые записи источников и координат теперь хранятся один раз. В Lua-симуляторе на той же базе память после входа снизилась с 160 до 82 МиБ относительно локальной 0.7.16. Данные предметов, NPC, добычи и заданий сверены с предыдущей сборкой.
- Поисковый индекс строится по необходимости и освобождается через 20 секунд после закрытия атласа. Карта, подсказки и запись находок работают без постоянного индекса.
- «Для меня» показывает улучшения и вещи для пустых слотов. Добавлены рейтинг внутри слота и сравнение выбранной вещи по спекам класса.

### English

- Shared source records and coordinates cut the post-login Lua mock memory from 160 to 82 MiB on the same catalog, compared with local build 0.7.16. Item, NPC, loot and quest records were verified against the prior build.
- The search index is built on demand and released 20 seconds after the atlas closes. Map pins, tooltips, and personal loot recording work without a resident index.
- Gear for me shows upgrades and gear for empty slots, with slot rankings and ratings for each specialization in your class.

После обновления / After updating: `/reload`.
