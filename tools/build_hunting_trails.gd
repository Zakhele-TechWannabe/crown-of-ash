extends SceneTree
## Offline contour routing using the same bounded A* grid as build_roads.gd.
class ContourGrid extends AStarGrid2D:
	var heights: Dictionary = {}
	func _compute_cost(a: Vector2i, b: Vector2i) -> float:
		var slope: float = absf(heights[a] - heights[b]) / Vector2(a).distance_to(Vector2(b))
		return Vector2(a).distance_to(Vector2(b)) * (1.0 + pow(slope * 1300.0, 2))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var grid := ContourGrid.new()
	grid.region = Rect2i(1490, 2150, 530, 320)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grid.update()
	for y in range(2150, 2470):
		for x in range(1490, 2020):
			var at := Vector2i(x, y)
			grid.heights[at] = map.ground.ground_height(at)
	var stops: Array[Vector2i] = [Vector2i(1510, 2385), Vector2i(1610, 2350), Vector2i(1650, 2190), Vector2i(1740, 2290), Vector2i(1800, 2420), Vector2i(1870, 2340), Vector2i(1910, 2225), Vector2i(1987, 2378)]
	var paths: Array = []
	var route: Array = []
	for i in range(stops.size() - 1):
		var leg := grid.get_id_path(stops[i], stops[i + 1])
		assert(not leg.is_empty())
		for at: Vector2i in leg:
			if route.is_empty() or route[-1] != [at.x, at.y]:
				route.append([at.x, at.y])
	# Round short stair-step corners without cutting across contour legs.
	var points: Array = []
	for i in route.size():
		var p := Vector2.ZERO
		for j in range(maxi(0, i - 3), mini(route.size(), i + 4)):
			p += Vector2(route[j][0], route[j][1])
		p /= mini(route.size(), i + 4) - maxi(0, i - 3)
		points.append([p.x, p.y])
	paths.append({"points": points, "width": 1.5})
	for ends: Array in [[Vector2i(1610, 2350), Vector2i(1690, 2370)], [Vector2i(1740, 2290), Vector2i(1810, 2250)], [Vector2i(1870, 2340), Vector2i(1940, 2410)]]:
		var branch: Array = []
		for at: Vector2i in grid.get_id_path(ends[0], ends[1]):
			branch.append([at.x, at.y])
		paths.append({"points": branch, "width": 0.7})
	var file := FileAccess.open("res://data/roads/hunting_trails.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"paths": paths}, "\t"))
	print("PASS hunting routes: %d points, gate level %d, summit level %d" % [points.size(), map.ground.terrace_level(stops[0]), map.ground.terrace_level(stops[-1])])
	quit()
