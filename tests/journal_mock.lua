local methods=getmetatable(UIParent).__index
for _,m in ipairs({'SetAllPoints','SetFont','SetJustifyV','SetColorTexture','SetTexCoord','SetBackdropColor','SetBackdropBorderColor','SetSpacing','SetHyperlink','SetSpellByID'}) do methods[m]=function() end end
function methods:GetFont() return 'Fonts/FRIZQT__.TTF',12,'' end
function methods:GetPoint() return 'CENTER',UIParent,'CENTER',0,0 end
function methods:GetNormalTexture() return self:CreateTexture() end
function methods:GetHeight() return self.height end
GameFontNormal=CreateFrame('Frame')
tinsert=table.insert
MOCK.playerLevel=11;MOCK.class='ROGUE';MOCK.faction='Alliance';MOCK.equipped={};MOCK.items={};MOCK.done={};MOCK.known={};MOCK.bags={};MOCK.skills={};MOCK.timers={}
function UnitLevel() return MOCK.playerLevel end
function UnitClass() return MOCK.class,MOCK.class,4 end
function UnitFactionGroup() return MOCK.faction end
function UnitName() return 'Tester' end
function GetRealmName() return 'Test Realm' end
function GetInventoryItemID(_,slot) return MOCK.equipped[slot] end
function GetNumSkillLines() return #MOCK.skills end
function GetSkillLineInfo(i) return MOCK.skills[i],false,false,50 end
function IsPlayerSpell(id) return MOCK.known[id] end
function IsSpellKnown(id) return MOCK.known[id] end
C_Timer={After=function(_,fn) MOCK.timers[#MOCK.timers+1]=fn end,NewTicker=function() end}
C_QuestLog={IsQuestFlaggedCompleted=function(id) return MOCK.done[id]==true end}
C_Item={
 GetItemInfo=function(id)
  if type(id)=='string' then id=tonumber(id:match('item:(%d+)')) end
  local d=MOCK.items[id];if not d then return end
  return d.name or ('Item '..id),'item:'..id,2,d.ilvl or 20,d.level or 1,'Armor','Leather',1,d.loc or 'INVTYPE_CHEST',134400,1,d.class or 4,d.subclass or 2
 end,
 GetItemStats=function(link) local id=tonumber(link:match('item:(%d+)'));return MOCK.items[id].stats or {} end,
 GetItemCount=function(id) return MOCK.bags[id] or 0 end,
 RequestLoadItemDataByID=function(id) MOCK.requested=id end,
}
C_MountJournal={GetMountIDs=function() return {1,2,3} end,GetMountInfoByID=function(id) return 'Mount '..id,100+id,134400,false,false,1,false,id==3,0,false,id==2 end,GetMountInfoExtraByID=function() return 1,'Description','Vendor' end}

function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function GetLocale() return 'ruRU' end
