extends RefCounted
## Disposable presentation context; no population writes.
const QUOTA := 50
const ROUTE_LIMIT := 128
var settlement := 50
var site: RefCounted
var grid := AStarGrid2D.new()
var people: Array[Dictionary] = []
var routes: Dictionary = {}
var anchors: Dictionary = {}
var beds: Array[Vector2i] = []
var requests := 0
var path_peak_usec := 0

func setup(ground: RefCounted) -> void:
	site = ground
	grid.region = Rect2i(site.center + Vector2i(-150, -175), Vector2i(300, 350))
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			grid.set_point_solid(at, not site.dry.call(at) or site.standing_tiles.has(at))
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			if site.surface_at(at) == "stairs": continue
			for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if site.level_at(at) != site.level_at(at + offset) and site.surface_at(at + offset) != "stairs":
					grid.set_point_solid(at)
	for zone: Dictionary in site.data.zones:
		anchors[zone.zone] = nearest(site.center + Vector2i(zone.anchor[0], zone.anchor[1]))
	build_beds()

func build_beds() -> void:
	for building: Dictionary in site.data.buildings:
		if int(building.get("beds", 0)) == 0: continue
		var r: Array = building.rect
		for n in int(building.beds):
			beds.append(nearest(site.center + Vector2i(int(r[0]) + n % 10, int(r[1]) + int(r[3]) + n / 10)))

func nearest(at: Vector2i) -> Vector2i:
	for radius in range(40):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var tile := at + Vector2i(x, y)
				if grid.is_in_boundsv(tile) and not grid.is_point_solid(tile): return tile
	return grid.region.get_center()

func sync(store: RefCounted) -> void:
	people = people.filter(func(p: Dictionary) -> bool: return eligible(store, int(p.id)))
	for id: int in store.society.fifty.people:
		if not eligible(store, id): continue
		var found := false
		for p: Dictionary in people:
			if p.id == id: found = true
		if found or people.size() >= QUOTA: continue
		var slot: int = int(store.society.fifty.people[id].dorm_bed)
		var bed: Vector2i = beds[slot % beds.size()]
		people.append({"id": id, "home": bed, "work": anchors.training, "pos": Vector2(bed), "destination": bed, "path": PackedVector2Array(), "step": 0, "hidden": false, "activity": "sleeping at home", "kind": 0, "age": store.age(id), "hunger": 0, "tint": Color(0.65, 0.85, 0.85)})

func eligible(store: RefCounted, id: int) -> bool:
	return store.society.alive[id] and store.settlement[id] == settlement and store.society.fifty.people[id].status not in ["dead", "restoring"] and not store.society.fifty.away(id)

func update(minutes: float, elapsed: float, speed: float) -> void:
	requests = 0
	for p: Dictionary in people:
		var t := fmod(minutes - p.id % 5, 1440.0)
		var zone := "dormitory"
		var activity := "sleeping at home"
		if t >= 360 and t < 480:
			zone = "kitchen" if t < 420 else "stores"
			activity = "breakfast and chores"
		elif t >= 480 and t < 570 or t >= 840 and t < 930:
			zone = "training"
			activity = "body tempering"
		elif t >= 600 and t < 660:
			zone = "training"
			activity = "weapon practice"
		elif t >= 720 and t < 780 or t >= 1080 and t < 1140:
			zone = "kitchen"
			activity = "eating a meal"
		elif t >= 570 and t < 1080:
			zone = "library"
			activity = "resting and studying"
		elif t >= 1140 and t < 1260:
			zone = "baths"
			activity = "evening rest"
		var target: Vector2i = p.home if zone == "dormitory" else anchors[zone]
		p.activity = activity
		p.hidden = false
		if speed >= 64:
			p.pos = Vector2(target)
			p.destination = target
			p.path = PackedVector2Array()
		elif target != p.destination and requests < 2:
			var start := nearest(Vector2i(Vector2(p.pos).round()))
			var key := Vector4i(start.x, start.y, target.x, target.y)
			if not routes.has(key):
				requests += 1
				var began := Time.get_ticks_usec()
				routes[key] = grid.get_point_path(start, target)
				path_peak_usec = maxi(path_peak_usec, Time.get_ticks_usec() - began)
			var path: PackedVector2Array = routes[key]
			routes.erase(key)
			routes[key] = path
			while routes.size() > ROUTE_LIMIT: routes.erase(routes.keys()[0])
			p.path = path
			p.step = 0
			p.destination = target
		var distance := elapsed * 1.5
		while distance > 0 and p.step < p.path.size():
			var next: Vector2 = p.path[p.step]
			var gap := Vector2(p.pos).distance_to(next)
			if gap <= distance:
				p.pos = next
				p.step += 1
				distance -= gap
			else:
				p.pos = Vector2(p.pos).move_toward(next, distance)
				distance = 0
