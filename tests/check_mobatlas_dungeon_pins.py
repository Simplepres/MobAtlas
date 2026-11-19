from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for name in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{name}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) assert(loadstring(s,n))("MobAtlas",ns) end')
for name in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if name.endswith('.lua'):load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas;A:Init();MOCK.playerLevel=18
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);canvas:SetScale(1);local mapID=1436;local children={}
function canvas:GetChildren() return unpack(children) end
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return mapID end
function WorldMapFrame:SetMapID(id) mapID=id end
WorldMapFrame:Show();A:Update()
local pin;for _,p in ipairs(A.dungeonPins) do if p:IsShown() and p.cell.areas[1]==1581 then pin=p end end
assert(pin and not pin.leatrixMarker,'standalone entrance marker')
assert(math.abs(pin.point[4]-425)<.001,'verified entrance coordinate')
for _,cell in ipairs(A:BuildMap(1436)) do assert(not cell.dungeon,'no duplicate overview loot entrance') end
local lines={};function GameTooltip:AddLine(text) lines[#lines+1]=text end
pin.scripts.OnEnter(pin);assert(#lines>1,'hover shows quests')
pin.scripts.OnClick(pin);assert(A.prep:IsShown() and A.prep.area==1581,'entrance opens clickable quest list')
assert(A:ShowQuestOnMap(167));assert(A.questFocus and A.db.questPin and mapID==1453)
A:Invalidate();assert(A.questFocus and A.focus.questID==167,'level/filter refresh keeps quest pin')
A:QuestLogChanged();table.remove(MOCK.timers)();assert(A.questFocus,'quest updates keep pin')
C_QuestLog.IsOnQuest=function(id) return id==167 end;A:QuestLogChanged();table.remove(MOCK.timers)();assert(A.questFocus,'accepted quest stays pinned')
C_QuestLog.IsOnQuest=nil
WorldMapFrame:Hide();A:Update();assert(A.questFocus,'closing map keeps pin')
WorldMapFrame:Show();A:Update();assert(A.habitatPins[1]:IsShown(),'opening map restores pin')
local saved=A.db.questPin;A.questFocus=nil;A.focus=nil;A:RestoreQuestPin();assert(A:IsQuestPinned(167),'saved selection restores')
A:FocusSource(5191,639,1436);assert(A.questFocus and A.focus.ids[639],'loot browsing does not discard quest')
A:ShowQuestOnMap(167);assert(not A.questFocus and not A.db.questPin,'same quest toggles off')
assert(A:ShowQuestOnMap(167));A.habitatPins[1].scripts.OnMouseUp();assert(not A.questFocus,'click quest marker unpins')
assert(A:ShowQuestOnMap(167));A.focusButton.scripts.OnClick();assert(not A.questFocus,'map unpin button')
-- Leatrix compatibility: keep native pin and its click/data; add a small quest badge.
mapID=1436;local native=CreateFrame('Frame',nil,canvas);native.isLeaMapsPin=true;native.data={'Dungeon',42.5,71.7,'The Deadmines'};native:Show();children={native}
local original=native.data;local calls=0;native:SetScript('OnClick',function() calls=calls+1 end)
LeaMapsPOITooltip=CreateFrame('Frame');local nativeLines={}
function LeaMapsPOITooltip:GetOwner() return native end
function LeaMapsPOITooltip:AddLine(text) nativeLines[#nativeLines+1]=text end
function LeaMapsPOITooltip:HookScript(name,fn) self.scripts[name]=fn end
A.dirty=true;A:Update();assert(pin.leatrixMarker==native and pin:GetWidth()==14,'badge replaces duplicate full-size icon')
assert(native.data==original and native:IsShown());native.scripts.OnClick();assert(calls==1,'native click unchanged')
LeaMapsPOITooltip.scripts.OnShow(LeaMapsPOITooltip);assert(#nativeLines>1,'native entrance tooltip gains quest list')
native:Hide();A:Update();assert(not pin.leatrixMarker and pin:GetWidth()==22,'own marker returns when native pin hidden')
canvas:SetScale(2);A:Update();assert(pin.scale==.5,'entrance scale follows zoom')
local container=CreateFrame('Frame');local overlay=CreateFrame('Frame');overlay.bg={};local art=CreateFrame('Frame');art.art={}
function container:GetChildren() return canvas,overlay end
function overlay:GetChildren() return art end
WorldMapFrame.ScrollContainer=container;LeaMapsDungeonTooltip=CreateFrame('Frame')
overlay:Show();A:Update();assert(not pin:IsShown(),'zone pins do not cover Leatrix dungeon preview')
overlay:Hide();A:Update();assert(pin:IsShown(),'return from preview restores entrance layer')
A.db.dungeonPins=false;A:Update();assert(not pin:IsShown(),'entrance layer toggle')
print('PASS dungeon markers: verified coordinates, hover quests/click list, no duplicate entrance; persistent quest across events/acceptance/close/reload/loot browsing; explicit unpin; Leatrix tooltip/badge preserves native click/data; zoom/toggle')
''')
