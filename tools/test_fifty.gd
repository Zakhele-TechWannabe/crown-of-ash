extends SceneTree
const Population = preload("res://src/population.gd")
const Save = preload("res://src/world_save.gd")
const Combat = preload("res://src/combat.gd")

func _init() -> void:
	var p: RefCounted = Population.new()
	var s: RefCounted = p.society
	var d: RefCounted = s.fifty
	var t: RefCounted = s.temper
	d.seed()
	assert(p.size() == 50 and d.open_places() == 0 and d.next_tournament == 4 * 365)
	assert(p.sex.count(0) > 5 and p.sex.count(1) > 5)
	var hearts: Dictionary = {}
	for id in 50:
		assert(p.age(id) == 12 and t.body_layer[id] == 0 and t.method[id] == 3)
		assert(p.settlement[id] == int(d.config.settlement) and p.household[id] > 0)
		assert(p.schedules[p.job[id]].is_empty() and t.grade_ceiling(id) == t.PERFECT)
		hearts[s.mind.heart.slice(id * s.mind.WEIGHTS, (id + 1) * s.mind.WEIGHTS).hex_encode()] = true
	assert(hearts.size() > 45, "Distinct inherited hearts")
	var law: RefCounted = preload("res://src/law.gd").new()
	s.law = law
	s.mind._options(0, s.mind.urges(0))
	s.mind._act(0, {"option": s.mind.Option.CULTIVATE, "target": -1}, 0)
	assert(law.totals.breaches == 0, "Terrace meditation never trespasses in the village sect")
	s.law = null
	var economy: RefCounted = preload("res://src/grain_economy.gd").new()
	economy.population = p
	assert(economy.daily_need() == 0, "No terrace rice")
	p.spirit_root[0] = 0
	var base: float = t.rate(0, 0)
	p.spirit_root[0] = 1
	p.root_purity[0] = 100
	assert(t.rate(0, 0) > base and not s.body_ready(0))
	# Even overwhelming blows stop below dying.
	var a: Dictionary = Combat.person(s, 0)
	a.power = 1e9
	var r: Dictionary = Combat.fight(a, Combat.person(s, 1), {"stop_at": 3}, p.rng)
	assert(r.harm[0] <= 60 and r.harm[1] <= 60 and r.how != "death")
	for i in 50:
		d.tournament(i * 1825)
		assert(d.ranking.size() == 50 and d.bouts.size() == 49)
		var unique: Dictionary = {}
		for rank in 50:
			var id: int = d.ranking[rank]
			assert(not unique.has(id) and d.people[id].rank == rank + 1)
			unique[id] = true
			assert(d.top(id, i * 1825 + 1824) == (rank < 10))
			assert(not d.top(id, (i + 1) * 1825))
	assert(s.alive.count(1) == 50 and s.injury_until.count(0) < 50, "50 safe tournaments apply injuries")
	var top_id: int = d.ranking[0]
	d.provision(top_id, 49 * 1825)
	assert(t.aim_doses[top_id] == 2)
	assert(is_equal_approx(d.training_factor(top_id, 49 * 1825), float(d.config.training_rate) * 1.3))
	for id in 7:
		t.body_layer[id] = 9
		for l in 9: t.grades[id * 9 + l] = t.PERFECT
		if id == 1: t.grades[id * 9] = t.HIGH
		d.peak(id, 0)
	assert(d.people[0].status == "apostle" and d.people[1].status == "envoy")
	assert(d.seats.count(-1) == 0 and d.people[6].status in ["envoy", "apostle"])
	# A direct challenge resolves exactly one seat and cannot be repeated in the same year.
	var challenger := 7
	t.body_layer[challenger] = 9
	for l in 9: t.grades[challenger * 9 + l] = t.PERFECT
	assert(d.challenge(challenger, 365))
	assert(not d.challenge(challenger, 365) and d.seats.count(-1) == 0 and d.open_places() == 0)
	s.die(1, "dao", "Envoy died")
	assert(d.people[1].status == "dead" and d.open_places() == 1)
	var apostle: int = d.seats[0]
	var birth: int = p.birth_day[apostle]
	var grades: PackedByteArray = t.grades.slice(apostle * 9, apostle * 9 + 9)
	s.die(apostle, "dao", "Apostle died")
	assert(d.people[apostle].status == "restoring" and d.open_places() == 1)
	d.next_tournament = 1000000
	d.last_income = 10
	d.stone = 9
	d.will = 30
	d.advance(3650)
	assert(not s.alive[apostle], "Restoration waits for stone")
	d.stone = 10
	d.will = 29
	d.advance(3651)
	assert(not s.alive[apostle], "Restoration waits for Will")
	d.will = 30
	d.advance(3652)
	assert(s.alive[apostle] and t.body_layer[apostle] == 9 and p.birth_day[apostle] == birth + 3652)
	assert(t.grades.slice(apostle * 9, apostle * 9 + 9) == grades and d.stone == 0 and d.will == 0)
	# Explicit choices driven by the mind: fear/family versus devotion/ambition/curiosity.
	var job: int = p.register_job("mortal", [])
	var mortal: int = p.add_person("Refuser", 20, job)
	for u in 8: s.mind._set_weight(mortal, s.mind.B2 + u, -3)
	s.mind.heart_ready[mortal] = 1
	s.mind._set_weight(mortal, s.mind.B2 + s.mind.FEAR, 3)
	assert(not d.invite(mortal) and p.settlement[mortal] == 0)
	for u in [s.mind.DEVOTION, s.mind.AMBITION, s.mind.CURIOSITY, s.mind.RESTLESS]: s.mind._set_weight(mortal, s.mind.B2 + u, 3)
	s.mind._set_weight(mortal, s.mind.B2 + s.mind.FEAR, -3)
	t.body_layer[mortal] = 4
	assert(d.invite(mortal) and p.settlement[mortal] != 0 and d.away(mortal))
	var old_threshold: float = d.config.admission.threshold
	d.config.admission.threshold = 0
	d._process_journeys(100000)
	assert(d.people[mortal].status == "candidate" and d.open_places() == 0 and t.body_layer[mortal] == 4)
	assert(d.admission.records[mortal][0].scores.size() == 4)
	# A call is allowed with full seats; good arrivals return honoured rather than overfill.
	for i in 200:
		var id: int = p.add_person("Pilgrim %d" % i, 20, job)
		s.mind.heart_ready[id] = 1
		for u in [s.mind.DEVOTION, s.mind.AMBITION, s.mind.CURIOSITY, s.mind.RESTLESS]: s.mind._set_weight(id, s.mind.B2 + u, 3)
		s.mind._set_weight(id, s.mind.B2 + s.mind.FEAR, -3)
	var count: int = d.call_to_heaven()
	assert(count > 100 and d.call_to_heaven() == 0)
	d._process_journeys(100000)
	assert(d.arrivals > 0 and d.arrivals < count / 3 and d.open_places() == 0 and d.journeys.is_empty())
	d.config.admission.threshold = old_threshold
	var other_policy := {"id":"future_sect", "age_min":10, "age_max":30, "threshold":1000, "weights":{"character":1}}
	assert(not d.admission.test(s, mortal, other_policy).passed and d.admission.records[mortal].size() == 2)
	# The actual recursive save hooks, encoded as the save system encodes them, preserve all per-person state.
	s.die(d.seats[1], "dao", "Restoring at save time")
	var travelling: int = p.add_person("Still searching", 20, job)
	d._depart(travelling, true)
	var snapshot: Dictionary = bytes_to_var(var_to_bytes(Save.capture(p)))
	var loaded: RefCounted = Population.new()
	Save.restore(loaded, snapshot)
	Save.repair_columns(loaded, snapshot, loaded.size())
	assert(loaded.society.fifty.people == d.people and loaded.society.fifty.seats == d.seats and loaded.society.fifty.journeys == d.journeys)
	assert(loaded.society.fifty.admission.records == d.admission.records and loaded.society.fifty.fate == d.fate)
	# Old state loads without dangling ids left by a freshly seeded world.
	var legacy: RefCounted = Population.new()
	legacy.add_person("Old resident", 20, legacy.register_job("mortal", []))
	var old: Dictionary = Save.capture(legacy)
	old.society.erase("fifty")
	Save.restore(loaded, old)
	Save.repair_columns(loaded, old, loaded.size())
	loaded.society.fifty.repair({})
	assert(loaded.size() == 51 and loaded.society.fifty.people.size() == 50 and loaded.society.alive.size() == 51)
	var decades: RefCounted = Population.new()
	decades.society.fifty.seed()
	for week in range(1, 2087):
		decades.day = mini(40 * 365, week * 7)
		decades.society.tick(decades.day)
		if week % 521 == 0: print("FIFTY TEST DECADE ", JSON.stringify(decades.society.fifty.summary()))
	assert(decades.society.fifty.tournaments == 8)
	assert(decades.society.fifty.people.size() == 50)
	print("FIFTY TEST 40 YEARS ", JSON.stringify(decades.society.fifty.summary()))
	print("FIFTY TEST PASS: creation, roots, 50 brackets, peak, challenge, restoration, admission, pilgrims, saves")
	quit()
