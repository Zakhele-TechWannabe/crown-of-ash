extends Control
## A small figure lit up to a person's tempering layer. The body is always drawn solid with an ink outline; each forged
## layer shows in its colour (dimmer at Low grade, full at High, glowing at Perfect), unforged layers as muted traces.
const Palette = preload("res://src/palette.gd")
const OPACITY := [0.72, 0.84, 0.94, 1.0]
const UNFORGED := 0.28
var layers: Array = []

func show_body(grades: Array) -> void:
	layers = grades
	queue_redraw()

func _alpha(l: int) -> float:
	return OPACITY[layers[l - 1]] if l <= layers.size() else UNFORGED

func _draw() -> void:
	# Drawn in a 200×350 design box, scaled to fit the control.
	var s := minf(size.x / 200.0, size.y / 350.0)
	draw_set_transform(Vector2((size.x - 200.0 * s) / 2.0, 0), 0, Vector2(s, s))
	if layers.size() == 9 and layers.all(func(g: int) -> bool: return g == 3):
		for r in [150.0, 110.0, 70.0]: draw_circle(Vector2(100, 170), r, Color(Palette.GOLD, 0.1))
	var parts := [Rect2(70, 66, 60, 112), Rect2(44, 70, 20, 112), Rect2(136, 70, 20, 112), Rect2(73, 172, 23, 158), Rect2(104, 172, 23, 158)]
	# The plain body, always readable.
	draw_circle(Vector2(100, 38), 22, Palette.PAPER_LIGHT)
	for r: Rect2 in parts: draw_rect(r, Palette.PAPER_LIGHT)
	var flesh := Color(Palette.EARTH.lightened(0.2), _alpha(2) if layers.size() >= 2 else 0.0)
	draw_circle(Vector2(100, 38), 22, flesh)
	for r: Rect2 in parts: draw_rect(r, flesh)
	var bone := Color(Palette.INK_SOFT, _alpha(4))
	for line: Array in [[100, 64, 100, 172], [54, 80, 54, 176], [146, 80, 146, 176], [84, 182, 84, 320], [116, 182, 116, 320]]:
		draw_line(Vector2(line[0], line[1]), Vector2(line[2], line[3]), bone, 3.0)
	for y in [92, 106, 120, 134]: draw_line(Vector2(80, y), Vector2(120, y), bone, 2.0)
	var marrow := Color(Palette.GOLD, _alpha(5))
	for point: Vector2 in [Vector2(54, 110), Vector2(54, 150), Vector2(146, 110), Vector2(146, 150), Vector2(84, 230), Vector2(84, 280), Vector2(116, 230), Vector2(116, 280), Vector2(100, 150)]:
		draw_circle(point, 2.8, marrow)
	var sinew := Color(Palette.PLUM, _alpha(3))
	for line: Array in [[64, 76, 72, 80], [136, 76, 128, 80], [48, 124, 60, 124], [140, 124, 152, 124], [76, 252, 92, 252], [108, 252, 124, 252]]:
		draw_line(Vector2(line[0], line[1]), Vector2(line[2], line[3]), sinew, 3.2)
	var blood := Color(Palette.RED, _alpha(6))
	for points: PackedVector2Array in [PackedVector2Array([Vector2(93, 100), Vector2(70, 120), Vector2(56, 150), Vector2(53, 180)]),
			PackedVector2Array([Vector2(107, 100), Vector2(130, 120), Vector2(144, 150), Vector2(147, 180)]),
			PackedVector2Array([Vector2(96, 112), Vector2(90, 200), Vector2(84, 312)]), PackedVector2Array([Vector2(104, 112), Vector2(110, 200), Vector2(116, 312)])]:
		draw_polyline(points, blood, 1.6)
	var organ := Color(Palette.RED, _alpha(7) * 0.6)
	draw_circle(Vector2(92, 100), 7, organ)
	draw_circle(Vector2(100, 158), 7, organ)
	for x in [82.0, 118.0]:
		draw_set_transform(Vector2((size.x - 200.0 * s) / 2.0, 0) + Vector2(x, 104) * s, 0, Vector2(s * 0.55, s))
		draw_circle(Vector2.ZERO, 12, organ)
	draw_set_transform(Vector2((size.x - 200.0 * s) / 2.0, 0), 0, Vector2(s, s))
	var meridian := Color(Palette.JADE, _alpha(8))
	for line: Array in [[100, 18, 100, 320], [54, 76, 52, 186], [146, 76, 148, 186], [86, 180, 82, 325], [114, 180, 118, 325]]:
		draw_dashed_line(Vector2(line[0], line[1]), Vector2(line[2], line[3]), meridian, 1.8, 4.0)
	# Outline: ink always; Copper Skin, once forged, rims it in brass.
	var forged_skin := layers.size() >= 1
	var skin := Palette.BRASS.darkened(0.3 - 0.1 * layers[0]) if forged_skin else Palette.INK_SOFT
	var width := 3.0 if forged_skin else 2.0
	draw_arc(Vector2(100, 38), 22, 0, TAU, 32, skin, width)
	for r: Rect2 in parts: draw_rect(r, skin, false, width)
