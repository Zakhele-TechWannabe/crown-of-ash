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
			var walk: bool = (level >= 0 or south or surface == "stairs") and surface != "spring" and surface != "cave" and sect.art[i] < 0
			if south:
				walk = walk and sect.dry.call(at)
			heights[i] = world.ground.terrace_level(at) if walk else maxi(0, level)
			if walk and not south and surface != "stairs":
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
				if grid.is_in_boundsv(other) and not grid.is_point_solid(other) and sect.surface_at(other) != "stairs" and absi(heights[sect.index_at(at)] - heights[sect.index_at(other)]) > (1 if y - sect.center.y >= 151 else 0):
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
				activity = ["weeding the spirit paddies", "cooking in the canteen", "sweeping the Great Plaza", "tending the barracks", "carrying water", "selling at the market", "tending the shrine", "cutting wood", "playing near home and the square"][int(p.kind)]
				var cycle := int((time + variation) / 25)
				if p.kind == 4:
					target = well if cycle % 2 == 0 else (p.home if cycle % 4 == 1 else people[n % 8].work)
				elif p.kind == 7 and cycle % 2:
					target = p.home
					activity = "bringing logs home"
				elif p.kind == 8:
					target = nearest((p.home if cycle % 2 else square) + Vector2i((cycle + n) % 7 - 3, (cycle * 3 + n) % 7 - 3))
		p.carrying = false
		if activity.begins_with("weeding"):
			activity = ["planting the paddies", "tending the paddies", "harvesting the paddies", "repairing tools and gathering firewood"][economy.season()]
			if economy.season() == 2 and int(time / 45 + n) % 2 == 0:
				target = granary
				p.carrying = true
				activity = "carrying grain to the granary"
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
	return "Year %d · %s, day %d · %02d:%02d" % [absolute_day / 365 + 1, economy.SEASONS[season], day, int(minutes / 60) % 24, int(minutes) % 60]


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
	economy.advance_to(years * 365 * 1440.0)
	for summary: String in economy.summaries:
		print(summary)
	for entry: String in economy.chronicle:
		print(entry)
	get_tree().quit()
