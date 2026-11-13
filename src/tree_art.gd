extends RefCounted
## Code-built trees at the map's texel (16 per tile), sized against the people: a villager is about
## a tile tall, a broadleaf four to five tiles, a forest giant six or seven. Lit from the top left,
## ink-outlined like everything else that stands up off the ground.
const Palette = preload("res://src/palette.gd")
const CELL := Vector2i(112, 128)
## Where a tree's trunk meets the ground, inside its cell.
const FOOT := Vector2i(56, 122)
enum { OAK, BIRCH, CONIFER, GIANT, WILLOW, BAMBOO, SPIRIT, SHRUB }
const COUNT := 8
const VARIANTS := 4
## Ground shadow radius in texels, per species.
const SHADOW := [26, 20, 18, 40, 30, 16, 28, 9]

static var _texture: ImageTexture


static func texture() -> ImageTexture:
	if _texture == null:
		_texture = ImageTexture.create_from_image(_build())
	return _texture


static func region(species: int, variant: int) -> Rect2:
	return Rect2(Vector2(variant * CELL.x, species * CELL.y), Vector2(CELL))


static func _hash(a: int, b: int) -> int:
	var h := (a * 374761393 + b * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return h


static func _build() -> Image:
	var image := Image.create(CELL.x * VARIANTS, CELL.y * COUNT, false, Image.FORMAT_RGBA8)
	for species in COUNT:
		for variant in VARIANTS:
			var cell := Image.create(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
			_draw_tree(cell, species, variant)
			_outline(cell)
			image.blit_rect(cell, Rect2i(Vector2i.ZERO, CELL), Vector2i(variant * CELL.x, species * CELL.y))
	return image


## A filled disc lit from the top left, in four soft bands.
static func _blob(image: Image, center: Vector2, radius: float, colour: Color) -> void:
	for y in range(maxi(0, floori(center.y - radius)), mini(CELL.y, ceili(center.y + radius) + 1)):
		for x in range(maxi(0, floori(center.x - radius)), mini(CELL.x, ceili(center.x + radius) + 1)):
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radius
			if d.length_squared() > 1.0: continue
			var light := -(d.x + d.y) * 0.5
			var band := clampi(floori((light + 0.7) * 2.6), 0, 3)
			image.set_pixel(x, y, colour.darkened(0.24 - band * 0.1) if band < 3 else colour.lightened(0.1))


static func _trunk(image: Image, base: Vector2, height: int, width: int, colour: Color) -> void:
	for y in height:
		var w := width + (2 if y < 3 else 0)
		for x in w:
			var at := Vector2i(roundi(base.x) - w / 2 + x, roundi(base.y) - y)
			if Rect2i(Vector2i.ZERO, CELL).has_point(at):
				image.set_pixelv(at, colour.lightened(0.12) if x < w / 3 else colour)


static func _draw_tree(image: Image, species: int, variant: int) -> void:
	var foot := Vector2(FOOT)
	var scale := 0.88 + variant * 0.08
	var h := _hash(species * 7 + 3, variant * 13 + 5)
	match species:
		OAK, SPIRIT:
			var leaf := Palette.GREEN.lerp(Palette.GRASS.darkened(0.25), (h % 100) / 200.0)
			if species == SPIRIT: leaf = Palette.JADE.lightened(0.08)
			_trunk(image, foot, int(22 * scale), 8, Palette.EARTH.darkened(0.55))
			var crown := foot - Vector2(0, 44 * scale)
			for i in 8:
				var hh := _hash(h, i)
				var offset := Vector2(cos(hh % 628 / 100.0) * 1.15, sin(hh % 628 / 100.0) * 0.7) * 16.0 * scale
				_blob(image, crown + offset, (14.0 + hh % 7) * scale, leaf)
			_blob(image, crown + Vector2(-4, -6), 17.0 * scale, leaf)
			if species == SPIRIT:
				for i in 6:
					var hh := _hash(h + 99, i)
					image.set_pixel(int(crown.x) - 16 + hh % 32, int(crown.y) - 14 + (hh >> 5) % 26, Palette.GOLD.lightened(0.4))
		BIRCH:
			var leaf := Palette.GRASS.lerp(Palette.GREEN, 0.35)
			_trunk(image, foot, int(44 * scale), 4, Palette.PAPER_LIGHT.darkened(0.08))
			for y in range(6, int(44 * scale), 7):
				image.set_pixel(int(foot.x) - 1, int(foot.y) - y, Palette.INK)
			var crown := foot - Vector2(0, 56 * scale)
			for i in 5:
				var hh := _hash(h, i)
				_blob(image, crown + Vector2((hh % 17) - 8, (hh >> 6) % 30 - 15) * scale, (9.0 + hh % 4) * scale, leaf)
		CONIFER:
			var needle := Palette.JADE.darkened(0.42).lerp(Palette.GREEN.darkened(0.35), (h % 100) / 150.0)
			_trunk(image, foot, 14, 5, Palette.EARTH.darkened(0.6))
			var tiers := 5
			for t in tiers:
				var width := (20.0 - t * 3.4) * scale
				var bottom := foot.y - 10 - t * 15 * scale
				for y in int(20 * scale):
					var half := width * (float(y) / (20.0 * scale))
					for x in range(int(-half), int(half) + 1):
						var at := Vector2i(int(foot.x) + x, int(bottom - 20 * scale + y))
						if Rect2i(Vector2i.ZERO, CELL).has_point(at):
							image.set_pixelv(at, needle.lightened(0.12) if x < -half * 0.3 else (needle.darkened(0.15) if x > half * 0.45 else needle))
		GIANT:
			var leaf := Palette.JADE.darkened(0.5).lerp(Palette.GREEN.darkened(0.45), (h % 100) / 120.0)
			_trunk(image, foot, int(40 * scale), 11, Palette.EARTH.darkened(0.65))
			for side in [-1, 1]:
				for y in 4:
					image.fill_rect(Rect2i(int(foot.x) + side * (7 + y), int(foot.y) - y, 3, 1), Palette.EARTH.darkened(0.65))
			var crown := foot - Vector2(0, 74 * scale)
			for i in 9:
				var hh := _hash(h, i)
				var offset := Vector2(cos(hh % 628 / 100.0), sin(hh % 628 / 100.0) * 0.7) * 20.0 * scale
				_blob(image, crown + offset, (17.0 + hh % 7) * scale, leaf)
		WILLOW:
			var leaf := Palette.GRASS.darkened(0.08)
			_trunk(image, foot, int(30 * scale), 7, Palette.EARTH.darkened(0.5))
			var crown := foot - Vector2(0, 48 * scale)
			_blob(image, crown, 22.0 * scale, leaf)
			for i in 26:
				var hh := _hash(h, i)
				var x := int(crown.x) - int(24 * scale) + hh % int(48 * scale)
				for y in range(int(crown.y), int(crown.y) + 14 + hh % 22):
					if y < CELL.y - 4: image.set_pixel(x, y, leaf.darkened(0.08 + (hh % 3) * 0.06))
		BAMBOO:
			var culm := Palette.JADE.lerp(Palette.GRASS, 0.35)
			for i in 7:
				var hh := _hash(h, i)
				var x := int(foot.x) - 14 + hh % 28
				var top := int(foot.y) - int((56 + hh % 26) * scale)
				for y in range(top, int(foot.y) - (hh >> 4) % 4):
					image.set_pixel(x, y, culm.darkened(0.25) if (y - top) % 9 == 0 else culm)
					image.set_pixel(x + 1, y, culm.darkened(0.12))
				for k in 5:
					var ly := top + k * 10 + 3
					for s in 6:
						for side in [-1, 1]:
							var at := Vector2i(x + side * s, ly + s / 2)
							if Rect2i(Vector2i.ZERO, CELL).has_point(at): image.set_pixelv(at, culm.lightened(0.05))
		SHRUB:
			var leaf := Palette.GREEN.darkened(0.15).lerp(Palette.GRASS.darkened(0.3), (h % 100) / 100.0)
			for i in 3:
				var hh := _hash(h, i)
				_blob(image, foot - Vector2(-6 + hh % 12, 7 + hh % 4) * scale, (6.0 + hh % 3) * scale, leaf)


## One-texel ink outline around every opaque shape.
static func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	for y in CELL.y:
		for x in CELL.x:
			if source.get_pixel(x, y).a > 0.5: continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var at := Vector2i(x, y) + offset
				if Rect2i(Vector2i.ZERO, CELL).has_point(at) and source.get_pixelv(at).a > 0.5:
					image.set_pixel(x, y, Palette.OUTLINE)
					break
