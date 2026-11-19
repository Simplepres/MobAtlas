from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');ns=l.table();load=l.eval('function(s,n,ns) assert(loadstring(s,n))("MobAtlas",ns) end')
for name in ['Data.lua','ClassGear.lua','Forever.lua','Catalog.lua','Expansion.lua','Preparation.lua','Observations.lua','Atlas.lua','Core.lua','Presentation.lua','Locale.lua','UI.lua']:load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas;A:Init();MOCK.playerLevel=18
local n=0;for _ in pairs(A.items) do n=n+1 end;assert(n>28000,'broad catalog integrated')
assert(#A:FindItems('','all','all')==n,'catalog-only items are searchable')
local ids=A:DungeonQuestList(1581,false);assert(#ids==5,'Deadmines short list excludes generic cloth donations/food errands')
local expected={[166]=true,[167]=true,[168]=true,[214]=true,[2040]=true}
for _,q in ipairs(ids) do assert(expected[q.id]);assert(type(A:QuestName(q.id))=='string') end
assert(A:QuestState(167)=='ready');assert(A:QuestState(166)=='chain' and A:FirstQuestStep(166)==65)
MOCK.done[65]=true;assert(A:FirstQuestStep(166)~=65,'completed prerequisite advances chain');MOCK.done[65]=nil
MOCK.done[167]=true;assert(#A:DungeonQuestList(1581,false)==4);MOCK.done[167]=nil
MOCK.faction='Horde';assert(#A:DungeonQuestList(1581,false)==0,'wrong faction quests excluded');MOCK.faction='Alliance'
MOCK.playerLevel=11;assert(#A:DungeonQuestList(1581,false)==0,'future quests are not suggested early');MOCK.playerLevel=18
A.dungeonQuests[999991]={name='Test class',min=1,level=18,classMask=1,raceMask=0,dungeons={1581},preAny={},preAll={},givers={}}
assert(A:QuestState(999991)=='restricted','class requirements respected');A.dungeonQuests[999991]=nil
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);canvas:SetScale(.625);local mapID=1429
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return mapID end
function WorldMapFrame:SetMapID(id) mapID=id end
function OpenWorldMap() WorldMapFrame:Show() end
A:OpenAtlas('5191');assert(A.atlas.prepButton);A.atlas.prepButton.scripts.OnClick();assert(A.prep:IsShown() and not A.atlas:IsShown());A.prep.area=1581;A:RefreshPreparation();assert(#A.prep.rows==5)
assert(A.prep.rows[1].questID and A.prep.rows[1].title:GetText():find('Сбор',1,true))
local ok=A:ShowQuestOnMap(167);assert(ok and mapID==1453 and A.focus.questID==167)
local pin=A.habitatPins[1];assert(pin:IsShown() and math.abs(pin.point[4]*pin.scale-canvas:GetWidth()*pin.sourceX/100)<.001,'quest giver pin scale')
canvas:SetScale(2);A:Update();assert(A.focus.questID==167 and A.habitatPins[1]:IsShown(),'zoom preserves quest target')
A:QuestLogChanged();local fn=table.remove(MOCK.timers);fn();assert(A.focus.questID==167,'ordinary quest log updates do not clear navigation')
C_QuestLog.IsOnQuest=function(id) return id==167 end
A:QuestLogChanged();fn=table.remove(MOCK.timers);fn();assert(not A.focus,'accepting the quest clears completed pickup navigation')
C_QuestLog.IsOnQuest=nil
MOCK.combat=true;assert(A:ShowQuestOnMap(167),'quest location on open combat map');MOCK.combat=false
local a=A:ShowQuestOnMap(166);assert(a and A.focus.questID==65,'chain map goes to available first step')
-- Non-creature sources are distinct, with their own geometry and no fake drop percent.
A.otherSources[990010]={{kind='quest',id=167,name='Test reward',givers={{points={{1453,20,30}}}},zone='Stormwind',chance=-1}}
A.items[990010]={name='Test quest reward',quality=2,classID=4,subclass=2,level=18,prof={}}
A:BuildAtlasIndex();assert(A:FindItems('Test quest reward','all','world')[1]==990010)
local source=A:AtlasSources(990010,'all')[1];assert(source.entry[2]==10 and not source.npcID and source.location.kind=='quest')
assert(A:FocusAtlasSource(990010,source) and A.focus.questID==167)
A.otherSources[990011]={{kind='crafted',id=123,name='Test craft',zone='',chance=-1}}
A.items[990011]={name='Craft only',quality=2,classID=4,subclass=2,level=18,prof={}}
A:BuildAtlasIndex();assert(#A:AtlasSources(990011,'all')==1 and not A:ShowItemOnMap(990011),'craft without location never pins the player')
-- Useful means own class, level band and an actual known source.
assert(not A:UsefulItem(17),'developer/source-unknown equipment never a suggestion')
C_Container={GetContainerNumFreeSlots=function() return 0,0 end,GetContainerNumSlots=function() return 16 end}
function GetInventoryItemDurability(slot) if slot==1 then return 10,100 end end
local checks=A:PreparationChecks();assert(checks:find('Мало места',1,true) and checks:find('почини',1,true))
-- Stockade stays discoverable before most of its quests unlock.
MOCK.playerLevel=18;C_Map={GetBestMapForUnit=function() return 1453 end}
local choices=A:DungeonChoices(false);assert(choices[1].id==717 and choices[1].count==6 and choices[1].locked==5,'nearby Stockade with future quest counts')
assert(A:DungeonName(717):find('Штормград',1,true))
A:OpenPreparation();A.prep.area=717;A.prep.page=1;A:RefreshPreparation();assert(A.prep.heading:GetText():find('Тюрьма',1,true))
local locked=false;for _,row in ipairs(A.prep.rows) do if row.questID and A:QuestState(row.questID)=='level' then locked=true;assert(not row.action.enabled) end end
assert(locked,'locked quests visible, not falsely marked available')
MOCK.playerLevel=22;assert(#A:DungeonQuestList(717,false)==6,'quests unlock at required level')
-- Forever-only Hall of Thanes: five main quests, prerequisite, honest indoor markers.
MOCK.playerLevel=13;C_Map={GetBestMapForUnit=function() return 1455 end}
local hall=A:DungeonQuestList(16919,false);assert(#hall==5,'Hall of Thanes five known quests')
assert(A:DungeonChoices(false)[1].id==16919,'Hall discoverable near Ironforge at 13')
assert(A:FirstQuestStep(96393)==96391,'Underground Map prerequisite retained')
assert(A:ShowQuestOnMap(96394) and mapID==1455 and A.focus.kind=='quest','Afadra actual outdoor coordinates')
assert(A:ShowQuestOnMap(96395) and mapID==1455 and A.focus.kind=='entrance','inside giver maps entrance, not fabricated NPC')
assert(A.focus.label:find('внутри',1,true))
assert(A:ShowQuestOnMap(98423) and A.focus.kind=='entrance','vault item maps entrance')
assert(A:ShowQuestOnMap(96393) and A.focus.questID==96391,'prerequisite item drop sources navigable')
MOCK.done[96391]=true;assert(A:ShowQuestOnMap(96393) and mapID==1426,'completed map leads to Farsen');MOCK.done[96391]=nil
MOCK.faction='Horde';assert(#A:DungeonQuestList(16919,false)==2,'only two neutral Hall quests');MOCK.faction='Alliance'
local expectedDungeons={16919,16611,16732,16544,-10002,-10003,-10004,-10005,-10006}
for _,id in ipairs(expectedDungeons) do
 assert(A.instances[id] and A.instances[id].minLevel,'all nine Forever dungeons registered')
 local n=0;for qid,q in pairs(A.dungeonQuests) do for _,d in ipairs(q.dungeons) do if d==id then n=n+1 end end end
 assert(n>0,'known quest membership for '..A.instances[id].name)
end
-- Every original five-player dungeon must retain preparation records too.
for _,id in ipairs({2437,1581,718,717,209,719,721,491,796,722,1337,1176,2100,1477,1584,1583,2557,2057,2017}) do
 assert(A.instances[id] and #(A.instances[id].entrances or {})>0,'legacy dungeon entrance retained')
 local n=0;for _,q in pairs(A.dungeonQuests) do for _,d in ipairs(q.dungeons) do if d==id then n=n+1 end end end
 assert(n>0,'legacy dungeon quests retained: '..id)
end
print('PASS expansion/catalog-only search, dungeon short list, RU titles, faction/class/level, chains, completed/active quests, map markers/zoom, quest log stability, non-NPC sources and preparation checks')
''')
