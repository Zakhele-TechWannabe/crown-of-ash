extends Node2D
## Disposable chunks share one small atlas; samples never depend on visit order.

const SIDE := 64
const TILE := 32.0
const LIMIT := 16
const SHADES := 9
const BANDS := 9
var world: Node2D
var atlas: TileSet
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
	_build_atlas()


func _build_atlas() -> void:
	var town := load("res://assets/kenney/tiny-town/Tilemap/tilemap_packed.png") as Texture2D
	var farm := load("res://assets/kenney/tiny-farm/Tilemap/tilemap_packed.png") as Texture2D
	var town_image := town.get_image()
	var farm_image := farm.get_image()
	var image := Image.create(20 * 16, SHADES * BANDS * 16, false, Image.FORMAT_RGBA8)
	var colors := [Color8(32, 68, 109), Color8(57, 115, 148), Color8(63, 133, 160), Color8(218, 198, 139), Color8(125, 127, 126), Color8(233, 240, 239), Color8(141, 158, 134), Color8(100, 119, 78), Color8(224, 183, 113), Color8(157, 168, 91)]
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
							col = col.lightened(0.16) if kind < 3 else col.darkened(0.13)
						if kind == 7 and (x * 3 + y * 7) % 23 < 3:
							col = col.darkened(0.3)
					else:
						var index: int = indices[kind - 10]
						var source := farm_image if kind >= 17 else town_image
						col = source.get_pixel((index % 12) * 16 + x, (index / 12) * 16 + y)
						if kind == 15:
							col *= Color(0.55, 0.86, 0.8)
						elif kind == 16:
							# Readable evergreen silhouette for sheltered highland groves.
							col = Color.TRANSPARENT
							if y >= 11 and y <= 15 and x in [7, 8]:
								col = Color8(78, 62, 42)
							for tier in 3:
								var top := 1 + tier * 3
								if y >= top and y <= top + 5 and abs(x - 7) <= (y - top) / 2 + tier:
									col = Color8(47, 82, 52) if x < 8 else Color8(34, 61, 42)
					# Elevation palettes are shared by every land biome, including highlands.
					if kind >= 3 and kind < 10 or kind == 10 or kind == 11 or kind == 12:
						var palettes := [Color8(113, 151, 77), Color8(122, 154, 79), Color8(132, 152, 82), Color8(141, 149, 88), Color8(148, 143, 96), Color8(140, 134, 116), Color8(160, 160, 155), Color8(206, 216, 214), Color8(236, 242, 240)]
						var tint: Color = palettes[band]
						col = col.lerp(tint, 0.85 if kind != 3 else 0.2)
					var light := 0.50 + shade * 0.125
					image.set_pixel(kind * 16 + x, row * 16 + y, Color(col.r * light, col.g * light, col.b * light, col.a))
	atlas = TileSet.new()
	atlas.tile_size = Vector2i(16, 16)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(16, 16)
	for x in 20:
		for y in SHADES * BANDS:
			source.create_tile(Vector2i(x, y))
	atlas.add_source(source, 0)


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
				if distance + noise.get_noise_2dv(p * 9.0) * 0.4 < 0.6 + world.rivers[i] / 10.0 * 0.9:
					kind = 2
	var warped := p + Vector2(noise.get_noise_2dv(p * 1.3), noise.get_noise_2dv(p * 1.3 + Vector2(51, 83))) * 0.9
	var b: int = world.biome[clampi(int(warped.y), 0, world.h - 1) * world.w + clampi(int(warped.x), 0, world.w - 1)]
	var cover: String = str(world.data.biome_names[b]).to_lower()
	if kind < 0:
		kind = {0: 0, 1: 1, 2: 1, 3: 3, 8: 8, 9: 9, 10: 7, 11: 9, 12: 4, 13: 5, 14: 6, 15: 5}.get(b, 10)
	else:
		cover = covers[kind]
	# The same global height function is used on both sides of chunk boundaries.
	var height := _relief(p)
	var west := _relief(p - Vector2(1.0 / 16.0, 0))
	var east := _relief(p + Vector2(1.0 / 16.0, 0))
	var north := _relief(p - Vector2(0, 1.0 / 16.0))
	var south := _relief(p + Vector2(0, 1.0 / 16.0))
	var gradient := Vector2(east - west, south - north) * 8.0
	var steep := gradient.length()
	var light := clampf(1.0 + (gradient.x + gradient.y) * 3.5, 0.7, 1.3)
	# Downhill south/east edges read as exposed dark rock faces.
	var cliff := steep > 0.12
	if cliff and kind > 3:
		kind = 4
		light *= 0.72 if gradient.x + gradient.y < 0.0 else 0.9
	var band := clampi(roundi((height - 0.52 + noise.get_noise_2dv(p * 7.0) * 0.018) / 0.06), 0, BANDS - 1)
	var decoration := -1
	var chance := float(_hash(tile.x, tile.y) % 1000) / 1000.0
	var density := smoothstep(-0.35, 0.45, woodland.get_noise_2dv(p))
	var forest := b in [5, 6, 7]
	var trees := smoothstep(0.28 if forest else 0.63, 0.8, density)
	if b == 11:
		trees = smoothstep(0.3, 0.8, density) * (1.0 - smoothstep(0.05, 0.12, steep))
	trees *= 1.0 - smoothstep(0.82, 0.9, height)
	if kind > 3 and kind != 8 and height < 0.88 and not cliff and chance < trees * 0.85:
		decoration = 16 if b == 11 else (15 if b == 6 else (14 if b == 7 else 13))
	elif kind > 3:
		# Coherent outcrops plus shared 2x2 patch decisions make boulder groups.
		var patch := float(_hash(floori(tile.x / 2.0), floori(tile.y / 2.0)) % 1000) / 1000.0
		var outcrop := smoothstep(0.04, 0.12, steep) * 0.15 + smoothstep(0.82, 0.92, height) * 0.2
		if patch < outcrop and chance < 0.8:
			decoration = 17 if chance < 0.4 else 19
	var shade := clampi(roundi((light - 0.5) / 0.125), 0, SHADES - 1) if kind > 2 else 4
	return {"kind": kind, "decoration": decoration, "shade": shade, "band": band if kind > 2 else 0, "cover": cover}


func _relief(p: Vector2) -> float:
	# Detail disappears near water; coastline and river masks stay world-derived.
	var base := _blend(p)
	return base + noise.get_noise_2dv(p * 2.4) * 0.04 * smoothstep(0.50, 0.56, base)


func update_chunks(camera: Camera2D, budget: int) -> bool:
	var half := get_viewport_rect().size / camera.zoom / 2.0
	var low := Vector2i(((camera.position - half) / (SIDE * TILE)).floor()) - Vector2i.ONE
	var high := Vector2i(((camera.position + half) / (SIDE * TILE)).floor()) + Vector2i.ONE
	if low != cached_low or high != cached_high:
		cached_low = low
		cached_high = high
		wanted.clear()
		for y in range(maxi(0, low.y), mini(world.h / 4 - 1, high.y) + 1):
			for x in range(maxi(0, low.x), mini(world.w / 4 - 1, high.x) + 1):
				wanted.append(Vector2i(x, y))
		var center := camera.position / (SIDE * TILE) - Vector2.ONE * 0.5
		var visible_rect := Rect2(camera.position - half, half * 2.0)
		wanted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var a_visible := visible_rect.intersects(Rect2(Vector2(a) * SIDE * TILE, Vector2.ONE * SIDE * TILE))
			var b_visible := visible_rect.intersects(Rect2(Vector2(b) * SIDE * TILE, Vector2.ONE * SIDE * TILE))
			if a_visible != b_visible:
				return a_visible
			return Vector2(a).distance_squared_to(center) < Vector2(b).distance_squared_to(center))
		if wanted.size() > LIMIT:
			wanted.resize(LIMIT)
	for key: Vector2i in chunks.keys():
		if not key in wanted:
			chunks[key].free()
			chunks.erase(key)
	var complete := true
	for key in wanted:
		if chunks.has(key):
			continue
		if budget <= 0:
			complete = false
			continue
		budget -= 1
		var chunk := Node2D.new()
		chunk.position = Vector2(key) * SIDE * TILE
		chunk.scale = Vector2.ONE * (TILE / 16.0)
		chunk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(chunk)
		chunks[key] = chunk
		var base := TileMapLayer.new()
		base.tile_set = atlas
		chunk.add_child(base)
		var props := TileMapLayer.new()
		props.tile_set = atlas
		chunk.add_child(props)
		for y in SIDE:
			for x in SIDE:
				var tile := Vector2i(x, y)
				var info := sample(key * SIDE + tile)
				base.set_cell(tile, 0, Vector2i(info.kind, info.shade + info.band * SHADES))
				if info.decoration >= 0:
					props.set_cell(tile, 0, Vector2i(info.decoration, info.shade))
	return complete
