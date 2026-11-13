extends RefCounted
## The one palette and the style rules. The map generator and every panel read colours only from here.

# Paper and ink: every panel, tag and label.
const PAPER := Color("ecdcb3")
const PAPER_LIGHT := Color("f6e9c6")
const PAPER_DARK := Color("d8c08f")
const LINE := Color("a8874f")
const INK := Color("3b2b1a")
const INK_SOFT := Color("6d563a")
# Accents shared by buttons, bars, roofs, banners and stalls.
const BRASS := Color("b08a52")
const GOLD := Color("dcae3e")
const RED := Color("b04a34")
const GREEN := Color("5f7a3a")
const JADE := Color("4f8a7b")
const BLUE := Color("5b7f95")
const PLUM := Color("7d5f85")
# The land itself.
const GRASS := Color("a3ad72")
const EARTH := Color("c7a877")
const STONE := Color("b9b19c")

const NAMES := ["PAPER", "PAPER_LIGHT", "PAPER_DARK", "LINE", "INK", "INK_SOFT", "BRASS", "GOLD", "RED", "GREEN", "JADE", "BLUE", "PLUM", "GRASS", "EARTH", "STONE"]

# Style rules.
# Ground is quiet: low contrast, little detail, never outlined.
# Built things (roofs, walls) keep their pattern at half strength and carry an ink edge.
# Things you can click or that move (people, stalls, trees, work sites) keep full contrast and an ink outline.
enum {GROUND, BUILT, THING}
const FLATTEN := [0.6, 0.62, 0.0]
const SATURATION := [0.5, 0.55, 0.7]
const WASH := [0.24, 0.14, 0.06]
const OUTLINE := INK
## One art pixel is two world pixels everywhere; the camera only stops on whole-texel zooms.
const TEXEL := 2
const ZOOMS: Array[float] = [0.25, 0.5, 1.0, 1.5, 2.0]
const DEFAULT_ZOOM := 3

# Text sizes: nothing else is allowed.
const SMALL := 13
const BODY := 16
const TITLE := 20
const HEAD := 26

static var _atlases: Dictionary = {}
static var _lock := Mutex.new()


## Pulls any colour toward the parchment: less saturation, then a paper wash.
static func tone(c: Color, style: int) -> Color:
	var grey := c.get_luminance()
	var s: float = SATURATION[style]
	var out := Color(lerpf(grey, c.r, s), lerpf(grey, c.g, s), lerpf(grey, c.b, s), c.a)
	if style != GROUND and grey < 0.3:
		# Dark edge pixels all become the same ink.
		return Color(out.lerp(OUTLINE, 0.65), c.a)
	return Color(out.lerp(PAPER, WASH[style]), c.a)


## A graded copy of a 16 px tile sheet. Flattening blends each tile toward its own mean, which thins busy patterns.
static func graded(source: Image, style: int) -> Image:
	var image := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	var flatten: float = FLATTEN[style]
	for ty in range(0, source.get_height(), 16):
		for tx in range(0, source.get_width(), 16):
			var total := Color(0, 0, 0, 0)
			for y in 16:
				for x in 16:
					var c := source.get_pixel(tx + x, ty + y)
					total += Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a)
			if total.a <= 0.0:
				continue
			var mean := Color(total.r / total.a, total.g / total.a, total.b / total.a)
			for y in 16:
				for x in 16:
					var c := source.get_pixel(tx + x, ty + y)
					if c.a <= 0.0:
						continue
					var flat := Color(lerpf(c.r, mean.r, flatten), lerpf(c.g, mean.g, flatten), lerpf(c.b, mean.b, flatten), c.a)
					image.set_pixel(tx + x, ty + y, tone(flat, style))
	return image


## Graded Kenney sheets, built once and shared by the bakers and the walkers.
static func atlas(sheet: String, style: int) -> Image:
	var key := "%s:%d" % [sheet, style]
	_lock.lock()
	if not _atlases.has(key):
		var texture := load("res://assets/kenney/%s/Tilemap/tilemap_packed.png" % sheet) as Texture2D
		_atlases[key] = graded(texture.get_image(), style)
	var image: Image = _atlases[key]
	_lock.unlock()
	return image


## One tile lifted out with a one-pixel ink outline around its silhouette (18 x 18).
static func outlined(sheet: Image, index: int, drop_rows: Array = []) -> Image:
	var columns := sheet.get_width() / 16
	var tile := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	var row := 17
	for y in range(15, -1, -1):
		if y in drop_rows:
			continue
		row -= 1
		for x in 16:
			tile.set_pixel(x + 1, row, sheet.get_pixel((index % columns) * 16 + x, (index / columns) * 16 + y))
	var result := tile.duplicate() as Image
	for y in 18:
		for x in 18:
			if tile.get_pixel(x, y).a > 0.5:
				continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var at := Vector2i(x, y) + offset
				if at.x >= 0 and at.y >= 0 and at.x < 18 and at.y < 18 and tile.get_pixel(at.x, at.y).a > 0.5:
					result.set_pixel(x, y, OUTLINE)
					break
	return result


## Hunger, mood and danger all use the same three signals.
static func signal_colour(level: int) -> Color:
	return [GREEN, GOLD.darkened(0.25), RED][clampi(level, 0, 2)]
