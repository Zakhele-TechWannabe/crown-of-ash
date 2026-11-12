extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var job := p.register_job("farmer", ["fields"])
	for i in 10:
		p.add_person("Wang %d" % i, 30, job, i)
		p.touch(i, "grain_farming.farming", 16)
	var s: RefCounted = p.society
	s.seed()
	var original: int = s.faction_keys["guild:grain_farming"]
	s.factions[original].cohesion = 20
	s.ties.opinion[s.ties.tie(1, 3)] = 60
	s.ties.opinion[s.ties.tie(2, 3)] = 60
	var split: int = s.schism(original, 3)
	assert(split >= 0)
	assert(3 not in s.factions[original].members)
	s.refresh_factions()
	assert(3 not in s.factions[original].members and 3 in s.factions[split].members)
	assert(split in s.memberships[3])
	s.factions[split].cohesion = 20
	assert(s.absorb(split, original))
	assert(not s.absorb(split, original), "An absorbed faction cannot repeatedly join")
	s.refresh_factions()
	assert(s.factions[split].members.is_empty())
	assert(3 in s.factions[original].members)
	var alliance: int = s.pact(0, original)
	assert(alliance >= 0 and s.factions[alliance].type == "alliance")
	print("PASS faction dynamics: persistent schism, absorption, membership index and treaty")
	quit()
