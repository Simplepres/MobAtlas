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
local result=A:CompareItem(999801);assert(result.state=='better' and result.slot==5 and result.percent>0 and math.abs(result.percent-result.delta/(result.score-result.delta)*100)<.0001 and result.text:match('^%+[%d.]+%%$'),'compare to the real worn slot and show its percent')
assert(A:CompareItem(999802).state=='same','already worn')
MOCK.equipped[5]=999801;local worse=A:CompareItem(999802);assert(worse.state=='worse' and worse.percent<0 and worse.text:match('^%-[%d.]+%%$'),'worse item shows a negative percent')
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
local count=0
for class,profiles in pairs(A.gearSpecs) do
 count=count+1
 assert(#profiles==(class=='DRUID' and 4 or 3),'all Forever talent branches and the bear profile')
 for _,profile in ipairs(profiles) do assert(next(profile.weights),'each profile defines stat weights') end
end
assert(count==9,'nine Forever classes')
local function armorScore(profile,stats) return A:ScoreGear(stats,profile,4,5,27) end
local healing={ITEM_MOD_SPELL_HEALING_DONE_SHORT=10}
local shadow={ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT=10}
local mp5={ITEM_MOD_POWER_REGEN0_SHORT=3,ITEM_MOD_MANA_REGENERATION_SHORT=3}
assert(armorScore(A.gearSpecs.PRIEST[2],healing)>armorScore(A.gearSpecs.PRIEST[2],shadow))
assert(armorScore(A.gearSpecs.PRIEST[3],shadow)>armorScore(A.gearSpecs.PRIEST[3],healing))
assert(math.abs(armorScore(A.gearSpecs.PRIEST[1],mp5)-4.8)<.001,'MP5 counts once across aliases')
local tank={ITEM_MOD_STAMINA_SHORT=7,ITEM_MOD_DEFENSE_SKILL_RATING_SHORT=4,RESISTANCE0_NAME=120}
assert(armorScore(A.gearSpecs.WARRIOR[3],tank)>armorScore(A.gearSpecs.WARRIOR[1],tank),'tank weights depend on armor and defense')
assert(armorScore(A.gearSpecs.DRUID[4],tank)>armorScore(A.gearSpecs.DRUID[2],tank),'bear and cat use different priorities')
local hunter={ITEM_MOD_AGILITY_SHORT=9,ITEM_MOD_DAMAGE_PER_SECOND_SHORT=24}
assert(A:ScoreGear(hunter,A.gearSpecs.HUNTER[2],2,18,27)>A:ScoreGear(hunter,A.gearSpecs.HUNTER[2],2,16,27),'marksmanship weighs ranged DPS')
assert(A:ScoreGear(hunter,A.gearSpecs.HUNTER[3],2,16,27)>A:ScoreGear(hunter,A.gearSpecs.HUNTER[3],2,18,27),'melee survival weighs melee DPS')
local generic={ITEM_MOD_STRENGTH_SHORT=5}
MOCK.items[999810].stats=generic;A.comparisonStats=nil
local zero=A:CompareItem(999811)
assert(zero.state=='better' and zero.percent==nil,'zero baseline has no valid percentage')
local tooltipReads=0
C_TooltipInfo={GetHyperlink=function()
 tooltipReads=tooltipReads+1
 return {lines={
  {leftText='(31,2 ед. урона в секунду)'},
  {leftText='Если на персонаже: восстанавливает 2 ед. маны раз в 5 сек.'},
  {leftText='Use: Restores 88 Mana every 5 seconds.'}
 }}
end}
MOCK.items[999813].stats={ITEM_MOD_INTELLECT_SHORT=4};A.comparisonStats=nil
local wandStats=A:GearComparisonStats('item:999813',A.gearSpecs.PRIEST[2],2,18,27)
assert(wandStats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT==31.2 and wandStats.ITEM_MOD_MANA_REGENERATION_SHORT==2,'localized static DPS and MP5 from the screenshot')
A:GearComparisonStats('item:999813',A.gearSpecs.PRIEST[1],2,18,27)
assert(tooltipReads==1,'alternate spec comparisons reuse parsed fields')
C_TooltipInfo=nil
local tooltip={lines={}}
function tooltip:AddLine(s) self.lines[#self.lines+1]=s end
A:AddComparisonTooltip(tooltip,999811);assert(#tooltip.lines==1,'item tooltip adds one comparison line')
tooltip.lines={};A:AddGearRatingsTooltip(tooltip,999811);assert(#tooltip.lines==4,'priest rating tooltip has heading plus three branches')

A.BuildAtlasIndex=function() error('comparison must not rebuild atlas') end;A:CompareItem(999801)
print('PASS comparison: worn slots, weaker ring, required level, exact links, unknown stats, legacy output-table API, weapon DPS/paired guards, no full indexing')
''')
