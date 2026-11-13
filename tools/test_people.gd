extends SceneTree
func _initialize() -> void:
	var store := preload("res://src/population.gd").new()
	var c: RefCounted = store.catalogue
	assert(c.errors.is_empty())
	assert(c.spheres.size() == 10 and c.domains.size() == 100 and c.disciplines.size() == 1500)
	var specials := 0
	var perks := 0
	for discipline: Dictionary in c.disciplines.values():
		if not discipline.get("detailed", false): continue
		assert(discipline.specialisations.size() >= 3 and discipline.specialisations.size() <= 6)
		assert(discipline.perks.size() == 10 and discipline.gates.size() == 9)
		specials += discipline.specialisations.size()
		perks += discipline.perks.size()
	assert(c.title(0) == "Untrained" and c.title(16) == "Skilled" and c.title(31) == "Master" and c.title(50) == "Peerless")
	var job := store.register_job("farmer", ["fields"])
	var p := store.add_person("Test cultivator", 50, job)
	store.potential[p * 8 + 1] = 20
	store.attributes[p * 8 + 1] = 16
	var entry := store.touch(p, "grain_farming.farming", 5)
	store.skill_xp[entry] = 10000
	store.tick_day(1)
	assert(store.skill_level[entry] == 5, "Gate requires practice")
	store.skill_days[entry] = 40
	store.tick_day(2)
	assert(store.skill_level[entry] >= 6)
	store.skill_level[entry] = 35
	store.skill_days[entry] = 20000
	store.skill_xp[entry] = 1000000
	store.tick_day(3)
	assert(store.skill_level[entry] == 35, "Spirit root alone cannot bypass qi ceiling")
	for definition: Dictionary in c.modifiers:
		if definition.effect == "qi": store.modifiers.apply(p, definition, 3)
	store.tick_day(4)
	assert(store.skill_level[entry] > 35)
	var cap: int = store.potential[p * 8 + 1]
	store.modifiers.apply(p, c.modifiers[1], 4)
	assert(store.potential[p * 8 + 1] == mini(20, cap + 1))
	store.modifiers.apply(p, c.modifiers[0], 4)
	assert(store.modifiers.value(p, "grain_farming.farming", "xp_multiplier", 4) > 1)
	store.modifiers.expire(7)
	assert(is_equal_approx(store.modifiers.value(p, "grain_farming.farming", "xp_multiplier", 7), 1))
	# Chronicle events also live in the population buffer; the personal story shows one specific entry.
	var PersonBook = preload("res://src/person_book.gd")
	store.society.note(p, "tempering", "A unique breakthrough")
	store.events.append({"day": store.day, "person": p, "kind": "milestone", "text": "A unique breakthrough"})
	var story: Array = PersonBook.story_entries(store, p).filter(func(e: Array) -> bool: return e[2] == "A unique breakthrough")
	assert(story.size() == 1 and story[0][1] == "tempering", "Story merges buffers and prefers the specific kind")
	var browser := preload("res://src/people_browser.gd").new()
	browser.population = store
	store.society.temper.body_layer[p] = 4
	browser.path_filter = "Body Tempering"
	browser.stage_filter = "4–6"
	assert(browser.cultivation_matches(p))
	browser.stage_filter = "7–9"
	assert(not browser.cultivation_matches(p))
	store.society.revealed[p] = 1
	store.society.temper.hours[p] = 2
	store.society.temper.regimen_until[p] = store.day + 100
	store.society.temper.teacher[p] = p
	store.society.temper.tempering[p] = store.society.temper.cost(5)
	store.birth_day[p] = store.day - 65 * 365
	store.last_insight_day[p] = store.day
	store.best_level[p] = 31
	store.society.injury_until[p] = store.day + 10
	assert(browser.notable_reason(p).size() == 10, "All notable reasons appear together")
	browser.free()
	# Identical day transactions must not depend on the frame batch size.
	var first := preload("res://src/population.gd").new()
	var second := preload("res://src/population.gd").new()
	for model: RefCounted in [first, second]:
		var farming_job: int = model.register_job("farmer", ["fields"])
		for i in 20:
			var resident: int = model.add_person("Resident %d" % i, 20 + i, farming_job, i / 4)
			model.touch(resident, "grain_farming.farming", 13, 800)
			model.touch(resident, "grain_farming.farming.paddy_rice", 13, 800)
			model.set_location(resident, Vector2(i, i))
	for d in range(1, 201):
		first.tick_day(d)
		assert(second.begin_day(d))
		while not second.process_batch(3): pass
	assert(first.skill_level == second.skill_level and first.skill_xp == second.skill_xp and first.attributes == second.attributes and first.events == second.events, "Batch size cannot change simulation results")
	assert(first.nearby(Rect2(0, 0, 100, 100), 7).size() == 7)
	var child: int = first.add_child("Newborn", 0, 1)
	assert(first.birth_day[child] == first.day and first.household[child] == first.household[0])
	for a in 8:
		assert(first.potential[child * 8 + a] >= 10 and first.potential[child * 8 + a] <= 20)
		assert(first.attributes[child * 8 + a] <= first.potential[child * 8 + a])
	var idle: int = first.register_job("retired", [])
	var elder: int = first.add_person("Retired carver", 70, idle)
	var rusty: int = first.touch(elder, "woodworking.carpentry", 17, 3000)
	for d in range(201, 270): first.tick_day(d)
	assert(first.skill_level[rusty] == 16, "Rust can lose levels within Skilled but preserves the title floor")
	var novice := preload("res://src/population.gd").new()
	var novice_job := novice.register_job("new farmer", ["fields"])
	var beginner := novice.add_person("Hard task apprentice", 25, novice_job)
	for a in 8: novice.attributes[beginner * 8 + a] = 10
	novice.comprehension[beginner] = 1
	novice.traits[beginner] = 0
	novice.xp_traits[beginner] = 1
	novice.mood[beginner] = .9
	var foundation := novice.touch(beginner, "grain_farming.farming", 0, 1)
	novice.touch(beginner, "grain_farming.farming.paddy_rice", 0, 1)
	novice.tick_day(1)
	assert(novice.skill_xp[foundation] > 1.0, "Over-hard assisted work gives failure XP, not the easy-task 10% penalty")
	print("PASS people catalogue spheres=%d domains=%d disciplines=%d detailed=375 specialisations=%d perks=%d traits=%d; gates, modifiers, qi ceiling" % [c.spheres.size(), c.domains.size(), c.disciplines.size(), specials, perks, c.traits.size()])
	quit()
