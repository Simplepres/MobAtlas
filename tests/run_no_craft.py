from pathlib import Path
from lupa.lua51 import LuaRuntime
import re
r=Path(__file__).resolve().parents[1];p=r/'Putnik'
l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text())
l.execute("function GetLocale() return 'enUS' end")
l.execute("PutnikJourneyDB={language='enUS'}")
ns=l.table();load=l.eval('function(s,n,ns) local f,e=loadstring(s,n);assert(f,e);return f("Putnik",ns) end')
for name in (p/'Putnik.toc').read_text().splitlines():
 if name and not name.startswith('#'):load((p/name).read_text(),'@'+name,ns)
l.execute((r/'tests/test_no_craft.lua').read_text())
for f in l.globals().MOCK.frames.values():
 text=f['text'] or ''
 assert not re.search('[А-Яа-яЁё]',text),(f['kind'],text)
print('PASS no Russian strings in rendered English UI')
