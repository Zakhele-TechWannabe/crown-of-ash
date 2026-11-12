extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var j := p.register_job("chores", ["chores"])
	p.add_person("Wang Root", 16, j)
	var s: RefCounted = p.society
	p.spirit_root[0] = 1
	p.root_purity[0] = 100
	p.comprehension[0] = 1
	assert(s.root_label(0) == "unknown" and s.qi_rate(0) == 0)
	assert(s.awaken(0, "test insight"))
	assert(not s.awaken(0, "duplicate"))
	assert(is_equal_approx(s.qi_rate(0), .72))
	s.site[0] = 2
	assert(is_equal_approx(s.qi_rate(0), 2.88))
	s.technique[0] = 1
	assert(is_equal_approx(s.qi_rate(0), 28.8))
	s.realm[0] = 2
	s.layer[0] = 9
	s.qi[0] = 100000
	s.cultivate(0, 7)
	assert(s.realm[0] == 2, "Incomplete Yellow technique cannot establish Foundation")
	assert(s.lifespan(0) == 120)
	s.technique[0] = 2
	for attempt in 100:
		if s.realm[0] >= 3: break
		p.day += 366
		s.qi[0] = 100000
		s.cultivate(0, 7)
	assert(s.realm[0] == 3, "A rare complete found manual must allow the first Foundation before technique creation exists")
	assert(s.awakenings == 1)
	print("PASS cultivation: hidden roots, unique awakening, qi formula, site density, technique cap, lifespan")
	quit()
