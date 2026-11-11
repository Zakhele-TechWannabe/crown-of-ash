extends RefCounted
## Relative, data-driven drawing plan. All hot-path queries are dictionary lookups.
var data: Dictionary
var center: Vector2i
var tiles: Dictionary = {}
var heights: Dictionary = {}
var labels: Array[Dictionary] = []
var town: Image
var farm: Image


func setup() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/sects/first_sect.json"))
	center = Vector2i(int(data.center[0]), int(data.center[1]))
	town = (load("res://assets/kenney/tiny-town/Tilemap/tilemap_packed.png") as Texture2D).get_image()
	farm = (load("res://assets/kenney/tiny-farm/Tilemap/tilemap_packed.png") as Texture2D).get_image()
	var edge := FastNoiseLite.new()
	edge.seed = int(data.seed)
	edge.frequency = 0.24
	for tier: Dictionary in data.tiers:
		var level := int(data.base_level) + int(tier.lvl)
		for y in range(int(tier.y0), int(tier.y1) + 1):
			var end_distance := mini(y - int(tier.y0), int(tier.y1) - y)
			var width := int(tier.hw) - (2 if end_distance == 0 else (1 if end_distance == 1 else 0))
			for x in range(-width, width + 1):
				if absi(x) == width and absi(x) > 3 and edge.get_noise_2d(x, y) > 0.2:
					continue
				var at := center + Vector2i(x, y)
				tiles[at] = {"level": level, "surface": "grass", "built": true}
				# Envelope of platforms supports every carved ledge, fading into a noisy skirt.
				for dy in range(-18, 19):
					for dx in range(-18, 19):
						var distance := Vector2(dx, dy).length()
						if distance > 18.0:
							continue
						var q := at + Vector2i(dx, dy)
						var h := 0.5 + (level - distance * 0.44 + edge.get_noise_2dv(Vector2(q)) * minf(distance, 4.0) * 0.3) * 0.02
						heights[q] = maxf(float(heights.get(q, 0.0)), h)
	# The foreland stays at its original height: paddies and village are surface-only.
	for at: Vector2i in heights.keys():
		if at.y - center.y >= 31:
			heights.erase(at)
	for at: Vector2i in tiles:
		heights[at] = 0.5 + int(tiles[at].level) * 0.02
	for surface: Dictionary in data.surfaces:
		_paint(surface.rect, str(surface.kind))
	for field: Dictionary in data.fields:
		_paint(field.rect, "field")
	_paint(data.road.rect, "earth")
	_paint([8, 31, 23, 14], "grass")
	for y in [34, 39, 44]:
		_paint([7, y, 25, 1], "earth")
	for x in [7, 12, 17, 22, 27]:
		_paint([x, 31, 1, 14], "earth")
	for stair: Dictionary in data.stairs:
		_paint(stair.rect, "stairs")
	for building: Dictionary in data.buildings + data.village:
		_building(building)
	for stair: Dictionary in data.stairs:
		_paint(stair.rect, "stairs")
	labels.append({"name": str(data.name), "tile": center + Vector2i(0, -32)})


func _paint(rect: Array, surface: String) -> void:
	for y in range(int(rect[1]), int(rect[1]) + int(rect[3])):
		for x in range(int(rect[0]), int(rect[0]) + int(rect[2])):
			var at := center + Vector2i(x, y)
			var info: Dictionary = tiles.get(at, {})
			info.surface = surface
			tiles[at] = info


func _stamp(at: Vector2i, index: int) -> void:
	var info: Dictionary = tiles.get(at, {"surface": "grass"})
	info.art = index
	tiles[at] = info


func _building(b: Dictionary) -> void:
	var r: Array = b.rect
	var origin := center + Vector2i(int(r[0]), int(r[1]))
	var w := int(r[2])
	var h := int(r[3])
	var kind := str(b.kind)
	if not str(b.name).is_empty():
		labels.append({"name": str(b.name), "tile": origin + Vector2i(w / 2, 0)})
	if kind in ["spring", "plaza", "training"]:
		if kind == "training":
			for x in [1, 5, 9]:
				_stamp(origin + Vector2i(x, 1), 95)
		return
	if kind == "court":
		_paint(r, "paving")
		for y in h:
			for x in w:
				if x == 0 or x == w - 1 or y == 0 or (y == h - 1 and x != w / 2):
					_stamp(origin + Vector2i(x, y), 80 if y == 0 or y == h - 1 else 59)
		for y in 2:
			for x in 3:
				_stamp(origin + Vector2i(x + 2, y + 1), (64 if x == 0 else 66) if y == 0 else (85 if x == 1 else 84))
		return
	if kind == "cave":
		_paint(r, "cave")
		return
	# A path across each terrace joins its buildings to the central ascent.
	if tiles.get(origin, {}).has("level"):
		_paint([mini(0, int(r[0])), int(r[1]) + h, maxi(0, int(r[0]) + w) - mini(0, int(r[0])), 1], "paving")
	for y in h:
		for x in w:
			var index := 0
			if kind == "gate":
				index = (96 if x == 0 else 98) if y == 0 else (108 if x == 0 else 110)
				if x > 0 and x < w - 1:
					index = (111 if x < w / 2 else 114) if y == 0 else -1
			else:
				var house := kind == "house"
				if y < h - 1:
					index = (52 if house else 48) + (0 if x == 0 else (2 if x == w - 1 else 1)) + (12 if y > 0 else 0)
				else:
					index = 85 if house else (76 if x == 0 else (79 if x == w - 1 else (88 if x % 3 == 1 else 77)))
					if x == w / 2:
						index = 85 if house else 78
			if index >= 0:
				_stamp(origin + Vector2i(x, y), index)


func draw_tile(image: Image, tile: Vector2i, pos: Vector2i) -> void:
	if not tiles.has(tile):
		return
	var info: Dictionary = tiles[tile]
	var surface: String = info.surface
	var rect := Rect2i(pos, Vector2i(16, 16))
	if surface == "grass":
		_blit(image, town, (tile.x + tile.y) % 2, pos)
	elif surface == "earth":
		_blit(image, town, 25, pos)
	elif surface == "field":
		image.fill_rect(rect, Color8(124, 81, 48))
		for row in [2, 7, 12]:
			image.fill_rect(Rect2i(pos + Vector2i(0, row), Vector2i(16, 2)), Color8(84, 57, 38))
		_blit(image, farm, 64 if tile.y % 2 == 0 else 65, pos)
	elif surface == "spring":
		image.fill_rect(rect, Color8(157, 219, 212))
		image.fill_rect(Rect2i(pos + Vector2i(2, 2), Vector2i(12, 12)), Color8(72, 165, 182))
		image.fill_rect(Rect2i(pos + Vector2i(4, 5), Vector2i(8, 1)), Color8(202, 255, 239))
	elif surface == "cave":
		image.fill_rect(rect, Color8(102, 108, 109))
		image.fill_rect(Rect2i(pos + Vector2i(3, 4), Vector2i(10, 12)), Color8(27, 31, 38))
	else:
		image.fill_rect(rect, Color8(163, 173, 170))
		for y in range(0, 16, 4 if surface == "stairs" else 8):
			image.fill_rect(Rect2i(pos + Vector2i(0, y), Vector2i(16, 1)), Color8(108, 124, 128))
			image.fill_rect(Rect2i(pos + Vector2i(0, y + 1), Vector2i(16, 1)), Color8(199, 206, 194))
			if surface != "stairs":
				image.fill_rect(Rect2i(pos + Vector2i(4 if y == 0 else 12, y), Vector2i(1, 8)), Color8(108, 124, 128))
	if info.has("art"):
		_blit(image, town, int(info.art), pos)
	if tile == center + Vector2i(0, 28):
		image.fill_rect(Rect2i(pos + Vector2i(-5, 2), Vector2i(26, 7)), Color8(55, 42, 35))
		image.fill_rect(Rect2i(pos + Vector2i(1, 4), Vector2i(14, 2)), Color8(220, 183, 92))


func _blit(image: Image, source: Image, index: int, pos: Vector2i) -> void:
	image.blend_rect(source, Rect2i((index % 12) * 16, (index / 12) * 16, 16, 16), pos)
