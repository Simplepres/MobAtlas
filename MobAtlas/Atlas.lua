local _,A=...
-- A searchable reverse index. Entries retain their source; unknown is never a measured 0%.
local upper={'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'}
local lower={'а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'}
function A:SearchText(text)
 text=(text or ''):gsub('[A-Z]',function(c)return string.char(c:byte()+32) end);for i,c in ipairs(upper) do text=text:gsub(c,lower[i]) end
 return text:gsub('ё','е'):gsub('^[ \t\r\n]+',''):gsub('[ \t\r\n]+$','')
end
function A:SpecialRank(id)
 local item=self.items[id];if not item then return 0 end
 if item.classID==15 and item.subclass==2 then return 50,'Питомец' end
 if item.quality==5 then return 40,'Легендарное' end
 if item.quality==4 then return 30,'Эпическое' end
 if item.quality==3 then return 20,'Редкое' end
 return 0
end
function A:BuildAtlasIndex()
 self.itemSources={};self.searchTerms={};self.entranceIndex={};self.mappableItems={}
 for id,mob in pairs(self.mobs) do
  local seen={}
  for _,list in ipairs({mob.loot or {},mob.stock or {}}) do for _,e in ipairs(list) do
   if self.items[e[1]] then
    local entry=seen[e[1]]
    if not entry then entry={npcID=id,entries={}};seen[e[1]]=entry;local sources=self.itemSources[e[1]] or {};self.itemSources[e[1]]=sources;sources[#sources+1]=entry end
    entry.entries[#entry.entries+1]=e
   end
  end end
  for _,area in ipairs(mob.instances or {}) do
   local dungeon=(self.instances or {})[area]
   for _,p in ipairs(dungeon and dungeon.entrances or {}) do
    local list=self.entranceIndex[p[1]] or {};self.entranceIndex[p[1]]=list
    list[#list+1]={npcID=id,x=p[2],y=p[3],area=area}
   end
  end
 end
 for iid,item in pairs(self.items) do self.itemSources[iid]=self.itemSources[iid] or {};local item=self.items[iid];self.searchTerms[iid]=self:SearchText(item.name..' '..(item.ruName or '')) end
end
function A:SourceEntry(source)
 local best,rank
 for _,e in ipairs(source.entries) do
  local value=e[2]==8 and 6 or e[2]==4 and 5 or e[2]==6 and 4 or e[2]==7 and 3 or e[4] and 0 or 2
  if not best or value>rank then best=e;rank=value end
 end
 return best
end
function A:MapName(id)
 local info=self:Safe(C_Map and C_Map.GetMapInfo,id)
 return info and info.name or (self.mapNames or {})[id] or ('Карта #'..id)
end
function A:SourceLocations(id)
 local mob=self.mobs[id];local result,seen={},{}
 for _,p in ipairs(mob.points or {}) do if not seen[p[1]] then seen[p[1]]=true;result[#result+1]={mapID=p[1],name=self:MapName(p[1]),kind='spawn'} end end
 for _,area in ipairs(mob.instances or {}) do
  local instance=(self.instances or {})[area]
  if instance then
   local maps={};for _,p in ipairs(instance.entrances) do if not maps[p[1]] then maps[p[1]]=true;result[#result+1]={mapID=p[1],name=instance.name,kind='entrance',area=area} end end
  end
 end
 if #result==0 then result[1]={name='Место пока неизвестно',kind='unknown'} end
 return result
end
function A:FindItems(query,category,scope,relevant,options)
 options=options or {};local recent={};if options.recent then for _,id in ipairs(self.db.recentItems or {}) do recent[id]=true end end
 query=self:SearchText(query);local exact=tonumber(query) or tonumber(query:match('item:(%d+)'));local results={}
 for iid,sources in pairs(self.itemSources or {}) do
  local item=self.items[iid];local rank=self:SpecialRank(iid)
  local matches=(exact and iid==exact) or (not exact and (query=='' or self.searchTerms[iid]:find(query,1,true)))
  matches=matches and (not category or category=='all' or category=='pets' and rank==50 or category=='rare' and item.quality==3 or category=='epic' and item.quality>=4 and item.quality<=5 or category=='useful' and self:UsefulItem(iid) or category=='gear' and (item.classID==2 or item.classID==4) or category=='bags' and item.classID==1 or category=='materials' and item.classID==7 or category=='recipes' and item.classID==9 or category=='consumables' and item.classID==0)
  if options.known and not self:HasKnownSource(iid) then matches=false end
  if options.recent and not recent[iid] then matches=false end
  if options.level and not self:AtlasLevelFits(item) then matches=false end
  if relevant then matches=matches and self:ClassFits(item,iid,true) and (item.level==nil or item.level<=UnitLevel('player')) end
  if matches and scope and scope~='all' and scope~='recent' then
   matches=false
   for _,source in ipairs(sources) do
    local mob=self.mobs[source.npcID]
    if scope=='dungeons' and #(mob.instances or {})>0 or scope=='world' and #(mob.points or {})>0 then matches=true;break end
   end
   if not matches and (scope=='world' or scope=='dungeons') then
    for _,source in ipairs((self.otherSources or {})[iid] or {}) do
     if scope=='dungeons' then
      local quest=source.kind=='quest' and (self.dungeonQuests or {})[source.id];if quest and #quest.dungeons>0 then matches=true end
     else
      if #(source.points or {})>0 then matches=true;break end
      for _,giver in ipairs(source.givers or {}) do if #(giver.points or {})>0 then matches=true;break end end
     end
     if matches then break end
    end
   end
  end
  if matches then results[#results+1]=iid end
 end
 table.sort(results,function(a,b)
  local ai,bi=self.items[a],self.items[b]
  local ak,bk=self:HasKnownSource(a),self:HasKnownSource(b);if ak~=bk then return ak end
  if category=='all' or category=='gear' or category=='useful' then
   local ag,bg=(ai.classID==2 or ai.classID==4),(bi.classID==2 or bi.classID==4);if ag~=bg then return ag end
   local ad,bd=math.abs((ai.level or 0)-UnitLevel('player')),math.abs((bi.level or 0)-UnitLevel('player'));if ad~=bd then return ad<bd end
  end;if (category=='gear' or category=='useful' or category=='rare' or category=='epic') and ai.quality~=bi.quality then return ai.quality>bi.quality end
  if ai.name~=bi.name then return ai.name<bi.name end;return a<b
 end)
 return results
end
function A:AtlasSources(iid,scope)
 if scope=='recent' then scope='all' end
 local rows={}
 for _,source in ipairs(self.itemSources[iid] or {}) do
  for _,loc in ipairs(self:SourceLocations(source.npcID)) do
   if not scope or scope=='all' or scope=='dungeons' and loc.kind=='entrance' or scope=='world' and loc.kind=='spawn' then
    rows[#rows+1]={npcID=source.npcID,entry=self:SourceEntry(source),location=loc}
   end
  end
 end
 for _,source in ipairs((self.otherSources or {})[iid] or {}) do
  local kind=source.kind;local points={}
  if kind=='quest' then for _,giver in ipairs(source.givers or {}) do for _,p in ipairs(giver.points or {}) do points[#points+1]=p end end
  elseif kind=='object' then points=source.points or {} end
  local byMap={};for _,p in ipairs(points) do byMap[p[1]]=byMap[p[1]] or {};table.insert(byMap[p[1]],p) end
  if not next(byMap) then byMap[0]={} end
  for mapID,coords in pairs(byMap) do
   local quest=source.kind=='quest' and (self.dungeonQuests or {})[source.id]
   if not scope or scope=='all' or scope=='world' and mapID>0 or scope=='dungeons' and quest and #quest.dungeons>0 then
    rows[#rows+1]={source=source,entry={iid,({quest=10,crafted=11,object=12,container=13})[kind],source.chance or -1,false},location={mapID=mapID>0 and mapID or nil,name=mapID>0 and self:MapName(mapID) or source.zone~='' and source.zone or 'Место пока неизвестно',kind=kind,points=coords}}
   end
  end
 end
 table.sort(rows,function(a,b)
  if (a.location.mapID~=nil)~=(b.location.mapID~=nil) then return a.location.mapID~=nil end
  if (a.entry[2]==4)~=(b.entry[2]==4) then return a.entry[2]==4 end
  if a.entry[3]~=b.entry[3] then return a.entry[3]>b.entry[3] end
  if (a.npcID or 0)~=(b.npcID or 0) then return (a.npcID or 0)<(b.npcID or 0) end
  if a.source and b.source and a.source.id~=b.source.id then return a.source.id<b.source.id end
  return (a.location.mapID or 0)<(b.location.mapID or 0)
 end)
 return rows
end
function A:ClearFocus(refresh)
 self.focus=nil;self.focusGroup=nil;self.pinned=nil;self.inspectPin=nil;self.hoverPin=nil;self:ClearHabitat()
 if self.tip then self.tip:Hide() end
 if self.focusButton then self.focusButton:Hide() end
 if self.atlas and self.atlas.clearFocus then self.atlas.clearFocus:Hide() end
 self.dirty=true;if refresh~=false then self:Update() end
end
function A:FocusSource(iid,npcID,mapID)
 if not mapID then return false,'Источник известен, но координат пока нет.' end
 local ids={}
 for _,source in ipairs(self.itemSources[iid] or {}) do if not npcID or source.npcID==npcID then ids[source.npcID]=true end end
 if not next(ids) then return false,'Источник не найден.' end
 local opened,reason=self:OpenMapAt(mapID);if not opened then return false,reason end
 self:ClearFocus(false)
 self.focus={ids=ids,itemID=iid,label=self:ItemDisplay(iid)}
 if self.settings then self.settings:Hide() end

 if self.atlas then self.atlas:Hide() end
 self.db.enabled=true;self.dirty=true;self:Update();return true
end
-- Filters apply to browsing. A deliberate item/source selection is visible even if filters exclude it.
function A:FocusedLoot(id)
 if self.focus and self.focus.itemID then
  for _,source in ipairs(self.itemSources[self.focus.itemID] or {}) do if source.npcID==id then
   local e=self:SourceEntry(source);local copy={};for i=1,8 do copy[i]=e[i] end;copy.alternatives=source.entries;return {copy}
  end end
 end
 return self:Loot(id,self.skills)
end

function A:RememberItem(iid)
 self.db.recentItems=type(self.db.recentItems)=='table' and self.db.recentItems or {}
 local recent={iid};for _,id in ipairs(self.db.recentItems) do if id~=iid and self.itemSources[id] and #recent<12 then recent[#recent+1]=id end end
 self.db.recentItems=recent
end
function A:ShowItemOnMap(iid)
 local rows=self:AtlasSources(iid,'all');local map=WorldMapFrame;local current=map and map.GetMapID and map:GetMapID();local best
 for _,row in ipairs(rows) do if row.location.mapID then best=best or row.location.mapID;if row.location.mapID==current then best=current;break end end end
 if not best then return false,#rows>0 and 'Источник известен, координаты пока нет. Открой список источников.' or 'Предмет есть в каталоге, источник пока неизвестен.' end
 if not map or not map.SetMapID then return false,'Карта сейчас недоступна.' end
 local opened,reason=self:OpenMapAt(best);if not opened then return false,reason end
 self:ClearFocus(false);local ids,points={},{}
 for _,row in ipairs(rows) do
  if row.npcID then ids[row.npcID]=true end
  for _,p in ipairs(row.location.points or {}) do points[#points+1]=p end
 end
 self.focus={ids=ids,points=points,itemID=iid,label=self:ItemDisplay(iid),kind='source'}
 self.settings:Hide();if self.atlas then self.atlas:Hide() end
 self.db.enabled=true;self.dirty=true;self:RememberItem(iid);self:Update();return true
end
function A:FocusAtlasSource(iid,row)
 if row.npcID then return self:FocusSource(iid,row.npcID,row.location.mapID) end
 if row.source.kind=='quest' and (self.dungeonQuests or {})[row.source.id] then return self:ShowQuestOnMap(row.source.id) end
 return self:FocusLocation(row.location.points,row.source.name,nil,row.source.kind)
end
function A:HookItemSearch()
 if self.searchHooked or not hooksecurefunc or type(ChatEdit_InsertLink)~='function' then return end
 self.searchHooked=true
 hooksecurefunc('ChatEdit_InsertLink',function(link)
  local f=self.atlas
  if not f or not f:IsShown() or not f.search:HasFocus() or type(link)~='string' then return end
  local id=tonumber(link:match('item:(%d+)'));if not id then return end
  f.category='all';f.scope='all';f.selectedItem=nil;f.results=nil;f.page=1;f.search:SetText(tostring(id));self:RefreshAtlas()
 end)
end

function A:OpenMapAt(mapID)
 -- Our map markers are ordinary UI. Only Blizzard panel operations need combat care.
 if InCombatLockdown() then
  local map=WorldMapFrame
  if not map or not map:IsShown() then return false,'В бою открой карту клавишей M и повтори.' end
  if map.GetMapID and map:GetMapID()==mapID then return true end
  if not map.SetMapID or (map.IsProtected and map:IsProtected()) then return false,'В бою выбери нужную зону на карте вручную.' end
  local ok=pcall(map.SetMapID,map,mapID)
  if not ok then return false,'В бою выбери нужную зону на карте вручную.' end
  return true
 end
 if C_Map and C_Map.OpenWorldMap then self:Safe(C_Map.OpenWorldMap,mapID) end
 local map=WorldMapFrame
 if not map then self:Safe(C_AddOns and C_AddOns.LoadAddOn or LoadAddOn,'Blizzard_WorldMap');map=WorldMapFrame end
 if not map then return false,'Не удалось загрузить карту.' end
 if not map:IsShown() then
  if ShowUIPanel then self:Safe(ShowUIPanel,map) elseif OpenWorldMap then self:Safe(OpenWorldMap) elseif ToggleWorldMap then self:Safe(ToggleWorldMap) end
 end
 if not map:IsShown() or not map.SetMapID then return false,'Карта не открылась. Открой её клавишей M и повтори.' end
 local ok=pcall(map.SetMapID,map,mapID);if not ok then return false,'Не удалось выбрать карту.' end
 return true
end
function A:HasKnownSource(iid)
 return #((self.itemSources or {})[iid] or {})+#((self.otherSources or {})[iid] or {})>0
end
function A:AtlasLevelFits(item)
 if (item.level or 0)>UnitLevel('player') then return false end
 if item.classID==2 or item.classID==4 then
  if not self:ClassFits(item,0,true) then return false end
  return (item.level or 0)>=math.max(0,UnitLevel('player')-10)
 end
 return true
end
function A:HasMappableSource(iid)
 self.mappableItems=self.mappableItems or {}
 if self.mappableItems[iid]~=nil then return self.mappableItems[iid] end
 local result=false
 for _,s in ipairs(self.itemSources[iid] or {}) do local m=self.mobs[s.npcID];if #(m.points or {})>0 then result=true;break end
  for _,area in ipairs(m.instances or {}) do if #((self.instances[area] or {}).entrances or {})>0 then result=true;break end end
 end
 if not result then for _,s in ipairs((self.otherSources or {})[iid] or {}) do
  if #(s.points or {})>0 then result=true;break end
  for _,g in ipairs(s.givers or {}) do if #(g.points or {})>0 then result=true;break end end
  if result then break end
 end end
 self.mappableItems[iid]=result;return result
end

-- Point updates are used by gameplay events; the full index is built only at login.
function A:IndexLootEntry(npcID,entry)
 local iid=entry[1];self.itemSources=self.itemSources or {};local sources=self.itemSources[iid] or {};self.itemSources[iid]=sources
 local source
 for _,s in ipairs(sources) do if s.npcID==npcID then source=s;break end end
 if not source then source={npcID=npcID,entries={}};sources[#sources+1]=source end
 for _,e in ipairs(source.entries) do if e==entry then return end end
 source.entries[#source.entries+1]=entry
 local item=self.items[iid];self.searchTerms[iid]=self:SearchText(item.name..' '..(item.ruName or ''))
 self.mappableItems[iid]=nil
end

function A:RefreshNpcIndex(npcID,oldIDs)
 for iid in pairs(oldIDs or {}) do
  local sources=self.itemSources[iid] or {}
  for i=#sources,1,-1 do if sources[i].npcID==npcID then table.remove(sources,i) end end
  self.mappableItems[iid]=nil
 end
 local mob=self.mobs[npcID]
 for _,entries in ipairs({mob.loot or {},mob.stock or {}}) do for _,e in ipairs(entries) do self:IndexLootEntry(npcID,e) end end
end
