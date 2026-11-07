extends Node2D
## CROWN OF ASH — win back a realm from the walking dead. Your villagers live by themselves; you set jobs, rules and
## works, and send the warband out. Args (after --): --play  --night  --fast  --shot=path.png --frames=N  --windowed

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
const JOB_COL := {"farm": Color(0.95, 0.85, 0.4), "chop": Color(0.65, 0.85, 0.45), "forage": Color(0.95, 0.65, 0.3),
	"build": Color(0.6, 0.8, 1.0), "guard": Color(0.95, 0.5, 0.45), "soldier": Color(1.0, 0.35, 0.3), "rest": Color(0.75, 0.75, 0.75)}

var c: Realm
var mode := "title"
var best := 0
var speed := 1
var font: Font
var font_px: Font
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
var cards_box: HBoxContainer
var warband_btn: Button
var order_row: HBoxContainer
var train_row: HBoxContainer
var order_btns := {}
var train_btns := {}
var minimap := Rect2()


func _ready() -> void:
	font = load("res://assets/fonts/Lato-Bold.ttf")
	font_px = load("res://assets/fonts/PixelifySans.ttf")
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.05))
	_load()
	sfx = Sfx.new()
	add_child(sfx)
	dark = CanvasModulate.new()
	add_child(dark)
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
	if not "--windowed" in OS.get_cmdline_user_args() and shot_path == "":
		if DisplayServer.get_screen_count() > 1:
			DisplayServer.window_set_current_screen(1)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	if start:
		new_game()
		if pick >= 0:
			_select(c.people[pick], true)
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
	cam.zoom = Vector2(0.7, 0.7)
	_clear_ui()
	_clear()
	overlay = _panel(1000)
	var v: VBoxContainer = overlay.get_meta("box")
	v.add_child(_lbl("CROWN OF ASH", 104, C_GOLD, font_px))
	v.add_child(_lbl("The dead walk. Ashford stands alone. Your people live by themselves — you set their work, the village rules and what gets built, and you send the warband to win back the land, village by village, to the Black Crypt.", 25, C_DIM))
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
	cam.zoom = Vector2(0.9, 0.9)
	_build_ui()
	_banner("DAY 1 — Ashford stands alone")


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
	v.add_child(_lbl("The crypt broken on day %d, with %d souls." % [c.day, c.people.size()] if won else "Ashford fell on day %d." % c.day, 28, C_TEXT))
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
	b.set_corner_radius_all(4)
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
	b.add_theme_stylebox_override("normal", _box(Color(0.12, 0.1, 0.08, 0.92), Color(0.55, 0.45, 0.3, 0.7)))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.16, 0.1, 0.95), C_GOLD))
	b.add_theme_stylebox_override("pressed", _box(Color(0.32, 0.22, 0.08, 0.95), C_GOLD))
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
	sp.position = Vector2(470, 8)
	sp.add_theme_constant_override("separation", 6)
	ui.add_child(sp)
	speed_btns.clear()
	for k in [0, 1, 2, 4]:
		var b := _btn("II" if k == 0 else "%d×" % k, 18)
		b.custom_minimum_size = Vector2(52, 38)
		b.pressed.connect(func(): speed = k; _refresh_ui())
		sp.add_child(b)
		speed_btns.append(b)
	# left: rules and people
	var left := VBoxContainer.new()
	left.position = Vector2(14, 70)
	left.add_theme_constant_override("separation", 5)
	ui.add_child(left)
	left.add_child(_lbl("RULES", 15, C_DIM, font_px, false))
	rule_btns.clear()
	for key in ["hearths", "rations", "close_gate"]:
		var b := _btn("", 16)
		b.custom_minimum_size = Vector2(270, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_toggle_rule.bind(key))
		left.add_child(b)
		rule_btns[key] = b
	left.add_child(_lbl("PEOPLE", 15, C_DIM, font_px, false))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(285, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	people_box = VBoxContainer.new()
	people_box.add_theme_constant_override("separation", 3)
	scroll.add_child(people_box)
	# right: the holdings, under the minimap
	var right := VBoxContainer.new()
	right.anchor_left = 1.0; right.anchor_right = 1.0
	right.offset_left = -300; right.offset_right = -14; right.offset_top = 64 + 214
	right.add_theme_constant_override("separation", 5)
	ui.add_child(right)
	right.add_child(_lbl("THE REALM", 15, C_DIM, font_px, false))
	hold_btns.clear()
	for h in c.land.holdings.size():
		var b := _btn("", 15)
		b.custom_minimum_size = Vector2(286, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_holding_click.bind(h))
		right.add_child(b)
		hold_btns[h] = b
	right.add_child(_lbl("Click a village you hold to manage its works; click one the dead hold to send the warband.", 13, C_DIM, null, false))
	# bottom: the selected village's works
	place_lbl = _lbl("", 16, C_GOLD, font_px)
	place_lbl.anchor_left = 0.5; place_lbl.anchor_right = 0.5; place_lbl.anchor_top = 1.0; place_lbl.anchor_bottom = 1.0
	place_lbl.offset_left = -300; place_lbl.offset_right = 300; place_lbl.offset_top = -124; place_lbl.offset_bottom = -102
	ui.add_child(place_lbl)
	var cards := HBoxContainer.new()
	cards_box = cards
	var n := Realm.UPGRADES.size()
	var cw := 132 * n + 6 * (n - 1)
	cards.anchor_left = 0.5; cards.anchor_right = 0.5; cards.anchor_top = 1.0; cards.anchor_bottom = 1.0
	cards.offset_left = -cw / 2.0; cards.offset_right = cw / 2.0; cards.offset_top = -98; cards.offset_bottom = -10
	cards.add_theme_constant_override("separation", 6)
	ui.add_child(cards)
	card_btns.clear()
	for u in Realm.UPGRADES:
		var b := _btn("", 14)
		b.custom_minimum_size = Vector2(132, 86)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.tooltip_text = u.info
		b.pressed.connect(_card.bind(u.id))
		cards.add_child(b)
		card_btns[u.id] = b
	warband_btn = _btn("", 20)
	warband_btn.anchor_left = 0.5; warband_btn.anchor_right = 0.5; warband_btn.anchor_top = 1.0; warband_btn.anchor_bottom = 1.0
	warband_btn.offset_left = -330; warband_btn.offset_right = 330; warband_btn.offset_top = -94; warband_btn.offset_bottom = -20
	warband_btn.pressed.connect(_send_warband)
	ui.add_child(warband_btn)
	# the villager card
	unit_card = PanelContainer.new()
	unit_card.add_theme_stylebox_override("panel", _box(Color(0.07, 0.06, 0.05, 0.94), Color(0.55, 0.45, 0.3, 0.8)))
	unit_card.anchor_left = 1.0; unit_card.anchor_right = 1.0; unit_card.anchor_top = 1.0; unit_card.anchor_bottom = 1.0
	unit_card.offset_left = -726; unit_card.offset_right = -314; unit_card.offset_top = -330; unit_card.offset_bottom = -132
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
			txt = "⚔ " + txt
		b.text = txt
		b.add_theme_color_override("font_color", C_BLUE.lightened(0.3) if hd.claimed else (C_GOLD if c.target == h else C_RED.lightened(0.2)))
		if h == place:
			b.add_theme_color_override("font_color", Color.WHITE)
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
		var b := _btn("%s · %s · %s%s" % [s.name, role, c.land.holdings[s.home].name, "  ✚ resting" if s.resting else ""], 14)
		b.draw.connect(_hp_strip.bind(b, s))
		b.custom_minimum_size = Vector2(275, 28)
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
			cam.zoom = (cam.zoom * 1.1).clamp(Vector2(0.35, 0.35), Vector2(2.0, 2.0))
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom = (cam.zoom / 1.1).clamp(Vector2(0.35, 0.35), Vector2(2.0, 2.0))
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
	for y in range(maxi(0, r.position.y), mini(Land.H, r.end.y)):
		for x in range(maxi(0, r.position.x), mini(Land.W, r.end.x)):
			_tile(Vector2i(x, y))
	for y in range(maxi(0, r.position.y), mini(Land.H, r.end.y)):
		for x in range(maxi(0, r.position.x), mini(Land.W, r.end.x)):
			if c.land.at(Vector2i(x, y)) == Land.FOREST:
				_tree(Vector2i(x, y))
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


func _tile(cell: Vector2i) -> void:
	var t := c.land.at(cell)
	var rect := Rect2(cell.x * T, cell.y * T, T, T)
	var h := _hash(cell.x, cell.y)
	match t:
		Land.GRASS, Land.FOREST:
			world.draw_rect(rect, Color(0.33, 0.47, 0.25).lerp(Color(0.38, 0.5, 0.27), h) if t == Land.GRASS else Color(0.22, 0.32, 0.18))
			if t == Land.GRASS and h < 0.06:
				world.draw_circle(rect.get_center() + Vector2(h * 80 - 2, 0), 3, Color(0.85, 0.8, 0.4))
		Land.ROAD:
			world.draw_rect(rect, Color(0.52, 0.42, 0.3).lerp(Color(0.48, 0.38, 0.27), h))
			world.draw_circle(rect.position + Vector2(8 + h * 16, 10 + h * 10), 2, Color(0.4, 0.32, 0.22))
		Land.FIELD:
			world.draw_rect(rect, Color(0.62, 0.52, 0.28))
			for k in 4:
				world.draw_line(rect.position + Vector2(0, 4 + k * 8), rect.position + Vector2(T, 4 + k * 8), Color(0.85, 0.72, 0.35), 3.0)
		Land.GRAVE:
			world.draw_rect(rect, Color(0.22, 0.2, 0.18).lerp(Color(0.26, 0.23, 0.2), h))
			if h < 0.35:
				var p := rect.get_center() + Vector2((h - 0.17) * 30, 0)
				world.draw_rect(Rect2(p - Vector2(5, 7), Vector2(10, 12)), Color(0.5, 0.5, 0.52))
		Land.FLOOR:
			var wood := Color(0.45, 0.35, 0.24)
			world.draw_rect(rect, wood.lerp(wood.darkened(0.12), h))
			world.draw_line(rect.position + Vector2(0, 16), rect.position + Vector2(T, 16), wood.darkened(0.25), 1.0)
		Land.WALL:
			world.draw_rect(rect, Color(0.55, 0.52, 0.48))
			world.draw_rect(rect, Color(0.38, 0.35, 0.32), false, 2.0)
		Land.WINDOW, Land.DOOR:
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


## The palisade: stakes where it's raised, a faint marked line where it's planned, gates on the roads; and the
## corner towers.
func _draw_walls(view: Rect2i) -> void:
	for cell in c.walls:
		if not view.has_point(cell):
			continue
		var w: Dictionary = c.walls[cell]
		var mine: bool = c.land.holdings[w.h].claimed
		var rect := Rect2(cell.x * T, cell.y * T, T, T)
		if not w.up:
			if not mine:
				continue
			var queued: bool = "palisade" in c.queue[w.h]
			world.draw_rect(rect.grow(-6), Color(0.9, 0.8, 0.55, 0.35 if queued else 0.16), false, 2.0)
			if float(w.work) > 0.0:
				world.draw_rect(Rect2(rect.position + Vector2(3, T - 7), Vector2((T - 6) * w.work / Realm.STAKE_WORK, 4)), C_GOLD)
			continue
		var wood := Color(0.48, 0.34, 0.2)
		if float(w.hp) <= 0.0:
			for k in 3:
				world.draw_line(rect.position + Vector2(5 + k * 10, 10), rect.position + Vector2(8 + k * 9, T - 4), wood.darkened(0.4), 3.0)
			continue
		if w.gate:
			world.draw_rect(rect, Color(0.3, 0.22, 0.14))
			if w.open:
				world.draw_rect(Rect2(rect.position, Vector2(6, T)), wood.lightened(0.1))
			else:
				world.draw_rect(rect.grow(-1), wood.lightened(0.15))
				world.draw_line(rect.position + Vector2(0, T / 2), rect.position + Vector2(T, T / 2), wood.darkened(0.4), 3.0)
		else:
			for k in 4:
				var x := rect.position.x + 4 + k * 8
				world.draw_rect(Rect2(x - 3.5, rect.position.y + 2, 7, T - 4), wood.lerp(wood.lightened(0.15), _hash(cell.x * 4 + k, cell.y)))
				world.draw_colored_polygon(PackedVector2Array([Vector2(x - 3.5, rect.position.y + 2), Vector2(x + 3.5, rect.position.y + 2), Vector2(x, rect.position.y - 3)]), wood.lightened(0.25))
		var full: float = c.wall_max(w)
		if float(w.hp) < full - 1.0:
			world.draw_rect(Rect2(rect.position + Vector2(2, -7), Vector2((T - 4) * float(w.hp) / full, 4)), C_RED)
	for h in c.towers:
		if not c.land.holdings[h].claimed:
			continue
		for k in c.towers[h].size():
			var at: Vector2 = c.towers[h][k]
			var tr := Rect2(at - Vector2(22, 22), Vector2(44, 44))
			if k < c.tower_count[h]:
				world.draw_rect(tr, Color(0.55, 0.52, 0.47))
				world.draw_rect(tr.grow(-7), Color(0.42, 0.33, 0.22))
				for q in 4:
					var cp: Vector2 = tr.position + Vector2(q % 2, q / 2) * 34.0
					world.draw_rect(Rect2(cp, Vector2(10, 10)), Color(0.66, 0.63, 0.58))
			else:
				var queued: bool = "towers" in c.queue[h] and k == c.tower_count[h]
				world.draw_rect(tr, Color(0.9, 0.8, 0.55, 0.4 if queued else 0.15), false, 2.0)
				if queued:
					var frac: float = c.progress[h].get("towers", 0.0) / 24.0
					if frac > 0.0:
						world.draw_rect(Rect2(tr.position + Vector2(0, 46), Vector2(44 * frac, 4)), C_GOLD)


func _tree(cell: Vector2i) -> void:
	var h := _hash(cell.x, cell.y)
	var p := c.land.center(cell) + Vector2((h - 0.5) * 10, (_hash(cell.y, cell.x) - 0.5) * 10)
	world.draw_circle(p + Vector2(3, 4), 18, Color(0.1, 0.16, 0.08, 0.5))
	world.draw_circle(p, 17 + h * 4, Color(0.18, 0.36, 0.16).lerp(Color(0.24, 0.42, 0.2), h))
	world.draw_circle(p + Vector2(-4, -4), 9, Color(0.3, 0.5, 0.25, 0.7))


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


## Roofs: thatch on cottages, slate on halls, lifted while one of your people is inside. Banners show who holds
## each village.
func _draw_roofs() -> void:
	if c == null:
		return
	for i in c.land.houses.size():
		var hs: Dictionary = c.land.houses[i]
		var hol: Dictionary = c.land.holdings[hs.holding]
		if hs.hall and hol.claimed:
			continue                                    # your halls stay open to see inside
		if c.people.any(func(s): return c.house_of(s.p) == i):
			continue
		var r: Rect2i = hs.rect
		var rr := Rect2(r.position.x * T - 4, r.position.y * T - 4, r.size.x * T + 8, r.size.y * T + 8)
		var base := Color(0.62, 0.52, 0.3) if not hs.hall else Color(0.35, 0.36, 0.4)
		if hol.crypt:
			base = Color(0.22, 0.18, 0.26)
		roofs.draw_rect(rr, base)
		for k in int(rr.size.y / 10.0):
			roofs.draw_line(Vector2(rr.position.x, rr.position.y + k * 10.0), Vector2(rr.end.x, rr.position.y + k * 10.0), base.darkened(0.18), 2.0)
		roofs.draw_line(Vector2(rr.position.x, rr.get_center().y), Vector2(rr.end.x, rr.get_center().y), base.darkened(0.4), 4.0)
		for oc in c.land.openings:
			var od: Dictionary = c.land.openings[oc]
			if od.house != i or od.kind != "door":
				continue
			var dr := Rect2(oc.x * T, oc.y * T, T, T)
			roofs.draw_rect(dr.grow(-3), Color(0.5, 0.33, 0.18) if not od.open else Color(0.1, 0.08, 0.07))
			roofs.draw_rect(dr.grow(3), Color(1.0, 0.85, 0.4), false, 2.0)


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
	# each village: a banner and its name
	for h in c.land.holdings.size():
		var hd: Dictionary = c.land.holdings[h]
		var hr := c.land.hall_rect(h)
		var top := Vector2((hr.position.x + hr.size.x / 2.0) * T, hr.position.y * T - 8)
		var flag := C_BLUE if hd.claimed else (Color(0.5, 0.25, 0.6) if hd.crypt else Color(0.35, 0.3, 0.28))
		labels.draw_line(top, top + Vector2(0, -46), Color(0.4, 0.3, 0.2), 3.0)
		labels.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -46), top + Vector2(30, -40 + sin(Time.get_ticks_msec() * 0.004 + h) * 3), top + Vector2(0, -32)]), flag)
		var name: String = hd.name + ("" if hd.claimed else ("  ⚔" if c.target == h else ""))
		var w := font_px.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		labels.draw_string(font_px, top + Vector2(-w / 2, -54), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_TEXT if hd.claimed else Color(0.9, 0.7, 0.65))
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
	hud_draw.draw_rect(Rect2(0, 0, vs.x, 54), Color(0.05, 0.04, 0.03, 0.75))
	var night := c.phase == Realm.NIGHT
	var left := c.time_left()
	hud_draw.draw_string(font_px, Vector2(20, 38), ("NIGHT %d" if night else "DAY %d") % c.day, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.6, 0.7, 1.0) if night else C_GOLD)
	hud_draw.draw_string(font, Vector2(170, 36), "%d:%02d until %s" % [int(left) / 60, int(left) % 60, "dawn" if night else "dusk"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_TEXT)
	var st := c.stock
	var txt := "Food %d    Wood %d    Arrows %d    Herbs %d    Souls %d    Villages %d/7" % [int(st.food), int(st.wood), st.arrows, st.herbs, c.people.size(), c.holdings_owned().size()]
	hud_draw.draw_string(font, Vector2(vs.x - 20 - font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x, 36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, C_TEXT)
	# minimap, top right
	minimap = Rect2(vs.x - 300, 64, 286, 286 * Land.H / float(Land.W))
	hud_draw.draw_rect(minimap, Color(0.12, 0.16, 0.1, 0.9))
	var k := minimap.size.x / Land.W
	for y in range(0, Land.H, 2):
		for x in range(0, Land.W, 2):
			var t := c.land.at(Vector2i(x, y))
			var col := Color.TRANSPARENT
			match t:
				Land.FOREST: col = Color(0.12, 0.26, 0.1)
				Land.ROAD: col = Color(0.45, 0.36, 0.25)
				Land.FIELD: col = Color(0.6, 0.52, 0.28)
				Land.GRAVE: col = Color(0.3, 0.25, 0.3)
			if col.a > 0.0:
				hud_draw.draw_rect(Rect2(minimap.position + Vector2(x, y) * k, Vector2(2, 2) * k), col)
	for h in c.land.holdings.size():
		var hd: Dictionary = c.land.holdings[h]
		var col := C_BLUE if hd.claimed else (Color(0.6, 0.3, 0.9) if hd.crypt else C_RED)
		var mp := minimap.position + Vector2(hd.center) * k
		hud_draw.draw_rect(Rect2(mp - Vector2(5, 4), Vector2(10, 8)), col)
		if c.target == h:
			hud_draw.draw_arc(mp, 10, 0, TAU, 16, C_GOLD, 2.0)
	for s in c.people:
		hud_draw.draw_rect(Rect2(minimap.position + s.p / T * k - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.95, 1.0))
	var view := Rect2(cam.get_screen_center_position() - vs / cam.zoom / 2.0, vs / cam.zoom)
	hud_draw.draw_rect(Rect2(minimap.position + view.position / T * k, view.size / T * k).intersection(minimap), Color(1, 1, 1, 0.7), false, 1.5)
	# the realm's chronicle, bottom left
	var y2 := vs.y - 120.0
	var lines := c.log.slice(maxi(0, c.log.size() - 5))
	lines.reverse()
	if not lines.is_empty():
		hud_draw.draw_rect(Rect2(10, y2 - 21.0 * lines.size() + 4, 560, 21.0 * lines.size() + 8), Color(0.08, 0.06, 0.05, 0.6))
	for i in lines.size():
		var l: Array = lines[i]
		hud_draw.draw_string(font, Vector2(20, y2), "Day %d · %s" % l, HORIZONTAL_ALIGNMENT_LEFT, 900, 15, Color(C_TEXT, 1.0 if i == 0 else 0.65))
		y2 -= 21.0
	if banner_t > 0.0:
		var al := clampf(minf(banner_t, 4.0 - banner_t) * 2.0, 0.0, 1.0)
		var w := font_px.get_string_size(banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		hud_draw.draw_string(font_px, Vector2(vs.x / 2 - w / 2, vs.y * 0.2), banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(C_GOLD, al))
	if speed == 0:
		hud_draw.draw_string(font_px, Vector2(vs.x / 2 - 60, 100), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, C_GOLD)


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
