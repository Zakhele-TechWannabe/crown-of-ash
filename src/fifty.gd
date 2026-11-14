extends RefCounted
const Combat = preload("res://src/combat.gd")
const Admission = preload("res://src/admission.gd")
## Families from beyond the valley: none share a surname with the Servants' Village.
const SURNAMES := ["Song", "Tang", "Han", "Feng", "Deng", "Cao", "Peng", "Xiao", "Tian", "Dong", "Pan", "Yuan", "Cai", "Jiang", "Du", "Ye", "Wei", "Su", "Lu", "Ding", "Ren", "Shen", "Yao", "Cui", "Tan", "Fan", "Qin", "Bai", "Mo", "Gu"]
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/dao.json"))
var society_ref: WeakRef
var admission := Admission.new()
var people: Dictionary = {}
var journeys: Dictionary = {}
var fate: Dictionary = {}
var seats: Array[int] = []
var ranking: Array[int] = []
var bouts: Array[Dictionary] = []
var tournaments := 0
var deaths := 0
var stone := 0.0
var will := 0.0
var last_income := 0
var next_tournament := 0
var last_call := 0
var seeded := false
var first_apostle_day := -1
var first_envoy_day := -1
var pilgrims := 0
var arrivals := 0
var last_day := 0

func _init(society: RefCounted) -> void:
	society_ref = weakref(society)
	seats.resize(int(config.seats))
	seats.fill(-1)
	next_tournament = (int(config.tournament_years) - 1) * 365
	last_call = -int(config.call_days)

func member(p: int) -> bool:
	return people.has(p) and people[p].status != "dead"

func away(p: int) -> bool:
	return journeys.has(p)

func open_places() -> int:
	var occupied := 0
	for r: Dictionary in people.values(): occupied += int(r.status != "dead")
	return maxi(0, int(config.capacity) - occupied)

func seed() -> void:
	if seeded: return
	seeded = true
	var s: RefCounted = society_ref.get_ref()
	var store: RefCounted = s.population
	last_income = store.day / 365
	next_tournament = ((store.day / 365 + 1) / int(config.tournament_years) + 1) * 365 * int(config.tournament_years) - 365
	var job: int = store.register_job("heaven's disciple", [])
	for i in int(config.capacity):
		var sex: int = store.rng.randi_range(0, 1)
		var surname: String = SURNAMES[store.rng.randi_range(0, SURNAMES.size() - 1)]
		var p: int = store.add_person(s.child_name(surname, sex), int(config.initial_age), job, s.household_serial + 1)
		store.sex[p] = sex
		if s.mind: s.mind._found_heart(p)
		join(p)
	s.note(-1, "dao", "Fifty youths began from nothing in Heaven's Terrace, hidden on Heavenly Ridge")

func join(p: int) -> bool:
	if open_places() <= 0 or member(p): return false
	var s: RefCounted = society_ref.get_ref()
	var store: RefCounted = s.population
	people[p] = {"status": "candidate", "rank": 0, "bonus_until": 0, "seat": -1, "death_day": -1, "challenge_day": -365, "joined": store.day}
	store.settlement[p] = int(config.settlement)
	s.household_serial += 1
	store.household[p] = s.household_serial
	store.household_names_day = -1
	store.job[p] = store.register_job("heaven's disciple", [])
	var site: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/" + str(config.site)))
	store.set_location(p, Vector2(float(site.center[0]), float(site.center[1])))
	store.hunger[p] = 0
	provision(p, store.day)
	return true

func top(p: int, day: int) -> bool:
	return member(p) and int(people[p].bonus_until) > day

func training_factor(p: int, day: int) -> float:
	if not member(p): return 1.0
	return float(config.training_rate) * (float(config.training_bonus) if top(p, day) else 1.0)

func provision(p: int, day: int) -> void:
	if not member(p): return
	var s: RefCounted = society_ref.get_ref()
	var t: RefCounted = s.temper
	if not t: return
	t.method[p] = t.config.method_grade_cap.size() - 1
	if not t.training(p, day):
		t.hours[p] = int(config.drill_hours)
		t.regimen_until[p] = day + int(t.config.regimen_weeks) * 7
	t.aim_doses[p] = int(config.top_doses if top(p, day) else config.basic_doses)
	for med: String in t.medicine: t.medicine[med][p] = t.wild.units(med) * t.aim_doses[p]
	s.site[p] = 2 if top(p, day) else 1
	s.resources[p] = float(config.qi_bonus) if top(p, day) else 1.0
	s.population.hunger[p] = 0

func bout(a: int, b: int) -> Dictionary:
	var s: RefCounted = society_ref.get_ref()
	var store: RefCounted = s.population
	var r: Dictionary = Combat.fight(Combat.person(s, a), Combat.person(s, b), {"stop_at": 3}, store.rng)
	# An exhausted draw is decided by harm, then bracket order; the bracket must always advance.
	if int(r.winner) < 0:
		r.winner = 0 if float(r.harm[0]) <= float(r.harm[1]) else 1
		r.loser = 1 - int(r.winner)
	r.merge({"kind": "spar", "day": store.day, "ids": [a, b], "names": [store.names[a], store.names[b]]})
	r.fates = [Combat._hurt(s, a, r.harm[0], b, r), Combat._hurt(s, b, r.harm[1], a, r)]
	s.record_fight(r)
	var winner: int = r.ids[r.winner]
	var loser: int = r.ids[r.loser]
	s.ties.event(a, b, "duel", store.day)
	s.ties.event(b, a, "duel", store.day)
	if s.mind:
		s.mind.feel(winner, s.mind.JOY, .3)
		s.mind.scar(winner, s.mind.PRIDE, .03)
		if s.mind.urges(loser)[s.mind.SPITE] > .5: s.ties.event(loser, winner, "beaten", store.day)
	return {"winner": winner, "loser": loser, "harm_dealt": float(r.harm[r.winner]), "harm": r.harm, "ids": [a, b]}

func tournament(day: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var pool: Array[int] = []
	for p: int in people:
		if people[p].status == "candidate" and s.alive[p]: pool.append(p)
	if tournaments == 0:
		for i in range(pool.size() - 1, 0, -1):
			var j: int = s.population.rng.randi_range(0, i)
			var swap: int = pool[i]
			pool[i] = pool[j]
			pool[j] = swap
	else:
		pool.sort_custom(func(a: int, b: int) -> bool: return _seed_rank(a) < _seed_rank(b))
	var seeds := pool.duplicate()
	bouts.clear()
	var eliminated: Array = []
	var width := 1
	while width < pool.size(): width *= 2
	# Standard seeded tree: 1 v last, with high seeds receiving the missing entries as byes.
	var order: Array[int] = [0]
	while order.size() < width:
		var expanded: Array[int] = []
		for seed_index: int in order:
			expanded.append(seed_index)
			expanded.append(order.size() * 2 - 1 - seed_index)
		order = expanded
	var bracket: Array[int] = []
	for seed_index: int in order: bracket.append(pool[seed_index] if seed_index < pool.size() else -1)
	while bracket.size() > 1:
		var next: Array[int] = []
		var losers: Array[Dictionary] = []
		for i in range(0, bracket.size(), 2):
			var a: int = bracket[i]
			var b: int = bracket[i + 1]
			if a < 0 or b < 0:
				next.append(maxi(a, b))
				continue
			var result := bout(a, b)
			result.round = bracket.size()
			result.upset = seeds.find(result.winner) > seeds.find(result.loser)
			bouts.append(result)
			next.append(result.winner)
			losers.append(result)
			if result.upset: s.note(result.winner, "dao", "%s upset %s in the tournament" % [s.population.names[result.winner], s.population.names[result.loser]])
		losers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.harm_dealt > b.harm_dealt)
		eliminated.push_front(losers)
		bracket = next
	ranking.clear()
	if not bracket.is_empty() and bracket[0] >= 0: ranking.append(bracket[0])
	for round_losers: Array in eliminated:
		for result: Dictionary in round_losers: ranking.append(result.loser)
	for i in ranking.size():
		people[ranking[i]].rank = i + 1
		people[ranking[i]].bonus_until = day + int(config.tournament_years) * 365 if i < int(config.top_count) else 0
	tournaments += 1
	if not ranking.is_empty(): s.note(ranking[0], "dao", "%s won the five-year tournament; the top ten receive richer medicine and the qi seat. %d bouts left wounds to heal" % [s.population.names[ranking[0]], bouts.size()])

func _seed_rank(p: int) -> int:
	return int(people[p].rank) if int(people[p].rank) > 0 else 100000 + p

func peak(p: int, day: int) -> void:
	if not member(p): return
	var s: RefCounted = society_ref.get_ref()
	if not s.alive[p] or not s.temper or s.temper.body_layer[p] < 9: return
	var r: Dictionary = people[p]
	if r.status not in ["candidate", "envoy"]: return
	if not s.temper.perfect_so_far(p):
		if r.status == "candidate": _envoy(p)
		return
	var empty := seats.find(-1)
	if empty >= 0:
		_apostle(p, empty, day)
		return
	if day - int(r.challenge_day) < 365: return
	var u: PackedFloat32Array = s.mind.urges(p) if s.mind else PackedFloat32Array([0,0,.5,.5,.5,.5,.5,.5])
	if (u[6] + u[3] - u[2]) / 2 >= float(config.challenge_threshold):
		if not challenge(p, day) and r.status == "candidate": _envoy(p)
	else:
		r.challenge_day = day
		if r.status == "candidate": _envoy(p)

func _envoy(p: int) -> void:
	if first_envoy_day < 0: first_envoy_day = society_ref.get_ref().population.day
	people[p].status = "envoy"
	people[p].seat = -1
	society_ref.get_ref().note(p, "dao", "%s became an envoy" % society_ref.get_ref().population.names[p])

func _apostle(p: int, seat: int, day: int) -> void:
	people[p].status = "apostle"
	people[p].seat = seat
	seats[seat] = p
	if first_apostle_day < 0: first_apostle_day = day
	society_ref.get_ref().note(p, "dao", "%s became a Divine Apostle" % society_ref.get_ref().population.names[p])

func challenge(p: int, day: int) -> bool:
	var s: RefCounted = society_ref.get_ref()
	if not member(p) or not s.alive[p] or s.temper.body_layer[p] != 9 or not s.temper.perfect_so_far(p): return false
	if people[p].status not in ["candidate", "envoy"] or day - int(people[p].challenge_day) < 365: return false
	var weakest := -1
	var power := INF
	for a: int in seats:
		if a < 0 or not s.alive[a]: continue
		var value := float(Combat.person(s, a).power)
		if value < power:
			power = value
			weakest = a
	if weakest < 0: return false
	var seat: int = people[weakest].seat
	var result := bout(p, weakest)
	people[p].challenge_day = day
	_envoy(result.loser)
	_apostle(result.winner, seat, day)
	s.note(result.winner, "dao", "%s held the pedestal after a challenge from %s" % [s.population.names[result.winner], s.population.names[p]])
	return true

func on_death(p: int) -> void:
	if not member(p): return
	deaths += 1
	people[p].death_day = society_ref.get_ref().population.day
	people[p].status = "restoring" if people[p].status == "apostle" else "dead"

func advance(day: int) -> void:
	if not seeded or day == last_day: return
	last_day = day
	var s: RefCounted = society_ref.get_ref()
	var years := day / 365 - last_income
	if years > 0:
		stone += years * float(config.stone_per_year)
		will += years * float(config.will_per_year)
		last_income = day / 365
	for p: int in people:
		var r: Dictionary = people[p]
		if not s.alive[p] and r.status not in ["dead", "restoring"]: on_death(p)
		if r.status != "restoring": continue
		if day - int(r.death_day) < int(config.restore_years) * 365 or stone < float(config.restore_stone) or will < float(config.restore_will): continue
		stone -= float(config.restore_stone)
		will -= float(config.restore_will)
		s.population.birth_day[p] += day - int(r.death_day)
		s.alive[p] = 1
		s.injury_until[p] = 0
		r.status = "apostle"
		s.note(p, "dao", "%s returned from the pedestal, memories and flawless body intact" % s.population.names[p])
	_process_journeys(day)
	while day >= next_tournament:
		tournament(next_tournament)
		next_tournament += int(config.tournament_years) * 365

func eligible(p: int) -> bool:
	var s: RefCounted = society_ref.get_ref()
	return p >= 0 and p < s.population.size() and s.alive[p] and s.population.settlement[p] == 0 and s.realm[p] < 2 and s.population.age(p) >= int(config.admission.age_min) and s.population.age(p) <= int(config.admission.age_max) and not member(p) and not journeys.has(p)

func willingness(p: int) -> float:
	var s: RefCounted = society_ref.get_ref()
	var u: PackedFloat32Array = s.mind.urges(p) if s.mind else PackedFloat32Array([0,0,.5,.5,.5,.5,.5,.5])
	return clampf((u[5] + u[6] + u[7] + u[4]) / 4 - u[2] * .2 - (.2 if s.spouse[p] >= 0 else 0) - minf(.3, s.children(p).size() * .08), 0, 1)

func invite(p: int) -> bool:
	if open_places() == 0 or not eligible(p): return false
	var s: RefCounted = society_ref.get_ref()
	if willingness(p) < float(config.invite_threshold):
		s.note(p, "dao", "%s refused Heaven's invitation" % s.population.names[p])
		return false
	_depart(p, false)
	return true

func call_to_heaven() -> int:
	var s: RefCounted = society_ref.get_ref()
	var day: int = s.population.day
	if day - last_call < int(config.call_days): return 0
	last_call = day
	var count := 0
	for p in s.population.size():
		if eligible(p) and willingness(p) >= float(config.call_threshold):
			_depart(p, true)
			count += 1
	s.note(-1, "dao", "Heaven called; %d pilgrims set out to find the hidden terrace" % count)
	return count

func _depart(p: int, pilgrimage: bool) -> void:
	var s: RefCounted = society_ref.get_ref()
	var store: RefCounted = s.population
	if not fate.has(p): fate[p] = store.rng.randf()
	var site: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/" + str(config.site)))
	var destination := Vector2(float(site.center[0]), float(site.center[1]))
	var duration: int = store.rng.randi_range(int(config.search_days[0]), int(config.search_days[1])) if pilgrimage else maxi(1, ceili(store.locations[p].distance_to(destination) / float(config.travel_tiles_per_day)))
	journeys[p] = {"due": store.day + duration, "pilgrimage": pilgrimage, "settlement": store.settlement[p], "home": store.household[p], "job": store.job[p], "location": store.locations[p]}
	store.settlement[p] = -int(config.settlement)
	if pilgrimage: pilgrims += 1
	s.note(p, "dao", "%s left a note at home and set out for heaven" % store.names[p])
	if s.mind:
		for kin: int in s.children(p): s.mind.feel(kin, s.mind.GRIEF, .25)
		for kin: int in s.parents(p):
			if kin >= 0 and s.alive[kin]: s.mind.feel(kin, s.mind.GRIEF, .25)
		if s.spouse[p] >= 0: s.mind.feel(s.spouse[p], s.mind.GRIEF, .25)

func _process_journeys(day: int) -> void:
	var s: RefCounted = society_ref.get_ref()
	var store: RefCounted = s.population
	var passed: Array[Dictionary] = []
	var finished: Array[int] = []
	for p: int in journeys:
		var j: Dictionary = journeys[p]
		if int(j.due) > day: continue
		finished.append(p)
		if not s.alive[p]: continue
		if j.pilgrimage and store.rng.randf() < float(config.road_death):
			s.die(p, "dao", "%s died on the pilgrimage to heaven" % store.names[p])
			continue
		var chance: float = float(config.find_rate) * float(fate[p]) * (store.attributes[p * 8 + 4] + store.attributes[p * 8 + 6]) / 20 * store.luck[p]
		if j.pilgrimage and store.rng.randf() >= chance:
			_home(p, "turned back without finding heaven")
			continue
		if j.pilgrimage: arrivals += 1
		var record: Dictionary = admission.test(s, p, config.admission)
		if record.passed: passed.append({"person": p, "score": record.total})
		else: _home(p, "returned with the story of Heaven's admission trials")
	passed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	for result: Dictionary in passed:
		var p: int = result.person
		if open_places() > 0:
			join(p)
			s.note(p, "dao", "%s passed the trials and joined the Fifty" % store.names[p])
		else: _home(p, "returned honoured: heaven saw them, but every place was full")
	for p: int in finished: journeys.erase(p)

func _home(p: int, story: String) -> void:
	var s: RefCounted = society_ref.get_ref()
	var j: Dictionary = journeys[p]
	s.population.settlement[p] = j.settlement
	s.population.household[p] = j.home
	s.population.job[p] = j.job
	s.population.set_location(p, j.location)
	s.note(p, "dao", "%s %s" % [s.population.names[p], story])

func repair(saved: Dictionary) -> void:
	if not saved.is_empty(): return
	# Old saves have no terrace people. Seed only after population columns have been repaired.
	people.clear()
	journeys.clear()
	fate.clear()
	admission.records.clear()
	ranking.clear()
	bouts.clear()
	tournaments = 0
	deaths = 0
	stone = 0
	will = 0
	last_call = society_ref.get_ref().population.day - int(config.call_days)
	last_day = -1
	first_apostle_day = -1
	first_envoy_day = -1
	pilgrims = 0
	arrivals = 0
	seats.fill(-1)
	seeded = false
	self.seed()

func summary() -> Dictionary:
	var s: RefCounted = society_ref.get_ref()
	var layers: Array[int] = []
	layers.resize(10)
	layers.fill(0)
	var candidate_layers: Array[int] = []
	candidate_layers.resize(10)
	candidate_layers.fill(0)
	var restoring := 0
	var alive := 0
	var apostles := 0
	var envoys := 0
	var candidates := 0
	for p: int in people:
		if people[p].status in ["apostle", "restoring"]: apostles += 1
		if people[p].status == "restoring": restoring += 1
		if not s.alive[p]: continue
		alive += 1
		if people[p].status == "envoy": envoys += 1
		if people[p].status == "candidate":
			candidates += 1
			candidate_layers[s.temper.body_layer[p]] += 1
		layers[s.temper.body_layer[p]] += 1
	return {"alive": alive, "layers": layers, "candidate_layers": candidate_layers, "restoring": restoring, "candidates": candidates, "tournaments": tournaments, "apostles": apostles, "envoys": envoys, "deaths": deaths, "first_apostle_year": first_apostle_day / 365.0 if first_apostle_day >= 0 else -1, "first_envoy_year": first_envoy_day / 365.0 if first_envoy_day >= 0 else -1}
