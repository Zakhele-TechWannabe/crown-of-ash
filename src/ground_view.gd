extends Node2D
## Camera and screen-space controls for ground travel.

const TILE := 32.0
var food: Label
var forecast: Label
var balance: Label
var history: RichTextLabel
var expanded := false
var shown_minute := -1
var shown_speed := -1.0
var shown_paused := false
var clock_label: Label
var card: Label
var cam: Camera2D
var hud: CanvasLayer
var place: Label
var readout: Label
var names: Control
var active := false
var dragging := false
var map: Node2D


func _ready() -> void:
	map = get_parent()
	cam = Camera2D.new()
	cam.enabled = false
	add_child(cam)
	hud = CanvasLayer.new()
	add_child(hud)
	var bar := Panel.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 46
	bar.add_theme_stylebox_override("panel", map._box())
	hud.add_child(bar)
	place = Label.new()
	place.position = Vector2(18, 9)
	place.add_theme_font_override("font", map.font)
	place.add_theme_color_override("font_color", map.GOLD)
	bar.add_child(place)
	var back := Button.new()
	back.text = "World map [M]"
	back.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	back.position = Vector2(-180, 7)
	back.size = Vector2(166, 32)
	back.pressed.connect(map.show_map)
	bar.add_child(back)
	clock_label = Label.new()
	clock_label.position = Vector2(650, 10)
	bar.add_child(clock_label)
	for n in 8:
		var button := Button.new()
		button.text = ["1x [1]", "4x [2]", "16x [3]", "64x [4]", "256x [5]", "1024x [6]", "4096x [7]", "Pause"][n]
		button.position = Vector2(980 + n * 94, 7)
		button.pressed.connect(func() -> void:
			if n == 7:
				map.life.paused = not map.life.paused
			else:
				map.life.speed = [1.0, 4.0, 16.0, 64.0, 256.0, 1024.0, 4096.0][n])
		bar.add_child(button)
	var village := PanelContainer.new()
	village.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	village.position = Vector2(-390, 58)
	village.custom_minimum_size = Vector2(375, 0)
	village.add_theme_stylebox_override("panel", map._box())
	hud.add_child(village)
	var rows := VBoxContainer.new()
	village.add_child(rows)
	var title := Button.new()
	title.text = "Village · Chronicle ▾"
	title.pressed.connect(func() -> void:
		expanded = not expanded
		history.custom_minimum_size.y = 420 if expanded else 125)
	rows.add_child(title)
	food = Label.new()
	rows.add_child(food)
	forecast = Label.new()
	rows.add_child(forecast)
	balance = Label.new()
	rows.add_child(balance)
	var crisis := CheckBox.new()
	crisis.text = "Pause on crisis"
	crisis.toggled.connect(func(enabled: bool) -> void: map.life.economy.pause_on_crisis = enabled)
	rows.add_child(crisis)
	history = RichTextLabel.new()
	history.custom_minimum_size = Vector2(350, 125)
	rows.add_child(history)
	card = Label.new()
	card.add_theme_stylebox_override("normal", map._box())
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(card)
	readout = Label.new()
	readout.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	readout.offset_top = -62
	readout.add_theme_stylebox_override("normal", map._box())
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(readout)
	names = Control.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	names.draw.connect(_draw_names)
	hud.add_child(names)
	hud.hide()


func enter(tile: Vector2i) -> void:
	active = true
	hud.show()
	cam.enabled = true
	cam.make_current()
	cam.position = (Vector2(tile) + Vector2.ONE * 0.5) * TILE
	cam.position.y -= map.ground.terrace_level(tile) * map.ground.exaggeration
	_clamp_camera()
	_update_readout()


func leave() -> void:
	active = false
	dragging = false
	hud.hide()
	cam.enabled = false


func _process(dt: float) -> void:
	if not active:
		return
	var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if motion != Vector2.ZERO:
		map.life.followed = -1
	if map.life.followed >= 0:
		cam.position = map.life.point(map.life.people[map.life.followed])
	if shown_minute != int(map.life.minutes) or shown_speed != map.life.speed or shown_paused != map.life.paused:
		shown_minute = int(map.life.minutes)
		shown_speed = map.life.speed
		shown_paused = map.life.paused
		clock_label.text = map.life.clock_text() + (" · paused" if map.life.paused else " · %dx" % int(map.life.speed))
	var economy: RefCounted = map.life.economy
	food.text = "Food: %d days" % floori(economy.stock / 19.0)
	food.modulate = Color.INDIAN_RED if economy.stock < 7 * 19 else (Color.ORANGE if economy.stock < 30 * 19 else Color.WHITE)
	forecast.text = "Next planting in %d days" % (366 - economy.day) if economy.season() == 3 else "Harvest forecast: ~%s" % _grouped(roundi(economy.forecast() / 100.0) * 100)
	var net: float = economy.produced - economy.consumed - economy.spoiled
	balance.text = "This year: %s%s" % ["+" if net >= 0 else "−", _grouped(roundi(absf(net)))]
	balance.modulate = Color.LIGHT_GREEN if net >= 0 else Color.INDIAN_RED
	var entries := PackedStringArray()
	for i in range(economy.chronicle.size() - 1, -1, -1):
		if not expanded and entries.size() >= 6:
			break
		entries.append(economy.chronicle[i])
	var chronicle_text := "\n".join(entries)
	if history.text != chronicle_text:
		history.text = chronicle_text
	var hovered: int = map.life.hover(get_global_mouse_position())
	card.visible = hovered >= 0
	if hovered >= 0:
		var p: Dictionary = map.life.people[hovered]
		card.text = "%s, %d, %s · %s · %s" % [p.name, p.age, p.job, economy.HUNGER[int(p.hunger)], map.life.activity_text(p)]
		card.position = (get_viewport().get_mouse_position() + Vector2(16, 20)).min(get_viewport_rect().size - card.size - Vector2(8, 8))
	cam.position += motion * dt * 650.0 / cam.zoom.x
	_clamp_camera()
	_update_readout()
	names.queue_redraw()


func _update_readout() -> void:
	var center := cam.position / (TILE * 16.0)
	var nearest := "The Seven Stars Continent"
	var distance := INF
	for feature: Dictionary in map.data.features:
		var d := center.distance_squared_to(Vector2(float(feature.x), float(feature.y)))
		if d < distance:
			distance = d
			nearest = str(feature.name)
	place.text = "%s · relief %.0f [ / ]" % [nearest, map.ground.exaggeration]
	var tile: Vector2i = map.ground.pick_tile(get_global_mouse_position())
	var cell := Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0))
	readout.text = "%s\n%s · tile %d, %d" % [map._info(cell, tile), map.ground.sample(tile).cover, tile.x, tile.y]


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
		map.ground.set_exaggeration(map.ground.exaggeration + (1.0 if event.keycode == KEY_BRACKETRIGHT else -1.0))
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and map.life.followed >= 0:
		map.life.followed = -1
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_M, KEY_ESCAPE]:
		map.show_map()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			map.life.followed = map.life.hover(get_global_mouse_position())
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.2, 2.0)
			_clamp_camera()
	elif event is InputEventMouseMotion and dragging:
		map.life.followed = -1
		cam.position -= event.relative / cam.zoom
		_clamp_camera()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size / cam.zoom / 2.0
	var extent := Vector2(map.w * 16, map.h * 16) * TILE
	for axis in 2:
		cam.position[axis] = extent[axis] / 2.0 if half[axis] * 2.0 >= extent[axis] else clampf(cam.position[axis], half[axis], extent[axis] - half[axis])
	cam.force_update_scroll()


func _draw_names() -> void:
	if not active:
		return
	var transform := get_viewport().get_canvas_transform()
	for entry: Dictionary in map.ground.sect.labels:
		if cam.zoom.x < 0.45 and not entry.name in ["Unnamed Sect", "Leader's Hall", "Main Hall", "Great Plaza", "Mountain Gate", "Servants' Village", "Spirit Fields"]:
			continue
		var tile: Vector2i = entry.tile
		var point := (Vector2(tile) + Vector2(0.5, 0.0)) * TILE
		point.y -= map.ground.terrace_level(tile) * map.ground.exaggeration
		var at: Vector2 = transform * point - Vector2(0, 8)
		if not get_viewport_rect().grow(80).has_point(at):
			continue
		var text: String = entry.name
		var px := 19 if text == str(map.ground.sect.data.name) else 13
		at.x -= map.serif.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / 2.0
		names.draw_string_outline(map.serif, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color8(244, 236, 214, 217))
		names.draw_string(map.serif, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, map.INK)


func _grouped(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			result += ","
		result += text[i]
	return result
