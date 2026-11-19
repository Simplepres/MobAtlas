"""Build rare reference locations from the existing attributed Forever snapshot."""
from pathlib import Path
import runpy,json,hashlib
R=Path(__file__).resolve().parent
G=runpy.run_path(str(R/'build_mobatlas_catalog.py'));records={}
for id,npc in G['npcs'].items():
 if npc[6] not in (2,4):continue
 points=set()
 for area,rows in npc[7].items() if npc[7] else []:
  zone=G['zones'][area]
  if area in G['area_instance'] or zone not in G['allowed']:continue
  for p in rows.values():
   x,y=p[1],p[2]
   if isinstance(x,(int,float)) and isinstance(y,(int,float)) and 0<=x<=100 and 0<=y<=100:points.add((zone,x,y))
 if not points:continue
 records[id]={'name':npc[1] or f'NPC #{id}','min':npc[4] or 0,'max':npc[5] or 0,'rank':npc[6],'points':[list(p) for p in sorted(points)]}
(R/'MobAtlas/Rares.lua').write_text('-- QuestieDB Forever reference locations, not live detections. See SOURCES.md and Licenses/.\nlocal _,A=...\nA.rareCatalog='+G['lua'](records)+'\n')
(R/'MobAtlas/Rares-BUILD.json').write_text(json.dumps({'source':'QuestieDB Forever raw NPC data + static traces','revision':G['rev'],'rareRanks':[2,4],'npcs':len(records),'points':sum(len(v['points']) for v in records.values()),'limits':'Reference rarity and spawn points; client UnitClassification wins when observed. No live presence implied.'},ensure_ascii=False,indent=2)+'\n')
print('Rare reference NPCs:',len(records))
