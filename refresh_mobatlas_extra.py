"""Fetch public catalogs for a local MobAtlas build. No player data is sent.
Atomic per-source snapshot: a failure keeps that source's previous files.
Usage: python3 refresh_mobatlas_extra.py [--kb-only]
"""
from pathlib import Path
from urllib.request import Request,urlopen
from datetime import datetime,timezone
import json,argparse
ROOT=Path(__file__).resolve().parent;CACHE=ROOT/'vendor/extra';CACHE.mkdir(parents=True,exist_ok=True)
def fetch(url):
 with urlopen(Request(url,headers={'User-Agent':'MobAtlas-local-catalog/0.5'}),timeout=35) as response:
  return json.load(response)
def commit(files):
 for name,data in files.items():
  path=CACHE/name;tmp=path.with_suffix('.tmp');tmp.write_text(json.dumps(data,ensure_ascii=False)+'\n');tmp.replace(path)
def run(kb_only=False):
 results={};base='https://gblaku.github.io/wow-forever-kb/api/'
 try:
  meta=fetch(base+'meta.json');files={'kb-meta.json':meta}
  for name in ['items','item_sources','quests']:
   rows=fetch(base+name+'.json');assert isinstance(rows,list) and rows and len(rows)==meta['counts'][name],name
   assert all(isinstance(r,dict) for r in rows)
   files['kb-'+name+'.json']=rows
  assert fetch(base+'meta.json')==meta,'KB snapshot changed; previous cache retained'
  commit(files);results['kb']={'ok':True,'asOf':meta['generated_utc'],'counts':meta['counts']}
 except Exception as e:results['kb']={'ok':False,'error':str(e),'previousSnapshotRetained':True}
 if not kb_only:
  try:
   files={}
   for name in ['armor','weapon','consumable','container','trade-goods','recipe','miscellaneous','quest','key','reagent','projectile','quiver']:
    data=fetch('https://ahledger.com/api/catalog?class='+name)
    assert isinstance(data,dict) and data.get('rows') and all(isinstance(r,list) and len(r)==8 and isinstance(r[0],int) for r in data['rows']),name
    files['ahledger-'+('catalog' if name=='trade-goods' else name)+'.json']=data
   commit(files);results['ahledger']={'ok':True,'rows':sum(len(v['rows']) for v in files.values()),'note':'Item metadata only; no measured drop sources. Follow published cache and attribution terms before distribution.'}
  except Exception as e:results['ahledger']={'ok':False,'error':str(e),'previousSnapshotRetained':True}
 results['checkedAt']=datetime.now(timezone.utc).isoformat();commit({'refresh-report.json':results});print(json.dumps(results,ensure_ascii=False,indent=2))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--kb-only',action='store_true');run(parser.parse_args().kb_only)
