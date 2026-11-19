local _,A=...
function A:ApplyExpansion()
 for iid,v in pairs(self.extraItems or {}) do
  local item=self.items[iid]
  if not item then self.items[iid]=v else
   if not item.observed then
    for _,k in ipairs({'name','quality','classID','subclass','level','slot','estimated','metadataSource','itemLevel'}) do
     if v[k]~=nil and (v.metadataSource=='ahledger' or item[k]==nil or item[k]==-1 or k=='estimated') then item[k]=v[k] end
    end
   end
  end
 end
 for id,v in pairs(self.extraMobs or {}) do
  local mob=self.mobs[id]
  if not mob then
   local c=(self.catalog or {})[id];mob={name=v.name,min=v.min or 0,max=v.max or 0,points=c and c.points or {},instances=c and c.instances or {},kind=c and c.kind or 'Unknown',friendly=c and c.friendly or '',loot={}};self.mobs[id]=mob
  end
  local known={};for _,e in ipairs(mob.loot or {}) do if e[2]==9 then known[e[1]]=true end end
  for _,e in ipairs(v.loot or {}) do if not known[e[1]] then mob.loot[#mob.loot+1]=e end end
  -- A reference addition never replaces an inventory observed by the player.
  if not self.db.merchants or not self.db.merchants[id] then
   if #(v.stock or {})>0 then
    mob.vendor=true;mob.stock=mob.stock or {};known={};for _,e in ipairs(mob.stock) do known[e[1]]=true end
    for _,e in ipairs(v.stock) do if not known[e[1]] then mob.stock[#mob.stock+1]=e end end
   end
  end
 end
end
function A:UsefulItem(iid)
 local item=self.items[iid];if not item then return false end
 if #((self.itemSources or {})[iid] or {})==0 and #((self.otherSources or {})[iid] or {})==0 then return false end
 return self:VendorRelevant(item,iid,self:Professions())
end
function A:QuestName(id)
 local q=(self.dungeonQuests or {})[id]
 return self:Safe(C_QuestLog and C_QuestLog.GetTitleForQuestID,id) or q and ((self:Safe(GetLocale)=='ruRU' and q.ruName) or q.name) or ('Задание #'..id)
end
function A:QuestFits(q)
 if q.classMask and q.classMask>0 then
  local _,_,id=UnitClass('player');if not id or math.floor(q.classMask/2^(id-1))%2~=1 then return false end
 end
 local mask=q.raceMask or 0
 if mask>0 then
  local _,_,race=self:Safe(UnitRace,'player')
  if race then if math.floor(mask/2^(race-1))%2~=1 then return false end
  else
   local faction=UnitFactionGroup('player');local bits=faction=='Alliance' and {0,2,3,6,32} or {1,4,5,7,33};local matches=false
   for _,bit in ipairs(bits) do if math.floor(mask/2^bit)%2==1 then matches=true end end
   if not matches then return false end
  end
 end
 return true
end
function A:QuestState(id)
 local q=(self.dungeonQuests or {})[id];if not q then return 'unknown','Условия пока неизвестны' end
 if self:Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted,id) then return 'done','Выполнено' end
 if self:Safe(C_QuestLog and C_QuestLog.IsOnQuest,id) then return 'active','Уже в журнале' end
 if not self:QuestFits(q) then return 'restricted','Другая фракция, раса или класс' end
 local level=UnitLevel('player')
 if level<(q.min or 0) then return 'level','Доступно с '..q.min..' ур.' end
 if (q.max or 0)>0 and level>q.max then return 'restricted','Выше предельного уровня' end
 for _,prev in ipairs(q.preAll or {}) do if prev>0 and not self:Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted,prev) then return 'chain','Сначала: '..self:QuestName(prev),prev end end
 if #(q.preAny or {})>0 then
  local done,positive=false,false
  for _,prev in ipairs(q.preAny) do if prev>0 then positive=true;if self:Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted,prev) then done=true end end end
  if positive and not done then for _,prev in ipairs(q.preAny) do if prev>0 then return 'chain','Нужна предыдущая часть цепочки',prev end end end
 end
 if q.inside then return 'check','Берётся внутри подземелья' end
 if q.minUnknown then return 'check','Минимальный уровень не подтверждён — проверь у NPC' end
 if q.special then return 'check','Особые условия — проверь у NPC' end
 if #(q.givers or {})==0 then return 'check',#(q.startItems or {})>0 and 'Начинается с предмета' or 'Место начала неизвестно' end
 return 'ready','Можно проверить у NPC'
end
function A:FirstQuestStep(id,seen)
 seen=seen or {};if seen[id] then return id end;seen[id]=true
 local state,_,prev=self:QuestState(id)
 if state=='chain' and prev then
  local q=self.dungeonQuests[id]
  for _,candidate in ipairs(q.preAny or {}) do if candidate>0 then local s=self:QuestState(candidate);if s=='ready' or s=='active' then return candidate end end end
  return self:FirstQuestStep(prev,seen)
 end
 return id
end
function A:DungeonQuestList(area,allLevels)
 local out={};local level=UnitLevel('player')
 for id,q in pairs(self.dungeonQuests or {}) do
  local member=false;for _,d in ipairs(q.dungeons) do if d==area then member=true end end
  if member and self:QuestFits(q) then
   local state=self:QuestState(id)
   if state~='done' and state~='restricted' and (allLevels or (q.minUnknown and q.recommendedMin or q.min or 0)<=level and (q.level or 0)>=level-10) then
    local step=self:FirstQuestStep(id);local stepstate=self:QuestState(step)
    out[#out+1]={id=id,step=step,state=state,stepstate=stepstate,priority=state=='active' and 0 or state=='ready' and 1 or state=='chain' and 2 or state=='check' and 3 or 4}
   end
  end
 end
 table.sort(out,function(a,b) if a.priority~=b.priority then return a.priority<b.priority end;local aq,bq=self.dungeonQuests[a.id],self.dungeonQuests[b.id];if aq.level~=bq.level then return math.abs(aq.level-level)<math.abs(bq.level-level) end;return a.id<b.id end)
 return out
end
function A:DungeonChoices(allLevels)
 local out={};local level=UnitLevel('player');local playerMap=self:Safe(C_Map and C_Map.GetBestMapForUnit,'player')
 local mapID=playerMap or (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
 for area,instance in pairs(self.instances or {}) do
  local excluded=({[2257]=true,[2597]=true,[3277]=true,[3358]=true,[5861]=true,[6618]=true,[5733]=true})[area]
  local all=not excluded and self:DungeonQuestList(area,true) or {};local current=self:DungeonQuestList(area,false)
  local min=100;local sum=0
  for _,entry in ipairs(all) do local q=self.dungeonQuests[entry.id];min=math.min(min,q.minUnknown and q.recommendedMin or q.min or 0);sum=sum+(q.level or 0) end
  if #all>0 and (allLevels or #current>0 or min<=level+8 and sum/#all>=level-10) then
   local nearby=false;for _,point in ipairs(instance.entrances or {}) do if point[1]==mapID then nearby=true end end
   out[#out+1]={id=area,name=self:DungeonName(area),englishName=instance.name,count=#all,available=#current,locked=#all-#current,level=math.floor(sum/#all+.5),min=min,nearby=nearby}
  end
 end
 table.sort(out,function(a,b) if a.nearby~=b.nearby then return a.nearby end;local ad,bd=math.abs(a.level-level),math.abs(b.level-level);if ad~=bd then return ad<bd end;return a.name<b.name end)
 return out
end
function A:FocusLocation(points,label,questID,kind)
 if InCombatLockdown() then return false,'Карту можно открыть после боя.' end
 if not points or #points==0 then return false,'Координаты пока неизвестны.' end
 local map=WorldMapFrame;local current=map and map.GetMapID and map:GetMapID();local chosen=points[1][1]
 for _,p in ipairs(points) do if p[1]==current then chosen=current;break end end
 if not map or not map.SetMapID then return false,'Карта сейчас недоступна.' end
 local opened,reason=self:OpenMapAt(chosen);if not opened then return false,reason end
 self:ClearFocus(false);self.focus={ids={},points=points,label=label,questID=questID,kind=kind or 'source'}
 self.db.enabled=true
 if self.atlas then self.atlas:Hide() end;if self.prep then self.prep:Hide() end
 self.dirty=true;self:Update();return true
end
function A:ShowQuestOnMap(id)
 local step=self:FirstQuestStep(id);local q=self.dungeonQuests[step]
 if not q then return false,'Задание пока не добавлено.' end
 local state,why=self:QuestState(step)
 if state=='active' then return false,'Задание уже в журнале — повторно брать его не нужно.' end
 if state=='level' or state=='restricted' or state=='done' then return false,why end
 if q.inside and q.entryPoints then
  return self:FocusLocation(q.entryPoints,'Вход: '..self:QuestName(step)..' — '..(q.pickupHint or 'Задание берётся внутри'),step,'entrance')
 end
 if q.sourceItem then
  local ok,reason=self:ShowItemOnMap(q.sourceItem)
  if ok and self.focus then self.focus.questID=step;self.focus.label=q.pickupHint or self:QuestName(step) end
  return ok,reason or q.pickupHint
 end
 local points={};local seen={}
 for _,giver in ipairs(q.givers) do for _,p in ipairs(giver.points) do local k=table.concat(p,':');if not seen[k] then seen[k]=true;points[#points+1]=p end end end
 if #points==0 then return false,#(q.startItems or {})>0 and 'Начинается с предмета #'..q.startItems[1]..'. Найди его в атласе.' or 'У квестодателя пока нет известных координат.' end
 return self:FocusLocation(points,'Взять: '..self:QuestName(step),step,'quest')
end
function A:PreparationChecks()
 local lines={};local free,total=0,0
 if C_Container and C_Container.GetContainerNumFreeSlots then
  for bag=0,4 do local n,family=self:Safe(C_Container.GetContainerNumFreeSlots,bag);if type(n)=='number' and (family==0 or family==nil) then free=free+n end;local size=self:Safe(C_Container.GetContainerNumSlots,bag);total=total+(type(size)=='number' and size or 0) end
  lines[#lines+1]=free<5 and ('Мало места: '..free..' свободных ячеек — пригодится сумка.') or ('Сумки: '..free..' свободных ячеек.')
 end
 if GetInventoryItemDurability then
  local lowest=1;local any=false
  for slot=1,18 do local cur,max=self:Safe(GetInventoryItemDurability,slot);if cur and max and max>0 then any=true;lowest=math.min(lowest,cur/max) end end
  if any then lines[#lines+1]=lowest<.4 and 'Перед выходом почини экипировку.' or 'Экипировка: ремонт пока не срочный.' end
 end
 if #lines==0 then lines[1]='Перед выходом: проверь место в сумках и ремонт.' end
 return table.concat(lines,'\n')
end

function A:QuestLogChanged()
 if self.questRefreshPending then return end
 self.questRefreshPending=true
 C_Timer.After(.2,function()
  self.questRefreshPending=false
  if self.focus and self.focus.questID then local state=self:QuestState(self.focus.questID);if state=='active' or state=='done' then self:ClearFocus() end end
  if self.prep and self.prep:IsShown() then self:RefreshPreparation() end
 end)
end
local dungeonNames={[717]='Тюрьма (Штормград)',[1581]='Мёртвые копи',[718]='Пещеры Стенаний',[2437]='Огненная Пропасть',[209]='Крепость Тёмного Клыка',[719]='Непроглядная Пучина',[491]='Лабиринты Иглошкурых',[722]='Курганы Иглошкурых',[721]='Гномреган',[796]='Монастырь Алого ордена',[1337]='Ульдаман',[1176]='Зул\'Фаррак',[1477]='Затонувший храм',[1584]='Глубины Чёрной горы',[1583]='Пик Чёрной горы',[2017]='Стратхольм',[2057]='Некроситет',[2100]='Мародон',[2557]='Забытый Город'}
function A:DungeonName(area)
 return dungeonNames[area] or (self.instances[area] or {}).name or ('Подземелье #'..area)
end
