extends PanelContainer
## Tab registry and economy flow keys keep presentation separate from simulation.
const TABS := {"overview": "Overview", "rice": "Spirit rice", "people": "People", "work": "Work & fields", "chronicle": "Chronicle"}
const INK := Color("493423")
const GOLD := Color("a57927")
var view: Node2D
var life: Node2D
var current := "overview"
var content: VBoxContainer
var timer := 0.0
var people_filter := "All"
var sort_column := 0
var sort_reverse := false
var year_filter := 0
var tree: Tree
var rice_chip: Button
var people_chip: Button
var clock: Label
var granary_card: PanelContainer
var hud_timer := 0.0
var icons: Dictionary = {}

static func amount(rations: float) -> String:
	var digits := str(absi(roundi(rations * 2.0)))
	var result := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return ("−" if rations < 0 else "") + result

static func skin(file: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load("res://assets/ui/kenney-rpg/" + file + ".png")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 8)
		box.set_content_margin(side, 10)
	return box

func icon(kind: String) -> Texture2D:
	if icons.has(kind):
		return icons[kind]
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var brown := Color("79532e")
	for y in 24:
		for x in 24:
			var mark := false
			match kind:
				"rice": mark = (y >= 9 and y <= 20 and x >= 5 and x <= 18 and absf(x - 11.5) < 7 - absf(y - 15) * 0.35) or (y in [5, 6] and x >= 8 and x <= 15)
				"people": mark = Vector2(x - 8, y - 6).length() < 4 or Vector2(x - 17, y - 8).length() < 3 or (y > 11 and y < 21 and x > 3 and x < 12) or (y > 13 and y < 21 and x > 13 and x < 21)
				"work": mark = (x in [11, 12] and y > 4 and y < 22) or (y in [5, 6, 7] and x > 4 and x < 21) or (y == 21 and x > 3 and x < 21)
				_: mark = (x in [5, 18] and y > 3 and y < 21) or (y in [4, 20] and x > 4 and x < 19) or (y in [9, 13, 17] and x > 8 and x < 16)
			if mark:
				image.set_pixel(x, y, brown)
	icons[kind] = ImageTexture.create_from_image(image)
	return icons[kind]

func setup(ground_view: Node2D) -> void:
	view = ground_view
	life = view.map.life
	var parchment := Theme.new()
	var body_font := FontVariation.new()
	body_font.base_font = load("res://assets/fonts/Lato-Bold.ttf")
	body_font.opentype_features = {"tnum": 1}
	parchment.default_font = body_font
	parchment.default_font_size = 16
	for type: String in ["Label", "Button", "CheckBox", "Tree", "OptionButton"]:
		parchment.set_color("font_color", type, INK)
		parchment.set_color("font_hover_color", type, INK)
		parchment.set_color("font_pressed_color", type, INK)
	parchment.set_stylebox("panel", "PanelContainer", skin("panel_beige"))
	parchment.set_stylebox("panel", "Tree", skin("panelInset_beigeLight"))
	for state: String in ["normal", "hover", "focus", "disabled"]:
		var button_skin := skin("buttonLong_brown")
		button_skin.set_content_margin(SIDE_LEFT, 5)
		button_skin.set_content_margin(SIDE_RIGHT, 5)
		parchment.set_stylebox(state, "Button", button_skin)
	parchment.set_stylebox("pressed", "Button", skin("buttonLong_brown_pressed"))
	view.hud.add_child(self)
	theme = parchment
	_build_hud(parchment)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.14
	anchor_right = 0.86
	anchor_top = 0.14
	anchor_bottom = 0.88
	var book := HBoxContainer.new()
	add_child(book)
	var tabs := VBoxContainer.new()
	tabs.custom_minimum_size.x = 180
	book.add_child(tabs)
	label(tabs, "VILLAGE\nLEDGER", true)
	for key: String in TABS:
		var tab := button(tabs, TABS[key], func() -> void: open_tab(key))
		tab.icon = icon(key)
	button(tabs, "Close [Esc / L]", close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	hide()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ledger="):
			open_tab(arg.trim_prefix("--ledger="))

func label(parent: Node, text: String, heading: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if heading:
		node.add_theme_font_override("font", load("res://assets/fonts/NotoSerifDisplay-Bold.ttf"))
		node.add_theme_font_size_override("font_size", 23)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func _build_hud(parchment: Theme) -> void:
	var panel := PanelContainer.new()
	panel.theme = parchment
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	view.hud.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	view.place = label(row, "Servants' Village")
	view.place.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.place.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rice_chip = button(row, "", func() -> void: open_tab("rice"))
	rice_chip.icon = icon("rice")
	people_chip = button(row, "", func() -> void: open_tab("people"))
	people_chip.icon = icon("people")
	clock = label(row, "")
	clock.autowrap_mode = TextServer.AUTOWRAP_OFF
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(row, "Ⅱ", func() -> void: life.paused = not life.paused).tooltip_text = "Pause [Space]"
	for speed: int in [1, 4, 16, 64, 256, 1024, 4096]:
		button(row, "%dx" % speed, func() -> void: life.speed = speed)
	var index := 1
	for key: String in TABS:
		var b := button(row, ["Overview", "Rice", "People", "Work", "Chronicle"][index - 1], func() -> void: toggle_tab(key))
		b.icon = icon(key)
		b.tooltip_text = "%s [F%d]" % [TABS[key], index]
		index += 1
	button(row, "World map [M]", view.map.show_map)
	granary_card = PanelContainer.new()
	granary_card.theme = parchment
	granary_card.position = Vector2(24, 90)
	granary_card.custom_minimum_size.x = 460
	granary_card.size.x = 460
	view.hud.add_child(granary_card)
	granary_card.hide()

func close() -> void:
	hide()

func toggle_tab(key: String) -> void:
	if visible and current == key:
		close()
	else:
		open_tab(key)

func open_tab(key: String) -> void:
	current = key if TABS.has(key) else "overview"
	show()
	refresh()

func _process(dt: float) -> void:
	hud_timer += dt
	if hud_timer >= 0.3 and view.active:
		hud_timer = 0.0
		var e: RefCounted = life.economy
		rice_chip.text = "%s jin · %d d" % [amount(e.stock), floori(e.days_left())]
		rice_chip.modulate = Color("f29b79") if e.days_left() < 7 else (Color("e9bd66") if e.days_left() < 30 else Color.WHITE)
		rice_chip.tooltip_text = "Spirit rice · Granary\n%s jin (斤) · %.1f days\nDaily need: %s jin · Ration: %d%%\nExpected harvest: %s jin\n1 ration = 2 jin" % [amount(e.stock), e.days_left(), amount(e.daily_need()), roundi(e.ration() * 100), amount(e.forecast())]
		people_chip.text = "%d · %d hungry" % [life.people.size(), e.hungry_count]
		clock.text = life.clock_text()
	if not visible:
		return
	timer += dt
	if timer >= 0.5:
		timer = 0.0
		refresh_values()

func refresh() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	label(content, TABS[current], true)
	if current == "people":
		var filters := HBoxContainer.new()
		content.add_child(filters)
		button(filters, "All", func() -> void: people_filter = "All"; refresh_values())
		button(filters, "Hungry", func() -> void: people_filter = "Hungry"; refresh_values())
		var choices := OptionButton.new()
		var jobs: Array[String] = ["All", "Hungry"]
		for p: Dictionary in life.people:
			if not p.job in jobs:
				jobs.append(p.job)
		for job: String in jobs:
			choices.add_item(job)
		choices.select(maxi(0, jobs.find(people_filter)))
		filters.add_child(choices)
		choices.item_selected.connect(func(i: int) -> void: people_filter = jobs[i]; refresh_values())
	elif current == "chronicle":
		var years := OptionButton.new()
		years.add_item("All years", 0)
		for y in range(1, life.economy.year + 1):
			years.add_item("Year %d" % y, y)
		years.select(year_filter)
		content.add_child(years)
		years.item_selected.connect(func(i: int) -> void: year_filter = i; refresh_values())
	refresh_values()

func refresh_values() -> void:
	# Keep filter controls and scroll position stable while replacing only data.
	for child: Node in content.get_children():
		if child.has_meta("data"):
			content.remove_child(child)
			child.queue_free()
	var data := VBoxContainer.new()
	data.set_meta("data", true)
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.add_theme_constant_override("separation", 12)
	content.add_child(data)
	var e: RefCounted = life.economy
	match current:
		"overview":
			label(data, "%d villagers · %d hungry\nSpirit rice in the Granary: %s jin · %.1f days\nRation level: %d%% · Daily need: %s jin\nHarvest forecast: %s jin · This year's balance: %s jin\n%s · %s" % [life.people.size(), e.hungry_count, amount(e.stock), e.days_left(), roundi(e.ration() * 100), amount(e.daily_need()), amount(e.forecast()), amount(e.produced - e.consumed - e.spoiled), e.SEASONS[e.season()], stage()])
			var alerts := "Alerts: "
			alerts += "Low spirit rice. " if e.days_left() < 30 else ""
			alerts += "Rationing active. " if e.ration() < 1 else ""
			alerts += "%d villagers hungry." % e.hungry_count if e.hungry_count else ""
			label(data, alerts if alerts != "Alerts: " else "Alerts: village supplied")
			var crisis := CheckBox.new()
			crisis.text = "Pause on crisis"
			crisis.button_pressed = e.pause_on_crisis
			crisis.toggled.connect(func(value: bool) -> void: e.pause_on_crisis = value)
			data.add_child(crisis)
			label(data, "Latest chronicle", true)
			for i in range(e.chronicle.size() - 1, maxi(-1, e.chronicle.size() - 6), -1):
				label(data, e.chronicle[i])
		"rice": _rice(data, e)
		"people": _people(data)
		"work": _work(data, e)
		"chronicle":
			var header := ""
			for i in range(e.chronicle.size() - 1, -1, -1):
				var entry: String = e.chronicle[i]
				if year_filter > 0 and not entry.begins_with("Y%d " % year_filter):
					continue
				var season_header := entry.get_slice(":", 0)
				if season_header != header:
					header = season_header
					label(data, header, true)
				label(data, entry)
			if e.chronicle.is_empty():
				label(data, "No events recorded yet.")

func stage() -> String:
	return ["Planting", "Tending", "Harvest", "Fallow"][life.economy.season()]

func table(parent: Node, headers: Array, rows: Array, height: float = 200) -> Tree:
	var widget := Tree.new()
	widget.columns = headers.size()
	widget.hide_root = true
	widget.column_titles_visible = true
	widget.custom_minimum_size.y = height
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in headers.size():
		widget.set_column_title(i, headers[i])
		widget.set_column_expand(i, true)
	var root := widget.create_item()
	for row: Array in rows:
		var item := widget.create_item(root)
		for i in row.size():
			item.set_text(i, str(row[i]))
			if i > 0:
				item.set_text_alignment(i, HORIZONTAL_ALIGNMENT_RIGHT)
	parent.add_child(widget)
	return widget

func _rice(parent: Node, e: RefCounted) -> void:
	label(parent, "Spirit rice · 斤 (jin) · 1 ration = 2 jin", true)
	var standing: float = e.harvest if e.season() == 2 else (e.forecast() if e.season() < 2 else 0.0)
	label(parent, "Where it is now\nGranary: %s jin\nStanding in the paddies: %s jin %s\nBeing carried: 0 jin · credited directly to the Granary at day end\nTotal stored + standing: %s jin" % [amount(e.stock), amount(standing), "(expected yield)" if e.season() < 2 else "(unharvested)", amount(e.stock + standing)])
	var rows: Array = []
	for key: String in {"harvested": "Harvested in", "adults": "Eaten by adults", "children": "Eaten by children", "foraged": "Foraged wild provisions (separate)", "spoiled": "Spoiled", "delivered": "Delivered to sect · not yet", "sold": "Sold · not yet", "bought": "Bought · not yet"}:
		var names := {"harvested": "Harvested in", "adults": "Eaten by adults", "children": "Eaten by children", "foraged": "Foraged wild provisions (not rice)", "spoiled": "Spoiled", "delivered": "Delivered to sect · not yet", "sold": "Sold · not yet", "bought": "Bought · not yet"}
		var row: Array = [names[key]]
		for value: float in e.flow_values(key):
			row.append(amount(value))
		rows.append(row)
	var flows_table := table(parent, ["Flows · jin", "Today", "This season", "This year", "All time"], rows, 275)
	flows_table.set_column_custom_minimum_width(0, 310)
	for i in range(5, 8):
		var item := flows_table.get_root().get_child(i)
		for col in 5:
			item.set_custom_color(col, Color("8b7c68"))
	var children := 0
	for p: Dictionary in life.people:
		if int(p.kind) == 8:
			children += 1
	label(parent, "Need\n%d adults × 2 jin + %d children × 1 jin = %s jin daily\nCurrent ration: %d%% · %.1f days left\nNext harvest begins in %d days · projected stock then: %s jin (before spoilage; current ration held constant)" % [life.people.size() - children, children, amount(e.daily_need()), roundi(e.ration() * 100), e.days_left(), e.days_to_harvest(), amount(maxf(0, e.stock - e.daily_need() * e.ration() * e.days_to_harvest()))])
	label(parent, "Harvest forecast\nPaddy area: %d tiles = %d mu · base yield: %.2f jin / mu\nField care so far: %.1f%% · weather: %.2f (%s)\nExpected harvest: %s jin" % [e.field_area, e.field_area, 16000.0 / 3300.0, e.care() * 100, e.weather, "poor" if e.weather < 0.8 else ("good" if e.weather > 1.02 else "fair"), amount(e.forecast())])
	var chart := preload("res://src/ledger_chart.gd").new()
	chart.custom_minimum_size.y = 230
	chart.caption = "Granary stock · last two years"
	chart.samples = e.stock_history.duplicate()
	for i in chart.samples.size():
		chart.samples[i].y *= 2.0
	chart.samples.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	parent.add_child(chart)
	var annual := preload("res://src/ledger_chart.gd").new()
	annual.custom_minimum_size.y = 200
	annual.caption = "Harvest per completed year"
	annual.bars = true
	annual.samples = e.harvest_history.duplicate()
	annual.samples.append(Vector2(e.year, e.produced))
	for i in annual.samples.size():
		annual.samples[i].y *= 2.0
	annual.caption = "Harvest by year · current year to date"
	parent.add_child(annual)

func _people(parent: Node) -> void:
	var residents: Array[Dictionary] = []
	for p: Dictionary in life.people:
		if people_filter == "Hungry" and int(p.hunger) == 0:
			continue
		if people_filter not in ["All", "Hungry"] and people_filter != p.job:
			continue
		residents.append(p)
	var keys := ["name", "age", "sex", "job", "home_cottage", "hunger", "rice_today", "activity"]
	residents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a[keys[sort_column]] > b[keys[sort_column]] if sort_reverse else a[keys[sort_column]] < b[keys[sort_column]])
	var rows: Array = []
	for p: Dictionary in residents:
		rows.append([p.name, p.age, p.sex, p.job, "Cottage %d" % (int(p.home_cottage) / 8 + 1), life.economy.HUNGER[int(p.hunger)], "%.1f jin" % (float(p.rice_today) * 2), life.activity_text(p)])
	tree = table(parent, ["Name", "Age", "Sex", "Job", "Home", "Hunger", "Rice today", "Activity"], rows, 620)
	tree.set_column_custom_minimum_width(0, 155)
	tree.set_column_custom_minimum_width(7, 200)
	for i in residents.size():
		var item := tree.get_root().get_child(i)
		item.set_metadata(0, life.people.find(residents[i]))
		item.set_custom_color(5, Color("a23522") if int(residents[i].hunger) > 0 else Color("49612e"))
	tree.column_title_clicked.connect(func(col: int, _mouse: int) -> void:
		sort_reverse = not sort_reverse if sort_column == col else false
		sort_column = col
		refresh_values())
	tree.item_selected.connect(func() -> void:
		life.followed = int(tree.get_selected().get_metadata(0))
		close())
	label(parent, "Click a villager to follow them. Click column headings to sort.")

func _work(parent: Node, e: RefCounted) -> void:
	var jobs: Dictionary = {}
	for p: Dictionary in life.people:
		if not jobs.has(p.job):
			jobs[p.job] = []
		jobs[p.job].append(p)
	var rows: Array = []
	for job: String in jobs:
		var names := PackedStringArray()
		var effectiveness := 0.0
		for p: Dictionary in jobs[job]:
			names.append(p.name)
			effectiveness += e.EFFECT[int(p.hunger)]
		rows.append([job, jobs[job].size(), ", ".join(names), "%d%%" % roundi(effectiveness / jobs[job].size() * 100)])
	var jobs_table := table(parent, ["Job", "Count", "Names", "Today's effectiveness"], rows, 310)
	jobs_table.set_column_custom_minimum_width(2, 500)
	label(parent, "Year %d farm calendar · today: day %d\nSpring 1–91: Planting  →  Summer 92–182: Tending  →  Autumn 183–273: Harvest  →  Winter 274–365: Fallow\n▼ Today: %s · %s" % [e.year, e.day, e.SEASONS[e.season()], stage()], true)
	var bar := ProgressBar.new()
	bar.max_value = 365
	bar.value = e.day
	bar.show_percentage = false
	bar.custom_minimum_size.y = 22
	bar.add_theme_stylebox_override("background", skin("barBack_horizontalMid"))
	bar.add_theme_stylebox_override("fill", skin("barYellow_horizontalMid"))
	parent.add_child(bar)
	rows = []
	var index := 1
	for field: Dictionary in life.sect.data.fields:
		var area := int(field.rect[2]) * int(field.rect[3])
		rows.append(["Paddy %d" % index, "%d tiles / mu" % area, stage(), "%d%%" % roundi(e.care() * 100), "%s jin" % amount(e.forecast() * area / e.field_area)])
		index += 1
	table(parent, ["Plot", "Area", "Stage", "Care", "Expected yield"], rows, 320)

func show_granary() -> void:
	for child: Node in granary_card.get_children():
		granary_card.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	granary_card.add_child(box)
	label(box, "Granary · %s jin of spirit rice · %d days" % [amount(life.economy.stock), floori(life.economy.days_left())])
	button(box, "Open ledger", func() -> void: granary_card.hide(); open_tab("rice"))
	button(box, "Close", granary_card.hide)
	granary_card.show()
