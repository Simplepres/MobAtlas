local _,A=...
-- A searchable reverse index. Entries retain their source; unknown is never a measured 0%.
local upper={'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'}
local lower={'а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'}
local foldRussian={['ё']='е'}
for i,c in ipairs(upper) do foldRussian[c]=c=='Ё' and 'е' or lower[i] end
function A:SearchText(text)
 text=(text or ''):gsub('[A-Z]',string.lower):gsub('[\208\209][\128-\191]',foldRussian)
 return text:gsub('^[ \t\r\n]+',''):gsub('[ \t\r\n]+$','')
end
-- Shared crafting writs remain in the full catalog.
local craftingWrits={[22568]=true,[248206]=true,[262887]=true,[262888]=true,[262889]=true,[262890]=true}
function A:SpecialRank(id)
 if craftingWrits[id] then return 0 end
 local item=self.items[id];if not item then return 0 end
 if item.classID==15 and item.subclass==2 then return 50,'Питомец' end
 if item.quality==6 then return 42,'Артефакт' end
 if item.quality==7 then return 41,'Наследуемое' end
 if item.quality==5 then return 40,'Легендарное' end
 if item.quality==4 then return 30,'Эпическое' end
 if item.quality==3 then return 20,'Редкое' end
 return 0
end
local emptyLinks={}
local function addSourceLink(index,npcID,entry)
 local iid=entry[1]
 local links=index[iid]
 if not links then links={};index[iid]=links end
 links[#links+1]=npcID
 links[#links+1]=entry
end

function A:ItemSources(iid)
 local grouped,result={},{}
 local links=self:AtlasSourceLinks()[iid] or emptyLinks
 for i=1,#links,2 do
  local npc=links[i]
  local source=grouped[npc]
  if not source then
   source={npcID=npc,entries={}}
   grouped[npc]=source;result[#result+1]=source
  end
  source.entries[#source.entries+1]=links[i+1]
 end
 return result
end

function A:BuildEntranceIndex()
 self.entranceIndex={}
 for id,mob in pairs(self.mobs) do
  for _,area in ipairs(mob.instances or {}) do
   local dungeon=(self.instances or {})[area]
   for _,p in ipairs(dungeon and dungeon.entrances or {}) do
    local list=self.entranceIndex[p[1]] or {};self.entranceIndex[p[1]]=list
    list[#list+1]={npcID=id,x=p[2],y=p[3],area=area}
   end
  end
 end
end

function A:BuildAtlasIndex()
 self.itemSourceLinks={};self.searchTerms=nil;self.mappableItems={}
 for id,mob in pairs(self.mobs) do
  for _,list in ipairs({mob.loot or {},mob.stock or {}}) do
   for _,entry in ipairs(list) do if self.items[entry[1]] then addSourceLink(self.itemSourceLinks,id,entry) end end
  end
 end
end

function A:AtlasSourceLinks()
 if not self.itemSourceLinks then self:BuildAtlasIndex() end
 return self.itemSourceLinks
end

function A:BuildSearchTerms()
 self.searchTerms={}
 for iid,item in pairs(self.items) do self.searchTerms[iid]=self:SearchText(item.name..' '..(item.ruName or '')..' '..(item.referenceName or '')) end
end

function A:DiscardAtlasIndex()
 self.itemSourceLinks=nil;self.searchTerms=nil;self.mappableItems=nil;self.accessibleAtlasSources=nil
 self.comparisonInfo=nil;self.comparisonStats=nil;self.gearTooltipStats=nil;self.atlasRequirementCache=nil;self.wornComparisonItems=nil
 self.atlasReadyItems=nil;self.atlasLoadFailures=nil;self.atlasRequested=nil
 if self.atlasRequestPump then self.atlasRequestQueue={} end
 local atlas=self.atlas
 if atlas then
  atlas.results=nil;atlas.recommendScan=nil;atlas.sourceCache=nil;atlas.previewSource=nil
  for _,row in ipairs(atlas.sourceRows) do row.value=nil end
 end
end

function A:SourceEvidenceTier(entry)
 local method=entry[2]
 if method==8 or method==4 or method==14 then return 2 end
 return entry[4] and 0 or 1
end
function A:SourceEntry(source)
 local best,rank
 for _,e in ipairs(source.entries) do
  local value=e[2]==8 and 6 or e[2]==4 and 5 or e[2]==14 and 4 or e[2]==6 and 4 or e[4] and 0 or e[2]==7 and 3 or 2
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
-- Reference browsing and personal recommendations intentionally use different rules.
function A:AtlasSourceAccessible(row)
 if row.entry and row.entry[4] then return false end
 local method=row.entry and row.entry[2]
 if method==5 or method==6 then
  local mob=self.mobs[row.npcID];local friendly=mob and mob.friendly or '';local faction=UnitFactionGroup('player')=='Alliance' and 'A' or 'H'
  if friendly~='' and not friendly:find(faction,1,true) then return false end
  if method==6 and row.entry[7]==0 then return false end
 end
 if row.source and row.source.kind=='quest' then
  local questID=row.source.id
  local q=(self.dungeonQuests or {})[questID]
  if q then
   local state=self:QuestState(questID)
   if state=='restricted' or state=='level' or state=='done' then return false end
  elseif self:Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted,questID) then return false end
 end
 return true
end
function A:HasAccessibleAtlasSource(iid,scope,requireMap)
 local sourceScope=scope=='recent' and 'all' or scope or 'all'
 local key=sourceScope..(requireMap and ':map' or '')
 self.accessibleAtlasSources=self.accessibleAtlasSources or {}
 local cache=self.accessibleAtlasSources[key]
 if not cache then
  cache={}
  self.accessibleAtlasSources[key]=cache
 end
 if cache[iid]~=nil then return cache[iid] end
 local accessible=false
 local links=self:AtlasSourceLinks()[iid] or emptyLinks
 for i=1,#links,2 do
  local npcID=links[i];local mob=self.mobs[npcID]
  local entry=links[i+1]
  if not entry[4] then
   local hasWorld=#(mob.points or {})>0
   local hasEntrance=false
   if sourceScope=='dungeons' or sourceScope=='all' and requireMap and not hasWorld then
    for _,area in ipairs(mob.instances or {}) do
     local instance=(self.instances or {})[area]
     if instance and #(instance.entrances or {})>0 then hasEntrance=true;break end
    end
   end
   if (sourceScope=='all' and (not requireMap or hasWorld or hasEntrance) or sourceScope=='world' and hasWorld or sourceScope=='dungeons' and hasEntrance)
    and self:AtlasSourceAccessible({npcID=npcID,entry=entry}) then accessible=true;break end
  end
 end
 if not accessible and (self.otherSources or {})[iid] then
  for _,row in ipairs(self:AtlasSources(iid,sourceScope)) do
   if (not requireMap or row.location.mapID) and self:AtlasSourceAccessible(row) then accessible=true;break end
  end
 end
 cache[iid]=accessible
 return accessible
end
function A:UnmetAtlasRequirement(iid)
 self.atlasRequirementCache=self.atlasRequirementCache or {}
 if self.atlasRequirementCache[iid]~=nil then return self.atlasRequirementCache[iid] end
 local data=self:Safe(C_TooltipInfo and C_TooltipInfo.GetHyperlink,'item:'..iid)
 if type(data)~='table' or type(data.lines)~='table' then return nil end
 for _,line in ipairs(data.lines) do
  local color=line.leftColor;local text=line.leftText
  if type(text)=='string' and color and (color.r or 0)>.75 and (color.g or 1)<.3 then
   text=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
   if text:find('^Requires ') or text:find('^Требуется') or text:find('^Требует') or text:find('^Необходимо') then self.atlasRequirementCache[iid]=text;return text end
  end
 end
 self.atlasRequirementCache[iid]=false;return false
end
function A:RecommendationStaticFits(item,iid,scope,requireMap,levelOnly)
 return (item.classID==2 or item.classID==4) and (item.quality or -1)>=1 and (not levelOnly or (item.level or 0)<=UnitLevel('player')) and self:ClassFits(item,iid,true,true) and self:HasAccessibleAtlasSource(iid,scope,requireMap)
end
function A:PersonalRecommendations(candidates)
 local f=self.atlas
 local key=table.concat({f.search:GetText(),f.scope,f.gearType or '',f.gearSlot or '',tostring(f.myLevel),tostring(f.knownOnly),tostring(UnitLevel('player')),tostring(self.db.specOnly),tostring(self.gearProfile and self.gearProfile[1])},'|')
 local scan=f.recommendScan
 if not scan or scan.key~=key then
  local list=f.gearSlot and candidates or self:BalanceGearSlots(candidates)
  scan={key=key,list=list,cursor=1,limit=math.min(128,#list),pending={},scores={}}
  f.recommendScan=scan
 end
 local function evaluate(iid,request)
  local info=self.comparisonInfo and self.comparisonInfo[iid]
  if not info and request then self:HydrateAtlasItem(iid);info=self.comparisonInfo and self.comparisonInfo[iid] end
  if not info then
   if not (self.atlasLoadFailures and self.atlasLoadFailures[iid]) then scan.pending[iid]=true end
   return
  end
  self:HydrateAtlasItem(iid)
  if self:RecommendationStaticFits(self.items[iid],iid,f.scope,f.knownOnly,true) then
   local comparison=self:CompareItem(iid)
   if comparison then scan.scores[iid]=comparison end
  end
 end
 for checked=1,8 do
  local iid=scan.cursor<=scan.limit and scan.list[scan.cursor]
  if not iid then break end
  scan.cursor=scan.cursor+1
  evaluate(iid,true)
 end
 local pending=0
 for iid in pairs(scan.pending) do
  if self.comparisonInfo and self.comparisonInfo[iid]
   or self.atlasReadyItems and self.atlasReadyItems[iid]
   or self.atlasLoadFailures and self.atlasLoadFailures[iid] then
   scan.pending[iid]=nil
   evaluate(iid,true)
  end
  if scan.pending[iid] then pending=pending+1 end
 end
 local result={}
 local unknown=0
 for iid,comparison in pairs(scan.scores) do
  if comparison.state=='better' or comparison.state=='empty' and (comparison.score or 0)>0 then result[#result+1]=iid end
  if comparison.state=='unknown' or comparison.state=='empty' and comparison.score==nil then unknown=unknown+1 end
 end
 table.sort(result,function(a,b)
  local as,bs=scan.scores[a],scan.scores[b]
  if as.state~=bs.state then return as.state=='better' end
  if as.state=='better' then
   local ap,bp=as.percent or -math.huge,bs.percent or -math.huge
   if ap~=bp then return ap>bp end
   if as.delta~=bs.delta then return as.delta>bs.delta end
  elseif as.score~=bs.score then return as.score>bs.score end
  if self.items[a].quality~=self.items[b].quality then return self.items[a].quality>self.items[b].quality end
  return a<b
 end)
 local positions={}
 scan.ranks={}
 for _,iid in ipairs(result) do
  local slot=self:GearSlot(self.items[iid])
  local comparison=scan.scores[iid]
  if slot and comparison.score~=nil then
   local position=(positions[slot] or 0)+1
   positions[slot]=position;scan.ranks[iid]=position
  end
 end
 f.recommendPending=pending
 f.recommendUnknown=unknown
 f.moreCandidates:SetShown(scan.cursor>scan.limit and scan.limit<#scan.list)
 if scan.cursor<=scan.limit and not f.recommendPump then
  f.recommendPump=true
  C_Timer.After(.12,function()
   f.recommendPump=nil
   if f:IsShown() and f.category=='upgrades' and f.recommendScan then self:RefreshAtlas() end
  end)
 end
 return result
end

function A:RefreshRecommendationItem(iid)
 local scan=self.atlas and self.atlas.recommendScan
 if scan and scan.scores[iid] then
  scan.scores[iid]=nil
  scan.pending[iid]=true
 end
end

local armorTypes={cloth=1,leather=2,mail=3,plate=4,shield=6}
local function matchesGearType(item,kind)
 if not kind then return true end
 if kind=='weapon' then return item.classID==2 end
 if item.classID~=4 then return false end
 local slot=(item.slot or ''):lower()
 local cloak=slot=='back' or slot=='cloak' or slot=='invtype_cloak'
 if kind=='accessory' then return item.subclass==0 or cloak end
 return item.subclass==armorTypes[kind] and not cloak
end

local namedSlots={head='head',neck='neck',shoulder='shoulder',shoulders='shoulder',chest='chest',robe='chest',waist='waist',legs='legs',feet='feet',wrist='wrist',hands='hand',hand='hand',finger='finger',trinket='trinket',back='cloak',cloak='cloak',
 ['one-hand']='weapon',['two-hand']='weapon',['main hand']='weapon',weapon='weapon',weaponmainhand='weapon',['2hweapon']='weapon',['off hand']='offhand',['off-hand']='offhand',['held in off-hand']='offhand',weaponoffhand='offhand',holdable='offhand',shield='offhand',ranged='ranged',rangedright='ranged',thrown='ranged',relic='ranged'}
function A:GearSlot(item)
 if item.classID==2 and item.subclass==19 then return 'wand' end
 return namedSlots[(item.slot or ''):lower():gsub('^invtype_','')]
end

function A:BalanceGearSlots(results)
 local groups,order={},{}
 for _,iid in ipairs(results) do
  local slot=self:GearSlot(self.items[iid]) or 'other'
  if not groups[slot] then groups[slot]={};order[#order+1]=groups[slot] end
  local group=groups[slot];group[#group+1]=iid
 end
 local balanced={}
 local row=1
 while #order>0 do
  for i=#order,1,-1 do if not order[i][row] then table.remove(order,i) end end
  for _,group in ipairs(order) do balanced[#balanced+1]=group[row] end
  row=row+1
 end
 return balanced
end

function A:FindItems(query,category,scope,relevant,options)
 options=options or {};local recent={};if options.recent then for _,id in ipairs(self.db.recentItems or {}) do recent[id]=true end end
 local personal=category=='gear' or category=='upgrades'
 query=self:SearchText(query)
 local exact=tonumber(query:match('^%d+$') or query:match('item:(%d+)'))
 local results,relevance={},{}
 local playerLevel=UnitLevel('player')
 if query~='' and not exact and not self.searchTerms then
  self:AtlasSourceLinks()
  self:BuildSearchTerms()
 end
 for iid,item in pairs(exact and {[exact]=self.items[exact]} or self.items) do
  local rank=self:SpecialRank(iid)
  local matches=(exact and iid==exact) or (not exact and (query=='' or self.searchTerms[iid] and self.searchTerms[iid]:find(query,1,true)))
  matches=matches and (not category or category=='all' or category=='pets' and rank==50 or category=='rare' and item.quality==3 or category=='epic' and item.quality>=4 and item.quality<=5 or category=='useful' and self:UsefulItem(iid) or (personal or category=='catalog') and (item.classID==2 or item.classID==4) or category=='bags' and item.classID==1 or category=='materials' and item.classID==7 or category=='recipes' and item.classID==9 or category=='consumables' and item.classID==0)
  if matches and (category=='catalog' or personal) then matches=matchesGearType(item,options.gearType) and (not options.slot or self:GearSlot(item)==options.slot) end
  if matches and personal and not self:RecommendationStaticFits(item,iid,scope,options.known,category=='upgrades' or options.level) then matches=false end
  if matches and category~='catalog' and not (category=='all' and query~='') and (self.db.classOnly or self.db.specOnly) and not self:ClassFits(item,iid,false,true) then matches=false end
  if matches and options.known and not personal and not self:HasMappableSource(iid) then matches=false end
  if matches and options.recent and not recent[iid] then matches=false end
  if matches and options.level then
   if category=='catalog' or personal or category=='all' and query~='' then
    matches=(item.level or 0)<=playerLevel
   else
    matches=self:AtlasLevelFits(item)
   end
  end
  if matches and relevant then matches=matches and self:ClassFits(item,iid,true) and (item.level==nil or item.level<=playerLevel) end
  if matches and not personal and scope and scope~='all' and scope~='recent' then
   matches=false
   local links=self:AtlasSourceLinks()[iid] or emptyLinks
   for i=1,#links,2 do
    local mob=self.mobs[links[i]]
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
  if matches then
   results[#results+1]=iid
   if query~='' and not exact then
    local score=0
    for _,name in ipairs({item.name,item.ruName or '',item.referenceName or ''}) do
     local normalized=self:SearchText(name)
     if normalized==query then score=2;break end
     if normalized:sub(1,#query)==query then score=1 end
    end
    relevance[iid]=score
   end
  end
 end
 table.sort(results,function(a,b)
  if relevance[a]~=relevance[b] then return relevance[a]>relevance[b] end
  local ai,bi=self.items[a],self.items[b]
  local ak,bk=self:HasKnownSource(a),self:HasKnownSource(b);if ak~=bk then return ak end
  if category=='all' or personal or category=='catalog' or category=='useful' then
   local ag,bg=(ai.classID==2 or ai.classID==4),(bi.classID==2 or bi.classID==4);if ag~=bg then return ag end
   local ad,bd=math.abs((ai.level or 0)-playerLevel),math.abs((bi.level or 0)-playerLevel);if ad~=bd then return ad<bd end
  end;if (personal or category=='catalog' or category=='useful' or category=='rare' or category=='epic') and ai.quality~=bi.quality then return ai.quality>bi.quality end
  if ai.name~=bi.name then return ai.name<bi.name end;return a<b
 end)
 if category=='gear' and not options.slot and query=='' then return self:BalanceGearSlots(results) end
 return results
end
function A:AtlasSources(iid,scope)
 if scope=='recent' then scope='all' end
 local rows={}
 for _,source in ipairs(self:ItemSources(iid)) do
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
  if kind=='crafted' and source.recipeID then
   for _,recipeSource in ipairs(self:ItemSources(source.recipeID)) do
    local entry=self:SourceEntry(recipeSource)
    if entry[2]==5 or entry[2]==6 then
     for _,loc in ipairs(self:SourceLocations(recipeSource.npcID)) do
      if loc.kind=='spawn' and (not scope or scope=='all' or scope=='world') then
       rows[#rows+1]={source=source,npcID=recipeSource.npcID,entry=entry,location=loc,recipeID=source.recipeID}
      end
     end
    end
   end
  end
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
  local ae,be=self:SourceEvidenceTier(a.entry),self:SourceEvidenceTier(b.entry);if ae~=be then return ae>be end
  if a.entry[3]~=b.entry[3] then return a.entry[3]>b.entry[3] end
  if (a.npcID or 0)~=(b.npcID or 0) then return (a.npcID or 0)<(b.npcID or 0) end
  if a.source and b.source and a.source.id~=b.source.id then return a.source.id<b.source.id end
  return (a.location.mapID or 0)<(b.location.mapID or 0)
 end)
 return rows
end
function A:ClearFocus(refresh,keepQuest)
 if not keepQuest then self.questFocus=nil;if self.db then self.db.questPin=nil end end
 self.habitatPinnedFocus=nil;self.focus=keepQuest and self.questFocus or nil;self.focusGroup=nil;self.pinned=nil;self.inspectPin=nil;self.hoverPin=nil;self:ClearHabitat()
 if self.tip then self.tip:Hide() end
 if self.focusButton then self.focusButton:Hide() end
 if self.atlas and self.atlas.clearFocus then self.atlas.clearFocus:Hide() end
 self.dirty=true;if refresh~=false then self:Update() end
end
function A:FocusSource(iid,npcID,mapID,location)
 if not mapID then return false,'Источник известен, но координат пока нет.' end
 local ids={}
 for _,source in ipairs(self:ItemSources(iid)) do if not npcID or source.npcID==npcID then ids[source.npcID]=true end end
 if not next(ids) then return false,'Источник не найден.' end
 local opened,reason=self:OpenMapAt(mapID);if not opened then return false,reason end
 self:ClearFocus(false,true)
 self.focus={ids=ids,itemID=iid,label=self:ItemDisplay(iid),explicitMap=true}
 self.habitatPinnedFocus=self.focus
 local entrances={}
 if location and location.kind=='entrance' then
  local dungeon=self.instances[location.area]
  for _,point in ipairs(dungeon and dungeon.entrances or {}) do
   if point[1]==mapID then entrances[#entrances+1]=point end
  end
 elseif not location then
  for id in pairs(ids) do
   local mob=self.mobs[id]
   local outdoor=false
   for _,point in ipairs(mob.points or {}) do
    if point[1]==mapID then outdoor=true;break end
   end
   if not outdoor then
    for _,area in ipairs(mob.instances or {}) do
     for _,point in ipairs((self.instances[area] or {}).entrances or {}) do
      if point[1]==mapID then entrances[#entrances+1]=point end
     end
    end
   end
  end
 end
 if #entrances>0 then self.focus.points=entrances;self.focus.kind='entrance' end
 if self.settings then self.settings:Hide() end

 if self.atlas then self.atlas:Hide() end
 self.db.enabled=true;self.dirty=true;self:Update();return true
end
-- Filters apply to browsing. A deliberate item/source selection is visible even if filters exclude it.
function A:FocusedLoot(id,fullLoot)
 if not fullLoot and self.focus and self.focus.itemID then
  local mob=self.mobs[id];if not mob then return {},0 end
  local entries={}
  for _,list in ipairs({mob.loot or emptyLinks,mob.stock or emptyLinks}) do
   for _,entry in ipairs(list) do if entry[1]==self.focus.itemID then entries[#entries+1]=entry end end
  end
  if #entries>0 then
   local best=self:SourceEntry({entries=entries})
   local copy={};for i=1,8 do copy[i]=best[i] end;copy.alternatives=entries
   return {copy},1
  end
 end
 return self:Loot(id,self.skills,true,true,self.db.specialMobsOnly and not fullLoot)
end

function A:RememberItem(iid)
 self.db.recentItems=type(self.db.recentItems)=='table' and self.db.recentItems or {}
 local recent={iid};for _,id in ipairs(self.db.recentItems) do if id~=iid and self.items[id] and #recent<12 then recent[#recent+1]=id end end
 self.db.recentItems=recent
end
function A:ShowItemOnMap(iid)
 local rows=self:AtlasSources(iid,'all');local map=WorldMapFrame;local current=map and map.GetMapID and map:GetMapID();local best
 for _,row in ipairs(rows) do if row.location.mapID then best=best or row.location.mapID;if row.location.mapID==current then best=current;break end end end
 if not best then return false,#rows>0 and 'Источник известен, координаты пока нет. Открой список источников.' or 'Предмет есть в каталоге, источник пока неизвестен.' end
 if not map or not map.SetMapID then return false,'Карта сейчас недоступна.' end
 local opened,reason=self:OpenMapAt(best);if not opened then return false,reason end
 self:ClearFocus(false,true);local ids,points={},{}
 for _,row in ipairs(rows) do
  if row.npcID then ids[row.npcID]=true end
  for _,p in ipairs(row.location.points or {}) do points[#points+1]=p end
 end
 self.focus={ids=ids,points=points,itemID=iid,label=self:ItemDisplay(iid),kind='source'}
 self.settings:Hide();if self.atlas then self.atlas:Hide() end
 self.db.enabled=true;self.dirty=true;self:RememberItem(iid);self:Update();return true
end
function A:FocusAtlasSource(iid,row)
 if row.npcID then return self:FocusSource(row.recipeID or iid,row.npcID,row.location.mapID,row.location) end
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
  f.category='all';f.gearType=nil;f.gearSlot=nil;f.scope='all';f.selectedItem=nil;f.results=nil;f.page=1;f.search:SetText(tostring(id));self:RefreshAtlas()
 end)
end

function A:OpenMapAt(mapID)
 -- Our map markers are ordinary UI. Only Blizzard panel operations need combat care.
 if InCombatLockdown() then
  local map=WorldMapFrame
  if not map or not map:IsShown() then return false,'В бою открой карту клавишей M и повтори.' end
  if map.GetMapID and map:GetMapID()==mapID then return true end
  return false,'В бою выбери нужную зону на карте вручную.'
 end
 if C_Map and C_Map.OpenWorldMap then self:Safe(C_Map.OpenWorldMap,mapID) end
 local map=WorldMapFrame
 if not map then self:Safe(C_AddOns and C_AddOns.LoadAddOn or LoadAddOn,'Blizzard_WorldMap');map=WorldMapFrame end
 if not map then return false,'Не удалось загрузить карту.' end
 if not map:IsShown() then
  if ShowUIPanel then self:Safe(ShowUIPanel,map) elseif OpenWorldMap then self:Safe(OpenWorldMap) elseif ToggleWorldMap then self:Safe(ToggleWorldMap) end
 end
 if not map:IsShown() or not map.SetMapID then return false,'Карта не открылась. Открой её клавишей M и повтори.' end
 if map.GetMapID and map:GetMapID()==mapID then return true end
 local ok=pcall(map.SetMapID,map,mapID);if not ok then return false,'Не удалось выбрать карту.' end
 return true
end
function A:HasKnownSource(iid)
 return #((self.otherSources or {})[iid] or {})>0 or self:AtlasSourceLinks()[iid]~=nil
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
 local links=self:AtlasSourceLinks()[iid] or emptyLinks
 for i=1,#links,2 do local m=self.mobs[links[i]];if #(m.points or {})>0 then result=true;break end
  for _,area in ipairs(m.instances or {}) do if #((self.instances[area] or {}).entrances or {})>0 then result=true;break end end
 end
 if not result then for _,s in ipairs((self.otherSources or {})[iid] or {}) do
  if #(s.points or {})>0 then result=true;break end
  if s.kind=='crafted' and s.recipeID then
   for _,row in ipairs(self:AtlasSources(iid,'all')) do if row.recipeID and row.location.mapID then result=true;break end end
  end
  for _,g in ipairs(s.givers or {}) do if #(g.points or {})>0 then result=true;break end end
  if result then break end
 end end
 self.mappableItems[iid]=result;return result
end

-- Gameplay events update an open index. A cold index will read the current loot when it is requested.
function A:IndexLootEntry(npcID,entry)
 if self.searchTerms then
  local iid=entry[1];local item=self.items[iid]
  self.searchTerms[iid]=self:SearchText(item.name..' '..(item.ruName or '')..' '..(item.referenceName or ''))
 end
 if not self.itemSourceLinks then return end
 for _,cache in pairs(self.accessibleAtlasSources or {}) do cache[entry[1]]=nil end
 local iid=entry[1]
 local links=self:AtlasSourceLinks()[iid] or emptyLinks
 for i=1,#links,2 do if links[i]==npcID and links[i+1]==entry then return end end
 addSourceLink(self.itemSourceLinks,npcID,entry)
 self.mappableItems[iid]=nil
end

function A:RefreshNpcIndex(npcID,oldIDs)
 if not self.itemSourceLinks and not self.searchTerms then return end
 for iid in pairs(oldIDs or {}) do
  for _,cache in pairs(self.accessibleAtlasSources or {}) do cache[iid]=nil end
  local links=self.itemSourceLinks and self.itemSourceLinks[iid]
  if links then
   local target=1
   for i=1,#links,2 do
    if links[i]~=npcID then links[target]=links[i];links[target+1]=links[i+1];target=target+2 end
   end
   for i=target,#links do links[i]=nil end
   if target==1 then self.itemSourceLinks[iid]=nil end
  end
  if self.mappableItems then self.mappableItems[iid]=nil end
 end
 local mob=self.mobs[npcID]
 for _,entries in ipairs({mob.loot or {},mob.stock or {}}) do for _,e in ipairs(entries) do self:IndexLootEntry(npcID,e) end end
end
