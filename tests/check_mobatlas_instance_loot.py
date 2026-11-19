from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();MOCK.instance='party';A.db.unitLoot=true
local selected=263396;local lines={}
function UnitGUID() return 'Creature-0-1-2-3-'..selected..'-001' end
function GameTooltip:GetUnit() return 'Dungeon mob','mouseover' end
function GameTooltip:AddLine(s) lines[#lines+1]=s end
A.BuildAtlasIndex=function() error('tooltip must not rebuild atlas') end
for _,id in ipairs({263396,263470}) do
 selected=id;lines={};GameTooltip.mobAtlasID=nil
 assert(A.catalog[id] and A.mobs[id] and #A.mobs[id].loot>0,'generated Forever dungeon mobs and loot retained')
 local direct=0;for _,e in ipairs(A.mobs[id].loot) do if e[2]==7 then assert(e[3]==-1,'reference association has no invented rate');direct=direct+1 end end
 assert(direct>0,'generated delta loot imported')
 A:UnitLootTooltip(GameTooltip);assert(GameTooltip.mobAtlasID==id and #lines>3,'loot appears inside dungeon')
 local before=#lines;A:UnitLootTooltip(GameTooltip);assert(#lines==before,'same tooltip is not duplicated')
end
selected=999893;lines={};GameTooltip.mobAtlasID=nil;A:UnitLootTooltip(GameTooltip)
assert(A.mobs[selected] and #lines>=3,'unknown dungeon creature explains missing data rather than silent empty tooltip')
print('PASS dungeon loot: generated Forever mobs, item links, unknown rates, unit hover, unknown NPC fallback, duplicate guard, no index rebuild')
''')
