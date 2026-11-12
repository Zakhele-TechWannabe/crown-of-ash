extends PanelContainer
## Tab registry and economy flow keys keep presentation separate from simulation.
class LedgerButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		var tip := Label.new()
		tip.text = for_text
		tip.custom_minimum_size.x = minf(448, get_viewport_rect().size.x - 32)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return tip

const TABS := {"overview": "Overview", "food": "Food", "materials": "Materials", "people": "People", "work": "Work & fields", "chronicle": "Chronicle"}
const INK := Color("493423")
const GOLD := Color("a57927")
var selected_work := ""
var selected_food := ""
var food_path: Array[String] = ["food"]
var food_grid: GridContainer
var drawer_scroll: ScrollContainer
var collapsed: Dictionary = {}
var closing := false
var slide: Tween
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
const SPEEDS: Array[int] = [1, 4, 16, 64, 256, 1024, 4096]
const KPIS: Array[Dictionary] = [
	{"id": "food", "icon": "rice", "tab": "food", "label": "food left"},
	{"id": "people", "icon": "people", "tab": "people", "label": "0 hungry"},
	{"id": "harvest", "icon": "work", "tab": "food", "label": "forecast jin"},
	{"id": "year", "icon": "overview", "tab": "food", "label": "food balance"},
]
var kpi_cards: Dictionary = {}
var hud_panel: PanelContainer
var pause_button: Button
var speed_selector: OptionButton
var ledger_button: Button
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
		box.set_content_margin(side, 8)
	return box

func icon(kind: String) -> Texture2D:
	if icons.has(kind):
		return icons[kind]
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
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
	for container_type: String in ["HBoxContainer", "VBoxContainer"]:
		parchment.set_constant("separation", container_type, 8)
	parchment.set_font("font", "TooltipLabel", body_font)
	parchment.set_font_size("font_size", "TooltipLabel", 14)
	parchment.set_color("font_color", "TooltipLabel", INK)
	parchment.set_stylebox("panel", "TooltipPanel", skin("panel_beige"))
	for type: String in ["Label", "Button", "CheckBox", "Tree", "OptionButton"]:
		parchment.set_color("font_color", type, INK)
		parchment.set_color("font_hover_color", type, INK)
		parchment.set_color("font_pressed_color", type, INK)
	parchment.set_stylebox("panel", "PanelContainer", skin("panel_beige"))
	parchment.set_stylebox("panel", "Tree", skin("panelInset_beigeLight"))
	parchment.set_stylebox("background", "ProgressBar", skin("barBack_horizontalMid"))
	parchment.set_stylebox("fill", "ProgressBar", skin("barYellow_horizontalMid"))
	for state: String in ["normal", "hover", "focus", "disabled"]:
		var button_skin := skin("buttonLong_brown")
		button_skin.set_content_margin(SIDE_LEFT, 5)
		button_skin.set_content_margin(SIDE_RIGHT, 5)
		parchment.set_stylebox(state, "Button", button_skin)
		parchment.set_stylebox(state, "OptionButton", button_skin)
	parchment.set_stylebox("pressed", "Button", skin("buttonLong_brown_pressed"))
	parchment.set_stylebox("pressed", "OptionButton", skin("buttonLong_brown_pressed"))
	view.hud.add_child(self)
	mouse_force_pass_scroll_events = false
	theme = parchment
	_build_hud(parchment)
	get_viewport().size_changed.connect(func() -> void:
		if visible: refresh.call_deferred())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.5
	anchor_right = 1.0
	anchor_top = 0.0
	offset_top = 64
	anchor_bottom = 1.0
	var book := VBoxContainer.new()
	add_child(book)
	var tabs := HBoxContainer.new()
	tabs.custom_minimum_size.x = 180
	book.add_child(tabs)

	for key: String in TABS:
		var tab := button(tabs, {"overview": "Overview", "food": "Food", "materials": "Materials", "people": "People", "work": "Work", "chronicle": "Chronicle"}[key], func() -> void: open_tab(key))
		tab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tab.icon = icon(key)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_button := button(tabs, "×", close)
	close_button.custom_minimum_size = Vector2(36, 36)
	var scroll := ScrollContainer.new()
	drawer_scroll = scroll
	scroll.mouse_force_pass_scroll_events = false
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	book.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
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
	var node := LedgerButton.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func _build_hud(parchment: Theme) -> void:
	hud_panel = PanelContainer.new()
	hud_panel.theme = parchment
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	view.hud.add_child(hud_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	hud_panel.add_child(row)
	var location := VBoxContainer.new()
	location.custom_minimum_size.x = 208
	location.add_theme_constant_override("separation", 0)
	row.add_child(location)
	view.place = label(location, "Servants' Village")
	view.place.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.place.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	clock = label(location, "")
	clock.autowrap_mode = TextServer.AUTOWRAP_OFF
	clock.add_theme_font_size_override("font_size", 12)
	for definition: Dictionary in KPIS:
		var card_button := button(row, "", func() -> void: open_tab(definition.tab))
		card_button.custom_minimum_size = Vector2(126, 44)
		var card_row := HBoxContainer.new()
		card_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_row.offset_left = 8
		card_row.offset_right = -8
		card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_button.add_child(card_row)
		var picture := TextureRect.new()
		picture.texture = icon(definition.icon)
		picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_row.add_child(picture)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", 0)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_row.add_child(words)
		var value := label(words, "—")
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.add_theme_font_size_override("font_size", 19)
		var caption := label(words, definition.label)
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.add_theme_font_size_override("font_size", 11)
		kpi_cards[definition.id] = {"button": card_button, "value": value, "label": caption}
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	var speed_group := HBoxContainer.new()
	speed_group.add_theme_constant_override("separation", 8)
	row.add_child(speed_group)
	pause_button = button(speed_group, "Ⅱ", func() -> void: life.paused = not life.paused; _refresh_hud())
	pause_button.custom_minimum_size.x = 32
	speed_selector = OptionButton.new()
	speed_selector.custom_minimum_size.x = 100
	for speed: int in SPEEDS:
		speed_selector.add_item("%dx" % speed)
	speed_selector.item_selected.connect(func(index: int) -> void: life.speed = SPEEDS[index]; _refresh_hud())
	speed_selector.tooltip_text = "Simulation speed [1–7]"
	speed_group.add_child(speed_selector)
	ledger_button = button(row, "Ledger [L]", func() -> void:
		if visible and not closing:
			close()
		else:
			open_tab(current))
	ledger_button.icon = icon("overview")
	button(row, "World map [M]", view.map.show_map)
	_refresh_hud()
	granary_card = PanelContainer.new()
	granary_card.theme = parchment
	granary_card.position = Vector2(24, 90)
	granary_card.custom_minimum_size.x = 460
	granary_card.size.x = 460
	view.hud.add_child(granary_card)
	granary_card.hide()

func close() -> void:
	closing = true
	if slide:
		slide.kill()
	slide = create_tween().set_parallel(true)
	slide.tween_property(self, "offset_left", get_viewport_rect().size.x * 0.5, 0.15)
	slide.tween_property(self, "offset_right", get_viewport_rect().size.x * 0.5, 0.15)
	slide.chain().tween_callback(hide)

func toggle_tab(key: String) -> void:
	key = "food" if key == "rice" else key
	if visible and not closing and current == key:
		close()
	else:
		open_tab(key)

func open_tab(key: String) -> void:
	key = "food" if key == "rice" else key
	if not visible or closing:
		closing = false
		if slide:
			slide.kill()
		offset_left = get_viewport_rect().size.x * 0.5
		offset_right = offset_left
		slide = create_tween().set_parallel(true)
		slide.tween_property(self, "offset_left", 0.0, 0.18)
		slide.tween_property(self, "offset_right", 0.0, 0.18)
	if key.begins_with("food") or key.begins_with("materials"):
		food_path = ["materials" if key.begins_with("materials") else "food"]
		selected_food = ""
		for part: String in key.split("/").slice(1):
			for category: Dictionary in life.economy.catalogue.categories:
				if category.id == part and category.parent == food_path[-1]:
					food_path.append(part)
		key = food_path[0]
	current = key if TABS.has(key) else "overview"
	show()
	refresh()

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


func _refresh_hud() -> void:
	var e: RefCounted = life.economy
	var food: Dictionary = kpi_cards.food
	food.value.text = "%d d" % floori(e.days_left())
	food.value.add_theme_color_override("font_color", Color("a23522") if e.days_left() < 7 else (GOLD if e.days_left() < 30 else INK))
	var totals := "Mortal meals: %s jin" % amount(e.mortal_food())
	for group: String in ["grains", "vegetables", "fruit", "meat", "fish", "pantry"]:
		totals += "\n%s: %s jin" % [food_title(group), amount(e.quantity(group))]
	food.button.tooltip_text = totals
	var people: Dictionary = kpi_cards.people
	people.value.text = str(life.people.size())
	people.label.text = "%d hungry" % e.hungry_count
	people.value.add_theme_color_override("font_color", Color("a23522") if e.hungry_count > 0 else INK)
	people.button.tooltip_text = "%d people · %d hungry" % [life.people.size(), e.hungry_count]
	var harvest: Dictionary = kpi_cards.harvest
	harvest.value.text = "~" + amount(roundf(e.forecast() / 50.0) * 50.0)
	harvest.label.text = "planting in %d d" % (366 - e.day) if e.season() == 3 else "forecast jin"
	harvest.button.tooltip_text = "Harvest forecast: %s jin" % amount(e.forecast())
	if e.season() == 3:
		harvest.value.text = "%d d" % (366 - e.day)
		harvest.button.tooltip_text = harvest.label.text
	var projected: float = e.after_harvest_days()
	var annual: Dictionary = kpi_cards.year
	annual.value.text = "%.0f d" % projected
	annual.label.text = "after harvest"
	annual.value.add_theme_color_override("font_color", Color("49612e") if projected > 365 else (Color("a23522") if projected < 60 else Color("a07826")))
	annual.button.tooltip_text = "Next harvest: food stock + remaining forecast − full food consumption until harvest, in days of food. Forecast is weather and care dependent."
	clock.text = life.clock_text()
	pause_button.text = "▶" if life.paused else "Ⅱ"
	pause_button.tooltip_text = ("Resume" if life.paused else "Pause") + " [Space]"
	speed_selector.select(SPEEDS.find(int(life.speed)))
	var narrow := get_viewport_rect().size.x < 1500
	for definition: Dictionary in KPIS:
		var entry: Dictionary = kpi_cards[definition.id]
		entry.label.visible = not narrow
		entry.button.custom_minimum_size.x = 112 if narrow else 160
		var font: Font = entry.value.get_theme_font("font")
		var available: float = entry.button.custom_minimum_size.x - 48
		var px := 19
		if font.get_string_size(entry.value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > available:
			px = 18
		entry.value.add_theme_font_size_override("font_size", px)
		if definition.id == "harvest" and e.season() != 3 and font.get_string_size(entry.value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > available:
			entry.value.text = "~%.0fk" % (e.forecast() * 2.0 / 1000.0)


func refresh() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	section(content, TABS[current])
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
	data.add_theme_constant_override("separation", 8)
	content.add_child(data)
	var e: RefCounted = life.economy
	match current:
		"overview": _overview(data, e)
		"food", "materials": _food(data, e)
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

func table(parent: Node, headers: Array, rows: Array, _height: float = 200) -> Tree:
	var widget := Tree.new()
	widget.columns = headers.size()
	widget.hide_root = true
	widget.column_titles_visible = true
	widget.custom_minimum_size.y = maxf(60, (rows.size() + 1) * 30)
	widget.scroll_vertical_enabled = false
	widget.scroll_horizontal_enabled = false
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in headers.size():
		widget.set_column_title(i, headers[i])
		widget.set_column_expand(i, false)
		var available := maxf(400, get_viewport_rect().size.x * 0.5 - 56)
		var share := 1.0 / headers.size()
		if headers.size() > 2:
			share = 0.32 if i == 0 else 0.68 / (headers.size() - 1)
		widget.set_column_custom_minimum_width(i, int(available * share))
	var root := widget.create_item()
	var widths: Array[int] = []
	for i in headers.size():
		var share := (0.32 if i == 0 else 0.68 / (headers.size() - 1)) if headers.size() > 2 else 0.5
		widths.append(int(maxf(400, get_viewport_rect().size.x * 0.5 - 56) * share))
	for row: Array in rows:
		var item := widget.create_item(root)
		for i in row.size():
			var text := str(row[i])
			item.set_tooltip_text(i, text)
			var font := get_theme_font("font", "Tree")
			var limit: int = widths[i] - 16
			var numeric := text.replace(",", "").replace("−", "-")
			if numeric.is_valid_float() and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > limit:
				var value := float(numeric)
				text = "%.1fm" % (value / 1000000.0) if absf(value) >= 1000000 else "%.1fk" % (value / 1000.0)
			while font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > limit and text.length() > 1:
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
		button(crumbs, food_title(food_path[index]), func() -> void:
			food_path.resize(at + 1)
			selected_food = ""
			refresh_values())
	food_grid = GridContainer.new()
	food_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	food_grid.add_theme_constant_override("h_separation", 8)
	food_grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(food_grid)
	food_grid.columns = maxi(1, int((get_viewport_rect().size.x * 0.5 - 48) / 112))
	food_grid.resized.connect(func() -> void:
		food_grid.columns = maxi(1, int(food_grid.size.x / 112)))
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
		breakdown.custom_minimum_size.y = 28
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
			segment.color = Color(child.get("colour", "b38a35"))
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.size_flags_stretch_ratio = maxf(0.01, e.quantity(child.id))
			segment.tooltip_text = "%s: %s jin" % [child.name, amount(e.quantity(child.id))]
			breakdown.add_child(segment)

	var rows: Array = []
	for key: String in {"harvested": "Produced / gathered", "adults": "Adults ate", "children": "Children ate", "spoiled": "Spoiled", "processed": "Used / ingredients"}:
		var names := {"harvested": "Produced / gathered", "adults": "Adults ate", "children": "Children ate", "spoiled": "Spoiled", "processed": "Used / ingredients"}
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
		for annual: bool in [false, true]:
			var chart := preload("res://src/ledger_chart.gd").new()
			chart.custom_minimum_size.y = 200
			chart.bars = annual
			chart.caption = "Yearly production" if annual else "Stock · last two years"
			chart.unit = str(e.goods[id].unit)
			chart.samples.assign(e.annual_histories[id] if annual else e.histories[id])
			if annual:
				chart.samples.append(Vector2(e.year, e.node_flow(id, "harvested")[2]))
			for i in chart.samples.size():
				chart.samples[i].y *= 2
			parent.add_child(chart)

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

func owns_pointer(event: InputEvent) -> bool:
	return is_visible_in_tree() and event is InputEventMouse and get_global_rect().has_point(event.position)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and current in ["food", "materials"]:
		food_up()
	if event is InputEventMouse:
		accept_event()

func _input(event: InputEvent) -> void:
	if owns_pointer(event):
		view.dragging = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and current in ["food", "materials"]:
				food_up()
			get_viewport().set_input_as_handled()
			return
	if is_visible_in_tree() and current in ["food", "materials"] and event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
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
	slot.set_meta("food_id", id)
	slot.custom_minimum_size = Vector2(104, 176)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame := skin("panelInset_beigeLight")
	slot.add_theme_stylebox_override("normal", frame)
	var spirit: bool = is_good and e.goods[id].grade == "spirit"
	if spirit:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color("e2dfc4")
		glow.border_color = Color("9babc0")
		glow.set_border_width_all(2)
		glow.shadow_color = Color(0.5, 0.65, 0.9, 0.2)
		glow.shadow_size = 3
		slot.add_theme_stylebox_override("normal", glow)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = 8
	box.offset_bottom = -8
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(box)
	var mark := label(box, "✦ Tier %d" % int(e.goods[id].spirit_tier) if spirit else "")
	mark.add_theme_font_size_override("font_size", 11)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var picture := TextureRect.new()
	picture.texture = grain_icon(id, Color(e.goods[id].colour) if is_good else GOLD)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size.y = 32
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(picture)
	var caption := label(box, title)
	caption.add_theme_font_size_override("font_size", 12)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var badge := label(box, quantity_text(e, id))
	if spirit and e.quantity(id) == 0:
		badge.text += "\nnot gathered yet"
	badge.add_theme_font_size_override("font_size", 11)
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
	var residents: Array[Dictionary] = []
	for p: Dictionary in life.people:
		if people_filter == "Hungry" and int(p.hunger) == 0:
			continue
		if people_filter not in ["All", "Hungry"] and people_filter != p.job:
			continue
		residents.append(p)
	var keys := ["name", "job", "mood", "activity"]
	residents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a[keys[sort_column]] > b[keys[sort_column]] if sort_reverse else a[keys[sort_column]] < b[keys[sort_column]])
	var rows: Array = []
	for p: Dictionary in residents:
		rows.append([p.name, p.job, life.economy.HUNGER[int(p.hunger)] if int(p.hunger) > 0 else str(p.get("mood", "content")), life.activity_text(p)])
	tree = table(parent, ["Name", "Job", "Fare", "Activity"], rows, 620)
	for i in residents.size():
		var item := tree.get_root().get_child(i)
		item.set_metadata(0, life.people.find(residents[i]))
		item.set_tooltip_text(0, "%d · %s · Cottage %d · Rice today %.1f jin" % [residents[i].age, residents[i].sex, int(residents[i].home_cottage) / 8 + 1, float(residents[i].rice_today) * 2])
		item.set_custom_color(2, Color("a23522") if int(residents[i].hunger) > 0 else Color("49612e"))
	tree.column_title_clicked.connect(func(col: int, _mouse: int) -> void:
		sort_reverse = not sort_reverse if sort_column == col else false
		sort_column = col
		refresh_values())
	tree.item_selected.connect(func() -> void:
		life.followed = int(tree.get_selected().get_metadata(0))
		close())
	label(parent, "Click a villager to follow them. Click column headings to sort.")

func section(parent: Node, title: String) -> void:
	label(parent, title, true)
	parent.add_child(HSeparator.new())

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
		["Population · adults / children", "%d / %d" % [life.people.size() - children, children]],
		["Jobs filled", filled], ["Content / well fed / plain fare", "%d / %d / %d" % [moods.content, moods["well fed"], moods["plain fare"]]],
		["Hungry", e.hungry_count], ["Ration level", "%d%%" % roundi(e.ration() * 100)]])
	section(parent, "Food by group · jin")
	label(parent, "In / out: yesterday · Net: this season · Days: village food needs")
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
	section(parent, "Production · jin")
	rows = []
	var registry := workplaces(e)
	for id: String in registry:
		var record: Dictionary = registry[id]
		rows.append([work_name(id), record.people.size(), amount(record.flow[0]), amount(record.flow[1]), work_status(record)])
	table(parent, ["Workplace", "Workers", "Today", "Season", "Status"], rows)
	section(parent, "Season & calendar")
	table(parent, ["Measure", "Value"], [["Season / day", "%s / %d" % [e.SEASONS[e.season()], e.day]], ["Days to harvest", e.days_to_harvest()], ["Harvest forecast · jin", amount(e.forecast())], ["Weather", "Poor" if e.weather < 0.8 else "Favourable"]])
	var alerts: Array[String] = []
	if e.days_left() < 30: alerts.append("Low food")
	if e.ration() < 1: alerts.append("Rationing active")
	if e.hungry_count > 0: alerts.append("%d villagers hungry" % e.hungry_count)
	if not alerts.is_empty():
		section(parent, "Alerts")
		for alert: String in alerts: label(parent, alert)
	section(parent, "Latest chronicle")
	for i in range(e.chronicle.size() - 1, maxi(-1, e.chronicle.size() - 6), -1):
		label(parent, e.chronicle[i])

	var crisis := CheckBox.new()
	crisis.text = "Pause on crisis"
	crisis.button_pressed = e.pause_on_crisis
	crisis.toggled.connect(func(value: bool) -> void: e.pause_on_crisis = value)
	var options := HBoxContainer.new()
	parent.add_child(options)
	options.add_child(crisis)

func _work(parent: Node, e: RefCounted) -> void:
	label(parent, "Y%d · Day %d · %s · %s" % [e.year, e.day, e.SEASONS[e.season()], stage()])
	var calendar := ProgressBar.new()
	calendar.max_value = 365
	calendar.value = e.day
	calendar.show_percentage = false
	calendar.custom_minimum_size.y = 8
	parent.add_child(calendar)
	label(parent, "Spring: plant · Summer: tend · Autumn: harvest · Winter: fallow")
	var registry := workplaces(e)
	var groups: Dictionary = {}
	for id: String in registry:
		var group := work_group(id)
		if not groups.has(group): groups[group] = []
		groups[group].append(id)
	for group: String in groups:
		section(parent, group)
		var grid := GridContainer.new()
		grid.columns = maxi(2, int((get_viewport_rect().size.x * 0.5 - 48) / 280))
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		parent.add_child(grid)
		for id: String in groups[group]:
			var record: Dictionary = registry[id]
			var card := button(grid, "", func() -> void: selected_work = id; refresh_values())
			card.set_meta("work_id", id)
			card.custom_minimum_size = Vector2(264, 112)
			card.size_flags_horizontal = Control.SIZE_FILL
			card.add_theme_stylebox_override("normal", skin("panelInset_beigeLight"))
			var box := VBoxContainer.new()
			card.add_child(box)
			box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			box.offset_left = 8
			box.offset_right = -8
			box.offset_top = 8
			box.offset_bottom = -8
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_theme_constant_override("separation", 3)
			var heading := HBoxContainer.new()
			box.add_child(heading)
			var picture := TextureRect.new()
			picture.texture = grain_icon(record.goods[0], Color(e.goods[record.goods[0]].colour)) if not record.goods.is_empty() else icon("people")
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.custom_minimum_size = Vector2(24, 24)
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			heading.add_child(picture)
			var name_label := label(heading, work_name(id))
			name_label.add_theme_font_size_override("font_size", 14)
			var status := label(heading, "●")
			status.size_flags_horizontal = Control.SIZE_SHRINK_END
			status.autowrap_mode = TextServer.AUTOWRAP_OFF
			status.add_theme_color_override("font_color", Color("49612e") if work_status(record) == "working" else GOLD)
			var summary := HBoxContainer.new()
			box.add_child(summary)
			label(summary, "%d workers" % record.people.size()).add_theme_font_size_override("font_size", 13)
			var use_yesterday: bool = record.flow[0] == 0 or fmod(life.minutes, 1440.0) < 390
			var totals: Dictionary = {}
			for good: String in record.goods:
				var unit := "pcs" if e.goods[good].unit == "pieces" else str(e.goods[good].unit)
				var value: float = e.yesterday_flow(good, "harvested") if use_yesterday else e.node_flow(good, "harvested")[0]
				totals[unit] = float(totals.get(unit, 0.0)) + value
			var output: Array[String] = []
			for unit: String in totals: output.append(amount(totals[unit]) + " " + unit)
			label(summary, ("yesterday " if use_yesterday else "today ") + " · ".join(output)).add_theme_font_size_override("font_size", 12)
			var effectiveness := ProgressBar.new()
			effectiveness.show_percentage = false
			effectiveness.custom_minimum_size.y = 4
			for style_name: String in ["background", "fill"]:
				var thin := StyleBoxFlat.new()
				thin.bg_color = GOLD if style_name == "fill" else Color("baa77b")
				effectiveness.add_theme_stylebox_override(style_name, thin)
			var total := 0.0
			for person: Dictionary in record.people: total += e.EFFECT[int(person.hunger)]
			effectiveness.value = total / maxf(1, record.people.size()) * 100
			card.tooltip_text = "%s · %d workers / no capacity limit\nEffectiveness: %d%%" % [work_name(id), record.people.size(), roundi(effectiveness.value)]
			box.add_child(effectiveness)
			for child: Control in box.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not registry.has(selected_work): return
	var chosen: Dictionary = registry[selected_work]
	section(parent, work_name(selected_work) + " · details")
	label(parent, "Schedule: prepare 05:30–06:30 · work 06:30–18:00 · meal 12:00–13:00 · rest until 21:00. Resident offsets: up to 60 minutes. Harvest and hunger can change assignments.")
	for person: Dictionary in chosen.people:
		button(parent, person.name + " · " + life.activity_text(person), func() -> void:
			life.followed = life.people.find(person)
			close())
	table(parent, ["Output · jin", "Today", "Season", "Year"], [["Produced", amount(chosen.flow[0]), amount(chosen.flow[1]), amount(chosen.flow[2])]])
	if selected_work == "fields":
		var rows: Array = []
		var index := 0
		for field: Dictionary in life.sect.data.fields:
			index += 1
			var area := int(field.rect[2]) * int(field.rect[3])
			rows.append(["Plot %d" % index, e.goods[field.crop].name, stage(), "%d%%" % roundi(e.care() * 100), amount(e.good_forecast(field.crop) * area / maxf(1, e.areas[field.crop]))])
		table(parent, ["Plot", "Crop", "Stage", "Care", "Yield · jin"], rows)

func show_granary() -> void:
	for child: Node in granary_card.get_children():
		granary_card.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	granary_card.add_child(box)
	label(box, "Granary · %s jin of food · %d days" % [amount(life.economy.stock), floori(life.economy.days_left())])
	button(box, "Open ledger", func() -> void: granary_card.hide(); open_tab("food"))
	button(box, "Close", granary_card.hide)
	granary_card.show()
