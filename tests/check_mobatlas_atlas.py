from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text());l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) return assert(loadstring(s,n))("MobAtlas",ns) end')
for name in ['Data.lua','ClassGear.lua','Forever.lua','Catalog.lua','Expansion.lua','Preparation.lua','Observations.lua','Atlas.lua','Core.lua','Presentation.lua','Locale.lua','UI.lua','DungeonPins.lua','DungeonPins.lua']:load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
l.execute('''
local A=MobAtlas;A:Init()
assert(A:SpecialRank(8499)==50,'pet from client taxonomy')
assert(A:SpecialRank(5191)==20,'unknown live quality retains known baseline rarity')
assert(A:FindItems('ЖЕСТОКАЯ КОЛЮЧКА','all','dungeons')[1]==5191,'Russian case-insensitive dungeon search')
assert(A:FindItems('Cruel Barb','all','dungeons')[1]==5191)
assert(A:FindItems('item:5191','all','all')[1]==5191)
local sources=A:AtlasSources(5191,'dungeons');assert(#sources>0)
local found
for _,s in ipairs(sources) do if s.npcID==639 then found=s end end
assert(found and found.location.kind=='entrance' and found.location.mapID==1436)
assert(#A.mobs[639].points==0,'legacy dungeon alias never becomes a boss position')
assert(A:Chance(found.entry):find('неизвестен',1,true),'do not invent dungeon chance')
A.db.qualities={};A.db.prof=197;A.db.classOnly=true
assert(A:FindItems('5191','all','dungeons')[1]==5191,'atlas independent of map filters')
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);canvas:SetScale(.625)
local mapID=1429
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return mapID end
function WorldMapFrame:SetMapID(id) mapID=id end
function OpenWorldMap() WorldMapFrame:Show() end
A:OpenAtlas('5191');assert(A.atlas.rows[1].itemID==5191)
A.atlas.rows[1].scripts.OnClick(A.atlas.rows[1]);assert(A.atlas.selectedItem==5191 and A.atlas.sourceRows[1].value and A.atlas.rows[1].itemID==5191)
assert(A:FocusSource(5191,639,1436));assert(A.focus.ids[639] and A.focusButton:IsShown())
local cells,total=A:BuildMap(1436);assert(total==1 and #cells>0)
for _,c in ipairs(cells) do assert(c.dungeon==1581 and #c.ids==1 and c.ids[1]==639) end
local pin=A.pins[1];assert(pin:IsShown() and pin.cell.dungeon==1581)
pin.scripts.OnClick(pin,'LeftButton');assert(A.tip.rows[1].itemID==5191);assert(A.tip.unpin:GetText()=='Открепить');A:PinInspection();assert(A.pinned==pin)
A.tip:Hide();A:Update();assert(A.focus and not A.inspectPin,'closing details preserves explicitly pinned tracking');assert(A:FocusSource(5191,639,1436))
canvas:SetScale(2);A:Update();assert(A.focus and math.abs(A.pins[1].point[4]*A.pins[1].scale-canvas:GetWidth()*A.pins[1].cell.x/100)<.001)
A.focusButton.scripts.OnClick();assert(not A.focus and not A.focusButton:IsShown())
MOCK.combat=true;local ok=A:FocusSource(5191,639,1436);assert(ok and A.focus,'source focus works on open combat map');A:ClearFocus();MOCK.combat=false
local ok=A:FocusSource(5191,639,nil);assert(not ok and not A.focus)
-- Deliberate outdoor focus shows every real source position, despite conflicting map filters.
local source=A.itemSources[8499][1];local loc=A:SourceLocations(source.npcID)[1]
assert(loc.kind=='spawn');assert(A:FocusSource(8499,source.npcID,loc.mapID))
local cells,total=A:BuildMap(loc.mapID);assert(total==1 and #cells>0)
for _,c in ipairs(cells) do assert(not c.dungeon and #c.ids==1 and c.ids[1]==source.npcID) end
assert(A.habitatPins[1]:IsShown());A:ClearFocus()
-- A previously unknown drop is saved only against exact loot API source GUIDs.
A:ClearFocus(false);A.db.qualities={[-1]=true,[1]=true,[2]=true,[3]=true};A.db.prof=0;A.db.classOnly=false
function GetNumLootItems() return 2 end
function GetLootSlotLink(slot) return slot==1 and 'item:990001' or 'item:990002' end
function GetLootSourceInfo(slot) if slot==1 then return 'Creature-0-1-2-3-43-00001',1 else return 'GameObject-0-1-2-3-999-00001',1 end end
local fullBuild=A.BuildAtlasIndex;local allMetadata=A.ApplyForeverItems;local replay=A.RestoreLoot
A.BuildAtlasIndex=function() error('Full search rebuild during loot') end;A.ApplyForeverItems=function() error('Full metadata pass during loot') end;A.RestoreLoot=function() error('Full saved history replay during loot') end
A:CaptureLoot();A.BuildAtlasIndex=fullBuild;A.ApplyForeverItems=allMetadata;A.RestoreLoot=replay;assert(A.db.lootFinds[43].items[990001]);assert(not A.items[990002],'object loot cannot be assigned to a mob')
assert(A.itemSources[990001] and A:SourceEntry(A.itemSources[990001][1])[2]==8)
local n=#A.mobs[43].loot;A:CaptureLoot();assert(#A.mobs[43].loot==n,'reopened loot window does not duplicate links')
assert(A:Chance({990001,8,-1}):find('неизвестен',1,true),'one personal find never produces a drop rate')
function GetLootSourceInfo() error('source inaccessible') end
A:CaptureLoot();assert(#A.mobs[43].loot==n,'inaccessible API never uses target fallback')
-- Direct map action, bounded recents and safe Shift-link search.
A:ClearFocus(false);A:OpenAtlas('5191');assert(A.atlas.rows[1].mapButton:IsShown())
A.atlas.rows[1].mapButton.scripts.OnClick();assert(A.atlas.selectedItem==5191 and A.atlas.sourceRows[1].value);A.atlas.sourceRows[1].map.scripts.OnClick();assert(A.focus.itemID==5191)
A:RememberItem(8499);A:RememberItem(5191);assert(A.db.recentItems[1]==5191 and A.db.recentItems[2]==8499)
A:OpenAtlas('');A.atlas.scope='recent';A.atlas.results=nil;A:RefreshAtlas();assert(A.atlas.showingRecent and A.atlas.rows[1].itemID==5191)
A.atlas.allItems.scripts.OnClick();assert(not A.atlas.showingRecent and #A.atlas.results>12)
local hooked
function ChatEdit_InsertLink() end
function hooksecurefunc(name,fn) assert(name=='ChatEdit_InsertLink');hooked=fn end
getmetatable(UIParent).__index.HasFocus=function(f) return f.focus end
A:HookItemSearch();A.atlas.search:SetFocus();hooked('|cff0070dd|Hitem:5191:0|h[Cruel Barb]|h|r')
assert(A.atlas.search:GetText()=='5191' and A.atlas.rows[1].itemID==5191)
A.atlas.search:ClearFocus();hooked('item:8499');assert(A.atlas.search:GetText()=='5191','link hook ignores unfocused search')
-- Actual clients expose C_Map.OpenWorldMap, not necessarily a global OpenWorldMap.
MOCK.playerLevel=18;OpenWorldMap=nil;WorldMapFrame:Hide()
C_Map={OpenWorldMap=function(id) WorldMapFrame:Show();mapID=id end}
assert(A:ShowQuestOnMap(167) and WorldMapFrame:IsShown() and mapID==1453)
A:ClearFocus(false);C_Map=nil;WorldMapFrame:Hide()
function ShowUIPanel(f) f:Show() end
assert(A:ShowQuestOnMap(167) and WorldMapFrame:IsShown(),'UI panel fallback opens a hidden map')
A:UnpinQuest();ShowUIPanel=nil;WorldMapFrame:Hide();assert(not A:ShowQuestOnMap(167),'failed open must not report success')
function OpenWorldMap() WorldMapFrame:Show() end
A:ClearFocus(false);A.atlas=nil;A:OpenAtlas();assert(A.atlas.category=='gear' and A.atlas.myLevel and A.atlas.knownOnly)
for _,iid in ipairs(A.atlas.results) do local item=A.items[iid];assert((item.classID==2 or item.classID==4) and (item.level or 0)<=UnitLevel('player') and A:HasKnownSource(iid)) end
A.atlas.categoryButton.scripts.OnClick();assert(A.atlas.categoryMenu:IsShown(),'explicit category chooser')
A.atlas.scopeButton.scripts.OnClick();assert(A.atlas.scopeMenu:IsShown() and not A.atlas.categoryMenu:IsShown())
A.atlas.allItems.scripts.OnClick();assert(A.atlas.category=='all' and not A.atlas.myLevel and not A.atlas.knownOnly)
assert(A:ShowQuestOnMap(167));A:OpenAtlas();assert(A.atlas.clearFocus:IsShown());A.atlas.clearFocus.scripts.OnClick();assert(not A.focus)
-- Exact Forever report beats the Classic shared-pool link for the same NPC.
MOCK.class='PRIEST';MOCK.playerLevel=26;A.db.classOnly=true;A.db.specOnly=true;A:RefreshGearProfile()
A.db.qualities={[3]=true};A.db.sharedLoot=false;A.db.prof=0
assert(not A:ClassFits(A.items[12992],12992))
assert(A:FindItems('Огненный клинок','all','all',nil,{level=true,known=true})[1]==12992)
assert(A:FindItems('12992','gear','all')[1]==nil)
local card=A:FocusedLoot(628);assert(card[1][1]==12992 and card[1][2]==14 and card[1][3]==-1)
local sources=A:AtlasSources(12992,'all')
assert(sources[1].npcID==628 and sources[1].location.mapID==1431 and sources[1].entry[2]==14)
local shared
for _,source in ipairs(A.itemSources[12992]) do
 if source.npcID==628 then for _,entry in ipairs(source.entries) do if entry[2]==1 and entry[4] then shared=entry end end end
end
assert(shared and A:Chance(shared):find('Classic',1,true) and shared[3]==-1)
A.db.sharedLoot=true;A.db.classOnly=false;A.db.specOnly=false
A.mobs[999911]={loot={shared}};assert(not A:HasSpecialMapLoot(999911))
A.mobs[999911]=nil
A:OpenAtlas();A.atlas.category='gear';A.atlas.search:SetText('12992');A.atlas.search.scripts.OnEnterPressed(A.atlas.search)
assert(A.atlas.category=='all' and A.atlas.rows[1].itemID==12992)
print('PASS atlas: RU/EN/ID, dungeon sources/entrances, pet/rare ranking, unknown rates, filtered search, item focus, zoom, reset, combat guard')
''')
