local _,A=...
-- Only loot API source GUIDs: never infer a source from the target or player position.
function A:RestoreLoot()
 self.db.lootFinds=type(self.db.lootFinds)=='table' and self.db.lootFinds or {}
 for id,record in pairs(self.db.lootFinds) do
  local mob=self.mobs[id]
  if not mob then mob={name=record.name or ('Существо #'..id),min=0,max=0,points={},loot={}};self.mobs[id]=mob end
  local known={};for _,e in ipairs(mob.loot) do if e[2]==8 then known[e[1]]=true end end
  for iid,item in pairs(record.items or {}) do
   if not self.items[iid] then self.items[iid]=item end
   if not known[iid] then mob.loot[#mob.loot+1]={iid,8,-1,false} end
  end
 end
end
function A:CaptureLoot()
 if not GetLootSourceInfo or not GetLootSlotLink or not GetNumLootItems then return end
 local count=self:Safe(GetNumLootItems);if type(count)~='number' then return end
 local changed=false
 for slot=1,math.min(count,100) do
  local link=self:Safe(GetLootSlotLink,slot);local iid=type(link)=='string' and tonumber(link:match('item:(%d+)'))
  if iid then
   local sources={pcall(GetLootSourceInfo,slot)}
   if sources[1] then for i=2,#sources,2 do
    local guid=sources[i];local id=type(guid)=='string' and tonumber(guid:match('^Creature%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-'))
    if id then
     local record=self.db.lootFinds[id] or {items={},name=self.mobs[id] and self.mobs[id].name};self.db.lootFinds[id]=record
     if not record.items[iid] then
      local item=self.items[iid] or {name='Предмет #'..iid,quality=-1,classID=-1,subclass=-1,prof={}}
      local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
      if fn then local v={pcall(fn,iid)};if v[1] and v[2] then item={name=v[2],quality=v[4] or -1,level=v[6],classID=v[13] or -1,subclass=v[14] or -1,prof=item.prof or {},observed=true} end end
      record.items[iid]=item;record.seen=self:Safe(time)
      local mob=self.mobs[id]
      if not mob then mob={name=record.name or ('Существо #'..id),min=0,max=0,points={},loot={}};self.mobs[id]=mob end
      if not self.items[iid] then self.items[iid]=item end
      local entry={iid,8,-1,false};mob.loot[#mob.loot+1]=entry;self:IndexLootEntry(id,entry);changed=true
     end
    end
   end end
  end
 end
 if changed then
  self.dirty=true
  if self.atlas then self.atlas.results=nil end
 end
end
