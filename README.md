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

The servants’ village keeps a seasonal mortal pantry: cottage greens, orchard
fruit, pond fish, livestock, forest game and kitchen preserves. Eight rice hands
remain on the paddies; the other adults tend food trades. Each midday meal takes
a staple, vegetables, occasional protein and fruit, using the most perishable
stock first. Winter relies on stored roots, beans and preserved food. Diet variety
gently changes the words on person cards; hunger never kills anyone.

Generous yields and starting reserves keep every food group stocked. The kitchen
preserves surplus above a fresh reserve of 130 jin per good; seasonal yields and
losses still make fresh stocks rise and fall. Vegetable fields cover 15 tiles,
cottage gardens four tiles, and the orchard holds 30 trees in rows. Footprints
exclude roads, paddies and buildings and are drawn outside chunk baking.

Food sites are declared in `data/sects/first_sect.json`; small pixel decorations
are drawn separately from terrain chunks. `data/goods.json` defines sources,
seasons, starting stores and seasonal spoilage. Stocks retain the original internal
ration scale (displayed as two jin, or two eggs, per internal unit). Tea and cooking
condiments accompany meals without substituting for edible rations. Salt is a
large finite city reserve; sea fish stays at zero until trade is implemented.
Kitchen recipes debit ingredients and credit output with separate ledger flows.

For a deterministic three-year group report:
`godot --headless --path . -- --headless-sim --years=3`.
Run each `tools/test*.gd` with `godot --headless --path . --script <path>`, one
process at a time. `tools/test_foods.gd` covers seasonal yields, staffing, recipes,
meal variety, survival, daily group reserves, day-200 abundance, annual pantry
growth, and stock reconciliation across daily and jumped time. The report also
prints day-200 group stocks for each year.
