from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1]

def scenario(client, saved, expected):
 l=LuaRuntime(unpack_returned_tuples=True)
 for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
 l.execute("getmetatable(UIParent).__index.EnableMouseWheel=function() end")
 l.globals().CLIENT_LOCALE=client;l.globals().SAVED_LANGUAGE=saved
 l.execute("function GetLocale() return CLIENT_LOCALE end;MobAtlasDB={language=SAVED_LANGUAGE}")
 ns=l.table();load=l.eval('function(s,n,ns) assert(loadstring(s,n))("MobAtlas",ns) end')
 for name in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
  if name.endswith('.lua'):load((r/'MobAtlas'/name).read_text(),'@'+name,ns)
 l.execute("MobAtlas:Init();MobAtlas:OpenAtlas();assert(MobAtlas.atlas.languageButton and MobAtlas.atlas.languageMenu)")
 l.globals().EXPECTED=expected
 l.execute("""
 local A=MobAtlas
 assert(A:GetLanguage()==EXPECTED)
 assert(A.atlas.prepButton:GetText()==(EXPECTED=='ruRU' and 'Перед данжем' or 'Dungeon prep'))
 assert(A:LocalizeWidget(A.atlas.prepButton)==A.atlas.prepButton,'no duplicate wrapper')
 local selected=A.atlas.selectedItem;local focus=A.focus;local search=A.atlas.search:GetText()
 assert(A:SetLanguage('enUS'));assert(A.db.language=='enUS' and A.atlas.prepButton:GetText()=='Dungeon prep')
 assert(A:L('Найдено: 494')=='Found: 494','dynamic count')
 assert(A:L('Ур. 21–22 · Гуманоид')=='Lv. 21–22 · Humanoid','multiple dynamic fragments')
 assert(A:L('Вообще другой текст')=='Вообще другой текст','untranslated text preserved')
 assert(A:L('Sealed Journeyman’s Writ')=='Sealed Journeyman’s Writ','item names preserved')
 assert(A.atlas.selectedItem==selected and A.focus==focus and A.atlas.search:GetText()==search,'language keeps navigation/search')
 A:OpenPreparation();assert(A.prep:IsShown());assert(A:SetLanguage('ruRU'))
 assert(A.atlas.prepButton:GetText()=='Перед данжем','existing hidden labels restore')
 assert(A.db.language=='ruRU');assert(not A:SetLanguage('invalid') and A.db.language=='ruRU')
 assert(A:SetLanguage('auto'));assert(A:GetLanguage()==(CLIENT_LOCALE=='ruRU' and 'ruRU' or 'enUS'))
 A:OpenAtlas();A.atlas.languageButton.scripts.OnClick();assert(A.atlas.languageMenu:IsShown())
 A.atlas:Hide();assert(not A.atlas.languageMenu:IsShown(),'menu closes with atlas')
 """)
for client,saved,expected in [('ruRU',None,'ruRU'),('enUS',None,'enUS'),('deDE',None,'enUS'),('enUS','ruRU','ruRU'),('ruRU','enUS','enUS'),('ruRU','bad','ruRU')]:scenario(client,saved,expected)
print('PASS locale: auto RU/EN, unsupported fallback, saved override, live switch/restore, dynamic text, preserved item names and navigation, language menu')
