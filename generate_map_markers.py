"""Original compact UI symbols, antialiased for map/minimap rendering."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parent;art=R/'MobAtlas/Art';S=4
colors={'rim':(177,139,75,255),'light':(228,201,135,255),'ink':(22,25,24,255),'ivory':(235,224,184,255)}
def marker(kind):
 im=Image.new('RGBA',(64*S,64*S));d=ImageDraw.Draw(im)
 def ellipse(box,fill,outline=None,width=1):d.ellipse(tuple(v*S for v in box),fill=fill,outline=outline,width=width*S)
 def poly(points,fill):d.polygon([(x*S,y*S) for x,y in points],fill=fill)
 def line(points,fill,width=2):d.line([(x*S,y*S) for x,y in points],fill=fill,width=width*S,joint='curve')
 silver=kind=='Rare';live=kind=='RareLive';rim=(165,176,180,255) if silver else colors['rim'];light=(226,232,228,255) if silver else colors['light']
 if silver:
  poly([(32,2),(62,32),(32,62),(2,32)],(22,24,25,245));poly([(32,4),(60,32),(32,60),(4,32)],rim);poly([(32,9),(55,32),(32,55),(9,32)],colors['ink'])
 else:
  ellipse((2,2,62,62),(19,15,11,235));ellipse((4,4,60,60),rim);ellipse((8,8,56,56),(56,24,22,255) if live else (29,32,28,255));d.arc((5*S,5*S,59*S,59*S),205,295,fill=light,width=2*S)
 c=colors['ivory']
 if kind=='Mob':
  for box in [(15,19,25,31),(26,12,36,26),(39,18,49,30)]:ellipse(box,c)
  ellipse((9,31,19,41),c);poly([(22,35),(30,29),(37,32),(46,43),(43,50),(34,48),(25,51),(18,47),(18,42)],c)
 elif kind=='Vendor':
  line([(24,18),(28,14),(37,14),(41,18)],c,3);poly([(24,22),(40,22),(45,34),(47,46),(40,51),(23,51),(17,45),(19,33)],c);line([(22,24),(42,24)],colors['rim'],3);line([(26,33),(36,33),(38,38),(35,43),(27,43),(25,39),(27,35)],colors['ink'],2)
 elif kind=='Dungeon':
  d.rectangle((18*S,30*S,46*S,51*S),fill=c);ellipse((18,13,46,44),c);d.rectangle((24*S,29*S,40*S,51*S),fill=colors['ink']);ellipse((24,20,40,38),colors['ink']);line([(16,51),(48,51)],c,3)
 else:
  ellipse((19,15,45,41),c);poly([(24,32),(40,32),(40,47),(24,47)],c);ellipse((23,25,30,33),colors['ink']);ellipse((35,25,42,33),colors['ink']);poly([(32,33),(29,39),(35,39)],colors['ink']);line([(28,43),(28,48)],colors['ink'],2);line([(36,43),(36,48)],colors['ink'],2)
 return im.resize((64,64),Image.Resampling.LANCZOS)
images={kind:marker(kind) for kind in ['Mob','Vendor','Dungeon','Rare','RareLive']}
for kind,im in images.items():im.save(art/f'Marker{kind}.tga')
# Preview is a design sheet, not an in-game screenshot.
out=R.parent/'outputs';out.mkdir(exist_ok=True);sheet=Image.new('RGB',(650,204),(22,25,24));draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype(str(art/'NotoSans-Regular.ttf'),13)
labels=['Мобы','Торговцы','Подземелья','Место появления','Моб замечен']
for i,(kind,im) in enumerate(images.items()):
 x=18+i*127;sheet.paste(im,(x+24,15),im);sheet.paste(im.resize((20,20),Image.Resampling.LANCZOS),(x+45,98),im.resize((20,20),Image.Resampling.LANCZOS));draw.text((x+8,132),labels[i],font=font,fill=(226,214,181))
draw.text((18,175),'Крупный вариант сверху; размер на карте — снизу.',font=font,fill=(159,164,158));sheet.save(out/'MobAtlas-markers-0.7.2.png')
