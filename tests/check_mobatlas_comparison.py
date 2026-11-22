from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();A.db.gearSpec=3;A:RefreshGearProfile()
local function item(id,loc,agi,sta) MOCK.items[id]={loc=loc,level=10,stats={ITEM_MOD_AGILITY_SHORT=agi,ITEM_MOD_STAMINA_SHORT=sta},class=4,subclass=2};A.items[id]={classID=4,subclass=2,name='Test',quality=2} end
item(999801,'INVTYPE_CHEST',8,2);item(999802,'INVTYPE_CHEST',3,3)
MOCK.equipped[5]=999802
function GetInventoryItemLink(_,slot) local id=MOCK.equipped[slot];return id and 'item:'..id end
local result=A:CompareItem(999801);assert(result.state=='better' and result.slot==5 and result.text:find('+5'),'compare to real worn slot and explain deltas')
assert(A:CompareItem(999802).state=='same','already worn')
MOCK.equipped[5]=999801;assert(A:CompareItem(999802).state=='worse','worse item not called upgrade')
MOCK.equipped[5]=nil;assert(A:CompareItem(999801).state=='empty','empty slot')
item(999803,'INVTYPE_FINGER',4,1);item(999804,'INVTYPE_FINGER',8,1);item(999805,'INVTYPE_FINGER',1,1)
MOCK.equipped[11]=999804;MOCK.equipped[12]=999805;assert(A:CompareItem(999803).slot==12,'compare ring to weaker ring')
MOCK.items[999803].level=60;A.comparisonInfo=nil;assert(A:CompareItem(999803).state=='later','respect required level')
MOCK.items[999801].stats={};A.comparisonStats=nil;MOCK.equipped[5]=999802;assert(A:CompareItem(999801).state=='unknown','missing candidate stats are not a zero score')
MOCK.items[999801].stats={ITEM_MOD_AGILITY_SHORT=8};C_Item.GetItemStats=function(link,out) for k,v in pairs(MOCK.items[tonumber(link:match('item:(%d+)'))].stats) do out[k]=v end;return true end
A.comparisonStats=nil;assert(A:CompareItem(999801).state=='better','legacy stats output-table contract')
MOCK.items[999806]={loc='INVTYPE_WEAPON',level=10,class=2,stats={ITEM_MOD_AGILITY_SHORT=8}};A.items[999806]={classID=2,subclass=15,name='Dagger'};MOCK.items[999807]={loc='INVTYPE_WEAPON',level=10,class=2,stats={ITEM_MOD_AGILITY_SHORT=3}};MOCK.equipped[16]=999807
assert(A:CompareItem(999806).state=='unknown','no weapon upgrade claim without DPS')
MOCK.equipped[17]=999802;assert(A:CompareItem(999806).text:find('комплекта'),'dual wield requires paired comparison')
MOCK.equipped[11]=nil;MOCK.equipped[12]=999804
assert(A:CompareItem(999804).state=='same','second ring already worn despite empty first slot')
local originalInventoryLink=GetInventoryItemLink
function GetInventoryItemLink(unit,slot) if slot==12 then return 'item:999804:0:0:0:0:0:-4' end return originalInventoryLink(unit,slot) end
assert(A:CompareItem(999804).text:find('вариант'),'an equipped variant is not an empty-slot upgrade')
GetInventoryItemLink=originalInventoryLink
MOCK.class='PRIEST';A.db.specOnly=false;A:RefreshGearProfile()
local function weapon(id,loc,sub,stats)
 MOCK.items[id]={loc=loc,level=10,class=2,subclass=sub,stats=stats};A.items[id]={classID=2,subclass=sub,name='Test weapon'}
end
weapon(999810,'INVTYPE_2HWEAPON',10,{ITEM_MOD_STAMINA_SHORT=5})
weapon(999811,'INVTYPE_2HWEAPON',10,{ITEM_MOD_INTELLECT_SHORT=8})
weapon(999812,'INVTYPE_RANGEDRIGHT',19,{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=12})
weapon(999813,'INVTYPE_RANGEDRIGHT',19,{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=20})
MOCK.items[999814]={loc='INVTYPE_HOLDABLE',level=10,class=4,subclass=0,stats={ITEM_MOD_INTELLECT_SHORT=5}}
A.items[999814]={classID=4,subclass=0,name='Orb'}
MOCK.equipped[16]=999810;MOCK.equipped[17]=nil;MOCK.equipped[18]=999812
assert(A:CompareItem(999811).state=='better','caster staff compares caster stats without melee DPS')
assert(A:CompareItem(999813).state=='better','wand compares against wand while a staff is equipped')
assert(A:CompareItem(999814).state=='unknown','offhand with two-handed staff is not an empty slot upgrade')
A.BuildAtlasIndex=function() error('comparison must not rebuild atlas') end;A:CompareItem(999801)
print('PASS comparison: worn slots, weaker ring, required level, exact links, unknown stats, legacy output-table API, weapon DPS/paired guards, no full indexing')
''')
