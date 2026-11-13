extends RefCounted
## Fights in real time, run blow by blow: each fighter strikes on its own clock (strike_seconds / speed), so the
## faster one lands more, and blows can cross. Harm builds from 0 to 100 through bruised, hurt, badly hurt and
## dying; a heavy blow staggers; breath runs out and the winded strike slower and weaker. Why someone fights (their
## motive) sets when they give up. The sim jumps from blow to blow, so a fight costs a few steps per blow, never
## a step per frame. People and beasts use the same rules; see data/society/combat.json.
const WOUNDS := ["unhurt", "bruised", "hurt", "badly hurt", "dying"]
const HARM_AT := [0.0, 15.0, 35.0, 60.0, 100.0]
const NEVER := 9
const MARTIAL := ["weapons.", "unarmed_arts.", "game_and_hunting.", "archery."]

static var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/combat.json"))


static func wound(harm: float) -> int:
	for w in range(4, 0, -1):
		if harm >= HARM_AT[w]: return w
	return 0


## The wound at which a fighter gives up, moved by why they fight. NEVER: they fight on until they fall.
static func will_for(base: int, motive: String) -> int:
	match motive:
		"fear": return maxi(1, base - 1)
		"hunger": return maxi(base, mini(3, base + 1))
		"young", "revenge": return NEVER
	return base


## A person as a fighter: body, tempering, qi, martial skill, age and injuries.
static func person(society: RefCounted, p: int) -> Dictionary:
	var store: RefCounted = society.population
	var rules: Dictionary = config.person
	var strength: float = store.attributes[p * 8]
	var endurance: float = store.attributes[p * 8 + 1]
	var agility: float = store.attributes[p * 8 + 2]
	var temper: RefCounted = society.temper
	var layers: int = temper.body_layer[p] if temper else 0
	var grade: float = maxf(0.0, temper.body_grade(p)) if temper else 0.0
	var body := 1.0 + layers * float(rules.tempering_per_layer) * (0.8 + 0.1 * grade)
	var realm: int = mini(2, society.realm[p])
	var qi: float = float(rules.qi_power[realm]) + (float(rules.qi_power_per_layer) * society.layer[p] if realm == 1 else 0.0)
	var might := maxf(body, qi) + 0.2 * minf(body, qi)
	var skill := martial_level(store, p)
	var power := float(rules.power) * (0.5 + strength / 20.0) * might * (1.0 + skill / float(rules.skill_power))
	var guard := float(rules.guard) * (0.5 + endurance / 20.0) * might * (1.0 + skill / float(rules.skill_guard))
	var speed := float(rules.speed) * (0.6 + agility / 25.0) * (1.0 + layers * float(rules.speed_per_layer))
	speed += float(rules.qi_speed[realm]) + (float(rules.qi_speed_per_layer) * society.layer[p] if realm == 1 else 0.0)
	var breath := float(rules.breath) * (0.5 + endurance / 20.0) * (1.0 + layers * float(rules.breath_per_layer)) * (1.0 + realm)
	if store.age(p) < int(rules.child_age):
		power *= float(rules.child_factor)
		guard *= float(rules.child_factor)
	if society.injury_until[p] > store.day:
		power *= float(rules.injured_power)
		guard *= float(rules.injured_guard)
	var will: int = int(rules.will) if store.attributes[p * 8 + 6] >= 8.0 else int(rules.fearful_will)
	return {"name": store.names[p], "person": p, "power": power, "guard": guard, "speed": speed, "breath": breath,
		"will": will, "motive": "own", "lethal": false, "verb": "strikes"}


## A beast from the table, by name.
static func beast(kind: String) -> Dictionary:
	var row: Dictionary = config.beasts[kind]
	return {"name": "a " + kind, "person": -1, "beast": kind, "power": float(row.power), "guard": float(row.guard),
		"speed": float(row.speed), "breath": float(row.breath), "will": int(row.will), "motive": "own",
		"lethal": bool(row.lethal), "verb": str(row.verb)}


## Best level across the fighting and hunting skills.
static func martial_level(store: RefCounted, p: int) -> int:
	var best := 0
	var e: int = store.head[p]
	while e >= 0:
		var id: String = store.catalogue.ids[store.skill_id[e]]
		for prefix: String in MARTIAL:
			if id.begins_with(prefix):
				best = maxi(best, store.skill_level[e])
				break
		e = store.skill_next[e]
	return best


## Why p fights q: revenge for a killed relative, fear, pride, or simply their nature.
static func motive(society: RefCounted, p: int, q: int) -> String:
	var ties: RefCounted = society.ties
	var e: int = ties.find(p, q)
	if e >= 0 and ties.has_grudge(e) and ties.grudge_record(e).cause == "killed_kin": return "revenge"
	var mind: RefCounted = society.mind
	if mind:
		if mind.emotion[p * 4 + mind.AFRAID] > 0.6: return "fear"
		if mind.urges(p)[mind.PRIDE] > 0.7: return "pride"
	return "own"


## Run a fight between a and b. opt: spar (stops at hurt), ambush (0 or 1 strikes first from hiding, -1 none),
## ground ("open" or "forest"). Returns {events, how, winner, loser, time, harm}; how is death, escape,
## yield, spar or apart.
static func fight(a: Dictionary, b: Dictionary, opt: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var f: Array[Dictionary] = []
	for side: Dictionary in [a, b]:
		f.append({"s": side, "h": 0.0, "next": 0.0, "last": -1.0, "lungs": float(side.breath) * float(config.breath_seconds),
			"winded": false, "retry": 0.0, "allin": false, "will": will_for(int(side.will), str(side.motive))})
	var spar: bool = opt.get("spar", false)
	var forest: bool = opt.get("ground", "open") == "forest"
	var events: Array[Dictionary] = []
	var result := {}
	var seconds := float(config.strike_seconds)

	var out := func(i: int, t: float) -> bool: return t >= f[i].lungs
	var people := func(i: int) -> bool: return int(f[i].s.person) >= 0
	var power := func(i: int, t: float) -> float:
		var p: float = float(f[i].s.power) * (0.6 if out.call(i, t) else 1.0)
		if f[i].s.motive == "young": p *= 1.1
		if f[i].allin: p *= 1.35
		return p
	var guard := func(i: int) -> float:
		var g: float = float(f[i].s.guard) * (0.7 if f[i].allin else 1.0)
		return g * (1.15 if forest else 1.0)
	var speed := func(i: int, t: float) -> float: return float(f[i].s.speed) * (0.7 if out.call(i, t) else 1.0)
	# Undergrowth slows people running, not striking.
	var running := func(i: int, t: float) -> float: return speed.call(i, t) * (0.75 if forest and people.call(i) else 1.0)
	var gap := func(i: int, t: float) -> float: return seconds / speed.call(i, t) * rng.randf_range(0.85, 1.15)
	var finish := func(t: float, how: String, winner: int, loser: int) -> void:
		result.merge({"how": how, "winner": winner, "loser": loser, "time": t}, true)
		events.append({"t": "end", "time": t, "how": how, "winner": winner, "loser": loser, "harm": [f[0].h, f[1].h]})

	var strike := func(i: int, t: float, mult: float, why: String) -> void:
		var you: Dictionary = f[1 - i]
		var p: float = power.call(i, t) * mult
		var g: float = guard.call(1 - i)
		var chance := p / (p + g)
		var hit := rng.randf() < chance
		var dmg := 0.0
		var stagger := false
		if hit:
			dmg = float(config.harm_per_blow) * pow(p / g, 0.8) * rng.randf_range(0.75, 1.25)
			var cap := 100.0 if f[i].s.lethal or spar else float(config.brawl_cap)
			if you.h < cap: you.h = minf(cap, you.h + dmg)
			if dmg >= float(config.stagger_harm):
				stagger = true
				you.next = maxf(you.next, t) + 0.6
		var allin := false
		if you.s.motive == "revenge" and you.h >= HARM_AT[3] and not you.allin:
			you.allin = true
			allin = true
		var winded := false
		if out.call(i, t) and not f[i].winded:
			f[i].winded = true
			winded = true
		var trade: bool = you.last >= 0.0 and absf(t - you.last) < 0.3
		f[i].last = t
		f[i].next = t + gap.call(i, t)
		events.append({"t": "strike", "time": t, "i": i, "hit": hit, "dmg": dmg, "chance": chance, "why": why,
			"stagger": stagger, "trade": trade, "winded": winded, "allin": allin, "harm": [f[0].h, f[1].h]})

	var over := func(i: int, t: float) -> bool:
		if spar and f[1 - i].h >= HARM_AT[2]:
			finish.call(t, "spar", i, 1 - i)
			return true
		if f[1 - i].h >= 100.0:
			finish.call(t, "spar" if spar else "death", i, 1 - i)
			return true
		return false

	# Closing in takes a moment; whoever strikes from hiding lands first and the other reels.
	for i in 2: f[i].next = 0.8 + rng.randf() * gap.call(i, 0.0) * 0.5
	var ambush: int = opt.get("ambush", -1)
	if ambush >= 0:
		strike.call(ambush, 0.0, float(opt.get("ambush_power", 1.5)), "from hiding")
		f[1 - ambush].next += 1.2
		if over.call(ambush, 0.0): return _done(events, result, f)
	while true:
		var i := 0 if f[0].next <= f[1].next else 1
		var t: float = f[i].next
		if t > float(config.time_limit):
			finish.call(float(config.time_limit), "apart", -1, -1)
			break
		strike.call(i, t, 1.0, "")
		if over.call(i, t): break
		if spar: continue
		var j := 1 - i
		var them: Dictionary = f[j]
		if them.will >= NEVER or them.h < HARM_AT[mini(4, them.will)] or t < them.retry: continue
		var sp: float = running.call(j, t)
		var chance: float = sp / (sp + running.call(i, t))
		chance *= float(opt.get("escape_cover", 1.0))
		# People who can't outrun another person yield; so do the proud. Beasts and stone never do.
		if people.call(j) and people.call(i) and (chance < 0.4 or them.s.motive == "pride"):
			events.append({"t": "yield", "time": t + 0.2, "i": j, "chance": chance, "harm": [f[0].h, f[1].h]})
			finish.call(t + 0.4, "yield", i, j)
			break
		var ok: bool = rng.randf() < chance
		events.append({"t": "flee", "time": t + 0.2, "i": j, "chance": chance, "ok": ok, "harm": [f[0].h, f[1].h]})
		if ok:
			finish.call(t + 1.8, "escape", i, j)
			break
		f[i].next = t + 1.0
		strike.call(i, t + 1.0, 1.3, "at a back turned to run")
		if over.call(i, t + 1.0): break
		them.retry = t + 5.0
		them.next = maxf(them.next, t + 1.6)
	return _done(events, result, f)


static func _done(events: Array[Dictionary], result: Dictionary, f: Array[Dictionary]) -> Dictionary:
	result.events = events
	result.harm = [f[0].h, f[1].h]
	return result


## Two villagers come to blows. kind "spar": a duel that stops at hurt. kind "brawl": blows in anger, where nobody
## means to kill unless it is revenge. Wounds, grudges and the story follow; returns the fight's record.
static func between(society: RefCounted, a: int, b: int, kind: String) -> Dictionary:
	var store: RefCounted = society.population
	var sides := [person(society, a), person(society, b)]
	sides[0].motive = motive(society, a, b)
	sides[1].motive = motive(society, b, a)
	for side: Dictionary in sides: side.lethal = kind == "brawl" and side.motive == "revenge"
	var r := fight(sides[0], sides[1], {"spar": kind == "spar"}, store.rng)
	var ids := [a, b]
	r.merge({"kind": kind, "day": store.day, "ids": ids, "names": [sides[0].name, sides[1].name], "motives": [sides[0].motive, sides[1].motive]})
	var fates := [_hurt(society, a, r.harm[0], b, r), _hurt(society, b, r.harm[1], a, r)]
	r.fates = fates
	var ties: RefCounted = society.ties
	ties.event(a, b, "duel", store.day)
	ties.event(b, a, "duel", store.day)
	if kind == "brawl" and r.loser >= 0 and fates[r.loser] != "dead": ties.event(ids[r.loser], ids[r.winner], "beaten", store.day)
	var mind: RefCounted = society.mind
	if mind and r.winner >= 0:
		mind.feel(ids[r.winner], mind.JOY, 0.3)
		if fates[r.loser] != "dead": mind.feel(ids[r.loser], mind.ANGER if kind == "brawl" else mind.JOY, 0.3 if kind == "brawl" else 0.05)
	society.record_fight(r)
	if fates[0] != "dead" and fates[1] != "dead":
		society.note(a, "fight", story(r))
	return r


## A hunter meets a beast in the forest. The hunter strikes from cover when skilled enough; the beast may win.
static func hunt(society: RefCounted, p: int, kind: String) -> Dictionary:
	var store: RefCounted = society.population
	var hunter := person(society, p)
	hunter.power *= float(config.person.hunter_weapon)
	hunter.verb = "thrusts the spear"
	hunter.motive = "fear" if kind == "black bear" else ("hunger" if store.hunger[p] > 0 else "own")
	hunter.lethal = true
	# A hunter backs off once hurt; nobody is paid to die for marrow.
	hunter.will = mini(int(hunter.will), int(config.hunter_will))
	var prey := beast(kind)
	var ambush := 0 if store.rng.randf() < float(config.hunt_ambush) + martial_level(store, p) / 50.0 else -1
	var r := fight(hunter, prey, {"ground": "forest", "ambush": ambush, "ambush_power": config.hunt_ambush_power}, store.rng)
	# Badly wounded prey leaves a blood trail; the hunter follows it to the kill.
	if r.how == "escape" and r.loser == 1 and r.harm[1] >= float(config.tracked_harm):
		r.how = "death"
		r.tracked = true
	r.merge({"kind": "hunt", "day": store.day, "ids": [p, -1], "names": [hunter.name, prey.name], "motives": [hunter.motive, "own"]})
	var fate := _hurt(society, p, r.harm[0], -1, r)
	r.fates = [fate, "dead" if r.how == "death" and r.loser == 1 else ""]
	r.kill = r.fates[1] == "dead"
	r.hurt = wound(r.harm[0]) >= 2
	r.dead = fate == "dead"
	society.record_fight(r)
	return r


## Apply a fight's harm to a person: rest for the wound, perhaps a lasting injury, perhaps death.
## Returns "", "hurt", "crippled" or "dead".
static func _hurt(society: RefCounted, p: int, harm: float, by: int, r: Dictionary) -> String:
	var store: RefCounted = society.population
	var w := wound(harm)
	if w == 0: return ""
	if w == 4 and store.rng.randf() >= float(config.dying_survives):
		var killer: String = r.names[0] if r.ids[1] == p else r.names[1]
		society.die(p, "killed", "%s was killed by %s%s" % [store.names[p], killer, " while hunting" if r.kind == "hunt" else ""], by)
		return "dead"
	var days: Array = config.heal_days[mini(w, 3)]
	society.injury_until[p] = maxi(society.injury_until[p], store.day + store.rng.randi_range(int(days[0]), int(days[1])))
	if w >= 3 and store.rng.randf() < float(config.cripple_chance):
		# A lasting injury lowers a ceiling for life: a lame leg or a weak arm.
		var a := 2 if store.rng.randf() < 0.5 else 0
		store.potential[p * 8 + a] = maxi(1, store.potential[p * 8 + a] - 3)
		store.attributes[p * 8 + a] = minf(store.attributes[p * 8 + a], store.potential[p * 8 + a])
		society.note(p, "injury", "%s was left with %s for life" % [store.names[p], "a lame leg" if a == 2 else "a weak arm"])
		return "crippled"
	return "hurt" if w >= 2 else ""


## The fight in one line for the stories.
static func story(r: Dictionary) -> String:
	var n: Array = r.names
	var lead: String = {"spar": "%s and %s sparred" % [n[0], n[1]], "brawl": "%s and %s came to blows" % [n[0], n[1]],
		"hunt": "%s hunted %s" % [n[0], n[1]]}[r.kind]
	if r.how == "apart": return lead + "; neither could finish it"
	var winner: String = n[r.winner]
	var loser: String = n[r.loser]
	var hurt: String = WOUNDS[wound(r.harm[r.loser])]
	match r.how:
		"spar": return "%s; %s won and %s was %s" % [lead, winner, loser, hurt]
		"yield": return "%s; %s yielded to %s, %s" % [lead, loser, winner, hurt]
		"escape": return "%s; %s ran from %s, %s" % [lead, loser, winner, hurt]
		"death": return "%s; %s fell" % [lead, loser]
	return lead


## Running pace before breath runs out; forest undergrowth slows people.
static func running(fighter: Dictionary, forest: bool = false) -> float:
	return float(fighter.speed) * (0.75 if forest and int(fighter.person) >= 0 else 1.0)
