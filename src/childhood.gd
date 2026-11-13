extends RefCounted
## Childhood changes hearts and interests, never work experience.
const Mind = preload("res://src/mind.gd")
var society_ref: WeakRef
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/childhood.json"))
var interests: Array[Dictionary] = []
var talent_given := PackedByteArray()
var hungry_days := PackedInt32Array()
var potential_lost := PackedByteArray()
var watching := PackedInt32Array()
var watching_day := PackedInt32Array()

func _init(society: RefCounted) -> void:
	society_ref = weakref(society)

func add_person() -> void:
	interests.append({})
	talent_given.append(0)
	hungry_days.append(0)
	potential_lost.append(0)
	watching.append(-1)
	watching_day.append(-1)

func carer(child: int) -> int:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	for parent: int in s.parents(child):
		if parent >= 0 and s.alive[parent] and p.settlement[parent] == p.settlement[child] and s.site[parent] == 0:
			return parent
	return -1

func work_fraction(person: int) -> float:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	if p.age(person) < 12: return 0.0
	var cut := 0.0
	for child: int in s.children(person):
		if not s.alive[child] or p.age(child) >= 2 or carer(child) != person: continue
		cut = maxf(cut, float(config.care_hours_cut if p.age(child) == 0 else config.second_year_cut))
	return 1.0 - cut

func activity(person: int) -> String:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	if p.age(person) < 3:
		var parent := carer(person)
		return "an infant, at home with " + (p.names[parent] if parent >= 0 else "family")
	if watching[person] >= 0 and watching_day[person] == p.day:
		var adult := watching[person]
		return "watching %s at %s" % [p.names[adult], p.jobs[p.job[adult]]]
	return "playing near home" if p.age(person) < 6 else "playing with friends near the square"

func grow(person: int, days: int, on_day: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	var hungry: bool = household_hungry(person)
	if hungry:
		hungry_days[person] += days
		var loss := mini(int(config.hunger_loss_cap), hungry_days[person] / int(config.hunger_days) * int(config.hunger_potential_loss))
		while potential_lost[person] < loss:
			for a in 8:
				var index := person * 8 + a
				p.potential[index] = maxi(1, p.potential[index] - 1)
				p.attributes[index] = minf(p.attributes[index], p.potential[index])
			potential_lost[person] += 1
	for a in 8:
		var index := person * 8 + a
		p.attributes[index] = minf(p.potential[index], p.attributes[index] + float(config.growth_per_day) * days * maxf(0, 1.0 - p.attributes[index] / p.potential[index]) * (0.0 if hungry else 1.0))

func household_hungry(person: int) -> bool:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	if p.hunger[person] > 0: return true
	for parent: int in s.parents(person):
		if parent >= 0 and s.alive[parent] and p.household[parent] == p.household[person] and p.hunger[parent] > 0: return true
	return false

func tag_along(child: int, adult: int, on_day: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	if p.age(child) < 6 or p.age(child) >= 12 or adult < 0 or p.age(adult) < 12 or not s.alive[adult]: return
	var trade: String = p.jobs[p.job[adult]]
	interests[child][trade] = minf(1.0, float(interests[child].get(trade, 0.0)) + float(config.interest_gain))
	watching[child] = adult
	watching_day[child] = on_day

func weekly(person: int, days: int, on_day: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	var years: int = p.age(person)
	if years >= 12:
		if p.jobs[p.job[person]] == "child": choose_trade(person)
		return
	if years < 3: return
	var hungry := household_hungry(person)
	var warm := not hungry and carer(person) >= 0
	for parent: int in s.parents(person):
		if parent < 0 or not s.alive[parent]: continue
		s.ties.event(person, parent, "family_time", on_day)
		s.ties.event(parent, person, "family_time", on_day)
		warm = warm and p.mood[parent] >= float(config.warm_mood)
	for sibling: int in s.siblings(person):
		if s.alive[sibling]: s.ties.event(person, sibling, "family_time", on_day)
	if s.mind:
		if warm:
			s.mind.scar(person, Mind.DEVOTION, config.warm_scar)
			s.mind.scar(person, Mind.FEAR, -float(config.warm_scar))
		if hungry:
			s.mind.scar(person, Mind.FEAR, config.hunger_scar)
			s.mind.scar(person, Mind.AMBITION, config.hunger_scar)
	if years < 6: return
	var peer := -1
	var adult := -1
	var peers := 0
	var adults := 0
	for other in p.size():
		if other == person or not s.alive[other] or p.district[other] != p.district[person] or p.settlement[other] != p.settlement[person]: continue
		if p.age(other) >= 6 and p.age(other) < 12:
			peers += 1
			if p.rng.randi_range(1, peers) == 1: peer = other
		elif p.age(other) >= 12:
			adults += 1
			if p.rng.randi_range(1, adults) == 1: adult = other
	if peer >= 0 and p.rng.randf() < float(config.play_chance):
		var kind := "quarrel" if p.rng.randf() < float(config.quarrel_chance) else "play"
		s.ties.event(person, peer, kind, on_day)
		s.ties.event(peer, person, kind, on_day)
	if p.rng.randf() < float(config.tag_along_chance):
		var parent := carer(person)
		tag_along(person, parent if parent >= 0 else adult, on_day)
	talent(person)
	if p.rng.randf() < float(config.wander_chance):
		var stories: Array = config.wander_stories
		s.note(person, "childhood", "%s %s" % [p.names[person], stories[p.rng.randi_range(0, stories.size() - 1)]])
		if s.temper and s.temper.wild and s.temper.wild.herd > 0 and p.rng.randf() < float(config.wildlife_encounter_chance):
			var guardian := carer(person)
			s.note(person, "childhood", "%s fled a beast at the forest edge%s" % [p.names[person], "; " + p.names[guardian] + " drove it away" if guardian >= 0 else " and ran safely home"])
		if p.rng.randf() < float(config.scrape_chance):
			s.injury_until[person] = on_day + p.rng.randi_range(config.scrape_days[0], config.scrape_days[1])
			s.note(person, "injury", p.names[person] + " came home with a bruised knee")

func talent(person: int) -> void:
	if talent_given[person]: return
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	var words := ""
	for a in 8:
		var below := 0
		var count := 0
		for other in p.size():
			if other == person or not s.alive[other] or p.age(other) != p.age(person): continue
			count += 1
			if p.potential[other * 8 + a] < p.potential[person * 8 + a]: below += 1
		if count > 0 and float(below) / count >= float(config.talent_percentile):
			words = "shows unusual promise in " + str(p.catalogue.rules.attributes[a])
			break
	if words.is_empty() and p.comprehension[person] >= float(config.talent_comprehension): words = "remembers everything they hear"
	if words.is_empty(): return
	talent_given[person] = 1
	s.note(person, "talent", "%s %s" % [p.names[person], words])

func choose_trade(person: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var p: RefCounted = s.population
	var parent := carer(person)
	var best := -1
	var best_score := -INF
	for trade in p.jobs.size():
		if p.schedules[trade].is_empty() or p.jobs[trade].begins_with("apprentice"): continue
		var aptitude := 0.0
		var count := 0
		for task: Dictionary in p.prepared_tasks[trade]:
			for a: int in task.attribute_indices:
				aptitude += p.attributes[person * 8 + a] / 20.0
				count += 1
		var workers := 0
		for other in p.size():
			if s.alive[other] and p.age(other) >= 12 and p.job[other] == trade: workers += 1
		var score: float = float(interests[person].get(p.jobs[trade], 0.0)) * float(config.interest_weight) + aptitude / maxi(1, count) * float(config.aptitude_weight) + float(config.need_weight) / (workers + 1) + p.rng.randf() * float(config.choice_randomness)
		if parent >= 0 and p.job[parent] == trade: score += float(config.family_weight)
		if score > best_score:
			best = trade
			best_score = score
	if best < 0: return
	p.job[person] = best
	p.prepare_person(person)
	s.note(person, "apprenticeship", "At twelve, %s chose %s%s" % [p.names[person], p.jobs[best], " over their parent's " + p.jobs[p.job[parent]] if parent >= 0 and p.job[parent] != best else ""])

func parent_fight(parent: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	if not s.mind: return
	for child: int in s.children(parent):
		if s.alive[child] and s.population.age(child) >= 3 and s.population.age(child) < 12:
			s.mind.scar(child, Mind.SPITE, config.fight_scar)
