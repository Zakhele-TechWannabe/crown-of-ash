extends RefCounted
## Stateless site override shared by near and far samplers and worker chunks.
static func weight(tile: Vector2i) -> float:
	var edge := minf(minf(tile.x - 1515, 2110 - tile.x), minf(tile.y - 2105, 2515 - tile.y))
	return smoothstep(0, 65, edge + 10 * sin(tile.y * 0.045) + 7 * sin(tile.x * 0.063))

static func mountain_height(tile: Vector2i, natural: float) -> float:
	var w := weight(tile)
	var rise := clampf((tile.x - 1515) / 480.0, 0, 1)
	var ridge := sin(tile.y * 0.035 + tile.x * 0.009) * 0.018
	var ravine := exp(-pow((tile.y - 2220 - 18 * sin(tile.x * 0.02)) / 12.0, 2)) * 0.035
	return lerpf(natural, 0.72 + rise * 0.50 + ridge - ravine, w)

static func clearing(tile: Vector2i) -> bool:
	for i in 3:
		var x := 1610 + i * 125
		var y := roundi(2320 + 65 * cos((x - 1510) / 480.0 * TAU * 2))
		if Vector2(tile - Vector2i(x, y)).length_squared() < 100:
			return true
	return Vector2(tile - Vector2i(1987, 2378)).length_squared() < 120

static func color(tile: Vector2i) -> Color:
	return Color8(73, 91, 55) if clearing(tile) else Color8(17, 42, 35)

static func draw(image: Image, tile: Vector2i, pos: Vector2i, occupied: bool) -> void:
	if weight(tile) < 0.25:
		return
	var clear := clearing(tile)
	var base := Color8(48, 68, 43) if clear else Color8(24, 43, 35)
	# Canopy shade is baked into the ground, including the trail.
	if not occupied:
		image.fill_rect(Rect2i(pos, Vector2i(16, 16)), base)
	else:
		for yy in 16:
			for xx in 16:
				var at := pos + Vector2i(xx, yy)
				image.set_pixelv(at, image.get_pixelv(at).darkened(0.35))
	var hash_value := absi(tile.x * 374761 + tile.y * 668265)
	if clear:
		if hash_value % 7 == 0 and not occupied:
			image.fill_rect(Rect2i(pos + Vector2i(2, 2), Vector2i(7, 3)), Color8(118, 133, 77))
		return
	if occupied:
		return
	for rock_at in [Vector2i(1855, 2190), Vector2i(1950, 2440)]:
		if Vector2(tile - rock_at).length_squared() < 60:
			image.fill_rect(Rect2i(pos, Vector2i(16, 16)), Color8(66, 76, 72))
			image.fill_rect(Rect2i(pos + Vector2i(1, 3), Vector2i(13, 1)), Color8(96, 106, 96))
			return
	# A coherent 3x3 tile crown: 48 pixels across versus a normal 16px tree.
	var cell := Vector2i(floori(tile.x / 3.0), floori(tile.y / 3.0))
	var crown_hash := absi(cell.x * 73856093 ^ cell.y * 19349663)
	var q := Vector2((posmod(tile.x, 3) * 16), (posmod(tile.y, 3) * 16))
	var crown_center := Vector2(20 + crown_hash % 9, 18 + (crown_hash / 11) % 12)
	var radius := 22.0 + crown_hash % 8
	var tint := float(crown_hash % 17) / 400.0
	for yy in 16:
		for xx in 16:
			var delta := q + Vector2(xx, yy) - crown_center
			if delta.length_squared() < radius * radius + 40 * sin((xx + tile.x * 16) * 0.25):
				var col := (Color8(23, 52, 41) if delta.x + delta.y * 0.4 < 0 else Color8(14, 34, 31)).lightened(tint)
				if sin(delta.x * 0.35) + cos(delta.y * 0.37) > 1.1:
					col = col.lightened(0.045)
				image.set_pixelv(pos + Vector2i(xx, yy), col)
	# Buttress roots show through small gaps beneath the oldest crowns.
	if posmod(tile.x, 3) == 1 and posmod(tile.y, 3) == 2 and crown_hash % 4 == 0:
		image.fill_rect(Rect2i(pos + Vector2i(7, 1), Vector2i(3, 9)), Color8(48, 52, 39))
		for step in 7:
			image.set_pixelv(pos + Vector2i(7 - step, 7 + step), Color8(64, 66, 44))
			image.set_pixelv(pos + Vector2i(9 + step, 6 + step), Color8(64, 66, 44))
	if hash_value % 29 == 0:
		image.fill_rect(Rect2i(pos + Vector2i(2, 9), Vector2i(12, 3)), Color8(65, 63, 43))
	elif hash_value % 11 == 0:
		for offset in [Vector2i(3, 10), Vector2i(5, 8), Vector2i(7, 10)]:
			image.fill_rect(Rect2i(pos + offset, Vector2i(2, 4)), Color8(49, 80, 52))
