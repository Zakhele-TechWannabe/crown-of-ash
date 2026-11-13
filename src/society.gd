extends RefCounted
## Social simulation owns packed birth/master/cultivation columns; kin is derived.
const Relationships = preload("res://src/relationships.gd")
const Mind = preload("res://src/mind.gd")
const BodyTempering = preload("res://src/body_tempering.gd")
const Nature = preload("res://src/nature.gd")
var ties := Relationships.new()
var store_ref: WeakRef
var population: RefCounted:
	get: return store_ref.get_ref()
var father := PackedInt32Array()
var spouse := PackedInt32Array()
var master := PackedInt32Array()
var joined := PackedInt32Array()
var revealed := PackedByteArray()
var awakening_age := PackedByteArray()
var realm := PackedByteArray()
var layer := PackedByteArray()
var qi := PackedFloat32Array()
var technique := PackedByteArray()
var technique_element := PackedInt32Array()
var site := PackedByteArray()
var injury_until := PackedInt32Array()
var bottleneck_since := PackedInt32Array()
var damage := PackedFloat32Array()
var last_birth := PackedInt32Array()
## The day a pregnancy comes to term (-1 when not with child), and whether it is twins.
var due_day := PackedInt32Array()
var twins := PackedByteArray()
var rivalry := PackedByteArray()
var guilt := PackedFloat32Array()
var resources := PackedFloat32Array()
var reputation := PackedFloat32Array()
var alive := PackedByteArray()
var events: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/events.json"))
var given_names: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/names.json"))
var wanderer_year := -1
var wanderer_present := false
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/cultivation.json"))
var factions: Array[Dictionary] = []
var positions: Array[Dictionary] = []
var chronicle: Array[Dictionary] = []
var marriages := 0
var births := 0
var awakenings := 0
var lifespan_death_enabled := false
var last_week := 0
var last_year := -1
var household_serial := 100
var stores_years := 0.0
var betrayal_happened := false
var faction_keys: Dictionary = {}
var faction_relations: Dictionary = {}
var memberships: Dictionary = {}
var archive: RefCounted = null
var mind: RefCounted = null
var temper: RefCounted = null
var nature: RefCounted = null
var archived_year := -1

func _init(store: RefCounted) -> void:
	store_ref = weakref(store)
	lifespan_death_enabled = bool(ProjectSettings.get_setting("simulation/lifespan_death_enabled", false))
	var body_probe: RefCounted = BodyTempering.new(self)
	if body_probe.config.enabled: temper = body_probe
	var probe: RefCounted = Mind.new(self)
	if probe.config.enabled: mind = probe
	nature = Nature.new(self)

func add_person() -> void:
	ties.add_person()
	if mind: mind.add_person()
	if temper: temper.add_person()
	nature.add_person()
	father.append(-1)
	spouse.append(-1)
	master.append(-1)
	joined.append(0)
	revealed.append(0)
	awakening_age.append(0)
	realm.append(0)
	layer.append(0)
	qi.append(0)
	technique.append(0)
	technique_element.append(-1)
	site.append(0)
	injury_until.append(0)
	bottleneck_since.append(0)
	damage.append(1)
	last_birth.append(-2000)
	due_day.append(-1)
	twins.append(0)
	rivalry.append(0)
	guilt.append(0)
	resources.append(1)
	reputation.append(20)
	alive.append(1)

func note(person: int, kind: String, words: String) -> void:
	var store: RefCounted = store_ref.get_ref()
	chronicle.append({"day": store.day, "person": person, "kind": kind, "text": words})
	if chronicle.size() > 2048: chronicle.pop_front()
	if archive: archive.event(store.day, person, kind, words)
	if mind and person >= 0: _feel_event(person, kind)
	if store.retain_events and store.events.size() < 8192:
		store.events.append({"day": store.day, "person": person, "kind": kind, "text": words})

# Feelings that follow what happens to someone; strong ones interrupt their routine and force a fresh decision.
func _feel_event(person: int, kind: String) -> void:
	match kind:
		"marriage":
			mind.feel(person, Mind.JOY, .6)
			if spouse[person] >= 0: mind.feel(spouse[person], Mind.JOY, .6)
		"birth":
			for parent: int in parents(person):
				if parent >= 0: mind.feel(parent, Mind.JOY, .5)
		"awakening", "breakthrough", "manual", "technique": mind.feel(person, Mind.JOY, .5)
		"setback": mind.feel(person, Mind.AFRAID, .5)
		"tempering": mind.feel(person, Mind.JOY, .4)
		"injury": mind.feel(person, Mind.AFRAID, .3)
		"old_age":
			for kin: int in children(person): mind.feel(kin, Mind.GRIEF, .8)
			if spouse[person] >= 0: mind.feel(spouse[person], Mind.GRIEF, 1.0)

func root_count(person: int) -> int:
	var store: RefCounted = store_ref.get_ref()
	var bits: int = store.spirit_root[person]
	var n := 0
	while bits:
		n += bits & 1
		bits >>= 1
	return n

func awaken(person: int, cause: String) -> bool:
	var store: RefCounted = store_ref.get_ref()
	if revealed[person] or not store.spirit_root[person]: return false
	revealed[person] = 1
	awakening_age[person] = mini(255, store.age(person))
	awakenings += 1
	note(person, "awakening", "%s awakened a hidden spirit root: %s" % [store.names[person], cause])
	return true

func root_label(person: int) -> String:
	var store: RefCounted = store_ref.get_ref()
	if not revealed[person]: return "unknown"
	var elements: Array[String] = []
	for i in 10:
		if store.spirit_root[person] & (1 << i): elements.append(rules.elements[i])
	return "%s · purity %d" % [" / ".join(elements), store.root_purity[person]]

func realm_label(person: int) -> String:
	if realm[person] >= 3: return str(rules.realms[realm[person]].name) + " · " + ["early", "middle", "late", "peak"][clampi(layer[person] - 1, 0, 3)]
	return str(rules.realms[realm[person]].name) + (" %d" % layer[person] if layer[person] else "")

func layer_cap(person: int) -> int:
	var store: RefCounted = store_ref.get_ref()
	if realm[person] >= 3: return 4
	if realm[person] == 2 and store.root_grade[person] >= 4 and store.root_purity[person] >= 95 and technique[person] >= 2: return 13
	return 9

func lifespan(person: int) -> int:
	if realm[person] < 2 and temper: return temper.lifespan(person)
	return int(rules.realms[realm[person]].lifespan)

func heart_demons(person: int) -> float:
	var total := guilt[person]
	var e := ties.head[person]
	while e >= 0:
		if ties.has_grudge(e): total += ties.grudge_intensity(e) / 100.0
		e = ties.next[e]
	return minf(.7, total * .1)

func qi_rate(person: int) -> float:
	var store: RefCounted = store_ref.get_ref()
	if not revealed[person] or root_count(person) == 0: return 0
	var effective_count := maxi(1, root_count(person) - (1 if store.spirit_root[person] & 992 else 0))
	var speed: float = rules.root_speed[mini(5, effective_count) - 1]
	var purity: float = .5 + .7 * store.root_purity[person] / 100.0
	var age_factor := maxf(.2, 1.0 - .02 * maxi(0, awakening_age[person] - 16))
	var method: float = rules.techniques[technique[person]].rate
	var teacher := 1.5 if master[person] >= 0 and realm[master[person]] >= 2 else 1.0
	var companion := 1.1 if spouse[person] >= 0 and realm[spouse[person]] >= 2 else 1.0
	var element: int = technique_element[person] if technique_element[person] >= 0 else rules.techniques[technique[person]].get("element", -1)
	var match_rate := 1.0 if element < 0 or store.spirit_root[person] & (1 << element) else .6
	var physique := 1.15 if store.constitution[person] in [3, 5] else 1.0
	var modifier: float = store.modifiers.value(person, "cultivation", "qi_multiplier", store.day)
	return physique * resources[person] * match_rate * modifier * 2.0 * speed * purity * float(rules.density[site[person]]) * method * store.comprehension[person] * age_factor * damage[person] * teacher * companion

func qi_cost(person: int) -> float:
	if realm[person] < 2: return 2000
	if layer[person] >= layer_cap(person): return float(rules.realms[mini(5, realm[person] + 1)].cost)
	if realm[person] == 2: return 2000 * pow(1.2, layer[person])
	return float(rules.realms[realm[person]].cost) / 4.0

func cultivate(person: int, days: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	if store.age(person) < 12 or injury_until[person] > store.day: return
	if not revealed[person]: return
	qi[person] += qi_rate(person) * days
	var cost := qi_cost(person)
	if qi[person] < cost or realm[person] >= 5: return
	store.mood[person] = maxf(0, store.mood[person] - .001 * days)
	if bottleneck_since[person] == 0: bottleneck_since[person] = store.day
	var major: bool = realm[person] >= 2 and layer[person] >= layer_cap(person)
	if major and int(rules.techniques[technique[person]].cap) <= realm[person]: return
	var base: float = float(rules.realms[realm[person] + 1].chance) if major else .8
	# A tempered body steadies the first step onto the qi road; a Perfect one most of all.
	if realm[person] < 2 and temper: base += temper.qi_bonus(person)
	var chance := minf(.95, base + store.attributes[person * 8 + 6] / 200.0 - heart_demons(person) + (store.day - bottleneck_since[person]) / 36500.0)
	if store.rng.randf() < chance:
		qi[person] -= cost
		if realm[person] < 2:
			realm[person] = 2
			layer[person] = 1
		elif major:
			realm[person] += 1
			layer[person] = 1
		else: layer[person] += 1
		bottleneck_since[person] = 0
		note(person, "breakthrough", "%s reached %s" % [store.names[person], realm_label(person)])
		if realm[person] == 2 and layer[person] == 1:
			for row: Dictionary in ties.rows(person): ties.event(row.person, person, "competition" if store.has_trait(row.person, "ambitious") else "first_cultivator", store.day)
	else:
		qi[person] *= store.rng.randf_range(.6, .9)
		injury_until[person] = store.day + store.rng.randi_range(21, 365)
		if store.rng.randf() < .05: damage[person] *= .95
		note(person, "setback", "%s suffered a cultivation injury; recovery remains possible" % store.names[person])

func parents(person: int) -> PackedInt32Array:
	var store: RefCounted = store_ref.get_ref()
	return PackedInt32Array([store.parent_id[person], father[person]])

func children(person: int) -> PackedInt32Array:
	var store: RefCounted = store_ref.get_ref()
	if annual_index and index_day == store.day and index_cursor >= social_size: return annual_children.get(person, PackedInt32Array())
	var result := PackedInt32Array()
	for p in store.size():
		if store.parent_id[p] == person or father[p] == person: result.append(p)
	return result

func siblings(person: int) -> PackedInt32Array:
	var store: RefCounted = store_ref.get_ref()
	var result := PackedInt32Array()
	for p in store.size():
		if p == person: continue
		if (store.parent_id[person] >= 0 and store.parent_id[p] == store.parent_id[person]) or (father[person] >= 0 and father[p] == father[person]): result.append(p)
	return result

func related(a: int, b: int) -> bool:
	var ancestors_a := ancestors(a, 3)
	var ancestors_b := ancestors(b, 3)
	for p: int in ancestors_a:
		if p in ancestors_b: return true
	return false

func ancestors(person: int, depth: int) -> PackedInt32Array:
	var result := PackedInt32Array([person])
	var frontier := result.duplicate()
	for generation in depth:
		var next_generation := PackedInt32Array()
		for p: int in frontier:
			for parent: int in parents(p):
				if parent >= 0 and parent not in result:
					result.append(parent)
					next_generation.append(parent)
		frontier = next_generation
	return result

func approval(person: int, candidate: int) -> bool:
	for parent: int in parents(person):
		if parent < 0: continue
		var e := ties.find(parent, candidate)
		if reputation[candidate] < 0 or (e >= 0 and ties.opinion[e] < 0): return false
	return true

func marry(a: int, b: int) -> bool:
	var store: RefCounted = store_ref.get_ref()
	if a == b or spouse[a] >= 0 or spouse[b] >= 0: return false
	if store.age(a) < 18 or store.age(b) < 18 or marriage_related(a, b): return false
	if absi(store.age(a) - store.age(b)) > int(events.marriage_age_gap): return false
	var ab := ties.find(a, b)
	var ba := ties.find(b, a)
	var minimum: float = float(events.mixed_cultivation_opinion) if (realm[a] >= 2) != (realm[b] >= 2) else 50.0
	if ab < 0 or ba < 0 or ties.opinion[ab] < minimum or ties.opinion[ba] < minimum: return false
	if not approval(a, b) or not approval(b, a): return false
	# A respected adult mediates the match; no invisible pre-made sect official.
	var matchmaker := -1
	for p in store.size():
		if p != a and p != b and store.age(p) >= 40 and reputation[p] >= 20:
			matchmaker = p
			break
	if matchmaker < 0: return false
	spouse[a] = b
	spouse[b] = a
	ties.event(a, b, "marriage", store.day)
	ties.event(b, a, "marriage", store.day)
	if realm[a] >= 2 and realm[b] >= 2:
		ties.bonds[ab] |= Relationships.DAO
		ties.bonds[ba] |= Relationships.DAO
	household_serial += 1
	store.household[a] = household_serial
	store.household[b] = household_serial
	store.household_names_day = -1
	marriages += 1
	note(a, "marriage", "%s and %s married, with %s arranging the match" % [store.names[a], store.names[b], store.names[matchmaker]])
	return true

func accept(teacher: int, pupil: int) -> bool:
	var store: RefCounted = store_ref.get_ref()
	if teacher == pupil or master[pupil] >= 0: return false
	if pupil in lineage_ancestors(teacher): return false
	var e := ties.find(teacher, pupil)
	if e < 0 or ties.opinion[e] < 20: return false
	if store.comprehension[pupil] < .6: return false
	var immortal: bool = realm[teacher] >= 2 and revealed[pupil] > 0 and (realm[teacher] > realm[pupil] or (realm[teacher] == realm[pupil] and layer[teacher] >= layer[pupil] + 5))
	if not immortal:
		if store.best_skill[teacher] < 0: return false
		var craft: String = store.catalogue.domain_for(store.catalogue.ids[store.best_skill[teacher]])
		if domain_level(teacher, craft) < domain_level(pupil, craft) + 5: return false
	var slots := 6 if realm[teacher] >= 4 else (3 if realm[teacher] >= 3 else 1)
	var load := master_load[teacher] if index_day == store.day and index_cursor >= social_size and teacher < master_load.size() else disciples(teacher).size()
	if load >= slots: return false
	master[pupil] = teacher
	if index_day == store.day and teacher < master_load.size(): master_load[teacher] += 1
	joined[pupil] = store.day
	ties.bonds[ties.tie(pupil, teacher)] |= Relationships.MASTER
	ties.bonds[e] |= Relationships.DISCIPLE
	if immortal:
		technique[pupil] = technique[teacher]
		technique_element[pupil] = technique_element[teacher]
	else:
		store.job[pupil] = store.job[teacher]
		store.prepare_person(pupil)
	note(pupil, "apprenticeship", "%s became %s's %s" % [store.names[pupil], store.names[teacher], "disciple" if immortal else "craft apprentice"])
	return true

func disciples(person: int) -> PackedInt32Array:
	var store: RefCounted = store_ref.get_ref()
	var result := PackedInt32Array()
	for p in store.size():
		if master[p] == person: result.append(p)
	result.sort()
	return result

func lineage_ancestors(person: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	var p := master[person]
	while p >= 0 and p not in result:
		result.append(p)
		p = master[p]
	return result

func seniority(person: int) -> int:
	if master[person] < 0: return 0
	var rank := 1
	for p: int in disciples(master[person]):
		if joined[p] < joined[person] or (joined[p] == joined[person] and p < person): rank += 1
	return rank

func betray(person: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	var teacher := master[person]
	if teacher < 0: return
	var founder := teacher
	while master[founder] >= 0: founder = master[founder]
	for p in store.size():
		if p == founder or founder in lineage_ancestors(p): ties.event(p, person, "betrayal", store.day)
	master[person] = -1
	if index_day == store.day and teacher < master_load.size(): master_load[teacher] = maxi(0, master_load[teacher] - 1)
	guilt[person] += 3
	reputation[person] -= 40
	betrayal_happened = true
	note(person, "betrayal", "%s betrayed the lineage of %s" % [store.names[person], store.names[founder]])

func inherit(child: int, mother: int, dad: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	father[child] = dad
	if mind: mind.inherit(child, mother, dad)
	if annual_index and index_day == store.day:
		for parent: int in [mother, dad]:
			if not annual_children.has(parent): annual_children[parent] = PackedInt32Array()
			annual_children[parent].append(child)
	var inherited_opinions: Dictionary = {}
	for parent: int in [mother, dad]:
		var e := ties.head[parent]
		while e >= 0:
			var other := ties.target[e]
			var value: Vector2 = inherited_opinions.get(other, Vector2.ZERO)
			inherited_opinions[other] = value + Vector2(ties.opinion[e], 1)
			var inherited := ties.tie(child, other, ties.opinion[e] * .3)
			if inherited >= 0 and ties.bonds[e] & Relationships.BENEFACTOR: ties.bonds[inherited] |= Relationships.BENEFACTOR
			if inherited >= 0: ties.inherit_grudge(e, inherited, .3)
			e = ties.next[e]
	for other: int in inherited_opinions:
		var value: Vector2 = inherited_opinions[other]
		var e := ties.find(child, other)
		if e >= 0: ties.opinion[e] = value.x / value.y * .3
	for parent: int in [mother, dad]:
		var kin := ties.tie(child, parent)
		ties.opinion[kin] = 55
		ties.familiarity[kin] = 40
		ties.trust[kin] = 60
		ties.tie(parent, child, 60)
	births += 1
	note(child, "birth", "%s was born to %s and %s" % [store.names[child], store.names[mother], store.names[dad]])

func seed() -> void:
	var store: RefCounted = store_ref.get_ref()
	var families: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/families.json"))
	for family: Dictionary in families:
		var child: int = store.names.find(family.child)
		if child < 0: continue
		store.parent_id[child] = store.names.find(family.mother)
		father[child] = store.names.find(family.father)
		if mind:
			for parent: int in [store.parent_id[child], father[child]]:
				if parent >= 0: mind.child_count[parent] = mini(255, mind.child_count[parent] + 1)
		var parent: int = store.parent_id[child] if store.parent_id[child] >= 0 else father[child]
		if parent >= 0 and store.age(child) >= 12 and store.age(child) < 18:
			var duties: Array = ["chores", store.schedules[store.job[parent]][-1]]
			store.job[child] = store.register_job("apprentice " + store.jobs[store.job[parent]], duties)
			store.prepare_person(child)
	# Seed acquaintance from actual homes and work; no preassigned sect or romance.
	for a in store.size():
		if not alive[a]: continue
		for b in store.size():
			if a == b or not alive[b] or ties.find(a, b) >= 0: continue
			if store.household[a] == store.household[b]:
				# Orphans raised under one roof start as friends.
				var e := ties.tie(a, b, 40)
				ties.familiarity[e] = 70
				ties.trust[e] = 45
				ties.bonds[e] |= Relationships.FRIEND
			elif store.shared_work(a, b) or store.locations[a].distance_squared_to(store.locations[b]) < 4096:
				var e := ties.tie(a, b, 25)
				ties.familiarity[e] = 40
				ties.trust[e] = 30
	# The village has experienced lay leadership, never a sect rank.
	if store.size() > 0:
		var candidate := 0
		for p in store.size():
			if store.age(p) >= 18 and store.attributes[p * 8 + 7] > store.attributes[candidate * 8 + 7]: candidate = p
		store.touch(candidate, "leadership.leadership", 8, 3650)
	refresh_factions()

var master_load := PackedInt32Array()
var annual_children: Dictionary = {}
var annual_index := false
var index_day := -1
var index_cursor := 0
var social_cursor := 0
var social_size := 0
var social_day := 0
var social_days := 0
var social_pending := false
var faction_pending := false

func begin_tick(on_day: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	if on_day - last_week < int(events.week_days) or social_pending: return
	social_days = on_day - last_week
	last_week = on_day
	social_day = on_day
	social_cursor = 0
	social_size = store.size()
	master_load.resize(social_size)
	master_load.fill(0)
	annual_children.clear()
	annual_index = on_day % 365 < 7
	index_day = on_day
	index_cursor = 0
	social_pending = true
	if temper: temper.wild.week(social_days, on_day)
	var year := on_day / 365
	if archive and year != archived_year:
		if archived_year >= 0: archive.year_end(year - 1)
		archived_year = year
	if year != wanderer_year:
		wanderer_year = year
		wanderer_present = store.rng.randf() < float(events.wanderer_per_year)
		if wanderer_present:
			faction("outsiders", "west_road_wanderer", "West Road wandering cultivator", PackedInt32Array(), -1)
			note(-1, "visitor", "A wandering cultivator offered to test village youths on the West Road")

func process_tick(limit: int = 32) -> bool:
	if faction_pending: return false
	if not social_pending: return true
	if index_cursor < social_size:
		var index_stop := mini(social_size, index_cursor + limit)
		while index_cursor < index_stop:
			var p := index_cursor
			if master[p] >= 0: master_load[master[p]] += 1
			if annual_index:
				for parent: int in parents(p):
					if parent < 0: continue
					if not annual_children.has(parent): annual_children[parent] = PackedInt32Array()
					annual_children[parent].append(p)
			index_cursor += 1
		return false
	var stop := mini(social_size, social_cursor + limit)
	while social_cursor < stop:
		_tick_person(social_cursor, social_days, social_day, social_size)
		social_cursor += 1
	if social_cursor < social_size: return false
	if social_day / 365 != last_year:
		last_year = social_day / 365
		if population.async_factions:
			faction_pending = true
			refresh_factions(true)
			return false
		refresh_factions()
	social_pending = false
	annual_index = false
	annual_children.clear()
	return true

func tick(on_day: int) -> void:
	begin_tick(on_day)
	while not process_tick(256): pass

func _tick_person(p: int, days: int, on_day: int, n: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	if not alive[p]: return
	var social_flags: int = ties.drift_person(p, store, days)
	rivalry[p] = 1 if social_flags & 4 else 0
	var years: int = store.age(p)
	if years > lifespan(p):
		store.mood[p] = minf(.5, store.mood[p])
		if lifespan_death_enabled:
			alive[p] = 0
			note(p, "old_age", "%s died of old age" % store.names[p])
			var heirs := children(p)
			if not heirs.is_empty(): pass_legacy(p, heirs[0])
			return
	if years >= 12 and years < 18 and store.parent_id[p] >= 0 and store.jobs[store.job[p]] == "child":
		store.job[p] = store.job[store.parent_id[p]]
		store.prepare_person(p)
	# Resolve one proximity contact per person/week, never every pair.
	var contact := (p + on_day / 7) % n
	if contact != p and store.settlement[contact] == store.settlement[p]:
		if on_day % 91 < 7 and store.shared_work(p, contact): ties.event(p, contact, "shared_work", on_day)
		elif store.household[contact] == store.household[p]: ties.event(p, contact, "meal", on_day)
		else: ties.tie(p, contact)
		if store.hunger[p] and not store.hunger[contact]:
			social_event(p, contact, "hunger_help")
			swear_oath(p, contact, "famine")
		if on_day % 365 < 7:
			if store.has_trait(p, "hot_tempered"): social_event(contact, p, "festival_insult")
			else: ties.event(p, contact, "meal", on_day)
	var in_hunting_grounds: bool = "hunt" in store.schedules[store.job[p]] or "logs" in store.schedules[store.job[p]]
	if not revealed[p] and store.spirit_root[p]:
		var rooted_parent := false
		for parent: int in parents(p):
			if parent >= 0 and store.spirit_root[parent]: rooted_parent = true
		if rooted_parent and years >= int(events.child_sign_min_age) + p % 7 and years <= int(events.child_sign_max_age): awaken(p, "a childhood sign in a rooted family")
		elif site[p] > 0 and store.rng.randf() < days * float(events.meditation_insight_per_day) * store.comprehension[p] * float(rules.density[site[p]]): awaken(p, "an insight in meditation at a qi-rich place")
		elif years >= 6 and years < 19 and wanderer_present and on_day % 365 < 7: awaken(p, "a wandering cultivator tested youths on the West Road")
		elif in_hunting_grounds and store.rng.randf() < days * float(events.spirit_fruit_find_per_day): awaken(p, "a spirit fruit found in the Eastern Hunting Grounds")
	if years >= 12 and store.rng.randf() < days * float(events.qi_site_visit_per_day): site[p] = store.rng.randi_range(1, 2)
	# No manuals lie waiting in the wild: an awakened mind works out its first breathing method by watching nature.
	if revealed[p] and technique[p] == 0 and store.rng.randf() < days * float(events.nature_breathing_per_day) * store.comprehension[p] * (1.5 if outdoors(p) else 1.0) * nature.insight(p):
		technique[p] = 1
		technique_element[p] = 0
		while (store.spirit_root[p] & (1 << technique_element[p])) == 0 and technique_element[p] < 9: technique_element[p] += 1
		var sights: Array = events.breathing_sights
		note(p, "manual", "%s worked out a breathing method from watching %s" % [store.names[p], sights[store.rng.randi_range(0, sights.size() - 1)]])
	if realm[p] >= 3 and store.comprehension[p] >= 1.5 and store.rng.randf() < days * float(events.technique_creation_per_day):
		technique[p] = 2
		technique_element[p] = 0
		while (store.spirit_root[p] & (1 << technique_element[p])) == 0: technique_element[p] += 1
		note(p, "technique", "%s created a complete lineage technique through insight" % store.names[p])
	cultivate(p, days)
	nature.observe(p, days, on_day)
	if temper: temper.weekly(p, days, on_day)
	if mind: mind.weekly(p, days, on_day, n)
	if master[p] >= 0 and on_day % 30 < 7:
		ties.event(p, master[p], "teaching", on_day)
		if realm[master[p]] >= 2 and technique[master[p]] > technique[p]:
			technique[p] = technique[master[p]]
			technique_element[p] = technique_element[master[p]]
	if mind == null and years >= 18 and spouse[p] < 0 and social_flags & 1:
		var e := ties.head[p]
		while e >= 0:
			var other := ties.target[e]
			if ties.opinion[e] >= 50 and store.sex[p] != store.sex[other] and abs(store.age(other) - years) <= int(events.marriage_age_gap):
				var reverse := ties.find(other, p)
				if reverse >= 0 and ties.opinion[reverse] >= 50 and not marriage_related(p, other): ties.bonds[e] |= Relationships.ROMANCE
				if marry(p, other): break
			e = ties.next[e]
	if due_day[p] >= 0 and on_day >= due_day[p]: deliver(p, on_day)
	elif due_day[p] < 0 and store.sex[p] == 1 and spouse[p] >= 0 and years >= int(events.fertility_min_age) and years <= int(events.fertility_max_age) and on_day - last_birth[p] >= int(events.birth_spacing_days) and store.hunger[p] == 0 and store.rng.randf() < days * float(events.birth_per_day):
		# Nine months to term; twins come a month early.
		twins[p] = 1 if store.rng.randf() < float(events.twin_chance) else 0
		due_day[p] = on_day + int(events.twin_gestation_days if twins[p] else events.gestation_days)
		note(p, "pregnancy", "%s is with child%s" % [store.names[p], " (twins)" if twins[p] else ""])
	if mind == null and years >= 12 and years < 30 and master[p] < 0 and social_flags & 2:
		var e := ties.head[p]
		while e >= 0:
			if ties.opinion[e] >= 20 and accept(ties.target[e], p): break
			e = ties.next[e]
	if years >= 60 and on_day % 365 < 7 and children(p).size() > 0:
		var child: int = children(p)[0]
		store.household[p] = store.household[child]
		store.household_names_day = -1
		ties.event(p, child, "filial_care", on_day)
		reputation[child] += 1
		if years == 70: pass_legacy(p, child)

## The father is the husband at conception; if he has died the child still takes his name.
func deliver(mother: int, on_day: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	var dad := spouse[mother]
	var surname: String = store.names[dad if dad >= 0 else mother].get_slice(" ", 0)
	for n in 2 if twins[mother] else 1:
		store.add_child(child_name(surname, store.rng.randi_range(0, 1)), mother, dad if dad >= 0 else mother)
	last_birth[mother] = on_day
	due_day[mother] = -1
	twins[mother] = 0

## Works under the open sky: fields, forest, hunting, herds or water.
func outdoors(p: int) -> bool:
	var store: RefCounted = store_ref.get_ref()
	for duty: String in store.schedules[store.job[p]]:
		if duty in ["fields", "hunt", "logs", "herd", "fishery", "orchard", "garden"]: return true
	return false

func faction(kind: String, key: String, title: String, members: PackedInt32Array, leader: int) -> int:
	var id: int = faction_keys.get(key, -1)
	if id < 0:
		id = factions.size()
		faction_keys[key] = id
		factions.append({"key": key, "absorbed_into": -1, "absorbed_members": PackedInt32Array(), "exiles": PackedInt32Array(), "id": id, "type": kind, "name": title, "leader": leader, "members": members, "succession": "eldest" if kind in ["household", "clan"] else "consensus", "cohesion": 50.0, "reputation": 0.0, "wealth": 0.0, "sites": [], "manuals": 0, "doctrine": {"martial": .2, "scholarly": .2, "mercantile": .2, "reclusive": .2, "expansionist": .2}, "goals": ["provide for members"], "loyalty": PackedFloat32Array()})
		if kind != "household": note(leader, "formation", "%s formed (%s)" % [title, kind])
	factions[id].name = title
	if not factions[id].exiles.is_empty():
		var retained := PackedInt32Array()
		for person: int in members:
			if person not in factions[id].exiles: retained.append(person)
		members = retained
	factions[id].members = members
	factions[id].leader = leader
	return id

func refresh_factions(time_sliced: bool = false) -> void:
	var refresh_counter := 0
	var refresh_began := Time.get_ticks_usec()
	var store: RefCounted = store_ref.get_ref()
	for f: Dictionary in factions:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		if str(f.key).begins_with("home:") or str(f.key).begins_with("guild:") or str(f.key).begins_with("lineage:") or str(f.key).begins_with("clan:") or str(f.key).begins_with("hall:"): f.members = PackedInt32Array()
	var homes: Dictionary = {}
	var domains: Dictionary = {}
	var lineages: Dictionary = {}
	var all := PackedInt32Array()
	for p in store.size():
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		if not alive[p]: continue
		all.append(p)
		var home: int = store.household[p]
		if not homes.has(home): homes[home] = PackedInt32Array()
		homes[home].append(p)
		if store.best_skill[p] >= 0 and store.best_level[p] >= 11:
			var domain: String = store.catalogue.domain_for(store.catalogue.ids[store.best_skill[p]])
			if not domains.has(domain): domains[domain] = PackedInt32Array()
			domains[domain].append(p)
		if master[p] >= 0:
			var chain := lineage_ancestors(p)
			var root: int = chain[-1]
			if not lineages.has(root): lineages[root] = PackedInt32Array([root])
			lineages[root].append(p)
	var leader := 0
	var leadership := -1.0
	for p: int in all:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		if store.age(p) < 18 or reputation[p] < 20: continue
		var level: int = store.level(p, "leadership.leadership")
		if level >= 8 and level > leadership:
			leader = p
			leadership = level
	faction("village", "village", "Servants' Village", all, leader if leadership >= 8 else -1)
	for home: int in homes:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var members: PackedInt32Array = homes[home]
		faction("household", "home:%d" % home, store.household_name(members[0]), members, members[0])
	for domain: String in domains:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var members: PackedInt32Array = domains[domain]
		if members.size() >= 3: faction("guild", "guild:" + domain, str(store.catalogue.domains[domain].name) + " guild", members, best_member(members))
	for root: int in lineages:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var members: PackedInt32Array = lineages[root]
		var lineage_id := faction("lineage", "lineage:%d" % root, store.names[root] + " lineage", members, root)
		members = factions[lineage_id].members
		var cultivators := 0
		for p: int in members:
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
			cultivators += int(realm[p] >= 2)
		if cultivators >= 3 and site[root] >= 1:
			faction("hall", "hall:%d" % root, store.names[root] + " Hall", members, root)
		if realm[root] >= 3 and technique[root] >= 2 and cultivators >= 5 and site[root] >= 1 and stores_years >= 1:
			faction("sect", "sect:%d" % root, store.names[root].get_slice(" ", 0) + " Mountain Sect", members, root)
	# Existing sects develop courts only around earned senior positions.
	for id in factions.size():
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var group: Dictionary = factions[id]
		if group.type != "sect": continue
		var available_sites: Array[int] = []
		for p: int in group.members:
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
			if site[p] > 0 and site[p] not in available_sites: available_sites.append(site[p])
		if group.members.size() >= 12:
			for p: int in group.members:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if realm[p] >= 3:
					var court := PackedInt32Array([p])
					court.append_array(disciples(p))
					faction("court", "court:%d" % p, store.names[p] + " court", court, p)
		if group.members.size() >= 100 and available_sites.size() >= 3:
			for p: int in group.members:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if realm[p] >= 4 or (realm[p] == 3 and layer[p] >= 3 and disciples(p).size() >= 10):
					var peak := PackedInt32Array([p])
					peak.append_array(disciples(p))
					faction("peak", "peak:%d" % p, store.names[p] + " Peak", peak, p)
	# Derive one surname line from parents; cache paths only during this rebuild.
	# This has no generation cutoff and does not create a clan for every ancestor.
	var clan_roots := PackedInt32Array()
	var clan_depth := PackedInt32Array()
	clan_roots.resize(store.size())
	clan_roots.fill(-1)
	clan_depth.resize(store.size())
	var descendants: Dictionary = {}
	var deepest: Dictionary = {}
	for person in store.size():
		var current: int = person
		var surname: String = store.names[person].get_slice(" ", 0)
		var path := PackedInt32Array()
		while clan_roots[current] < 0:
			if current in path:
				clan_roots[current] = current
				break
			path.append(current)
			var dad := father[current]
			var mom: int = store.parent_id[current]
			var parent := -1
			if dad >= 0 and store.names[dad].get_slice(" ", 0) == surname: parent = dad
			elif mom >= 0 and store.names[mom].get_slice(" ", 0) == surname: parent = mom
			if parent < 0:
				clan_roots[current] = current
				break
			current = parent
		for at in range(path.size() - 1, -1, -1):
			var member := path[at]
			if clan_roots[member] < 0:
				clan_roots[member] = clan_roots[current]
				clan_depth[member] = clan_depth[current] + 1
			current = member
		if alive[person]:
			var root := clan_roots[person]
			if not descendants.has(root): descendants[root] = PackedInt32Array()
			descendants[root].append(person)
			deepest[root] = maxi(int(deepest.get(root, 0)), clan_depth[person])
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
	for root: int in descendants:
		var members: PackedInt32Array = descendants[root]
		if members.size() >= 10 and int(deepest[root]) >= 2:
			var clan_leader := root
			if not alive[clan_leader]:
				clan_leader = members[0]
				for person: int in members:
					if store.birth_day[person] < store.birth_day[clan_leader]: clan_leader = person
			faction("clan", "clan:%d" % root, store.names[root].get_slice(" ", 0) + " clan", members, clan_leader)
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
	# Reapply persistent absorptions after rule-driven groups have refreshed.
	for group: Dictionary in factions:
		var destination: int = group.absorbed_into
		if destination < 0: continue
		var incoming := merge_members(group.members, group.absorbed_members)
		var merged := merge_members(factions[destination].members, incoming)
		var retained := PackedInt32Array()
		for person: int in merged:
			if person not in factions[destination].exiles: retained.append(person)
		factions[destination].members = retained
		group.members = PackedInt32Array()
	memberships.clear()
	for f: Dictionary in factions:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		f.members.sort()
		var loyalty := PackedFloat32Array()
		var total := 0.0
		var fame := 0.0
		f.sites = []
		f.manuals = 0
		f.wealth = stores_years * f.members.size() * 365
		for p: int in f.members:
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
			var e := ties.find(p, int(f.leader)) if int(f.leader) >= 0 else -1
			var kin := 0
			for parent: int in parents(p):
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if parent >= 0:
					var at: int = f.members.bsearch(parent)
					kin += int(at < f.members.size() and f.members[at] == parent)
			var fit: float = (store.comprehension[p] - 1) * float(f.doctrine.scholarly) * 10
			var value := clampf(40 + (ties.opinion[e] * .4 if e >= 0 else 0) + (10 if store.hunger[p] == 0 else -20) + kin * 5 + fit, 0, 100)
			fame += reputation[p]
			f.manuals += int(technique[p] > 0)
			if site[p] > 0 and site[p] not in f.sites: f.sites.append(site[p])
			loyalty.append(value)
			total += value
			if not memberships.has(p): memberships[p] = PackedInt32Array()
			memberships[p].append(int(f.id))
		f.loyalty = loyalty
		f.cohesion = total / maxi(1, f.members.size())
		f.reputation = fame / maxi(1, f.members.size())
	var before := factions.size()
	for id in before:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var group: Dictionary = factions[id]
		if group.members.is_empty() or int(group.absorbed_into) >= 0: continue
		if group.type in ["household", "village", "clique", "alliance", "outsiders"]: continue
		var grievances: Dictionary = {}
		for p: int in group.members:
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
			var e := ties.head[p]
			while e >= 0:
				if ties.has_grudge(e):
					var cause: String = ties.grudge_record(e).cause
					if not grievances.has(cause): grievances[cause] = PackedInt32Array()
					if p not in grievances[cause]: grievances[cause].append(p)
				e = ties.next[e]
		for cause: String in grievances:
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
			var members: PackedInt32Array = grievances[cause]
			if members.size() >= 3:
				faction("clique", "clique:%d:%s" % [id, cause], cause.capitalize() + " grievance circle", members, members[0])
				group.cohesion = maxf(0, group.cohesion - members.size() * 2)
		if group.cohesion < 30:
			for p: int in group.members:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if p != group.leader and schism(id, p) >= 0: break
		if group.cohesion < 20 and group.members.size() < 3:
			for strong in before:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if factions[strong].type == group.type and factions[strong].cohesion >= 50:
					if absorb(id, strong): break
	# Schisms, absorptions and new cliques change membership in this same tick.
	memberships.clear()
	for group: Dictionary in factions:
		for person: int in group.members:
			if not memberships.has(person): memberships[person] = PackedInt32Array()
			memberships[person].append(int(group.id))
			refresh_counter += 1
			if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
				await Engine.get_main_loop().process_frame
				refresh_began = Time.get_ticks_usec()
	await refresh_positions(time_sliced)
	faction_pending = false

func best_member(members: PackedInt32Array) -> int:
	var store: RefCounted = store_ref.get_ref()
	var best := members[0]
	for p: int in members:
		if store.best_level[p] > store.best_level[best]: best = p
	return best

func domain_level(person: int, domain: String) -> int:
	var store: RefCounted = store_ref.get_ref()
	var best := 0
	var e: int = store.head[person]
	while e >= 0:
		if store.catalogue.domain_for(store.catalogue.ids[store.skill_id[e]]) == domain: best = maxi(best, store.skill_level[e])
		e = store.skill_next[e]
	return best

func average_opinion(person: int) -> float:
	var store: RefCounted = store_ref.get_ref()
	var total := 0.0
	var count := 0
	for p in store.size():
		var e := ties.find(p, person)
		if e >= 0:
			total += ties.opinion[e]
			count += 1
	return total / maxi(1, count)

func refresh_positions(time_sliced: bool = false) -> void:
	var refresh_counter := 0
	var refresh_began := Time.get_ticks_usec()
	var store: RefCounted = store_ref.get_ref()
	positions.clear()
	var influence := PackedFloat32Array()
	var influence_count := PackedInt32Array()
	influence.resize(store.size())
	influence_count.resize(store.size())
	for person in store.size():
		var e := ties.head[person]
		while e >= 0:
			influence[ties.target[e]] += ties.opinion[e]
			influence_count[ties.target[e]] += 1
			e = ties.next[e]
		if time_sliced and person % 32 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
	var definitions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/positions.json"))
	var sect_members := PackedInt32Array()
	var halls := 0
	var manuals := 0
	var sites: Dictionary = {}
	for f: Dictionary in factions:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		if f.type == "sect":
			for p: int in f.members:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if p not in sect_members: sect_members.append(p)
		if f.type == "hall": halls += 1
	for p in store.size():
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		manuals += int(technique[p] > 0)
		if site[p] > 0: sites[site[p]] = true
	var outer_count := 0
	for p: int in sect_members:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		outer_count += int(revealed[p] > 0 and store.comprehension[p] >= .6)
	for definition: Dictionary in definitions:
		refresh_counter += 1
		if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
			await Engine.get_main_loop().process_frame
			refresh_began = Time.get_ticks_usec()
		var exists := false
		var holder := -1
		match str(definition.id):
			"headman":
				exists = true
				var best := -1
				for p in store.size():
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					var skill: int = store.level(p, "leadership.leadership")
					if alive[p] and store.age(p) >= 18 and skill >= 8 and skill > best and influence[p] / maxi(1, influence_count[p]) >= 20:
						holder = p
						best = skill
				var village_id: int = faction_keys.get("village", -1)
				if village_id >= 0:
					var previous: int = factions[village_id].leader
					if previous >= 0 and previous != holder and holder >= 0: social_event(previous, holder, "competition")
					factions[village_id].leader = holder
			"craftsman":
				for f: Dictionary in factions:
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					if f.type == "guild" and f.members.size() >= 3:
						exists = true
						var p := best_member(f.members)
						if store.best_level[p] >= 16 and (holder < 0 or store.best_level[p] > store.best_level[holder]): holder = p
			"hall_master":
				exists = halls > 0
				for f: Dictionary in factions:
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					if f.type == "hall" and realm[f.leader] >= 2 and (realm[f.leader] > 2 or layer[f.leader] >= 3): holder = f.leader
			"sect_master", "outer": exists = not sect_members.is_empty()
			"elder": exists = sect_members.size() >= 12
			"inner":
				for p: int in sect_members:
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					if realm[p] >= 2 and disciples(p).size() < (6 if realm[p] >= 4 else (3 if realm[p] >= 3 else 1)): exists = true
			"steward": exists = outer_count >= 20
			"mission": exists = sect_members.size() >= 30
			"scripture": exists = manuals >= 3
			"alchemy":
				for p in store.size():
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					if domain_level(p, "alchemy") >= 20: exists = true
			"law": exists = sect_members.size() >= 50 or betrayal_happened
			"peak": exists = sect_members.size() >= 100 and sites.size() >= 3
			"grand_elder":
				for p: int in sect_members:
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					if realm[p] >= 4: exists = true
		if exists and holder < 0:
			var candidates := sect_members
			if definition.id in ["alchemy", "scripture", "law"]:
				candidates = PackedInt32Array()
				for p in store.size():
					refresh_counter += 1
					if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
						await Engine.get_main_loop().process_frame
						refresh_began = Time.get_ticks_usec()
					candidates.append(p)
			for p: int in candidates:
				refresh_counter += 1
				if time_sliced and refresh_counter % 64 == 0 and Time.get_ticks_usec() - refresh_began >= 2000:
					await Engine.get_main_loop().process_frame
					refresh_began = Time.get_ticks_usec()
				if not alive[p]: continue
				var qualified := false
				match str(definition.id):
					"sect_master": qualified = realm[p] >= 3
					"outer": qualified = revealed[p] > 0 and store.comprehension[p] >= .6
					"inner": qualified = master[p] >= 0 and realm[p] >= 2 and (realm[p] > 2 or layer[p] >= 4) and (store.root_grade[p] >= 2 or reputation[p] >= 80)
					"elder": qualified = realm[p] >= 3 or (realm[p] == 2 and layer[p] >= 9 and joined[p] > 0 and store.day - joined[p] >= 40 * 365)
					"steward": qualified = domain_level(p, "administration") >= 16 and reputation[p] >= 40
					"mission": qualified = maxi(domain_level(p, "administration"), domain_level(p, "logistics")) >= 16
					"scripture": qualified = domain_level(p, "letters") >= 16 and realm[p] >= 2 and (realm[p] > 2 or layer[p] >= 5)
					"alchemy": qualified = domain_level(p, "alchemy") >= 20 and (holder < 0 or domain_level(p, "alchemy") > domain_level(holder, "alchemy"))
					"law": qualified = domain_level(p, "law") >= 12 and store.has_trait(p, "impartial") and maxi(domain_level(p, "weapons"), domain_level(p, "unarmed_arts")) >= 16
					"peak": qualified = realm[p] >= 4 or (realm[p] == 3 and layer[p] >= 3 and disciples(p).size() >= 10)
					"grand_elder": qualified = realm[p] >= 4
				if qualified: holder = p
		positions.append({"name": definition.name, "exists": exists, "holder": holder, "condition": definition.exists_when, "hold_when": definition.hold_when})

func summary() -> Dictionary:
	var store: RefCounted = store_ref.get_ref()
	var realms: Dictionary = {}
	for p in store.size():
		var key: String = rules.realms[realm[p]].name
		realms[key] = int(realms.get(key, 0)) + 1
	var clans := 0
	for f: Dictionary in factions: clans += int(f.type == "clan" and not f.members.is_empty())
	var filled := 0
	for pos: Dictionary in positions: filled += int(pos.holder >= 0)
	var active_factions := 0
	for f: Dictionary in factions: active_factions += int(not f.members.is_empty() or f.type == "outsiders")
	return {"population": store.size(), "marriages": marriages, "births": births, "clans": clans, "awakenings": awakenings, "realms": realms, "factions": active_factions, "positions_filled": filled, "grudges": ties.grudge_count(), "body": temper.summary() if temper else {}}

func social_event(observer: int, actor: int, kind: String) -> void:
	if observer == actor: return
	var store: RefCounted = store_ref.get_ref()
	ties.event(observer, actor, kind, store.day)
	if mind:
		if kind in ["theft", "festival_insult", "competition"]: mind.feel(observer, Mind.ANGER, .5 if kind == "theft" else .35)
		if kind == "betrayal":
			mind.feel(observer, Mind.ANGER, .9)
			mind.feel(observer, Mind.AFRAID, .4)
			# Betrayal leaves people wary and bitter for life.
			mind.scar(observer, Mind.FEAR, .3)
			mind.scar(observer, Mind.SPITE, .2)
		if kind == "saved_life":
			mind.feel(observer, Mind.JOY, .5)
			mind.scar(observer, Mind.DEVOTION, .25)
	if kind == "saved_life": ties.bonds[ties.tie(actor, observer)] |= Relationships.DEBTOR
	if kind in ["theft", "betrayal", "festival_insult"]:
		reputation[actor] = maxf(-100, reputation[actor] - (20 if kind == "theft" else 5))
		# One witness transmits a bounded rumour rather than scanning the village.
		var e := ties.head[observer]
		if e >= 0:
			var witness := ties.target[e]
			var heard := ties.tie(witness, actor)
			if heard >= 0: ties.opinion[heard] = maxf(-100, ties.opinion[heard] - 3)
	if kind == "revenge":
		injury_until[actor] = store.day + 21
		reputation[actor] -= 5
	if kind in ["saved_life", "hunger_help"]: reputation[actor] = minf(100, reputation[actor] + 2)
	if kind in ["theft", "betrayal", "revenge", "duel", "mediation"]:
		note(observer, kind, "%s and %s: %s (no killing)" % [store.names[observer], store.names[actor], kind])

func swear_oath(a: int, b: int, trial: String) -> bool:
	var store: RefCounted = store_ref.get_ref()
	var ab := ties.find(a, b)
	var ba := ties.find(b, a)
	if trial not in ["famine", "beast attack"] or ab < 0 or ba < 0: return false
	if ties.opinion[ab] < 80 or ties.opinion[ba] < 80 or ties.familiarity[ab] < 30 or ties.familiarity[ba] < 30: return false
	ties.bonds[ab] |= Relationships.SWORN
	ties.bonds[ba] |= Relationships.SWORN
	note(a, "oath", "%s and %s swore siblinghood after a %s" % [store.names[a], store.names[b], trial])
	return true

func pass_legacy(person: int, heir: int) -> bool:
	var store: RefCounted = store_ref.get_ref()
	if heir not in children(person) and master[heir] != person: return false
	if technique[person] > technique[heir]:
		technique[heir] = technique[person]
		technique_element[heir] = technique_element[person]
	store.tool_quality[heir] = maxi(store.tool_quality[heir], store.tool_quality[person])
	store.household[heir] = store.household[person]
	for other: int in disciples(person):
		if other != heir: social_event(other, heir, "competition")
	note(person, "legacy", "%s passed a home, tools and notes to %s" % [store.names[person], store.names[heir]])
	return true

func pact(a: int, b: int) -> int:
	if a == b or a < 0 or b < 0 or a >= factions.size() or b >= factions.size(): return -1
	var members := merge_members(factions[a].members, factions[b].members)
	faction_relations["%d:%d" % [a, b]] = {"opinion": 50, "treaty": "mutual aid", "tribute": 0, "feud": false}
	return faction("alliance", "alliance:%d:%d" % [mini(a,b), maxi(a,b)], factions[a].name + " — " + factions[b].name + " pact", members, factions[a].leader)

func schism(id: int, rival: int) -> int:
	var store: RefCounted = store_ref.get_ref()
	var source: Dictionary = factions[id]
	if source.cohesion >= 30 or rival == source.leader or rival not in source.members: return -1
	var followers := PackedInt32Array([rival])
	var remaining := PackedInt32Array()
	for p: int in source.members:
		if p == rival: continue
		var e := ties.find(p, rival)
		if e >= 0 and ties.opinion[e] >= 40: followers.append(p)
		else: remaining.append(p)
	if followers.size() < 3 or remaining.is_empty(): return -1
	source.members = remaining
	for person: int in followers:
		if person not in source.exiles: source.exiles.append(person)
	var split := faction(source.type, "split:%d:%d" % [id, rival], store.names[rival] + " fellowship", followers, rival)
	faction_relations["%d:%d" % [id, split]] = {"opinion": -40, "treaty": "", "tribute": 0, "feud": true}
	note(rival, "schism", "%s split from %s with %d followers" % [store.names[rival], source.name, followers.size()])
	return split

func absorb(weak: int, strong: int) -> bool:
	if weak == strong or weak < 0 or strong < 0: return false
	var a: Dictionary = factions[weak]
	var b: Dictionary = factions[strong]
	if int(a.absorbed_into) >= 0 or a.members.is_empty(): return false
	if a.members.size() >= b.members.size() or a.cohesion > 30: return false
	a.absorbed_members = merge_members(a.absorbed_members, a.members)
	b.members = merge_members(b.members, a.members)
	for person: int in a.members:
		var at: int = b.exiles.find(person)
		if at >= 0: b.exiles.remove_at(at)
	a.members = PackedInt32Array()
	a.absorbed_into = strong
	a.goals = ["absorbed into " + str(b.name)]
	note(b.leader, "absorption", "%s joined %s" % [a.name, b.name])
	return true

func top_events(since_day: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for event: Dictionary in chronicle:
		if event.day >= since_day: records.append(event)
	var priority := {"awakening": 100, "schism": 90, "breakthrough": 80, "betrayal": 75, "marriage": 60, "birth": 50, "manual": 45, "formation": 40, "legacy": 30}
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = priority.get(a.kind, 10)
		var pb: int = priority.get(b.kind, 10)
		return a.day > b.day if pa == pb else pa > pb)
	return records.slice(0, 5)

func merge_members(a: PackedInt32Array, b: PackedInt32Array) -> PackedInt32Array:
	var result := a.duplicate()
	result.append_array(b)
	result.sort()
	if result.is_empty(): return result
	var written := 1
	for read in range(1, result.size()):
		if result[read] != result[written - 1]:
			result[written] = result[read]
			written += 1
	result.resize(written)
	return result

func marriage_related(a: int, b: int) -> bool:
	if bool(events.extended_kin_exclusion): return related(a, b)
	var a_kin := ancestors(a, 3)
	var b_kin := ancestors(b, 3)
	if a in b_kin or b in a_kin: return true
	for parent: int in parents(a):
		if parent >= 0 and parent in b_kin: return true
	for parent: int in parents(b):
		if parent >= 0 and parent in a_kin: return true
	return false


# A given name matching the child's sex that no living member of the family name already uses.
func child_name(surname: String, sex: int) -> String:
	var store: RefCounted = store_ref.get_ref()
	var pool: Array = given_names.female if sex == 1 else given_names.male
	var taken: Dictionary = {}
	for q in store.size():
		if alive[q] and store.names[q].get_slice(" ", 0) == surname: taken[store.names[q].get_slice(" ", 1)] = true
	var start: int = store.rng.randi_range(0, pool.size() - 1)
	for i in pool.size():
		var given: String = pool[(start + i) % pool.size()]
		if not taken.has(given): return surname + " " + given
	return surname + " " + str(pool[start]) + " the Younger"
