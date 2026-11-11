extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func export_area(g: Node2D, rect: Rect2i, path: String) -> void:
	var image := Image.create(rect.size.x * 4, rect.size.y * 4 + 100, false, Image.FORMAT_RGBA8)
	for cy in range(floori(rect.position.y / 64.0), ceili(rect.end.y / 64.0)):
		for cx in range(floori(rect.position.x / 64.0), ceili(rect.end.x / 64.0)):
			var key := Vector2i(cx, cy)
			var baker: RefCounted = g._new_baker()
			baker.bake(key)
			var chunk: Image = baker.pending.image
			chunk.resize(256, maxi(1, chunk.get_height() / 4), Image.INTERPOLATE_NEAREST)
			var offset := (key * 64 - rect.position) * 4 + Vector2i(0, 100 + (int(baker.pending.min_y) - int(baker.pending.overflow)) / 4)
			image.blend_rect(chunk, Rect2i(Vector2i.ZERO, chunk.get_size()), offset)
	assert(image.save_png(path) == OK)

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var g: Node2D = map.ground
	for name: String in g.sect.destinations:
		map._go_to(name, false)
		assert(map.on_ground)
		assert(g.pick_tile(map.ground_view.cam.position) == g.sect.destinations[name])
	var city: RefCounted = g.sect.sites[0]
	var count := 0
	for b: Dictionary in city.data.buildings:
		if b.kind in ["house", "hall", "court"]:
			count += 2 if b.kind == "court" else 1
			for y in int(b.rect[3]):
				for x in int(b.rect[2]):
					var at: Vector2i = city.center + Vector2i(int(b.rect[0]) + x, int(b.rect[1]) + y)
					assert(city.dry.call(at), "Wet building " + str(at))
	for y in city.bounds.size.y:
		for x in city.bounds.size.x:
			var at: Vector2i = city.center + city.bounds.position + Vector2i(x, y)
			var i: int = city.index_at(at)
			if city.has_tile(at) and city.surfaces[i] != 9:
				assert(city.dry.call(at), "City overlay in water " + str(at))
	for plot: Dictionary in city.data.plots:
		var at: Vector2i = city.center + Vector2i(int(plot.rect[0]), int(plot.rect[1]))
		if city.dry.call(at):
			assert(g.terrace_level(at) == city.level_at(at))
	assert(count >= 250 and count <= 350)
	var route: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/roads/west_road.json"))
	assert(route.length_tiles > 500)
	for at: Array in route.points:
		assert(g.sect.has_tile(Vector2i(int(at[0]), int(at[1]))))
	export_area(g, Rect2i(450, 2110, 320, 220), "res://out/city-overview.png")
	export_area(g, Rect2i(1475, 2100, 640, 430), "res://out/hunt-overview.png")
	print("PASS sites: destinations, dry city plots, %d buildings, %.1f tile road, detailed overview exports" % [count, route.length_tiles])
	quit()
