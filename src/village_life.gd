extends Node2D
## Deterministic mortals. Routes are planned only when a schedule destination changes.
var draw_order: Array[Dictionary] = []
var world: Node2D
var sect: RefCounted
var grid := AStarGrid2D.new()
var people: Array[Dictionary] = []
var population := preload("res://src/population.gd").new()
const WALKER_LIMIT := 100
var nearby_views: Dictionary = {}
var view_cell := Vector2i(-999999, -999999)
var routes: Dictionary = {}
var minutes := 300.0
var economy := preload("res://src/grain_economy.gd").new()
var granary: Vector2i
var skip_next_day := 0
var skip_target := 0
var skip_start := 0
var skip_was_paused := false
var speed := 1.0
var paused := false
var last_minute := -1
var followed := -1
var atlas: Texture2D
var person_art: Array[ImageTexture] = []
var child_art: Array[ImageTexture] = []
## Population id of the villager the card is showing, ringed on the map.
var selected := -1
## The first twenty as they arrived; a fresh twenty is sent from these if the valley ever empties.
var founders: Array[Dictionary] = []
const LANES := ["earth", "paving", "bridge"]
## Tiles on a bank that walkers may not cross (unless a ramp is cut there).
var cliffs: Dictionary = {}
var tended_day := -1
var heights := PackedInt32Array()
var square: Vector2i
var well: Vector2i
var food_places: Dictionary = {}
var food_patches: Array[Dictionary] = []
var material_patches: Array[Dictionary] = []
var material_places: Dictionary = {}
var shrine: Vector2i
const Palette = preload("res://src/palette.gd")


func setup(map: Node2D) -> void:
	world = map
	sect = map.ground.sect
	z_index = 1000
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sheet := Palette.atlas("tiny-farm", Palette.THING)
	atlas = ImageTexture.create_from_image(sheet)
	# Everyone shares one texel size; a child is the same art with a shorter body.
	for frame in [108, 109]:
		person_art.append(ImageTexture.create_from_image(Palette.outlined(sheet, frame)))
		child_art.append(ImageTexture.create_from_image(Palette.outlined(sheet, frame, [4, 11, 12])))
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
	# Terrace faces and natural banks are cliffs: nobody walks up them. Stairs join the built terraces;
	# where a lane crosses a one-step bank, a ramp of earth steps is cut into it.
	var pairs: Array = []
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			if grid.is_point_solid(at) or sect.surface_at(at) == "stairs":
				continue
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var other := at + offset
				if not grid.is_in_boundsv(other) or grid.is_point_solid(other) or sect.surface_at(other) == "stairs": continue
				var step := absi(heights[sect.index_at(at)] - heights[sect.index_at(other)])
				if step == 0: continue
				if step == 1 and sect.level_at(at) < 0 and sect.level_at(other) < 0 and (sect.surface_at(at) in LANES or sect.surface_at(other) in LANES):
					sect.ramps[at] = true
					sect.ramps[other] = true
				else:
					pairs.append([at, other])
	# Each cliff blocks one side: the one that is not a ramp for some other crossing.
	for pair: Array in pairs:
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		if grid.is_point_solid(a) or grid.is_point_solid(b) or (sect.ramps.has(a) and sect.ramps.has(b)): continue
		var block: Vector2i = b if sect.ramps.has(a) else a
		cliffs[block] = true
		grid.set_point_solid(block)
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
	# Twenty orphans from twenty families: housemates are friends, not kin.
	var families := ["Wang", "Li", "Zhang", "Liu", "Chen", "Yang", "Zhao", "Huang", "Zhou", "Wu", "Xu", "Sun", "Hu", "Zhu", "Gao", "Lin", "He", "Guo", "Ma", "Luo"]
	var given := ["Erniu", "Cuihua", "Dazhi", "Xiaolan", "Shan", "Mei", "Yong", "Lian", "Bao", "Qing", "An", "Xiu", "Fu", "Lan", "Ping", "Hua", "Song", "Yun", "Xiaohu", "Xiaoyu"]
	var jobs := ["field hand", "canteen cook", "plaza sweeper", "barracks attendant", "water carrier", "market vendor", "shrine keeper", "woodcutter", "child"]
	for n in 20:
		var household := n / 3 if n < 12 else (4 + (n - 12) / 2 if n < 18 else 4 + n - 18)
		var b: Dictionary = sect.data.village[household * 8]
		var home := nearest(sect.center + Vector2i(int(b.rect[0]) + 2, int(b.rect[1]) + int(b.rect[3])))
		var job := 0 if n < 8 else (n - 7 if n < 11 else (4 if n < 13 else (5 if n < 15 else (6 if n == 15 else (7 if n < 18 else 4)))))
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
		people.append({"name": families[n] + " " + given[n], "sex": "female" if n % 2 else "male", "age": 12, "home_cottage": household * 8, "home": home, "job": jobs[job], "kind": job, "work": work, "pos": Vector2(home), "destination": Vector2i(-999, -999), "path": PackedVector2Array(), "step": 0, "hidden": true, "activity": "sleeping at home", "tint": Color.from_hsv(rng.randf_range(0.05, 0.65), rng.randf_range(0.1, 0.28), rng.randf_range(0.85, 1.0))})
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
	for p: Dictionary in people: founders.append(p.duplicate(true))
	_link_levels()
	population.seed_residents(people)
	var archive_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/archive.json"))
	if archive_settings.enabled and not "--no-archive" in OS.get_cmdline_user_args():
		var society: RefCounted = population.society
		society.archive = preload("res://src/archive.gd").new(population, int(sect.data.seed))
		for record: Dictionary in society.chronicle: society.archive.event(record.day, record.person, record.kind, record.text)
	economy.population = population
	economy.setup(sect.data, people, int(world.data.get("seed", sect.data.seed)))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="):
			minutes += (clampi(int(arg.trim_prefix("--day=")), 1, 365) - 1) * 1440.0
		if arg.begins_with("--time="):
			var parts := arg.trim_prefix("--time=").split(":")
			if parts.size() == 2:
				minutes = floorf(minutes / 1440.0) * 1440.0 + clampi(int(parts[0]), 0, 23) * 60 + clampi(int(parts[1]), 0, 59)
	economy.advance_to(minutes)
	var skip_requested := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--skip-years="):
			skip_requested = true
			start_skip(maxi(1, int(arg.trim_prefix("--skip-years="))))
	if "--headless-sim" in OS.get_cmdline_user_args() or (skip_requested and DisplayServer.get_name() == "headless"):
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
	if day != tended_day:
		tended_day = day
		_tend_the_dead()
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
					target = well if cycle % 2 == 0 else (p.home if cycle % 4 == 1 else people[n % mini(8, people.size())].work)
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
	if skip_target > 0:
		_process_skip()
		return
	var elapsed := 0.0 if paused else dt * speed
	minutes += elapsed * 2.4
	var was_crisis: bool = economy.crisis
	economy.advance_to(minutes)
	if population.size() > 1000:
		population.async_factions = true
		if population.pending_day < 0 and population.day < int(minutes / 1440):
			population.begin_day(population.day + 1)
		var budget_start := Time.get_ticks_usec()
		while population.pending_day >= 0 and Time.get_ticks_usec() - budget_start < 2000:
			population.process_batch(32)
			if population.society.faction_pending: break
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
		_refresh_population_views()
		queue_redraw()


func point(p: Dictionary) -> Vector2:
	# Height blends between neighbouring tiles, so a walker climbs a ramp instead of popping up a level.
	var pos := Vector2(p.pos)
	var base := Vector2i(pos.floor())
	var f := pos - Vector2(base)
	var level := 0.0
	var total := 0.0
	for corner: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
		var at := base + corner
		var i: int = sect.index_at(at)
		if i < 0 or not grid.is_in_boundsv(at) or grid.is_point_solid(at): continue
		var weight := (f.x if corner.x else 1.0 - f.x) * (f.y if corner.y else 1.0 - f.y)
		level += weight * heights[i]
		total += weight
	if total <= 0.0:
		var own: int = sect.index_at(Vector2i(pos.round()))
		return (pos + Vector2.ONE * 0.5) * 32.0 - Vector2(0, (heights[own] if own >= 0 else 0) * world.ground.exaggeration)
	return (pos + Vector2.ONE * 0.5) * 32.0 - Vector2(0, level / total * world.ground.exaggeration)


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
	draw_order = people.duplicate()
	for p: Dictionary in nearby_views.values(): draw_order.append(p)
	draw_order.sort_custom(_feet_before)
	var drawn := 0
	for p: Dictionary in draw_order:
		var at := point(p)
		if p.hidden or not area.has_point(at):
			continue
		if drawn >= WALKER_LIMIT: break
		drawn += 1
		var child: bool = p.kind == 8 or population.age(int(p.get("id", 0))) < 16
		var phase := minutes * 5 + int(p.age)
		if int(p.get("id", -1)) == selected:
			draw_arc(at - Vector2(0, 2), 15, 0, TAU, 24, Palette.OUTLINE, 5)
			draw_arc(at - Vector2(0, 2), 15, 0, TAU, 24, Palette.GOLD, 3)
		at.y -= roundf(absf(sin(phase)))
		var frame := 0 if sin(phase * 0.3) > 0 else 1
		draw_texture_rect((child_art if child else person_art)[frame], Rect2(at - Vector2(18, 34), Vector2(36, 36)), false, p.tint)
		if p.get("carrying", false):
			draw_texture_rect_region(atlas, Rect2(at - Vector2(16, (28 if child else 34) + 26), Vector2(32, 32)), Rect2(0, 128, 16, 16))


func _feet_before(a: Dictionary, b: Dictionary) -> bool:
	return point(a).y < point(b).y


func hover(at: Vector2) -> int:
	for n in people.size():
		if not people[n].hidden and Rect2(point(people[n]) - Vector2(14, 32), Vector2(28, 36)).has_point(at):
			return n
	return -1


## Whoever stands under the pointer, as a population id. Walkers first, then the neighbours drawn around them.
func pick(at: Vector2) -> int:
	var best := -1
	var feet := -INF
	for p: Dictionary in people + nearby_views.values():
		if p.hidden: continue
		var here := point(p)
		if Rect2(here - Vector2(18, 36), Vector2(36, 42)).has_point(at) and here.y > feet:
			feet = here.y
			best = int(p.get("id", -1))
	return best


## The dead stop walking and eating. If nobody is left, twenty new twelve-year-olds are sent down to the valley.
func _tend_the_dead() -> void:
	var society: RefCounted = population.society
	var changed := false
	for n in range(people.size() - 1, -1, -1):
		if not society.alive[int(people[n].id)]:
			people.remove_at(n)
			changed = true
	if society.alive.count(1) == 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(sect.data.seed) + population.day
		var names: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/names.json"))
		var arrivals: Array[Dictionary] = []
		for founder: Dictionary in founders:
			var p: Dictionary = founder.duplicate(true)
			var pool: Array = names.female if p.sex == "female" else names.male
			p.name = str(p.name).get_slice(" ", 0) + " " + str(pool[rng.randi_range(0, pool.size() - 1)])
			p.erase("id")
			p.hunger = 0
			p.diet_variety = 0
			p.contentment = 0.6
			p.mood = "content"
			p.foraged = 0.0
			p.rice_today = 0.0
			arrivals.append(p)
		population.seed_residents(arrivals)
		people.append_array(arrivals)
		society.note(int(arrivals[0].id), "arrival", "The valley stood empty; twenty new servants, all twelve years old, were sent down to it")
		changed = true
	if changed:
		if followed >= people.size(): followed = -1
		economy.walkers_changed()
		routes.clear()


## Every home and workplace must be reachable from the square. Where a bank cuts one off,
## a ramp is cut at the crossing that needs the fewest cliff tiles opened.
func _link_levels() -> void:
	var targets: Array[Vector2i] = [square, well, granary, shrine]
	for p: Dictionary in people:
		targets.append(p.home)
		targets.append(p.work)
	for place: Variant in food_places.values() + material_places.values():
		if place is Vector2i: targets.append(place)
	var region := grid.region
	var cost := PackedInt32Array()
	cost.resize(region.size.x * region.size.y)
	cost.fill(1 << 30)
	var came := PackedInt32Array()
	came.resize(cost.size())
	came.fill(-1)
	var index := func(at: Vector2i) -> int: return (at.y - region.position.y) * region.size.x + at.x - region.position.x
	# 0-1 search from the square: open ground costs nothing, crossing a cliff tile costs one.
	var front: Array[Vector2i] = [square]
	var back: Array[Vector2i] = []
	cost[index.call(square)] = 0
	while not front.is_empty() or not back.is_empty():
		if front.is_empty():
			front = back
			back = []
		var at: Vector2i = front.pop_back()
		var here: int = cost[index.call(at)]
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := at + offset
			if not grid.is_in_boundsv(next): continue
			var open := not grid.is_point_solid(next)
			if not open and not cliffs.has(next): continue
			var step := here + (0 if open else 1)
			var i: int = index.call(next)
			if step >= cost[i]: continue
			cost[i] = step
			came[i] = index.call(at)
			if open: front.append(next)
			else: back.append(next)
	var carved := 0
	for target: Vector2i in targets:
		if not grid.is_in_boundsv(target) or cost[index.call(target)] == 0: continue
		var i: int = index.call(target)
		while i >= 0:
			var at := Vector2i(i % region.size.x + region.position.x, i / region.size.x + region.position.y)
			if grid.is_point_solid(at) and cliffs.has(at):
				grid.set_point_solid(at, false)
				sect.ramps[at] = true
				for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if cliffs.has(at + offset) or not grid.is_point_solid(at + offset): sect.ramps[at + offset] = true
				carved += 1
			i = came[i]
	# The ground may have been drawn before the ramps were known.
	if carved > 0 or not sect.ramps.is_empty(): world.ground.set_exaggeration(world.ground.exaggeration)


func walker_of(id: int) -> int:
	for n in people.size():
		if int(people[n].id) == id: return n
	return -1


## Where a person stands in the world, whether or not they are being drawn.
func place_of(id: int) -> Vector2:
	var walker := walker_of(id)
	if walker >= 0: return point(people[walker])
	return point({"pos": population.locations[id]})


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


func start_skip(years: int) -> void:
	if skip_target > 0: return
	skip_next_day = 0
	skip_start = population.day
	skip_target = skip_start + years * 365
	skip_was_paused = paused
	economy.coarse_population = true

func cancel_skip() -> void:
	if skip_next_day > 0:
		skip_target = skip_next_day
		return
	if population.pending_day >= 0:
		skip_target = population.pending_day
		return
	skip_target = 0
	economy.coarse_population = false
	paused = skip_was_paused

func _skip_week(target_day: int) -> void:
	var next_day := mini(target_day, population.day + 7)
	economy.advance_to(next_day * 1440.0)
	population.tick_span(next_day)
	minutes = next_day * 1440.0

func _process_skip() -> void:
	population.async_factions = population.size() > 1000
	var began := Time.get_ticks_usec()
	while skip_target > 0 and Time.get_ticks_usec() - began < 2000:
		if population.pending_day < 0:
			if skip_next_day == 0: skip_next_day = mini(skip_target, population.day + 7)
			var target_minutes := skip_next_day * 1440.0
			if economy.next_event <= target_minutes:
				economy.advance_to(economy.next_event)
				return
			population.tick_days = skip_next_day - population.day
			population.begin_day(skip_next_day)
		if population.society.faction_pending: return
		if population.process_batch(16):
			skip_next_day = 0
			population.tick_days = 1
			minutes = population.day * 1440.0
			if population.day >= skip_target: cancel_skip()

func _headless_sim() -> void:
	set_process(false)
	population.async_factions = false
	var years := 1
	var coarse := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--years="): years = maxi(1, int(arg.trim_prefix("--years=")))
		if arg.begins_with("--skip-years="):
			years = maxi(1, int(arg.trim_prefix("--skip-years=")))
			coarse = true
	economy.coarse_population = coarse
	print("SKILLS Start: %s" % population.tier_distribution())
	for y in years:
		var target_day := (y + 1) * 365
		if coarse:
			while population.day < target_day: _skip_week(target_day)
		else: economy.advance_to(target_day * 1440.0)
		if (y + 1) % 10 == 0 or y == years - 1:
			print("DECADE %d SKILLS %s" % [y + 1, population.tier_distribution()])
			print("DECADE %d SOCIETY %s" % [y + 1, JSON.stringify(population.society.summary())])
			var mind: RefCounted = population.society.mind
			if mind:
				var mix: Dictionary = {}
				for i in mind.OPTION_NAMES.size(): mix[mind.OPTION_NAMES[i]] = mind.choice_counts[i]
				print("DECADE %d MIND decisions=%d ms=%d %s" % [y + 1, mind.decisions, mind.decide_usec / 1000, JSON.stringify(mix)])
			var records: Array = population.society.top_events(maxi(0, (y - 9) * 365))
			for event: Dictionary in records:
				print("CHRONICLE day=%d %s" % [event.day, event.text])
		await get_tree().process_frame
	_close_archive()
	get_tree().quit()

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
		var brown := Palette.BRASS.darkened(0.3)
		match str(patch.kind):
			"garden":
				for tile: Vector2i in patch.tiles:
					var pos := _food_point(tile)
					draw_rect(Rect2(pos - Vector2(16, 16), Vector2(32, 32)), Palette.BRASS.darkened(0.2))
					for row in 3:
						for col in 3:
							var crop := Color(["78a64c", "c1b476", "c68d43", "598745"][posmod(tile.x + tile.y, 4)])
							draw_rect(Rect2(pos + Vector2(col * 10 - 13, row * 10 - 12), Vector2(7, 5)), crop if economy.season() != 3 else Palette.EARTH.darkened(0.05))
			"orchard":
				for i in patch.tiles.size():
					if i % 12 % 2 != 0 or i / 12 % 2 != 0:
						continue
					var pos := _food_point(patch.tiles[i]) + Vector2(1, 32)
					draw_rect(Rect2(pos - Vector2(3, 20), Vector2(6, 24)), brown)
					draw_circle(pos - Vector2(0, 29), 17, Palette.GREEN.darkened(0.05) if economy.season() != 3 else Palette.PAPER.darkened(0.45))
					if economy.season() != 3:
						for j in 5:
							draw_circle(pos + Vector2(j * 6 - 12, -28 + j % 2 * 7), 3, Palette.RED.lightened(0.7) if economy.season() == 0 else Palette.GOLD.lightened(0.2))
			"herd", "fishery":
				for tile: Vector2i in patch.tiles:
					var pos := _food_point(tile)
					draw_rect(Rect2(pos - Vector2(15, 15), Vector2(30, 30)), Palette.BLUE.lightened(0.05) if patch.kind == "fishery" else Palette.BRASS.darkened(0.15))
					draw_line(pos - Vector2(15, 14), pos + Vector2(15, -14), brown, 2)
					draw_line(pos - Vector2(14, 15), pos + Vector2(-14, 15), brown, 2)
					if patch.kind == "herd":
						draw_circle(pos, 5, Palette.RED.lightened(0.5) if tile.x % 2 == 0 else Palette.PAPER.lightened(0.1))
					else:
						draw_line(pos - Vector2(12, 12), pos + Vector2(12, 12), Palette.GRASS.lightened(0.3), 1)
				draw_rect(Rect2(at - Vector2(26, 18), Vector2(52, 36)), Palette.BLUE.lightened(0.05) if patch.kind == "fishery" else Palette.BRASS.darkened(0.15))
				for i in 5:
					var pos := at + Vector2(i * 10 - 22, -16)
					draw_line(pos, pos + Vector2(0, 32), brown if patch.kind == "herd" else Palette.GRASS.lightened(0.3), 2)
				if patch.kind == "herd":
					draw_rect(Rect2(at + Vector2(-18, -5), Vector2(15, 9)), Palette.RED.lightened(0.5))
					draw_rect(Rect2(at + Vector2(8, -4), Vector2(7, 6)), Palette.PAPER.lightened(0.1))
					draw_rect(Rect2(at + Vector2(28, -5), Vector2(25, 18)), Palette.BLUE.lightened(0.05))
					draw_rect(Rect2(at + Vector2(33, 0), Vector2(8, 5)), Palette.PAPER.lightened(0.15))
					draw_rect(Rect2(at + Vector2(-18, -33), Vector2(22, 13)), brown)
				else:
					for i in 3:
						draw_line(at + Vector2(-24, i * 10 - 12), at + Vector2(24, i * 10 - 12), Palette.GRASS.lightened(0.3), 1)
			"logs":
				for i in 4:
					var pos := at + Vector2(i % 2 * 24, i / 2 * 16)
					draw_rect(Rect2(pos, Vector2(20, 7)), brown)
					draw_rect(Rect2(pos + Vector2(5, -4), Vector2(7, 5)), Palette.PAPER.darkened(0.2))
			"kitchen":
				draw_rect(Rect2(at - Vector2(22, 25), Vector2(44, 25)), Palette.EARTH.darkened(0.05))
				draw_rect(Rect2(at - Vector2(26, 32), Vector2(52, 9)), Palette.INK_SOFT.lightened(0.05))
				for i in 5:
					draw_rect(Rect2(at + Vector2(i * 9 - 20, 4), Vector2(6, 9)), Palette.BRASS.darkened(0.05))

			"hunt":
				# A game drying rack beside the existing lodge destination.
				for x in [-20, 20]:
					draw_rect(Rect2(at + Vector2(x, -28), Vector2(3, 32)), brown)
				draw_line(at + Vector2(-20, -26), at + Vector2(23, -26), brown, 3)
				for i in 4:
					draw_line(at + Vector2(i * 10 - 14, -26), at + Vector2(i * 10 - 14, -19), Palette.PAPER.darkened(0.2), 1)
					draw_rect(Rect2(at + Vector2(i * 10 - 17, -19), Vector2(6, 11)), Palette.RED.lightened(0.25))

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
		var timber := Palette.BRASS.darkened(0.35)
		var rock := Palette.STONE.darkened(0.15)
		for tile: Vector2i in patch.tiles:
			draw_rect(Rect2(_food_point(tile) - Vector2(16, 16), Vector2(32, 32)), Palette.INK_SOFT.lightened(0.2))
		match str(patch.kind):
			"woodcutting":
				for x in [-65, 65]:
					draw_rect(Rect2(at + Vector2(x - 8, -30), Vector2(16, 14)), timber)
					draw_circle(at + Vector2(x, -30), 9, Palette.BRASS.lightened(0.15))
					draw_arc(at + Vector2(x, -30), 5, 0, TAU, 12, timber, 1)
				for i in 5:
					var pos := at + Vector2(i * 24 - 50, i % 2 * 24)
					draw_rect(Rect2(pos, Vector2(25, 10)), timber)
					draw_circle(pos, 6, Palette.BRASS.lightened(0.15))
				draw_line(at + Vector2(-20, -25), at + Vector2(20, -25), timber, 6)
				for x in [-15, 15]: draw_line(at + Vector2(x, -25), at + Vector2(x * 1.5, 0), timber, 4)
			"quarry", "mine":
				draw_rect(Rect2(at + Vector2(-60, -45), Vector2(120, 30)), rock)
				for i in 4: draw_rect(Rect2(at + Vector2(i * 26 - 50, 10), Vector2(22, 16)), rock.lightened(0.15))
				if patch.kind == "mine":
					draw_rect(Rect2(at + Vector2(-18, -42), Vector2(36, 32)), Palette.PLUM.darkened(0.65))
					for x in [-40, 20]:
						draw_rect(Rect2(at + Vector2(x, 0), Vector2(25, 14)), timber)
						draw_circle(at + Vector2(x + 5, 16), 4, Palette.STONE.darkened(0.6))
						draw_circle(at + Vector2(x + 20, 16), 4, Palette.STONE.darkened(0.6))
						draw_circle(at + Vector2(x + 12, 1), 6, rock.darkened(0.25))
				else:
					draw_line(at + Vector2(35, -65), at + Vector2(15, 5), timber, 4)
					draw_line(at + Vector2(35, -65), at + Vector2(60, 5), timber, 4)
					draw_line(at + Vector2(35, -65), at + Vector2(35, -5), Palette.PAPER.darkened(0.1), 2)
			"clay":
				_draw_material_pit(at, Palette.BRASS.darkened(0.05))
			"kiln", "smith":
				for x in [-35, 25]:
					draw_circle(at + Vector2(x, 0), 22, Palette.STONE.darkened(0.55) if x < 0 and patch.kind == "kiln" else Palette.BRASS.darkened(0.05))
					draw_rect(Rect2(at + Vector2(x - 7, -8), Vector2(14, 18)), Palette.STONE.darkened(0.7))
					draw_rect(Rect2(at + Vector2(x - 3, 0), Vector2(6, 8)), Palette.GOLD)
			"weaver":
				draw_rect(Rect2(at + Vector2(-32, -60), Vector2(64, 30)), timber)
				draw_rect(Rect2(at + Vector2(-37, -65), Vector2(74, 8)), Palette.BRASS.darkened(0.2))
				for i in 12:
					var pos := at + Vector2(i % 6 * 20 - 60, i / 6 * 24)
					draw_line(pos, pos - Vector2(0, 26), Palette.GREEN.lightened(0.05), 3)
					draw_line(pos - Vector2(8, 15), pos + Vector2(8, -22), Palette.GREEN.lightened(0.15), 3)
				draw_rect(Rect2(at + Vector2(-25, -58), Vector2(50, 22)), timber)
				for i in 10: draw_line(at + Vector2(i * 4 - 18, -55), at + Vector2(i * 4 - 18, -37), Palette.PAPER.darkened(0.05), 1)
			"tanner":
				for x in [-40, 0, 40]:
					draw_rect(Rect2(at + Vector2(x - 12, -30), Vector2(24, 38)), timber, false, 3)
					draw_rect(Rect2(at + Vector2(x - 8, -25), Vector2(16, 26)), Palette.EARTH.darkened(0.1))

func _draw_material_pit(at: Vector2, colour: Color) -> void:
	draw_set_transform(at, 0, Vector2(2, 1))
	draw_circle(Vector2.ZERO, 25, colour)
	draw_set_transform(Vector2.ZERO)

func _refresh_population_views() -> void:
	var camera: Camera2D = world.ground_view.cam
	var cell := Vector2i(camera.position / (32.0 * 32.0))
	if cell == view_cell: return
	view_cell = cell
	nearby_views.clear()
	var extent := get_viewport_rect().size / camera.zoom / 32.0
	var area := Rect2(camera.position / 32.0 - extent / 2.0, extent).grow(16)
	for person: int in population.nearby(area, WALKER_LIMIT):
		if walker_of(person) >= 0 or not population.society.alive[person]: continue
		if nearby_views.size() + people.size() >= WALKER_LIMIT: break
		nearby_views[person] = {"id": person, "name": population.names[person], "pos": population.locations[person], "kind": 8 if population.age(person) < 18 else 0, "age": population.age(person), "hidden": false, "tint": Palette.PAPER, "carrying": false}

func _close_archive() -> void:
	var society: RefCounted = population.society if population else null
	if society and society.archive:
		# A run that stops exactly on a new year closes the finished year with its snapshot.
		if population.day % 365 == 0 and society.archived_year != population.day / 365: society.archive.year_end(population.day / 365 - 1)
		society.archive.close()
		society.archive = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE: _close_archive()
