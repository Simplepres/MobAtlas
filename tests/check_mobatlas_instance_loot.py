from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas
Enum={TooltipDataType={Unit=2,Corpse=3}}
local callbacks={}
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) callbacks[kind]=fn end}
local activeMap=2998
function GetInstanceInfo() return 'Dungeon','party',1,'',5,false,nil,activeMap end
A:Init();A.db.unitLoot=true
assert(callbacks[2] and callbacks[3],'modern unit and corpse hooks installed')

local selected=260802;local lines={};local unitName='Матриарх из чащи';local hideGUID=false;local corpseGUID=false;local unitToken='mouseover'
function issecretvalue(v) return v=='[secret]' end
function UnitGUID() return hideGUID and '[secret]' or corpseGUID and 'Corpse-0-0-0-0' or ('Creature-0-1-2-3-'..selected..'-001') end
function GameTooltip:GetUnit() return unitName,unitToken end
function GameTooltip:AddLine(s) lines[#lines+1]=s end
local function clear() lines={};GameTooltip.mobAtlasID=nil end

local dungeons,knownBosses=0,0
for map,area in pairs(A.foreverInstanceMaps) do
 dungeons=dungeons+1
 assert(A.instances[area], 'stable instance ID and area are linked')
 local bosses=0
 for npc,bossArea in pairs(A.instanceBosses) do
  if bossArea==area then
   local mob=A.mobs[npc]
   if mob and #mob.loot>0 then
    bosses=bosses+1;knownBosses=knownBosses+1
    local source
    for _,loot in ipairs(mob.loot) do
     if loot[2]==7 and not loot[4] then
      assert(loot[3]==-1,'reference link has no invented drop rate')
      for _,row in ipairs(A:AtlasSources(loot[1],'dungeons')) do
       if row.npcID==npc and row.location.area==area then source=row;break end
      end
      if source then break end
     end
    end
    assert(source,'boss item has a source in the correct dungeon')
    activeMap=map;clear()
    callbacks[2](GameTooltip,{guid='Creature-0-1-2-3-'..npc..'-002'})
    assert(GameTooltip.mobAtlasID==npc and #lines>3,'boss loot reaches the unit tooltip')
   end
  end
 end
 assert(bosses>0,'every new dungeon has known boss loot')
end
assert(dungeons==9)
local entrance=false
for _,row in ipairs(A:AtlasSources(284845,'dungeons')) do
 if row.npcID==260802 and row.location.area==16732 and row.location.mapID==1437 then entrance=true end
end
assert(entrance,'Matriarch quest item resolves to the verified Wetlands entrance')
print('Coverage:',dungeons,'new dungeons,',knownBosses,'boss NPCs with known loot')

A.BuildAtlasIndex=function() error('tooltip must not rebuild atlas') end
activeMap=2998;hideGUID=true;unitToken=nil;unitName=nil;clear()
callbacks[3](GameTooltip,{guid='[secret]',lines={{leftText='|cffff0000Матриарх из чащи|r'}}})
assert(GameTooltip.mobAtlasID==260802 and #lines>3,'Russian corpse title recovers loot with a restricted GUID and no unit token')
local before=#lines;callbacks[3](GameTooltip,{guid='Corpse-0-0-0-0',lines={{leftText='Матриарх из чащи'}}})
assert(#lines==before,'corpse hooks do not duplicate the source')
clear();unitToken='mouseover';hideGUID=false;corpseGUID=true
callbacks[3](GameTooltip,{guid='Corpse-0-0-0-0',lines={{leftText='Матриарх из чащи'}}})
assert(GameTooltip.mobAtlasID==260802,'generic corpse GUID still falls back to the actual title')
unitToken=nil;hideGUID=true;corpseGUID=false
clear();callbacks[2](GameTooltip,{guid='Player-1-42',lines={{leftText='Матриарх из чащи'}}})
assert(not GameTooltip.mobAtlasID,'player tooltips cannot resolve as creatures')
activeMap=3065;clear();callbacks[3](GameTooltip,{lines={{leftText='Матриарх из чащи'}}})
assert(not GameTooltip.mobAtlasID,'NPC title must match the current dungeon')
clear();callbacks[3](GameTooltip,{lines={{leftText='Dark Iron Looter'}}})
assert(GameTooltip.mobAtlasID==263396 and #lines>3,'known regular dungeon creature fallback')
selected=999893;unitToken='mouseover';hideGUID=false;clear();callbacks[2](GameTooltip,{})
assert(A.mobs[selected] and #lines>=3,'unknown dungeon creature gets the missing-data message')
print('PASS dungeon loot: nine new dungeons, known boss sources, Matriarch corpse with restricted GUID, localized fallback, duplicate guard, no index rebuild')
''')
