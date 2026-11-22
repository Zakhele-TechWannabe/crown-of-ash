extends SceneTree
## Weapons, reach, tempo, parries and feints (docs/combat.md, phase 2). A spear holds bare hands off and wins;
## the shorter side has to step inside; quick weapons strike more often than heavy ones; skill parries, ripostes
## and feints; a shield thickens the guard; a spear helps a hunter against a tiger; no weapon fights as before.
const Combat = preload("res://src/combat.gd")


func armed(name: String, weapon: String, skill: int, shield: bool = false, body: float = 53.2) -> Dictionary:
	var row: Dictionary = Combat.config.weapons[weapon]
	return {"name": name, "person": 0, "power": body, "guard": body, "speed": 8.2 if body > 20.0 else 5.0, "breath": 16.0, "will": 3,
		"motive": "own", "lethal": true, "verb": str(row.verb), "qi": {}, "footwork": 0,
		"weapon": {"id": weapon, "power": float(row.power), "reach": float(row.reach), "tempo": float(row.tempo),
			"parry": float(row.parry), "skill": skill, "verb": str(row.verb), "shield": shield}}


func tally(a: Dictionary, b: Dictionary, runs: int = 1000) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var out := {"a": 0, "b": 0, "blows_a": 0, "blows_b": 0, "time": 0.0}
	for n in runs:
		var r := Combat.fight(a, b, {}, rng)
		if r.winner == 0: out.a += 1
		elif r.winner == 1: out.b += 1
		out.time += float(r.get("time", 0.0))
		out.harm_b = float(out.get("harm_b", 0.0)) + float(r.harm[1]) / runs
		for e: Dictionary in r.events:
			if e.t == "strike":
				out["blows_a" if e.i == 0 else "blows_b"] += 1
				if e.parried: out.parried = out.get("parried", 0) + 1
				if e.why != "": out[e.why] = out.get(e.why, 0) + 1
			elif e.t in ["close", "held off", "steps back"]: out[e.t] = out.get(e.t, 0) + 1
	return out


func _init() -> void:
	var spear := tally(armed("spearman", "spear", 0), armed("brawler", "unarmed", 0))
	print("spear vs bare hands: %s" % spear)
	assert(spear.a > spear.b * 1.5, "A spear beats bare hands")
	assert(spear.get("held off", 0) > 0 and spear.get("close", 0) > 0, "Bare hands must step inside the spear")

	var quick := tally(armed("twin", "twin_weapons", 0), armed("hammer", "hammer", 0))
	print("twin weapons vs hammer: %s" % quick)
	assert(quick.blows_a > quick.blows_b * 1.4, "Quick weapons strike more often")

	var master := tally(armed("swordmaster", "straight_sword", 25), armed("novice", "straight_sword", 0))
	print("skilled jian vs unskilled jian: %s" % master)
	assert(master.get("parried", 0) > 0 and master.get("riposte", 0) > 0, "Skill parries and ripostes")
	assert(master.a > master.b, "The skilled sword wins more")
	var feint := tally(armed("feinter", "blade", 25), armed("wall", "blade", 0, true))
	print("skilled dao vs shield wall: %s" % feint)
	assert(feint.get("after a feint", 0) > 0, "A skilled fighter feints against a stronger guard")
	var shield := tally(armed("shield", "blade", 0, true), armed("open", "blade", 0))
	print("shield and dao vs dao: %s" % shield)
	assert(shield.a > shield.b, "A shield helps")

	var tiger := Combat.beast("tiger")
	# An untempered villager (power and guard 10, speed 5).
	var hunter := tally(armed("hunter", "spear", 5, false, 10.0), tiger)
	var bare := tally(armed("hunter", "unarmed", 5, false, 10.0), tiger)
	print("spear vs tiger: %s; bare hands vs tiger: %s" % [hunter, bare])
	assert(hunter.harm_b > bare.harm_b * 1.3, "A spear helps against a tiger")

	# A fighter dictionary without a weapon keeps the old engine: same draws, same fight.
	var plain := {"name": "plain", "person": -1, "power": 53.2, "guard": 53.2, "speed": 8.2, "breath": 16.0, "will": 3, "motive": "own", "lethal": true, "verb": "strikes"}
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 3
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 3
	var x := Combat.fight(plain, plain.duplicate(), {}, rng_a)
	var natural := plain.duplicate()
	natural.weapon = Combat.natural_weapon({})
	var y := Combat.fight(natural, natural.duplicate(), {}, rng_b)
	assert(x.harm == y.harm and x.events.size() == y.events.size(), "Natural weapons are the old fight")
	print("PASS weapons: reach, tempo, parry, riposte, feint, shield, hunting spear")
	quit()
