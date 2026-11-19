local _,A=...
-- Source phrases stay intact; translation is confined to addon-owned UI text.
local en={
 ["Спек: откл."]="Spec: off",
 ["Спек: авто"]="Spec: auto",
 ["Источники вещи"]="Item sources",
 ["‹ К вещам"]="‹ Items",
 ["Источники"]="Sources",
 ["Недавние"]="Recent",
 ["Мир"]="World",
 ["Данжи"]="Dungeons",
 ["Экипировка моего класса"]="Gear for my class",
 ["Без учёта спека"]="Ignore spec",
 ["Авто: мои таланты"]="Auto: my talents",
 ["Спек отключён. Выбери авто или свою ветку талантов."]="Spec filtering is off. Choose auto or your talent tree.",
 ["Таланты ещё не выбраны. Укажи спек вручную."]="No talent tree detected. Choose your spec manually.",
 ["Выбран спек: "]="Selected spec: ",
 ["Подбор по классу, оружию и известным характеристикам."]="Filters by class, weapon type and known stats.",

 ["Спек: откл."]="Spec: off",["Спек: авто"]="Spec: auto",["Экипировка моего класса"]="Gear for my class",
 ["Источники вещи"]="Item sources",["‹ К вещам"]="‹ Items",["Источники"]="Sources",["Мир"]="World",["Данжи"]="Dungeons",["Недавние"]="Recent",
 ["Спек отключён. Выбери авто или свою ветку талантов."]="Spec is off. Choose auto or your talent tree.",
 ["Выбран спек: "]="Selected spec: ",["Авто: "]="Auto: ",
 ["Таланты ещё не выбраны. Укажи спек вручную."]="No talent tree detected. Choose a spec manually.",
 ["Подбор по классу, оружию и известным характеристикам."]="Filters by class, weapon and known stats.",
 ["Без учёта спека"]="Spec off",["Авто: мои таланты"]="Auto: my talents",
 ["Ликвидация"]="Assassination",["Скрытность"]="Subtlety",["Бой"]="Combat",

 ["Неизвестное"]="Unknown",
 ["Серое"]="Poor",
 ["Белое"]="Common",
 ["Зелёное"]="Uncommon",
 ["Синее"]="Rare",
 ["Фиолетовое"]="Epic",
 ["Легендарное"]="Legendary",
 ["Артефакт"]="Artifact",
 ["Наследуемое"]="Heirloom",
 ["Следопыт"]="MobAtlas",
 ["Точки на карте"]="Map markers",
 ["Добыча на мобах"]="Creature loot tooltips",
 ["Качество"]="Quality",
 ["Все"]="All",
 ["Снять все"]="Clear all",
 ["Материалы"]="Materials",
 ["Любая добыча"]="Any loot",
 ["Все материалы"]="All materials",
 ["Мои профессии"]="My professions",
 ["Портняжное дело"]="Tailoring",
 ["Кожевничество"]="Leatherworking",
 ["Алхимия"]="Alchemy",
 ["Кузнечное дело"]="Blacksmithing",
 ["Инженерия"]="Engineering",
 ["Инженерное дело"]="Engineering",
 ["Наложение чар"]="Enchanting",
 ["Кулинария"]="Cooking",
 ["Первая помощь"]="First Aid",
 ["Экипировка только моего класса"]="Equipment for my class only",
 ["Дополнительно"]="Advanced",
 ["К карте"]="Open map",
 ["Вещей в карточке"]="Items per card",
 ["Снятие шкур"]="Skinning",
 ["Карманная кража"]="Pickpocketing",
 ["Наблюдения Forever"]="Forever observations",
 ["Общий / условный дроп"]="Shared / conditional drops",
 ["Покупки: мой уровень и ниже"]="Purchases: my level or below",
 ["Торговцы: полезное моему персонажу"]="Vendors: useful to my character",
 ["Карта: "]="Map: ",
 ["мобы и торговцы"]="creatures and vendors",
 ["только мобы"]="creatures only",
 ["только торговцы"]="vendors only",
 ["Все качества"]="All qualities",
 ["Ничего не выбрано"]="Nothing selected",
 ["Выбрано качеств: "]="Qualities selected: ",
 ["Порядок: особенное в начале"]="Order: special loot first",
 ["Порядок: чаще выпадает"]="Order: drop frequency",
 ["Порядок: редкость вещи"]="Order: item rarity",
 ["Низкое"]="Poor",
 ["Обычное"]="Common",
 ["Необычное"]="Uncommon",
 ["Редкое"]="Rare",
 ["Эпическое"]="Epic",
 ["Открепить"]="Unpin",
 ["Нажми: посмотреть предметы"]="Click to inspect items",
 ["Другой моб в этой точке"]="Another creature at this location",
 ["Вход: "]="Entrance: ",
 ["Торговец · экипировка, сумки, ремесло"]="Vendor · gear, bags, crafting",
 ["Ур. "]="Lv. ",
 ["У продавца"]="Sold by vendor",
 ["Шанс не измерен"]="Chance not measured",
 [" · шкуры"]=" · skinning",
 [" · кража"]=" · pickpocketing",
 ["К торговцам"]="Back to vendors",
 ["К группе мобов"]="Back to creatures",
 ["MobAtlas · Следопыт"]="MobAtlas",
 ["ЛКМ: атлас · ПКМ: отслеживание"]="Left-click: atlas · Right-click: tracking",
 ["Перетащи: переместить кнопку"]="Drag to move the button",
 ["Следопыт · в продаже"]="MobAtlas · vendor stock",
 ["Следопыт · возможная добыча"]="MobAtlas · possible loot",
 ["Нет вещей по текущим фильтрам"]="No items match the current filters",
 ["Everloot · CC BY-SA 4.0; Classic — справка"]="Everloot · CC BY-SA 4.0; Classic reference",
 ["Следопыт · атлас"]="MobAtlas · atlas",
 ["Снять выделение"]="Clear selection",
 ["Метки выключены"]="Markers disabled",
 ["Выбрано: "]="Selected: ",
 [" · нет точек на этой карте"]=" · no locations on this map",
 ["Групп: "]="Groups: ",
 [" · QuestieDB · выбранная зона"]=" · QuestieDB · selected zone",
 ["Нет добычи по фильтрам — измените настройки"]="No matching loot — adjust your filters",
 ["Для этой карты пока нет подходящих точек"]="No matching locations on this map yet",
 ["Другие записи (проценты не складываются):"]="Other records (percentages are not added):",
 ["vMaNGOS Classic через wow-forever-kb; требует проверки на Forever."]="vMaNGOS Classic via wow-forever-kb; unverified on Forever.",
 ["Предмет был в окне добычи этого NPC на этом клиенте."]="Item seen in this NPC's loot window on this client.",
 ["Способ получения не определён; шанс не рассчитывается."]="Loot method unknown; no chance calculated.",
 ["Связь из справочника Forever; частота не измерена."]="Forever reference source; frequency not measured.",
 ["Общий или условный дроп; может зависеть от условий."]="Shared or conditional drop; requirements may apply.",
 ["Особенное: категория / редкость, затем известный шанс."]="Special loot: category / rarity, then known chance.",
 ["№1 — первое в категории этой карточки, не BiS."]="#1 in this card's category, not a BiS rating.",
 ["Цена и наличие на момент последнего визита."]="Price and stock at the last visit.",
 [" выпадений / "]=" drops / ",
 [" окон · "]=" loot windows · ",
 [" источников"]=" sources",
 ["Зверь"]="Beast",
 ["Гуманоид"]="Humanoid",
 ["Нежить"]="Undead",
 ["Демон"]="Demon",
 ["Дракон"]="Dragonkin",
 ["Элементаль"]="Elemental",
 ["Механизм"]="Mechanical",
 ["Великан"]="Giant",
 ["Животное"]="Critter",
 ["Существо"]="Creature",
 ["Следопыт · атлас добычи"]="MobAtlas · loot atlas",
 ["Название / ID · Shift-клик по вещи при вводе"]="Name / ID · Shift-click an item while typing",
 ["Снять выбор"]="Clear selection",
 ["Мой уровень"]="My level",
 ["Известен источник"]="Known source",
 ["Все предметы"]="All items",
 ["Полезное мне сейчас"]="Useful to me now",
 ["Экипировка"]="Equipment",
 ["Сумки"]="Bags",
 ["Материалы профессий"]="Profession materials",
 ["Рецепты"]="Recipes",
 ["Расходники"]="Consumables",
 ["Питомцы"]="Pets",
 ["Редкие вещи"]="Rare items",
 ["Эпические вещи"]="Epic items",
 ["Все источники"]="All sources",
 ["Открытый мир"]="Open world",
 ["Данжи и рейды"]="Dungeons and raids",
 ["Недавно выбраны"]="Recently selected",
 ["Сброс"]="Reset",
 ["Карта"]="Map",
 ["Клик: вход в подземелье. Позиция босса неизвестна."]="Click: dungeon entrance. Boss position unknown.",
 ["Клик: оставить на карте только этот источник."]="Click: show only this source on the map.",
 ["Координат пока нет."]="Coordinates not available yet.",
 ["Перед данжем"]="Dungeon prep",
 ["Настройки"]="Settings",
 ["Все источники на карте"]="All sources on map",
 ["‹ К результатам"]="‹ Back to results",
 ["Выбери источник, чтобы выделить его на карте."]="Choose a source to highlight it on the map.",
 ["Недавно выбраны: "]="Recently selected: ",
 ["Найдено: "]="Found: ",
 [" ур."]=" lvl",
 ["Квест · "]="Quest · ",
 ["Крафт · "]="Crafting · ",
 ["Объект · "]="Object · ",
 ["Внутри · "]="Inside · ",
 ["Качество неизвестно"]="Unknown quality",
 [" · с "]=" · requires level ",
 [" · источников: "]=" · sources: ",
 ["Ничего не найдено. Попробуй часть названия, другой раздел или ID."]="Nothing found. Try part of the name, another category or an ID.",
 ["Клик по источнику → карта. «Снять выделение» вернёт остальных."]="Click a source → map. Clear selection to restore the overview.",
 ["«Карта» → источники · «Перед данжем» → задания"]="Map → sources · Dungeon prep → quests",
 ["Перед походом в данж"]="Before your dungeon run",
 ["Атлас вещей"]="Item atlas",
 ["Следующий шаг: "]="Next step: ",
 ["Взять у: "]="Pick up from: ",
 ["Награда: "]="Reward: ",
 ["Справочник: наличие задания проверяется у NPC."]="Reference data: check quest availability with the NPC.",
 ["‹ Другой данж"]="‹ Other dungeon",
 ["Все уровни моей фракции"]="All levels for my faction",
 ["Мой уровень и ближайшие · "]="My level and nearby · ",
 ["Задания, цепочки и подготовка · без выполненных квестов"]="Quests, chains and preparation · completed quests hidden",
 ["Выбери подземелье"]="Choose a dungeon",
 ["Будущие задания видны заранее; карта доступна по условиям."]="Future quests shown ahead; map availability depends on requirements.",
 ["Небольшой список подходящих походов и заданий."]="A short list of relevant dungeons and quests.",
 ["Сначала цепочка: "]="Prerequisite chain: ",
 ["Взято"]="Accepted",
 ["С "]="From ",
 ["Вход"]="Entrance",
 ["Начать"]="Start",
 ["Задание уже в журнале. Подробности — в журнале заданий."]="Quest already accepted. Check your quest log for details.",
 ["Сейчас: "]="Now: ",
 [" · всего: "]=" · total: ",
 [" · позже: "]=" · later: ",
 ["Открыть"]="Open",
 ["Пока нет заданий по этим условиям. Попробуй все уровни."]="No matching quests yet. Try all levels.",
 ["Справочные условия могут отличаться на текущем патче."]="Reference requirements may differ on the current patch.",
 ["Данные предмета: AHledger (ahledger.com)"]="Item metadata: AHledger (ahledger.com)",
 ["Характеристики из Classic — проверь tooltip в игре."]="Classic stats — check the in-game tooltip.",
 ["Отслеживание"]="Tracking",
 ["Мобы"]="Creatures",
 ["Продавцы"]="Vendors",
 ["Добыча при наведении"]="Loot on hover",
 ["Все настройки"]="All settings",
 ["Добыча"]="Loot",
 ["Forever · способ не разделён"]="Forever · method not separated",
 ["Продажа · справочник QuestieDB"]="Vendor · QuestieDB reference",
 ["Продажа · личное наблюдение"]="Vendor · personal observation",
 ["Добыча · справочник Forever"]="Loot · Forever reference",
 ["Личная находка · способ не определён"]="Personal find · method unknown",
 ["Classic · vMaNGOS через KB"]="Classic · vMaNGOS via KB",
 ["Награда за задание"]="Quest reward",
 ["Изготовление"]="Crafting",
 ["Сундук / объект · Classic"]="Chest / object · Classic",
 ["Содержимое предмета"]="Container contents",
 ["Внутри другого предмета"]="Inside another item",
 ["Шанс неизвестен · Classic"]="Unknown chance · Classic",
 ["Лично найдено · шанс неизвестен"]="Personally found · unknown chance",
 ["шанс неизвестен · Forever DB"]="unknown chance · Forever DB",
 ["Покупка · справочник"]="Purchase · reference",
 ["Особая стоимость · у продавца"]="Special cost · check vendor",
 ["Цена уточняется"]="Price pending",
 ["%dз %dс %dм"]="%dg %ds %dc",
 [" шт."]=" items",
 ["шанс неизвестен"]="unknown chance",
 ["Предмет #"]="Item #",
 ["Существо #"]="Creature #",
 ["Торговец #"]="Vendor #",
 ["Питомец"]="Pet",
 ["Карта #"]="Map #",
 ["Место пока неизвестно"]="Location not known yet",
 ["Карту можно открыть после боя."]="The map can be opened after combat.",
 ["Источник известен, но координат пока нет."]="Source known, coordinates not available yet.",
 ["Источник не найден."]="Source not found.",
 ["Источник известен, координаты пока нет. Открой список источников."]="Source known, coordinates unavailable. Open the source list.",
 ["Предмет есть в каталоге, источник пока неизвестен."]="Item in catalog; source not known yet.",
 ["Карта сейчас недоступна."]="Map currently unavailable.",
 ["Не удалось загрузить карту."]="Could not load the map.",
 ["Карта не открылась. Открой её клавишей M и повтори."]="Map did not open. Press M and try again.",
 ["Не удалось выбрать карту."]="Could not select the map.",
 ["Задание #"]="Quest #",
 ["Условия пока неизвестны"]="Requirements not known yet",
 ["Выполнено"]="Completed",
 ["Уже в журнале"]="Already in quest log",
 ["Другая фракция, раса или класс"]="Different faction, race or class",
 ["Доступно с "]="Available from level ",
 ["Выше предельного уровня"]="Above the maximum level",
 ["Сначала: "]="First: ",
 ["Нужна предыдущая часть цепочки"]="Previous chain step required",
 ["Берётся внутри подземелья"]="Picked up inside the dungeon",
 ["Минимальный уровень не подтверждён — проверь у NPC"]="Minimum level unconfirmed — check with the NPC",
 ["Особые условия — проверь у NPC"]="Special requirements — check with the NPC",
 ["Начинается с предмета"]="Starts from an item",
 ["Место начала неизвестно"]="Starting location unknown",
 ["Можно проверить у NPC"]="Check availability with the NPC",
 ["Координаты пока неизвестны."]="Coordinates not known yet.",
 ["Задание пока не добавлено."]="Quest not added yet.",
 ["Задание уже в журнале — повторно брать его не нужно."]="Quest already accepted — no need to pick it up again.",
 ["Задание берётся внутри"]="Quest picked up inside",
 ["Начинается с предмета #"]="Starts from item #",
 [". Найди его в атласе."]=". Find it in the atlas.",
 ["У квестодателя пока нет известных координат."]="Quest giver coordinates are not known yet.",
 ["Взять: "]="Pick up: ",
 ["Мало места: "]="Low bag space: ",
 [" свободных ячеек — пригодится сумка."]=" free slots — consider getting a bag.",
 ["Сумки: "]="Bags: ",
 [" свободных ячеек."]=" free slots.",
 ["Перед выходом почини экипировку."]="Repair your equipment before leaving.",
 ["Экипировка: ремонт пока не срочный."]="Equipment: repairs are not urgent.",
 ["Перед выходом: проверь место в сумках и ремонт."]="Before leaving: check bag space and repairs.",
 ["Тюрьма (Штормград)"]="The Stockade (Stormwind)",
 ["Мёртвые копи"]="The Deadmines",
 ["Пещеры Стенаний"]="Wailing Caverns",
 ["Огненная Пропасть"]="Ragefire Chasm",
 ["Крепость Тёмного Клыка"]="Shadowfang Keep",
 ["Непроглядная Пучина"]="Blackfathom Deeps",
 ["Лабиринты Иглошкурых"]="Razorfen Kraul",
 ["Курганы Иглошкурых"]="Razorfen Downs",
 ["Гномреган"]="Gnomeregan",
 ["Монастырь Алого ордена"]="Scarlet Monastery",
 ["Ульдаман"]="Uldaman",
 ["Зул'Фаррак"]="Zul'Farrak",
 ["Затонувший храм"]="Sunken Temple",
 ["Глубины Чёрной горы"]="Blackrock Depths",
 ["Пик Чёрной горы"]="Blackrock Spire",
 ["Стратхольм"]="Stratholme",
 ["Некроситет"]="Scholomance",
 ["Мародон"]="Maraudon",
 ["Забытый Город"]="Dire Maul",
 ["Подземелье #"]="Dungeon #",
 ["Закрепить группу"]="Pin group",
 ["Закрепить"]="Pin",
 ["Торговцы рядом"]="Nearby vendors",
 ["Группа мобов"]="Creature group",
 [" · вход"]=" · entrance",
 ["Стальгорн"]="Ironforge",
 ["Точки: QuestieDB Forever, справочник.\nForever: окна добычи, способ не разделён.\nДанные Everloot · CC BY-SA 4.0 · everloot.app"]="Locations: QuestieDB Forever reference.\nForever: loot windows, method not separated.\nEverloot data · CC BY-SA 4.0 · everloot.app",
}
en['Язык интерфейса']='Interface language'
en['Авто: по языку WoW. Другие языки используют English.']='Auto: follow WoW language. Other languages fall back to English.'
en['Найди Dark Iron Map у Dark Iron Spy или Captain Beld в Дун Мороге; используй предмет и отнеси Фарсену.']='Find Dark Iron Map from Dark Iron Spy or Captain Beld in Dun Morogh; use it and bring it to Farsen.'
en['После Underground Map — Earthseer Farsen, Дун Морог.']='After Underground Map — Earthseer Farsen, Dun Morogh.'
en['Afadra Dunwall — Старый Стальгорн, перед входом.']='Afadra Dunwall — Old Ironforge, before the entrance.'
en['Thom Filch — Старый Стальгорн, перед входом.']='Thom Filch — Old Ironforge, before the entrance.'
en['Ghostly Attendant внутри подземелья, перед первым боссом. На карте показан только вход.']='Ghostly Attendant inside the dungeon, before the first boss. Only the entrance is marked.'
en['Возьми Treaty of Understanding в хранилище последнего зала и используй предмет. На карте показан только вход.']='Take Treaty of Understanding from a vault in the last room and use it. Only the entrance is marked.'
en['В бою открой карту клавишей M и повтори.']='In combat, open the map with M and try again.'
en['В бою выбери нужную зону на карте вручную.']='In combat, choose the required map zone manually.'
en['Подземелья и задания']='Dungeons and quests'
en['Нет заданий для взятия на твоём уровне.']='No quests to pick up at your level.'
en['Ещё заданий: ']='More quests: '
en['Нажми значок заданий, чтобы выбрать квест.']='Click the quest icon to choose a quest.'
en['MobAtlas · задания перед данжем']='MobAtlas · dungeon quests'
en['Подземелья и задания']='Dungeons and quests'
en['Нет заданий для взятия на твоём уровне.']='No quests to pick up at your level.'
en['Ещё заданий: ']='More quests: '
en['Нажми значок заданий, чтобы выбрать квест.']='Click the quest marker to choose a quest.'
en['MobAtlas · задания перед данжем']='MobAtlas · dungeon quests'
en['Нажми метку, чтобы открепить.']='Click the marker to unpin.'
en['MobAtlas · задания перед данжем']='MobAtlas · dungeon quests'
en['Нет заданий для взятия на твоём уровне.']='No quests to pick up at your level.'
en['Ещё заданий: ']='More quests: '
en['Нажми значок заданий, чтобы выбрать квест.']='Click the quest icon to choose a quest.'
en['Нажми метку, чтобы открепить.']='Click the marker to unpin.'
en['только подземелья']='dungeons only'
en['Редкие мобы…']='Rare creatures…'
en['Редкие мобы']='Rare creatures'
en['Редкий моб обнаружен']='Rare creature detected'
en['Моб замечен: координаты из клиента.']='Creature detected: position provided by the client.'
en['Замечен рядом; точка — место появления из базы.']='Detected nearby; marker is a reference spawn location.'
en['Возможное место появления. Наличие не подтверждено.']='Possible spawn location. Presence not confirmed.'
en['Нажми: добыча и область появления.']='Click for loot and spawn area.'
en['Нажми, чтобы открыть карту']='Click to open the map'
en['Отслеживать редких мобов']='Track rare creatures'
en['Показывать уведомления']='Show alerts'
en['Звук при обнаружении']='Detection sound'
en['Метки на миникарте']='Minimap markers'
en['Метки на карте']='World map markers'
en['Дальность имён до 80']='Nameplate distance up to 80'
en['Мягкая подсветка области']='Soft spawn-area shading'
en['Дальность ограничена клиентом. Место из базы — не подтверждение живого моба.']='Range is limited by the client. Reference locations do not confirm a live creature.'
en['Моб замечен, но его координаты недоступны.']='Creature detected, but its position is unavailable.'
en['За краем миникарты: показано направление.']='Outside the minimap view: showing direction.'
en['Forever · сообщение игрока']='Forever · player report'
en['Сообщение игрока · шанс неизвестен']='Player report · unknown chance'
en['Связь добавлена по сообщению игрока. Шанс и частота не измерены.']='Added from a player report. Chance and frequency have not been measured.'
en['Добыча пока неизвестна. Находки будут сохраняться.']='Loot not known yet. Your finds will be recorded.'
en['Показано: ']='Showing: '
en[' из ']=' of '
en[' · остальное в карточке на карте.']=' · more in the map card.'
en['Добыча пока неизвестна.']='Loot not known yet.'
local keys={};for key in pairs(en) do keys[#keys+1]=key end
table.sort(keys,function(a,b) return #a>#b end)
function A:GetLanguage()
 local mode=self.db and self.db.language or 'auto'
 if mode=='ruRU' or mode=='enUS' then return mode end
 return type(GetLocale)=='function' and GetLocale()=='ruRU' and 'ruRU' or 'enUS'
end
function A:L(text)
 if type(text)~='string' or self:GetLanguage()=='ruRU' or not (text:find('\208',1,true) or text:find('\209',1,true)) then return text end
 local direct=en[text];if direct then return direct end
 self.translationCache=self.translationCache or {}
 if self.translationCache[text] then return self.translationCache[text] end
 -- Replace only source fragments in a single pass, so translated output is never reprocessed.
 local out={};local pos=1
 while pos<=#text do
  local start,finish,replacement
  for _,key in ipairs(keys) do
   local a,b=text:find(key,pos,true)
   if a and (not start or a<start) then start,finish,replacement=a,b,en[key] end
  end
  if not start then out[#out+1]=text:sub(pos);break end
  out[#out+1]=text:sub(pos,start-1);out[#out+1]=replacement;pos=finish+1
 end
 local value=table.concat(out)
 self.translationCacheCount=(self.translationCacheCount or 0)+1
 if self.translationCacheCount>512 then self.translationCache={};self.translationCacheCount=1 end
 self.translationCache[text]=value;return value
end
function A:LocalizeWidget(widget)
 self.localizedWidgets=self.localizedWidgets or setmetatable({},{__mode='k'})
 if self.localizedWidgets[widget] then return widget end
 local original=widget.SetText
 self.localizedWidgets[widget]={set=original,text=''}
 widget.SetText=function(node,text)
  local record=self.localizedWidgets[node];record.text=text
  return original(node,self:L(text))
 end
 return widget
end
function A:SetLanguage(mode)
 if mode~='auto' and mode~='ruRU' and mode~='enUS' then return false end
 self.db.language=mode
 for widget,record in pairs(self.localizedWidgets or {}) do record.set(widget,self:L(record.text)) end
 if self.atlas then
  self.atlas.results=nil
  self.atlas.languageButton:SetText(mode=='auto' and 'Auto ▾' or mode=='ruRU' and 'RU ▾' or 'EN ▾')
  if self.atlas:IsShown() then self:RefreshAtlas() end
 end
 if self.prep and self.prep:IsShown() then self:RefreshPreparation() end
 self:RefreshSettings();self:Invalidate()
 return true
end
