extends Control
## Daily samples are supplied in calendar order; chart never polls the simulation.
var samples: Array[Vector2] = []
var bars := false
var caption := ""
var unit := "jin"
const Palette = preload("res://src/palette.gd")
var font: Font = preload("res://src/ui_theme.gd").body()

func _draw() -> void:
	var ink := Palette.INK
	draw_style_box(preload("res://src/ui_theme.gd").box(Palette.PAPER_LIGHT), Rect2(Vector2.ZERO, size))
	var maximum := 1.0
	for p: Vector2 in samples:
		maximum = maxf(maximum, p.y)
	var maximum_text := "%.0f %s" % [maximum, unit]
	var left := font.get_string_size(maximum_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16
	var area := Rect2(left, 32, maxf(100, size.x - left - 24), maxf(50, size.y - 66))
	draw_string(font, Vector2(8, 20), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
	draw_line(area.position, Vector2(area.position.x, area.end.y), ink)
	draw_line(Vector2(area.position.x, area.end.y), area.end, ink)
	if samples.is_empty():
		draw_string(font, area.position + Vector2(16, 30), "No completed days / years yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
		return
	draw_string(font, Vector2(2, area.position.y + 14), maximum_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
	draw_string(font, Vector2(left - 24, area.end.y), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
	var previous := Vector2.ZERO
	for i in samples.size():
		var at := Vector2(area.position.x + (float(i) + 0.5) / samples.size() * area.size.x, area.end.y - samples[i].y / maximum * area.size.y)
		if bars:
			draw_rect(Rect2(at - Vector2(5, 0), Vector2(10, area.end.y - at.y)), Palette.BRASS)
		elif i > 0:
			draw_line(previous, at, Palette.BRASS.darkened(0.25), 2.0, true)
		else:
			draw_circle(at, 3, Palette.BRASS.darkened(0.25))
		previous = at
	draw_string(font, Vector2(area.position.x, size.y - 8), "%s %.0f" % ["Year" if bars else "Day", samples[0].x], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
	draw_string(font, Vector2(area.end.x - 100, size.y - 8), "%s %.0f" % ["Year" if bars else "Day", samples[-1].x], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
