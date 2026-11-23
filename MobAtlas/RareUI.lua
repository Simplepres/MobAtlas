local _,A=...
local skull='Interface\\TargetingFrame\\UI-TargetingFrame-Skull'
local glow='Interface\\AddOns\\MobAtlas\\Art\\SpawnGlow.tga'
local function text(parent,value,x,y,width,size)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(A.font,size or 11,'');t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');A:LocalizeWidget(t);t:SetText(value);return t
end
local arrows={'↑','↗','→','↘','↓','↙','←','↖'}
local function direction(x,y)
 return arrows[math.floor(math.atan2(x,y)*4/math.pi+.5)%8+1]
end
local guideModes={live='Живое положение',last='Последняя точка',spawn='Место появления'}

function A:UpdateRareGuide(sighting,mapID,position,point,mode)
 if not sighting then if self.rareGuide then self.rareGuide:Hide() end;return end
 local f=self.rareGuide
 if not f then
  f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');self.rareGuide=f
  f:SetSize(174,33);f:SetPoint('TOP',UIParent,'TOP',0,-187);f:SetFrameStrata('DIALOG')
  f:SetBackdrop({bgFile='Interface\\AddOns\\MobAtlas\\Art\\JournalPanel.tga',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=8})
  f:SetBackdropBorderColor(.63,.46,.72,.9)
  f.aura=f:CreateTexture(nil,'BACKGROUND');f.aura:SetTexture(glow);f.aura:SetSize(38,38);f.aura:SetPoint('LEFT',0,0)
  f.arrow=text(f,'',8,-5,22,17)
  f.info=text(f,'',34,-5,132,10)
  f.status=text(f,'',34,-17,132,9)
 end
 local dx,dy=self:RareOffset(point,mapID,position)
 local distance=dx and math.sqrt(dx*dx+dy*dy)
 local x,y
 if dx then x,y=self:RareRelativeOffset(dx,dy) end
 f.arrow:SetText(distance and distance<5 and '•' or x and direction(x,y) or '◇')
 f.arrow:SetTextColor(1,.82,.37)
 f.info:SetText(distance and (distance<5 and 'Точка рядом' or string.format('%d',math.floor(distance+.5))..self:L(' ярд.')) or 'Без направления')
 f.status:SetText(guideModes[mode] or 'Координаты недоступны')
 if f.aura.SetVertexColor then f.aura:SetVertexColor(.8,.5,1,.2+.18*(1+math.sin(GetTime()*4))/2) end
 f:Show()
end

function A:DismissRareAlert(nextAlert)
 local f=self.rareAlert
 if f then
  if self.pendingRareMap==f.sighting then self.pendingRareMap=nil end
  f.sighting=nil;f.npcID=nil;f:Hide()
 end
 if self.rareGuide then self.rareGuide:Hide() end
 if nextAlert then
  local queue=self.rareAlertQueue or {}
  while #queue>0 do
   local record=table.remove(queue,1)
   if not record.dead and self.db.rareEnabled and self.db.rareAlerts then
    self:ShowRareAlert(record.id,record);break
   end
  end
 else self.rareAlertQueue={} end
end

function A:QueueRareAlert(id,record)
 local active=self.rareAlert and self.rareAlert.sighting
 if not active then self:ShowRareAlert(id,record);return end
 if active.guid==record.guid then return end
 self.rareAlertQueue=self.rareAlertQueue or {}
 for _,candidate in ipairs(self.rareAlertQueue) do if candidate.guid==record.guid then return end end
 if #self.rareAlertQueue<5 then self.rareAlertQueue[#self.rareAlertQueue+1]=record end
end

function A:RareSightingDied(guid)
 local alert=self.rareAlert and self.rareAlert.sighting
 for _,record in ipairs(self.rareAlertQueue or {}) do if record.guid==guid then record.dead=true end end
 if alert and alert.guid==guid then
  if alert.record then alert.record.dead=true end
  self:DismissRareAlert(true)
 end
 if self.focus and self.focus.rareGUID and self.focus.rareGUID==guid then self:ClearFocus(false,true) end
end

function A:HideRarePins()
 for _,p in ipairs(self.rareWorldPins or {}) do p:Hide() end
 for _,p in ipairs(self.rareMiniPins or {}) do p:Hide() end
 self:DismissRareAlert(false)
end
function A:RarePinTooltip(pin)
 GameTooltip:SetOwner(pin,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,self.mobs[pin.entry.id].name,1,.83,.4)
 self:AddTooltipLine(GameTooltip,pin.entry.guideMode=='last' and 'Последнее наблюдение' or pin.entry.exact and 'Моб замечен: координаты из клиента.' or pin.entry.live and 'Замечен рядом; точка — место появления из базы.' or 'Возможное место появления. Наличие не подтверждено.',.8,.8,.75)
 if pin.edge then self:AddTooltipLine(GameTooltip,'За краем миникарты: показано направление.',.9,.8,.5) end
 self:AddTooltipLine(GameTooltip,'Нажми: добыча и область появления.',.7,.8,.7);GameTooltip:Show()
end
function A:CreateRarePin(parent)
 local p=CreateFrame('Button',nil,parent);p.mobAtlasPin=true;p:SetSize(17,17)
 p.halo=p:CreateTexture(nil,'BACKGROUND');p.halo:SetTexture(glow);p.halo:SetPoint('CENTER');p.halo:SetSize(30,30)
 p.arrow=text(p,'',0,-1,24,17);p.arrow:Hide()
 p.icon=p:CreateTexture(nil,'ARTWORK');p.icon:SetAllPoints();p.icon:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\MarkerRare.tga')
 p:SetScript('OnEnter',function(b) self:RarePinTooltip(b) end)
 p:SetScript('OnLeave',function() GameTooltip:Hide() end)
 p:SetScript('OnMouseDown',function(b) b.pressedEntry=b.entry end)
 p:SetScript('OnClick',function(b)
  local entry=b.pressedEntry or b.entry;b.pressedEntry=nil
  GameTooltip:Hide();local ok,why=self:TrackRare(entry.id,entry.sighting)
  if not ok and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self:L(why)) end
 end)
 return p
end
function A:StyleRarePin(pin,entry)
 pin.arrow:SetShown(entry.direction~=nil);pin.arrow:SetText(entry.direction or '');pin.arrow:SetTextColor(1,.85,.36)
 pin.icon:SetShown(entry.direction==nil)
 pin.entry=entry;pin.icon:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\'..(entry.exact and 'MarkerRareLive.tga' or 'MarkerRare.tga'))
 if pin.icon.SetVertexColor then pin.icon:SetVertexColor(1,1,1,entry.exact and 1 or .95) end
 if pin.halo.SetVertexColor then pin.halo:SetVertexColor(.65,.43,.9,entry.guideMode and .33 or entry.exact and .18 or .05) end
end
function A:UpdateRareWorld(canvas,scale,level,strata)
 self.rareWorldPins=self.rareWorldPins or {}
 if not self.db.enabled or not self.db.rareEnabled or not self.db.rareMap then for _,pin in ipairs(self.rareWorldPins) do pin:Hide() end;return end
 local entries=self:RareMapEntries(WorldMapFrame:GetMapID());local used=0;local occupied={}
 for _,entry in ipairs(entries) do
  if self.focus and (self.focus.ids or {})[entry.id] or not self.focus and (entry.sighting or not self.db.specialMobsOnly or self:HasSpecialMapLoot(entry.id)) then
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
 local sighting=self.db.rareEnabled and self.db.rareAlerts and self.rareAlert and self.rareAlert.sighting
 local visibleMini=Minimap and self.db.rareEnabled and self.db.rareMinimap and Minimap:IsShown()
 if not sighting and not visibleMini then
  self:UpdateRareGuide()
  for _,p in ipairs(self.rareMiniPins) do p:Hide() end
  return
 end
 local mapID=self:Safe(C_Map and C_Map.GetBestMapForUnit,'player')
 local position=mapID and self:Safe(C_Map and C_Map.GetPlayerMapPosition,mapID,'player')
 local selected,mode
 if sighting then selected,mode=self:RareGuidePoint(sighting,mapID==sighting.mapID and position or nil) end
 self:UpdateRareGuide(sighting,mapID,position,selected,mode)
 if not visibleMini then for _,p in ipairs(self.rareMiniPins) do p:Hide() end;return end
 local candidates={};local exact={}
 local tracked
 if selected and selected[1]==mapID then
  tracked={id=sighting.id,point=selected,exact=mode=='live',live=self:RareLiveRecord(sighting.id,sighting)~=nil,guideMode=mode,key='guide:'..(sighting.guid or sighting.id),sighting=sighting}
  exact[tracked.id]=true
 end
 -- A confirmed position can move. A reference spawn must never chase the player.
 for id in pairs(self.rareSeen or {}) do
  local live=self:RareLiveRecord(id)
  if not exact[id] and live and live.point and live.point[1]==mapID then
   exact[id]=true;candidates[#candidates+1]={id=id,point=live.point,exact=true,live=true,key='live:'..live.guid}
  end
 end
 table.sort(candidates,function(a,b) return a.key<b.key end)
 if tracked then table.insert(candidates,1,tracked) end
 for _,anchor in ipairs(mapID and self:RareMinimapAnchors(mapID) or {}) do
  if not exact[anchor.id] then candidates[#candidates+1]={id=anchor.id,point=anchor.point,key=anchor.key,exact=false,live=self:RareLiveRecord(anchor.id)~=nil} end
 end
 local visible={};local wanted={}
 for _,entry in ipairs(candidates) do
  local x,y,edge=self:MinimapRareOffset(entry.point,mapID,position,entry.exact or entry.guideMode~=nil)
  if x then
   local overlaps=false
   for _,other in ipairs(visible) do if (x-other.x)^2+(y-other.y)^2<14^2 then overlaps=true;break end end
   if not overlaps and #visible<24 then entry.x=x;entry.y=y;entry.edge=edge;entry.direction=entry.guideMode and edge and direction(x,y) or nil;visible[#visible+1]=entry;wanted[entry.key]=true end
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
function A:PlayRareAlertSound()
 local primary=SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959
 local fallback=SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 882
 local played=self:Safe(PlaySound,primary,'Master',false)
 if played==false then
  C_Timer.After(.2,function()
   if self.db.rareEnabled and self.db.rareSound then self:Safe(PlaySound,fallback,'Master',false) end
  end)
 end
end

function A:OpenRareAlertMap(sighting)
 local ok,reason=self:TrackRare(sighting.id,sighting)
 if not ok and InCombatLockdown() and reason and reason:find('В бою',1,true)==1 then
  self.pendingRareMap=sighting
  if self.rareAlert and self.rareAlert.sighting==sighting then self.rareAlert.hint:SetText('Карта откроется после боя') end
 elseif self.rareAlert and self.rareAlert.sighting==sighting then
  self.rareAlert.hint:SetText(ok and 'Клик: цель рядом или карта' or reason)
 end
end

function A:SyncRareTargetButton()
 local button=self.rareTargetButton
 if not button or InCombatLockdown() then return end
 local visible=self.rareAlert and self.rareAlert:IsShown()
 if not visible then button.pressedSighting=nil end
 button:SetShown(visible)
end

function A:CreateRareTargetButton()
 if not RegisterStateDriver or InCombatLockdown() or self.rareTargetButton then return end
 -- Separate from the banner so combat lockdown never blocks its visibility or close button.
 local button=CreateFrame('Button',nil,UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
 self.rareTargetButton=button
 button:SetSize(288,72)
 button:SetPoint('TOP',UIParent,'TOP',-21,-110)
 button:SetFrameStrata('DIALOG')
 button:SetFrameLevel(self.rareAlert:GetFrameLevel()+2)
 button:RegisterForClicks('LeftButtonUp')
 button:SetAttribute('useOnKeyDown',false)
 button:EnableMouse(true)
 button:SetAttribute('_onstate-mobatlascombat',[[if newstate == 'combat' then self:Hide() end]])
 RegisterStateDriver(button,'mobatlascombat','[combat] combat; idle')
 button:SetScript('OnMouseDown',function(b) b.pressedSighting=self.rareAlert.sighting end)
 button:SetScript('PreClick',function(b)
  if InCombatLockdown() then return end
  b.sighting=nil
  local alert=self.rareAlert
  if not alert or not alert:IsShown() then return end
  local sighting=b.pressedSighting or alert.sighting
  b.pressedSighting=nil
  if sighting~=alert.sighting then return end
  b.sighting=sighting
  local live=self:RareLiveRecord(sighting.id,sighting)
  local dead=live and self:Safe(UnitIsDeadOrGhost or UnitIsDead,live.unit)
  if live and live.guid==sighting.guid and not (issecretvalue and issecretvalue(dead)) and not dead then
   b:SetAttribute('unit',live.unit)
   b:SetAttribute('type','target')
  end
 end)
 button:SetScript('PostClick',function(b)
  if InCombatLockdown() then return end
  b:SetAttribute('type',nil)
  b:SetAttribute('unit',nil)
  local sighting=b.sighting;b.sighting=nil
  if not sighting then return end
  local guid=self:Safe(UnitGUID,'target')
  if not sighting.guid or (issecretvalue and issecretvalue(guid)) or guid~=sighting.guid then self:OpenRareAlertMap(sighting) end
 end)
 self:SyncRareTargetButton()
end

function A:ShowRareAlert(id,record)
 if not self.rareAlert then
  local f=CreateFrame('Button','MobAtlasRareAlert',UIParent,'BackdropTemplate');self.rareAlert=f;f:SetSize(330,72);f:SetPoint('TOP',UIParent,'TOP',0,-110);f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile='Interface\\AddOns\\MobAtlas\\Art\\JournalPanel.tga',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10});f:SetBackdropColor(1,1,1,1);f:SetBackdropBorderColor(.6,.47,.72,.9)
  f.icon=f:CreateTexture(nil,'ARTWORK');f.icon:SetTexture(skull);f.icon:SetSize(38,38);f.icon:SetPoint('LEFT',10,0)
  text(f,'Редкий моб обнаружен',57,-10,245,10);f.name=text(f,'',57,-25,240,14);f.hint=text(f,'Клик: цель рядом или карта',57,-48,245,10)
  local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-2,-2);close:SetScript('OnClick',function() self:DismissRareAlert(true) end)
  f:SetScript('OnClick',function() if f.sighting then self:OpenRareAlertMap(f.sighting) end end)
  f:SetScript('OnHide',function() self:SyncRareTargetButton() end)
 end
 local f=self.rareAlert
 record=record or {}
 f.npcID=id
 f.sighting={id=id,guid=record.guid,point=record.point,mapID=record.mapID,record=record}
 local live=self:RareLiveRecord(id,f.sighting)
 local name=live and self:Safe(UnitName,live.unit)
 f.name:SetText(not (issecretvalue and issecretvalue(name)) and type(name)=='string' and name or self.mobs[id].name)
 self:SetNpcPortrait(f.icon,id,live and live.unit)
 f.hint:SetText('Клик: цель рядом или карта')
 f:Show()
 self:CreateRareTargetButton()
 self:SyncRareTargetButton()
 self:UpdateRareMinimap()
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
  f:SetBackdrop({bgFile='Interface\\AddOns\\MobAtlas\\Art\\JournalPanel.tga',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10});f:SetBackdropColor(1,1,1,1);f:SetBackdropBorderColor(.65,.5,.75,1);tinsert(UISpecialFrames,'MobAtlasRareSettings')
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
