extends SceneTree
## Combat: real-time fights run blow by blow; the faster land more; motives move the breaking point; spars stop at
## hurt; anger without revenge never kills; hunts are fights; a killing leaves the family a grudge that becomes revenge.
const Population = preload("res://src/population.gd")
const Combat = preload("res://src/combat.gd")


func row(name: String, power: float, guard: float, speed: float, breath: float, will: int, lethal: bool = false) -> Dictionary:
	return {"name": name, "person": -1, "power": power, "guard": guard, "speed": speed, "breath": breath, "will": will,
		"motive": "own", "lethal": lethal, "verb": "strikes"}


func tally(a: Dictionary, b: Dictionary, opt: Dictionary, runs: int = 1000) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var out := {"a": 0, "b": 0, "death": 0, "escape": 0, "yield": 0, "spar": 0, "apart": 0, "blows_a": 0, "blows_b": 0, "flee_a": 0}
	for n in runs:
		var r := Combat.fight(a, b, opt, rng)
		if r.winner == 0: out.a += 1
		elif r.winner == 1: out.b += 1
		out[r.how] += 1
		for e: Dictionary in r.events:
			if e.t == "strike": out["blows_a" if e.i == 0 else "blows_b"] += 1
			if e.t == "flee" and e.i == 0: out.flee_a += 1
	return out


func _init() -> void:
	var villager := row("villager", 10, 10, 5, 8, 2)
	var wolf := row("wolf", 14, 12, 8, 12, 2, true)
	var tiger := row("tiger", 80, 45, 9, 4, 3, true)
	var stone := row("stone swordsman", 66, 70, 9, 30, Combat.NEVER, true)

	# The faster one lands more: a wolf strikes about 1.6 times as often as a villager.
	var t := tally(villager, wolf, {})
	assert(t.blows_b > t.blows_a * 1.3, "Wolf should out-strike a villager: %s" % t)
	# An ambushing tiger nearly always wins; stone never yields and never loses to a villager.
	t = tally(villager, tiger, {"ambush": 1})
	assert(t.b > 950, "Tiger from hiding: %s" % t)
	t = tally(villager, stone, {})
	assert(t.a == 0, "Stone never loses to a villager: %s" % t)
	# A spar always ends at hurt, never in death.
	t = tally(villager, villager.duplicate(), {"spar": true})
	assert(t.spar == 1000 and t.death == 0, "Spars end at hurt: %s" % t)
	# Anger without revenge never kills: non-lethal blows stop short of dying.
	t = tally(villager, villager.duplicate(), {})
	assert(t.death == 0, "Brawls without intent to kill: %s" % t)
	# Revenge: never runs, goes all in once badly hurt, and dies far more often.
	var avenger := villager.duplicate()
	avenger.motive = "revenge"
	avenger.lethal = true
	t = tally(avenger, wolf, {})
	assert(t.flee_a == 0, "An avenger never runs: %s" % t)
	var plain := tally(villager, wolf, {})
	assert(t.death > plain.death * 2, "Revenge fights to the death: %s vs %s" % [t, plain])
	assert(Combat.will_for(2, "fear") == 1 and Combat.will_for(2, "hunger") == 3 and Combat.will_for(3, "hunger") == 3)
	assert(Combat.will_for(3, "pride") == 3 and Combat.will_for(2, "young") == Combat.NEVER)

	# Cost: blow by blow, not frame by frame.
	var rng := RandomNumberGenerator.new()
	var started := Time.get_ticks_usec()
	var blows := 0
	for n in 5000: blows += Combat.fight(villager, wolf, {}, rng).events.size()
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	print("5000 fights in %.0f ms (%.1f events each)" % [ms, blows / 5000.0])
	assert(ms < 4000.0, "Fights must stay cheap")

	# People as fighters: body, tempering and age.
	var p: RefCounted = Population.new()
	var j: int = p.register_job("hunter", ["chores"])
	for i in 8: p.add_person("Person %d" % i, 25, j, i)
	var kid: int = p.add_person("Small Child", 8, j, 9)
	var s: RefCounted = p.society
	s.seed()
	var plain_body := Combat.person(s, 0)
	s.temper.body_layer[1] = 4
	for l in 4: s.temper.grades[1 * 9 + l] = 1
	var iron := Combat.person(s, 1)
	assert(iron.power > plain_body.power * 2.5 and iron.guard > plain_body.guard * 2.5, "Iron Bone hits far harder: %s vs %s" % [iron, plain_body])
	assert(Combat.person(s, kid).power < plain_body.power, "A child is weaker")
	p.touch(2, "game_and_hunting.hunting", 15)
	assert(Combat.martial_level(p, 2) == 15 and Combat.person(s, 2).power > plain_body.power * 1.8, "Skill counts")

	# A spar between villagers: recorded, a story, injuries only up to hurt, nobody dies.
	for n in 40: Combat.between(s, 3, 4, "spar")
	assert(s.alive[3] and s.alive[4] and s.fights.size() == 40 and s.fights[-1].kind == "spar")
	assert(s.chronicle.any(func(c: Dictionary) -> bool: return c.kind == "fight" and "sparred" in c.text))

	# A killing: the family grieves and inherits a grudge, and their next fight with the killer is revenge.
	var child: int = p.add_child("Person Child", 5, 6)
	p.day += 18 * 365
	s.die(5, "killed", "Person 5 was killed by Person 7", 7)
	assert(not s.alive[5])
	var e: int = s.ties.find(child, 7)
	assert(e >= 0 and s.ties.has_grudge(e) and s.ties.grudge_record(e).cause == "killed_kin", "Kin inherit the grudge")
	assert(Combat.motive(s, child, 7) == "revenge" and Combat.motive(s, 7, child) != "revenge")

	# Hunts are fights: kills happen, some hunters are hurt, deaths are rare.
	var hunts := {"kill": 0, "hurt": 0, "dead": 0}
	var hunter: int = p.add_person("Old Hunter", 30, j, 12)
	p.touch(hunter, "game_and_hunting.hunting", 12)
	for n in 2000:
		s.alive[hunter] = 1
		s.injury_until[hunter] = 0
		var r := Combat.hunt(s, hunter, "sika deer" if n % 5 < 3 else "wild boar")
		if r.kill: hunts.kill += 1
		if r.hurt: hunts.hurt += 1
		if r.dead: hunts.dead += 1
	print("2000 beast fights: %s" % hunts)
	assert(hunts.kill > 400 and hunts.dead < 60, "Hunting stays survivable: %s" % hunts)
	print("PASS combat: real-time blows, motives, spars, no killing in anger, hunts, revenge")
	quit()
