extends RefCounted
## Authoritative structure-of-arrays population. Walkers retain only local presentation.
## Sparse skill maps use linked packed pools (30 bytes/touched skill), never a dictionary/person.
const Catalogue = preload("res://src/skill_catalogue.gd")
const Modifiers = preload("res://src/skill_modifiers.gd")
const TOOL_RATES := [0.8, 1.0, 1.15, 1.3]
var base_xp_hour := 2.5
var green_thumb_mask := 0
var daily_has_modifiers := false
var async_factions := false
var society: RefCounted
var learning_rates := PackedFloat32Array()
var level_rates := PackedFloat32Array()
var practice_floors := PackedInt32Array()
var tick_days := 1
var catalogue := Catalogue.new()
var modifiers := Modifiers.new()
var names: Array[String] = []
var sex := PackedByteArray()
var birth_day := PackedInt32Array()
var household := PackedInt32Array()
var household_names: Dictionary = {}
var household_names_day := -1
var household_names_size := -1
var locations := PackedVector2Array()
var spatial_cells: Dictionary = {}
var settlement := PackedInt32Array()
var district := PackedInt32Array()
var job := PackedInt32Array()
var attributes := PackedFloat32Array()
var potential := PackedByteArray()
var comprehension := PackedFloat32Array()
var spirit_root := PackedInt32Array()
var root_purity := PackedByteArray()
var root_grade := PackedByteArray()
var constitution := PackedByteArray()
var luck := PackedFloat32Array()
var traits := PackedInt64Array()
var mood := PackedFloat32Array()
var hunger := PackedByteArray()
var tool_quality := PackedByteArray()
var parent_id := PackedInt32Array()
var head := PackedInt32Array()
var best_level := PackedByteArray()
var best_skill := PackedInt32Array()
var recently_levelled := PackedInt32Array()
var insights := PackedInt32Array()
var last_insight_day := PackedInt32Array()
var stuck := PackedByteArray()
var last_rust_check := PackedInt32Array()
# Pool: next, catalogue index, level, banked XP, days practised, gate flags, last practice.
var skill_next := PackedInt32Array()
var skill_id := PackedInt32Array()
var skill_level := PackedByteArray()
var skill_xp := PackedFloat32Array()
var skill_days := PackedInt32Array()
var skill_gate := PackedByteArray()
var skill_care := PackedInt32Array()
var skill_last := PackedInt32Array()
var jobs: Array[String] = []
var schedules: Array[Array] = []
var prepared_tasks: Array[Array] = []
var active_duties: Array[Array] = []
var job_versions := PackedInt32Array()
var person_versions := PackedInt32Array()
var practice_entries := PackedInt32Array()
var events: Array[Dictionary] = []
var day := 0
var pending_day := -1
var cursor := 0
var teacher_cursor := 0
var rng := RandomNumberGenerator.new()
var xp_traits := PackedFloat32Array()
var output_traits := PackedFloat32Array()
var mood_traits := PackedFloat32Array()
var teacher_levels: Dictionary = {}
var trait_indices: Dictionary = {}
var total_insights := 0
var notable_levels := 0
var retain_events := true
var statistics_day := -1
var statistics_entries := -1
var cached_domains: Dictionary = {}
var cached_skills: Dictionary = {}

func _init() -> void:
	society = preload("res://src/society.gd").new(self)
	learning_rates = PackedFloat32Array(catalogue.rules.learning_rates)
	for level in 51:
		level_rates.append(learning_rate(level))
		practice_floors.append(practice_floor(level))
	for t in catalogue.traits.size(): trait_indices[catalogue.traits[t].id] = t
	base_xp_hour = float(catalogue.rules.base_xp_hour)
	green_thumb_mask = 1 << int(trait_indices.green_thumb)
	rng.seed = 718
	modifiers.instant_handler = _instant_modifier

func size() -> int:
	return names.size()

func register_job(name_text: String, duties: Array) -> int:
	assert(duties.size() <= 2, "Two half-day shifts per person")
	var index := jobs.find(name_text)
	if index >= 0: return index
	jobs.append(name_text)
	schedules.append(duties)
	var tasks: Array = []
	for duty: String in duties: tasks.append(catalogue.activities[duty])
	prepared_tasks.append(tasks)
	active_duties.append(duties.duplicate())
	job_versions.append(0)
	return jobs.size() - 1

func add_person(name_text: String, age: int, job_index: int, home: int = 0) -> int:
	var person := size()
	names.append(name_text)
	sex.append(person % 2)
	birth_day.append(day - age * 365 - rng.randi_range(0, 364))
	household.append(home)
	society.household_serial = maxi(society.household_serial, home)
	locations.append(Vector2.ZERO)
	settlement.append(0)
	district.append(home / 20)
	job.append(register_job("child", []) if age < 12 else job_index)
	person_versions.append(-1)
	for a in 8:
		var cap := rng.randi_range(10, 20)
		potential.append(cap)
		attributes.append(minf(cap, rng.randf_range(8, 12) if age >= 18 else (rng.randf_range(6, 10) if age >= 12 else rng.randf_range(3, 7))))
	comprehension.append(rng.randf_range(0.5, 2.0))
	var root := 0
	if rng.randf() < .03:
		var roll := rng.randf()
		var count := 1 if roll < .01 else (2 if roll < .10 else (3 if roll < .40 else (4 if roll < .75 else 5)))
		var elements: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
		for element in count:
			var choice := rng.randi_range(0, elements.size() - 1)
			root |= 1 << elements[choice]
			elements.remove_at(choice)
	spirit_root.append(root)
	root_purity.append(rng.randi_range(1, 100) if root else 0)
	root_grade.append(mini(4, 5 - _bit_count(root) + (1 if root & 992 else 0)) if root else 0)
	constitution.append(rng.randi_range(1, 5) if rng.randf() < .0002 else 0)
	luck.append(rng.randf_range(.8, 1.2))
	var bits: int = 0
	for roll in rng.randi_range(1, 3): bits |= 1 << rng.randi_range(0, catalogue.traits.size() - 1)
	traits.append(bits)
	var xp := 1.0
	var output := 0.0
	var mood_bonus := 0.0
	for t in catalogue.traits.size():
		if bits & (1 << t):
			xp *= float(catalogue.traits[t].xp_multiplier)
			output += float(catalogue.traits[t].output_bonus)
			mood_bonus += float(catalogue.traits[t].mood_bonus)
	xp_traits.append(xp)
	output_traits.append(output)
	mood_traits.append(mood_bonus)
	mood.append(clampf(.7 + mood_bonus, 0, 1))
	hunger.append(0)
	tool_quality.append(1)
	parent_id.append(-1)
	head.append(-1)
	for slot in 6: practice_entries.append(-1)
	best_level.append(0)
	best_skill.append(-1)
	recently_levelled.append(-1000)
	insights.append(0)
	last_insight_day.append(-10000)
	stuck.append(0)
	last_rust_check.append(day)
	society.add_person()
	return person

func touch(person: int, id: String, level: int = 0, practised: int = 0) -> int:
	assert(catalogue.indices.has(id), "Unknown skill: " + id)
	var index: int = catalogue.indices[id]
	var entry := head[person]
	while entry >= 0:
		if skill_id[entry] == index: return entry
		entry = skill_next[entry]
	entry = skill_id.size()
	skill_next.append(head[person])
	head[person] = entry
	skill_id.append(index)
	skill_level.append(level)
	skill_xp.append(0)
	skill_days.append(practised)
	skill_gate.append(0)
	skill_care.append(mini(practised, 365))
	skill_last.append(day)
	if level > best_level[person]:
		best_level[person] = level
		best_skill[person] = index
	return entry

func sparse_skills(person: int) -> Dictionary:
	var result: Dictionary = {}
	var entry := head[person]
	while entry >= 0:
		result[catalogue.ids[skill_id[entry]]] = {"level": skill_level[entry], "xp": skill_xp[entry], "days_practised": skill_days[entry], "gate_progress": {"flags": skill_gate[entry], "care_days": skill_care[entry]}}
		entry = skill_next[entry]
	return result

func age(person: int, on_day: int = -1) -> int:
	return maxi(0, ((day if on_day < 0 else on_day) - birth_day[person]) / 365)

func seed_residents(walkers: Array[Dictionary]) -> void:
	for p: Dictionary in walkers:
		var duties: Array = []
		if int(p.kind) != 8:
			duties.append(str(p.get("food_work", "fields" if int(p.kind) == 0 else "chores")))
			if p.has("material_work"): duties.append(str(p.material_work))
		else: duties.append("chores")
		var person := add_person(str(p.name), int(p.age), register_job(str(p.job), duties), int(p.home_cottage) / 8)
		set_location(person, Vector2(p.home))
		p.id = person
		if int(p.kind) == 8: parent_id[person] = maxi(0, person - 2)
		sex[person] = 1 if p.sex == "female" else 0
		for duty: String in duties:
			var activity: Dictionary = catalogue.activities[duty]
			var level := clampi(8 + (int(p.age) - 18) / 4, 8, 19) if int(p.kind) != 8 else 2
			var practice := maxi(0, (int(p.age) - 15) * 150)
			touch(person, activity.discipline, level, practice)
			touch(person, activity.specialisation, level, practice)
			for related: String in catalogue.disciplines[activity.discipline].related_disciplines:
				touch(person, related, maxi(0, level / 3), practice / 3)
			for key: String in catalogue.disciplines[activity.discipline].key_attributes:
				var a: int = catalogue.rules.attributes.find(key)
				attributes[person * 8 + a] = minf(potential[person * 8 + a], 10 + level * .17)
		prepare_person(person)

	# Youths learn a parent's trade alongside light household duties. Walker
	# schedules stay familiar until adulthood, while the simulated apprenticeship
	# starts at the design's age twelve.
	for p: Dictionary in walkers:
		var child := int(p.id)
		if int(p.kind) != 8 or age(child) < 12: continue
		var parent_person := parent_id[child]
		if parent_person < 0: continue
		var parent_duties: Array = schedules[job[parent_person]]
		var duties: Array = ["chores", parent_duties[-1]]
		job[child] = register_job("apprentice " + jobs[job[parent_person]], duties)
		var task: Dictionary = catalogue.activities[parent_duties[-1]]
		touch(child, task.discipline, 2)
		touch(child, task.specialisation, 2)
		prepare_person(child)

	society.seed()

func prepare_person(person: int) -> void:
	person_versions[person] = job_versions[job[person]]
	var slot := person * 6
	for task: Dictionary in prepared_tasks[job[person]]:
		practice_entries[slot] = touch(person, task.specialisation)
		practice_entries[slot + 1] = touch(person, task.discipline)
		var related: Array = catalogue.disciplines[task.discipline].related_disciplines
		practice_entries[slot + 2] = touch(person, related[0]) if not related.is_empty() else -1
		slot += 3

func sync_walkers(walkers: Array[Dictionary]) -> void:
	for p: Dictionary in walkers:
		var person := int(p.id)
		hunger[person] = int(p.hunger)
		mood[person] = clampf(float(p.contentment) + mood_traits[person], 0, 1)
		p.age = age(person)
		var known_parent: int = parent_id[person] if parent_id[person] >= 0 else society.father[person]
		if int(p.kind) == 8 and age(person) >= 18 and known_parent >= 0:
			var parent_person := known_parent
			job[person] = job[parent_person]
			prepare_person(person)
			p.job = jobs[job[person]]
			for parent_walker: Dictionary in walkers:
				if int(parent_walker.id) != parent_person: continue
				p.kind = int(parent_walker.kind)
				p.work = parent_walker.work
				for key: String in ["food_work", "material_work"]:
					if parent_walker.has(key): p[key] = parent_walker[key]
				break

func begin_day(next_day: int) -> bool:
	if pending_day >= 0 or next_day <= day: return false
	daily_has_modifiers = not modifiers.active.is_empty()
	_update_calendar(next_day)
	pending_day = next_day
	cursor = 0
	teacher_levels.clear()
	teacher_cursor = 0
	return true

func process_batch(max_people: int = 256) -> bool:
	if pending_day < 0: return true
	if society.social_pending:
		if not society.process_tick(max_people): return false
		pending_day = -1
		modifiers.expire(day)
		return true
	if teacher_cursor < size():
		var teacher_stop := mini(size(), teacher_cursor + max_people)
		while teacher_cursor < teacher_stop:
			var person := teacher_cursor
			if person_versions[person] != job_versions[job[person]]: prepare_person(person)
			var slot := person * 6
			for task: Dictionary in prepared_tasks[job[person]]:
				var key: int = settlement[person] * 16777216 + district[person] * 4096 + int(task.discipline_index)
				if not teacher_levels.has(key): teacher_levels[key] = [0, false]
				var level: int = skill_level[practice_entries[slot + 1]]
				if level > int(teacher_levels[key][0]):
					teacher_levels[key] = [level, has_trait(person, "born_teacher")]
				slot += 3
			teacher_cursor += 1
		return false
	var stop := mini(size(), cursor + max_people)
	while cursor < stop:
		_tick_person(cursor)
		cursor += 1
	if cursor == size():
		day = pending_day
		society.begin_tick(day)
		if society.social_pending: return false
		pending_day = -1
		modifiers.expire(day)
		return true
	return false

func tick_span(next_day: int) -> void:
	tick_days = maxi(1, next_day - day)
	tick_day(next_day)
	tick_days = 1

func tick_day(next_day: int) -> void:
	if not begin_day(next_day): return
	while not process_batch(1024): pass

func has_trait(person: int, id: String) -> bool:
	return trait_indices.has(id) and (traits[person] & (1 << int(trait_indices[id]))) != 0

func _tick_person(person: int) -> void:
	if not society.alive[person] or society.fifty.away(person): return
	stuck[person] = 0
	var years := age(person, pending_day)
	if years < 12:
		society.childhood.grow(person, tick_days, pending_day)
		return
	var age_factor := 1.4 if years < 18 else (1.0 if years <= 35 else (.8 if years <= 50 else (.55 if years <= 65 else .35)))
	var food_factor := 0.0 if hunger[person] >= 4 else (.6 if hunger[person] > 0 else (1.1 if mood[person] >= .45 and mood[person] < .78 else (1.0 if mood[person] >= .78 else .9)))
	if person_versions[person] != job_versions[job[person]]: prepare_person(person)
	var span_multiplier := tick_days * (1.1 if society.rivalry[person] else 1.0)
	var learning: float = society.childhood.work_fraction(person) * base_xp_hour * comprehension[person] * age_factor * food_factor * xp_traits[person] * TOOL_RATES[tool_quality[person]] * span_multiplier
	var task_slot := person * 6
	for task: Dictionary in prepared_tasks[job[person]]:
		var attr := 0.0
		for attribute_index: int in task.attribute_indices:
			attr += attributes[person * 8 + attribute_index]
		attr /= task.attribute_indices.size()
		var e := practice_entries[task_slot]
		var parent := practice_entries[task_slot + 1]
		# Unlocked techniques require their parent level AND attributes. Assisted novices
		# practise the parent at half rate until the technique is available.
		var spec: Dictionary = catalogue.skills[task.specialisation]
		var unlocked: bool = skill_level[parent] >= int(spec.unlock_level) and not spec.locked
		for requirement: Vector2i in spec.attribute_thresholds:
			if attributes[person * 8 + requirement.x] < requirement.y: unlocked = false
		var practice_level: int = skill_level[e] if unlocked else skill_level[parent]
		var gap := int(task.difficulty) - practice_level
		var difficulty := .1 if gap < -5 else (.5 if gap > 5 else 1.0)
		var teacher: Array = teacher_levels[settlement[person] * 16777216 + district[person] * 4096 + int(task.discipline_index)]
		var teacher_factor := (1.8 if teacher[1] else 1.5) if int(teacher[0]) >= int(skill_level[e]) + 5 else 1.0
		var xp: float = learning * float(task.hours) * attr / 10.0 * teacher_factor * difficulty
		if traits[person] & green_thumb_mask and catalogue.domain_for(task.discipline) in ["grain_farming", "gardens"]: xp *= 1.3
		# A rare failed attempt still teaches half of the usual XP.
		if (person * 17 + pending_day) % 97 == 0: xp *= .5
		if unlocked: _gain(person, e, xp, attr, int(teacher[0]))
		_gain(person, parent, xp * (.4 if unlocked else .5), attr, int(teacher[0]))
		if practice_entries[task_slot + 2] >= 0: _gain(person, practice_entries[task_slot + 2], xp * .05, attr, 0)
		task_slot += 3
		for trained_attribute: int in task.attribute_indices:
			var index := person * 8 + trained_attribute
			var current_attribute := attributes[index]
			var cap := float(potential[index])
			var growth := tick_days * .0008 * maxf(0.0, 1.0 - current_attribute / cap) * food_factor
			if constitution[person] == 1 and trained_attribute < 4: growth *= 1.2
			if constitution[person] == 2 and trained_attribute >= 4: growth *= 1.15
			if daily_has_modifiers and modifiers.active.has(person): growth *= modifiers.value(person, "attribute:" + str(catalogue.rules.attributes[trained_attribute]), "attribute_multiplier", pending_day)
			attributes[index] = minf(cap, current_attribute + growth)
	# Attribute ageing is daily, independent of work. Rust consumes banked XP only;
	# levels never cross a title floor and skills never lose their acquired title.
	if years > 50:
		for a in (8 if years > 65 else 4): attributes[person * 8 + a] = maxf(1.0, attributes[person * 8 + a] - .0002 * tick_days)
	# Unused skills fade on a monthly cadence, amortising long sparse lists.
	var rust_days := pending_day - last_rust_check[person]
	if rust_days < 30: return
	last_rust_check[person] = pending_day
	_rust_person(person, rust_days)

func _rust_person(person: int, rust_days: int) -> void:
	var entry := head[person]
	while entry >= 0:
		var level := int(skill_level[entry])
		if level > 15 and pending_day - skill_last[entry] > 30 and (level % 5 != 1 or skill_xp[entry] > 0):
			var floor_level: int = (level - 1) / 5 * 5 + 1
			var remaining := skill_xp[entry] - catalogue.thresholds[skill_level[entry]] * .0001 * mini(rust_days, pending_day - skill_last[entry] - 30)
			if remaining < 0 and skill_level[entry] > floor_level:
				skill_level[entry] -= 1
				remaining += catalogue.thresholds[skill_level[entry]]
				rebuild_best(person)
			skill_xp[entry] = maxf(0.0, remaining)
		entry = skill_next[entry]

func _gain(person: int, entry: int, xp: float, attr: float, teacher: int, learning_ceiling: int = 50) -> void:
	if age(person, maxi(day, pending_day)) < 12: return
	if xp <= 0.0: return
	if skill_days[entry] < 30 and has_trait(person, "curious"): xp *= 1.1
	if skill_days[entry] == 0:
		xp += 25.0
		_event(person, "first", "first practice of " + str(catalogue.nodes[skill_id[entry]].name))
	var first_today := skill_last[entry] != pending_day
	if first_today:
		skill_days[entry] += tick_days
		if hunger[person] == 0 and mood[person] >= .45: skill_care[entry] += tick_days
		skill_last[entry] = pending_day
	if daily_has_modifiers and modifiers.active.has(person):
		var target := catalogue.ids[skill_id[entry]]
		xp *= modifiers.value(person, target, "xp_multiplier", pending_day)
		if first_today: xp += modifiers.value(person, target, "flat_xp", pending_day, 0)
	# Stretch later tiers without making the first seasons an endless grind.
	xp *= level_rates[skill_level[entry]]
	skill_xp[entry] += xp
	var level := int(skill_level[entry])
	if learning_ceiling < 50 and level >= learning_ceiling:
		skill_xp[entry] = minf(skill_xp[entry], catalogue.thresholds[level])
	while level < learning_ceiling and skill_xp[entry] >= catalogue.thresholds[level]:
		var id := catalogue.ids[skill_id[entry]]
		if skill_days[entry] < practice_floors[level + 1]:
			skill_xp[entry] = minf(skill_xp[entry], catalogue.thresholds[level] * 2)
			break
		if level > 0 and level % 5 == 0 and not _gate(person, entry, attr, teacher):
			stuck[person] = 1
			# One daily insight roll while stuck, cached by gate flags.
			if first_today and (skill_gate[entry] & 1) == 0 and rng.randf() < 1.0 - pow(1.0 - .0002 * comprehension[person] * attributes[person * 8 + 6] / 10.0 * luck[person], tick_days):
				skill_gate[entry] |= 1
				insights[person] += 1
				last_insight_day[person] = pending_day
				total_insights += 1
				_event(person, "insight", "understood " + str(catalogue.skills[id].name) + " at the tier gate")
			break
		skill_xp[entry] -= catalogue.thresholds[level]
		level += 1
		skill_level[entry] = level
		if level % 5 == 1: skill_gate[entry] = 0
		recently_levelled[person] = pending_day
		if level > best_level[person]:
			best_level[person] = level
			best_skill[person] = skill_id[entry]
		if level >= 16:
			notable_levels += 1
			_event(person, "level", "%s reached %s %d" % [catalogue.skills[id].name, catalogue.title(level), level])

func _gate(person: int, entry: int, attr: float, teacher: int) -> bool:
	var id := catalogue.ids[skill_id[entry]]
	var parent: Dictionary = catalogue.disciplines[catalogue.discipline_for(id)]
	var gate: Dictionary = parent.gates[int(skill_level[entry]) / 5 - 1]
	if modifiers.active.has(person) and modifiers.value(person, id, "bottleneck_bypass", pending_day, 0) >= skill_level[entry]: return true
	if skill_days[entry] < int(gate.get("practice_days", 0)): return false
	if attr < float(gate.get("key_attribute", 0)): return false
	if gate.has("season_cycle") and skill_care[entry] < 91: return false
	if gate.has("milestone_output") and output_for(person, entry) * (1.15 if attr >= 12 else 1.0) < float(gate.milestone_output): return false
	if gate.get("or_insight", false) and teacher < int(gate.teacher_level) and (skill_gate[entry] & 1) == 0: return false
	if gate.get("insight", false) and (skill_gate[entry] & 1) == 0: return false
	if gate.get("qi", false): return society.realm[person] >= 2 or modifiers.value(person, id, "qi", pending_day, 0) > 0
	if gate.has("realm"):
		return society.realm[person] >= (3 if skill_level[entry] == 40 else 4)
	return true

func output_for(person: int, entry: int) -> float:
	var level := int(skill_level[entry])
	var bonus := output_traits[person]
	var parent: Dictionary = catalogue.disciplines[catalogue.discipline_for(catalogue.ids[skill_id[entry]])]
	var parent_level := level
	var own := head[person]
	while own >= 0:
		if catalogue.ids[skill_id[own]] == parent.id: parent_level = skill_level[own]; break
		own = skill_next[own]
	for perk: Dictionary in parent.perks:
		if parent_level >= int(perk.level) and perk.effect == "output": bonus += float(perk.value)
	return .5 + .03 * level + bonus

func output(person: int, duty: String) -> float:
	if age(person) < 12: return 0.0
	var entry := touch(person, catalogue.activities[duty].specialisation)
	return output_for(person, entry)

func _event(person: int, kind: String, message: String) -> void:
	if retain_events and events.size() < 8192: events.append({"day": maxi(day, pending_day), "person": person, "kind": kind, "text": names[person] + " " + message})

func _instant_modifier(person: int, effect: Dictionary) -> void:
	daily_has_modifiers = not modifiers.active.is_empty()
	match str(effect.effect):
		"potential_raise", "attribute_gain":
			var a: int = catalogue.rules.attributes.find(str(effect.target).trim_prefix("attribute:"))
			if a < 0: return
			if effect.effect == "potential_raise": potential[person * 8 + a] = mini(20, potential[person * 8 + a] + int(effect.value))
			else: attributes[person * 8 + a] = minf(potential[person * 8 + a], attributes[person * 8 + a] + float(effect.value))
		"flat_xp": _gain(person, touch(person, effect.target), float(effect.value), 10, 0)
		"insight_roll":
			var entry := head[person]
			if entry >= 0 and rng.randf() < .1 * comprehension[person]:
				skill_gate[entry] |= 1
				insights[person] += 1
				total_insights += 1
				last_insight_day[person] = day
				_event(person, "insight", "found an insight through " + str(effect.source))

func tier_distribution() -> Dictionary:
	var counts: Dictionary = {}
	for level: int in best_level:
		var title := catalogue.title(level)
		counts[title] = int(counts.get(title, 0)) + 1
	return counts

func skill_tier_distribution() -> Dictionary:
	var counts: Dictionary = {}
	for level: int in skill_level:
		var title := catalogue.title(level)
		counts[title] = int(counts.get(title, 0)) + 1
	return counts

func domain_statistics() -> Dictionary:
	_build_statistics()
	return cached_domains

func skill_statistics(id: String) -> Dictionary:
	_build_statistics()
	return cached_skills.get(id, {"count": 0, "best_level": 0, "person": -1})

func _build_statistics() -> void:
	if statistics_day == day and statistics_entries == skill_id.size(): return
	statistics_day = day
	statistics_entries = skill_id.size()
	cached_domains.clear()
	cached_skills.clear()
	for person in size():
		var per_person: Dictionary = {}
		var entry := head[person]
		while entry >= 0:
			if skill_level[entry] == 0:
				entry = skill_next[entry]
				continue
			var id := catalogue.ids[skill_id[entry]]
			var domain := catalogue.domain_for(id)
			for key: String in [id, catalogue.discipline_for(id), domain, str(catalogue.domains[domain].sphere)]:
				per_person[key] = maxi(int(per_person.get(key, 0)), skill_level[entry])
			entry = skill_next[entry]
		for key: String in per_person:
			var level: int = per_person[key]
			if not cached_skills.has(key): cached_skills[key] = {"count": 0, "best_level": 0, "person": -1}
			cached_skills[key].count += 1
			if level > int(cached_skills[key].best_level):
				cached_skills[key].best_level = level
				cached_skills[key].person = person
			if catalogue.domains.has(key):
				if not cached_domains.has(key): cached_domains[key] = {"count": 0, "total": 0.0, "experts": 0}
				cached_domains[key].count += 1
				cached_domains[key].total += level
				cached_domains[key].experts += int(level >= 26)

func set_location(person: int, location: Vector2) -> void:
	var old_cell := Vector2i((locations[person] / 64.0).floor())
	if spatial_cells.has(old_cell):
		var old: PackedInt32Array = spatial_cells[old_cell]
		var at := old.find(person)
		if at >= 0: old.remove_at(at)
		spatial_cells[old_cell] = old
	locations[person] = location
	var cell := Vector2i((location / 64.0).floor())
	var members: PackedInt32Array = spatial_cells.get(cell, PackedInt32Array())
	members.append(person)
	spatial_cells[cell] = members

func nearby(area: Rect2, limit: int = 100) -> PackedInt32Array:
	var selected := PackedInt32Array()
	var first_cell := Vector2i((area.position / 64.0).floor())
	var last_cell := Vector2i((area.end / 64.0).floor())
	for y in range(first_cell.y, last_cell.y + 1):
		for x in range(first_cell.x, last_cell.x + 1):
			for person: int in spatial_cells.get(Vector2i(x, y), PackedInt32Array()):
				if area.has_point(locations[person]):
					selected.append(person)
					if selected.size() >= limit: return selected
	return selected

func rebuild_best(person: int) -> void:
	best_level[person] = 0
	best_skill[person] = -1
	var entry := head[person]
	while entry >= 0:
		if skill_level[entry] > best_level[person]:
			best_level[person] = skill_level[entry]
			best_skill[person] = skill_id[entry]
		entry = skill_next[entry]

func add_child(name_text: String, mother: int, father: int) -> int:
	var chores := register_job("child", [])
	var child := add_person(name_text, 0, chores, household[mother])
	birth_day[child] = day
	parent_id[child] = mother
	settlement[child] = settlement[mother]
	district[child] = district[mother]
	for a in 8:
		potential[child * 8 + a] = clampi((int(potential[mother * 8 + a]) + int(potential[father * 8 + a])) / 2 + rng.randi_range(-2, 2), 10, 20)
		attributes[child * 8 + a] = clampf((attributes[mother * 8 + a] + attributes[father * 8 + a]) * .2 + rng.randf_range(-1, 1), 1, potential[child * 8 + a])
	var inherited := spirit_root[mother] | spirit_root[father]
	if inherited != 0 and rng.randf() < .4:
		while _bit_count(inherited) > 5:
			var bit := 1 << rng.randi_range(0, 9)
			inherited &= ~bit
		spirit_root[child] = inherited
		root_purity[child] = rng.randi_range(10, 100)
		root_grade[child] = mini(4, 5 - _bit_count(inherited) + (1 if inherited & 992 else 0))
	society.inherit(child, mother, father)
	settlement[child] = settlement[mother]
	set_location(child, locations[mother])
	return child

func _update_calendar(next_day: int) -> void:
	var day_of_year := (next_day - 1) % 365 + 1
	for j in schedules.size():
		var duties: Array = schedules[j].duplicate()
		for shift in duties.size():
			var duty: String = duties[shift]
			if duty == "fields" and day_of_year > 273: duties[shift] = "chores"
			elif duty in ["quarry", "mine"] and day_of_year > 273: duties[shift] = "smith"
			elif duty == "quarry" and day_of_year % 3 == 0: duties[shift] = "clay"
			elif duty == "weaver" and day_of_year >= 153 and day_of_year <= 182: duties[shift] = "hemp"
			elif duty == "smith" and day_of_year % 2 == 0: duties[shift] = "bloomery"
		if duties == active_duties[j]: continue
		active_duties[j] = duties
		job_versions[j] += 1
		var tasks: Array = []
		for duty: String in duties: tasks.append(catalogue.activities[duty])
		prepared_tasks[j] = tasks

func learning_rate(level: int) -> float:
	var band := 0 if level < 11 else (1 if level < 16 else (2 if level < 21 else (3 if level < 26 else 4)))
	return learning_rates[band]

func practice_floor(level: int) -> int:
	var floor_days := 0
	for boundary: String in catalogue.rules.practice_years:
		if level >= int(boundary): floor_days = maxi(floor_days, int(catalogue.rules.practice_years[boundary]) * 365)
	return floor_days

func level(person: int, id: String) -> int:
	var index: int = catalogue.indices.get(id, -1)
	var e := head[person]
	while e >= 0:
		if skill_id[e] == index: return skill_level[e]
		e = skill_next[e]
	return 0

func household_name(person: int) -> String:
	if household_names_day != day or household_names_size != size():
		household_names.clear()
		var heads: Dictionary = {}
		var surname_counts: Dictionary = {}
		var mixed: Dictionary = {}
		for p in size():
			if not society.alive[p]: continue
			if heads.has(household[p]):
				# Unrelated housemates (the orphans who arrived together) share a cottage, not a family name.
				if names[p].get_slice(" ", 0) != names[heads[household[p]]].get_slice(" ", 0): mixed[household[p]] = true
				continue
			heads[household[p]] = p
			var surname := names[p].get_slice(" ", 0)
			surname_counts[surname] = int(surname_counts.get(surname, 0)) + 1
		for home: int in heads:
			var p: int = heads[home]
			var surname := names[p].get_slice(" ", 0)
			if mixed.has(home): household_names[home] = "%s cottage %d" % [district_name(p), home + 1]
			else: household_names[home] = (names[p] if int(surname_counts[surname]) > 1 else surname) + " household"
		household_names_day = day
		household_names_size = size()
	return str(household_names.get(household[person], names[person] + " household"))

func district_name(person: int) -> String:
	return ["Lower Lane", "Mill Row", "Orchard Rise", "Spring Lane", "East Crofts"][district[person] % 5]

func _bit_count(bits: int) -> int:
	var count := 0
	while bits:
		count += bits & 1
		bits >>= 1
	return count

func shared_work(a: int, b: int) -> bool:
	if job[a] == job[b]: return true
	for duty: String in schedules[job[a]]:
		if duty in schedules[job[b]]: return true
	return false
