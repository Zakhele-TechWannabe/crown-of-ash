extends Node2D
## The atlas is baked once; only screen-space names and controls redraw.
const Palette = preload("res://src/palette.gd")

const CELL := 8.0
const GOLD := Palette.GOLD
const INK := Palette.INK
const BLUE := Palette.BLUE
const PANEL := Palette.PAPER
const DIRECTIONS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]

var life: Node2D
var ground_view: Node2D
var map_layer: CanvasLayer
var on_ground := false
var travel_button: Button
var ground: Node2D
var terrain: Sprite2D
var travel: Tween
var selected_tile := Vector2i(-1, -1)
var data: Dictionary
var w: int
var h: int
var heights: PackedByteArray
var biome: PackedByteArray
var water: PackedByteArray
var rivers: PackedByteArray
var directions: PackedByteArray
var temperature: PackedByteArray
var cam: Camera2D
var overlay: Control
var river_art: Node2D
var serif: Font
var font: Font
var fit_zoom := 1.0
var dragging := false
var drag_distance := 0.0
var selected := Vector2i(-1, -1)
var shot_path := ""
var shot_frames := 0
var frame := 0
var taking_shot := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BLUE.darkened(0.4))
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_zi-xue-718.json"))
	w = int(data.width)
	h = int(data.height)
	heights = Marshalls.base64_to_raw(data.heights_u16)
	biome = Marshalls.base64_to_raw(data.biome)
	water = Marshalls.base64_to_raw(data.water)
	rivers = Marshalls.base64_to_raw(data.river)
	directions = Marshalls.base64_to_raw(data.down_dir)
	temperature = Marshalls.base64_to_raw(data.temperature)
	font = preload("res://src/ui_theme.gd").body()
	# Atlas names use the ledger's heading face; there are only two font families in the game.
	serif = preload("res://src/ui_theme.gd").heading()
	_bake_terrain()
	river_art = Node2D.new()
	river_art.draw.connect(_draw_rivers)
	add_child(river_art)
	ground = preload("res://src/ground_terrain.gd").new()
	add_child(ground)
	ground.setup(self)
	ground.hide()
	ground_view = preload("res://src/ground_view.gd").new()
	add_child(ground_view)
	life = preload("res://src/village_life.gd").new()
	add_child(life)
	life.setup(self)
	ground_view.setup_panels()
	cam = Camera2D.new()
	cam.position = Vector2(w, h) * CELL / 2.0
	add_child(cam)
	var layer := CanvasLayer.new()
	map_layer = layer
	add_child(layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	overlay.theme = preload("res://src/ui_theme.gd").build()
	layer.add_child(overlay)
	var places := OptionButton.new()
	places.position = Vector2(300, 7)
	places.size = Vector2(240, 32)
	places.add_item("Go to…")
	for feature: Dictionary in data.features:
		places.add_item(str(feature.name))
	places.add_item(str(ground.sect.data.name))
	places.add_item("Servants' Village")
	for name: String in ground.sect.destinations:
		places.add_item(name)
	places.item_selected.connect(func(index: int) -> void:
		if index > 0:
			_go_to(places.get_item_text(index), true))
	overlay.add_child(places)
	var reset := Button.new()
	reset.text = "World [Home]"
	reset.position = Vector2(550, 7)
	reset.pressed.connect(_reset)
	overlay.add_child(reset)
	travel_button = Button.new()
	travel_button.text = "Travel here"
	travel_button.pressed.connect(func() -> void: _travel_to(selected_tile))
	overlay.add_child(travel_button)
	get_viewport().size_changed.connect(_resize)
	_resize()
	var destination := ""
	var start_at := false
	var at := Vector2i.ZERO
	var start_map := false
	var ground_zoom := 0.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--goto="):
			destination = argument.trim_prefix("--goto=")
		elif argument.begins_with("--at="):
			var coordinates := argument.trim_prefix("--at=").split(",")
			if coordinates.size() == 2 and coordinates[0].is_valid_int() and coordinates[1].is_valid_int():
				at = Vector2i(int(coordinates[0]), int(coordinates[1]))
				start_at = true
			else:
				push_warning("Expected --at=X,Y")
		elif argument.begins_with("--exag="):
			ground.set_exaggeration(float(argument.get_slice("=", 1)))
		elif argument == "--map":
			start_map = true
		elif argument.begins_with("--zoom="):
			ground_zoom = float(argument.get_slice("=", 1))
		elif argument.begins_with("--shot="):
			shot_path = argument.trim_prefix("--shot=")
		elif argument.begins_with("--frames="):
			shot_frames = int(argument.get_slice("=", 1))
	if not start_map:
		if not destination.is_empty():
			_go_to(destination, false)
		elif start_at:
			_travel_to(at)
	if ground_zoom > 0.0:
		ground_view.cam.zoom = Vector2.ONE * clampf(ground_zoom, 0.2, 2.0)
	if not start_map and destination.is_empty() and not start_at:
		_start_in_valley.call_deferred()
	_window_setup()


## Played normally, the game opens on the village rather than the continent; tests build the scene themselves.
func _start_in_valley() -> void:
	if get_tree().current_scene == self and not on_ground:
		_go_to("Servants' Village", false)


func _height(x: int, y: int) -> float:
	var i := (clampi(y, 0, h - 1) * w + clampi(x, 0, w - 1)) * 2
	return float(heights.decode_u16(i)) / 30000.0


func _smooth_height(x: int, y: int) -> float:
	var total := 0.0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			total += _height(x + dx, y + dy) * (2.0 if dx == 0 else 1.0) * (2.0 if dy == 0 else 1.0)
	return total / 16.0


func _bake_terrain() -> void:
	var image := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var i := y * w + x
			var rgb: Array = data.biome_colors[biome[i]]
			var col := Vector3(float(rgb[0]), float(rgb[1]), float(rgb[2]))
			if water[i] == 0:
				var elevation := _height(x, y)
				col = col.lerp(Vector3(145, 119, 86), smoothstep(0.60, 0.80, elevation) * 0.7)
				col = col.lerp(Vector3(153, 153, 149), smoothstep(0.79, 0.87, elevation))
				col = col.lerp(Vector3(241, 243, 237), smoothstep(0.90, 0.96, elevation))
				col *= clampf(1.0 + (_smooth_height(x - 1, y) - _smooth_height(x + 1, y) + _smooth_height(x, y - 1) - _smooth_height(x, y + 1)) * 12.0, 0.6, 1.35)
			elif water[i] == 1:
				var depth := minf(1.0, (0.5 - _height(x, y)) * 5.0)
				col *= Vector3(1.0 - depth * 0.25, 1.0 - depth * 0.2, 1.0 - depth * 0.12)
				var coast := false
				for offset in DIRECTIONS:
					var nx: int = x + offset.x
					var ny: int = y + offset.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h and water[ny * w + nx] == 0:
						coast = true
				if coast:
					col = col * Vector3(0.8, 0.8, 0.85) + Vector3(30, 40, 40)
			var grain := float(((x * 374761393 + y * 668265263) & 0x7fffffff) % 9)
			col += Vector3.ONE * grain
			image.set_pixel(x, y, Color(col.x / 255.0, col.y / 255.0, col.z / 255.0))
	terrain = Sprite2D.new()
	terrain.texture = ImageTexture.create_from_image(image)
	terrain.centered = false
	terrain.scale = Vector2.ONE * CELL
	terrain.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(terrain)


func _draw_rivers() -> void:
	for y in h:
		for x in w:
			var i := y * w + x
			if rivers[i] == 0 or directions[i] > 7:
				continue
			var at := (Vector2(x, y) + Vector2.ONE * 0.5) * CELL
			var end := at + Vector2(DIRECTIONS[directions[i]]) * CELL
			river_art.draw_line(at, end, Palette.BLUE.darkened(0.15), minf(2.4, 0.4 + rivers[i] / 10.0 * 0.32) * CELL, true)


func _resize() -> void:
	var size := get_viewport_rect().size - Vector2(0, 88)
	var previous := fit_zoom
	fit_zoom = minf(size.x / (w * CELL), size.y / (h * CELL))
	cam.zoom = Vector2.ONE * clampf(fit_zoom if is_equal_approx(cam.zoom.x, previous) else cam.zoom.x, fit_zoom, 8.0)
	_clamp_camera()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size / cam.zoom / 2.0
	var extent := Vector2(w, h) * CELL
	for axis in 2:
		cam.position[axis] = extent[axis] / 2.0 if half[axis] * 2.0 >= extent[axis] else clampf(cam.position[axis], half[axis], extent[axis] - half[axis])
	cam.force_update_scroll()


func _process(dt: float) -> void:
	var complete := true
	if on_ground:
		complete = ground.update_chunks(ground_view.cam, 8 if not shot_path.is_empty() else 2)
	else:
		var motion := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		motion += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		cam.position += motion * dt * 650.0 / cam.zoom.x
		_clamp_camera()
		overlay.queue_redraw()
	travel_button.visible = _inside(selected)
	travel_button.position = Vector2(overlay.size.x - 418, 224)
	frame += 1
	if not shot_path.is_empty() and frame >= maxi(1, shot_frames) and not taking_shot and complete and DisplayServer.get_name() != "headless":
		taking_shot = true
		await RenderingServer.frame_post_draw
		if not shot_path.get_base_dir().is_empty():
			DirAccess.make_dir_recursive_absolute(shot_path.get_base_dir())
		var error := get_viewport().get_texture().get_image().save_png(shot_path)
		if error != OK:
			push_error("Screenshot failed: %s" % error_string(error))
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M and not on_ground:
		_travel_to(Vector2i(ground_view.cam.position / 32.0))
		get_viewport().set_input_as_handled()
		return
	if on_ground:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		_reset()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
				_travel_to(Vector2i((get_global_mouse_position() / 0.5).floor()))
				return
			dragging = event.pressed
			if event.pressed:
				drag_distance = 0.0
			elif event.button_index == MOUSE_BUTTON_LEFT and drag_distance < 5.0:
				selected = _mouse_cell()
				selected_tile = Vector2i((get_global_mouse_position() / 0.5).floor())
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var before := get_global_mouse_position()
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), fit_zoom, 8.0)
			cam.force_update_scroll()
			cam.position += before - get_global_mouse_position()
			_clamp_camera()
	elif event is InputEventMouseMotion and dragging:
		drag_distance += event.relative.length()
		cam.position -= event.relative / cam.zoom
		_clamp_camera()


func _mouse_cell() -> Vector2i:
	return Vector2i((get_global_mouse_position() / CELL).floor())


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < w and cell.y >= 0 and cell.y < h


func _info(cell: Vector2i, tile := Vector2i(-1, -1)) -> String:
	if not _inside(cell):
		return "Hover to read the land · Drag to pan · Scroll to zoom · WASD / arrows to travel"
	var i := cell.y * w + cell.x
	var height: float = ground.ground_height(tile) if tile.x >= 0 else _height(cell.x, cell.y)
	var elevation := roundi((height - 0.5) / 0.5 * 2400.0)
	var t := temperature[i] / 200.0
	var climate := "freezing" if t < 0.25 else ("cold" if t < 0.45 else ("mild" if t < 0.7 else "hot"))
	var result := "%s · %s · %s" % [data.biome_names[biome[i]], "%d zhang deep" % absi(elevation) if water[i] == 1 else "%d zhang" % elevation, climate]
	if rivers[i] > 0:
		result += " · on a river"
	var nearest: Dictionary = {}
	var distance := INF
	for feature: Dictionary in data.features:
		var d := Vector2(cell).distance_to(Vector2(float(feature.x), float(feature.y)))
		if d < distance:
			distance = d
			nearest = feature
	if not nearest.is_empty():
		result += " · near the %s" % nearest.name
	return result


func _draw_overlay() -> void:
	var size := overlay.size
	var transform := get_viewport().get_canvas_transform()
	for feature: Dictionary in data.features:
		var at: Vector2 = transform * (Vector2(float(feature.x), float(feature.y)) * CELL)
		if not Rect2(Vector2.ZERO, size).grow(100).has_point(at):
			continue
		var kind: String = feature.kind
		var px := 19 if kind == "Mountains" else 16
		var angle := 0.0
		if kind == "Rivers":
			angle = wrapf(float(feature.get("ang", 0.0)) * 0.6, -PI, PI)
			if angle > PI / 2.0:
				angle -= PI
			elif angle < -PI / 2.0:
				angle += PI
		if kind == "Mountains":
			at.y += 14
		var text: String = feature.name
		var offset := Vector2(-serif.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / 2.0, 0)
		overlay.draw_set_transform(at, angle)
		overlay.draw_string_outline(serif, offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 4, Color(Palette.PAPER.lightened(0.45), 0.85))
		overlay.draw_string(serif, offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, BLUE if kind in ["Rivers", "Lakes"] else INK)
	overlay.draw_set_transform(Vector2.ZERO)
	for name: String in ["Western Market City", "Eastern Hunting Grounds"]:
		if not ground.sect.destinations.has(name):
			continue
		var at: Vector2 = transform * (Vector2(ground.sect.destinations[name]) * CELL / 16.0)
		overlay.draw_circle(at, 5, Palette.RED.lightened(0.05))
		overlay.draw_string(serif, at + Vector2(9, -8), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	var sect_at: Vector2 = transform * (Vector2(ground.sect.center) * CELL / 16.0)
	overlay.draw_circle(sect_at, 5, Palette.RED)
	var sect_name: String = ground.sect.data.name
	var sect_offset := sect_at + Vector2(9, -8)
	overlay.draw_string_outline(serif, sect_offset, sect_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Palette.PAPER.lightened(0.45))
	overlay.draw_string(serif, sect_offset, sect_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if _inside(selected):
		var at: Vector2 = transform * ((Vector2(selected) + Vector2.ONE * 0.5) * CELL)
		overlay.draw_arc(at, 7, 0, TAU, 24, GOLD, 2, true)
		overlay.draw_line(at - Vector2(11, 0), at + Vector2(11, 0), GOLD, 1)
		overlay.draw_line(at - Vector2(0, 11), at + Vector2(0, 11), GOLD, 1)
		var card := Rect2(size.x - 430, 60, 412, 160)
		overlay.draw_style_box(_box(), card)
		overlay.draw_string(font, card.position + Vector2(12, 24), "Selected · %d, %d" % [selected.x, selected.y], HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.TITLE, INK)
		var lines := _info(selected).replace(" · ", "\n").split("\n")
		for i in lines.size():
			overlay.draw_string(font, card.position + Vector2(12, 46 + i * 16), lines[i], HORIZONTAL_ALIGNMENT_LEFT, 390, Palette.SMALL, Palette.INK_SOFT)
	overlay.draw_style_box(_box(), Rect2(0, 0, size.x, 46))
	overlay.draw_string(font, Vector2(18, 30), str(data.continent), HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.TITLE, INK)
	overlay.draw_string(font, Vector2(size.x - 420, 29), "Seed %s" % data.seed, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, Palette.INK_SOFT)
	overlay.draw_style_box(_box(), Rect2(0, size.y - 42, size.x, 42))
	overlay.draw_string(font, Vector2(18, size.y - 16), _info(_mouse_cell()), HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, Palette.BODY, INK)
	var scale_cells := 50.0 if cam.zoom.x < 2.0 else (5.0 if cam.zoom.x < 12.0 else 0.25)
	var length := scale_cells * CELL * cam.zoom.x
	var base := Vector2(24, size.y - 66)
	overlay.draw_style_box(_box(), Rect2(base - Vector2(10, 28), Vector2(length + 20, 42)))
	overlay.draw_line(base, base + Vector2(length, 0), INK, 2)
	for x in [0.0, length]:
		overlay.draw_line(base + Vector2(x, -5), base + Vector2(x, 3), INK, 2)
	overlay.draw_string(font, base + Vector2(0, -9), "%.1f li" % (scale_cells * 10.0), HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, INK)


func _box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = Palette.LINE
	box.set_border_width_all(1)
	box.set_content_margin_all(6)
	return box


func _reset() -> void:
	if travel:
		travel.kill()
	travel = create_tween().set_parallel(true)
	travel.tween_property(cam, "zoom", Vector2.ONE * fit_zoom, 0.65)
	travel.tween_property(cam, "position", Vector2(w, h) * CELL / 2.0, 0.65)


func _go_to(place: String, _animate: bool) -> void:
	for name: String in ground.sect.destinations:
		if name.nocasecmp_to(place) == 0:
			_travel_to(ground.sect.destinations[name])
			return
	if place.nocasecmp_to("Servants' Village") == 0:
		_travel_to(life.square)
		return
	if place.nocasecmp_to(str(ground.sect.data.name)) == 0:
		_travel_to(ground.sect.center)
		return
	for feature: Dictionary in data.features:
		if str(feature.name).nocasecmp_to(place) != 0:
			continue
		_travel_to(Vector2i(roundi(float(feature.x) * 16.0), roundi(float(feature.y) * 16.0)))
		return
	push_warning("Unknown place: %s" % place)


func _travel_to(tile: Vector2i) -> void:
	if travel:
		travel.kill()
	on_ground = true
	dragging = false
	terrain.hide()
	river_art.hide()
	map_layer.hide()
	ground.show()
	ground_view.enter(tile)


func show_map() -> void:
	on_ground = false
	ground_view.leave()
	cam.make_current()
	cam.position = ground_view.cam.position / 64.0
	var margin := cam.position.min(Vector2(w, h) * CELL - cam.position).max(Vector2.ONE)
	var required := get_viewport_rect().size / (margin * 2.0)
	cam.zoom = Vector2.ONE * clampf(maxf(cam.zoom.x, maxf(required.x, required.y)), fit_zoom, 8.0)
	_clamp_camera()
	ground.hide()
	terrain.show()
	river_art.show()
	map_layer.show()
	get_viewport().set_input_as_handled()


func _window_setup() -> void:
	if DisplayServer.get_name() == "headless" or "--windowed" in OS.get_cmdline_user_args() or "--windowed" in OS.get_cmdline_args() or not shot_path.is_empty():
		return
	var target := -1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screen="):
			target = int(argument.get_slice("=", 1))
	if target < 0 and DisplayServer.get_screen_count() > 1:
		target = 1 if DisplayServer.get_primary_screen() == 0 else 0
	var win := get_window()
	if target >= 0 and target < DisplayServer.get_screen_count():
		win.mode = Window.MODE_WINDOWED
		win.current_screen = target
	win.mode = Window.MODE_FULLSCREEN
