<p align="center"><img src="docs/images/icon.png" width="96" alt="MobAtlas"></p>

# MobAtlas · Следопыт

Атлас добычи, экипировки и заданий для **WoW Forever**. **Бета 0.7.17.**

A loot atlas, gear finder and dungeon quest guide for **WoW Forever**. **Beta 0.7.17.**

[**Скачать / Download**](https://github.com/Simplepres/MobAtlas/releases/latest) · [Скриншоты / Gallery](#скриншоты--gallery) · [Сообщить о баге / Report an issue](https://github.com/Simplepres/MobAtlas/issues)

## Что нового в 0.7.17

- **Меньше памяти.** Одинаковые записи базы хранятся один раз. Поисковый индекс строится по необходимости и освобождается после закрытия атласа.
- **Улучшения по слотам.** «Для меня» показывает улучшения и вещи для пустых слотов. У проверенных вещей есть место в рейтинге слота.
- **Сравнение по спекам.** Открой предмет и наведи на «Оценки по спекам», чтобы увидеть баллы и разницу с надетым для веток своего класса.

## What’s new in 0.7.17

- **Lower memory use.** Identical database records are shared. The search index is built on demand and released after the atlas closes.
- **Slot rankings.** Gear for me shows upgrades and gear for empty slots. Checked items are ranked within their slot.
- **Spec ratings.** Select an item and hover over Spec ratings to see its score and how it compares with your equipped gear for each specialization in your class.

[Как работает подбор экипировки / Gear discovery and comparison](docs/DEVELOPMENT-NOTES.ru.md#как-атлас-помогает-выбрать-экипировку)

## Установка / Install

Распакуй **MobAtlas-0.7.17.zip** в `Interface/AddOns/` клиента Forever и полностью перезапусти WoW. Открой атлас через книжку у миникарты или `/mobatlas`. ПКМ по книжке открывает настройки отслеживания.

Extract **MobAtlas-0.7.17.zip** into the Forever client’s `Interface/AddOns/` folder and restart WoW. Click the minimap book or type `/mobatlas`. Right-click the book for tracking settings.

## Скриншоты / Gallery

**Атлас экипировки / Gear atlas**

Рекомендации слева, карта источника справа. / Gear suggestions on the left, source map on the right.

![Gear recommendations and a source map](docs/images/atlas-gear.webp)

**Обнаружение редких мобов / Rare discovery**

Следопыт заметил Крыло скорби. Клик по уведомлению берёт моба в цель вне боя, если он ещё доступен, или открывает карту с известным местом появления.

MobAtlas spotted Sorrow Wing. Click the alert to target it out of combat if it is still available, or open its known spawn location on the map.

![Уведомление об обнаружении Крыла скорби / Sorrow Wing detection alert](docs/images/rare-alert.webp)

<details>
<summary>Ещё скриншоты / More screenshots</summary>

**Закреплённый редкий моб / Pinned rare**

Карточка добычи Sorrow Wing и его метка в Когтистых горах. / Sorrow Wing’s loot card and map marker in Stonetalon Mountains.

![Pinned Sorrow Wing and loot details](docs/images/pinned-rare.webp)

**Питомцы / Pets**

Где искать детёныша кроколиска в Штормграде. / Where to look for the crocolisk pet in Stormwind.

![Pet sources on the Stormwind map](docs/images/atlas-pets.webp)

**Перед данжем / Dungeon prep**

Задания и цепочки для Пещер Стенаний. / Wailing Caverns quests and prerequisites.

![Wailing Caverns quest preparation](docs/images/dungeon-quests.webp)

**Добыча при наведении / Loot on hover**

Известные предметы прямо в подсказке моба. / Known drops in the creature tooltip.

![Creature tooltip with possible loot](docs/images/creature-hover.webp)

</details>

Метки показывают известные места появления. Обнаружение живых мобов зависит от данных клиента. Проценты Classic подписаны отдельно, а неизвестные шансы и цены отмечены в интерфейсе.

Spawn markers show known locations. Live detection depends on what the game client exposes. Classic rates are labeled and unknown prices or chances are marked in the UI.

[Источники и авторы / Data and credits](docs/DATA-AND-CREDITS.md) · [Лицензии / Licenses](LICENSE.md) · [Telegram @brunotwin](https://t.me/brunotwin) · [Threads @teur_person](https://www.threads.com/@teur_person)
