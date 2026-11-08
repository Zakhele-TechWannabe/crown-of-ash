extends RefCounted
## Seeded natural terrain, with tiles reserved for settlement growth.

enum { GRASS, FOREST, WATER, ROCK, SAND, ROAD, FIELD, HOUSE }
const W := 104
const H := 78
const T := 32.0

const PROVINCES := [
	["NYOKA MOUNTAINS", Vector2i(36, 4)], ["NYOKA PROVINCE", Vector2i(5, 12)], ["MALIBA PROVINCE", Vector2i(5, 33)],
	["BOMANI PROVINCE", Vector2i(4, 56)], ["KASAI PROVINCE", Vector2i(40, 74)], ["LUMBA PROVINCE", Vector2i(70, 74)],
	["NDELE PROVINCE", Vector2i(88, 48)], ["ZAWADI PROVINCE", Vector2i(69, 41)], ["KIRANGA PLATEAU", Vector2i(86, 4)],
	["THE GOLDEN COAST", Vector2i(95, 22)], ["THE KAMBARA RIVER", Vector2i(36, 54)], ["THE AGRICULTURAL BELT", Vector2i(68, 52)],
]
const RIVER := [Vector2i(34, 6), Vector2i(33, 14), Vector2i(31, 24), Vector2i(31, 36), Vector2i(32, 48), Vector2i(37, 54),
	Vector2i(41, 60), Vector2i(41, 68), Vector2i(39, 78)]

var tiles := PackedByteArray()
var falls: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()


## A seed always gives the same uninhabited landscape.
func build(seed_val: int) -> void:
	falls.clear()
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


## Cells beyond the map are rock.
func at(c: Vector2i) -> int:
	return tiles[c.y * W + c.x] if _in(c.x, c.y) else ROCK


## Only cells within the map can change.
func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


## The middle of a tile in drawing coordinates.
func center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * T
