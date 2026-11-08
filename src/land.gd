extends RefCounted
## The Empire of Kambara, seen from above: Ala Kambara walled in the middle, the Nyoka Mountains across the
## north, the Kambara River running down the west and over the falls, Kiranga Citadel on its plateau, the
## Trade Port on the Golden Coast, the agricultural belt to the south-east and the provincial cities around.
## The dead hold all of it but the capital, and the Black Crypt lies hidden in the Nyoka peaks.

enum { GRASS, ROAD, FLOOR, WALL, WINDOW, DOOR, FOREST, FIELD, GRAVE, WATER, ROCK, SAND, PAVE }

const W := 104
const H := 78
const T := 32.0

# name, centre, half-size of its ground, houses
const PLACES := [
	["Ala Kambara", Vector2i(52, 38), Vector2i(16, 13), 6],
	["Tenga City", Vector2i(16, 21), Vector2i(12, 10), 4],
	["Kiranga Citadel", Vector2i(74, 10), Vector2i(12, 10), 3],
	["Kambara Port", Vector2i(82, 31), Vector2i(12, 10), 4],
	["Ilanga City", Vector2i(14, 44), Vector2i(12, 10), 4],
	["Mabele City", Vector2i(83, 62), Vector2i(12, 10), 4],
	["Kifaru City", Vector2i(57, 67), Vector2i(12, 10), 4],
	["Savu City", Vector2i(22, 66), Vector2i(12, 10), 4],
]
const CRYPT := Vector2i(12, 4)
# provinces, written across the land
const PROVINCES := [
	["NYOKA MOUNTAINS", Vector2i(36, 4)], ["NYOKA PROVINCE", Vector2i(5, 12)], ["MALIBA PROVINCE", Vector2i(5, 33)],
	["BOMANI PROVINCE", Vector2i(4, 56)], ["KASAI PROVINCE", Vector2i(40, 74)], ["LUMBA PROVINCE", Vector2i(70, 74)],
	["NDELE PROVINCE", Vector2i(88, 48)], ["ZAWADI PROVINCE", Vector2i(69, 41)], ["KIRANGA PLATEAU", Vector2i(86, 4)],
	["THE GOLDEN COAST", Vector2i(95, 22)], ["THE KAMBARA RIVER", Vector2i(36, 54)], ["THE AGRICULTURAL BELT", Vector2i(68, 52)],
]
const RIVER := [Vector2i(34, 6), Vector2i(33, 14), Vector2i(31, 24), Vector2i(31, 36), Vector2i(32, 48), Vector2i(37, 54),
	Vector2i(41, 60), Vector2i(41, 68), Vector2i(39, 78)]

var tiles := PackedByteArray()
var openings := {}                   # Vector2i → {kind, house}
var crates: Array = []               # {cell, searched, house}
var houses: Array = []               # {rect, hall, holding}
var holdings: Array = []             # {name, center, half, hall, houses, fields, claimed, crypt}
var graves: Array[Vector2i] = []     # where the dead rise at night
var falls: Array[Vector2i] = []      # white water
var rng := RandomNumberGenerator.new()


func build(seed_val: int) -> void:
	rng.seed = seed_val
	tiles.resize(W * H)
	tiles.fill(GRASS)
	_coast()
	_mountains()
	# woods: thick in Maliba and Bomani to the west, thinner to the east
	for k in 70:
		var c := Vector2i(rng.randi_range(0, W - 1), rng.randi_range(8, H - 1))
		if c.x > 40 and rng.randf() < 0.6:
			c.x = rng.randi_range(0, 30)
		var r := rng.randf_range(2.0, 5.0)
		for y in range(c.y - 6, c.y + 7):
			for x in range(c.x - 6, c.x + 7):
				if _in(x, y) and tiles[y * W + x] == GRASS and Vector2(x - c.x, y - c.y).length() < r + rng.randf_range(-0.8, 0.8):
					tiles[y * W + x] = FOREST
	_river()
	# clear the ground of every settlement and the crypt's hollow, then the imperial highways from the capital
	for p in PLACES:
		_fill(Rect2i(p[1] - p[2], p[2] * 2 + Vector2i.ONE), GRASS)
	_fill(Rect2i(CRYPT.x - 7, CRYPT.y - 4, 15, 9), GRASS)
	for i in range(1, PLACES.size()):
		_road(PLACES[0][1], PLACES[i][1])
	_road(PLACES[1][1], CRYPT)
	# the port's piers run out into the sea
	_fill(Rect2i(PLACES[3][1].x, PLACES[3][1].y + 2, 14, 2), ROAD)
	for i in PLACES.size():
		_holding(i)
	_streets()
	_crypt()
	_belt()
	for p in [Vector2i(3, 30), Vector2i(98, 72), Vector2i(36, 76), Vector2i(60, 20)]:
		_fill(Rect2i(p.x - 1, p.y - 1, 3, 3), GRAVE)
		graves.append(p)


## The sea along the east, sand along its edge, and the bay north of the port.
func _coast() -> void:
	for y in H:
		var x0 := 95.0 + 2.0 * sin(y * 0.35) + (maxf(0.0, y - 48.0) * 1.3)
		if y < 18:
			x0 -= (18 - y) * 0.6
		for x in W:
			if x >= x0:
				tiles[y * W + x] = WATER
			elif x >= x0 - 2.0:
				tiles[y * W + x] = SAND


## The Nyoka range across the north-west and the broken hills of the Kiranga plateau.
func _mountains() -> void:
	for x in W:
		var foot := 8.0 + 3.0 * sin(x * 0.45) + 2.0 * sin(x * 0.17)
		if x > 58:
			foot = 3.0 + 2.0 * sin(x * 0.6)
		for y in range(0, int(foot)):
			if tiles[y * W + x] == GRASS:
				tiles[y * W + x] = ROCK
	for k in 40:
		var c := Vector2i(rng.randi_range(0, 60), rng.randi_range(4, 14)) if k < 20 else Vector2i(rng.randi_range(60, 92), rng.randi_range(0, 22))
		var r := rng.randf_range(1.5, 3.5)
		for y in range(c.y - 4, c.y + 5):
			for x in range(c.x - 4, c.x + 5):
				if _in(x, y) and tiles[y * W + x] == GRASS and Vector2(x - c.x, y - c.y).length() < r:
					tiles[y * W + x] = ROCK


## The Kambara River: out of the mountains at the upper falls, down the west of the capital, over Kambara
## Falls and away south.
func _river() -> void:
	for i in RIVER.size() - 1:
		var a: Vector2 = RIVER[i]
		var b: Vector2 = RIVER[i + 1]
		var n := int(a.distance_to(b) * 2.0)
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			var wide := 1 if p.y < 30 else 2
			for dy in range(-1, 1):
				for dx in range(-1, wide):
					var c := Vector2i(int(p.x) + dx, int(p.y) + dy)
					if _in(c.x, c.y):
						tiles[c.y * W + c.x] = WATER
	for y in range(6, 11):
		falls.append(Vector2i(33, y))
		falls.append(Vector2i(34, y))
	for y in range(57, 61):
		for x in range(38, 42):
			if at(Vector2i(x, y)) == WATER:
				falls.append(Vector2i(x, y))


## Big fields between the capital and Mabele: the empire's bread. They belong to Mabele City.
func _belt() -> void:
	var mab: Dictionary = holdings[5]
	for r in [Rect2i(70, 44, 6, 4), Rect2i(78, 44, 6, 4), Rect2i(70, 49, 6, 4), Rect2i(86, 44, 5, 4)]:
		if not _free(r):
			continue
		_fill(r, FIELD)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				mab.fields.append(Vector2i(x, y))


func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


func _fill(r: Rect2i, t: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _in(x, y):
				tiles[y * W + x] = t


## Highways two cells wide; they bridge the river and cut passes through rock.
func _road(a: Vector2i, b: Vector2i) -> void:
	var p := a
	while p.y != b.y:
		_fill(Rect2i(p.x, p.y, 2, 1), ROAD)
		p.y += signi(b.y - p.y)
	while p.x != b.x:
		_fill(Rect2i(p.x, p.y, 1, 2), ROAD)
		p.x += signi(b.x - p.x)


func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not _in(x, y) or tiles[y * W + x] in [WALL, FLOOR, DOOR, WINDOW, ROAD, FIELD, WATER, ROCK, PAVE]:
				return false
	return true


func _holding(i: int) -> void:
	var p: Vector2i = PLACES[i][1]
	var half: Vector2i = PLACES[i][2]
	var h := {"name": PLACES[i][0], "center": p, "half": half, "hall": -1, "houses": [], "fields": [], "claimed": i == 0, "crypt": false}
	holdings.append(h)
	# the hall (in the capital, the palace): the holding's heart and its shelter at night
	var hall := Rect2i(p.x - 6, p.y - 4, 13, 9) if i == 0 else Rect2i(p.x - 4, p.y - 3, 9, 7)
	h.hall = _house(hall, true, i)
	h.houses.append(h.hall)
	# fields and cottages around it: the capital's fields first (it must eat), then the rest
	if i == 0:
		_patches(h, 3)
	_cottages(h, int(PLACES[i][3]))
	if i != 0:
		_patches(h, 2)


## Spots around a holding's centre, corners and sides first, then anywhere on its ground.
func _spots(h: Dictionary, size: Vector2i) -> Array:
	var p: Vector2i = h.center
	var half: Vector2i = h.half
	var lo := -half
	var hi := half - size + Vector2i.ONE
	var out := []
	for y in [lo.y, hi.y, 0 - size.y / 2]:
		for x in [lo.x, hi.x, 0 - size.x / 2, lo.x + size.x + 1, hi.x - size.x - 1]:
			out.append(Rect2i(p + Vector2i(x, y), size))
	for k in 400:
		out.append(Rect2i(p + Vector2i(rng.randi_range(lo.x, hi.x), rng.randi_range(lo.y, hi.y)), size))
	return out


func _cottages(h: Dictionary, n: int) -> void:
	var hi := holdings.find(h)
	var size := Vector2i(rng.randi_range(4, 5), 4) if hi == 0 else Vector2i(rng.randi_range(5, 6), rng.randi_range(4, 5))
	for r in _spots(h, size):
		if h.houses.size() > n:
			return
		if _free(r.grow(1)) and _within(hi, r):
			h.houses.append(_house(r, false, hi))


func _patches(h: Dictionary, n: int) -> void:
	for r in _spots(h, Vector2i(5, 4)):
		if n <= 0:
			return
		if _free(r.grow(1)) and _within(holdings.find(h), r):
			_fill(r, FIELD)
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					h.fields.append(Vector2i(x, y))
			n -= 1


## The palisade runs round an octagon: the holding's ground with its corners cut off.
func cut(h: int) -> int:
	var half: Vector2i = holdings[h].half
	return int(mini(half.x, half.y) * 0.45)


func in_ring(h: int, c: Vector2i, margin := 0) -> bool:
	var hd: Dictionary = holdings[h]
	var d: Vector2i = (c - hd.center).abs()
	return d.x <= hd.half.x - margin and d.y <= hd.half.y - margin and d.x + d.y <= hd.half.x + hd.half.y - cut(h) - margin


## Room to spare between a building or field and its wall.
func _within(h: int, r: Rect2i) -> bool:
	for c in [r.position, Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), r.end - Vector2i.ONE]:
		if not in_ring(h, c, 1):
			return false
	return true


## Inside the capital's wall: paved streets in a grid and around the palace, with gardens between.
func _streets() -> void:
	var h: Dictionary = holdings[0]
	var hall: Rect2i = houses[h.hall].rect
	for y in range(h.center.y - h.half.y, h.center.y + h.half.y + 1):
		for x in range(h.center.x - h.half.x, h.center.x + h.half.x + 1):
			var c := Vector2i(x, y)
			if at(c) != GRASS or not in_ring(0, c, 1):
				continue
			var d: Vector2i = c - h.center
			if not in_ring(0, c, 3) or posmod(d.x, 7) == 0 or posmod(d.y, 6) == 0 or hall.grow(2).has_point(c):
				tiles[y * W + x] = PAVE


func _crypt() -> void:
	var h := {"name": "The Black Crypt", "center": CRYPT, "half": Vector2i(8, 5), "hall": -1, "houses": [], "fields": [],
		"claimed": false, "crypt": true}
	holdings.append(h)
	_fill(Rect2i(CRYPT.x - 6, CRYPT.y - 3, 12, 7), GRAVE)
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
	var p: Vector2i = holdings[holding].center
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


## Open water and sheer rock: nobody, living or dead, walks there.
func impassable(t: int) -> bool:
	return t == WALL or t == WATER or t == ROCK


func cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / T)), int(floor(p.y / T)))


func center(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * T, (c.y + 0.5) * T)


func hall_rect(holding: int) -> Rect2i:
	return houses[holdings[holding].hall].rect


func holding_area(holding: int) -> Rect2i:
	var hd: Dictionary = holdings[holding]
	return Rect2i(hd.center - hd.half, hd.half * 2 + Vector2i.ONE)
