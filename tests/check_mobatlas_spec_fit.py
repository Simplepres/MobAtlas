from pathlib import Path
from lupa.lua51 import LuaRuntime
r=Path(__file__).resolve().parents[1];l=LuaRuntime(unpack_returned_tuples=True)
for n in ['wow_mock','journal_mock']:l.execute((r/'tests'/f'{n}.lua').read_text())
l.execute('getmetatable(UIParent).__index.EnableMouseWheel=function() end')
a=l.table();load=l.eval('function(s,a) assert(loadstring(s))("MobAtlas",a) end')
for n in (r/'MobAtlas/MobAtlas.toc').read_text().splitlines():
 if n.endswith('.lua'):load((r/'MobAtlas'/n).read_text(),a)
l.execute('''
local A=MobAtlas;A:Init();A.db.classOnly=true;A.db.specOnly=true
function GetNumTalentTabs() return 3 end
function GetTalentTabInfo(i) return 'Test',nil,i==3 and 10 or 0 end
A:RefreshGearProfile();assert(A.gearProfile[1]=='Скрытность','dominant classic talent tree')
local axe={classID=2,subclass=0};local dagger={classID=2,subclass=15};local leather={classID=4,subclass=2};local cloth={classID=4,subclass=1}
assert(not A:ClassFits(axe,999401),'subtlety rogue excludes axes')
assert(A:ClassFits(dagger,999402),'subtlety rogue accepts daggers')
local queries=0
function GetItemStats(link) queries=queries+1;if link=='item:999403' then return {ITEM_MOD_INTELLECT_SHORT=5} elseif link=='item:999404' then return {ITEM_MOD_AGILITY_SHORT=5} end end
C_Item.GetItemStats=GetItemStats
assert(not A:ClassFits(leather,999403),'intellect-only leather is not rogue gear')
assert(A:ClassFits(leather,999404),'agility leather fits')
assert(A:ClassFits(leather,999405),'uncached stats do not erase potential loot')
local before=queries;A:ClassFits(leather,999405);assert(queries==before,'empty stat lookup cached')
A:ClassFits(leather,999406,false,true);assert(queries==before,'atlas browsing does not query every uncached item')
A.db.gearSpec=2;A:RefreshGearProfile();assert(A:ClassFits(axe,999401),'manual combat override allows client-supported axes')
A.db.gearSpec=nil
function GetSpecialization() return 1 end
function GetSpecializationInfo() return 259 end
A:RefreshGearProfile();assert(A.gearProfile[1]=='Ликвидация','modern spec API preferred')
A.db.specOnly=false;assert(A:ClassFits(axe,999401),'class-only mode remains available')
MOCK.class='PRIEST';A.db.specOnly=true;A.db.gearSpec=3;A:RefreshGearProfile()
assert(A:ClassFits(cloth,999403) and not A:ClassFits(cloth,999404),'caster stat preference')
assert(not A:ClassFits(axe,999401),'class restriction before spec filtering')
MOCK.class='ROGUE';A.db.gearSpec=nil;GetSpecialization=nil;GetSpecializationInfo=nil
function GetTalentTabInfo() return 'Test',nil,0 end
A:RefreshGearProfile();assert(not A.gearProfile and A:ClassFits(dagger,999402),'no selected talents safely falls back to class')
A:RefreshSettings();assert(A.specButton:GetText():find('выбери'),'UI asks to select unresolved spec')
assert(not A.specChoices[1].classIcon and not A.specChoices[1].specIcon,'off mode has no fake spec icon')
assert(A.specChoices[3].specIconPath~=A.specChoices[4].specIconPath and A.specChoices[4].specIconPath~=A.specChoices[5].specIconPath,'rogue specializations have distinct icons')
-- Spec selection belongs next to atlas item filters, with a native class icon.
A:OpenAtlas();local f=A.atlas
assert(f.specButton:IsShown() and f.specButton.classIcon:IsShown(),'visible atlas control and class icon')
assert(not A.specButton:IsShown(),'no duplicate spec control in settings')
assert(f.specButton:GetText():find('авто'),'auto state on atlas button')
f.specButton.scripts.OnClick();assert(A.specMenu:IsShown() and A.specMenu:GetParent()==f,'dropdown owned by visible atlas')
A.specChoices[1].scripts.OnClick();assert(not A.db.specOnly and f.specButton:GetText():find('откл.'),'disable directly from atlas')
f.specButton.scripts.OnClick();A.specChoices[5].scripts.OnClick()
assert(A.db.specOnly and A.db.gearSpec==3 and f.specButton:GetText():find('Скрытность'),'manual selection refreshes atlas label')
f.specButton.scripts.OnClick();A.specChoices[2].scripts.OnClick()
assert(A.db.specOnly and not A.db.gearSpec and f.specButton:GetText():find('авто'),'return to automatic selection')
f.specButton.scripts.OnClick();f.categoryButton.scripts.OnClick();assert(not A.specMenu:IsShown(),'sibling dropdown closes spec menu')
f.categoryMenu:Hide();f.specButton.scripts.OnClick();f:Hide();assert(not A.specMenu:IsShown(),'atlas close dismisses dropdown')
print('PASS spec fit: classic/modern auto detection, manual override, rogue dagger/axe rules, primary stats, class restrictions, missing stats, cached/bounded lookup, no-talents fallback')
''')
