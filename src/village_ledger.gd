extends PanelContainer
## The valley book: a centred page over the dimmed world, opened from the thin top bar.
## Tab registry and economy flow keys keep presentation separate from simulation.
class LedgerButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		var tip := Label.new()
		tip.text = for_text
		tip.custom_minimum_size.x = minf(448, get_viewport_rect().size.x - 32)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return tip

const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const Law = preload("res://src/law.gd")
const TABS := {"cultivators": "Cultivators", "tempering": "Paths & realms", "medicine": "Medicine & methods", "fifty": "The Fifty", "laws": "Laws & guardians", "people": "Everyone", "society": "Families & factions", "chronicle": "Chronicle", "overview": "Overview", "food": "Food", "materials": "Materials & work", "forest": "Forest & beasts", "bestiary": "Bestiary"}
const GROUPS := {"Cultivation": ["cultivators", "tempering", "medicine"], "Heaven": ["fifty", "laws"], "People": ["people", "society", "chronicle"], "The valley": ["overview", "food", "materials"], "The wild": ["forest", "bestiary"]}
var sidebar: VBoxContainer
var sections_button: MenuButton

const INK := Palette.INK
const GOLD := Palette.BRASS
const MAX_WIDTH := 1320.0
var selected_work := ""
var selected_food := ""
var food_path: Array[String] = ["food"]
var food_grid: GridContainer
var drawer_scroll: ScrollContainer
var closing := false
var slide: Tween
var view: Node2D
var life: Node2D
var current := "cultivators"
var content: VBoxContainer
var timer := 0.0
var people_browser: VBoxContainer
var year_filter := 0
var tab_buttons: Dictionary = {}
var dim: ColorRect
const SPEEDS: Array[int] = [1, 4, 16, 64, 256, 1024, 4096]
var top_bar: PanelContainer
var food_chip: Button
var alert_row: HBoxContainer
var people_button: Button
var tour_button: Button
var map_button: Button
var pause_button: Button
var page_day := -1
var society_offset := 0
var skip_progress: ProgressBar
var speed_selector: OptionButton
var ledger_button: Button
var clock: Label
var hud_timer := 0.0
var icons: Dictionary = {}
var alerts_day := -1
var alerts: Array = []
var living := 0

static func amount(rations: float) -> String:
	var digits := str(absi(roundi(rations * 2.0)))
	var result := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return ("−" if rations < 0 else "") + result

func icon(kind: String) -> Texture2D:
	if icons.has(kind):
		return icons[kind]
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 24:
		for x in 24:
			var mark := false
			match kind:
				"people": mark = Vector2(x - 8, y - 6).length() < 4 or Vector2(x - 17, y - 8).length() < 3 or (y > 11 and y < 21 and x > 3 and x < 12) or (y > 13 and y < 21 and x > 13 and x < 21)
				_: mark = (x in [5, 18] and y > 3 and y < 21) or (y in [4, 20] and x > 4 and x < 19) or (y in [9, 13, 17] and x > 8 and x < 16)
			if mark:
				image.set_pixel(x, y, Palette.INK_SOFT)
	icons[kind] = ImageTexture.create_from_image(image)
	return icons[kind]

func setup(ground_view: Node2D) -> void:
	view = ground_view
	life = view.map.life
	dim = ColorRect.new()
	dim.color = Color(Palette.INK, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close())
	dim.hide()
	view.ui.add_child(dim)
	view.ui.add_child(self)
	mouse_force_pass_scroll_events = false
	_build_hud()
	get_viewport().size_changed.connect(func() -> void:
		_layout()
		if visible: refresh.call_deferred())
	_layout()
	var book := VBoxContainer.new()
	add_child(book)
	var top := HBoxContainer.new()
	book.add_child(top)
	sections_button = MenuButton.new()
	sections_button.text = "Sections ▾"
	top.add_child(sections_button)
	for group: String in GROUPS:
		sections_button.get_popup().add_separator(group)
		for key: String in GROUPS[group]:
			sections_button.get_popup().add_item(TABS[key], TABS.keys().find(key))
	sections_button.get_popup().id_pressed.connect(func(id: int) -> void: open_tab(TABS.keys()[id]))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	button(top, "Esc ✕", close)
	var pages := HBoxContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation", UiTheme.SPACE_24)
	book.add_child(pages)
	sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 208
	pages.add_child(sidebar)
	for group: String in GROUPS:
		small(sidebar, group)
		for key: String in GROUPS[group]:
			var tab := button(sidebar, TABS[key], func() -> void: open_tab(key))
			tab.theme_type_variation = "Chip"
			tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
			tab.toggle_mode = true
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab_buttons[key] = tab
	var scroll := ScrollContainer.new()
	drawer_scroll = scroll
	scroll.mouse_force_pass_scroll_events = false
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pages.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UiTheme.SPACE_8)
	scroll.add_child(content)
	hide()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ledger="):
			open_tab(arg.trim_prefix("--ledger="))

## The book is centred and never wider than a comfortable reading width.
func _layout() -> void:
	var screen := get_viewport_rect().size
	var width := minf(MAX_WIDTH, screen.x - 96)
	if is_instance_valid(sidebar): sidebar.visible = screen.x >= 1450
	if is_instance_valid(sections_button): sections_button.visible = screen.x < 1450
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = floorf((screen.x - width) / 2.0)
	offset_right = -offset_left
	offset_top = 68
	offset_bottom = -20

## Usable width inside the page, for tables and grids.
func content_width() -> float:
	return minf(MAX_WIDTH, get_viewport_rect().size.x - 96) - 72 - (232 if get_viewport_rect().size.x >= 1450 else 0)

func label(parent: Node, text: String, heading: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if heading:
		node.theme_type_variation = "Title"
	parent.add_child(node)
	return node

func small(parent: Node, text: String) -> Label:
	var node := label(parent, text)
	node.theme_type_variation = "Small"
	return node

func button(parent: Node, text: String, action: Callable) -> Button:
	var node := LedgerButton.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func _build_hud() -> void:
	top_bar = PanelContainer.new()
	top_bar.theme_type_variation = "Bar"
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	view.ui.add_child(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.SPACE_8)
	top_bar.add_child(row)
	var location := VBoxContainer.new()
	location.custom_minimum_size.x = 200
	location.add_theme_constant_override("separation", -2)
	row.add_child(location)
	view.place = label(location, "Servants' Village", true)
	view.place.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.place.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	clock = small(location, "")
	clock.autowrap_mode = TextServer.AUTOWRAP_OFF
	food_chip = button(row, "", func() -> void: open_tab("food"))
	food_chip.theme_type_variation = "Chip"
	food_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alert_row = HBoxContainer.new()
	alert_row.add_theme_constant_override("separation", UiTheme.SPACE_8)
	row.add_child(alert_row)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	pause_button = button(row, "Ⅱ", func() -> void: life.paused = not life.paused; _refresh_hud())
	pause_button.custom_minimum_size.x = 36
	pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_selector = OptionButton.new()
	speed_selector.custom_minimum_size.x = 92
	speed_selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_selector.fit_to_longest_item = false
	for speed: int in SPEEDS:
		speed_selector.add_item("%dx" % speed)
	for years: int in [1, 10, 100]: speed_selector.add_item("Skip %d years" % years)
	speed_selector.add_item("Cancel skip")
	speed_selector.item_selected.connect(func(index: int) -> void:
		if index < SPEEDS.size(): life.speed = SPEEDS[index]
		elif index < SPEEDS.size() + 3: life.start_skip([1, 10, 100][index - SPEEDS.size()])
		else: life.cancel_skip()
		_refresh_hud())
	speed_selector.tooltip_text = "Speed [1–7], skip years, or cancel a skip · Space pauses"
	row.add_child(speed_selector)
	skip_progress = ProgressBar.new()
	skip_progress.custom_minimum_size = Vector2(90, 10)
	skip_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skip_progress.show_percentage = false
	skip_progress.hide()
	row.add_child(skip_progress)
	people_button = button(row, "", func() -> void: open_tab("people"))
	people_button.theme_type_variation = "Chip"
	people_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tour_button = button(row, "Tour", func() -> void: view.tour.start())
	tour_button.tooltip_text = "A guided walk through the valley, ten stops"
	tour_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ledger_button = button(row, "Valley book [L]", func() -> void:
		if visible and not closing:
			close()
		else:
			open_tab(current))
	ledger_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	map_button = button(row, "World map [M]", view.map.show_map)
	map_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_refresh_hud()

func close() -> void:
	if not visible:
		return
	closing = true
	if slide:
		slide.kill()
	slide = create_tween()
	slide.tween_property(self, "modulate:a", 0.0, 0.12)
	slide.tween_callback(func() -> void:
		hide()
		dim.hide())

func toggle_tab(key: String) -> void:
	key = "food" if key == "rice" else key
	if visible and not closing and current == key.get_slice("/", 0):
		close()
	else:
		open_tab(key)

func open_tab(key: String) -> void:
	key = "food" if key == "rice" else key
	if not visible or closing:
		closing = false
		if slide:
			slide.kill()
		modulate.a = 0.0
		slide = create_tween()
		slide.tween_property(self, "modulate:a", 1.0, 0.14)
	if key.begins_with("food") or key.begins_with("materials"):
		food_path = ["materials" if key.begins_with("materials") else "food"]
		selected_food = ""
		for part: String in key.split("/").slice(1):
			for category: Dictionary in life.economy.catalogue.categories:
				if category.id == part and category.parent == food_path[-1]:
					food_path.append(part)
		key = food_path[0]
	current = key if TABS.has(key) or key == "work" else "cultivators"
	for tab: String in tab_buttons:
		tab_buttons[tab].set_pressed_no_signal(tab == current)
	_layout()
	dim.show()
	show()
	refresh()
	drawer_scroll.scroll_vertical = 0

## Opens someone's page in the book, on one of the person tabs.
func open_person(person: int, tab: String = "Story") -> void:
	open_tab("people")
	people_browser.person = person
	people_browser.person_tab = tab
	people_browser.redraw()

func _process(dt: float) -> void:
	hud_timer += dt
	if hud_timer >= 0.3 and view.active:
		hud_timer = 0.0
		_refresh_hud()
	if not visible:
		return
	timer += dt
	if timer >= 0.5:
		timer = 0.0
		refresh_values()

func _food_tooltip(id: String, depth: int) -> String:
	var e: RefCounted = life.economy
	var title := id.capitalize()
	for category: Dictionary in e.catalogue.categories:
		if category.id == id:
			title = category.name
	var text := "%s%s: %s jin" % ["  ".repeat(depth), title, amount(e.quantity(id))]
	for category: Dictionary in e.catalogue.categories:
		if category.parent == id:
			text += "\n" + _food_tooltip(category.id, depth + 1)
	for good: String in e.goods:
		if e.goods[good].category_path[-1] == id:
			text += "\n%s%s: %s jin" % ["  ".repeat(depth + 1), e.goods[good].name, amount(e.stocks[good])]
	return text

## Things worth a look right now, worst first: [words, hot, where it leads].
func _compute_alerts() -> void:
	var population: RefCounted = life.population
	if alerts_day == population.day:
		return
	alerts_day = population.day
	alerts = []
	var society: RefCounted = population.society
	living = 0
	var at_gate := 0
	for p in population.size():
		if not society.alive[p]: continue
		living += 1
		if society.temper and society.temper.at_gate(p): at_gate += 1
	var e: RefCounted = life.economy
	if e.hungry_count > 0:
		alerts.append(["%d hungry" % e.hungry_count, true, "people"])
	if at_gate > 0:
		alerts.append(["%d at a gate" % at_gate, at_gate >= 3, "tempering"])
	if society.temper:
		var summary: Dictionary = society.temper.summary()
		var wild: Dictionary = summary.wild
		var wanting: Dictionary = summary.wanting
		var supply := {"iron_bark": float(wild.bark_in_patches) / 4.0, "beast_marrow": float(wild.herd) * 0.25, "seven_leaf": float(wild.herbs)}
		var short_names := {"iron_bark": "iron-bark", "beast_marrow": "beast marrow", "seven_leaf": "seven-leaf"}
		for id: String in wanting:
			if float(wanting[id]) > float(supply.get(id, 0.0)):
				alerts.append(["%s tight" % short_names.get(id, id), false, "forest"])
	if society.wanderer_present:
		alerts.append(["wanderer on the West Road", false, "tempering"])

func _refresh_hud() -> void:
	if is_instance_valid(skip_progress):
		skip_progress.visible = life.skip_target > 0
		if life.skip_target > 0:
			skip_progress.value = 100.0 * (life.population.day - life.skip_start) / maxi(1, life.skip_target - life.skip_start)
	var e: RefCounted = life.economy
	_compute_alerts()
	var narrow := get_viewport_rect().size.x < 1500
	var days := floori(e.days_left())
	food_chip.text = "food %d d" % days
	food_chip.theme_type_variation = "Hot" if days < 7 else "Chip"
	var totals := "Food for %d days at today's ration.\nNext harvest leaves about %.0f days.\nMortal meals: %s jin" % [days, e.after_harvest_days(), amount(e.mortal_food())]
	for group: String in ["grains", "vegetables", "fruit", "meat", "fish", "pantry"]:
		totals += "\n%s: %s jin" % [food_title(group), amount(e.quantity(group))]
	food_chip.tooltip_text = totals
	var shown := alerts.slice(0, 2 if narrow else 3)
	while alert_row.get_child_count() < shown.size():
		var chip := button(alert_row, "", func() -> void: pass)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in alert_row.get_child_count():
		var chip: Button = alert_row.get_child(i)
		chip.visible = i < shown.size()
		if not chip.visible: continue
		var alert: Array = shown[i]
		chip.text = alert[0]
		chip.theme_type_variation = "Hot" if alert[1] else "Chip"
		chip.set_meta("target", alert[2])
		for connection: Dictionary in chip.pressed.get_connections():
			chip.pressed.disconnect(connection.callable)
		var target: String = alert[2]
		chip.pressed.connect(func() -> void: open_tab(target))
	people_button.text = "%d people" % living
	people_button.tooltip_text = "%d living · %d hungry · open the People page" % [living, e.hungry_count]
	ledger_button.text = "Book [L]" if narrow else "Valley book [L]"
	map_button.text = "Map [M]" if narrow else "World map [M]"
	clock.text = life.clock_text().get_slice(" · ", 1) + " · " + life.clock_text().get_slice(" · ", 2) if narrow else life.clock_text()
	pause_button.text = "▶" if life.paused else "Ⅱ"
	pause_button.tooltip_text = ("Resume" if life.paused else "Pause") + " [Space]"
	speed_selector.select(SPEEDS.find(int(life.speed)))

func refresh() -> void:
	page_day = -1
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var heading := label(content, TABS.get(current, "Materials & work"))
	heading.theme_type_variation = "Heading"
	if current == "chronicle":
		var years := OptionButton.new()
		years.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		years.add_item("All years", 0)
		for y in range(1, life.economy.year + 1):
			years.add_item("Year %d" % y, y)
		years.select(year_filter)
		content.add_child(years)
		years.item_selected.connect(func(i: int) -> void: year_filter = i; refresh_values())
	refresh_values()

func refresh_values() -> void:
	if current in ["society", "tempering", "forest", "chronicle", "bestiary", "laws"] and page_day == life.population.day: return
	if current in ["people", "cultivators"] and is_instance_valid(people_browser) and people_browser.is_inside_tree(): return
	# Keep filter controls and scroll position stable while replacing only data.
	for child: Node in content.get_children():
		if child.has_meta("data"):
			content.remove_child(child)
			child.queue_free()
	var data := VBoxContainer.new()
	data.set_meta("data", true)
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.add_theme_constant_override("separation", UiTheme.SPACE_16)
	content.add_child(data)
	var e: RefCounted = life.economy
	_summary(data)
	match current:
		"overview": _overview(data, e)
		"food": _food(data, e)
		"materials":
			_food(data, e)
			_work(data, e)
		"people", "cultivators": _people(data)
		"tempering": _tempering(data)
		"medicine": _medicine(data)
		"fifty": label(data, "Raising the Fifty: coming soon")
		"forest": _forest(data)
		"society": _society(data)
		"work": _work(data, e)
		"chronicle": _chronicle(data, e)
		"bestiary": _bestiary(data)
		"laws": _laws(data)
	_group_cards(data)

## Each titled section gets whitespace and its own parchment card.
func _group_cards(data: VBoxContainer) -> void:
	var box: VBoxContainer
	for child: Node in data.get_children().slice(1):
		if child is HSeparator:
			child.queue_free()
			continue
		if box == null or (child is Label and child.theme_type_variation == "Title"):
			var card := PanelContainer.new()
			card.theme_type_variation = "CardPanel"
			data.add_child(card)
			box = VBoxContainer.new()
			box.add_theme_constant_override("separation", UiTheme.SPACE_12)
			card.add_child(box)
		child.reparent(box)

func stage() -> String:
	return ["Planting", "Tending", "Harvest", "Fallow"][life.economy.season()]

func table(parent: Node, headers: Array, rows: Array, _height: float = 200) -> Tree:
	var widget := Tree.new()
	widget.columns = headers.size()
	widget.hide_root = true
	widget.column_titles_visible = true
	widget.custom_minimum_size.y = maxf(60, (rows.size() + 1) * 30)
	widget.scroll_vertical_enabled = false
	widget.scroll_horizontal_enabled = false
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var available := maxf(400, content_width() - 16)
	var widths: Array[int] = []
	for i in headers.size():
		var share := (0.32 if i == 0 else 0.68 / (headers.size() - 1)) if headers.size() > 2 else 0.5
		widths.append(int(available * share))
		widget.set_column_title(i, headers[i])
		widget.set_column_expand(i, false)
		widget.set_column_custom_minimum_width(i, widths[i])
	var root := widget.create_item()
	var font := UiTheme.body()
	for row: Array in rows:
		var item := widget.create_item(root)
		for i in row.size():
			var text := str(row[i])
			item.set_tooltip_text(i, text)
			var limit: int = widths[i] - 16
			var numeric := text.replace(",", "").replace("−", "-")
			if numeric.is_valid_float() and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.BODY).x > limit:
				var value := float(numeric)
				text = "%.1fm" % (value / 1000000.0) if absf(value) >= 1000000 else "%.1fk" % (value / 1000.0)
			while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.BODY).x > limit and text.length() > 1:
				text = text.left(text.length() - 2) + "…"
			item.set_text(i, text)
			if i > 0 and headers[i] not in ["Job", "Fare", "Activity", "Status", "Crop", "Stage"]:
				item.set_text_alignment(i, HORIZONTAL_ALIGNMENT_RIGHT)
	parent.add_child(widget)
	return widget

func _food(parent: Node, e: RefCounted) -> void:
	var crumbs := HBoxContainer.new()
	parent.add_child(crumbs)
	for index in food_path.size():
		var at := index
		if index > 0:
			var arrow := label(crumbs, "›")
			arrow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
		var crumb := button(crumbs, food_title(food_path[index]), func() -> void:
			food_path.resize(at + 1)
			selected_food = ""
			refresh_values())
		crumb.theme_type_variation = "Chip"
	food_grid = GridContainer.new()
	food_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(food_grid)
	food_grid.columns = maxi(1, int(content_width() / 128))
	food_grid.resized.connect(func() -> void:
		food_grid.columns = maxi(1, int(food_grid.size.x / 128)))
	for category: Dictionary in e.catalogue.categories:
		if category.parent == food_path[-1]:
			food_slot(category.id, category.name, false, e)
	for good: String in e.goods:
		if e.goods[good].category_path[-1] == food_path[-1]:
			food_slot(good, e.goods[good].name, true, e)
	if food_grid.get_child_count() == 0:
		label(parent, "No provisions recorded in this category.")
	if selected_food.is_empty():
		return
	var id := selected_food
	var is_good: bool = e.goods.has(id)
	label(parent, e.goods[id].name if is_good else id.capitalize(), true)
	if is_good:
		var g: Dictionary = e.goods[id]
		label(parent, g.description)
		if g.has("recipe"):
			var ingredients: Array[String] = []
			for ingredient: String in g.recipe:
				ingredients.append("%s %s" % [str(g.recipe[ingredient]), e.goods[ingredient].name])
			label(parent, "Recipe ratio: " + ", ".join(ingredients))
		if g.get("gather_days", []).size() == 2:
			label(parent, "Harvest days %d–%d · late summer" % [int(g.gather_days[0]), int(g.gather_days[1])])
		label(parent, "Source: %s\nSeason: %s\nStore: %s · Spoilage each season: %d%%\nUnit: %s" % [g.get("source", "Sect fields"), ", ".join(g.get("seasons", ["Autumn"])), g.store, roundi(float(g.seasonal_spoilage) * 100), g.unit])
	var standing := 0.0
	for good: String in e.descendants(id):
		standing += float(e.standing[good]) if e.season() == 2 else (e.good_forecast(good) if e.season() < 2 else 0.0)
	label(parent, "Stored in %s: %s %s" % [e.goods[id].store if is_good else "village stores", amount(e.quantity(id)), str(e.goods[id].unit) if is_good else "jin / pieces"])
	if standing > 0:
		label(parent, "Standing in fields: %s jin" % amount(standing))
	if not is_good:
		var breakdown := HBoxContainer.new()
		breakdown.custom_minimum_size.y = 20
		breakdown.add_theme_constant_override("separation", UiTheme.SPACE_8)
		parent.add_child(breakdown)
		var children: Array[Dictionary] = []
		for category: Dictionary in e.catalogue.categories:
			if category.parent == id:
				children.append(category)
		for good: String in e.goods:
			if e.goods[good].category_path[-1] == id:
				children.append(e.goods[good])
		for child: Dictionary in children:
			var segment := ColorRect.new()
			segment.color = Palette.tone(Color(child.get("colour", "b38a35")), Palette.THING)
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.size_flags_stretch_ratio = maxf(0.01, e.quantity(child.id))
			segment.tooltip_text = "%s: %s jin" % [child.name, amount(e.quantity(child.id))]
			breakdown.add_child(segment)

	var rows: Array = []
	var names := {"harvested": "Produced / gathered", "adults": "Adults ate", "children": "Children ate", "spoiled": "Spoiled", "processed": "Used / ingredients"}
	for key: String in names:
		var row: Array = [names[key]]
		for value: float in e.node_flow(id, key):
			row.append(amount(value))
		rows.append(row)
	table(parent, ["Flows · " + str(e.goods[id].unit) if is_good else "Flows · units", "Today", "Season", "Year", "All time"], rows, 245)
	if current == "food":
		label(parent, "Wild provisions (separate): %s jin today · %s jin this year" % [amount(e.flow_values("foraged")[0]), amount(e.flow_values("foraged")[2])])
	var edible: bool = not is_good or "mortals" in e.goods[id].edible_by
	if "grains" in (e.goods[id].category_path if is_good else [id]):
		label(parent, "Need: %s jin daily · Ration: %d%%\nDays remaining: %s · Harvest begins in %d days\nProjected stock at harvest: %s jin (before spoilage)\nForecast: %s jin · Care %.1f%% · Weather %.2f" % [amount(e.daily_need() if edible else 0.0), roundi(e.ration() * 100), "%.1f" % (e.edible_quantity(id) / e.daily_need()) if edible else "Reserved for cultivators", e.days_to_harvest(), amount(maxf(0, e.quantity(id) - (e.daily_need() * e.ration() * e.days_to_harvest() if edible else 0.0))), amount(e.good_forecast(id)), e.care() * 100, e.weather])
	else:
		label(parent, "Mortal resources supply households and crafts. Spirit materials are not gathered yet." if current == "materials" else "Fresh provisions reach the table first. The village kitchen turns autumn surpluses into winter stores.")
	if is_good:
		if "grains" in e.goods[id].category_path:
			label(parent, "Plots: %d mu · Base yield %.2f jin / mu" % [e.areas[id], float(e.goods[id].yield_rations_per_mu) * 2])
		var charts := HBoxContainer.new()
		parent.add_child(charts)
		for annual: bool in [false, true]:
			var chart := preload("res://src/ledger_chart.gd").new()
			chart.custom_minimum_size.y = 200
			chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chart.bars = annual
			chart.caption = "Yearly production" if annual else "Stock · last two years"
			chart.unit = str(e.goods[id].unit)
			chart.samples.assign(e.annual_histories[id] if annual else e.histories[id])
			if annual:
				chart.samples.append(Vector2(e.year, e.node_flow(id, "harvested")[2]))
			for i in chart.samples.size():
				chart.samples[i].y *= 2
			charts.add_child(chart)

func food_title(id: String) -> String:
	for category: Dictionary in life.economy.catalogue.categories:
		if category.id == id:
			return category.name
	return id.capitalize()

func food_up() -> void:
	selected_food = ""
	if food_path.size() > 1:
		food_path.pop_back()
	refresh_values()

## While the book is open it owns the pointer everywhere: the dim behind it belongs to the book.
func owns_pointer(event: InputEvent) -> bool:
	return is_visible_in_tree() and not closing and event is InputEventMouse

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		accept_event()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or closing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and get_global_rect().has_point(event.position):
		view.dragging = false
		if event.pressed and current in ["food", "materials"]:
			food_up()
		get_viewport().set_input_as_handled()
		return
	if current in ["food", "materials"] and event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE and not get_viewport().gui_get_focus_owner() is LineEdit:
		food_up()
		get_viewport().set_input_as_handled()

func grain_icon(id: String, colour: Color) -> Texture2D:
	if icons.has("food:" + id):
		return icons["food:" + id]
	var image := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var seed_value := absi(id.hash())
	var kind := str(life.economy.goods[id].icon) if life.economy.goods.has(id) else str({"wood": "log", "earth": "stone", "metal": "ore", "fibre": "spool", "other_materials": "bottle", "grains": "grain", "rice": "rice", "vegetables": "cabbage", "greens": "leaf", "roots": "root", "gourds": "gourd", "legumes": "bean", "mushrooms": "mushroom", "fruit": "fruit", "meat": "meat", "fish": "fish", "pantry": "jar"}.get(id, "grain"))
	if not life.economy.goods.has(id):
		colour = Color({"log": "a47b4f", "stone": "a1a394", "ore": "8c9299", "spool": "c4b58a", "bottle": "a4ad68", "cabbage": "70a64c", "leaf": "358250", "root": "e5a46f", "gourd": "dfa439", "bean": "9fbd58", "mushroom": "b98165", "fruit": "ec9b91", "meat": "c97568", "fish": "71a9b4", "jar": "b68b55", "grain": "d9bd65", "rice": "e4d9ad"}.get(kind, "d9bd65"))
	# Icons are things: the same grading as stalls and trees on the map.
	colour = Palette.tone(colour, Palette.THING)
	var edge := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	for y in range(4, 36):
		for x in range(5, 35):
			var p := Vector2(x - 20, y - 22)
			var mark := false
			match kind:
				"cabbage": mark = p.length() < 12 and (absi(x - 20) % 5 != y % 4 or p.length() < 5)
				"root": mark = (absf(p.x) < (11 - (p.y + 12) * 0.35) and absf(p.y) < 12) or (y < 10 and absf(p.x) < 2)
				"gourd": mark = pow(p.x / 12, 2) + pow(p.y / 9, 2) < 1 or (y < 15 and y > 8 and absf(p.x) < 2)
				"bean": mark = Vector2(p.x + sin(p.y * 0.15) * 4, p.y * 0.55).length() < 7
				"mushroom": mark = (p.y < 0 and pow(p.x / 14, 2) + pow(p.y / 10, 2) < 1) or (p.y >= 0 and p.y < 11 and absf(p.x) < 4)
				"fruit": mark = p.length() < 11 or (y < 13 and y > 7 and x > 19 and x < 25)
				"leaf": mark = pow((p.x + p.y * 0.4) / 7, 2) + pow(p.y / 14, 2) < 1 and (x + y) % 8 != 0
				"salt": mark = p.y > -8 and p.y < 10 and absf(p.x) < (p.y + 10) * 0.8
				"honeycomb": mark = absf(p.x) < 13 and absf(p.y) < 11 and (x % 8 != 0 and y % 7 != 0)
				"berries": mark = Vector2(fposmod(p.x + 12, 9) - 4, fposmod(p.y + 12, 9) - 4).length() < 4 and p.length() < 14
				"drumstick": mark = Vector2(p.x + 4, p.y + 4).length() < 9 or (absf(p.x - p.y) < 3 and p.y > 0 and p.y < 13)
				"fish": mark = pow(p.x / 12, 2) + pow(p.y / 6, 2) < 1 or (p.x < -8 and absf(p.y) < -p.x * 0.5)
				"meat": mark = Vector2(p.x + 3, p.y + 2).length() < 10 or (p.x > 2 and p.x < 13 and absf(p.y - 6) < 3)
				"egg": mark = pow(p.x / (8 + p.y * 0.1), 2) + pow(p.y / 12, 2) < 1
				"log": mark = absf(p.y) < 7 and absf(p.x) < 14
				"stone", "ore": mark = absf(p.x) + absf(p.y) < 16
				"spool": mark = absf(p.x) < 10 and absf(p.y) < 13
				"jar": mark = (absf(p.x) < 11 and p.y > -6 and p.y < 10) or (absf(p.x) < 7 and p.y > -12 and p.y <= -6)
				"bottle": mark = (absf(p.x) < 7 and p.y > -4 and p.y < 11) or (absf(p.x) < 3 and p.y > -15 and p.y <= -4)
				"rice": mark = (p.length() < 12 - absf(p.y) * 0.16) or (y in [7, 8, 9] and x > 14 and x < 26)
				"grain": mark = absf(x - 20) < 1.5 or (y % 7 < 4 and absf(absf(x - 20) - 5) < 3 and y < 29)
				_: mark = p.length() < 11
			# Stable per-good shading makes varieties distinct within each silhouette.
			if mark:
				image.set_pixel(x, y, colour.lightened(0.28) if (x + seed_value % 13) % (4 + seed_value % 4) == 0 else colour.darkened(0.22 if (x + y + seed_value) % 7 < 2 else 0))
	# Things carry the ink outline, like everything you can pick on the map.
	for y in range(1, 39):
		for x in range(1, 39):
			if image.get_pixel(x, y).a > 0: continue
			for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if image.get_pixel(x + offset.x, y + offset.y).a > 0:
					edge.set_pixel(x, y, Palette.OUTLINE)
					break
	image.blend_rect(edge, Rect2i(0, 0, 40, 40), Vector2i.ZERO)
	icons["food:" + id] = ImageTexture.create_from_image(image)
	return icons["food:" + id]

func food_slot(id: String, title: String, is_good: bool, e: RefCounted) -> void:
	var slot := button(food_grid, "", func() -> void:
		if is_good:
			selected_food = id
		else:
			food_path.append(id)
			selected_food = ""
		refresh_values())
	slot.theme_type_variation = "Card"
	slot.set_meta("food_id", id)
	slot.custom_minimum_size = Vector2(120, 208)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spirit: bool = is_good and e.goods[id].grade == "spirit"
	if spirit:
		slot.add_theme_stylebox_override("normal", UiTheme.box(Palette.PAPER_LIGHT, Palette.JADE, 2))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = 8
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", UiTheme.SPACE_8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(box)
	var mark := small(box, "✦ Tier %d" % int(e.goods[id].spirit_tier) if spirit else "")
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var picture := TextureRect.new()
	picture.texture = grain_icon(id, Color(e.goods[id].colour) if is_good else Palette.BRASS)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size.y = 40
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(picture)
	var caption := label(box, title)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var badge := small(box, quantity_text(e, id))
	if spirit and e.quantity(id) == 0:
		badge.text += "\nnot gathered yet"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for child: Control in box.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_good and e.quantity(id) == 0:
		box.modulate.a = 0.45
	slot.tooltip_text = (e.goods[id].description + (" · Not gathered yet" if spirit else "")) if is_good else title + " · " + quantity_text(e, id)

func quantity_text(e: RefCounted, id: String, yesterday: bool = false) -> String:
	var totals: Dictionary = {}
	for good: String in e.descendants(id):
		var unit := "pcs" if e.goods[good].unit == "pieces" else str(e.goods[good].unit)
		var value: float = e.yesterday_flow(good, "harvested") if yesterday else float(e.stocks[good])
		totals[unit] = float(totals.get(unit, 0.0)) + value
	var parts: Array[String] = []
	for unit: String in totals:
		parts.append(amount(totals[unit]) + " " + unit)
	return " · ".join(parts)

func _people(parent: Node) -> void:
	people_browser = preload("res://src/people_browser.gd").new()
	parent.add_child(people_browser)
	people_browser.cultivation_mode = current == "cultivators"
	people_browser.setup(self)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--people-path="):
			people_browser.path.assign(arg.trim_prefix("--people-path=").split("/", false))
			people_browser.redraw()
		if arg.begins_with("--graph="):
			people_browser.graph_mode = arg.trim_prefix("--graph=")
			people_browser.redraw()
		if arg.begins_with("--person-tab="):
			people_browser.person_tab = arg.trim_prefix("--person-tab=").replace("_", " ")
		if arg.begins_with("--person="):
			people_browser.person = clampi(int(arg.trim_prefix("--person=")), 0, life.population.size() - 1)
			people_browser.redraw()
		if arg == "--skills":
			people_browser.catalogue_mode = true
			people_browser.redraw()
		# For screenshots: refresh the open record after a few seconds of play, then scroll the page.
		if arg.begins_with("--scroll="):
			var pixels := int(arg.trim_prefix("--scroll="))
			get_tree().create_timer(12.0).timeout.connect(func() -> void: people_browser.redraw())
			get_tree().create_timer(12.5).timeout.connect(func() -> void: drawer_scroll.scroll_vertical = pixels)

func section(parent: Node, title: String) -> void:
	label(parent, title, true)
	parent.add_child(HSeparator.new())

## A person's name as a small link that opens their page.
func person_link(parent: Node, person: int, words: String = "", tab: String = "Story") -> Button:
	var link := button(parent, words if not words.is_empty() else life.population.names[person], func() -> void: open_person(person, tab))
	link.theme_type_variation = "Chip"
	return link

## A row of words with a thin meter: "the north ridge ▬▬▬▭▭ 5 of 8".
func meter(parent: Node, name: String, value: float, maximum: float, words: String, colour: Color = Palette.GREEN) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var title := label(row, name)
	title.size_flags_horizontal = Control.SIZE_FILL
	title.custom_minimum_size.x = 260
	var bar := ProgressBar.new()
	bar.max_value = maxf(0.001, maximum)
	bar.value = value
	UiTheme.thin(bar, colour, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var tail := small(row, words)
	tail.size_flags_horizontal = Control.SIZE_FILL
	tail.custom_minimum_size.x = 220

# Resource facilities and resident jobs are the registry; unknown additions still get a card.
func workplaces(e: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for id: String in e.goods:
		var g: Dictionary = e.goods[id]
		var facility := str(g.get("facility", "fields" if float(g.yield_rations_per_mu) > 0 else "kitchen"))
		if facility == "apiary":
			facility = "orchard"
		if not result.has(facility):
			result[facility] = {"people": [], "goods": [], "flow": [0.0, 0.0, 0.0], "active": false}
		result[facility].goods.append(id)
		if e.SEASONS[e.season()] in g.seasons and g.grade != "spirit":
			result[facility].active = true
		if facility == "fields":
			result[facility].active = e.season() != 3
		var output: Array = e.node_flow(id, "harvested")
		for i in 3:
			result[facility].flow[i] += output[i]
	for person: Dictionary in life.people:
		if person.has("material_work") and result.has(person.material_work):
			result[person.material_work].people.append(person)
		var facility := str(person.get("food_work", "fields" if person.kind == 0 else person.job))
		if not result.has(facility):
			result[facility] = {"people": [], "goods": [], "flow": [0.0, 0.0, 0.0], "active": true}
		result[facility].people.append(person)
	return result

func work_name(id: String) -> String:
	return str({"fields": "Paddies", "garden": "Vegetable plots & gardens", "orchard": "Orchard & bees", "herd": "Livestock", "fishery": "Fish pond", "hunt": "Hunting", "logs": "Mushroom logs", "kitchen": "Kitchen & pickling", "child": "Household", "woodcutting": "Woodcutters’ camp", "quarry": "Quarry & clay pit", "mine": "Iron mine", "smith": "Smithy & bloomery", "kiln": "Charcoal & brick kilns", "weaver": "Hemp & weaving", "tanner": "Tannery"}.get(id, id.capitalize()))

func work_group(id: String) -> String:
	if id in ["woodcutting", "quarry", "mine"]: return "Forest, quarry & mine"
	if id in ["smith", "kiln", "weaver", "tanner"]: return "Crafts"
	return str({"fields": "Fields", "garden": "Gardens & orchard", "orchard": "Gardens & orchard", "herd": "Livestock & fish", "fishery": "Livestock & fish", "hunt": "Forest & hunting", "logs": "Forest & hunting", "kitchen": "Kitchen & stores"}.get(id, "Household / unassigned"))

func work_status(record: Dictionary) -> String:
	return "idle" if record.people.is_empty() or record.goods.is_empty() else ("working" if record.active else "off-season")

func _overview(parent: Node, e: RefCounted) -> void:
	var notes: Array[String] = []
	if e.days_left() < 30: notes.append("Food is low: %d days left." % floori(e.days_left()))
	if e.ration() < 1: notes.append("Rationing is on (%d%%)." % roundi(e.ration() * 100))
	if e.hungry_count > 0: notes.append("%d villagers are hungry." % e.hungry_count)
	if not notes.is_empty():
		section(parent, "Needs attention")
		for note: String in notes: label(parent, note).add_theme_color_override("font_color", Palette.RED.darkened(0.2))
	section(parent, "Village")
	var children := 0
	var filled := 0
	var moods := {"content": 0, "well fed": 0, "plain fare": 0}
	for person: Dictionary in life.people:
		children += int(int(person.kind) == 8)
		filled += int(int(person.kind) != 8)
		var mood := str(person.get("mood", "content"))
		moods[mood] = int(moods.get(mood, 0)) + 1
	table(parent, ["Measure", "Count / level"], [
		["People living", living],
		["Walking the lanes · adults / children", "%d / %d" % [life.people.size() - children, children]],
		["Content / well fed / plain fare", "%d / %d / %d" % [moods.content, moods["well fed"], moods["plain fare"]]],
		["Hungry", e.hungry_count], ["Ration level", "%d%%" % roundi(e.ration() * 100)]])
	section(parent, "Food by group · jin")
	small(parent, "In / out: yesterday · Net: this season · Days: village food needs · select a row to open it")
	var rows: Array = []
	var paths: Array[String] = []
	for category: Dictionary in e.catalogue.categories:
		if category.parent != "food" and category.id != "spirit_grains":
			continue
		var id: String = category.id
		var incoming: Array = e.node_flow(id, "harvested")
		var out := [0.0, 0.0]
		for key: String in ["adults", "children", "spoiled", "processed"]:
			var flow: Array = e.node_flow(id, key)
			for i in 2:
				out[i] += flow[i]
		var net: float = incoming[1] - out[1]
		rows.append([category.name, amount(e.quantity(id)), "—" if id == "spirit_grains" else "%.1f" % (e.edible_quantity(id) / e.daily_need()), amount(e.yesterday_flow(id, "harvested")), amount(e.yesterday_flow(id, "adults") + e.yesterday_flow(id, "children") + e.yesterday_flow(id, "spoiled") + e.yesterday_flow(id, "processed")), amount(net), "↑" if net > 0 else ("↓" if net < 0 else "→")])
		paths.append("food/grains/spirit_grains" if id == "spirit_grains" else "food/" + id)
	var food_table := table(parent, ["Group", "Stock", "Days", "In (yday)", "Out (yday)", "Net", "Trend"], rows)
	food_table.item_selected.connect(func() -> void: open_tab(paths[food_table.get_selected().get_index()]))
	section(parent, "Materials · jin / pieces")
	var material_rows: Array = []
	var material_paths: Array[String] = []
	for category: Dictionary in e.catalogue.categories:
		if category.parent == "materials":
			material_paths.append("materials/" + str(category.id))
			material_rows.append([category.name, quantity_text(e, category.id), amount(e.node_flow(category.id, "harvested")[2]), amount(e.node_flow(category.id, "processed")[2])])
	var material_table := table(parent, ["Group", "Stored", "Year in", "Year used"], material_rows)
	material_table.item_selected.connect(func() -> void: open_tab(material_paths[material_table.get_selected().get_index()]))
	section(parent, "Skills by domain")
	var counts: Dictionary = life.population.domain_statistics()
	var skill_rows: Array = []
	for id: String in counts:
		var summary: Dictionary = counts[id]
		skill_rows.append([life.population.catalogue.domains[id].name, summary.count, "%.1f" % (summary.total / maxf(1, summary.count)), summary.experts])
	table(parent, ["Domain", "People", "Average", "Expert+"], skill_rows)
	section(parent, "Season & calendar")
	table(parent, ["Measure", "Value"], [["Season / day", "%s / %d" % [e.SEASONS[e.season()], e.day]], ["Days to harvest", e.days_to_harvest()], ["Harvest forecast · jin", amount(e.forecast())], ["Weather", "Poor" if e.weather < 0.8 else "Favourable"]])
	var crisis := CheckBox.new()
	crisis.text = "Pause on crisis"
	crisis.button_pressed = e.pause_on_crisis
	crisis.toggled.connect(func(value: bool) -> void: e.pause_on_crisis = value)
	parent.add_child(crisis)

## The body-tempering ladder for the whole valley, and who is stuck where.
func _tempering(parent: Node) -> void:
	page_day = life.population.day
	var population: RefCounted = life.population
	var society: RefCounted = population.society
	var temper: RefCounted = society.temper
	if temper == null:
		label(parent, "Body tempering is switched off.")
		return
	var summary: Dictionary = temper.summary()
	var layers: Array = summary.layers
	var tempered := 0
	for l in range(1, layers.size()): tempered += int(layers[l])
	label(parent, "%d of %d villagers have tempered their bodies; %d are drilling now. Labour hardens skin and flesh, but every gate after that needs a method, drills and sometimes a medicine from the forest." % [tempered, living, summary.drilling])
	section(parent, "The ladder")
	var most := 1
	for count: int in layers: most = maxi(most, count)
	for l in range(layers.size() - 1, -1, -1):
		var name: String = "Untempered" if l == 0 else "%d · %s" % [l, temper.layer_name(l)]
		meter(parent, name, layers[l], most, "%d %s" % [layers[l], "person" if layers[l] == 1 else "people"], Palette.BRASS if l else Palette.LINE)
	var grades: Array = summary.grades
	if grades.reduce(func(a: int, b: int) -> int: return a + b, 0) > 0:
		section(parent, "How well the layers were forged")
		var words: PackedStringArray = []
		for g in grades.size():
			if grades[g] > 0: words.append("%d %s" % [grades[g], str(temper.config.grade_names[g]).to_lower()])
		label(parent, ", ".join(words) + ". A layer's grade is fixed when it is forged: a better method, a teacher and patience raise it; rushing lowers it.")
	if current == "tempering":
		label(parent, "Qi cultivation", true)
		var qi_rows: Array = []
		for realm in society.rules.realms.size():
			var count := 0
			for p in population.size():
				if society.alive[p] and society.realm[p] == realm: count += 1
			qi_rows.append([society.rules.realms[realm].name, count])
		table(parent, ["Realm", "People"], qi_rows)
	var gate: Array[int] = []
	var drilling: Array[int] = []
	for p in population.size():
		if not society.alive[p]: continue
		if temper.at_gate(p): gate.append(p)
		elif temper.training(p, population.day): drilling.append(p)
	if not gate.is_empty():
		section(parent, "At a gate")
		small(parent, "Their progress is full; each waits on one thing before the next layer.")
		var grid := HFlowContainer.new()
		parent.add_child(grid)
		for p: int in gate.slice(0, 30):
			var need: String = temper.gate_need(p)
			var link := person_link(grid, p, "%s · %s gate%s" % [population.names[p], temper.layer_name(temper.body_layer[p] + 1), (", needs " + need) if not need.is_empty() else ""], "Body & cultivation")
			link.theme_type_variation = "Hot" if not need.is_empty() else "Chip"
	if not drilling.is_empty():
		section(parent, "Drilling now")
		var grid := HFlowContainer.new()
		parent.add_child(grid)
		for p: int in drilling.slice(0, 30):
			var state: Dictionary = temper.describe(p)
			person_link(grid, p, "%s · %d h%s" % [population.names[p], state.hours, (" under " + str(state.teacher)) if not str(state.teacher).is_empty() else ""], "Body & cultivation")

## The wild supply behind the medicines: bark patches, the herd and the spring herbs.
func _forest(parent: Node) -> void:
	page_day = life.population.day
	var temper: RefCounted = life.population.society.temper
	if temper == null:
		label(parent, "The forest is not simulated while body tempering is off.")
		return
	var wild: RefCounted = temper.wild
	var config: Dictionary = wild.config
	var summary: Dictionary = temper.summary()
	label(parent, "Tempering past Steel Sinew needs medicine the valley cannot farm. Iron-bark is stripped from six patches and regrows each year; beast marrow comes from hunting the herd; seven-leaf herbs grow slowly at the spirit spring.")
	section(parent, "Iron-bark patches")
	var cap := float(config.iron_bark.cap_per_patch)
	for i in wild.patch_stock.size():
		var stock: float = wild.patch_stock[i]
		var state := "stripped" if stock < 1 else ("thinning" if stock < cap * 0.4 else ("healthy" if stock < cap * 0.85 else "thick with bark"))
		meter(parent, str(config.iron_bark.patches[i]).capitalize(), stock, cap, "%s · %.0f of %.0f roots" % [state, stock, cap], Palette.signal_colour(0 if stock >= cap * 0.4 else (1 if stock >= 1 else 2)))
	section(parent, "Beasts and herbs")
	wild.refresh_herd()
	var herd: float = wild.herd
	meter(parent, "Huntable deer and boar", herd, maxf(1, wild.herd_cap), "%.0f in the hills" % herd, Palette.signal_colour(0 if herd >= wild.herd_cap * 0.5 else 1))
	var herb_cap := float(config.seven_leaf.cap)
	meter(parent, "Seven-leaf at %s" % config.seven_leaf.place, wild.herbs, herb_cap, "%.0f of %.0f herbs" % [floorf(wild.herbs), herb_cap], Palette.JADE)
	var wanting: Dictionary = summary.wanting
	if not wanting.is_empty():
		section(parent, "Wanted now")
		for id: String in wanting:
			label(parent, "%d %s preparing for a gate with %s." % [wanting[id], "person is" if int(wanting[id]) == 1 else "people are", temper.config.medicine_names[id]])
	section(parent, "This year in the forest")
	var year: Dictionary = wild.year_stats
	label(parent, "%d hunts · %d beasts taken · %d hunters hurt · %d iron-bark roots gathered · %d herbs found" % [year.get("hunts",0),year.get("kills",0),year.get("hunt_injuries",0),year.get("roots_taken",0),year.get("herbs_taken",0)])
	var last: Dictionary = summary.wild.last_year
	if not last.is_empty():
		section(parent, "Last year in the forest")
		label(parent, "%d iron-bark roots taken in %d stripping trips. %d hunts brought down %d beasts; %d hunters were hurt. %d seven-leaf herbs found, %d searches came back empty." % [int(last.get("roots_taken", 0)), int(last.get("stripped_trips", 0)), int(last.get("hunts", 0)), int(last.get("kills", 0)), int(last.get("hunt_injuries", 0)), int(last.get("herbs_taken", 0)), int(last.get("herb_misses", 0))])

	_wildlife_page(parent, false)

## What the valley has seen of the thousands of species that live in it.
func _bestiary(parent: Node) -> void:
	_wildlife_page(parent, true)
	page_day = life.population.day


func _thousands(n: int) -> String:
	var text := str(n)
	return text if n < 1000 else "%s,%s" % [text.substr(0, text.length() - 3), text.substr(text.length() - 3)]


func _work(parent: Node, e: RefCounted) -> void:
	label(parent, "Y%d · Day %d · %s · %s" % [e.year, e.day, e.SEASONS[e.season()], stage()])
	var calendar := ProgressBar.new()
	calendar.max_value = 365
	calendar.value = e.day
	UiTheme.thin(calendar, Palette.BRASS, 8)
	parent.add_child(calendar)
	small(parent, "Spring: plant · Summer: tend · Autumn: harvest · Winter: fallow")
	var registry := workplaces(e)
	var groups: Dictionary = {}
	for id: String in registry:
		var group := work_group(id)
		if not groups.has(group): groups[group] = []
		groups[group].append(id)
	for group: String in groups:
		section(parent, group)
		var grid := GridContainer.new()
		grid.columns = maxi(2, int(content_width() / 280))
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent.add_child(grid)
		for id: String in groups[group]:
			var record: Dictionary = registry[id]
			var card := button(grid, "", func() -> void: selected_work = id; refresh_values())
			card.theme_type_variation = "Card"
			card.set_meta("work_id", id)
			card.custom_minimum_size = Vector2(264, 160)
			card.size_flags_horizontal = Control.SIZE_FILL
			var box := VBoxContainer.new()
			card.add_child(box)
			box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			box.offset_left = 8
			box.offset_right = -8
			box.offset_top = 8
			box.offset_bottom = -8
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_theme_constant_override("separation", UiTheme.SPACE_8)
			var heading := HBoxContainer.new()
			box.add_child(heading)
			var picture := TextureRect.new()
			picture.texture = grain_icon(record.goods[0], Color(e.goods[record.goods[0]].colour)) if not record.goods.is_empty() else icon("people")
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.custom_minimum_size = Vector2(24, 24)
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			heading.add_child(picture)
			label(heading, work_name(id))
			var status := label(heading, "●")
			status.size_flags_horizontal = Control.SIZE_SHRINK_END
			status.autowrap_mode = TextServer.AUTOWRAP_OFF
			status.add_theme_color_override("font_color", Palette.GREEN if work_status(record) == "working" else Palette.BRASS)
			var summary := HBoxContainer.new()
			box.add_child(summary)
			small(summary, "%d workers" % record.people.size())
			var use_yesterday: bool = record.flow[0] == 0 or fmod(life.minutes, 1440.0) < 390
			var totals: Dictionary = {}
			for good: String in record.goods:
				var unit := "pcs" if e.goods[good].unit == "pieces" else str(e.goods[good].unit)
				var value: float = e.yesterday_flow(good, "harvested") if use_yesterday else e.node_flow(good, "harvested")[0]
				totals[unit] = float(totals.get(unit, 0.0)) + value
			var output: Array[String] = []
			for unit: String in totals: output.append(amount(totals[unit]) + " " + unit)
			small(summary, ("yesterday " if use_yesterday else "today ") + " · ".join(output))
			var effectiveness := ProgressBar.new()
			UiTheme.thin(effectiveness, Palette.BRASS, 4)
			var total := 0.0
			for person: Dictionary in record.people: total += e.EFFECT[int(person.hunger)]
			effectiveness.value = total / maxf(1, record.people.size()) * 100
			card.tooltip_text = "%s · %d workers / no capacity limit\nEffectiveness: %d%%" % [work_name(id), record.people.size(), roundi(effectiveness.value)]
			box.add_child(effectiveness)
			small(box, "%d%% effectiveness" % roundi(effectiveness.value))
			for child: Control in box.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not registry.has(selected_work): return
	var chosen: Dictionary = registry[selected_work]
	section(parent, work_name(selected_work) + " · details")
	label(parent, "Schedule: prepare 05:30–06:30 · work 06:30–18:00 · meal 12:00–13:00 · rest until 21:00. Resident offsets: up to 60 minutes. Harvest and hunger can change assignments.")
	var people_row := HFlowContainer.new()
	parent.add_child(people_row)
	for person: Dictionary in chosen.people:
		var id := int(person.id)
		var link := button(people_row, person.name + " · " + life.activity_text(person), func() -> void:
			view.show_person(id)
			close())
		link.theme_type_variation = "Chip"
	table(parent, ["Output · jin", "Today", "Season", "Year"], [["Produced", amount(chosen.flow[0]), amount(chosen.flow[1]), amount(chosen.flow[2])]])
	if selected_work == "fields":
		var rows: Array = []
		var index := 0
		for field: Dictionary in life.sect.data.fields:
			index += 1
			var area := int(field.rect[2]) * int(field.rect[3])
			rows.append(["Plot %d" % index, e.goods[field.crop].name, stage(), "%d%%" % roundi(e.care() * 100), amount(e.good_forecast(field.crop) * area / maxf(1, e.areas[field.crop]))])
		table(parent, ["Plot", "Crop", "Stage", "Care", "Yield · jin"], rows)

## The granary on the map opens the food page.
func show_granary() -> void:
	open_tab("food")

## Year by year, season by season: harvest notes from the stores and the lives of the valley.
func _chronicle(parent: Node, e: RefCounted) -> void:
	page_day = life.population.day
	var seasons: Array = e.SEASONS
	var buckets: Dictionary = {}
	var order: Array[int] = []
	var add := func(year: int, season: int, line: String) -> void:
		var key := year * 4 + season
		if not buckets.has(key):
			buckets[key] = []
			order.append(key)
		buckets[key].append(line)
	var society: RefCounted = life.population.society
	var society_lines: Dictionary = {}
	for i in range(society.chronicle.size() - 1, maxi(-1, society.chronicle.size() - 400), -1):
		var entry: Dictionary = society.chronicle[i]
		var year := int(entry.day) / 365 + 1
		if year_filter > 0 and year != year_filter: continue
		var season := mini(3, (int(entry.day) % 365) / 91)
		society_lines["%d:%d:%s" % [year, season, entry.text]] = true
		add.call(year, season, str(entry.text))
	for i in range(e.chronicle.size() - 1, -1, -1):
		var line: String = e.chronicle[i]
		var year := int(line.get_slice(" ", 0).trim_prefix("Y"))
		if year_filter > 0 and year != year_filter: continue
		var season := maxi(0, seasons.find(line.get_slice(" ", 1).trim_suffix(":")))
		var words := line.get_slice(": ", 1) if ": " in line else line
		if not society_lines.has("%d:%d:%s" % [year, season, words]): add.call(year, season, words)
	order.sort()
	order.reverse()
	for key: int in order:
		label(parent, "Year %d · %s" % [key / 4, seasons[key % 4]], true)
		for line: String in buckets[key]:
			label(parent, line)
	if order.is_empty():
		label(parent, "Nothing recorded yet.")

func _society(parent: Node) -> void:
	page_day = life.population.day
	var society: RefCounted = life.population.society
	if society.faction_pending:
		page_day = -1
		label(parent, "Society is updating…")
		return
	small(parent, "Lifespan death: " + ("on" if society.lifespan_death_enabled else "off · elders keep living"))
	section(parent, "Factions")
	var active: Array[Dictionary] = []
	for faction: Dictionary in society.factions:
		if not faction.members.is_empty() or faction.type == "outsiders": active.append(faction)
	if active.size() > 25:
		var navigation := HBoxContainer.new()
		parent.add_child(navigation)
		button(navigation, "Previous", func() -> void: society_offset = maxi(0, society_offset - 25); refresh())
		small(navigation, "%d–%d of %d" % [mini(society_offset + 1, active.size()), mini(society_offset + 25, active.size()), active.size()])
		button(navigation, "Next", func() -> void: society_offset = mini(maxi(0, active.size() - 1) / 25 * 25, society_offset + 25); refresh())
	var grid := GridContainer.new()
	grid.columns = 2 if content_width() > 900 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	for faction: Dictionary in active.slice(society_offset, society_offset + 25):
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		label(box, "%s · %d members" % [faction.name, faction.members.size()], true)
		small(box, "%s · led by %s · %s cohesion" % [faction.type.capitalize(), life.population.names[faction.leader] if faction.leader >= 0 else "no one yet", "strong" if faction.cohesion >= 60 else ("fair" if faction.cohesion >= 30 else "weak")])
		var details := VBoxContainer.new()
		var actions := HBoxContainer.new()
		box.add_child(actions)
		var toggle := button(actions, "Details", func() -> void: details.visible = not details.visible)
		toggle.theme_type_variation = "Chip"
		var browse := button(actions, "Browse members", func() -> void:
			open_tab("people")
			people_browser.group_mode = "Faction"
			people_browser.path.assign(["faction:%d" % faction.id])
			people_browser.redraw())
		browse.theme_type_variation = "Chip"
		box.add_child(details)
		details.hide()
		small(details, "Succession: %s · goals: %s" % [faction.succession, ", ".join(faction.goals)])
		var members := HFlowContainer.new()
		details.add_child(members)
		for p: int in faction.members.slice(0, 12):
			person_link(members, p)
	section(parent, "Positions")
	for position: Dictionary in society.positions:
		var row := HBoxContainer.new()
		parent.add_child(row)
		label(row, "%s · %s" % [position.name, (life.population.names[position.holder] if position.holder >= 0 else "vacant") if position.exists else "not yet existing"])
		row.tooltip_text = "Exists: %s\nHolder: %s" % [position.condition, position.hold_when]
		row.mouse_filter = Control.MOUSE_FILTER_PASS


## The first law, its stone enforcers and the trails that are still warm.
func _laws(parent: Node) -> void:
	page_day = life.population.day
	label(parent, "No one enters the sect grounds without an invitation.")
	label(parent, "All villagers are bound. Servants have a work pass only at their own workplace during work hours. Stone swordsmen enforce the law; those caught face pursuit and lethal combat.")
	var society: RefCounted = life.population.society
	var law: RefCounted = society.law
	if not law: return
	section(parent, "The swordsmen")
	for g: Dictionary in law.guardians:
		button(parent, "%s · %s" % [Law.title(g.name), str(g.get("visual_state", g.state))], func() -> void: close(); view.guardian_card.open(g))
		meter(parent, "Harm", float(g.get("harm", 0.0)), 100, "%.0f / 100 harm" % float(g.get("harm", 0.0)), Palette.RED)
		meter(parent, "Energy", float(g.energy), float(law.config.energy_max), "%d energy · %d kills · %d breaks" % [int(g.energy), g.kills, g.breaks], Palette.JADE)
	section(parent, "This year")
	var year: Dictionary = law.years.get(life.population.day / 365, {})
	label(parent, "%d breaches · %d seen · %d escaped · %d killed · %d swordsmen broken" % [int(year.get("breaches", 0)), int(year.get("seen", 0)), int(year.get("escaped", 0)), int(year.get("killed", 0)), int(year.get("broken", 0))])
	section(parent, "The hunt list")
	if law.hunt_list.is_empty(): small(parent, "No warm trails.")
	for entry: Dictionary in law.hunt_list.values():
		var days: int = life.population.day - int(entry.day)
		label(parent, "%s · %s · %d days · priority %.2f%s" % [life.population.names[entry.person], str(law.config.offences.get(entry.place, entry.place)), days, law.priority(entry, life.population.day), " · trail nearly cold" if days >= int(law.config.cold_days) - int(law.config.cold_warning) else ""])
	section(parent, "Recent breaches")
	for i in range(society.breaches.size() - 1, maxi(-1, society.breaches.size() - 11), -1):
		var r: Dictionary = society.breaches[i]
		label(parent, "Day %d · %s" % [r.day, r.text])

func _medicine(parent: Node) -> void:
	var temper: RefCounted = life.population.society.temper
	if not temper: return
	var summary: Dictionary = temper.summary()
	section(parent, "Methods known")
	var methods: Array = summary.methods
	var known: PackedStringArray = []
	for m in methods.size():
		if methods[m] > 0: known.append("%d know %s" % [methods[m], temper.config.method_names[m]])
	label(parent, ", ".join(known) + ".")
	_forest(parent)

func _summary(parent: Node) -> void:
	var store: RefCounted = life.population
	var society: RefCounted = store.society
	var values: Array = []
	if current in ["cultivators", "tempering", "medicine"]:
		var tempering := 0
		var gates := 0
		var roots := 0
		var highest := 0
		var qi := 0
		var highest_qi := 0
		for p in store.size():
			if not society.alive[p]: continue
			if society.temper:
				tempering += int(society.temper.body_layer[p] > 0 or society.temper.training(p, store.day))
				gates += int(society.temper.at_gate(p))
				highest = maxi(highest, society.temper.body_layer[p])
			highest_qi = maxi(highest_qi, society.realm[p])
			roots += int(society.revealed[p] > 0)
			qi += int(society.realm[p] >= 2 or society.qi[p] > 0)
		values = [[tempering, "tempering"], [gates, "at a gate"], [roots, "roots revealed"], [society.rules.realms[highest_qi].name if highest_qi >= 2 else str(highest), "highest realm" if highest_qi >= 2 else "highest body layer"], [qi, "qi cultivators"]]
	elif current in ["forest", "bestiary"]:
		var wildlife: Dictionary = society.wildlife.summary()
		values = [[wildlife.total,"wild animals"],[wildlife.awakened,"awakened beasts"],[wildlife.events.births,"births"],[wildlife.events.predation,"prey taken"]]
	elif current == "laws" and society.law:
		var law: RefCounted = society.law
		values = [[law.guardians.filter(func(g: Dictionary) -> bool: return g.state != "broken").size(), "swordsmen"], [law.hunt_list.size(), "warm trails"], [law.totals.breaches, "breaches"], [law.totals.broken, "broken"]]
	elif current == "food":
		values = [[floori(life.economy.days_left()), "days of food"], [life.economy.hungry_count, "hungry"], [living, "mouths to feed"]]
	else:
		values = [[living, "people"], [society.factions.size(), "families & factions"], [store.day / 365 + 1, "year in the valley"]]
	var row := HFlowContainer.new()
	parent.add_child(row)
	for value: Array in values:
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.custom_minimum_size.x = 144
		row.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		label(box, str(value[0]), true)
		small(box, str(value[1]))


## Same book rhythm as people: summary, population cards, and persistent individual cards.
func _wildlife_page(parent: Node, notable_only: bool) -> void:
	var wildlife: RefCounted = life.population.society.wildlife
	wildlife.seed(life.population.day)
	section(parent, "Species catalogue" if notable_only else "Populations")
	var catalogue := parent
	for species: Dictionary in wildlife.species:
		var count: int = wildlife.count(species.sci)
		if count <= 0: continue
		var role: String = wildlife.role(species)
		if notable_only:
			label(catalogue, "%s · %d" % [Law.title(species.name), count], true)
			small(catalogue, "Typical lifespan ~%.1f years · %s · danger to villagers: %s" % [species.lifespan_y, species.diet, ("high" if float(species.get("danger",0)) >= 2 else ("defensive" if float(species.get("danger",0)) > 0 else "low"))])
		else:
			label(catalogue, "%s · %d · %s · %s" % [Law.title(species.name), count, wildlife.trend(species.sci), role])
	if not notable_only: return
	section(parent, "Awakened beasts")
	var box := parent
	var found := false
	for beast: Dictionary in wildlife.individuals:
		if not beast.alive or not beast.awakened: continue
		found = true
		_beast_record(box, wildlife, beast)
	if not found: small(box, "No awakened beasts have been seen.")
	var notable := 0
	for beast: Dictionary in wildlife.individuals:
		if not beast.alive or beast.awakened or not beast.get("notable", false): continue
		if notable == 0: section(parent, "Notable ordinary animals")
		_beast_record(parent, wildlife, beast)
		notable += 1
		if notable >= 5: break

func _beast_record(box: Node, wildlife: RefCounted, beast: Dictionary) -> void:
	label(box, Law.title(beast.name), true)
	small(box, wildlife.description(beast))
	meter(box, "Age", float(beast.age), wildlife.lifespan(beast), "%.1f of ~%.1f years · %.1f× lifespan" % [beast.age, wildlife.lifespan(beast), wildlife.rules.lifespan[int(beast.layer)]], Palette.GREEN)
	small(box, "Roams %s · %s" % [wildlife.place(beast), beast.state])
