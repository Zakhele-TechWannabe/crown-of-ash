extends SceneTree
## Headless invariants plus an overview made from the actual chunk bake.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var g: Node2D = map.ground
	var sect: RefCounted = g.sect
	for at: Vector2i in sect.tiles:
		var info: Dictionary = sect.tiles[at]
		assert(g.sample(at).decoration == -1)
		if info.has("level"):
			assert(g.terrace_level(at) == int(info.level))
			assert(is_equal_approx(g.ground_height(at), 0.5 + int(info.level) * 0.02))
		if at.y >= sect.center.y + 31:
			assert(not sect.heights.has(at))
	map._go_to("Unnamed Sect", false)
	assert(map.on_ground)
	assert(g.pick_tile(map.ground_view.cam.position) == sect.center)
	assert(sect.data.village.size() == 12)
	var overview := Image.create(2048, 2048, false, Image.FORMAT_RGBA8)
	for cy in range(34, 37):
		for cx in range(20, 23):
			var key := Vector2i(cx, cy)
			g.pending = {"image": Image.create(1024, 1400, false, Image.FORMAT_RGBA8), "overflow": 376, "min_y": 1400, "max_y": 0}
			g.baking = true
			for y in 64:
				g._bake_row(key, y)
			g.baking = false
			var offset := key * 1024 - Vector2i(sect.center.x * 16 - 1024, sect.center.y * 16 - 1024 + 376)
			overview.blend_rect(g.pending.image, Rect2i(0, 0, 1024, 1400), offset)
			g.pending.clear()
			g.height_cache.clear()
	overview.save_png("res://out/first-sect-overview.png")
	print("PASS sect: flat levels, clear footprints, natural foreland, travel, 12 houses, chunk bake; overview res://out/first-sect-overview.png")
	quit()
