extends RefCounted
## Dense, bounded overrides: no per-tile dictionaries in storage or drawing.
const BOUNDS := Rect2i(-160, -210, 320, 620)
var bounds := BOUNDS
var source := "res://data/sects/first_sect.json"
var no_trees := PackedByteArray()
const SURFACES := ["", "grass", "earth", "paving", "stairs", "field", "spring", "cave", "garden", "bridge", "boundary"]
var data: Dictionary
var center: Vector2i
var surfaces := PackedByteArray()
var levels := PackedInt32Array()
## Footprint (plus a one-tile margin and doorstep) of every building on natural ground → the tile whose level it is built at.
var plinth: Dictionary = {}
## Tiles on either side of a bank where a ramp of earth steps is cut, so walkers can change level there.
var ramps: Dictionary = {}
## Houses and halls drawn standing (BuildingArt), sorted with people and trees: {origin, w, h, kind, variant}.
var standing: Array[Dictionary] = []
var standing_tiles: Dictionary = {}
var boundary_art: Dictionary = {}
var heights := PackedFloat32Array()
var art := PackedInt32Array()
var labels: Array[Dictionary] = []
var built: Image
var things: Image
var farm: Image
var far_colors := PackedColorArray()
var dry: Callable
var crop_colours: Dictionary = {}
const Palette = preload("res://src/palette.gd")


func index_at(at: Vector2i) -> int:
	var p := at - center - bounds.position
	return p.y * bounds.size.x + p.x if p.x >= 0 and p.y >= 0 and p.x < bounds.size.x and p.y < bounds.size.y else -1


func has_tile(at: Vector2i) -> bool:
	var i := index_at(at)
	return i >= 0 and surfaces[i] != 0


func level_at(at: Vector2i) -> int:
	var i := index_at(at)
	return levels[i] if i >= 0 else -1


func height_at(at: Vector2i) -> float:
	var i := index_at(at)
	return heights[i] if i >= 0 else 0.0


func surface_at(at: Vector2i) -> String:
	return SURFACES[surfaces[index_at(at)]] if has_tile(at) else ""


func setup(is_dry: Callable) -> void:
	dry = is_dry
	for good: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/goods.json")).goods:
		crop_colours[good.id] = Color(good.colour)
	data = JSON.parse_string(FileAccess.get_file_as_string(source))
	center = Vector2i(int(data.center[0]), int(data.center[1]))
	if data.has("bounds"):
		bounds = Rect2i(int(data.bounds[0]), int(data.bounds[1]), int(data.bounds[2]), int(data.bounds[3]))
	var count := bounds.size.x * bounds.size.y
	no_trees.resize(count)
	surfaces.resize(count)
	levels.resize(count)
	levels.fill(-1)
	heights.resize(count)
	art.resize(count)
	art.fill(-1)
	built = Palette.atlas("tiny-town", Palette.BUILT)
	things = Palette.atlas("tiny-town", Palette.THING)
	farm = Palette.atlas("tiny-farm", Palette.THING)
	var edge := FastNoiseLite.new()
	edge.seed = int(data.get("seed", 718))
	edge.frequency = 0.048
	# Evaluate each tile against seven terrace envelopes, rather than expanding every tile.
	for y in range(bounds.position.y, 160 if data.has("tiers") else bounds.position.y):
		for x in range(bounds.position.x, bounds.end.x):
			var at := center + Vector2i(x, y)
			var i := index_at(at)
			var envelope := 0.0
			for tier: Dictionary in data.tiers:
				var yy := clampi(y, int(tier.y0), int(tier.y1))
				var end_distance := mini(yy - int(tier.y0), int(tier.y1) - yy)
				var width := float(tier.hw) - maxf(0.0, 10.0 - end_distance) + edge.get_noise_2d(0, yy) * 7.0
				var distance := Vector2(maxf(0, absf(x) - width), y - yy).length()
				var level := int(data.base_level) + int(tier.lvl)
				if distance == 0.0:
					levels[i] = level
					surfaces[i] = 1
				if distance < 55.0:
					var ravine := maxf(0.0, 0.15 - absf(edge.get_noise_2d(x * 2, y))) * minf(distance, 20.0) * 0.7
					envelope = maxf(envelope, 0.5 + (level - distance * 0.36 - ravine + edge.get_noise_2d(x, y) * 2.0) * 0.02)
			if y < 156:
				heights[i] = envelope
			if levels[i] >= 0:
				heights[i] = 0.5 + levels[i] * 0.02
	for surface: Dictionary in data.get("surfaces", []):
		_paint(surface.rect, str(surface.kind))
	for field: Dictionary in data.get("fields", []):
		_paint(field.rect, "field")
		# Each paddy is one flat terrace: the hillside steps at field edges, never through the crop.
		var r: Array = field.rect
		var anchor := center + Vector2i(int(r[0]) + int(r[2]) / 2, int(r[1]) + int(r[3]) / 2)
		for yy in range(int(r[1]), int(r[1]) + int(r[3])):
			for xx in range(int(r[0]), int(r[0]) + int(r[2])):
				var tile := center + Vector2i(xx, yy)
				if index_at(tile) >= 0 and levels[index_at(tile)] < 0: plinth[tile] = anchor
	if data.has("road"):
		_path(data.road)
	for path: Dictionary in data.get("paths", []):
		_path(path)
	var occupied: Array[Rect2i] = []
	for building: Dictionary in data.get("buildings", []) + data.get("village", []):
		# Relocate whole footprints inland; never disguise river water with a cottage.
		var r: Array = building.rect.duplicate()
		if data.has("tiers") and int(r[1]) >= 156:
			var attempts := 0
			while not _dry_rect(r) or _overlaps(r, occupied):
				r[0] = int(r[0]) - 1
				attempts += 1
				if int(r[0]) < -130:
					r[0] = 65
					r[1] = int(r[1]) + 5
				assert(attempts < 10000)
			occupied.append(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
			building.rect = r
			_paint([int(r[0]) - 1, int(r[1]) - 1, int(r[2]) + 2, int(r[3]) + 2], "grass")
		if not data.has("tiers"):
			_building(building)
			continue
		var bx := int(r[0]) + int(r[2]) / 2
		var by := int(r[1]) + int(r[3])
		# Houses stand on level ground: no terrace face may cut through a roof or a doorway.
		for yy in range(int(r[1]) - 1, by + 1):
			for xx in range(int(r[0]) - 1, int(r[0]) + int(r[2]) + 1):
				var tile := center + Vector2i(xx, yy)
				if index_at(tile) >= 0 and levels[index_at(tile)] < 0: plinth[tile] = center + Vector2i(bx, by)
		if by < 156:
			_paint([mini(0, bx), by, absi(bx) + 1, 2], "paving")
		else:
			_paint([int(r[0]) - 2, by - 1, int(r[2]) + 4, 2], "earth")
		_building(building)
	for stair: Dictionary in data.get("stairs", []):
		_paint(stair.rect, "stairs")
	for plot: Dictionary in data.get("plots", []):
		var r: Array = plot.rect
		_paint(r, str(plot.get("surface", "grass")))
		for yy in range(int(r[1]), int(r[1]) + int(r[3])):
			for xx in range(int(r[0]), int(r[0]) + int(r[2])):
				var i := index_at(center + Vector2i(xx, yy))
				if i >= 0 and (data.has("tiers") or dry.call(center + Vector2i(xx, yy))):
					levels[i] = int(plot.level)
					heights[i] = 0.5 + levels[i] * 0.02
	for stamp: Dictionary in data.get("stamps", []):
		_stamp(center + Vector2i(int(stamp.at[0]), int(stamp.at[1])), int(stamp.tile))
	_register_props()
	for i in count:
		no_trees[i] = int(surfaces[i] != 0)
	var soil := Palette.BRASS.darkened(0.3)
	var colors := [Palette.GRASS, Palette.GRASS, Palette.EARTH, Palette.STONE, Palette.STONE, soil, Palette.BLUE.lightened(0.2), Palette.INK, Palette.GRASS, Palette.BRASS.darkened(0.15), Palette.GRASS.darkened(0.05)]
	var art_colors: Array[Color] = []
	for index in 132:
		var sheet := _sheet(index)
		var total := Color(0, 0, 0, 0)
		for yy in 16:
			for xx in 16:
				var col := sheet.get_pixel((index % 12) * 16 + xx, (index / 12) * 16 + yy)
				total += Color(col.r * col.a, col.g * col.a, col.b * col.a, col.a)
		art_colors.append(Color(total.r / maxf(1, total.a), total.g / maxf(1, total.a), total.b / maxf(1, total.a), total.a / 256.0))
	for extra in 8:
		art_colors.append(Palette.BRASS.lightened(0.04 * extra))
	far_colors.resize(count)
	for i in count:
		var col: Color = colors[surfaces[i]]
		if art[i] >= 0:
			col = col.blend(art_colors[art[i]])
		far_colors[i] = col


func _overlaps(r: Array, occupied: Array[Rect2i]) -> bool:
	var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).grow(1)
	for other: Rect2i in occupied:
		if rect.intersects(other):
			return true
	return false


func _dry_rect(r: Array) -> bool:
	for y in range(int(r[1]), int(r[1]) + int(r[3])):
		for x in range(int(r[0]), int(r[0]) + int(r[2])):
			if not dry.call(center + Vector2i(x, y)):
				return false
	return true


func _path(path: Dictionary) -> void:
	var points: Array = path.points
	for j in range(points.size() - 1):
		var a := Vector2(points[j][0], points[j][1])
		var b := Vector2(points[j + 1][0], points[j + 1][1])
		for step in range(ceili(a.distance_to(b)) + 1):
			var p := Vector2i(a.lerp(b, float(step) / maxf(1.0, ceilf(a.distance_to(b)))))
			_paint([p.x - int(path.width) / 2, p.y - int(path.width) / 2, int(path.width), int(path.width)], str(path.kind))


func _paint(rect: Array, surface: String) -> void:
	for y in range(int(rect[1]), int(rect[1]) + int(rect[3])):
		for x in range(int(rect[0]), int(rect[0]) + int(rect[2])):
			var at := center + Vector2i(x, y)
			var i := index_at(at)
			if surface == "field" and (x < int(rect[0]) + absi(y % 5 - 2) or x >= int(rect[0]) + int(rect[2]) - absi(y % 7 - 3)):
				continue
			if i >= 0 and (data.has("tiers") and y < 156 or dry.call(at) or surface == "bridge"):
				surfaces[i] = SURFACES.find(surface)


func _stamp(at: Vector2i, value: int) -> void:
	var i := index_at(at)
	if i >= 0:
		if not data.has("tiers") and not dry.call(at) and value != 136:
			return
		if surfaces[i] == 0:
			surfaces[i] = 9 if value == 136 else 1
		art[i] = value


func _building(b: Dictionary) -> void:
	var r: Array = b.rect
	var origin := center + Vector2i(int(r[0]), int(r[1]))
	var w := int(r[2])
	var h := int(r[3])
	var kind := str(b.kind)
	if not str(b.name).is_empty():
		labels.append({"name": str(b.name), "tile": origin + Vector2i(w / 2, 0)})
	if kind == "tent":
		_stamp(origin, 137)
		return
	if kind == "marker":
		return
	if kind == "prop":
		_stamp(origin, 95)
		return
	if kind == "wall":
		for x in w:
			_stamp(origin + Vector2i(x, 0), 80)
		return
	if kind == "ring":
		for y in h:
			for x in w:
				if absf(Vector2(x - w / 2, y - h / 2).length() - 5.0) < 0.7:
					_stamp(origin + Vector2i(x, y), 95)
		return
	if kind in ["spring", "plaza", "training"]:
		if kind == "training":
			for x in range(3, w - 2, 7):
				_stamp(origin + Vector2i(x, 1), 95)
		return
	if kind == "court":
		_paint(r, "paving")
		for y in h:
			for x in w:
				if x == 0 or x == w - 1 or y == 0 or (y == h - 1 and x != w / 2):
					_stamp(origin + Vector2i(x, y), 80 if y == 0 or y == h - 1 else 59)
					if str(b.name) == "Hunters' Lodge": boundary_art[origin + Vector2i(x, y)] = "fence" if y == 0 or y == h - 1 else "fence_side"
		_paint([int(r[0]) + 2, int(r[1]) + 7, w - 4, h - 9], "garden")
		_building({"name": "", "rect": [int(r[0]) + 2, int(r[1]) + 2, 6, 4], "kind": "house"})
		_building({"name": "", "rect": [int(r[0]) + 10, int(r[1]) + 2, 5, 4], "kind": "house"})
		return
	if kind == "cave":
		_paint(r, "cave")
		standing.append({"origin": origin, "w": w, "h": h, "kind": "cave", "variant": absi(origin.x * 31 + origin.y * 17) % 3})
		for y in h:
			for x in w: standing_tiles[origin + Vector2i(x, y)] = true
		return
	if kind in ["house", "hall", "gate"]:
		standing.append({"origin": origin, "w": w, "h": h, "kind": kind, "variant": absi(origin.x * 31 + origin.y * 17) % 3})
		for y in h:
			for x in w: standing_tiles[origin + Vector2i(x, y)] = true
	# A path across each terrace joins its buildings to the central ascent.
	if level_at(origin) >= 0:
		_paint([mini(0, int(r[0])), int(r[1]) + h, maxi(0, int(r[0]) + w) - mini(0, int(r[0])), 1], "paving")
	for y in h:
		for x in w:
			var index := 0
			if kind == "gate":
				index = (96 if x == 0 else 98) if y == 0 else (108 if x == 0 else 110)
				if x > 0 and x < w - 1:
					index = (111 if x < w / 2 else 114) if y == 0 else -1
			else:
				var house := kind == "house"
				if y < h - 1:
					index = (52 if house else 48) + (0 if x == 0 else (2 if x == w - 1 else 1)) + (12 if y > 0 else 0)
				else:
					index = 85 if house else (76 if x == 0 else (79 if x == w - 1 else (88 if x % 3 == 1 else 77)))
					if x == w / 2:
						index = 85 if house else 78
			if index >= 0:
				_stamp(origin + Vector2i(x, y), index)


## Keep the original atlas indices for collision; only replace their presentation.
func _register_props() -> void:
	for y in bounds.size.y:
		var x := 0
		while x < bounds.size.x:
			var tile := center + bounds.position + Vector2i(x, y)
			var i := index_at(tile)
			if standing_tiles.has(tile) or art[i] < 0:
				x += 1
				continue
			var value: int = art[i]
			var kind := ""
			if value in [80, 96, 97]: kind = "wall"
			elif value == 59: kind = "fence_side"
			elif value in [132, 133, 134, 135]: kind = "stall"
			elif value == 137: kind = "tent"
			elif value == 138: kind = "smith"
			elif value == 136: kind = "boat"
			elif value == 83: kind = "sign"
			elif value == 116: kind = "tool"
			elif value == 95: kind = "prop"
			if boundary_art.has(tile): kind = boundary_art[tile]
			if kind.is_empty():
				x += 1
				continue
			var run := 1
			if kind in ["wall", "fence"]:
				while x + run < bounds.size.x:
					var next := tile + Vector2i(run, 0)
					if standing_tiles.has(next) or art[index_at(next)] != value: break
					run += 1
			standing.append({"origin": tile, "w": run, "h": 1, "kind": kind, "variant": posmod(value, 4)})
			for dx in run: standing_tiles[tile + Vector2i(dx, 0)] = true
			x += run


func draw_tile(image: Image, tile: Vector2i, pos: Vector2i) -> void:
	if not has_tile(tile):
		return
	var i := index_at(tile)
	var surface: String = SURFACES[surfaces[i]]
	var rect := Rect2i(pos, Vector2i(16, 16))
	var ink := Palette.OUTLINE
	# Ground: quiet palette fills, low contrast, never outlined.
	if surface in ["grass", "garden"]:
		image.fill_rect(rect, Palette.GRASS)
		var tuft := (tile.x * 7 + tile.y * 13) % 11
		if tuft < 3:
			image.fill_rect(Rect2i(pos + Vector2i(3 + tuft * 4, 5 + tuft * 3), Vector2i(2, 1)), Palette.GRASS.darkened(0.08))
		if surface == "garden" and tile.x % 3 == 0 and tile.y % 3 == 0:
			image.fill_rect(Rect2i(pos + Vector2i(5, 6), Vector2i(5, 2)), Palette.GREEN)
	elif surface == "bridge":
		image.fill_rect(rect, Palette.BRASS.darkened(0.15))
		for yy in range(0, 16, 4):
			image.fill_rect(Rect2i(pos + Vector2i(0, yy), Vector2i(16, 1)), Palette.BRASS.darkened(0.35))
	elif surface == "boundary":
		image.fill_rect(Rect2i(pos + Vector2i(6, 6), Vector2i(4, 4)), Palette.STONE)
	elif surface == "earth":
		image.fill_rect(rect, Palette.EARTH)
		if (tile.x * 5 + tile.y * 3) % 7 == 0:
			image.fill_rect(Rect2i(pos + Vector2i(5, 9), Vector2i(3, 1)), Palette.EARTH.darkened(0.07))
	elif surface == "field":
		var soil := Palette.BRASS.darkened(0.3)
		image.fill_rect(rect, soil)
		for row in [2, 7, 12]:
			image.fill_rect(Rect2i(pos + Vector2i(0, row), Vector2i(16, 2)), soil.darkened(0.12))
		for field: Dictionary in data.get("fields", []):
			var r: Array = field.rect
			if Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).has_point(tile - center):
				var col: Color = Palette.tone(crop_colours[field.crop], Palette.THING)
				for xx in range(2, 16, 4):
					image.fill_rect(Rect2i(pos + Vector2i(xx, 3 + (tile.y % 3)), Vector2i(2, 8)), col.darkened(0.25))
					image.fill_rect(Rect2i(pos + Vector2i(xx - 1, 2 + (tile.y % 3)), Vector2i(4, 3)), col)

	elif surface == "spring":
		image.fill_rect(rect, Palette.JADE.lightened(0.55))
		image.fill_rect(Rect2i(pos + Vector2i(2, 2), Vector2i(12, 12)), Palette.BLUE.lightened(0.2))
		image.fill_rect(Rect2i(pos + Vector2i(4, 5), Vector2i(8, 1)), Palette.JADE.lightened(0.7))
	elif surface == "cave":
		image.fill_rect(rect, Palette.STONE.darkened(0.3))
	else:
		# Paving stays under the stalls: faint seams only. A stair tread is plain stone with a lit nosing
		# at its front edge; the riser below it is drawn with the bank (ground_paint.wall).
		image.fill_rect(rect, Palette.STONE)
		if surface == "stairs":
			image.fill_rect(Rect2i(pos + Vector2i(0, 15), Vector2i(16, 1)), Palette.STONE.lightened(0.18))
			image.fill_rect(Rect2i(pos + Vector2i(0, 8), Vector2i(16, 1)), Palette.STONE.darkened(0.05))
		else:
			for y in range(0, 16, 8):
				image.fill_rect(Rect2i(pos + Vector2i(0, y), Vector2i(16, 1)), Palette.STONE.darkened(0.07))
				image.fill_rect(Rect2i(pos + Vector2i(4 if y == 0 else 12, y), Vector2i(1, 8)), Palette.STONE.darkened(0.07))
	# A standing building is drawn as a sprite over this ground; its old roof tiles stay unpainted.
	if standing_tiles.has(tile): return
	# Things: full contrast and an ink outline.
	if art[i] >= 132:
		var value := art[i]
		if value == 136:
			# Tapered wooden hull and a pale mooring line.
			for yy in range(1, 16):
				var inset := absi(8 - yy) / 3
				image.fill_rect(Rect2i(pos + Vector2i(2 + inset, yy), Vector2i(12 - inset * 2, 1)), ink)
			for yy in range(2, 15):
				var inset := absi(8 - yy) / 3
				image.fill_rect(Rect2i(pos + Vector2i(3 + inset, yy), Vector2i(10 - inset * 2, 1)), Palette.BRASS.darkened(0.35))
			image.fill_rect(Rect2i(pos + Vector2i(7, 4), Vector2i(2, 8)), Palette.PAPER)
		elif value == 137:
			for yy in 13:
				image.fill_rect(Rect2i(pos + Vector2i(6 - yy / 2, yy + 2), Vector2i(4 + yy, 1)), ink)
			for yy in 12:
				image.fill_rect(Rect2i(pos + Vector2i(7 - yy / 2, yy + 3), Vector2i(2 + yy, 1)), Palette.PAPER_DARK)
		elif value == 138:
			image.fill_rect(Rect2i(pos + Vector2i(3, 4), Vector2i(10, 10)), ink)
			image.fill_rect(Rect2i(pos + Vector2i(4, 5), Vector2i(8, 8)), Palette.INK_SOFT)
			image.fill_rect(Rect2i(pos + Vector2i(6, 5), Vector2i(5, 7)), Palette.GOLD)
			image.fill_rect(Rect2i(pos + Vector2i(7, 7), Vector2i(3, 5)), Palette.RED)
		else:
			var awnings := [Palette.RED, Palette.BLUE, Palette.GOLD, Palette.GREEN]
			image.fill_rect(Rect2i(pos + Vector2i(1, 2), Vector2i(14, 14)), ink)
			image.fill_rect(Rect2i(pos + Vector2i(2, 3), Vector2i(12, 8)), awnings[(value - 132) % 4])
			for xx in [3, 7, 11]:
				image.fill_rect(Rect2i(pos + Vector2i(xx, 3), Vector2i(2, 8)), Palette.PAPER_LIGHT)
			image.fill_rect(Rect2i(pos + Vector2i(2, 12), Vector2i(12, 3)), Palette.BRASS.darkened(0.25))
	elif art[i] >= 0:
		var sheet := _sheet(art[i])
		_blit(image, sheet, art[i], pos)
		# The ink edge follows the silhouette wherever a built tile meets open ground.
		var origin := Vector2i((art[i] % 12) * 16, (art[i] / 12) * 16)
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var other := index_at(tile + side)
			if other >= 0 and art[other] >= 0:
				continue
			for step in 16:
				var at := Vector2i(0 if side.x < 0 else (15 if side.x > 0 else step), 0 if side.y < 0 else (15 if side.y > 0 else step))
				if sheet.get_pixel(origin.x + at.x, origin.y + at.y).a > 0.5:
					image.fill_rect(Rect2i(pos + at, Vector2i.ONE), ink)


## Roof tiles are calmed; walls, doors, trees and props keep full contrast.
func _sheet(index: int) -> Image:
	return built if index >= 48 and index < 72 else things


func _blit(image: Image, source: Image, index: int, pos: Vector2i) -> void:
	image.blend_rect(source, Rect2i((index % 12) * 16, (index / 12) * 16, 16, 16), pos)


func far_color(tile: Vector2i) -> Color:
	return far_colors[index_at(tile)]
