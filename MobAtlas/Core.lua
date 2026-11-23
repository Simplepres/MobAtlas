local _,A=...
_G.MobAtlas=A
A.version='0.7.22';A.font='Interface\\AddOns\\MobAtlas\\Art\\NotoSans-Regular.ttf'
A.profNames={[129]='Первая помощь',[164]='Кузнечное дело',[165]='Кожевничество',[171]='Алхимия',[185]='Кулинария',[197]='Портняжное дело',[202]='Инженерное дело',[333]='Наложение чар'}
A.methods={[1]='Добыча',[2]='Снятие шкур',[3]='Карманная кража',[4]='Forever · способ не разделён',[5]='Продажа · справочник QuestieDB',[6]='Продажа · личное наблюдение',[7]='Добыча · справочник Forever',[8]='Личная находка · способ не определён',[9]='Classic · vMaNGOS через KB',[10]='Награда за задание',[11]='Изготовление',[12]='Сундук / объект · Classic',[13]='Содержимое предмета',[14]='Forever · сообщение игрока'}
function A:Safe(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d,e,f,g,h=pcall(fn,...);if ok then return a,b,c,d,e,f,g,h end
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
-- Independent Forever leveling weights, expressed per point of each item stat.
-- Blizzard class deep dives and WoWSims Forever inform role and weapon usage.
local function gearProfile(name,primary,weights,weapon,school,daggers)
 return {name,primary,daggers,weights=weights,weapon=weapon,school=school}
end
A.gearSpecs={
 WARRIOR={
  gearProfile('Оружие','strength',{STRENGTH=1,AGILITY=.44,ATTACK_POWER=.50,MELEE_HIT=1.45,MELEE_CRIT=.90,STAMINA=.15},'melee'),
  gearProfile('Неистовство','strength',{STRENGTH=1,AGILITY=.58,ATTACK_POWER=.50,MELEE_HIT=1.75,MELEE_CRIT=1.15,HASTE=.65,STAMINA=.15},'melee'),
  gearProfile('Защита','strength',{STRENGTH=.42,AGILITY=.50,STAMINA=1,ARMOR=.07,DEFENSE=1.15,DODGE=1.1,PARRY=1.1,BLOCK=.7,BLOCK_VALUE=.4,MELEE_HIT=.45,ATTACK_POWER=.2},'tank')},
 PALADIN={
  gearProfile('Свет','intellect',{HEALING=1,INTELLECT=.65,MP5=1.8,SPELL_CRIT=.95,SPIRIT=.12,STAMINA=.18}),
  gearProfile('Защита','strength',{STAMINA=1,ARMOR=.07,DEFENSE=1.1,DODGE=1,PARRY=.9,BLOCK=.88,BLOCK_VALUE=.4,SPELL_DAMAGE=.57,INTELLECT=.48,MP5=.76,STRENGTH=.38},'tank','HOLY'),
  gearProfile('Воздаяние','strength',{STRENGTH=1,ATTACK_POWER=.5,AGILITY=.48,MELEE_HIT=1.3,MELEE_CRIT=.92,SPELL_DAMAGE=.36,INTELLECT=.20,STAMINA=.15},'melee','HOLY')},
 HUNTER={
  gearProfile('Повелитель зверей','agility',{AGILITY=1,RANGED_AP=.54,RANGED_HIT=1.15,RANGED_CRIT=.65,INTELLECT=.22,MP5=.45,STAMINA=.17},'ranged'),
  gearProfile('Стрельба','agility',{AGILITY=1,RANGED_AP=.58,RANGED_HIT=1.5,RANGED_CRIT=1.05,INTELLECT=.20,MP5=.38,STAMINA=.14},'ranged'),
  gearProfile('Выживание','agility',{AGILITY=1,STRENGTH=.65,ATTACK_POWER=.50,MELEE_HIT=1.35,MELEE_CRIT=.95,INTELLECT=.22,STAMINA=.23},'melee')},
 ROGUE={
  gearProfile('Ликвидация','agility',{AGILITY=1,ATTACK_POWER=.48,STRENGTH=.48,MELEE_HIT=1.35,MELEE_CRIT=.78,STAMINA=.14},'melee',nil,true),
  gearProfile('Бой','agility',{AGILITY=1,ATTACK_POWER=.51,STRENGTH=.51,MELEE_HIT=1.65,MELEE_CRIT=.90,HASTE=.72,STAMINA=.15},'melee'),
  gearProfile('Скрытность','agility',{AGILITY=1,ATTACK_POWER=.58,STRENGTH=.53,MELEE_HIT=1.2,MELEE_CRIT=1.02,STAMINA=.23},'melee',nil,true)},
 PRIEST={
  gearProfile('Послушание','intellect',{HEALING=.68,SPELL_DAMAGE=.45,INTELLECT=.68,SPIRIT=.53,MP5=1.6,SPELL_HIT=.24,SPELL_CRIT=.45,STAMINA=.18},'wand'),
  gearProfile('Свет','intellect',{HEALING=1,INTELLECT=.6,SPIRIT=.8,MP5=1.42,SPELL_CRIT=.58,STAMINA=.2},'wand'),
  gearProfile('Тьма','intellect',{SPELL_DAMAGE=1,INTELLECT=.38,SPIRIT=.3,MP5=.47,SPELL_HIT=1.5,SPELL_CRIT=.65,STAMINA=.19},'wand','SHADOW')},
 SHAMAN={
  gearProfile('Стихии','intellect',{SPELL_DAMAGE=1,INTELLECT=.51,MP5=.67,SPELL_HIT=1.45,SPELL_CRIT=1.06,STAMINA=.17},nil,'NATURE'),
  gearProfile('Совершенствование','agility',{AGILITY=.76,STRENGTH=1,ATTACK_POWER=.50,MELEE_HIT=1.35,MELEE_CRIT=.87,SPELL_DAMAGE=.32,INTELLECT=.31,STAMINA=.17},'melee'),
  gearProfile('Исцеление','intellect',{HEALING=1,INTELLECT=.65,SPIRIT=.18,MP5=1.85,SPELL_CRIT=.63,STAMINA=.19})},
 MAGE={
  gearProfile('Тайная магия','intellect',{SPELL_DAMAGE=1,INTELLECT=.75,MP5=.86,SPIRIT=.38,SPELL_HIT=1.45,SPELL_CRIT=.68,STAMINA=.15},'wand','ARCANE'),
  gearProfile('Огонь','intellect',{SPELL_DAMAGE=1,INTELLECT=.43,MP5=.3,SPIRIT=.17,SPELL_HIT=1.5,SPELL_CRIT=1.12,STAMINA=.15},'wand','FIRE'),
  gearProfile('Лёд','intellect',{SPELL_DAMAGE=1,INTELLECT=.51,MP5=.41,SPIRIT=.23,SPELL_HIT=1.4,SPELL_CRIT=.79,STAMINA=.21},'wand','FROST')},
 WARLOCK={
  gearProfile('Колдовство','intellect',{SPELL_DAMAGE=1,INTELLECT=.34,STAMINA=.35,SPIRIT=.2,MP5=.15,SPELL_HIT=1.35,SPELL_CRIT=.49},'wand','SHADOW'),
  gearProfile('Демонология','intellect',{SPELL_DAMAGE=1,INTELLECT=.45,STAMINA=.53,MP5=.17,SPELL_HIT=1.31,SPELL_CRIT=.72},'wand'),
  gearProfile('Разрушение','intellect',{SPELL_DAMAGE=1,INTELLECT=.42,STAMINA=.24,MP5=.18,SPELL_HIT=1.52,SPELL_CRIT=1.07},'wand')},
 DRUID={
  gearProfile('Баланс','intellect',{SPELL_DAMAGE=1,INTELLECT=.55,SPIRIT=.37,MP5=.7,SPELL_HIT=1.31,SPELL_CRIT=.83,STAMINA=.18},nil,'NATURE_ARCANE'),
  gearProfile('Сила зверя · кошка','agility',{AGILITY=1,STRENGTH=.82,ATTACK_POWER=.43,FERAL_ATTACK_POWER=.43,MELEE_HIT=1.32,MELEE_CRIT=.99,STAMINA=.2}),
  gearProfile('Исцеление','intellect',{HEALING=1,INTELLECT=.56,SPIRIT=.8,MP5=1.46,SPELL_CRIT=.24,STAMINA=.18}),
  gearProfile('Сила зверя · медведь','agility',{STAMINA=1,ARMOR=.105,AGILITY=.83,DEFENSE=.95,DODGE=1.18,STRENGTH=.38,ATTACK_POWER=.2,FERAL_ATTACK_POWER=.2,MELEE_HIT=.62})}
}
local classDefaults={
 PRIEST=gearProfile('Подбор по классу','intellect',{INTELLECT=.62,HEALING=.63,SPELL_DAMAGE=.7,SPIRIT=.43,MP5=1.1,STAMINA=.2,SPELL_HIT=.6},'wand'),
 MAGE=gearProfile('Подбор по классу','intellect',{INTELLECT=.55,SPELL_DAMAGE=1,MP5=.54,SPIRIT=.24,SPELL_HIT=1.4,SPELL_CRIT=.8,STAMINA=.17},'wand'),
 WARLOCK=gearProfile('Подбор по классу','intellect',{INTELLECT=.4,SPELL_DAMAGE=1,STAMINA=.37,SPELL_HIT=1.4,SPELL_CRIT=.72},'wand'),
 ROGUE=gearProfile('Подбор по классу','agility',{AGILITY=1,STRENGTH=.5,ATTACK_POWER=.5,MELEE_HIT=1.4,MELEE_CRIT=.9,STAMINA=.17},'melee',nil,true),
 HUNTER=gearProfile('Подбор по классу','agility',{AGILITY=1,RANGED_AP=.55,RANGED_HIT=1.3,RANGED_CRIT=.87,INTELLECT=.21,STAMINA=.17},'ranged'),
 WARRIOR=gearProfile('Подбор по классу','strength',{STRENGTH=1,ATTACK_POWER=.5,AGILITY=.5,MELEE_HIT=1.55,MELEE_CRIT=.95,STAMINA=.20},'melee'),
}
local specIDs={ [259]=1,[260]=2,[261]=3,[71]=1,[72]=2,[73]=3,[65]=1,[66]=2,[70]=3,[253]=1,[254]=2,[255]=3,[256]=1,[257]=2,[258]=3,[262]=1,[263]=2,[264]=3,[62]=1,[63]=2,[64]=3,[265]=1,[266]=2,[267]=3,[102]=1,[103]=2,[104]=4,[105]=3 }
function A:RefreshGearProfile()
 local _,class=UnitClass('player');local choices=self.gearSpecs[class] or {};local index=self.db.gearSpec
 if not choices[index] then
  index=nil
  local getSpec=GetSpecialization or C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
  local getInfo=GetSpecializationInfo or C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
  local current=self:Safe(getSpec);local id=current and self:Safe(getInfo,current);id=id or self:Safe(PlayerUtil and PlayerUtil.GetCurrentSpecID)
  index=specIDs[id]
  if not index then
   local primary=self:Safe(GetPrimaryTalentTree,self:Safe(GetActiveTalentGroup) or 1)
   if type(primary)=='number' and choices[primary] then index=primary end
  end
  if not index then
   local tabInfo=GetTalentTabInfo or C_Talent and C_Talent.GetTalentTabInfo;local numTabs=GetNumTalentTabs or C_Talent and C_Talent.GetNumTalentTabs;local numTalents=GetNumTalents or C_Talent and C_Talent.GetNumTalents;local talentInfo=GetTalentInfo or C_Talent and C_Talent.GetTalentInfo
   local most=0;local count=self:Safe(numTabs);if type(count)~='number' or count<=0 then count=#choices end
   for tree=1,count do
    local info={pcall(tabInfo or function() end,tree)};local points
    if info[1] then
     if type(info[2])=='string' then points=info[4] elseif type(info[2])=='number' and type(info[3])=='string' then points=info[6] end
    end
    if numTalents and talentInfo then
     local total=0
     for talent=1,(self:Safe(numTalents,tree) or 0) do local _,_,_,_,rank=self:Safe(talentInfo,tree,talent);if type(rank)=='number' and rank>=0 and rank<=10 then total=total+rank end end
     if total>0 then points=total end
    end
    if type(points)=='number' and points>most and choices[tree] then most=points;index=tree end
   end
  end
 end
 self.gearProfile=choices[index];self.gearProfileSource=index and (self.db.gearSpec and 'manual' or 'talents') or nil
 if not self.gearProfile and classDefaults[class] then
  self.gearProfile=classDefaults[class];self.gearProfileSource='class'
 end
 self.gearProfileClass=class;self.gearProfileResolved=true;self.db.lastGearProfile={class=class,source=self.gearProfileSource,index=index,label=self.gearProfile and self.gearProfile[1]}
end
local function itemStat(stats,key)
 return tonumber(stats['ITEM_MOD_'..key..'_SHORT'] or stats['ITEM_MOD_'..key]) or 0
end

local function casterStats(stats)
 local damage=math.max(itemStat(stats,'SPELL_POWER'),itemStat(stats,'SPELL_DAMAGE_DONE'))
 local healing=math.max(itemStat(stats,'SPELL_POWER'),itemStat(stats,'HEALING_DONE'),itemStat(stats,'SPELL_HEALING_DONE'))
 return damage,healing
end

function A:SpecFits(item,id,cacheOnly,profile)
 if not (profile or self.db.specOnly) or item.classID~=2 and item.classID~=4 then return true end
 if not self.gearProfileResolved then self:RefreshGearProfile() end
 local p=profile or self.gearProfile;if not p then return true end
 -- Assassination/Subtlety melee techniques require daggers; ranged stat sticks stay available.
 if self.gearProfileClass=='ROGUE' and p[3] and item.classID==2 then
  local melee=({[0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[17]=true})[item.subclass]
  if melee and item.subclass~=15 then return false end
 end
 self.gearStatCache=self.gearStatCache or {};local stats=self.gearStatCache[id]
 if stats==nil and not cacheOnly and id and id>0 then stats=self:ComparisonStats('item:'..id);if type(stats)~='table' or not next(stats) then stats=false end;self.gearStatCache[id]=stats end
 if not stats then return true end
 local function stat(k) return itemStat(stats,k) end
 local agi,str,int=stat('AGILITY'),stat('STRENGTH'),stat('INTELLECT')
 local damage,healing=casterStats(stats)
 local caster=int+stat('SPIRIT')+math.max(damage,healing)
 if p.weights.ARMOR and (stat('ARMOR')>0 or stat('DEFENSE_SKILL_RATING')>0 or stat('DODGE_RATING')>0 or stat('BLOCK_RATING')>0) then return true end
 if p.weights.SPELL_DAMAGE and p[2]~='intellect' and damage>0 then return true end
 if p.weights.STRENGTH and p[2]=='agility' and str>0 then return true end
 if p[2]=='intellect' then return caster>0 or agi+str==0 end
 if p[2]=='agility' then return agi>0 or str+caster==0 end
 return str>0 or agi+caster==0
end
function A:ClassFits(item,id,force,cacheOnly,profile)
 if not force and not self.db.classOnly and not self.db.specOnly then return true end
 if item.classID==-1 then return false end
 if item.classID~=2 and item.classID~=4 then return true end
 local _,class,classID=UnitClass('player');local data=self.classData.classes[(class or ''):lower()]
 local restrictions=self.classData.restricted or {};local mask=restrictions[tostring(id)] or restrictions[id]
 if mask and classID and math.floor(mask/2^(classID-1))%2==0 then return false end
 local frill=item.slot=='Held In Off-hand' or item.slot=='Held In Off-Hand' or item.slot=='INVTYPE_HOLDABLE'
 if frill then
  if class=='ROGUE' or class=='WARRIOR' or class=='HUNTER' or class=='DEATHKNIGHT' then return false end
  local p=profile or self.db.specOnly and self.gearProfile
  if p and not p.weights.SPELL_DAMAGE and not p.weights.HEALING then return false end
 end
 if item.classID==4 and (item.subclass==0 or item.slot=='Back' or item.slot=='Cloak') then return self:SpecFits(item,id,cacheOnly,profile) end
 for _,g in ipairs(data and data.gear or {}) do if g[1]==item.classID and g[2]==item.subclass and g[3]<=UnitLevel('player') then return self:SpecFits(item,id,cacheOnly,profile) end end
 return false
end
-- Original transparent comparison heuristic, independent of GearQuest's implementation/data.
local equipSlots={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_BODY={4},INVTYPE_CHEST={5},INVTYPE_ROBE={5},INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16},INVTYPE_WEAPONMAINHAND={16},INVTYPE_WEAPONOFFHAND={17},INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},INVTYPE_2HWEAPON={16},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18},INVTYPE_RELIC={18}}
function A:ComparisonInfo(key,uncached)
 local cached=self.comparisonInfo and self.comparisonInfo[key]
 if cached then return cached end
 local fn=C_Item and C_Item.GetItemInfo or GetItemInfo;if not fn then return end
 local v={pcall(fn,key)};if not v[1] or not v[2] then return end
 local result={name=v[2],link=v[3] or key,level=v[6] or 0,loc=v[10],classID=v[13],subclass=v[14],quality=v[4]}
 if not uncached then
  self.comparisonInfo=self.comparisonInfo or {}
  self.comparisonInfo[key]=result
 end
 return result
end
-- Load only visible item metadata. No item-ID sweep or startup server scan.
function A:HydrateAtlasItem(iid)
 local item=self.items[iid];if not item then return false end
 local info=self:ComparisonInfo(iid)
 if not info then
  self.atlasRequested=self.atlasRequested or {};self.atlasRequestQueue=self.atlasRequestQueue or {}
  if not self.atlasRequested[iid] or (type(self.atlasRequested[iid])=='number' and (self:Safe(GetTime) or time())-self.atlasRequested[iid]>30) then self.atlasRequested[iid]=self:Safe(GetTime) or time();self.atlasRequestQueue[#self.atlasRequestQueue+1]=iid end
  if not self.atlasRequestPump and #self.atlasRequestQueue>0 then
   self.atlasRequestPump=true
   local function pump()
    for i=1,4 do local id=table.remove(self.atlasRequestQueue,1);if not id then break end;self:Safe(C_Item and C_Item.RequestLoadItemDataByID,id) end
    if #self.atlasRequestQueue>0 then C_Timer.After(.1,pump) else self.atlasRequestPump=nil end
   end
   C_Timer.After(.1,pump)
  end
  return false
 end
 local changed=false
 for field,value in pairs({classID=info.classID,subclass=info.subclass,level=info.level,quality=info.quality,slot=info.loc}) do
  if value~=nil and value~='' and item[field]~=value then item[field]=value;changed=true end
 end
 return changed
end

function A:ComparisonStats(link)
 self.comparisonStats=self.comparisonStats or {};if self.comparisonStats[link] then return self.comparisonStats[link] end
 local stats={};local seen={}
 for _,fn in pairs({C_Item and C_Item.GetItemStats,GetItemStats}) do
  if type(fn)=='function' and not seen[fn] then
   seen[fn]=true;local buffer={};local ok,result=pcall(fn,link)
   if not ok or type(result)~='table' then ok,result=pcall(fn,link,buffer) end
   if ok then
    for key,value in pairs(type(result)=='table' and result or buffer) do if type(value)=='number' and stats[key]==nil then stats[key]=value end end
   end
  end
 end
 if next(stats) then self.comparisonStats[link]=stats;return stats end
end
local statAliases={
 ARMOR={'RESISTANCE0_NAME','ARMOR'},
 MP5={'MANA_REGENERATION','POWER_REGEN0','MANA_REGEN','MANA_REGENERATION_INTERRUPTED'},
 MELEE_HIT={'HIT_MELEE_RATING','MELEE_HIT_RATING','HIT_RATING'},
 RANGED_HIT={'HIT_RANGED_RATING','RANGED_HIT_RATING','HIT_RATING'},
 SPELL_HIT={'HIT_SPELL_RATING','SPELL_HIT_RATING','HIT_RATING'},
 MELEE_CRIT={'CRIT_MELEE_RATING','MELEE_CRIT_RATING','CRIT_RATING'},
 RANGED_CRIT={'CRIT_RANGED_RATING','RANGED_CRIT_RATING','CRIT_RATING'},
 SPELL_CRIT={'CRIT_SPELL_RATING','SPELL_CRIT_RATING','CRIT_RATING'},
 RANGED_AP={'RANGED_ATTACK_POWER','ATTACK_POWER'},
 DEFENSE={'DEFENSE_SKILL_RATING','DEFENSE_RATING'},
 DODGE={'DODGE_RATING'},PARRY={'PARRY_RATING'},BLOCK={'BLOCK_RATING'},
 HASTE={'HASTE_MELEE_RATING','HASTE_RATING'}
}

local function weightedStat(stats,key)
 local aliases=statAliases[key]
 if not aliases then return itemStat(stats,key) end
 local value=0
 for _,alias in ipairs(aliases) do value=math.max(value,itemStat(stats,alias),tonumber(stats[alias]) or 0) end
 return value
end

function A:ActiveComparisonProfile()
 if self.db.specOnly then
  if not self.gearProfileResolved then self:RefreshGearProfile() end
  return self.gearProfile
 end
 local _,class=UnitClass('player')
 return classDefaults[class]
end

local function gearDpsWeight(profile,itemClass,slot,level)
 if itemClass~=2 then return 0 end
 if profile.weapon=='wand' and slot==18 then return 2.5-1.85*math.max(0,math.min(35,level-25))/35 end
 if profile.weapon=='ranged' and slot==18 then return 3.5 end
 if slot==16 or slot==17 then
  if profile.weapon=='melee' then return 3 end
  if profile.weapon=='tank' then return .6 end
 end
 return 0
end

-- Read only explicitly displayed, passive mana regeneration and weapon DPS missing from the API.
function A:GearComparisonStats(link,profile,itemClass,slot,level)
 local stats=self:ComparisonStats(link)
 if not profile then return stats end
 local needDps=gearDpsWeight(profile,itemClass,slot,level)>0 and (not stats or itemStat(stats,'DAMAGE_PER_SECOND')==0)
 local needMp5=profile.weights.MP5 and (not stats or weightedStat(stats,'MP5')==0)
 if not needDps and not needMp5 then return stats end
 self.gearTooltipStats=self.gearTooltipStats or {}
 local fallback=self.gearTooltipStats[link]
 if not fallback then
  local payload=type(link)=='number' and ('item:'..link) or link:match('|H(item:[^|]+)|h') or link
  local info=self:Safe(C_TooltipInfo and C_TooltipInfo.GetHyperlink,payload)
  if type(info)~='table' or type(info.lines)~='table' then return stats end
  fallback={}
  for _,line in ipairs(info.lines) do
   local text=line.leftText
   if not (issecretvalue and issecretvalue(text)) and type(text)=='string' then
    text=self:SearchText(text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''))
    local dps=text:match('^%(([%d.,]+) damage per second%)$') or text:match('^%(([%d.,]+) ед%. урона в секунду%)$')
    if dps then fallback.dps=tonumber((dps:gsub(',','.'))) end
    local mp5=text:match('^equip: restores (%d+) mana per 5 sec') or text:match('^equip: restores (%d+) mana every 5 sec')
     or text:match('^если на персонаже: восстанавливает (%d+) ед%. маны раз в 5 сек')
    if mp5 then fallback.mp5=tonumber(mp5) end
   end
  end
  self.gearTooltipStats[link]=fallback
 end
 if not (needDps and fallback.dps or needMp5 and fallback.mp5) then return stats end
 local complete={}
 for key,value in pairs(stats or {}) do complete[key]=value end
 if needDps then complete.ITEM_MOD_DAMAGE_PER_SECOND_SHORT=fallback.dps end
 if needMp5 then complete.ITEM_MOD_MANA_REGENERATION_SHORT=fallback.mp5 end
 return complete
end

function A:ScoreGear(stats,profile,itemClass,slot,level)
 if not stats or not profile then return end
 local dpsWeight=gearDpsWeight(profile,itemClass,slot,level)
 local dps=itemStat(stats,'DAMAGE_PER_SECOND')
 if dpsWeight>0 and dps<=0 then return end
 local damage,healing=casterStats(stats)
 if profile.school=='NATURE_ARCANE' then
  damage=damage+(itemStat(stats,'NATURE_DAMAGE_DONE')+itemStat(stats,'ARCANE_DAMAGE_DONE'))*.5
 elseif profile.school then
  damage=damage+itemStat(stats,profile.school..'_DAMAGE_DONE')
 end
 local total=dps*dpsWeight
 for key,weight in pairs(profile.weights) do
  local value=key=='SPELL_DAMAGE' and damage or key=='HEALING' and healing or weightedStat(stats,key)
  total=total+value*weight
 end
 return total
end

local function formatGearPercent(value)
 if math.abs(value)<.05 then return '≈ 0%' end
 return math.abs(value)<10 and string.format('%+.1f%%',value) or string.format('%+.0f%%',value)
end

function A:CompareItem(iid,profile)
 local item=self.items[iid];if not item or item.classID~=2 and item.classID~=4 then return end
 local info=self:ComparisonInfo(iid);if not info then return {state='unknown',text=self.atlasLoadFailures and self.atlasLoadFailures[iid] and 'Клиент не вернул описание предмета' or 'Характеристики ещё загружаются'} end
 if not self:ClassFits(item,iid,true,nil,profile) then return {state='wrong',text='Не подходит выбранному классу / спеку'} end
 local slots=equipSlots[info.loc];if not slots then return {state='unknown',text='Слот пока неизвестен'} end
 local location=slots[1]
 profile=profile or self:ActiveComparisonProfile()
 local level=UnitLevel('player')
 local candidateScore=self:ScoreGear(self:GearComparisonStats(info.link,profile,item.classID,location,level),profile,item.classID,location,level)
 if info.level>UnitLevel('player') then return {state='later',text='Позже: с '..info.level..' ур.',score=candidateScore} end
 local requirement=self:UnmetAtlasRequirement(iid)
 if requirement then return {state='restricted',text=requirement,score=candidateScore} end
 local equipment={};local empty,variant
 local itemPayload=type(info.link)=='string' and info.link:match('item:[%d:%-]+')
 for _,slot in ipairs(slots) do
  local link=self:Safe(GetInventoryItemLink,'player',slot)
  local equippedID=self:Safe(GetInventoryItemID,'player',slot) or type(link)=='string' and tonumber(link:match('item:(%d+)'))
  if link and (link==info.link or itemPayload and type(link)=='string' and link:match('item:[%d:%-]+')==itemPayload) then return {state='same',text='Уже надето',score=candidateScore,slot=slot} end
  if equippedID then
   self.wornComparisonItems=self.wornComparisonItems or {}
   self.wornComparisonItems[equippedID]=true
  end
  if equippedID==iid then variant=slot end
  if link then equipment[slot]=link elseif not equippedID then empty=empty or slot end
 end
 if variant then return {state='unknown',text='Уже надет вариант этого предмета',score=candidateScore,slot=variant} end
 -- Ranged gear has an independent slot. Only changes that affect the main/off hand need a set comparison.
 if location==16 or location==17 then
  local main=self:Safe(GetInventoryItemLink,'player',16);local worn=main and self:ComparisonInfo(main)
  if (location==17 and main and (not worn or worn.loc=='INVTYPE_2HWEAPON'))
   or (location==16 and self:Safe(GetInventoryItemLink,'player',17) and (info.loc=='INVTYPE_WEAPON' or info.loc=='INVTYPE_2HWEAPON')) then
   return {state='unknown',text='Нужно сравнение комплекта оружия',score=candidateScore}
  end
 end
 if empty then return {state='empty',text='Пустой слот',slot=empty,score=candidateScore} end
 if not profile then return {state='unknown',text='Выбери спек'} end
 local weakest,chosen
 for _,slot in ipairs(slots) do
  local link=equipment[slot]
  if not link then return {state='unknown',text='Нужна ссылка надетого предмета',score=candidateScore} end
  if slot==17 then
   local equipped=self:ComparisonInfo(link)
   if equipped and equipped.classID~=nil and (equipped.classID==2)~=(item.classID==2) then
    return {state='unknown',text='Нужно сравнение комплекта оружия',score=candidateScore}
   end
  end
  local power=self:ScoreGear(self:GearComparisonStats(link,profile,item.classID,location,level),profile,item.classID,location,level)
  if power==nil or candidateScore==nil then return {state='unknown',text='Недостаточно характеристик',score=candidateScore} end
  if weakest==nil or power<weakest then weakest=power;chosen=slot end
 end
 local delta=candidateScore-weakest
 local percent=weakest>0 and 100*delta/weakest or nil
 local difference=percent or delta
 local epsilon=percent and .05 or .0001
 local state=difference>=epsilon and 'better' or difference<=-epsilon and 'worse' or 'same'
 local text=percent and formatGearPercent(percent) or state=='better' and 'Лучше' or state=='worse' and 'Хуже' or 'Примерно равно'
 return {state=state,delta=delta,percent=percent,score=candidateScore,slot=chosen,text=text}
end

local comparisonColors={better={.3,.95,.55},worse={1,.42,.36},empty={.3,.95,.55}}
function A:ComparisonColor(result)
 return unpack(comparisonColors[result and result.state] or {.78,.8,.74})
end

function A:AddGearRatingsTooltip(t,iid)
 local _,class=UnitClass('player')
 self:AddTooltipLine(t,'Оценка слота к надетому',1,.84,.52)
 for _,profile in ipairs(self.gearSpecs[class] or {}) do
  local result=self:CompareItem(iid,profile)
  if result then self:AddTooltipLine(t,profile[1]..'   '..result.text,self:ComparisonColor(result)) end
 end
end

function A:AddComparisonTooltip(t,iid)
 local result=self:CompareItem(iid);if not result then return end
 self:AddTooltipLine(t,'Следопыт · '..result.text..(result.percent and ' к оценке слота' or ''),self:ComparisonColor(result))
end
function A:Matches(entry,skills,includeRareFinds,ignoreClass)
 if entry[4] and not self.db.sharedLoot then return false end
 if entry[2]==4 and not self.db.observed then return false end
 local item=self.items[entry[1]];if not item then return false end
 if (entry[2]==5 or entry[2]==6) and self.db.vendorRelevant and not self:VendorRelevant(item,entry[1],skills) then return false end
 if (entry[2]==5 or entry[2]==6) and self.db.vendorLevel and (item.level or 0)>UnitLevel('player') then return false end
 if (entry[2]==5 or entry[2]==6) and item.classID~=1 and item.classID~=2 and item.classID~=4 and item.classID~=7 and item.classID~=9 then return false end
 if not self.db.qualities[item.quality] then return false end
 if entry[2]==2 and not self.db.skinning or entry[2]==3 and not self.db.pickpocket then return false end
 local rareFind=includeRareFinds and (entry[2]==8 or entry[2]==14) and self:SpecialRank(entry[1])>0
 if not rareFind and not ignoreClass and not self:ClassFits(item,entry[1]) then return false end
 local prof=self.db.prof
 if prof~=0 then
  local found=false
  for _,id in ipairs(item.prof or {}) do if prof==-2 or prof==-1 and skills[id] or prof==id then found=true end end
  if not found then return false end
 end
 return true
end
function A:IsSpecialMapDrop(entry)
 return not entry[4] and self:SpecialRank(entry[1])>0
end
function A:Loot(id,skills,forceSpecial,includeRareFinds,rareOnly,ignoreClass)
 local mob=self.mobs[id];local list=mob and (mob.vendor and mob.stock or mob.loot) or {}
 local unique={};local out={}
 rareOnly=rareOnly and mob and not mob.vendor
 for _,entry in ipairs(list or {}) do if rareOnly and self:SpecialRank(entry[1])>0 or not rareOnly and self:Matches(entry,skills or self.skills or {},includeRareFinds,ignoreClass) then
  local previous=unique[entry[1]]
  local priority=entry[4] and 0 or entry[2]==8 and 5 or entry[2]==6 and 4 or entry[2]==4 and 3 or entry[2]==14 and 2 or 1
  if not previous then
   local copy={};for i=1,8 do copy[i]=entry[i] end;copy.alternatives={entry};copy.priority=priority;unique[entry[1]]=copy
  else
   local alternatives=previous.alternatives;alternatives[#alternatives+1]=entry
   if priority>previous.priority then local copy={};for i=1,8 do copy[i]=entry[i] end;copy.alternatives=alternatives;copy.priority=priority;unique[entry[1]]=copy end
  end
 end end
 local direct=0
 for _,entry in pairs(unique) do
  out[#out+1]=entry
  if not entry[4] then direct=direct+1 end
 end
 table.sort(out,function(a,b)
  if (not a[4])~=(not b[4]) then return not a[4] end
  local aq,bq=self.items[a[1]].quality,self.items[b[1]].quality
  if rareOnly then
   if aq~=bq then return aq>bq end
   local ae,be=self:SourceEvidenceTier(a),self:SourceEvidenceTier(b)
   if ae~=be then return ae>be end
   local knownA,knownB=a[3]>=0,b[3]>=0
   if knownA~=knownB then return knownA end
   if a[3]~=b[3] then return a[3]<b[3] end
   return a[1]<b[1]
  end
  if (forceSpecial or self.db.specialFirst) and not (mob and mob.vendor) then local ar,br=self:SpecialRank(a[1]),self:SpecialRank(b[1]);if ar~=br then return ar>br end end
  if (mob and mob.vendor or self.db.sort=='quality') and aq~=bq then return aq>bq end
  if a[3]~=b[3] then return a[3]>b[3] end
  if aq~=bq then return aq>bq end
  return a[1]<b[1]
 end)
 return out,direct
end
function A:Chance(entry)
 if entry[2]==10 then return 'Награда за задание' end
 if entry[2]==11 then return 'Изготовление' end
 if entry[2]==13 then return 'Внутри другого предмета' end
 if entry[2]==9 or entry[2]==12 then return entry[3]<0 and 'Шанс неизвестен · Classic' or string.format('%.3g%% · Classic',entry[3]) end
 if entry[2]==14 then return 'Сообщение игрока · шанс неизвестен' end
 if entry[2]==8 then return 'Лично найдено · шанс неизвестен' end
 if entry[2]==7 then return entry[4] and 'Общий или условный дроп · Forever DB' or 'шанс неизвестен · Forever DB' end
 if entry[4] then return 'Общий или условный дроп · шанс неизвестен · Classic' end
 if entry[2]==5 then return 'Покупка · справочник' end
 if entry[2]==6 then
  if entry[8] then return 'Особая стоимость · у продавца' end
  if type(entry[5])~='number' or entry[5]<0 then return 'Цена уточняется' end
  local p=entry[5];return string.format('%dз %dс %dм',math.floor(p/10000),math.floor(p/100)%100,p%100)..(entry[6] and entry[6]>1 and (' / '..entry[6]..' шт.') or '')
 end
 if entry[2]==4 then
  local historical=entry[8] and self.foreverAsOf and entry[8]~=self.foreverAsOf:sub(1,10)
  return string.format('%.3g%% · Forever',entry[3])..(historical and (' · архив '..entry[8]) or '')
 end
 if entry[3]<0 then return 'шанс неизвестен' end
 return string.format('%.4g%% · Classic',entry[3])
end
function A:HasSpecialMapLoot(id)
 local mob=self.mobs[id]
 if not mob or mob.vendor then return false end
 for _,entry in ipairs(mob.loot or {}) do
  if self:IsSpecialMapDrop(entry) and self:Matches(entry,self.skills or {},true) then return true end
 end
 return false
end

function A:BuildMap(mapID)
 self.skills=self:Professions();local cells={};local counted={};local total=0
 local function visible(id)
  if self.focus then return self.focus.ids[id]==true end
  local mob=self.mobs[id];local faction=self:Safe(UnitFactionGroup,'player');local friendly=mob.friendly or ''
  if not mob.vendor and not mob.huntable and (mob.service or mob.kind=='Humanoid') and (friendly=='AH' or faction=='Alliance' and friendly:find('A',1,true) or faction=='Horde' and friendly:find('H',1,true)) then return false end
  if self.db.specialMobsOnly then return self.db.mapLayer~='vendors' and self:HasSpecialMapLoot(id) end
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
 self.wornComparisonItems=nil;self.accessibleAtlasSources=nil;if self.atlas then self.atlas.results=nil;self.atlas.sourceCache=nil;self.atlas.recommendScan=nil end
 self:ClearFocus(false,true);self:Update()
end
function A:Init()
 MobAtlasDB=type(MobAtlasDB)=='table' and MobAtlasDB or {};self.db=MobAtlasDB
 local defaults={specialMobsOnly=false,specOnly=false,rareEnabled=true,rareAlerts=true,rareSound=true,rareMap=true,rareMinimap=true,rareMaxRange=true,habitatGlow=true,dungeonPins=true,language='auto',enabled=true,quality='all',classOnly=false,prof=0,skinning=true,pickpocket=false,visibleItems=5,sort='chance',unitLoot=true,observed=true,minimapAngle=225,sharedLoot=false,vendorLevel=true,vendorRelevant=true,mapLayer='all',specialFirst=true}
 for k,v in pairs(defaults) do if self.db[k]==nil then self.db[k]=v end end
 if self.db.language~='auto' and self.db.language~='ruRU' and self.db.language~='enUS' then self.db.language='auto' end
 if not ({all=true,green=true,blue=true,both=true})[self.db.quality] then self.db.quality='all' end
 if type(self.db.qualities)~='table' then
  local old=self.db.quality;self.db.qualities={}
  for q=-1,7 do self.db.qualities[q]=old=='all' or old=='green' and q==2 or old=='blue' and q==3 or old=='both' and (q==2 or q==3) end
 end
 if not self.db.junkFilterInitialized then self.db.qualities[0]=false;self.db.junkFilterInitialized=true end
 if self.db.prof~=0 and self.db.prof~=-1 and self.db.prof~=-2 and not self.profNames[self.db.prof] then self.db.prof=0 end
 if not ({[3]=true,[5]=true,[7]=true})[self.db.visibleItems] then self.db.visibleItems=5 end
 if not ({all=true,mobs=true,vendors=true,none=true})[self.db.mapLayer] then self.db.mapLayer='all' end
 if self.db.sort~='quality' then self.db.sort='chance' end
 self:MergeForever();self:ApplyCatalog();self:ApplyExpansion();if self.MergeRareCatalog then self:MergeRareCatalog() end;self:RestoreMerchants();self:RestoreLoot();self:ApplyForeverItems()
 self.vendorItems=nil;self.extraItems=nil;self.extraMobs=nil;self.foreverItems=nil;self.foreverProf=nil;self.foreverNames=nil;self.commonWorldItems=nil
 self.zoneIndex={}
 for id,mob in pairs(self.mobs) do local seen={};for _,p in ipairs(mob.points) do if not seen[p[1]] then seen[p[1]]=true;self.zoneIndex[p[1]]=self.zoneIndex[p[1]] or {};table.insert(self.zoneIndex[p[1]],id) end end end
 for _,ids in pairs(self.zoneIndex) do table.sort(ids) end
 self:BuildEntranceIndex();self:HookItemSearch();self:CreateSettings();self:CreateMinimapButton();self:HookUnitLoot();self:RefreshGearProfile();self:RestoreQuestPin();if self.StartNpcObservation then self:StartNpcObservation() end;if self.StartRareTracking then self:StartRareTracking() end;self.dirty=true
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
A.events:SetScript('OnEvent',function(_,event,arg,success)
 if (event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT') and A.db then
  if issecretvalue and issecretvalue(arg) or type(arg)~='number' then return end
  local hadGearStats=A.gearStatCache and A.gearStatCache[arg]~=nil
  local scan=A.atlas and A.atlas.recommendScan
  local equippedChanged=A.wornComparisonItems and A.wornComparisonItems[arg]
  local relevant=equippedChanged or hadGearStats or A.atlasRequested and A.atlasRequested[arg] or A.pendingLootItems and A.pendingLootItems[arg]
   or A.comparisonInfo and A.comparisonInfo[arg] or scan and (scan.pending[arg] or scan.scores[arg])
   or A.atlas and A.atlas.selectedItem==arg
  if not relevant then return end
  A.atlasLoadFailures=A.atlasLoadFailures or {};A.atlasLoadFailures[arg]=success==false or nil
  A.atlasReadyItems=A.atlasReadyItems or {};A.atlasReadyItems[arg]=success~=false or nil
  if A.gearStatCache then A.gearStatCache[arg]=nil end
  if A.atlasRequirementCache then A.atlasRequirementCache[arg]=nil end
  for _,cache in ipairs({A.comparisonInfo or {},A.comparisonStats or {},A.gearTooltipStats or {}}) do
   for key in pairs(cache) do if key==arg or type(key)=='string' and tonumber(key:match('item:(%d+)'))==arg then cache[key]=nil end end
  end
  A:RefreshObservedLootItem(arg)
  if equippedChanged and A.atlas then A.atlas.recommendScan=nil else A:RefreshRecommendationItem(arg) end
  if hadGearStats and A.db.specOnly then A.dirty=true;if A.atlas and A.atlas.category~='upgrades' then A.atlas.results=nil end end
  if A.atlas and A.atlas:IsShown() and not A.comparisonRefreshPending then
   A.comparisonRefreshPending=true
   C_Timer.After(.1,function()
    A.comparisonRefreshPending=nil
    if A.atlas and A.atlas:IsShown() then A:RefreshAtlas() end
   end)
  end
 elseif event=='UPDATE_FACTION' and A.db then
  A.atlasRequirementCache=nil
  if A.atlas then A.atlas.recommendScan=nil;if A.atlas:IsShown() then A:RefreshAtlas() end end
 elseif (event=='PLAYER_TALENT_UPDATE' or event=='ACTIVE_TALENT_GROUP_CHANGED') and A.db then
  A:RefreshGearProfile()
  if A.db.specOnly then
   A:RefreshSettings();A:Invalidate()
   if A.atlas and A.atlas:IsShown() then A:RefreshAtlas() end
  end
 elseif event=='PLAYER_LOGIN' then A:Init()
 elseif A.db and (event=='QUEST_LOG_UPDATE' or event=='QUEST_ACCEPTED' or event=='QUEST_TURNED_IN') then A:QuestLogChanged(event)
 elseif A.db and (event=='LOOT_OPENED' or event=='LOOT_READY' or event=='LOOT_SLOT_CHANGED') then A:CaptureLoot()
 elseif A.db and (event=='MERCHANT_SHOW' or event=='MERCHANT_UPDATE') then A:CaptureMerchant()
 elseif A.db then
  A:Invalidate()
  if A.atlas and A.atlas:IsShown() then A:RefreshAtlas() end
 end
end)
for _,event in ipairs({'PLAYER_EQUIPMENT_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_LOGIN','SKILL_LINES_CHANGED','PLAYER_LEVEL_UP','PLAYER_ENTERING_WORLD','MERCHANT_SHOW','MERCHANT_UPDATE','LOOT_OPENED','LOOT_READY','LOOT_SLOT_CHANGED','GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','QUEST_LOG_UPDATE','UPDATE_FACTION','QUEST_TURNED_IN','QUEST_ACCEPTED'}) do A.events:RegisterEvent(event) end

-- Observations stay separate from Classic methods: this feed does not identify the method.
function A:MergeForever()
 for _,r in ipairs(self.foreverRates or {}) do
  local id,itemID=r[1],r[2]
  if not self.items[itemID] then self.items[itemID]={name='Предмет #'..itemID,quality=-1,classID=-1,subclass=-1,prof={}} end
  if not self.mobs[id] then self.mobs[id]={name=(self.foreverNames or {})[id] or ('Существо #'..id),min=0,max=0,points={},loot={}} end
  local mob=self.mobs[id];local exists=false
  for _,e in ipairs(mob.loot) do if e[1]==itemID and e[2]==4 then exists=true end end
  if not exists then table.insert(mob.loot,{itemID,4,r[3],false,r[4],r[5],r[6],r[7]}) end
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
function A:NpcIDFromGUID(guid)
 if issecretvalue and issecretvalue(guid) or type(guid)~='string' then return end
 local kind,id=guid:match('^(%a+)%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)%-')
 if kind=='Creature' or kind=='Vehicle' then return tonumber(id) end
end

function A:NpcID(unit)
 return self:NpcIDFromGUID(self:Safe(UnitGUID,unit))
end

function A:CurrentForeverDungeon()
 local _,kind,_,_,_,_,_,instanceID=self:Safe(GetInstanceInfo)
 if issecretvalue and (issecretvalue(kind) or issecretvalue(instanceID)) or kind~='party' then return end
 return (self.foreverInstanceMaps or {})[instanceID]
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
 local referenceEntries,sharedEntries={},{}
 local classicPools={{},{},{}}
 for id,c in pairs(self.catalog) do
  local mob=self.mobs[id]
  if mob or c.vendor or c.referenceLoot or c.reportedLoot then
   if not mob then mob={loot={}};self.mobs[id]=mob end
   for _,k in ipairs({'name','min','max','points','instances','kind','family','vendor','stock','friendly','huntable','service','reportSource'}) do mob[k]=c[k] end
   local existing={};local conditional={};local direct={}
   for i,e in ipairs(mob.loot) do
    local pool=classicPools[e[2]]
    if pool and e[4] and e[3]<0 then
     local pooled=pool[e[1]]
     if pooled then mob.loot[i]=pooled else pool[e[1]]=e end
    end
    if e[2]==7 then existing[e[1]]=true end
    if e[2]==1 then if e[4] then conditional[e[1]]=true else direct[e[1]]=true end end
   end
   local reports={};for _,e in ipairs(mob.loot) do if e[2]==14 then reports[e[1]]=true end end
   for _,iid in ipairs(c.reportedLoot or {}) do if self.items[iid] and not reports[iid] then mob.loot[#mob.loot+1]={iid,14,-1,false} end end
   for _,iid in ipairs(c.referenceLoot or {}) do if not existing[iid] then
    -- Catalog entries have no NPC-specific rate or counters and are read-only.
    local shared=((self.commonWorldItems or {})[iid] or conditional[iid] and not direct[iid])==true
    local pool=shared and sharedEntries or referenceEntries
    local entry=pool[iid]
    if not entry then entry={iid,7,-1,shared};pool[iid]=entry end
    mob.loot[#mob.loot+1]=entry
   end end
  end
  c.referenceLoot=nil;c.reportedLoot=nil;c.stock=nil
 end
end
function A:RestoreMerchants()
 self.db.merchants=type(self.db.merchants)=='table' and self.db.merchants or {}
 for id,m in pairs(self.db.merchants) do
  for iid,item in pairs(m.items or {}) do
   local catalog=self.items[iid]
   if catalog then
    for key,value in pairs(item) do catalog[key]=value end
   else self.items[iid]=item end
  end
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
   local item={name=info.name or ('Предмет #'..iid),quality=-1,classID=-1,subclass=-1,prof={}}
   for key,value in pairs(self.items[iid] or {}) do item[key]=value end
   local client=self:ComparisonInfo(iid,true)
   if client then
    item.name=client.name;item.quality=client.quality or item.quality;item.level=client.level
    item.classID=client.classID or item.classID;item.subclass=client.subclass or item.subclass
    item.slot=client.loc and client.loc~='' and client.loc or item.slot
    item.observed=true
   end
   m.items[iid]=item
   m.stock[#m.stock+1]={iid,6,-1,false,info.price or -1,info.stackCount or info.quantity or 1,info.numAvailable,info.hasExtendedCost}
  else incomplete=true end
 end
 -- Never replace a complete saved inventory with an incompletely cached merchant window.
 if incomplete or #m.stock==0 then return end
 local oldIDs={};local npc=self.mobs[id] or {points={},min=0,max=0,loot={}}
 for _,list in ipairs({npc.loot or {},npc.stock or {}}) do for _,e in ipairs(list) do oldIDs[e[1]]=true end end
 for iid,item in pairs(m.items) do self.items[iid]=item end
 self.db.merchants[id]=m;npc.vendor=true;npc.name=m.name;npc.stock=m.stock;self.mobs[id]=npc
 self:RefreshNpcIndex(id,oldIDs);self.dirty=true
 if self.atlas then
  self.atlas.results=nil;self.atlas.recommendScan=nil;self.atlas.sourceCache=nil
  if self.atlas:IsShown() then self:RefreshAtlas() end
 end
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
