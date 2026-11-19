from pathlib import Path
import json,re,html,urllib.request,concurrent.futures,shutil
R=Path(__file__).resolve().parent;raw=R/'vendor/source-snapshots';cache=R/'vendor/mobatlas-cache';cache.mkdir(exist_ok=True);out=R/'MobAtlas'
npcs={x['id']:x for x in json.load(open(raw/'npcs.json'))['records']}
items={x['numericId']:x for x in json.load(open(raw/'items.json'))['items'] if isinstance(x.get('numericId'),int)}
zones=json.load(open(R/'vendor/everloot/web/src/data/game-data/map.json'))['zones']
selected=[n for n in npcs.values() if 1<=(n.get('maxLevel') or 999)<=25 and n.get('spawnCount',0)>0 and n.get('lootCounts',{}).get('creature',0)>0]
fail=[]
def fetch(url,file):
 if file.exists():return file.read_text()
 try:
  b=urllib.request.urlopen(url,timeout=15).read();file.write_bytes(b);return b.decode()
 except Exception as e:fail.append(url);return ''
def download(n):
 id=n['id'];src=raw/'npc-details'/f'{id}.json';dest=cache/f'npc-{id}.json'
 if src.exists() and not dest.exists():shutil.copy2(src,dest)
 fetch(f'https://www.wowforeverfriends.org/assets/library/npc-data/{id}.json',dest)
 fetch(f'https://www.wowforeverfriends.org/npcs/{id}/',cache/f'npc-{id}.html')
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 for i,_ in enumerate(pool.map(download,selected),1):
  if i%100==0:print('Fetched mobs',i,'/',len(selected),flush=True)
def rows(s):
 out=[]
 for row in re.findall(r'<tr[^>]*>(.*?)</tr>',s,re.S):
  cols=re.findall(r'<td[^>]*>(.*?)</td>',row,re.S)
  if len(cols)<4:continue
  item=re.search(r'href="/items/(\d+)/',cols[0]);pool=re.search(r'href="/library/loot/(\d+)/',cols[0])
  if not item and not pool:continue
  clean=lambda x:html.unescape(re.sub('<[^>]+>','',x)).strip()
  chance=re.fullmatch(r'([\d.]+)%',clean(cols[1]));rule=clean(cols[3])
  percent=float(chance[1]) if chance and 0<float(chance[1])<=100 else None
  out.append(dict(id=int((item or pool)[1]),pool=bool(pool),chance=percent,rule=rule,quantity=clean(cols[2])))
 return out
parsed={};pools=set()
for n in selected:
 f=cache/f"npc-{n['id']}.html"
 if not f.exists():continue
 s=f.read_text();allrows=[]
 for title,method in [('Corpse loot','drop'),('Skinning loot','skinning'),('Pickpocket loot','pickpocket')]:
  match=re.search(r'<h3>'+title+r'</h3>(.*?)(?=<h3>|</section>)',s,re.S)
  if match:
   for row in rows(match[1]):row['method']=method;allrows.append(row);pools.add(row['id']) if row['pool'] else None
 parsed[n['id']]=allrows
poolrows={}
for depth in range(4):
 todo=sorted(pools-set(poolrows))
 if not todo:break
 def getpool(id):
  page=fetch(f'https://www.wowforeverfriends.org/library/loot/{id}/',cache/f'pool-{id}.html')
  return id,rows(page.split('<h2>Pool contents</h2>',1)[1].split('</section>',1)[0]) if '<h2>Pool contents</h2>' in page else []
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
  for id,rr in pool.map(getpool,todo):
   poolrows[id]=rr
   for r in rr:
    if r['pool']:pools.add(r['id'])
 print('Parsed shared pools',len(poolrows),flush=True)
def expand(row,seen=None):
 if not row['pool']:return [row]
 seen=set() if seen is None else seen
 if row['id'] in seen:return []
 seen=seen|{row['id']};out=[]
 for r in poolrows.get(row['id'],[]):
  for child in expand(r,seen):out.append(dict(id=child['id'],pool=False,chance=None,rule='shared-pool',method=row.get('method','drop'),quantity=child['quantity']))
 return out
# Never infer a zone from overlapping map-art rectangles.
# Build Catalog.lua first from the pinned QuestieDB Forever snapshot.
from lupa.lua51 import LuaRuntime
_geometry=LuaRuntime(unpack_returned_tuples=True);_namespace=_geometry.table()
_geometry.eval('function(source,ns) assert(loadstring(source))("MobAtlas",ns) end')((out/'Catalog.lua').read_text(),_namespace)
def points(d):
 record=_namespace['catalog'][d['id']]
 return [[p[1],p[2],p[3]] for _,p in record['points'].items()] if record else []
prof={}
for p in json.load(open(R/'vendor/everloot/web/src/data/game-data/client-recipes.json'))['professions']:
 for recipe in p['recipes']:
  for id,count in recipe[5]:prof.setdefault(id,set()).add(p['id'])
mobs={};used=set();methods={'drop':1,'skinning':2,'pickpocket':3}
for id,rr in parsed.items():
 f=cache/f'npc-{id}.json'
 if not f.exists():continue
 ps=points(json.loads(f.read_text()))
 if not ps:continue
 loot={}
 for r in rr:
  for entry in expand(r):
   iid=entry['id']
   if iid not in items:continue
   method=r['method'];key=(iid,method);chance=entry['chance'];rule=entry['rule']
   # Only simple unconditional entries are numerically interpretable.
   if rule!='Direct entry':chance=None
   v=[iid,methods[method],chance if chance is not None else -1,rule!='Direct entry']
   if key in loot:loot[key][2]=-1;loot[key][3]=True
   else:loot[key]=v
   used.add(iid)
 if loot:mobs[id]=dict(name=npcs[id]['name'],min=npcs[id]['minLevel'],max=npcs[id]['maxLevel'],points=ps,loot=list(loot.values()))
itemout={}
for id in sorted(used):
 i=items[id];itemout[id]=dict(name=i['name'],quality=i['qualityId'] if isinstance(i.get('qualityId'),int) else 1,classID=i.get('classId',-1),subclass=i.get('subclassId',-1),level=i.get('requiredLevel') or 0,slot=i.get('slot') or '',prof=sorted(prof.get(id,set())))
def lua(v):
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if v is None:return 'nil'
 if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
 raise TypeError(type(v))
(out/'Data.lua').write_text('-- Classic-reference facts from WoW Forever Friends / CMaNGOS; GPL-3.0.\nlocal _,A=...\nA.mobs='+lua(mobs)+'\nA.items='+lua(itemout)+'\n')
gear=json.load(open(R/'vendor/everloot/web/src/data/game-data/client-class-gear.json'))
(out/'ClassGear.lua').write_text('local _,A=...\nA.classData='+lua(gear)+'\n')
report=dict(mobs=len(mobs),items=len(itemout),spawnPoints=sum(len(m['points']) for m in mobs.values()),lootRelations=sum(len(m['loot']) for m in mobs.values()),failedRequests=fail,levelRange=[1,25])
(out/'BUILD.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k!='failedRequests'}), 'failures',len(fail),flush=True)
