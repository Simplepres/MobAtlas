"""Relative Lua 5.1 simulator benchmark, not an in-client FPS measurement."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import time,statistics,json
root=Path(__file__).resolve().parents[2]
results={}
for version,folder in [('0.5.4',root/'outputs/MobAtlas-0.5.4/MobAtlas'),('0.6.0',root/'work/MobAtlas')]:
 l=LuaRuntime(unpack_returned_tuples=True)
 for f in ['wow_mock.lua','journal_mock.lua']:l.execute((root/'work/tests'/f).read_text())
 l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
 a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
 for name in ['Data','ClassGear','Forever','Catalog','Expansion','Preparation','Observations','Atlas','Core','Presentation','UI']:load((folder/(name+'.lua')).read_text(),a)
 l.execute('''MobAtlas:Init();local A=MobAtlas;A.fullRebuilds=0;local build=A.BuildAtlasIndex;A.BuildAtlasIndex=function(self,...) self.fullRebuilds=self.fullRebuilds+1;return build(self,...) end
function GetNumLootItems() return 1 end
function GetLootSlotLink() return 'item:'..MOCK.newItem end
function GetLootSourceInfo() return 'Creature-0-1-2-3-43-00001',1 end
''')
 samples=[]
 for i in range(8):
  l.globals().MOCK.newItem=990100+i
  start=time.perf_counter();l.globals().MobAtlas.CaptureLoot(a);samples.append((time.perf_counter()-start)*1000)
 results[version]={'medianMs':round(statistics.median(samples),3),'maxMs':round(max(samples),3),'newItems':8,'fullIndexRebuilds':a.fullRebuilds}
print(json.dumps(results,indent=2))
(root/'work/MobAtlas/Performance.json').write_text(json.dumps({'environment':'Lua 5.1 API simulator on development machine, not WoW client FPS','lootCapture':results},indent=2)+'\n')
