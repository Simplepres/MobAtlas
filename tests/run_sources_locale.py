from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];p=r/'Putnik'
l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text())
l.execute("function GetLocale() return 'enUS' end")
ns=l.table();load=l.eval('function(s,n,ns) local f,e=loadstring(s,n);assert(f,e);return f("Putnik",ns) end')
for name in (p/'Putnik.toc').read_text().splitlines():
 if name and not name.startswith('#'):load((p/name).read_text(),'@'+name,ns)
l.execute('''
local P=Putnik
assert(P.locale=='ruRU' and P:L('Вещи')=='Вещи')
P.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
P.sources={};P.db.observed={};P.items={};P.indexMeta={};P.slot='CHEST';P.mode=2
MOCK.items={};MOCK.equipped={[5]=900}
MOCK.items[900]={name='Old leather',stats={ITEM_MOD_AGILITY_SHORT=1}}
MOCK.items[100]={name='Known source item',level=10,stats={ITEM_MOD_AGILITY_SHORT=8}}
MOCK.items[101]={name='Unknown source item',level=10,stats={ITEM_MOD_AGILITY_SHORT=30}}
P.Quests[700]={starts={'npc:700'}};P.Places['npc:700']={mapID=1429,x=40,y=50,name='Quest NPC'}
P.sources={{id=100,kind='quest',quest=700,q=P.Quests[700],min=25,level=25,key='q700'}}
P:Observe('item:100','tooltip');P:Observe('item:101','tooltip')
local current=P:GearCandidates(2,'');assert(#current==1 and current[1].id==101,'late source excluded from current level')
local rows=P:GearCandidates(3,'')
assert(#rows==2 and rows[1].id==100,'known source must precede unlocated catalog entries')
assert((rows[1].s or rows[1].sourceRow.s).quest==700,'source survives level filter')
assert(#P:MapPoints(rows[1])==1,'known source map retained')
assert(#P:GearCandidates(1,'')==0,'future acquisition must not become a current upgrade')
P.detail=rows[1];P.expandedDetails=true;P:Toggle(true)
local details=P.detailText:GetText()
assert(details:find('ГДЕ ВЗЯТЬ',1,true))
assert(details:find('Quest NPC',1,true)<details:find('СРАВНЕНИЕ',1,true))
assert(P.listUI:IsShown() and P.detailUI:IsShown(),'list remains visible beside detail')
MOCK.items[102]={name='Late armor with no equip gate',level=0,ilvl=60,stats={ITEM_MOD_AGILITY_SHORT=99}}
P.items[102]=nil;P:Observe('item:102','tooltip')
local late=P:Info(102);late.ilvl=60
assert(not P:AtCurrentProgress({item=late,id=102}))
P.expandedDetails=true;assert(P:DetailSections({item=late,id=102,why='',status=''}):find('60',1,true))
SlashCmdList.PUTNIK('en');assert(PutnikJourneyDB.language=='enUS')
SlashCmdList.PUTNIK('ru');assert(PutnikJourneyDB.language=='ruRU')
print('PASS Russian on English client; source lookup independent of level; source-first detail; no future upgrade; language commands')
''')
# Actual bundled font includes Cyrillic glyphs, not just a nonempty file.
from fontTools.ttLib import TTFont
font=TTFont(p/'Art/NotoSans-Regular.ttf');cmap=font.getBestCmap()
assert all(ord(ch) in cmap for ch in 'ПутникГдевзятьЁё')
print('PASS bundled font Cyrillic glyph coverage')
