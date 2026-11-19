local _,A=...
local function number(v)
 return not (issecretvalue and issecretvalue(v)) and type(v)=='number' and v==v and math.abs(v)<1e9
end
local function xy(v)
 if not v then return end
 local ok,x,y=pcall(function() return v:GetXY() end)
 if ok and number(x) and number(y) then return x,y end
end
function A:MergeRareCatalog()
 self.rareZones={}
 for id,rec in pairs(self.rareCatalog or {}) do
  local mob=self.mobs[id]
  if not mob then mob={name=rec.name,min=rec.min,max=rec.max,points=rec.points,instances={},kind='Unknown',loot={}};self.mobs[id]=mob end
  mob.rareRank=rec.rank
  local seen={};for _,p in ipairs(rec.points) do if not seen[p[1]] then seen[p[1]]=true;local list=self.rareZones[p[1]] or {};self.rareZones[p[1]]=list;list[#list+1]=id end end
 end
 for _,ids in pairs(self.rareZones) do table.sort(ids) end
end
function A:RareUnitPosition(unit,mapID)
 if not UnitPosition or not C_Map or not C_Map.GetMapPosFromWorldPos or not CreateVector2D then return end
 local x,y,_,instance=self:Safe(UnitPosition,unit)
 if not number(x) or not number(y) or not number(instance) then return end
 local id,pos=self:Safe(C_Map.GetMapPosFromWorldPos,instance,CreateVector2D(x,y),mapID)
 local px,py=xy(pos)
 if id and px and px>=0 and px<=1 and py>=0 and py<=1 then return {id,px*100,py*100} end
end
function A:WatchRareUnit(unit,retry)
 if not self.db.rareEnabled or type(unit)~='string' then return end
 local guid=self:Safe(UnitGUID,unit)
 if issecretvalue and issecretvalue(guid) or type(guid)~='string' then return end
 local id=tonumber(guid:match('^Creature%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-'))
 if not id then return end
 local classification=self:Safe(UnitClassification,unit)
 if issecretvalue and issecretvalue(classification) then return end
 if UnitClassification and classification==nil then if not retry then C_Timer.After(.2,function() self:WatchRareUnit(unit,true) end) end;return end
 if classification~='rare' and classification~='rareelite' and not (not UnitClassification and (self.rareCatalog or {})[id]) then return end
 local friendly=self:Safe(UnitIsFriend,'player',unit);if not (issecretvalue and issecretvalue(friendly)) and friendly then return end
 self.rareSeen=self.rareSeen or {};self.rareUnits=self.rareUnits or {};self.rareAlertTimes=self.rareAlertTimes or {}
 local now=GetTime();local dead=self:Safe(UnitIsDeadOrGhost,unit);if issecretvalue and issecretvalue(dead) then return end
 if dead==nil then dead=self:Safe(UnitIsDead,unit);if issecretvalue and issecretvalue(dead) then return end end
 local record=self.rareSeen[id] or {id=id};self.rareSeen[id]=record
 record.guid=guid;record.unit=unit;record.time=now;record.dead=not not dead
 if dead and self.rareAlert and self.rareAlert.npcID==id then self.rareAlert:Hide() end
 record.mapID=self:Safe(C_Map and C_Map.GetBestMapForUnit,'player')
 record.point=not dead and self:RareUnitPosition(unit,record.mapID) or nil
 self.rareUnits[unit]=id
 if not self.mobs[id] then
  local name=self:Safe(UnitName,unit);self.mobs[id]={name=type(name)=='string' and name or ('Существо #'..id),min=0,max=0,points={},instances={},kind='Unknown',loot={},rareRank=4}
 end
 if not dead and (not self.rareAlertTimes[guid] or now-self.rareAlertTimes[guid]>=300) then
  self.rareAlertTimes[guid]=now
  if self.db.rareAlerts then self:ShowRareAlert(id) end
 end
 self.rareMapDirty=true
end
function A:RareLiveRecord(id)
 local r=self.rareSeen and self.rareSeen[id]
 if r and not r.dead and GetTime()-r.time<=10 and r.unit then local guid=self:Safe(UnitGUID,r.unit);if not (issecretvalue and issecretvalue(guid)) and guid==r.guid then return r end end
end
function A:ConfigureRareRange()
 if not self.db then return end
 if InCombatLockdown() then self.rareRangePending=true;return end
 local get=C_CVar and C_CVar.GetCVar or GetCVar;local set=C_CVar and C_CVar.SetCVar or SetCVar
 if not get or not set then return end
 local enabled=self.db.rareEnabled and self.db.rareMaxRange
 self.db.rareCVarOriginals=self.db.rareCVarOriginals or {};self.db.rareCVarApplied=self.db.rareCVarApplied or {}
 for key,value in pairs({nameplateMaxDistance='80',nameplateShowEnemies='1',nameplateShowAll='1'}) do
  local current=self:Safe(get,key)
  if type(current)=='string' or type(current)=='number' then
   if enabled then
    if self.db.rareCVarOriginals[key]==nil then self.db.rareCVarOriginals[key]=tostring(current) end
    self:Safe(set,key,value)
    local applied=self:Safe(get,key);if type(applied)=='string' or type(applied)=='number' then self.db.rareCVarApplied[key]=tostring(applied) end
   else
    local original=self.db.rareCVarOriginals[key]
    if original and self.db.rareCVarApplied[key] and tostring(current)==self.db.rareCVarApplied[key] then self:Safe(set,key,original) end
    self.db.rareCVarOriginals[key]=nil;self.db.rareCVarApplied[key]=nil
   end
  end
 end
 self.rareRangePending=false
end
function A:RareMapEntries(mapID)
 local out,seen={},{}
 for _,id in ipairs((self.rareZones or {})[mapID] or {}) do
  local live=self:RareLiveRecord(id);if live and live.mapID~=mapID and (not live.point or live.point[1]~=mapID) then live=nil end;local point=live and live.point and live.point[1]==mapID and live.point
  if not point then for _,p in ipairs((self.rareCatalog[id] or {}).points or {}) do if p[1]==mapID then point=p;break end end end
  if point then out[#out+1]={id=id,point=point,exact=not not (live and live.point and live.point[1]==mapID),live=not not live};seen[id]=true end
 end
 for id in pairs(self.rareSeen or {}) do
  local live=self:RareLiveRecord(id)
  if not seen[id] and live and live.point and live.point[1]==mapID then out[#out+1]={id=id,point=live.point,exact=true,live=true} end
 end
 table.sort(out,function(a,b) if a.live~=b.live then return a.live end;return a.id<b.id end)
 return out
end
function A:TrackRare(id)
 local mob=self.mobs[id];if not mob then return end
 local live=self:RareLiveRecord(id);local points={}
 if live and live.point then points={live.point} else points=mob.points or {} end
 if #points==0 then return false,'Моб замечен, но его координаты недоступны.' end
 local current=WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID();local mapID=points[1][1]
 for _,p in ipairs(points) do if p[1]==current then mapID=current;break end end
 local ok,why=self:OpenMapAt(mapID);if not ok then return false,why end
 self:ClearFocus(false,true);self.focus={ids={[id]=true},label=mob.name,points=live and live.point and points or nil,kind='rare'}
 self.db.enabled=true;self.dirty=true;self:Update()
 for _,pin in ipairs(self.pins or {}) do if pin:IsShown() and pin.cell then for index,npcID in ipairs(pin.cell.ids) do if npcID==id then pin.selected=true;pin.mobIndex=index;self:InspectPin(pin);return true end end end end
 return true
end
function A:MinimapRareOffset(point,mapID,position,clampEdge)
 if point[1]~=mapID or not C_Map then return end
 local px,py=xy(position);if not px then return end
 local width,height=self:RareMapWorldSize(mapID)
 if not number(width) or not number(height) or width<=0 or height<=0 then return end
 local dx=(point[2]/100-px)*width;local dy=(py-point[3]/100)*height
 local radius=self:Safe(C_Minimap and C_Minimap.GetViewRadius)
 if not number(radius) or radius<=0 then
  local zoom=Minimap.GetZoom and Minimap:GetZoom() or 0;if not number(zoom) then return end
  local outdoors={233.3333,200,166.6667,133.3333,100,66.6667};local indoors={150,120,90,60,40,25}
  radius=(self:Safe(IsIndoors) and indoors or outdoors)[zoom+1]
 end
 local edge=false
 if not radius then return end
 if dx*dx+dy*dy>(radius*.88)^2 then
  if not clampEdge then return end
  local ratio=radius*.88/math.sqrt(dx*dx+dy*dy);dx,dy=dx*ratio,dy*ratio;edge=true
 end
 if tonumber(self:Safe(GetCVar,'rotateMinimap'))==1 then
  local facing=self:Safe(GetPlayerFacing)
  if number(facing) then local c,s=math.cos(facing),math.sin(facing);dx,dy=dx*c+dy*s,-dx*s+dy*c end
 end
 local w,h=Minimap:GetWidth(),Minimap:GetHeight();if not number(w) or not number(h) then return end
 return dx/radius*w/2,dy/radius*h/2,edge
end
function A:RareTick()
 if not self.db.rareEnabled then self:HideRarePins();return end
 for unit,id in pairs(self.rareUnits or {}) do
  local rec=self.rareSeen[id]
  local guid=self:Safe(UnitGUID,unit);if rec and not (issecretvalue and issecretvalue(guid)) and guid==rec.guid then self:WatchRareUnit(unit) else self.rareUnits[unit]=nil end
 end
 local now=GetTime()
 for id,record in pairs(self.rareSeen or {}) do if now-record.time>300 then self.rareSeen[id]=nil end end
 for guid,time in pairs(self.rareAlertTimes or {}) do if now-time>600 then self.rareAlertTimes[guid]=nil end end
 self:UpdateRareMinimap()
 if WorldMapFrame and WorldMapFrame:IsShown() then self:Update() end
end
function A:StartRareTracking()
 self.rareSeen={};self.rareUnits={};self.rareAlertTimes={}
 self:ConfigureRareRange()
 if self.rareEvents then return end
 local f=CreateFrame('Frame');self.rareEvents=f
 f:SetScript('OnEvent',function(_,event,unit)
  if event=='NAME_PLATE_UNIT_ADDED' or event=='UNIT_CLASSIFICATION_CHANGED' then self:WatchRareUnit(unit)
  elseif event=='NAME_PLATE_UNIT_REMOVED' then self.rareUnits[unit]=nil
  elseif event=='PLAYER_TARGET_CHANGED' then self:WatchRareUnit('target')
  elseif event=='UPDATE_MOUSEOVER_UNIT' then self:WatchRareUnit('mouseover')
  elseif event=='PLAYER_REGEN_ENABLED' and self.rareRangePending then self:ConfigureRareRange()
  elseif event=='PLAYER_ENTERING_WORLD' then self.rareUnits={};self.rareSeen={};self.rareWorldSizes={};C_Timer.After(.5,function() self:ScanVisibleRareUnits() end) end
 end)
 for _,event in ipairs({'NAME_PLATE_UNIT_ADDED','NAME_PLATE_UNIT_REMOVED','UNIT_CLASSIFICATION_CHANGED','PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED'}) do f:RegisterEvent(event) end
 self:ScanVisibleRareUnits()
 C_Timer.NewTicker(1,function() self:RareTick() end)
end

function A:RareMapWorldSize(mapID)
 self.rareWorldSizes=self.rareWorldSizes or {};local cached=self.rareWorldSizes[mapID]
 if cached then return cached[1],cached[2] end
 local w,h=self:Safe(C_Map and C_Map.GetMapWorldSize,mapID)
 if (not number(w) or not number(h) or w<=0 or h<=0) and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
  local a,p=self:Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(0,0))
  local b,q=self:Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(1,0))
  local c,r=self:Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(0,1))
  local x,y=xy(p);local xx,yy=xy(q);local xxx,yyy=xy(r)
  if a==b and b==c and x and xx and xxx then w=math.sqrt((xx-x)^2+(yy-y)^2);h=math.sqrt((xxx-x)^2+(yyy-y)^2) end
 end
 if number(w) and number(h) and w>0 and h>0 then self.rareWorldSizes[mapID]={w,h};return w,h end
end

function A:ScanVisibleRareUnits()
 if C_NamePlate and C_NamePlate.GetNamePlates then
  for _,plate in ipairs(self:Safe(C_NamePlate.GetNamePlates) or {}) do if plate.namePlateUnitToken then self:WatchRareUnit(plate.namePlateUnitToken) end end
 end
 self:WatchRareUnit('target');self:WatchRareUnit('mouseover')
end
