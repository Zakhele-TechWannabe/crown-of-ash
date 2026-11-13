extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var j := p.register_job("chores", ["chores"])
	p.add_person("Wang Mother", 25, j)
	p.add_person("Li Father", 25, j)
	p.add_person("Zhao Matchmaker", 60, j)
	p.sex[0] = 1
	p.sex[1] = 0
	var s: RefCounted = p.society
	for a: int in [0, 1]:
		var e: int = s.ties.tie(a, 1 - a, 60)
		s.ties.familiarity[e] = 50
	assert(s.marry(0, 1))
	assert(p.household[0] == p.household[1])
	var child := p.add_child("Li Child", 0, 1)
	assert(s.father[child] == 1 and p.parent_id[child] == 0)
	var sibling := p.add_child("Li Sibling", 0, 1)
	assert(s.siblings(child) == PackedInt32Array([sibling]))
	assert(s.related(child, sibling))
	assert(s.children(0).size() == 2)
	assert(not s.marry(child, sibling))
	assert(s.lifespan_death_enabled)
	# A pregnancy comes to term after nine months; twins a month early, both born.
	var before: int = s.children(0).size()
	s.twins[0] = 1
	s.due_day[0] = p.day + int(s.events.twin_gestation_days)
	assert(int(s.events.twin_gestation_days) == 243 and int(s.events.gestation_days) == 273)
	s.deliver(0, s.due_day[0])
	assert(s.children(0).size() == before + 2 and s.due_day[0] == -1 and s.twins[0] == 0)
	p.day = 20 * 365
	var aunt := p.add_person("Zhao Aunt", 48, j, 2)
	var cousin := p.add_person("Cao Cousin", 18, j, 3)
	s.father[0] = 2
	s.father[aunt] = 2
	p.parent_id[cousin] = aunt
	assert(s.related(child, cousin) and not s.marriage_related(child, cousin))
	assert(s.marriage_related(0, cousin), "Avuncular marriage remains excluded")
	s.events.extended_kin_exclusion = true
	assert(s.marriage_related(child, cousin))
	s.events.extended_kin_exclusion = false
	s.ties.opinion[s.ties.tie(child, cousin)] = 60
	s.ties.opinion[s.ties.tie(cousin, child)] = 60
	s.realm[child] = 2
	assert(not s.marry(child, cousin), "Mixed cultivation status needs stronger mutual affection")
	s.ties.opinion[s.ties.find(child, cousin)] = 80
	s.ties.opinion[s.ties.find(cousin, child)] = 80
	assert(s.marry(child, cousin), "Cultivation is a preference rather than an absolute marriage ban")

	p.day = 36500
	s.tick(p.day)
	assert(s.alive[0] == 0, "Lifespan deaths are on: a 125-year-old mortal has died")
	print("PASS family: mutual marriage, matchmaker, household split, two parents, kin, birth, pregnancy and twins, frail elders")
	quit()
