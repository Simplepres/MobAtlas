"""Bounded-work checks and timings in Lua 5.1 mocks, not in-client FPS."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import time,json
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''MobAtlas:Init();local A=MobAtlas
A.BuildAtlasIndex=function() error('full atlas rebuild during loot') end
function GetNumLootItems() return 1 end
function GetLootSlotLink() return 'item:'..MOCK.newItem end
function GetLootSourceInfo() return 'Creature-0-1-2-3-43-00001',1 end
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);MOCK.canvas=canvas
MOCK.cells={};for i=1,80 do MOCK.cells[i]={x=5+(i%10)*9,y=5+math.floor(i/10)*11} end
''')
start=time.perf_counter()
for i in range(100):l.globals().MOCK.newItem=990100+i;a.CaptureLoot(a)
loot=(time.perf_counter()-start)*1000/100
start=time.perf_counter()
for i in range(20):a.RenderHabitatArea(a,l.globals().MOCK.cells,l.globals().MOCK.canvas,1,20,'HIGH')
contour=(time.perf_counter()-start)*1000/20
count=len(a.habitatAreas)
a.RenderHabitatArea(a,l.globals().MOCK.cells,l.globals().MOCK.canvas,1,20,'HIGH')
assert len(a.habitatAreas)==count and count<=2048
print(json.dumps({'lootMsPerNewItem':round(loot,3),'contourMs80Patches':round(contour,3),'pooledSegments':count,'fullIndexRebuilds':0,'environment':'Lua mocks; not WoW FPS'}))
