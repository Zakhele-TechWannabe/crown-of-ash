extends RefCounted
## Code-built buildings in three-quarter view at the map's texel (16 per tile): the roof covers the
## footprint and rises above it, the front wall shows at the bottom with its door and windows.
## A door is a little taller than a villager (about 18 texels), so scale reads at a glance.
const Palette = preload("res://src/palette.gd")
## Overhang of the eaves beyond the walls, and how far a roof rises above its footprint, in texels.
const EAVE := 3
const RISE := {"house": 14, "hall": 22, "cave": 22}

static var _cache: Dictionary = {}


## Texture for a building, cached by kind, size and variant.
static func texture(kind: String, w: int, h: int, variant: int) -> ImageTexture:
	var key := "%s:%d:%d:%d" % [kind, w, h, variant]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_build(kind, w, h, variant))
	return _cache[key]


## Where the bottom-left corner of the footprint sits inside the image.
static func anchor(kind: String, h: int) -> Vector2:
	return Vector2(EAVE, h * 16 + RISE[kind])


static func _build(kind: String, w: int, h: int, variant: int) -> Image:
	if kind == "cave": return _cave(w, h, variant)
	var hall := kind == "hall"
	var width := w * 16
	var size := Vector2i(width + EAVE * 2, h * 16 + RISE[kind])
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var footing := 5 if hall else 3
	# Bigger halls stand taller: the wall grows with the footprint so the roof never swamps it.
	var wall := (clampi(h * 4, 30, 60) if hall else 22) if h > 2 else 18
	var wall_top := size.y - footing - wall
	# Stone footing along the front.
	image.fill_rect(Rect2i(EAVE, size.y - footing, width, footing), Palette.STONE.darkened(0.12))
	image.fill_rect(Rect2i(EAVE, size.y - footing, width, 1), Palette.STONE.lightened(0.1))
	# Front wall: plaster between timber posts (a house) or a red-columned front (a hall).
	var plaster := Palette.PAPER_LIGHT.darkened(0.04) if not hall else Palette.PAPER.darkened(0.06)
	image.fill_rect(Rect2i(EAVE, wall_top, width, wall), plaster)
	var post := Palette.RED.darkened(0.15) if hall else Palette.EARTH.darkened(0.55)
	var bay := 32 if hall else (width if w <= 7 else 48)
	for x in range(0, width + 1, bay):
		image.fill_rect(Rect2i(EAVE + mini(x, width - 3), wall_top, 3, wall), post)
	image.fill_rect(Rect2i(EAVE, wall_top + wall - 2, width, 2), post.darkened(0.1))
	# Doors face the lane; long rows get one door per dwelling.
	var door := Vector2i(16 if hall else 9, 26 if hall else 19)
	if hall and w >= 15: door = Vector2i(22, mini(wall - 6, 40))
	var doors: Array[int] = []
	if hall and w >= 15:
		doors.append_array([width / 2 - 64, width / 2, width / 2 + 64])
	elif width <= 7 * 16 or hall:
		doors.append(width / 2)
	else:
		for x in range(24, width - 16, 48): doors.append(x)
	for x: int in doors:
		var at := Vector2i(EAVE + x - door.x / 2, size.y - footing - door.y)
		image.fill_rect(Rect2i(at - Vector2i(1, 1), door + Vector2i(2, 1)), Palette.EARTH.darkened(0.6))
		image.fill_rect(Rect2i(at, door), Palette.EARTH.darkened(0.42))
		image.fill_rect(Rect2i(at + Vector2i(door.x / 2, 0), Vector2i(1, door.y)), Palette.EARTH.darkened(0.6))
		image.set_pixelv(at + Vector2i(door.x / 2 - 2, door.y / 2), Palette.GOLD)
	# Lattice windows between the doors.
	var window := Vector2i(10, 8) if hall else Vector2i(8, 7)
	var spots: Array[int] = []
	for x in range(8, width / 2 - window.x / 2, 24 if hall else 22):
		spots.append(x)
		spots.append(width - x - window.x)
	for x: int in spots:
		var clear := true
		for d: int in doors:
			if absi(x + window.x / 2 - d) < door.x / 2 + window.x / 2 + 3: clear = false
		if not clear: continue
		var at := Vector2i(EAVE + x, wall_top + (8 if hall else 6))
		image.fill_rect(Rect2i(at - Vector2i(1, 1), window + Vector2i(2, 2)), Palette.EARTH.darkened(0.55))
		image.fill_rect(Rect2i(at, window), Palette.PAPER_LIGHT)
		for k in range(2, window.x, 3): image.fill_rect(Rect2i(at + Vector2i(k, 0), Vector2i(1, window.y)), Palette.EARTH.darkened(0.3))
		image.fill_rect(Rect2i(at + Vector2i(0, window.y / 2), Vector2i(window.x, 1)), Palette.EARTH.darkened(0.3))
	# Roof: the front slope faces us, the ridge runs along the top, hipped ends to either side.
	var tones := [Palette.RED.darkened(0.12).lerp(Palette.EARTH.darkened(0.2), 0.35), Palette.RED.darkened(0.25).lerp(Palette.BRASS, 0.25), Palette.EARTH.darkened(0.35)]
	var roof: Color = Palette.STONE.darkened(0.42).lerp(Palette.BLUE.darkened(0.3), 0.3) if hall else tones[variant % tones.size()]
	var bottom := wall_top + 2
	var ridge := 3
	var inset := mini(width / 5, 24)
	for y in range(ridge, bottom):
		var t := float(y - ridge) / float(bottom - ridge)
		var left := int(lerpf(EAVE + inset, 0, t))
		var right := int(lerpf(size.x - EAVE - inset, size.x, t))
		if hall and t > 0.82:
			# Upturned eaves at the corners.
			var lift := int((t - 0.82) / 0.18 * 3)
			left = maxi(0, left - lift)
			right = mini(size.x, right + lift)
		for x in range(left, right):
			var col := roof
			var end := minf(x - left, right - 1 - x)
			if end < inset * (1.0 - t) + 2: col = roof.lightened(0.1) if x - left < right - 1 - x else roof.darkened(0.16)
			if (y - ridge) % 4 == 3: col = col.darkened(0.14)
			elif (x + (y / 4) * 2) % 5 == 0: col = col.darkened(0.06)
			image.set_pixel(x, y, col)
	image.fill_rect(Rect2i(EAVE + inset, ridge - 2, width - inset * 2, 3), roof.darkened(0.3))
	# Great halls get a second, lower eave: a double-eaved roof.
	if hall and w >= 15:
		var band := ridge + int((bottom - ridge) * 0.45)
		image.fill_rect(Rect2i(EAVE / 2, band, size.x - EAVE, 2), roof.darkened(0.35))
		image.fill_rect(Rect2i(EAVE / 2, band + 2, size.x - EAVE, 3), roof.darkened(0.18))
		for side in [EAVE / 2, size.x - EAVE / 2 - 4]:
			image.fill_rect(Rect2i(side, band - 3, 4, 3), roof.darkened(0.35))
	if hall:
		for side in [EAVE + inset - 2, size.x - EAVE - inset - 2]:
			image.fill_rect(Rect2i(side, ridge - 4, 4, 4), Palette.GOLD.darkened(0.2))
	# The eave throws a band of shade on the wall.
	for x in range(EAVE, EAVE + width):
		for y in range(bottom, mini(bottom + 3, size.y - footing)):
			image.set_pixel(x, y, image.get_pixel(x, y).darkened(0.25))
	_outline(image)
	return image


## A seclusion cave: a mossy outcrop with an arched mouth, a stone sill and a paper talisman sealing it.
static func _cave(w: int, h: int, variant: int) -> Image:
	var size := Vector2i(w * 16 + EAVE * 2, h * 16 + RISE["cave"])
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var rock := Palette.STONE.darkened(0.18 + variant * 0.04)
	var middle := size.x / 2.0
	# The outcrop: a rounded hump of rock, lit from the top left.
	for y in size.y:
		for x in size.x:
			var dx := (x + 0.5 - middle) / (size.x / 2.0)
			var top := size.y * (0.08 + 0.55 * dx * dx) + sin(x * 0.7 + variant) * 1.5
			if y < top: continue
			var light := -dx * 0.5 - float(y) / size.y * 0.4
			var col := rock.lightened(0.12) if light > 0.0 else (rock if light > -0.35 else rock.darkened(0.15))
			if (x * 7 + y * 3 + variant) % 23 == 0: col = col.darkened(0.25)
			if y < top + 3 and (x + variant) % 5 < 3: col = Palette.GREEN.darkened(0.2)
			image.set_pixel(x, y, col)
	# The arched mouth, darkest at the back.
	var mouth := Vector2i(16, 20)
	var left := int(middle) - mouth.x / 2
	var bottom := size.y - 3
	for y in mouth.y:
		var t := float(y) / mouth.y
		var half := int(mouth.x / 2.0 * sqrt(clampf(t * 1.6, 0.0, 1.0)))
		for x in range(-half, half):
			image.set_pixel(int(middle) + x, bottom - mouth.y + y, Palette.INK.lerp(Palette.INK_SOFT, absf(float(x)) / maxf(1, half) * 0.4))
	image.fill_rect(Rect2i(left - 3, bottom, mouth.x + 6, 3), Palette.STONE.lightened(0.05))
	# A talisman on a cord across the entrance.
	image.fill_rect(Rect2i(left, bottom - mouth.y + 6, mouth.x, 1), Palette.BRASS)
	image.fill_rect(Rect2i(int(middle) - 2, bottom - mouth.y + 7, 4, 8), Palette.GOLD.lightened(0.15))
	image.fill_rect(Rect2i(int(middle) - 1, bottom - mouth.y + 9, 2, 4), Palette.RED)
	_outline(image)
	return image


static func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	for y in image.get_height():
		for x in image.get_width():
			if source.get_pixel(x, y).a > 0.5: continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if bounds.has_point(Vector2i(x, y) + offset) and source.get_pixelv(Vector2i(x, y) + offset).a > 0.5:
					image.set_pixel(x, y, Palette.OUTLINE)
					break
