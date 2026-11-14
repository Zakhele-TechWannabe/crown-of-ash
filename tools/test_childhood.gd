extends SceneTree
const Population = preload("res://src/population.gd")
const Save = preload("res://src/world_save.gd")

func _initialize() -> void:
	var p := Population.new()
	# Keep the talent peer cohort intact; encounters have their own seeded-decade test.
	p.society.wildlife.enabled = false
	var farm := p.register_job("paddies", ["fields"])
	var smith := p.register_job("smithy", ["chores"])
	var mother := p.add_person("Mother", 25, farm)
	var father := p.add_person("Father", 25, farm)
	var peer := p.add_person("Peer", 25, farm)
	var infant := p.add_child("Infant", mother, father)
	var child := p.add_child("Child", mother, father)
	var friend := p.add_child("Friend", mother, father)
	p.birth_day[child] = -7 * 365
	p.birth_day[friend] = -7 * 365
	var c: RefCounted = p.society.childhood
	assert(p.schedules[p.job[infant]].is_empty())
	assert(c.activity(infant).contains("at home with Mother"))
	assert(is_equal_approx(c.work_fraction(mother), .6))
	assert(c.work_fraction(peer) == 1.0)
	p.prepare_person(mother)
	p.prepare_person(peer)
	p.comprehension[peer] = p.comprehension[mother]
	for a in 8: p.attributes[peer * 8 + a] = p.attributes[mother * 8 + a]
	p.xp_traits[peer] = p.xp_traits[mother]
	p.traits[peer] = p.traits[mother]
	p.tool_quality[peer] = p.tool_quality[mother]
	p.mood[peer] = p.mood[mother]
	p.base_xp_hour = .001
	p.tick_span(1)
	var mother_xp := 0.0
	var peer_xp := 0.0
	for row: Dictionary in p.sparse_skills(mother).values(): mother_xp += float(row.xp)
	for row: Dictionary in p.sparse_skills(peer).values(): peer_xp += float(row.xp)
	assert(mother_xp < peer_xp, "Infant care reduces actual practice")
	c.tag_along(child, mother, 0)
	assert(c.interests[child].paddies > 0)
	var before: Dictionary = p.sparse_skills(child)
	for day in 365: p.tick_span(day + 1)
	assert(p.sparse_skills(child) == before, "Children never gain skill XP")
	assert(p.sparse_skills(infant).is_empty())
	var edge: int = p.society.ties.find(child, friend)
	assert(edge >= 0 and p.society.ties.familiarity[edge] > 0)
	for a in 8:
		p.potential[child * 8 + a] = 20
		p.potential[friend * 8 + a] = 10
	p.birth_day[friend] = p.birth_day[child]
	c.talent_given[child] = 0
	c.talent(child)
	assert(c.talent_given[child])
	assert(p.society.chronicle[-1].kind == "talent")
	var original: int = p.potential[child * 8]
	p.hunger[mother] = 1
	c.grow(child, 365, p.day)
	assert(original - p.potential[child * 8] == int(c.config.hunger_loss_cap))
	c.grow(child, 365, p.day)
	assert(original - p.potential[child * 8] == int(c.config.hunger_loss_cap))
	c.interests[child] = {"smithy": 1.0}
	p.birth_day[child] = p.day - 12 * 365
	c.choose_trade(child)
	assert(p.job[child] == smith)
	p.hunger[child] = 0
	p.tick_span(p.day + 7)
	assert(not p.sparse_skills(child).is_empty(), "At twelve work starts")
	var state := Save.capture(p)
	assert(state.society.childhood.interests[child].smithy == 1.0)
	var restored := Population.new()
	Save.restore(restored, state)
	assert(restored.society.childhood.interests[child].smithy == 1.0)
	assert(restored.society.childhood.potential_lost[child] == c.potential_lost[child])
	assert(restored.society.childhood.talent_given[child] == c.talent_given[child])
	var trades := {}
	for i in 20:
		var youngster := p.add_child("Youngster %d" % i, mother, father)
		p.birth_day[youngster] = p.day - 12 * 365
		c.interests[youngster] = {"smithy" if i % 2 else "paddies": 1.0}
		c.choose_trade(youngster)
		trades[p.job[youngster]] = true
	assert(trades.size() == 2, "Children choose a mix of trades")
	print("PASS childhood: no XP or duties before twelve, infant care, playmates, interests, real talent, capped hunger and trade choice, save hooks")
	quit()
