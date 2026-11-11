extends SceneTree
## Validate dense overrides and export the actual chunk artwork at four pixels per tile.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var g: Node2D = map.ground
	var sect: RefCounted = g.sect
	assert(sect.center == Vector2i(1365, 2286))
	assert(sect.level_at(sect.center + Vector2i(0, -130)) == 21)
	assert(sect.data.village.size() == 64)
	for y in range(sect.BOUNDS.position.y, sect.BOUNDS.end.y):
		for x in range(sect.BOUNDS.position.x, sect.BOUNDS.end.x):
			var at: Vector2i = sect.center + Vector2i(x, y)
			var level: int = sect.level_at(at)
			if level >= 0:
				assert(g.terrace_level(at) == level)
				assert(is_equal_approx(g.ground_height(at), 0.5 + level * 0.02))
			if y >= 156:
				assert(sect.height_at(at) == 0.0)
	for b: Dictionary in sect.data.village:
		assert(sect._dry_rect(b.rect))
	map._go_to("Unnamed Sect", false)
	assert(map.on_ground)
	assert(g.pick_tile(map.ground_view.cam.position) == sect.center)
	var low: Vector2i = sect.center + sect.BOUNDS.position
	var high: Vector2i = sect.center + sect.BOUNDS.end
	var overview := Image.create(sect.BOUNDS.size.x * 4, sect.BOUNDS.size.y * 4 + 160, false, Image.FORMAT_RGBA8)
	var overflow := ceili(g.max_level * g.exaggeration / 2.0) + 16
	for cy in range(floori(float(low.y) / 64), ceili(float(high.y) / 64)):
		for cx in range(floori(float(low.x) / 64), ceili(float(high.x) / 64)):
			var key := Vector2i(cx, cy)
			g.pending = {"image": Image.create(1024, 1024 + overflow, false, Image.FORMAT_RGBA8), "overflow": overflow, "min_y": 1024 + overflow, "max_y": 0}
			g.baking = true
			for y in 64:
				g._bake_row(key, y)
			g.baking = false
			var chunk: Image = g.pending.image
			chunk.resize(256, (1024 + overflow) / 4, Image.INTERPOLATE_NEAREST)
			var offset := key * 256 - low * 4 + Vector2i(0, 160 - overflow / 4)
			overview.blend_rect(chunk, Rect2i(Vector2i.ZERO, chunk.get_size()), offset)
			g.pending.clear()
			g.height_cache.clear()
	DirAccess.make_dir_recursive_absolute("res://out")
	assert(overview.save_png("res://out/first-sect-overview.png") == OK)
	print("PASS sect: 5x tiers, summit 21, packed overrides, natural foreland, 64 dry cottages, travel and chunk overview")
	quit()
