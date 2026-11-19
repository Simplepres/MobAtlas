from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for name in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{name}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) assert(loadstring(s,n))("MobAtlas",ns) end')
for name in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if name.endswith('.lua'):load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas;A:Init();MOCK.playerLevel=18;MOCK.combat=true
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);local mapID=1436
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return mapID end
function WorldMapFrame:SetMapID(id) mapID=id end
function WorldMapFrame:IsProtected() return MOCK.protectedMap or false end
function ShowUIPanel() error('protected panel operation in combat') end
function OpenWorldMap() error('protected panel operation in combat') end
C_Map={OpenWorldMap=function() error('protected panel operation in combat') end}
WorldMapFrame:Show();A:Update();assert(A.pins[1]:IsShown(),'first render in combat')
local pin=A.pins[1];A:ShowTooltip(pin,true);assert(A.tip:IsShown(),'inspect during combat')
A:PinInspection();assert(A.focus,'pin during combat');A:ClearFocus();assert(not A.focus,'unpin during combat')
mapID=1429;A:Update();assert(A.lastMap==1429 and A.pins[1]:IsShown(),'zone change refreshes during combat')
canvas:SetScale(2);A:Update();assert(A.pins[1].scale==.5,'zoom during combat')
A:OpenAtlas();assert(A.atlas:IsShown());assert(A:ShowItemOnMap(5191) and A.focus,'item search to map in combat')
assert(A:ShowQuestOnMap(167) and A.focus.questID==167,'quest navigation in combat')
local before=A.focus;WorldMapFrame:Hide();local ok,why=A:FocusSource(5191,639,1436)
assert(not ok and why:find('M',1,true) and A.focus==before,'closed map gives instruction and preserves selection')
A:Update();assert(not A.pins[1]:IsShown(),'closed map cleans own markers in combat')
WorldMapFrame:Show();mapID=1436;MOCK.protectedMap=true
assert(A:FocusSource(5191,639,1436),'already displayed protected zone can be used')
before=A.focus;local changed,reason=A:FocusSource(5191,639,1429)
assert(not changed and A.focus==before and reason:find('вручную',1,true),'protected zone change gives fallback, preserves focus')
MOCK.protectedMap=false;assert(A:FocusSource(5191,639,1429),'ordinary map can change zone in combat')
print('PASS combat: first render, hover, pin/unpin, map change, zoom, item/quest navigation, no protected panel calls, focus preserved on restrictions')
''')
