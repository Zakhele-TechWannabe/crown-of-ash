extends VBoxContainer
## Population drill-down and personal records; never depends on walker membership.
const VirtualList = preload("res://src/people_list.gd")
const EgoGraph = preload("res://src/ego_graph.gd")
var ledger: PanelContainer
var population: RefCounted
var group_mode := "Place"
var path: Array[String] = []
var person := -1
var graph_mode := "Relationships"
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
	redraw()

func text(parent: Node, words: String, heading: bool = false) -> Label:
	return ledger.label(parent, words, heading)

func action(parent: Node, words: String, callback: Callable) -> Button:
	var control: Button = ledger.button(parent, words, callback)
	control.autowrap_mode = TextServer.AUTOWRAP_OFF
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.custom_minimum_size.x = 0
	return control

func redraw() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var modes := HBoxContainer.new()
	add_child(modes)
	action(modes, "People", func() -> void: catalogue_mode = false; person = -1; redraw())
	action(modes, "Skills catalogue", func() -> void: catalogue_mode = true; redraw())
	if catalogue_mode:
		_catalogue()
		return
	if person >= 0:
		_person()
		return
	if path.is_empty(): _notables()
	var group := OptionButton.new()
	for mode: String in ["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"]: group.add_item(mode)
	group.select(["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"].find(group_mode))
	group.item_selected.connect(func(index: int) -> void:
		group_mode = ["Place", "Work", "Life stage", "Status", "Clan", "Faction", "Realm"][index]
		path.clear()
		redraw())
	add_child(group)
	_breadcrumb()
	var groups := _groups()
	if not groups.is_empty():
		var grid := GridContainer.new()
		grid.columns = 2 if ledger.get_viewport_rect().size.x >= 1500 else 1
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(grid)
		for key: String in groups:
			_summary_card(grid, key, groups[key])
	else:
		_list()

func _notables() -> void:
	text(self, "Notable people", true)
	var grid := GridContainer.new()
	grid.columns = 2 if ledger.get_viewport_rect().size.x >= 1500 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	var shown := 0
	for p in population.size():
		if population.best_level[p] < 31 and population.society.revealed[p] == 0 and population.day - population.last_insight_day[p] > 90 and population.age(p) < 60: continue
		var target: int = p
		var reason := "Spirit root" if population.society.revealed[p] else ("Recent insight" if population.day - population.last_insight_day[p] <= 90 else ("Master" if population.best_level[p] >= 31 else "Elder"))
		var card := PanelContainer.new()
		grid.add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		text(box, "%s · %s" % [population.names[p], reason])
		text(box, "%s %d" % [population.catalogue.title(population.best_level[p]), population.best_level[p]])
		action(box, "View", func() -> void: person = target; redraw())
		shown += 1
		if shown == 6: break
	if shown == 0: text(grid, "A quiet village; no notables yet.")

func _breadcrumb() -> void:
	var crumbs := HFlowContainer.new()
	add_child(crumbs)
	action(crumbs, "All people", func() -> void: path.clear(); redraw())
	for depth in path.size():
		var upto := depth + 1
		action(crumbs, _group_label(path[depth]), func() -> void: path.resize(upto); redraw())

func _keys(p: int) -> Array[String]:
	match group_mode:
		"Place": return ["Servants' Village" if population.settlement[p] == 0 else "Settlement %d" % population.settlement[p], population.district_name(p), population.household_name(p)]
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
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var card := VBoxContainer.new()
	panel.add_child(card)
	var target := key
	text(card, "%s · %d people" % [_group_label(key), summary.count], true)
	if key.begins_with("faction:"):
		var group: Dictionary = population.society.factions[int(key.get_slice(":", 1))]
		text(card, "Led by " + (population.names[group.leader] if group.leader >= 0 else "no one yet"))
	text(card, "Best: %s %d · %s mood · %s hunger" % [population.catalogue.title(summary.best), summary.best, "●" if summary.mood / summary.count >= .45 else "○", "●" if summary.hungry > 0 else "○"])
	action(card, "Browse", func() -> void: path.append(target); redraw())
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.value = 100.0 * summary.female / summary.count
	bar.tooltip_text = "%d female · %d male · %d youths · %d elders" % [summary.female, summary.count - summary.female, summary.young, summary.elder]
	card.add_child(bar)
	var ages := HBoxContainer.new()
	ages.custom_minimum_size.y = 5
	card.add_child(ages)
	for stage in 3:
		var segment := ColorRect.new()
		segment.color = [Color("8aaf70"), Color("b89953"), Color("9686a4")][stage]
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio = maxf(.01, [summary.young, summary.count - summary.young - summary.elder, summary.elder][stage])
		ages.add_child(segment)

func _list() -> void:
	search = LineEdit.new()
	search.placeholder_text = "Name, age:12-30, skill:id>=16"
	search.text = query
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(search)
	search.text_changed.connect(func(value: String) -> void: query = value; _update_list())
	var chips := HFlowContainer.new()
	add_child(chips)
	for filter_name: String in ["All", "Hungry", "Unhappy", "Spirit root", "At gate", "Recent"]:
		var selected := filter_name
		var control := action(chips, filter_name, func() -> void: chip = selected; _update_list())
		control.toggle_mode = true
		control.button_pressed = chip == filter_name
	var sorting := HBoxContainer.new()
	add_child(sorting)
	var choices := OptionButton.new()
	for key: String in ["Name", "Age", "Level", "Mood", "Hunger", "Discipline"]: choices.add_item(key)
	choices.item_selected.connect(func(index: int) -> void: sort_key = ["Name", "Age", "Level", "Mood", "Hunger", "Discipline"][index]; _update_list())
	sorting.add_child(choices)
	var discipline_sort := LineEdit.new()
	discipline_sort.placeholder_text = "Sort discipline id"
	discipline_sort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discipline_sort.tooltip_text = "Example: grain_farming.farming; select Discipline to sort by it"
	discipline_sort.text_submitted.connect(func(value: String) -> void: sort_discipline = value; sort_key = "Discipline"; _update_list())
	add_child(discipline_sort)
	action(sorting, "Reverse", func() -> void: descending = not descending; _update_list())
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(body)
	_update_list()

func _update_list() -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var selected: Array[int] = []
	for p: int in results:
		if chip == "Hungry" and population.hunger[p] == 0: continue
		if chip == "Unhappy" and population.mood[p] >= .45: continue
		if chip == "Spirit root" and population.society.revealed[p] == 0: continue
		if chip == "At gate" and population.stuck[p] == 0: continue
		if chip == "Recent" and population.day - population.recently_levelled[p] > 30: continue
		if not _matches_query(p): continue
		selected.append(p)
	sort_values.clear()
	for id: int in selected: sort_values[id] = _sort_value(id)
	selected.sort_custom(func(a: int, b: int) -> bool:
		var va: Variant = sort_values[a]
		var vb: Variant = sort_values[b]
		return va > vb if descending else va < vb)
	text(body, "%d people · select a name for their record" % selected.size())
	virtual_list = VirtualList.new()
	body.add_child(virtual_list)
	virtual_list.setup(population, PackedInt32Array(selected))
	virtual_list.person_selected.connect(func(id: int) -> void: person = id; redraw())

func _sort_value(p: int) -> Variant:
	match sort_key:
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

func _person() -> void:
	action(self, "Back to people", func() -> void: person = -1; redraw())
	text(self, population.names[person], true)
	text(self, "%s · age %d · %s\n%s · %s · Servants' Village" % ["Female" if population.sex[person] else "Male", population.age(person), population.jobs[population.job[person]], population.household_name(person), population.district_name(person)])
	var nearby := -1
	for i in ledger.life.people.size():
		if int(ledger.life.people[i].id) == person: nearby = i; break
	var walker := nearby
	var follow := action(self, "Follow" if nearby >= 0 else "Not nearby", func() -> void: ledger.life.followed = walker; ledger.close())
	follow.disabled = nearby < 0
	var views := HBoxContainer.new()
	add_child(views)
	for view: String in ["Relationships", "Family", "Lineage", "Skills"]:
		var chosen := view
		var tab := action(views, view, func() -> void: graph_mode = chosen; redraw())
		tab.toggle_mode = true
		tab.button_pressed = view == graph_mode
	var graph := EgoGraph.new()
	graph.custom_minimum_size = Vector2(0, 340)
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(graph)
	graph.build(population, person, graph_mode)
	graph.opened.connect(func(target: int) -> void: person = target; redraw())
	text(self, "Attributes", true)
	var attributes_grid := GridContainer.new()
	attributes_grid.columns = 2
	attributes_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(attributes_grid)
	for a in 8:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attributes_grid.add_child(cell)
		text(cell, "%s  %.1f / 20" % [str(population.catalogue.rules.attributes[a]).capitalize(), population.attributes[person * 8 + a]])
		var bar := ProgressBar.new()
		bar.max_value = 20
		bar.value = population.attributes[person * 8 + a]
		bar.show_percentage = false
		_thin_bar(bar)
		bar.custom_minimum_size.y = 4
		cell.add_child(bar)
	var trait_chips := HFlowContainer.new()
	add_child(trait_chips)
	for t in population.catalogue.traits.size():
		if population.traits[person] & (1 << t):
			var chip_panel := PanelContainer.new()
			trait_chips.add_child(chip_panel)
			text(chip_panel, str(population.catalogue.traits[t].name)).autowrap_mode = TextServer.AUTOWRAP_OFF
	var skills: Dictionary = population.sparse_skills(person)
	var ordered: Array = skills.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool: return int(skills[a].level) > int(skills[b].level))
	_social_record()
	text(self, "Top skills" + (" · stuck at a gate" if population.stuck[person] else ""), true)
	for id: String in ordered.slice(0, 3):
		var row: Dictionary = skills[id]
		text(self, "%s · %s %d" % [population.catalogue.skills[id].name, population.catalogue.title(row.level), row.level])
		var bar := ProgressBar.new()
		bar.max_value = population.catalogue.thresholds[row.level]
		bar.value = row.xp
		bar.tooltip_text = "%.1f / %.1f XP · %d practice days" % [row.xp, bar.max_value, row.days_practised]
		bar.custom_minimum_size.y = 16
		add_child(bar)
	text(self, "Personal skill tree", true)
	var tree := Tree.new()
	tree.hide_root = true
	tree.custom_minimum_size.y = 280
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tree)
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
			item.collapsed = true
			parents[node_id] = item
		if id == di: continue
		var leaf := tree.create_item(parents[di])
		leaf.set_text(0, "%s · %d" % [population.catalogue.skills[id].name, skills[id].level])
	for di: String in parents:
		if not population.catalogue.disciplines.has(di): continue
		var level: int = int(skills.get(di, {"level": 0}).level)
		for spec: Dictionary in population.catalogue.disciplines[di].get("specialisations", []):
			if skills.has(spec.id) or int(spec.unlock_level) > level + 5: continue
			var leaf := tree.create_item(parents[di])
			leaf.set_text(0, "%s · unlock %d" % [spec.name, spec.unlock_level])
			leaf.set_custom_color(0, Color("888078"))
			leaf.set_tooltip_text(0, str(spec.condition) if spec.locked else str(spec.attribute_requirements))
	text(self, "History", true)
	var lines := 0
	for entry: Dictionary in population.events:
		if int(entry.person) == person:
			text(self, "Day %d: %s" % [entry.day, entry.text])
			lines += 1
	if lines == 0: text(self, "No recorded milestones yet.")

func _catalogue() -> void:
	var crumbs := HFlowContainer.new()
	add_child(crumbs)
	action(crumbs, "All spheres", func() -> void: catalogue_path.clear(); redraw())
	for depth in catalogue_path.size():
		var upto := depth + 1
		action(crumbs, catalogue_path[depth].replace("_", " ").capitalize(), func() -> void: catalogue_path.resize(upto); redraw())
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
	grid.columns = 2 if ledger.get_viewport_rect().size.x >= 1500 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	for row: Dictionary in rows:
		var id := str(row.id)
		var summary := _skill_summary(id)
		var is_locked := bool(row.get("locked", false)) or (catalogue_path.size() > 0 and catalogue_path[0] == "cultivation")
		var words := str(row.name) + "\n" + ("Locked: " + str(row.get("condition", "Revealed spirit root; manuals or teaching deepen practice")) if is_locked else ("Best %s · %d know it" % [summary.best, summary.count]))
		var card := action(grid, words, func() -> void:
			if catalogue_path.size() < 3: catalogue_path.append(id); redraw()
			elif int(summary.person) >= 0: person = int(summary.person); catalogue_mode = false; redraw())
		if is_locked: card.modulate = Color(.65, .65, .65)
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

func _person_links(parent: Node, ids: PackedInt32Array) -> void:
	var row := HFlowContainer.new()
	parent.add_child(row)
	for id: int in ids:
		if id < 0: continue
		var target := id
		action(row, population.names[id], func() -> void: person = target; redraw())
	if row.get_child_count() == 0: text(row, "None known")

func _social_record() -> void:
	var society: RefCounted = population.society
	text(self, "Cultivation", true)
	text(self, "%s · spirit root: %s" % [society.realm_label(person), society.root_label(person)])
	text(self, "%s · lifespan %d%s" % [society.rules.techniques[society.technique[person]].name, society.lifespan(person), " · frail elder" if population.age(person) > society.lifespan(person) else ""])
	var qi_bar := ProgressBar.new()
	qi_bar.max_value = society.qi_cost(person)
	qi_bar.value = society.qi[person]
	qi_bar.show_percentage = false
	qi_bar.custom_minimum_size.y = 8
	qi_bar.tooltip_text = "%.1f / %.1f qi" % [society.qi[person], society.qi_cost(person)]
	add_child(qi_bar)
	text(self, "Family", true)
	text(self, "Parents")
	_person_links(self, society.parents(person))
	text(self, "Spouse")
	_person_links(self, PackedInt32Array([society.spouse[person]]))
	text(self, "Children")
	_person_links(self, society.children(person))
	text(self, "Siblings")
	_person_links(self, society.siblings(person))
	text(self, "Lineage", true)
	text(self, "Master · seniority %d" % society.seniority(person))
	_person_links(self, PackedInt32Array([society.master[person]]))
	text(self, "Disciples / apprentices")
	_person_links(self, society.disciples(person))
	text(self, "Relationships", true)
	var rows: Array = society.ties.rows(person)
	if rows.is_empty(): text(self, "No acquaintances yet")
	for row: Dictionary in rows.slice(0, 8):
		var target: int = row.person
		var panel := PanelContainer.new()
		add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		action(box, population.names[target], func() -> void: person = target; redraw())
		text(box, "%+.0f opinion · familiarity %d · trust %d" % [row.opinion, row.familiarity, row.trust])
		var opinion_bar := ProgressBar.new()
		opinion_bar.min_value = -100
		opinion_bar.max_value = 100
		opinion_bar.value = row.opinion
		opinion_bar.show_percentage = false
		opinion_bar.custom_minimum_size.y = 4
		box.add_child(opinion_bar)
		var bond_chips := HFlowContainer.new()
		box.add_child(bond_chips)
		for bond: String in society.ties.bond_names(row.bonds).split(", ", false):
			var chip := PanelContainer.new()
			bond_chips.add_child(chip)
			text(chip, bond).autowrap_mode = TextServer.AUTOWRAP_OFF
		if society.ties.has_grudge(row.entry):
			var grudge: Dictionary = society.ties.grudge_record(row.entry)
			text(box, "Grudge %.0f · %s · %s" % [grudge.intensity, grudge.cause, grudge.resolution])

func _thin_bar(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("d1c5a9")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("729363")
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func _group_label(key: String) -> String:
	if key.begins_with("faction:"):
		var id := int(key.get_slice(":", 1))
		if id >= 0 and id < population.society.factions.size(): return str(population.society.factions[id].name)
	return key
