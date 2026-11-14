extends VBoxContainer
## Population drill-down and personal records; never depends on walker membership.
const VirtualList = preload("res://src/people_list.gd")
const PersonBook = preload("res://src/person_book.gd")
const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
var cultivation_mode := false
var path_filter := "All"
var stage_filter := "All"
var also_filters: Array[String] = []
var talent_cutoff := 0.0
var comprehension_cutoff := 0.0
var advanced := false
var ledger: PanelContainer
var population: RefCounted
var group_mode := "Place"
var path: Array[String] = []
var person := -1
var graph_mode := "Family"
var person_tab := "Overview"
var catalogue_mode := false
var catalogue_path: Array[String] = []
var results := PackedInt32Array()
var query := ""
var chip := "All"
var sort_key := "Name"
var descending := false
var sort_discipline := "grain_farming.farming"
var sort_values: Dictionary = {}
var body: VBoxContainer
var virtual_list: VBoxContainer
var search: LineEdit

func setup(book: PanelContainer) -> void:
	ledger = book
	population = ledger.life.population
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var potentials: Array[float] = []
	var comprehensions: Array[float] = []
	for p in population.size():
		potentials.append(_potential(p))
		comprehensions.append(population.comprehension[p])
	potentials.sort()
	comprehensions.sort()
	if not potentials.is_empty():
		talent_cutoff = potentials[mini(potentials.size() - 1, floori(potentials.size() * .9))]
		comprehension_cutoff = comprehensions[mini(comprehensions.size() - 1, floori(comprehensions.size() * .9))]
	if cultivation_mode: sort_key = "Stage"; descending = true
	redraw()

func text(parent: Node, words: String, heading: bool = false) -> Label:
	return ledger.label(parent, words, heading)

func small(parent: Node, words: String) -> Label:
	return ledger.small(parent, words)

func action(parent: Node, words: String, callback: Callable, variation: String = "") -> Button:
	var control: Button = ledger.button(parent, words, callback)
	control.theme_type_variation = variation
	control.autowrap_mode = TextServer.AUTOWRAP_OFF
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.custom_minimum_size.x = 0
	return control

func redraw() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if person >= 0 and not catalogue_mode:
		var book := PersonBook.new()
		add_child(book)
		book.build(self)
		return
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", UiTheme.SPACE_8)
	add_child(modes)
	for mode: String in ["People", "Skills catalogue"]:
		var tab := action(modes, mode, func() -> void: catalogue_mode = mode != "People"; person = -1; redraw())
		tab.theme_type_variation = "Tab"
		tab.toggle_mode = true
		tab.set_pressed_no_signal(catalogue_mode == (mode != "People"))
	if catalogue_mode:
		_catalogue()
		return
	if cultivation_mode:
		results.clear()
		for p in population.size():
			if population.society.alive[p]: results.append(p)
		_list()
		return
	if path.is_empty(): _notables()
	var group := OptionButton.new()
	for mode: String in ["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"]: group.add_item(mode)
	group.select(["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"].find(group_mode))
	group.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	group.tooltip_text = "Group people by"
	group.item_selected.connect(func(index: int) -> void:
		group_mode = ["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"][index]
		path.clear()
		redraw())
	add_child(group)
	_breadcrumb()
	var groups := _groups()
	if not groups.is_empty():
		var grid := GridContainer.new()
		grid.columns = 3 if ledger.content_width() >= 1100 else 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(grid)
		for key: String in groups:
			_summary_card(grid, key, groups[key])
	else:
		_list()

func _potential(p: int) -> float:
	var total := 0.0
	for a in 8: total += population.potential[p * 8 + a]
	return total / 8.0

## Every applicable reason, shared by rows, cards and the personal record.
func notable_reason(p: int) -> Array[String]:
	var reasons: Array[String] = []
	if not population.society.alive[p]: return reasons
	var temper: RefCounted = population.society.temper
	if temper and temper.at_gate(p): reasons.append("at a gate")
	if population.society.revealed[p]: reasons.append("spirit root revealed")
	if temper and temper.body_layer[p] >= 3: reasons.append("layer 3+")
	if population.last_insight_day[p] >= 0 and population.day - population.last_insight_day[p] <= 90: reasons.append("recent insight")
	if population.best_level[p] >= 31: reasons.append("master of a craft")
	if temper and temper.training(p, population.day) and temper.teacher[p] >= 0: reasons.append("drilling under a teacher")
	if population.age(p) >= 60: reasons.append("elder")
	if _potential(p) >= talent_cutoff or population.comprehension[p] >= comprehension_cutoff: reasons.append("rare talent")
	if population.society.injury_until[p] > population.day: reasons.append("injured")
	if temper and temper.training(p, population.day): reasons.append("training now")
	return reasons

const REASONS := {"at a gate": "Progress is full; the next body layer needs a gate requirement.", "spirit root revealed": "Their spirit root has awakened.", "layer 3+": "Has forged at least three body layers.", "recent insight": "An insight within the last 90 days.", "master of a craft": "A supporting skill at level 31 or higher.", "drilling under a teacher": "Training now under a body tempering teacher.", "elder": "At least 60 years old.", "rare talent": "Top tenth of the valley in average attribute potential or comprehension.", "injured": "Still recovering from an injury.", "training now": "Currently practising body tempering drills."}

func tags(parent: Node, p: int) -> void:
	for reason: String in notable_reason(p):
		var tag := UiTheme.tag(parent, reason)
		tag.tooltip_text = REASONS[reason]

func _notables() -> void:
	text(self, "Worth knowing", true)
	var grid := GridContainer.new()
	grid.columns = 3 if ledger.content_width() >= 1100 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	var shown := 0
	for p in population.size():
		var reason := notable_reason(p)
		if reason.is_empty() or reason == ["elder"]: continue
		var target: int = p
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var card := VBoxContainer.new()
		panel.add_child(card)
		action(card, population.names[p], func() -> void: person = target; person_tab = "Overview"; redraw(), "Chip")
		small(card, population.jobs[population.job[p]])
		var reasons := HFlowContainer.new()
		card.add_child(reasons)
		tags(reasons, p)
		shown += 1
		if shown == 6: break
	if shown == 0: text(grid, "A quiet village; no one stands out yet.")

func _breadcrumb() -> void:
	var crumbs := HFlowContainer.new()
	add_child(crumbs)
	action(crumbs, "All people", func() -> void: path.clear(); redraw(), "Chip")
	for depth in path.size():
		var upto := depth + 1
		action(crumbs, _group_label(path[depth]), func() -> void: path.resize(upto); redraw(), "Chip")

func _keys(p: int) -> Array[String]:
	match group_mode:
		"Place": return ["Servants' Village" if population.settlement[p] == 0 else ("Heavenly Dao Palace" if population.settlement[p] == 50 else "Settlement %d" % population.settlement[p]), population.district_name(p), population.household_name(p)]
		"Work":
			if population.best_skill[p] < 0: return ["Untrained", "No domain", "No discipline"]
			var id: String = population.catalogue.ids[population.best_skill[p]]
			var domain: Dictionary = population.catalogue.domains[id.get_slice(".", 0)]
			return [population.catalogue.spheres[domain.sphere].name, domain.name, population.catalogue.disciplines[population.catalogue.discipline_for(id)].name]
		"Realm": return [str(population.society.rules.realms[population.society.realm[p]].name)]
		"Clan", "Faction":
			var labels: Array[String] = []
			for id: int in population.society.memberships.get(p, PackedInt32Array()):
				var faction: Dictionary = population.society.factions[id]
				if group_mode == "Faction" or faction.type == "clan": labels.append(faction.name)
			return [", ".join(labels) if not labels.is_empty() else "Unaffiliated"]
		"Life stage":
			var years: int = population.age(p)
			return ["Children" if years < 12 else ("Youths" if years < 18 else ("Adults" if years < 60 else "Elders"))]
		_: return ["Hungry" if population.hunger[p] else ("Unhappy" if population.mood[p] < .45 else ("Stuck at a gate" if population.stuck[p] else ("Spirit root" if population.society.revealed[p] else ("Recently levelled" if population.day - population.recently_levelled[p] <= 30 else "Settled"))))]

func _group_paths(p: int) -> Array[Array]:
	var paths: Array[Array] = []
	if group_mode == "Status":
		if population.hunger[p] > 0: paths.append(["Hungry"])
		if population.mood[p] < .45: paths.append(["Unhappy"])
		if population.stuck[p] > 0: paths.append(["Stuck at a gate"])
		if population.society.revealed[p] > 0: paths.append(["Spirit root"])
		if population.day - population.recently_levelled[p] <= 30: paths.append(["Recently levelled"])
		if paths.is_empty(): paths.append(["Settled"])
	elif group_mode in ["Faction", "Clan"]:
		for id: int in population.society.memberships.get(p, PackedInt32Array()):
			var faction: Dictionary = population.society.factions[id]
			if group_mode == "Faction" or faction.type == "clan": paths.append(["faction:%d" % id])
		if paths.is_empty(): paths.append(["Unaffiliated"])
	elif group_mode == "Work":
		for duty: String in population.schedules[population.job[p]]:
			var discipline: String = population.catalogue.activities[duty].discipline
			var domain: Dictionary = population.catalogue.domains[population.catalogue.domain_for(discipline)]
			paths.append([population.catalogue.spheres[domain.sphere].name, domain.name, population.catalogue.disciplines[discipline].name])
	else: paths.append(_keys(p))
	return paths

func _path_matches(keys: Array) -> bool:
	for i in path.size():
		if i >= keys.size() or keys[i] != path[i]: return false
	return true

func _groups() -> Dictionary:
	var grouped: Dictionary = {}
	results.clear()
	for p in population.size():
		var matched := false
		var grouped_once: Dictionary = {}
		for keys: Array in _group_paths(p):
			if not _path_matches(keys): continue
			matched = true
			if path.size() >= keys.size(): continue
			var key: String = keys[path.size()]
			if grouped_once.has(key): continue
			grouped_once[key] = true
			if not grouped.has(key): grouped[key] = {"count": 0, "female": 0, "young": 0, "elder": 0, "mood": 0.0, "hungry": 0, "best": 0}
			var summary: Dictionary = grouped[key]
			summary.count += 1
			summary.female += int(population.sex[p])
			summary.young += int(population.age(p) < 18)
			summary.elder += int(population.age(p) >= 60)
			summary.mood += population.mood[p]
			summary.hungry += int(population.hunger[p] > 0)
			summary.best = maxi(summary.best, population.best_level[p])
		if matched: results.append(p)
	return grouped

func _summary_card(parent: Node, key: String, summary: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", UiTheme.SPACE_8)
	panel.add_child(card)
	var target := key
	text(card, "%s · %d people" % [_group_label(key), summary.count], true)
	if key.begins_with("faction:"):
		var group: Dictionary = population.society.factions[int(key.get_slice(":", 1))]
		text(card, "Led by " + (population.names[group.leader] if group.leader >= 0 else "no one yet"))
	var mood_words := "content" if summary.mood / summary.count >= .45 else "unhappy"
	small(card, "Best %s · mostly %s%s" % [population.catalogue.title(summary.best).to_lower(), mood_words, (" · %d hungry" % summary.hungry) if summary.hungry > 0 else ""])
	action(card, "Browse", func() -> void: path.append(target); redraw(), "Chip")
	var bar := ProgressBar.new()
	UiTheme.thin(bar, Palette.PLUM, 5)
	bar.value = 100.0 * summary.female / summary.count
	bar.tooltip_text = "%d female · %d male · %d youths · %d elders" % [summary.female, summary.count - summary.female, summary.young, summary.elder]
	card.add_child(bar)
	small(card, bar.tooltip_text)
	var ages := HBoxContainer.new()
	ages.custom_minimum_size.y = 5
	card.add_child(ages)
	for stage in 3:
		var segment := ColorRect.new()
		segment.color = [Palette.GREEN, Palette.BRASS, Palette.INK_SOFT][stage]
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio = maxf(.01, [summary.young, summary.count - summary.young - summary.elder, summary.elder][stage])
		ages.add_child(segment)

func _filter_row(caption: String, choices: Array, value: String, changed: Callable, parent: Node = self) -> void:
	var row := HFlowContainer.new()
	parent.add_child(row)
	small(row, caption)
	for choice: String in choices:
		var chosen := choice
		var control := action(row, choice, func() -> void: changed.call(chosen); redraw(), "Chip")
		control.toggle_mode = true
		control.set_pressed_no_signal(choice == value)

func _list() -> void:
	_filter_row("Path", ["All", "Body Tempering", "Qi cultivation", "Not yet started"], path_filter, func(value: String) -> void: path_filter = value)
	_filter_row("Stage", ["All", "Layers 1–3", "4–6", "7–9", "At a gate", "Perfect grades"], stage_filter, func(value: String) -> void: stage_filter = value)
	var realms: Array = ["All realms"]
	for realm: Dictionary in population.society.rules.realms: realms.append(str(realm.name))
	_filter_row("Qi realm", realms, qi_realm, func(value: String) -> void: qi_realm = value)
	var also := HFlowContainer.new()
	add_child(also)
	small(also, "Also")
	for choice: String in ["Spirit root", "Training now", "Injured", "Has a teacher"]:
		_also_button(also, choice)
	var more := MenuButton.new()
	more.text = "More ▾"
	also.add_child(more)
	for choice: String in ["Hungry", "Unhappy", "Elders", "Children", "Recent insight"]: more.get_popup().add_check_item(choice)
	more.get_popup().index_pressed.connect(func(index: int) -> void:
		var value := more.get_popup().get_item_text(index)
		_toggle_also(value)
		more.get_popup().set_item_checked(index, value in also_filters)
		_update_list())
	_filter_row("Sort", ["Stage", "Grade", "Talent", "Age", "Years left", "Name"], sort_key, func(value: String) -> void: sort_key = value)
	action(self, "Advanced ▾", func() -> void: advanced = not advanced; redraw(), "Chip")
	var fold := VBoxContainer.new()
	fold.visible = advanced
	add_child(fold)
	search = LineEdit.new()
	search.placeholder_text = "Name, age:12-30, skill:id>=16"
	search.text = query
	fold.add_child(search)
	search.text_changed.connect(func(value: String) -> void: query = value; _update_list())
	var discipline_sort := LineEdit.new()
	discipline_sort.placeholder_text = "Sort discipline id"
	fold.add_child(discipline_sort)
	discipline_sort.text_submitted.connect(func(value: String) -> void: sort_discipline = value; sort_key = "Discipline"; _update_list())
	action(fold, "Reverse sort", func() -> void: descending = not descending; _update_list(), "Chip")
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(body)
	_update_list()

var qi_realm := "All realms"

func _toggle_also(value: String) -> void:
	if value in also_filters: also_filters.erase(value)
	else: also_filters.append(value)

func _also_button(parent: Node, value: String) -> void:
	var control := action(parent, value, func() -> void: _toggle_also(value); _update_list(), "Chip")
	control.toggle_mode = true
	control.set_pressed_no_signal(value in also_filters)

func cultivation_matches(p: int) -> bool:
	var society: RefCounted = population.society
	var temper: RefCounted = society.temper
	var layer: int = temper.body_layer[p] if temper else 0
	var qi: bool = society.realm[p] >= 2 or society.qi[p] > 0
	if path_filter == "Body Tempering" and layer == 0 and not (temper and temper.training(p, population.day)): return false
	if path_filter == "Qi cultivation" and not qi: return false
	if path_filter == "Not yet started" and (layer > 0 or qi or (temper and temper.training(p, population.day))): return false
	var stage: int = society.layer[p] if path_filter == "Qi cultivation" or (qi and qi_realm != "All realms") else layer
	if stage_filter == "Layers 1–3" and (stage < 1 or stage > 3): return false
	if stage_filter == "4–6" and (stage < 4 or stage > 6): return false
	if stage_filter == "7–9" and (stage < 7 or stage > 9): return false
	if stage_filter == "At a gate" and not (temper and temper.at_gate(p)): return false
	if stage_filter == "Perfect grades" and not (temper and layer > 0 and temper.perfect_so_far(p)): return false
	if qi_realm != "All realms" and str(society.rules.realms[society.realm[p]].name) != qi_realm: return false
	for filter: String in also_filters:
		match filter:
			"Spirit root":
				if not society.revealed[p]: return false
			"Training now":
				if not (temper and temper.training(p, population.day)): return false
			"Injured":
				if society.injury_until[p] <= population.day: return false
			"Has a teacher":
				if society.master[p] < 0 and not (temper and temper.teacher[p] >= 0): return false
			"Hungry":
				if population.hunger[p] == 0: return false
			"Unhappy":
				if population.mood[p] >= .45: return false
			"Elders":
				if population.age(p) < 60: return false
			"Children":
				if population.age(p) >= 18: return false
			"Recent insight":
				if population.last_insight_day[p] < 0 or population.day - population.last_insight_day[p] > 90: return false
	return true

func _update_list() -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var selected: Array[int] = []
	for p: int in results:
		if not cultivation_matches(p): continue
		if chip == "Notable" and notable_reason(p).is_empty(): continue
		if chip == "Hungry" and population.hunger[p] == 0: continue
		if chip == "Unhappy" and population.mood[p] >= .45: continue
		if chip == "Spirit root" and population.society.revealed[p] == 0: continue
		if chip == "At gate" and population.stuck[p] == 0 and not (population.society.temper and population.society.temper.at_gate(p)): continue
		if chip == "Recent" and population.day - population.recently_levelled[p] > 30: continue
		if not _matches_query(p): continue
		selected.append(p)
	sort_values.clear()
	for id: int in selected: sort_values[id] = _sort_value(id)
	selected.sort_custom(func(a: int, b: int) -> bool:
		var va: Variant = sort_values[a]
		var vb: Variant = sort_values[b]
		return va > vb if descending else va < vb)
	small(body, "%d people · select a name to open their page" % selected.size())
	virtual_list = VirtualList.new()
	body.add_child(virtual_list)
	virtual_list.reason_source = self
	virtual_list.setup(population, PackedInt32Array(selected))
	small(body, "Tags: gate · root · layer 3+ · insight (90 days) · craft master (31+) · teacher · elder (60+) · rare talent (top 10%) · injured · training. Hover a tag for its reason.")
	virtual_list.person_selected.connect(func(id: int) -> void: person = id; person_tab = "Overview"; redraw())

func _sort_value(p: int) -> Variant:
	match sort_key:
		"Stage": return population.society.realm[p] * 100 + (population.society.layer[p] if population.society.realm[p] > 0 else (population.society.temper.body_layer[p] if population.society.temper else 0))
		"Grade": return population.society.temper.grade(p, population.society.temper.body_layer[p]) if population.society.temper and population.society.temper.body_layer[p] > 0 else -1
		"Talent": return _potential(p) + population.comprehension[p] * 10
		"Years left": return population.society.lifespan(p) - population.age(p)
		"Age": return population.age(p)
		"Level": return population.best_level[p]
		"Mood": return population.mood[p]
		"Hunger": return population.hunger[p]
		"Discipline": return int(population.sparse_skills(p).get(sort_discipline, {"level": 0}).level)
	return population.names[p]

func _matches_query(p: int) -> bool:
	for token: String in query.to_lower().split(" ", false):
		if token.begins_with("age:"):
			var bounds := token.trim_prefix("age:").split("-")
			if bounds.size() != 2: continue
			if population.age(p) < int(bounds[0]) or population.age(p) > int(bounds[1]): return false
		elif token.begins_with("skill:"):
			var condition := token.trim_prefix("skill:").split(">=")
			if condition.size() != 2: continue
			var skills: Dictionary = population.sparse_skills(p)
			if not skills.has(condition[0]) or int(skills[condition[0]].level) < int(condition[1]): return false
		elif not token in population.names[p].to_lower(): return false
	return true

func _catalogue() -> void:
	var crumbs := HFlowContainer.new()
	add_child(crumbs)
	action(crumbs, "All spheres", func() -> void: catalogue_path.clear(); redraw(), "Chip")
	for depth in catalogue_path.size():
		var upto := depth + 1
		action(crumbs, catalogue_path[depth].replace("_", " ").capitalize(), func() -> void: catalogue_path.resize(upto); redraw(), "Chip")
	var rows: Array[Dictionary] = []
	if catalogue_path.is_empty(): rows.assign(population.catalogue.spheres.values())
	elif catalogue_path.size() == 1:
		for row: Dictionary in population.catalogue.domains.values():
			if row.sphere == catalogue_path[0]: rows.append(row)
	elif catalogue_path.size() == 2:
		for row: Dictionary in population.catalogue.disciplines.values():
			if row.domain == catalogue_path[1]: rows.append(row)
	else:
		rows.assign(population.catalogue.disciplines[catalogue_path[2]].get("specialisations", []))
	var grid := GridContainer.new()
	grid.columns = 3 if ledger.content_width() >= 1100 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	for row: Dictionary in rows:
		var id := str(row.id)
		var summary := _skill_summary(id)
		var is_locked := bool(row.get("locked", false)) or (catalogue_path.size() > 0 and catalogue_path[0] == "cultivation")
		var words := str(row.name) + "\n" + ("Locked: " + str(row.get("condition", "Revealed spirit root; manuals or teaching deepen practice")) if is_locked else ("Best %s · %d know it" % [summary.best, summary.count]))
		var card := action(grid, words, func() -> void:
			if catalogue_path.size() < 3: catalogue_path.append(id); redraw()
			elif int(summary.person) >= 0: person = int(summary.person); person_tab = "Skills"; catalogue_mode = false; redraw())
		card.theme_type_variation = "Card"
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_locked: card.modulate = Color(1, 1, 1, .6)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = str(row.get("description", ""))
	if catalogue_path.size() == 3:
		var discipline: Dictionary = population.catalogue.disciplines[catalogue_path[2]]
		text(self, str(discipline.description))
		text(self, "Perks", true)
		for perk: Dictionary in discipline.get("perks", []): text(self, "%d · %s: %s" % [perk.level, perk.name, perk.description])
		text(self, "Tier gates", true)
		for gate: Dictionary in discipline.get("gates", []): text(self, "%d → %d: %s" % [gate.level, int(gate.level) + 1, gate.get("description", str(gate))])
	if rows.is_empty(): text(self, "Detailed techniques await further study.")

func _skill_summary(id: String) -> Dictionary:
	var summary: Dictionary = population.skill_statistics(id)
	return {"count": summary.count, "best": population.catalogue.title(summary.best_level) + " " + str(summary.best_level), "person": summary.person}

func _group_label(key: String) -> String:
	if key.begins_with("faction:"):
		var id := int(key.get_slice(":", 1))
		if id >= 0 and id < population.society.factions.size(): return str(population.society.factions[id].name)
	return key
