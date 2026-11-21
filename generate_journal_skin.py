"""Original lightweight UI textures; deterministic, no runtime generation."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import random,math
out=Path(__file__).resolve().parent/'MobAtlas/Art';rng=random.Random(79)
im=Image.new('RGBA',(512,512));px=im.load()
for y in range(512):
 for x in range(512):
  grain=rng.uniform(-5,5);v=1-.24*((x-256)**2+(y-256)**2)/131072
  edge=min(x,511-x,y,511-y);alpha=min(1,max(0,(edge-2-rng.random()*2)/6))
  px[x,y]=(int((38+grain)*v),int((33+grain)*v),int((27+grain)*v),int(alpha*252))
im.save(out/'JournalPanel.tga')
for name,base in [('JournalButton',(83,45,33)),('JournalButtonDown',(48,29,23))]:
 im=Image.new('RGBA',(256,64));p=im.load()
 for y in range(64):
  for x in range(256):
   n=rng.uniform(-5,5);edge=min(x,255-x,y,63-y);a=int(255*min(1,max(0,(edge-rng.random()*2)/3)))
   p[x,y]=(*(max(0,int(c+n)) for c in base),a)
 d=ImageDraw.Draw(im);d.line((8,5,247,5),fill=(170,130,83,100),width=1);d.line((8,58,247,58),fill=(8,6,4,180),width=1);im.save(out/(name+'.tga'))
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
d.rounded_rectangle((3,3,60,60),radius=5,outline=(25,25,25,255),width=6)
d.rounded_rectangle((5,5,58,58),radius=4,outline=(190,190,190,255),width=3)
d.line((10,5,53,5),fill=(255,255,255,255),width=1)
for x,y,sx,sy in [(5,5,1,1),(58,5,-1,1),(5,58,1,-1),(58,58,-1,-1)]:
 d.line((x,y,x+sx*10,y),fill=(255,255,255,255),width=2);d.line((x,y,x,y+sy*10),fill=(255,255,255,255),width=2)
im.save(out/'JournalRarity.tga')
# Rare and higher: a second bevel with tiny corner rivets, tinted by item quality.
d.rounded_rectangle((1,1,62,62),radius=6,outline=(150,150,150,170),width=1)
for x,y in [(5,5),(58,5),(5,58),(58,58)]:
 d.polygon([(x,y-3),(x+3,y),(x,y+3),(x-3,y)],fill=(245,245,245,255),outline=(30,30,30,255))
d.polygon([(28,3),(32,0),(36,3),(32,6)],fill=(235,235,235,255))
im.save(out/'JournalRarityRare.tga')
