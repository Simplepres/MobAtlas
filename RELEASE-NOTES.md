# MobAtlas 0.7.2 — Beta

New original map icons for mobs, vendors, dungeons and rares: compact silhouettes, dark backgrounds and restrained gold/silver rims.

Fixed rare minimap markers jumping between reference spawns. Each reference stays anchored to a fixed catalog point and keeps its own frame; projection updates smoothly while moving or rotating. Confirmed live positions remain distinct. The frame pool is bounded and no atlas rebuild occurs during projection.

## На русском

Обновлены метки мобов, торговцев, подземелий и редких существ. Тёмная основа, понятные силуэты и аккуратный ободок лучше сочетаются с картой WoW.

Исправлены скачки редких меток между местами появления. Справочные точки закреплены за координатами; движение и вращение миникарты обрабатываются плавнее. Подтверждённая позиция живого моба отмечается отдельно.

Install / Установка: replace MobAtlas, then **/reload**. Tested with Lua mock regressions; live-client visual verification is still needed.

Feedback: [Telegram @brunotwin](https://t.me/brunotwin) · [Threads @teur_person](https://www.threads.com/@teur_person).
