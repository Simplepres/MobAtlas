from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end');a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();local canvas=CreateFrame('Frame');canvas:SetSize(1000,700);local mapID=1436;function WorldMapFrame:GetCanvas() return canvas end;function WorldMapFrame:GetMapID() return mapID end;function WorldMapFrame:SetMapID(id) mapID=id end;function OpenWorldMap() WorldMapFrame:Show() end;A:OpenAtlas('5191');local f=A.atlas
assert(f:GetWidth()==880 and f:GetHeight()==660 and f.sourceTitle,'book spread layout')
local page=f.page;assert(f.rows[1].itemID==5191);f.rows[1].scripts.OnClick(f.rows[1])
assert(f.selectedItem==5191 and f.rows[1].itemID==5191 and f.page==page,'select item preserves left list/page')
assert(f.sourceRows[1].value and f.sourceRows[1]:IsShown(),'right source pane populated')
local previous;local seen={}
for _,source in ipairs(f.sourceCache) do if source.group~=previous then assert(not seen[source.group],'zone groups must be contiguous');seen[source.group]=true;previous=source.group end end
local found;for _,row in ipairs(f.sourceRows) do if row.value and row.value.location.mapID then found=row;break end end
assert(found,'known map source');found.scripts.OnClick(found);assert(f.previewSource==found.value and f.mapPreview.sourcePointCount>0,'source row previews exact points');found.map.scripts.OnClick();assert(A.focus and A.habitatPinnedFocus==A.focus,'world map action explicitly pins source')
f.sourceReset.scripts.OnClick();assert(not f.selectedItem and f.rows[1].itemID==5191,'clear selection does not erase item list')
-- Native art layout and points are independent of the world map state.
local selectedMap=mapID
C_Map=C_Map or {};C_Map.GetMapArtLayers=function() return {{layerWidth=600,layerHeight=400,tileWidth=256,tileHeight=256}} end
C_Map.GetMapArtLayerTextures=function() return {101,102,103,104,105,106} end
A.mobs[999919]={points={{1429,25,50}},name='Preview test'}
local preview={npcID=999919,location={mapID=1429,name='Test zone',kind='spawn'}}
A:PreviewAtlasSource(preview);assert(mapID==selectedMap,'mini preview never changes world map')
assert(f.mapPreview.hasArt and f.mapPreview.drawnTiles>0 and f.mapPreview.drawnTiles<=6,'native tiles drawn')
local pin=f.mapPreview.pins[1];assert(pin.sourceX==25 and pin.sourceY==50,'pins use NPC source coordinates')
local t=f.mapPreview.transform;assert(math.abs(pin.point[4]-(t.x+t.rw*.25))<.001,'zoomed map projection');for _,tile in ipairs(f.mapPreview.tiles) do if tile:IsShown() then assert(tile.point[4]>=0 and tile.point[4]+tile.width<=408.001 and -tile.point[5]+tile.height<=f.mapPreview:GetHeight()+.001,'tiles cropped to viewport') end end
C_Map.GetMapArtID=function() return 999999 end
A.mapReveal[999999]={{600,400,0,0,201,202,203,204,205,206}}
local methods=getmetatable(UIParent).__index;local oldTexture=methods.SetTexture;methods.SetTexture=function(t,file) t.file=file end
A:PreviewAtlasSource(preview);assert(f.mapPreview.fullReveal,'full reveal independent of explored flags')
local overlay=false;for _,tile in ipairs(f.mapPreview.tiles) do if tile:IsShown() then if type(tile.file)=='number' and tile.file>=201 then overlay=true end;assert(tile.point[4]>=0 and tile.point[4]+tile.width<=408.001,'revealed tiles do not overflow') end end
assert(overlay,'overlay artwork fills unexplored map regions');methods.SetTexture=oldTexture
-- A known source without coordinates is excluded by the map-location checkbox.
A.items[999918]={name='Unlocated test',classID=4,subclass=2,level=18,quality=2};A.mobs[999917]={name='Unlocated source',points={},instances={},loot={{999918,7,-1,false}}};A:IndexLootEntry(999917,A.mobs[999917].loot[1])
assert(A:HasKnownSource(999918) and not A:HasMappableSource(999918),'known association does not imply coordinates')
assert(#A:FindItems('999918','all','all',nil,{known=true})==0,'location-only filter excludes unlocated source')
-- Client required level overrides stale catalog data, without scanning unrelated items.
A.items[999910]={name='Cached test',classID=4,subclass=2,level=17,quality=2}
MOCK.items[999910]={loc='INVTYPE_CHEST',level=19,class=4,subclass=2}
assert(A:HydrateAtlasItem(999910) and A.items[999910].level==19,'hydrate actual required level')
MOCK.playerLevel=18;assert(not A:AtlasLevelFits(A.items[999910]),'updated required level is respected')
local requests={};C_Item.RequestLoadItemDataByID=function(id) requests[#requests+1]=id end
A.atlasRequested={};A.atlasRequestQueue={};A.atlasRequestPump=nil
for i=1,10 do A.items[999920+i]={classID=4,subclass=2};A:HydrateAtlasItem(999920+i) end
assert(#requests==0 and #A.atlasRequestQueue==10,'metadata requests are queued, not sent during rendering')
MOCK.timers[#MOCK.timers]();assert(#requests==4,'four metadata requests per tick')
MOCK.timers[#MOCK.timers]();assert(#requests==8,'bounded second batch')
MOCK.timers[#MOCK.timers]();assert(#requests==10 and not A.atlasRequestPump,'queue terminates')
A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999930,false);assert(A.atlasLoadFailures[999930],'modern load failure recorded');A.events.scripts.OnEvent(A.events,'ITEM_DATA_LOAD_RESULT',999930,true);assert(not A.atlasLoadFailures[999930],'modern load success clears failure')
print('PASS book atlas: persistent left list, right source grouping/map, clear selection, real required level, bounded lazy metadata loading')
''')
