local _,A=...
-- Only loot API source GUIDs: never infer a source from the target or player position.
function A:RestoreLoot()
 self.db.lootFinds=type(self.db.lootFinds)=='table' and self.db.lootFinds or {}
 for id,record in pairs(self.db.lootFinds) do
  local mob=self.mobs[id]
  if not mob then mob=self:EnsureObservedNpc(id) end
  mob.huntable=true
  local known={};for _,e in ipairs(mob.loot) do if e[2]==8 then known[e[1]]=true end end
  for iid,item in pairs(record.items or {}) do
   if not self.items[iid] then self.items[iid]=item end
   if item.quality==-1 or item.classID==-1 then self.pendingLootItems=self.pendingLootItems or {};self.pendingLootItems[iid]=self.pendingLootItems[iid] or {};self.pendingLootItems[iid][id]=true;self:Safe(C_Item and C_Item.RequestLoadItemDataByID,iid) end
   if not known[iid] then mob.loot[#mob.loot+1]={iid,8,-1,false} end
  end
 end
end
function A:CaptureLoot()
 if not GetLootSourceInfo or not GetLootSlotLink or not GetNumLootItems then return end
 local count=self:Safe(GetNumLootItems);if issecretvalue and issecretvalue(count) or type(count)~='number' then return end
 local changed=false
 for slot=1,math.min(count,100) do
  local link=self:Safe(GetLootSlotLink,slot);local iid=not (issecretvalue and issecretvalue(link)) and type(link)=='string' and tonumber(link:match('item:(%d+)'))
  if iid then
   local sources={pcall(GetLootSourceInfo,slot)}
   if sources[1] then for i=2,#sources,2 do
    local guid=sources[i];local id=not (issecretvalue and issecretvalue(guid)) and type(guid)=='string' and tonumber(guid:match('^Creature%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-'))
    if id then
     local record=self.db.lootFinds[id] or {items={},name=self.mobs[id] and self.mobs[id].name};self.db.lootFinds[id]=record
     if not record.items[iid] then
      local item=self.items[iid] or {name='Предмет #'..iid,quality=-1,classID=-1,subclass=-1,prof={}}
      local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
      if fn then local v={pcall(fn,iid)};if v[1] and v[2] then item={name=v[2],quality=v[4] or -1,level=v[6],classID=v[13] or -1,subclass=v[14] or -1,prof=item.prof or {},observed=true} end end
      record.items[iid]=item;record.seen=self:Safe(time)
      local mob=self.mobs[id]
      if not mob then mob=self:EnsureObservedNpc(id) end
      if not self.items[iid] or item.observed then local old=self.items[iid];if old then item.ruName=old.ruName;item.referenceName=old.referenceName or old.name end;self.items[iid]=item end
      if item.quality==-1 or item.classID==-1 then self.pendingLootItems=self.pendingLootItems or {};self.pendingLootItems[iid]=self.pendingLootItems[iid] or {};self.pendingLootItems[iid][id]=true;self:Safe(C_Item and C_Item.RequestLoadItemDataByID,iid) end
      mob.huntable=true
      local entry={iid,8,-1,false};mob.loot[#mob.loot+1]=entry;self:IndexLootEntry(id,entry);changed=true
     end
    end
   end end
  end
 end
 if changed then
  self.dirty=true
  if self.atlas then self.atlas.results=nil;self.atlas.sourceCache=nil end
 end
end

-- Client-confirmed attackability is stronger evidence than a reference faction flag.
function A:EnsureObservedNpc(id)
 local mob=self.mobs[id];if mob then return mob end
 local c=(self.catalog or {})[id]
 mob={name=c and c.name or ('Существо #'..id),min=c and c.min or 0,max=c and c.max or 0,points=c and c.points or {},instances=c and c.instances or {},kind=c and c.kind or 'Unknown',family=c and c.family or '',friendly=c and c.friendly or '',service=c and c.service,loot={}}
 self.mobs[id]=mob
 if self.zoneIndex then
  local seen={};for _,p in ipairs(mob.points) do if not seen[p[1]] then
   seen[p[1]]=true;self.zoneIndex[p[1]]=self.zoneIndex[p[1]] or {};local exists=false
   for _,npcID in ipairs(self.zoneIndex[p[1]]) do if npcID==id then exists=true;break end end
   if not exists then self.zoneIndex[p[1]][#self.zoneIndex[p[1]]+1]=id end
  end end
 end
 return mob
end
function A:CaptureNpcTraits(unit)
 local guid=self:Safe(UnitGUID,unit)
 if issecretvalue and issecretvalue(guid) or type(guid)~='string' then return end
 local id=tonumber(guid:match('^Creature%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-'));if not id then return end
 local attackable=self:Safe(UnitCanAttack,'player',unit)
 if issecretvalue and issecretvalue(attackable) or attackable~=true then return end
 local mob=self:EnsureObservedNpc(id);local changed=mob.huntable~=true;mob.huntable=true
 local kinds={Beast='Beast',['Зверь']='Beast',Humanoid='Humanoid',['Гуманоид']='Humanoid',Undead='Undead',['Нежить']='Undead',Demon='Demon',['Демон']='Demon',Dragonkin='Dragonkin',['Дракон']='Dragonkin',Elemental='Elemental',['Элементаль']='Elemental',Mechanical='Mechanical',['Механизм']='Mechanical',Giant='Giant',['Великан']='Giant',Critter='Critter',['Животное']='Critter'}
 local kind=self:Safe(UnitCreatureType,unit)
 if not (issecretvalue and issecretvalue(kind)) and kinds[kind] and kinds[kind]~=mob.kind then mob.kind=kinds[kind];changed=true end
 local name=self:Safe(UnitName,unit)
 if not (issecretvalue and issecretvalue(name)) and type(name)=='string' and name~=mob.name then mob.name=name;changed=true end
 self.db.npcTraits=self.db.npcTraits or {}
 local faction=UnitFactionGroup('player');local saved=self.db.npcTraits[id]
 if changed or not saved or saved.faction~=faction then
  self.db.npcTraits[id]={huntable=true,kind=mob.kind,name=mob.name,faction=faction};self.dirty=true
 end
end
function A:StartNpcObservation()
 self.db.npcTraits=type(self.db.npcTraits)=='table' and self.db.npcTraits or {}
 for id,traits in pairs(self.db.npcTraits) do
  if type(traits)=='table' and traits.huntable and traits.faction==UnitFactionGroup('player') then
   local mob=self:EnsureObservedNpc(id);mob.huntable=true
   if type(traits.kind)=='string' then mob.kind=traits.kind end
  end
 end
 if self.npcObservationEvents then return end
 local f=CreateFrame('Frame');self.npcObservationEvents=f
 f:SetScript('OnEvent',function(_,event,unit)
  self:CaptureNpcTraits(event=='PLAYER_TARGET_CHANGED' and 'target' or event=='UPDATE_MOUSEOVER_UNIT' and 'mouseover' or unit)
 end)
 for _,event in ipairs({'PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','NAME_PLATE_UNIT_ADDED'}) do f:RegisterEvent(event) end
 self:CaptureNpcTraits('target');self:CaptureNpcTraits('mouseover')
end

function A:RefreshObservedLootItem(iid)
 if issecretvalue and issecretvalue(iid) then return end
 local pending=self.pendingLootItems and self.pendingLootItems[iid];if not pending then return end
 local fn=C_Item and C_Item.GetItemInfo or GetItemInfo;if type(fn)~='function' then return end
 local v={pcall(fn,iid)};if not v[1] or type(v[2])~='string' or issecretvalue and issecretvalue(v[2]) then return end
 local item=self.items[iid] or {};item.name=v[2];item.quality=v[4] or item.quality;item.level=v[6] or item.level;item.classID=v[13] or item.classID;item.subclass=v[14] or item.subclass;item.observed=true;item.prof=item.prof or {};self.items[iid]=item
 for npcID in pairs(pending) do local record=self.db.lootFinds[npcID];if record then record.items[iid]=item end end
 self.pendingLootItems[iid]=nil
 if self.searchTerms then self.searchTerms[iid]=self:SearchText(item.name..' '..(item.ruName or '')..' '..(item.referenceName or '')) end
 if self.atlas then self.atlas.results=nil;self.atlas.sourceCache=nil end
 self.dirty=true
end
