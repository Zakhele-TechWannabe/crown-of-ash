extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var j := p.register_job("farmer", ["fields"])
	for i in 10:
		p.add_person("Wang %d" % i, 30, j)
		p.touch(i, "grain_farming.farming", 16, 5000)
	var s: RefCounted = p.society
	s.seed()
	assert(not s.faction_keys.has("sect:0"))
	for i in range(1, 6): s.father[i] = 0
	for i in range(6, 10): s.father[i] = 1
	for i in 6:
		p.spirit_root[i] = 1
		s.revealed[i] = 1
		s.realm[i] = 2
		s.layer[i] = 9 if i < 4 else 4
		s.technique[i] = 1
		if i > 0: s.ties.tie(0, i, 40)
	s.realm[0] = 3
	s.layer[0] = 1
	s.technique[0] = 2
	s.site[0] = 1
	for i in [1, 2, 3]:
		assert(s.accept(0, i))
	s.ties.tie(1, 4, 40)
	s.ties.tie(2, 5, 40)
	assert(s.accept(1, 4) and s.accept(2, 5))
	assert(not s.accept(0, 6), "Foundation master's personal slots are full")
	s.stores_years = .9
	s.refresh_factions()
	assert(s.faction_keys.has("hall:0") and not s.faction_keys.has("sect:0"))
	s.stores_years = 1
	s.refresh_factions()
	assert(s.faction_keys.has("sect:0") and s.faction_keys.has("clan:0"))
	assert(s.positions[3].exists and s.positions[3].holder == 0)
	assert(not s.positions[4].exists, "An elder post needs twelve sect members")
	assert(s.technique[1] == 2, "A master transmits their technique")
	print("PASS emergence: 3-generation clan, slots, technique transmission, hall and all five sect gates")
	quit()
