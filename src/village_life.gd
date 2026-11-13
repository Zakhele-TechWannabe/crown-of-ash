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
const GuardianArt = preload("res://src/guardian_art.gd")
var law_stages: Array[Dictionary] = []
var breaches_seen := 0
const TreeArt = preload("res://src/tree_art.gd")
const WorkplaceArt = preload("res://src/workplace_art.gd")
var workplace_sprites: Array[Dictionary] = []

const BuildingArt = preload("res://src/building_art.gd")
var tree_view: Array = []
var tree_view_key := Rect2i()
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
const Combat = preload("res://src/combat.gd")
const UiTheme = preload("res://src/ui_theme.gd")
## Fights between villagers, played on the map. The society decides them at dawn; in daylight the two meet, stand
## and trade blows (harm floats up, a bar fills over each head), then whoever breaks runs home with the other on
## their heels, yields and limps off, or falls. Staged fights hold their walkers until the scene has played.
var stages: Array[Dictionary] = []
var fights_seen := 0


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
	# where a lane crosses a one-step bank (lane on both sides), a ramp of earth steps is cut into it.
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
				if step == 1 and sect.level_at(at) < 0 and sect.level_at(other) < 0 and sect.surface_at(at) in LANES and sect.surface_at(other) in LANES:
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
	population.society.law = preload("res://src/law.gd").new()
	population.society.law.setup(sect, grid, people, world.ground)
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
		if int(p.kind) == 8 and population.age(int(p.id)) >= 12:
			for model: Dictionary in founders:
				if str(model.job) != population.jobs[population.job[int(p.id)]]: continue
				p.job = str(model.job)
				for key: String in ["kind", "work", "food_work", "material_work"]:
					if model.has(key): p[key] = model[key]
				break
		if p.get("law_scene", false): continue
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
		var id := int(p.id)
		if population.age(id) < 12:
			p.kind = 8
			p.carrying = false
			activity = population.society.childhood.activity(id)
			var watching: int = population.society.childhood.watching[id]
			var adult := walker_of(watching) if watching >= 0 else -1
			if adult >= 0 and population.society.childhood.watching_day[id] == population.day:
				target = nearest(Vector2i(people[adult].pos) + Vector2i(1, 0))
			else:
				var anchor: Vector2i = square if population.age(id) >= 6 else Vector2i(p.home)
				target = nearest(anchor + Vector2i((day + int(time / 30)) % 5 - 2 + id % 3, (day + int(time / 45)) % 5 - 2))
			if time < 360 or time >= 1200:
				target = p.home
				activity = "sleeping at home"
		var scene := _scene_for(p, target, activity)
		target = scene[0]
		activity = scene[1]
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
	_watch_fights()
	_advance_stages(elapsed)
	_advance_law(elapsed)
	var schedule_tick := int(minutes / 720.0) if speed >= 64 else int(minutes)
	if schedule_tick != last_minute:
		last_minute = schedule_tick
		_refresh()
	for p: Dictionary in people:
		var distance: float = elapsed * 1.5 * economy.EFFECT[int(p.hunger)] * float(p.get("rush", 1.0)) if speed < 64 else 0.0
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
					draw_circle(at, 4, Color(Palette.JADE, 0.18 + 0.08 * sin(minutes + x + y)))
	_draw_food_places(area)
	_draw_material_places(area)
	draw_order = people.duplicate()
	for p: Dictionary in nearby_views.values(): draw_order.append(p)
	draw_order.sort_custom(_feet_before)
	# Trees stand up off the ground: shadows first, then trees and people in order of their feet,
	# so a villager can walk behind a trunk.
	var trees := _trees_in(area.grow(256)).duplicate()
	if population.society.law:
		for g: Dictionary in population.society.law.guardians:
			for state: String in ["plinth", str(g.get("visual_state", g.state))]:
				var tile: Vector2 = Vector2(g.post) if state == "plinth" else Vector2(g.get("visual_tile", g.tile))
				var foot := (tile + Vector2.ONE * 0.5) * 32.0 - Vector2(0, world.ground.terrace_level(Vector2i(tile)) * world.ground.exaggeration)
				if area.grow(64).has_point(foot): trees.append([foot, -1, {"kind": "guardian", "state": state, "facing": g.facing, "w": 1}])
		trees.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	var shade := Color(Palette.INK, 0.22)
	for tree: Array in trees:
		if tree[1] >= 0: _shadow(tree[0] + Vector2(10, -2), TreeArt.SHADOW[tree[1]] * 2.0, shade)
		elif str(tree[2].kind).begins_with("gate_side"):
			_shadow(tree[0] + Vector2(tree[2].w * 16 + (-16 if tree[2].kind == "gate_side_back" else 6), -2), 16.0, shade)
		else: _standing_shadow(tree[0], tree[2].w)
	for p: Dictionary in draw_order:
		if not p.hidden: _shadow(point(p) + Vector2(3, -1), 11.0, shade)
	var next_tree := 0
	var drawn := 0
	for p: Dictionary in draw_order:
		var at := point(p)
		if p.hidden or not area.has_point(at):
			continue
		while next_tree < trees.size() and trees[next_tree][0].y <= at.y:
			_tree(trees[next_tree])
			next_tree += 1
		if drawn >= WALKER_LIMIT: break
		drawn += 1
		var child: bool = p.kind == 8 or population.age(int(p.get("id", 0))) < 16
		var phase := minutes * 5 + int(p.age)
		if int(p.get("id", -1)) == selected:
			draw_arc(at - Vector2(0, 2), 15, 0, TAU, 24, Palette.OUTLINE, 5)
			draw_arc(at - Vector2(0, 2), 15, 0, TAU, 24, Palette.GOLD, 3)
		if p.get("fallen", false):
			draw_set_transform(at - Vector2(0, 6), PI / 2.0)
			draw_texture_rect((child_art if child else person_art)[0], Rect2(Vector2(-18, -18), Vector2(36, 36)), false, Color(p.tint).darkened(0.35))
			draw_set_transform(Vector2.ZERO)
			continue
		if not p.has("fighting"): at.y -= roundf(absf(sin(phase)))
		var frame := 0 if sin(phase * 0.3) > 0 or p.has("fighting") else 1
		draw_texture_rect((child_art if child else person_art)[frame], Rect2(at - Vector2(18, 34), Vector2(36, 36)), false, p.tint)
		if p.get("carrying", false):
			draw_texture_rect_region(atlas, Rect2(at - Vector2(16, (28 if child else 34) + 26), Vector2(32, 32)), Rect2(0, 128, 16, 16))
	while next_tree < trees.size():
		_tree(trees[next_tree])
		next_tree += 1
	_draw_fights(area)
	_draw_law_harm(area)


## The trees the ground has placed around the view, sorted by their feet.
func _trees_in(area: Rect2) -> Array:
	var first := Vector2i((area.position / (32.0 * 16.0)).floor())
	var last := Vector2i((area.end / (32.0 * 16.0)).floor()) + Vector2i(0, 1)
	var key := Rect2i(first, last - first)
	if key == tree_view_key: return tree_view
	tree_view_key = key
	tree_view = []
	for by in range(first.y, last.y + 1):
		for bx in range(first.x, last.x + 1):
			for tree: Array in world.ground.trees_in_block(Vector2i(bx, by)):
				tree_view.append(tree)
	# Houses and halls stand in the same order as trees and people.
	var bounds := Rect2(Vector2(first) * 512.0, Vector2(last - first + Vector2i.ONE) * 512.0)
	for b: Dictionary in sect.standing + workplace_sprites:
		var anchor: Vector2i = b.origin + Vector2i(b.w / 2, b.h - 1)
		var foot := Vector2(b.origin.x, b.origin.y + b.h) * 32.0 - Vector2(0, world.ground.terrace_level(anchor) * world.ground.exaggeration)
		if bounds.grow(b.w * 32.0).has_point(foot):
			if b.kind == "gate" and b.get("side_passage", false):
				var back := b.duplicate()
				back.kind = "gate_side_back"
				back.visual_offset = Vector2(0, (b.h * 16 + 8) * 2)
				tree_view.append([foot - back.visual_offset, -1, back])
				var front := b.duplicate()
				front.kind = "gate_side_front"
				tree_view.append([foot, -1, front])
			else: tree_view.append([foot, -1, b])
	tree_view.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	return tree_view


func _tree(tree: Array) -> void:
	if tree[1] < 0:
		var b: Dictionary = tree[2]
		if b.kind == "guardian":
			var sprite := GuardianArt.texture(b.state, b.get("facing", "south"))
			draw_texture_rect(sprite, Rect2(tree[0] - Vector2(20, 64), sprite.get_size() * 2.0), false)
			return
		if b.kind == "orchard":
			var region := TreeArt.region(TreeArt.OAK, b.variant)
			draw_texture_rect_region(TreeArt.texture(), Rect2(tree[0] + Vector2(16, 0) - Vector2(TreeArt.FOOT), region.size), region)
			return
		var building: bool = b.kind in ["house", "hall", "cave"]
		var texture: ImageTexture = BuildingArt.texture(b.kind, b.w, b.h, b.variant) if building else WorkplaceArt.texture(b.kind, b.w, b.h, b.variant)
		var anchor: Vector2 = BuildingArt.anchor(b.kind, b.h) if building else WorkplaceArt.anchor(b.h, b.kind)
		draw_texture_rect(texture, Rect2(tree[0] + b.get("visual_offset", Vector2.ZERO) - anchor * 2.0, texture.get_size() * 2.0), false)
		return
	var region := TreeArt.region(tree[1], tree[2])
	draw_texture_rect_region(TreeArt.texture(), Rect2(tree[0] - Vector2(TreeArt.FOOT) * 2.0, region.size * 2.0), region)


func _shadow(at: Vector2, radius: float, colour: Color) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, radius, colour)
	draw_set_transform(Vector2.ZERO)


func _standing_shadow(at: Vector2, w: int) -> void:
	draw_set_transform(at + Vector2(w * 16.0 + 6, -3), 0.0, Vector2(w * 16.0 + 8, clampf(w * 3.0, 8, 22)))
	for radius in [1.0, 0.8, 0.6]: draw_circle(Vector2.ZERO, radius, Color(Palette.INK, 0.075))
	draw_set_transform(Vector2.ZERO)


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
	stages = stages.filter(func(st: Dictionary) -> bool: return st.phase != "fallen")
	var staged := _staged_ids()
	for n in range(people.size() - 1, -1, -1):
		if not society.alive[int(people[n].id)] and not staged.has(int(people[n].id)):
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
	for id in population.size():
		if people.size() >= WALKER_LIMIT: break
		if not society.alive[id] or population.age(id) < 3 or walker_of(id) >= 0: continue
		var parent: int = society.childhood.carer(id)
		var model := walker_of(parent) if parent >= 0 else -1
		if model < 0 and people.is_empty(): continue
		var p: Dictionary = people[maxi(0, model)].duplicate(true)
		p.id = id
		p.name = population.names[id]
		p.age = population.age(id)
		p.kind = 8 if population.age(id) < 12 else p.kind
		p.job = population.jobs[population.job[id]]
		p.pos = Vector2(p.home)
		p.path = PackedVector2Array()
		p.step = 0
		p.destination = Vector2i(-999, -999)
		p.erase("food_work")
		p.erase("material_work")
		p.activity = society.childhood.activity(id) if population.age(id) < 12 else "preparing for the day"
		people.append(p)
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
	if population.age(int(p.id)) < 12: return population.society.childhood.activity(int(p.id))
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
	for st: Dictionary in law_stages: _finish_law(st)
	law_stages.clear()
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
	breaches_seen = population.society.breach_count
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
			var kinds: Dictionary = {}
			for fight: Dictionary in population.society.fights: kinds[fight.kind + ":" + fight.how] = int(kinds.get(fight.kind + ":" + fight.how, 0)) + 1
			print("LAW " + JSON.stringify(population.society.law.totals))
			var founder_line := PackedByteArray()
			founder_line.resize(population.size())
			var line_living := 0
			var founders_living := 0
			for p in population.size():
				founder_line[p] = int(p < founders.size())
				for parent: int in population.society.parents(p):
					if parent >= 0 and founder_line[parent]: founder_line[p] = 1
				if founder_line[p] and population.society.alive[p]: line_living += 1
				if p < founders.size() and population.society.alive[p]: founders_living += 1
			print("LAW LINE living=%d founders_alive=%d initial=%d" % [line_living, founders_living, founders.size()])
			print("DECADE %d FIGHTS total=%d recent=%s" % [y + 1, population.society.fight_count, JSON.stringify(kinds)])
			var records: Array = population.society.top_events(maxi(0, (y - 9) * 365))
			for event: Dictionary in records:
				print("CHRONICLE day=%d %s" % [event.day, event.text])
		await get_tree().process_frame
	var children_alive := 0
	for id in population.size():
		if population.society.alive[id] and population.age(id) < 12: children_alive += 1
	print("FAMILY %d years: marriages=%d births=%d children_alive=%d" % [years, population.society.marriages, population.society.births, children_alive])
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

## Ground-only beds and ponds; upright worksite pieces join the walkers' draw order.
func _draw_food_places(area: Rect2) -> void:
	for patch: Dictionary in food_patches:
		if patch.kind in ["garden", "herd", "fishery"]: _draw_workplace_ground(patch, area)

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

	_setup_workplace_sprites()

func _draw_material_places(area: Rect2) -> void:
	for patch: Dictionary in material_patches: _draw_workplace_ground(patch, area)

func _draw_workplace_ground(patch: Dictionary, area: Rect2) -> void:
	for i in patch.tiles.size():
		var tile: Vector2i = patch.tiles[i]
		var pos := _food_point(tile)
		if not area.has_point(pos): continue
		var tex := WorkplaceArt.ground_texture(patch.kind, patch.edges[i], posmod(tile.x + tile.y, 4), economy.season() == 3)
		draw_texture_rect(tex, Rect2(pos - Vector2(16, 16), Vector2(32, 32)), false)

## Art registrations never touch footprints, destinations or the walking grid.
func _setup_workplace_sprites() -> void:
	for patch: Dictionary in food_patches + material_patches:
		var claimed: Dictionary = {}
		for at: Vector2i in patch.tiles: claimed[at] = true
		patch.edges = []
		for at: Vector2i in patch.tiles:
			var edges := 0
			var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			for i in 4:
				if not claimed.has(at + directions[i]): edges |= 1 << i
			patch.edges.append(edges)
		if patch.tiles.is_empty(): continue
		var tile: Vector2i = patch.tiles[patch.tiles.size() / 2]
		var kind := str(patch.kind)
		if kind == "garden" or kind == "clay": continue
		if kind == "orchard":
			for i in patch.tiles.size():
				if i % 12 % 3 == 0 and i / 12 % 3 == 0: _workplace(patch.tiles[i], "orchard", 1)
			for i in [8, 10]: _workplace(patch.tiles[i], "hive", 2)
		elif kind == "herd":
			var first: Vector2i = patch.tiles[0]
			var last: Vector2i = patch.tiles[-1]
			_workplace(first, "fence", last.x - first.x + 1)
			_workplace(Vector2i(first.x, last.y), "fence", last.x - first.x + 1)
			for y in range(first.y + 1, last.y):
				_workplace(Vector2i(first.x, y), "fence_side", 1)
				_workplace(Vector2i(last.x, y), "fence_side", 1)
			_workplace(tile, "kitchen", 2)
			for i in [5, 7, 9]: _workplace(patch.tiles[i], "pig" if i == 5 else "chicken", 1)
		else:
			_workplace(tile, kind, 3 if kind in ["mine", "quarry", "weaver", "tanner", "hunt", "woodcutting", "logs"] else 2)
	tree_view_key = Rect2i()

func _workplace(tile: Vector2i, kind: String, w: int) -> void:
	workplace_sprites.append({"origin": tile, "w": w, "h": 1, "kind": kind, "variant": posmod(tile.x + tile.y, 4)})

func _refresh_population_views() -> void:
	var camera: Camera2D = world.ground_view.cam
	var cell := Vector2i(camera.position / (32.0 * 32.0))
	if cell == view_cell: return
	view_cell = cell
	nearby_views.clear()
	var extent := get_viewport_rect().size / camera.zoom / 32.0
	var area := Rect2(camera.position / 32.0 - extent / 2.0, extent).grow(16)
	for person: int in population.nearby(area, WALKER_LIMIT):
		if population.age(person) < 3 or walker_of(person) >= 0 or not population.society.alive[person]: continue
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
	if what == NOTIFICATION_PREDELETE: _close_archive()


# ---------- fights on the map ----------

func _staged_ids() -> Dictionary:
	var ids := {}
	for st: Dictionary in stages:
		for id: int in st.r.ids: ids[id] = st
	for st: Dictionary in law_stages: ids[int(st.r.person)] = st
	return ids


## New fights between two villagers who are both walking here become scenes; fights while skipping are not shown.
func _watch_fights() -> void:
	var society: RefCounted = population.society
	var fights: Array = society.fights
	if fights_seen > society.fight_count or speed >= 64:
		fights_seen = society.fight_count
		return
	while fights_seen < society.fight_count:
		var back: int = society.fight_count - fights_seen
		fights_seen += 1
		if back > fights.size(): continue
		var r: Dictionary = fights[fights.size() - back]
		if r.kind in ["hunt", "guardian"] or walker_of(int(r.ids[0])) < 0 or walker_of(int(r.ids[1])) < 0: continue
		stages.append({"r": r, "phase": "wait", "clock": 0.0, "next": 0, "pops": [], "spot": Vector2i.ZERO, "met": 0.0})


func _advance_stages(elapsed: float) -> void:
	var time := fmod(minutes, 1440.0)
	for st: Dictionary in stages:
		var a: Dictionary = people[walker_of(int(st.r.ids[0]))] if walker_of(int(st.r.ids[0])) >= 0 else {}
		var b: Dictionary = people[walker_of(int(st.r.ids[1]))] if walker_of(int(st.r.ids[1])) >= 0 else {}
		if a.is_empty() or b.is_empty():
			st.phase = "done"
			continue
		match st.phase:
			"wait":
				if time >= 450 and time < 1080:
					st.phase = "meet"
					st.spot = nearest(Vector2i(((Vector2(a.pos) + Vector2(b.pos)) / 2.0).round()))
					last_minute = -1
			"meet":
				st.met += elapsed
				var here := Vector2(st.spot)
				if (Vector2(a.pos).distance_to(here) < 1.5 and Vector2(b.pos).distance_to(here) < 1.5) or st.met > 40.0:
					st.phase = "fight"
					a.fighting = 0
					b.fighting = 1
					last_minute = -1
			"fight":
				st.clock += elapsed
				var events: Array = st.r.events
				while st.next < events.size() and float(events[st.next].time) <= st.clock:
					_show_blow(st, events[st.next], [a, b])
					st.next += 1
				if st.next >= events.size(): _end_scene(st, [a, b])
			"chase":
				st.clock += elapsed
				if st.clock > st.until:
					st.phase = "done"
		if st.phase == "done":
			for w: Dictionary in [a, b]:
				w.erase("fighting")
				w.erase("rush")
				w.erase("harm")
			last_minute = -1
	stages = stages.filter(func(st: Dictionary) -> bool: return st.phase != "done")


func _show_blow(st: Dictionary, e: Dictionary, sides: Array) -> void:
	if e.has("harm"):
		sides[0].harm = float(e.harm[0])
		sides[1].harm = float(e.harm[1])
	var text := ""
	var at := 0
	match e.t:
		"strike":
			at = 1 - int(e.i)
			text = "all in!" if e.allin else ("-%d" % roundi(e.dmg) if e.hit else "miss")
			if e.hit and e.stagger and not e.allin: text += " staggers"
		"flee":
			at = int(e.i)
			text = "runs!"
		"yield":
			at = int(e.i)
			text = "yields"
	if text != "": st.pops.append({"at": at, "text": text, "hit": e.t != "strike" or e.hit, "born": Time.get_ticks_msec()})


func _end_scene(st: Dictionary, sides: Array) -> void:
	var r: Dictionary = st.r
	for w: Dictionary in sides: w.erase("fighting")
	st.clock = 0.0
	if r.loser < 0:
		st.phase = "done"
		return
	var loser: Dictionary = sides[r.loser]
	var winner: Dictionary = sides[r.winner]
	if r.fates[r.loser] == "dead":
		loser.fallen = true
		st.phase = "fallen"
	elif r.how == "escape":
		loser.rush = 2.2
		winner.rush = 2.0
		st.phase = "chase"
		st.until = 4.0
	elif r.how == "yield":
		st.phase = "chase"
		st.until = 2.0
	else:
		st.phase = "done"
	last_minute = -1


## Where a walker in a fight scene goes, and what they are doing, instead of their day.
func _scene_for(p: Dictionary, target: Vector2i, activity: String) -> Array:
	var id := int(p.get("id", -1))
	for st: Dictionary in stages:
		var side: int = st.r.ids.find(id)
		if side < 0: continue
		var other: String = st.r.names[1 - side]
		var sparring: bool = st.r.kind == "spar"
		match st.phase:
			"meet": return [st.spot, ("meeting %s to spar" if sparring else "squaring up to %s") % other]
			"fight": return [Vector2i(Vector2(p.pos).round()), ("sparring with %s" if sparring else "fighting %s") % other]
			"chase":
				if side == st.r.loser:
					return [p.home, ("running from %s" if st.r.how == "escape" else "limping home from %s") % other]
				if st.r.how == "escape":
					var runner: Dictionary = people[walker_of(int(st.r.ids[st.r.loser]))]
					return [nearest(Vector2i(Vector2(runner.pos).round())), "chasing %s" % other]
				return [Vector2i(Vector2(p.pos).round()), "watching %s go" % other]
			"fallen":
				if side == st.r.loser: return [Vector2i(Vector2(p.pos).round()), "lying still"]
	return [target, activity]


func _draw_fights(area: Rect2) -> void:
	var font := UiTheme.body()
	var now := Time.get_ticks_msec()
	for st: Dictionary in stages:
		if st.phase != "fight" and st.pops.is_empty(): continue
		var sides: Array = []
		for id: int in st.r.ids:
			var n := walker_of(id)
			sides.append(people[n] if n >= 0 else {})
		for side in 2:
			var w: Dictionary = sides[side]
			if w.is_empty(): continue
			var at := point(w)
			if not area.has_point(at): continue
			if st.phase == "fight":
				var bar := Rect2(at - Vector2(13, 48), Vector2(26, 4))
				draw_rect(bar.grow(1), Palette.OUTLINE)
				draw_rect(bar, Palette.PAPER_LIGHT)
				draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(w.get("harm", 0.0)) / 100.0, 0.0, 1.0), bar.size.y)), Palette.RED)
		var kept: Array = []
		for pop: Dictionary in st.pops:
			var age := (now - int(pop.born)) / 1000.0
			if age > 1.4: continue
			kept.append(pop)
			var w: Dictionary = sides[int(pop.at)]
			if w.is_empty(): continue
			var at := point(w) - Vector2(0, 54 + age * 18)
			var width := font.get_string_size(pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL).x
			var colour := Palette.RED if pop.hit else Palette.INK_SOFT
			colour.a = clampf(1.4 - age, 0.0, 1.0)
			var outline := Palette.PAPER_LIGHT
			outline.a = colour.a
			draw_string_outline(font, at - Vector2(width / 2.0, 0), pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, 3, outline)
			draw_string(font, at - Vector2(width / 2.0, 0), pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, colour)
		st.pops = kept


## Breach records become trips, gliding chases, blows and returns at the chosen hour.
func _advance_law(elapsed: float) -> void:
	var society: RefCounted = population.society
	if not society.law: return
	if speed >= 64:
		breaches_seen = society.breach_count
		for st: Dictionary in law_stages: _finish_law(st)
		law_stages.clear()
		return
	while breaches_seen < society.breach_count:
		var back: int = society.breach_count - breaches_seen
		breaches_seen += 1
		if back > society.breaches.size(): continue
		var r: Dictionary = society.breaches[society.breaches.size() - back]
		var n := walker_of(int(r.person))
		if n < 0: continue
		law_stages.append({"r": r, "phase": "wait", "clock": 0.0, "next": 0, "pops": [], "walker": people[n], "start": Vector2(people[n].pos)})
	var time := fmod(minutes, 1440.0)
	for st: Dictionary in law_stages:
		var r: Dictionary = st.r
		var w: Dictionary = st.walker
		var g: Dictionary = society.law.guardians[int(r.guardian)] if int(r.guardian) >= 0 else {}
		if st.phase == "wait":
			var night: bool = time >= float(society.law.config.evening) or time < float(society.law.config.dawn)
			if night != (r.trip == "night"): continue
			st.phase = "trip"
			if r.get("pursuit", false):
				st.path = grid.get_id_path(society.law.nearest(g.post), nearest(r.spot))
			else:
				st.path = society.law.route(r.place).duplicate()
				if r.seen:
					var index: int = st.path.find(r.spot)
					if index >= 0: st.path = st.path.slice(0, index + 1)
			w.law_scene = true
			w.activity = "facing a stone swordsman" if r.get("pursuit", false) else "trespassing by " + str(r.trip)
			w.hidden = false
			w.path = PackedVector2Array()
			w.fighting = 1
			st.clock = 0.0
		st.clock += elapsed
		var target := Vector2(r.spot)
		match st.phase:
			"trip":
				var path: Array = st.path
				if not path.is_empty():
					var index := mini(path.size() - 1, int(st.clock * 2.0))
					if r.get("pursuit", false):
						g.visual_state = "pursuing"
						g.visual_tile = Vector2(path[index])
					else: w.pos = Vector2(path[index])
					if index < path.size() - 1: continue
				st.phase = "chase" if r.seen else "return"
				st.clock = 0.0
			"chase":
				w.pos = target.lerp(st.start, minf(1.0, st.clock / 8.0))
				if not g.is_empty():
					g.visual_state = "pursuing"
					g.visual_tile = Vector2(g.post).move_toward(Vector2(w.pos), st.clock * 3.0)
				if st.clock >= 8.0:
					st.phase = "fight" if r.has("fight") else "return"
					st.clock = 0.0
			"fight":
				var events: Array = r.fight.events
				while st.next < events.size() and float(events[st.next].time) <= st.clock:
					var e: Dictionary = events[st.next]
					if e.t == "strike" and e.hit: st.pops.append({"text": str(roundi(e.dmg)), "born": Time.get_ticks_msec(), "side": 1 - int(e.i)})
					st.next += 1
				if st.next >= events.size():
					st.phase = "return"
					st.clock = 0.0
			"return":
				w.pos = Vector2(w.pos).move_toward(st.start, elapsed * 3.0)
				if not g.is_empty() and g.state not in ["frozen", "broken"]:
					g.visual_tile = Vector2(g.get("visual_tile", g.tile)).move_toward(Vector2(g.post), elapsed * 3.0)
				if not g.is_empty() and g.state in ["frozen", "broken"]:
					g.visual_state = g.state
					g.visual_tile = Vector2(g.tile)
				if st.clock >= 12.0: _finish_law(st)
	law_stages = law_stages.filter(func(st: Dictionary) -> bool: return st.phase != "done")

func _finish_law(st: Dictionary) -> void:
	st.phase = "done"
	st.walker.erase("law_scene")
	st.walker.erase("fighting")
	st.walker.pos = st.start
	if not population.society.alive[int(st.r.person)]: st.walker.fallen = true
	if int(st.r.guardian) >= 0:
		var g: Dictionary = population.society.law.guardians[int(st.r.guardian)]
		g.erase("visual_state")
		g.erase("visual_tile")
	last_minute = -1


func _draw_law_harm(area: Rect2) -> void:
	var font := UiTheme.body()
	for st: Dictionary in law_stages:
		if st.phase != "fight": continue
		for pop: Dictionary in st.pops:
			var age := (Time.get_ticks_msec() - int(pop.born)) / 1000.0
			if age > 1.4: continue
			var at := point(st.walker)
			if int(pop.side) == 0 and int(st.r.guardian) >= 0:
				var g: Dictionary = population.society.law.guardians[int(st.r.guardian)]
				at = point({"pos": Vector2(g.get("visual_tile", g.tile))})
			if not area.has_point(at): continue
			at -= Vector2(0, 54 + age * 18)
			draw_string_outline(font, at, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, 3, Palette.PAPER_LIGHT)
			draw_string(font, at, pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, Palette.RED)
