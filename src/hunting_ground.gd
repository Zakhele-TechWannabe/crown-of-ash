extends RefCounted
## World-coordinate foliage and local segment buckets; immutable during worker baking.
var segments: Dictionary = {}
var crown_atlas: Array[Image] = []
var floor_atlas: Array[Image] = []
var crown_cache: Dictionary = {}
var candidates: Dictionary = {}
var render_tiles: Dictionary = {}
var prepared := false
const CACHE_ORIGIN := Vector2i(1376, 1976)
const CACHE_SIZE := Vector2i(849, 669)
var weights := PackedFloat32Array()
var elevations := PackedFloat32Array()
var shades := PackedColorArray()
var flags := PackedByteArray()
const Palette = preload("res://src/palette.gd")

func cache_index(tile: Vector2i) -> int:
	var at := tile - CACHE_ORIGIN
	return at.y * CACHE_SIZE.x + at.x if at.x >= 0 and at.y >= 0 and at.x < CACHE_SIZE.x and at.y < CACHE_SIZE.y else -1

func cached_weight(tile: Vector2i) -> float:
	var i := cache_index(tile)
	return weights[i] if i >= 0 else 0.0

func cached_height(tile: Vector2i, natural: float) -> float:
	var i := cache_index(tile)
	return natural * (1.0 - weights[i]) + elevations[i] if i >= 0 else natural

func cached_color(tile: Vector2i) -> Color:
	return shades[cache_index(tile)]

func cached_flag(tile: Vector2i, bit: int) -> bool:
	var i := cache_index(tile)
	return i >= 0 and (flags[i] & bit) != 0

func build_samples() -> void:
	# Bounded packed maps (~14 MiB), shared by all worker copies.
	var count := CACHE_SIZE.x * CACHE_SIZE.y
	weights.resize(count)
	elevations.resize(count)
	shades.resize(count)
	flags.resize(count)
	for y in CACHE_SIZE.y:
		for x in CACHE_SIZE.x:
			var at := CACHE_ORIGIN + Vector2i(x, y)
			var i := y * CACHE_SIZE.x + x
			var w := weight(at)
			weights[i] = w
			if w <= 0:
				continue
			elevations[i] = mountain_height(at, 0)
			flags[i] = (1 if clearing(at) else 0) | (2 if rocky(at) else 0)

	# Reuse packed heights for hillshade instead of evaluating four neighbours again.
	for y in CACHE_SIZE.y:
		for x in CACHE_SIZE.x:
			var at := CACHE_ORIGIN + Vector2i(x, y)
			var i := y * CACHE_SIZE.x + x
			if weights[i] <= 0:
				continue
			var col := Palette.JADE.darkened(0.7).lerp(Palette.GREEN.darkened(0.5), (field(Vector2(at), 23) + 1) * 0.5)
			if (flags[i] & 1) != 0:
				col = Palette.GREEN.darkened(0.35)
			if (flags[i] & 2) != 0:
				col = Palette.STONE.darkened(0.6) * (0.8 + (field(Vector2(at), 6) + 1) * 0.24)
			var dx := cached_height(at + Vector2i(3, 0), 0.8) - cached_height(at - Vector2i(3, 0), 0.8)
			var dy := cached_height(at + Vector2i(0, 3), 0.8) - cached_height(at - Vector2i(0, 3), 0.8)
			col *= clampf(1.0 - (dx + dy) * 12.0, 0.55, 1.4)
			col.a = 1
			shades[i] = col

func worker_copy() -> RefCounted:
	var copy := new()
	copy.weights = weights
	copy.elevations = elevations
	copy.shades = shades
	copy.flags = flags
	copy.segments = segments
	copy.crown_atlas = crown_atlas
	copy.floor_atlas = floor_atlas
	return copy

func crowns_at(cell: Vector2i) -> Array:
	if crown_cache.has(cell):
		return crown_cache[cell]
	var result: Array = []
	for cy in range(cell.y - 2, cell.y + 3):
		for cx in range(cell.x - 2, cell.x + 3):
			var key := Vector2i(cx, cy)
			if not candidates.has(key):
				var h := hash_at(cx, cy)
				var center := Vector2(cx * 3 + (h % 1000) / 333.0, cy * 3 + ((h >> 10) % 1000) / 333.0)
				var radius := 1.0 + ((h >> 7) % 1000) / 666.0
				var at := Vector2i(center)
				var valid := h % 1000 <= cached_weight(at) * 960 and not cached_flag(at, 1) and not cached_flag(at, 2) and trail(center, segments.get(Vector2i(floori(center.x / 16.0), floori(center.y / 16.0)), [])) <= 0.1
				candidates[key] = [center, radius, h] if valid else []
			if not candidates[key].is_empty():
				result.append(candidates[key])
	result.sort_custom(func(a: Array, b: Array) -> bool: return a[0].x < b[0].x if a[0].y == b[0].y else a[0].y < b[0].y)
	crown_cache[cell] = result
	return result

func prepare_chunk(key: Vector2i) -> void:
	prepared = true
	render_tiles.clear()
	var low := key * 64
	if not Rect2i(low, Vector2i(64, 64)).intersects(Rect2i(CACHE_ORIGIN, CACHE_SIZE)):
		return
	var trees: Array = []
	for cy in range(floori((low.y - 6) / 3.0), ceili((low.y + 70) / 3.0)):
		for cx in range(floori((low.x - 6) / 3.0), ceili((low.x + 70) / 3.0)):
			# crowns_at populates the candidate cache once per world cell.
			var cell := Vector2i(cx, cy)
			if not candidates.has(cell):
				crowns_at(cell)
			if not candidates[cell].is_empty():
				trees.append(candidates[cell])
	trees.sort_custom(func(a: Array, b: Array) -> bool: return a[0].x < b[0].x if a[0].y == b[0].y else a[0].y < b[0].y)
	for crown: Array in trees:
		var center: Vector2 = crown[0] * 16.0
		var origin := Vector2i(center.round()) - Vector2i(48, 48)
		var seed: int = crown[2]
		var variant := 0 if seed % 67 == 0 else 1 + seed % 23
		var size := clampi(roundi((float(crown[1]) - 1.0) / 0.75), 0, 2)
		var extent := float(crown[1]) * 20 + 12
		for y in range(maxi(low.y, floori((center.y - extent) / 16)), mini(low.y + 64, ceili((center.y + extent) / 16))):
			for x in range(maxi(low.x, floori((center.x - extent) / 16)), mini(low.x + 64, ceili((center.x + extent) / 16))):
				var tile := Vector2i(x, y)
				if center.distance_squared_to(Vector2(tile * 16) + Vector2(8, 8)) > extent * extent:
					continue
				var clipped := Rect2i(tile * 16, Vector2i(16, 16)).intersection(Rect2i(origin, Vector2i(96, 96)))
				if not clipped.has_area():
					continue
				if not render_tiles.has(tile):
					render_tiles[tile] = []
				render_tiles[tile].append([Rect2i(clipped.position - origin, clipped.size), clipped.position - tile * 16, size * 24 + variant])

func build_atlas() -> void:
	# 72 small transparent crowns, shared read-only by workers (~2 MiB).
	for size in 3:
		for variant in 24:
			var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
			var radius := 16.0 + size * 12.0
			var tint := Palette.JADE.darkened(0.7).lerp(Palette.GREEN.darkened(0.55), variant / 24.0)
			if variant == 0:
				tint = Palette.STONE.darkened(0.65)
			for step in ceili(radius):
				for side in [-1, 0, 1]:
					image.set_pixel(48 + roundi(step * side * 0.36), 48 + step, Palette.EARTH.darkened(0.7))
			for blob in range(3 + variant % 4):
				var bh := hash_at(variant, blob)
				var center := Vector2(48, 48) + Vector2(cos(bh % 628 / 100.0), sin(bh % 628 / 100.0)) * radius * 0.46
				var r := radius * (0.48 + bh % 29 / 100.0)
				for y in range(maxi(0, ceili(center.y - r)), mini(96, floori(center.y + r) + 1)):
					var dy := (y + 0.5 - center.y) / r
					var span := sqrt(maxf(0, 1 - dy * dy)) * r
					for x in range(maxi(0, ceili(center.x - span)), mini(96, ceili(center.x + span))):
						var band := clampi(floori((x - center.x + r) / (r * 0.5)), 0, 3)
						var col := tint * clampf(1.13 - band * 0.12 - dy * 0.2, 0.6, 1.3)
						col.a = 1
						image.set_pixel(x, y, col)
			crown_atlas.append(image)
	for variant in 24:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var h := hash_at(x + variant * 16, y)
				var shift := (h % 17 - 7) / 100.0
				image.set_pixel(x, y, Color(1, 1, 1, shift * 0.2) if shift > 0 else Color(0, 0, 0, -shift))
		floor_atlas.append(image)

static func hash_at(x: int, y: int) -> int:
	var h := (x * 374761393 + y * 668265263 + 718) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return h ^ (h >> 16)

static func field(p: Vector2, scale: float) -> float:
	var q := p / scale
	var c := Vector2i(q.floor())
	var f := q - Vector2(c)
	f = f * f * (Vector2.ONE * 3.0 - f * 2.0)
	return lerpf(lerpf(hash_at(c.x, c.y) % 1000 / 500.0 - 1.0, hash_at(c.x + 1, c.y) % 1000 / 500.0 - 1.0, f.x), lerpf(hash_at(c.x, c.y + 1) % 1000 / 500.0 - 1.0, hash_at(c.x + 1, c.y + 1) % 1000 / 500.0 - 1.0, f.x), f.y)

static func weight(tile: Vector2i) -> float:
	if tile.x < 1380 or tile.x > 2220 or tile.y < 1980 or tile.y > 2640:
		return 0.0
	var p := Vector2(tile)
	var q := (p - Vector2(1800, 2310)) / Vector2(310, 211)
	var edge := (1.0 - pow(pow(absf(q.x), 2.7) + pow(absf(q.y), 2.7), 1.0 / 2.7)) * 200.0
	edge += field(p, 73.0) * 34.0 + field(p, 27.0) * 13.0
	return smoothstep(-16, 12, edge)

static func mountain_height(tile: Vector2i, natural: float) -> float:
	var w := weight(tile)
	if w <= 0.0:
		return natural
	var p := Vector2(tile)
	var rise := clampf((tile.x - 1515) / 480.0, 0, 1)
	var ridge := 0.045 * cos((tile.y - 2320) / 75.0) + field(p, 81) * 0.028
	var ravine := exp(-pow((tile.y - 2220 - field(Vector2(tile.x, 0), 95) * 36) / 13.0, 2)) * 0.075
	return lerpf(natural, 0.70 + rise * 0.53 + ridge - ravine, w)

static func clearing(tile: Vector2i) -> bool:
	for at: Vector2 in [Vector2(1610, 2350), Vector2(1740, 2290), Vector2(1870, 2340), Vector2(1987, 2378)]:
		if Vector2(tile).distance_to(at) < 9 + field(Vector2(tile), 5) * 4:
			return true
	return false

static func rocky(tile: Vector2i) -> bool:
	var summit := (Vector2(tile) - Vector2(1994, 2342)) / Vector2(42, 69)
	return (tile.x > 1960 and summit.length() < 1.0 + field(Vector2(tile), 19) * 0.32 and mountain_height(tile, 0.8) > 1.20) or Vector2(tile - Vector2i(1855, 2190)).length() < 9 + field(Vector2(tile), 6) * 5


static func color(tile: Vector2i) -> Color:
	var p := Vector2(tile)
	var col := Palette.JADE.darkened(0.7).lerp(Palette.GREEN.darkened(0.5), (field(p, 23) + 1) * 0.5)
	if clearing(tile):
		col = Palette.GREEN.darkened(0.35)
	if rocky(tile):
		col = Palette.STONE.darkened(0.6) * (0.8 + (field(p, 6) + 1.0) * 0.24)
	var dx := mountain_height(tile + Vector2i(3, 0), 0.8) - mountain_height(tile - Vector2i(3, 0), 0.8)
	var dy := mountain_height(tile + Vector2i(0, 3), 0.8) - mountain_height(tile - Vector2i(0, 3), 0.8)
	col *= clampf(1.0 - (dx + dy) * 12.0, 0.55, 1.4)
	col.a = 1.0
	return col

func setup() -> void:
	build_samples()
	build_atlas()
	if not FileAccess.file_exists("res://data/roads/hunting_trails.json"):
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/roads/hunting_trails.json"))
	for path: Dictionary in data.paths:
		for i in range(path.points.size() - 1):
			var a := Vector2(path.points[i][0], path.points[i][1])
			var b := Vector2(path.points[i + 1][0], path.points[i + 1][1])
			for y in range(floori((minf(a.y, b.y) - 2) / 16), floori((maxf(a.y, b.y) + 2) / 16) + 1):
				for x in range(floori((minf(a.x, b.x) - 2) / 16), floori((maxf(a.x, b.x) + 2) / 16) + 1):
					var key := Vector2i(x, y)
					if not segments.has(key):
						segments[key] = []
					segments[key].append([a, b, float(path.width)])

func trail(p: Vector2, local: Array) -> float:
	var amount := 0.0
	for segment: Array in local:
		var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, segment[0], segment[1]))
		amount = maxf(amount, (1.0 - smoothstep(segment[2] * 0.5 - 0.07, segment[2] * 0.5 + 0.10, d)) * (1.0 if segment[2] > 1 else 0.45))
	return amount

func draw(image: Image, tile: Vector2i, pos: Vector2i, occupied: bool) -> void:
	var w := cached_weight(tile)
	if w <= 0.0 or occupied:
		return
	var clear := cached_flag(tile, 1)
	var rock := cached_flag(tile, 2)
	var base := cached_color(tile)
	if clear:
		base = base.lightened(maxf(0, field(Vector2(tile) + Vector2(0.5, 0.5), 2.7) - 0.25) * 0.22)
	var local: Array = []
	for segment: Array in segments.get(Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0)), []):
		if (Vector2(tile) + Vector2.ONE * 0.5).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(tile) + Vector2.ONE * 0.5, segment[0], segment[1])) < 1.6:
			local.append(segment)
	var bounds := Rect2i(pos, Vector2i(16, 16))
	# Native image blits replace pixel-level canopy blob evaluation.
	if w > 0.99:
		image.fill_rect(bounds, base)
	else:
		var ground := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		ground.fill(Color(base, w))
		image.blend_rect(ground, Rect2i(0, 0, 16, 16), pos)
	if w > 0.99:
		image.blend_rect(floor_atlas[hash_at(tile.x, tile.y) % 24], Rect2i(0, 0, 16, 16), pos)
	if rock:
		for yy in 16:
			for xx in 16:
				var p := Vector2(tile) + Vector2(xx + 0.5, yy + 0.5) / 16.0
				var col := base
				var seam := field(p, 3.8) + field(p, 1.7) * 0.35
				if absf(seam) < 0.028:
					col = col.darkened(0.3)
				elif seam > 0.4:
					col = col.lightened(0.09)
				var at := pos + Vector2i(xx, yy)
				image.set_pixelv(at, image.get_pixelv(at).lerp(col, w))
	if not clear and not rock:
		var detail := hash_at(tile.x, tile.y)
		if detail % 23 == 0:
			for step in 10:
				image.fill_rect(Rect2i(pos + Vector2i(2 + step, 4 + step / 2), Vector2i(2, 2)), Palette.EARTH.darkened(0.7))
		elif detail % 9 == 0:
			for step in 5:
				for side in [-1, 1]:
					image.fill_rect(Rect2i(pos + Vector2i(8 + side * step, 9 - step / 2), Vector2i(2, 1)), Palette.GREEN.darkened(0.45))
		# Crowns now stand up as tree sprites (ground_terrain.trees_in_block); the floor stays painted.
	# The packed-earth ribbon has subpixel coverage and a textured, soft edge.
	if not local.is_empty():
		for yy in 16:
			for xx in 16:
				var p := Vector2(tile) + Vector2(xx + 0.5, yy + 0.5) / 16.0
				var amount := trail(p, local)
				if amount <= 0:
					continue
				var h := hash_at(tile.x * 16 + xx, tile.y * 16 + yy)
				var col := Palette.INK.lightened(0.15) * (0.9 + h % 21 / 100.0)
				if h % 83 < 3:
					col = Palette.GRASS.darkened(0.7)
				col.a = 1.0
				var at := pos + Vector2i(xx, yy)
				image.set_pixelv(at, image.get_pixelv(at).lerp(col, amount * w))
