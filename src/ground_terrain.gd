extends Node2D
## Disposable chunks share one small atlas; samples never depend on visit order.
const Palette = preload("res://src/palette.gd")
const GroundPaint = preload("res://src/ground_paint.gd")
const TreeArt = preload("res://src/tree_art.gd")

const SIDE := 64
const TILE := 32.0
const LIMIT := 128
const SHADES := 9
const BANDS := 9
var sect := preload("res://src/sites_ground.gd").new()
var world: Node2D
const SEA := 0.5
const TERRACE := 0.02
const E := 24.0
var exaggeration := E
var atlas_image: Image
var mountain := FastNoiseLite.new()
var height_cache: Dictionary = {}
var tree_blocks: Dictionary = {}
var baking := false
var pending: Dictionary = {}
var jobs: Dictionary = {}
var generation := 0
var far_cache: Dictionary = {}
var far_lru: Array[Vector2i] = []
var detailed: Dictionary = {}
var snapshot: RefCounted
var far_colors: Array[Color] = []
var last_bake_ms := 0.0
var max_slice_ms := 0.0
var max_level := 0
var noise := FastNoiseLite.new()
var woodland := FastNoiseLite.new()
var chunks: Dictionary = {}
var wanted: Array[Vector2i] = []
var cached_low := Vector2i(-999, -999)
var cached_high := Vector2i(-999, -999)
var covers := ["deep water", "shallow water", "river", "sand", "bare rock", "snow", "tundra", "marsh", "desert", "steppe", "grass", "tufts", "flowers", "tree", "autumn tree", "spirit tree", "bamboo", "rock", "bush", "stump"]


func setup(map: Node2D) -> void:
	world = map
	noise.seed = str(world.data.seed).hash()
	noise.frequency = 0.25
	noise.fractal_octaves = 4
	woodland.seed = noise.seed ^ 0x35ab91
	woodland.frequency = 0.65
	woodland.fractal_octaves = 3
	mountain.seed = noise.seed ^ 0x712ac
	mountain.frequency = 0.2
	mountain.fractal_octaves = 3
	for i in range(0, world.heights.size(), 2):
		max_level = maxi(max_level, ceili((world.heights.decode_u16(i) / 30000.0 + 0.07 - SEA) / TERRACE))
	sect.setup(natural_dry)
	max_level = maxi(max_level, 45)
	_build_atlas()
	snapshot = preload("res://src/ground_snapshot.gd").new()
	for property: String in ["w", "h", "heights", "water", "biome", "rivers", "directions", "data"]:
		snapshot.set(property, world.get(property))
	for band in BANDS:
		for shade in SHADES:
			for kind in 20:
				far_colors.append(atlas_image.get_pixel(kind * 16 + 8, (shade + band * SHADES) * 16 + 8))


func _build_atlas() -> void:
	var ground_image := Palette.atlas("tiny-town", Palette.GROUND)
	var town_image := Palette.atlas("tiny-town", Palette.THING)
	var farm_image := Palette.atlas("tiny-farm", Palette.THING)
	var image := Image.create(20 * 16, SHADES * BANDS * 16, false, Image.FORMAT_RGBA8)
	var colors := [Palette.BLUE.darkened(0.3), Palette.BLUE, Palette.BLUE.lightened(0.12), Palette.EARTH.lightened(0.25), Palette.STONE.darkened(0.2), Palette.STONE.lightened(0.75), Palette.GRASS.lightened(0.2), Palette.GREEN.lightened(0.1), Palette.EARTH.lightened(0.1), Palette.GRASS.darkened(0.05)]
	var indices := [0, 1, 2, 4, 3, 5, 16, 77, 39, 89]
	for kind in 20:
		for row in SHADES * BANDS:
			var shade := row % SHADES
			var band := row / SHADES
			for y in 16:
				for x in 16:
					var col: Color
					if kind < 10:
						col = colors[kind]
						var speck := _hash(x + kind * 31, y) % 37
						if speck < 3:
							col = col.lightened(0.08) if kind < 3 else col.darkened(0.07)
						if kind == 7 and (x * 3 + y * 7) % 23 < 3:
							col = col.darkened(0.14)
					else:
						var index: int = indices[kind - 10]
						var source := farm_image if kind >= 17 else (ground_image if kind < 13 else town_image)
						col = source.get_pixel((index % 12) * 16 + x, (index / 12) * 16 + y)
						if kind == 15:
							col *= Color(0.55, 0.86, 0.8)
						elif kind == 16:
							# Readable evergreen silhouette for sheltered highland groves.
							col = Color.TRANSPARENT
							if y >= 11 and y <= 15 and x in [7, 8]:
								col = Palette.INK_SOFT.darkened(0.3)
							for tier in 3:
								var top := 1 + tier * 3
								if y >= top and y <= top + 5 and abs(x - 7) <= (y - top) / 2 + tier:
									col = Palette.JADE.darkened(0.45) if x < 8 else Palette.JADE.darkened(0.6)
					# Elevation palettes are shared by every land biome, including highlands.
					if kind >= 3 and kind < 10 or kind == 10 or kind == 11 or kind == 12:
						var palettes := [Palette.GREEN.lightened(0.15), Palette.GREEN.lightened(0.2), Palette.GRASS.darkened(0.15), Palette.GRASS.darkened(0.1), Palette.GRASS.lerp(Palette.STONE, 0.5).darkened(0.1), Palette.STONE.darkened(0.2), Palette.STONE.darkened(0.08), Palette.STONE.lightened(0.45), Palette.STONE.lightened(0.75)]
						var tint: Color = palettes[band]
						col = col.lerp(tint, 0.2 if kind in [3, 4, 5] else 0.85)
					var light := 0.50 + shade * 0.125
					image.set_pixel(kind * 16 + x, row * 16 + y, Color(col.r * light, col.g * light, col.b * light, col.a))
	atlas_image = image


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
	return {"kind": kind, "decoration": decoration, "shade": shade, "band": band if kind > 2 else 0, "cover": covers[kind] if kind in [4, 5] else cover, "height": height, "level": terrace_level(tile), "biome": b}


## Standing trees in a 16×16-tile block: [foot (world px), species, variant], sorted by foot.
## One candidate per jittered 3×3-tile cell; the species follows the land (TreeArt).
func trees_in_block(block: Vector2i) -> Array:
	if tree_blocks.has(block): return tree_blocks[block]
	var found: Array = []
	var low := block * 16
	for cy in range(floori(low.y / 3.0), ceili((low.y + 16) / 3.0)):
		for cx in range(floori(low.x / 3.0), ceili((low.x + 16) / 3.0)):
			var h := _hash(cx * 7 + 11, cy * 13 + 5)
			var jitter := Vector2((h % 1000) / 400.0, ((h >> 10) % 1000) / 400.0)
			var spot := Vector2(cx * 3, cy * 3) + jitter
			var tile := Vector2i(spot.floor())
			if not Rect2i(low, Vector2i(16, 16)).has_point(tile) or sect.has_tile(tile) or _near_building(tile): continue
			var species := -1
			var weight: float = sect.hunting.cached_weight(tile)
			if weight >= 0.25:
				if sect.hunting.cached_flag(tile, 1) or sect.hunting.cached_flag(tile, 2) or (h >> 3) % 1000 > weight * 900: continue
				species = [TreeArt.GIANT, TreeArt.GIANT, TreeArt.GIANT, TreeArt.CONIFER, TreeArt.CONIFER, TreeArt.OAK][(h >> 5) % 6]
			else:
				var info := sample(tile)
				match int(info.decoration):
					13: species = TreeArt.WILLOW if int(info.biome) == 10 else (TreeArt.CONIFER if float(info.height) > 0.72 else (TreeArt.BIRCH if (h >> 5) % 4 == 0 else TreeArt.OAK))
					14: species = TreeArt.BAMBOO
					15: species = [TreeArt.SPIRIT, TreeArt.SPIRIT, TreeArt.OAK, TreeArt.OAK, TreeArt.BIRCH, TreeArt.CONIFER][(h >> 5) % 6]
					16: species = TreeArt.SHRUB if (h >> 5) % 10 < 7 else TreeArt.CONIFER
			if species < 0: continue
			var foot := (spot + Vector2(0.5, 0.9)) * TILE - Vector2(0, terrace_level(tile) * exaggeration)
			found.append([foot, species, (h >> 8) % TreeArt.VARIANTS])
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	tree_blocks[block] = found
	return found


## A crown reaches four or five tiles up from its foot: no tree grows right in front of a building.
func _near_building(tile: Vector2i) -> bool:
	for dy in range(-5, 2):
		for dx in range(-1, 2):
			if sect.plinth.has(tile + Vector2i(dx, dy)) or sect.standing_tiles.has(tile + Vector2i(dx, dy)): return true
	return false


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


func set_exaggeration(value: float) -> void:
	exaggeration = clampf(value, 0.0, 48.0)
	for chunk: Sprite2D in chunks.values():
		chunk.texture = null
		chunk.free()
	chunks.clear()
	pending.clear()
	height_cache.clear()
	tree_blocks.clear()
	generation += 1
	far_cache.clear()
	far_lru.clear()
	detailed.clear()


func pick_tile(point: Vector2) -> Vector2i:
	var column := floori(point.x / TILE)
	var row := floori(point.y / TILE)
	for y in range(row + ceili(max_level * exaggeration / TILE) + 1, row - 2, -1):
		var tile := Vector2i(column, y)
		var top := y * TILE - terrace_level(tile) * exaggeration
		if point.y >= top and point.y < top + TILE:
			return tile
	return Vector2i(column, row)


func _new_baker() -> RefCounted:
	var baker := preload("res://src/ground_baker.gd").new()
	baker.world = snapshot
	baker.sect = sect
	baker.hunting = sect.hunting.worker_copy()
	baker.noise = noise.duplicate()
	baker.mountain = mountain.duplicate()
	baker.woodland = woodland.duplicate()
	baker.atlas_image = atlas_image
	baker.far_colors = far_colors
	baker.max_level = max_level
	baker.exaggeration = exaggeration
	return baker


func _far_image(key: Vector2i) -> Image:
	if far_cache.has(key):
		far_lru.erase(key)
		far_lru.append(key)
		return far_cache[key]
	var baker := _new_baker()
	var image: Image = baker._far_image(key)
	far_cache[key] = image
	far_lru.append(key)
	while far_lru.size() > 128:
		far_cache.erase(far_lru.pop_front())
	return image


func _exit_tree() -> void:
	for job: Dictionary in jobs.values():
		WorkerThreadPool.wait_for_task_completion(job.id)


func update_chunks(camera: Camera2D, budget: int) -> bool:
	var half := get_viewport_rect().size / camera.zoom / 2.0
	var low := Vector2i(((camera.position - half) / (SIDE * TILE)).floor()) - Vector2i.ONE
	var high := Vector2i(((camera.position + half + Vector2(0, max_level * exaggeration)) / (SIDE * TILE)).floor()) + Vector2i.ONE
	wanted.clear()
	for y in range(maxi(0, low.y), mini(world.h / 4 - 1, high.y) + 1):
		for x in range(maxi(0, low.x), mini(world.w / 4 - 1, high.x) + 1):
			wanted.append(Vector2i(x, y))
	var center := camera.position / (SIDE * TILE) - Vector2.ONE * 0.5
	wanted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).distance_squared_to(center) < Vector2(b).distance_squared_to(center))
	wanted.resize(mini(wanted.size(), 128))
	var near := camera.zoom.x >= 0.45
	if near: wanted.resize(mini(wanted.size(), 16))
	for key: Vector2i in chunks.keys():
		if key not in wanted or (not near and detailed.has(key)):
			chunks[key].free()
			chunks.erase(key)
			detailed.erase(key)
	for key: Vector2i in jobs.keys():
		var job: Dictionary = jobs[key]
		if key not in wanted or (job.detail and not near):
			job.cancelled = true
		if not WorkerThreadPool.is_task_completed(job.id):
			continue
		WorkerThreadPool.wait_for_task_completion(job.id)
		if job.generation == generation and not job.cancelled:
			var result: Dictionary = job.baker.pending
			if job.detail:
				var retained_bytes := 0
				for bytes: int in detailed.values(): retained_bytes += bytes
				if chunks.has(key) and retained_bytes + result.image.get_data_size() <= 96 * 1024 * 1024:
					var sprite: Sprite2D = chunks[key]
					sprite.texture = ImageTexture.create_from_image(result.image)
					sprite.position = Vector2(key) * SIDE * TILE - Vector2(0, (int(result.overflow) - int(result.min_y)) * 2)
					sprite.scale = Vector2.ONE * 2.0
					detailed[key] = result.image.get_data_size()
					last_bake_ms = result.elapsed
			else:
				var sprite := Sprite2D.new()
				sprite.texture = ImageTexture.create_from_image(result.image)
				sprite.centered = false
				sprite.position = Vector2(key) * SIDE * TILE
				sprite.scale = Vector2.ONE * TILE
				sprite.z_index = key.y
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				add_child(sprite)
				chunks[key] = sprite
		jobs.erase(key)
	if budget <= 0:
		pending = jobs.duplicate()
		return false
	# Both LODs rasterize on workers. Never synchronously bake a panning frame.
	for key: Vector2i in wanted:
		if jobs.size() >= 1:
			break
		if not chunks.has(key) and not jobs.has(key):
			var baker := _new_baker()
			jobs[key] = {"baker": baker, "id": WorkerThreadPool.add_task(baker.bake_far.bind(key)), "generation": generation, "cancelled": false, "detail": false}
	if near:
		for key: Vector2i in wanted:
			var detail_bytes := 0
			for bytes: int in detailed.values(): detail_bytes += bytes
			if detailed.size() >= 16 or detail_bytes >= 88 * 1024 * 1024: break
			if jobs.size() >= 1:
				break
			if not detailed.has(key) and not jobs.has(key) and chunks.has(key):
				var baker := _new_baker()
				jobs[key] = {"baker": baker, "id": WorkerThreadPool.add_task(baker.bake.bind(key)), "generation": generation, "cancelled": false, "detail": true}
	pending = jobs.duplicate()
	return detailed.size() == wanted.size() if near else chunks.size() == wanted.size()


func _bake_row(key: Vector2i, y: int) -> void:
	var image: Image = pending.image
	for x in SIDE:
		var tile := key * SIDE + Vector2i(x, y)
		var info := GroundPaint.info(self, tile)
		var level: int = info.level
		var top := y * 16 + int(pending.overflow) - roundi(level * exaggeration / 2.0)
		var south: int = GroundPaint.info(self, tile + Vector2i.DOWN).level
		var drop := roundi((level - south) * exaggeration / 2.0) if info.kind > 2 else 0
		pending.min_y = mini(pending.min_y, top)
		pending.max_y = maxi(pending.max_y, top + 16 + maxi(0, drop))
		if drop > 0:
			# Natural banks are earth and turf; built terraces (below) are faced with stone; a ramp is a flight of earth steps.
			var face := Palette.EARTH.darkened(0.38).lerp(Palette.GRASS.darkened(0.42), 0.45).lerp(Palette.GREEN.darkened(0.5), sect.hunting.cached_weight(tile)).darkened(minf(0.2, drop * 0.006))
			GroundPaint.bank(self, image, tile, Vector2i(x * 16, top + 16), drop, face)
			if sect.ramps.has(tile) and sect.ramps.has(tile + Vector2i.DOWN):
				GroundPaint.steps(image, Vector2i(x * 16, top + 16), drop, not sect.ramps.has(tile + Vector2i.LEFT), not sect.ramps.has(tile + Vector2i.RIGHT))
			if sect.level_at(tile) >= 0:
				GroundPaint.wall(self, image, tile, Vector2i(x * 16, top + 16), drop, sect.surface_at(tile) == "stairs")
		var source := Rect2i(int(info.kind) * 16, (int(info.shade) + int(info.band) * SHADES) * 16, 16, 16)
		image.blit_rect(atlas_image, source, Vector2i(x * 16, top))
		sect.draw_tile(image, tile, Vector2i(x * 16, top))
		GroundPaint.ground(self, image, tile, Vector2i(x * 16, top))
		sect.hunting.draw(image, tile, Vector2i(x * 16, top), sect.has_tile(tile))
		# Trees (13–16) stand up as sprites (see trees_in_block); only low things are painted on the ground.
		if info.decoration >= 0 and not info.decoration in [13, 14, 15, 16] and sect.hunting.cached_weight(tile) < 0.25:
			image.blend_rect(atlas_image, Rect2i(int(info.decoration) * 16, int(info.shade) * 16, 16, 16), Vector2i(x * 16, top))

func natural_dry(at: Vector2i) -> bool:
	var p := (Vector2(at) + Vector2.ONE * 0.5) / 16.0
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if _sea(p + offset / 16.0):
			return false
	var warped := p + Vector2(noise.get_noise_2dv(p * 1.3), noise.get_noise_2dv(p * 1.3 + Vector2(51, 83))) * 0.9
	var b: int = world.biome[clampi(int(warped.y), 0, world.h - 1) * world.w + clampi(int(warped.x), 0, world.w - 1)]
	return b != 3 and _river_distance(p) > 1.5
