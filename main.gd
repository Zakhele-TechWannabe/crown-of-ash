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
var descriptions: Array[Label] = []
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
	column.add_child(_lbl("POLICIES", 25, C_GOLD))
	for index in 3:
		column.add_child(_lbl(["Labour focus", "Rations", "Growth"][index], 19, C_TEXT, null, false))
		var row := HBoxContainer.new()
		column.add_child(row)
		var buttons: Array[Button] = []
		for setting in 3:
			var button := _btn(World.POLICY_NAMES[index][setting], 16)
			button.toggle_mode = true
			button.pressed.connect(_set_policy.bind(index, setting))
			row.add_child(button)
			buttons.append(button)
		policy_buttons.append(buttons)
		var description := _lbl("", 15, C_TEXT, null, false)
		description.custom_minimum_size = Vector2(315, 48)
		column.add_child(description)
		descriptions.append(description)
	var speeds := HBoxContainer.new()
	speeds.position = Vector2(16, 52)
	hud_draw.add_child(speeds)
	for value in [0, 1, 2, 4]:
		var button := _btn("Pause" if value == 0 else "%dx" % value, 17)
		button.toggle_mode = true
		button.pressed.connect(_set_speed.bind(value))
		speeds.add_child(button)
		speed_buttons.append(button)


## A government change takes effect at the next daily allocation.
func _set_policy(index: int, setting: int) -> void:
	c.policies[index] = setting


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
		descriptions[index].text = World.DESCRIPTIONS[index][c.policies[index]]
		for setting in 3:
			policy_buttons[index][setting].set_pressed_no_signal(c.policies[index] == setting)
	for index in 4:
		speed_buttons[index].set_pressed_no_signal(speed == [0, 1, 2, 4][index])
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
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			drag = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and minimap.has_point(event.position):
			cam.position = (event.position - minimap.position) / minimap.size * Vector2(Land.W, Land.H) * T
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.3, 5.0)
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
	h.draw_string(font, Vector2(250, 30), "Year %d · Day %d     Population %d     Food %.0f     Housing %d/%d" % [c.year, c.day, c.population, c.food, c.population, c.housing()], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_TEXT)
	var stats := Rect2(14, policy_panel.position.y + policy_panel.size.y + 10, 340, 100)
	h.draw_style_box(_box(P_BG, P_EDGE), stats)
	h.draw_string(font, stats.position + Vector2(12, 25), "DAILY LABOUR", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_GOLD)
	h.draw_string(font, stats.position + Vector2(12, 53), "Farm %.0f   Build %.0f   Idle %.0f" % [c.labour.x, c.labour.y, c.population - c.labour.x - c.labour.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_TEXT)
	h.draw_string(font, stats.position + Vector2(12, 82), "This year: %d births · %d deaths" % [c.births, c.deaths], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_TEXT)
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
	for house in c.houses:
		_hut(house)


## The minimap's land, one pixel a cell, made again whenever the ground is.
func _bake_minimap() -> void:
	var img := Image.create(Land.W, Land.H, false, Image.FORMAT_RGBA8)
	for y in Land.H:
		for x in Land.W:
			var col := Color(0.36, 0.56, 0.2)
			match c.land.at(Vector2i(x, y)):
				Land.ROAD: col = Color(0.72, 0.58, 0.38)
				Land.HOUSE: col = Color(0.85, 0.63, 0.25)
				Land.FIELD: col = Color(0.88, 0.7, 0.26)
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
		Land.ROAD:
			g.draw_rect(rect, Color(0.73, 0.59, 0.39).lerp(Color(0.78, 0.64, 0.43), h))
			g.draw_rect(rect.grow(-3), Color(0.78, 0.64, 0.43))
		Land.HOUSE:
			g.draw_rect(rect, Color(0.48, 0.55, 0.25))
		Land.FIELD:
			g.draw_rect(rect, Color(0.84, 0.66, 0.22))
			for k in 4:
				var x := rect.position.x + 4 + k * 8
				g.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.96, 0.82, 0.38), 3.0)
				g.draw_line(Vector2(x + 3, rect.position.y), Vector2(x + 3, rect.end.y), Color(0.66, 0.48, 0.14), 1.0)
			for o in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if land.at(cell + o) != Land.FIELD:
					var strip := Rect2(rect.position + Vector2(maxf(0, o.x) * (T - 2), maxf(0, o.y) * (T - 2)), Vector2(2 if o.x != 0 else T, 2 if o.y != 0 else T))
					g.draw_rect(strip, Color(0.52, 0.36, 0.14))


## Golden hipped thatch shelters each household.
func _hut(cell: Vector2i) -> void:
	var p := Vector2(cell) * T + Vector2(1, 2)
	var a := p + Vector2(8, 13)
	var b := p + Vector2(22, 13)
	ground.draw_rect(Rect2(p + Vector2(3, 7), Vector2(30, 27)), Color(0, 0, 0, 0.3))
	ground.draw_rect(Rect2(p + Vector2(3, 10), Vector2(24, 20)), Color(0.65, 0.43, 0.23))
	ground.draw_rect(Rect2(p + Vector2(12, 22), Vector2(7, 8)), Color(0.22, 0.14, 0.07))
	ground.draw_colored_polygon(PackedVector2Array([p, p + Vector2(30, 0), b, a]), Color(0.96, 0.79, 0.33))
	ground.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 25), a, b, p + Vector2(30, 25)]), Color(0.69, 0.48, 0.17))
	ground.draw_colored_polygon(PackedVector2Array([p, a, p + Vector2(0, 25)]), Color(0.84, 0.65, 0.25))
	ground.draw_colored_polygon(PackedVector2Array([p + Vector2(30, 0), p + Vector2(30, 25), b]), Color(0.77, 0.55, 0.18))
	for offset in [4, 8]:
		ground.draw_line(p + Vector2(offset, offset), p + Vector2(30 - offset, offset), Color(0.67, 0.47, 0.18), 1)
	ground.draw_line(a, b, Color(0.4, 0.26, 0.1), 2)


## Figures follow the labour counts without feeding anything back into the world.
func _move_people(dt: float) -> void:
	while figures.size() < mini(c.population, 300):
		var person := Figure.new()
		person.position = c.land.center(c.houses[figures.size() % c.houses.size()]) + Vector2(0, 18)
		person.target = person.position
		person.phase = figure_rng.randf_range(0, TAU)
		person.colour = Color.from_hsv(figure_rng.randf(), 0.35, figure_rng.randf_range(0.55, 0.85))
		figures.append(person)
	figures.resize(mini(c.population, 300))
	var farmers := roundi(c.labour.x * figures.size() / maxf(1, c.population))
	var builders := roundi(c.labour.y * figures.size() / maxf(1, c.population))
	for index in figures.size():
		var person := figures[index]
		var task := 0 if index < farmers else (1 if index < farmers + builders and c.project >= 0 else 2)
		var workplace := c.fields[index % c.fields.size()] if task == 0 else (c.site if task == 1 else c.houses[index % c.houses.size()])
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
	if c.project >= 0:
		var plot := Rect2(Vector2(c.site) * T + Vector2(2, 2), Vector2(T - 4, T - 4))
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
