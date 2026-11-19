local _,A=...
-- Independent entrance/quest layer. Never change another addon's pins or routes.
local supported={2437,1581,718,717,209,719,721,491,796,722,1337,1176,2100,1477,1584,1583,2557,2057,2017,16919,16611,16732,16544,-10002,-10003,-10004,-10005,-10006}
function A:BuildDungeonPinIndex()
 self.dungeonPinIndex={};self.dungeonPinAreas={};local grouped={}
 for _,area in ipairs(supported) do
  local instance=(self.instances or {})[area]
  for _,p in ipairs(instance and instance.entrances or {}) do
   local key=string.format('%d:%.1f:%.1f',p[1],p[2],p[3]);local cell=grouped[key]
   if not cell then cell={x=p[2],y=p[3],mapID=p[1],areas={}};grouped[key]=cell;local list=self.dungeonPinIndex[p[1]] or {};self.dungeonPinIndex[p[1]]=list;list[#list+1]=cell end
   cell.areas[#cell.areas+1]=area;self.dungeonPinAreas[area]=true
  end
 end
 for _,list in pairs(self.dungeonPinIndex) do table.sort(list,function(a,b) if a.y~=b.y then return a.y<b.y end;return a.x<b.x end) end
end
function A:AddDungeonQuestLines(tooltip,areas,header)
 for _,area in ipairs(areas) do
  if header then self:AddTooltipLine(tooltip,self:DungeonName(area),1,.83,.4) end
  local rows=self:DungeonQuestList(area,false);local count=0
  for _,entry in ipairs(rows) do
   if entry.state~='active' then
    count=count+1
    if count<=5 then
     self:AddTooltipLine(tooltip,(self:IsQuestPinned(entry.id) and '◆ ' or '! ')..self:QuestName(entry.id),1,.9,.65)
     if entry.step~=entry.id then self:AddTooltipLine(tooltip,'Сначала: '..self:QuestName(entry.step),.7,.75,.7) end
    end
   end
  end
  if count==0 then self:AddTooltipLine(tooltip,'Нет заданий для взятия на твоём уровне.',.7,.75,.7)
  elseif count>5 then self:AddTooltipLine(tooltip,'Ещё заданий: '..(count-5),.7,.75,.7) end
 end
 self:AddTooltipLine(tooltip,'Нажми значок заданий, чтобы выбрать квест.',.65,.8,.7)
end
function A:OpenDungeonEntrance(cell)
 self:OpenPreparation();local f=self.prep
 f.page=1;f.entranceAreas=#cell.areas>1 and cell.areas or nil;f.area=#cell.areas==1 and cell.areas[1] or nil
 self:RefreshPreparation()
end
function A:HookLeatrixQuestTooltip()
 local tooltip=_G.LeaMapsPOITooltip
 if not tooltip or tooltip.mobAtlasQuestsHooked or not tooltip.HookScript then return end
 tooltip.mobAtlasQuestsHooked=true
 tooltip:HookScript('OnShow',function(t)
  if self.leatrixQuestTooltipBusy or not self.db or not self.db.enabled or not self.db.dungeonPins then return end
  local owner=t.GetOwner and t:GetOwner();local cell=owner and self.leatrixDungeonCells and self.leatrixDungeonCells[owner]
  if not cell then return end
  self.leatrixQuestTooltipBusy=true
  self:AddTooltipLine(t,'MobAtlas · задания перед данжем',1,.82,.4)
  self:AddDungeonQuestLines(t,cell.areas,false);t:Show()
  self.leatrixQuestTooltipBusy=false
 end)
end
function A:UpdateDungeonPins(canvas,scale,level,strata)
 self.dungeonPins=self.dungeonPins or {}
 if not self.db.enabled or not self.db.dungeonPins then for _,pin in ipairs(self.dungeonPins) do pin:Hide() end;return end
 if not self.dungeonPinIndex then self:BuildDungeonPinIndex() end
 local mapID=WorldMapFrame:GetMapID();local cells=self.dungeonPinIndex[mapID] or {};local external={}
 -- Leatrix 1.60 exposes a marker flag on its display-only frames; read, never replace.
 if canvas.GetChildren then
  for _,child in ipairs({canvas:GetChildren()}) do
   if child.isLeaMapsPin and child:IsShown() and type(child.data)=='table' and (child.data[1]=='Dungeon' or child.data[1]=='Raid' or child.data[1]=='Dunraid') then external[#external+1]=child end
  end
 end
 self.leatrixDungeonCells=setmetatable({},{__mode='k'})
 self:HookLeatrixQuestTooltip()
 for i,cell in ipairs(cells) do
  local native
  for _,candidate in ipairs(external) do
   local x,y=candidate.data[2],candidate.data[3]
   if type(x)=='number' and type(y)=='number' and math.abs(x-cell.x)<1 and math.abs(y-cell.y)<1 then native=candidate;self.leatrixDungeonCells[native]=cell;break end
  end
  local pin=self.dungeonPins[i]
  if not pin then
   pin=CreateFrame('Button',nil,canvas);pin.mobAtlasPin=true;pin.dot=pin:CreateTexture(nil,'ARTWORK');pin.dot:SetAllPoints();self.dungeonPins[i]=pin
   pin:SetScript('OnEnter',function(b)
    GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddDungeonQuestLines(GameTooltip,b.cell.areas,true);GameTooltip:Show()
   end)
   pin:SetScript('OnLeave',function() GameTooltip:Hide() end)
   pin:SetScript('OnClick',function(b) GameTooltip:Hide();self:OpenDungeonEntrance(b.cell) end)
  end
  pin.cell=cell;pin.leatrixMarker=native;pin:SetParent(canvas);pin:SetFrameLevel(level+4);pin:SetFrameStrata(strata);pin:SetScale(scale);pin:SetSize(native and 14 or 20,native and 14 or 20)
  pin.dot:SetTexture(native and 'Interface\\GossipFrame\\AvailableQuestIcon' or 'Interface\\AddOns\\MobAtlas\\Art\\TrackDungeon.tga')
  pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',canvas:GetWidth()*cell.x/100/scale+(native and 14 or 0),-canvas:GetHeight()*cell.y/100/scale+(native and 10 or 0));pin:Show()
 end
 for i=#cells+1,#self.dungeonPins do self.dungeonPins[i]:Hide() end
end

function A:IsExternalDungeonPreview(canvas)
 -- Leatrix's private dungeon canvas is separate from Blizzard's zone canvas.
 -- Only inspect its visible overlay; never move, hide or hook the overlay itself.
 if not _G.LeaMapsDungeonTooltip then return false end
 local container=WorldMapFrame.ScrollContainer
 if not container or not container.GetChildren then return false end
 if self.leatrixDungeonOverlay then return self.leatrixDungeonOverlay:IsShown() end
 for _,overlay in ipairs({container:GetChildren()}) do
  if overlay~=canvas and overlay.bg and overlay.GetChildren then
   for _,child in ipairs({overlay:GetChildren()}) do
    if child.art then self.leatrixDungeonOverlay=overlay;return overlay:IsShown() end
   end
  end
 end
 return false
end
