from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();MOCK.playerLevel=25;A.db.specOnly=true;A.db.classOnly=true;A.db.gearSpec=3;A:RefreshGearProfile()
A.itemSources={};A.searchTerms={};A.mappableItems={};A.accessibleAtlasSources={}
A.mobs[999800]={name='Test mob',min=24,max=25,points={{1429,30,40}},loot={}}
A.mobs[999801]={name='Enemy vendor',vendor=true,friendly='H',points={{1429,40,40}},stock={}}
local function add(id,agi,quality,level,cls,sub,loc,npc,method)
 A.items[id]={name='Candidate '..id,classID=cls or 4,subclass=sub or 2,slot=loc or 'Chest',quality=quality,level=level,prof={}}
 MOCK.items[id]={name='Candidate '..id,class=cls or 4,subclass=sub or 2,loc=loc or 'INVTYPE_CHEST',quality=quality,level=level,stats={ITEM_MOD_AGILITY_SHORT=agi}}
 local e={id,method or 1,10,false};A.mobs[npc or 999800].loot=A.mobs[npc or 999800].loot or {};A:IndexLootEntry(npc or 999800,e)
end
add(999901,9,2,25);add(999902,1,2,25);add(999903,50,0,25);add(999904,50,2,30);add(999905,7,2,25);MOCK.items[999905]=nil;A.atlasLoadFailures={[999905]=true}
add(999906,0,2,25);MOCK.items[999906].stats={ITEM_MOD_INTELLECT_SHORT=15}
add(999907,10,2,25,2,19,'INVTYPE_RANGEDRIGHT');add(999908,10,2,25,4,2,'INVTYPE_CHEST',999801,5)
add(999909,0,2,25);MOCK.items[999909].stats={}
MOCK.items[999900]={name='Worn',class=4,subclass=2,loc='INVTYPE_CHEST',quality=2,level=20,stats={ITEM_MOD_AGILITY_SHORT=5}}
MOCK.equipped[5]=999900;function GetInventoryItemLink(_,slot) local id=MOCK.equipped[slot];return id and 'item:'..id end
C_Item.GetItemInfo=function(id) if type(id)=='string' then id=tonumber(id:match('item:(%d+)')) end;local d=MOCK.items[id];if not d then return end;return d.name,'item:'..id,d.quality,30,d.level,'Armor','Leather',1,d.loc,134400,1,d.class,d.subclass end
A:OpenAtlas();for i=1,4 do A:RefreshAtlas() end
assert(#A.atlas.rows==8,'eight item rows')
assert(A.atlas.category=='gear' and #A.atlas.results>0,'personal mode defaults on')
local visible={};for _,row in ipairs(A.atlas.rows) do if row:IsShown() then visible[row.itemID]=true end end
assert(visible[999901],'confirmed upgrade visible')
for _,id in ipairs({999902,999903,999904,999905,999906,999907,999908,999909}) do assert(not visible[id],'exclude bad candidate '..id) end
A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999901,true);A:RefreshAtlas();local retained=false;for _,row in ipairs(A.atlas.rows) do if row:IsShown() and row.itemID==999901 then retained=true end end;assert(retained,'loading another item never clears confirmed recommendations')
C_TooltipInfo={GetHyperlink=function() return {lines={{leftText='Requires Test Faction - Exalted',leftColor={r=1,g=0,b=0}}}} end};A.atlasRequirementCache=nil;A:RefreshAtlas();local blocked=true;for _,row in ipairs(A.atlas.rows) do if row:IsShown() and row.itemID==999901 then blocked=false end end;assert(blocked,'red client reputation requirement blocks recommendation');C_TooltipInfo=nil;A.atlasRequirementCache=nil
assert(A.atlas.recommendScan.limit<=128,'bounded validation batch')
local description=A:AtlasSourceDescription({entry={999901,6,-1,false,12345,2,-1,false},location={mapID=1429}})
assert(description:find('Купить за') and description:find('1з 23с 45м'),'observed buy price rendered')
assert(A:AtlasSourceDescription({entry={999901,5,-1},location={mapID=1429}}):find('неизвестна'),'reference vendor never invents a price')
assert(A:AtlasSourceDescription({entry={999901,1,12.5},location={mapID=1429}}):find('12.5',1,true),'drop rate rendered')
-- Catalog material filtering works across classes and includes useful low-level gear.
MOCK.class='PRIEST';A:RefreshGearProfile()
A.items[999901].subclass=1;A.items[999901].level=8
MOCK.items[999901].subclass=1;MOCK.items[999901].level=8;MOCK.items[999901].stats={ITEM_MOD_SPELL_HEALING_DONE_SHORT=20}
A.comparisonInfo=nil;A.comparisonStats=nil;A.gearStatCache=nil
A.items[999902].subclass=4
local cloth=A:FindItems('999901','catalog','all',nil,{gearType='cloth',level=true})
assert(A:FindItems('999901','gear','all',nil,{gearType='cloth',level=true})[1]==999901,'cloth recommendation survives the old level band')
assert(cloth[1]==999901,'old level band must not hide cloth in catalog')
assert(A:FindItems('999902','catalog','all',nil,{gearType='plate',level=true})[1]==999902,'plate catalog browsable on priest')
assert(#A:FindItems('999902','catalog','all',nil,{gearType='cloth'})==0,'cloth excludes plate')
assert(#A:FindItems('999902','gear','all',nil,{gearType='plate'})==0,'recommendations still require wearable armor')
MOCK.items[999901].stats={ITEM_MOD_SPELL_HEALING_DONE_SHORT=20}
MOCK.items[999900].stats={ITEM_MOD_INTELLECT_SHORT=3}
A.comparisonStats=nil;A.gearStatCache=nil
assert(A:CompareItem(999901).state=='better','classic healing bonus counts for priest')
print('PASS personal recommendations: client-confirmed upgrade, weaker/grey/future/unavailable/caster/wand/enemy-vendor rejection, eight rows, bounded work, actual buy price and drop rate')
''')
