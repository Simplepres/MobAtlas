from pathlib import Path
from lupa.lua51 import LuaRuntime
import time,json
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text());l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) return assert(loadstring(s,n))("MobAtlas",ns) end')
t=time.monotonic()
for f in ['Data.lua','ClassGear.lua','Forever.lua','Catalog.lua','Expansion.lua','Preparation.lua','Observations.lua','Atlas.lua','Core.lua','Presentation.lua','Locale.lua','UI.lua','DungeonPins.lua','DungeonPins.lua']:load((r/'MobAtlas'/f).read_text(),'@'+f,ns)
l.execute('''
local A=MobAtlas;A:Init()
assert(A.mobs[6] and A.items[755]);assert(#A.foreverRates>0)
local observed=0;for _,m in pairs(A.mobs) do for _,e in ipairs(m.loot) do if e[2]==4 then observed=observed+1;assert(e[5]<=e[6] and e[7]>=3) end end end;assert(observed==#A.foreverRates)
assert(A.mobs[3].points[1][1]==1431,'Duskwood belongs only to Duskwood')
for _,p in ipairs(A.mobs[6].points) do assert(p[1]==1429) end
for _,p in ipairs(A.mobs[36].points) do assert(p[1]==1436) end
local direct=false;local unknown=false;local pins=0
for _,mob in pairs(A.mobs) do
 for _,p in ipairs(mob.points) do assert(p[2]>=0 and p[2]<=100 and p[3]>=0 and p[3]<=100);pins=pins+1 end
 for _,e in ipairs(mob.loot) do assert(A.items[e[1]]);assert(e[3]==-1 or e[3]>0 and e[3]<=100);if e[4] then assert(e[3]==-1) end end
end
for _,e in ipairs(A.mobs[6].loot) do
 if e[1]==755 and e[2]==1 then assert(math.abs(e[3]-29.7889)<.00001);direct=true end
 if e[4] then unknown=true end
end
assert(direct and unknown and pins>10000)
local westfall,westfallMobs=A:BuildMap(1436);assert(#westfall>100 and westfallMobs>10,'Westfall has map points');print('Westfall: '..#westfall..' points, '..westfallMobs..' mob types')
local cells,total=A:BuildMap(1429);assert(total>10 and #cells>10)
A.db.qualities={[2]=true};A.db.classOnly=true
local green=A:BuildMap(1429);assert(#green>0)
for _,cell in ipairs(green) do for _,id in ipairs(cell.ids) do for _,e in ipairs(A:Loot(id)) do assert(A.items[e[1]].quality==2 and A:ClassFits(A.items[e[1]],e[1])) end end end
A.db.qualities={[-1]=true,[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true};A.db.classOnly=false;A.db.prof=197
local tailors=A:BuildMap(1429);assert(#tailors>0)
print('PASS actual data: corpse percent, unknown pool chances, coordinate bounds, Elwynn green/class and tailoring filters')
''')
print('Load + validation seconds:',round(time.monotonic()-t,3))
print('Data bytes:',(r/'MobAtlas/Data.lua').stat().st_size)
