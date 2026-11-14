extends VBoxContainer
## One personal record: cultivation first, with supporting skills and separate heart and ties cards.
const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const EgoGraph = preload("res://src/ego_graph.gd")
const BodyFigure = preload("res://src/body_figure.gd")
const AttributeMeter = preload("res://src/attribute_meter.gd")
const TABS := ["Overview", "Cultivation", "Heart & ties"]
const OLD_TABS := {"Story": "Overview", "Body & cultivation": "Cultivation", "Skills": "Cultivation", "Heart & mind": "Heart & ties", "Family & lineage": "Heart & ties", "Ties": "Heart & ties"}
var browser: VBoxContainer
var ledger: PanelContainer
var population: RefCounted
var society: RefCounted
var person := -1


func build(owner_browser: VBoxContainer) -> void:
	browser = owner_browser
	ledger = browser.ledger
	population = browser.population
	society = population.society
	person = browser.person
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", UiTheme.SPACE_8)
	_header()
	if society.fifty.open_places() > 0 and society.fifty.eligible(person):
		ledger.button(self, "Invite to the Dao", func() -> void: society.fifty.invite(person); ledger.life._tend_the_dead(); browser.redraw())
	var tab: String = browser.person_tab if browser.person_tab in TABS else str(OLD_TABS.get(browser.person_tab, "Overview"))
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UiTheme.SPACE_8)
	add_child(page)
	match tab:
		"Overview":
			var overview := _card(page, "Life in the valley")
			_lifespan(overview)
			text(overview, "Household · " + population.household_name(person))
			text(overview, "Path · " + path_stage(population, person))
			var tags := HFlowContainer.new()
			overview.add_child(tags)
			browser.tags(tags, person)
			var walker: int = ledger.life.walker_of(person)
			if walker >= 0: text(overview, "Current activity · " + str(ledger.life.people[walker].get("activity", "living in the valley")))
			_story(_card(page, "Story and recent events"))
		"Cultivation":
			var cultivation := _card(page, "Cultivation")
			_lifespan(cultivation)
			_body(cultivation)
			_skills(_card(page, "Supporting skills"))
		"Heart & ties":
			_mind(_card(page, "Heart and mind"))
			_family(_card(page, "Family and lineage"))
			_ties(_card(page, "Ties and grudges"))

func _card(parent: Node, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	text(box, title, true)
	return box

static func path_stage(store: RefCounted, p: int) -> String:
	var state: RefCounted = store.society
	if state.realm[p] >= 2: return state.realm_label(p)
	if state.temper and state.temper.body_layer[p] > 0:
		var description: Dictionary = state.temper.describe(p)
		return "%s · %s" % [description.name, description.grade]
	return "Not yet tempering"

func _lifespan(parent: Node) -> void:
	var years: int = society.lifespan(person)
	var age: int = population.age(person)
	var line := text(parent, "Age %d · expected lifespan %d" % [age, years])
	line.name = "Lifespan"
	if years - age <= 5: line.add_theme_color_override("font_color", Palette.RED)
	var bar := ProgressBar.new()
	bar.name = "LifeBar"
	bar.max_value = years
	bar.value = age
	UiTheme.thin(bar, Palette.RED if years - age <= 5 else Palette.GREEN, UiTheme.SPACE_8)
	parent.add_child(bar)
	small(parent, "%d of ~%d years" % [age, years])
	if society.realm[person] >= 2:
		small(parent, "%s extends life to %d years." % [society.rules.realms[society.realm[person]].name, years])
	elif society.temper:
		small(parent, "Body Tempering raises it: %s lives to %d." % [society.temper.layer_name(society.temper.LAYERS), society.temper.config.peak_lifespan])


func text(parent: Node, words: String, heading: bool = false) -> Label:
	return ledger.label(parent, words, heading)


func small(parent: Node, words: String) -> Label:
	return ledger.small(parent, words)


func link(parent: Node, target: int, words: String = "", tab: String = "Story") -> Button:
	var node: Button = ledger.button(parent, words if not words.is_empty() else population.names[target], func() -> void: browser.person = target; browser.person_tab = tab; browser.redraw())
	node.theme_type_variation = "Chip"
	return node


## "Y3 Summer" for a simulation day.
func when(day: int) -> String:
	return "Y%d %s" % [day / 365 + 1, ["Spring", "Summer", "Autumn", "Winter"][mini(3, (day % 365) / 91)]]


func _header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.SPACE_8)
	add_child(row)
	var back: Button = ledger.button(row, "‹ People", func() -> void: browser.person = -1; browser.redraw())
	back.theme_type_variation = "Chip"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("separation", UiTheme.SPACE_8)
	row.add_child(title)
	var name_label := text(title, population.names[person])
	name_label.theme_type_variation = "Heading"
	var alive: bool = society.alive[person]
	small(title, "%s%d · %s · %s · %s" % ["" if alive else "died · ", population.age(person), population.jobs[population.job[person]], population.household_name(person), population.district_name(person)])
	if alive:
		var show: Button = ledger.button(row, "Show on map", func() -> void:
			ledger.view.show_person(person)
			ledger.close())
		show.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		show.tooltip_text = "Close the book and select %s in the valley" % population.names[person]
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("separation", UiTheme.SPACE_8)
	add_child(tabs)
	for tab: String in TABS:
		var chosen := tab
		var button: Button = ledger.button(tabs, tab, func() -> void: browser.person_tab = chosen; browser.redraw())
		button.theme_type_variation = "Tab"
		button.toggle_mode = true
		button.set_pressed_no_signal(tab == str(OLD_TABS.get(browser.person_tab, browser.person_tab)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(HSeparator.new())


func _story(page: VBoxContainer) -> void:
	if population.age(person) < 12:
		small(page, population.society.childhood.activity(person))
		for trade: String in population.society.childhood.interests[person]:
			small(page, "Interest in %s: %.0f%%" % [trade, population.society.childhood.interests[person][trade] * 100])
	var lines: PackedStringArray = []
	var temper: RefCounted = society.temper
	if temper:
		var state: Dictionary = temper.describe(person)
		if state.layer > 0:
			lines.append("Tempered to %s, %s overall." % [state.name, str(state.grade).to_lower()])
		if state.training:
			lines.append("Drills %d hours a day%s." % [state.hours, (" under " + str(state.teacher)) if not str(state.teacher).is_empty() else " alone"])
		if not str(state.gate).is_empty():
			lines.append("Waits at the gate of %s for %s." % [temper.layer_name(state.layer + 1), state.gate])
	if society.revealed[person]:
		lines.append("Has a spirit root (%s) and stands at %s." % [society.root_label(person), society.realm_label(person)])
	if society.spouse[person] >= 0:
		lines.append("Married to %s." % population.names[society.spouse[person]])
	var children: PackedInt32Array = society.children(person)
	if not children.is_empty():
		lines.append("Parent of %d." % children.size())
	if society.master[person] >= 0:
		lines.append("Learns under %s." % population.names[society.master[person]])
	if society.mind:
		var goal := str(society.mind.describe(person).goal)
		if not goal.is_empty(): lines.append("Wants to %s." % goal)
	if not lines.is_empty():
		text(page, " ".join(lines))
	# Their own entries in the chronicle and milestones, newest first.
	var entries := story_entries(population, person)
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	text(page, "Their story", true)
	if entries.is_empty():
		small(page, "Nothing recorded yet; their story is still ahead of them.")
	for entry: Array in entries.slice(0, 40):
		var row := HBoxContainer.new()
		page.add_child(row)
		var stamp := small(row, "%s · %s" % [when(entry[0]), entry[1].replace("_", " ")])
		stamp.size_flags_horizontal = Control.SIZE_FILL
		stamp.custom_minimum_size.x = 220
		text(row, entry[2])


## The population buffer also retains chronicle events; merge by identity, keeping the specific kind.
static func story_entries(store: RefCounted, p: int) -> Array:
	var unique: Dictionary = {}
	for source: Array in [store.society.chronicle, store.events]:
		for entry: Dictionary in source:
			if int(entry.person) != p: continue
			var key := "%d:%s" % [int(entry.day), str(entry.text)]
			var kind := str(entry.get("kind", "milestone"))
			if not unique.has(key) or (unique[key][1] == "milestone" and kind != "milestone"):
				unique[key] = [int(entry.day), kind, str(entry.text)]
	return unique.values()

func _attribute_words(value: float) -> String:
	return "far below most" if value < 5 else ("below most" if value < 8.5 else ("like most" if value < 11.5 else ("above most" if value < 15 else "far above most")))


func _body(page: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.SPACE_8)
	page.add_child(row)
	var temper: RefCounted = society.temper
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if temper:
		var state: Dictionary = temper.describe(person)
		var figure: Control = BodyFigure.new()
		figure.custom_minimum_size = Vector2(170, 300)
		var grades: Array = []
		for l in state.layer: grades.append(temper.grade(person, l + 1))
		figure.show_body(grades)
		figure.tooltip_text = "Faint parts are Low grade, bright parts High, glowing parts Perfect."
		row.add_child(figure)
		row.add_child(info)
		text(info, "Body tempering", true)
		if population.spirit_root[person]: text(info, "Spirit root: tempers %.2fx faster" % temper.spirit_root_factor(person))
		if state.layer == 0: text(info, "Untempered. Knows %s." % state.method)
		else: text(info, "Layer %d of 9: %s, %s overall." % [state.layer, state.name, str(state.grade).to_lower()])
		var forged := HFlowContainer.new()
		info.add_child(forged)
		for layer: Array in state.layers:
			UiTheme.tag(forged, "%s · %s" % [layer[0], str(layer[1]).to_lower()])
		if state.layer > 0 or state.training:
			text(info, "Method: %s. The best grade still possible is %s." % [state.method, str(state.ceiling).to_lower()])
		if state.training:
			var drills := text(info, "Drills %d hours a day%s. Strain %s." % [state.hours, (" under " + str(state.teacher)) if not str(state.teacher).is_empty() else " alone", "light" if state.strain < 0.3 else ("heavy" if state.strain < 0.7 else "dangerous")])
			drills.tooltip_text = "Strain %d%%" % roundi(state.strain * 100)
			drills.mouse_filter = Control.MOUSE_FILTER_PASS
		if not state.holds.is_empty(): text(info, "Holds " + ", ".join(state.holds) + ".")
		var want: String = temper.wanted_medicine(person)
		if not want.is_empty(): text(info, "Gathering %s for the next gate." % temper.config.medicine_names[want])
		if not str(state.gate).is_empty():
			var gate := text(info, "At the gate of %s: needs %s." % [temper.layer_name(state.layer + 1), state.gate])
			gate.add_theme_color_override("font_color", Palette.RED.darkened(0.2))
		elif state.layer < temper.LAYERS and (state.layer > 0 or state.training):
			var bar := ProgressBar.new()
			bar.max_value = 1
			bar.value = state.progress
			UiTheme.thin(bar, Palette.BRASS, 8)
			bar.tooltip_text = "%d%% of the way to %s" % [roundi(state.progress * 100), temper.layer_name(state.layer + 1)]
			info.add_child(bar)
			small(info, bar.tooltip_text)
	else:
		row.add_child(info)
	if society.revealed[person] or society.realm[person] > 0:
		text(info, "Cultivation", true)
		text(info, "%s. Spirit root: %s." % [society.realm_label(person), society.root_label(person)])
		text(info, "Practises %s; may live to about %d." % [society.rules.techniques[society.technique[person]].name, society.lifespan(person)])
		var qi := ProgressBar.new()
		qi.max_value = maxf(0.001, society.qi_cost(person))
		qi.value = society.qi[person]
		UiTheme.thin(qi, Palette.JADE, 8)
		qi.tooltip_text = "%.1f of %.1f qi toward the next step" % [society.qi[person], society.qi_cost(person)]
		info.add_child(qi)
		small(info, qi.tooltip_text)
	text(page, "Body and gifts", true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	for a in 8:
		var value: float = population.attributes[person * 8 + a]
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", UiTheme.SPACE_8)
		cell.tooltip_text = "%.1f now, potential %d (of 20)" % [value, population.potential[person * 8 + a]]
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(cell)
		text(cell, "%s %.1f · %s" % [str(population.catalogue.rules.attributes[a]).capitalize(), value, _attribute_words(value)])
		var bar := AttributeMeter.new()
		bar.potential = population.potential[person * 8 + a]
		bar.max_value = 20
		bar.value = value
		UiTheme.thin(bar, Palette.GREEN, 5)
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.add_child(bar)

	var talents := HFlowContainer.new()
	page.add_child(talents)
	for words: String in ["Comprehension %.2f" % population.comprehension[person], "Luck %.2f" % population.luck[person], "Constitution %d" % population.constitution[person]]: UiTheme.tag(talents, words)
	if society.revealed[person]: UiTheme.tag(talents, "Spirit root · " + society.root_label(person))


func _feeling_words(value: float) -> String:
	return "none" if value < 0.15 else ("a little" if value < 0.35 else ("some" if value < 0.6 else ("much" if value < 0.8 else "overwhelming")))


func _mind(page: VBoxContainer) -> void:
	var mind: RefCounted = society.mind
	var traits := HFlowContainer.new()
	for t in population.catalogue.traits.size():
		if population.traits[person] & (1 << t):
			UiTheme.tag(traits, str(population.catalogue.traits[t].name))
	if traits.get_child_count() > 0:
		text(page, "Nature", true)
		page.add_child(traits)
	else:
		traits.free()
	if mind == null:
		return
	var state: Dictionary = mind.describe(person)
	text(page, "What drives them", true)
	var urges: Array = state.urges
	text(page, "Driven most by %s and %s.%s" % [urges[0][0], urges[1][0], (" Wants to %s." % state.goal) if not str(state.goal).is_empty() else ""])
	text(page, "How they feel", true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	for feeling: Array in state.feelings:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", UiTheme.SPACE_8)
		cell.tooltip_text = "%.2f" % feeling[1]
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(cell)
		text(cell, "%s · %.0f%% · %s" % [str(feeling[0]).capitalize(), float(feeling[1]) * 100, _feeling_words(feeling[1])])
		var bar := ProgressBar.new()
		bar.max_value = 1
		bar.value = feeling[1]
		UiTheme.thin(bar, {"anger": Palette.RED, "grief": Palette.BLUE, "joy": Palette.GOLD, "fear": Palette.PLUM}.get(str(feeling[0]), Palette.BRASS), 5)
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.add_child(bar)
	if not state.recent.is_empty():
		text(page, "Recent choices", true)
		for record: Dictionary in state.recent.slice(0, 6):
			var target: int = record.target
			var reasons: PackedStringArray = []
			for reason: Array in record.reasons.slice(0, 3): reasons.append("%s %.2f" % [reason[0], reason[1]])
			var line := text(page, "%s · chose to %s%s; %s.%s" % [when(record.day), record.option, (" " + population.names[target]) if target >= 0 else "", record.outcome, " On impulse." if not str(record.impulse).is_empty() else ""])
			line.tooltip_text = "Strongest reasons: " + ", ".join(reasons)
			line.mouse_filter = Control.MOUSE_FILTER_PASS


func _links(parent: Node, title: String, ids: PackedInt32Array, tab: String = "Family & lineage") -> void:
	var shown: Array[int] = []
	for id: int in ids:
		if id >= 0: shown.append(id)
	if shown.is_empty():
		return
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption := small(row, title)
	caption.size_flags_horizontal = Control.SIZE_FILL
	caption.custom_minimum_size.x = 160
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flow)
	for id: int in shown:
		link(flow, id, "", tab)


func _graph(page: VBoxContainer, modes: Array, height: float) -> void:
	if modes.size() > 1:
		var chips := HBoxContainer.new()
		page.add_child(chips)
		for mode: String in modes:
			var chosen := mode
			var chip: Button = ledger.button(chips, mode, func() -> void: browser.graph_mode = chosen; browser.redraw())
			chip.theme_type_variation = "Chip"
			chip.toggle_mode = true
			chip.set_pressed_no_signal(browser.graph_mode == mode)
	var graph := EgoGraph.new()
	graph.custom_minimum_size = Vector2(0, height)
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(graph)
	graph.build(population, person, browser.graph_mode if browser.graph_mode in modes else modes[0])
	graph.opened.connect(func(target: int) -> void: browser.person = target; browser.redraw())


func _family(page: VBoxContainer) -> void:
	var kin: bool = society.spouse[person] >= 0 or society.master[person] >= 0 or not (society.children(person).is_empty() and society.siblings(person).is_empty() and society.disciples(person).is_empty())
	for parent: int in society.parents(person): kin = kin or parent >= 0
	# Orphans of the first generation have no one yet; an empty graph says less than a sentence.
	if kin: _graph(page, ["Family", "Lineage"], 320)
	else: small(page, "No family yet: %s came to the valley as an orphan. Marriage, children and a master will appear here." % population.names[person].get_slice(" ", 1))
	var lists := VBoxContainer.new()
	page.add_child(lists)
	_links(lists, "Parents", society.parents(person))
	_links(lists, "Spouse", PackedInt32Array([society.spouse[person]]))
	_links(lists, "Children", society.children(person))
	_links(lists, "Brothers and sisters", society.siblings(person))
	var housemates := PackedInt32Array()
	for other in population.size():
		if other != person and society.alive[other] and population.household[other] == population.household[person] and not society.related(person, other) and society.spouse[person] != other: housemates.append(other)
	_links(lists, "Shares a home with", housemates)
	_links(lists, "Master", PackedInt32Array([society.master[person]]))
	_links(lists, "Disciples", society.disciples(person))
	if lists.get_child_count() == 0:
		small(page, "No family or teachers recorded yet.")
	elif society.master[person] >= 0 or not society.disciples(person).is_empty():
		small(page, "Seniority in the lineage: %d" % society.seniority(person))


func _opinion_words(opinion: float) -> String:
	return "devoted to" if opinion >= 60 else ("fond of" if opinion >= 30 else ("warm toward" if opinion >= 10 else ("indifferent to" if opinion > -10 else ("cool toward" if opinion > -40 else "hostile to"))))


func _ties(page: VBoxContainer) -> void:
	browser.graph_mode = "Relationships"
	_graph(page, ["Relationships"], 300)
	var rows: Array = society.ties.rows(person)
	if rows.is_empty():
		small(page, "No acquaintances yet.")
		return
	var grid := GridContainer.new()
	grid.columns = 3 if ledger.content_width() > 1000 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	for row: Dictionary in rows.slice(0, 9):
		var target: int = row.person
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.tooltip_text = "Opinion %+.0f · familiarity %d · trust %d" % [row.opinion, row.familiarity, row.trust]
		grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", UiTheme.SPACE_8)
		panel.add_child(box)
		link(box, target, "", "Ties")
		small(box, "%s them · %s · %s" % [_opinion_words(row.opinion), "knows them well" if row.familiarity >= 60 else ("knows them" if row.familiarity >= 25 else "barely knows them"), "trusts them" if row.trust >= 50 else ("some trust" if row.trust >= 20 else "little trust")])
		var bonds := HFlowContainer.new()
		for bond: String in society.ties.bond_names(row.bonds).split(", ", false):
			UiTheme.tag(bonds, bond)
		if bonds.get_child_count() > 0: box.add_child(bonds)
		else: bonds.free()
		if society.ties.has_grudge(row.entry):
			var grudge: Dictionary = society.ties.grudge_record(row.entry)
			var line := small(box, "Holds a grudge: %s · %s" % [grudge.cause, grudge.resolution])
			line.add_theme_color_override("font_color", Palette.RED.darkened(0.2))


func _skills(page: VBoxContainer) -> void:
	_graph(page, ["Skills"], 360)
	var skills: Dictionary = population.sparse_skills(person)
	var ordered: Array = skills.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool: return int(skills[a].level) > int(skills[b].level))
	text(page, "Best at" + (" · stuck at a gate" if population.stuck[person] else ""), true)
	if ordered.is_empty():
		small(page, "No skills practised yet.")
	for id: String in ordered.slice(0, 3):
		var row: Dictionary = skills[id]
		var line := HBoxContainer.new()
		page.add_child(line)
		var name_label := text(line, "%s · %s" % [population.catalogue.skills[id].name, population.catalogue.title(row.level)])
		name_label.custom_minimum_size.x = 240
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bar := ProgressBar.new()
		bar.max_value = population.catalogue.thresholds[row.level]
		bar.value = row.xp
		UiTheme.thin(bar, Palette.GREEN, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.tooltip_text = "Level %d · %.1f / %.1f XP · %d practice days" % [row.level, row.xp, bar.max_value, row.days_practised]
		line.add_child(bar)
		small(page, bar.tooltip_text)
	if ordered.is_empty():
		return
	text(page, "Everything they know", true)
	var tree := Tree.new()
	tree.hide_root = true
	tree.scroll_horizontal_enabled = false
	tree.custom_minimum_size.y = 320
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(tree)
	var root := tree.create_item()
	var parents: Dictionary = {}
	for id: String in ordered:
		var di: String = population.catalogue.discipline_for(id)
		var domain: Dictionary = population.catalogue.domains[population.catalogue.domain_for(id)]
		for node_id: String in [domain.sphere, domain.id, di]:
			if parents.has(node_id): continue
			var parent_item: TreeItem = root if node_id == domain.sphere else (parents[domain.sphere] if node_id == domain.id else parents[domain.id])
			var item := tree.create_item(parent_item)
			var name_text := str(population.catalogue.spheres[node_id].name) if node_id == domain.sphere else (str(domain.name) if node_id == domain.id else str(population.catalogue.disciplines[di].name))
			item.set_text(0, name_text + (" · %d" % skills[node_id].level if skills.has(node_id) else ""))
			item.collapsed = node_id != domain.sphere
			parents[node_id] = item
		if id == di: continue
		var leaf := tree.create_item(parents[di])
		leaf.set_text(0, "%s · %d" % [population.catalogue.skills[id].name, skills[id].level])
	tree.custom_minimum_size.y = clampi(parents.size() * 30 + 16, 120, 320)
	for di: String in parents:
		if not population.catalogue.disciplines.has(di): continue
		var level: int = int(skills.get(di, {"level": 0}).level)
		for spec: Dictionary in population.catalogue.disciplines[di].get("specialisations", []):
			if skills.has(spec.id) or int(spec.unlock_level) > level + 5: continue
			var leaf := tree.create_item(parents[di])
			leaf.set_text(0, "%s · unlocks at %d" % [spec.name, spec.unlock_level])
			leaf.set_custom_color(0, Palette.INK_SOFT)
			leaf.set_tooltip_text(0, str(spec.condition) if spec.locked else str(spec.attribute_requirements))
