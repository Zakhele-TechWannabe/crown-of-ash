extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map._go_to("Unnamed Sect", false)
	var ground: Node2D = map.ground
	var camera: Camera2D = map.ground_view.cam
	camera.zoom = Vector2.ONE * 0.2
	var started := Time.get_ticks_usec()
	while not ground.update_chunks(camera, 8):
		await process_frame
	print("LOD fill: %.2f ms, %d chunks" % [(Time.get_ticks_usec() - started) / 1000.0, ground.chunks.size()])
	assert(ground.jobs.is_empty())
	for sprite: Sprite2D in ground.chunks.values():
		assert(sprite.scale == Vector2.ONE * 32)
		var image := sprite.texture.get_image()
		assert(image.get_size() == Vector2i(64, 64))
		for y in 64:
			for x in 64:
				assert(image.get_pixel(x, y).a == 1.0)
	camera.zoom = Vector2.ONE * 0.5
	while not ground.update_chunks(camera, 8):
		await process_frame
	assert(ground.detailed.size() == ground.wanted.size())
	ground.set_exaggeration(12)
	ground.update_chunks(camera, 8)
	ground.set_exaggeration(24)
	camera.zoom = Vector2.ONE * 0.2
	while not ground.update_chunks(camera, 8):
		await process_frame
	assert(ground.detailed.is_empty())
	# Check the worker's world snapshot and raster output against the original path.
	var key := Vector2i(21, 35)
	var baker: RefCounted = ground._new_baker()
	var task := WorkerThreadPool.add_task(baker.bake.bind(key))
	WorkerThreadPool.wait_for_task_completion(task)
	var overflow := ceili(ground.max_level * ground.exaggeration / 2.0) + 16
	ground.pending = {"image": Image.create(1024, 1024 + overflow, false, Image.FORMAT_RGBA8), "overflow": overflow, "min_y": 1024 + overflow, "max_y": 0}
	ground.baking = true
	for y in 64:
		ground._bake_row(key, y)
	ground.baking = false
	var expected: Image = ground.pending.image.get_region(Rect2i(0, ground.pending.min_y, 1024, int(ground.pending.max_y) - int(ground.pending.min_y)))
	assert(expected.get_data() == baker.pending.image.get_data())
	ground.pending.clear()
	ground.height_cache.clear()
	print("PASS LOD: far fill, opaque pixels, worker upgrade, relief invalidation")
	quit()
