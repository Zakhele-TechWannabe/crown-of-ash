extends SceneTree
## Check deterministic samples, streaming budgets and travel continuity.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	assert(not map.on_ground)
	var tile := Vector2i(2840, 3016)
	var sample: Dictionary = map.ground.sample(tile)
	assert(sample == map.ground.sample(tile))
	map._travel_to(tile)
	assert(map.on_ground and map.ground_view.hud.visible)
	var camera: Camera2D = map.ground_view.cam
	assert(map.ground.update_chunks(camera, 1) == false)
	assert(map.ground.chunks.size() == 1)
	for n in 12:
		await process_frame
	assert(map.ground.chunks.size() == map.ground.wanted.size())
	assert(map.ground.chunks.size() <= map.ground.LIMIT)
	var old_keys: Array = map.ground.chunks.keys()
	var position := camera.position
	map.show_map()
	assert(not map.on_ground and not map.ground_view.hud.visible)
	assert(map.cam.position.is_equal_approx(position / 64.0))
	map._go_to("Sunset Heights", false)
	assert(map.on_ground and camera.position != position)
	for n in 12:
		await process_frame
	for key: Vector2i in old_keys:
		assert(not map.ground.chunks.has(key))
	assert(map.ground.chunks.size() <= map.ground.LIMIT)
	for key: Vector2i in map.ground.chunks:
		var base: TileMapLayer = map.ground.chunks[key].get_child(0)
		for local in [Vector2i.ZERO, Vector2i(63, 63)]:
			var info: Dictionary = map.ground.sample(key * 64 + local)
			assert(base.get_cell_atlas_coords(local) == Vector2i(info.kind, info.shade + info.band * 9))
	assert(sample == map.ground.sample(tile))
	map._travel_to(Vector2i(-100, -100))
	assert(camera.position.x >= 0 and camera.position.y >= 0)
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	map.ground_view._unhandled_input(event)
	assert(not map.on_ground)
	event.keycode = KEY_M
	map._unhandled_input(event)
	assert(map.on_ground)
	print("PASS ground: deterministic samples, chunks, eviction, travel, bounds, map return")
	quit()
