extends RefCounted
## Task-local sampler and image drawing; shared resources are read-only.
const SIDE := 64
const TILE := 32.0
const SHADES := 9
const BANDS := 9
var sect := preload("res://src/sect_ground.gd").new()
var hunting: RefCounted
var world: RefCounted
const SEA := 0.5
const TERRACE := 0.02
const E := 24.0
var exaggeration := E
var atlas_image: Image
var mountain := FastNoiseLite.new()
var height_cache: Dictionary = {}
var baking := false
var pending: Dictionary = {}
var max_level := 0
var noise := FastNoiseLite.new()
var woodland := FastNoiseLite.new()
var covers := ["deep water", "shallow water", "river", "sand", "bare rock", "snow", "tundra", "marsh", "desert", "steppe", "grass", "tufts", "flowers", "tree", "autumn tree", "spirit tree", "bamboo", "rock", "bush", "stump"]
const Palette = preload("res://src/palette.gd")


func _hash(x: int, y: int) -> int:
	var value := (x * 374761393 + y * 668265263 + noise.seed) & 0x7fffffff
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return value ^ (value >> 16)


func _blend(p: Vector2, mask: bool = false) -> float:
	var q := p - Vector2.ONE * 0.5
	var cell := Vector2i(q.floor())
	var f := q - Vector2(cell)
	var values: Array[float] = []
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
		var at: Vector2i = cell + offset
		var i: int = clampi(at.y, 0, world.h - 1) * world.w + clampi(at.x, 0, world.w - 1)
		values.append(float(world.water[i] != 0) if mask else world._height(at.x, at.y))
	return lerpf(lerpf(values[0], values[1], f.x), lerpf(values[2], values[3], f.x), f.y)


func _sea(p: Vector2) -> bool:
	return _blend(p, true) > 0.5 or _blend(p) + noise.get_noise_2dv(p * 2.0) * 0.012 < 0.5


func sample(tile: Vector2i) -> Dictionary:
	var p := (Vector2(tile) + Vector2.ONE * 0.5) / 16.0
	var elevation := _blend(p)
	var kind := -1
	if _sea(p):
		kind = 0 if elevation < 0.46 else 1
	else:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			if _sea(p + offset / 16.0):
				kind = 3
		if _river_distance(p) < 0.0:
			kind = 2
	var warped := p + Vector2(noise.get_noise_2dv(p * 1.3), noise.get_noise_2dv(p * 1.3 + Vector2(51, 83))) * 0.9
	var b: int = world.biome[clampi(int(warped.y), 0, world.h - 1) * world.w + clampi(int(warped.x), 0, world.w - 1)]
	var cover: String = str(world.data.biome_names[b]).to_lower()
	if kind < 0:
		kind = {0: 0, 1: 1, 2: 1, 3: 3, 8: 8, 9: 9, 10: 7, 11: 9, 12: 4, 13: 5, 14: 6, 15: 5}.get(b, 10)
	else:
		cover = covers[kind]
	# The same global height function is used on both sides of chunk boundaries.
	var height := ground_height(tile)
	var west := ground_height(tile + Vector2i.LEFT)
	var east := ground_height(tile + Vector2i.RIGHT)
	var north := ground_height(tile + Vector2i.UP)
	var south := ground_height(tile + Vector2i.DOWN)
	var gradient := Vector2(east - west, south - north) * 8.0
	var steep := gradient.length()
	var light := clampf(1.0 - (gradient.x + gradient.y) * 3.5, 0.7, 1.3)
	# Downhill south/east edges read as exposed dark rock faces.
	var cliff := steep > 0.12
	if cliff and kind > 3:
		kind = 4
		light *= 0.72 if gradient.x + gradient.y < 0.0 else 0.9
	if kind > 3:
		if height > 0.92 + noise.get_noise_2dv(p * 4.0) * 0.01:
			kind = 5
		elif height > 0.82 + noise.get_noise_2dv(p * 4.0) * 0.015:
			kind = 4
	var band := clampi(roundi((height - 0.52 + noise.get_noise_2dv(p * 7.0) * 0.018) / 0.06), 0, BANDS - 1)
	var decoration := -1
	var chance := float(_hash(tile.x, tile.y) % 1000) / 1000.0
	var density := smoothstep(-0.35, 0.45, woodland.get_noise_2dv(p))
	var forest := b in [5, 6, 7]
	var trees := smoothstep(0.28 if forest else 0.63, 0.8, density)
	if b == 11:
		trees = smoothstep(0.3, 0.8, density) * (1.0 - smoothstep(0.05, 0.12, steep))
	trees *= 1.0 - smoothstep(0.76, 0.83, height)
	if kind > 3 and kind != 8 and height < 0.84 and not cliff and chance < trees * 0.85:
		decoration = 16 if b == 11 else (15 if b == 6 else (14 if b == 7 else 13))
	elif kind > 3:
		# Coherent outcrops plus shared 2x2 patch decisions make boulder groups.
		var patch := float(_hash(floori(tile.x / 2.0), floori(tile.y / 2.0)) % 1000) / 1000.0
		var outcrop := smoothstep(0.04, 0.12, steep) * 0.15 + smoothstep(0.82, 0.92, height) * 0.2
		if patch < outcrop and chance < 0.8:
			decoration = 17 if chance < 0.4 else 19
	if sect.has_tile(tile):
		decoration = -1
		kind = 10
		light = 1.0
		cover = sect.surface_at(tile)
	elif sect.height_at(tile) > 0.0:
		var skirt_patch := woodland.get_noise_2dv(Vector2(tile) * 0.3)
		if skirt_patch > 0.12 and chance < 0.36:
			decoration = 16
		elif skirt_patch < -0.25 and chance < 0.3:
			decoration = 17
		elif decoration in [13, 14, 15]:
			decoration = 16
	var shade := clampi(roundi((light - 0.5) / 0.125), 0, SHADES - 1) if kind > 2 else 4
	return {"kind": kind, "decoration": decoration, "shade": shade, "band": band if kind > 2 else 0, "cover": covers[kind] if kind in [4, 5] else cover, "height": height, "level": terrace_level(tile)}


func _river_distance(p: Vector2) -> float:
	var nearest := 100.0
	var cell := Vector2i(p.floor())
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var at := cell + Vector2i(dx, dy)
			if not world._inside(at):
				continue
			var i: int = at.y * world.w + at.x
			if world.rivers[i] == 0 or world.directions[i] > 7:
				continue
			var start := Vector2(at) + Vector2.ONE * 0.5
			var end := start + Vector2(world.DIRECTIONS[world.directions[i]])
			var distance := p.distance_to(Geometry2D.get_closest_point_to_segment(p, start, end)) * 16.0
			nearest = minf(nearest, distance + noise.get_noise_2dv(p * 9.0) * 0.4 - (0.6 + world.rivers[i] / 10.0 * 0.9))
	return nearest


func ground_height(tile: Vector2i) -> float:
	if baking and height_cache.has(tile):
		return height_cache[tile]
	# Inside the full mountain override, natural height contributes zero.
	# Avoid evaluating the river/noise sampler just to discard its result.
	if sect.hunting.cached_weight(tile) >= 1.0:
		var overridden: float = sect.hunting.cached_height(tile, 0.0)
		var level: int = sect.level_at(tile)
		if level >= 0:
			overridden = SEA + level * TERRACE
		if baking:
			height_cache[tile] = overridden
		return overridden
	var p := (Vector2(tile) + Vector2.ONE * 0.5) / 16.0
	var base := _blend(p)
	var height := base
	if not _sea(p):
		var river := _river_distance(p)
		var ridge := pow(1.0 - absf(mountain.get_noise_2dv(p)), 2.0)
		var relief := noise.get_noise_2dv(p * 1.2) * 0.012
		relief += (ridge - 0.45) * 0.10 * smoothstep(SEA + 0.12, SEA + 0.32, base)
		height += relief * smoothstep(0.0, 5.0, river) * smoothstep(SEA, SEA + 0.06, base)
	else:
		var cell := Vector2i(p.floor())
		var i: int = clampi(cell.y, 0, world.h - 1) * world.w + clampi(cell.x, 0, world.w - 1)
		height = SEA if world.water[i] == 1 else world._height(cell.x, cell.y)
	if sect.height_at(tile) > 0.0:
		height = maxf(height, sect.height_at(tile))
	if sect.has_method("site_height"):
		height = sect.site_height(tile, height)
	if sect.level_at(tile) >= 0:
		height = SEA + sect.level_at(tile) * TERRACE
	if baking:
		height_cache[tile] = height
	return height


func terrace_level(tile: Vector2i) -> int:
	if sect.level_at(tile) >= 0:
		return sect.level_at(tile)
	return _smoothed_level(sect.plinth.get(tile, tile))


func _raw_level(tile: Vector2i) -> int:
	return maxi(0, floori((ground_height(tile) - SEA) / TERRACE))


## A lone tile above or below all four neighbours is noise, not a terrace: it would draw as a stray slab of cliff.
func _smoothed_level(tile: Vector2i) -> int:
	var level := _raw_level(tile)
	var up := _raw_level(tile + Vector2i.UP)
	var down := _raw_level(tile + Vector2i.DOWN)
	var left := _raw_level(tile + Vector2i.LEFT)
	var right := _raw_level(tile + Vector2i.RIGHT)
	# A ridge or groove one tile thin, either way, is levelled with the higher side of its neighbours.
	if level > maxi(left, right): level = maxi(left, right)
	elif level < mini(left, right): level = mini(left, right)
	if level > maxi(up, down): level = maxi(up, down)
	elif level < mini(up, down): level = mini(up, down)
	return level


func _bake_row(key: Vector2i, y: int) -> void:
	var image: Image = pending.image
	for x in SIDE:
		var tile := key * SIDE + Vector2i(x, y)
		var info := sample(tile)
		var level: int = info.level
		var top := y * 16 + int(pending.overflow) - roundi(level * exaggeration / 2.0)
		var south := terrace_level(tile + Vector2i.DOWN)
		var drop := roundi((level - south) * exaggeration / 2.0) if info.kind > 2 else 0
		pending.min_y = mini(pending.min_y, top)
		pending.max_y = maxi(pending.max_y, top + 16 + maxi(0, drop))
		if drop > 0:
			# Natural ground keeps low contrast and no outline: a slope is a soft turf shade. Only built terraces (below) are walls of stone.
			var face := Palette.GRASS.darkened(0.16).lerp(Palette.GREEN.darkened(0.3), sect.hunting.cached_weight(tile))
			if sect.surface_at(tile) == "field": face = Palette.EARTH.darkened(0.22)
			image.fill_rect(Rect2i(x * 16, top + 16, 16, drop), face)
			if sect.level_at(tile) >= 0:
				var steps: bool = sect.surface_at(tile) == "stairs"
				var stone := Palette.STONE.darkened(0.3)
				image.fill_rect(Rect2i(x * 16, top + 16, 16, drop), stone)
				for seam in range(0, drop, 3 if steps else 6):
					image.fill_rect(Rect2i(x * 16, top + 16 + seam, 16, 1), stone.darkened(0.22))
					image.fill_rect(Rect2i(x * 16, top + 17 + seam, 16, 1), stone.lightened(0.12))
					if not steps:
						image.fill_rect(Rect2i(x * 16 + (4 if seam % 12 == 0 else 12), top + 16 + seam, 1, mini(6, drop - seam)), stone.darkened(0.22))
		var source := Rect2i(int(info.kind) * 16, (int(info.shade) + int(info.band) * SHADES) * 16, 16, 16)
		image.blit_rect(atlas_image, source, Vector2i(x * 16, top))
		if info.kind > 2 and level > terrace_level(tile + Vector2i.RIGHT):
			image.fill_rect(Rect2i(x * 16 + 15, top, 1, 16), Palette.GRASS.darkened(0.2))
		if info.kind > 2 and level > terrace_level(tile + Vector2i.LEFT):
			image.fill_rect(Rect2i(x * 16, top, 1, 16), Palette.GRASS.darkened(0.2))
		sect.draw_tile(image, tile, Vector2i(x * 16, top))
		hunting.draw(image, tile, Vector2i(x * 16, top), sect.has_tile(tile))
		if info.decoration >= 0 and sect.hunting.cached_weight(tile) < 0.25:
			image.blend_rect(atlas_image, Rect2i(int(info.decoration) * 16, int(info.shade) * 16, 16, 16), Vector2i(x * 16, top))

func bake(key: Vector2i) -> void:
	var started := Time.get_ticks_usec()
	var overflow := ceili(max_level * exaggeration / 2.0) + 16
	pending = {"overflow": overflow, "image": Image.create(1024, 1024 + overflow, false, Image.FORMAT_RGBA8), "min_y": 1024 + overflow, "max_y": 0}
	baking = true
	hunting.prepare_chunk(key)
	for y in SIDE:
		_bake_row(key, y)
	pending.image = pending.image.get_region(Rect2i(0, pending.min_y, 1024, int(pending.max_y) - int(pending.min_y)))
	pending.elapsed = (Time.get_ticks_usec() - started) / 1000.0

var far_colors: Array[Color] = []

func bake_far(key: Vector2i) -> void:
	var started := Time.get_ticks_usec()
	pending = {"image": _far_image(key), "elapsed": (Time.get_ticks_usec() - started) / 1000.0}

func _far_image(key: Vector2i) -> Image:
	var image := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	# Sample displaced source rows too, so elevated tops crossing a chunk edge
	# belong to the destination chunk and leave no transparent seams.
	baking = true
	# FAR interpolates deterministic terrain samples on a 16-tile grid.
	# Dense sect overrides remain per tile; detailed rendering is unchanged.
	var rows := SIDE + ceili(max_level * exaggeration / TILE) + 1
	var heights := PackedFloat32Array()
	var colors := PackedColorArray()
	var kinds := PackedInt32Array()
	for gy in range(ceili(rows / 16.0) + 1):
		for gx in 5:
			var info := sample(key * SIDE + Vector2i(gx * 16, gy * 16))
			heights.append(info.height)
			colors.append(far_colors[(info.band * SHADES + info.shade) * 20 + info.kind])
			kinds.append(info.kind)
	for y in range(rows):
		for x in SIDE:
			var tile := key * SIDE + Vector2i(x, y)
			var index := (y / 16) * 5 + x / 16
			var height := lerpf(lerpf(heights[index], heights[index + 1], (x % 16) / 16.0), lerpf(heights[index + 5], heights[index + 6], (x % 16) / 16.0), (y % 16) / 16.0)
			var level: int = sect.level_at(tile)
			if level < 0:
				var skirt: float = sect.height_at(tile)
				level = maxi(0, floori((maxf(height, skirt) - SEA) / TERRACE))
			var top := y - roundi(level * exaggeration / TILE)
			var col: Color = colors[index]
			if kinds[index] > 3 and kinds[index] != 8 and height < 0.84 and float(_hash(tile.x, tile.y) % 1000) / 1000.0 < smoothstep(0.28, 0.8, smoothstep(-0.35, 0.45, woodland.get_noise_2dv((Vector2(tile) + Vector2.ONE * 0.5) / 16.0))) * 0.55:
				col = Palette.GREEN.darkened(0.4)
			if sect.has_tile(tile):
				col = sect.far_color(tile)
			var forest_index: int = sect.hunting.cache_index(tile)
			var forest_weight: float = sect.hunting.weights[forest_index] if forest_index >= 0 else 0.0
			if forest_weight > 0.0 and not sect.has_tile(tile):
				var forest_color: Color = sect.hunting.shades[forest_index]
				if sect.hunting.flags[forest_index] == 0:
					forest_color *= 0.76 + preload("res://src/hunting_ground.gd").hash_at(tile.x, tile.y) % 100 / 500.0
				forest_color.a = 1.0
				col = col.lerp(forest_color, forest_weight)
				# Far LOD uses cached colour, relief and noise, without crown or trail geometry.
				level = maxi(0, floori((height * (1.0 - forest_weight) + sect.hunting.elevations[forest_index] - SEA) / TERRACE))
				top = y - roundi(level * exaggeration / TILE)
			var face_start := maxi(0, top + 1)
			var face_end := mini(SIDE, y + 2)
			if face_end > face_start:
				image.fill_rect(Rect2i(x, face_start, 1, face_end - face_start), col.darkened(0.3))
			if top >= 0 and top < SIDE:
				image.set_pixel(x, top, col)
	baking = false
	height_cache.clear()
	return image
