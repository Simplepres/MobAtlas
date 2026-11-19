from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text())
l.execute("getmetatable(UIParent).__index.EnableMouseWheel=function() end")
ns=l.table();load=l.eval('function(s,n,ns) return assert(loadstring(s,n))("MobAtlas",ns) end')
for name in ['Preparation.lua','Observations.lua','Atlas.lua','Core.lua','Presentation.lua','Locale.lua','UI.lua','DungeonPins.lua','DungeonPins.lua']:load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas
A.classData={classes={rogue={gear={{4,1,0},{4,2,0},{2,15,0}}}},restricted={}}
A.items={
 [1]={name='Green leather',quality=2,classID=4,subclass=2,prof={}},
 [2]={name='Blue plate',quality=3,classID=4,subclass=4,prof={}},
 [3]={name='Linen',quality=1,classID=7,subclass=5,prof={197,129}},
 [4]={name='Blue dagger',quality=3,classID=2,subclass=15,prof={}},
 [5]={name='Light leather',quality=1,classID=7,subclass=6,prof={165}},
}
A.mobs={
 [6]={name='Test kobold',min=1,max=2,points={{1429,42,65},{1429,42.1,65.1}},loot={{1,1,.15,false},{2,1,2,false},{3,1,40,false},{4,1,-1,true},{5,2,80,false}}},
 [7]={name='Nearby mob',min=2,max=3,points={{1429,55,65.1}},loot={{1,1,3,false}}},
}
A.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
assert(A.db.enabled and A.db.quality=='all')
assert(#A:Loot(6)==4,'conditional loot hidden by default');A.db.sharedLoot=true;assert(#A:Loot(6)==5)
A.items[8]={name='Epic test',quality=4,classID=2,subclass=15,prof={}}
table.insert(A.mobs[6].loot,{8,1,1,false})
A.db.qualities={[2]=true,[4]=true};assert(#A:Loot(6)==2,'green and epic coexist')
A.db.qualities={};assert(#A:Loot(6)==0,'empty selection is empty')
table.remove(A.mobs[6].loot)

A.db.qualities={[2]=true};assert(#A:Loot(6)==1)
A.db.qualities={[3]=true};assert(#A:Loot(6)==2)
A.db.classOnly=true;assert(#A:Loot(6)==1 and A:Loot(6)[1][1]==4,'rogue cannot equip plate')
A.db.qualities={[-1]=true,[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true};A.db.prof=197;assert(#A:Loot(6)==1 and A:Loot(6)[1][1]==3,'profession filter uses reagents')
A.db.prof=-1;assert(#A:Loot(6,{})==0);assert(#A:Loot(6,{[165]=true})==1)
A.db.skinning=false;assert(#A:Loot(6,{[165]=true})==0)
A.db.prof=0;A.db.classOnly=false;A.db.skinning=true
local cells,total=A:BuildMap(1429);assert(total==2 and #cells==3 and #cells[1].ids==1,'actual spawn coordinates are not grid-clustered')
assert(A:Chance({1,1,.15,false}):find('0.15%%'))
assert(A:Chance({4,1,-1,true})=='шанс неизвестен','pool probability never substituted for item probability')
MOCK.canvas=CreateFrame('Frame');MOCK.canvas:SetSize(1000,800)
function WorldMapFrame:GetCanvas() return MOCK.canvas end
function WorldMapFrame:GetMapID() return 1429 end
WorldMapFrame:Show();A:Update();assert(#A.pins==2 and A.pins[1]:IsShown())
assert(not A.pins[1].glow:IsShown(),'overview has no permanent glow')
assert(A.pins[1].dot and A.pins[1]:GetWidth()==20 and A.pins[1].dot:GetWidth()==18,'visible independent dot texture');A.pins[1].scripts.OnEnter(A.pins[1]);assert(A.tip:IsShown());assert(A.tip:GetWidth()==300 and A.tip:GetHeight()<360 and not A.tip.footer,'compact card without footer')
local pin=A.pins[1]
local terrain=CreateFrame('Frame');terrain:SetFrameLevel(500)
function WorldMapFrame:GetPinFrameLevelsManager() return {GetValidFrameLevel=function(_,kind) assert(kind=='PIN_FRAME_LEVEL_AREA_POI');return 450 end} end
function WorldMapFrame:EnumeratePinsByTemplate(name) assert(name=='MapExplorationPinTemplate');local done=false;return function() if not done then done=true;return terrain end end end
A:Update();assert(pin:GetFrameLevel()==501,'above Leatrix exploration terrain')
terrain:SetFrameLevel(700);MOCK.canvas:SetScale(2);A:Update();assert(pin:GetFrameLevel()==701 and pin.scale==.5,'late overlay and zoom updates without dirty rebuild')
A:Update();assert(pin:GetFrameLevel()==701,'no frame level escalation')
assert(math.abs(pin.point[4]*pin.scale-MOCK.canvas:GetWidth()*pin.cell.x/100)<.001,'zoom must not shift x')
assert(math.abs(pin.point[5]*pin.scale+MOCK.canvas:GetHeight()*pin.cell.y/100)<.001,'zoom must not shift y')
MOCK.canvas:SetScale(.625);A:Update();assert(math.abs(pin.scale-1.6)<.001)
assert(math.abs(pin.point[4]*pin.scale-MOCK.canvas:GetWidth()*pin.cell.x/100)<.001,'fractional map scale must not shift pin')

MOCK.canvas:SetScale(1);A:Update()

pin.scripts.OnClick(pin,'LeftButton');pin.scripts.OnLeave(pin);assert(A.tip:IsShown() and A.inspectPin==pin and not A.pinned and not A.focus,'click inspects without tracking');A.tip.unpin.scripts.OnClick();assert(A.pinned==pin and A.focus,'explicit button pins habitat')
A.pins[2].scripts.OnEnter(A.pins[2]);assert(A.pinned==pin,'hover cannot replace fixed card')
A.tip.close.scripts.OnClick();assert(not A.tip:IsShown() and not A.pinned);A:ClearFocus(false)
A.db.visibleItems=3;A:ShowTooltip(pin);assert(A.tip.rows[3]:IsShown() and not A.tip.rows[4]:IsShown())
A:ClearFocus(false);A.db.specialFirst=false;assert(A:Loot(6)[1][3]==80 and A:Loot(6)[5][3]==-1,'chance sort: unknown last')
A.db.sort='quality';assert(A.items[A:Loot(6)[1][1]].quality==3);A.db.sort='chance'
local registered
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) registered=fn end};Enum={TooltipDataType={Unit=1}}
A:HookUnitLoot();assert(type(registered)=='function','modern unit tooltip hook registered')
local methods=getmetatable(GameTooltip).__index
function methods:GetUnit() return 'Test kobold','mouseover' end
function UnitGUID() return 'Creature-0-1-2-3-6-00001' end
local lines={};function GameTooltip:AddLine(text) lines[#lines+1]=text end
A.db.specialFirst=false;registered(GameTooltip);assert(lines[3]:find('Blue plate',1,true) or lines[3]:find('Blue dagger',1,true),'unit hover always puts rare loot before common loot');assert(#lines>=5 and GameTooltip.mobAtlasID==6)
local count=#lines;A:UnitLootTooltip(GameTooltip);assert(#lines==count,'no duplicate unit tooltip')
GameTooltip.mobAtlasID=nil;A.db.unitLoot=false;A:UnitLootTooltip(GameTooltip);assert(#lines==count);A.db.unitLoot=true
assert(A:NpcID('mouseover')==6);function UnitGUID() return 'Player-1-42' end;assert(A:NpcID('mouseover')==nil)
assert(A.minimapButton);A.minimapButton.scripts.OnClick(nil,'LeftButton');assert(A.atlas:IsShown());A.atlas:Hide()
A.db.enabled=false;A:Invalidate();assert(not A.pins[1]:IsShown())
A.settingsButton=nil;SlashCmdList.MOBATLAS('on');assert(A.pins[1]:IsShown())
SlashCmdList.MOBATLAS('settings');assert(A.settings:IsShown())
A.db.qualities={[3]=true};A.db.prof=197;A:Invalidate();assert(A.mapStatus:GetText():find('Нет добычи',1,true))
A.db.qualities=nil;A.db.quality='both';A:Init();assert(A.db.qualities[2] and A.db.qualities[3] and not A.db.qualities[4],'legacy quality migrates')
A.db.qualities={[4]=true,[5]=true};A:Init();assert(A.db.qualities[4] and A.db.qualities[5] and not A.db.qualities[2],'custom choice survives reload')
A.qualitySelect.scripts.OnClick();assert(A.qualityMenu:IsShown());A.profSelect.scripts.OnClick();assert(not A.qualityMenu:IsShown() and A.profMenu:IsShown(),'only one popup')
-- Inspecting must preserve the hover card position rather than jump to the map corner.
A.settings:Hide();A:ClearFocus(false);A:ShowTooltip(pin,true)
local anchor=A.tip.point;A:InspectPin(pin)
for i=1,5 do assert(A.tip.point[i]==anchor[i],'click must preserve the preview anchor') end
A.tip.GetLeft=function() return 230 end;A.tip.GetTop=function() return 610 end
A:CloseInspection();A:ShowTooltip(pin,true);A:InspectPin(pin)
assert(A.tip.point[1]=='TOPLEFT' and A.tip.point[2]==UIParent and A.tip.point[4]==230 and A.tip.point[5]==610,'freeze actual on-screen position')
A:PinInspection();assert(A.tip.point[4]==230 and A.tip.point[5]==610,'pinning preserves frozen position')
A:ShowTooltip(pin,true);assert(A.tip.point[4]==230 and A.tip.point[5]==610,'refresh preserves frozen position')
A:ClearFocus(false);assert(not A.tip.stableAnchor,'close releases anchor for next marker')
A.tip.GetLeft=nil;A.tip.GetTop=nil
-- A row has an explicit hover state and leaves it without sticking on refresh.
A:ShowTooltip(pin,true);local row=A.tip.rows[1]
row.scripts.OnEnter(row);assert(row.hover:IsShown(),'hover fills the whole row')
row.scripts.OnLeave(row);assert(not row.hover:IsShown() and not row.arrow:IsShown())
assert(A.tip.headerLine.point[3]==-51,'header separator stays above list')
A:LayoutLootCard(pin,2,1,false);assert(not A.tip.prev:IsShown() and not A.tip.next:IsShown() and not A.tip.pageText:IsShown(),'one-page card has no redundant pager')
assert(A.tip.unpin.point[3]==-(58+2*40+13),'short list footer follows visible rows')
A:LayoutLootCard(pin,5,3,true);assert(A.tip.prev:IsShown() and A.tip.pageText:IsShown())
assert(A.tip.unpin.point[3]==A.tip.mobNext.point[3],'footer actions share a baseline')
-- Idle pinned maps must not rebuild habitats and portraits on every ticker.
A:ClearFocus(false);A:ShowTooltip(pin,true);A:PinInspection();A.dirty=false
local render=A.RenderFocus;A.RenderFocus=function() error('idle focus redraw') end;A:Update();A.RenderFocus=render;A:ClearFocus(false)
A:ToggleTrackingMenu(A.minimapButton);assert(A.trackingMenu:IsShown());A.trackingMenu.mobs:SetChecked(false);A.trackingMenu.vendors:SetChecked(false);A.trackingMenu.mobs.scripts.OnClick();assert(A.db.enabled and A.db.mapLayer=='none','dungeons-only layer');A.trackingMenu.dungeons:SetChecked(false);A.trackingMenu.dungeons.scripts.OnClick();assert(A.db.enabled==false)
A.trackingMenu.mobs:SetChecked(true);A.trackingMenu.mobs.scripts.OnClick();assert(A.db.enabled and A.db.mapLayer=='mobs');A.trackingMenu:Hide()
-- Portraits use the visible unit, then the cached native display, with a family fallback.
A.db.portraits={};A.mobs[834]={name='Coyote',family='Wolf',kind='Beast'}
local portrait=CreateFrame('Frame'):CreateTexture();function portrait:SetTexture(v) self.image=v end
function UnitGUID(unit) if unit=='target' then return 'Creature-0-1-2-3-834-0001' end end
local nativeUnit;function SetPortraitTexture(tex,unit) nativeUnit=unit end
A:SetNpcPortrait(portrait,834);assert(nativeUnit=='target')
function UnitGUID() end;SetPortraitTexture=nil
A:SetNpcPortrait(portrait,834);assert(portrait.image:find('Pet_Wolf',1,true),'wolf family icon instead of generic whistle')
A.db.portraits[834]=444;local display
function SetPortraitTextureFromCreatureDisplayID(tex,id) display=id end
A:SetNpcPortrait(portrait,834);assert(display==444)
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700)
local cells={{x=10,y=20,ids={6}},{x=10.1,y=20.1,ids={6}},{x=70,y=20,ids={6}}}
local sparse=A:ReadableFocusCells(cells,canvas,1);assert(#sparse==2 and sparse[1]==cells[1] and sparse[2]==cells[3],'thinning preserves actual coordinates')
print('PASS MobAtlas: class/quality/profession intersections, unknown pools, exact points, frozen card, item counts, sorting, minimap, map hover, settings and enable/disable')
''')
