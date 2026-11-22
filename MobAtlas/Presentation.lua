local _,A=...
local families={Fox='Ability_Hunter_Pet_Wolf',Wolf='Ability_Hunter_Pet_Wolf',Spider='Ability_Hunter_Pet_Spider',Boar='Ability_Hunter_Pet_Boar',Bat='Ability_Hunter_Pet_Bat',Bear='Ability_Hunter_Pet_Bear',Cat='Ability_Hunter_Pet_Cat',CarrionBird='Ability_Hunter_Pet_Vulture',Crab='Ability_Hunter_Pet_Crab',Crocolisk='Ability_Hunter_Pet_Crocolisk',Gorilla='Ability_Hunter_Pet_Gorilla',Hyena='Ability_Hunter_Pet_Hyena',Raptor='Ability_Hunter_Pet_Raptor',Scorpid='Ability_Hunter_Pet_Scorpid',Tallstrider='Ability_Hunter_Pet_TallStrider',Turtle='Ability_Hunter_Pet_Turtle',WindSerpent='Ability_Hunter_Pet_WindSerpent'}
function A:SetNpcPortrait(texture,id)
 local mob=self.mobs[id];if not mob then return end
 if self.db.portraitSchema~=2 then self.db.portraits={};self.db.portraitSchema=2 end
 texture.mobAtlasNpcID=id
 texture:SetTexture(families[mob.family] and 'Interface\\Icons\\'..families[mob.family] or self:CreatureIcon(mob))
 for _,unit in ipairs({'target','mouseover','npc'}) do
  if self:NpcID(unit)==id and SetPortraitTexture then local ok=pcall(SetPortraitTexture,texture,unit);if ok then return end end
 end
 local function apply(display)
  if type(display)=='number' and display>0 and texture.mobAtlasNpcID==id and SetPortraitTextureFromCreatureDisplayID then
   local ok=pcall(SetPortraitTextureFromCreatureDisplayID,texture,display)
   if ok then self.db.portraits=self.db.portraits or {};self.db.portraits[id]=display;return true end
  end
 end
 if apply((self.db.portraits or {})[id]) then return end
 -- The client resolves the NPC's own model. No hard-coded wolf/bat display IDs.
 local model=texture.mobAtlasProbe
 if not model then
  model=self:Safe(CreateFrame,'PlayerModel',nil,texture:GetParent())
  if not model or not model.SetCreature or not model.GetDisplayInfo then return end
  texture.mobAtlasProbe=model;model:SetSize(1,1);model:SetPoint('TOPLEFT');model:EnableMouse(false);if model.SetAlpha then model:SetAlpha(0) end
 end
 model:SetScript('OnModelLoaded',function(m) if texture.mobAtlasNpcID==id then apply(self:Safe(m.GetDisplayInfo,m)) end end)
 self:Safe(model.ClearModel,model);model:Show();self:Safe(model.SetCreature,model,id)
end
function A:CloseInspection()
 self:ClearHabitat()
 self.inspectPin=nil;self.hoverPin=nil;self.pinned=nil;self.focusGroup=nil
 if self.tip then self.tip:Hide() end
 self.dirty=true
end
function A:SchedulePreviewHide(pin)
 if self.inspectPin then return end
 self.previewSerial=(self.previewSerial or 0)+1;local serial=self.previewSerial
 C_Timer.After(.25,function()
  if serial~=self.previewSerial or self.inspectPin then return end
  if self:Safe(self.tip.IsMouseOver,self.tip) or pin and self:Safe(pin.IsMouseOver,pin) then return end
  self.hoverPin=nil;self.tip:Hide()
 end)
end
function A:InspectionFooter(pin,y,multiple)
 local t=self.tip
 t.unpin:ClearAllPoints();t.unpin:SetPoint('TOPLEFT',multiple and 164 or 14,-y-30);t.unpin:SetWidth(multiple and 122 or 272)
 t.unpin:SetText(self:IsInspectionTracked(pin) and 'Открепить' or 'Закрепить');t.unpin:Show()
end
function A:FreezeInspection(pin)
 local t=self.tip
 if t.stablePin==pin and t.stableAnchor then return end
 local left=t.GetLeft and t:GetLeft();local top=t.GetTop and t:GetTop()
 if t:IsShown() and t.anchorPin==pin and type(left)=='number' and type(top)=='number' then
  -- Coordinates and offsets both use the card's effective scale.
  t.stableAnchor={'TOPLEFT',UIParent,'BOTTOMLEFT',left,top}
 else t.stableAnchor={'TOPLEFT',pin,'TOPRIGHT',8,12} end
 t.stablePin=pin
end
function A:AnchorInspection(pin)
 local t=self.tip;t:ClearAllPoints()
 if self.inspectPin==pin and t.stablePin==pin and t.stableAnchor then t:SetPoint(unpack(t.stableAnchor))
 else t:SetPoint('TOPLEFT',pin,'TOPRIGHT',8,12) end
 t.anchorPin=pin
end
function A:InspectPin(pin,keepArea)
 self:FreezeInspection(pin);self.inspectPin=pin;self.hoverPin=pin;self:ShowTooltip(pin,true);if not keepArea and self.PreviewMobHabitat then self:PreviewMobHabitat(pin) end
end
function A:PinInspection()
 local pin=self.inspectPin or self.hoverPin;if not pin then return end
 self:FreezeInspection(pin);self.inspectPin=pin;self.hoverPin=pin;self.pinned=pin
 self:ShowHabitat(pin);self:ShowTooltip(pin,true)
end
function A:ReadableFocusCells(cells,canvas,scale)
 -- Keep real coordinates, thinning only the drawing; never average or move a spawn.
 local out,occupied={},{};local spacing=18
 for _,cell in ipairs(cells) do
  local gx=math.floor(canvas:GetWidth()*cell.x/100/scale/spacing);local gy=math.floor(canvas:GetHeight()*cell.y/100/scale/spacing);local key=gx..':'..gy
  if not occupied[key] or cell.dungeon then occupied[key]=true;out[#out+1]=cell end
 end
 return out
end

function A:IsInspectionTracked(pin)
 if not pin or not self.focus or self.habitatPinnedFocus~=self.focus or not next(self.focus.ids or {}) then return false end
 local expected={}
 if pin.selected then expected[pin.cell.ids[pin.mobIndex or 1]]=true else for _,id in ipairs(pin.cell.ids) do expected[id]=true end end
 for id in pairs(expected) do if not self.focus.ids[id] then return false end end
 for id in pairs(self.focus.ids) do if not expected[id] then return false end end
 return true
end

function A:LayoutLootCard(pin,count,pages,multiple,lootMode)
 local t=self.tip;local y=58+count*40;local paged=pages>1;local actionY=y+(paged and 43 or 13)
 t.lootMode:ClearAllPoints();t.lootMode:SetPoint('TOPLEFT',14,-actionY-32);t.lootMode:SetShown(lootMode==true)
 t:SetHeight(actionY+(lootMode and 71 or 39));t.footerLine:ClearAllPoints();t.footerLine:SetPoint('TOPLEFT',12,-y-4)
 t.prev:ClearAllPoints();t.prev:SetPoint('TOPLEFT',14,-y-9);t.prev:SetShown(paged)
 t.next:ClearAllPoints();t.next:SetPoint('TOPLEFT',251,-y-9);t.next:SetShown(paged)
 t.pageText:ClearAllPoints();t.pageText:SetPoint('TOPLEFT',55,-y-15);t.pageText:SetWidth(190);t.pageText:SetText(paged and (pin.page..' / '..pages) or '');t.pageText:SetShown(paged)
 t.mobNext:SetWidth(145);t.mobNext:ClearAllPoints();t.mobNext:SetPoint('TOPLEFT',14,-actionY);t.mobNext:SetShown(multiple)
 t.unpin:ClearAllPoints();t.unpin:SetPoint('TOPLEFT',multiple and 164 or 14,-actionY);t.unpin:SetWidth(multiple and 122 or 272)
 t.unpin:SetText(self:IsInspectionTracked(pin) and 'Открепить' or (not pin.selected and #pin.cell.ids>1 and 'Закрепить группу' or 'Закрепить'));t.unpin:Show()
 self:AnchorInspection(pin)
end
