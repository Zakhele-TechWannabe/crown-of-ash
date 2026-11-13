extends Node2D
## Camera and screen-space controls for ground travel.
## Everything on screen hangs under `ui`, which carries the one Theme.

const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const TILE := 32.0
const MAJOR_NAMES := ["Unnamed Sect", "Leader's Hall", "Main Hall", "Great Plaza", "Mountain Gate", "Servants' Village", "Spirit Fields"]
var ledger: PanelContainer
var villager: PanelContainer
var stories: PanelContainer
var tour: Control
var card: PanelContainer
var card_text: Label
var cam: Camera2D
var hud: CanvasLayer
var ui: Control
var place: Label
var readout: Label
var names: Control
var active := false
var dragging := false
var entered_once := false
var map: Node2D


func _ready() -> void:
	map = get_parent()
	cam = Camera2D.new()
	cam.enabled = false
	add_child(cam)
	hud = CanvasLayer.new()
	add_child(hud)
	ui = Control.new()
	ui.theme = UiTheme.build()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(ui)
	names = Control.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	names.draw.connect(_draw_names)
	ui.add_child(names)
	readout = Label.new()
	readout.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	readout.offset_top = -48
	readout.add_theme_stylebox_override("normal", UiTheme.box(Color(Palette.PAPER, 0.94), Palette.LINE, 1, 12, 4, 0))
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(readout)
	# Hovering a person shows a small tag; clicking opens their card.
	card = PanelContainer.new()
	card.theme_type_variation = "Tag"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_text = Label.new()
	card_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_text)
	ui.add_child(card)
	card.hide()
	ledger = preload("res://src/village_ledger.gd").new()
	villager = preload("res://src/villager_card.gd").new()
	stories = preload("res://src/stories_rail.gd").new()
	tour = preload("res://src/tour.gd").new()
	hud.hide()


## Wires the panels once the village exists (called by the world after `life.setup`).
func setup_panels() -> void:
	stories.setup(self)
	villager.setup(self)
	ledger.setup(self)
	tour.setup(self)


func enter(tile: Vector2i) -> void:
	active = true
	hud.show()
	cam.enabled = true
	cam.make_current()
	if not entered_once:
		entered_once = true
		set_zoom_step(Palette.DEFAULT_ZOOM)
	cam.position = (Vector2(tile) + Vector2.ONE * 0.5) * TILE
	cam.position.y -= map.ground.terrace_level(tile) * map.ground.exaggeration
	_clamp_camera()
	_update_readout()


func leave() -> void:
	active = false
	dragging = false
	hud.hide()
	cam.enabled = false


## Window pixels per canvas pixel, so a zoom step lands on whole screen pixels per texel.
func _stretch() -> float:
	return maxf(0.01, get_viewport().get_final_transform().get_scale().x)


func zoom_step() -> int:
	var actual := cam.zoom.x * _stretch()
	var best := 0
	for i in Palette.ZOOMS.size():
		if absf(Palette.ZOOMS[i] - actual) < absf(Palette.ZOOMS[best] - actual):
			best = i
	return best


func set_zoom_step(step: int) -> void:
	cam.zoom = Vector2.ONE * Palette.ZOOMS[clampi(step, 0, Palette.ZOOMS.size() - 1)] / _stretch()
	_clamp_camera()


## Selects a person and brings them into view; walkers are followed, everyone else is centred once.
func show_person(id: int, follow: bool = true) -> void:
	if id < 0:
		return
	map.life.selected = id
	var walker: int = map.life.walker_of(id)
	map.life.followed = walker if follow else -1
	cam.position = map.life.place_of(id)
	_clamp_camera()


func _process(dt: float) -> void:
	if not active:
		return
	var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if ledger.visible or (get_viewport().gui_get_focus_owner() is LineEdit):
		motion = Vector2.ZERO
	if motion != Vector2.ZERO:
		map.life.followed = -1
	if map.life.followed >= 0 and map.life.followed < map.life.people.size():
		cam.position = map.life.point(map.life.people[map.life.followed])
	var mouse := get_viewport().get_mouse_position()
	var hovered: int = -1 if ledger.visible or get_viewport().gui_get_hovered_control() != null else map.life.pick(get_global_mouse_position())
	card.visible = hovered >= 0
	if hovered >= 0:
		var walker: int = map.life.walker_of(hovered)
		card_text.text = map.life.population.names[hovered] + (" · " + map.life.activity_text(map.life.people[walker]) if walker >= 0 else "")
		card.reset_size()
		card.position = (mouse + Vector2(14, 18)).min(get_viewport_rect().size - card.size - Vector2(8, 8))
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
	if place:
		place.text = nearest
	readout.visible = Input.is_physical_key_pressed(KEY_ALT)
	if readout.visible:
		var tile: Vector2i = map.ground.pick_tile(get_global_mouse_position())
		var cell := Vector2i(floori(tile.x / 16.0), floori(tile.y / 16.0))
		readout.text = "%s\n%s · tile %d, %d" % [map._info(cell, tile), map.ground.sample(tile).cover, tile.x, tile.y]


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if ledger.owns_pointer(event):
		dragging = false
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
		if event.keycode in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
			map.ground.set_exaggeration(map.ground.exaggeration + (1.0 if event.keycode == KEY_BRACKETRIGHT else -1.0))
			return
		if event.keycode == KEY_ESCAPE and map.life.followed >= 0:
			map.life.followed = -1
			return
		if event.keycode == KEY_ESCAPE and map.life.selected >= 0:
			map.life.selected = -1
			return
		if event.keycode in [KEY_M, KEY_ESCAPE]:
			map.show_map()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var person: int = map.life.pick(get_global_mouse_position())
			map.life.selected = person
			map.life.followed = -1
			var tile: Vector2i = map.ground.pick_tile(get_global_mouse_position())
			for building: Dictionary in map.ground.sect.data.buildings:
				if person < 0 and building.name == "Granary":
					var r: Array = building.rect
					if Rect2i(map.ground.sect.center + Vector2i(int(r[0]), int(r[1])), Vector2i(int(r[2]), int(r[3]))).has_point(tile):
						ledger.open_tab("food")
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom_step(zoom_step() + (1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1))
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


## Place names sit on small parchment tags so they read as part of the ledger, not as paint on the land.
func _draw_names() -> void:
	if not active:
		return
	var transform := get_viewport().get_canvas_transform()
	var font := UiTheme.body()
	var tag := UiTheme.box(Color(Palette.PAPER_LIGHT, 0.92), Palette.LINE, 1, 0, 0, 3)
	for entry: Dictionary in map.ground.sect.labels:
		var major: bool = entry.name in MAJOR_NAMES or entry.name == str(map.ground.sect.data.name)
		if cam.zoom.x < 0.45 and not major:
			continue
		var tile: Vector2i = entry.tile
		var point := (Vector2(tile) + Vector2(0.5, 0.0)) * TILE
		point.y -= map.ground.terrace_level(tile) * map.ground.exaggeration
		var at: Vector2 = (transform * point - Vector2(0, 8)).round()
		if not get_viewport_rect().grow(80).has_point(at):
			continue
		var text: String = entry.name
		var px := Palette.BODY if major else Palette.SMALL
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var box := Rect2(at - Vector2(width / 2.0 + 7, px + 3), Vector2(width + 14, px + 9))
		box.position = box.position.round()
		names.draw_style_box(tag, box)
		names.draw_string(font, box.position + Vector2(7, px + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Palette.INK)
