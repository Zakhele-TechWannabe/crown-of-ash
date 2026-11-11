extends Node2D
## Camera and screen-space controls for ground travel.

const TILE := 32.0
var cam: Camera2D
var hud: CanvasLayer
var place: Label
var readout: Label
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
	readout = Label.new()
	readout.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	readout.offset_top = -62
	readout.add_theme_stylebox_override("normal", map._box())
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(readout)
	hud.hide()


func enter(tile: Vector2i) -> void:
	active = true
	hud.show()
	cam.enabled = true
	cam.make_current()
	cam.position = (Vector2(tile) + Vector2.ONE * 0.5) * TILE
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
	cam.position += motion * dt * 650.0 / cam.zoom.x
	_clamp_camera()
	_update_readout()


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
	var tile := Vector2i((get_global_mouse_position() / TILE).floor())
	var cell := Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0))
	readout.text = "%s\n%s · tile %d, %d" % [map._info(cell, tile), map.ground.sample(tile).cover, tile.x, tile.y]


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_M, KEY_ESCAPE]:
		map.show_map()
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.5, 2.0)
			_clamp_camera()
	elif event is InputEventMouseMotion and dragging:
		cam.position -= event.relative / cam.zoom
		_clamp_camera()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size / cam.zoom / 2.0
	var extent := Vector2(map.w * 16, map.h * 16) * TILE
	for axis in 2:
		cam.position[axis] = extent[axis] / 2.0 if half[axis] * 2.0 >= extent[axis] else clampf(cam.position[axis], half[axis], extent[axis] - half[axis])
	cam.force_update_scroll()
