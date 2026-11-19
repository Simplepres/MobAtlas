"""Build the offline Forever atlas: explicit zone geometry, drop links and entrances.
No inferred boss positions. Lua 5.1/lupa; inputs and revisions in Catalog-BUILD.json.
"""
from pathlib import Path
import json,re,hashlib,subprocess,shutil
from lupa.lua51 import LuaRuntime
R=Path(__file__).resolve().parent;Q=R/'vendor/QuestieDB';out=R/'MobAtlas'
def lua(v):
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if v is None:return 'nil'
 if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
 return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in sorted(v.items()))+'}'
def table_field(path,field):
 match=re.search(re.escape(field)+r'\s*=\s*\[\[(.*?)\]\]',path.read_text(),re.S)
 assert match,field
 return L.execute(match[1])
L=LuaRuntime(unpack_returned_tuples=True)
np=Q/'data/Forever/foreverNpcDB.lua';ip=Q/'data/Forever/foreverItemDB.lua';zp=Q/'support/Forever/Zones/areaIdToUiMapId.lua'
npcs=table_field(np,'npcData');items=table_field(ip,'itemData');zones=table_field(zp,'areaIdToUiMapId');overrides=table_field(zp,'areaIdToUiMapIdOverride')
for area,zone in overrides.items():zones[area]=zone
# Trace files contain declarative field assignments only; apply the fields we consume.
L.execute('''modules={QuestieDB={npcKeys=setmetatable({},{__index=function(_,k)return k end}),itemKeys=setmetatable({},{__index=function(_,k)return k end})},ZoneDB={private={}},Expansions={Current=1,Wotlk=3,Cata=4}}
QuestieLoader={CreateModule=function(_,n) modules[n]={};return modules[n] end,ImportModule=function(_,n)return assert(modules[n],n) end}
function UnitFactionGroup() return 'Alliance' end''')
trace_paths=[]
for kind,table,fields in [('Npc',npcs,{'name':1,'minLevel':4,'maxLevel':5,'rank':6,'spawns':7,'zoneID':9,'friendlyToFaction':13,'npcFlags':15,'factionID':12}),('Item',items,{'name':1})]:
 path=Q/f'src/corrections/Forever/traces/forever{kind}Traces.lua';trace_paths.append(path)
 L.execute(path.read_text());module=L.globals().modules['Forever'+kind+'Traces'];corrections=module.Load(module)
 for id,c in corrections.items():
  row=table[id]
  if row is None:row=L.table();table[id]=row
  for key,idx in fields.items():
   if c[key] is not None:row[idx]=c[key]
  if kind=='Npc':
   for key,idx in [('questStarts_add',10),('questEnds_add',11)]:
    if c[key]:
     values=set(row[idx].values()) if row[idx] else set();values.update(c[key].values());row[idx]=L.table_from(sorted(values))
  if kind=='Item' and c['npcDrops_add']:
   values=set(row[2].values()) if row[2] else set();values.update(c['npcDrops_add'].values());row[2]=L.table_from(sorted(values))
mapdata=json.load(open(R/'vendor/everloot/web/src/data/game-data/map.json'))
allowed={z['uiMapId'] for z in mapdata['zones']};mapnames={z['uiMapId']:z['name'] for z in mapdata['zones']}
# Questie explicitly labels dungeon UiMapID overrides as legacy aliases, NOT native floor maps.
# Keep instance identities and outside entrances separate from real spawn positions.
dp=Q/'support/Forever/Zones/dungeons.lua';L.execute(dp.read_text());dungeons=L.globals().modules.ZoneDB.private.dungeons
instances={};area_instance={}
for area,d in dungeons.items():
 entrances=[]
 for p in d[4].values():
  zone=zones[p[1]]
  if zone in allowed and 0<=p[2]<=100 and 0<=p[3]<=100:entrances.append([zone,p[2],p[3]])
 if not entrances:continue
 instances[area]={'name':d[1],'entrances':entrances}
 area_instance[area]=area
 for alias in d[2].values() if d[2] else []:area_instance[alias]=area
classic={n['id']:n for n in json.load(open(R/'vendor/source-snapshots/npcs.json'))['records']}
baseitems={x['numericId']:x for x in json.load(open(R/'vendor/source-snapshots/items.json'))['items'] if isinstance(x.get('numericId'),int)}
client_layer=json.load(open(R/'vendor/forever-live/client-layer.json'));client={x[0]:x for x in client_layer['items']}
spell_skills={e[1]:e[4] for e in client_layer['edges'] if e[0]=='spell' and e[2]=='in_skill_line'}
ru={};locale_paths=[]
for rel in ['l10n/Forever/lookupItems/ruRU.lua','l10n/Forever/traces/lookupItems/ruRU.lua']:
 path=Q/rel;locale_paths.append(path)
 match=re.search(r'loadstring\(\[\[(.*?)\]\]',path.read_text(),re.S);assert match
 for iid,name in L.execute(match[1]).items():ru.setdefault(iid,name)
vendors={};drops={};newitems={}
for iid,item in items.items():
 if item[14] and item[12] in (1,2,4,7,9):
  for npc in item[14].values():vendors.setdefault(npc,[]).append([iid,5,-1,False])
 if item[2]:
  for npc in item[2].values():drops.setdefault(npc,set()).add(iid)
 if not item[2] and not item[14]:continue
 old=baseitems.get(iid,{})
 c=client.get(iid);q=c[4] if c and isinstance(c[4],int) else old.get('qualityId',-1)
 newitems[iid]={'name':item[1] or f'Item #{iid}','quality':q if isinstance(q,int) else -1,'classID':c[1] if c else item[12] or -1,'subclass':c[2] if c else item[13] or -1,'level':item[10] if item[10] is not None else old.get('requiredLevel'),'slot':old.get('slot') or '', 'prof':[spell_skills[item[16]]] if item[16] in spell_skills else []}
 if iid in ru:newitems[iid]['ruName']=ru[iid]
frequency={}
for ids in drops.values():
 for iid in ids:frequency[iid]=frequency.get(iid,0)+1
common={iid:True for iid,count in frequency.items() if count>=80 and newitems[iid]['classID'] in (2,4) and newitems[iid]['quality']>=2}
curated_path=R/'vendor/extra/npc-overrides.json'
curated=json.loads(curated_path.read_text())['npcs']
for id,override in curated.items():
 row=npcs[int(id)]
 if row and override.get('spawns'):
  row[7]=L.table_from({int(area):L.table_from([L.table_from(p) for p in positions]) for area,positions in override['spawns'].items()})
  row[9]=override.get('zoneID',row[9])
catalog={};bad=0;points=0
new_metadata={id for id,npc in npcs.items() if id>=200000 and npc[7] and any(zones[area] in allowed and area not in area_instance for area in npc[7].keys())}
for id in sorted(set(classic)|set(vendors)|set(drops)|new_metadata):
 npc=npcs[id]
 if npc is None:continue
 coords=[];seen=set();instance_ids=set()
 for area,spawns in (npc[7].items() if npc[7] else []):
  if area in area_instance:instance_ids.add(area_instance[area]);continue
  zone=zones[area]
  if zone not in allowed:continue
  for p in spawns.values():
   x,y=p[1],p[2]
   if not isinstance(x,(float,int)) or not isinstance(y,(float,int)) or not 0<=x<=100 or not 0<=y<=100:bad+=1;continue
   key=(zone,x,y)
   if key not in seen:seen.add(key);coords.append(list(key))
 if npc[9] in area_instance:instance_ids.add(area_instance[npc[9]])
 rec={'name':npc[1] or f'NPC #{id}', 'min':npc[4] or 0,'max':npc[5] or 0,'points':sorted(coords),'instances':sorted(instance_ids),'friendly':npc[13] or '', 'kind':classic.get(id,{}).get('type','Unknown'),'family':classic.get(id,{}).get('family') or '', 'vendor':id in vendors}
 rec['service']=bool((npc[15] or 0)>0 or (npc[10] and len(npc[10])>0) or (npc[11] and len(npc[11])>0))
 rec.update(curated.get(str(id),{}))
 if id in vendors:rec['stock']=sorted(vendors[id])
 if id in drops:rec['referenceLoot']=sorted(drops[id])
 catalog[id]=rec;points+=len(coords)
(out/'Catalog.lua').write_text('-- QuestieDB Forever reference + static traces; see Licenses/QuestieDB-LICENSE.md.\nlocal _,A=...\nA.catalog='+lua(catalog)+'\nA.vendorItems='+lua(newitems)+'\nA.instances='+lua(instances)+'\nA.mapNames='+lua(mapnames)+'\nA.commonWorldItems='+lua(common)+'\n')
if (Q/'snapshot.json').exists() and not (Q/'.git').exists():rev=json.loads((Q/'snapshot.json').read_text())['revision']
else:
 try:rev=subprocess.check_output(['git','-C',str(Q),'rev-parse','HEAD'],text=True,stderr=subprocess.DEVNULL).strip()
 except (subprocess.CalledProcessError,FileNotFoundError):rev=json.loads((Q/'snapshot.json').read_text())['revision']
report={'schemaVersion':2,'questieDBRevision':rev,'geometry':'Explicit areaId -> uiMapId; Forever raw + trace coordinates; no rectangle inference','corrections':'Forever NPC/Item static traces applied; character-dependent and full authored correction stack not applied','catalogNPCs':len(catalog),'referenceDropItems':len({iid for ids in drops.values() for iid in ids}),'referenceDropLinks':sum(len(ids) for ids in drops.values()),'dungeonSourceNPCs':sum(bool(c['instances']) and bool(c.get('referenceLoot')) for c in catalog.values()),'dungeonsWithDrops':len({a for c in catalog.values() if c.get('referenceLoot') for a in c['instances']}),'vendorNPCs':sum(x['vendor'] for x in catalog.values()),'points':points,'rejectedCoordinates':bad,'foreverIdFloor':200000,'foreverMetadata':sum(id>=200000 for id in catalog),'foreverWithCoordinates':sum(id>=200000 and bool(v['points']) for id,v in catalog.items()),'foreverWithReferenceLoot':sum(id>=200000 and bool(v.get('referenceLoot')) for id,v in catalog.items()),'inputs':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [np,ip,zp,dp,curated_path]+trace_paths+locale_paths},'vendorSource':'QuestieDB reference; prices/stock unknown until observed in game','dungeonGeometry':'Outside entrances only; no invented boss floor coordinates'}
(out/'Catalog-BUILD.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
for f in ['LICENSE.md','gpl-3.0.md','PROVENANCE.md']:shutil.copy2(Q/f,out/'Licenses'/('QuestieDB-'+f))
print(json.dumps({k:v for k,v in report.items() if k not in ['inputs','corrections','geometry']},ensure_ascii=False))
