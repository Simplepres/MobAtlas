local _,A=...
_G.MobAtlas=A
A.version='0.7.2';A.font='Interface\\AddOns\\MobAtlas\\Art\\NotoSans-Regular.ttf'
A.profNames={[129]='Первая помощь',[164]='Кузнечное дело',[165]='Кожевничество',[171]='Алхимия',[185]='Кулинария',[197]='Портняжное дело',[202]='Инженерное дело',[333]='Наложение чар'}
A.methods={[1]='Добыча',[2]='Снятие шкур',[3]='Карманная кража',[4]='Forever · способ не разделён',[5]='Продажа · справочник QuestieDB',[6]='Продажа · личное наблюдение',[7]='Добыча · справочник Forever',[8]='Личная находка · способ не определён',[9]='Classic · vMaNGOS через KB',[10]='Награда за задание',[11]='Изготовление',[12]='Сундук / объект · Classic',[13]='Содержимое предмета',[14]='Forever · сообщение игрока',[14]='Forever · сообщение игрока'}
function A:Safe(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d,e,f,g=pcall(fn,...);if ok then return a,b,c,d,e,f,g end
end
function A:Professions()
 local result={}
 if GetProfessions and GetProfessionInfo then for _,idx in pairs({GetProfessions()}) do local _,_,_,_,_,_,id=GetProfessionInfo(idx);if id then result[id]=true end end end
 if GetNumSkillLines and GetSkillLineInfo then
  for i=1,GetNumSkillLines() do local name,header=GetSkillLineInfo(i);if not header then
   for id,pname in pairs(self.profNames) do if name==pname then result[id]=true end end
   local english={['First Aid']=129,Blacksmithing=164,Leatherworking=165,Alchemy=171,Cooking=185,Tailoring=197,Engineering=202,Enchanting=333}
   if english[name] then result[english[name]]=true end
  end end
 end
 return result
end
function A:ClassFits(item,id,force)
 if not force and not self.db.classOnly then return true end
 if item.classID==-1 then return false end
 if item.classID~=2 and item.classID~=4 then return true end
 local _,class,classID=UnitClass('player');local data=self.classData.classes[(class or ''):lower()]
 local restrictions=self.classData.restricted or {};local mask=restrictions[tostring(id)] or restrictions[id]
 if mask and classID and math.floor(mask/2^(classID-1))%2==0 then return false end
 if item.classID==4 and (item.subclass==0 or item.slot=='Back' or item.slot=='Cloak') then return true end
 for _,g in ipairs(data and data.gear or {}) do if g[1]==item.classID and g[2]==item.subclass and g[3]<=UnitLevel('player') then return true end end
 return false
end
function A:Matches(entry,skills)
 if entry[4] and not self.db.sharedLoot then return false end
 if entry[2]==4 and not self.db.observed then return false end
 local item=self.items[entry[1]];if not item then return false end
 if (entry[2]==5 or entry[2]==6) and self.db.vendorRelevant and not self:VendorRelevant(item,entry[1],skills) then return false end
 if (entry[2]==5 or entry[2]==6) and self.db.vendorLevel and (item.level or 0)>UnitLevel('player') then return false end
 if (entry[2]==5 or entry[2]==6) and item.classID~=1 and item.classID~=2 and item.classID~=4 and item.classID~=7 and item.classID~=9 then return false end
 if not self.db.qualities[item.quality] then return false end
 if entry[2]==2 and not self.db.skinning or entry[2]==3 and not self.db.pickpocket then return false end
 if not self:ClassFits(item,entry[1]) then return false end
 local prof=self.db.prof
 if prof~=0 then
  local found=false
  for _,id in ipairs(item.prof or {}) do if prof==-2 or prof==-1 and skills[id] or prof==id then found=true end end
  if not found then return false end
 end
 return true
end
function A:Loot(id,skills,forceSpecial)
 local mob=self.mobs[id];local list=mob and (mob.vendor and mob.stock or mob.loot) or {}
 local unique={};local out={}
 for _,entry in ipairs(list or {}) do if self:Matches(entry,skills or self.skills or {}) then
  local previous=unique[entry[1]]
  local priority=entry[2]==8 and 5 or entry[2]==6 and 4 or entry[2]==4 and 3 or entry[2]==14 and 2 or entry[4] and 0 or 1
  if not previous then
   local copy={};for i=1,8 do copy[i]=entry[i] end;copy.alternatives={entry};copy.priority=priority;unique[entry[1]]=copy
  else
   local alternatives=previous.alternatives;alternatives[#alternatives+1]=entry
   if priority>previous.priority then local copy={};for i=1,8 do copy[i]=entry[i] end;copy.alternatives=alternatives;copy.priority=priority;unique[entry[1]]=copy end
  end
 end end
 for _,entry in pairs(unique) do out[#out+1]=entry end
 table.sort(out,function(a,b)
  local aq,bq=self.items[a[1]].quality,self.items[b[1]].quality
  if (forceSpecial or self.db.specialFirst) and not (mob and mob.vendor) then local ar,br=self:SpecialRank(a[1]),self:SpecialRank(b[1]);if ar~=br then return ar>br end end
  if (mob and mob.vendor or self.db.sort=='quality') and aq~=bq then return aq>bq end
  if a[3]~=b[3] then return a[3]>b[3] end
  if aq~=bq then return aq>bq end
  return a[1]<b[1]
 end)
 return out
end
function A:Chance(entry)
 if entry[2]==10 then return 'Награда за задание' end
 if entry[2]==11 then return 'Изготовление' end
 if entry[2]==13 then return 'Внутри другого предмета' end
 if entry[2]==9 or entry[2]==12 then return entry[3]<0 and 'Шанс неизвестен · Classic' or string.format('%.3g%% · Classic',entry[3]) end
 if entry[2]==14 then return 'Сообщение игрока · шанс неизвестен' end
 if entry[2]==8 then return 'Лично найдено · шанс неизвестен' end
 if entry[2]==7 then return 'шанс неизвестен · Forever DB' end
 if entry[2]==5 then return 'Покупка · справочник' end
 if entry[2]==6 then
  if entry[8] then return 'Особая стоимость · у продавца' end
  if type(entry[5])~='number' or entry[5]<0 then return 'Цена уточняется' end
  local p=entry[5];return string.format('%dз %dс %dм',math.floor(p/10000),math.floor(p/100)%100,p%100)..(entry[6] and entry[6]>1 and (' / '..entry[6]..' шт.') or '')
 end
 if entry[2]==4 then return string.format('%.3g%% · Forever',entry[3]) end
 if entry[3]<0 then return 'шанс неизвестен' end
 return string.format('%.4g%% · Classic',entry[3])
end
function A:BuildMap(mapID)
 self.skills=self:Professions();local cells={};local counted={};local total=0
 local function visible(id)
  if self.focus then return self.focus.ids[id]==true end
  local mob=self.mobs[id];local faction=self:Safe(UnitFactionGroup,'player');local friendly=mob.friendly or ''
  if not mob.vendor and not mob.huntable and (mob.service or mob.kind=='Humanoid') and (friendly=='AH' or faction=='Alliance' and friendly:find('A',1,true) or faction=='Horde' and friendly:find('H',1,true)) then return false end
  return (#self:Loot(id,self.skills)>0 or mob.huntable and #(mob.loot or {})==0) and (not mob.vendor or friendly=='' or friendly=='AH' or faction=='Alliance' and friendly:find('A',1,true) or faction=='Horde' and friendly:find('H',1,true))
   and (self.db.mapLayer=='all' or self.db.mapLayer=='vendors' and mob.vendor or self.db.mapLayer=='mobs' and not mob.vendor)
 end
 local visibility={};local function add(id,x,y,area)
  if visibility[id]==nil then visibility[id]=visible(id) and true or false end
  if not visibility[id] then return end
  if not counted[id] then counted[id]=true;total=total+1 end
  local key=string.format('%.4f:%.4f:%d',x,y,area or 0);local cell=cells[key]
  if not cell then cell={x=x,y=y,ids={},seen={},dungeon=area};cells[key]=cell end
  if not cell.seen[id] then cell.seen[id]=true;cell.ids[#cell.ids+1]=id end
 end
 for _,id in ipairs(self.zoneIndex[mapID] or {}) do
  for _,p in ipairs(self.mobs[id].points) do if p[1]==mapID then add(id,p[2],p[3]) end end
 end
 for _,p in ipairs((self.entranceIndex or {})[mapID] or {}) do if self.focus or not self.db.dungeonPins or not (self.dungeonPinAreas or {})[p.area] then add(p.npcID,p.x,p.y,p.area) end end
 local out={};for _,cell in pairs(cells) do table.sort(cell.ids);out[#out+1]=cell end
 table.sort(out,function(a,b) if a.y~=b.y then return a.y<b.y end;if a.x~=b.x then return a.x<b.x end;return (a.dungeon or 0)<(b.dungeon or 0) end)
 return out,total
end
function A:Invalidate()
 self:ClearFocus(false,true);self:Update()
end
function A:Init()
 MobAtlasDB=type(MobAtlasDB)=='table' and MobAtlasDB or {};self.db=MobAtlasDB
 local defaults={rareEnabled=true,rareAlerts=true,rareSound=true,rareMap=true,rareMinimap=true,rareMaxRange=true,habitatGlow=true,dungeonPins=true,language='auto',enabled=true,quality='all',classOnly=false,prof=0,skinning=true,pickpocket=false,visibleItems=5,sort='chance',unitLoot=true,observed=true,minimapAngle=225,sharedLoot=false,vendorLevel=true,vendorRelevant=true,mapLayer='all',specialFirst=true}
 for k,v in pairs(defaults) do if self.db[k]==nil then self.db[k]=v end end
 if self.db.language~='auto' and self.db.language~='ruRU' and self.db.language~='enUS' then self.db.language='auto' end
 if not ({all=true,green=true,blue=true,both=true})[self.db.quality] then self.db.quality='all' end
 if type(self.db.qualities)~='table' then
  local old=self.db.quality;self.db.qualities={}
  for q=-1,7 do self.db.qualities[q]=old=='all' or old=='green' and q==2 or old=='blue' and q==3 or old=='both' and (q==2 or q==3) end
 end
 if self.db.prof~=0 and self.db.prof~=-1 and self.db.prof~=-2 and not self.profNames[self.db.prof] then self.db.prof=0 end
 if not ({[3]=true,[5]=true,[7]=true})[self.db.visibleItems] then self.db.visibleItems=5 end
 if not ({all=true,mobs=true,vendors=true,none=true})[self.db.mapLayer] then self.db.mapLayer='all' end
 if self.db.sort~='quality' then self.db.sort='chance' end
 self:MergeForever();self:ApplyCatalog();self:ApplyExpansion();if self.MergeRareCatalog then self:MergeRareCatalog() end;self:RestoreMerchants();self:RestoreLoot();self:ApplyForeverItems()
 self.zoneIndex={}
 for id,mob in pairs(self.mobs) do local seen={};for _,p in ipairs(mob.points) do if not seen[p[1]] then seen[p[1]]=true;self.zoneIndex[p[1]]=self.zoneIndex[p[1]] or {};table.insert(self.zoneIndex[p[1]],id) end end end
 for _,ids in pairs(self.zoneIndex) do table.sort(ids) end
 self:BuildAtlasIndex();self:HookItemSearch();self:CreateSettings();self:CreateMinimapButton();self:HookUnitLoot();self:RestoreQuestPin();if self.StartNpcObservation then self:StartNpcObservation() end;if self.StartRareTracking then self:StartRareTracking() end;self.dirty=true
 SLASH_MOBATLAS1='/mobatlas';SLASH_MOBATLAS2='/следопыт'
 SlashCmdList.MOBATLAS=function(msg)
  if msg=='clear' then self:ClearFocus()
  elseif msg=='off' then self.db.enabled=false;self:Invalidate()
  elseif msg=='on' then self.db.enabled=true;self:Invalidate()
  elseif msg=='map' then local id=WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or self:Safe(C_Map and C_Map.GetBestMapForUnit,'player');if id then local ok,why=self:OpenMapAt(id);if not ok and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self:L(why)) end end
  elseif msg=='rares' and self.OpenRareSettings then self:OpenRareSettings()
  elseif msg=='prep' then self:OpenPreparation()
  elseif msg=='settings' then self.settings:SetShown(not self.settings:IsShown());self:RefreshSettings()
  else self:OpenAtlas(msg~='' and msg or nil) end
 end
 C_Timer.NewTicker(.5,function() self:Update() end)
end
A.events=CreateFrame('Frame')
A.events:SetScript('OnEvent',function(_,event,arg)
 if event=='GET_ITEM_INFO_RECEIVED' and A.db then A:RefreshObservedLootItem(arg)
 elseif event=='PLAYER_LOGIN' then A:Init() elseif A.db and (event=='QUEST_LOG_UPDATE' or event=='QUEST_ACCEPTED' or event=='QUEST_TURNED_IN') then A:QuestLogChanged() elseif A.db and (event=='LOOT_OPENED' or event=='LOOT_READY' or event=='LOOT_SLOT_CHANGED') then A:CaptureLoot() elseif A.db and (event=='MERCHANT_SHOW' or event=='MERCHANT_UPDATE') then A:CaptureMerchant() elseif A.db then A:Invalidate() end
end)
for _,event in ipairs({'PLAYER_LOGIN','SKILL_LINES_CHANGED','PLAYER_LEVEL_UP','PLAYER_ENTERING_WORLD','MERCHANT_SHOW','MERCHANT_UPDATE','LOOT_OPENED','LOOT_READY','LOOT_SLOT_CHANGED','GET_ITEM_INFO_RECEIVED','QUEST_LOG_UPDATE','QUEST_TURNED_IN','QUEST_ACCEPTED'}) do A.events:RegisterEvent(event) end

-- Observations stay separate from Classic methods: this feed does not identify the method.
function A:MergeForever()
 for _,r in ipairs(self.foreverRates or {}) do
  local id,itemID=r[1],r[2]
  if not self.items[itemID] then self.items[itemID]={name='Предмет #'..itemID,quality=-1,classID=-1,subclass=-1,prof={}} end
  if not self.mobs[id] then self.mobs[id]={name=(self.foreverNames or {})[id] or ('Существо #'..id),min=0,max=0,points={},loot={}} end
  local mob=self.mobs[id];local exists=false
  for _,e in ipairs(mob.loot) do if e[1]==itemID and e[2]==4 then exists=true end end
  if not exists then table.insert(mob.loot,{itemID,4,r[3],false,r[4],r[5],r[6]}) end
 end
end
function A:ApplyForeverItems()
 for id,item in pairs(self.items) do
  local v=(self.foreverItems or {})[id]
  if v and not item.observed then item.classID=v[1];item.subclass=v[2];if v[4]>=0 then if item.metadataSource~='ahledger' then item.quality=v[4] end end;if v[3]==16 then item.slot='Back' end end
  if (self.foreverProf or {})[id] then item.prof=self.foreverProf[id] end
 end
end
function A:ItemDisplay(id)
 local item=self.items[id];local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
 if fn then
  local result={pcall(fn,id)}
  if result[1] and result[2] then
   local icon=result[11];return result[2],(not icon or icon==134400) and 'Interface\\AddOns\\MobAtlas\\Art\\TrackAtlas.tga' or icon
  end
 end
 self:Safe(C_Item and C_Item.RequestLoadItemDataByID,id)
 local icon=self:Safe(C_Item and C_Item.GetItemIconByID or GetItemIcon,id)
 return item and (self:Safe(GetLocale)=='ruRU' and item.ruName or item.name) or ('Предмет #'..id),(not icon or icon==134400) and 'Interface\\AddOns\\MobAtlas\\Art\\TrackAtlas.tga' or icon
end
function A:NpcID(unit)
 local guid=self:Safe(UnitGUID,unit)
 if type(guid)~='string' then return end
 local kind,id=guid:match('^(%a+)%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-')
 if kind=='Creature' or kind=='Vehicle' then return tonumber(id) end
end

function A:ApplyCatalog()
 if not self.catalog then return end
 for _,mob in pairs(self.mobs) do mob.points={} end
 for id,v in pairs(self.vendorItems or {}) do
  if not self.items[id] then self.items[id]=v else
   local item=self.items[id];item.ruName=v.ruName
   if item.name:find('Предмет #',1,true) then item.name=v.name end
   if item.level==nil then item.level=v.level end
   if #(item.prof or {})==0 and #(v.prof or {})>0 then item.prof=v.prof end
  end
 end
 for id,c in pairs(self.catalog) do
  local mob=self.mobs[id]
  if mob or c.vendor or c.referenceLoot or c.reportedLoot then
   if not mob then mob={loot={}};self.mobs[id]=mob end
   for _,k in ipairs({'name','min','max','points','instances','kind','family','vendor','stock','friendly','huntable','service','reportSource'}) do mob[k]=c[k] end
   local reported={};for _,e in ipairs(mob.loot) do if e[2]==14 then reported[e[1]]=true end end
   for _,iid in ipairs(c.reportedLoot or {}) do if self.items[iid] and not reported[iid] then mob.loot[#mob.loot+1]={iid,14,-1,false} end end
   local existing={};local conditional={};local direct={}
   for _,e in ipairs(mob.loot) do
    if e[2]==7 then existing[e[1]]=true end
    if e[2]==1 then if e[4] then conditional[e[1]]=true else direct[e[1]]=true end end
   end
   local reports={};for _,e in ipairs(mob.loot) do if e[2]==14 then reports[e[1]]=true end end
   for _,iid in ipairs(c.reportedLoot or {}) do if self.items[iid] and not reports[iid] then mob.loot[#mob.loot+1]={iid,14,-1,false} end end
   for _,iid in ipairs(c.referenceLoot or {}) do if not existing[iid] then
    mob.loot[#mob.loot+1]={iid,7,-1,((self.commonWorldItems or {})[iid] or conditional[iid] and not direct[iid])==true}
   end end
  end
 end
end
function A:RestoreMerchants()
 self.db.merchants=type(self.db.merchants)=='table' and self.db.merchants or {}
 for id,m in pairs(self.db.merchants) do
  for iid,item in pairs(m.items or {}) do self.items[iid]=item end
  local npc=self.mobs[id] or {points={},min=0,max=0,loot={}}
  npc.vendor=true;npc.name=m.name;npc.stock=m.stock;self.mobs[id]=npc
 end
end
function A:CaptureMerchant()
 local id=self:NpcID('npc');local count=self:Safe(GetMerchantNumItems)
 if not id or type(count)~='number' or count<1 then return end
 local old=self.db.merchants[id];local m={name=self:Safe(UnitName,'npc') or ('Торговец #'..id),stock={},items={},build=self:Safe(GetBuildInfo),seen=self:Safe(time)}
 local incomplete=count>500
 for i=1,math.min(count,500) do
  local link=self:Safe(GetMerchantItemLink,i);local iid=type(link)=='string' and tonumber(link:match('item:(%d+)'))
  if iid then
   local info=self:Safe(C_MerchantFrame and C_MerchantFrame.GetItemInfo,i)
   if type(info)~='table' then
    local name,texture,price,quantity,stock,usable,extended=self:Safe(GetMerchantItemInfo,i)
    info={name=name,texture=texture,price=price,stackCount=quantity,numAvailable=stock,hasExtendedCost=extended}
   end
   local item=self.items[iid] or {name=info.name or ('Предмет #'..iid),quality=-1,classID=-1,subclass=-1,prof={}}
   local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
   if fn then local v={pcall(fn,iid)};if v[1] and v[2] then item={name=v[2],quality=v[4] or -1,level=v[6] or 0,classID=v[13] or -1,subclass=v[14] or -1,prof=item.prof or {},observed=true} end end
   m.items[iid]=item;self.items[iid]=item
   m.stock[#m.stock+1]={iid,6,-1,false,info.price or -1,info.stackCount or info.quantity or 1,info.numAvailable,info.hasExtendedCost}
  else incomplete=true end
 end
 -- Never replace a complete saved inventory with an incompletely cached merchant window.
 if incomplete or #m.stock==0 then return end
 local oldIDs={};local npc=self.mobs[id] or {points={},min=0,max=0,loot={}}
 for _,list in ipairs({npc.loot or {},npc.stock or {}}) do for _,e in ipairs(list) do oldIDs[e[1]]=true end end
 self.db.merchants[id]=m;npc.vendor=true;npc.name=m.name;npc.stock=m.stock;self.mobs[id]=npc
 self:RefreshNpcIndex(id,oldIDs);self.dirty=true;if self.atlas then self.atlas.results=nil end
end

-- Relevance, not a BiS score: level band, class proficiency, preferred armour, own trades.
function A:VendorRelevant(item,id,skills)
 local level=UnitLevel('player');local required=item.level
 if type(required)~='number' or required>level then return false end
 if item.classID==1 then
  if item.subclass==0 then return true end
  local _,class=UnitClass('player');if item.subclass==1 then return class=='WARLOCK' end
  local bagProf=({[2]=182,[3]=333,[4]=202,[5]=755,[6]=186,[7]=165,[8]=773,[9]=356,[10]=185})[item.subclass]
  return bagProf and skills and skills[bagProf] or false
 end
 if item.classID==7 or item.classID==9 then
  for _,prof in ipairs(item.prof or {}) do if skills and skills[prof] then return true end end
  return false
 end
 if item.classID~=2 and item.classID~=4 then return false end
 if not self:ClassFits(item,id,true) then return false end
 if (item.quality or -1)<(level<=10 and 1 or 2) then return false end
 if required<math.max(0,level-8) then return false end
 if item.classID==4 and item.subclass and item.subclass>=1 and item.subclass<=4 and item.slot~='Back' and item.slot~='Cloak' then
  local _,class=UnitClass('player')
  local armour={MAGE=1,PRIEST=1,WARLOCK=1,ROGUE=2,DRUID=2,HUNTER=level>=40 and 3 or 2,SHAMAN=level>=40 and 3 or 2,WARRIOR=level>=40 and 4 or 3,PALADIN=level>=40 and 4 or 3}
  if armour[class] and item.subclass~=armour[class] then return false end
 end
 return true
end
