extends RefCounted
## Ground techniques shared by both renderers (ground_baker on workers, ground_terrain on the main
## thread), so the two stay pixel-identical. Light comes from the top left:
## - where two grounds meet, the higher one (grass over earth over sand over water) creeps over the
##   seam in a wavy lip with a lit rim and a thin shadow under it; water gets a line of foam;
## - convex corners are clipped and concave ones filled, so patches read as shapes, not squares;
## - banks are rock faces with facets, ledges, a turf lip, hanging vines and a darker foot;
## - the ground at the foot of a bank, or east of a raised one, lies in soft shade.
## `owner` is the renderer: it provides sample(), sect, atlas_image and the per-bake `pending`.
const Palette = preload("res://src/palette.gd")
const SHADES := 9
const SIDES := [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const RANK := {0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1, 8: 1, 6: 2, 7: 2, 9: 2}
const SECT_RANK := {"grass": 3, "garden": 3, "earth": 2, "field": 2, "paving": 1}


static func hash2(x: int, y: int) -> int:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return h ^ (h >> 16)


## Smooth noise in [0, 1] along a line of world pixels: a value every `step` pixels, eased between.
static func wave(u: int, line: int, step: int) -> float:
	var i := floori(float(u) / step)
	var f := float(u - i * step) / step
	f = f * f * (3.0 - 2.0 * f)
	return lerpf((hash2(i, line) % 1000) / 1000.0, (hash2(i + 1, line) % 1000) / 1000.0, f)


## sample() once per tile per bake: neighbours are asked for again and again.
static func info(owner: Object, tile: Vector2i) -> Dictionary:
	var cache: Dictionary = owner.pending.get_or_add("info", {})
	if not cache.has(tile):
		var found: Dictionary = owner.sample(tile)
		found.material = _material(owner, tile, found)
		cache[tile] = found
	return cache[tile]


## What a tile's ground is made of, for blending: `order` ranks it (higher creeps over lower; -1 never blends).
static func _material(owner: Object, tile: Vector2i, found: Dictionary) -> Dictionary:
	var sect: RefCounted = owner.sect
	if sect.has_tile(tile):
		var surface: String = sect.surface_at(tile)
		if sect.standing_tiles.has(tile) or sect.art[sect.index_at(tile)] >= 0 or not SECT_RANK.has(surface):
			return {"order": -1, "rank": -1}
		var colour: Color = {"grass": Palette.GRASS, "garden": Palette.GRASS, "earth": Palette.EARTH, "field": Palette.BRASS.darkened(0.3), "paving": Palette.STONE}[surface]
		return {"order": SECT_RANK[surface] * 1000 + 900 + sect.SURFACES.find(surface), "rank": SECT_RANK[surface], "colour": colour, "grassy": surface in ["grass", "garden"]}
	var kind: int = found.kind
	var rank: int = RANK.get(kind, 3)
	var row: int = int(found.shade) + int(found.band) * SHADES
	return {"order": rank * 1000 + int(found.band) * 100 + int(found.shade) * 10 + kind % 10, "rank": rank, "source": Vector2i(kind * 16, row * 16), "grassy": rank >= 2}


static func _pixel(owner: Object, material: Dictionary, x: int, y: int) -> Color:
	if material.has("colour"):
		return material.colour
	var source: Vector2i = material.source
	return owner.atlas_image.get_pixel(source.x + x, source.y + y)


## Edges, texture and shade for one tile already drawn at `pos`.
static func ground(owner: Object, image: Image, tile: Vector2i, pos: Vector2i) -> void:
	var here := info(owner, tile)
	var me: Dictionary = here.material
	var level: int = here.level
	if me.order >= 0:
		_edges(owner, image, tile, pos, me, level)
		_texture(owner, image, tile, pos, me)
	_shade(owner, image, tile, pos, level)


static func _edges(owner: Object, image: Image, tile: Vector2i, pos: Vector2i, me: Dictionary, level: int) -> void:
	# The neighbour on each side that creeps over this tile, and how deep, per pixel along the seam.
	var over: Array = [null, null, null, null]
	var lower: Array[bool] = [false, false, false, false]
	var any := false
	for s in 4:
		var other := info(owner, tile + SIDES[s])
		if other.material.order < 0:
			continue
		if other.level > level and s % 2 == 1:
			# Raised ground beside: its turf spills over the edge, outlined dark where it drops.
			over[s] = other.material.merged({"ledge": true, "order": other.material.order + 10000}, true)
			any = true
			continue
		if other.level != level:
			continue
		if other.material.order > me.order:
			over[s] = other.material
			any = true
		elif other.material.order < me.order:
			lower[s] = true
	# A convex corner (both sides lower) is clipped with the ground beside it.
	var clips: Array = [null, null, null, null]
	for s in 4:
		var t := (s + 1) % 4
		if lower[s] and lower[t]:
			clips[s] = info(owner, tile + SIDES[t]).material
			any = true
	if not any:
		return
	var overs := 0
	for s in 4:
		if over[s] != null:
			overs += 1
	if overs == 0:
		# Only clipped corners: a few pixels each.
		for s in 4:
			if clips[s] != null:
				var r := 2 + hash2(tile.x * 4 + s, tile.y) % 3
				for a in r:
					for b in r - a:
						var p := _corner(s, a, b)
						image.set_pixel(pos.x + p.x, pos.y + p.y, _pixel(owner, clips[s], p.x, p.y))
		return
	# Depth of each creeping side along its seam (0 where nothing creeps).
	var depth: Array[PackedInt32Array] = []
	var orders := PackedInt32Array([-1, -1, -1, -1])
	for s in 4:
		var row := PackedInt32Array()
		row.resize(16)
		if over[s] != null:
			orders[s] = over[s].order
			var side: Vector2i = SIDES[s]
			var vertical := side.x != 0
			var line := (tile.x + maxi(0, side.x)) * 2 + 1 if vertical else (tile.y + maxi(0, side.y)) * 2
			var along := tile.y * 16 if vertical else tile.x * 16
			# Where the creeping ground ends beside this seam, the lip tapers off instead of stopping square.
			var step: Vector2i = Vector2i(0, 1) if vertical else Vector2i(1, 0)
			var before: Dictionary = info(owner, tile + side - step)
			var after: Dictionary = info(owner, tile + side + step)
			for u in 16:
				var d := 1 + int(wave(along + u, line, 5) * 4.0)
				if before.material.order != over[s].order:
					d = mini(d, u / 2)
				if after.material.order != over[s].order:
					d = mini(d, (15 - u) / 2)
				row[u] = d
		depth.append(row)
	var up_d: PackedInt32Array = depth[0]
	var left_d: PackedInt32Array = depth[1]
	var down_d: PackedInt32Array = depth[2]
	var right_d: PackedInt32Array = depth[3]
	var clip_r := PackedInt32Array([0, 0, 0, 0])
	for s in 4:
		if clips[s] != null:
			clip_r[s] = 2 + hash2(tile.x * 4 + s, tile.y) % 3
	# cover: 0 none, 1-4 the creeping side, 5-8 a clipped corner; one pixel of border for rims.
	var cover := PackedByteArray()
	cover.resize(18 * 18)
	# Nothing reaches more than five pixels in from a seam: visit only the bands along active sides.
	var top_band := orders[0] >= 0 or clip_r[0] > 0 or clip_r[3] > 0
	var left_band := orders[1] >= 0 or clip_r[0] > 0 or clip_r[1] > 0
	var bottom_band := orders[2] >= 0 or clip_r[1] > 0 or clip_r[2] > 0
	var right_band := orders[3] >= 0 or clip_r[2] > 0 or clip_r[3] > 0
	var full := PackedInt32Array(range(-1, 17))
	var sides := PackedInt32Array()
	if left_band:
		sides.append_array(range(-1, 6))
	if right_band:
		sides.append_array(range(10, 17))
	var rows := PackedInt32Array()
	for y in range(-1, 17):
		if (top_band and y <= 5) or (bottom_band and y >= 10) or not sides.is_empty():
			rows.append(y)
	for y in rows:
		var cy := clampi(y, 0, 15)
		var xs := full if (top_band and y <= 5) or (bottom_band and y >= 10) else sides
		for x in xs:
			var cx := clampi(x, 0, 15)
			var best := 0
			var best_order := -1
			if orders[0] > best_order and (y < 0 or cy < up_d[cx]):
				best = 1
				best_order = orders[0]
			if orders[1] > best_order and (x < 0 or cx < left_d[cy]):
				best = 2
				best_order = orders[1]
			if orders[2] > best_order and (y > 15 or 15 - cy < down_d[cx]):
				best = 3
				best_order = orders[2]
			if orders[3] > best_order and (x > 15 or 15 - cx < right_d[cy]):
				best = 4
				best_order = orders[3]
			if best == 0 and overs >= 2:
				# Concave corners fill in where two creeping sides meet.
				for s in 4:
					var t := (s + 1) % 4
					if orders[s] >= 0 and orders[t] >= 0:
						var corner := _corner(s, cx, cy)
						if corner.x + corner.y < depth[s][cx if s % 2 == 0 else cy] + depth[t][cx if t % 2 == 0 else cy] + 2:
							best = s + 1 if orders[s] > orders[t] else t + 1
							break
			if best == 0 and x >= 0 and x < 16 and y >= 0 and y < 16:
				# Convex corners are clipped by the ground beside them.
				for s in 4:
					if clip_r[s] > 0:
						var corner := _corner(s, cx, cy)
						if corner.x + corner.y < clip_r[s]:
							best = s + 5
							break
			cover[(y + 1) * 18 + x + 1] = best
	var mats: Array = [null, over[0], over[1], over[2], over[3], clips[0], clips[1], clips[2], clips[3]]
	# Rims only where a higher ground (or a raised ledge) creeps over: lit lip, shadow or foam beneath.
	var raised := PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0, 0])
	var ledges := PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0, 0])
	for k in range(1, 5):
		if mats[k] != null:
			raised[k] = 1 if mats[k].rank > me.rank or mats[k].has("ledge") else 0
			ledges[k] = 1 if mats[k].has("ledge") else 0
	var water: bool = me.rank == 0
	for y in rows:
		if y < 0 or y > 15:
			continue
		var xs := full if (top_band and y <= 5) or (bottom_band and y >= 10) else sides
		for x in xs:
			if x < 0 or x > 15:
				continue
			var c := cover[(y + 1) * 18 + x + 1]
			var up := cover[y * 18 + x + 1]
			var left := cover[(y + 1) * 18 + x]
			if c != 0:
				var col := _pixel(owner, mats[c], x, y)
				# The lip's top-left rim catches the light.
				if raised[c] == 1 and (up == 0 or left == 0):
					col = col.lightened(0.06)
				image.set_pixel(pos.x + x, pos.y + y, col)
				continue
			var down := cover[(y + 2) * 18 + x + 1]
			var right := cover[(y + 1) * 18 + x + 2]
			if ledges[up] + ledges[left] + ledges[down] + ledges[right] > 0:
				image.set_pixel(pos.x + x, pos.y + y, image.get_pixel(pos.x + x, pos.y + y).darkened(0.34))
			elif raised[up] == 1 or raised[left] == 1:
				if water:
					image.set_pixel(pos.x + x, pos.y + y, Palette.BLUE.lightened(0.45))
				else:
					image.set_pixel(pos.x + x, pos.y + y, image.get_pixel(pos.x + x, pos.y + y).darkened(0.14))
			elif water and (raised[down] == 1 or raised[right] == 1):
				image.set_pixel(pos.x + x, pos.y + y, Palette.BLUE.lightened(0.45))


## Distance of a pixel from the tile corner between side s and the next side (up/left, left/down, down/right, right/up).
static func _corner(s: int, x: int, y: int) -> Vector2i:
	match s:
		0: return Vector2i(x, y)
		1: return Vector2i(x, 15 - y)
		2: return Vector2i(15 - x, 15 - y)
	return Vector2i(15 - x, y)


## Small tufts on grassy ground, pebbles on earth and sand: enough to break the flat fill.
static func _texture(owner: Object, image: Image, tile: Vector2i, pos: Vector2i, me: Dictionary) -> void:
	var h := hash2(tile.x * 3 + 7, tile.y * 5 + 1)
	for k in 2:
		var hk := hash2(h, k)
		if hk % 3 == 0:
			continue
		var at := Vector2i(2 + hk % 11, 3 + (hk >> 5) % 11)
		var base := image.get_pixelv(pos + at)
		if me.grassy:
			image.set_pixelv(pos + at, base.lightened(0.08))
			image.set_pixelv(pos + at + Vector2i(2, 0), base.lightened(0.08))
			image.set_pixelv(pos + at + Vector2i(1, 1), base.darkened(0.1))
			if (hk >> 9) % 17 == 0:
				image.set_pixelv(pos + at + Vector2i(1, -1), Palette.PAPER_LIGHT if (hk >> 14) % 2 == 0 else Palette.GOLD.lightened(0.2))
		elif me.rank >= 1:
			image.set_pixelv(pos + at, base.lightened(0.07))
			image.set_pixelv(pos + at + Vector2i(1, 0), base.darkened(0.12))


## Shade at the foot of a bank (the face above falls here) and east of raised ground.
static func _shade(owner: Object, image: Image, tile: Vector2i, pos: Vector2i, level: int) -> void:
	var north: int = info(owner, tile + Vector2i.UP).level - level
	var west: int = info(owner, tile + Vector2i.LEFT).level - level
	var corner: int = info(owner, tile + Vector2i(-1, -1)).level - level
	if north <= 0 and west <= 0 and corner <= 0:
		return
	var reach_y := mini(7, 2 + north * 2) if north > 0 else 0
	var reach_x := mini(7, 2 + west * 2) if west > 0 else 0
	var rows := 16 if west > 0 else (reach_y if north > 0 else 6)
	var cols := 16 if north > 0 else (reach_x if west > 0 else 6)
	for y in rows:
		for x in cols:
			var dark := 0.0
			if north > 0 and y < reach_y:
				dark = 0.26 * (1.0 - float(y) / reach_y)
			if west > 0 and x < reach_x:
				dark = maxf(dark, 0.22 * (1.0 - float(x) / reach_x))
			if corner > 0 and north <= 0 and west <= 0 and x + y < 6:
				dark = maxf(dark, 0.2 * (1.0 - (x + y) / 6.0))
			if dark > 0.0:
				image.set_pixel(pos.x + x, pos.y + y, image.get_pixel(pos.x + x, pos.y + y).darkened(dark))
	return


## A natural bank's face below `tile`: rock in lit and shaded facets, staggered ledges, a turf lip with a
## shadow under it, vines hanging from grassy tops, and a darker foot. `base` is the face colour.
static func bank(owner: Object, image: Image, tile: Vector2i, at: Vector2i, drop: int, base: Color) -> void:
	var top: Dictionary = info(owner, tile).material
	var grassy: bool = top.get("grassy", false)
	var level: int = info(owner, tile).level
	# Where the face ends beside a shorter one, its edge turns: lit on the left, shaded on the right.
	var mine: int = level - info(owner, tile + Vector2i.DOWN).level
	var west_face: int = info(owner, tile + Vector2i.LEFT).level - info(owner, tile + Vector2i(-1, 1)).level
	var east_face: int = info(owner, tile + Vector2i.RIGHT).level - info(owner, tile + Vector2i(1, 1)).level
	var shift := hash2(tile.y, 9) % 7
	for fx in 16:
		var wx := tile.x * 16 + fx
		var lip := 1 + int(wave(wx, tile.y * 7 + 3, 3) * 2.5)
		if grassy and hash2(wx, tile.y) % 23 == 0:
			lip += 2 + hash2(wx, tile.y + 1) % 3
		var block := floori((wx + shift) / 6.0)
		var in_block := (wx + shift) % 6
		var facet := float(hash2(block, tile.y) % 100) / 100.0
		var stagger := hash2(block, tile.y + 2) % 5
		var period := 5 + hash2(block, tile.y + 4) % 4
		var turf: Color = _pixel(owner, top, fx, 15) if top.order >= 0 else base.lightened(0.15)
		for fy in drop:
			var col := base.lightened(0.1)
			if in_block == 0:
				col = col.lightened(0.08)
			elif in_block == 5:
				col = col.darkened(0.1)
			col = col.darkened(facet * 0.08 + float(fy) / drop * 0.16)
			var ledge := (fy + stagger) % period
			if ledge == 0:
				col = col.lightened(0.1)
			elif ledge == 1:
				col = col.darkened(0.12)
			if hash2(wx, fy + tile.y * 31) % 37 == 0:
				col = col.darkened(0.18)
			if fx == 0 and west_face < mine:
				col = col.lightened(0.12)
			elif fx == 15 and east_face < mine:
				col = col.darkened(0.2)
			if fy < lip:
				col = turf.darkened(0.12) if fy == lip - 1 else turf
			elif fy == lip:
				col = col.darkened(0.22)
			if fy == drop - 1:
				col = col.darkened(0.18)
			image.set_pixel(at.x + fx, at.y + fy, col)
	if not grassy:
		return
	# Vines: a strand from the lip with a leaf every few pixels, alternating sides.
	var vine := Palette.GREEN.darkened(0.35)
	for fx in range(1, 15):
		var wx := tile.x * 16 + fx
		if hash2(wx, tile.y * 3) % 31 != 0:
			continue
		var length := 4 + hash2(wx, tile.y * 5) % maxi(1, drop - 3)
		for fy in range(2, mini(length, drop - 1)):
			image.set_pixel(at.x + fx, at.y + fy, vine)
			if fy % 3 == 1:
				var side := -1 if (fy / 3) % 2 == 0 else 1
				image.set_pixel(at.x + fx + side, at.y + fy, vine.lightened(0.12))


## A built terrace wall below `tile`: coursed stone blocks, each lit on top and shaded beneath, the
## whole wall darker toward its foot, moss along the top where grass is above. Stairs are treads and risers.
static func wall(owner: Object, image: Image, tile: Vector2i, at: Vector2i, drop: int, steps: bool) -> void:
	var stone := Palette.STONE.darkened(0.3)
	var top: Dictionary = info(owner, tile).material
	var mossy: bool = top.get("grassy", false)
	if steps:
		# Risers: shaded stone, darkest just under each nosing, a little lighter toward the next tread.
		# A tall riser is a flight: steps of six texels, each with its own lit nosing.
		var flight := 6 if drop > 12 else drop
		for fy in drop:
			var in_step := fy % flight
			var col := stone.darkened(0.12 - float(in_step) / flight * 0.1)
			if in_step == 0:
				col = stone.darkened(0.35) if fy == 0 else stone.lightened(0.14)
			elif in_step == 1 and fy > 1:
				col = stone.darkened(0.3)
			col = col.darkened(float(fy) / drop * 0.1)
			for fx in 16:
				var c := col.darkened(0.06) if hash2(tile.x * 16 + fx, tile.y * 13 + fy) % 29 == 0 else col
				image.set_pixel(at.x + fx, at.y + fy, c)
		return
	var course := 6
	for fy in drop:
		var row := fy / course
		var in_row := fy % course
		for fx in 16:
			var wx := tile.x * 16 + fx + (row % 2) * 5
			var in_block := wx % 10
			var col := stone.darkened(float(hash2(floori(wx / 10.0), tile.y * 8 + row) % 100) / 100.0 * 0.08)
			if in_row == 0:
				col = col.lightened(0.16)
			elif in_row == course - 1:
				col = col.darkened(0.2)
			elif not steps and in_block == 0:
				col = col.darkened(0.22)
			elif not steps and in_block == 1:
				col = col.lightened(0.06)
			col = col.darkened(float(fy) / drop * 0.2)
			if mossy and fy < 1 + int(wave(tile.x * 16 + fx, tile.y * 5 + 1, 4) * 2.5):
				col = Palette.GREEN.darkened(0.25)
			image.set_pixel(at.x + fx, at.y + fy, col)


## A ramp of earth steps cut into a bank: lit treads, shaded risers, darker toward the foot, with
## stone cheeks where the cut ends beside uncut bank.
static func steps(image: Image, at: Vector2i, drop: int, cheek_left: bool, cheek_right: bool) -> void:
	var tread := Palette.EARTH.darkened(0.08)
	for fy in drop:
		var in_step := fy % 4
		var col := tread.lightened(0.12) if in_step == 0 else (tread.darkened(0.28) if in_step == 3 else tread)
		col = col.darkened(float(fy) / drop * 0.12)
		for fx in 16:
			var c := col
			if (cheek_left and fx < 2) or (cheek_right and fx > 13):
				c = Palette.STONE.darkened(0.3 if fx < 8 else 0.42).darkened(float(fy) / drop * 0.15)
			image.set_pixel(at.x + fx, at.y + fy, c)
