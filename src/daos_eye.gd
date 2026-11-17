extends PanelContainer
## The Dao's Eye: the all-seeing finder. One centred page over the dimmed world,
## opened with [E]. Read-only: it inspects the world and never changes it.
const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const Ledger = preload("res://src/village_ledger.gd")
const TABS := {"people": "People", "beasts": "Beasts", "wild": "Herbs & materials", "places": "Places", "dead": "The dead", "world": "World ledger", "laws": "The laws"}
const RANKS := ["Strength", "Age", "Years left", "Contribution", "Purity", "Residue", "Strain"]
const ONLY := {"cultivators": "Cultivators", "mortals": "Mortals", "children": "Children", "injured": "Injured", "women": "Women", "men": "Men", "wants": "Wants purer qi"}
const MAX_WIDTH := 1320.0
var laws_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/laws.json"))
var book: PanelContainer
var view: Node2D
var life: Node2D
var dim: ColorRect
var content: VBoxContainer
var drawer_scroll: ScrollContainer
var tab_buttons: Dictionary = {}
var current := "people"
var where := "all"
var rank := "Strength"
var only: Dictionary = {}
var closing := false
var slide: Tween
var listed := PackedInt32Array()
var query := ""
var selected := -1
var this_year := false
var law_book := "Heaven’s laws"
var selected_law := 0
var village_bounds := Rect2()
var search: LineEdit
var back_button: Button
var date_label: Label

func setup(ledger: PanelContainer) -> void:
	book = ledger
	view = book.view
	life = book.life
	# Use the actual village footprint from the site's houses and named plaza.
	var sect: RefCounted = view.map.ground.sect
	for building: Dictionary in sect.data.get("village", []) + sect.data.get("buildings", []):
		if building not in sect.data.get("village", []) and building.get("name", "") != "Servants' Village": continue
		var r: Array = building.rect
		var footprint := Rect2(Vector2(sect.center) + Vector2(r[0], r[1]), Vector2(r[2], r[3]))
		village_bounds = footprint if not village_bounds.has_area() else village_bounds.merge(footprint)
	village_bounds = village_bounds.grow(UiTheme.SPACE_16)
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
	get_viewport().size_changed.connect(func() -> void:
		_layout()
		if visible: refresh.call_deferred())
	_layout()
	var page := VBoxContainer.new()
	add_child(page)
	var top := HBoxContainer.new()
	page.add_child(top)
	var title := label(top, "The Dao's Eye")
	title.theme_type_variation = "Heading"
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	button(top, "Esc ✕", close)
	date_label = small(page, "")
	var links := HFlowContainer.new()
	page.add_child(links)
	back_button = button(links, "← Back to the Dao's Eye", func() -> void: open_tab("people"))
	for key: String in ["world", "laws"]:
		button(links, TABS[key] + " →", func() -> void: open_tab(key))
	for caption: String in ["World qi · soon", "Treasury · soon"]:
		button(links, caption, func() -> void: pass).disabled = true
	search = LineEdit.new()
	search.placeholder_text = "Find by name"
	page.add_child(search)
	search.text_changed.connect(func(value: String) -> void: query = value; refresh())
	var tabs := HFlowContainer.new()
	page.add_child(tabs)
	for key: String in ["people", "beasts", "wild", "places", "dead"]:
		var tab := button(tabs, TABS[key], func() -> void: open_tab(key))
		tab.theme_type_variation = "Chip"
		tab.toggle_mode = true
		tab_buttons[key] = tab
	drawer_scroll = ScrollContainer.new()
	drawer_scroll.mouse_force_pass_scroll_events = false
	drawer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(drawer_scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UiTheme.SPACE_16)
	drawer_scroll.add_child(content)
	hide()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--eye="):
			open_tab(arg.trim_prefix("--eye="))

func _layout() -> void:
	var screen := get_viewport_rect().size
	var width := minf(MAX_WIDTH, screen.x - 96)
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = floorf((screen.x - width) / 2.0)
	offset_right = -offset_left
	offset_top = 68
	offset_bottom = -20

func content_width() -> float:
	return minf(MAX_WIDTH, get_viewport_rect().size.x - 96) - 72

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
	var node := Button.new()
	node.text = text
	node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func section(parent: Node, title: String) -> void:
	label(parent, title, true)

func table(parent: Node, headers: Array, rows: Array) -> Tree:
	var widget := Tree.new()
	widget.columns = headers.size()
	widget.hide_root = true
	widget.column_titles_visible = true
	widget.custom_minimum_size.y = maxf(60, (rows.size() + 1) * 30)
	widget.scroll_vertical_enabled = false
	widget.scroll_horizontal_enabled = false
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var available := maxf(400, content_width() - 16)
	for i in headers.size():
		var share := (0.3 if i == 0 else 0.7 / (headers.size() - 1)) if headers.size() > 2 else 0.5
		widget.set_column_title(i, headers[i])
		widget.set_column_expand(i, false)
		widget.set_column_custom_minimum_width(i, int(available * share))
	var root := widget.create_item()
	for row: Array in rows:
		var item := widget.create_item(root)
		for i in row.size():
			item.set_text(i, str(row[i]))
			item.set_tooltip_text(i, str(row[i]))
			item.set_text_overrun_behavior(i, TextServer.OVERRUN_TRIM_ELLIPSIS)
	parent.add_child(widget)
	return widget

func owns_pointer(event: InputEvent) -> bool:
	return is_visible_in_tree() and not closing and event is InputEventMouse

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		accept_event()

func toggle() -> void:
	if visible and not closing:
		close()
	else:
		open_tab(current)

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

func open_tab(key: String) -> void:
	if not visible or closing:
		closing = false
		if slide:
			slide.kill()
		modulate.a = 0.0
		slide = create_tween()
		slide.tween_property(self, "modulate:a", 1.0, 0.14)
	current = key if TABS.has(key) else "people"
	for tab: String in tab_buttons:
		tab_buttons[tab].set_pressed_no_signal(tab == current)
	if book.visible:
		book.close()
	_layout()
	dim.show()
	show()
	refresh()
	drawer_scroll.scroll_vertical = 0

## A person's seat in the world, as Heaven sorts them: the Palace, or the valley below.
func place_of(p: int) -> String:
	var s: RefCounted = life.population.society
	if s.fifty and s.fifty.member(p): return "the Palace"
	for id: int in s.memberships.get(p, PackedInt32Array()):
		if s.factions[id].type == "sect": return "the sect"
	var at: Vector2 = life.population.locations[p]
	return "the village" if village_bounds.has_point(at) else "the wild"

func is_cultivator(p: int) -> bool:
	var s: RefCounted = life.population.society
	return s.realm[p] > 0 or s.meridian_store.slot[p] >= 0 or (s.temper and s.temper.body_layer[p] > 0)

func wants_purer(p: int) -> bool:
	var s: RefCounted = life.population.society
	var records: Variant = s.qi_practice.get("records")
	if records is Dictionary:
		return bool((records as Dictionary).get(p, {}).get("wants_purer_qi", false))
	return false

## [sort key descending, words shown beside the name]. Everyone has a strength;
## meridian measures exist only for those who practise.
func measure(p: int) -> Array:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	var ms: RefCounted = s.meridian_store
	match rank:
		"Age":
			return [float(store.age(p)), "%d years" % store.age(p)]
		"Years left":
			var left: int = s.lifespan(p) - store.age(p)
			return [-float(left), "about %d years left" % maxi(0, left)]
		"Contribution":
			return [0.0, "Contribution · not recorded"]
		"Purity", "Residue", "Strain":
			if ms.slot[p] < 0:
				return []
			var report: Dictionary = ms.report(p)
			if rank == "Purity":
				return [float(report.purity), "purity %.2f" % report.purity]
			if rank == "Residue":
				var load: float = float(report.residue) / maxi(1, int(report.capacity))
				return [load, "residue %.1f%% of the dantian" % (load * 100)]
			var worst: float = report.strain
			return [worst, "strain %.2f" % worst]
	var qc := 0
	if ms.slot[p] >= 0:
		qc = ms.integers[ms.slot[p] * ms.PERSON_INTS + ms.PersonInt.LAYER]
	var body: int = s.temper.body_layer[p] if s.temper else 0
	var key := float(qc) * 1e12 + float(body) * 1e9 + float(ms.integers[ms.slot[p] * ms.PERSON_INTS + ms.PersonInt.RESERVE] if ms.slot[p] >= 0 else s.qi[p])
	return [key, "certified %d · body %d · reserve %.1f" % [qc, body, float(ms.integers[ms.slot[p] * ms.PERSON_INTS + ms.PersonInt.RESERVE]) / 1000.0 if ms.slot[p] >= 0 else s.qi[p]]]

func chip_row(parent: Node, title: String, names: Array, chosen: Callable, pick: Callable) -> void:
	var row := HFlowContainer.new()
	parent.add_child(row)
	small(row, title)
	for name: String in names:
		var caption := name
		if title == "Where":
			var count := 0
			for p in life.population.size():
				if life.population.society.alive[p] and (name == "Everywhere" or place_of(p).to_lower() == name.to_lower()): count += 1
			caption += " · %d" % count
		var chip := button(row, caption, func() -> void: pick.call(name); refresh())
		chip.theme_type_variation = "Hot" if chosen.call(name) else "Chip"

func refresh() -> void:
	date_label.text = "Year %d · day %d · nothing is hidden from you" % [life.population.day / 365 + 1, life.population.day % 365 + 1]
	back_button.visible = current in ["world", "laws"]
	search.visible = current in ["people", "dead"]
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	_tiles(content)
	match current:
		"people": _people(content)
		"beasts": _beasts(content)
		"wild": _wild(content)
		"places": _places(content)
		"dead": _dead(content)
		"world": _world(content)
		"laws": _laws(content)
	_group_cards()

## The same parchment-card rhythm as the valley book.
func _group_cards() -> void:
	var box: VBoxContainer
	for child: Node in content.get_children().slice(1):
		if box == null or (child is Label and child.theme_type_variation == "Title"):
			var card := PanelContainer.new()
			card.theme_type_variation = "CardPanel"
			content.add_child(card)
			box = VBoxContainer.new()
			box.add_theme_constant_override("separation", UiTheme.SPACE_12)
			card.add_child(box)
		child.reparent(box)

func _counts() -> Dictionary:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	var living := 0
	var born := 0
	var palace_dead := 0
	for p in store.size():
		if not s.alive[p] and s.fifty.people.has(p): palace_dead += 1
		if s.alive[p]: living += 1
		if store.parent_id[p] >= 0 and store.birth_day[p] >= 0: born += 1
	return {"living": living, "born": born, "died": store.size() - living - palace_dead + maxi(palace_dead, s.fifty.deaths)}

func _tiles(parent: Node) -> void:
	var s: RefCounted = life.population.society
	var tolls := _counts()
	var field: RefCounted = s.qi_field
	# Ledger.amount doubles (rations to jin), so halve the QU before formatting.
	var values: Array = [[tolls.living, "Living people"], [tolls.born, "Born"], [tolls.died, "Died"], [s.wildlife.summary().total, "Beasts"], ["%.0f" % (s.temper.wild.herbs + s.temper.wild.bark_total()), "Wild medicine"], [Ledger.amount(field.world_totals().total / 2000.0), "World qi · QU"], [known_places().size(), "Places"]]
	var row := HFlowContainer.new()
	parent.add_child(row)
	for value: Array in values:
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.custom_minimum_size.x = 144
		row.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		small(box, str(value[1]))
		label(box, str(value[0]), true)

func _people(parent: Node) -> void:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	section(parent, "Everyone under Heaven")
	chip_row(parent, "Where", ["Everywhere", "The village", "The sect", "The Palace", "The wild"],
		func(name: String) -> bool: return {"Everywhere": "all", "The village": "village", "The sect": "sect", "The Palace": "palace", "The wild": "wild"}[name] == where,
		func(name: String) -> void: where = {"Everywhere": "all", "The village": "village", "The sect": "sect", "The Palace": "palace", "The wild": "wild"}[name])
	chip_row(parent, "Rank by", RANKS,
		func(name: String) -> bool: return name == rank,
		func(name: String) -> void: rank = name)
	chip_row(parent, "Only", ONLY.values(),
		func(name: String) -> bool: return only.get(ONLY.find_key(name), false),
		func(name: String) -> void:
			var key: String = ONLY.find_key(name)
			only[key] = not only.get(key, false))
	var questions := HFlowContainer.new()
	parent.add_child(questions)
	small(questions, "Quick questions")
	button(questions, "Clear filters", func() -> void:
		where = "all"
		only.clear()
		query = ""
		search.text = ""
		rank = "Strength"
		refresh()).theme_type_variation = "Chip"
	for ask: Array in [["The strongest in the village", "village", "Strength", {}], ["The strongest anywhere", "all", "Strength", {}], ["Who is straining", "all", "Strain", {}], ["Who wants purer qi", "all", "Strength", {"wants": true}], ["Who is closest to death", "all", "Years left", {}]]:
		button(questions, ask[0], func() -> void:
			where = ask[1]
			rank = ask[2]
			only = (ask[3] as Dictionary).duplicate()
			refresh()).theme_type_variation = "Chip"
	listed = people_ids()
	small(parent, "%d match · pick a row to see it in full." % listed.size())
	if listed.is_empty(): small(parent, "Nothing here matches. Loosen a filter or widen Where.")
	var columns := HBoxContainer.new()
	parent.add_child(columns)
	var results := preload("res://src/people_list.gd").new()
	columns.add_child(results)
	results.row_summary = func(p: int) -> String: return place_of(p) + " · " + str(measure(p)[1])
	results.setup(store, listed)
	results.person_selected.connect(func(p: int) -> void: selected = p; refresh())
	if not listed.has(selected): selected = listed[0] if not listed.is_empty() else -1
	var card := VBoxContainer.new()
	card.custom_minimum_size.x = 270
	columns.add_child(card)
	if selected >= 0:
		label(card, store.names[selected], true)
		label(card, place_of(selected))
		label(card, preload("res://src/person_book.gd").path_stage(store, selected))
		label(card, "%d of ~%d years" % [store.age(selected), s.lifespan(selected)])
		label(card, str(measure(selected)[1]))
		button(card, "Open their book", func() -> void: book.open_person(selected, "Overview"))

func strength_parts(p: int) -> Array:
	var s: RefCounted = life.population.society
	var ms: RefCounted = s.meridian_store
	var row: int = ms.slot[p]
	return [ms.integers[row * ms.PERSON_INTS + ms.PersonInt.LAYER] if row >= 0 else 0, s.temper.body_layer[p] if s.temper else 0, ms.integers[row * ms.PERSON_INTS + ms.PersonInt.RESERVE] if row >= 0 else s.qi[p]]

func people_ids() -> PackedInt32Array:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	var ranked: Array = []
	for p in store.size():
		if not s.alive[p]: continue
		if not query.is_empty() and not query.to_lower() in store.names[p].to_lower(): continue
		if where != "all" and place_of(p).to_lower() != "the " + where: continue
		if only.get("cultivators", false) and not is_cultivator(p): continue
		if only.get("mortals", false) and is_cultivator(p): continue
		if only.get("children", false) and store.age(p) >= 18: continue
		if only.get("women", false) and store.sex[p] != 1: continue
		if only.get("men", false) and store.sex[p] != 0: continue
		if only.get("injured", false) and not (s.damage[p] < 0.85 or s.injury_until[p] > store.day): continue
		if only.get("wants", false) and not wants_purer(p): continue
		var value := measure(p)
		if not value.is_empty(): ranked.append([strength_parts(p) if rank == "Strength" else [value[0]], p])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		for i in a[0].size():
			if a[0][i] != b[0][i]: return a[0][i] > b[0][i]
		return a[1] < b[1])
	var ids := PackedInt32Array()
	for entry: Array in ranked: ids.append(entry[1])
	return ids

func beast_territory(wildlife: RefCounted, species: String) -> String:
	var places: Dictionary = {}
	for i in wildlife.cells.size():
		if wildlife.cohort_count(i, species) > 0: places[wildlife.place({"cell": i})] = true
	for beast: Dictionary in wildlife.individuals:
		if beast.alive and beast.species == species: places[wildlife.place(beast)] = true
	return ", ".join(PackedStringArray(places.keys()))

func _beasts(parent: Node) -> void:
	var wl: RefCounted = life.population.society.wildlife
	var summary: Dictionary = wl.summary()
	section(parent, "The wild under Heaven")
	label(parent, "%d animals · %d awakened · %d births and %d taken by predators since the world began." % [summary.total, summary.awakened, summary.events.get("births", 0), summary.events.get("predation", 0)])
	section(parent, "Populations")
	var rows: Array = []
	for species: Dictionary in wl.species:
		var count: int = wl.count(species.sci)
		if count <= 0: continue
		rows.append([preload("res://src/law.gd").title(str(species.name)), count, beast_territory(wl, str(species.sci)), wl.role(species), "high" if float(species.get("danger", 0)) >= 2 else ("defensive" if float(species.get("danger", 0)) > 0 else "low")])
	table(parent, ["Beast", "Numbers", "Territory", "Kind", "Threat"], rows)
	section(parent, "Awakened and notable")
	var found := false
	for beast: Dictionary in wl.individuals:
		if not beast.alive or not (beast.awakened or beast.get("notable", false)): continue
		found = true
		label(parent, preload("res://src/law.gd").title(str(beast.name)) + (" · awakened" if beast.awakened else ""))
		small(parent, "%s · roams %s · %s" % [wl.description(beast), wl.place(beast), beast.state])
	if not found:
		small(parent, "No beast has yet risen above the rest.")

func _wild(parent: Node) -> void:
	var s: RefCounted = life.population.society
	var e: RefCounted = life.economy
	if s.temper:
		var wild: RefCounted = s.temper.wild
		var config: Dictionary = wild.config
		section(parent, "Medicine growing wild")
		var bark := 0.0
		for stock: float in wild.patch_stock: bark += stock
		label(parent, "Iron-bark in the patches: %.0f roots · huntable herd: %.0f · seven-leaf at %s: %.0f herbs." % [bark, wild.herd, str(config.seven_leaf.place), floorf(wild.herbs)])
		var growth: Array = []
		for i in wild.patch_stock.size(): growth.append(["Iron-bark", str(config.iron_bark.patches[i]), "%.0f" % wild.patch_stock[i], "No"])
		growth.append(["Seven-leaf", str(config.seven_leaf.place), "%.0f" % wild.herbs, "Yes"])
		table(parent, ["What", "Where", "How much", "Qi-rich"], growth)
		var wanting: Dictionary = s.temper.summary().wanting
		for id: String in wanting:
			small(parent, "%d waiting on %s for a gate." % [wanting[id], s.temper.config.medicine_names[id]])
	section(parent, "Stores of the valley")
	var rows: Array = []
	for category: Dictionary in e.catalogue.categories:
		if category.parent in ["food", "materials"]:
			rows.append([category.name, book.quantity_text(e, category.id), Ledger.amount(e.node_flow(category.id, "harvested")[2])])
	table(parent, ["Group", "Stored", "This year in"], rows)
	section(parent, "Materials in store")
	var materials: Array = []
	for id: String in e.goods:
		var good: Dictionary = e.goods[id]
		if "materials" in good.category_path:
			materials.append([good.name, good.store, "%s %s" % [Ledger.amount(e.stocks[id]), good.unit], "Yes" if good.grade == "spirit" else "No"])
	table(parent, ["What", "Where", "How much", "Qi-rich"], materials)
	section(parent, "Spirit goods")
	var listed_any := false
	for id: String in e.goods:
		if e.goods[id].grade == "spirit":
			listed_any = true
			small(parent, "%s · tier %d · %s" % [e.goods[id].name, int(e.goods[id].spirit_tier), ("%s in store" % Ledger.amount(e.stocks[id])) if e.stocks[id] > 0 else "not yet gathered"])
	if not listed_any:
		small(parent, "Nothing of spirit grade is known yet.")

func known_places() -> Dictionary:
	var places: Dictionary = {}
	for feature: Dictionary in view.map.data.features:
		places[str(feature.name)] = {"position": Vector2(float(feature.x), float(feature.y)) * 16.0, "kind": str(feature.kind)}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/index.json"))
	for name: String in manifest.destinations:
		var coordinates: Array = manifest.destinations[name]
		places[name] = {"position": Vector2(coordinates[0], coordinates[1]), "kind": "destination"}
	var landmarks: Dictionary = life.population.society.qi_field.landmarks
	for spec: Array in [["Servants' Village", "Village", "village"], [str(view.map.ground.sect.data.name), "Sect", "sect"], ["Heavenly Dao Palace", "Palace", "estate"]]:
		places[spec[0]] = {"position": landmarks[spec[1]], "kind": spec[2]}
	return places

func _places(parent: Node) -> void:
	var s: RefCounted = life.population.society
	var store: RefCounted = life.population
	var field: RefCounted = s.qi_field
	for name: String in ["Palace", "Sect", "Village"]:
		section(parent, {"Palace": "The Heavenly Dao Palace", "Sect": "The sect", "Village": "Servants' Village"}[name])
		label(parent, field.describe(field.landmarks[name]))
		var sample: Dictionary = field.sample(field.landmarks[name])
		small(parent, "Purity %.1f%% · corruption %.1f%% · %.1f QU in this cell" % [sample.purity * 100.0, sample.corruption * 100.0, sample.quantity / 1000.0])
		var count := 0
		for p in store.size():
			if s.alive[p] and place_of(p).to_lower() == "the " + name.to_lower(): count += 1
		small(parent, "%d people · %s" % [count, {"Palace": "estate", "Sect": "sect settlement", "Village": "village settlement"}[name]])
	section(parent, "Named places")
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/index.json"))
	var rows: Array = []
	var kinds: Dictionary = {}
	var sources: Array = [view.map.ground.sect.data]
	for file: String in index.sites:
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/" + file))
		if source is Dictionary:
			sources.append(source)
			kinds[str(source.get("name", file))] = "road" if source.has("surface") else ("estate" if source.has("zone_budgets") else "city" if file == "city.json" else "settlement")
	for source: Dictionary in sources:
		for building: Dictionary in source.get("buildings", []):
			if not str(building.get("name", "")).is_empty(): kinds[building.name] = building.kind
	var places := known_places()
	for name: String in places:
		var at: Vector2 = places[name].position
		var residents := 0
		for p in store.size():
			if s.alive[p] and store.locations[p].distance_to(at) < 50: residents += 1
		rows.append([name, kinds.get(name, places[name].kind), residents, field.describe(at)])
	table(parent, ["Name", "Kind", "Who lives nearby", "Local qi"], rows)

func archived_events() -> Array:
	var s: RefCounted = life.population.society
	var events: Array = []
	var archive: RefCounted = s.archive
	if archive:
		for year: String in DirAccess.get_directories_at(archive.root):
			for file: String in DirAccess.get_files_at(archive.root.path_join(year)):
				if not file.begins_with("events") or not file.ends_with(".gz"): continue
				var bytes := FileAccess.get_file_as_bytes(archive.root.path_join(year).path_join(file))
				for line: String in bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8().split("\n", false):
					var event: Variant = JSON.parse_string(line)
					if event is Dictionary: events.append(event)
		for lines: PackedStringArray in archive.pending.values():
			for line: String in lines: events.append(JSON.parse_string(line))
	events.append_array(s.chronicle)
	return events

func death_records() -> Array:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	var seen: Dictionary = {}
	var people: Dictionary = {}
	var rows: Array = []
	for event: Dictionary in archived_events():
		var p := int(event.get("person", -1))
		if p < 0 or p >= store.size(): continue
		var kind := str(event.get("kind", ""))
		var words := str(event.get("text", ""))
		if kind not in ["killed", "old_age", "death", "road_death", "cultivation_death"] and not (kind == "dao" and " died " in words): continue
		var day := int(event.day)
		var key := "%d:%d:%s" % [p, day, words]
		if seen.has(key): continue
		seen[key] = true
		people[p] = true
		rows.append({"person": p, "name": store.names[p], "day": day, "cause": words, "age": store.age(p, day)})
	# Old saves may predate the archive; preserve their dead without inventing dates.
	for p in store.size():
		if not s.alive[p] and not people.has(p): rows.append({"person": p, "name": store.names[p], "day": -1, "cause": "Not recorded in the archive", "age": -1})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.day) > int(b.day) or (a.day == b.day and a.person < b.person))
	return rows

func _dead(parent: Node) -> void:
	section(parent, "The dead")
	var rows: Array = []
	for record: Dictionary in death_records():
		if not query.is_empty() and not query.to_lower() in str(record.name).to_lower(): continue
		rows.append([record.name, record.day if record.day >= 0 else "Unrecorded", record.cause, record.age if record.age >= 0 else "Unrecorded"])
	table(parent, ["Name", "Died day", "Cause", "Age"], rows)

func cause_group(words: String) -> String:
	var text := words.to_lower()
	if "old age" in text: return "Old age"
	if "swordsman" in text or "guardian" in text: return "The law"
	if "pilgrimage" in text or "road" in text: return "The road"
	if "deviation" in text: return "Qi deviation"
	if "hunting" in text or "wolf" in text or "boar" in text or "tiger" in text or "bear" in text: return "Beasts"
	if "sickness" in text: return "Sickness"
	if "childbirth" in text: return "Childbirth"
	if "killed" in text: return "Fights"
	return "Unrecorded"

func _world(parent: Node) -> void:
	var store: RefCounted = life.population
	var s: RefCounted = store.society
	var field: RefCounted = s.qi_field
	section(parent, "World ledger")
	chip_row(parent, "Period", ["This year", "All time"], func(n: String) -> bool: return this_year == (n == "This year"), func(n: String) -> void: this_year = n == "This year")
	var since: int = store.day / 365 * 365 if this_year else -2147483648
	var births := 0
	for p in store.size():
		if store.parent_id[p] >= 0 and store.birth_day[p] >= maxi(0, since): births += 1
	var causes: Dictionary = {}
	var deaths := 0
	for record: Dictionary in death_records():
		if int(record.day) < since: continue
		deaths += 1
		var cause := cause_group(str(record.cause))
		causes[cause] = int(causes.get(cause, 0)) + 1
	label(parent, "Born %d · Died %d · Living now %d" % [births, deaths, _counts().living])
	section(parent, "How people died")
	for cause: String in causes: small(parent, "%s · %d" % [cause, causes[cause]])
	section(parent, "The qi of the world")
	var totals: Dictionary = field.world_totals()
	label(parent, "%.1f QU in all: %.1f in the land and %.1f held in veins." % [totals.total / 1000.0, totals.land / 1000.0, totals.veins / 1000.0])
	section(parent, "By element")
	var shares: Array[String] = []
	for e in 5: shares.append("%s %.1f%%" % [["Metal", "Wood", "Water", "Fire", "Earth"][e], 100.0 * totals.elements[e] / maxi(1, totals.total)])
	label(parent, ", ".join(shares))
	var ledger: Dictionary = field.ledger
	label(parent, "Today: veins poured out %.1f QU; dispersed %.1f; drawn by living things %.1f; unaccounted = %d." % [ledger.source_output / 1000.0, ledger.dispersion / 1000.0, ledger.withdrawals / 1000.0, ledger.residual])
	var active: Array[String] = []
	for decree: Dictionary in field.decrees():
		active.append("%s: %s (%.1f Will/year)" % [decree.id, "sealed" if int(decree.level) == 0 else "%d%% open" % decree.level, decree.upkeep])
	label(parent, "Decrees: " + ("none" if active.is_empty() else "; ".join(active)))
	section(parent, "People by place")
	var places: Dictionary = {}
	for p in store.size():
		if s.alive[p]: places[place_of(p)] = int(places.get(place_of(p), 0)) + 1
	for place: String in places: label(parent, "%s · %d" % [place, places[place]])
	section(parent, "Greatest veins")
	var veins: Array = field._nodes.duplicate()
	veins.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.reserve) > int(b.reserve))
	for vein: Dictionary in veins.slice(0, 5): small(parent, "%s · %.1f QU" % [vein.id, int(vein.reserve) / 1000.0])
	section(parent, "The wild")
	label(parent, "%d beasts · %d awakened" % [s.wildlife.summary().total, s.wildlife.summary().awakened])
	section(parent, "Milestones")
	var first_layers: Dictionary = {}
	for entry: Dictionary in archived_events():
		if str(entry.kind) != "breakthrough": continue
		var key := str(entry.text).get_slice(" certified the ", 1)
		if key.is_empty(): continue
		if not first_layers.has(key) or int(entry.day) < int(first_layers[key].day): first_layers[key] = entry
	var milestones: Array = first_layers.values()
	milestones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.day) < int(b.day))
	for entry: Dictionary in milestones: small(parent, "Day %d · %s" % [entry.day, entry.text])
	if milestones.is_empty(): small(parent, "No certified breakthrough yet. The first is worth watching for.")

func _laws(parent: Node) -> void:
	var s: RefCounted = life.population.society
	section(parent, "The laws")
	label(parent, "Heaven's laws bind everything that lives, grows or flows. Nothing can break them. The laws of men are rules people set for each other, and people break those every day.")
	chip_row(parent, "Which laws", ["Heaven’s laws", "Laws of the valley", "Rules of your Palace"], func(n: String) -> bool: return law_book == n, func(n: String) -> void: law_book = n; selected_law = 0)
	var rows: Array = []
	match law_book:
		"Heaven’s laws":
			for rule: Dictionary in laws_config.heaven: rows.append([rule.law, rule.consequence, rule.status])
		"Laws of the valley":
			var rules: Dictionary = s.law.config
			for id: String in rules.offences:
				rows.append([str(rules.offences[id]).capitalize(), "Offence weight · " + str(rules.weights.get(id, "not specified")), "In force"])
			rows.append(["Work passes", "%02d:%02d–%02d:%02d · radius %d tile · adult from %d" % [int(rules.work_start) / 60, int(rules.work_start) % 60, int(rules.work_end) / 60, int(rules.work_end) % 60, int(rules.pass_radius), int(rules.adult_age)], "In force"])
			rows.append(["Enforcement", "Sight %d tiles by day / %d at night · detection %.0f%% / %.0f%%" % [int(rules.day_sight), int(rules.night_sight), float(rules.day_seen)*100, float(rules.night_seen)*100], "In force"])
		"Rules of your Palace":
			var rules: Dictionary = s.fifty.config
			rows.append(["Qualification", "Ages %d–%d · admission score %d. Apostle selection follows the Palace's challenges." % [int(rules.admission.age_min), int(rules.admission.age_max), int(rules.admission.threshold)], "In force"])
			rows.append(["The five-year tournament", "Ranked every %d years · next tournament day %d" % [int(rules.tournament_years), s.fifty.next_tournament], "In force"])
			rows.append(["Restoration", "A fallen Apostle rests %d years and returns for %d Will and %d heaven-stone." % [int(rules.restore_years), int(rules.restore_will), int(rules.restore_stone)], "In force"])
			rows.append(["Call to Heaven", "May sound every %d days." % int(rules.call_days), "In force"])
	var columns := HBoxContainer.new()
	parent.add_child(columns)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(list)
	for i in rows.size():
		var index := i
		button(list, "%d · %s · %s" % [i+1, rows[i][0], rows[i][2]], func() -> void: selected_law = index; refresh()).theme_type_variation = "Chip"
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 320
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(detail)
	if not rows.is_empty():
		selected_law = clampi(selected_law, 0, rows.size()-1)
		small(detail, rows[selected_law][2])
		label(detail, rows[selected_law][0], true)
		label(detail, rows[selected_law][1])
