from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');ns=l.table();load=l.eval('function(s,n,a) assert(loadstring(s,n))("MobAtlas",a) end')
for name in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if name.endswith('.lua'):load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas;A:Init();A.db.classOnly=true
local fox=A.mobs[277645];assert(fox and fox.name=='Gray Fox' and fox.kind=='Beast' and fox.huntable)
assert(fox.family=='Fox' and #fox.points>100,'Forever metadata/portrait family retained')
local function mapped(id)
 for _,c in ipairs(A:BuildMap(1431)) do for _,n in ipairs(c.ids) do if n==id then return true end end end
 return false
end
assert(mapped(277645),'neutral Gray Fox not hidden as friendly NPC')
local canine;for _,e in ipairs(A:Loot(277645)) do if e[1]==3301 then canine=e end end
assert(canine and canine[2]==14 and canine[3]==-1 and not A:Chance(canine):find('%%'),'player report is not invented measured rate')
local meta=0;local withLoot=0
for id,c in pairs(A.catalog) do if id>=200000 and #c.points>0 then meta=meta+1 end end
for id,m in pairs(A.mobs) do if id>=200000 and #m.loot>0 then withLoot=withLoot+1 end end
assert(meta>=1105 and withLoot>400,'new NPC metadata/loot associations integrated')
A.mobs[999502]={name='Test quest NPC',min=22,max=22,kind='Unknown',friendly='AH',service=true,points={{1431,10,20}},loot={{3301,14,-1,false}}};table.insert(A.zoneIndex[1431],999502)
assert(not mapped(999502),'friendly service NPC stays hidden')
local target=999502
function UnitGUID(unit) if unit=='target' then return 'Creature-0-1-2-3-'..target..'-001' end end
function UnitCanAttack(_,unit) return unit=='target' end
function UnitCreatureType() return 'Beast' end
function UnitName() return 'Test neutral beast' end
local build=A.BuildAtlasIndex;A.BuildAtlasIndex=function() error('full rebuild in unit observation') end
A:CaptureNpcTraits('target');assert(mapped(999502) and A.db.npcTraits[999502].huntable,'client attackability overrides reference flag')
A.mobs[999502].huntable=nil;A:StartNpcObservation();assert(A.mobs[999502].huntable,'observed traits restored')
-- A new, loot-unknown NPC can use known reference coordinates after observation.
A.catalog[999503]={name='Test new creature',min=22,max=23,points={{1431,30,40}},instances={},friendly='AH',kind='Unknown',service=false}
target=999503;A:CaptureNpcTraits('target');assert(mapped(999503) and #A.mobs[999503].loot==0,'unknown loot is not mistaken for no creature')
assert(A.mobs[999503].points[1][2]==30,'reference coordinates, never player substitute')
-- Direct API observations supersede player reports without duplicates or a full index pass.
function GetNumLootItems() return 1 end
function GetLootSlotLink() return 'item:3301' end
function GetLootSourceInfo() return 'Creature-0-1-2-3-277645-001',1 end
A:CaptureLoot();local count=0
for _,e in ipairs(A:Loot(277645)) do if e[1]==3301 then count=count+1;assert(e[2]==8) end end
assert(count==1,'personal observation wins and stays unique')
target=277645;local tooltip=CreateFrame('Frame');local lines={}
function tooltip:GetUnit() return 'Gray Fox','target' end
function tooltip:AddLine(text) lines[#lines+1]=text end
A:UnitLootTooltip(tooltip);local more=false
for _,line in ipairs(lines) do if line:find('Показано:',1,true) then more=true end end
assert(more,'tooltip explains that only top items are shown')
function GetLootSlotLink() return 'item:990500' end
C_Item={GetItemInfo=function() return nil end};A:CaptureLoot()
assert(A.pendingLootItems[990500] and A.db.lootFinds[277645].items[990500],'uncached item retains exact NPC source')
C_Item.GetItemInfo=function() return 'Test cached loot','item:990500',2,22,20,'Armor','Leather',1,'INVTYPE_CHEST',123,1,4,2 end
A.events.scripts.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',990500)
assert(A.items[990500].quality==2 and A.items[990500].classID==4 and not A.pendingLootItems[990500],'delayed item metadata resolved incrementally')
assert(A:FindItems('Test cached loot','all','all')[1]==990500,'resolved item searchable')
A.BuildAtlasIndex=build
print('PASS new NPCs: Gray Fox map/loot, reported Sharp Canine, neutral/service distinction, new metadata, client traits/restore, unknown-loot visibility, source geometry, observed loot priority and tooltip count')
''')
