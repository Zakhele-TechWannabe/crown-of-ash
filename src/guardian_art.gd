extends RefCounted
## Upright weathered stone and a separate plinth, cached at map texel scale.
const Palette = preload("res://src/palette.gd")
const BuildingArt = preload("res://src/building_art.gd")
static var cache: Dictionary = {}

static func texture(state: String, facing: String = "south") -> ImageTexture:
	var key := state + ":" + facing
	if not cache.has(key): cache[key] = ImageTexture.create_from_image(image(state, facing))
	return cache[key]

static func image(state: String, facing: String = "south") -> Image:
	var im := Image.create(22, 34, false, Image.FORMAT_RGBA8)
	var stone := Palette.STONE.darkened(0.18)
	var moss := Palette.GREEN.darkened(0.4)
	if state == "frozen": stone = stone.lerp(Palette.PAPER_DARK, 0.3)
	if state == "plinth":
		im.fill_rect(Rect2i(2, 25, 17, 8), stone.darkened(0.2))
		im.fill_rect(Rect2i(1, 24, 19, 3), stone.lightened(0.18))
		im.fill_rect(Rect2i(3, 28, 15, 1), Palette.OUTLINE)
		im.fill_rect(Rect2i(4, 30, 13, 1), stone.lightened(0.15))
	elif state == "broken":
		for r: Rect2i in [Rect2i(3, 27, 7, 5), Rect2i(9, 25, 6, 7), Rect2i(14, 28, 5, 4), Rect2i(6, 24, 4, 4)]:
			im.fill_rect(r, stone)
			im.fill_rect(Rect2i(r.position, Vector2i(r.size.x, 1)), stone.lightened(0.2))
		im.fill_rect(Rect2i(12, 20, 2, 8), Palette.BRASS)
		im.fill_rect(Rect2i(10, 23, 6, 1), Palette.OUTLINE)
	elif facing in ["west", "east"]:
		var lift := 7 if state == "guarding" else 0
		var forward := -1 if facing == "west" else 1
		im.fill_rect(Rect2i(8, 9 - lift, 6, 4), stone.darkened(0.2))
		im.fill_rect(Rect2i(8, 12 - lift, 6, 6), stone)
		im.fill_rect(Rect2i(7 if forward < 0 else 14, 14 - lift, 2, 2), stone.lightened(0.14))
		im.fill_rect(Rect2i(9, 12 - lift, 2, 3), stone.lightened(0.22))
		im.fill_rect(Rect2i(8 if forward < 0 else 13, 14 - lift, 1, 1), Palette.JADE if state != "frozen" else Palette.OUTLINE)
		for y in range(18, 32):
			var spread := (y - 18) / 6
			im.fill_rect(Rect2i(8 - spread, y - lift, 7 + spread * 2, 1), stone)
		im.fill_rect(Rect2i(8, 18 - lift, 2, 11), stone.lightened(0.17))
		im.fill_rect(Rect2i(14, 19 - lift, 2, 10), stone.darkened(0.3))
		im.fill_rect(Rect2i(9, 19 - lift, 4, 8), stone.lightened(0.1))
		var sword_x := 6 if forward < 0 else 16
		im.fill_rect(Rect2i(sword_x, 21 - lift, 2, 10), Palette.PAPER_LIGHT)
		im.fill_rect(Rect2i(sword_x - 2, 20 - lift, 6, 1), Palette.BRASS)
		im.fill_rect(Rect2i(9, 18 - lift, 4, 2), stone.lightened(0.25))
		im.fill_rect(Rect2i(8, 27 - lift, 3, 3), moss)
	else:
		var lift := 7 if state == "guarding" else 0
		im.fill_rect(Rect2i(8, 9 - lift, 5, 4), stone.darkened(0.2))
		im.fill_rect(Rect2i(7, 12 - lift, 7, 6), stone.lightened(0.18))
		for y in range(18, 32):
			var spread := (y - 18) / 5
			im.fill_rect(Rect2i(6 - spread, y - lift, 10 + spread * 2, 1), stone)
		im.fill_rect(Rect2i(6, 18 - lift, 3, 11), stone.lightened(0.17))
		im.fill_rect(Rect2i(13, 19 - lift, 2, 11), stone.darkened(0.3))
		im.fill_rect(Rect2i(7, 18 - lift, 3, 2), moss)
		im.fill_rect(Rect2i(4, 29 - lift, 4, 2), moss)
		im.fill_rect(Rect2i(12, 25 - lift, 1, 4), Palette.OUTLINE)
		var eyes := stone.darkened(0.5) if state == "frozen" else Palette.JADE.lightened(0.35 if state == "pursuing" else 0.0)
		for x in [8, 11]: im.fill_rect(Rect2i(x, 14 - lift, 2, 1), eyes)
		if state == "pursuing":
			im.fill_rect(Rect2i(16, 6, 2, 17), Palette.PAPER_LIGHT)
			im.fill_rect(Rect2i(14, 21, 6, 1), Palette.BRASS)
			im.fill_rect(Rect2i(16, 23, 2, 4), Palette.EARTH)
		else:
			im.fill_rect(Rect2i(10, 21 - lift, 2, 10), Palette.PAPER_LIGHT)
			im.fill_rect(Rect2i(8, 20 - lift, 6, 1), Palette.BRASS)
			im.fill_rect(Rect2i(8, 18 - lift, 6, 2), stone.lightened(0.25))
		if state == "frozen":
			im.fill_rect(Rect2i(12, 17, 3, 3), moss)
			im.fill_rect(Rect2i(7, 27, 3, 3), moss)
	BuildingArt._outline(im)
	return im
