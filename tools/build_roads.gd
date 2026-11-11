extends SceneTree
## Offline deterministic terrain survey, city plots and weighted A* road generation.
var g: Node2D
var occupied: Array[Rect2i] = []
var city := {"name": "Western Market City", "center": [630, 2220], "bounds": [-180, -110, 320, 220], "buildings": [], "plots": [], "paths": [], "stamps": []}
var road := {"name": "Roads", "center": [0, 0], "bounds": [450, 2000, 1700, 650], "buildings": [], "plots": [], "paths": [], "stamps": []}

func _initialize() -> void:
	call_deferred("run")

func dry(at: Vector2i) -> bool:
	var p := (Vector2(at) + Vector2.ONE * 0.5) / 16.0
	return not g._sea(p) and g._river_distance(p) > 1.5

func save_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))

func path_to(points: Array, width: int, kind: String = "earth") -> void:
	road.paths.append({"points": points, "width": width, "kind": kind})

func add_house(at: Vector2i, size: Vector2i, name: String = "", kind: String = "house") -> bool:
	for y in range(-1, size.y + 2):
		for x in range(-1, size.x + 2):
			if not dry(at + Vector2i(x, y)):
				return false
	var footprint := Rect2i(at, size).grow(1)
	for other: Rect2i in occupied:
		if footprint.intersects(other):
			return false
	occupied.append(footprint)
	var local := at - Vector2i(630, 2220)
	city.buildings.append({"name": name, "kind": kind, "rect": [local.x, local.y, size.x, size.y]})
	city.plots.append({"rect": [local.x - 1, local.y - 1, size.x + 2, size.y + 2], "level": g.terrace_level(at), "surface": "paving"})
	return true

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	g = map.ground
	for item: Array in [[680, 2150, "Yamen"], [675, 2260, "Temple"], [640, 2180, "Grain Exchange"], [690, 2190, "Medicine Street"], [650, 2240, "Cloth Street"], [700, 2250, "Inn District"], [550, 2200, "Customs House"]]:
		add_house(Vector2i(item[0], item[1]), Vector2i(18, 18) if item[2] in ["Yamen", "Temple"] else Vector2i(12, 7), item[2], "court" if item[2] in ["Yamen", "Temple"] else "hall")
	for y in [2160, 2180, 2240, 2260]:
		add_house(Vector2i(515, y), Vector2i(12, 6), "", "hall")
	# Survey every footprint; staggered blocks leave winding lanes and named civic districts.
	for row in 18:
		for col in 24:
			var at := Vector2i(510 + col * 10 + (row % 3), 2126 + row * 10 + (col % 3))
			if (col + row * 3) % 13 == 0 or absi(at.y - 2220) < 9 or (Rect2i(575, 2170, 55, 38).has_point(at) or Rect2i(610, 2250, 25, 25).has_point(at)):
				continue
			add_house(at, Vector2i(4 + col % 3, 3 + row % 2), "", "house" if (col + row) % 3 else "hall")
	for y in range(-85, 95, 10):
		city.paths.append({"points": [[-125, y], [-40, y + 1], [40, y - 1], [125, y]], "width": 2, "kind": "earth"})
	city.paths.append({"points": [[-80, 0], [0, 0], [129, 0]], "width": 5, "kind": "paving"})
	city.plots.append({"rect": [-20, 30, 25, 25], "level": 5, "surface": "garden"})
	city.plots.append({"rect": [-55, -50, 55, 38], "level": 6, "surface": "paving"})
	city.buildings.append({"name": "Market Square", "kind": "marker", "rect": [-28, -34, 1, 1]})
	city.buildings.append({"name": "Western Market City", "kind": "marker", "rect": [0, -90, 1, 1]})
	for y in range(-46, -16, 6):
		for x in range(-50, -5, 5):
			city.stamps.append({"at": [x, y], "tile": 132 + absi(x + y) % 4})
			city.stamps.append({"at": [x, y + 1], "tile": 132 + absi(x + y) % 4})
	# Shore-following quay, piers only over the water, and warehouses on dry ground.
	var harbour := Vector2i(0, 2220)
	for y in range(2160, 2281):
		var shore := 480
		while shore < 650 and not dry(Vector2i(shore, y)):
			shore += 1
		if y == 2220:
			harbour.x = shore + 3
		city.paths.append({"points": [[shore - 630 + 2, y - 2220], [shore - 630 + 6, y - 2220]], "width": 2, "kind": "paving"})
		if y % 24 == 0:
			city.paths.append({"points": [[shore - 630 + 3, y - 2220], [shore - 630 - 15, y - 2220]], "width": 3, "kind": "bridge"})
			city.stamps.append({"at": [shore - 630 - 12, y - 2220 + 3], "tile": 136})
	for avenue: Dictionary in city.paths:
		if int(avenue.width) == 5:
			avenue.points[0] = [harbour.x - 630, 0]
	city.buildings.append({"name": "Harbour", "kind": "marker", "rect": [harbour.x - 630, 0, 1, 1]})
	# Stone perimeter follows dry terrain; openings are cut before gate arches.
	for y in range(2122, 2318):
		for x in range(502, 758):
			if x not in [502, 757] and y not in [2122, 2317]:
				continue
			if not dry(Vector2i(x, y)) or (absi(y - 2220) < 4 and x == 757) or (absi(x - (550 if y == 2122 else 720)) < 4 and y in [2122, 2317]):
				continue
			city.stamps.append({"at": [x - 630, y - 2220], "tile": 96 if x % 20 == 0 or y % 20 == 0 else 97})
	for edge_x in [502, 755]:
		for edge_y in range(2122, 2318, 39):
			for yy in 3:
				for xx in 3:
					if dry(Vector2i(edge_x + xx, edge_y + yy)):
						city.stamps.append({"at": [edge_x + xx - 630, edge_y + yy - 2220], "tile": 96 + xx + yy * 12})
	for edge_y in [2122, 2315]:
		for edge_x in range(520, 750, 39):
			for yy in 3:
				for xx in 3:
					if dry(Vector2i(edge_x + xx, edge_y + yy)):
						city.stamps.append({"at": [edge_x + xx - 630, edge_y + yy - 2220], "tile": 96 + xx + yy * 12})
	for entry: Array in [[754, 2219, "East Gate"], [547, 2122, "North Gate"], [717, 2316, "South Gate"]]:
		city.buildings.append({"name": entry[2], "kind": "gate", "rect": [entry[0] - 630, entry[1] - 2220, 7, 2]})
	save_json("res://data/sites/city.json", city)
	# Weighted A*: cache natural terrain costs in a bounded grid, never run in-game.
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(755, 2070, 510, 430)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grid.update()
	for y in range(2070, 2500):
		for x in range(755, 1265):
			var at := Vector2i(x, y)
			var level: int = g.terrace_level(at)
			var slope := absi(level - g.terrace_level(at + Vector2i.RIGHT)) + absi(level - g.terrace_level(at + Vector2i.DOWN))
			if g._sea((Vector2(at) + Vector2.ONE * 0.5) / 16.0):
				grid.set_point_solid(at)
			grid.set_point_weight_scale(at, 1.0 + slope * 12.0 + (150.0 if not dry(at) else 0.0))
	var route := grid.get_id_path(Vector2i(1245, 2381), Vector2i(757, 2220))
	assert(not route.is_empty())
	# Local corner rounding is accepted only on dry, comparably gentle terrain.
	for iteration in 2:
		var rounded: Array[Vector2i] = route.duplicate()
		for i in range(3, route.size() - 3):
			var average := Vector2.ZERO
			for j in range(i - 3, i + 4):
				average += Vector2(route[j]) / 7.0
			var at := Vector2i(average.round())
			var safe := true
			for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not dry(at + offset):
					safe = false
			if safe and absi(g.terrace_level(at) - g.terrace_level(route[i])) <= 1:
				rounded[i] = at
		route = rounded
	route.push_front(Vector2i(1266, 2381))
	var points: Array = []
	var length := 0.0
	for i in route.size():
		points.append([route[i].x, route[i].y])
		if i > 0:
			length += Vector2(route[i]).distance_to(Vector2(route[i - 1]))
		if i % 150 == 0:
			road.stamps.append({"at": [route[i].x, route[i].y - 3], "tile": 83})
		if not dry(route[i]):
			path_to([[route[i].x - 1, route[i].y], [route[i].x + 1, route[i].y]], 3, "bridge")
	path_to(points, 3)
	path_to(points.slice(0, 40), 3, "paving")
	path_to(points.slice(points.size() - 40), 3, "paving")
	for i in [180, 350]:
		var at: Vector2i = route[mini(i, route.size() - 1)]
		road.buildings.append({"name": "Waystation Inn" if i == 180 else "Roadside Shrine", "kind": "hall", "rect": [at.x, at.y - 10, 8, 5]})
	path_to([[1266, 2381], [1245, 2381]], 3, "stairs")
	path_to([[1464, 2381], [1490, 2381]], 3, "stairs")
	for x in [1263, 1461]:
		road.buildings.append({"name": "West Gate" if x == 1263 else "East Gate", "kind": "gate", "rect": [x, 2380, 7, 2]})
	path_to([[1490, 2381], [1530, 2360], [1570, 2380], [1620, 2330], [1680, 2345], [1740, 2280], [1810, 2300], [1880, 2240], [1950, 2260]], 2)
	for i in 3:
		var x := 1610 + i * 125
		path_to([[x, 2335 - i * 35], [x + 30, 2410], [x + 70, 2440]], 1)
		road.buildings.append({"name": "Hunting Camp %d" % (i + 1), "kind": "tent", "rect": [x, 2330 - i * 35, 4, 3]})
		for offset in [Vector2i(5, 3), Vector2i(7, 0)]:
			road.stamps.append({"at": [x + offset.x, 2330 - i * 35 + offset.y], "tile": 138 if offset.x == 5 else 116})
	for at in [[1497, 2362], [1500, 2362], [1512, 2362], [1518, 2370]]:
		road.stamps.append({"at": at, "tile": 116})
	road.buildings.append({"name": "Skinning Shed", "kind": "house", "rect": [1520, 2368, 5, 3]})
	road.buildings.append({"name": "Kennel", "kind": "house", "rect": [1520, 2375, 3, 3]})
	road.buildings.append({"name": "Hunters' Lodge", "kind": "court", "rect": [1495, 2365, 22, 20]})
	for x in range(1500, 2100, 8):
		for y in [2110, 2510]:
			path_to([[x, y], [x + 3, y]], 1, "boundary")
	for y in range(2110, 2510, 8):
		for x in [1500, 2100]:
			path_to([[x, y], [x, y + 3]], 1, "boundary")
	for side in [-1, 1]:
		for step in 25:
			var x: int = 1365 + side * (99 + step)
			var level := roundi(lerpf(11, g.terrace_level(Vector2i(1365 + side * 124, 2381)), step / 24.0))
			road.plots.append({"rect": [x, 2379, 1, 5], "surface": "stairs", "level": level})
	road.points = points
	road.width = 3
	road.surface = "earth"
	road.length_tiles = length
	save_json("res://data/roads/west_road.json", road)
	var destinations := {"West Gate": [1266, 2381], "East Gate": [1464, 2381], "Western Market City": [630, 2220], "Harbour": [harbour.x, harbour.y], "Market Square": [602, 2186], "Hunters' Lodge": [1506, 2380], "Eastern Hunting Grounds": [1800, 2310]}
	save_json("res://data/sites/index.json", {"sect": "res://data/sects/first_sect.json", "sites": ["city.json", "../roads/west_road.json"], "destinations": destinations})
	var building_count := 0
	for building: Dictionary in city.buildings:
		if building.kind in ["house", "hall", "court"]:
			building_count += 2 if building.kind == "court" else 1
	print("BUILD city centre (630, 2220), buildings %d, road %.1f tiles" % [building_count, length])
	quit()
