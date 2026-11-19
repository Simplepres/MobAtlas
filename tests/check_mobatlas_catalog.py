from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text());l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
ns=l.table();load=l.eval('function(s,n,ns) return assert(loadstring(s,n))("MobAtlas",ns) end')
for f in ['Data.lua','ClassGear.lua','Forever.lua','Catalog.lua','Expansion.lua','Preparation.lua','Observations.lua','Atlas.lua','Core.lua','Presentation.lua','Locale.lua','UI.lua']:load((r/'MobAtlas'/f).read_text(),'@'+f,ns)
l.execute('''
local A=MobAtlas;A:Init();A.db.vendorRelevant=false
-- The old rectangle choice assigned these NPCs to the wrong map.
for _,p in ipairs(A.mobs[3].points) do assert(p[1]==1431) end
for _,p in ipairs(A.mobs[6].points) do assert(p[1]==1429) end
for _,p in ipairs(A.mobs[36].points) do assert(p[1]==1436) end
for _,mapID in ipairs({1429,1436}) do
 local cells=A:BuildMap(mapID)
 for _,cell in ipairs(cells) do for _,id in ipairs(cell.ids) do assert(id~=3,'Flesh Eater must not leak onto Elwynn/Westfall') end end
end
-- Stock is not presented as a drop chance. Reference vendors have no invented prices.
local vendorCount=0
for id,mob in pairs(A.mobs) do if mob.vendor then
 vendorCount=vendorCount+1;for _,e in ipairs(mob.stock) do assert(e[2]==5 and e[3]==-1) end
end end
assert(vendorCount>500)
A.db.mapLayer='vendors';local vendors=A:BuildMap(1429);assert(#vendors>0)
for _,cell in ipairs(vendors) do for _,id in ipairs(cell.ids) do assert(A.mobs[id].vendor) end end
A.db.mapLayer='mobs';local mobs=A:BuildMap(1429);assert(#mobs>0)
for _,cell in ipairs(mobs) do for _,id in ipairs(cell.ids) do assert(not A.mobs[id].vendor) end end
local direct=#A:Loot(95);A.db.sharedLoot=true;local broad=#A:Loot(95)
assert(broad>direct);print('Defias Smuggler: '..direct..' main unique items / '..broad..' including shared loot')
local seen={};for _,e in ipairs(A:Loot(95)) do assert(not seen[e[1]]);seen[e[1]]=true end
A.db.sharedLoot=false
-- Prefer an observation without adding two chances or mutating source rows.
A.items[999]={name='Test',quality=2,classID=4,subclass=2,level=1,prof={}}
A.mobs[999]={name='Test NPC',min=1,max=1,points={},loot={{999,1,80,false},{999,4,20,false,2,10,3}}}
local result=A:Loot(999);assert(#result==1 and result[1][3]==20 and #result[1].alternatives==2)
assert(#A.mobs[999].loot[1]==4)
-- Modern Forever merchant API; only NPC interaction, no target or player-position guessing.
function UnitGUID(unit) if unit=='npc' then return 'Creature-0-1-2-3-999-0001' end end
function GetMerchantNumItems() return 1 end
function GetMerchantItemLink() return 'item:999' end
C_MerchantFrame={GetItemInfo=function() return {name='Test',price=1200,stackCount=2,numAvailable=4,hasExtendedCost=false} end}
local full=A.BuildAtlasIndex;A.BuildAtlasIndex=function() error('full rebuild in merchant event') end;A:CaptureMerchant();A.BuildAtlasIndex=full;assert(A.db.merchants[999] and A.mobs[999].vendor)
result=A:Loot(999);assert(#result==1 and result[1][2]==6 and result[1][5]==1200 and result[1][6]==2)
assert(not A:Chance(result[1]):find('%%') and #A.mobs[999].points==0)
function GetMerchantItemLink() return nil end
A:CaptureMerchant();assert(A.db.merchants[999].stock[1][5]==1200,'incomplete cache cannot erase known inventory')
function GetMerchantItemLink() return 'item:999' end
C_MerchantFrame.GetItemInfo=function() return {price=0,stackCount=1,numAvailable=1,hasExtendedCost=true} end
A:CaptureMerchant();assert(A:Loot(999)[1][8]);assert(A:Chance(A:Loot(999)[1]):find('Особая',1,true))
A.items[999].level=60;assert(#A:Loot(999)==0);A.db.vendorLevel=false;assert(#A:Loot(999)==1)
local cells={{x=20,y=30,ids={6}},{x=20.1,y=30.1,ids={36}}}
local grouped=A:CompactPoints(cells,1000,800);assert(#grouped==1 and #grouped[1].ids==2 and grouped[1].x==20,'group preserves NPC IDs and a real point')
-- Separate camps stay separate even when connected by a long chain of spawn points.
local chain={};for x=10,90,5 do chain[#chain+1]={x=x,y=30,ids={6}} end
assert(#A:CompactPoints(chain,1000,800)>5,'no single-link chaining across the map')
A.db.vendorLevel=true;A.db.mapLayer='all'
for _,mapID in ipairs({1429,1436}) do
 local raw=A:BuildMap(mapID);local groups=A:CompactPoints(raw,1000,700)
 local input,output={},{};for _,c in ipairs(raw) do for _,id in ipairs(c.ids) do input[id]=true end end
 for _,c in ipairs(groups) do for _,id in ipairs(c.ids) do output[id]=true end end
 for id in pairs(input) do assert(output[id],'grouping lost NPC') end
 assert(#groups<#raw/4,'regional grouping must materially reduce map clutter')
 print('Map '..mapID..': '..#raw..' positions -> '..#groups..' groups')
end
-- Group hover is a selectable NPC list, not the first member masquerading as the whole group.
A.settings:Hide();local testPin=CreateFrame('Button');testPin.dot=testPin:CreateTexture();testPin.cell={ids={6,36},locations=5};testPin.page=1
A.pinned=testPin;A:ShowTooltip(testPin,true);assert(A.tip.rows[1].npcID==6 and not A.tip.rows[1].itemID)
A.tip.rows[1].scripts.OnClick(A.tip.rows[1]);assert(testPin.selected and A.tip.rows[1].itemID and not A.tip.rows[1].npcID)
A.tip.mobNext.scripts.OnClick();assert(not testPin.selected and A.tip.rows[1].npcID)

A:ClearFocus(false)
-- Smart vendor recommendations are independent of the optional general class filter.
A.db.vendorRelevant=true;A.db.vendorLevel=true;A.db.classOnly=false;MOCK.playerLevel=18
local leather={classID=4,subclass=2,quality=2,level=16,prof={}}
assert(A:VendorRelevant(leather,999,{}))
leather.subclass=1;assert(not A:VendorRelevant(leather,999,{}),'do not recommend cloth to rogue')
leather.subclass=4;assert(not A:VendorRelevant(leather,999,{}),'do not recommend plate to rogue')
leather.subclass=2;leather.level=25;assert(not A:VendorRelevant(leather,999,{}))
leather.level=1;assert(not A:VendorRelevant(leather,999,{}),'outgrown items hidden')
assert(A:VendorRelevant({classID=1,subclass=0,level=0},999,{}),'regular bags')
assert(not A:VendorRelevant({classID=1,subclass=1,level=0},999,{}),'rogue does not need soul bags')
assert(not A:VendorRelevant({classID=7,level=0,prof={197}},999,{}))
assert(A:VendorRelevant({classID=7,level=0,prof={197}},999,{[197]=true}))
A.db.mapLayer='vendors';A.db.vendorRelevant=false;local all=A:BuildMap(1453)
A.db.vendorRelevant=true;local useful=A:BuildMap(1453);assert(#useful>0 and #useful<#all)
print('Stormwind vendor positions, level 18 rogue: '..#all..' -> '..#useful)
-- Expanding hides other groups; only the chosen NPCs remain on the current zone.
local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);canvas:SetScale(.625)
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return 1429 end
WorldMapFrame:Show()
A.mobs[900001]={name='Focus A',min=1,max=2,points={{1429,20,30},{1429,21,30}},loot={{999,1,10,false}}}
A.mobs[900002]={name='Focus B',min=1,max=2,points={{1429,22,30}},loot={{999,1,10,false}}}
A.zoneIndex[1429]={900001,900002};A.db.mapLayer='all'
local p=CreateFrame('Button');p.dot=p:CreateTexture();p.cell={x=20,y=30,vendor=false,ids={900001,900002}};p.page=1
local other=CreateFrame('Button');A.pins={p,other};A.pinned=p
A:ShowTooltip(p,true);assert(A.habitatPins[2]:IsShown() and not other:IsShown())
assert(not A.tip.rows[1].rarityBorder:IsShown(),'NPC rows have no item rarity')
A.tip.rows[1].scripts.OnClick(A.tip.rows[1]);assert(A.habitatPins[1].npcID==900001)
assert(A.tip.rows[1].rarityBorder:IsShown(),'item rarity frame shown')
local point=A.habitatPins[1];assert(math.abs(point.point[4]*point.scale-200)<.001,'habitat coordinates under scale')
A.tip.mobNext.scripts.OnClick();assert(A.habitatPins[2]:IsShown(),'back restores selected group')
A.lastMap=1429;A.lastCanvas=canvas;A.dirty=false;canvas:SetScale(2);A:Update()
assert(A.pinned==p and A.habitatPins[2]:IsShown(),'zoom keeps selected habitat')
A.tip.close.scripts.OnClick();assert(A.focus and not A.pinned,'map tracking stays until explicit unpin')
A:ClearFocus(false);assert(not A.focus and not A.habitatPins[1]:IsShown(),'explicit reset clears focus')

print('PASS zone ownership, vendor layers, reference/observed prices, merchant caching, level filter, no loot duplicates, compact groups')
''')
