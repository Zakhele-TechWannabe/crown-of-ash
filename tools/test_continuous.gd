extends SceneTree
## Exercise shared simulation, terrain plots and bounded streaming.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var family: Node2D = map.settlement
	assert(family.c.houses.size() == 1)
	assert(not map.on_ground)
	var clock: float = family.c.clock
	await process_frame
	assert(family.c.clock > clock)
	var blocked := 0
	for y in family.Land.H:
		for x in family.Land.W:
			var local := Vector2i(x, y)
			var sample: Dictionary = map.ground.sample(family.origin + local)
			if not family.Land.is_open(sample):
				blocked += 1
				assert(family.c.land.at(local) == family.Land.BLOCKED)
				assert(not family.c.can_mark(Rect2i(local, Vector2i(2, 2)), true))
	assert(blocked > 0)
	family._demo()
	assert(family.c.fields.size() == family.World.CROPS.size())
	assert(family.c.zones.size() >= 2)
	map._travel_home()
	assert(map.on_ground and family.active and family.hud.visible)
	var position: Vector2 = family.cam.position
	for n in 12:
		await process_frame
	assert(map.ground.chunks.size() <= 16)
	for key: Vector2i in map.ground.chunks:
		var base: TileMapLayer = map.ground.chunks[key].get_child(0)
		for local in [Vector2i.ZERO, Vector2i(63, 63)]:
			var sample: Dictionary = map.ground.sample(key * 64 + local)
			assert(base.get_cell_atlas_coords(local) == Vector2i(sample.kind, sample.shade + sample.band * 9))
	map.show_map()
	assert(not map.on_ground and not family.active)
	assert(map.cam.position.is_equal_approx(position / 64.0))
	map._go_to("Sunset Heights", false)
	assert(map.on_ground)
	assert(family.cam.position != position)
	for n in 12:
		await process_frame
	assert(map.ground.chunks.size() <= 16)
	map.show_map()
	var key := InputEventKey.new()
	key.keycode = KEY_M
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	assert(map.on_ground)
	key = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	assert(not map.on_ground)
	var same_family: Node2D = map.settlement
	map._create_settlement(Vector2i(2840, 3016))
	assert(map.settlement != same_family)
	assert(map.settlement.c.fields.is_empty())
	map._travel_home()
	await process_frame
	print("PASS continuous world: shared simulation, demo, terrain, travel, reset, chunks")
	quit()
