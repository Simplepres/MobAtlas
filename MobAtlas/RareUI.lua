local _,A=...
local skull='Interface\\TargetingFrame\\UI-TargetingFrame-Skull'
local glow='Interface\\AddOns\\MobAtlas\\Art\\SpawnGlow.tga'
local function text(parent,value,x,y,width,size)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(A.font,size or 11,'');t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');A:LocalizeWidget(t);t:SetText(value);return t
end
function A:HideRarePins()
 for _,p in ipairs(self.rareWorldPins or {}) do p:Hide() end
 for _,p in ipairs(self.rareMiniPins or {}) do p:Hide() end
 if self.rareAlert then self.rareAlert:Hide() end
end
function A:RarePinTooltip(pin)
 GameTooltip:SetOwner(pin,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,self.mobs[pin.entry.id].name,1,.83,.4)
 self:AddTooltipLine(GameTooltip,pin.entry.exact and 'Моб замечен: координаты из клиента.' or pin.entry.live and 'Замечен рядом; точка — место появления из базы.' or 'Возможное место появления. Наличие не подтверждено.',.8,.8,.75)
 if pin.edge then self:AddTooltipLine(GameTooltip,'За краем миникарты: показано направление.',.9,.8,.5) end
 self:AddTooltipLine(GameTooltip,'Нажми: добыча и область появления.',.7,.8,.7);GameTooltip:Show()
end
function A:CreateRarePin(parent)
 local p=CreateFrame('Button',nil,parent);p.mobAtlasPin=true;p:SetSize(17,17)
 p.halo=p:CreateTexture(nil,'BACKGROUND');p.halo:SetTexture(glow);p.halo:SetPoint('CENTER');p.halo:SetSize(30,30)
 p.icon=p:CreateTexture(nil,'ARTWORK');p.icon:SetAllPoints();p.icon:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\MarkerRare.tga')
 p:SetScript('OnEnter',function(b) self:RarePinTooltip(b) end)
 p:SetScript('OnLeave',function() GameTooltip:Hide() end)
 p:SetScript('OnClick',function(b)
  GameTooltip:Hide();local ok,why=self:TrackRare(b.entry.id)
  if not ok and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self:L(why)) end
 end)
 return p
end
function A:StyleRarePin(pin,entry)
 pin.entry=entry;pin.icon:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\'..(entry.exact and 'MarkerRareLive.tga' or 'MarkerRare.tga'))
 if pin.icon.SetVertexColor then pin.icon:SetVertexColor(1,1,1,entry.exact and 1 or .95) end
 if pin.halo.SetVertexColor then pin.halo:SetVertexColor(.65,.43,.9,entry.exact and .18 or .05) end
end
function A:UpdateRareWorld(canvas,scale,level,strata)
 self.rareWorldPins=self.rareWorldPins or {}
 if not self.db.enabled or not self.db.rareEnabled or not self.db.rareMap then for _,pin in ipairs(self.rareWorldPins) do pin:Hide() end;return end
 local entries=self:RareMapEntries(WorldMapFrame:GetMapID());local used=0;local occupied={}
 for _,entry in ipairs(entries) do
  if not self.focus or (self.focus.ids or {})[entry.id] or entry.exact then
   local x,y=entry.point[2],entry.point[3];local key=math.floor(canvas:GetWidth()*x/100/scale/20)..':'..math.floor(canvas:GetHeight()*y/100/scale/20)
   if not occupied[key] and used<48 then
    occupied[key]=true;used=used+1;local pin=self.rareWorldPins[used] or self:CreateRarePin(canvas);self.rareWorldPins[used]=pin
    self:StyleRarePin(pin,entry);pin:SetParent(canvas);pin:SetScale(scale);pin:SetFrameLevel(level+3);pin:SetFrameStrata(strata);pin:SetSize(entry.exact and 21 or 19,entry.exact and 21 or 19)
    pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',canvas:GetWidth()*x/100/scale,-canvas:GetHeight()*y/100/scale);pin:Show()
   end
  end
 end
 for i=used+1,#self.rareWorldPins do self.rareWorldPins[i]:Hide() end
 self.rareMapDirty=false
end
function A:RareMinimapAnchors(mapID)
 self.rareMiniAnchorCache=self.rareMiniAnchorCache or {}
 if self.rareMiniAnchorCache[mapID] then return self.rareMiniAnchorCache[mapID] end
 local w,h=self:RareMapWorldSize(mapID);if not w or not h then return {} end
 local anchors={}
 for _,id in ipairs((self.rareZones or {})[mapID] or {}) do
  local cells={}
  for _,point in ipairs(((self.rareCatalog or {})[id] or {}).points or {}) do
   if point[1]==mapID then
    local cell=math.floor(point[2]/100*w/60)..':'..math.floor(point[3]/100*h/60)
    if not cells[cell] then
     cells[cell]=true;anchors[#anchors+1]={id=id,point=point,key=string.format('%d:%d:%.4f:%.4f',id,mapID,point[2],point[3])}
    end
   end
  end
 end
 table.sort(anchors,function(a,b) return a.key<b.key end)
 self.rareMiniAnchorCache[mapID]=anchors;return anchors
end
function A:UpdateRareMinimap()
 self.rareMiniPins=self.rareMiniPins or {};self.rareMiniByKey=self.rareMiniByKey or {}
 if not Minimap or not self.db.rareEnabled or not self.db.rareMinimap or not Minimap:IsShown() then for _,p in ipairs(self.rareMiniPins) do p:Hide() end;return end
 local mapID=self:Safe(C_Map and C_Map.GetBestMapForUnit,'player');local position=mapID and self:Safe(C_Map and C_Map.GetPlayerMapPosition,mapID,'player')
 local candidates={};local exact={}
 -- A confirmed position can move. A reference spawn must never chase the player.
 for id in pairs(self.rareSeen or {}) do
  local live=self:RareLiveRecord(id)
  if live and live.point and live.point[1]==mapID then
   exact[id]=true;candidates[#candidates+1]={id=id,point=live.point,exact=true,live=true,key='live:'..live.guid}
  end
 end
 table.sort(candidates,function(a,b) return a.key<b.key end)
 for _,anchor in ipairs(mapID and self:RareMinimapAnchors(mapID) or {}) do
  if not exact[anchor.id] then candidates[#candidates+1]={id=anchor.id,point=anchor.point,key=anchor.key,exact=false,live=self:RareLiveRecord(anchor.id)~=nil} end
 end
 local visible={};local wanted={}
 for _,entry in ipairs(candidates) do
  local x,y,edge=self:MinimapRareOffset(entry.point,mapID,position,entry.exact)
  if x then
   local overlaps=false
   for _,other in ipairs(visible) do if (x-other.x)^2+(y-other.y)^2<14^2 then overlaps=true;break end end
   if not overlaps and #visible<24 then entry.x=x;entry.y=y;entry.edge=edge;visible[#visible+1]=entry;wanted[entry.key]=true end
  end
 end
 -- Recycle only frames no longer wanted. Persistent anchors keep the same owner.
 for _,pin in ipairs(self.rareMiniPins) do
  if pin.markerKey and not wanted[pin.markerKey] then self.rareMiniByKey[pin.markerKey]=nil;pin.markerKey=nil;pin:Hide() end
 end
 for _,entry in ipairs(visible) do
  local pin=self.rareMiniByKey[entry.key]
  if not pin then
   for _,free in ipairs(self.rareMiniPins) do if not free.markerKey then pin=free;break end end
   if not pin then pin=self:CreateRarePin(Minimap);self.rareMiniPins[#self.rareMiniPins+1]=pin end
   pin.markerKey=entry.key;self.rareMiniByKey[entry.key]=pin
  end
  self:StyleRarePin(pin,entry);pin.edge=entry.edge;pin:SetSize(entry.exact and 17 or 16,entry.exact and 17 or 16);pin:SetFrameLevel(Minimap:GetFrameLevel()+8)
  pin:ClearAllPoints();pin:SetPoint('CENTER',Minimap,'CENTER',entry.x,entry.y);pin:Show()
 end
end
function A:ShowRareAlert(id)
 if not self.rareAlert then
  local f=CreateFrame('Button','MobAtlasRareAlert',UIParent,'BackdropTemplate');self.rareAlert=f;f:SetSize(330,72);f:SetPoint('TOP',UIParent,'TOP',0,-110);f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});f:SetBackdropColor(.08,.09,.12,.96);f:SetBackdropBorderColor(.6,.47,.72,.9)
  f.icon=f:CreateTexture(nil,'ARTWORK');f.icon:SetTexture(skull);f.icon:SetSize(34,34);f.icon:SetPoint('LEFT',12,0)
  text(f,'Редкий моб обнаружен',57,-10,245,10);f.name=text(f,'',57,-25,240,14);text(f,'Нажми, чтобы открыть карту',57,-48,245,10)
  local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-2,-2);close:SetScript('OnClick',function() f:Hide() end)
  f:SetScript('OnClick',function() local ok,why=self:TrackRare(f.npcID);if ok then f:Hide() elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self:L(why)) end end)
 end
 local f=self.rareAlert;f.npcID=id;f.name:SetText(self.mobs[id].name);f:Show();f.serial=(f.serial or 0)+1;local serial=f.serial
 if self.db.rareSound then self:Safe(PlaySound,SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.IG_QUEST_LOG_OPEN) or 8959,'Master') end
 C_Timer.After(12,function() if f.serial==serial then f:Hide() end end)
end
function A:HideHabitatAreas()
 for _,f in ipairs(self.habitatAreas or {}) do f:Hide() end
end
-- Separate soft patches at actual source points; no joined area or outline mesh.
function A:RenderHabitatArea(cells,canvas,scale,level,strata)
 self:HideHabitatAreas();self.habitatAreas=self.habitatAreas or {}
 if not self.db.habitatGlow then return end
 local used,occupied=0,{}
 for _,cell in ipairs(cells) do if not cell.dungeon then
  local x,y=canvas:GetWidth()*cell.x/100/scale,canvas:GetHeight()*cell.y/100/scale
  local key=math.floor(x/24)..':'..math.floor(y/24)
  if not occupied[key] and used<80 then
   occupied[key]=true;used=used+1;local f=self.habitatAreas[used]
   if not f then f=CreateFrame('Frame',nil,canvas);f.mobAtlasPin=true;f:EnableMouse(false);f.fill=f:CreateTexture(nil,'BACKGROUND');f.fill:SetTexture(glow);f.fill:SetAllPoints();self.habitatAreas[used]=f end
   f:SetParent(canvas);f:SetScale(scale);f:SetFrameStrata(strata);f:SetFrameLevel(math.max(1,level-1));f:SetSize(52,52)
   if f.fill.SetVertexColor then f.fill:SetVertexColor(.67,.45,.9,.60) end
   f:ClearAllPoints();f:SetPoint('CENTER',canvas,'TOPLEFT',x,-y);f:Show()
  end
 end end
end
function A:HasHabitatSelection()
 return self.focus and self.habitatPinnedFocus==self.focus or self.tip and self.tip:IsShown() and self.inspectPin and (self.inspectPin.selected or #self.inspectPin.cell.ids==1)
end
function A:PreviewMobHabitat(pin)
 self:HideHabitatAreas()
 if not self:HasHabitatSelection() or not WorldMapFrame or not WorldMapFrame:IsShown() or not self.db.habitatGlow then return end
 local cells={};local mapID=WorldMapFrame:GetMapID();local ids=pin.selected and {pin.cell.ids[pin.mobIndex or 1]} or pin.cell.ids
 for _,id in ipairs(ids) do for _,p in ipairs((self.mobs[id] or {}).points or {}) do if p[1]==mapID then cells[#cells+1]={x=p[2],y=p[3]} end end end
 local canvas=WorldMapFrame:GetCanvas();local level,strata=self:MapPinLayer(WorldMapFrame,canvas);local scale=WorldMapFrame:GetEffectiveScale()/math.max(.01,canvas:GetEffectiveScale())
 self:RenderHabitatArea(cells,canvas,scale,level,strata)
end
function A:OpenRareSettings()
 if not self.rareSettings then
  local f=CreateFrame('Frame','MobAtlasRareSettings',UIParent,'BackdropTemplate');self.rareSettings=f;f:SetSize(370,310);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:EnableMouse(true);f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=14});f:SetBackdropColor(.08,.1,.12,.98);f:SetBackdropBorderColor(.65,.5,.75,1);tinsert(UISpecialFrames,'MobAtlasRareSettings')
  text(f,'Редкие мобы',16,-16,300,16);local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-3,-3);close:SetScript('OnClick',function() f:Hide() end)
  f.checks={}
  local choices={{'rareEnabled','Отслеживать редких мобов'},{'rareAlerts','Показывать уведомления'},{'rareSound','Звук при обнаружении'},{'rareMap','Метки на карте'},{'rareMinimap','Метки на миникарте'},{'rareMaxRange','Дальность имён до 80'},{'habitatGlow','Мягкая подсветка области'}}
  for i,v in ipairs(choices) do
   local key=v[1];local c=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate');c:SetSize(24,24);c:SetPoint('TOPLEFT',14,-45-(i-1)*29);text(c,v[2],29,-5,300,11)
   c:SetScript('OnClick',function(b) self.db[key]=not not b:GetChecked();self:ConfigureRareRange();if key=='rareEnabled' and self.db.rareEnabled then self:ScanVisibleRareUnits() end;self:RareTick();self.dirty=true;self:Update() end);f.checks[key]=c
  end
  text(f,'Дальность ограничена клиентом. Место из базы — не подтверждение живого моба.',16,-260,338,10)
 end
 for key,c in pairs(self.rareSettings.checks) do c:SetChecked(self.db[key]) end
 self.rareSettings:Show()
end

function A:HideRarePins()
 for _,pin in ipairs(self.rareWorldPins or {}) do pin:Hide() end
 for _,pin in ipairs(self.rareMiniPins or {}) do pin:Hide() end
 if self.rareAlert then self.rareAlert:Hide() end
end
