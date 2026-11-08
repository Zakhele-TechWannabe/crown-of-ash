extends Node2D
## CROWN OF ASH — win back a realm from the walking dead. Your villagers live by themselves; you set jobs, rules and
## works, and send the warband out. Args (after --): --play  --night  --fast  --shot=path.png --frames=N  --windowed  --zoom=Z  --look=x,y  --walled

const Realm := preload("res://src/realm.gd")
const Land := preload("res://src/land.gd")
const Sfx := preload("res://src/sfx.gd")
const SAVE := "user://crownofash.json"
const T := Land.T

const C_TEXT := Color(0.95, 0.92, 0.85)
const C_DIM := Color(0.72, 0.7, 0.66)
const C_RED := Color(0.9, 0.25, 0.2)
const C_GOLD := Color(1.0, 0.8, 0.35)
const C_OK := Color(0.55, 0.9, 0.55)
const C_BLUE := Color(0.35, 0.55, 0.95)
const P_BG := Color(0.16, 0.1, 0.06, 0.94)
const P_EDGE := Color(0.76, 0.58, 0.3)
const JOB_COL := {"farm": Color(0.95, 0.85, 0.4), "chop": Color(0.65, 0.85, 0.45), "forage": Color(0.95, 0.65, 0.3),
	"build": Color(0.6, 0.8, 1.0), "guard": Color(0.95, 0.5, 0.45), "soldier": Color(1.0, 0.35, 0.3), "rest": Color(0.75, 0.75, 0.75)}

var c: Realm
var mode := "title"
var best := 0
var speed := 1
var font: Font
var font_px: Font
var font_serif: FontVariation
var ground: Node2D
var ground_sig := 0
var sfx: Sfx
var dark: CanvasModulate
var world: Node2D
var roofs: Node2D
var labels: Node2D
var hearths: Array[PointLight2D] = []
var cam: Camera2D
var hud: CanvasLayer
var hud_draw: Control
var ui: Control
var overlay: Control
var occ := {}
var selected: Variant = null
var place := 0                       # the village whose works the cards show
var decals: Array = []
var corpses: Array = []
var floats: Array = []
var banner := ""
var banner_t := 0.0
var drag := false
var shot_path := ""
var shot_frames := 0
var frame := 0

var speed_btns: Array[Button] = []
var rule_btns := {}
var card_btns := {}
var job_btns := {}
var hold_btns := {}
var people_box: VBoxContainer
var unit_card: PanelContainer
var unit_lbl: Label
var move_btn: Button
var place_lbl: Label
var cards_box: Control
var warband_btn: Button
var order_row: HBoxContainer
var train_row: HBoxContainer
var order_btns := {}
var train_btns := {}
var minimap := Rect2()
var task_rows: Array = []
var task_done: Array = []
var cit_head: Label
var look_zoom := 0.0                 # --zoom= and --look=x,y (cells): for screenshots
var look_at := Vector2.ZERO


func _ready() -> void:
	font = load("res://assets/fonts/Lato-Bold.ttf")
	font_px = load("res://assets/fonts/PixelifySans.ttf")
	font_serif = FontVariation.new()
	font_serif.base_font = load("res://assets/fonts/NotoSerifDisplay-Bold.ttf")
	font_serif.spacing_glyph = 5
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.05))
	_load()
	sfx = Sfx.new()
	add_child(sfx)
	dark = CanvasModulate.new()
	add_child(dark)
	ground = Node2D.new()
	ground.draw.connect(_draw_ground)
	add_child(ground)
	world = Node2D.new()
	world.draw.connect(_draw_world)
	add_child(world)
	roofs = Node2D.new()
	roofs.draw.connect(_draw_roofs)
	add_child(roofs)
	labels = Node2D.new()
	var um := CanvasItemMaterial.new()
	um.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	labels.material = um
	labels.draw.connect(_draw_labels)
	add_child(labels)
	cam = Camera2D.new()
	add_child(cam)
	hud = CanvasLayer.new()
	add_child(hud)
	hud_draw = Control.new()
	hud_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_draw.draw.connect(_draw_hud)
	hud.add_child(hud_draw)
	var start := false
	var night := false
	var pick := -1
	var walled := false
	for a in OS.get_cmdline_user_args():
		if a == "--play":
			start = true
		elif a == "--night":
			start = true
			night = true
		elif a == "--fast":
			speed = 4
		elif a.begins_with("--shot="):
			shot_path = a.get_slice("=", 1)
		elif a.begins_with("--frames="):
			shot_frames = int(a.get_slice("=", 1))
		elif a.begins_with("--select="):
			pick = int(a.get_slice("=", 1))
		elif a == "--walled":
			walled = true
		elif a.begins_with("--zoom="):
			look_zoom = float(a.get_slice("=", 1))
		elif a.begins_with("--look="):
			look_at = Vector2(float(a.get_slice("=", 1).get_slice(",", 0)), float(a.get_slice("=", 1).get_slice(",", 1))) * T
	if not "--windowed" in OS.get_cmdline_user_args() and shot_path == "":
		if DisplayServer.get_screen_count() > 1:
			DisplayServer.window_set_current_screen(1)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	if start:
		new_game()
		if pick >= 0:
			_select(c.people[pick], true)
		if walled:                                          # screenshots: the capital's palisade and towers raised
			for w in c.walls.values():
				if w.h == 0:
					w.up = true
					w.hp = c.wall_max(w)
			c.tower_count[0] = Realm.TOWERS
		if look_zoom > 0.0:
			cam.zoom = Vector2(look_zoom, look_zoom)
		if look_at != Vector2.ZERO:
			cam.position = look_at
		if night:
			c.clock = Realm.DAY_LEN - 3.0
	else:
		show_title()


func _round_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var tx := GradientTexture2D.new()
	tx.gradient = g
	tx.width = 128
	tx.height = 128
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5)
	tx.fill_to = Vector2(1.0, 0.5)
	return tx


func _build_scene() -> void:
	for n in get_children():
		if n is LightOccluder2D or n is PointLight2D:
			n.queue_free()
	occ.clear()
	hearths.clear()
	ground_sig = hash(c.land.tiles)
	ground.queue_redraw()
	for cell in c.land.openings:
		occ[cell] = _occluder(cell.x, cell.x + 1, cell.y)
	for y in Land.H:
		var x := 0
		while x < Land.W:
			if c.land.at(Vector2i(x, y)) != Land.WALL:
				x += 1
				continue
			var x0 := x
			while x < Land.W and c.land.at(Vector2i(x, y)) == Land.WALL:
				x += 1
			_occluder(x0, x, y)
	for h in c.land.holdings.size():
		var l := PointLight2D.new()
		l.texture = _round_texture()
		l.texture_scale = 5.0
		l.color = Color(1.0, 0.8, 0.5)
		l.shadow_enabled = true
		l.position = c.hall_pos(h)
		add_child(l)
		hearths.append(l)


func _occluder(x0: int, x1: int, y: int) -> LightOccluder2D:
	var oc := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(x0 * T, y * T), Vector2(x1 * T, y * T), Vector2(x1 * T, (y + 1) * T), Vector2(x0 * T, (y + 1) * T)])
	oc.occluder = poly
	add_child(oc)
	return oc


# ---------------------------------------------------------------- flow

func show_title() -> void:
	mode = "title"
	c = Realm.new()
	c.setup(randi() % 9999 + 1)
	_build_scene()
	cam.position = c.hall_pos(0)
	cam.zoom = Vector2(0.5, 0.5)
	_clear_ui()
	_clear()
	overlay = _panel(1000)
	var v: VBoxContainer = overlay.get_meta("box")
	v.add_child(_lbl("CROWN OF ASH", 104, C_GOLD, font_px))
	v.add_child(_lbl("The dead walk in the Empire of Kambara. Only the capital, Ala Kambara, still stands. Your people live by themselves — you set their work, the rules and what gets built, and you send the warband to win back the empire, city by city, to the Black Crypt in the Nyoka peaks.", 25, C_DIM))
	var go := _btn("Raise the banner")
	go.pressed.connect(new_game)
	v.add_child(go)
	v.add_child(_lbl("Click a villager to set their work · click a village to manage it or send the warband\nWASD / arrows / right-drag to look around · wheel to zoom · click the map · Space pauses", 19, C_DIM))
	if best > 0:
		v.add_child(_lbl("Your longest reign: %d days" % best, 24, C_GOLD))


func new_game() -> void:
	_clear()
	c = Realm.new()
	c.setup(randi() % 99999 + 1)
	_build_scene()
	decals.clear(); corpses.clear(); floats.clear()
	selected = null
	place = 0
	mode = "play"
	cam.position = c.hall_pos(0)
	cam.zoom = Vector2(0.62, 0.62)
	_build_ui()
	_banner("DAY 1 — Ala Kambara stands alone")


func _game_over() -> void:
	mode = "over"
	best = maxi(best, c.day)
	_save()
	_clear_ui()
	_clear()
	overlay = _panel(820)
	var v: VBoxContainer = overlay.get_meta("box")
	var won := c.phase == Realm.WON
	v.add_child(_lbl("THE REALM IS YOURS" if won else "THE LAST FIRE GOES OUT", 60, C_GOLD if won else C_RED, font_px))
	v.add_child(_lbl("The crypt broken on day %d, with %d souls." % [c.day, c.people.size()] if won else "Ala Kambara fell on day %d." % c.day, 28, C_TEXT))
	var again := _btn("A new reign")
	again.pressed.connect(new_game)
	v.add_child(again)
	var t := _btn("Title")
	t.pressed.connect(show_title)
	v.add_child(t)


func _banner(t: String) -> void:
	banner = t
	banner_t = 4.0


# ---------------------------------------------------------------- UI

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


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_corner_radius_all(3)
	b.set_border_width_all(2)
	b.border_color = border
	b.set_content_margin_all(8)
	return b


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


func _panel(w: float) -> Control:
	var o := Control.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(o)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(cc)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(w, 0)
	v.add_theme_constant_override("separation", 16)
	cc.add_child(v)
	o.set_meta("box", v)
	return o


func _clear() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null


func _clear_ui() -> void:
	if ui:
		ui.queue_free()
		ui = null


func _build_ui() -> void:
	_clear_ui()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ui)
	var sp := HBoxContainer.new()
	sp.position = Vector2(600, 5)
	sp.add_theme_constant_override("separation", 5)
	ui.add_child(sp)
	speed_btns.clear()
	for k in [0, 1, 2, 4]:
		var b := _btn("II" if k == 0 else "%d×" % k, 16)
		b.custom_minimum_size = Vector2(46, 34)
		b.pressed.connect(func(): speed = k; _refresh_ui())
		sp.add_child(b)
		speed_btns.append(b)
	# left: the rules, the tasks, the citizens
	var left := VBoxContainer.new()
	left.position = Vector2(10, 56)
	left.add_theme_constant_override("separation", 8)
	ui.add_child(left)
	var rv := _section(left, "RULES — THE EMPIRE")
	rule_btns.clear()
	for key in ["hearths", "rations", "close_gate"]:
		var b := _btn("", 14)
		b.custom_minimum_size = Vector2(262, 28)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_toggle_rule.bind(key))
		rv.add_child(b)
		rule_btns[key] = b
	var tv := _section(left, "TASKS")
	task_rows.clear()
	for k in 6:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		tv.add_child(row)
		var chk := Control.new()
		chk.custom_minimum_size = Vector2(16, 20)
		chk.draw.connect(_draw_check.bind(chk, k))
		row.add_child(chk)
		var l := _lbl("", 14, C_TEXT, null, false)
		l.custom_minimum_size = Vector2(238, 20)
		row.add_child(l)
		task_rows.append([chk, l])
	var cv := _section(left, "CITIZENS")
	cit_head = cv.get_child(0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(262, 290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(scroll)
	people_box = VBoxContainer.new()
	people_box.add_theme_constant_override("separation", 3)
	scroll.add_child(people_box)
	# right: the holdings, under the minimap
	var right := VBoxContainer.new()
	right.anchor_left = 1.0; right.anchor_right = 1.0
	right.offset_left = -300; right.offset_right = -14; right.offset_top = 56 + 222
	ui.add_child(right)
	var hv := _section(right, "THE REALM — EMPIRE OF KAMBARA")
	hold_btns.clear()
	for h in c.land.holdings.size():
		var b := _btn("", 14)
		b.custom_minimum_size = Vector2(272, 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_holding_click.bind(h))
		b.draw.connect(_hold_badge.bind(b, h))
		hv.add_child(b)
		hold_btns[h] = b
	hv.add_child(_lbl("Click a city you hold to manage its works; click one the dead hold to send the warband.", 13, C_DIM, null, false))
	# bottom: the selected city's works
	place_lbl = _lbl("", 16, C_GOLD, font_px)
	place_lbl.anchor_left = 0.5; place_lbl.anchor_right = 0.5; place_lbl.anchor_top = 1.0; place_lbl.anchor_bottom = 1.0
	place_lbl.offset_left = -300; place_lbl.offset_right = 300; place_lbl.offset_top = -130; place_lbl.offset_bottom = -106
	ui.add_child(place_lbl)
	var n := Realm.UPGRADES.size()
	var cw := 104 + 6 + 118 * n + 6 * (n - 1) + 16
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _box(P_BG, P_EDGE))
	bar.anchor_left = 0.5; bar.anchor_right = 0.5; bar.anchor_top = 1.0; bar.anchor_bottom = 1.0
	bar.offset_left = -cw / 2.0; bar.offset_right = cw / 2.0; bar.offset_top = -104; bar.offset_bottom = -4
	ui.add_child(bar)
	cards_box = bar
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 6)
	bar.add_child(cards)
	var tag := Control.new()
	tag.custom_minimum_size = Vector2(104, 84)
	tag.draw.connect(func():
		tag.draw_rect(Rect2(Vector2.ZERO, tag.size), Color(0.24, 0.15, 0.08))
		tag.draw_rect(Rect2(Vector2.ZERO, tag.size), P_EDGE, false, 2.0)
		_icon(tag, "hammer", Vector2(26, tag.size.y / 2), 1.3)
		tag.draw_string(font_px, Vector2(44, tag.size.y / 2 + 8), "BUILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_GOLD))
	cards.add_child(tag)
	card_btns.clear()
	for u in Realm.UPGRADES:
		var b := _btn("", 13)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st).duplicate()
			sb.content_margin_top = 40
			sb.content_margin_bottom = 4
			b.add_theme_stylebox_override(st, sb)
		b.custom_minimum_size = Vector2(118, 84)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.tooltip_text = u.info
		b.pressed.connect(_card.bind(u.id))
		b.draw.connect(func(): _icon(b, u.id, Vector2(b.size.x / 2, 22), 1.2))
		cards.add_child(b)
		card_btns[u.id] = b
	warband_btn = _btn("", 20)
	warband_btn.anchor_left = 0.5; warband_btn.anchor_right = 0.5; warband_btn.anchor_top = 1.0; warband_btn.anchor_bottom = 1.0
	warband_btn.offset_left = -330; warband_btn.offset_right = 330; warband_btn.offset_top = -94; warband_btn.offset_bottom = -20
	warband_btn.pressed.connect(_send_warband)
	ui.add_child(warband_btn)
	# the villager card
	unit_card = PanelContainer.new()
	unit_card.add_theme_stylebox_override("panel", _box(P_BG, P_EDGE))
	unit_card.anchor_left = 1.0; unit_card.anchor_right = 1.0; unit_card.anchor_top = 1.0; unit_card.anchor_bottom = 1.0
	unit_card.offset_left = -726; unit_card.offset_right = -314; unit_card.offset_top = -330; unit_card.offset_bottom = -140
	unit_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui.add_child(unit_card)
	var uv := VBoxContainer.new()
	uv.add_theme_constant_override("separation", 5)
	unit_card.add_child(uv)
	unit_lbl = _lbl("", 16, C_TEXT, null, false)
	unit_lbl.custom_minimum_size = Vector2(390, 0)
	uv.add_child(unit_lbl)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	uv.add_child(grid)
	job_btns.clear()
	for j in Realm.JOBS:
		var b := _btn(j.capitalize(), 15)
		b.custom_minimum_size = Vector2(92, 32)
		b.tooltip_text = Realm.JOB_INFO[j]
		b.pressed.connect(_set_job.bind(j))
		grid.add_child(b)
		job_btns[j] = b
	order_row = HBoxContainer.new()
	order_row.add_theme_constant_override("separation", 5)
	uv.add_child(order_row)
	order_btns.clear()
	for o in Realm.ORDERS:
		var b := _btn({"escort": "Escort foragers", "fields": "Guard fields", "warband": "Warband"}[o], 14)
		b.custom_minimum_size = Vector2(124, 32)
		b.tooltip_text = Realm.ORDERS[o]
		b.pressed.connect(_set_order.bind(o))
		order_row.add_child(b)
		order_btns[o] = b
	train_row = HBoxContainer.new()
	train_row.add_theme_constant_override("separation", 5)
	uv.add_child(train_row)
	train_btns.clear()
	for u in Realm.UNITS:
		if u == "militia":
			continue
		var ud: Dictionary = Realm.UNITS[u]
		var b := _btn("", 13)
		b.custom_minimum_size = Vector2(124, 44)
		b.tooltip_text = ud.info
		b.pressed.connect(_train.bind(u))
		train_row.add_child(b)
		train_btns[u] = b
	move_btn = _btn("", 15)
	move_btn.pressed.connect(_move_selected)
	uv.add_child(move_btn)
	_refresh_ui()


## A framed panel with a gold title, like the rest of the empire's ledgers.
func _section(parent: Control, title: String) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := _box(P_BG, P_EDGE)
	sb.set_content_margin_all(6)
	pc.add_theme_stylebox_override("panel", sb)
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var head := _lbl(title, 15, C_GOLD, font_px, false)
	head.custom_minimum_size.y = 20
	v.add_child(head)
	var line := ColorRect.new()
	line.color = Color(P_EDGE, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	return v


## What the empire is working toward, ticked off as it gets there.
func _tasks() -> Array:
	var st := c.stakes(0)
	var band := c.people.filter(func(s): return s.job == "soldier" and s.order == "warband").size()
	var cities := c.holdings_owned().size() - 1
	var total := c.land.holdings.size() - 2
	return [
		["Keep food in store: %d/60" % mini(int(c.stock.food), 60), c.stock.food >= 60.0],
		["Raise the palisade: %d/%d" % [st.x, st.y], st.y > 0 and st.x >= st.y],
		["Build the towers: %d/%d" % [c.tower_count[0], Realm.TOWERS], c.tower_count[0] >= Realm.TOWERS],
		["Raise a warband: %d/%d soldiers" % [mini(band, Realm.WARBAND_MIN), Realm.WARBAND_MIN], band >= Realm.WARBAND_MIN],
		["Win back the cities: %d/%d" % [cities, total], cities >= total],
		["Break the Black Crypt", c.phase == Realm.WON],
	]


func _draw_check(chk: Control, k: int) -> void:
	var done: bool = task_done.size() > k and task_done[k]
	var r := Rect2(1, 3, 14, 14)
	chk.draw_rect(r, Color(0.08, 0.05, 0.03))
	chk.draw_rect(r, P_EDGE, false, 1.5)
	if done:
		chk.draw_rect(r.grow(-3), Color(0.45, 0.8, 0.35))


func _hold_badge(b: Button, h: int) -> void:
	var hd: Dictionary = c.land.holdings[h]
	_icon(b, "crown" if h == 0 else ("crypt" if hd.crypt else ("ours" if hd.claimed else "dead")), Vector2(16, b.size.y / 2), 0.7)


func _toggle_rule(key: String) -> void:
	match key:
		"hearths":
			c.rules.hearths = not c.rules.hearths
		"rations":
			c.rules.rations = "half" if c.rules.rations == "normal" else "normal"
		"close_gate":
			c.rules.close_gate = not c.rules.close_gate
	_refresh_ui()


## Clicking a village picks it: works if it's yours, the warband order if the dead hold it.
func _holding_click(h: int) -> void:
	place = h
	cam.position = c.hall_pos(h)
	_refresh_ui()


func _send_warband() -> void:
	var r := c.send_warband(place)
	if r != "":
		floats.append([c.hall_pos(place), r, 2.0, C_DIM])
	_refresh_ui()


func _set_order(o: String) -> void:
	if selected != null:
		c.set_order(selected, o)
		_refresh_ui()


func _train(u: String) -> void:
	if selected == null:
		return
	var r := c.train(selected, u)
	if r != "":
		floats.append([selected.p, r, 2.0, C_DIM])
	_refresh_ui()


func _card(id: String) -> void:
	var r := c.queue_upgrade(place, id)
	if r != "":
		floats.append([cam.position, r, 1.5, C_DIM])
	_refresh_ui()


func _set_job(j: String) -> void:
	if selected != null:
		selected.job = j
		selected.house = -1
		selected.spot = Vector2i(-1, -1)
		_refresh_ui()


func _move_selected() -> void:
	if selected == null:
		return
	var owned := c.holdings_owned()
	if owned.size() < 2:
		return
	var i := owned.find(selected.home)
	c.move_home(selected, owned[(i + 1) % owned.size()])
	_refresh_ui()


func _refresh_ui() -> void:
	if ui == null:
		return
	for i in speed_btns.size():
		speed_btns[i].add_theme_color_override("font_color", C_GOLD if speed == [0, 1, 2, 4][i] else C_TEXT)
	rule_btns.hearths.text = "Hearths at night: " + ("LIT (seen through windows)" if c.rules.hearths else "out")
	rule_btns.rations.text = "Rations: " + ("HALF (food lasts longer)" if c.rules.rations == "half" else "full")
	rule_btns.close_gate.text = "Shut the gate behind you: " + ("yes" if c.rules.close_gate else "no")
	for h in hold_btns:
		var hd: Dictionary = c.land.holdings[h]
		var b: Button = hold_btns[h]
		var txt: String = hd.name
		if hd.claimed:
			txt += "  — yours (%d)" % c.people.filter(func(s): return s.home == h).size()
		elif hd.crypt:
			txt += "  — altar %d%%" % int(100.0 * maxf(0.0, c.altar_hp) / Realm.ALTAR_HP)
		elif c.dead_in(h) == 0:
			txt += "  — empty, no banner"
		else:
			txt += "  — the dead (%d)" % c.dead_in(h)
		if c.target == h:
			txt += "  (marching)"
		b.text = "      " + txt
		b.add_theme_color_override("font_color", C_BLUE.lightened(0.3) if hd.claimed else (C_GOLD if c.target == h else C_RED.lightened(0.2)))
		if h == place:
			b.add_theme_color_override("font_color", Color.WHITE)
	var tasks := _tasks()
	task_done = tasks.map(func(t): return t[1])
	for k in task_rows.size():
		task_rows[k][1].text = tasks[k][0]
		task_rows[k][1].add_theme_color_override("font_color", C_OK if tasks[k][1] else C_TEXT)
		task_rows[k][0].queue_redraw()
	cit_head.text = "CITIZENS (%d)" % c.people.size()
	var ph: Dictionary = c.land.holdings[place]
	cards_box.visible = ph.claimed
	warband_btn.visible = not ph.claimed
	if ph.claimed:
		place_lbl.text = "WORKS OF " + ph.name.to_upper()
	else:
		var band := c.people.filter(func(s): return s.job == "soldier" and s.order == "warband").size()
		place_lbl.text = ph.name.to_upper() + (" — THE CRYPT" if ph.crypt else " — HELD BY THE DEAD (%d)" % c.dead_in(place))
		if c.target == place:
			warband_btn.text = "The warband is marching here — call it back"
		elif band < Realm.WARBAND_MIN:
			warband_btn.text = "A warband needs %d soldiers — %d have the Warband order" % [Realm.WARBAND_MIN, band]
		else:
			warband_btn.text = "Send the warband here (%d soldier%s)" % [band, "" if band == 1 else "s"]
	for u in Realm.UPGRADES:
		var b: Button = card_btns[u.id]
		var cost := " ".join(u.cost.keys().map(func(k): return "%d %s" % [u.cost[k], k]))
		var status := cost
		if u.id == "palisade":
			var st := c.stakes(place)
			status = "%d/%d stakes" % [st.x, st.y]
		elif u.id == "towers" and not c.has_built(place, u.id):
			status = "%d/%d · %s" % [c.tower_count[place], Realm.TOWERS, cost]
		if c.has_built(place, u.id):
			status = "BUILT"
		elif c.progress[place].has(u.id):
			status = "building %d%%" % int(100.0 * c.progress[place][u.id] / u.work)
		elif u.id in c.queue[place]:
			status = "queued #%d · %s" % [c.queue[place].find(u.id) + 1, status]
		b.text = "%s\n%s" % [u.name, status]
		b.add_theme_color_override("font_color", C_OK if c.has_built(place, u.id) else (C_GOLD if u.id in c.queue[place] else C_TEXT))
	for n in people_box.get_children():
		n.queue_free()
	for s in c.people:
		var role: String = s.job if s.job != "soldier" else Realm.UNITS[s.unit].name.to_lower() + " (" + s.order + ")"
		var b := _btn("    %s — %s%s" % [s.name, role, "  (resting)" if s.resting else ""], 14)
		b.tooltip_text = "Lives at " + c.land.holdings[s.home].name
		b.draw.connect(_hp_strip.bind(b, s))
		b.custom_minimum_size = Vector2(250, 28)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", JOB_COL[s.job] if s != selected else Color.WHITE)
		b.pressed.connect(func(): _select(s, true))
		people_box.add_child(b)
	unit_card.visible = selected != null
	if selected != null:
		var soldier: bool = selected.job == "soldier"
		order_row.visible = soldier
		train_row.visible = soldier
		for o in order_btns:
			order_btns[o].add_theme_color_override("font_color", C_GOLD if selected.order == o else C_TEXT)
		var barracks := c.has_built(selected.home, "barracks")
		for u in train_btns:
			var ud: Dictionary = Realm.UNITS[u]
			var cost := " ".join(ud.cost.keys().map(func(k): return "%d %s" % [ud.cost[k], k]))
			var b: Button = train_btns[u]
			b.text = "Train %s\n%s" % [ud.name, "current" if selected.unit == u else ("training…" if selected.train == u else (cost if barracks else "needs barracks"))]
			b.disabled = not barracks or selected.unit == u or selected.train != ""
		move_btn.text = "Lives at %s — move" % c.land.holdings[selected.home].name if c.holdings_owned().size() > 1 else "Lives at %s" % c.land.holdings[selected.home].name
		move_btn.disabled = c.holdings_owned().size() < 2


## A health bar along the bottom of each name in the people list.
func _hp_strip(b: Button, s: Dictionary) -> void:
	var f := clampf(s.hp / 100.0, 0.0, 1.0)
	b.draw_circle(Vector2(15, b.size.y / 2 - 1), 5, JOB_COL[s.job])
	b.draw_arc(Vector2(15, b.size.y / 2 - 1), 5, 0, TAU, 12, Color(0.08, 0.05, 0.03), 1.5)
	b.draw_rect(Rect2(4, b.size.y - 5, (b.size.x - 8) * f, 3), Color(0.9, 0.25, 0.2).lerp(Color(0.45, 0.85, 0.35), f))


func _select(s: Variant, center := false) -> void:
	selected = s
	if s != null and center:
		cam.position = s.p
	_refresh_ui()


# ---------------------------------------------------------------- input

func _unhandled_input(e: InputEvent) -> void:
	if mode != "play":
		return
	if e is InputEventMouseButton:
		if e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x * 1.1, _min_zoom(), 2.0)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom = Vector2.ONE * clampf(cam.zoom.x / 1.1, _min_zoom(), 2.0)
		elif e.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			drag = e.pressed
		elif e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var m := get_viewport().get_mouse_position()
			if minimap.has_point(m):
				cam.position = (m - minimap.position) / minimap.size * Vector2(Land.W, Land.H) * T
			else:
				_click(get_global_mouse_position())
	elif e is InputEventMouseMotion and drag:
		cam.position -= e.relative / cam.zoom
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_SPACE:
				speed = 1 if speed == 0 else 0
				_refresh_ui()
			KEY_1:
				speed = 1
				_refresh_ui()
			KEY_2:
				speed = 2
				_refresh_ui()
			KEY_3:
				speed = 4
				_refresh_ui()
			KEY_ESCAPE:
				if selected != null:
					_select(null)
				else:
					show_title()


## Zoomed right out, the whole empire fills the screen and no further.
func _min_zoom() -> float:
	var vs := get_viewport_rect().size
	return maxf(vs.x / (Land.W * T), vs.y / (Land.H * T))


func _click(at: Vector2) -> void:
	for s in c.people:
		if s.p.distance_to(at) < 18.0:
			_select(s)
			sfx.play("click", -6.0)
			return
	var hi := c.house_of(at)
	if hi >= 0:
		var hol: int = c.land.houses[hi].holding
		if c.land.houses[hi].hall:
			_holding_click(hol)
			return
		if c.marked.has(hi):
			c.marked.erase(hi)
		else:
			c.marked[hi] = true
			floats.append([at, "foragers will search here first", 2.0, C_GOLD])
		sfx.play("click", -6.0)
		return
	_select(null)


# ---------------------------------------------------------------- loop

func _physics_process(dt: float) -> void:
	frame += 1
	if mode in ["play", "title"]:
		var steps := 1 if mode == "title" else speed
		for i in steps:
			var was := c.phase
			c.step(dt)
			_events()
			if mode == "play" and c.phase in [Realm.LOST, Realm.WON] and was != c.phase:
				get_tree().create_timer(2.5).timeout.connect(_game_over)
				break
		if mode == "play" and frame % 15 == 0:
			_refresh_ui()
		if selected != null and not c.people.has(selected):
			_select(null)
	_update_view(dt)
	if shot_path != "" and frame == shot_frames:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_path)
		get_tree().quit()


func _events() -> void:
	var quiet := mode != "play"
	for e in c.events:
		var p: Vector2 = e.p
		var near := clampf(1.0 - p.distance_to(cam.position) / (900.0 / cam.zoom.x), 0.0, 1.0)
		var vol := lerpf(-28.0, -4.0, near)
		match e.k:
			"hit":
				if not quiet: sfx.play("hit", vol)
				decals.append([p, randf() * TAU, randf_range(5, 10)])
			"kill":
				if not quiet: sfx.play("kill", vol)
				corpses.append([p, randf() * TAU])
			"arrow":
				if not quiet: sfx.play("swing", vol, 1.9)
			"chop":
				if not quiet and near > 0.2: sfx.play("board", vol - 4.0, 0.8)
			"door":
				if not quiet and near > 0.3: sfx.play("board", vol - 8.0, 1.6)
			"bang":
				if not quiet: sfx.play("bang", vol)
			"break":
				if not quiet: sfx.play("crack", vol)
				floats.append([p, "broken!", 1.5, C_RED])
			"loot":
				floats.append([p, e.text, 2.0, C_GOLD])
			"noticed":
				if not quiet: sfx.groan(vol)
			"hurt":
				if not quiet: sfx.play("hurt", vol)
			"died":
				if not quiet: sfx.play("die", -4.0)
			"joined":
				if not quiet: sfx.play("heal", -6.0)
			"built":
				if not quiet: sfx.play("board", -6.0)
				floats.append([p, "built!", 2.0, C_OK])
			"claimed":
				if not quiet: sfx.play("dawn", -2.0)
				_banner("A VILLAGE WON BACK")
				floats.append([p, "OURS AGAIN!", 3.0, C_GOLD])
			"night":
				if not quiet: sfx.play("night", -4.0)
				_banner("NIGHT %d — the dead rise from the graveyards" % c.day)
			"dawn":
				if not quiet: sfx.play("dawn", -6.0)
				_banner("DAY %d" % c.day)
				corpses.clear()


func _update_view(dt: float) -> void:
	if c == null:
		return
	var n := c.night_ratio()
	dark.color = Color(1.0, 0.97, 0.9).lerp(Color(0.22, 0.24, 0.36), n)
	for h in hearths.size():
		hearths[h].energy = 1.1 * n if c.rules.hearths and c.land.holdings[h].claimed else 0.0
	for cell in occ:
		occ[cell].visible = not c.clear_at(cell)
	if mode == "play":
		var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
		var lft := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		var up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		cam.position += Vector2(float(right) - float(lft), float(down) - float(up)) * 800.0 * dt / cam.zoom.x
	var size := Vector2(Land.W, Land.H) * T
	var half := get_viewport_rect().size / cam.zoom / 2.0
	cam.position = cam.position.clamp(half.min(size / 2.0), (size - half).max(size / 2.0))
	banner_t = maxf(0.0, banner_t - dt)
	for f in floats:
		f[2] -= dt
		f[0].y -= 25.0 * dt
	floats = floats.filter(func(f): return f[2] > 0.0)
	if decals.size() > 400:
		decals = decals.slice(decals.size() - 400)
	if unit_card and selected != null:
		var s: Dictionary = selected
		var carry := ", ".join(s.carry.keys().map(func(k): return "%d %s" % [s.carry[k], k]))
		var kind := ("%s · %s\n" % [Realm.UNITS[s.unit].name, Realm.ORDERS[s.order]]) if s.job == "soldier" else ""
		unit_lbl.text = "%s  (%s — %s)\n%s%s\nHealth %d   Food %d   Strength %d%s" % [s.name, s.trait, Realm.TRAITS[s.trait], kind,
			{"fight": "fighting!", "flee": "running for the hall!", "": "—"}.get(s.doing, s.doing), int(s.hp), int(s.hunger), int(s.energy), ("\nCarrying " + carry) if carry != "" else ""]
		for j in job_btns:
			job_btns[j].add_theme_color_override("font_color", C_GOLD if s.job == j else C_TEXT)
	if frame % 30 == 0:
		var sig := hash(c.land.tiles)
		if sig != ground_sig:
			ground_sig = sig
			ground.queue_redraw()
	world.queue_redraw()
	roofs.queue_redraw()
	labels.queue_redraw()
	hud_draw.queue_redraw()


# ---------------------------------------------------------------- drawing the land

func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float(h % 1000) / 1000.0


func _view_cells() -> Rect2i:
	var vs := get_viewport_rect().size / cam.zoom
	var cc := cam.get_screen_center_position()
	var a := c.land.cell(cc - vs / 2.0) - Vector2i(1, 1)
	var b := c.land.cell(cc + vs / 2.0) + Vector2i(2, 2)
	return Rect2i(a, b - a)


func _draw_world() -> void:
	if c == null:
		return
	var r := _view_cells()
	var px := Rect2(Vector2(r.position) * T, Vector2(r.size) * T)
	var tsec := Time.get_ticks_msec() * 0.001
	# white water at the falls, and the doors and windows (they open, shut and get boarded)
	for cell in c.land.falls:
		if r.has_point(cell):
			for k in 3:
				var x := cell.x * T + 5 + k * 10 + sin(tsec * 2.0 + cell.y + k) * 2.0
				world.draw_line(Vector2(x, cell.y * T + 2), Vector2(x, cell.y * T + T - 2), Color(0.92, 0.97, 1.0, 0.85), 3.0)
	for cell in c.land.openings:
		if r.has_point(cell):
			_opening(cell)
	# ships off the port, riding at anchor
	for k in 3:
		var sp := Vector2([100, 99, 102][k], [30, 38, 45][k]) * T + Vector2(sin(tsec * 0.2 + k * 2.0) * 24.0, 0)
		if not px.has_point(sp) or c.land.at(c.land.cell(sp)) != Land.WATER:
			continue
		sp.y += sin(tsec * 1.5 + k) * 2.0
		world.draw_colored_polygon(PackedVector2Array([sp + Vector2(-20, 4), sp + Vector2(24, 4), sp + Vector2(16, 14), sp + Vector2(-16, 14)]), Color(0.42, 0.26, 0.13))
		world.draw_line(sp + Vector2(2, 6), sp + Vector2(2, -26), Color(0.3, 0.2, 0.1), 2.0)
		world.draw_colored_polygon(PackedVector2Array([sp + Vector2(4, -24), sp + Vector2(20, 2), sp + Vector2(4, 2)]), Color(0.96, 0.93, 0.85))
		world.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -20), sp + Vector2(-14, 2), sp + Vector2(0, 2)]), Color(0.88, 0.84, 0.75))
	for h in c.holdings_owned():
		for b in c.beds[h]:
			world.draw_rect(Rect2(b - Vector2(12, 8), Vector2(24, 16)), Color(0.75, 0.65, 0.35) if c.has_built(h, "beds") else Color(0.45, 0.38, 0.28))
		for u in Realm.UPGRADES:
			if not u.id in Realm.HALL_WORKS:
				continue
			var at: Vector2 = c.slots[h][u.id]
			if c.has_built(h, u.id):
				_work_icon(u.id, at)
			elif u.id in c.queue[h]:
				var frac: float = c.progress[h].get(u.id, 0.0) / u.work
				world.draw_rect(Rect2(at - Vector2(13, 13), Vector2(26, 26)), Color(1, 0.9, 0.6, 0.35), false, 2.0)
				if frac > 0.0:
					world.draw_rect(Rect2(at + Vector2(-13, 15), Vector2(26 * frac, 4)), C_GOLD)
	_draw_walls(r)
	# the crypt's altar
	var ch := c.land.holdings.size() - 1
	var ap := c.hall_pos(ch)
	if c.altar_hp > 0.0:
		world.draw_rect(Rect2(ap - Vector2(16, 10), Vector2(32, 20)), Color(0.2, 0.15, 0.25))
		world.draw_circle(ap, 7, Color(0.6, 0.3, 0.9))
	for d in decals:
		world.draw_set_transform(d[0], d[1], Vector2(1.4, 0.8))
		world.draw_circle(Vector2.ZERO, d[2], Color(0.3, 0.06, 0.05, 0.7))
	world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for cp in corpses:
		world.draw_set_transform(cp[0], cp[1], Vector2.ONE)
		world.draw_rect(Rect2(-14, -7, 26, 14), Color(0.35, 0.36, 0.32))
		world.draw_circle(Vector2(14, 0), 6, Color(0.6, 0.62, 0.55))
	world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for cr in c.land.crates:
		var p := c.land.center(cr.cell)
		var col := Color(0.5, 0.36, 0.2) if not cr.searched else Color(0.3, 0.24, 0.18)
		world.draw_circle(p, 9, col)
		world.draw_arc(p, 9, 0, TAU, 12, col.darkened(0.4), 2.0)
	for z in c.dead:
		_dead(z)
	for s in c.people:
		_person(s)
	for sh in c.shots:
		world.draw_line(sh[0], sh[1], Color(0.9, 0.85, 0.7, 0.8), 1.5)


## The land itself, drawn once and kept: it only changes when a forest is cleared or a field is dug, so it's redrawn
## when the tiles change.
func _draw_ground() -> void:
	if c == null:
		return
	ground.draw_rect(Rect2(0, 0, Land.W * T, Land.H * T), Color(0.38, 0.6, 0.21))
	for y in Land.H:
		for x in Land.W:
			_tile(Vector2i(x, y))
	for y in Land.H:
		for x in Land.W:
			var cell := Vector2i(x, y)
			var t := c.land.at(cell)
			var h := _hash(x, y)
			if t == Land.FOREST:
				_tree(cell, 1.0)
			elif t == Land.GRASS and h > 0.955 and h < 0.975 and not c.land.in_ring(0, cell, -2):
				_tree(cell, 0.75)                          # a lone tree out in the fields
	# the provinces of Kambara, written across the land
	for pv in Land.PROVINCES:
		var words: PackedStringArray = pv[0].split(" ")
		var lines := [pv[0]]
		if words.size() > 1 and words[-1] in ["PROVINCE", "MOUNTAINS", "PLATEAU", "COAST"]:
			lines = [" ".join(words.slice(0, words.size() - 1)), words[-1]]
		var wet: bool = "RIVER" in pv[0] or "COAST" in pv[0]
		for i in lines.size():
			var at := Vector2(pv[1]) * T + Vector2(0, i * 60)
			ground.draw_string(font_serif, at + Vector2(3, 3), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(0.1, 0.08, 0.04, 0.45))
			ground.draw_string(font_serif, at, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(0.85, 0.95, 1.0, 0.9) if wet else Color(1.0, 0.95, 0.78, 0.88))


func _tile(cell: Vector2i) -> void:
	var g := ground
	var land := c.land
	var t := land.at(cell)
	var rect := Rect2(cell.x * T, cell.y * T, T, T)
	var h := _hash(cell.x, cell.y)
	var patch := _hash(cell.x / 4, cell.y / 4)
	match t:
		Land.GRASS, Land.FOREST:
			var col := Color(0.35, 0.56, 0.19).lerp(Color(0.45, 0.66, 0.25), patch * 0.65 + h * 0.35)
			var garden := t == Land.GRASS and land.in_ring(0, cell, 1)
			if t == Land.FOREST:
				col = col.darkened(0.22)
			elif garden:
				col = Color(0.3, 0.54, 0.2).lerp(Color(0.35, 0.6, 0.24), h)       # the capital's gardens
			g.draw_rect(rect, col)
			if garden:
				if h < 0.22:
					g.draw_circle(rect.get_center(), 8, Color(0.18, 0.4, 0.14))
					g.draw_circle(rect.get_center() + Vector2(-2, -2), 4, Color(0.32, 0.6, 0.24))
				elif h < 0.4:
					g.draw_circle(rect.get_center(), 3, Color(0.95, 0.55, 0.6))
			elif t == Land.GRASS:
				if h < 0.04:
					var fc: Color = [Color(0.98, 0.9, 0.4), Color(0.96, 0.96, 0.9), Color(0.92, 0.55, 0.62)][int(h * 75) % 3]
					g.draw_circle(rect.position + Vector2(6 + h * 300, 10), 2.5, fc)
					g.draw_circle(rect.position + Vector2(20, 24 - h * 100), 2.0, fc)
				elif h < 0.14:
					var p := rect.position + Vector2(6 + h * 120, 16 + h * 60)
					g.draw_line(p, p + Vector2(-2, -6), col.darkened(0.25), 1.5)
					g.draw_line(p, p + Vector2(2, -7), col.darkened(0.25), 1.5)
				elif h > 0.985:
					g.draw_circle(rect.get_center() + Vector2(2, 3), 5, Color(0.2, 0.25, 0.15, 0.4))
					g.draw_circle(rect.get_center(), 5, Color(0.62, 0.62, 0.58))
		Land.WATER:
			var deep := 0
			for o in [Vector2i(-3, 0), Vector2i(3, 0), Vector2i(0, -3), Vector2i(0, 3), Vector2i(-2, -2), Vector2i(2, 2), Vector2i(2, -2), Vector2i(-2, 2)]:
				if land.at(cell + o) == Land.WATER:
					deep += 1
			var col := Color(0.32, 0.62, 0.9).lerp(Color(0.13, 0.36, 0.7), deep / 8.0)
			g.draw_rect(rect, col.lerp(col.lightened(0.06), h))
			for o in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var n := land.at(cell + o)
				if n == Land.WATER or n == Land.ROAD or not land._in(cell.x + o.x, cell.y + o.y):
					continue
				var strip := Rect2(rect.position + Vector2(maxf(0, o.x) * (T - 4), maxf(0, o.y) * (T - 4)), Vector2(4 if o.x != 0 else T, 4 if o.y != 0 else T))
				g.draw_rect(strip, Color(0.82, 0.93, 1.0, 0.75))
			if cell in land.falls:
				g.draw_rect(rect, Color(0.7, 0.86, 0.98, 0.5))
			elif h < 0.22:
				var p := rect.position + Vector2(6 + h * 40, 12 + h * 30)
				g.draw_arc(p, 4, PI * 1.1, PI * 1.9, 5, Color(0.85, 0.95, 1.0, 0.5), 1.5)
				g.draw_arc(p + Vector2(8, 0), 4, PI * 1.1, PI * 1.9, 5, Color(0.85, 0.95, 1.0, 0.5), 1.5)
		Land.ROCK:
			g.draw_rect(rect, Color(0.5, 0.52, 0.42).lerp(Color(0.56, 0.57, 0.48), h))
			var tall := 10.0 + h * 12.0
			var top := rect.position + Vector2(T * 0.5 + (h - 0.5) * 10, -tall + 6)
			var l := rect.position + Vector2(-5, T)
			var r := rect.position + Vector2(T + 5, T)
			var mid := rect.position + Vector2(T * 0.5 + (h - 0.5) * 6, T)
			g.draw_colored_polygon(PackedVector2Array([l, top, mid]), Color(0.74, 0.73, 0.7))
			g.draw_colored_polygon(PackedVector2Array([mid, top, r]), Color(0.47, 0.46, 0.45))
			g.draw_polyline(PackedVector2Array([l, top, r]), Color(0.3, 0.29, 0.28), 1.5)
			if cell.y < 7 or (cell.x > 62 and cell.y < 5):
				g.draw_colored_polygon(PackedVector2Array([top, top + Vector2(-7, 10), top + Vector2(-1, 7), top + Vector2(6, 10)]), Color(0.96, 0.97, 1.0))
		Land.SAND:
			g.draw_rect(rect, Color(0.94, 0.84, 0.57).lerp(Color(0.9, 0.79, 0.5), h))
			if h < 0.3:
				g.draw_circle(rect.position + Vector2(8 + h * 50, 20), 1.5, Color(0.75, 0.65, 0.42))
		Land.ROAD:
			var water_ns := land.at(cell + Vector2i(0, 1)) == Land.WATER or land.at(cell - Vector2i(0, 1)) == Land.WATER
			var water_ew := land.at(cell + Vector2i(1, 0)) == Land.WATER or land.at(cell - Vector2i(1, 0)) == Land.WATER
			if water_ns or water_ew:
				# timber over the water: a bridge or a pier, planks across and a rail on each open side
				var wood := Color(0.55, 0.38, 0.22)
				g.draw_rect(rect, wood)
				for k in 4:
					if water_ns:
						g.draw_line(rect.position + Vector2(4 + k * 8, 0), rect.position + Vector2(4 + k * 8, T), wood.darkened(0.3), 1.5)
					else:
						g.draw_line(rect.position + Vector2(0, 4 + k * 8), rect.position + Vector2(T, 4 + k * 8), wood.darkened(0.3), 1.5)
				for o in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
					if land.at(cell + o) == Land.WATER:
						var a := rect.get_center() + Vector2(o) * (T / 2 - 2) - Vector2(o).orthogonal() * T / 2
						g.draw_line(a, a + Vector2(o).orthogonal() * T, Color(0.32, 0.2, 0.1), 4.0)
			else:
				g.draw_rect(rect, Color(0.78, 0.64, 0.43).lerp(Color(0.73, 0.59, 0.39), h))
				for o in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
					if land.at(cell + o) in [Land.ROAD, Land.PAVE]:
						continue
					var strip := Rect2(rect.position + Vector2(maxf(0, o.x) * (T - 3), maxf(0, o.y) * (T - 3)), Vector2(3 if o.x != 0 else T, 3 if o.y != 0 else T))
					g.draw_rect(strip, Color(0.6, 0.47, 0.3))
				if h < 0.4:
					g.draw_circle(rect.position + Vector2(8 + h * 40, 10 + h * 25), 1.8, Color(0.6, 0.48, 0.32))
		Land.PAVE:
			var stone := Color(0.76, 0.73, 0.66).lerp(Color(0.71, 0.68, 0.61), h)
			var gr := stone.darkened(0.16)
			g.draw_rect(rect, stone)
			g.draw_line(rect.position + Vector2(0, 16), rect.position + Vector2(T, 16), gr, 1.0)
			g.draw_line(rect.position + Vector2(0, 0.5), rect.position + Vector2(T, 0.5), gr, 1.0)
			var ox := 8.0 if cell.y % 2 == 0 else 24.0
			g.draw_line(rect.position + Vector2(ox, 0), rect.position + Vector2(ox, 16), gr, 1.0)
			g.draw_line(rect.position + Vector2(fmod(ox + 16.0, T), 16), rect.position + Vector2(fmod(ox + 16.0, T), T), gr, 1.0)
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
		Land.GRAVE:
			g.draw_rect(rect, Color(0.3, 0.27, 0.22).lerp(Color(0.34, 0.3, 0.24), h))
			if h < 0.4:
				var p := rect.get_center() + Vector2((h - 0.2) * 30, 2)
				g.draw_rect(Rect2(p - Vector2(4, 6), Vector2(11, 12)), Color(0, 0, 0, 0.3))
				g.draw_rect(Rect2(p - Vector2(6, 8), Vector2(11, 12)), Color(0.58, 0.58, 0.6))
				g.draw_circle(p - Vector2(0.5, 8), 5.5, Color(0.58, 0.58, 0.6))
		Land.FLOOR:
			var wood := Color(0.55, 0.42, 0.28)
			g.draw_rect(rect, wood.lerp(wood.darkened(0.1), h))
			g.draw_line(rect.position + Vector2(0, 16), rect.position + Vector2(T, 16), wood.darkened(0.25), 1.0)
		Land.WALL, Land.WINDOW, Land.DOOR:
			g.draw_rect(rect, Color(0.64, 0.57, 0.46))
			g.draw_rect(rect, Color(0.42, 0.36, 0.28), false, 2.0)


## A door or window: open, shut, broken, and the planks nailed across it.
func _opening(cell: Vector2i) -> void:
	var t := c.land.at(cell)
	var rect := Rect2(cell.x * T, cell.y * T, T, T)
	var o: Dictionary = c.land.openings[cell]
	var horiz := c.land.at(cell + Vector2i(1, 0)) == Land.WALL or c.land.at(cell - Vector2i(1, 0)) == Land.WALL
	var planks := int(o.planks)
	if t == Land.DOOR:
		world.draw_rect(rect, Color(0.42, 0.36, 0.28))
		var leaf := Color(0.5, 0.33, 0.18)
		if float(o.hp) <= 0.0:
			for k in 3:
				world.draw_line(rect.position + Vector2(4 + k * 10, 4), rect.position + Vector2(8 + k * 9, T - 6), leaf.darkened(0.3), 3.0)
		elif o.open:
			if horiz:
				world.draw_rect(Rect2(rect.position + Vector2(0, -T + 4), Vector2(6, T - 2)), leaf)
			else:
				world.draw_rect(Rect2(rect.position + Vector2(-T + 4, 0), Vector2(T - 2, 6)), leaf)
		else:
			world.draw_rect(rect.grow(-2), leaf)
			world.draw_rect(rect.grow(-2), leaf.darkened(0.35), false, 2.0)
	else:
		world.draw_rect(rect, Color(0.3, 0.26, 0.2))
		world.draw_rect(rect.grow(-6), Color(0.85, 0.65, 0.3, 0.5))
	if not (t == Land.DOOR and (o.open or float(o.hp) <= 0.0)):
		for k in planks:
			var off := 6.0 + k * 10.0
			var bc := Color(0.6, 0.45, 0.26).darkened(0.1 * k)
			if horiz:
				world.draw_rect(Rect2(rect.position + Vector2(off - 4, -3), Vector2(7, T + 6)), bc)
			else:
				world.draw_rect(Rect2(rect.position + Vector2(-3, off - 4), Vector2(T + 6, 7)), bc)
	var full: float = c.door_max(o) if t == Land.DOOR else planks * Realm.PLANK_HP
	if full > 0.0 and float(o.hp) < full - 1.0 and float(o.hp) > 0.0:
		world.draw_rect(Rect2(rect.position + Vector2(2, -8), Vector2((T - 4) * float(o.hp) / full, 4)), C_RED)


## The octagon a holding's palisade runs round, through the middle of its wall cells.
func _ring_points(h: int) -> PackedVector2Array:
	var hd: Dictionary = c.land.holdings[h]
	var hx := float(hd.half.x)
	var hy := float(hd.half.y)
	var k := float(c.land.cut(h)) + 0.5
	var o := (Vector2(hd.center) + Vector2(0.5, 0.5)) * T
	var out := PackedVector2Array()
	for p in [Vector2(hx - k, -hy), Vector2(hx, -hy + k), Vector2(hx, hy - k), Vector2(hx - k, hy), Vector2(-hx + k, hy),
			Vector2(-hx, hy - k), Vector2(-hx, -hy + k), Vector2(-hx + k, -hy)]:
		out.append(o + p * T)
	out.append(out[0])
	return out


func _wall_near(p: Vector2, h: int) -> Variant:
	var cc := c.land.cell(p)
	for o in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var w: Variant = c.walls.get(cc + o)
		if w != null and w.h == h:
			return w
	return null


## The palisade: a timber wall round the octagon where it's raised, a faint line where it's planned, gatehouses on
## the roads; and the towers in the cut corners.
func _draw_walls(view: Rect2i) -> void:
	var px := Rect2(Vector2(view.position) * T, Vector2(view.size) * T).grow(T)
	var up := []
	for h in c.rings:
		var mine: bool = c.land.holdings[h].claimed
		var pts := _ring_points(h)
		for e in 8:
			var a := pts[e]
			var b := pts[e + 1]
			var n := maxi(1, int(a.distance_to(b) / (T * 0.5)))
			for k in n:
				var p0 := a.lerp(b, float(k) / n)
				var p1 := a.lerp(b, float(k + 1) / n)
				if not px.has_point(p0):
					continue
				var w: Variant = _wall_near((p0 + p1) / 2.0, h)
				if w == null or w.gate:
					continue
				if not w.up:
					if mine and k % 2 == 0:
						var queued: bool = "palisade" in c.queue[h]
						world.draw_line(p0, p1, Color(1.0, 0.9, 0.6, 0.55 if queued else 0.25), 3.0)
				elif float(w.hp) <= 0.0:
					world.draw_line(p0, p0.lerp(p1, 0.35), Color(0.3, 0.2, 0.12), 6.0)
				else:
					up.append([p0, p1])
	for s in up:
		world.draw_line(s[0] + Vector2(3, 5), s[1] + Vector2(3, 5), Color(0, 0, 0, 0.25), 14.0)
	for s in up:
		world.draw_line(s[0], s[1], Color(0.24, 0.14, 0.07), 15.0)
	for s in up:
		world.draw_line(s[0], s[1], Color(0.56, 0.38, 0.2), 10.0)
		world.draw_line(s[0] - Vector2(0, 2), s[1] - Vector2(0, 2), Color(0.68, 0.5, 0.3), 3.0)
	for s in up:
		world.draw_circle(s[0], 7.0, Color(0.24, 0.14, 0.07))
		world.draw_circle(s[0], 5.5, Color(0.5, 0.33, 0.17))
		world.draw_circle(s[0] - Vector2(1, 1), 2.5, Color(0.72, 0.55, 0.34))
	for cell in c.walls:
		if not view.has_point(cell):
			continue
		var w: Dictionary = c.walls[cell]
		var rect := Rect2(cell.x * T, cell.y * T, T, T)
		if w.gate and w.up and float(w.hp) > 0.0:
			_gatehouse(cell, w)
		elif w.gate and not w.up and c.land.holdings[w.h].claimed:
			world.draw_rect(rect.grow(-4), Color(1.0, 0.9, 0.6, 0.3), false, 2.0)
		if w.up and float(w.hp) > 0.0 and float(w.hp) < c.wall_max(w) - 1.0:
			world.draw_rect(Rect2(rect.position + Vector2(2, -10), Vector2((T - 4) * float(w.hp) / c.wall_max(w), 4)), C_RED)
		if not w.up and float(w.work) > 0.0:
			world.draw_rect(Rect2(rect.position + Vector2(3, T - 7), Vector2((T - 6) * w.work / Realm.STAKE_WORK, 4)), C_GOLD)
	for h in c.towers:
		if not c.land.holdings[h].claimed:
			continue
		for k in c.towers[h].size():
			var at: Vector2 = c.towers[h][k]
			var tr := Rect2(at - Vector2(24, 24), Vector2(48, 48))
			if k < c.tower_count[h]:
				world.draw_rect(Rect2(tr.position + Vector2(6, 8), tr.size), Color(0, 0, 0, 0.3))
				world.draw_rect(tr, Color(0.38, 0.3, 0.2))
				world.draw_rect(tr.grow(-2), Color(0.78, 0.7, 0.54))
				world.draw_rect(tr.grow(-10), Color(0.56, 0.47, 0.34))
				for q in 4:
					for m in 3:
						var off := 4.0 + m * 15.0
						var cp: Vector2 = [Vector2(off, 2), Vector2(off, 40), Vector2(2, off), Vector2(40, off)][q]
						world.draw_rect(Rect2(tr.position + cp, Vector2(6, 6)), Color(0.86, 0.8, 0.66))
				world.draw_line(at, at + Vector2(0, -34), Color(0.3, 0.2, 0.1), 2.5)
				world.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -34), at + Vector2(18, -29 + sin(Time.get_ticks_msec() * 0.004 + k) * 2), at + Vector2(0, -23)]), Color(0.8, 0.16, 0.12))
			else:
				var queued: bool = "towers" in c.queue[h] and k == c.tower_count[h]
				world.draw_rect(tr, Color(0.9, 0.8, 0.55, 0.4 if queued else 0.15), false, 2.0)
				if queued:
					var frac: float = c.progress[h].get("towers", 0.0) / 24.0
					if frac > 0.0:
						world.draw_rect(Rect2(tr.position + Vector2(0, 50), Vector2(48 * frac, 4)), C_GOLD)


## A gate in the palisade: stone posts either side, a red banner, and the leaves open or barred.
func _gatehouse(cell: Vector2i, w: Dictionary) -> void:
	var p := c.land.center(cell)
	var side := Vector2(w["in"]).orthogonal()
	var leaf := Color(0.48, 0.32, 0.16)
	world.draw_rect(Rect2(p - Vector2(T, T) / 2.0, Vector2(T, T)), Color(0.3, 0.2, 0.12))
	if w.open:
		world.draw_line(p - side * 14.0, p - side * 14.0 + Vector2(w["in"]) * 12.0, leaf, 5.0)
		world.draw_line(p + side * 14.0, p + side * 14.0 + Vector2(w["in"]) * 12.0, leaf, 5.0)
	else:
		world.draw_line(p - side * 15.0, p + side * 15.0, leaf, 12.0)
		world.draw_line(p - side * 15.0, p + side * 15.0, Color(0.3, 0.3, 0.32), 2.0)
	for sgn in [-1.0, 1.0]:
		var nb: Vector2i = cell + Vector2i(side * sgn)
		if c.walls.has(nb) and c.walls[nb].gate:
			continue                                        # a wide road: one gatehouse over both cells
		var q: Vector2 = p + side * sgn * 20.0
		world.draw_rect(Rect2(q - Vector2(10, 10) + Vector2(3, 4), Vector2(20, 20)), Color(0, 0, 0, 0.3))
		world.draw_rect(Rect2(q - Vector2(10, 10), Vector2(20, 20)), Color(0.42, 0.36, 0.28))
		world.draw_rect(Rect2(q - Vector2(8, 8), Vector2(16, 16)), Color(0.78, 0.72, 0.6))
		world.draw_line(q, q + Vector2(0, -24), Color(0.3, 0.2, 0.1), 2.0)
		world.draw_colored_polygon(PackedVector2Array([q + Vector2(0, -24), q + Vector2(14, -20), q + Vector2(0, -15)]), Color(0.8, 0.16, 0.12))


func _tree(cell: Vector2i, size: float) -> void:
	var g := ground
	var h := _hash(cell.x, cell.y)
	var h2 := _hash(cell.y + 7, cell.x + 3)
	var p := c.land.center(cell) + Vector2((h - 0.5) * 12, (h2 - 0.5) * 12)
	var r := (13.0 + h * 6.0) * size
	g.draw_circle(p + Vector2(4, 6), r, Color(0.05, 0.12, 0.04, 0.4))
	g.draw_circle(p, r + 1.5, Color(0.07, 0.19, 0.06))
	g.draw_circle(p, r, Color(0.15, 0.38, 0.12).lerp(Color(0.22, 0.47, 0.16), h2))
	g.draw_circle(p + Vector2(-r * 0.25, -r * 0.3), r * 0.6, Color(0.27, 0.55, 0.2))
	g.draw_circle(p + Vector2(-r * 0.4, -r * 0.45), r * 0.22, Color(0.45, 0.7, 0.3, 0.8))


func _work_icon(id: String, at: Vector2) -> void:
	match id:
		"mill":
			world.draw_circle(at, 12, Color(0.6, 0.55, 0.5))
			for k in 4:
				world.draw_line(at, at + Vector2.RIGHT.rotated(k * PI / 2 + 0.4) * 16, Color(0.45, 0.32, 0.2), 3.0)
		"fletcher":
			world.draw_rect(Rect2(at - Vector2(13, 8), Vector2(26, 16)), Color(0.5, 0.36, 0.2))
			world.draw_line(at + Vector2(-9, 4), at + Vector2(9, -4), Color(0.85, 0.85, 0.8), 2.0)
		"chapel":
			world.draw_rect(Rect2(at - Vector2(3, 13), Vector2(6, 26)), Color(0.9, 0.85, 0.6))
			world.draw_rect(Rect2(at - Vector2(10, 6), Vector2(20, 6)), Color(0.9, 0.85, 0.6))
		"tower":
			world.draw_rect(Rect2(at - Vector2(10, 10), Vector2(20, 20)), Color(0.55, 0.5, 0.45))
			world.draw_rect(Rect2(at - Vector2(10, 10), Vector2(20, 20)), Color(0.35, 0.3, 0.28), false, 3.0)
		"barracks":
			world.draw_line(at + Vector2(-10, 10), at + Vector2(10, -10), Color(0.75, 0.75, 0.8), 3.0)
			world.draw_line(at + Vector2(10, 10), at + Vector2(-10, -10), Color(0.75, 0.75, 0.8), 3.0)
		"bell":
			world.draw_colored_polygon(PackedVector2Array([at + Vector2(-9, 8), at + Vector2(9, 8), at + Vector2(6, -8), at + Vector2(-6, -8)]), Color(0.8, 0.65, 0.25))
		"beds":
			pass
		_:
			world.draw_rect(Rect2(at - Vector2(12, 12), Vector2(24, 24)), Color(0.55, 0.42, 0.26))
			world.draw_line(at + Vector2(-10, 0), at + Vector2(10, 0), Color(0.38, 0.28, 0.16), 3.0)


func _dead(z: Dictionary) -> void:
	var col := Color(0.55, 0.6, 0.52)
	var size := 1.0
	match z.kind:
		"runner":
			col = Color(0.65, 0.62, 0.5)
			size = 0.9
		"brute":
			col = Color(0.45, 0.48, 0.42)
			size = 1.5
	if z.stun > 0.0:
		col = col.lightened(0.3)
	var sway := sin(z.step) * 0.25
	world.draw_set_transform(z.p, z.face.angle(), Vector2(size, size))
	world.draw_line(Vector2(4, -7), Vector2(18, -6 + sway * 8), col.darkened(0.2), 4.0)
	world.draw_line(Vector2(4, 7), Vector2(18, 6 - sway * 8), col.darkened(0.2), 4.0)
	world.draw_rect(Rect2(-8, -10, 14, 20), Color(0.28, 0.25, 0.22))
	world.draw_circle(Vector2(2, 0), 8.0, col)
	world.draw_circle(Vector2(6, -3), 1.6, Color(0.6, 0.85, 0.9))
	world.draw_circle(Vector2(6, 3), 1.6, Color(0.6, 0.85, 0.9))
	world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _person(s: Dictionary) -> void:
	var col: Color = s.color
	if s.hurt_t > 0.0 and fmod(s.hurt_t, 0.1) < 0.05:
		col = Color(1, 0.4, 0.4)
	if s.asleep:
		world.draw_set_transform(s.p, 0.0, Vector2.ONE)
		world.draw_rect(Rect2(-12, -6, 22, 12), col.darkened(0.3))
		world.draw_circle(Vector2(-12, 0), 6, Color(0.86, 0.7, 0.55))
		world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	world.draw_set_transform(s.p, s.face.angle(), Vector2.ONE * (0.85 if s.sneak else 1.0))
	world.draw_rect(Rect2(-9, -11, 16, 22), col.darkened(0.25))
	match s.job:
		"soldier":
			match s.unit:
				"archer":
					world.draw_arc(Vector2(10, 0), 11, -1.3, 1.3, 10, Color(0.55, 0.4, 0.22), 3.0)
					world.draw_line(Vector2(-6, -8), Vector2(-12, 6), Color(0.85, 0.8, 0.7), 2.0)
				"spearman":
					world.draw_line(Vector2(-4, 6), Vector2(38, 6), Color(0.6, 0.45, 0.3), 3.0)
					world.draw_colored_polygon(PackedVector2Array([Vector2(38, 2), Vector2(46, 6), Vector2(38, 10)]), Color(0.85, 0.85, 0.9))
				"man_at_arms":
					world.draw_rect(Rect2(-10, -12, 18, 24), Color(0.6, 0.62, 0.66))
					world.draw_line(Vector2(4, 7), Vector2(24, 7), Color(0.85, 0.85, 0.9), 4.0)
					world.draw_rect(Rect2(2, -14, 6, 12), Color(0.7, 0.2, 0.2))
				_:
					world.draw_line(Vector2(0, 6), Vector2(26, 6), Color(0.6, 0.45, 0.3), 3.0)
					world.draw_colored_polygon(PackedVector2Array([Vector2(26, 3), Vector2(32, 6), Vector2(26, 9)]), Color(0.8, 0.8, 0.85))
					world.draw_rect(Rect2(-2, -14, 8, 10), Color(0.7, 0.2, 0.2))
		"guard":
			world.draw_arc(Vector2(10, 0), 10, -1.2, 1.2, 10, Color(0.55, 0.4, 0.22), 2.5)
		"chop":
			world.draw_line(Vector2(6, 4), Vector2(18, 4), Color(0.5, 0.36, 0.2), 3.0)
			world.draw_rect(Rect2(16, 0, 5, 8), Color(0.75, 0.75, 0.8))
		"farm":
			world.draw_line(Vector2(4, 4), Vector2(20, 8), Color(0.6, 0.45, 0.25), 2.5)
	world.draw_circle(Vector2.ZERO, 7.5, Color(0.86, 0.7, 0.55))
	world.draw_arc(Vector2.ZERO, 7.5, PI * 0.5, PI * 1.5, 12, col.darkened(0.5), 4.0)
	if s.job == "soldier" and s.unit == "man_at_arms":
		world.draw_circle(Vector2.ZERO, 7.5, Color(0.62, 0.64, 0.68))
	if not s.carry.is_empty():
		world.draw_rect(Rect2(-14, -6, 7, 12), Color(0.55, 0.45, 0.3))
	world.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if s == selected:
		world.draw_arc(s.p, 17, 0, TAU, 24, Color.WHITE, 2.0)


## Roofs: golden thatch on cottages, slate on city halls, the palace's red wings and golden dome. Roofs left to
## the dead are grey and holed. They fade when you zoom in close, and while one of your people is inside.
func _draw_roofs() -> void:
	if c == null:
		return
	var fade := clampf((cam.zoom.x - 1.0) / 0.4, 0.0, 1.0)
	var inside := {}
	for s in c.people:
		inside[c.house_of(s.p)] = true
	var doors := {}
	for oc in c.land.openings:
		if c.land.openings[oc].kind == "door":
			doors[c.land.openings[oc].house] = oc
	for i in c.land.houses.size():
		var hs: Dictionary = c.land.houses[i]
		var hol: Dictionary = c.land.holdings[hs.holding]
		var a := 1.0 - 0.8 * fade
		if inside.has(i) and not hs.hall:
			a = minf(a, 0.22)                           # a cottage being searched; halls keep their roofs
		var r: Rect2i = hs.rect
		var rr := Rect2(r.position.x * T - 3, r.position.y * T - 3, r.size.x * T + 6, r.size.y * T + 6)
		if hol.crypt:
			_roof(rr, Color(0.24, 0.19, 0.3), a, false, i)
			roofs.draw_circle(rr.get_center(), 10, Color(0.65, 0.35, 0.95, 0.8 * a))
		elif hs.hall and hs.holding == 0:
			_palace(rr, a)
		elif hs.hall:
			_roof(rr, Color(0.45, 0.48, 0.58) if hol.claimed else Color(0.4, 0.4, 0.42), a, not hol.claimed, i)
		else:
			_roof(rr, Color(0.88, 0.66, 0.32) if hol.claimed else Color(0.58, 0.5, 0.36), a, not hol.claimed, i)
		if a < 0.5:
			continue
		if doors.has(i):
			var oc: Vector2i = doors[i]
			var dr := Rect2(oc.x * T, oc.y * T, T, T).grow(-5)
			roofs.draw_rect(dr, _ca(Color(0.42, 0.26, 0.12) if not c.land.openings[oc].open else Color(0.1, 0.08, 0.07), a))
			roofs.draw_rect(dr, _ca(Color(0.25, 0.15, 0.07), a), false, 2.0)


func _ca(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * a)


## A hipped roof along its long side, lit from the top: thatch rings, a ridge, a chimney; holes if the dead hold it.
func _roof(rr: Rect2, base: Color, a: float, ruined: bool, seed_i: int, deco := true) -> void:
	var R := roofs
	if deco:
		R.draw_rect(Rect2(rr.position + Vector2(7, 9), rr.size), Color(0, 0, 0, 0.28 * a))
	var p := rr.position
	var s := rr.size
	var horiz := s.x >= s.y
	var hh := (s.y if horiz else s.x) / 2.0
	var ra := p + Vector2(hh, hh)
	var rb := p + (Vector2(s.x - hh, hh) if horiz else Vector2(hh, s.y - hh))
	var tl := p
	var tr := p + Vector2(s.x, 0)
	var bl := p + Vector2(0, s.y)
	var br := p + s
	var light := base.lightened(0.16)
	var shade := base.darkened(0.22)
	if horiz:
		R.draw_colored_polygon(PackedVector2Array([tl, tr, rb, ra]), _ca(light, a))
		R.draw_colored_polygon(PackedVector2Array([bl, ra, rb, br]), _ca(shade, a))
		R.draw_colored_polygon(PackedVector2Array([tl, ra, bl]), _ca(base, a))
		R.draw_colored_polygon(PackedVector2Array([tr, br, rb]), _ca(base.darkened(0.1), a))
	else:
		R.draw_colored_polygon(PackedVector2Array([tl, ra, rb, bl]), _ca(light, a))
		R.draw_colored_polygon(PackedVector2Array([tr, br, rb, ra]), _ca(shade, a))
		R.draw_colored_polygon(PackedVector2Array([tl, tr, ra]), _ca(base.lightened(0.05), a))
		R.draw_colored_polygon(PackedVector2Array([bl, rb, br]), _ca(base.darkened(0.1), a))
	for k in range(1, int(hh / 7.0)):
		var d := k * 7.0
		R.draw_polyline(PackedVector2Array([p + Vector2(d, d), p + Vector2(s.x - d, d), p + Vector2(s.x - d, s.y - d), p + Vector2(d, s.y - d), p + Vector2(d, d)]),
			_ca(base.darkened(0.12), a * 0.6), 1.0)
	R.draw_line(ra, rb, _ca(base.darkened(0.4), a), 3.0)
	for q in [[tl, ra], [tr, rb if horiz else ra], [bl, ra if horiz else rb], [br, rb]]:
		R.draw_line(q[0], q[1], _ca(base.darkened(0.3), a), 1.5)
	R.draw_rect(rr, _ca(Color(0.22, 0.14, 0.07), a), false, 2.0)
	if not deco:
		return
	if ruined:
		for k in 2:
			var hp := p + s * Vector2(0.25 + 0.45 * _hash(seed_i, k), 0.25 + 0.4 * _hash(k, seed_i))
			R.draw_colored_polygon(PackedVector2Array([hp, hp + Vector2(12, -3), hp + Vector2(16, 8), hp + Vector2(4, 11), hp + Vector2(-3, 5)]), _ca(Color(0.1, 0.08, 0.06), a))
	else:
		var ch := p + s * Vector2(0.72, 0.22)
		R.draw_rect(Rect2(ch, Vector2(9, 11)), _ca(Color(0.55, 0.5, 0.46), a))
		R.draw_rect(Rect2(ch, Vector2(9, 3)), _ca(Color(0.2, 0.18, 0.16), a))


## The palace of Ala Kambara: a paved court with gardens in its corners, red wings in a cross, a golden roof
## over the throne room.
func _palace(rr: Rect2, a: float) -> void:
	var R := roofs
	var p := rr.position
	var s := rr.size
	R.draw_rect(Rect2(p + Vector2(8, 10), s), Color(0, 0, 0, 0.28 * a))
	R.draw_rect(rr, _ca(Color(0.8, 0.76, 0.68), a))
	var q := s * 0.3
	for cp in [p, p + Vector2(s.x - q.x, 0), p + Vector2(0, s.y - q.y), p + s - q]:
		var g := Rect2(cp, q).grow(-8)
		R.draw_rect(g, _ca(Color(0.3, 0.55, 0.22), a))
		R.draw_rect(g, _ca(Color(0.2, 0.38, 0.14), a), false, 2.0)
		for k in 3:
			R.draw_circle(g.position + g.size * Vector2(0.25 + 0.25 * k, 0.5), 6, _ca(Color(0.2, 0.42, 0.15), a))
	var red := Color(0.74, 0.2, 0.15)
	_roof(Rect2(p.x, p.y + s.y * 0.3, s.x, s.y * 0.4), red, a, false, 0, false)
	_roof(Rect2(p.x + s.x * 0.33, p.y, s.x * 0.34, s.y), red, a, false, 0, false)
	var cc := rr.get_center()
	var d := minf(s.x, s.y) * 0.3
	var c0 := cc + Vector2(-d, -d)
	var c1 := cc + Vector2(d, -d)
	var c2 := cc + Vector2(d, d)
	var c3 := cc + Vector2(-d, d)
	var top := cc + Vector2(0, -4)
	R.draw_rect(Rect2(c0 - Vector2(4, 4), Vector2(d, d) * 2 + Vector2(8, 8)), _ca(Color(0.45, 0.12, 0.08), a))
	R.draw_colored_polygon(PackedVector2Array([c0, c1, top]), _ca(Color(1.0, 0.86, 0.38), a))
	R.draw_colored_polygon(PackedVector2Array([c1, c2, top]), _ca(Color(0.86, 0.64, 0.18), a))
	R.draw_colored_polygon(PackedVector2Array([c2, c3, top]), _ca(Color(0.72, 0.5, 0.12), a))
	R.draw_colored_polygon(PackedVector2Array([c3, c0, top]), _ca(Color(0.94, 0.74, 0.26), a))
	R.draw_polyline(PackedVector2Array([c0, c1, c2, c3, c0]), _ca(Color(0.4, 0.25, 0.06), a), 2.0)
	for k in [c0, c1, c2, c3]:
		R.draw_line(k, top, _ca(Color(0.6, 0.4, 0.1), a), 1.5)
	R.draw_circle(top, 6, _ca(Color(0.8, 0.15, 0.12), a))


## A name plaque over a holding, the same size on screen whatever the zoom: a crown for the capital, a blue badge
## for a city we hold, a red one for a city of the dead.
func _plaque(at: Vector2, text: String, kind: String, sub: String, sub_col: Color) -> void:
	var k := clampf(1.0 / cam.zoom.x, 0.5, 2.6)
	labels.draw_set_transform(at, 0.0, Vector2(k, k))
	var fs := 24 if kind == "crown" else 19
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sw := 0.0 if sub == "" else font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 14.0
	var hgt := fs + 14.0
	var box := Rect2(-(tw + sw + 46.0) / 2.0, -hgt, tw + sw + 46.0, hgt)
	labels.draw_rect(box.grow(3), Color(0.08, 0.05, 0.03, 0.9))
	labels.draw_rect(box, Color(0.3, 0.18, 0.09))
	labels.draw_rect(box.grow(-2), Color(0.9, 0.7, 0.36), false, 2.0)
	_icon(labels, kind, at + Vector2(box.position.x + 19, box.position.y + hgt / 2.0) * k, 0.85 * k)
	labels.draw_set_transform(at, 0.0, Vector2(k, k))
	labels.draw_string(font, Vector2(box.position.x + 36, box.end.y - 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_TEXT)
	if sub != "":
		labels.draw_string(font, Vector2(box.position.x + 36 + tw + 10, box.end.y - 10), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, sub_col)
	labels.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_labels() -> void:
	if c == null:
		return
	var n := c.night_ratio()
	for nz in c.noises:
		var u: float = 1.0 - nz[2] / 0.6
		labels.draw_arc(nz[0], nz[1] * (0.3 + 0.7 * u), 0, TAU, 40, Color(1.0, 0.85, 0.6, 0.25 * (1.0 - u)), 2.0)
	for z in c.dead:
		if n > 0.3:
			var side: Vector2 = z.face.orthogonal() * 3.0
			var e: Vector2 = z.p + z.face * 6.0
			labels.draw_circle(e + side, 1.8, Color(0.6, 0.9, 1.0, 0.85 * n))
			labels.draw_circle(e - side, 1.8, Color(0.6, 0.9, 1.0, 0.85 * n))
		var tag := ""
		var col := C_GOLD
		if z.state == Realm.CHASE:
			tag = "!"
			col = C_RED
		elif z.state == Realm.INVESTIGATE or z.sus > 0.15:
			tag = "?"
		if tag != "":
			labels.draw_string(font_px, z.p + Vector2(-6, -18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
	for s in c.people:
		var txt: String = "zzz" if s.asleep else s.name
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		labels.draw_string(font, s.p + Vector2(-w / 2, -16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, JOB_COL[s.job])
		var f := clampf(s.hp / 100.0, 0.0, 1.0)
		labels.draw_rect(Rect2(s.p + Vector2(-13, 15), Vector2(26, 4)), Color(0, 0, 0, 0.6))
		labels.draw_rect(Rect2(s.p + Vector2(-13, 15), Vector2(26 * f, 4)), Color(0.9, 0.25, 0.2).lerp(Color(0.45, 0.85, 0.35), f))
	# each city: its name on a plaque over the hall
	for h in c.land.holdings.size():
		var hd: Dictionary = c.land.holdings[h]
		var hr := c.land.hall_rect(h)
		var top := Vector2((hr.position.x + hr.size.x / 2.0) * T, hr.position.y * T - 10)
		var kind := "crown" if h == 0 else ("crypt" if hd.crypt else ("ours" if hd.claimed else "dead"))
		var sub := ""
		var sub_col := C_RED.lightened(0.3)
		if c.target == h:
			sub = "warband marching"
			sub_col = C_GOLD
		elif not hd.claimed and not hd.crypt and c.dead_in(h) > 0:
			sub = "%d dead" % c.dead_in(h)
		_plaque(top, hd.name, kind, sub, sub_col)
		if hd.crypt and c.target == h:
			labels.draw_rect(Rect2(c.hall_pos(h) + Vector2(-40, 24), Vector2(80 * maxf(0.0, c.altar_hp) / Realm.ALTAR_HP, 6)), Color(0.7, 0.4, 0.95))
	for i in c.land.houses.size():
		if not c.marked.has(i):
			continue
		var hp := c.land.center(c.land.houses[i].rect.get_center())
		labels.draw_string(font, hp + Vector2(-40, 6), "SEARCH HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_GOLD)
	for f in floats:
		var w := font.get_string_size(f[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		labels.draw_string(font, f[0] - Vector2(w / 2, 20), f[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(f[3], clampf(f[2], 0.0, 1.0)))


func _draw_hud() -> void:
	if c == null or mode == "title":
		return
	var vs := hud_draw.size
	var H := hud_draw
	# the top bar: the empire, the day, the clock, the stores
	H.draw_rect(Rect2(0, 0, vs.x, 46), Color(0.12, 0.075, 0.045, 0.97))
	H.draw_rect(Rect2(0, 44, vs.x, 2), P_EDGE)
	_icon(H, "crown", Vector2(26, 23), 1.1)
	H.draw_string(font_px, Vector2(48, 32), "EMPIRE OF KAMBARA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, C_GOLD)
	H.draw_rect(Rect2(296, 8, 2, 30), Color(P_EDGE, 0.5))
	var night := c.phase == Realm.NIGHT
	var left := c.time_left()
	H.draw_string(font_px, Vector2(312, 32), ("NIGHT %d" if night else "DAY %d") % c.day, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.6, 0.7, 1.0) if night else C_GOLD)
	H.draw_string(font, Vector2(430, 30), "%d:%02d until %s" % [int(left) / 60, int(left) % 60, "dawn" if night else "dusk"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_TEXT)
	var st := c.stock
	var items := [["food", "Food %d" % int(st.food)], ["wood", "Wood %d" % int(st.wood)], ["arrows", "Arrows %d" % st.arrows],
		["herbs", "Herbs %d" % st.herbs], ["souls", "Souls %d" % c.people.size()], ["cities", "Cities %d/%d" % [c.holdings_owned().size(), c.land.holdings.size() - 1]]]
	var x := vs.x - 14.0
	items.reverse()
	for it in items:
		var w := font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		x -= w + 30.0
		_icon(H, it[0], Vector2(x + 10, 23), 0.95)
		H.draw_string(font, Vector2(x + 26, 30), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_TEXT)
		x -= 16.0
	# minimap, top right, framed
	minimap = Rect2(vs.x - 300, 56, 286, 286 * Land.H / float(Land.W))
	H.draw_rect(minimap.grow(4), Color(0.1, 0.06, 0.03))
	H.draw_rect(minimap, Color(0.36, 0.56, 0.2))
	var k := minimap.size.x / Land.W
	for y in range(0, Land.H, 2):
		for xx in range(0, Land.W, 2):
			var col := Color.TRANSPARENT
			match c.land.at(Vector2i(xx, y)):
				Land.FOREST: col = Color(0.16, 0.34, 0.12)
				Land.ROAD: col = Color(0.72, 0.58, 0.38)
				Land.PAVE: col = Color(0.72, 0.7, 0.64)
				Land.FIELD: col = Color(0.88, 0.7, 0.26)
				Land.GRAVE: col = Color(0.3, 0.25, 0.3)
				Land.WATER: col = Color(0.2, 0.46, 0.8)
				Land.ROCK: col = Color(0.56, 0.55, 0.52)
				Land.SAND: col = Color(0.92, 0.82, 0.55)
				Land.WALL, Land.FLOOR, Land.DOOR, Land.WINDOW: col = Color(0.8, 0.6, 0.32)
			if col.a > 0.0:
				H.draw_rect(Rect2(minimap.position + Vector2(xx, y) * k, Vector2(2, 2) * k), col)
	for h in c.land.holdings.size():
		var hd: Dictionary = c.land.holdings[h]
		var col := C_BLUE if hd.claimed else (Color(0.6, 0.3, 0.9) if hd.crypt else C_RED)
		var mp := minimap.position + Vector2(hd.center) * k
		H.draw_rect(Rect2(mp - Vector2(5, 4), Vector2(10, 8)), col)
		H.draw_rect(Rect2(mp - Vector2(5, 4), Vector2(10, 8)), Color(0.1, 0.06, 0.03), false, 1.0)
		if c.target == h:
			H.draw_arc(mp, 10, 0, TAU, 16, C_GOLD, 2.0)
	for s in c.people:
		H.draw_rect(Rect2(minimap.position + s.p / T * k - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.95, 1.0))
	var view := Rect2(cam.get_screen_center_position() - vs / cam.zoom / 2.0, vs / cam.zoom)
	H.draw_rect(Rect2(minimap.position + view.position / T * k, view.size / T * k).intersection(minimap), Color(1, 1, 1, 0.8), false, 1.5)
	H.draw_rect(minimap.grow(2), P_EDGE, false, 2.0)
	H.draw_string(font_px, minimap.position + Vector2(minimap.size.x - 18, 18), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	# the realm's chronicle, bottom left, over the build bar
	var y2 := vs.y - 132.0
	var lines := c.log.slice(maxi(0, c.log.size() - 3))
	lines.reverse()
	for i in lines.size():
		var l: Array = lines[i]
		var txt := "Day %d · %s" % l
		if i == 0:
			var r := Rect2(10, y2 - 20, 600, 28)
			H.draw_rect(r, P_BG)
			H.draw_rect(r, P_EDGE, false, 1.5)
			_icon(H, "info", Vector2(25, y2 - 6), 0.9)
			H.draw_string(font, Vector2(42, y2), txt, HORIZONTAL_ALIGNMENT_LEFT, 560, 15, C_TEXT)
		else:
			H.draw_string(font, Vector2(42, y2), txt, HORIZONTAL_ALIGNMENT_LEFT, 560, 14, Color(C_TEXT, 0.75))
		y2 -= 26.0 if i == 0 else 20.0
	if banner_t > 0.0:
		var al := clampf(minf(banner_t, 4.0 - banner_t) * 2.0, 0.0, 1.0)
		var w := font_px.get_string_size(banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var box := Rect2(vs.x / 2 - w / 2 - 56, 62, w + 112, 50)
		H.draw_rect(box.grow(3), Color(0.06, 0.04, 0.02, 0.85 * al))
		H.draw_rect(box, Color(0.2, 0.12, 0.06, 0.95 * al))
		H.draw_rect(box.grow(-3), Color(P_EDGE, al), false, 2.0)
		H.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for dx in [box.position.x + 28, box.end.x - 28]:
			H.draw_colored_polygon(PackedVector2Array([Vector2(dx, box.position.y + 13), Vector2(dx + 11, box.position.y + 25), Vector2(dx, box.position.y + 37), Vector2(dx - 11, box.position.y + 25)]), Color(C_GOLD, al))
		H.draw_string(font_px, Vector2(vs.x / 2 - w / 2, box.position.y + 36), banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(C_GOLD, al))
	if speed == 0:
		var pw := font_px.get_string_size("PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		H.draw_string(font_px, Vector2(vs.x / 2 - pw / 2, 140), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, C_GOLD)


## Small drawn icons for the top bar, the build cards and the map plaques.
func _icon(ci: CanvasItem, id: String, at: Vector2, s := 1.0) -> void:
	ci.draw_set_transform(at, 0.0, Vector2(s, s))
	var gold := Color(0.95, 0.75, 0.25)
	var wood := Color(0.55, 0.36, 0.18)
	var stone := Color(0.72, 0.7, 0.66)
	match id:
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-12, 8), Vector2(-12, -7), Vector2(-6, 0), Vector2(0, -10), Vector2(6, 0), Vector2(12, -7), Vector2(12, 8)]), C_GOLD)
			ci.draw_rect(Rect2(-12, 4, 24, 4), Color(0.8, 0.55, 0.12))
			ci.draw_circle(Vector2(0, -10), 2.2, Color(0.9, 0.2, 0.15))
		"ours", "dead":
			ci.draw_rect(Rect2(-11, -11, 22, 22), Color(0.2, 0.36, 0.75) if id == "ours" else Color(0.72, 0.14, 0.1))
			ci.draw_rect(Rect2(-11, -11, 22, 22), Color(0.1, 0.05, 0.03), false, 1.5)
			_star(ci, Vector2.ZERO, 8.0, C_GOLD)
		"crypt":
			ci.draw_circle(Vector2.ZERO, 11, Color(0.35, 0.15, 0.45))
			ci.draw_circle(Vector2(-4, -2), 2.8, Color(0.85, 0.7, 1.0))
			ci.draw_circle(Vector2(4, -2), 2.8, Color(0.85, 0.7, 1.0))
			ci.draw_rect(Rect2(-4, 5, 8, 3), Color(0.85, 0.7, 1.0))
		"food":
			ci.draw_line(Vector2(0, 11), Vector2(0, -6), Color(0.75, 0.55, 0.15), 2.0)
			for q in 3:
				ci.draw_circle(Vector2(-3.5, -6 + q * 5), 2.8, gold)
				ci.draw_circle(Vector2(3.5, -6 + q * 5), 2.8, gold)
			ci.draw_circle(Vector2(0, -10), 2.6, gold)
		"wood":
			for q in 2:
				var o := Vector2(-3 + q * 5, -5 + q * 8)
				ci.draw_rect(Rect2(o + Vector2(-9, -4), Vector2(16, 8)), wood)
				ci.draw_circle(o + Vector2(7, 0), 4.5, Color(0.86, 0.68, 0.44))
				ci.draw_arc(o + Vector2(7, 0), 2.2, 0, TAU, 8, wood, 1.0)
		"arrows":
			ci.draw_line(Vector2(-10, 9), Vector2(8, -9), Color(0.85, 0.8, 0.7), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(11, -12), Vector2(3, -9), Vector2(8, -4)]), stone)
			ci.draw_line(Vector2(-10, 9), Vector2(-12, 3), Color(0.9, 0.3, 0.25), 2.0)
			ci.draw_line(Vector2(-10, 9), Vector2(-4, 11), Color(0.9, 0.3, 0.25), 2.0)
		"herbs":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, 9), Vector2(-8, -2), Vector2(0, -10), Vector2(9, -10), Vector2(8, 0), Vector2(0, 8)]), Color(0.35, 0.72, 0.3))
			ci.draw_line(Vector2(-9, 9), Vector2(6, -7), Color(0.2, 0.45, 0.15), 1.5)
		"souls":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(7, -1), Vector2(6, 6), Vector2(0, 10), Vector2(-6, 6), Vector2(-7, -1)]), Color(0.62, 0.38, 0.95))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -4), Vector2(3.5, 2), Vector2(0, 7), Vector2(-3.5, 2)]), Color(0.9, 0.8, 1.0))
		"cities", "towers":
			ci.draw_rect(Rect2(-10, -5, 20, 15), stone)
			for q in 3:
				ci.draw_rect(Rect2(-10 + q * 8, -10, 4, 5), stone)
			ci.draw_rect(Rect2(-3, 2, 6, 8), Color(0.3, 0.22, 0.15))
		"palisade":
			for q in 5:
				var px := -12.0 + q * 6.0
				ci.draw_rect(Rect2(px - 2.5, -6, 5, 16), wood.lightened(0.05 * q))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 2.5, -6), Vector2(px + 2.5, -6), Vector2(px, -11)]), wood.lightened(0.2))
		"gate":
			ci.draw_rect(Rect2(-8, -11, 16, 22), wood)
			for q in 3:
				ci.draw_rect(Rect2(-10, -8 + q * 7, 20, 3), Color(0.75, 0.6, 0.38))
		"shutters":
			ci.draw_rect(Rect2(-10, -10, 20, 20), Color(0.35, 0.28, 0.2))
			ci.draw_rect(Rect2(-9, -9, 8, 18), wood.lightened(0.15))
			ci.draw_rect(Rect2(1, -9, 8, 18), wood.lightened(0.1))
		"beds":
			ci.draw_rect(Rect2(-12, -6, 24, 13), Color(0.92, 0.8, 0.42))
			ci.draw_rect(Rect2(-12, -6, 7, 13), Color(0.95, 0.94, 0.9))
			ci.draw_rect(Rect2(-12, -6, 24, 13), wood, false, 1.5)
		"mill":
			ci.draw_rect(Rect2(-5, -2, 10, 13), stone)
			for q in 4:
				var d := Vector2.RIGHT.rotated(q * PI / 2 + 0.4)
				ci.draw_line(Vector2(0, -2), Vector2(0, -2) + d * 12, wood, 3.0)
		"fletcher":
			ci.draw_arc(Vector2(-2, 0), 11, -1.2, 1.2, 10, wood, 2.5)
			ci.draw_line(Vector2(-12, 0), Vector2(11, 0), Color(0.85, 0.82, 0.72), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(8, -3), Vector2(8, 3)]), stone)
		"chapel":
			ci.draw_rect(Rect2(-9, -2, 18, 12), Color(0.9, 0.86, 0.75))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-11, -2), Vector2(0, -10), Vector2(11, -2)]), Color(0.75, 0.25, 0.18))
			ci.draw_rect(Rect2(-1, -16, 2, 7), C_GOLD)
			ci.draw_rect(Rect2(-3.5, -14, 7, 2), C_GOLD)
		"barracks":
			ci.draw_line(Vector2(-10, 10), Vector2(10, -10), Color(0.8, 0.82, 0.88), 3.0)
			ci.draw_line(Vector2(10, 10), Vector2(-10, -10), Color(0.8, 0.82, 0.88), 3.0)
			ci.draw_line(Vector2(-11, 5), Vector2(-5, 11), wood, 3.0)
			ci.draw_line(Vector2(11, 5), Vector2(5, 11), wood, 3.0)
		"bell":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-11, 8), Vector2(11, 8), Vector2(7, -3), Vector2(4, -9), Vector2(-4, -9), Vector2(-7, -3)]), gold)
			ci.draw_circle(Vector2(0, 10), 2.5, Color(0.6, 0.45, 0.12))
		"hammer":
			ci.draw_line(Vector2(-10, 12), Vector2(5, -3), wood, 4.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-2, -9), Vector2(6, -14), Vector2(13, -5), Vector2(5, 0)]), stone)
		"info":
			ci.draw_circle(Vector2.ZERO, 9, gold)
			ci.draw_rect(Rect2(-1.5, -2, 3, 7), Color(0.15, 0.1, 0.05))
			ci.draw_circle(Vector2(0, -5), 1.8, Color(0.15, 0.1, 0.05))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _star(ci: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for q in 10:
		pts.append(at + Vector2.UP.rotated(q * PI / 5.0) * (r if q % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


# ---------------------------------------------------------------- save

func _load() -> void:
	if FileAccess.file_exists(SAVE):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if d is Dictionary:
			best = int(d.get("best", 0))


func _save() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best": best}))
