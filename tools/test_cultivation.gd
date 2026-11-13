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
	# The rule: Qi Condensation waits for a Perfected Body, whatever the qi.
	var unready: int = p.add_person("Liu Unready", 16, j)
	p.spirit_root[unready] = 1
	p.root_purity[unready] = 100
	assert(s.awaken(unready, "test"))
	s.technique[unready] = 2
	s.temper.body_layer[unready] = 2
	for attempt in 200:
		s.injury_until[unready] = 0
		s.qi[unready] = 1000000.0
		s.cultivate(unready, 7)
	assert(s.realm[unready] < 2, "No Qi Condensation before the ninth layer of Body Tempering")
	s.temper.body_layer[unready] = 9
	for attempt in 200:
		s.injury_until[unready] = 0
		s.qi[unready] = 1000000.0
		s.cultivate(unready, 7)
		if s.realm[unready] >= 2: break
	assert(s.realm[unready] >= 2, "A Perfected Body may condense qi")
	# An older world's unready qi cultivator is set right on their next day.
	s.temper.body_layer[unready] = 3
	s.realm[unready] = 2
	s._tick_person(unready, 1, p.day, p.size())
	assert(s.realm[unready] == 1 and s.layer[unready] == 3, "Unready qi scatters back to Body Tempering")
	print("PASS cultivation: hidden roots, unique awakening, qi formula, site density, technique cap, lifespan")
	quit()
