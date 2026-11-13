extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var life: Node2D = map.life
	assert(life.people.size() == 20)
	var jobs: Dictionary = {}
	var households: Dictionary = {}
	for p: Dictionary in life.people:
		households[p.home_cottage] = int(households.get(p.home_cottage, 0)) + 1
		jobs[p.job] = int(jobs.get(p.job, 0)) + 1
		assert(p.age == 12)
		assert(not life.grid.get_point_path(p.home, p.work).is_empty(), "Unreachable workplace: " + str(p.name))
	for count: int in households.values():
		assert(count >= 2 and count <= 3)
	assert(jobs["field hand"] == 8 and not jobs.has("child"))
	# Ten boys and ten girls, all twelve, with no parents in the valley.
	assert(life.people.filter(func(p: Dictionary) -> bool: return p.sex == "female").size() == 10)
	for job: String in ["orchard keeper", "fisher", "hunter", "woodcutter", "quarryman", "miner", "smith", "weaver", "tanner", "kiln tender"]:
		assert(jobs.has(job))
	var food_duties: Dictionary = {}
	for person: Dictionary in life.people:
		var duty := str(person.get("food_work", ""))
		food_duties[duty] = int(food_duties.get(duty, 0)) + 1
	assert(food_duties.garden == 2 and food_duties.herd == 2 and food_duties.kitchen == 2)
	assert(life.food_patches.size() == 17)
	assert(Vector2(life.food_places.hunt).distance_to(Vector2(life.sect.center + Vector2i(141, 94))) < 4.0)
	for id: String in life.food_places:
		assert(not life.grid.is_point_solid(life.food_places[id]))
		print("FOOD PLACE %s: %s" % [id, life.food_places[id] - life.sect.center])
	life.minutes = 540
	life._refresh(true)
	for p: Dictionary in life.people:
		assert(not p.hidden)
		assert(p.pos == Vector2(p.destination))
	# A changed destination creates a route; movement consumes it at 1.5 tiles/s.
	var walker: Dictionary = life.people[0]
	walker.pos = Vector2(walker.home)
	walker.destination = Vector2i(-999, -999)
	life._refresh()
	var route_count: int = life.routes.size()
	life._refresh()
	assert(life.routes.size() == route_count)
	var start: Vector2 = walker.pos
	life._process(1.0)
	assert(start.distance_to(walker.pos) > 0.0 and start.distance_to(walker.pos) <= 1.5)
	life.minutes = 750
	life._refresh(true)
	for p: Dictionary in life.people:
		assert(p.activity == "eating a midday meal")
	life.minutes = 1380
	life._refresh(true)
	for p: Dictionary in life.people:
		assert(p.hidden)
	life.minutes = 540
	life._refresh(true)
	map._go_to("Servants' Village", false)
	assert(map.on_ground)
	life.followed = 0
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	map.ground_view._unhandled_input(escape)
	assert(life.followed == -1 and map.on_ground)
	map.ground_view.cam.zoom = Vector2.ONE * 0.2
	map.ground.update_chunks(map.ground_view.cam, 0)
	assert(map.ground.wanted.size() > 16 and map.ground.wanted.size() <= map.ground.LIMIT)
	map.ground_view.cam.zoom = Vector2.ONE
	map.ground.update_chunks(map.ground_view.cam, 0)
	assert(map.ground.wanted.size() <= 20)
	var before: float = life.minutes
	map.show_map()
	life._process(1.0)
	assert(is_equal_approx(life.minutes, before + 2.4))
	life.paused = true
	life._process(1.0)
	assert(is_equal_approx(life.minutes, before + 2.4))
	var claimed: Dictionary = {}
	for patch: Dictionary in life.food_patches:
		assert(not patch.tiles.is_empty(), "Missing footprint: " + str(patch.kind))
		if patch.kind == "orchard": assert(patch.tiles.size() == 120)
		for tile: Vector2i in patch.tiles:
			assert(not claimed.has(tile))
			assert(life.sect.surface_at(tile) in ["", "grass", "garden"])
			assert(life.sect.art[life.sect.index_at(tile)] < 0)
			assert(life.sect.dry.call(tile))
			claimed[tile] = true
	# Nobody climbs a cliff: every change of level on a route happens on a ramp or a stair.
	var climbs := 0
	for p: Dictionary in life.people:
		for target: Vector2i in [p.work, life.square, life.granary]:
			var route: PackedVector2Array = life.grid.get_point_path(p.home, target)
			assert(not route.is_empty(), "Unreachable after the cliffs: %s" % p.name)
			for k in range(1, route.size()):
				var a := Vector2i(route[k - 1])
				var b := Vector2i(route[k])
				if life.heights[life.sect.index_at(a)] != life.heights[life.sect.index_at(b)]:
					climbs += 1
					assert((life.sect.ramps.has(a) and life.sect.ramps.has(b)) or "stairs" in [life.sect.surface_at(a), life.sect.surface_at(b)], "Walked up a cliff at %s" % str(b))
	print("climbs on ramps or stairs: %d, ramps: %d" % [climbs, life.sect.ramps.size()])
	# Housemates are unrelated friends living in a named cottage.
	var pop: RefCounted = life.population
	var society: RefCounted = pop.society
	assert(pop.household[0] == pop.household[1] and pop.household_name(0).contains("cottage"))
	assert(not society.related(0, 1) and society.ties.bonds[society.ties.find(0, 1)] & 1)
	# A fight between two villagers plays on the map: they meet, stand and trade blows, then go their ways.
	var fa := int(life.people[2].id)
	var fb := int(life.people[3].id)
	preload("res://src/combat.gd").between(society, fa, fb, "spar")
	life.minutes = floorf(life.minutes / 1440.0) * 1440.0 + 500.0
	life.paused = false
	life.speed = 8.0
	var seen := {}
	var sparring := false
	var pops := 0
	for frame in 4000:
		life._process(0.1)
		for st: Dictionary in life.stages:
			seen[st.phase] = true
			pops = maxi(pops, st.pops.size())
		if str(life.people[2].activity).begins_with("sparring with"): sparring = true
		if seen.has("fight") and life.stages.is_empty(): break
	assert(seen.has("meet") and seen.has("fight") and life.stages.is_empty() and sparring and pops > 0, "Fight scene: %s, sparring %s, pops %d" % [seen, sparring, pops])
	assert(not life.people[2].has("fighting") and not life.people[3].has("fighting"))
	print("fight scene phases: %s" % [seen.keys()])
	life.speed = 1.0
	# The dead stop walking and eating; an empty valley gets twenty new twelve-year-olds.
	society.alive[0] = 0
	life._tend_the_dead()
	assert(life.people.size() == 19 and life.walker_of(0) < 0 and not life.economy.walker_ids.has(0))
	for id in pop.size(): society.alive[id] = 0
	life._tend_the_dead()
	assert(life.people.size() == 20 and pop.size() == 40)
	for p: Dictionary in life.people:
		assert(int(p.id) >= 20 and society.alive[int(p.id)] and pop.age(int(p.id)) == 12)
	assert(life.economy.walker_ids.size() == 20 and is_equal_approx(life.economy.daily_need(), 20.0))
	print("PASS village: dead walkers leave, an empty valley is resettled;")
	print("PASS village: jobs, reachable workplaces, schedules, sleep, travel, zoom coverage and clock in both views")
	quit()
