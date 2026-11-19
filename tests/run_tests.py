from pathlib import Path
from lupa.lua51 import LuaRuntime, lua_type
import xml.etree.ElementTree as ET
import json

root = Path(__file__).resolve().parents[1]
addon = root / 'Putnik'
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'tests/wow_mock.lua').read_text())
namespace = lua.table()
load = lua.eval('function(source, name, namespace) local fn, err = loadstring(source, name); assert(fn, err); return fn("Putnik", namespace) end')
for name in ('Data.lua', 'Social.lua', 'Engine.lua', 'UI.lua', 'Core.lua'):
    load((addon / name).read_text(), '@' + name, namespace)
ET.parse(addon / 'Bindings.xml')
for line in (addon / 'Putnik.toc').read_text().splitlines():
    if line and not line.startswith('#'):
        assert (addon / line).is_file(), line
lua.execute((root / 'tests/test.lua').read_text())
print('PASS TOC file list and bindings XML')

def serialize(v):
    if lua_type(v) == 'table':
        return '{' + ','.join('[' + serialize(k) + ']=' + serialize(value) for k, value in v.items()) + '}'
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if v is None:
        return 'nil'
    return str(v)

saved = serialize(lua.globals().PutnikDB)
assert 'message 30' not in saved and 'Alice' not in saved
restored = lua.execute('return ' + saved)
assert restored['completed']['first_run']
assert restored['cards']['group_12']['streak'] > 0
assert restored['settings']['capture'] is True
print('PASS SavedVariables Lua serialization round trip')
