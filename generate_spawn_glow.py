from pathlib import Path
from PIL import Image
import math
im=Image.new('RGBA',(64,64))
for y in range(64):
 for x in range(64):
  radius=math.hypot((x-31.5)/31.5,(y-31.5)/31.5)
  alpha=int(255*max(0,1-radius*radius)**2) if radius<1 else 0
  im.putpixel((x,y),(255,255,255,alpha))
im.save(Path(__file__).resolve().parent/'MobAtlas/Art/SpawnGlow.tga')
