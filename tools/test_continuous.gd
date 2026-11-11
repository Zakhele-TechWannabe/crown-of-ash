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
	assert(not map.ground.pending.is_empty())
	while not map.ground.update_chunks(camera, 1):
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
	while not map.ground.update_chunks(camera, 1):
		await process_frame
	for key: Vector2i in old_keys:
		assert(not map.ground.chunks.has(key))
	assert(map.ground.chunks.size() <= map.ground.LIMIT)
	for key: Vector2i in map.ground.chunks:
		var sprite: Sprite2D = map.ground.chunks[key]
		assert(sprite.texture != null and sprite.scale == Vector2(2, 2))
		assert(sprite.texture.get_width() == 1024)
		assert(sprite.z_index == key.y)
		for local in [Vector2i.ZERO, Vector2i(63, 63)]:
			var at: Vector2i = key * 64 + local
			var info: Dictionary = map.ground.sample(at)
			assert(info.height == map.ground.ground_height(at))
			var point := (Vector2(at) + Vector2.ONE * 0.5) * 32.0
			point.y -= info.level * map.ground.exaggeration
			var picked: Vector2i = map.ground.pick_tile(point)
			assert(picked.x == at.x)
			var top: float = picked.y * 32.0 - map.ground.terrace_level(picked) * map.ground.exaggeration
			assert(point.y >= top and point.y < top + 32.0)
	var origin := Vector2i(camera.position / 32.0)
	for y in 32:
		for x in 32:
			var at := origin + Vector2i(x, y)
			var height: float = map.ground.ground_height(at)
			assert(absf(height - map.ground.ground_height(at + Vector2i.RIGHT)) < 0.03)
			var p := (Vector2(at) + Vector2.ONE * 0.5) / 16.0
			if not map.ground._sea(p) and map.ground._river_distance(p) <= 0:
				assert(is_equal_approx(height, map.ground._blend(p)))
	map.ground.set_exaggeration(20)
	assert(map.ground.exaggeration == 20 and map.ground.chunks.is_empty())
	map.ground.set_exaggeration(-1)
	assert(map.ground.exaggeration == 0)
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
	print("PASS ground: deterministic heights, smooth slopes, rivers, baked sprites, picking, exaggeration, eviction, travel, bounds, map return")
	quit()
