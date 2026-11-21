extends SceneTree
## Qi combat (docs/combat.md): qi is paid per action through real channels and capped by the tissue. An empty
## reserve fights as a mortal; a Perfect body beats a layer-1 novice; a layer-5 cultivator beats an equal mortal;
## shells absorb and break; projection opens at range; the spent qi leaves the reserve and the ledger still closes.
const Population = preload("res://src/population.gd")
const Combat = preload("res://src/combat.gd")
const Fixture = preload("res://tools/qi_cohort_fixture.gd")


func fighter(name: String, body: float, speed: float, qi: Dictionary = {}) -> Dictionary:
	return {"name": name, "person": -1, "power": body, "guard": body, "speed": speed, "breath": 16.0, "will": 3,
		"motive": "own", "lethal": true, "verb": "strikes", "qi": qi}


func qi(layer: int, palm: float, reserve: float = 1000.0) -> Dictionary:
	return {"layer": layer, "reserve": reserve, "purity": 1.0, "stability": 1.0, "error": 0.2, "tolerance": 0.5,
		"palm": palm, "sole": palm, "coherence": 3.0, "blade": false}


func tally(a: Dictionary, b: Dictionary, runs: int = 1000) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var out := {"a": 0, "b": 0, "spent": 0.0, "events": {}}
	for n in runs:
		var r := Combat.fight(a, b, {}, rng)
		if r.winner == 0: out.a += 1
		elif r.winner == 1: out.b += 1
		out.spent += float(r.qi_spent[0])
		for e: Dictionary in r.events:
			if e.t != "strike" or e.why != "": out.events[e.t if e.t != "strike" else e.why] = out.events.get(e.t if e.t != "strike" else e.why, 0) + 1
	return out


func _init() -> void:
	# Body Tempering 9 bodies, as Combat.person builds them: Perfect 69, ordinary 53.
	var perfect := fighter("Perfect martial artist", 69.4, 8.2)
	var ordinary := fighter("ordinary martial artist", 53.2, 8.2)

	# An empty reserve fights exactly as a mortal: the same draws give the same fight.
	var a := Combat.fight(fighter("dry", 53.2, 8.2, qi(5, 0.05, 0.0)), perfect, {}, _rng())
	var b := Combat.fight(ordinary, perfect, {}, _rng())
	assert(a.harm == b.harm and a.events.size() == b.events.size() and a.qi_spent[0] == 0.0, "Empty reserve = mortal")

	var novice := tally(fighter("layer-1 novice", 53.2, 8.2, qi(1, 0.02)), perfect)
	print("novice vs Perfect mortal: %s" % novice)
	assert(novice.b > novice.a * 1.5, "A Perfect body beats a layer-1 novice")
	assert(novice.spent > 0.0 and novice.spent / 1000.0 < 0.5, "Reinforcement is paid but small: under half a QU a fight")

	var five := tally(fighter("layer-5", 53.2, 8.2, qi(5, 0.05)), ordinary)
	print("layer 5 vs equal mortal: %s" % five)
	assert(five.a > five.b * 2, "Layer 5 beats an equal mortal")
	var five_vs_perfect := tally(fighter("layer-5", 53.2, 8.2, qi(5, 0.05)), perfect)
	print("layer 5 vs Perfect mortal: %s" % five_vs_perfect)

	var tiger := {"name": "tiger", "person": -1, "power": 80.0, "guard": 45.0, "speed": 9.0, "breath": 4.0, "will": 3,
		"motive": "own", "lethal": true, "verb": "claws"}
	var eight := tally(fighter("layer-8", 53.2, 8.2, qi(8, 0.05)), tiger)
	var mortal := tally(ordinary, tiger)
	print("layer 8 vs tiger: %s; mortal vs tiger: %s" % [eight, mortal])
	assert(eight.events.get("shell", 0) > 0 and eight.events.get("shell broken", 0) > 0, "Shells rise and break")
	assert(eight.events.get("with palm wind", 0) > 0, "Projection opens at range")
	assert(eight.a > mortal.a, "Qi helps against a tiger")

	# Spars raise no shells and throw no projections.
	var spar := Combat.fight(fighter("layer-8", 53.2, 8.2, qi(8, 0.05)), ordinary, {"spar": true}, _rng())
	assert(not spar.events.any(func(e: Dictionary) -> bool: return e.t == "shell" or str(e.get("why", "")).begins_with("with ")), "Spars stay friendly")

	# A real cultivator: qi_profile reads their body; a brawl's spent qi leaves the reserve as dissipated qi.
	var pop := Population.new()
	var ids := Fixture.long_prepare(pop)
	var s: RefCounted = pop.society
	var p: int = ids[0]
	var state: RefCounted = s.qi_practice.body(s, p)
	var gift := 200000
	state.absorbed += gift
	state.reserve += gift
	state.reserve_moments = [float(gift), 0.0, float(gift), 0.0]
	state.nodes[4].stored_quanta = state.reserve
	s.meridian_store.integers[s.meridian_store.slot[p] * Combat.Store.PERSON_INTS + Combat.Store.PersonInt.LAYER] = 5
	s.meridian_store.writeback(s.meridian_store.slot[p], state)
	var profile: Dictionary = Combat.person(s, p).qi
	print("real layer-5 profile: %s" % profile)
	assert(profile.layer == 5 and is_equal_approx(profile.reserve, 200.0) and profile.palm > 0.0 and profile.tolerance == 1.0)
	assert(Combat.person(s, ids[1]).qi.is_empty(), "No opened dantian, no qi")
	var before: int = state.reserve
	var spent := 0.0
	for n in 20:
		s.alive[p] = 1
		s.alive[ids[1]] = 1
		var r := Combat.between(s, p, ids[1], "brawl")
		spent += float(r.qi_spent[0])
	print("20 brawls spent %.3f QU; reserve %d -> %d; residual %d" % [spent, before, state.reserve, s.qi_practice._compiler.residual(state)])
	assert(spent > 0.0 and before - state.reserve == roundi(spent * 1000.0) or absi(before - state.reserve - roundi(spent * 1000.0)) <= 20)
	assert(s.qi_practice._compiler.residual(state) == 0, "The ledger closes")
	assert(s.meridian_report(p).reserve == state.reserve, "The store sees the debit")
	print("PASS qi combat: paid reinforcement, empty = mortal, walls of body and channel, shells, projection, ledger")
	quit()


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng
