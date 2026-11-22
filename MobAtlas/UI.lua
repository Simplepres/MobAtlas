local _,A=...
local skin='Interface\\AddOns\\MobAtlas\\Art\\'
local function label(parent,text,x,y,w,size,color)
 local f=parent:CreateFontString(nil,'OVERLAY','GameFontNormal');f:SetFont(A.font,size or 12,'');f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetJustifyH('LEFT');f:SetTextColor(unpack(color or {1,.92,.75}));A:LocalizeWidget(f);f:SetText(text);return f
end
local function button(parent,text,x,y,w,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(w,27);A:LocalizeWidget(b);b:SetText(text);b:GetFontString():SetFont(A.font,11,'');b:GetFontString():SetTextColor(.95,.87,.72);b:SetScript('OnClick',fn);b:SetNormalTexture(skin..'JournalButton.tga');if b.SetPushedTexture then b:SetPushedTexture(skin..'JournalButtonDown.tga') end;if b.SetDisabledTexture then b:SetDisabledTexture(skin..'JournalButtonDown.tga') end;return b
end
local function panel(name,parent,w,h)
 local f=CreateFrame('Frame',name,parent,'BackdropTemplate');f:SetSize(w,h);f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile=skin..'JournalPanel.tga',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10});f:SetBackdropColor(1,1,1,1);f:SetBackdropBorderColor(.32,.28,.22,.85);if name and name~='MobAtlasLootCard' then local rule=f:CreateTexture(nil,'ARTWORK');rule:SetColorTexture(.65,.5,.3,.22);rule:SetPoint('TOPLEFT',18,-40);rule:SetPoint('TOPRIGHT',-18,-40);rule:SetHeight(1);f.skinHeaderRule=rule end;return f
end
function A:StyleRarityBorder(frame,color,quality)
 frame:SetBackdropColor(0,0,0,0);frame:SetBackdropBorderColor(0,0,0,0)
 if not frame.ornament then frame.ornament=frame:CreateTexture(nil,'OVERLAY');frame.ornament:SetTexture(skin..'JournalRarity.tga');frame.ornament:SetAllPoints() end
 local ornate=quality and quality>=3;frame.ornament:SetTexture(skin..(ornate and 'JournalRarityRare.tga' or 'JournalRarity.tga'))
 if frame.ornament.SetVertexColor then frame.ornament:SetVertexColor(color[1],color[2],color[3],1) end
 frame.rarityQuality=quality;frame.rarityColor={color[1],color[2],color[3]}
end
local qualityChoices={{-1,'Неизвестное',{.6,.6,.6}},{0,'Серое',{.6,.6,.6}},{1,'Белое',{1,1,1}},{2,'Зелёное',{.2,1,.2}},{3,'Синее',{.3,.6,1}},{4,'Фиолетовое',{.75,.4,1}},{5,'Легендарное',{1,.5,.1}},{6,'Артефакт',{1,.8,.5}},{7,'Наследуемое',{.4,.8,1}}}
local function check(parent,text,x,y,w,action,color)
 local c=CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',x,y);c:SetSize(24,24)
 c.caption=label(c,text,28,-5,w-28,11,color);c:SetScript('OnClick',function() action(c:GetChecked()) end);return c
end
function A:CreateSettings()
 local f=panel('MobAtlasSettings',UIParent,380,338);self.settings=f;f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function() f:StartMoving() end);f:SetScript('OnDragStop',function() f:StopMovingOrSizing() end)
 f:SetScale(math.min(1,(UIParent:GetHeight()-30)/635));tinsert(UISpecialFrames,'MobAtlasSettings')
 label(f,'Следопыт',18,-17,300,18,{1,.76,.28})
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4);close:SetScript('OnClick',function() f:Hide() end)
 local function changed() self:RefreshSettings();self:Invalidate() end
 self.toggle=check(f,'Точки на карте',18,-53,185,function(v) self.db.enabled=v;changed() end)
 self.unitButton=check(f,'Добыча на мобах',202,-53,160,function(v) self.db.unitLoot=v;changed() end)
 label(f,'Качество',18,-95,105,12)
 self.qualitySelect=button(f,'',125,-86,235,function() self.profMenu:Hide();self.qualityMenu:SetShown(not self.qualityMenu:IsShown()) end)
 self.qualityMenu=panel(nil,f,235,284);self.qualityMenu:SetPoint('TOPLEFT',self.qualitySelect,'BOTTOMLEFT',0,-2);self.qualityMenu:SetFrameLevel(f:GetFrameLevel()+40);self.qualityMenu:EnableMouse(true)
 self.qualityButtons={}
 for i,v in ipairs(qualityChoices) do local q=v[1];self.qualityButtons[q]=check(self.qualityMenu,v[2],9,-8-(i-1)*25,215,function(value) self.db.qualities[q]=value;changed() end,v[3]) end
 button(self.qualityMenu,'Все',10,-245,102,function() for q=-1,7 do self.db.qualities[q]=true end;changed() end)
 button(self.qualityMenu,'Снять все',121,-245,102,function() self.db.qualities={};changed() end);self.qualityMenu:Hide()
 label(f,'Материалы',18,-135,105,12)
 self.profSelect=button(f,'',125,-126,235,function() self.qualityMenu:Hide();self.profMenu:SetShown(not self.profMenu:IsShown()) end)
 self.profMenu=panel(nil,f,235,326);self.profMenu:SetPoint('TOPLEFT',self.profSelect,'BOTTOMLEFT',0,-2);self.profMenu:SetFrameLevel(f:GetFrameLevel()+40);self.profMenu:EnableMouse(true)
 local choices={{0,'Любая добыча'},{-2,'Все материалы'},{-1,'Мои профессии'},{197,'Портняжное дело'},{165,'Кожевничество'},{171,'Алхимия'},{164,'Кузнечное дело'},{202,'Инженерия'},{333,'Наложение чар'},{185,'Кулинария'},{129,'Первая помощь'}}
 self.profLabels={};for i,v in ipairs(choices) do local id=v[1];self.profLabels[id]=v[2];button(self.profMenu,v[2],8,-8-(i-1)*28,219,function() self.db.prof=id;self.profMenu:Hide();changed() end) end;self.profMenu:Hide()
 self.classButton=check(f,'Экипировка моего класса',18,-166,340,function(v) self.db.classOnly=v;if not v then self.db.specOnly=false end;changed() end)
 self.specButton=button(f,'',202,-166,158,function() self.specMenu:SetShown(not self.specMenu:IsShown()) end)
 local _,class=UnitClass('player');local specs=self.gearSpecs[class] or {}
 self.specMenu=panel(nil,f,235,78+#specs*28);self.specMenu:SetPoint('TOPRIGHT',self.specButton,'BOTTOMRIGHT',0,-2);self.specMenu:SetFrameLevel(f:GetFrameLevel()+45);self.specMenu:EnableMouse(true)
 local function choose(index,enabled) self.db.gearSpec=index;self.db.specOnly=enabled;if enabled then self.db.classOnly=true end;self:RefreshGearProfile();self.specMenu:Hide();if self.atlas then self.atlas.results=nil;self.atlas.page=1;self.atlas.sourceCache=nil;if enabled and self.atlas.selectedItem and not self:ClassFits(self.items[self.atlas.selectedItem],self.atlas.selectedItem,true) then self.atlas.selectedItem=nil end end;changed();if self.atlas and self.atlas:IsShown() then self:RefreshAtlas() end end
 self.specChoices={}
 local function specChoice(text,y,action,index)
  local row=button(self.specMenu,text,8,y,219,action);if index and self:SetSpecIcon(row,index) then row:GetFontString():SetPoint('CENTER',row,'CENTER',10,0) end;self.specChoices[#self.specChoices+1]=row
 end
 specChoice('Без учёта спека',-8,function() choose(nil,false) end)
 specChoice('Авто: мои таланты',-36,function() choose(nil,true) end)
 for i,p in ipairs(specs) do local index=i;specChoice(p[1],-36-i*28,function() choose(index,true) end,index) end
 self.specMenu:Hide();self.specButton:Hide()
 self.sortButton=button(f,'',18,-204,342,function() if self.db.specialFirst then self.db.specialFirst=false;self.db.sort='chance' elseif self.db.sort=='chance' then self.db.sort='quality' else self.db.specialFirst=true;self.db.sort='chance' end;changed() end)
 self.layerButton=button(f,'',18,-242,342,function() self.db.mapLayer=({all='mobs',mobs='vendors',vendors='all'})[self.db.mapLayer] or 'all';changed() end)
 button(f,'Дополнительно',18,-288,166,function() self.qualityMenu:Hide();self.profMenu:Hide();self.advanced:SetShown(not self.advanced:IsShown());f:SetHeight(self.advanced:IsShown() and 635 or 338) end)
 button(f,'К карте',194,-288,166,function() local id=WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or self:Safe(C_Map and C_Map.GetBestMapForUnit,'player');if id then local ok=self:OpenMapAt(id);if ok then f:Hide() end end end)
 self.advanced=CreateFrame('Frame',nil,f);self.advanced:SetPoint('TOPLEFT',0,-333);self.advanced:SetSize(380,290)
 label(self.advanced,'Вещей в карточке',18,-6,150,12);self.countButtons={}
 for i,n in ipairs({3,5,7}) do self.countButtons[n]=button(self.advanced,tostring(n),205+(i-1)*52,0,46,function() self.db.visibleItems=n;changed() end) end
 self.skinButton=check(self.advanced,'Снятие шкур',18,-38,170,function(v) self.db.skinning=v;changed() end)
 self.pickButton=check(self.advanced,'Карманная кража',202,-38,170,function(v) self.db.pickpocket=v;changed() end)
 self.observedButton=check(self.advanced,'Наблюдения Forever',18,-73,342,function(v) self.db.observed=v;changed() end)
 self.sharedButton=check(self.advanced,'Общий / условный дроп',18,-105,342,function(v) self.db.sharedLoot=v;changed() end)
 self.vendorLevelButton=check(self.advanced,'Покупки: мой уровень и ниже',18,-137,342,function(v) self.db.vendorLevel=v;changed() end)
 self.relevantButton=check(self.advanced,'Торговцы: полезное моему персонажу',18,-169,342,function(v) self.db.vendorRelevant=v;changed() end)
 label(self.advanced,'Точки: QuestieDB Forever, справочник.\nForever: окна добычи, способ не разделён.\nДанные Everloot · CC BY-SA 4.0 · everloot.app',18,-209,342,10,{.75,.75,.7})
 self.advanced:Hide()
 f:SetScript('OnShow',function() if self.tip then self.tip:Hide() end end)
 f:SetScript('OnHide',function() self.qualityMenu:Hide();self.profMenu:Hide();self.specMenu:Hide() end)
 f:Hide();self:CreateLootCard();self:RefreshSettings()
end
function A:RefreshSettings()
 self.specButton:SetText(not self.db.specOnly and 'Спек: любой  v' or self.gearProfile and ((self.db.gearSpec and '' or 'Авто: ')..self.gearProfile[1]..'  v') or 'Спек: выбери  v')
 self.layerButton:SetText('Карта: '..(({all='мобы и торговцы',mobs='только мобы',vendors='только торговцы',none='только подземелья'})[self.db.mapLayer] or 'мобы и торговцы'))
 for _,pair in ipairs({{self.toggle,'enabled'},{self.unitButton,'unitLoot'},{self.classButton,'classOnly'},{self.skinButton,'skinning'},{self.pickButton,'pickpocket'},{self.observedButton,'observed'},{self.sharedButton,'sharedLoot'},{self.vendorLevelButton,'vendorLevel'},{self.relevantButton,'vendorRelevant'}}) do pair[1]:SetChecked(self.db[pair[2]]) end
 local names={};for _,v in ipairs(qualityChoices) do self.qualityButtons[v[1]]:SetChecked(self.db.qualities[v[1]]);if self.db.qualities[v[1]] then names[#names+1]=v[2] end end
 self.qualitySelect:SetText((#names==9 and 'Все качества' or #names==0 and 'Ничего не выбрано' or #names<=2 and table.concat(names,' + ') or ('Выбрано качеств: '..#names))..'  ▾')
 self.profSelect:SetText((self.profLabels[self.db.prof] or 'Любая добыча')..'  ▾')
 self.sortButton:SetText(self.db.specialFirst and 'Порядок: особенное в начале' or self.db.sort=='chance' and 'Порядок: чаще выпадает' or 'Порядок: редкость вещи')
 for n,b in pairs(self.countButtons) do if n==self.db.visibleItems then b:Disable() else b:Enable() end end
end
local colors={[-1]={.55,.55,.55},[0]={.62,.62,.62},[1]={1,1,1},[2]={.12,1,.12},[3]={.1,.45,1},[4]={.64,.21,.93},[5]={1,.5,0},[6]={.9,.8,.5},[7]={0,.8,1}}
local qualities={[0]='Низкое',[1]='Обычное',[2]='Необычное',[3]='Редкое',[4]='Эпическое',[5]='Легендарное',[6]='Артефакт',[7]='Наследуемое'}
function A:CreateLootCard()
 local t=panel('MobAtlasLootCard',UIParent,300,260);t:SetScale(math.min(.8,(UIParent:GetHeight()-30)/350,(UIParent:GetWidth()-30)/300));self.tip=t;t:SetFrameStrata('TOOLTIP');t:EnableMouse(true)
 tinsert(UISpecialFrames,'MobAtlasLootCard')
 t.portrait=t:CreateTexture(nil,'ARTWORK');t.portrait:SetSize(28,28);t.portrait:SetPoint('TOPLEFT',12,-12)
 t.title=label(t,'',48,-12,216,13,{1,.8,.35})
 t.subtitle=label(t,'',48,-32,235,10,{.72,.75,.68});t.subtitle:SetWordWrap(false)
 t.headerLine=t:CreateTexture(nil,'ARTWORK');t.headerLine:SetColorTexture(.75,.61,.3,.25);t.headerLine:SetPoint('TOPLEFT',12,-51);t.headerLine:SetSize(276,1)
 t.footerLine=t:CreateTexture(nil,'ARTWORK');t.footerLine:SetColorTexture(.75,.61,.3,.20);t.footerLine:SetSize(276,1)
 t.close=CreateFrame('Button',nil,t,'UIPanelCloseButton');t.close:SetPoint('TOPRIGHT',-3,-3);t.close:SetScript('OnClick',function() self:CloseInspection() end)
 t.unpin=button(t,'Открепить',164,-300,122,function() local pin=self.inspectPin or self.hoverPin;if self:IsInspectionTracked(pin) then self:ClearFocus(true,true) else self:PinInspection() end end);t.unpin:Hide()
 t.lootMode=button(t,'Вся добыча',14,-300,272,function()
  local pin=self.inspectPin or self.hoverPin
  if pin then self:FreezeInspection(pin);self.inspectPin=pin;pin.fullLoot=not pin.fullLoot;pin.page=1;self:ShowTooltip(pin,true) end
 end);t.lootMode:Hide()
 t.rows={}
 for i=1,7 do
  local r=CreateFrame('Button',nil,t);r:SetPoint('TOPLEFT',12,-58-(i-1)*40);r:SetSize(276,39)
  r.tint=r:CreateTexture(nil,'BACKGROUND');r.tint:SetAllPoints();r.tint:SetColorTexture(0,0,0,0)
  r.icon=r:CreateTexture(nil,'ARTWORK');r.icon:SetSize(26,26);r.icon:SetPoint('TOPLEFT',1,-5)
  r.rarityBorder=CreateFrame('Frame',nil,r,'BackdropTemplate');r.rarityBorder:SetPoint('TOPLEFT',-2,-2);r.rarityBorder:SetSize(32,32);r.rarityBorder:EnableMouse(false)
  r.rarityBorder:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
  r.rarityBorder:Hide()
  r.name=label(r,'',38,-4,220,12);r.name:SetWordWrap(false);r.meta=label(r,'',38,-23,220,10,{.8,.8,.7})
  r.hover=r:CreateTexture(nil,'BACKGROUND');r.hover:SetAllPoints();r.hover:SetColorTexture(1,.78,.3,.12);r.hover:Hide()
  r.arrow=label(r,'>',260,-10,14,14,{1,.82,.4});r.arrow:Hide()
  r.separator=r:CreateTexture(nil,'BACKGROUND');r.separator:SetColorTexture(1,1,1,.04);r.separator:SetPoint('BOTTOMLEFT',38,0);r.separator:SetSize(235,1)
  r:SetScript('OnEnter',function(b) self.previewSerial=(self.previewSerial or 0)+1;b.hover:Show();b.arrow:SetShown(b.npcID~=nil);if (self.inspectPin or self.hoverPin) and b.npcID then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,self.mobs[b.npcID].name);self:AddTooltipLine(GameTooltip,'Нажми: посмотреть предметы');GameTooltip:Show();return end;if (self.inspectPin or self.hoverPin) and b.itemID then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');GameTooltip:SetHyperlink('item:'..b.itemID);self:ItemEvidence(GameTooltip,b.entry);GameTooltip:Show() end end)
  r:SetScript('OnLeave',function(b) b.hover:Hide();b.arrow:Hide();GameTooltip:Hide();self:SchedulePreviewHide(self.hoverPin) end)
  r:SetScript('OnClick',function(b)
   local p=self.inspectPin or self.hoverPin;if not p then return end
   self:FreezeInspection(p);self.inspectPin=p
   if b.npcIndex then p.mobIndex=b.npcIndex;p.selected=true;p.page=1;p.fullLoot=nil;GameTooltip:Hide();self:ShowTooltip(p,true);if self.PreviewMobHabitat then self:PreviewMobHabitat(p) end
   elseif b.itemID then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');GameTooltip:SetHyperlink('item:'..b.itemID);self:ItemEvidence(GameTooltip,b.entry);GameTooltip:Show() end
  end)
  t.rows[i]=r
 end
 t.prev=button(t,'‹',14,-340,35,function() local p=self.inspectPin or self.hoverPin;if p then p.page=p.page-1;self:ShowTooltip(p,true) end end)
 t.next=button(t,'›',391,-340,35,function() local p=self.inspectPin or self.hoverPin;if p then p.page=p.page+1;self:ShowTooltip(p,true) end end)
 t.pageText=label(t,'',60,-345,320,11);t.pageText:SetJustifyH('CENTER')
 t.mobNext=button(t,'Другой моб в этой точке',14,-375,412,function() local p=self.inspectPin or self.hoverPin;if p then p.selected=false;p.page=1;self:ShowTooltip(p,true);if self.PreviewMobHabitat then self:PreviewMobHabitat(p) end end end)
 -- Provenance is available in settings and individual item tooltips.
 t:SetScript('OnEnter',function() self.previewSerial=(self.previewSerial or 0)+1 end)
 t:SetScript('OnLeave',function() self:SchedulePreviewHide(self.hoverPin) end)
 t:SetScript('OnHide',function() self:ClearHabitat();self.inspectPin=nil;self.hoverPin=nil;self.pinned=nil;self.focusGroup=nil;t.stableAnchor=nil;t.stablePin=nil;t.anchorPin=nil;GameTooltip:Hide();if self.focus then self:RenderFocus() end end)
 t:EnableMouseWheel(true);t:SetScript('OnMouseWheel',function(_,delta) local p=self.inspectPin or self.hoverPin;if p then p.page=(p.page or 1)-delta;self:ShowTooltip(p,true) end end)
 t:Hide()
end
function A:ShowTooltip(pin,force)
 if self.settings:IsShown() then return end
 if self.inspectPin and self.inspectPin~=pin and not force then return end
 self.hoverPin=pin

 if #pin.cell.ids>1 and not pin.selected then self:ShowGroupTooltip(pin);return end
 local t=self.tip;local id=pin.cell.ids[pin.mobIndex or 1];local mob=self.mobs[id];local exact=self.focus and self.focus.itemID
 local limited=not mob.vendor and (self.db.specialMobsOnly or exact~=nil)
 local rows=self:FocusedLoot(id,pin.fullLoot)
 local n=self.db.visibleItems;local pages=math.max(1,math.ceil(#rows/n));pin.page=math.min(math.max(1,pin.page or 1),pages);pin.pages=pages
 self:AnchorInspection(pin)
 local shown=math.min(n,math.max(0,#rows-(pin.page-1)*n));local multiple=#pin.cell.ids>1

 t.title:SetText(mob.name);t.title:SetWordWrap(false);self:SetNpcPortrait(t.portrait,id)
 t.subtitle:SetText(pin.cell.dungeon and ('Вход: '..self.instances[pin.cell.dungeon].name) or mob.vendor and 'Торговец · экипировка, сумки, ремесло' or ((mob.min>0 and ('Ур. '..mob.min..'–'..mob.max..' · ') or '')..self:CreatureKind(mob)))
 if #rows==0 then t.subtitle:SetText(not mob.vendor and #(mob.loot or {})==0 and 'Добыча пока неизвестна.' or (limited and not pin.fullLoot and 'Нет редкой добычи по фильтрам' or 'Нет вещей по текущим фильтрам')) end
 for i,r in ipairs(t.rows) do
  local e=i<=n and rows[(pin.page-1)*n+i] or nil;r:SetShown(e~=nil);r.itemID=e and e[1] or nil;r.npcID=nil;r.npcIndex=nil;r.rarityBorder:SetShown(e~=nil)
  r.special=nil;r.hover:Hide();r.arrow:Hide()
  if e then
   r.icon.mobAtlasNpcID=nil;local item=self.items[e[1]];local name,icon=self:ItemDisplay(e[1]);r.icon:SetTexture(icon)
   local c=colors[item.quality] or {.6,.6,.6};self:StyleRarityBorder(r.rarityBorder,c,item.quality);r.itemQuality=item.quality
   r.name:SetText(name);r.name:SetTextColor(unpack(colors[item.quality] or {1,.8,.4}))
   local specialRank,specialName=self:SpecialRank(e[1]);local first=specialRank>0
   for j=1,(pin.page-1)*n+i-1 do if self:SpecialRank(rows[j][1])==specialRank then first=false;break end end
   r.special=first and specialName or nil;r.tint:SetColorTexture(c[1],c[2],c[3],first and .14 or 0)
   r.meta:SetText((e[4] and 'Общий / условный · справочник' or e[2]==5 and 'У продавца' or (e[3]<0 and not e[4] and e[2]~=8 and e[2]~=14 and 'Шанс не измерен' or self:Chance(e)))..(e[2]==2 and ' · шкуры' or e[2]==3 and ' · кража' or ''))
   r.meta:SetWordWrap(false);r.entry=e
  end
 end
 t.lootMode:SetText(pin.fullLoot and (exact and 'Выбранный предмет' or 'Редкая добыча') or 'Вся добыча')
 t.mobNext:SetText(pin.cell.vendor and 'К торговцам' or 'К группе мобов')
 self:LayoutLootCard(pin,shown,pages,#pin.cell.ids>1,limited);t:Show()
end
function A:CreateMinimapButton()
 if not Minimap then return end
 local b=CreateFrame('Button','MobAtlasMinimapButton',Minimap);self.minimapButton=b;b:SetSize(30,30);b:SetFrameLevel(Minimap:GetFrameLevel()+10)
 b:SetNormalTexture('Interface\\AddOns\\MobAtlas\\Art\\TrackAtlas.tga');b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton')
 local function place() local angle=math.rad(self.db.minimapAngle);b:ClearAllPoints();b:SetPoint('CENTER',Minimap,'CENTER',math.cos(angle)*(Minimap:GetWidth()/2+10),math.sin(angle)*(Minimap:GetHeight()/2+10)) end
 place()
 b:SetScript('OnDragStart',function() b.dragging=true;b:SetScript('OnUpdate',function() local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale();self.db.minimapAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx));place() end) end)
 b:SetScript('OnDragStop',function() b:SetScript('OnUpdate',nil);b.dragging=false end)
 b:SetScript('OnClick',function(_,mouse) if b.dragging then return end;if mouse=='RightButton' then self:ToggleTrackingMenu(b) else self:OpenAtlas() end;self:RefreshSettings() end)
 b:SetScript('OnEnter',function() GameTooltip:SetOwner(b,'ANCHOR_LEFT');self:AddTooltipLine(GameTooltip,'MobAtlas · Следопыт');self:AddTooltipLine(GameTooltip,'ЛКМ: атлас · ПКМ: отслеживание');self:AddTooltipLine(GameTooltip,'Перетащи: переместить кнопку');GameTooltip:Show() end)
 b:SetScript('OnLeave',function() GameTooltip:Hide() end)
end
function A:UnitLootTooltip(tooltip)
 if not self.db.unitLoot then return end
 local _,unit=tooltip:GetUnit();unit=unit or 'mouseover';local id=self:NpcID(unit)
 if not id or tooltip.mobAtlasID==id then return end
 if not self.mobs[id] and self.EnsureObservedNpc then self:EnsureObservedNpc(id) end
 if not self.mobs[id] then return end
 tooltip.mobAtlasID=id;local rows=self:Loot(id,self:Professions(),true,true)
 self:AddTooltipLine(tooltip,' ');self:AddTooltipLine(tooltip,self.mobs[id].vendor and 'Следопыт · в продаже' or 'Следопыт · возможная добыча',1,.8,.35)
 if #rows==0 then self:AddTooltipLine(tooltip,#(self.mobs[id].loot or {})==0 and 'Добыча пока неизвестна. Находки будут сохраняться.' or 'Нет вещей по текущим фильтрам',.7,.7,.7) end
 for i=1,math.min(#rows,self.db.visibleItems) do
  local e=rows[i];local item=self.items[e[1]];local name,icon=self:ItemDisplay(e[1]);local c=colors[item.quality] or {1,.8,.4}
  self:AddTooltipLine(tooltip,'|T'..icon..':18|t '..name..' · '..self:Chance(e),unpack(c))
 end
 if #rows>self.db.visibleItems then self:AddTooltipLine(tooltip,'Показано: '..self.db.visibleItems..' из '..#rows..(self.db.specialMobsOnly and not self.mobs[id].vendor and ' · на карте: «Вся добыча».' or ' · остальное в карточке на карте.'),.7,.75,.7) end
 self:AddTooltipLine(tooltip,'Everloot · CC BY-SA 4.0; Classic — справка',.7,.7,.7)
 tooltip:Show()
end
function A:HookUnitLoot()
 if not GameTooltip then return end
 if GameTooltip.HookScript then
  GameTooltip:HookScript('OnTooltipCleared',function(t) t.mobAtlasID=nil end)
 end
 if TooltipDataProcessor and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(t) self:UnitLootTooltip(t) end)
 elseif GameTooltip.HookScript then
  GameTooltip:HookScript('OnTooltipSetUnit',function(t) self:UnitLootTooltip(t) end)
 end
end
-- Map detail providers can rebuild their layers after the pins are created.
-- Follow the current canvas stack; exclude our own frames to avoid level escalation.
function A:MapPinLayer(map,canvas)
 local ranks={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
 local strata=map.GetFrameStrata and map:GetFrameStrata() or 'MEDIUM'
 local level=math.max(map:GetFrameLevel(),canvas:GetFrameLevel())
 local manager=self:Safe(map.GetPinFrameLevelsManager,map)
 local native=manager and self:Safe(manager.GetValidFrameLevel,manager,'PIN_FRAME_LEVEL_AREA_POI',1)
 if type(native)=='number' then
  level=math.max(level,native)
  -- Leatrix adds revealed terrain textures to this Blizzard pin.
  if map.EnumeratePinsByTemplate then
   for terrain in map:EnumeratePinsByTemplate('MapExplorationPinTemplate') do
    level=math.max(level,terrain:GetFrameLevel()+1)
   end
  end
  return level,strata
 end
 local function visit(frame,depth)
  if frame.mobAtlasPin or depth>12 then return end
  local value=frame.GetFrameStrata and frame:GetFrameStrata() or strata
  if (ranks[value] or 3)>(ranks[strata] or 3) then strata=value;level=frame:GetFrameLevel()
  elseif value==strata then level=math.max(level,frame:GetFrameLevel()) end
  if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do visit(child,depth+1) end end
 end
 visit(canvas,0)
 return level+2,strata
end
function A:Update()
 if not self.db then return end
 if self.HasHabitatSelection and not self:HasHabitatSelection() then self:HideHabitatAreas() end
 local map=WorldMapFrame
 if not map or not map:IsShown() or not map.GetCanvas or not map.GetMapID then
  if self.tip then self.tip:Hide() end;self:ClearHabitat()
  for _,pin in ipairs(self.pins or {}) do pin:Hide() end
  for _,pin in ipairs(self.dungeonPins or {}) do pin:Hide() end
  for _,pin in ipairs(self.rareWorldPins or {}) do pin:Hide() end
  self.lastMap=nil;return
 end
 local canvas=map:GetCanvas();if not canvas then return end
 if self.IsExternalDungeonPreview and self:IsExternalDungeonPreview(canvas) then
  for _,pin in ipairs(self.pins or {}) do pin:Hide() end
  for _,pin in ipairs(self.dungeonPins or {}) do pin:Hide() end
  for _,pin in ipairs(self.rareWorldPins or {}) do pin:Hide() end
  self:ClearHabitat();if self.tip then self.tip:Hide() end
  if self.mapButton then self.mapButton:Hide();self.mapStatus:Hide();self.focusButton:Hide();self.specialMapCheck:Hide() end
  self.lastMap=nil;return
 end
 if self.mapButton then self.mapButton:Show();self.mapStatus:Show();self.specialMapCheck:Show() end
 if not self.mapButton then
  self.mapButton=button(map,'Следопыт · атлас',15,-35,160,function() self:OpenAtlas() end)
  self.mapButton:ClearAllPoints();self.mapButton:SetPoint('BOTTOMLEFT',map,'BOTTOMLEFT',18,30);self.mapButton:SetFrameLevel(map:GetFrameLevel()+30)
  self.mapStatus=label(map,'',208,-35,500,11,{1,.9,.65});self.mapStatus:ClearAllPoints();self.mapStatus:SetPoint('BOTTOMLEFT',map,'BOTTOMLEFT',188,62)
  self.specialMapCheck=check(map,'Мобы с редкой добычей',0,0,205,function(value)
   self.db.specialMobsOnly=value
   self.dirty=true
   self:Update()
  end)
  self.specialMapCheck:ClearAllPoints()
  self.specialMapCheck:SetPoint('BOTTOMLEFT',map,'BOTTOMLEFT',188,31)
  self.specialMapCheck:SetScript('OnEnter',function(control)
   GameTooltip:SetOwner(control,'ANCHOR_RIGHT')
   self:AddTooltipLine(GameTooltip,'Метки показывают мобов с редкой добычей. В карточке видны также синие вещи и выше из общих пулов.',1,.85,.55)
   GameTooltip:Show()
  end)
  self.specialMapCheck:SetScript('OnLeave',function() GameTooltip:Hide() end)
  self.focusButton=button(map,'Снять выделение',188,-35,155,function()
   if self.focus and self.focus~=self.questFocus then self:ClearFocus(true,true)
   elseif self.questFocus then self:UnpinQuest()
   else self:ClearFocus() end
  end)
  self.focusButton:ClearAllPoints();self.focusButton:SetPoint('BOTTOMLEFT',map,'BOTTOMLEFT',18,63);self.focusButton:Hide()
 end
 self.specialMapCheck:SetChecked(self.db.specialMobsOnly)
 local pinLevel,pinStrata=self:MapPinLayer(map,canvas)
 self.specialMapCheck:SetFrameStrata('TOOLTIP');self.specialMapCheck:SetFrameLevel(pinLevel+30)
 self.focusButton:SetFrameStrata('TOOLTIP');self.focusButton:SetFrameLevel(pinLevel+30)
 local pinScale=map:GetEffectiveScale()/math.max(.01,canvas:GetEffectiveScale())
 for _,pin in ipairs(self.pins or {}) do pin:SetFrameLevel(pinLevel);pin:SetFrameStrata(pinStrata);pin:SetScale(pinScale) end
 for _,point in ipairs(self.habitatPins or {}) do point:SetFrameLevel(pinLevel+1);point:SetFrameStrata(pinStrata) end
 local mapID=map:GetMapID();local width,height=canvas:GetWidth(),canvas:GetHeight()
 if self.UpdateDungeonPins then self:UpdateDungeonPins(canvas,pinScale,pinLevel,pinStrata) end
 if self.UpdateRareWorld then self:UpdateRareWorld(canvas,pinScale,pinLevel,pinStrata) end
 self.focusButton:SetText(self.questFocus and 'Открепить' or 'Снять выделение');self.focusButton:SetShown(self.focus~=nil or self.questFocus~=nil)
 -- While inspecting a habitat, zoom its same source members instead of replacing the selection.
 if self.focusGroup and self.pinned and not self.dirty and self.lastMap==mapID and self.lastCanvas==canvas then
  if self.lastWidth==width and self.lastHeight==height and self.lastPinScale==pinScale then return end
  for _,p in ipairs(self.pins or {}) do if p.cell and p.cell.x and p.cell.y then
   p:ClearAllPoints();p:SetPoint('CENTER',canvas,'TOPLEFT',width*p.cell.x/100/pinScale,-height*p.cell.y/100/pinScale)
  end end
  self.lastWidth=width;self.lastHeight=height;self.lastPinScale=pinScale;self:ShowHabitat(self.pinned);return
 end
 if not self.dirty and self.lastMap==mapID and self.lastWidth==width and self.lastHeight==height and self.lastCanvas==canvas and self.lastPinScale==pinScale then return end
 self.dirty=false;self.lastMap=mapID;self.lastWidth=width;self.lastHeight=height;self.lastCanvas=canvas;self.lastPinScale=pinScale
 if self.tip then self.tip:Hide() end
 self:ClearHabitat();self.pins=self.pins or {};for _,pin in ipairs(self.pins) do pin:Hide() end
 if not self.db.enabled then self.mapStatus:SetText('Метки выключены');return end
 local cells,total=self:BuildMap(mapID);cells=self:CompactPoints(cells,width/pinScale,height/pinScale)
 self.focusButton:SetShown(self.focus~=nil or self.questFocus~=nil)
 local customHere=false;for _,p in ipairs(self.focus and self.focus.points or {}) do if p[1]==mapID then customHere=true end end
 self.mapStatus:SetText(self.focus and ('Выбрано: '..self.focus.label..(total==0 and not customHere and ' · нет точек на этой карте' or '')) or total>0 and ('Групп: '..#cells..' · NPC: '..total..' · QuestieDB · выбранная зона') or self.zoneIndex[mapID] and 'Нет добычи по фильтрам — измените настройки' or 'Для этой карты пока нет подходящих точек')
 for i,cell in ipairs(cells) do
  local pin=self.pins[i]
  if not pin then
   pin=CreateFrame('Button',nil,canvas);pin.mobAtlasPin=true;pin:SetSize(20,20);pin:SetFrameLevel(pinLevel);pin:SetFrameStrata(pinStrata)
   pin.dot=pin:CreateTexture(nil,'OVERLAY');pin.dot:SetSize(16,16);pin.dot:SetPoint('CENTER');pin.dot:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\MobDot.tga')
   pin:EnableMouseWheel(true);pin:RegisterForClicks('LeftButtonUp','RightButtonUp')
   pin:SetScript('OnEnter',function(b) b.hovered=true;self:StyleGroupPin(b);self.previewSerial=(self.previewSerial or 0)+1;self:ShowTooltip(b) end)
   pin:SetScript('OnLeave',function(b) b.hovered=false;self:StyleGroupPin(b);self:SchedulePreviewHide(b) end)
   pin:SetScript('OnMouseWheel',function(b,delta) if not self.inspectPin or self.inspectPin==b then b.page=(b.page or 1)-delta;self:ShowTooltip(b) end end)
   pin:SetScript('OnClick',function(b,mouse) if mouse=='RightButton' then self:CloseInspection();self.settings:Show();self:RefreshSettings() elseif not self.settings:IsShown() then self:InspectPin(b) end end)
   self.pins[i]=pin
  end
  pin:SetParent(canvas);pin:SetFrameLevel(pinLevel);pin:SetFrameStrata(pinStrata);pin:SetScale(pinScale);pin.dot:SetSize(16,16)
  pin.cell=cell;pin.page=1;pin.mobIndex=1;pin.selected=false;pin.fullLoot=nil;self:StyleGroupPin(pin)
  pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',width*cell.x/100/pinScale,-height*cell.y/100/pinScale);pin:Show()
 end
 self.dirty=false;if self.focus then self:RenderFocus() end
end

function A:AddTooltipLine(t,text,...)
 t:AddLine(self:L(text),...)
 if t.GetName and t.NumLines then
  local name=t:GetName();local line=name and _G[name..'TextLeft'..t:NumLines()]
  if line then line:SetFont(self.font,11,'') end
 end
end

function A:ItemEvidence(t,e)
 if not e then return end
 self:AddTooltipLine(t,self.methods[e[2]]..' · '..self:Chance(e),.8,.8,.7);self:ItemMetadataCredit(t,e[1])
 if e.alternatives and #e.alternatives>1 then
  self:AddTooltipLine(t,'Другие записи (проценты не складываются):',.7,.7,.7)
  for _,other in ipairs(e.alternatives) do if other[2]~=e[2] then self:AddTooltipLine(t,self.methods[other[2]]..' · '..self:Chance(other),.7,.7,.7) end end
 end
 if e[2]==14 then self:AddTooltipLine(t,'Связь добавлена по сообщению игрока. Шанс и частота не измерены.',.8,.8,.7) end
 if e[2]==9 then self:AddTooltipLine(t,'vMaNGOS Classic через wow-forever-kb; требует проверки на Forever.',.7,.7,.7) end
 if e[2]==8 then self:AddTooltipLine(t,'Предмет был в окне добычи этого NPC на этом клиенте.',.8,.9,.7);self:AddTooltipLine(t,'Способ получения не определён; шанс не рассчитывается.',.7,.7,.7) end
  if e[2]==7 then self:AddTooltipLine(t,'Связь из справочника Forever; частота не измерена.',.7,.7,.7) end
 if e[4] then self:AddTooltipLine(t,'Общий или условный дроп; может зависеть от условий.',.7,.7,.7) end
 if self:SpecialRank(e[1])>0 then self:AddTooltipLine(t,'Особенное: категория / редкость, затем известный шанс.',1,.82,.45);self:AddTooltipLine(t,'№1 — первое в категории этой карточки, не BiS.',.7,.7,.7) end
 if e[2]==6 then self:AddTooltipLine(t,'Цена и наличие на момент последнего визита.',.7,.7,.7) end
 if e[2]==4 then
  self:AddTooltipLine(t,e[5]..' выпадений / '..e[6]..' окон · '..e[7]..' источников',.8,.8,.7)
  if e[8] then self:AddTooltipLine(t,'Снимок наблюдений: '..e[8],.7,.7,.7) end
  self:AddTooltipLine(t,'Everloot · CC BY-SA 4.0 · everloot.app',.7,.7,.7)
 end
end

local kindNames={Beast='Зверь',Humanoid='Гуманоид',Undead='Нежить',Demon='Демон',Dragonkin='Дракон',Elemental='Элементаль',Mechanical='Механизм',Giant='Великан',Critter='Животное'}
local kindIcons={Beast='Ability_Hunter_BeastCall',Humanoid='INV_Misc_Head_Human_01',Undead='Spell_Shadow_RaiseDead',Demon='Spell_Shadow_SummonFelGuard',Dragonkin='INV_Misc_Head_Dragon_01',Elemental='Spell_Fire_Elemental_Totem',Mechanical='INV_Gizmo_02',Giant='Ability_Racial_Avatar'}
function A:CreatureKind(mob) return kindNames[mob.kind] or 'Существо' end
function A:CreatureIcon(mob)
 return 'Interface\\Icons\\'..(mob.vendor and 'INV_Misc_Bag_10' or kindIcons[mob.kind] or 'INV_Misc_Note_01')
end
-- Compact original symbols share the game's brass-and-parchment palette.
function A:StyleGroupPin(pin)
 local vendor=self.mobs[pin.cell.ids[1]].vendor;local selected=false
 if self.focus then for _,id in ipairs(pin.cell.ids) do if self.focus.ids[id] then selected=true;break end end end
 pin.dot:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\'..(pin.cell.dungeon and 'MarkerDungeon.tga' or vendor and 'MarkerVendor.tga' or 'MarkerMob.tga'))
 pin.dot:SetTexCoord(0,1,0,1)
 local size=18;if selected or pin.hovered then size=size+2 end;pin.dot:SetSize(size,size)
 if pin.dot.SetAlpha then pin.dot:SetAlpha(selected and 1 or pin.hovered and 1 or .95) end
 if not pin.glow then
  pin.glow=pin:CreateTexture(nil,'BACKGROUND');pin.glow:SetPoint('CENTER');pin.glow:SetSize(27,27)
  if pin.glow.SetAtlas and self:Safe(C_Texture and C_Texture.GetAtlasInfo,'UI-QuestPoi-OuterGlow') then pin.glow:SetAtlas('UI-QuestPoi-OuterGlow')
  else pin.glow:SetTexture('Interface\\Buttons\\UI-ActionButton-Border') end
  if pin.glow.SetBlendMode then pin.glow:SetBlendMode('ADD') end
 end
 if pin.glow.SetVertexColor then pin.glow:SetVertexColor(1,.82,.34,.3) end
 pin.glow:SetShown(selected)
 if pin.special then pin.special:SetText('');pin.special:Hide() end
 if pin.count then pin.count:SetText('');pin.count:Hide() end
 pin.isFocused=selected
end
function A:CompactPoints(cells,width,height)
 -- Fixed-radius cover, not connected components: a chain of spawns cannot merge a whole zone.
 -- Every anchor is an actual source coordinate. Vendors use a smaller radius and separate groups.
 local out={}
 for _,cell in ipairs(cells) do
  for _,id in ipairs(cell.ids) do
   local vendor=self.mobs[id].vendor==true;local radius=vendor and 24 or 64
   local best,distance=nil,radius*radius
   for _,group in ipairs(out) do if group.vendor==vendor and group.dungeon==cell.dungeon then
    local dx=(cell.x-group.x)*width/100;local dy=(cell.y-group.y)*height/100;local d=dx*dx+dy*dy
    if d<=distance then best=group;distance=d end
   end end
   if not best then best={x=cell.x,y=cell.y,ids={},seen={},locations=0,pointKeys={},members={},memberKeys={},vendor=vendor,dungeon=cell.dungeon};out[#out+1]=best end
   if not best.seen[id] then best.seen[id]=true;best.ids[#best.ids+1]=id end
   local memberKey=id..':'..cell.x..':'..cell.y
   if not best.memberKeys[memberKey] then best.memberKeys[memberKey]=true;best.members[#best.members+1]={id=id,x=cell.x,y=cell.y} end
   local key=cell.x..':'..cell.y
   if not best.pointKeys[key] then best.pointKeys[key]=true;best.locations=best.locations+1 end
  end
 end
 for _,cell in ipairs(out) do table.sort(cell.ids) end
 return out
end
function A:ShowGroupTooltip(pin)
 local t=self.tip;local n=self.db.visibleItems;local ids=pin.cell.ids
 local pages=math.max(1,math.ceil(#ids/n));pin.page=math.min(math.max(1,pin.page or 1),pages);pin.pages=pages
 local count=math.min(n,#ids-(pin.page-1)*n)
 self:AnchorInspection(pin)
 t.title:SetText((pin.cell.dungeon and self.instances[pin.cell.dungeon].name..' · вход' or pin.cell.vendor and 'Торговцы рядом' or 'Группа мобов')..' · '..#ids)
 t.portrait.mobAtlasNpcID=nil;t.portrait:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\'..(pin.cell.vendor and 'TrackVendor.tga' or 'TrackMob.tga'))
 t.subtitle:SetText(pin.cell.dungeon and 'Вход в подземелье, не позиция босса' or pin.cell.vendor and 'Выбери торговца, чтобы посмотреть товары' or 'Выбери моба, чтобы посмотреть добычу')
 for i,r in ipairs(t.rows) do
  local index=(pin.page-1)*n+i;local id=i<=n and ids[index] or nil
  r:SetShown(id~=nil);r.hover:Hide();r.arrow:Hide();r.tint:SetColorTexture(0,0,0,0);r.rarityBorder:Hide();r.itemID=nil;r.entry=nil;r.npcID=id;r.npcIndex=id and index or nil
  if id then
   local mob=self.mobs[id];self:SetNpcPortrait(r.icon,id);r.name:SetText(mob.name);r.name:SetTextColor(1,.86,.54)
   r.meta:SetText((mob.vendor and 'Продавец' or ('Ур. '..mob.min..'–'..mob.max))..' · предметов: '..#self:FocusedLoot(id))
  end
 end
 self:LayoutLootCard(pin,count,pages,false);t:Show()
end

function A:ClearHabitat()
 if self.HideHabitatAreas then self:HideHabitatAreas() end
 for _,point in ipairs(self.habitatPins or {}) do point:Hide() end
end
function A:ShowHabitat(pin)
 local selected=pin.selected and pin.cell.ids[pin.mobIndex or 1] or nil
 local ids={};for _,id in ipairs(pin.cell.ids) do if not selected or selected==id then ids[id]=true end end
 local itemID=self.focus and self.focus.itemID
 self.focus={ids=ids,itemID=itemID,label=itemID and self:ItemDisplay(itemID) or selected and self.mobs[selected].name or pin.cell.dungeon and self.instances[pin.cell.dungeon].name or ('Группа · '..#pin.cell.ids..' NPC')}
 self.habitatPinnedFocus=self.focus
 self.focusGroup=pin
 for _,other in ipairs(self.pins or {}) do other:SetShown(other==pin);if other.cell then self:StyleGroupPin(other) end end
 if self.focusButton then self.focusButton:Show() end
 if self.mapStatus then self.mapStatus:SetText('Выбрано: '..self.focus.label) end
 self:RenderFocus()
end
function A:RenderFocus()
 self:ClearHabitat()
 local map=WorldMapFrame;local canvas=map and map.GetCanvas and map:GetCanvas()
 if not self.focus or not canvas or not map:IsShown() then return end
 local cells=self:BuildMap(map:GetMapID());self.habitatPins=self.habitatPins or {}
 local scale=map:GetEffectiveScale()/math.max(.01,canvas:GetEffectiveScale());local level,strata=self:MapPinLayer(map,canvas);local used=0
 local showHabitat=not self.HasHabitatSelection or self:HasHabitatSelection()
 if showHabitat and self.RenderHabitatArea then self:RenderHabitatArea(cells,canvas,scale,level,strata) end
 for _,cell in ipairs(showHabitat and self:ReadableFocusCells(cells,canvas,scale) or {}) do if not cell.dungeon then
  used=used+1;local point=self.habitatPins[used]
  if not point then
   point=CreateFrame('Frame',nil,canvas);point.mobAtlasPin=true;point:EnableMouse(false);point:SetSize(7,7)
   point.dot=point:CreateTexture(nil,'OVERLAY');point.dot:SetAllPoints();point.dot:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\MobDot.tga')
   self.habitatPins[used]=point
  end
  point:SetSize(self.focus.explicitMap and 13 or 8,self.focus.explicitMap and 13 or 8);point:EnableMouse(false);if point.dot.SetVertexColor then point.dot:SetVertexColor(1,.88,.45,1) end;point.dot:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\MobDot.tga');point.npcID=cell.ids[1];point.sourceX=cell.x;point.sourceY=cell.y
  point:SetParent(canvas);point:SetScale(scale);point:SetFrameLevel(level+1);point:SetFrameStrata(strata)
  point:ClearAllPoints();point:SetPoint('CENTER',canvas,'TOPLEFT',canvas:GetWidth()*cell.x/100/scale,-canvas:GetHeight()*cell.y/100/scale);point:Show()
 end end
 self:RenderLocationFocus(canvas,scale,level,strata,used)
end

local classCoords={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},HUNTER={0,.25,.25,.5},SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75},DEATHKNIGHT={.25,.5,.5,.75}}
local specIcons={
 ROGUE={'Ability_Rogue_Eviscerate','Ability_BackStab','Ability_Stealth'},
 WARRIOR={'Ability_Warrior_SavageBlow','Ability_Warrior_InnerRage','Ability_Warrior_DefensiveStance'},
 PALADIN={'Spell_Holy_HolyBolt','Spell_Holy_DevotionAura','Spell_Holy_AuraOfLight'},
 HUNTER={'Ability_Hunter_BeastTaming','Ability_Marksmanship','Ability_Hunter_SwiftStrike'},
 PRIEST={'Spell_Holy_WordFortitude','Spell_Holy_HolyBolt','Spell_Shadow_ShadowWordPain'},
 SHAMAN={'Spell_Nature_Lightning','Spell_Nature_LightningShield','Spell_Nature_MagicImmunity'},
 MAGE={'Spell_Holy_MagicalSentry','Spell_Fire_FireBolt02','Spell_Frost_FrostBolt02'},
 WARLOCK={'Spell_Shadow_DeathCoil','Spell_Shadow_Metamorphosis','Spell_Shadow_RainOfFire'},
 DRUID={'Spell_Nature_StarFall','Ability_Racial_BearForm','Spell_Nature_HealingTouch'},
 DEATHKNIGHT={'Spell_Deathknight_BloodPresence','Spell_Deathknight_FrostPresence','Spell_Deathknight_UnholyPresence'}}
function A:SetSpecIcon(owner,index)
 local _,class=UnitClass('player');local first,second,_,fourth=self:Safe(GetTalentTabInfo,index);local native=type(first)=='number' and fourth or second
 local fallback=specIcons[class] and specIcons[class][index]
 local icon=(type(native)=='string' or type(native)=='number') and native or fallback and ('Interface\\Icons\\'..fallback)
 if not icon then return false end
 local t=owner:CreateTexture(nil,'ARTWORK');owner.specIcon=t;owner.specIconPath=icon;t:SetTexture(icon);t:SetSize(18,18);t:SetPoint('LEFT',owner,'LEFT',7,0);return true
end
function A:SetClassIcon(owner)
 local _,class=UnitClass('player');local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] or classCoords[class]
 local t=owner.classIcon or owner:CreateTexture(nil,'ARTWORK');owner.classIcon=t;t:SetSize(18,18);t:SetPoint('LEFT',owner,'LEFT',7,0)
 if coords then t:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes');t:SetTexCoord(unpack(coords));t:Show() else t:Hide() end
end

-- Atlas browsing is separate from the map's filters: finding an item must not hide its sources.
function A:AtlasSourcePoints(row)
 local points={};local mapID=row and row.location.mapID
 if not mapID then return points end
 if row.npcID then
  if row.location.kind=='entrance' then
   local dungeon=self.instances[row.location.area];for _,p in ipairs(dungeon and dungeon.entrances or {}) do if p[1]==mapID then points[#points+1]=p end end
  else
   for _,p in ipairs((self.mobs[row.npcID] or {}).points or {}) do if p[1]==mapID then points[#points+1]=p end end
  end
 else for _,p in ipairs(row.location.points or {}) do if p[1]==mapID then points[#points+1]=p end end end
 return points
end
function A:PreviewAtlasSource(row)
 local f=self.atlas;f.previewSource=row;local m=f.mapPreview
 for _,t in ipairs(m.tiles) do t:Hide() end;for _,p in ipairs(m.pins) do p:Hide() end
 if not row or not row.location.mapID then m.caption:SetText('Выбери источник с координатами');m.empty:SetText('Выбери строку источника для предпросмотра');m.empty:Show();f.previewWorld:Hide();return end
 local mapID=row.location.mapID;local points=self:AtlasSourcePoints(row)
 m.caption:SetText(row.location.kind=='entrance' and ('Вход: '..row.location.name) or self:MapName(mapID));f.previewWorld:Show()
 local layers=self:Safe(C_Map and C_Map.GetMapArtLayers,mapID);local layer=layers and layers[1]
 local files=self:Safe(C_Map and C_Map.GetMapArtLayerTextures,mapID,1)
 local hasArt=layer and layer.layerWidth and layer.layerHeight and layer.tileWidth and layer.tileHeight and type(files)=='table' and files[1]
 local w,h=m:GetWidth(),m:GetHeight();local rw,rh,x0,y0=w,h,0,0;local usedTiles=0
 local function tile(file,x,y,tw,th,umax,vmax,overlay)
  local l,t,r,b=math.max(0,x),math.max(0,y),math.min(w,x+tw),math.min(h,y+th)
  if r<=l or b<=t or usedTiles>=384 then return end
  usedTiles=usedTiles+1;local texture=m.tiles[usedTiles]
  if not texture then texture=m:CreateTexture(nil,overlay and 'ARTWORK' or 'BACKGROUND');m.tiles[usedTiles]=texture end
  if texture.SetDrawLayer then texture:SetDrawLayer(overlay and 'ARTWORK' or 'BACKGROUND') end
  texture:SetTexture(file);texture:SetTexCoord((l-x)/tw*umax,(r-x)/tw*umax,(t-y)/th*vmax,(b-y)/th*vmax)
  texture:SetSize(r-l,b-t);texture:ClearAllPoints();texture:SetPoint('TOPLEFT',m,'TOPLEFT',l,-t);texture:Show()
 end
 if hasArt then
  local cx,cy=.5,.5;local minx,miny,maxx,maxy=1,1,0,0
  for _,p in ipairs(points) do minx=math.min(minx,p[2]/100);maxx=math.max(maxx,p[2]/100);miny=math.min(miny,p[3]/100);maxy=math.max(maxy,p[3]/100) end
  if #points>0 then cx=(minx+maxx)/2;cy=(miny+maxy)/2 end
  local zoom=#points>0 and maxx-minx<.35 and maxy-miny<.35 and 1.3 or 1.05
  local scale=math.max(w/layer.layerWidth,h/layer.layerHeight)*zoom
  rw=layer.layerWidth*scale;rh=layer.layerHeight*scale;x0=math.max(w-rw,math.min(0,w/2-cx*rw));y0=math.max(h-rh,math.min(0,h/2-cy*rh))
  local cols=math.ceil(layer.layerWidth/layer.tileWidth)
  for index,file in ipairs(files) do
   local col=(index-1)%cols;local r=math.floor((index-1)/cols);local tw=math.min(layer.tileWidth,layer.layerWidth-col*layer.tileWidth);local th=math.min(layer.tileHeight,layer.layerHeight-r*layer.tileHeight)
   if tw>0 and th>0 then tile(file,x0+col*layer.tileWidth*scale,y0+r*layer.tileHeight*scale,tw*scale,th*scale,tw/layer.tileWidth,th/layer.tileHeight,false) end
  end
  -- Render full zone artwork, independent of this character's explored areas.
  local artID=self:Safe(C_Map and C_Map.GetMapArtID,mapID);local overlays={};local byRect={}
  for _,area in ipairs((self.mapReveal or {})[artID] or {}) do local key=table.concat({area[1],area[2],area[3],area[4]},':');overlays[#overlays+1]=area;byRect[key]=#overlays end
  for _,area in ipairs(self:Safe(C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures,mapID) or {}) do
   if area.textureWidth and area.textureWidth>0 then
    local converted={area.textureWidth,area.textureHeight,area.offsetX,area.offsetY};for _,id in ipairs(area.fileDataIDs or {}) do converted[#converted+1]=id end
    local key=table.concat({converted[1],converted[2],converted[3],converted[4]},':');if byRect[key] then overlays[byRect[key]]=converted else overlays[#overlays+1]=converted end
   end
  end
  local function padded(n) local size=16;while size<n do size=size*2 end;return size end
  for _,area in ipairs(overlays) do
   local columns=math.ceil(area[1]/256)
   for j=5,#area do
    local index=j-5;local col=index%columns;local r=math.floor(index/columns);local tw=math.min(256,area[1]-col*256);local th=math.min(256,area[2]-r*256)
    if tw>0 and th>0 then tile(area[j],x0+(area[3]+col*256)*scale,y0+(area[4]+r*256)*scale,tw*scale,th*scale,tw/padded(tw),th/padded(th),true) end
   end
  end
  m.fullReveal=((self.mapReveal or {})[artID]~=nil);m.empty:Hide()
 else m.empty:SetText('Изображение карты недоступно.\nМетки показаны по известным координатам.');m.empty:Show() end
 local occupied={};local used=0
 for _,point in ipairs(points) do
  local x,y=x0+rw*point[2]/100,y0+rh*point[3]/100;local key=math.floor(x/9)..':'..math.floor(y/9)
  if x>=4 and x<=w-4 and y>=4 and y<=h-4 and not occupied[key] and used<64 then occupied[key]=true;used=used+1
   local p=m.pins[used]
   if not p then p=CreateFrame('Frame',nil,m);p:EnableMouse(false);p.halo=p:CreateTexture(nil,'BACKGROUND');p.halo:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\SpawnGlow.tga');p.halo:SetSize(36,36);p.halo:SetPoint('CENTER');p.dot=p:CreateTexture(nil,'OVERLAY');p.dot:SetAllPoints();m.pins[used]=p end
   p:SetSize(row.location.kind=='entrance' and 18 or 11,row.location.kind=='entrance' and 18 or 11);p:SetFrameLevel(m:GetFrameLevel()+3)
   p.dot:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\'..(row.location.kind=='entrance' and 'MarkerDungeon.tga' or 'MobDot.tga'))
   if p.dot.SetVertexColor then p.dot:SetVertexColor(1,.84,.24,1);p.halo:SetVertexColor(.68,.36,.95,.48) end
   p:ClearAllPoints();p:SetPoint('CENTER',m,'TOPLEFT',x,-y);p.sourceX=point[2];p.sourceY=point[3];p:Show()
  end
 end
 f.sourceStatus:SetText(#points>0 and (row.location.kind=='entrance' and 'Метка показывает вход, не позицию босса.' or 'Места появления: '..#points..' · область приближена') or 'Источник известен, но точных координат нет.')
 if row.entry and row.entry[2]==6 then f.sourceStatus:SetText('Цена сохранена при посещении. Наличие может измениться.') end
 m.mapID=mapID;m.sourcePointCount=#points;m.visiblePointCount=used;m.hasArt=not not hasArt;m.drawnTiles=usedTiles;m.transform={rw=rw,rh=rh,x=x0,y=y0}
end
function A:CreateAtlasPreview(f)
 local m=CreateFrame('Frame',nil,f,'BackdropTemplate');f.mapPreview=m;m:SetSize(408,252);m:SetPoint('TOPLEFT',456,-150);m:EnableMouse(false);if m.SetClipsChildren then m:SetClipsChildren(true) end
 m:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=8});m:SetBackdropColor(.06,.05,.04,.85);m:SetBackdropBorderColor(.55,.43,.26,.7);m.tiles={};m.pins={}
 m.empty=label(m,'Выбери строку источника для предпросмотра',20,-70,368,11,{.8,.8,.7});m.empty:SetJustifyH('CENTER')
 m.caption=label(f,'Карта источника',456,-132,280,10,{.9,.8,.6})
 f.previewWorld=button(f,'Карта мира',756,-112,105,function()
  local row=f.previewSource;if row then GameTooltip:Hide();local ok,why=self:FocusAtlasSource(f.selectedItem,row);if not ok then f.sourceStatus:SetText(why) end end
 end);f.previewWorld:Hide()
end

function A:SelectAtlasItem(iid)
 local f=self.atlas;self:RememberItem(iid);f.selectedItem=iid;f.sourcePage=1;f.sourceCache=nil;f.previewSource=nil;self:RefreshAtlas()
end
function A:AtlasSourceDescription(source)
 if source.recipeID then
  local recipe=self:ItemDisplay(source.recipeID)
  return 'Рецепт: '..recipe..(source.source.skill and (' · навык '..source.source.skill) or '')..(source.location.mapID and '' or ' · нет координат')
 end
 local method=source.entry[2];local detail
   if method==5 or method==6 then
    if method==6 and source.entry[8] then detail='Купить: нужна специальная валюта'
    elseif method==6 and type(source.entry[5])=='number' and source.entry[5]>=0 then
     local copper=source.entry[5];local money=self:Safe(GetCoinTextureString,copper) or string.format('%dз %dс %dм',math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
     detail='Купить за '..money..((source.entry[6] or 1)>1 and (' · за '..source.entry[6]..' шт.') or '')
    else detail='Купить: цена ещё неизвестна' end
   elseif method==10 then detail='Награда за задание'
   elseif method==11 then detail='Изготовление: '..source.source.name..(source.source.skill and (' · навык '..source.source.skill) or '')
   else detail=(method==2 and 'Шкуры: ' or method==3 and 'Карманная кража: ' or 'Дроп: ')..self:Chance(source.entry) end
 if not source.location.mapID then detail=detail..' · нет координат' elseif source.location.kind=='entrance' then detail=detail..' · карта входа' end
 return detail
end
function A:CreateAtlasSourcePane(f)
 f.sourceTitle=label(f,'Где взять предмет',456,-20,330,15,{1,.85,.6})
 f.sourceMeta=label(f,'Выбери вещь слева',456,-49,360,11,{.8,.8,.72})
 f.sourceCompare=label(f,'',456,-75,390,10,{.7,.8,.7});f.sourceCompare:SetWordWrap(true)
 f.sourceBaseline=label(f,'',456,-102,402,10,{.75,.72,.65});f.sourceBaseline:SetWordWrap(false)
 f.sourceReset=button(f,'Снять выбор',756,-48,105,function() f.selectedItem=nil;f.sourceCache=nil;self:RefreshAtlas() end);f.sourceReset:Hide()
 f.sourceHeading=label(f,'Источники по локациям',456,-119,290,12,{1,.84,.56})
 self:CreateAtlasPreview(f)
 f.sourceRows={}
 for i=1,3 do
  local row=CreateFrame('Button',nil,f,'BackdropTemplate');row:SetSize(408,55);row:SetPoint('TOPLEFT',456,-420-(i-1)*56);row:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});row:SetBackdropColor(.42,.34,.24,.12)
  row.zone=label(row,'',6,-2,306,10,{.9,.73,.43});row.zone:SetWordWrap(false)
  row.name=label(row,'',6,-17,299,12);row.name:SetWordWrap(false)
  row.meta=label(row,'',6,-34,300,9,{.73,.77,.7});row.meta:SetWordWrap(false)
  row.map=button(row,'Карта',322,-16,78,function() if not row.value then return end
   GameTooltip:Hide()
   local opened,reason=self:FocusAtlasSource(f.selectedItem,row.value)
   if not opened then f.sourceStatus:SetText(reason) end
  end)
  row:SetScript('OnEnter',function(b) b:SetBackdropColor(.65,.48,.25,.22);if b.value then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,b.name:GetText(),1,.85,.55);self:AddTooltipLine(GameTooltip,b.value.location.name);self:AddTooltipLine(GameTooltip,b.meta:GetText());GameTooltip:Show() end end)
  row:SetScript('OnLeave',function(b) b:SetBackdropColor(.42,.34,.24,.12);GameTooltip:Hide() end)
  row:SetScript('OnClick',function(b) if b.value and b.value.location.mapID then GameTooltip:Hide();self:PreviewAtlasSource(b.value) end end)
  f.sourceRows[i]=row;row:Hide()
 end
 f.sourcePrev=button(f,'‹',456,-599,35,function() f.sourcePage=f.sourcePage-1;self:RefreshAtlasSources() end)
 f.sourceNext=button(f,'›',829,-599,35,function() f.sourcePage=f.sourcePage+1;self:RefreshAtlasSources() end)
 f.sourcePager=label(f,'',501,-606,320,11,{.8,.8,.72});f.sourcePager:SetJustifyH('CENTER')
 f.sourceStatus=label(f,'',456,-638,408,10,{.7,.75,.68})
end
function A:RefreshAtlasSources()
 local f=self.atlas;local iid=f.selectedItem;local selected=iid and self.items[iid]
 f.sourceReset:SetShown(selected~=nil)
 if not selected then
  f.sourceTitle:SetText('Сравнение и источники');f.sourceMeta:SetText('Выбери предмет слева');f.sourceCompare:SetText('Здесь появятся сравнение с экипировкой и способы получения.');f.sourceBaseline:SetText('');f.sourceStatus:SetText('');f.sourcePager:SetText('')
  self:PreviewAtlasSource(nil);for _,row in ipairs(f.sourceRows) do row:Hide() end;f.sourcePrev:Hide();f.sourceNext:Hide();return
 end
 f.sourceTitle:SetText(self:ItemDisplay(iid));f.sourceTitle:SetWordWrap(false)
 local comparison=self:CompareItem(iid);f.sourceCompare:SetText(comparison and comparison.text or '')
 local worn=comparison and comparison.slot and self:Safe(GetInventoryItemLink,'player',comparison.slot)
 local baseline=worn and self:ComparisonInfo(worn)
 f.sourceBaseline:SetText(baseline and comparison.delta~=nil and ('Надето: '..baseline.name) or '')

 local key=tostring(iid)..':'..f.scope..':'..f.category..':'..tostring(f.knownOnly)
 if not f.sourceCache or f.sourceCacheKey~=key then
  local sources=self:AtlasSources(iid,f.scope);if f.knownOnly or (f.category=='gear' or f.category=='upgrades') then local mapped={};for _,source in ipairs(sources) do if (not f.knownOnly or source.location.mapID) and (f.category~='gear' and f.category~='upgrades' or self:AtlasSourceAccessible(source)) then mapped[#mapped+1]=source end end;sources=mapped end;local current=self:Safe(C_Map and C_Map.GetBestMapForUnit,'player')
  for _,source in ipairs(sources) do source.group=(source.location.kind=='entrance' and 'Подземелье: ' or '')..source.location.name end
  table.sort(sources,function(a,b)
   local aMap,bMap=a.location.mapID~=nil,b.location.mapID~=nil;if aMap~=bMap then return aMap end
   local ae,be=self:SourceEvidenceTier(a.entry),self:SourceEvidenceTier(b.entry);if ae~=be then return ae>be end
   local aHere,bHere=a.location.mapID==current,b.location.mapID==current;if aHere~=bHere then return aHere end
   if a.group~=b.group then return a.group<b.group end
   if a.entry[3]~=b.entry[3] then return a.entry[3]>b.entry[3] end
   return (a.npcID or a.source and a.source.id or 0)<(b.npcID or b.source and b.source.id or 0)
  end)
  f.sourceCache=sources;f.sourceCacheKey=key
 end
 local sources=f.sourceCache;local groups={};for _,source in ipairs(sources) do if source.location.mapID then groups[source.location.mapID]=true end end
 local n=0;for _ in pairs(groups) do n=n+1 end
 f.sourceMeta:SetText('Источников: '..#sources..' · зон на карте: '..n)
 local pages=math.max(1,math.ceil(#sources/3));f.sourcePage=math.max(1,math.min(f.sourcePage or 1,pages));local previous
 for i,row in ipairs(f.sourceRows) do
  local source=sources[(f.sourcePage-1)*3+i];row.value=source;row:SetShown(source~=nil)
  if source then
   row.zone:SetText(source.group~=previous and source.group or '');previous=source.group
   local mob=source.npcID and self.mobs[source.npcID];row.name:SetText(mob and (mob.name..(not mob.vendor and mob.min and mob.min>0 and (' · '..mob.min..'–'..mob.max..' ур.') or '')) or source.source and source.source.name or 'Источник')
   local detail=self:AtlasSourceDescription(source)
   row.meta:SetText(detail)
   if source.location.mapID then row.map:Enable() else row.map:Disable() end
  end
 end
 f.sourcePrev:Show();f.sourceNext:Show();if f.sourcePage>1 then f.sourcePrev:Enable() else f.sourcePrev:Disable() end;if f.sourcePage<pages then f.sourceNext:Enable() else f.sourceNext:Disable() end;f.sourcePager:SetText(f.sourcePage..' / '..pages)
 if not f.previewSource then for _,source in ipairs(sources) do if source.location.mapID then f.previewSource=source;break end end end
 self:PreviewAtlasSource(f.previewSource)
 if #sources==0 then f.sourceStatus:SetText(f.knownOnly and 'Нет точек по этим фильтрам.' or 'Нет источников по этим фильтрам.') end
end

function A:CreateAtlas()
 local f=panel('MobAtlasAtlas',UIParent,880,660);self.atlas=f;f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:EnableMouse(true)
 f:SetScale(.85*math.min(1.1875,(UIParent:GetHeight()-30)/660,(UIParent:GetWidth()-30)/880));f:SetBackdrop({bgFile=skin..'AtlasBook.tga'});f:SetBackdropColor(1,1,1,1);if f.skinHeaderRule then f.skinHeaderRule:Hide() end;for _,x in ipairs({16,456}) do local line=f:CreateTexture(nil,'ARTWORK');line:SetColorTexture(.65,.5,.3,.22);line:SetPoint('TOPLEFT',x,-40);line:SetSize(408,1) end;f:SetMovable(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function() f:StartMoving() end);f:SetScript('OnDragStop',function() f:StopMovingOrSizing() end)
 tinsert(UISpecialFrames,'MobAtlasAtlas');f.category='gear';f.scope='all';f.page=1;f.myLevel=true;f.knownOnly=true
 label(f,'Следопыт · атлас добычи',16,-15,205,15,{1,.79,.32})
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4);close:SetScript('OnClick',function() f:Hide() end)
 f.search=CreateFrame('EditBox',nil,f,'InputBoxTemplate');f.search:SetSize(393,28);f.search:SetPoint('TOPLEFT',22,-49);f.search:SetFont(self.font,12,'');f.search:SetAutoFocus(false);f.search:SetMaxLetters(160)
 f.search:SetScript('OnEscapePressed',function(b) b:ClearFocus() end)
 local function search()
  local query=self:SearchText(f.search:GetText())
  if query:match('^%d+$') or query:match('item:%d+') then
   f.category='all';f.gearType=nil;f.gearSlot=nil;f.scope='all';f.myLevel=false;f.knownOnly=false
  end
  f.selectedItem=nil
  f.previewSource=nil
  f.page=1
  f.results=nil
  f.recommendScan=nil
  self:RefreshAtlas()
 end
 f.search:SetScript('OnEnterPressed',function(b) b:ClearFocus();search() end)
 f.search:SetScript('OnTextChanged',function(_,user)
  if not user then return end
  f.searchSerial=(f.searchSerial or 0)+1;local serial=f.searchSerial
  C_Timer.After(.2,function() if f.searchSerial==serial then search() end end)
 end)
 f.hint=label(f,'Название / ID · Shift-клик по вещи при вводе',20,-81,405,10,{.65,.69,.65});f.hint:SetWordWrap(false)
 f.languageMenu=panel(nil,f,150,100);f.languageMenu:SetPoint('TOPLEFT',225,-41);f.languageMenu:SetFrameLevel(f:GetFrameLevel()+45);f.languageMenu:EnableMouse(true)
 for i,choice in ipairs({{'auto','Авто / Auto'},{'ruRU','Русский'},{'enUS','English'}}) do
  local mode=choice[1];button(f.languageMenu,choice[2],6,-6-(i-1)*29,138,function() f.languageMenu:Hide();self:SetLanguage(mode) end)
 end
 f.languageMenu:Hide()
 f.languageButton=button(f,'',225,-10,68,function() self.specMenu:Hide();f.slotMenu:Hide();f.gearMenu:Hide();f.categoryMenu:Hide();f.scopeMenu:Hide();f.languageMenu:SetShown(not f.languageMenu:IsShown()) end)
 f.languageButton:SetText(self.db.language=='ruRU' and 'RU v' or self.db.language=='enUS' and 'EN v' or 'Auto v')
 f.languageButton:SetScript('OnEnter',function(b) GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,'Язык интерфейса');self:AddTooltipLine(GameTooltip,'Авто: по языку WoW. Другие языки используют English.');GameTooltip:Show() end)
 f.languageButton:SetScript('OnLeave',function() GameTooltip:Hide() end)
 f.clearFocus=button(f,'Снять выбор',300,-10,124,function() self:ClearFocus();self:RefreshAtlas() end);f.clearFocus:Hide()
 f.myLevelCheck=check(f,'Мой уровень',16,-76,180,function(v) f.myLevel=v;search() end)
 f.myLevelCheck:SetScript('OnEnter',function(control)
  GameTooltip:SetOwner(control,'ANCHOR_RIGHT')
  self:AddTooltipLine(GameTooltip,'Вещи, доступные по уровню персонажа')
  GameTooltip:Show()
 end)
 f.myLevelCheck:SetScript('OnLeave',function() GameTooltip:Hide() end)
 f.knownCheck=check(f,'Есть место на карте',205,-76,220,function(v) f.knownOnly=v;search() end)
 local categories={{'all','Все предметы'},{'useful','Полезное мне сейчас'},{'gear','Для меня'},{'upgrades','Только улучшения'},{'catalog','Вся экипировка'},{'bags','Сумки'},{'materials','Материалы профессий'},{'recipes','Рецепты'},{'consumables','Расходники'},{'pets','Питомцы'},{'rare','Редкие вещи'},{'epic','Эпические вещи'}}
 f.categoryNames={};for _,v in ipairs(categories) do f.categoryNames[v[1]]=v[2] end
 f.categoryMenu=panel(nil,f,245,12+#categories*28);f.categoryMenu:SetPoint('TOPLEFT',16,-134);f.categoryMenu:SetFrameLevel(f:GetFrameLevel()+40);f.categoryMenu:EnableMouse(true)
 local gearTypes={{nil,'Все типы'},{'cloth','Ткань'},{'leather','Кожа'},{'mail','Кольчуга'},{'plate','Латы'},{'shield','Щиты'},{'accessory','Плащи и аксессуары'},{'weapon','Оружие'}}
 f.gearTypeNames={}
 f.gearMenu=panel(nil,f,245,12+(#gearTypes+1)*28)
 f.gearMenu:SetPoint('TOPLEFT',16,-134)
 f.gearMenu:SetFrameLevel(f:GetFrameLevel()+40)
 f.gearMenu:EnableMouse(true)
 button(f.gearMenu,'‹ Категории',6,-6,233,function() f.gearMenu:Hide();f.categoryMenu:Show() end)
 for i,choice in ipairs(gearTypes) do
  local kind,name=choice[1],choice[2]
  if kind then f.gearTypeNames[kind]=name end
  button(f.gearMenu,name,6,-6-i*28,233,function()
   f.category=f.gearMenuCategory
   f.gearType=kind
   f.gearSlot=nil
   f.gearMenu:Hide()
   search()
  end)
 end
 f.gearMenu:Hide()
 for i,choice in ipairs(categories) do
  local id,name=choice[1],choice[2]
  local hasTypes=id=='catalog' or id=='gear' or id=='upgrades'
  button(f.categoryMenu,name..(hasTypes and '  ›' or ''),6,-6-(i-1)*28,233,function()
   f.categoryMenu:Hide()
   if hasTypes then
    f.gearMenuCategory=id
    f.gearMenu:Show()
   else
    f.category=id
    f.gearType=nil
    f.gearSlot=nil
    search()
   end
  end)
 end
 f.categoryMenu:Hide()
 f.scopeMenu=panel(nil,f,201,124);f.scopeMenu:SetPoint('TOPLEFT',180,-134);f.scopeMenu:SetFrameLevel(f:GetFrameLevel()+40);f.scopeMenu:EnableMouse(true)
 for i,v in ipairs({{'all','Все источники'},{'world','Открытый мир'},{'dungeons','Данжи и рейды'},{'recent','Недавно выбраны'}}) do local id=v[1];button(f.scopeMenu,v[2],6,-6-(i-1)*28,189,function() f.scope=id;f.scopeMenu:Hide();f.results=nil;f.page=1;f.sourcePage=1;f.sourceCache=nil;f.previewSource=nil;self:RefreshAtlas() end) end
 f.scopeMenu:Hide()
 f.categoryButton=button(f,'',16,-104,158,function()
  local open=f.categoryMenu:IsShown() or f.gearMenu:IsShown();f.slotMenu:Hide()
  f.gearMenu:Hide();self.specMenu:Hide();f.scopeMenu:Hide();f.categoryMenu:SetShown(not open)
 end)
 f.scopeButton=button(f,'',180,-104,112,function()
  self.specMenu:Hide();f.slotMenu:Hide();f.gearMenu:Hide();f.categoryMenu:Hide();f.scopeMenu:SetShown(not f.scopeMenu:IsShown())
 end)
 f.specButton=button(f,'',298,-104,126,function()
  local menu=self.specMenu;local open=menu:IsShown() and menu:GetParent()==f
  f.gearMenu:Hide();f.categoryMenu:Hide();f.scopeMenu:Hide();f.languageMenu:Hide();f.slotMenu:Hide();GameTooltip:Hide()
  menu:Hide();menu:SetParent(f);menu:ClearAllPoints();menu:SetPoint('TOPRIGHT',f.specButton,'BOTTOMRIGHT',0,-3);menu:SetFrameLevel(f:GetFrameLevel()+50);menu:SetShown(not open)
 end)
 self:SetClassIcon(f.specButton)
 local font=f.specButton:GetFontString();font:ClearAllPoints();font:SetPoint('CENTER',f.specButton,'CENTER',9,0);font:SetWidth(90);font:SetWordWrap(false);font:SetFont(self.font,10,'')
 f.specButton:SetScript('OnEnter',function(b)
  GameTooltip:SetOwner(b,'ANCHOR_RIGHT');local className=UnitClass('player');self:AddTooltipLine(GameTooltip,className,1,.86,.56)
  self:AddTooltipLine(GameTooltip,not self.db.specOnly and 'Спек отключён. Выбери авто или свою ветку талантов.' or self.gearProfile and ((self.db.gearSpec and 'Выбран спек: ' or 'Авто: ')..self.gearProfile[1]) or 'Таланты ещё не выбраны. Укажи спек вручную.',.8,.85,.8)
  self:AddTooltipLine(GameTooltip,'Подбор по классу, оружию и известным характеристикам.',.7,.75,.7);GameTooltip:Show()
 end)
 f.specButton:SetScript('OnLeave',function() GameTooltip:Hide() end)
 f.heading=label(f,'',17,-143,178,12,{1,.86,.56});f.heading:SetWordWrap(false)
 local slots={{false,'Все слоты'},{'head','Голова'},{'neck','Шея'},{'shoulder','Плечи'},{'cloak','Спина'},{'chest','Грудь'},{'wrist','Запястья'},{'hand','Кисти'},{'waist','Пояс'},{'legs','Ноги'},{'feet','Ступни'},{'finger','Кольца'},{'trinket','Аксессуары'},{'weapon','Оружие'},{'offhand','Левая рука'},{'wand','Жезлы'},{'ranged','Дальний бой'}}
 f.gearSlotNames={}
 f.slotMenu=panel(nil,f,296,12+math.ceil(#slots/2)*28)
 f.slotMenu:SetPoint('TOPLEFT',128,-166);f.slotMenu:SetFrameLevel(f:GetFrameLevel()+44);f.slotMenu:EnableMouse(true)
 for i,choice in ipairs(slots) do
  local slot,name=choice[1],choice[2]
  if slot then f.gearSlotNames[slot]=name end
  button(f.slotMenu,name,6+((i-1)%2)*143,-6-math.floor((i-1)/2)*28,141,function()
   f.gearSlot=slot or nil;f.slotMenu:Hide();search()
  end)
 end
 f.slotMenu:Hide()
 f.slotButton=button(f,'Все слоты  v',197,-137,145,function()
  f.categoryMenu:Hide();f.gearMenu:Hide();f.languageMenu:Hide();f.scopeMenu:Hide();self.specMenu:Hide()
  f.slotMenu:SetShown(not f.slotMenu:IsShown())
 end)

 f.allItems=button(f,'Сброс',350,-137,74,function() f.slotMenu:Hide();f.category='all';f.gearType=nil;f.gearSlot=nil;f.scope='all';f.myLevel=false;f.knownOnly=false;f.selectedItem=nil;f.sourceCache=nil;f.results=nil;f.page=1;self:RefreshAtlas() end)
 f.rows={}
 for i=1,8 do
  local r=CreateFrame('Button',nil,f,'BackdropTemplate');r:SetSize(408,48);r:SetPoint('TOPLEFT',16,-166-(i-1)*51)
  r:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});r:SetBackdropColor(.42,.34,.24,.12)
  r.icon=r:CreateTexture(nil,'ARTWORK');r.icon:SetSize(32,32);r.icon:SetPoint('TOPLEFT',7,-8)
  r.border=CreateFrame('Frame',nil,r,'BackdropTemplate');r.border:SetPoint('TOPLEFT',5,-6);r.border:SetSize(36,36);r.border:EnableMouse(false);r.border:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
  r.title=label(r,'',48,-5,338,12);r.title:SetWordWrap(false)
  r.meta=label(r,'',48,-21,330,10,{.75,.77,.7});r.meta:SetWordWrap(false)
  r.detail=label(r,'',48,-35,330,9,{.67,.72,.68});r.detail:SetWordWrap(false)
  r.action=label(r,'›',391,-16,15,15,{1,.8,.4})
  r.mapButton=button(r,'Где взять',340,-10,62,function() if r.itemID then self:SelectAtlasItem(r.itemID) end end)
  r:SetScript('OnEnter',function(b)
   b:SetBackdropColor(.65,.48,.25,.22)
   local iid=b.itemID or f.selectedItem
   if iid then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');if self:ComparisonInfo(iid) then GameTooltip:SetHyperlink('item:'..iid) else self:AddTooltipLine(GameTooltip,self:ItemDisplay(iid));self:AddTooltipLine(GameTooltip,self.atlasLoadFailures and self.atlasLoadFailures[iid] and 'Клиент не вернул описание. Источник указан по справочнику.' or 'Описание ещё загружается. Источник взят из справочника.',.75,.8,.72);self:HydrateAtlasItem(iid) end;self:ItemMetadataCredit(GameTooltip,iid);self:AddComparisonTooltip(GameTooltip,iid);if b.source then self:ItemEvidence(GameTooltip,b.source.entry);self:AddTooltipLine(GameTooltip,b.source.location.name,1,.85,.5);self:AddTooltipLine(GameTooltip,b.source.location.kind=='entrance' and 'Клик: вход в подземелье. Позиция босса неизвестна.' or b.source.location.mapID and 'Клик: оставить на карте только этот источник.' or 'Координат пока нет.',.8,.8,.7) end;GameTooltip:Show() end
  end)
  r:SetScript('OnLeave',function(b) b:SetBackdropColor(.42,.34,.24,.12);GameTooltip:Hide() end)
  r:SetScript('OnClick',function(b)
   GameTooltip:Hide()
   if b.itemID then self:SelectAtlasItem(b.itemID)
   elseif b.source then local ok,why=self:FocusAtlasSource(f.selectedItem,b.source);if not ok then f.status:SetText(why) end end
  end)
  f.rows[i]=r
 end
 self:CreateAtlasSourcePane(f)
 f.gearMode=button(f,'Улучшения',178,-631,117,function()
  f.category=f.category=='gear' and 'upgrades' or 'gear'
  search()
 end)
 f.moreCandidates=button(f,'Проверить ещё',300,-631,124,function() local scan=f.recommendScan;if scan then scan.limit=math.min(#scan.list,scan.limit+128);self:RefreshAtlas() end end);f.moreCandidates:Hide()
 f.prev=button(f,'‹',16,-599,35,function() f.page=f.page-1;self:RefreshAtlas() end)
 f.next=button(f,'›',389,-599,35,function() f.page=f.page+1;self:RefreshAtlas() end)
 f.pager=label(f,'',57,-605,78,11,{.8,.8,.72})
 f.prepButton=button(f,'Перед данжем',139,-599,115,function() f:Hide();self:OpenPreparation() end)
 button(f,'Настройки',261,-599,118,function() f:Hide();self.settings:Show();self:RefreshSettings() end)
 f.status=label(f,'',17,-638,407,10,{.67,.72,.68})
 f:EnableMouseWheel(true);f:SetScript('OnMouseWheel',function(_,d) f.page=f.page-d;self:RefreshAtlas() end)
 f:SetScript('OnHide',function() GameTooltip:Hide();f.search:ClearFocus();f.gearMenu:Hide();f.categoryMenu:Hide();f.scopeMenu:Hide();f.languageMenu:Hide();f.slotMenu:Hide();self.specMenu:Hide() end)
 f:Hide()
end
function A:OpenAtlas(query)
 self.atlasRequirementCache=nil;local previousProfile=self.gearProfile;self:RefreshGearProfile();if self.atlas and previousProfile~=self.gearProfile then self.atlas.results=nil end
 if not self.atlas then self:CreateAtlas() end
 self.settings:Hide();if self.tip then self.tip:Hide() end;if self.prep then self.prep:Hide() end
 local f=self.atlas
 if query then f.category='all';f.gearType=nil;f.gearSlot=nil;f.scope='all';f.myLevel=false;f.knownOnly=false;f.search:SetText(query);f.selectedItem=nil;f.results=nil;f.page=1 end
 self:RefreshAtlas();f:Show()
end
function A:RefreshAtlas()
 local f=self.atlas;if not f then return end
 f.specButton:SetText(not self.db.specOnly and 'Спек: откл.  v' or not self.db.gearSpec and (self.gearProfileSource=='class' and 'По классу  v' or self.gearProfile and 'Спек: авто  v' or 'Спек: ?  v') or self.gearProfile and (self.gearProfile[1]..'  v') or 'Спек: ?  v')
 f.allItems:Show();f.clearFocus:SetShown(self.focus~=nil);f.myLevelCheck:Show();f.knownCheck:Show();f.myLevelCheck:SetChecked(f.myLevel);f.knownCheck:SetChecked(f.knownOnly)
 f.showingRecent=f.scope=='recent';f.recentResults=f.showingRecent
 local function results() return self:FindItems(f.search:GetText(),f.category,f.scope,nil,{level=f.myLevel,known=f.knownOnly,recent=f.showingRecent,gearType=f.gearType,slot=f.gearSlot}) end
 if not f.results then f.results=results() end
 local values=f.category=='upgrades' and self:PersonalRecommendations(f.results) or f.results;if f.category~='upgrades' then f.moreCandidates:Hide() end;local pages=math.max(1,math.ceil(#values/8));f.page=math.max(1,math.min(pages,f.page))
 local changed=false
 for i=1,8 do local iid=values[(f.page-1)*8+i];if iid and self:HydrateAtlasItem(iid) then changed=true end end
 if changed then f.results=results();values=f.category=='upgrades' and self:PersonalRecommendations(f.results) or f.results;pages=math.max(1,math.ceil(#values/8));f.page=math.max(1,math.min(pages,f.page)) end
 f.heading:SetText((f.showingRecent and 'Недавно выбраны: ' or 'Найдено: ')..#values)
 local personal=f.category=='gear' or f.category=='upgrades'
 f.gearMode:SetShown(personal)
 f.gearMode:SetText(f.category=='upgrades' and 'Для меня' or 'Улучшения')
 local equipment=personal or f.category=='catalog'
 f.slotButton:SetShown(equipment)
 f.slotButton:SetText((f.gearSlotNames[f.gearSlot] or 'Все слоты')..'  v')
 f.categoryButton:SetText((f.gearTypeNames[f.gearType] or f.categoryNames[f.category] or 'Все предметы')..'  v')
 f.scopeButton:SetText((({all='Источники',world='Мир',dungeons='Данжи',recent='Недавние'})[f.scope] or 'Источники')..'  v')
 f.hint:SetText('');f.pager:SetText(f.page..' / '..pages)
 for i,r in ipairs(f.rows) do
  local iid=values[(f.page-1)*8+i];r:SetShown(iid~=nil);r.itemID=iid;r.source=nil
  if iid then
   local item=self.items[iid];local name,icon=self:ItemDisplay(iid);local c=colors[item.quality] or {.65,.65,.65}
   r.action:Hide();r.mapButton:Show();r.mapButton:Enable();r.title:SetWidth(282);r.meta:SetWidth(282);r.icon:SetTexture(icon);r.border:Show();self:StyleRarityBorder(r.border,c,item.quality)
   r.title:SetText(name);r.title:SetTextColor(c[1],c[2],c[3])
   local _,special=self:SpecialRank(iid);local comparison=self:CompareItem(iid);r.detail:SetText(comparison and comparison.text or '')
   local better=comparison and (comparison.state=='better' or comparison.state=='empty');r.detail:SetTextColor(better and .35 or .72,better and .95 or .73,.62)
   local slot=equipment and f.gearSlotNames[self:GearSlot(item)]
   r.meta:SetText((slot and slot..' · ' or '')..(special or qualities[item.quality] or 'Качество неизвестно')..(item.level and item.level>0 and (' · с '..item.level..' ур.') or ''))
   r:SetBackdropColor(.42,.34,.24,iid==f.selectedItem and .35 or .12)
  end
 end
 if f.category=='upgrades' then
  local scan=f.recommendScan
  local checked=scan.cursor-1-(f.recommendPending or 0)
  f.status:SetWidth(152)
  if #scan.list==0 then f.status:SetText('Нет кандидатов') else
   f.status:SetText('Проверено: '..checked..' / '..#scan.list..((f.recommendUnknown or 0)>0 and (' · без оценки: '..f.recommendUnknown) or ''))
  end
 else
  f.status:SetWidth(personal and 152 or 407)
  f.status:SetText(#values==0 and 'Ничего не найдено.' or personal and 'Доступные варианты' or 'Выбери вещь: источники появятся справа')
 end
 self:RefreshAtlasSources()
end

function A:RenderLocationFocus(canvas,scale,level,strata,used)
 local targets={};if self.focus then targets[#targets+1]=self.focus end;if self.questFocus and self.questFocus~=self.focus then targets[#targets+1]=self.questFocus end
 local mapID=WorldMapFrame:GetMapID();local seen={}
 for _,target in ipairs(targets) do for _,p in ipairs(target.points or {}) do if p[1]==mapID then
  local key=(target.kind or '')..':'..p[2]..':'..p[3]
  if not seen[key] then
   seen[key]=true;used=used+1;local point=self.habitatPins[used]
   if not point then point=CreateFrame('Frame',nil,canvas);point.mobAtlasPin=true;point.dot=point:CreateTexture(nil,'OVERLAY');point.dot:SetAllPoints();self.habitatPins[used]=point end
   point:SetSize(target.explicitMap and 28 or 22,target.explicitMap and 28 or 22);point:EnableMouse(true);point:SetParent(canvas);point:SetScale(scale);point:SetFrameLevel(level+3);point:SetFrameStrata(strata)
   point.dot:SetTexture(target.kind=='rare' and 'Interface\\AddOns\\MobAtlas\\Art\\MarkerRareLive.tga' or (target.kind=='rareSpawn' or target.kind=='rareLast') and 'Interface\\AddOns\\MobAtlas\\Art\\MarkerRare.tga' or target.kind=='quest' and 'Interface\\GossipFrame\\AvailableQuestIcon' or target.kind=='entrance' and 'Interface\\AddOns\\MobAtlas\\Art\\MarkerDungeon.tga' or 'Interface\\Minimap\\Tracking\\Object')
   point:ClearAllPoints();point:SetPoint('CENTER',canvas,'TOPLEFT',canvas:GetWidth()*p[2]/100/scale,-canvas:GetHeight()*p[3]/100/scale);point.sourceX=p[2];point.sourceY=p[3]
   point:SetScript('OnEnter',function(b) GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,target.label,1,.85,.35);self:AddTooltipLine(GameTooltip,self:MapName(mapID)..string.format(' · %.1f, %.1f',p[2],p[3]),.8,.8,.7);if target.questID then local _,why=self:QuestState(target.questID);self:AddTooltipLine(GameTooltip,why,.8,.8,.7);self:AddTooltipLine(GameTooltip,'Нажми метку, чтобы открепить.',.8,.85,.7) end;GameTooltip:Show() end)
   point:SetScript('OnLeave',function() GameTooltip:Hide() end);point:SetScript('OnMouseUp',function() if self.questFocus==target then GameTooltip:Hide();self:UnpinQuest() end end);point:Show()
  end
 end end end
end
function A:CreatePreparation()
 local f=panel('MobAtlasPreparation',UIParent,450,530);self.prep=f;f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetScale(math.min(.95,(UIParent:GetHeight()-30)/530));f:EnableMouse(true)
 f:SetMovable(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function() f:StartMoving() end);f:SetScript('OnDragStop',function() f:StopMovingOrSizing() end);tinsert(UISpecialFrames,'MobAtlasPreparation')
 label(f,'Перед походом в данж',18,-16,375,18,{1,.8,.35})
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4);close:SetScript('OnClick',function() f:Hide() end)
 f.sub=label(f,'',18,-48,410,11,{.8,.8,.7})
 f.mode=button(f,'',18,-73,265,function() f.allLevels=not f.allLevels;f.area=nil;f.entranceAreas=nil;f.page=1;self:RefreshPreparation() end)
 button(f,'Атлас вещей',295,-73,137,function() f:Hide();self:OpenAtlas() end)
 f.heading=label(f,'',18,-112,410,13,{1,.87,.5});f.heading:SetWordWrap(false)
 f.hint=label(f,'',18,-136,410,10,{.7,.76,.7});f.hint:SetWordWrap(false)
 f.rows={}
 for i=1,5 do
  local row=CreateFrame('Button',nil,f,'BackdropTemplate');row:SetSize(414,49);row:SetPoint('TOPLEFT',18,-160-(i-1)*51);row:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});row:SetBackdropColor(.2,.23,.2,.4)
  row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(24,24);row.icon:SetPoint('TOPLEFT',7,-12)
  row.title=label(row,'',40,-5,280,12);row.title:SetWordWrap(false)
  row.detail=label(row,'',40,-25,280,10,{.76,.8,.73});row.detail:SetWordWrap(false)
  row.action=button(row,'',330,-11,77,function() row.scriptsAction() end)
  row:SetScript('OnClick',function() row.scriptsAction() end)
  row:SetScript('OnEnter',function(b)
   if not b.questID then return end
   GameTooltip:SetOwner(b,'ANCHOR_RIGHT');self:AddTooltipLine(GameTooltip,self:QuestName(b.questID),1,.85,.4)
   local q=self.dungeonQuests[b.questID];local state,why=self:QuestState(b.questID);self:AddTooltipLine(GameTooltip,why,.8,.8,.7);if q.pickupHint then self:AddTooltipLine(GameTooltip,q.pickupHint,.85,.85,.7) end
   local step=self:FirstQuestStep(b.questID)
   if step~=b.questID then self:AddTooltipLine(GameTooltip,'Следующий шаг: '..self:QuestName(step),1,.85,.5) end
   local target=self.dungeonQuests[step]
   for j,giver in ipairs(target.givers) do if j<=3 then self:AddTooltipLine(GameTooltip,'Взять у: '..giver.name,.8,.8,.7) end end
   for j,iid in ipairs(q.rewards or {}) do if j<=3 then self:AddTooltipLine(GameTooltip,'Награда: '..self:ItemDisplay(iid),.5,.85,1) end end
   self:AddTooltipLine(GameTooltip,'Справочник: наличие задания проверяется у NPC.',.65,.7,.65);GameTooltip:Show()
  end)
  row:SetScript('OnLeave',function() GameTooltip:Hide() end);f.rows[i]=row
 end
 f.prev=button(f,'‹',18,-420,36,function() f.page=f.page-1;self:RefreshPreparation() end)
 f.next=button(f,'›',396,-420,36,function() f.page=f.page+1;self:RefreshPreparation() end)
 f.pager=label(f,'',62,-427,120,11)
 f.back=button(f,'‹ Другой данж',205,-420,180,function() f.area=nil;f.page=1;self:RefreshPreparation() end)
 f.checks=label(f,'',18,-461,414,11,{.85,.8,.65})
 f.status=label(f,'',18,-508,414,10,{.7,.76,.7});f.status:SetWordWrap(false)
 f:EnableMouseWheel(true);f:SetScript('OnMouseWheel',function(_,delta) f.page=f.page-delta;self:RefreshPreparation() end)
 f:SetScript('OnHide',function() GameTooltip:Hide() end);f.page=1;f:Hide()
end
function A:OpenPreparation()
 if not self.prep then self:CreatePreparation() end
 self.settings:Hide();if self.atlas then self.atlas:Hide() end;if self.tip then self.tip:Hide() end
 self:RefreshPreparation();self.prep:Show()
end
function A:RefreshPreparation()
 local f=self.prep;if not f then return end
 local values=f.area and self:DungeonQuestList(f.area,true) or self:DungeonChoices(f.entranceAreas and true or f.allLevels)
 if not f.area and f.entranceAreas then local allowed={};for _,id in ipairs(f.entranceAreas) do allowed[id]=true end;local filtered={};for _,v in ipairs(values) do if allowed[v.id] then filtered[#filtered+1]=v end end;values=filtered end
 if not f.area and f.entranceAreas then local allowed={};for _,id in ipairs(f.entranceAreas) do allowed[id]=true end;local filtered={};for _,entry in ipairs(values) do if allowed[entry.id] then filtered[#filtered+1]=entry end end;values=filtered end
 f.mode:SetText(f.allLevels and 'Все уровни моей фракции' or ('Мой уровень и ближайшие · '..UnitLevel('player')))
 f.sub:SetText('Задания, цепочки и подготовка · без выполненных квестов')
 f.heading:SetText(f.area and self:DungeonName(f.area) or 'Выбери подземелье')
 f.hint:SetText(f.area and 'Будущие задания видны заранее; карта доступна по условиям.' or 'Небольшой список подходящих походов и заданий.')
 local pages=math.max(1,math.ceil(#values/5));f.page=math.max(1,math.min(pages,f.page or 1));f.pager:SetText(f.page..' / '..pages);f.back:SetShown(f.area~=nil)
 for i,row in ipairs(f.rows) do
  local value=values[(f.page-1)*5+i];row:SetShown(value~=nil);row.questID=nil;row.action:Enable()
  if value then
   if f.area then
    local q=self.dungeonQuests[value.id];row.questID=value.id;row.title:SetText(self:QuestName(value.id));row.icon:SetTexture(value.state=='active' and 'Interface\\GossipFrame\\ActiveQuestIcon' or 'Interface\\GossipFrame\\AvailableQuestIcon')
    local pinned=self:IsQuestPinned(value.id);local _,why=self:QuestState(value.id);row.detail:SetText('Ур. '..q.level..' · '..(value.step~=value.id and 'Сначала цепочка: '..self:QuestName(value.step) or why))
    row.action:SetText(pinned and 'Открепить' or value.state=='active' and 'Взято' or value.state=='level' and 'С '..q.min..' ур.' or q.inside and 'Вход' or value.step~=value.id and 'Начать' or 'Карта');if not pinned and (value.state=='active' or value.state=='level') then row.action:Disable() end
    row.scriptsAction=function()
     if self:IsQuestPinned(value.id) then self:UnpinQuest();return end
     if value.state=='active' then f.status:SetText('Задание уже в журнале. Подробности — в журнале заданий.');return end
     local ok,why=self:ShowQuestOnMap(value.id);if not ok then f.status:SetText(why) end
    end
   else
    row.icon:SetTexture('Interface\\AddOns\\MobAtlas\\Art\\TrackDungeon.tga');row.title:SetText(value.name);row.detail:SetText('Сейчас: '..value.available..' · всего: '..value.count..(value.locked>0 and (' · позже: '..value.locked) or ''));row.action:SetText('Открыть')
    row.scriptsAction=function() f.area=value.id;f.page=1;self:RefreshPreparation() end
   end
  end
 end
 f.checks:SetText(self:PreparationChecks());f.status:SetText(#values==0 and 'Пока нет заданий по этим условиям. Попробуй все уровни.' or 'Справочные условия могут отличаться на текущем патче.')
end

function A:ItemMetadataCredit(t,iid)
 local item=self.items[iid]
 if item and item.metadataSource=='ahledger' then self:AddTooltipLine(t,'Данные предмета: AHledger (ahledger.com)',.65,.7,.65) end
 if item and item.estimated then self:AddTooltipLine(t,'Характеристики из Classic — проверь tooltip в игре.',.7,.7,.65) end
end

function A:ToggleTrackingMenu(owner)
 if not self.trackingMenu then
  local f=panel('MobAtlasTrackingMenu',UIParent,260,296);self.trackingMenu=f;f:SetFrameStrata('TOOLTIP');f:EnableMouse(true);tinsert(UISpecialFrames,'MobAtlasTrackingMenu')
  label(f,'Отслеживание',15,-15,220,14,{1,.82,.4})
  local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-3,-3);close:SetScript('OnClick',function() f:Hide() end)
  local function layer()
   local mobs,vendors=f.mobs:GetChecked(),f.vendors:GetChecked()
   self.db.enabled=not not (mobs or vendors or f.dungeons:GetChecked());self.db.mapLayer=mobs and vendors and 'all' or mobs and 'mobs' or vendors and 'vendors' or 'none';self:Invalidate()
  end
  f.mobs=check(f,'Мобы',14,-49,225,layer)
  f.vendors=check(f,'Продавцы',14,-81,225,layer)
  f.prof=check(f,'Мои профессии',14,-113,225,function(v) self.db.prof=v and -1 or 0;self:Invalidate() end)
  f.unit=check(f,'Добыча при наведении',14,-145,225,function(v) self.db.unitLoot=v end)
  f.dungeons=check(f,'Подземелья и задания',14,-177,225,function(v) self.db.dungeonPins=v;layer() end)
  button(f,'Редкие мобы…',14,-213,232,function() f:Hide();if self.OpenRareSettings then self:OpenRareSettings() end end)
  button(f,'Все настройки',14,-249,232,function() f:Hide();self.settings:Show();self:RefreshSettings() end)
  f:Hide()
 end
 local f=self.trackingMenu
 if f:IsShown() then f:Hide();return end
 f.mobs:SetChecked(self.db.enabled and (self.db.mapLayer=='all' or self.db.mapLayer=='mobs'));f.vendors:SetChecked(self.db.enabled and (self.db.mapLayer=='all' or self.db.mapLayer=='vendors'));f.prof:SetChecked(self.db.prof==-1);f.unit:SetChecked(self.db.unitLoot);f.dungeons:SetChecked(self.db.dungeonPins)
 f:ClearAllPoints();f:SetPoint('TOPRIGHT',owner,'BOTTOMRIGHT',0,-5);f:Show()
end
