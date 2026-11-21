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
const BLADES := ["weapons.straight_sword", "weapons.blade"]
const Store = preload("res://src/meridian_store.gd")
const Practice = preload("res://src/qi_practice.gd")
const Anatomy = preload("res://src/meridians.gd")
# Channels that carry qi to the right hand and the right foot (shoulder then limb).
const PALM_ROUTE := [12, 13]
const SOLE_ROUTE := [18, 19]

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


## A person as a fighter: body, tempering, martial skill, age and injuries. Qi adds nothing by itself: the
## "qi" block says what their certified layers and channels let them pay for during the fight.
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
	var might := body
	var skill := martial_level(store, p)
	var power := float(rules.power) * (0.5 + strength / 20.0) * might * (1.0 + skill / float(rules.skill_power))
	var guard := float(rules.guard) * (0.5 + endurance / 20.0) * might * (1.0 + skill / float(rules.skill_guard))
	var speed := float(rules.speed) * (0.6 + agility / 25.0) * (1.0 + layers * float(rules.speed_per_layer))
	var breath := float(rules.breath) * (0.5 + endurance / 20.0) * (1.0 + layers * float(rules.breath_per_layer))
	if store.age(p) < int(rules.child_age):
		power *= float(rules.child_factor)
		guard *= float(rules.child_factor)
	if society.injury_until[p] > store.day:
		power *= float(rules.injured_power)
		guard *= float(rules.injured_guard)
	var will: int = int(rules.will) if store.attributes[p * 8 + 6] >= 8.0 else int(rules.fearful_will)
	return {"name": store.names[p], "person": p, "power": power, "guard": guard, "speed": speed, "breath": breath,
		"will": will, "motive": "own", "lethal": false, "verb": "strikes", "qi": qi_profile(society, p)}


## What a cultivator can pay for in a fight: certified layer, reserve, purity, control and the channel widths
## that limit how fast qi reaches the hand and foot. Empty for anyone without an opened dantian.
static func qi_profile(society: RefCounted, p: int) -> Dictionary:
	var ms: RefCounted = society.meridian_store
	if p >= ms.slot.size() or ms.slot[p] < 0: return {}
	var row: int = ms.slot[p]
	var layer: int = ms.integers[row * Store.PERSON_INTS + Store.PersonInt.LAYER]
	if layer < 1: return {}
	var state: RefCounted = society.qi_practice.body(society, p)
	var reserve: int = state.reserve
	var rules: Dictionary = config.qi
	var grade: float = maxf(0.0, society.temper.body_grade(p)) / 3.0 if society.temper else 0.0
	var route := func(edges: Array) -> float:
		var cap := INF
		for e: int in edges: cap = minf(cap, ms.capacity(row, e))
		return cap
	var store: RefCounted = society.population
	return {"layer": layer, "reserve": reserve / 1000.0,
		"purity": state.reserve_moments[0] / maxi(1, reserve), "stability": clampf(state.reserve_moments[2] / maxi(1, reserve), 0, 1),
		"error": Practice.control_error(state),
		"tolerance": lerpf(float(rules.tolerance_ordinary), float(rules.tolerance_perfect), clampf(grade, 0, 1)),
		"palm": route.call(PALM_ROUTE), "sole": route.call(SOLE_ROUTE),
		"coherence": 1.0 + 4.0 * clampf(float(Anatomy.definition().operation_mastery), 0, 1),
		"blade": BLADES.any(func(id: String) -> bool: return skill_level(store, p, id) > 0)}


## A person's level in one skill, 0 if untouched.
static func skill_level(store: RefCounted, p: int, id: String) -> int:
	var e: int = store.head[p]
	while e >= 0:
		if store.catalogue.ids[store.skill_id[e]] == id: return store.skill_level[e]
		e = store.skill_next[e]
	return 0


## Pay a fight's qi from a cultivator's reserve: it leaves the body as dissipated qi, so the ledger still closes.
static func spend_qi(society: RefCounted, p: int, qu: float) -> void:
	if p < 0 or qu <= 0.0: return
	var ms: RefCounted = society.meridian_store
	if p >= ms.slot.size() or ms.slot[p] < 0: return
	var state: RefCounted = society.qi_practice.body(society, p)
	var quanta: int = mini(state.reserve, roundi(qu * 1000.0))
	if quanta <= 0: return
	for q in 4: state.reserve_moments[q] -= state.reserve_moments[q] * quanta / state.reserve
	state.reserve -= quanta
	state.nodes[4].stored_quanta = state.reserve
	state.nodes[4].hazard_valid = false
	state.dissipated += quanta
	state.session_revision += 1
	ms.writeback(ms.slot[p], state)


## Settle both sides' qi after Combat.fight.
static func settle_qi(society: RefCounted, ids: Array, r: Dictionary) -> void:
	for i in 2: spend_qi(society, int(ids[i]), float(r.qi_spent[i]))


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
## stop_at (2 = hurt, 3 = badly hurt; always non-lethal), ground ("open" or "forest"). Returns {events, how, winner, loser, time, harm}; how is death, escape,
## yield, spar or apart.
static func fight(a: Dictionary, b: Dictionary, opt: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var f: Array[Dictionary] = []
	var starting: Array = opt.get("start_harm", [0.0, 0.0])
	for side: Dictionary in [worn(a, float(starting[0])), worn(b, float(starting[1]))]:
		f.append({"s": side, "h": 0.0, "next": 0.0, "last": -1.0, "lungs": float(side.breath) * float(config.breath_seconds),
			"winded": false, "retry": 0.0, "allin": false, "will": will_for(int(side.will), str(side.motive)),
			"q": side.get("qi", {}), "reserve": float(side.get("qi", {}).get("reserve", 0.0)), "spent": 0.0, "shell": 0.0,
			"paid_to": 0.0, "upkeep": float(side.get("qi", {}).get("reserve", 0.0)) > 0.0, "second": false, "burst": false, "recast": false})
	for i in 2: f[i].h = clampf(float(starting[i]), 0.0, 100.0)
	var stop_at: int = clampi(int(opt.get("stop_at", 2 if opt.get("spar", false) else 0)), 0, 3)
	var spar: bool = stop_at > 0
	var forest: bool = opt.get("ground", "open") == "forest"
	var events: Array[Dictionary] = []
	var result := {}
	var seconds := float(config.strike_seconds)
	var qr: Dictionary = config.qi

	# Qi is paid from a fight-local reserve; Combat.settle_qi debits the real one afterwards.
	var layer := func(i: int) -> int: return int(f[i].q.get("layer", 0))
	var pay := func(i: int, qu: float) -> float:
		var paid := minf(qu, f[i].reserve)
		f[i].reserve -= paid
		f[i].spent += paid
		return paid
	var useful := func(i: int, qu: float) -> float:
		var q: Dictionary = f[i].q
		return qu * pow(float(q.purity), 2) * float(q.stability) * (1.0 - float(q.error))
	# A hand can only take what its channel carries during the wind-up and what its buffer holds.
	var reinforce := func(i: int, base: float, buffer: float) -> float:
		if layer.call(i) < 1 or f[i].reserve <= 0.0: return 0.0
		var qu: float = pay.call(i, minf(float(f[i].q.palm) * float(qr.windup_seconds), buffer))
		return minf(float(qr.harm_per_qu) * useful.call(i, qu), base * float(f[i].q.tolerance))
	# Armour (layer 5) and qi-step (layer 4) run on upkeep; the shell leaks. Paid up to time t.
	var upkeep := func(i: int, t: float) -> void:
		var dt: float = t - f[i].paid_to
		if dt <= 0.0: return
		f[i].paid_to = t
		f[i].shell *= exp(-float(qr.shell_leak_per_second) * dt)
		if not f[i].upkeep: return
		var rate := (float(qr.armour_qu_per_second) if layer.call(i) >= 5 else 0.0) + (float(qr.step_qu_per_second) if layer.call(i) >= 4 else 0.0)
		if rate > 0.0 and pay.call(i, rate * dt) < rate * dt - 1e-9:
			f[i].upkeep = false
			events.append({"t": "dry", "time": t, "i": i, "harm": [f[0].h, f[1].h]})
	var stepping := func(i: int) -> bool: return layer.call(i) >= 4 and f[i].upkeep
	var raise_shell := func(i: int, t: float) -> void:
		if layer.call(i) < 7 or f[i].reserve < float(qr.shell_min_reserve_qu): return
		f[i].shell = pay.call(i, float(qr.shell_max_qu) + float(qr.shell_raise_qu)) - float(qr.shell_raise_qu)
		events.append({"t": "shell", "time": t, "i": i, "charge": f[i].shell, "harm": [f[0].h, f[1].h]})

	var out := func(i: int, t: float) -> bool: return t >= f[i].lungs
	var people := func(i: int) -> bool: return int(f[i].s.person) >= 0
	var power := func(i: int, t: float) -> float:
		var p: float = float(f[i].s.power) * (0.6 if out.call(i, t) else 1.0)
		if f[i].s.motive == "young": p *= 1.1
		if f[i].allin: p *= 1.35
		return p
	var guard := func(i: int) -> float:
		var g: float = float(f[i].s.guard) * (0.7 if f[i].allin else 1.0)
		if layer.call(i) >= 5 and f[i].upkeep:
			g += minf(float(qr.armour_score), float(f[i].s.guard) * float(f[i].q.tolerance) * float(qr.armour_share))
		return g * (1.15 if forest else 1.0)
	var speed := func(i: int, t: float) -> float:
		return float(f[i].s.speed) * (0.7 if out.call(i, t) else 1.0) * (float(qr.step_speed) if stepping.call(i) else 1.0)
	# Undergrowth slows people running, not striking.
	var running := func(i: int, t: float) -> float: return speed.call(i, t) * (0.75 if forest and people.call(i) else 1.0)
	var gap := func(i: int, t: float) -> float: return seconds / speed.call(i, t) * rng.randf_range(0.85, 1.15)
	var finish := func(t: float, how: String, winner: int, loser: int) -> void:
		result.merge({"how": how, "winner": winner, "loser": loser, "time": t}, true)
		events.append({"t": "end", "time": t, "how": how, "winner": winner, "loser": loser, "harm": [f[0].h, f[1].h]})

	var strike := func(i: int, t: float, mult: float, why: String) -> void:
		var you: Dictionary = f[1 - i]
		for k in 2: upkeep.call(k, t)
		# Second wind (layer 2): qi buys back the breath once.
		if out.call(i, t) and layer.call(i) >= 2 and not f[i].second and pay.call(i, float(qr.second_wind_qu)) >= float(qr.second_wind_qu):
			f[i].second = true
			f[i].lungs = t + float(f[i].s.breath) * float(config.breath_seconds)
			events.append({"t": "second wind", "time": t, "i": i, "harm": [f[0].h, f[1].h]})
		# Before layer 7 qi goes to one place at a time: the one losing guards, the other strikes.
		var guarding := func(k: int) -> bool: return layer.call(k) >= 7 or f[k].h > f[1 - k].h + 10.0
		var p: float = power.call(i, t) * mult
		var qi_hit := 0.0
		if layer.call(i) >= 7 or not guarding.call(i):
			var buffer := float(qr.hand_buffer_qu)
			# All-in (layer 3): once a fight, when hurt, the hand buffer is drawn to its limit.
			if layer.call(i) >= 3 and not f[i].burst and f[i].h >= HARM_AT[2]:
				f[i].burst = true
				buffer = float(qr.allin_buffer_qu)
			qi_hit = reinforce.call(i, p, buffer)
		p += qi_hit
		var g: float = guard.call(1 - i)
		if guarding.call(1 - i): g += reinforce.call(1 - i, g, float(qr.hand_buffer_qu))
		var chance := p / (p + g)
		var hit := rng.randf() < chance
		var dmg := 0.0
		var stagger := false
		if hit:
			dmg = float(config.harm_per_blow) * pow(p / g, 0.8) * rng.randf_range(0.75, 1.25)
			if you.shell > 0.0:
				var held := minf(dmg, you.shell / float(qr.shell_qu_per_harm))
				you.shell -= held * float(qr.shell_qu_per_harm)
				dmg -= held
				if you.shell < 0.01:
					you.shell = 0.0
					events.append({"t": "shell broken", "time": t, "i": 1 - i, "harm": [f[0].h, f[1].h]})
					# Layer 8 can project a new one mid-fight, once.
					if layer.call(1 - i) >= 8 and not you.recast and not spar:
						you.recast = true
						raise_shell.call(1 - i, t)
			var cap: float = HARM_AT[stop_at] if spar else (100.0 if f[i].s.lethal else float(config.brawl_cap))
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
		events.append({"t": "strike", "time": t, "i": i, "hit": hit, "dmg": dmg, "chance": chance, "why": why, "qi": qi_hit,
			"stagger": stagger, "trade": trade, "winded": winded, "allin": allin, "harm": [f[0].h, f[1].h]})

	var over := func(i: int, t: float) -> bool:
		if spar and f[1 - i].h >= HARM_AT[stop_at]:
			finish.call(t, "spar", i, 1 - i)
			return true
		if f[1 - i].h >= 100.0:
			finish.call(t, "spar" if spar else "death", i, 1 - i)
			return true
		return false

	for i in 2:
		if over.call(i, 0.0): return _done(events, result, f)

	# Closing in takes a moment; whoever strikes from hiding lands first and the other reels.
	for i in 2: f[i].next = 0.8 + rng.randf() * gap.call(i, 0.0) * 0.5
	# Layer 7 holds a shell cast before the fight; nobody raises one for a friendly bout.
	if not spar:
		for i in 2: raise_shell.call(i, 0.0)
	var ambush: int = opt.get("ambush", -1)
	if ambush >= 0:
		var hidden := float(opt.get("ambush_power", 1.5))
		# Qi sense (layer 1) feels the hidden presence before the blow lands.
		if layer.call(1 - ambush) >= 1: hidden = 1.0 + (hidden - 1.0) * float(qr.sense_ambush)
		strike.call(ambush, 0.0, hidden, "from hiding")
		f[1 - ambush].next += 1.2
		if over.call(ambush, 0.0): return _done(events, result, f)
	# Projection (layer 8): sword qi or palm wind crosses the opening gap before the closing blow.
	if not spar:
		for i in 2:
			if layer.call(i) < 8 or f[i].reserve <= 0.0: continue
			var packet: float = useful.call(i, pay.call(i, float(qr.projection_qu))) * exp(-float(qr.projection_tiles) / float(f[i].q.coherence))
			var base: float = power.call(i, 0.4)
			var mult := 1.0 + minf(float(qr.harm_per_qu) * packet, base) / base
			strike.call(i, 0.4, mult, "with sword qi" if f[i].q.blade else "with palm wind")
			if over.call(i, 0.4): return _done(events, result, f)
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
		# Sword pulse (layer 8, a blade): the tethered sword follows a runner within its reach.
		if layer.call(i) >= 8 and f[i].q.blade and pay.call(i, float(qr.pulse_qu_per_second) * 2.0) > 0.0: chance *= float(qr.pulse_escape)
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
	result.qi_spent = [f[0].spent, f[1].spent]
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
	settle_qi(society, ids, r)
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
static func hunt(society: RefCounted, p: int, kind: String, persistent_profile: Dictionary = {}, harm: float = 0.0, awakened: bool = false) -> Dictionary:
	var store: RefCounted = society.population
	var hunter := person(society, p)
	hunter.power *= float(config.person.hunter_weapon)
	hunter.verb = "thrusts the spear"
	hunter.motive = "fear" if kind == "black bear" else ("hunger" if store.hunger[p] > 0 else "own")
	hunter.lethal = true
	# A hunter backs off once hurt; nobody is paid to die for marrow.
	hunter.will = mini(int(hunter.will), int(config.hunter_will))
	var prey := beast(kind) if persistent_profile.is_empty() else persistent_profile
	var ambush := 0 if store.rng.randf() < float(config.hunt_ambush) + martial_level(store, p) / 50.0 else -1
	var r := fight(hunter, prey, {"ground": "forest", "ambush": ambush, "ambush_power": config.hunt_ambush_power, "start_harm":[0.0,harm]}, store.rng)
	# Badly wounded prey leaves a blood trail; the hunter follows it to the kill.
	if not awakened and r.how == "escape" and r.loser == 1 and r.harm[1] >= float(config.tracked_harm):
		r.how = "death"
		r.tracked = true
	r.merge({"kind": "hunt", "day": store.day, "ids": [p, -1], "names": [hunter.name, prey.name], "motives": [hunter.motive, "own"]})
	spend_qi(society, p, float(r.qi_spent[0]))
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

## Existing cracks reduce a stone fighter's strength; fresh fighters keep their catalogue values.
static func worn(stats: Dictionary, harm: float) -> Dictionary:
	var result := stats.duplicate()
	if harm > 0:
		for key: String in ["power", "guard", "speed", "breath"]:
			result[key] = float(stats[key]) * (1.0 - clampf(harm, 0, 100) * .003)
	return result
