from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();MOCK.playerLevel=25;A.db.specOnly=true;A.db.classOnly=true;A.db.gearSpec=3;A:RefreshGearProfile()
-- Reproduce the priest screenshot against shipped data with cold item metadata.
MOCK.class='PRIEST';MOCK.playerLevel=26;A.db.specOnly=false;A:RefreshGearProfile()
local heads=A:FindItems('','gear','all',nil,{slot='head',level=true})
local found={};for _,id in ipairs(heads) do found[id]=true end
assert(#heads>20 and found[253955] and found[253981],'both crafted circlets appear with no item cache')
assert(#A:FindItems('','gear','all',nil,{slot='wand',level=true})>10,'wands have their own slot')
local recipe
for _,row in ipairs(A:AtlasSources(253955,'all')) do if row.recipeID==253956 and row.npcID==256735 then recipe=row end end
assert(recipe and recipe.location.mapID==1433 and recipe.source.skill==125,'recipe offers mapped Redridge vendor and known required skill')
assert(A:HasAccessibleAtlasSource(253955,'all',true),'craft is browseable with map filter')
assert(A:HasAccessibleAtlasSource(253981,'all',false) and not A:HasAccessibleAtlasSource(253981,'all',true),'unmapped craft respects map checkbox')
local gear=A:FindItems('','gear','all',nil,{level=true});local slots={}
for i=1,8 do local slot=A:GearSlot(A.items[gear[i]]) or 'other';assert(not slots[slot],'first page is spread across slots');slots[slot]=true end
-- Check the shipped catalog across all Forever classes and representative leveling breakpoints.
local classIDs={WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11}
local originalClass=UnitClass
function UnitClass() return MOCK.class,MOCK.class,classIDs[MOCK.class] end
for class in pairs(classIDs) do
 MOCK.class=class
 for _,level in ipairs({10,26,60}) do
  MOCK.playerLevel=level
  A:RefreshGearProfile()
  local choices=A:FindItems('','gear','all',nil,{level=true,known=true})
  assert(#choices>0,class..' has no gear at level '..level)
  for i=1,math.min(#choices,12) do
   local id=choices[i];local item=A.items[id]
   assert(item.quality>0 and (item.level or 0)<=level and A:ClassFits(item,id,true,true),'unwearable catalog result')
   local available=false
   for _,source in ipairs(A:AtlasSources(id,'all')) do
    if source.location.mapID and not source.entry[4] and A:AtlasSourceAccessible(source) then available=true;break end
   end
   assert(available,class..' result lacks the source promised by the map filter: '..id)
  end
 end
end
UnitClass=originalClass
MOCK.class='ROGUE';MOCK.playerLevel=25;A.db.specOnly=true;A:RefreshGearProfile()
A.items={};A.otherSources={};A.itemSourceLinks={};A.searchTerms={};A.mappableItems={};A.accessibleAtlasSources={}
A.mobs[999800]={name='Test mob',min=24,max=25,points={{1429,30,40}},loot={}}
A.mobs[999801]={name='Enemy vendor',vendor=true,friendly='H',points={{1429,40,40}},stock={}}
A.mobs[999802]={name='Mob in an unmapped dungeon',points={},instances={999802},loot={}}
A.instances[999802]={name='Unmapped dungeon',entrances={}}
local function add(id,agi,quality,level,cls,sub,loc,npc,method)
 A.items[id]={name='Candidate '..id,classID=cls or 4,subclass=sub or 2,slot=loc or 'Chest',quality=quality,level=level,prof={}}
 MOCK.items[id]={name='Candidate '..id,class=cls or 4,subclass=sub or 2,loc=loc or 'INVTYPE_CHEST',quality=quality,level=level,stats={ITEM_MOD_AGILITY_SHORT=agi}}
 local e={id,method or 1,10,false};A.mobs[npc or 999800].loot=A.mobs[npc or 999800].loot or {};A:IndexLootEntry(npc or 999800,e)
end
add(999901,9,2,25);add(999902,1,2,25);add(999903,50,0,25);add(999904,50,2,30);add(999905,7,2,25);MOCK.items[999905]=nil;A.atlasLoadFailures={[999905]=true}
add(999906,0,2,25);MOCK.items[999906].stats={ITEM_MOD_INTELLECT_SHORT=15}
add(999907,10,2,25,2,19,'INVTYPE_RANGEDRIGHT');add(999908,10,2,25,4,2,'INVTYPE_CHEST',999801,5)
add(999910,12,2,25);add(999909,0,2,25);MOCK.items[999909].stats={}
add(999911,30,3,25,4,2,'INVTYPE_CHEST',999802)
add(999912,30,3,25)
A.itemSourceLinks[999912][2][4]=true
assert(A:HasAccessibleAtlasSource(999911,'all',false) and not A:HasAccessibleAtlasSource(999911,'all',true))
assert(not A:HasAccessibleAtlasSource(999911,'dungeons',true),'dungeon entry requires a real mapped entrance')
assert(not A:HasAccessibleAtlasSource(999912,'all',true),'shared-only source cannot qualify as an obtainable upgrade')
assert(A:FindItems('999912','catalog','all',nil,{known=true})[1]==999912,'catalog retains the reference entry')
local quest={kind='quest',id=999813}
assert(A:AtlasSourceAccessible({source=quest,entry={999911,10,-1}}))
MOCK.done[999813]=true
assert(not A:AtlasSourceAccessible({source=quest,entry={999911,10,-1}}),'completed outdoor quest cannot recommend its reward')
assert(not A:AtlasSourceAccessible({npcID=999800,entry={999911,6,-1,false,50,1,0}}),'sold-out vendor is excluded')

A.items[999902].ruName='Плащ проверки'
A.items[999910].ruName='Улучшенный плащ проверки'
A.items[999901].ruName='Плащ проверки силы'
A:BuildSearchTerms()
local search=A:FindItems('  ПЛАЩ ПРОВЕРКИ  ','all','all')
assert(search[1]==999902 and search[2]==999901 and search[3]==999910,'exact localized name, prefix, then substring')
assert(A:FindItems('|cff0070dd|Hitem:999910:0:0|h[Other name]|h|r','all','all')[1]==999910,'hyperlink resolves exact ID')
MOCK.items[999900]={name='Worn',class=4,subclass=2,loc='INVTYPE_CHEST',quality=2,level=20,stats={ITEM_MOD_AGILITY_SHORT=5}}
MOCK.equipped[5]=999900;function GetInventoryItemLink(_,slot) local id=MOCK.equipped[slot];return id and 'item:'..id end
C_Item.GetItemInfo=function(id) if type(id)=='string' then id=tonumber(id:match('item:(%d+)')) end;local d=MOCK.items[id];if not d then return end;return d.name,'item:'..id,d.quality,30,d.level,'Armor','Leather',1,d.loc,134400,1,d.class,d.subclass end
A:OpenAtlas()
assert(A.atlas.category=='upgrades' and #A.atlas.results>0,'strict improvements default on')
local f=A.atlas
f.category='upgrades';f.results=nil
for i=1,4 do A:RefreshAtlas() end
assert(#A.atlas.rows==8,'eight item rows')
local visible={};for _,row in ipairs(A.atlas.rows) do if row:IsShown() then visible[row.itemID]=true end end
assert(visible[999901] and visible[999910],'confirmed upgrades visible')
assert(f.recommendScan.ranks[999910]==1 and f.recommendScan.ranks[999901]==2 and not f.recommendScan.ranks[999902],'ranks order improvements within slot and exclude worse items')
assert(f.rows[1].detail:GetText():find('№1',1,true),'rank is rendered')
f.gearMode.scripts.OnClick();assert(f.category=='catalog','full gear remains available')
f.gearMode.scripts.OnClick();assert(f.category=='upgrades','return to strict upgrades')
for _,id in ipairs({999902,999903,999904,999905,999906,999907,999908,999909,999911,999912}) do assert(not visible[id],'exclude bad candidate '..id) end
A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999901,true);A:RefreshAtlas();local retained=false;for _,row in ipairs(A.atlas.rows) do if row:IsShown() and row.itemID==999901 then retained=true end end;assert(retained,'loading another item never clears confirmed recommendations')
C_TooltipInfo={GetHyperlink=function() return {lines={{leftText='Requires Test Faction - Exalted',leftColor={r=1,g=0,b=0}}}} end};A.events.scripts.OnEvent(A.events,'UPDATE_FACTION');A:RefreshAtlas();local blocked=true;for _,row in ipairs(A.atlas.rows) do if row:IsShown() and row.itemID==999901 then blocked=false end end;assert(blocked,'red client reputation requirement blocks recommendation');C_TooltipInfo=nil;A.atlasRequirementCache=nil
assert(A.atlas.recommendScan.limit<=128,'bounded validation batch')
A:RefreshAtlas()
MOCK.items[999900].stats.ITEM_MOD_AGILITY_SHORT=20
A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999900,true)
A:RefreshAtlas()
assert(not f.recommendScan.ranks[999901] and not f.recommendScan.ranks[999910],'worn item data refresh removes outdated upgrades')
MOCK.items[999900].stats.ITEM_MOD_AGILITY_SHORT=5
A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999900,true)
A:RefreshAtlas()
assert(f.recommendScan.ranks[999901],'updated baseline restores correct upgrades')
A:OpenAtlas('Плащ проверки')
f.allItems.scripts.OnClick()
assert(f.search:GetText()=='' and f.selectedItem==nil,'reset removes the actual search query')
local description=A:AtlasSourceDescription({entry={999901,6,-1,false,12345,2,-1,false},location={mapID=1429}})
assert(description:find('Купить за') and description:find('1з 23с 45м'),'observed buy price rendered')
assert(A:AtlasSourceDescription({entry={999901,5,-1},location={mapID=1429}}):find('неизвестна'),'reference vendor never invents a price')
assert(A:AtlasSourceDescription({entry={999901,1,12.5},location={mapID=1429}}):find('12.5',1,true),'drop rate rendered')
-- Catalog material filtering works across classes and includes useful low-level gear.
MOCK.class='PRIEST';A.db.gearSpec=2;A:RefreshGearProfile()
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
A.db.gearSpec=3;A:RefreshGearProfile()
assert(A:CompareItem(999901).state~='better','shadow priest does not receive a damage upgrade from healing-only stats')
A.db.specOnly=false
assert(A:CompareItem(999901).state=='better','disabling spec uses general priest priorities')
local holy=A:CompareItem(999901,A.gearSpecs.PRIEST[2])
local shadow=A:CompareItem(999901,A.gearSpecs.PRIEST[3])
assert(holy.score>shadow.score and holy.delta>0 and shadow.delta<0,'same item gets distinct scores and comparisons per spec')
assert(not A.db.specOnly and A.db.gearSpec==3,'rating preview does not change configuration')
A:OpenAtlas('999901');A:SelectAtlasItem(999901)
assert(A.atlas.gearRatings:IsShown(),'the item has a spec rating in the full catalog')
A.atlas.gearRatings.scripts.OnEnter(A.atlas.gearRatings)
print('PASS personal recommendations: name/link search, shared and unmapped source rejection, live equipped baseline, weaker/grey/future/caster/wand/enemy vendor checks, bounded work and source price/rate')
''')
