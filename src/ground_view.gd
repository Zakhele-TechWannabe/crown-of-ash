extends Node2D
## Camera and screen-space controls for ground travel.

const TILE := 32.0
var ledger: PanelContainer
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
	card = Label.new()
	card.add_theme_stylebox_override("normal", preload("res://src/village_ledger.gd").skin("panel_beige"))
	card.add_theme_font_override("font", load("res://assets/fonts/Lato-Bold.ttf"))
	card.add_theme_font_size_override("font_size", 16)
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.custom_minimum_size.x = 384
	card.size.x = 384
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
	ledger = preload("res://src/village_ledger.gd").new()
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
	var economy: RefCounted = map.life.economy
	var hovered: int = map.life.hover(get_global_mouse_position())
	card.visible = hovered >= 0 and (not ledger.visible or get_viewport().get_mouse_position().x < get_viewport_rect().size.x * 0.5)
	if hovered >= 0:
		var p: Dictionary = map.life.people[hovered]
		card.text = "%s, %d · %s\n%s · food today: %.1f jin · %s\n%s" % [p.name, p.age, p.job, economy.HUNGER[int(p.hunger)], float(p.rice_today) * 2, p.get("mood", "content"), map.life.activity_text(p)]
		card.add_theme_color_override("font_color", Color("a23522") if int(p.hunger) > 0 else Color("49612e"))
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
	place.text = nearest
	var tile: Vector2i = map.ground.pick_tile(get_global_mouse_position())
	var cell := Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0))
	readout.visible = Input.is_physical_key_pressed(KEY_ALT)
	readout.text = "%s\n%s · tile %d, %d" % [map._info(cell, tile), map.ground.sample(tile).cover, tile.x, tile.y]


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if ledger.owns_pointer(event):
		dragging = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and ledger.current == "food":
			ledger.food_up()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_F1 and event.keycode < KEY_F1 + ledger.TABS.size():
			ledger.toggle_tab(ledger.TABS.keys()[event.keycode - KEY_F1])
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_L or (event.keycode == KEY_ESCAPE and ledger.visible):
			if ledger.visible:
				ledger.close()
			else:
				ledger.open_tab(ledger.current)
			get_viewport().set_input_as_handled()
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
			var tile: Vector2i = map.ground.pick_tile(get_global_mouse_position())
			for building: Dictionary in map.ground.sect.data.buildings:
				if building.name == "Granary":
					var r: Array = building.rect
					if Rect2i(map.ground.sect.center + Vector2i(int(r[0]), int(r[1])), Vector2i(int(r[2]), int(r[3]))).has_point(tile):
						ledger.show_granary()
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
		var px := 19 if text == str(map.ground.sect.data.name) else 16
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
