extends Node2D
## Deterministic mortals. Routes are planned only when a schedule destination changes.
var draw_order: Array[Dictionary] = []
var world: Node2D
var sect: RefCounted
var grid := AStarGrid2D.new()
var people: Array[Dictionary] = []
var routes: Dictionary = {}
var minutes := 300.0
var economy := preload("res://src/grain_economy.gd").new()
var granary: Vector2i
var speed := 1.0
var paused := false
var last_minute := -1
var followed := -1
var atlas: Texture2D
var heights := PackedInt32Array()
var square: Vector2i
var well: Vector2i
var food_places: Dictionary = {}
var food_patches: Array[Dictionary] = []
var material_patches: Array[Dictionary] = []
var material_places: Dictionary = {}
var shrine: Vector2i


func setup(map: Node2D) -> void:
	world = map
	sect = map.ground.sect
	z_index = 1000
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas = load("res://assets/kenney/tiny-farm/Tilemap/tilemap_packed.png")
	grid.region = Rect2i(sect.center + sect.BOUNDS.position, sect.BOUNDS.size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	heights.resize(sect.surfaces.size())
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			var i: int = sect.index_at(at)
			var surface: String = sect.surface_at(at)
			var level: int = sect.level_at(at)
			var south: bool = y - sect.center.y >= 151
			var lodge_path: bool = x - sect.center.x >= 110 and y - sect.center.y >= 90 and y - sect.center.y <= 160
			var walk: bool = (level >= 0 or sect.dry.call(at) or surface == "stairs") and surface != "spring" and surface != "cave" and sect.art[i] < 0
			if south or lodge_path:
				walk = walk and sect.dry.call(at)
			heights[i] = world.ground.terrace_level(at) if walk else maxi(0, level)
			if walk and not south and not lodge_path and surface != "stairs":
				for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if sect.level_at(at + offset) != level and sect.surface_at(at + offset) != "stairs":
						walk = false
			grid.set_point_solid(at, not walk)
	# Terrace faces are solid; only stair tiles connect different heights.
	var faces: Array[Vector2i] = []
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			if grid.is_point_solid(at) or sect.surface_at(at) == "stairs":
				continue
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var other := at + offset
				if grid.is_in_boundsv(other) and not grid.is_point_solid(other) and sect.surface_at(other) != "stairs" and absi(heights[sect.index_at(at)] - heights[sect.index_at(other)]) > (1 if sect.level_at(at) < 0 or y - sect.center.y >= 151 or (x - sect.center.x >= 110 and y - sect.center.y >= 90) else 0):
					faces.append(at)
	for at: Vector2i in faces:
		grid.set_point_solid(at)
	# The plaza, well and shrine can be relocated inland during sect setup.
	for b: Dictionary in sect.data.buildings:
		if str(b.name) == "Servants' Village":
			square = nearest(sect.center + Vector2i(int(b.rect[0]) + 5, int(b.rect[1]) + 5))
			well = nearest(sect.center + Vector2i(int(b.rect[0]) + 4, int(b.rect[1]) + 6))
		if str(b.name) == "Granary":
			granary = nearest(sect.center + Vector2i(int(b.rect[0]) + 3, int(b.rect[1]) + int(b.rect[3])))
		if b.kind == "hall" and str(b.name) != "Granary" and int(b.rect[1]) >= 156:
			shrine = nearest(sect.center + Vector2i(int(b.rect[0]) + 3, int(b.rect[1]) + int(b.rect[3])))
	_setup_food_places()
	_setup_material_places()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sect.data.seed)
	var families := ["Wang", "Li", "Zhang", "Liu", "Chen", "Yang", "Zhao", "Huang"]
	var given := ["Erniu", "Cuihua", "Dazhi", "Xiaolan", "Shan", "Mei", "Yong", "Lian", "Bao", "Qing", "An", "Xiu", "Fu", "Lan", "Ping", "Hua", "Song", "Yun", "Xiaohu", "Xiaoyu"]
	var jobs := ["field hand", "canteen cook", "plaza sweeper", "barracks attendant", "water carrier", "market vendor", "shrine keeper", "woodcutter", "child"]
	for n in 20:
		var household := n / 3 if n < 12 else (4 + (n - 12) / 2 if n < 18 else 4 + n - 18)
		var b: Dictionary = sect.data.village[household * 8]
		var home := nearest(sect.center + Vector2i(int(b.rect[0]) + 2, int(b.rect[1]) + int(b.rect[3])))
		var job := 0 if n < 8 else (n - 7 if n < 11 else (4 if n < 13 else (5 if n < 15 else (6 if n == 15 else (7 if n < 18 else 8)))))
		var work := square
		if job == 0:
			var f: Dictionary = sect.data.fields[n]
			work = nearest(sect.center + Vector2i(int(f.rect[0]) + 6 + n % 5, int(f.rect[1]) + 4))
		elif job in [1, 2, 3]:
			work = nearest(sect.center + [Vector2i(-64, 125), Vector2i(12, 15), Vector2i(-65, 76)][job - 1])
		elif job == 6:
			work = shrine
		elif job == 7:
			work = nearest(sect.center + Vector2i(80 + n % 2 * 8, 245))
		else:
			work = nearest(square + Vector2i(n % 4 * 2 - 3, n % 3 * 2))
		people.append({"name": families[household] + " " + given[n], "sex": "female" if n % 2 else "male", "age": rng.randi_range(12, 16) if job == 8 else rng.randi_range(18, 60), "home_cottage": household * 8, "home": home, "job": jobs[job], "kind": job, "work": work, "pos": Vector2(home), "destination": Vector2i(-999, -999), "path": PackedVector2Array(), "step": 0, "hidden": true, "activity": "sleeping at home", "tint": Color.from_hsv(rng.randf_range(0.05, 0.65), rng.randf_range(0.12, 0.32), rng.randf_range(0.55, 0.85))})
	var trades := ["gardener", "gardener", "orchard keeper", "herder", "herder", "fisher", "hunter", "cook / pickler", "mushroom grower", "cook / pickler"]
	# Keep the first eight adults on rice, and the two children at home.
	var facilities := ["garden", "garden", "orchard", "herd", "herd", "fishery", "hunt", "kitchen", "logs", "kitchen"]
	for n in range(8, 18):
		people[n].job = trades[n - 8]
		people[n].food_work = facilities[n - 8]
		people[n].work = food_places[facilities[n - 8]]
	# Shared morning food duties and afternoon material trades keep all twenty residents.
	for assignment: Dictionary in sect.data.material_workers:
		var n := int(assignment.resident)
		people[n].material_work = str(assignment.facility)
		people[n].job = str(assignment.job)
	economy.no_farmers = "--no-farmers" in OS.get_cmdline_user_args()
	economy.bad_harvest = "--bad-harvest" in OS.get_cmdline_user_args()
	economy.setup(sect.data, people, int(world.data.get("seed", sect.data.seed)))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="):
			minutes += (clampi(int(arg.trim_prefix("--day=")), 1, 365) - 1) * 1440.0
		if arg.begins_with("--time="):
			var parts := arg.trim_prefix("--time=").split(":")
			if parts.size() == 2:
				minutes = floorf(minutes / 1440.0) * 1440.0 + clampi(int(parts[0]), 0, 23) * 60 + clampi(int(parts[1]), 0, 59)
	economy.advance_to(minutes)
	if "--headless-sim" in OS.get_cmdline_user_args():
		call_deferred("_headless_sim")
	draw_order = people.duplicate()
	_refresh(true)


func nearest(at: Vector2i) -> Vector2i:
	if grid.is_in_boundsv(at) and not grid.is_point_solid(at):
		return at
	for radius in range(1, 40):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var p := at + Vector2i(x, y)
				if grid.is_in_boundsv(p) and not grid.is_point_solid(p):
					return p
	return square


func _refresh(initial: bool = false) -> void:
	var day := int(minutes / 1440)
	var time := fmod(minutes, 1440.0)
	for n in people.size():
		var p: Dictionary = people[n]
		var variation := (n * 17 + day * 13 + int(sect.data.seed)) % 61
		var target: Vector2i = p.home
		var activity := "sleeping at home"
		if time >= 330 + variation and time < 1260 + variation:
			if time < 390 + variation:
				activity = "preparing for the day"
			elif time >= 720 + variation / 2 and time < 780 + variation / 2:
				target = granary if n % 2 else square
				activity = "eating a midday meal"
			elif time >= 1080 + variation:
				target = [square, shrine, p.home][(n + day) % 3]
				activity = "resting in the evening"
			else:
				target = p.work
				activity = ["weeding the rice paddies", "cooking in the canteen", "sweeping the Great Plaza", "tending the barracks", "carrying water", "selling at the market", "tending the shrine", "cutting wood", "playing near home and the square"][int(p.kind)]
				var cycle := int((time + variation) / 25)
				if p.has("food_work"):
					target = p.work
					activity = {"garden": "tending seasonal vegetables", "orchard": "tending orchard and beehives", "herd": "feeding pigs, chickens and ducks", "fishery": "checking pond nets", "hunt": "bringing game from the Eastern Hunting Grounds to the lodge", "logs": "gathering mushrooms from the forest logs", "kitchen": "cooking, drying and pickling in the village kitchen"}[p.food_work]
				elif p.kind == 4:
					target = well if cycle % 2 == 0 else (p.home if cycle % 4 == 1 else people[n % 8].work)
				elif p.kind == 7 and cycle % 2:
					target = p.home
					activity = "bringing logs home"
				elif p.kind == 8:
					target = nearest((p.home if cycle % 2 else square) + Vector2i((cycle + n) % 7 - 3, (cycle * 3 + n) % 7 - 3))
		if p.has("material_work") and activity not in ["sleeping at home", "preparing for the day", "eating a midday meal", "resting in the evening"]:
			var trade: String = p.material_work
			if time >= 840:
				target = material_places[trade]
				activity = "working at " + trade
				if trade == "quarry" and economy.day % 3 == 0:
					target = material_places.clay
					activity = "digging clay beside the water"
				if trade == "woodcutting" and economy.season() == 2:
					activity = "stacking firewood for winter"
				if trade == "weaver":
					activity = "harvesting late-summer hemp" if economy.day >= 153 and economy.day <= 182 else "weaving cloth and twisting rope"
				if trade in ["quarry", "mine"] and economy.season() == 3:
					target = material_places.smith
					activity = "winter maintenance in the smithy"
		p.carrying = false
		if activity.begins_with("weeding"):
			activity = ["planting the paddies", "tending the paddies", "harvesting the paddies", "repairing tools and gathering firewood"][economy.season()]
			if economy.season() == 2 and int(time / 45 + n) % 2 == 0:
				target = granary
				p.carrying = true
				activity = "carrying rice to the granary"
		var harvest_time := economy.season() == 2 and economy.harvest > 0.0
		if harvest_time and int(p.hunger) >= 2 and int(p.kind) != 8 and time >= 390 and time < 1080:
			# Hungry hands of every trade join the harvest.
			if not activity.begins_with("carrying") and not activity.begins_with("harvesting"):
				target = nearest(sect.center + Vector2i(-95 + n % 6 * 4, 190 + n % 4 * 3))
				activity = "helping with the harvest"
		elif int(p.hunger) >= 3 and time >= 390 and time < 1080:
			target = nearest(sect.center + Vector2i(80 + n % 5 * 2, 245))
			activity = "foraging along the forest edge"
			p.carrying = false
		p.activity = activity
		if speed >= 64:
			p.destination = target
			p.pos = Vector2(target)
			p.path = PackedVector2Array()
			p.step = 0
			p.hidden = activity == "sleeping at home"
			continue
		if initial or target != p.destination or (p.path.is_empty() and Vector2(p.pos) != Vector2(target)):
			p.destination = target
			var start := nearest(Vector2i(Vector2(p.pos).round()))
			var key := Vector4i(start.x, start.y, target.x, target.y)
			if not routes.has(key):
				if routes.size() >= 512:
					routes.clear()
				routes[key] = grid.get_point_path(start, target)
			p.path = routes[key]
			p.step = 0
			if initial:
				p.pos = Vector2(target)
				p.step = p.path.size()
		p.hidden = activity == "sleeping at home" and Vector2(p.pos).distance_to(Vector2(p.home)) < 0.1


func _process(dt: float) -> void:
	var elapsed := 0.0 if paused else dt * speed
	minutes += elapsed * 2.4
	var was_crisis: bool = economy.crisis
	economy.advance_to(minutes)
	if economy.pause_on_crisis and economy.crisis and not was_crisis:
		paused = true
	var schedule_tick := int(minutes / 720.0) if speed >= 64 else int(minutes)
	if schedule_tick != last_minute:
		last_minute = schedule_tick
		_refresh()
	for p: Dictionary in people:
		var distance: float = elapsed * 1.5 * economy.EFFECT[int(p.hunger)] if speed < 64 else 0.0
		var path: PackedVector2Array = p.path
		while distance > 0 and int(p.step) < path.size():
			var next: Vector2 = path[int(p.step)]
			var gap := Vector2(p.pos).distance_to(next)
			if gap <= distance:
				p.pos = next
				p.step += 1
				distance -= gap
			else:
				p.pos = Vector2(p.pos).move_toward(next, distance)
				distance = 0
		p.hidden = p.activity == "sleeping at home" and Vector2(p.pos).distance_squared_to(Vector2(p.home)) < 0.01
	visible = world.on_ground
	if visible:
		queue_redraw()


func point(p: Dictionary) -> Vector2:
	var tile := Vector2i(Vector2(p.pos).round())
	var i: int = sect.index_at(tile)
	return (Vector2(p.pos) + Vector2.ONE * 0.5) * 32.0 - Vector2(0, heights[i] * world.ground.exaggeration if i >= 0 else 0)


func _draw() -> void:
	var camera: Camera2D = world.ground_view.cam
	var area := Rect2(camera.position - get_viewport_rect().size / camera.zoom / 2.0, get_viewport_rect().size / camera.zoom).grow(64)
	# A soft pulse on the qi-rich shoots, using the same world projection as people.
	for field: Dictionary in sect.data.fields:
		if economy.goods[field.crop].grade != "spirit":
			continue
		for y in range(int(field.rect[1]), int(field.rect[1]) + int(field.rect[3]), 2):
			for x in range(int(field.rect[0]), int(field.rect[0]) + int(field.rect[2]), 2):
				var tile: Vector2i = sect.center + Vector2i(x, y)
				var at := (Vector2(tile) + Vector2.ONE * 0.5) * 32 - Vector2(0, world.ground.terrace_level(tile) * world.ground.exaggeration)
				if area.has_point(at):
					draw_circle(at, 4, Color(0.3, 0.95, 0.85, 0.18 + 0.08 * sin(minutes + x + y)))
	_draw_food_places(area)
	_draw_material_places(area)
	draw_order.sort_custom(_feet_before)
	for p: Dictionary in draw_order:
		var at := point(p)
		if p.hidden or not area.has_point(at):
			continue
		var size := Vector2.ONE * (22.4 if p.kind == 8 else 32.0)
		var phase := minutes * 5 + int(p.age)
		at.y -= absf(sin(phase)) * 1.5
		var index := 108 if sin(phase * 0.3) > 0 else 109
		draw_texture_rect_region(atlas, Rect2(at - Vector2(size.x / 2, size.y), size), Rect2((index % 12) * 16, (index / 12) * 16, 16, 16), p.tint)

		if p.get("carrying", false):
			draw_texture_rect_region(atlas, Rect2(at - Vector2(8, size.y + 12), Vector2(16, 16)), Rect2(0, 128, 16, 16))


func _feet_before(a: Dictionary, b: Dictionary) -> bool:
	return point(a).y < point(b).y


func hover(at: Vector2) -> int:
	for n in people.size():
		if not people[n].hidden and Rect2(point(people[n]) - Vector2(14, 32), Vector2(28, 36)).has_point(at):
			return n
	return -1


func activity_text(p: Dictionary) -> String:
	if int(p.step) < p.path.size():
		return "walking home" if p.destination == p.home else "walking to work" if p.destination == p.work else "walking through the village"
	return str(p.activity)


func clock_text() -> String:
	var absolute_day := int(minutes / 1440)
	var day := absolute_day % 365 + 1
	var season := 0 if day <= 91 else (1 if day <= 182 else (2 if day <= 273 else 3))
	return "Year %d · %s %d · %02d:%02d" % [absolute_day / 365 + 1, economy.SEASONS[season], day - [0, 91, 182, 273][season], int(minutes / 60) % 24, int(minutes) % 60]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			paused = not paused
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]:
			speed = [1.0, 4.0, 16.0, 64.0, 256.0, 1024.0, 4096.0][event.keycode - KEY_1]
			get_viewport().set_input_as_handled()


func _headless_sim() -> void:
	set_process(false)
	var years := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--years="):
			years = maxi(1, int(arg.trim_prefix("--years=")))
	for y in years:
		economy.advance_to((y * 365 + 199) * 1440.0)
		for group: String in ["grains", "vegetables", "fruit", "meat", "fish", "pantry", "wood", "earth", "metal", "fibre", "other_materials"]:
			print("DAY200 Year %d %s: %.2f %s" % [y + 1, group, economy.quantity(group) * 2, "jin / pieces" if group in ["wood", "earth", "metal", "fibre", "other_materials"] else "jin"])
		for id: String in economy.descendants("materials"):
			if economy.goods[id].grade == "mortal":
				print("DAY200 Year %d %s: %.2f %s" % [y + 1, id, float(economy.stocks[id]) * 2, economy.goods[id].unit])
		economy.advance_to((y + 1) * 365 * 1440.0)
	for summary: String in economy.summaries:
		print(summary)
	for entry: String in economy.chronicle:
		print(entry)
	get_tree().quit()

# Small foreground decorations bypass chunk rasterization entirely.
func _setup_food_places() -> void:
	for plan: Dictionary in sect.data.food_sites:
		var at := nearest(sect.center + Vector2i(int(plan.at[0]), int(plan.at[1])))
		# Nearest valid path point keeps every trade reachable on natural terrain.
		food_places[plan.id] = at
		food_patches.append({"kind": plan.id, "tile": at})
		if plan.id != "hunt":
			sect.labels.append({"name": plan.name, "tile": at})
	# Claim complete dry footprints once; drawing never touches chunk baking.
	var occupied: Dictionary = {}
	for patch: Dictionary in food_patches:
		var size := Vector2i(5, 3) if patch.kind == "garden" else (Vector2i(12, 10) if patch.kind == "orchard" else Vector2i(4, 3))
		patch.tiles = _food_footprint(patch.tile, size, occupied)
	for offset: Vector2i in [Vector2i(8, 0), Vector2i(0, 8)]:
		food_patches.append({"kind": "garden", "tile": food_places.garden + offset, "tiles": _food_footprint(food_places.garden + offset, Vector2i(5, 3), occupied)})
	for n in range(0, 64, 8):
		var b: Dictionary = sect.data.village[n]
		var at: Vector2i = sect.center + Vector2i(int(b.rect[0]) - 3, int(b.rect[1]) + 2)
		food_patches.append({"kind": "garden", "tile": at, "tiles": _food_footprint(at, Vector2i(2, 2), occupied)})

func _food_footprint(origin: Vector2i, size: Vector2i, occupied: Dictionary, max_slope: int = -1) -> Array[Vector2i]:
	for radius in range(25):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var tiles: Array[Vector2i] = []
				var valid := true
				for y in size.y:
					for x in size.x:
						var at := origin + Vector2i(dx + x, dy + y)
						var i: int = sect.index_at(at)
						if i < 0 or occupied.has(at) or sect.surface_at(at) not in ["", "grass", "garden"] or sect.art[i] >= 0 or not sect.dry.call(at):
							valid = false
						tiles.append(at)
				if valid and max_slope >= 0:
					var low := 1000
					var high := -1000
					for tile: Vector2i in tiles:
						var level: int = world.ground.terrace_level(tile)
						low = mini(low, level)
						high = maxi(high, level)
					valid = high - low <= max_slope
				if valid:
					for at: Vector2i in tiles:
						occupied[at] = true
					return tiles
	return []

func _food_point(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2.ONE * 0.5) * 32 - Vector2(0, heights[sect.index_at(tile)] * world.ground.exaggeration)

func _draw_food_places(area: Rect2) -> void:
	for patch: Dictionary in food_patches:
		var at := (_food_point(patch.tiles[0]) + _food_point(patch.tiles[-1])) * 0.5 if not patch.tiles.is_empty() else _food_point(patch.tile)
		if not area.grow(500).has_point(at):
			continue
		var brown := Color("805731")
		match str(patch.kind):
			"garden":
				for tile: Vector2i in patch.tiles:
					var pos := _food_point(tile)
					draw_rect(Rect2(pos - Vector2(16, 16), Vector2(32, 32)), Color("936440"))
					for row in 3:
						for col in 3:
							var crop := Color(["78a64c", "c1b476", "c68d43", "598745"][posmod(tile.x + tile.y, 4)])
							draw_rect(Rect2(pos + Vector2(col * 10 - 13, row * 10 - 12), Vector2(7, 5)), crop if economy.season() != 3 else Color("b3a577"))
			"orchard":
				for i in patch.tiles.size():
					if i % 12 % 2 != 0 or i / 12 % 2 != 0:
						continue
					var pos := _food_point(patch.tiles[i]) + Vector2(1, 32)
					draw_rect(Rect2(pos - Vector2(3, 20), Vector2(6, 24)), brown)
					draw_circle(pos - Vector2(0, 29), 17, Color("527b43") if economy.season() != 3 else Color("82785d"))
					if economy.season() != 3:
						for j in 5:
							draw_circle(pos + Vector2(j * 6 - 12, -28 + j % 2 * 7), 3, Color("f2c7cd") if economy.season() == 0 else Color("e8a268"))
			"herd", "fishery":
				for tile: Vector2i in patch.tiles:
					var pos := _food_point(tile)
					draw_rect(Rect2(pos - Vector2(15, 15), Vector2(30, 30)), Color("61949b") if patch.kind == "fishery" else Color("95744c"))
					draw_line(pos - Vector2(15, 14), pos + Vector2(15, -14), brown, 2)
					draw_line(pos - Vector2(14, 15), pos + Vector2(-14, 15), brown, 2)
					if patch.kind == "herd":
						draw_circle(pos, 5, Color("d4a599") if tile.x % 2 == 0 else Color("efdfbd"))
					else:
						draw_line(pos - Vector2(12, 12), pos + Vector2(12, 12), Color("c4c3a0"), 1)
				draw_rect(Rect2(at - Vector2(26, 18), Vector2(52, 36)), Color("61949b") if patch.kind == "fishery" else Color("95744c"))
				for i in 5:
					var pos := at + Vector2(i * 10 - 22, -16)
					draw_line(pos, pos + Vector2(0, 32), brown if patch.kind == "herd" else Color("c4c3a0"), 2)
				if patch.kind == "herd":
					draw_rect(Rect2(at + Vector2(-18, -5), Vector2(15, 9)), Color("d4a599"))
					draw_rect(Rect2(at + Vector2(8, -4), Vector2(7, 6)), Color("efdfbd"))
					draw_rect(Rect2(at + Vector2(28, -5), Vector2(25, 18)), Color("61949b"))
					draw_rect(Rect2(at + Vector2(33, 0), Vector2(8, 5)), Color("eee4bf"))
					draw_rect(Rect2(at + Vector2(-18, -33), Vector2(22, 13)), brown)
				else:
					for i in 3:
						draw_line(at + Vector2(-24, i * 10 - 12), at + Vector2(24, i * 10 - 12), Color("c4c3a0"), 1)
			"logs":
				for i in 4:
					var pos := at + Vector2(i % 2 * 24, i / 2 * 16)
					draw_rect(Rect2(pos, Vector2(20, 7)), brown)
					draw_rect(Rect2(pos + Vector2(5, -4), Vector2(7, 5)), Color("c0aa89"))
			"kitchen":
				draw_rect(Rect2(at - Vector2(22, 25), Vector2(44, 25)), Color("bca174"))
				draw_rect(Rect2(at - Vector2(26, 32), Vector2(52, 9)), Color("795245"))
				for i in 5:
					draw_rect(Rect2(at + Vector2(i * 9 - 20, 4), Vector2(6, 9)), Color("a97945"))

			"hunt":
				# A game drying rack beside the existing lodge destination.
				for x in [-20, 20]:
					draw_rect(Rect2(at + Vector2(x, -28), Vector2(3, 32)), brown)
				draw_line(at + Vector2(-20, -26), at + Vector2(23, -26), brown, 3)
				for i in 4:
					draw_line(at + Vector2(i * 10 - 14, -26), at + Vector2(i * 10 - 14, -19), Color("c3b492"), 1)
					draw_rect(Rect2(at + Vector2(i * 10 - 17, -19), Vector2(6, 11)), Color("b4775e"))

func _setup_material_places() -> void:
	var occupied: Dictionary = {}
	for patch: Dictionary in food_patches:
		for tile: Vector2i in patch.tiles: occupied[tile] = true
	for plan: Dictionary in sect.data.material_sites:
		var origin: Vector2i = sect.center + Vector2i(int(plan.at[0]), int(plan.at[1]))
		var tiles := _food_footprint(origin, Vector2i(6, 4), occupied, 2)
		assert(not tiles.is_empty(), "No dry material footprint: " + str(plan.id))
		var low := 1000
		var high := -1000
		for tile: Vector2i in tiles:
			var level: int = world.ground.terrace_level(tile)
			low = mini(low, level)
			high = maxi(high, level)
		assert(high - low <= 3, "Unsafe worksite slope: " + str(plan.id))
		var at := nearest(tiles[0])
		assert(Vector2(at).distance_to(Vector2(tiles[0])) <= 8, "Workplace too far from material site")
		material_places[plan.id] = at
		material_patches.append({"kind": plan.id, "tiles": tiles, "tile": at})
		sect.labels.append({"name": plan.name, "tile": tiles[0]})
		print("MATERIAL SITE %s: %s levels %d..%d dry tiles %d" % [plan.id, tiles[0] - sect.center, low, high, tiles.size()])

func _draw_material_places(area: Rect2) -> void:
	for patch: Dictionary in material_patches:
		var at := (_food_point(patch.tiles[0]) + _food_point(patch.tiles[-1])) * 0.5
		if not area.grow(500).has_point(at): continue
		var timber := Color("795336")
		var rock := Color("99988b")
		for tile: Vector2i in patch.tiles:
			draw_rect(Rect2(_food_point(tile) - Vector2(16, 16), Vector2(32, 32)), Color("8d785b"))
		match str(patch.kind):
			"woodcutting":
				for x in [-65, 65]:
					draw_rect(Rect2(at + Vector2(x - 8, -30), Vector2(16, 14)), timber)
					draw_circle(at + Vector2(x, -30), 9, Color("c69b69"))
					draw_arc(at + Vector2(x, -30), 5, 0, TAU, 12, timber, 1)
				for i in 5:
					var pos := at + Vector2(i * 24 - 50, i % 2 * 24)
					draw_rect(Rect2(pos, Vector2(25, 10)), timber)
					draw_circle(pos, 6, Color("c69b69"))
				draw_line(at + Vector2(-20, -25), at + Vector2(20, -25), timber, 6)
				for x in [-15, 15]: draw_line(at + Vector2(x, -25), at + Vector2(x * 1.5, 0), timber, 4)
			"quarry", "mine":
				draw_rect(Rect2(at + Vector2(-60, -45), Vector2(120, 30)), rock)
				for i in 4: draw_rect(Rect2(at + Vector2(i * 26 - 50, 10), Vector2(22, 16)), rock.lightened(0.15))
				if patch.kind == "mine":
					draw_rect(Rect2(at + Vector2(-18, -42), Vector2(36, 32)), Color("292c2d"))
					for x in [-40, 20]:
						draw_rect(Rect2(at + Vector2(x, 0), Vector2(25, 14)), timber)
						draw_circle(at + Vector2(x + 5, 16), 4, Color("454848"))
						draw_circle(at + Vector2(x + 20, 16), 4, Color("454848"))
						draw_circle(at + Vector2(x + 12, 1), 6, rock.darkened(0.25))
				else:
					draw_line(at + Vector2(35, -65), at + Vector2(15, 5), timber, 4)
					draw_line(at + Vector2(35, -65), at + Vector2(60, 5), timber, 4)
					draw_line(at + Vector2(35, -65), at + Vector2(35, -5), Color("d3c7a3"), 2)
			"clay":
				_draw_material_pit(at, Color("aa7654"))
			"kiln", "smith":
				for x in [-35, 25]:
					draw_circle(at + Vector2(x, 0), 22, Color("55554c") if x < 0 and patch.kind == "kiln" else Color("aa7352"))
					draw_rect(Rect2(at + Vector2(x - 7, -8), Vector2(14, 18)), Color("302e2c"))
					draw_rect(Rect2(at + Vector2(x - 3, 0), Vector2(6, 8)), Color("e29b45"))
			"weaver":
				draw_rect(Rect2(at + Vector2(-32, -60), Vector2(64, 30)), timber)
				draw_rect(Rect2(at + Vector2(-37, -65), Vector2(74, 8)), Color("8e6547"))
				for i in 12:
					var pos := at + Vector2(i % 6 * 20 - 60, i / 6 * 24)
					draw_line(pos, pos - Vector2(0, 26), Color("648348"), 3)
					draw_line(pos - Vector2(8, 15), pos + Vector2(8, -22), Color("789950"), 3)
				draw_rect(Rect2(at + Vector2(-25, -58), Vector2(50, 22)), timber)
				for i in 10: draw_line(at + Vector2(i * 4 - 18, -55), at + Vector2(i * 4 - 18, -37), Color("e2d3a2"), 1)
			"tanner":
				for x in [-40, 0, 40]:
					draw_rect(Rect2(at + Vector2(x - 12, -30), Vector2(24, 38)), timber, false, 3)
					draw_rect(Rect2(at + Vector2(x - 8, -25), Vector2(16, 26)), Color("b59a72"))

func _draw_material_pit(at: Vector2, colour: Color) -> void:
	draw_set_transform(at, 0, Vector2(2, 1))
	draw_circle(Vector2.ZERO, 25, colour)
	draw_set_transform(Vector2.ZERO)
