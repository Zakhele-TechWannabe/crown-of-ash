# Crown of Ash

A Godot 4.7 xianxia world map: **The Seven Stars Continent**, seed `zi-xue-718`.
Explore the atlas, then travel anywhere across deterministic, streamed ground terrain.

Run `./play.sh`. Startup uses fullscreen on the second monitor when available.

- Map: drag or WASD/arrows to pan, wheel to zoom, Home to fit the world.
- Select a point and press **Travel here**, double-click, or choose a place in **Go to…**.
- Ground: WASD/arrows or right/middle-drag to pan, wheel for 0.5–2× zoom.
  Hover for biome, elevation in zhang, cover, tile coordinates and nearest place.
- M/Esc or **World map [M]** returns to the map centred on your position; M on the map resumes ground travel.

Arguments (after `--` when running Godot directly):
`--map`, `--goto="Sunset Heights"`, `--at=2840,3016`, `--windowed`, `--screen=1`,
`--shot=/tmp/ground.png`, `--frames=200` (wait at least this many frames before capture).
`--map` overrides travel arguments. Screenshots wait for visible chunks to finish loading.

The source web atlas is preserved at `tools/atlas/xianxia-atlas.html`. Its generated
seeded world was exported into `data/world_zi-xue-718.json`: dimensions, base64
terrain arrays (including unsigned 16-bit heights), biome palettes, rivers, peaks
and named features. Godot reads that snapshot and adds deterministic ground detail.

Ground checks: `godot --headless --path . -s res://tools/test_continuous.gd`.
