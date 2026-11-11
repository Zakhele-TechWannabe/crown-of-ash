extends RefCounted
## Dense, bounded overrides: no per-tile dictionaries in storage or drawing.
const BOUNDS := Rect2i(-160, -210, 320, 620)
const SURFACES := ["", "grass", "earth", "paving", "stairs", "field", "spring", "cave", "garden"]
var data: Dictionary
var center: Vector2i
var surfaces := PackedByteArray()
var levels := PackedInt32Array()
var heights := PackedFloat32Array()
var art := PackedInt32Array()
var labels: Array[Dictionary] = []
var town: Image
var farm: Image
var dry: Callable


func index_at(at: Vector2i) -> int:
	var p := at - center - BOUNDS.position
	return p.y * BOUNDS.size.x + p.x if p.x >= 0 and p.y >= 0 and p.x < BOUNDS.size.x and p.y < BOUNDS.size.y else -1


func has_tile(at: Vector2i) -> bool:
	var i := index_at(at)
	return i >= 0 and surfaces[i] != 0


func level_at(at: Vector2i) -> int:
	var i := index_at(at)
	return levels[i] if i >= 0 else -1


func height_at(at: Vector2i) -> float:
	var i := index_at(at)
	return heights[i] if i >= 0 else 0.0


func surface_at(at: Vector2i) -> String:
	return SURFACES[surfaces[index_at(at)]] if has_tile(at) else ""


func setup(is_dry: Callable) -> void:
	dry = is_dry
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/sects/first_sect.json"))
	center = Vector2i(int(data.center[0]), int(data.center[1]))
	var count := BOUNDS.size.x * BOUNDS.size.y
	surfaces.resize(count)
	levels.resize(count)
	levels.fill(-1)
	heights.resize(count)
	art.resize(count)
	art.fill(-1)
	town = (load("res://assets/kenney/tiny-town/Tilemap/tilemap_packed.png") as Texture2D).get_image()
	farm = (load("res://assets/kenney/tiny-farm/Tilemap/tilemap_packed.png") as Texture2D).get_image()
	var edge := FastNoiseLite.new()
	edge.seed = int(data.seed)
	edge.frequency = 0.048
	# Evaluate each tile against seven terrace envelopes, rather than expanding every tile.
	for y in range(BOUNDS.position.y, 160):
		for x in range(BOUNDS.position.x, BOUNDS.end.x):
			var at := center + Vector2i(x, y)
			var i := index_at(at)
			var envelope := 0.0
			for tier: Dictionary in data.tiers:
				var yy := clampi(y, int(tier.y0), int(tier.y1))
				var end_distance := mini(yy - int(tier.y0), int(tier.y1) - yy)
				var width := float(tier.hw) - maxf(0.0, 10.0 - end_distance) + edge.get_noise_2d(0, yy) * 7.0
				var distance := Vector2(maxf(0, absf(x) - width), y - yy).length()
				var level := int(data.base_level) + int(tier.lvl)
				if distance == 0.0:
					levels[i] = level
					surfaces[i] = 1
				if distance < 55.0:
					var ravine := maxf(0.0, 0.15 - absf(edge.get_noise_2d(x * 2, y))) * minf(distance, 20.0) * 0.7
					envelope = maxf(envelope, 0.5 + (level - distance * 0.36 - ravine + edge.get_noise_2d(x, y) * 2.0) * 0.02)
			if y < 156:
				heights[i] = envelope
			if levels[i] >= 0:
				heights[i] = 0.5 + levels[i] * 0.02
	for surface: Dictionary in data.surfaces:
		_paint(surface.rect, str(surface.kind))
	for field: Dictionary in data.fields:
		_paint(field.rect, "field")
	_path(data.road)
	for path: Dictionary in data.paths:
		_path(path)
	var occupied: Array[Rect2i] = []
	for building: Dictionary in data.buildings + data.village:
		# Relocate whole footprints inland; never disguise river water with a cottage.
		var r: Array = building.rect.duplicate()
		if int(r[1]) >= 156:
			var attempts := 0
			while not _dry_rect(r) or _overlaps(r, occupied):
				r[0] = int(r[0]) - 1
				attempts += 1
				if int(r[0]) < -130:
					r[0] = 65
					r[1] = int(r[1]) + 5
				assert(attempts < 10000)
			occupied.append(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
			building.rect = r
			_paint([int(r[0]) - 1, int(r[1]) - 1, int(r[2]) + 2, int(r[3]) + 2], "grass")
		var bx := int(r[0]) + int(r[2]) / 2
		var by := int(r[1]) + int(r[3])
		if by < 156:
			_paint([mini(0, bx), by, absi(bx) + 1, 2], "paving")
		else:
			_paint([int(r[0]) - 2, by - 1, int(r[2]) + 4, 2], "earth")
		_building(building)
	for stair: Dictionary in data.stairs:
		_paint(stair.rect, "stairs")


func _overlaps(r: Array, occupied: Array[Rect2i]) -> bool:
	var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).grow(1)
	for other: Rect2i in occupied:
		if rect.intersects(other):
			return true
	return false


func _dry_rect(r: Array) -> bool:
	for y in range(int(r[1]), int(r[1]) + int(r[3])):
		for x in range(int(r[0]), int(r[0]) + int(r[2])):
			if not dry.call(center + Vector2i(x, y)):
				return false
	return true


func _path(path: Dictionary) -> void:
	var points: Array = path.points
	for j in range(points.size() - 1):
		var a := Vector2(points[j][0], points[j][1])
		var b := Vector2(points[j + 1][0], points[j + 1][1])
		for step in range(ceili(a.distance_to(b)) + 1):
			var p := Vector2i(a.lerp(b, float(step) / maxf(1.0, ceilf(a.distance_to(b)))))
			_paint([p.x - int(path.width) / 2, p.y, int(path.width), 1], str(path.kind))


func _paint(rect: Array, surface: String) -> void:
	for y in range(int(rect[1]), int(rect[1]) + int(rect[3])):
		for x in range(int(rect[0]), int(rect[0]) + int(rect[2])):
			var at := center + Vector2i(x, y)
			var i := index_at(at)
			if surface == "field" and (x < int(rect[0]) + absi(y % 5 - 2) or x >= int(rect[0]) + int(rect[2]) - absi(y % 7 - 3)):
				continue
			if i >= 0 and (y < 156 or dry.call(at)):
				surfaces[i] = SURFACES.find(surface)


func _stamp(at: Vector2i, value: int) -> void:
	var i := index_at(at)
	if i >= 0:
		if surfaces[i] == 0:
			surfaces[i] = 1
		art[i] = value


func _building(b: Dictionary) -> void:
	var r: Array = b.rect
	var origin := center + Vector2i(int(r[0]), int(r[1]))
	var w := int(r[2])
	var h := int(r[3])
	var kind := str(b.kind)
	if not str(b.name).is_empty():
		labels.append({"name": str(b.name), "tile": origin + Vector2i(w / 2, 0)})
	if kind == "marker":
		return
	if kind == "prop":
		_stamp(origin, 95)
		return
	if kind == "wall":
		for x in w:
			_stamp(origin + Vector2i(x, 0), 80)
		return
	if kind == "ring":
		for y in h:
			for x in w:
				if absf(Vector2(x - w / 2, y - h / 2).length() - 5.0) < 0.7:
					_stamp(origin + Vector2i(x, y), 95)
		return
	if kind in ["spring", "plaza", "training"]:
		if kind == "training":
			for x in range(3, w - 2, 7):
				_stamp(origin + Vector2i(x, 1), 95)
		return
	if kind == "court":
		_paint(r, "paving")
		for y in h:
			for x in w:
				if x == 0 or x == w - 1 or y == 0 or (y == h - 1 and x != w / 2):
					_stamp(origin + Vector2i(x, y), 80 if y == 0 or y == h - 1 else 59)
		_paint([int(r[0]) + 2, int(r[1]) + 7, w - 4, h - 9], "garden")
		_building({"name": "", "rect": [int(r[0]) + 2, int(r[1]) + 2, 6, 4], "kind": "house"})
		_building({"name": "", "rect": [int(r[0]) + 10, int(r[1]) + 2, 5, 4], "kind": "house"})
		return
	if kind == "cave":
		_paint(r, "cave")
		return
	# A path across each terrace joins its buildings to the central ascent.
	if level_at(origin) >= 0:
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
	if not has_tile(tile):
		return
	var i := index_at(tile)
	var surface: String = SURFACES[surfaces[i]]
	var rect := Rect2i(pos, Vector2i(16, 16))
	if surface in ["grass", "garden"]:
		_blit(image, town, (tile.x + tile.y) % 2, pos)
		if surface == "garden" and tile.x % 3 == 0 and tile.y % 3 == 0:
			_blit(image, town, 4, pos)
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
	if art[i] >= 0:
		_blit(image, town, art[i], pos)


func _blit(image: Image, source: Image, index: int, pos: Vector2i) -> void:
	image.blend_rect(source, Rect2i((index % 12) * 16, (index / 12) * 16, 16, 16), pos)
