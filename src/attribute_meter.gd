extends ProgressBar
## Potential is a faint vertical mark against the current attribute value.
const Palette = preload("res://src/palette.gd")
var potential := 20.0

func _draw() -> void:
	var x := size.x * clampf(potential / maxf(1, max_value), 0, 1)
	draw_line(Vector2(x, 0), Vector2(x, size.y), Color(Palette.INK_SOFT, .5), 2)
