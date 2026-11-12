extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var life: Node2D = world.life
	life.set_process(false)
	life.paused = true
	var positions := PackedVector2Array()
	for person: Dictionary in life.people: positions.append(person.pos)
	life.start_skip(1)
	var iterations := 0
	while life.skip_target > 0:
		life._process_skip()
		iterations += 1
		if iterations % 30 == 0: await process_frame
	assert(life.population.day == 365)
	assert(life.population.tick_days == 1 and not life.economy.coarse_population)
	for i in life.people.size(): assert(life.people[i].pos == positions[i], "Walkers freeze while skipping")
	life.start_skip(100)
	life._process_skip()
	life.cancel_skip()
	while life.skip_target > 0: life._process_skip()
	assert(life.population.day <= 372, "Cancellation finishes at most the current week")
	assert(life.paused)
	assert(life.economy.stock >= 0)
	print("PASS fast-forward: weekly population ticks, frozen walkers, complete year, cancellation and pause restoration")
	quit()
