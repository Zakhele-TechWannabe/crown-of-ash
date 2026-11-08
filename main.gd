extends Node2D
## Watch a settlement grow; govern its policies and move only the camera.

const World := preload("res://src/world.gd")
const Land := preload("res://src/land.gd")
const Sfx := preload("res://src/sfx.gd")
const T := Land.T
const C_TEXT := Color(0.95, 0.92, 0.85)
const C_GOLD := Color(1.0, 0.8, 0.35)
const P_BG := Color(0.16, 0.1, 0.06, 0.94)
const P_EDGE := Color(0.76, 0.58, 0.3)

## Visual people carry no simulation state.
class Figure:
	var position := Vector2.ZERO
	var target := Vector2.ZERO
	var task := -1
	var workplace := Vector2i(-1, -1)
	var pause := 0.0
	var phase := 0.0
	var walking := false
	var colour := Color.WHITE

var figures: Array[Figure] = []
var people: Node2D
var figure_rng := RandomNumberGenerator.new()

var c := World.new()
var speed := 1
var font: Font
var font_px: Font
var ground: Node2D
var cam: Camera2D
var hud_draw: Control
var sfx: Sfx
var mini_tex: ImageTexture
var minimap := Rect2()
var ground_sig := -1
var drag := false
var shot_path := ""
var shot_frames := 0
var frame := 0
var policy_panel: PanelContainer
var policy_buttons: Array = []
var field_label: Label
var rotation_buttons: Array[OptionButton] = []
var granary_rows: Array[Label] = []
var selected := -1
var tool := 0
var marking := false
var mark_start := Vector2i.ZERO
var mark_end := Vector2i.ZERO
var status_label: Label
var speed_buttons: Array[Button] = []


## Fonts, cached terrain and government controls share the existing visual theme.
func _ready() -> void:
	font = load("res://assets/fonts/Lato-Bold.ttf")
	font_px = load("res://assets/fonts/PixelifySans.ttf")
	sfx = Sfx.new()
	add_child(sfx)
	ground = Node2D.new()
	ground.draw.connect(_draw_ground)
	add_child(ground)
	people = Node2D.new()
	people.draw.connect(_draw_people)
	add_child(people)
	figure_rng.seed = 719
	cam = Camera2D.new()
	cam.position = c.land.center(c.center)
	cam.zoom = Vector2(2.6, 2.6)
	add_child(cam)
	var hud := CanvasLayer.new()
	add_child(hud)
	hud_draw = Control.new()
	hud_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_draw.draw.connect(_draw_hud)
	hud.add_child(hud_draw)
	_build_ui()
	for argument in OS.get_cmdline_user_args():
		if argument == "--fast":
			speed = 4
		elif argument.begins_with("--shot="):
			shot_path = argument.trim_prefix("--shot=")
		elif argument.begins_with("--frames="):
			shot_frames = int(argument.get_slice("=", 1))
		elif argument.begins_with("--zoom="):
			cam.zoom = Vector2.ONE * maxf(0.2, float(argument.get_slice("=", 1)))
		elif argument.begins_with("--look="):
			var parts := argument.get_slice("=", 1).split(",")
			if parts.size() == 2:
				cam.position = Vector2(float(parts[0]), float(parts[1])) * T
	if not "--windowed" in OS.get_cmdline_user_args() and shot_path.is_empty():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


## Policies are the only controls that change settlement decisions.
func _build_ui() -> void:
	var panel := PanelContainer.new()
	policy_panel = panel
	panel.position = Vector2(14, 100)
	panel.custom_minimum_size = Vector2(340, 0)
	panel.add_theme_stylebox_override("panel", _box(P_BG, P_EDGE))
	hud_draw.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_lbl("TOOLS", 25, C_GOLD))
	for mode in 3:
		var button := _btn(["Select / none", "Mark field", "Mark housing"][mode], 18)
		button.pressed.connect(func(): tool = mode; marking = false)
		column.add_child(button)
	column.add_child(_lbl("Drag 2–12 cells per side · Esc cancels", 15, C_TEXT))
	column.add_child(_lbl("Labour focus", 19, C_GOLD))
	var row := HBoxContainer.new()
	column.add_child(row)
	for setting in 3:
		var button := _btn(World.POLICY_NAMES[setting], 16)
		button.toggle_mode = true
		button.pressed.connect(func(): c.focus = setting)
		row.add_child(button)
		policy_buttons.append(button)
	status_label = _lbl("", 15, C_TEXT)
	column.add_child(status_label)
	field_label = _lbl("Click a field to select it.", 16, C_TEXT)
	column.add_child(field_label)
	for season_index in 4:
		var rotation := HBoxContainer.new()
		column.add_child(rotation)
		rotation.add_child(_lbl(World.SEASONS[season_index], 16, C_GOLD))
		var button := OptionButton.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", _box(P_BG, P_EDGE))
		button.add_theme_color_override("font_color", C_TEXT)
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 16)
		for crop_index in World.CROPS.size():
			var crop: Dictionary = World.CROPS[crop_index]
			button.add_item("%s (%s)" % [crop.name, crop.kind])
			button.get_popup().set_item_tooltip(crop_index, crop.info)
		button.item_selected.connect(_choose_crop.bind(season_index))
		rotation.add_child(button)
		rotation_buttons.append(button)
	var remove := _btn("Remove selected field", 16)
	remove.pressed.connect(func(): c.remove_field(selected); selected = -1)
	column.add_child(remove)
	var speeds := HBoxContainer.new()
	speeds.position = Vector2(16, 52)
	hud_draw.add_child(speeds)
	for value in [0, 1, 2, 4]:
		var button := _btn("Pause" if value == 0 else "%dx" % value, 17)
		button.toggle_mode = true
		button.pressed.connect(_set_speed.bind(value))
		speeds.add_child(button)
		speed_buttons.append(button)

	var stores := PanelContainer.new()
	stores.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	stores.position = Vector2(-284, 280)
	stores.custom_minimum_size.x = 270
	stores.add_theme_stylebox_override("panel", _box(P_BG, P_EDGE))
	hud_draw.add_child(stores)
	var contents := VBoxContainer.new()
	stores.add_child(contents)
	contents.add_child(_lbl("GRANARY", 20, C_GOLD))
	for crop in World.CROPS:
		var label := _lbl("", 16, Color(0.55, 0.9, 0.95) if crop.kind == "spirit root" else C_TEXT, null, false)
		contents.add_child(label)
		granary_rows.append(label)


## A government change takes effect at the next daily allocation.
func _selected_field() -> Dictionary:
	for f in c.fields:
		if f.id == selected:
			return f
	return {}

func _choose_crop(crop_index: int, season_index: int) -> void:
	var f := _selected_field()
	if not f.is_empty():
		f.plan[season_index] = crop_index
		# Plans apply when the next season begins; active crops remain unchanged.

## Time can be paused without stopping the camera.
func _set_speed(value: int) -> void:
	speed = value


## Terrain and minimap are rebuilt only after a tile revision.
func _process(dt: float) -> void:
	c.step(dt * speed)
	_move_people(dt * speed)
	people.queue_redraw()
	if ground_sig != c.revision:
		ground_sig = c.revision
		ground.queue_redraw()
	for index in 3:
		policy_buttons[index].set_pressed_no_signal(c.focus == index)
	status_label.text = "Fields %d · Building %d · Idle %d" % [c.labour.x, c.labour.y, 10 - c.labour.x - c.labour.y]
	var f := _selected_field()
	field_label.text = "Click a field to select it." if f.is_empty() else "Field %d · %d × %d cells\nFertility %.1f · %s\n%s · growth %.0f%%" % [f.id, f.rect.size.x, f.rect.size.y, c.average_fertility(f), World.CROPS[f.crop].name, "Idle (season)" if f.idle else f.stage, c.average_growth(f) * 100]
	for index in 4:
		rotation_buttons[index].get_parent().visible = not f.is_empty()
		if not f.is_empty():
			rotation_buttons[index].select(int(f.plan[index]))
			rotation_buttons[index].tooltip_text = World.CROPS[f.plan[index]].info
	for index in 4:
		speed_buttons[index].set_pressed_no_signal(speed == [0, 1, 2, 4][index])
	for index in World.CROPS.size():
		granary_rows[index].visible = c.granary[index] > 0
		granary_rows[index].text = "%s  %.2f" % [World.CROPS[index].name, c.granary[index]]
	var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	cam.position += motion * dt * 650.0 / cam.zoom.x
	_clamp_camera()
	hud_draw.queue_redraw()
	frame += 1
	if shot_path != "" and frame >= maxi(1, shot_frames):
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(shot_path)
		if error != OK:
			push_error("Screenshot failed: %s" % error_string(error))
		get_tree().quit()


## Drag to pan, scroll to zoom, or click the minimap to look elsewhere.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		tool = 0
		marking = false
		ground.queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var cell := Vector2i((get_global_mouse_position() / T).floor())
			if event.pressed:
				if tool > 0:
					marking = true
					mark_start = cell
					mark_end = cell
				else:
					selected = c.land.field_ids[c.land.index(cell)] if c.land._in(cell.x, cell.y) else -1
			elif marking:
				mark_end = cell
				var rect := _mark_rect()
				if tool == 1:
					selected = c.mark_field(rect)
				else:
					c.mark_housing(rect)
				marking = false
			ground.queue_redraw()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.3, 5.0)
	elif event is InputEventMouseMotion and marking:
		mark_end = Vector2i((get_global_mouse_position() / T).floor())
	elif event is InputEventMouseMotion and drag:
		cam.position -= event.relative / cam.zoom


## Keep the view inside the land, centering any axis smaller than the viewport.
func _clamp_camera() -> void:
	var half := get_viewport_rect().size / cam.zoom / 2.0
	var extent := Vector2(Land.W, Land.H) * T
	for axis in 2:
		cam.position[axis] = extent[axis] / 2.0 if half[axis] * 2.0 >= extent[axis] else clampf(cam.position[axis], half[axis], extent[axis] - half[axis])


## Stores and the chronicle explain the results of government policy.
func _draw_hud() -> void:
	var h := hud_draw
	var size := h.size
	h.draw_rect(Rect2(0, 0, size.x, 46), P_BG)
	h.draw_line(Vector2(0, 45), Vector2(size.x, 45), P_EDGE, 2)
	_icon(h, Vector2(26, 23))
	h.draw_string(font_px, Vector2(48, 31), "THE EMPIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, C_GOLD)
	h.draw_string(font, Vector2(250, 30), "Year %d · %s · Day %d    People 10    Stores %.1f" % [c.year, World.SEASONS[c.season()], c.day, _total_stores()], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_TEXT)
	var y := size.y - 24.0
	for index in range(c.log.size() - 1, maxi(-1, c.log.size() - 6), -1):
		h.draw_rect(Rect2(14, y - 20, 600, 26), P_BG)
		h.draw_string(font, Vector2(24, y), c.log[index], HORIZONTAL_ALIGNMENT_LEFT, 580, 16, C_TEXT)
		y -= 28
	minimap = Rect2(size.x - 284, 60, 270, 270.0 * Land.H / Land.W)
	if mini_tex:
		h.draw_texture_rect(mini_tex, minimap, false)
		var view := Rect2(cam.position - size / cam.zoom / 2.0, size / cam.zoom)
		var scale := minimap.size / (Vector2(Land.W, Land.H) * T)
		h.draw_rect(Rect2(minimap.position + view.position * scale, view.size * scale).intersection(minimap), C_TEXT, false, 1.5)
	h.draw_rect(minimap.grow(2), P_EDGE, false, 2)

func _total_stores() -> float:
	var total := 0.0
	for amount in c.granary:
		total += amount
	return total


## A crown marks the government view.
func _icon(item: CanvasItem, at: Vector2) -> void:
	item.draw_colored_polygon(PackedVector2Array([at + Vector2(-12, 8), at + Vector2(-12, -7), at + Vector2(-6, 0), at + Vector2(0, -10), at + Vector2(6, 0), at + Vector2(12, -7), at + Vector2(12, 8)]), C_GOLD)


## Make a label in the shared interface style.
func _lbl(text: String, size: int, col: Color, f: Font = null, center := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", f if f else font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.y = size * 1.4
	l.tree_entered.connect(_fit_label.bind(l))
	return l


## Wrapping labels in an HBox shrink to one letter per line unless they're told to fill.
func _fit_label(l: Label) -> void:
	if l.get_parent() is HBoxContainer:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Frame a panel with the shared border and padding.
func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_corner_radius_all(3)
	b.set_border_width_all(2)
	b.border_color = border
	b.set_content_margin_all(8)
	return b


## Make a policy or speed button with click feedback.
func _btn(text: String, size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	b.add_theme_stylebox_override("normal", _box(Color(0.22, 0.14, 0.08, 0.95), Color(0.5, 0.36, 0.2)))
	b.add_theme_stylebox_override("hover", _box(Color(0.3, 0.2, 0.1, 0.97), C_GOLD))
	b.add_theme_stylebox_override("pressed", _box(Color(0.4, 0.26, 0.1, 0.97), C_GOLD))
	b.add_theme_stylebox_override("disabled", _box(Color(0.08, 0.08, 0.08, 0.9), Color(0.3, 0.3, 0.3)))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(sfx.play.bind("click"))
	return b


## Stable tile variation needs no mutable random state.
func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float(h % 1000) / 1000.0


## Cache the plain and completed settlement plots.
func _draw_ground() -> void:
	if c == null:
		return
	_bake_minimap()
	ground.draw_rect(Rect2(0, 0, Land.W * T, Land.H * T), Color(0.38, 0.6, 0.21))
	for y in Land.H:
		for x in Land.W:
			_tile(Vector2i(x, y))
	for zone in c.zones:
		var r := Rect2(Vector2(zone.position) * T, Vector2(zone.size) * T)
		for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
			ground.draw_dashed_line(edge[0], edge[1], C_GOLD, 1.5, 6)
	for f in c.fields:
		ground.draw_rect(Rect2(Vector2(f.rect.position) * T, Vector2(f.rect.size) * T), C_GOLD if f.id == selected else Color(0.45, 0.3, 0.12), false, 2)
	for house in c.houses:
		_hut(house)


## The minimap's land, one pixel a cell, made again whenever the ground is.
func _bake_minimap() -> void:
	var img := Image.create(Land.W, Land.H, false, Image.FORMAT_RGBA8)
	for y in Land.H:
		for x in Land.W:
			var col := Color(0.36, 0.56, 0.2)
			match c.land.at(Vector2i(x, y)):
				Land.TILLED: col = Color(0.55, 0.4, 0.2)
				Land.HOUSE: col = Color(0.85, 0.63, 0.25)
			img.set_pixel(x, y, col)
	mini_tex = ImageTexture.create_from_image(img)


## Draw grass, roads and worked plots.
func _tile(cell: Vector2i) -> void:
	var g := ground
	var land := c.land
	var t := land.at(cell)
	var rect := Rect2(cell.x * T, cell.y * T, T, T)
	var h := _hash(cell.x, cell.y)
	var patch := _hash(cell.x / 4, cell.y / 4)
	match t:
		Land.GRASS:
			var col := Color(0.35, 0.56, 0.19).lerp(Color(0.45, 0.66, 0.25), patch * 0.65 + h * 0.35)
			g.draw_rect(rect, col)
			if h < 0.04:
				var fc: Color = [Color(0.98, 0.9, 0.4), Color(0.96, 0.96, 0.9), Color(0.92, 0.55, 0.62)][int(h * 75) % 3]
				g.draw_circle(rect.position + Vector2(6 + h * 300, 10), 2.5, fc)
				g.draw_circle(rect.position + Vector2(20, 24 - h * 100), 2.0, fc)
			elif h < 0.14:
				var p := rect.position + Vector2(6 + h * 120, 16 + h * 60)
				g.draw_line(p, p + Vector2(-2, -6), col.darkened(0.25), 1.5)
				g.draw_line(p, p + Vector2(2, -7), col.darkened(0.25), 1.5)
		Land.HOUSE:
			g.draw_rect(rect, Color(0.48, 0.55, 0.25))
		Land.TILLED:
			g.draw_rect(rect, Color(0.37, 0.24, 0.13))
			var i := land.index(cell)
			var growth: float = land.growth[i]
			var crop: int = land.crops[i]
			var kind: String = World.CROPS[crop].kind
			for k in 4:
				var p := rect.position + Vector2(5 + k * 7, 27)
				var col := Color(0.85, 0.7, 0.25) if growth >= 0.99 and kind == "grain" else Color(0.3, 0.6, 0.18)
				if kind == "none":
					g.draw_line(p, p + Vector2(2, -6), Color(0.48, 0.47, 0.26), 3)
				elif growth > 0 and kind in ["root", "spirit root"]:
					var leaf := Color(0.25, 0.65, 0.25) if kind == "root" else Color(0.5, 0.75, 0.95)
					for row in 2:
						var tuft := p + Vector2(0, -row * 13)
						if kind == "spirit root":
							g.draw_circle(tuft + Vector2(0, -3), 5 + growth * 3, Color(0.45, 0.3, 0.85, 0.18))
						g.draw_line(tuft, tuft + Vector2(-3, -3 - growth * 5), leaf, 2)
						g.draw_line(tuft, tuft + Vector2(3, -4 - growth * 5), leaf, 2)
				elif growth > 0:
					g.draw_line(p, p + Vector2(0, -4 - growth * 20), col, 3)
				else:
					g.draw_line(p, p + Vector2(0, -25), Color(0.26, 0.17, 0.1), 2)
	g.draw_rect(rect, Color(0.1, 0.16, 0.05, 0.12), false, 0.5)

func _mark_rect() -> Rect2i:
	return Rect2i(Vector2i(mini(mark_start.x, mark_end.x), mini(mark_start.y, mark_end.y)), Vector2i(absi(mark_end.x - mark_start.x) + 1, absi(mark_end.y - mark_start.y) + 1))

## Golden hipped thatch shelters each household.
func _hut(cell: Vector2i) -> void:
	var p := Vector2(cell) * T + Vector2(4, 8)
	var a := p + Vector2(16, 26)
	var b := p + Vector2(44, 26)
	ground.draw_rect(Rect2(p + Vector2(6, 14), Vector2(60, 54)), Color(0, 0, 0, 0.3))
	ground.draw_rect(Rect2(p + Vector2(6, 20), Vector2(48, 40)), Color(0.65, 0.43, 0.23))
	ground.draw_rect(Rect2(p + Vector2(24, 44), Vector2(14, 16)), Color(0.22, 0.14, 0.07))
	ground.draw_colored_polygon(PackedVector2Array([p, p + Vector2(60, 0), b, a]), Color(0.96, 0.79, 0.33))
	ground.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 50), a, b, p + Vector2(60, 50)]), Color(0.69, 0.48, 0.17))
	ground.draw_colored_polygon(PackedVector2Array([p, a, p + Vector2(0, 50)]), Color(0.84, 0.65, 0.25))
	ground.draw_colored_polygon(PackedVector2Array([p + Vector2(60, 0), p + Vector2(60, 50), b]), Color(0.77, 0.55, 0.18))
	for offset in [4, 8]:
		ground.draw_line(p + Vector2(offset, offset), p + Vector2(30 - offset, offset), Color(0.67, 0.47, 0.18), 1)
	ground.draw_line(a, b, Color(0.4, 0.26, 0.1), 2)


## Figures follow the labour counts without feeding anything back into the world.
func _move_people(dt: float) -> void:
	while figures.size() < mini(c.population, 300):
		var person := Figure.new()
		person.position = c.land.center(c.center) + Vector2(0, 28)
		person.target = person.position
		person.phase = figure_rng.randf_range(0, TAU)
		person.colour = Color.from_hsv(figure_rng.randf(), 0.35, figure_rng.randf_range(0.55, 0.85))
		figures.append(person)
	figures.resize(mini(c.population, 300))
	for index in figures.size():
		var person := figures[index]
		var task: int = c.assignments[index].task
		var workplace: Vector2i = c.assignments[index].cell
		if task != person.task or workplace != person.workplace:
			person.task = task
			person.workplace = workplace
			_pick_spot(person)
		var distance := person.position.distance_to(person.target)
		person.walking = distance > 0.5
		person.phase += dt * (8.0 if person.walking else 3.0)
		if person.walking:
			person.position = person.position.move_toward(person.target, dt * (13.0 + index % 5))
		else:
			person.pause -= dt
			if person.pause <= 0:
				_pick_spot(person)


## Workers stay on their plot; idle people wander just outside their home.
func _pick_spot(person: Figure) -> void:
	var spread := 11.0 if person.task == 0 else 19.0
	person.target = c.land.center(person.workplace) + Vector2(figure_rng.randf_range(-spread, spread), figure_rng.randf_range(-spread, spread))
	if person.task != 0:
		person.target.y = c.land.center(person.workplace).y + figure_rng.randf_range(17, 27)
	person.pause = figure_rng.randf_range(2, 6)


## Heads, coloured tunics and swaying limbs keep the crowd inexpensive.
func _draw_people() -> void:
	if marking:
		var rect := _mark_rect()
		people.draw_rect(Rect2(Vector2(rect.position) * T, Vector2(rect.size) * T), Color(0.8, 0.9, 0.4, 0.3) if c.can_mark(rect, tool == 1) else Color(1, 0.2, 0.1, 0.4))
	if c.site.x >= 0:
		var plot := Rect2(Vector2(c.site) * T + Vector2(2, 2), Vector2(T * 2 - 4, T * 2 - 4))
		people.draw_rect(plot, Color(0.52, 0.36, 0.19, 0.65))
		people.draw_rect(plot, C_GOLD, false, 1)
	for person in figures:
		var sway := sin(person.phase)
		var working := not person.walking and person.task < 2
		var p := person.position
		var bend := Vector2(2, 1) * sway if working and person.task == 0 else Vector2.ZERO
		people.draw_line(p + Vector2(-2, 2), p + Vector2(-2, 5 + sway * float(person.walking)), Color(0.23, 0.17, 0.12), 2)
		people.draw_line(p + Vector2(2, 2), p + Vector2(2, 5 - sway * float(person.walking)), Color(0.23, 0.17, 0.12), 2)
		people.draw_rect(Rect2(p + Vector2(-3, -4) + bend, Vector2(6, 7)), person.colour)
		people.draw_circle(p + Vector2(0, -6) + bend, 2.7, Color(0.65, 0.43, 0.27))
		if working:
			var hand := p + Vector2(5, -2 + sway * 3)
			people.draw_line(p + Vector2(2, -2), hand, Color(0.65, 0.43, 0.27), 2)
			people.draw_line(hand, hand + Vector2(3, 5 if person.task == 0 else -3), Color(0.35, 0.29, 0.2), 1.5)
