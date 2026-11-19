"""Combine separately attributed catalogs, and build dungeon quest preparation data.
Offline builder. Inputs are fetched by refresh_mobatlas_extra.py or kept in source archive.
"""
import runpy,json,re,hashlib
from pathlib import Path
R=Path(__file__).resolve().parent
G=runpy.run_path(str(R/'build_mobatlas_catalog.py'))
L=G['L'];lua=G['lua'];npcs=G['npcs'];zones=G['zones'];allowed=G['allowed'];area_instance=G['area_instance'];instances=G['instances'];Q=G['Q'];cache=R/'vendor/extra'
quests=G['table_field'](Q/'data/Forever/foreverQuestDB.lua','questData')
objects=G['table_field'](Q/'data/Forever/foreverObjectDB.lua','objectData')
ruquests={}
for rel in ['l10n/Forever/lookupQuests/ruRU.lua','l10n/Forever/traces/lookupQuests/ruRU.lua']:
 p=Q/rel
 if p.exists():
  m=re.search(r'loadstring\(\[\[(.*?)\]\]',p.read_text(),re.S)
  if m:
   for id,name in L.execute(m[1]).items():ruquests.setdefault(id,name if isinstance(name,str) else name[1])
# Only the declarative quest trace fields consumed by this feature are applied.
L.globals().modules.QuestieDB.questKeys=L.eval('setmetatable({},{__index=function(_,k)return k end})')
p=Q/'src/corrections/Forever/traces/foreverQuestTraces.lua';L.execute(p.read_text());module=L.globals().modules.ForeverQuestTraces
fields={'name':1,'requiredLevel':4,'questLevel':5,'requiredRaces':6,'requiredClasses':7,'zoneOrSort':17,'preQuestGroup':12,'preQuestSingle':13,'requiredMaxLevel':32}
for id,c in module.Load(module).items():
 row=quests[id]
 if row is None:row=L.table();quests[id]=row
 for k,idx in fields.items():
  if c[k] is not None:row[idx]=c[k]
 for k,idx in [('startedBy_add',2),('finishedBy_add',3)]:
  if c[k]:
   if row[idx] is None:row[idx]=L.table()
   for kind,ids in c[k].items():
    current=set(row[idx][kind].values()) if row[idx][kind] else set();current.update(ids.values());row[idx][kind]=L.table_from(sorted(current))
def values(t):return list(t.values()) if t else []
def points(spawns):
 out=set()
 for area,ps in spawns.items() if spawns else []:
  zone=zones[area]
  if area in area_instance or zone not in allowed:continue
  for p in ps.values():
   x,y=p[1],p[2]
   if isinstance(x,(int,float)) and isinstance(y,(int,float)) and 0<=x<=100 and 0<=y<=100:out.add((zone,x,y))
 return [list(x) for x in sorted(out)]
def giver(kind,id):
 row=(npcs if kind=='npc' else objects)[id]
 return {'id':id,'kind':kind,'name':row[1] if row and row[1] else f'#{id}','points':points(row[7 if kind=='npc' else 4]) if row else []}
# Broader item catalog: client metadata wins over estimated Classic values; client API wins at runtime.
classes={'Consumable':0,'Container':1,'Weapon':2,'Armor':4,'Reagent':5,'Projectile':6,'Trade Goods':7,'Recipe':9,'Quiver':11,'Quest':12,'Key':13,'Miscellaneous':15,'WoW Token':18}
sub={2:{'One-Handed Axe':0,'Two-Handed Axe':1,'Bow':2,'Gun':3,'One-Handed Mace':4,'Two-Handed Mace':5,'Polearm':6,'One-Handed Sword':7,'Two-Handed Sword':8,'Staff':10,'Fist Weapon':13,'Dagger':15,'Thrown':16,'Crossbow':18,'Wand':19,'Fishing Pole':20},4:{'Miscellaneous':0,'Cloth':1,'Leather':2,'Mail':3,'Plate':4,'Shield':6,'Libram':7,'Idol':8,'Totem':9},1:{'Bag':0,'Soul Bag':1,'Herb Bag':2,'Enchanting Bag':3,'Engineering Bag':4,'Mining Bag':6,'Leatherworking Bag':7},15:{'Junk':0,'Reagent':1,'Pet':2,'Holiday':3,'Other':4,'Mount':5}}
kbitems=json.loads((cache/'kb-items.json').read_text());sources=json.loads((cache/'kb-item_sources.json').read_text());meta=json.loads((cache/'kb-meta.json').read_text());itemmeta={};rejected=0
for i in kbitems:
 # Hidden/developer-only items without an obtainable source must not become recommendations.
 if i.get('junk') or i.get('hidden'):rejected+=1;continue
 cls=classes.get(i.get('item_class'),-1);client=G['client'].get(i['id'])
 record={'name':i['name'],'quality':i.get('quality',-1),'classID':cls,'subclass':sub.get(cls,{}).get(i.get('subclass'),-1),'level':i.get('required_level'),'slot':i.get('slot',''),'prof':[], 'estimated':i.get('estimated',0)==1,'metadataSource':'kb','itemLevel':i.get('item_level',0)}
 if client:record['classID']=client[1];record['subclass']=client[2]
 itemmeta[i['id']]=record
ahcount=0
quality={'POOR':0,'COMMON':1,'UNCOMMON':2,'RARE':3,'EPIC':4,'LEGENDARY':5,'ARTIFACT':6,'HEIRLOOM':7}
for path in sorted(cache.glob('ahledger-*.json')):
 if path.name=='ahledger-health.json':continue
 clsname=path.stem.removeprefix('ahledger-');cls={'armor':4,'weapon':2,'consumable':0,'container':1,'recipe':9,'miscellaneous':15,'quest':12,'key':13,'reagent':5,'projectile':6,'quiver':11,'catalog':7}.get(clsname)
 if cls is None:continue
 data=json.loads(path.read_text())
 for row in data.get('rows',[]):
  if len(row)!=8 or not isinstance(row[0],int):continue
  iid,name,q,subname,ilvl,level,icon,slot=row
  record=itemmeta.get(iid)
  if not record:record={'name':name,'classID':cls,'subclass':sub.get(cls,{}).get(subname,-1),'slot':slot or '', 'prof':[]};itemmeta[iid]=record
  # AHledger catalog is game-file metadata, not evidence of a drop.
  record.update(name=name,quality=quality.get(q,-1),level=level,itemLevel=ilvl,metadataSource='ahledger',estimated=False);ahcount+=1
extra_mobs={};other={};links=0;seen=set()
for s in sources:
 iid=s['item_id'];kind=s['kind'];sid=s.get('source_id',0)
 if iid not in itemmeta or sid<=0:continue
 key=(iid,kind,sid)
 if key in seen:continue
 seen.add(key)
 if kind in ('drop','vendor'):
  rec=extra_mobs.setdefault(sid,{'name':s.get('name',f'NPC #{sid}'),'min':s.get('min_level',0),'max':s.get('max_level',0),'loot':[],'stock':[]})
  if kind=='drop':
   chance=s.get('chance',-1)
   if not isinstance(chance,(int,float)) or not 0<chance<=100:chance=-1
   rec['loot'].append([iid,9,chance,False])
  else:rec['stock'].append([iid,5,-1,False])
  links+=1
 else:
  record={'kind':kind,'id':sid,'name':s.get('name',f'#{sid}'),'zone':s.get('zone',''),'chance':s.get('chance',-1),'source':'kb'}
  if kind=='quest':
   q=quests[sid];record['givers']=[giver('npc',id) for id in values(q[2][1] if q and q[2] else None)]+[giver('object',id) for id in values(q[2][2] if q and q[2] else None)]
  elif kind=='object':record['points']=giver('object',sid)['points']
  other.setdefault(iid,[]).append(record)
# World equipment pools must stay conditional, or every wolf becomes a unique epic source.
frequency={}
for rec in extra_mobs.values():
 for e in rec['loot']:frequency[e[0]]=frequency.get(e[0],0)+1
for rec in extra_mobs.values():
 for e in rec['loot']:
  item=itemmeta[e[0]];e[3]=frequency[e[0]]>=80 and item['classID'] in (2,4) and item['quality']>=2
# Identify dungeon quests by explicit zone tag and objective NPC/item associations.
item_dungeons={}
for iid,item in G['items'].items():
 ds=set()
 for id in values(item[2]):
  npc=npcs[id]
  if npc:
   for area in values(npc[7] and L.table_from(list(npc[7].keys()))):
    if area in area_instance:ds.add(area_instance[area])
 if ds:item_dungeons[iid]=ds
members={}
for id,q in quests.items():
 ds=set()
 if q[17] in area_instance:ds.add(area_instance[q[17]])
 for obj in values(q[10][1] if q[10] else None):
  npc=npcs[obj[1]]
  if npc and npc[9] in area_instance:ds.add(area_instance[npc[9]])
 for obj in values(q[10][3] if q[10] else None):
  item=G['items'][obj[1]]
  if item and item[12]==12:ds.update(item_dungeons.get(obj[1],set()))
 if ds:members[id]=ds
# Curated Forever-only dungeon membership fills gaps in the upstream zone table.
# Negative IDs are private atlas identities, never official AreaIDs or map IDs.
curated=json.loads((cache/'dungeon-overrides.json').read_text())
for id,v in curated['instances'].items():instances.setdefault(int(id),{}).update(v)
for id,v in curated['quests'].items():
 if v.get('dungeons'):members[int(id)]=set(v['dungeons'])
needed=set(members)
needed.update(int(id) for id in curated['quests'])
def ancestors(id,depth=0):
 if depth>12:return
 q=quests[id]
 if not q:return
 for prev in values(q[12])+values(q[13]):
  if prev>0 and prev not in needed:needed.add(prev);ancestors(prev,depth+1)
for id in list(needed):ancestors(id)
questdata={}
for id in sorted(needed):
 q=quests[id]
 if not q:continue
 givers=[giver('npc',i) for i in values(q[2][1] if q[2] else None)]+[giver('object',i) for i in values(q[2][2] if q[2] else None)]
 record={'name':q[1] or f'Quest #{id}','ruName':ruquests.get(id),'min':q[4] or 0,'level':q[5] or 0,'raceMask':q[6] or 0,'classMask':q[7] or 0,'preAll':values(q[12]),'preAny':values(q[13]),'givers':givers,'startItems':values(q[2][3] if q[2] else None),'dungeons':sorted(members.get(id,set())),'max':q[32] or 0,'special':any(q[k] is not None for k in [18,19,20,25,30,31,33,34,35,36])}
 override=curated['quests'].get(str(id),{})
 record.update(override)
 if override and q[4] is None and 'min' not in override:record['minUnknown']=True
 # Infer faction only from explicit friendly-to-faction giver metadata; otherwise uncertain.
 if override and q[6] is None and 'raceMask' not in override:
  factions={npcs[g['id']][13] for g in givers if g['kind']=='npc' and npcs[g['id']]}
  if factions=={'A'}:record['raceMask']=77
  elif factions=={'H'}:record['raceMask']=178

 questdata[id]=record
# Explicit reward source links for preparation ranking, not invented item/BiS scores.
rewards={}
for iid,rows in other.items():
 for s in rows:
  if s['kind']=='quest':rewards.setdefault(s['id'],[]).append(iid)
for id,q in questdata.items():q['rewards']=sorted(set(rewards.get(id,[])))
(out:=R/'MobAtlas'/'Expansion.lua').write_text('-- Local catalog expansion. Provenance: Expansion-BUILD.json / SOURCES.md\nlocal _,A=...\nA.extraItems='+lua(itemmeta)+'\nA.extraMobs='+lua(extra_mobs)+'\nA.otherSources='+lua(other)+'\nA.dungeonQuests='+lua(questdata)+'\nfor id,v in pairs('+lua({int(k):instances[int(k)] for k in curated['instances']})+') do A.instances[id]=v end\n')
report={'schemaVersion':1,'kb':meta,'itemCatalog':len(itemmeta),'skippedHiddenOrJunk':rejected,'npcSourceLinks':links,'otherSourceLinks':sum(map(len,other.values())),'ahledgerMetadataRows':ahcount,'dungeonQuestRecords':len(questdata),'dungeonQuests':len(members),'questDungeons':len({d for ds in members.values() for d in ds}),'inputs':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(cache.glob('*.json'))},'limits':'KB drop rates are Classic reference, not current Forever measurements. AHledger only item metadata; no invented spawn coordinates. Local testing build, third-party notices retained.'}
(R/'MobAtlas/Expansion-BUILD.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ('kb','inputs')},ensure_ascii=False))
