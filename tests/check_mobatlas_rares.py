from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for name in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{name}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) assert(loadstring(s,n))("MobAtlas",ns) end')
for name in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if name.endswith('.lua'):load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas
function GetTime() return MOCK.clock end
A.rareCatalog[999501]={name='Test rare',min=5,max=6,rank=4,points={{1429,52,50},{1429,80,80}}}
local playerX,playerY=.5,.5
local units={};local cvars={nameplateMaxDistance='40',nameplateShowEnemies='0',rotateMinimap='0',nameplateShowAll='0'};local sets=0
C_CVar={GetCVar=function(k) return cvars[k] end,SetCVar=function(k,v) assert(not MOCK.combat);sets=sets+1;cvars[k]=v end}
function GetCVar(k) return cvars[k] end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);local mapID=1429
function WorldMapFrame:GetMapID() return mapID end
function WorldMapFrame:SetMapID(id) mapID=id end
function WorldMapFrame:GetCanvas() return canvas end
C_Map={GetBestMapForUnit=function() return 1429 end,GetPlayerMapPosition=function(id,unit) assert(unit=='player','never infer NPC position using player map position');return CreateVector2D(playerX,playerY) end,GetMapWorldSize=function() return 1000,1000 end,GetMapPosFromWorldPos=function(instance,v,map) return map,CreateVector2D(v:GetXY()/1000,.5) end}
function UnitGUID(unit) return units[unit] and units[unit].guid end
function UnitClassification(unit) return units[unit] and units[unit].classification end
function UnitIsFriend() return false end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead or false end
function UnitName(unit) return units[unit] and 'Test rare' end
function UnitPosition(unit) if units[unit] and units[unit].position then return 520,500,0,0 end end
function GetPlayerFacing() return math.pi/2 end
C_Minimap={GetViewRadius=function() return 100 end};Minimap:SetSize(140,140)
local sounds=0;function PlaySound() sounds=sounds+1 end
A:Init();assert(cvars.nameplateMaxDistance=='80' and cvars.nameplateShowEnemies=='1','requested maximum nameplates')
local build=A.BuildAtlasIndex;A.BuildAtlasIndex=function() error('full index rebuild in rare scan') end
units.nameplate1={guid='Creature-0-1-2-3-999501-001',classification='rare',position=false}
A:WatchRareUnit('nameplate1');assert(A.rareAlert:IsShown() and sounds==1,'alert on actual unit detection')
assert(not A.rareSeen[999501].point,'no NPC position -> never fabricate at player position')
A:WatchRareUnit('nameplate1');A:RareTick();assert(sounds==1,'deduplicate repeated nameplate/target detections')
A:UpdateRareMinimap();local mini
for _,p in ipairs(A.rareMiniPins) do if p:IsShown() and p.entry.id==999501 then mini=p end end
assert(mini and not mini.entry.exact and mini.entry.live,'minimap reference marker explicitly not live coordinates')
assert(math.abs(mini.point[4]-14)<.001 and mini.point[5]==0,'minimap distance geometry')
cvars.rotateMinimap='1';A:UpdateRareMinimap();assert(math.abs(mini.point[4])<.001 and math.abs(mini.point[5]+14)<.001,'minimap rotation');cvars.rotateMinimap='0'
cvars.rotateMinimap='1';A:UpdateRareMinimap();assert(math.abs(mini.point[4])<.001 and math.abs(mini.point[5]+14)<.001,'rotating minimap')
cvars.rotateMinimap='0';units.nameplate1.position=true;A:WatchRareUnit('nameplate1');assert(A.rareSeen[999501].point[2]==52,'exact coordinates only when API supplies them')
local found=false;for _,e in ipairs(A:RareMapEntries(1429)) do if e.id==999501 then found=e.exact end end;assert(found,'exact live state')
A:Update();assert(#A.rareWorldPins>0)
local ex,ey,edge=A:MinimapRareOffset({1429,80,50},1429,CreateVector2D(.5,.5),true);assert(edge and math.abs(ex-61.6)<.01 and ey==0,'confirmed off-map marker clamps to rim')
assert(not A:MinimapRareOffset({1429,80,50},1429,CreateVector2D(.5,.5),false),'do not clamp unconfirmed reference points')
assert(A:TrackRare(999501));assert(A.focus.ids[999501] and A.tip:IsShown(),'rare click opens loot card');assert(A:IsInspectionTracked(A.inspectPin),'rare map action explicitly pins that creature')
local area=0;for _,f in ipairs(A.habitatAreas) do if f:IsShown() then area=area+1 end end;assert(area>0 and area<=80,'bounded soft patch pool')
A:RenderHabitatArea({{x=10,y=10},{x=90,y=90}},canvas,1,20,'HIGH');for _,f in ipairs(A.habitatAreas) do if f:IsShown() then local pos=f.point or f.startPoint;local x=f.point and pos[4] or pos[3];assert(x<150 or x>850,'no bridge across empty map') end end
units.nameplate1.dead=true;A:WatchRareUnit('nameplate1');assert(not A:RareLiveRecord(999501),'dead creature not live')
units.nameplate2={guid='Creature-0-1-2-3-999501-002',classification='normal'};A:WatchRareUnit('nameplate2');assert(sounds==1,'client normal classification overrides reference rarity')
units.nameplate2.classification='rare';units.nameplate2.position=false;A:WatchRareUnit('nameplate2');assert(sounds==2,'new spawn gets alert')
units.secret={guid={secret=true},classification='rare'};A:WatchRareUnit('secret');assert(sounds==2,'secret GUID ignored')
units.secret={guid='Creature-0-1-2-3-999501-099',classification={secret=true}};A:WatchRareUnit('secret');assert(sounds==2,'secret classification ignored')
MOCK.clock=MOCK.clock+11;units.nameplate2=nil;assert(not A:RareLiveRecord(999501),'stale unit expires')
MOCK.combat=true;local before=sets;A.db.rareMaxRange=false;A:ConfigureRareRange();assert(A.rareRangePending and sets==before,'defer CVars in combat')
MOCK.combat=false;A:ConfigureRareRange();assert(cvars.nameplateMaxDistance=='40' and cvars.nameplateShowEnemies=='0' and cvars.nameplateShowAll=='0','restore previous preferences')
local originalSet=C_CVar.SetCVar;C_CVar.SetCVar=function(k,v) originalSet(k,k=='nameplateMaxDistance' and v=='80' and '60' or v) end
A.db.rareMaxRange=true;A:ConfigureRareRange();assert(cvars.nameplateMaxDistance=='60','client clamps request');A.db.rareMaxRange=false;A:ConfigureRareRange();assert(cvars.nameplateMaxDistance=='40','restore works after clamp')
A:OpenRareSettings();assert(A.rareSettings:IsShown() and A.rareSettings.checks.rareMaxRange,'rare settings available');A.rareSettings:Hide()
-- Targeting is armed only on click, and the saved sighting must match the live GUID.
function RegisterStateDriver() end
units.nameplate2={guid='Creature-0-1-2-3-999501-002',classification='rare'}
A:WatchRareUnit('nameplate2');A:ShowRareAlert(999501,A.rareSeen[999501])
local button=A.rareTargetButton
button.scripts.PreClick(button)
assert(button.attributes.type=='target' and button.attributes.unit=='nameplate2','nearby exact GUID arms a secure target click')
units.target=units.nameplate2
button.scripts.PostClick(button)
assert(not A.rareAlert:IsShown() and not button.attributes.type,'successful secure target disarms click')
local sighting=A.rareSeen[999501]
A:ShowRareAlert(999501,sighting)
units.nameplate2={guid='Creature-0-1-2-3-999502-003',classification='rare'}
units.target=nil
button.scripts.PreClick(button)
assert(not button.attributes.type,'recycled unit token never targets a different creature')
button.scripts.PostClick(button)
assert(A.focus.ids[999501] and not A.focus.ids[999502] and A.habitatPinnedFocus==A.focus,'fallback map pins the creature from the alert')
local rareEntries=A.RareMapEntries
A.RareMapEntries=function() return {{id=999502,point={1429,40,40},exact=true}} end
A:UpdateRareWorld(canvas,1,20,'HIGH')
for _,pin in ipairs(A.rareWorldPins) do assert(not pin:IsShown(),'an unrelated live rare cannot compete with the pinned selection') end
A.RareMapEntries=rareEntries
function OpenWorldMap() WorldMapFrame:Show() end
WorldMapFrame:Hide()
MOCK.combat=true
A:ShowRareAlert(999501,sighting);local queued=A.rareAlert.sighting
A.rareAlert.scripts.OnClick()
assert(A.pendingRareMap==queued and not WorldMapFrame:IsShown(),'blocked map click queues the original sighting')
MOCK.combat=false
A.rareEvents.scripts.OnEvent(A.rareEvents,'PLAYER_REGEN_ENABLED')
assert(not A.pendingRareMap and WorldMapFrame:IsShown() and A.focus.ids[999501],'queue opens the right rare after combat')
local plays=0
function PlaySound() plays=plays+1;return plays>1 end
A:PlayRareAlertSound();MOCK.timers[#MOCK.timers]();assert(plays==2,'failed primary sound falls back once')
-- The map toggle uses loot quality and pets, not NPC rarity.
A:ClearFocus(false)
A.items[999701]={quality=1,classID=15,subclass=2}
A.items[999702]={quality=3,classID=0,subclass=0}
A.items[999703]={quality=2,classID=0,subclass=0}
A.db.specialMobsOnly=true
A.mobs[999711]={name='Pet source',points={{1429,40,40}},loot={{999701,7,-1}}}
A.mobs[999712]={name='Blue source',points={{1429,50,50}},loot={{999702,7,-1}}}
A.mobs[999713]={name='Green only',points={{1429,60,60}},loot={{999703,7,-1}}}
A.zoneIndex[1429]={999711,999712,999713}
local matched={}
for _,cell in ipairs(A:BuildMap(1429)) do for _,id in ipairs(cell.ids) do matched[id]=true end end
assert(matched[999711] and matched[999712] and not matched[999713],'map toggle keeps blue and pet drops only')
A.db.specialMobsOnly=false
-- Two visible spawns of one NPC must retain their own coordinates and frames.
A.rareCatalog[999601]={points={{1429,45,54},{1429,55,54}}}
A.rareZones[1429]={999601};A.rareMiniAnchorCache={};A.rareSeen={}
A:UpdateRareMinimap();local owners={};local count=0
for _,p in ipairs(A.rareMiniPins) do if p:IsShown() then owners[p.markerKey]=p;count=count+1 end end
assert(count==2,'show separate fixed source anchors')
playerX=.501;A:UpdateRareMinimap()
for key,p in pairs(owners) do assert(A.rareMiniByKey[key]==p,'stable frame ownership while player moves');assert(p.entry.point[2]==45 or p.entry.point[2]==55,'reference coordinates unchanged') end
cvars.rotateMinimap='1';A:UpdateRareMinimap()
for key,p in pairs(owners) do assert(A.rareMiniByKey[key]==p,'stable ownership on rotation') end
for i=1,30 do playerX=.5+i*.0001;A:UpdateRareMinimap() end
assert(#A.rareMiniPins<=24,'bounded minimap frame pool')
-- Restored separate patches keep real coordinates and reuse a small pool.
A:RenderHabitatArea({{x=30,y=40},{x=70,y=60}},canvas,1,20,'HIGH')
assert(A.habitatAreas[1].point[4]==300 and A.habitatAreas[2].point[4]==700,'separate source patches')
local allocations=#MOCK.frames;A:RenderHabitatArea({{x=30,y=40}},canvas,1,20,'HIGH');assert(#MOCK.frames==allocations,'patch pool reused');assert(not A.habitatAreas[2]:IsShown(),'unused patch hidden')
-- Closing a temporary preview must remove it even when another focus exists.
local render=A.RenderFocus
A.focus=nil;A:RenderHabitatArea({{x=20,y=20}},canvas,1,20,'HIGH');A.tip:Show();A.tip:Hide()
for _,f in ipairs(A.habitatAreas) do assert(not f:IsShown(),'closed preview cleared') end
A.focus={ids={[999501]=true},label='Test rare'};A.habitatPinnedFocus=A.focus;A.RenderFocus=function(self) self:RenderHabitatArea({{x=80,y=80}},canvas,1,20,'HIGH') end
A:RenderHabitatArea({{x=20,y=20}},canvas,1,20,'HIGH');A.tip:Show();A.tip:Hide()
assert(A.habitatAreas[1].point[4]>750,'restore pinned area, never retain temporary preview')
-- A focus is navigation state, not an explicit habitat pin.
A.RenderFocus=render;A.habitatPinnedFocus=nil;A:RenderHabitatArea({{x=20,y=20}},canvas,1,20,'HIGH');A.tip:Show();A.tip:Hide()
for _,f in ipairs(A.habitatAreas) do assert(not f:IsShown(),'un-pinned navigation focus must not restore a closed preview') end
A:RenderHabitatArea({{x=20,y=20}},canvas,1,20,'HIGH');A:Update()
for _,f in ipairs(A.habitatAreas) do assert(not f:IsShown(),'idle update cleans stale region without a preview or explicit pin') end
A.RenderFocus=render;A:ClearFocus(false)
for _,f in ipairs(A.habitatAreas) do assert(not f:IsShown(),'unpin removes glow') end
A.db.rareEnabled=false;A:RareTick();for _,p in ipairs(A.rareMiniPins) do assert(not p:IsShown()) end
A.BuildAtlasIndex=build
print('PASS rares: event detection, no invented positions, classification/dead checks, cooldown, exact/reference separation, minimap scale/rotation, loot+soft habitat, CVars defer/restore, no full indexing')
''')
