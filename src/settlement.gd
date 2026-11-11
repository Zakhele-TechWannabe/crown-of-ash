extends Node2D
## Watch a settlement grow; govern its policies and move only the camera.

const World := preload("res://src/world.gd")
const Land := preload("res://src/land.gd")
const Sfx := preload("res://src/sfx.gd")
const FARM := preload("res://assets/kenney/tiny-farm/Tilemap/tilemap_packed.png")
const TOWN := preload("res://assets/kenney/tiny-town/Tilemap/tilemap_packed.png")
const CROP_ROWS := [64, 64, 40, 0, 16, 16, 4, 16, 52, 40, 28, 4, 52, 16]
const CROP_TINTS := [Color.WHITE, Color(1, 1, 0.8), Color(0.65, 1, 0.5), Color.WHITE,
	Color.WHITE, Color(1, 0.4, 0.45), Color.WHITE, Color(0.65, 0.18, 0.3),
	Color(1, 1, 0.8), Color(0.75, 0.65, 0.4), Color(0.9, 0.6, 0.3),
	Color(1, 0.95, 0.7), Color(0.5, 1, 0.75), Color(1, 0.3, 0.15)]
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
	var facing_left := false

var figures: Array[Figure] = []
var people: Node2D
var figure_rng := RandomNumberGenerator.new()

var c: World
var active := false
var hud: CanvasLayer
var origin := Vector2i.ZERO
var speed := 1
var font: Font
var font_px: Font
var ground: Node2D
var cam: Camera2D
var hud_draw: Control
var sfx: Sfx
var ground_sig := -1
var drag := false
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
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.draw.connect(_draw_ground)
	add_child(ground)
	people = Node2D.new()
	people.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	people.draw.connect(_draw_people)
	add_child(people)
	figure_rng.seed = 719
	cam = Camera2D.new()
	cam.position = Vector2(origin) * T + c.land.center(c.center)
	cam.zoom = Vector2.ONE
	add_child(cam)
	hud = CanvasLayer.new()
	add_child(hud)
	hud_draw = Control.new()
	hud_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_draw.draw.connect(_draw_hud)
	hud.add_child(hud_draw)
	_build_ui()
	ground.position = Vector2(origin) * T
	people.position = ground.position


## Policies are the only controls that change settlement decisions.
func _build_ui() -> void:
	var map_button := _btn("World map [M]", 17)
	map_button.position = Vector2(310, 52)
	map_button.pressed.connect(_open_world_map)
	hud_draw.add_child(map_button)
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
	column.add_child(_lbl("Drag 2–12 tiles · M / Esc: map", 15, C_TEXT))
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
	contents.add_child(_lbl("CROPS · GRANARY", 20, C_GOLD))
	var heading := ""
	for crop in World.CROPS:
		# A small heading whenever the kind changes: grains, roots, spirit roots.
		var group: String = {"grain": "Grains & beans", "legume": "Grains & beans", "none": "Grains & beans", "root": "Roots", "spirit root": "Spirit roots"}[crop.kind]
		if group != heading:
			heading = group
			contents.add_child(_lbl(group, 15, Color(0.55, 0.9, 0.95) if group == "Spirit roots" else C_GOLD, null, false))
		var label := _lbl("", 15, Color(0.55, 0.9, 0.95) if crop.kind == "spirit root" else C_TEXT, null, false)
		label.tooltip_text = crop.info
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		contents.add_child(label)
		granary_rows.append(label)
	contents.add_child(_lbl("Mark a field, then pick its crop\nfor each season in the Tools panel.", 13, C_TEXT, null, false))


## A government change takes effect at the next daily allocation.
## A ready-made village for looking at: a field of every crop and a housing zone, a few days in.
func _demo() -> void:
	for k in World.CROPS.size():
		var placed := false
		for y in range(24, Land.H - 4, 4):
			for x in range(24, Land.W - 4, 4):
				if c.mark_field(Rect2i(x, y, 3, 3), [k, k, k, k]) >= 0:
					placed = true
					break
			if placed:
				break
	for y in range(20, Land.H - 4):
		var placed := false
		for x in range(20, Land.W - 4):
			if c.mark_housing(Rect2i(x, y, 4, 4)):
				placed = true
				break
		if placed:
			break
	c.focus = 0
	for d in 5:
		c.step(World.DAY_LEN)


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


## Settlement art is rebuilt only after a tile revision.
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
		granary_rows[index].visible = World.CROPS[index].kind != "none"
		granary_rows[index].text = "  %s  %.2f" % [World.CROPS[index].name, c.granary[index]]
		granary_rows[index].modulate.a = 1.0 if c.granary[index] > 0 else 0.55
	if not active:
		return
	var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	cam.position += motion * dt * 650.0 / cam.zoom.x
	_clamp_camera()
	hud_draw.queue_redraw()


## Drag to pan or scroll to zoom.
func _open_world_map() -> void:
	get_parent().show_map()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_M, KEY_ESCAPE]:
		_open_world_map()
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var cell := Vector2i((get_global_mouse_position() / T - Vector2(origin)).floor())
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
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.5, 2.0)
	elif event is InputEventMouseMotion and marking:
		mark_end = Vector2i((get_global_mouse_position() / T - Vector2(origin)).floor())
	elif event is InputEventMouseMotion and drag:
		cam.position -= event.relative / cam.zoom


## Keep the view inside the land, centering any axis smaller than the viewport.
func _clamp_camera() -> void:
	var half := get_viewport_rect().size / cam.zoom / 2.0
	var extent := Vector2(get_parent().w * 16, get_parent().h * 16) * T
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


## Cache completed settlement plots.
func _draw_ground() -> void:
	if c == null:
		return

	for y in Land.H:
		for x in Land.W:
			_tile(Vector2i(x, y))
	for zone in c.zones:
		var r := Rect2(Vector2(zone.position) * T, Vector2(zone.size) * T)
		for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
			ground.draw_dashed_line(edge[0], edge[1], C_GOLD, 1.5, 6)
	for house in c.houses:
		_hut(house)


## Atlas regions stay at one tile per world cell.
func _atlas(item: CanvasItem, texture: Texture2D, index: int, at: Vector2, tint := Color.WHITE, flip := false) -> void:
	var source := Rect2(Vector2(index % 12, index / 12) * 16, Vector2(16, 16))
	var rect := Rect2(at, Vector2(T, T))
	if flip:
		rect.position.x += T
		rect.size.x = -T
	item.draw_texture_rect_region(texture, rect, source, tint)


## Grass remains beneath soil and transparent sprites.
func _tile(cell: Vector2i) -> void:
	var at := Vector2(cell) * T
	var i := c.land.index(cell)
	var crop: int = c.land.crops[i]
	if c.land.field_ids[i] < 0:
		return
	if World.CROPS[crop].kind == "none":
		_atlas(ground, FARM, 0, at, Color(1, 1, 1, 0.55))
	elif c.land.at(cell) == Land.TILLED:
		_atlas(ground, FARM, 1, at)
		if c.land.growth[i] > 0 and World.CROPS[crop].kind != "spirit root":
			_plant(ground, cell, crop, c.land.growth[i])


## Ripe produce follows the three leafy growth stages.
func _plant(item: CanvasItem, cell: Vector2i, crop: int, growth: float) -> void:
	var stage := 4 if growth >= 0.99 else mini(2, int(growth * 3.0))
	_atlas(item, FARM, CROP_ROWS[crop] + stage, Vector2(cell) * T, CROP_TINTS[crop])

func _mark_rect() -> Rect2i:
	return Rect2i(Vector2i(mini(mark_start.x, mark_end.x), mini(mark_start.y, mark_end.y)), Vector2i(absi(mark_end.x - mark_start.x) + 1, absi(mark_end.y - mark_start.y) + 1))

## Two roof tiles sit above the window and door.
func _hut(cell: Vector2i) -> void:
	var at := Vector2(cell) * T
	_atlas(ground, TOWN, 64, at)
	_atlas(ground, TOWN, 66, at + Vector2(T, 0))
	_atlas(ground, TOWN, 84, at + Vector2(0, T))
	_atlas(ground, TOWN, 85, at + Vector2(T, T))


## Figures follow the labour counts without feeding anything back into the world.
func _move_people(dt: float) -> void:
	while figures.size() < mini(c.population, 300):
		var person := Figure.new()
		person.position = c.land.center(c.center) + Vector2(0, 28)
		person.target = person.position
		person.phase = figure_rng.randf_range(0, TAU)
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
			if absf(person.target.x - person.position.x) > 0.1:
				person.facing_left = person.target.x < person.position.x
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


## Glows, selection and moving farmers leave the ground cache untouched.
func _draw_people() -> void:
	for f in c.fields:
		people.draw_rect(Rect2(Vector2(f.rect.position) * T, Vector2(f.rect.size) * T), C_GOLD if f.id == selected else Color(0.45, 0.3, 0.12), false, 2)
		if World.CROPS[f.crop].kind != "spirit root":
			continue
		for cell in c.cells(f.rect):
			var i := c.land.index(cell)
			if c.land.at(cell) != Land.TILLED or c.land.growth[i] <= 0:
				continue
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.002 + _hash(cell.x, cell.y) * TAU)
			for ring in 3:
				var glow: Color = CROP_TINTS[f.crop]
				glow.a = (0.035 + pulse * 0.025) * (ring + 1)
				people.draw_circle(c.land.center(cell), 15.0 - ring * 3.0, glow)
			_plant(people, cell, c.land.crops[i], c.land.growth[i])
	if marking:
		var rect := _mark_rect()
		people.draw_rect(Rect2(Vector2(rect.position) * T, Vector2(rect.size) * T), Color(0.8, 0.9, 0.4, 0.3) if c.can_mark(rect, tool == 1) else Color(1, 0.2, 0.1, 0.4))
	if c.site.x >= 0:
		var at := Vector2(c.site) * T
		_atlas(people, TOWN, 84, at + Vector2(0, T), Color(1, 1, 1, 0.5))
		_atlas(people, TOWN, 85, at + Vector2(T, T), Color(1, 1, 1, 0.5))
		_atlas(people, FARM, 98, at + Vector2(0, T * 2))
		_atlas(people, FARM, 99, at + Vector2(T, T * 2))
		people.draw_rect(Rect2(at + Vector2(2, 2), Vector2(T * 2 - 4, T * 2 - 4)), C_GOLD, false, 1)
	for index in figures.size():
		var person := figures[index]
		_atlas(people, FARM, 108 + index % 2, person.position - Vector2(T / 2, T - 5), Color.WHITE, person.facing_left)
