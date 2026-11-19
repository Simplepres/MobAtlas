"""Refresh public Forever observations. No credentials, no upload. Run outside WoW."""
from pathlib import Path
import json, urllib.request, argparse
ROOT=Path(__file__).resolve().parent
CACHE=ROOT/'vendor/forever-live'; CACHE.mkdir(parents=True,exist_ok=True)
def fetch(url):
    req=urllib.request.Request(url,headers={'User-Agent':'MobAtlas/0.2 data updater'})
    with urllib.request.urlopen(req,timeout=45) as r:return json.load(r)
def run(offline=False):
    url='https://everloot.app/api/rollups/drops?limit=500'; pages=[];i=0
    while url:
        assert url.startswith('https://everloot.app/api/rollups/drops?')
        path=CACHE/f'drops-{i}.json'
        p=json.loads(path.read_text()) if offline else fetch(url)
        assert not p.get('unreachable') and p.get('ok',True), 'Feed unavailable; retaining installed data'
        assert p.get('attribution',{}).get('licence')=='CC BY-SA 4.0'
        if pages:assert p['dataAsOf']==pages[0]['dataAsOf'],'Snapshot changed during pagination; retry'
        # Cache is committed only after the entire response has passed validation.
        pages.append(p);url=p.get('next');i+=1
        assert i<=25,'Pagination exceeds anonymous API budget'
    client_path=CACHE/'client-layer.json'
    client=json.loads(client_path.read_text()) if offline else fetch('https://everloot.app/api/edges/client-layer')
    assert client['schema']=='everloot.client-layer/2' and client['build']['product']=='wowf'
    
    rows=[]
    for p in pages:
        for r in p['rates']:
            if not r.get('sourceNpcId') or r.get('public') is not True or r.get('reporters',0)<3:continue
            assert 0<=r['drops']<=r['kills'] and r['kills']>0 and 0<=r['rate']<=1
            assert abs(r['rate']-r['drops']/r['kills'])<1e-6
            rows.append(r)
    assert rows, 'Empty observations feed; keeping previous nonempty snapshot'
    if not offline:
        for j,page in enumerate(pages):(CACHE/f'drops-{j}.json').write_text(json.dumps(page,ensure_ascii=False,indent=2)+'\n')
        client_path.write_text(json.dumps(client,ensure_ascii=False)+'\n')
    # Do not infer a loot method: feed aggregates all windows of the NPC.
    data={'schemaVersion':1,'source':'https://everloot.app/api/rollups/drops','dataAsOf':pages[0]['dataAsOf'],'attribution':pages[0]['attribution'],'rates':rows}
    (CACHE/'forever-drops.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    lines=['local _,A=...','A.foreverAsOf='+json.dumps(data['dataAsOf']), 'A.foreverRates={']
    for r in rows:
        lines.append('{%d,%d,%.10g,%d,%d,%d},'%(r['sourceNpcId'],r['itemId'],100*r['rate'],r['drops'],r['kills'],r['reporters']))
    lines+=['}', 'A.foreverNames={']
    for npc,name in sorted({r['sourceNpcId']:r['sourceName'] for r in rows if r.get('sourceName')}.items()):
        lines.append('[%d]=%s,'%(npc,json.dumps(name,ensure_ascii=False)))
    lines+=['}', 'A.foreverItems={']
    for item,cls,sub,slot,q in client['items']:
        lines.append('[%d]={%d,%d,%d,%d},'%(item,cls,sub,slot,q if q is not None else -1))
    skills={e[1]:e[4] for e in client['edges'] if e[0]=='spell' and e[2]=='in_skill_line'}
    prof={}
    for e in client['edges']:
        if e[0]=='item' and e[2]=='reagent_for' and e[4] in skills:prof.setdefault(e[1],set()).add(skills[e[4]])
    lines+=['}', 'A.foreverProf={']
    for item,values in sorted(prof.items()):lines.append('[%d]={%s},'%(item,','.join(map(str,sorted(values)))))
    lines+=['}', 'A.foreverBuild='+json.dumps(client['build']['version']), '-- Everloot https://everloot.app · CC BY-SA 4.0. Loot windows, not kills.']
    path=ROOT/'MobAtlas/Forever.lua';tmp=path.with_suffix('.tmp');tmp.write_text('\n'.join(lines)+'\n');tmp.replace(path)
    print(f"Forever snapshot {data['dataAsOf']}: {len(rows)} NPC/item observations, {len(pages)} pages")
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--offline',action='store_true');run(parser.parse_args().offline)
