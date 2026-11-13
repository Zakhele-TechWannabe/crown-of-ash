extends RefCounted
## Cached upright worksite and boundary art; all dimensions are map texels.
const Palette = preload("res://src/palette.gd")
const BuildingArt = preload("res://src/building_art.gd")
static var _cache: Dictionary = {}

static func texture(kind: String, w: int, h: int, variant: int) -> ImageTexture:
	var key := "%s:%d:%d:%d" % [kind, w, h, variant]
	if not _cache.has(key): _cache[key] = ImageTexture.create_from_image(_build(kind, w, h, variant))
	return _cache[key]

static func anchor(h: int) -> Vector2:
	return Vector2(3, h * 16 + 36)

static func _box(im: Image, r: Rect2i, col: Color) -> void:
	im.fill_rect(r, col)
	im.fill_rect(Rect2i(r.position, Vector2i(r.size.x, 1)), col.lightened(0.16))
	im.fill_rect(Rect2i(r.end - Vector2i(2, r.size.y), Vector2i(2, r.size.y)), col.darkened(0.22))

static func _build(kind: String, w: int, h: int, variant: int) -> Image:
	var width := w * 16
	var im := Image.create(width + 6, h * 16 + 36, false, Image.FORMAT_RGBA8)
	var foot := im.get_height() - 2
	var timber := Palette.EARTH.darkened(0.5)
	var stone := Palette.STONE.darkened(0.14)
	var roof := Palette.STONE.darkened(0.42).lerp(Palette.BLUE, 0.12)
	match kind:
		"wall":
			_box(im, Rect2i(3, foot - 22, width, 22), stone)
			for y in range(foot - 19, foot, 6):
				im.fill_rect(Rect2i(3, y, width, 1), stone.darkened(0.22))
				for x in range(3 + (8 if y % 12 < 6 else 0), width, 16): im.fill_rect(Rect2i(x, y - 5, 1, 5), stone.darkened(0.18))
			_box(im, Rect2i(1, foot - 26, width + 4, 5), roof)
			for x in range(3, width + 3, 5): im.fill_rect(Rect2i(x, foot - 26, 1, 4), roof.lightened(0.16))
		"fence":
			for rail in [6, 12]: _box(im, Rect2i(3, foot - rail, width, 3), timber)
			for x in range(3, width + 2, 16): _box(im, Rect2i(x, foot - 18, 4, 18), timber)
		"fence_side":
			for x in [10, 13]: _box(im, Rect2i(x, foot - 28, 2, 16), timber)
			_box(im, Rect2i(9, foot - 34, 4, 18), timber)
			_box(im, Rect2i(9, foot - 18, 4, 18), timber)
		"gate":
			for x in [7, width - 4]:
				_box(im, Rect2i(x - 2, foot - 3, 9, 4), stone)
				_box(im, Rect2i(x, foot - 30, 5, 28), Palette.RED.darkened(0.18))
			_box(im, Rect2i(5, foot - 30, width - 3, 4), timber)
			for y in 12:
				var inset := maxi(0, 10 - y)
				im.fill_rect(Rect2i(inset, foot - 44 + y, im.get_width() - inset * 2, 1), roof.lightened(0.09) if y % 4 == 0 else roof)
			_box(im, Rect2i(1, foot - 33, width + 4, 3), roof.darkened(0.2))
			for x in [1, width + 1]: _box(im, Rect2i(x, foot - 36, 4, 4), roof)
		"hive":
			for x in [5, 17]: _box(im, Rect2i(x, foot - 5, 3, 5), timber)
			_box(im, Rect2i(4, foot - 17, 19, 13), Palette.BRASS)
			for y in range(foot - 15, foot - 4, 4): im.fill_rect(Rect2i(5, y, 16, 1), timber)
			_box(im, Rect2i(2, foot - 20, 23, 4), roof)
			im.fill_rect(Rect2i(11, foot - 7, 5, 2), Palette.INK)
		"smith", "kiln":
			_box(im, Rect2i(9, foot - 40, 9, 30), stone.darkened(0.25))
			_box(im, Rect2i(7, foot - 42, 13, 4), roof)
			_box(im, Rect2i(3, foot - 23, 29, 23), Palette.EARTH.darkened(0.22))
			for y in range(foot - 20, foot, 5): im.fill_rect(Rect2i(4, y, 26, 1), stone.darkened(0.25))
			_box(im, Rect2i(12, foot - 13, 12, 13), Palette.INK)
			im.fill_rect(Rect2i(15, foot - 7, 6, 5), Palette.RED)
			im.fill_rect(Rect2i(16, foot - 4, 3, 2), Palette.GOLD)
		"mine", "quarry":
			for i in 5: _box(im, Rect2i(3 + i * 8, foot - 18 - (i % 3) * 5, 12, 18 + (i % 3) * 5), stone)
			if kind == "mine":
				_box(im, Rect2i(16, foot - 23, 18, 23), Palette.INK)
				for x in [13, 34]: _box(im, Rect2i(x, foot - 25, 4, 25), timber)
				_box(im, Rect2i(12, foot - 27, 27, 4), timber)
		"logs", "woodcutting":
			for i in 4:
				var p := Vector2i(4 + i % 2 * 23, foot - 5 - i / 2 * 8)
				_box(im, Rect2i(p, Vector2i(21, 5)), timber)
				im.fill_rect(Rect2i(p, Vector2i(3, 5)), Palette.BRASS)
				if kind == "logs": _box(im, Rect2i(p + Vector2i(8, -3), Vector2i(5, 3)), Palette.PAPER_DARK)
		"hunt", "tanner", "weaver", "fishery":
			for x in [5, width - 4]: _box(im, Rect2i(x, foot - 25, 3, 25), timber)
			_box(im, Rect2i(4, foot - 26, width - 3, 3), timber)
			for x in range(10, width - 4, 6):
				im.fill_rect(Rect2i(x, foot - 23, 1, 17), Palette.PAPER_DARK)
				if kind != "fishery": _box(im, Rect2i(x - 1, foot - 20, 4, 12), Palette.PAPER_DARK if kind == "weaver" else Palette.EARTH.darkened(0.18))
		"pig", "chicken":
			var pig := kind == "pig"
			var coat := Palette.EARTH.lerp(Palette.RED, 0.2) if pig else Palette.PAPER_DARK
			for x in [6, 15]: _box(im, Rect2i(x, foot - 4, 2, 4), timber)
			_box(im, Rect2i(4, foot - 11, 14 if pig else 9, 8), coat)
			_box(im, Rect2i(14, foot - 13, 5, 7), coat)
			im.set_pixel(17, foot - 11, Palette.INK)
			if not pig: im.set_pixel(18, foot - 8, Palette.GOLD)
		"sign", "tool":
			_box(im, Rect2i(10, foot - 22, 3, 22), timber)
			if kind == "sign":
				_box(im, Rect2i(3, foot - 24, 18, 9), Palette.BRASS)
				im.fill_rect(Rect2i(6, foot - 21, 10, 1), timber)
				im.fill_rect(Rect2i(6, foot - 18, 7, 1), timber)
			else:
				for x in [6, 10, 14]: _box(im, Rect2i(x, foot - 29, 2, 8), stone.darkened(0.4))
				_box(im, Rect2i(6, foot - 22, 10, 2), stone.darkened(0.4))
		"boat":
			for y in 13:
				var inset := absi(y - 6) / 2
				im.fill_rect(Rect2i(3 + inset, foot - 14 + y, width - inset * 2, 1), timber)
				if y > 2 and y < 10: im.fill_rect(Rect2i(5 + inset, foot - 14 + y, width - inset * 2 - 4, 1), Palette.EARTH.darkened(0.25))
			for x in range(7, width, 7): _box(im, Rect2i(x, foot - 12, 2, 9), Palette.BRASS)
		"stall", "tent", "kitchen":
			for x in [5, width - 4]: _box(im, Rect2i(x, foot - 20, 3, 20), timber)
			_box(im, Rect2i(4, foot - 7, width - 3, 6), timber)
			for y in 12:
				var inset := (11 - y) / 2
				im.fill_rect(Rect2i(inset, foot - 31 + y, im.get_width() - inset * 2, 1), Palette.EARTH.darkened(0.25) if kind == "kitchen" else Palette.PAPER_DARK.lerp(Palette.RED, variant * 0.07))
		_:
			_box(im, Rect2i(6, foot - 12, 12, 12), stone)
	BuildingArt._outline(im)
	return im


## Quiet painted ground tiles, cached by exposed edge, season and local variation.
static func ground_texture(kind: String, edges: int, variant: int, winter: bool) -> ImageTexture:
	var key := "ground:%s:%d:%d:%s" % [kind, edges, variant, winter]
	if _cache.has(key): return _cache[key]
	var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var soil := Palette.EARTH.darkened(0.12)
	if kind == "fishery": soil = Palette.BLUE.lerp(Palette.JADE, 0.25)
	elif kind == "clay": soil = Palette.EARTH.lerp(Palette.RED, 0.16).darkened(0.12)
	elif kind != "garden" and kind != "herd": soil = Palette.STONE.lerp(Palette.EARTH, 0.55)
	for y in 16:
		for x in 16:
			var creep := 1 + posmod(x * 7 + y * 3 + variant, 3) / 2
			if (edges & 1 and x < creep) or (edges & 2 and x >= 16 - creep) or (edges & 4 and y < creep) or (edges & 8 and y >= 16 - creep): continue
			var col := soil
			if posmod(x * 13 + y * 7 + variant, 29) < 2: col = col.darkened(0.07)
			if kind == "garden":
				if y % 5 == 0: col = soil.darkened(0.14)
				if not winter and y % 5 == 2 and x % 5 in [1, 2]: col = [Palette.GREEN, Palette.GRASS, Palette.BRASS, Palette.JADE][variant]
			elif kind == "fishery":
				if y % 6 == 2 and posmod(x + y + variant, 9) < 4: col = soil.lightened(0.12)
				if (edges & 1 and x == creep) or (edges & 4 and y == creep): col = Palette.PAPER_DARK.lerp(soil, 0.5)
			elif kind == "clay":
				if edges != 0: col = soil.lightened(0.1) if y < 8 else soil.darkened(0.14)
				else: col = soil.darkened(0.19)
			im.set_pixel(x, y, col)
	_cache[key] = ImageTexture.create_from_image(im)
	return _cache[key]
