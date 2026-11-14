extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map.life.set_process(false)
	var context: RefCounted = map.life.palace
	var site: RefCounted = context.site
	assert(site.bounds == Rect2i(-992, -500, 1984, 1000))
	for zone: Dictionary in site.data.zones:
		var r: Array = zone.rect
		assert(site.bounds.encloses(Rect2i(r[0], r[1], r[2], r[3])))
		if zone.has("reserve_rect"):
			var reserve: Array = zone.reserve_rect
			assert(site.bounds.encloses(Rect2i(reserve[0], reserve[1], reserve[2], reserve[3])))
		assert(not context.grid.get_point_path(context.anchors.dormitory, context.anchors[zone.zone]).is_empty(), zone.zone)
	for building: Dictionary in site.data.buildings:
		if building.kind == "marker": continue
		assert(site._dry_rect(building.rect), "Wet building: " + str(building.name))
	var store: RefCounted = map.life.population
	context.sync(store)
	var snapshot: Dictionary = store.society.fifty.people.duplicate(true)
	var expected := 0
	for id: int in store.society.fifty.people:
		if context.eligible(store, id): expected += 1
	assert(context.people.size() == expected)
	map._go_to("Heavenly Dao Palace", false)
	assert(map.on_ground)
	var selected: Dictionary = context.people[0]
	assert(map.life.pick(map.life.point(selected) - Vector2(0, 10)) >= 0)
	assert(expected == 50)
	assert(context.beds.size() == 60)
	var slots: Dictionary = {}
	for p: Dictionary in context.people:
		var slot: int = store.society.fifty.people[int(p.id)].dorm_bed
		assert(not slots.has(slot))
		slots[slot] = true
		for zone: String in ["kitchen", "training", "library", "baths", "stores"]:
			assert(not context.grid.get_point_path(p.home, context.anchors[zone]).is_empty(), "Unreachable bed")
	assert(map.life.people.size() <= 100)
	for minute in range(0, 1440, 10):
		context.update(minute, 1.0, 1.0)
		assert(context.requests <= 2)
		assert(context.routes.size() <= 128)
		for p: Dictionary in context.people:
			assert(context.grid.region.has_point(p.destination))
	assert(snapshot == store.society.fifty.people, "Walking must not change the simulation")
	var first: int = context.people[0].id
	store.settlement[first] = -50
	context.sync(store)
	assert(context.people.size() == expected - 1)
	store.settlement[first] = 50
	context.sync(store)
	assert(context.people.size() == expected)
	for region: Rect2i in [Rect2i(2550, 1360, 100, 40), Rect2i(3450, 1050, 100, 100)]:
		var water := 0
		for y in range(region.position.y, region.end.y, 4):
			for x in range(region.position.x, region.end.x, 4):
				var at := Vector2i(x, y)
				if int(map.ground.sample(at).kind) <= 2:
					water += 1
					assert(not site.has_tile(at))
		assert(water > 0)
	print("PALACE peak path usec=%d" % context.path_peak_usec)
	print("PALACE bounds=1984000 storage=%d nav=%d walkers=%d routes=%d" % [site.surfaces.size(), context.grid.region.get_area(), expected, context.routes.size()])
	map.free()
	quit()
