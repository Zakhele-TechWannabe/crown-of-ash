extends RefCounted
## The countryside: your village in the middle, abandoned hamlets around it, forests, fields, dirt roads,
## graveyards at the edges and the Black Crypt in a far corner.

enum { GRASS, ROAD, FLOOR, WALL, WINDOW, DOOR, FOREST, FIELD, GRAVE }

const W := 84
const H := 60
const T := 32.0

const NAMES := ["Ashford", "Mill End", "Thornby", "Coldwater", "Brackenhurst", "Wychley", "Hollowmere"]
const SPOTS := [Vector2i(42, 30), Vector2i(15, 12), Vector2i(42, 9), Vector2i(68, 13), Vector2i(14, 47), Vector2i(41, 51), Vector2i(66, 44)]
const CRYPT := Vector2i(78, 55)

var tiles := PackedByteArray()
var openings := {}                   # Vector2i → {kind, house}
var crates: Array = []               # {cell, searched, house}
var houses: Array = []               # {rect, hall, holding}
var holdings: Array = []             # {name, center, hall, houses, fields, claimed, crypt}
var graves: Array[Vector2i] = []     # where the dead rise at night
var rng := RandomNumberGenerator.new()


func build(seed_val: int) -> void:
	rng.seed = seed_val
	tiles.resize(W * H)
	tiles.fill(GRASS)
	# woods: soft blobs scattered over the land
	for k in 34:
		var c := Vector2i(rng.randi_range(0, W - 1), rng.randi_range(0, H - 1))
		var r := rng.randf_range(2.0, 5.5)
		for y in range(c.y - 6, c.y + 7):
			for x in range(c.x - 6, c.x + 7):
				if _in(x, y) and Vector2(x - c.x, y - c.y).length() < r + rng.randf_range(-0.8, 0.8):
					tiles[y * W + x] = FOREST
	# clear room around every settlement, then lay roads from each to Ashford
	for p in SPOTS + [CRYPT]:
		_fill(Rect2i(p.x - 9, p.y - 8, 19, 17), GRASS)
	for i in range(1, SPOTS.size()):
		_road(SPOTS[i], SPOTS[0])
	_road(CRYPT, SPOTS[6])
	for i in SPOTS.size():
		_holding(i)
	_crypt()
	# graveyards at the edges of the land
	for p in [Vector2i(3, 30), Vector2i(80, 28), Vector2i(30, 2), Vector2i(56, 57)]:
		_fill(Rect2i(p.x - 2, p.y - 2, 5, 5), GRAVE)
		graves.append(p)


func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


func _fill(r: Rect2i, t: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _in(x, y):
				tiles[y * W + x] = t


func _road(a: Vector2i, b: Vector2i) -> void:
	var p := a
	while p.x != b.x:
		_fill(Rect2i(p.x, p.y, 1, 2), ROAD)
		p.x += signi(b.x - p.x)
	while p.y != b.y:
		_fill(Rect2i(p.x, p.y, 2, 1), ROAD)
		p.y += signi(b.y - p.y)


func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not _in(x, y) or tiles[y * W + x] in [WALL, FLOOR, DOOR, WINDOW, ROAD, FIELD]:
				return false
	return true


func _holding(i: int) -> void:
	var p: Vector2i = SPOTS[i]
	var h := {"name": NAMES[i], "center": p, "hall": -1, "houses": [], "fields": [], "claimed": i == 0, "crypt": false}
	holdings.append(h)
	# the hall: the holding's heart and its shelter at night
	var hall := Rect2i(p.x - 4, p.y - 3, 9, 7)
	h.hall = _house(hall, true, i)
	h.houses.append(h.hall)
	# cottages and fields around it
	var tries := 0
	while h.houses.size() < (3 if i == 0 else 4) and tries < 80:
		tries += 1
		var r := Rect2i(p.x + rng.randi_range(-9, 4), p.y + rng.randi_range(-8, 3), rng.randi_range(5, 6), rng.randi_range(4, 5))
		if _free(r.grow(1)):
			h.houses.append(_house(r, false, i))
	var patches := 0
	tries = 0
	while patches < 2 and tries < 60:
		tries += 1
		var r := Rect2i(p.x + rng.randi_range(-10, 5), p.y + rng.randi_range(-9, 4), 5, 4)
		if _free(r.grow(1)):
			_fill(r, FIELD)
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					h.fields.append(Vector2i(x, y))
			patches += 1


func _crypt() -> void:
	var h := {"name": "The Black Crypt", "center": CRYPT, "hall": -1, "houses": [], "fields": [], "claimed": false, "crypt": true}
	holdings.append(h)
	_fill(Rect2i(CRYPT.x - 6, CRYPT.y - 4, 12, 8), GRAVE)
	h.hall = _house(Rect2i(CRYPT.x - 3, CRYPT.y - 2, 7, 5), true, holdings.size() - 1)
	h.houses.append(h.hall)


func _house(r: Rect2i, is_hall: bool, holding: int) -> int:
	var idx := houses.size()
	houses.append({"rect": r, "hall": is_hall, "holding": holding})
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var edge := x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1
			tiles[y * W + x] = WALL if edge else FLOOR
	# the door faces the holding's centre (the hall's faces the road south)
	var p: Vector2i = SPOTS[holding] if holding < SPOTS.size() else CRYPT
	var cx := r.position.x + r.size.x / 2
	var cy := r.position.y + r.size.y / 2
	var door: Vector2i
	if is_hall:
		door = Vector2i(cx, r.end.y - 1)
	elif absi(cy - p.y) >= absi(cx - p.x):
		door = Vector2i(cx, r.end.y - 1) if cy < p.y else Vector2i(cx, r.position.y)
	else:
		door = Vector2i(r.end.x - 1, cy) if cx < p.x else Vector2i(r.position.x, cy)
	_open(door, "door", idx)
	# windows on the walls
	var spots: Array[Vector2i] = []
	for x in range(r.position.x + 2, r.end.x - 2, 3):
		spots.append(Vector2i(x, r.position.y))
		spots.append(Vector2i(x, r.end.y - 1))
	for y in range(r.position.y + 2, r.end.y - 2, 3):
		spots.append(Vector2i(r.position.x, y))
		spots.append(Vector2i(r.end.x - 1, y))
	spots.shuffle()
	var n := 4 if is_hall else 2
	for c in spots:
		if n <= 0:
			break
		if c.distance_to(door) < 2.0 or openings.has(c):
			continue
		_open(c, "window", idx)
		n -= 1
	if not is_hall or holding != 0:
		for k in rng.randi_range(2, 4):
			crates.append({"cell": Vector2i(rng.randi_range(r.position.x + 1, r.end.x - 2), rng.randi_range(r.position.y + 1, r.end.y - 2)),
				"searched": false, "house": idx})
	return idx


func _open(c: Vector2i, kind: String, house: int) -> void:
	tiles[c.y * W + c.x] = WINDOW if kind == "window" else DOOR
	openings[c] = {"kind": kind, "house": house}


func at(c: Vector2i) -> int:
	if not _in(c.x, c.y):
		return WALL
	return tiles[c.y * W + c.x]


func cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / T)), int(floor(p.y / T)))


func center(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * T, (c.y + 0.5) * T)


func hall_rect(holding: int) -> Rect2i:
	return houses[holdings[holding].hall].rect


func holding_area(holding: int) -> Rect2i:
	var p: Vector2i = holdings[holding].center
	return Rect2i(p.x - 11, p.y - 10, 23, 20)
