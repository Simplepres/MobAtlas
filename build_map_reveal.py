"""Adapt the pinned, MIT-licensed map overlay data; never fetch game textures."""
from pathlib import Path
r=Path(__file__).resolve().parent;src=r/'vendor/map-reveal'
s=(src/'Data.lua').read_text();body=s[s.index('ns.modules.WorldMap.internal.unexploredAreas.overlays ='):].split('=',1)[1]
(r/'MobAtlas/MapReveal.lua').write_text('-- Full map overlay data adapted from ForeverPlusPlus; MIT copyright 2026 Cameron Weaver.\n-- See Licenses/MapReveal-MIT.txt and vendor/map-reveal/PROVENANCE.json. No upstream runtime copied.\nlocal _,A=...\nA.mapReveal ='+body)
(r/'MobAtlas/Licenses/MapReveal-MIT.txt').write_bytes((src/'LICENSE').read_bytes())
