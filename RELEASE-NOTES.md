# MobAtlas 0.7.3 — Beta

Fixed lingering habitat highlights after closing a loot preview. Temporary previews are cleared on close; an existing pinned selection restores its own area. Unpin clears the highlight. Slightly brighter habitat glow.

Исправлена зависшая подсветка мест обитания после просмотра добычи. При закрытии временный просмотр очищается; если есть закреплённый объект, возвращается его область. После открепления подсветка исчезает. Свечение немного ярче.

Install / Установка: replace MobAtlas, then **/reload**. Lua regression checks cover closing previews with and without an existing pin, restoring the pinned area and clearing on unpin. Live-client visual verification remains necessary.
