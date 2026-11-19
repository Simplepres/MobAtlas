from pathlib import Path
from lupa.lua51 import LuaRuntime
import xml.etree.ElementTree as ET
r=Path(__file__).resolve().parents[1];p=r/'Putnik'
l=LuaRuntime(unpack_returned_tuples=True)
l.execute((r/'tests/wow_mock.lua').read_text());l.execute((r/'tests/journal_mock.lua').read_text())
ns=l.table();load=l.eval('function(s,n,ns) local f,e=loadstring(s,n);assert(f,e);return f("Putnik",ns) end')
for name in (p/'Putnik.toc').read_text().splitlines():
 if name and not name.startswith('#'):
  assert name!='Bindings.xml'
  load((p/name).read_text(),'@'+name,ns)
ET.parse(p/'Bindings.xml')
l.execute((r/'tests/test_journal.lua').read_text())
print('PASS Lua 5.1 compilation, TOC and bindings')
