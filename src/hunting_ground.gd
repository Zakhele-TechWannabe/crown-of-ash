extends RefCounted
## World-coordinate foliage and local segment buckets; immutable during worker baking.
var segments: Dictionary = {}

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
	var col := Color8(22, 44, 36).lerp(Color8(44, 62, 39), (field(p, 23) + 1) * 0.5)
	if clearing(tile):
		col = Color8(67, 77, 43)
	if rocky(tile):
		col = Color8(66, 77, 72) * (0.8 + (field(p, 6) + 1.0) * 0.24)
	var dx := mountain_height(tile + Vector2i(3, 0), 0.8) - mountain_height(tile - Vector2i(3, 0), 0.8)
	var dy := mountain_height(tile + Vector2i(0, 3), 0.8) - mountain_height(tile - Vector2i(0, 3), 0.8)
	col *= clampf(1.0 - (dx + dy) * 12.0, 0.55, 1.4)
	col.a = 1.0
	return col

func setup() -> void:
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
	var w := weight(tile)
	if w <= 0.0 or occupied:
		return
	var clear := clearing(tile)
	var rock := rocky(tile)
	var base := color(tile)
	var local: Array = []
	for segment: Array in segments.get(Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0)), []):
		if (Vector2(tile) + Vector2.ONE * 0.5).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(tile) + Vector2.ONE * 0.5, segment[0], segment[1])) < 1.6:
			local.append(segment)
	var crowns: Array = []
	var cell := Vector2i(floori(tile.x / 3.0), floori(tile.y / 3.0))
	for cy in range(cell.y - 2, cell.y + 3):
		for cx in range(cell.x - 2, cell.x + 3):
			var h := hash_at(cx, cy)
			var center := Vector2(cx * 3 + (h % 1000) / 333.0, cy * 3 + ((h >> 10) % 1000) / 333.0)
			var radius := 1.0 + ((h >> 7) % 1000) / 666.0
			if center.distance_to(Vector2(tile) + Vector2.ONE * 0.5) > radius * 1.23 + 0.71:
				continue
			var at := Vector2i(center)
			var crown_segments: Array = segments.get(Vector2i(floori(center.x / 16.0), floori(center.y / 16.0)), [])
			if h % 1000 > weight(at) * 960 or clearing(at) or rocky(at) or trail(center, crown_segments) > 0.1:
				continue
			crowns.append([center, radius, h])
	crowns.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	var blobs: Array = []
	for crown: Array in crowns:
		var seed: int = crown[2]
		var tint := Color8(10, 28, 29).lerp(Color8(36, 57, 36), float(seed % 100) / 100.0) * clampf(base.g * 255.0 / 52.0, 0.65, 1.25)
		if seed % 67 == 0:
			tint = Color8(63, 67, 57)
		for blob in range(3 + seed % 4):
			var bh := hash_at(seed % 100003, blob)
			var offset := Vector2(cos(bh % 628 / 100.0), sin(bh % 628 / 100.0)) * float(crown[1]) * 0.46
			blobs.append([crown[0] + offset, float(crown[1]) * (0.48 + bh % 29 / 100.0), tint])
	var bounds := Rect2i(pos, Vector2i(16, 16))
	for yy in 16:
		for xx in 16:
			var p := Vector2(tile) + Vector2(xx + 0.5, yy + 0.5) / 16.0
			var h := hash_at(tile.x * 16 + xx, tile.y * 16 + yy)
			var col := base * (0.93 + h % 17 / 100.0)
			if clear:
				col = col.lightened(maxf(0, field(p, 2.7) - 0.25) * 0.22)
			elif rock:
				var seam := field(p, 3.8) + field(p, 1.7) * 0.35
				if absf(seam) < 0.028:
					col = col.darkened(0.3)
				elif seam > 0.4:
					col = col.lightened(0.09)
			else:
				if h % 193 == 0:
					col = Color8(51, 76, 43)
				elif h % 197 < 2:
					col = Color8(61, 57, 39)
			col.a = 1.0
			var at := pos + Vector2i(xx, yy)
			image.set_pixelv(at, image.get_pixelv(at).lerp(col, w))
	if not clear and not rock:
		var detail := hash_at(tile.x, tile.y)
		if detail % 23 == 0:
			for step in 10:
				image.fill_rect(Rect2i(pos + Vector2i(2 + step, 4 + step / 2), Vector2i(2, 2)), Color8(57, 53, 38))
		elif detail % 9 == 0:
			for step in 5:
				for side in [-1, 1]:
					image.fill_rect(Rect2i(pos + Vector2i(8 + side * step, 9 - step / 2), Vector2i(2, 1)), Color8(47, 70, 41))
	# Roots and fallen wood are painted underneath the crowns, visible only in gaps.
	for crown: Array in crowns:
		var center: Vector2 = Vector2(pos) + (crown[0] - Vector2(tile)) * 16.0
		for step in range(0, ceili(float(crown[1]) * 16)):
			for side in [-1, 0, 1]:
				var at := Vector2i(center) + Vector2i(roundi(step * side * 0.36), step)
				if bounds.has_point(at):
					image.set_pixelv(at, Color8(59, 55, 39))
	# Scanline spans avoid searching every crown at every pixel. All clipping is tile-local.
	for blob: Array in blobs:
		var center: Vector2 = Vector2(pos) + (blob[0] - Vector2(tile)) * 16.0
		var r: float = blob[1] * 16.0
		for y in range(maxi(pos.y, ceili(center.y - r)), mini(pos.y + 16, floori(center.y + r) + 1)):
			var dy := (y + 0.5 - center.y) / r
			var half_span := sqrt(maxf(0, 1.0 - dy * dy)) * r
			var left := maxi(pos.x, ceili(center.x - half_span))
			var right := mini(pos.x + 16, ceili(center.x + half_span))
			for band in 4:
				var x0 := maxi(left, floori(center.x - r + band * r * 0.5))
				var x1 := mini(right, floori(center.x - r + (band + 1) * r * 0.5))
				if x1 <= x0:
					continue
				var col: Color = blob[2] * clampf(1.13 - band * 0.12 - dy * 0.2, 0.6, 1.3)
				col.a = 1.0
				if w > 0.99:
					image.fill_rect(Rect2i(x0, y, x1 - x0, 1), col)
				else:
					for x in range(x0, x1):
						image.set_pixel(x, y, image.get_pixel(x, y).lerp(col, w))
	# The packed-earth ribbon has subpixel coverage and a textured, soft edge.
	if not local.is_empty():
		for yy in 16:
			for xx in 16:
				var p := Vector2(tile) + Vector2(xx + 0.5, yy + 0.5) / 16.0
				var amount := trail(p, local)
				if amount <= 0:
					continue
				var h := hash_at(tile.x * 16 + xx, tile.y * 16 + yy)
				var col := Color8(83, 77, 53) * (0.9 + h % 21 / 100.0)
				if h % 83 < 3:
					col = Color8(53, 51, 35)
				col.a = 1.0
				var at := pos + Vector2i(xx, yy)
				image.set_pixelv(at, image.get_pixelv(at).lerp(col, amount * w))
