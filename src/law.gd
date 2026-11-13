extends RefCounted
## Immutable sight and route caches; daily law resolution never searches the map per frame.
const Combat = preload("res://src/combat.gd")
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/law.json"))
var guardians: Array[Dictionary] = []
var hunt_list: Dictionary = {}
var totals := {"breaches": 0, "seen": 0, "killed": 0, "escaped": 0, "pursuits": 0, "frozen": 0, "broken": 0}
var years: Dictionary = {}
var sect: RefCounted
var grid: AStarGrid2D
var blocked: Dictionary = {}
var residents: Dictionary = {}
var routes: Dictionary = {}
var walk_paths: Dictionary = {}
var last_day := -1

## A guardian's name opening a sentence: "The west swordsman of the Mountain Gate".
static func title(name: String) -> String:
	return name.substr(0, 1).to_upper() + name.substr(1)

func setup(ground: RefCounted, walk_grid: AStarGrid2D, walkers: Array, terrain: Node2D = null) -> void:
	sect = ground
	grid = walk_grid
	blocked = sect.standing_tiles.duplicate()
	if terrain:
		var rect: Rect2i = Rect2i(sect.center + sect.bounds.position, sect.bounds.size)
		for y in range(floori(rect.position.y / 16.0), ceili(rect.end.y / 16.0)):
			for x in range(floori(rect.position.x / 16.0), ceili(rect.end.x / 16.0)):
				for tree: Array in terrain.trees_in_block(Vector2i(x, y)):
					var foot: Vector2 = tree[0]
					var tile := Vector2i((foot / 32.0).floor())
					for attempt in 4: tile = Vector2i(((foot + Vector2(0, terrain.terrace_level(tile) * terrain.exaggeration)) / 32.0 - Vector2(0.5, 0.9)).floor())
					blocked[tile] = true
	for p: Dictionary in walkers: residents[int(p.id)] = p
	var sources: Array = [sect]
	if "sites" in sect: sources.append_array(sect.sites)
	for source: RefCounted in sources:
		for b: Dictionary in source.data.get("buildings", []):
			if b.kind != "gate": continue
			var r: Array = b.rect
			var origin: Vector2i = source.center + Vector2i(int(r[0]), int(r[1]))
			var middle := origin + Vector2i(int(r[2]) / 2, int(r[3]))
			# Lateral gates touch the outer terrace; the mountain gate faces south.
			if not sect.inside_grounds(middle) and not sect.inside_grounds(middle + Vector2i.UP * 3): continue
			var lateral := preload("res://src/gate_direction.gd").east_west(source, origin, int(r[2]), int(r[3]))
			var outward := "west" if middle.x < sect.center.x else "east"
			var pair := guardians.size()
			for side in 2:
				var post := origin + Vector2i(-1 if side == 0 else int(r[2]), int(r[3]))
				if lateral: post = middle + Vector2i(0, -3 if side == 0 else 2)
				var direction := ("west" if side == 0 else "east") if not lateral else ("north" if side == 0 else "south")
				var g := {"id": guardians.size(), "gate": str(b.name), "name": "the %s swordsman of the %s" % [direction, b.name],
					"post": post, "tile": post, "facing": outward if lateral else "south", "state": "guarding", "energy": float(config.energy_max), "kills": 0, "breaks": 0, "harm": 0.0, "fights": 0, "driven_off": 0, "last_fight": "", "broken_by": "", "broken_day": -1,
					"partner": pair + 1 - side, "sight": {}, "night": {}}
				guardians.append(g)
	rebuild_sight()

func rebuild_sight() -> void:
	for g: Dictionary in guardians:
		g.sight = {}
		g.night = {}
		for at: Vector2i in sect.grounds:
			if Vector2(g.post).distance_to(Vector2(at)) > float(config.day_sight): continue
			if line_clear(g.post, at):
				g.sight[at] = true
				if Vector2(g.post).distance_to(Vector2(at)) <= float(config.night_sight): g.night[at] = true


## Bresenham, with opaque footprints and tall terrace faces.
func line_clear(a: Vector2i, b: Vector2i) -> bool:
	var at := a
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var error := dx + dy
	var previous: int = sect.level_at(a)
	while at != b:
		var twice := error * 2
		if twice >= dy:
			error += dy
			at.x += sx
		if twice <= dx:
			error += dx
			at.y += sy
		var level: int = sect.level_at(at)
		if at != b and (blocked.has(at) or (previous >= 0 and level - previous >= 2)): return false
		if level >= 0: previous = level
	return true

func awake(g: Dictionary) -> bool:
	return g.state == "guarding" and float(g.energy) > 0.0 and float(g.get("harm", 0.0)) <= float(config.retreat_harm)

func destination(place: String) -> Vector2i:
	var r: Array = config.places.get(place, config.places.spring)
	return sect.center + Vector2i(int(r[0]), int(r[1]))

func nearest(at: Vector2i) -> Vector2i:
	for radius in 16:
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var p := at + Vector2i(x, y)
				if grid.is_in_boundsv(p) and not grid.is_point_solid(p): return p
	return at

func walk_path(a: Vector2i, b: Vector2i) -> Array:
	var key := Vector4i(a.x, a.y, b.x, b.y)
	if not walk_paths.has(key): walk_paths[key] = grid.get_id_path(a, b)
	return walk_paths[key]

func route(place: String) -> Array:
	if routes.has(place): return routes[place]
	var target := nearest(destination(place))
	var best: Array = []
	for g: Dictionary in guardians:
		var path: Array = walk_path(nearest(g.post), target)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()): best = path
	if best.is_empty(): best = [target]
	routes[place] = best
	return best

func visible(at: Vector2i, night: bool) -> bool:
	for g: Dictionary in guardians:
		if awake(g) and (g.night if night else g.sight).has(at): return true
	return false

func stealth(store: RefCounted, p: int) -> int:
	var best := 0
	var e: int = store.head[p]
	while e >= 0:
		var id: String = store.catalogue.ids[store.skill_id[e]]
		if "stealth" in id or "scent_masking" in id or "mountain_ambush" in id or "trail_reading" in id: best = maxi(best, store.skill_level[e])
		e = store.skill_next[e]
	return best

func danger(society: RefCounted, p: int, place: String, night: bool) -> float:
	var count := 0
	var seen := 0
	for at: Vector2i in route(place):
		if not sect.inside_grounds(at): continue
		count += 1
		if visible(at, night): seen += 1
	var exposure := float(seen) / maxf(1, count)
	return maxf(0.0, exposure * float(config.night_seen if night else config.day_seen) - floorf(stealth(society.population, p) / float(config.stealth_step)) * float(config.stealth_reduction))

func has_pass(p: int, at: Vector2i, minute: float, day: int) -> bool:
	if not sect.inside_grounds(at): return true
	if not residents.has(p): return false
	var w: Dictionary = residents[p]
	var variation := (int(w.get("schedule_index", p)) * 17 + day * 13 + int(sect.data.seed)) % 61
	return sect.inside_grounds(w.work) and at.distance_to(w.work) <= float(config.pass_radius) and minute >= float(config.work_start) + variation and minute < float(config.work_end) + variation and not (minute >= float(config.midday_start) + variation / 2 and minute < float(config.midday_end) + variation / 2)

func cover(at: Vector2i, night: bool) -> float:
	var total := 0
	var hidden := 0
	var reach := int(config.cover_reach)
	for y in range(-reach, reach + 1):
		for x in range(-reach, reach + 1):
			var tile := at + Vector2i(x, y)
			if Vector2(x, y).length() > reach: continue
			total += 1
			if blocked.has(tile) or not line_clear(at, tile) or sect.surface_at(tile) == "spring": hidden += 1
	return float(hidden) / maxf(1, total)

func _count(key: String, day: int) -> void:
	totals[key] += 1
	var year := day / 365
	if not years.has(year): years[year] = { "breaches": 0, "seen": 0, "killed": 0, "escaped": 0, "pursuits": 0, "frozen": 0, "broken": 0}
	years[year][key] += 1

func priority(entry: Dictionary, day: int) -> float:
	return float(config.weights.get(entry.place, 1.0)) * pow(0.5, float(day - int(entry.day)) / float(config.half_life)) * (1.0 + float(config.repeat) * (int(entry.offences) - 1))

func mark(p: int, place: String, day: int) -> void:
	var offences := int(hunt_list[p].offences) + 1 if hunt_list.has(p) else 1
	hunt_list[p] = {"person": p, "place": place, "day": day, "offences": offences, "priority": 0.0}
	hunt_list[p].priority = priority(hunt_list[p], day)

func spend(society: RefCounted, g: Dictionary, path: Array, returning: bool = false) -> void:
	for at: Vector2i in path:
		g.tile = at
		g.energy = maxf(0.0, float(g.energy) - float(config.inside_cost if sect.inside_grounds(at) else config.outside_cost))
		if g.energy <= 0.0:
			freeze(society, g)
			return
		if not returning and float(g.energy) < float(config.reserve): return

func freeze(society: RefCounted, g: Dictionary) -> void:
	if g.state in ["frozen", "broken"]: return
	g.state = "frozen"
	_count("frozen", society.population.day)
	var where := "in the rice paddies" if sect.surface_at(g.tile) == "field" else ("on the sect terraces" if sect.inside_grounds(g.tile) else "outside the sect grounds")
	society.note(-1, "guardian", "%s stands frozen %s" % [title(g.name), where])

func _return(society: RefCounted, g: Dictionary) -> void:
	if g.state in ["broken", "frozen"]: return
	var path: Array = walk_path(nearest(g.tile), nearest(g.post))
	spend(society, g, path, true)
	if g.state != "frozen":
		g.state = "guarding"
		g.tile = g.post

## A caught runner fights stone through the same blow-by-blow engine as every other fighter.
func battle(society: RefCounted, g: Dictionary, p: int, kin: bool = false) -> Dictionary:
	var store: RefCounted = society.population
	var defenders: Array[int] = [p]
	if kin and society.temper:
		for q in store.size():
			if q != p and society.alive[q] and store.household[q] == store.household[p] and store.age(q) >= int(config.adult_age) and society.temper.body_layer[q] >= int(config.kin_layer): defenders.append(q)
	var person := Combat.person(society, p)
	person.lethal = true
	for q: int in defenders.slice(1):
		var other := Combat.person(society, q)
		person.power += other.power
		person.guard += other.guard
		person.speed = minf(person.speed, other.speed)
	if defenders.size() > 1:
		var names: Array[String] = []
		for q: int in defenders: names.append(store.names[q])
		society.note(p, "guardian", "%s stood together against %s" % [", ".join(names), g.name])
	var stone := Combat.beast("stone swordsman")
	stone.name = g.name
	var r := Combat.fight(stone, person, {"lethal": true, "escape_cover": cover(g.tile, false), "start_harm": [float(g.get("harm", 0.0)), 0.0]}, store.rng)
	r.merge({"kind": "guardian", "day": store.day, "ids": [-1, p], "names": [g.name, store.names[p]], "motives": ["own", "own"], "defenders": defenders})
	g.harm = float(r.harm[0])
	g.fights = int(g.get("fights", 0)) + 1
	g.last_fight = "Day %d · %s · %s" % [store.day, store.names[p], r.how]
	g.energy = maxf(0.0, float(g.energy) - float(config.fight_cost))
	var killed := false
	var harms: Dictionary = {}
	for q: int in defenders: harms[q] = 0.0
	var applied := 0.0
	for event: Dictionary in r.events:
		if event.t != "strike" or int(event.i) != 0 or not event.hit: continue
		var delta := maxf(0.0, float(event.harm[1]) - applied)
		applied += delta
		var q: int = defenders[store.rng.randi_range(0, defenders.size() - 1)]
		harms[q] = minf(100.0, float(harms[q]) + delta)
	r.defender_harm = harms
	for q: int in defenders:
		var harm: float = harms[q]
		if harm >= 100.0:
			society.die(q, "killed", "%s was cut down by %s" % [store.names[q], g.name], -1)
			killed = true
			g.kills += 1
			_count("killed", store.day)
			if society.mind:
				var family: Array = Array(society.children(q)) + Array(society.parents(q))
				if society.spouse[q] >= 0: family.append(society.spouse[q])
				for relative: int in family:
					if relative >= 0 and society.alive[relative]:
						society.mind.scar(relative, society.mind.FEAR, float(config.scar_fear))
						society.mind.scar(relative, society.mind.SPITE, float(config.scar_spite))
		else: Combat._hurt(society, q, harm, -1, r)
	if float(r.harm[0]) >= 100.0:
		g.state = "broken"
		g.broken_by = store.names[p]
		g.broken_day = store.day
		g.breaks += 1
		_count("broken", store.day)
		for q: int in defenders: society.reputation[q] += float(config.renown)
		society.note(p, "oath", "%s broke %s; the village cheered and feared what would follow" % [store.names[p], g.name])
		if society.mind:
			for q in store.size():
				if society.alive[q]: society.mind.feel(q, society.mind.JOY if store.rng.randf() < float(config.coin) else society.mind.AFRAID, float(config.village_feeling))
	elif g.energy <= 0.0: freeze(society, g)
	r.outcome = "killed" if killed else ("broken" if g.state == "broken" else "escaped")
	if r.outcome == "escaped": g.driven_off = int(g.get("driven_off", 0)) + 1
	society.record_fight(r)
	return r

func trespass(society: RefCounted, p: int, place: String, at_night: bool) -> Dictionary:
	var store: RefCounted = society.population
	var r := {"day": store.day, "person": p, "place": place, "trip": "night" if at_night else "day", "seen": false, "outcome": "unseen", "guardian": -1, "spot": destination(place)}
	_count("breaches", store.day)
	var chance := danger(society, p, place, at_night)
	r.seen = store.rng.randf() < chance
	if r.seen:
		_count("seen", store.day)
		var spot: Vector2i = r.spot
		for at: Vector2i in route(place):
			if visible(at, at_night):
				spot = at
				break
		r.spot = spot
		var nearest_g: Dictionary = {}
		var distance := INF
		for g: Dictionary in guardians:
			if not awake(g): continue
			var d := Vector2(g.post).distance_to(Vector2(spot))
			if d < distance:
				distance = d
				nearest_g = g
		if not nearest_g.is_empty():
			var g := nearest_g
			r.guardian = g.id
			g.state = "pursuing"
			spend(society, g, walk_path(nearest(g.post), nearest(spot)))
			var runner := Combat.person(society, p)
			var escape := cover(spot, at_night) * Combat.running(runner) / Combat.running(Combat.beast("stone swordsman"))
			if g.state == "frozen" or float(g.energy) < float(config.reserve) or store.rng.randf() < escape: r.outcome = "escaped"
			else:
				r.fight = battle(society, g, p)
				r.outcome = r.fight.outcome
			if r.outcome == "escaped":
				if not r.has("fight"): g.driven_off = int(g.get("driven_off", 0)) + 1
				_count("escaped", store.day)
				mark(p, "fight" if r.has("fight") else place, store.day)
			_return(society, g)
	var words := "%s slipped into the grounds by %s to %s. Nobody saw." % [store.names[p], r.trip, "pick seven-leaf" if place == "seven_leaf" else "meditate at the " + place]
	if r.seen:
		var name: String = guardians[int(r.guardian)].name if int(r.guardian) >= 0 else "the swordsmen"
		words = "%s was seen %s; %s pursued them; %s" % [store.names[p], str(config.offences.get(place, "trespassing")), name, r.outcome]
	r.text = words
	society.note(p, "guardian" if r.seen else "trespass", words)
	society.record_breach(r)
	return r

func can_leave(g: Dictionary, cost: float) -> bool:
	return awake(g) and guardians[int(g.partner)].state == "guarding" and float(g.energy) >= cost + float(config.fight_cost) + float(config.reserve)

func advance(society: RefCounted, day: int) -> void:
	if day <= last_day: return
	var days := 1 if last_day < 0 else day - last_day
	last_day = day
	for g: Dictionary in guardians:
		if g.state == "guarding" and g.tile == g.post:
			g.energy = minf(float(config.energy_max), float(g.energy) + days * float(config.recharge))
			g.harm = maxf(0.0, float(g.get("harm", 0.0)) - days * float(config.mend_per_day))
	for p: int in hunt_list.keys():
		if not society.alive[p]: hunt_list.erase(p)
		elif day - int(hunt_list[p].day) > int(config.cold_days):
			society.note(p, "guardian", "The trail went cold; the swordsmen stopped looking for %s" % society.population.names[p])
			hunt_list.erase(p)
		else: hunt_list[p].priority = priority(hunt_list[p], day)
	if hunt_list.is_empty(): return
	var entries: Array = hunt_list.values()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority)
	var p: int = entries[0].person
	var target: Vector2i = residents[p].home if residents.has(p) else Vector2i(society.population.locations[p].round())
	for g: Dictionary in guardians:
		if not awake(g): continue
		var path: Array = walk_path(nearest(g.post), nearest(target))
		if path.is_empty(): continue
		var cost := 0.0
		for at: Vector2i in path: cost += 2.0 * float(config.inside_cost if sect.inside_grounds(at) else config.outside_cost)
		if not can_leave(g, cost): continue
		g.state = "pursuing"
		_count("pursuits", day)
		spend(society, g, path)
		var fight := battle(society, g, p, true)
		var r := {"day": day, "person": p, "place": "village", "trip": "day", "seen": true, "outcome": fight.outcome, "guardian": g.id, "spot": target, "fight": fight, "pursuit": true}
		r.text = "%s followed the trail into the village to %s; %s" % [title(g.name), society.population.names[p], r.outcome]
		society.note(p, "guardian", r.text)
		society.record_breach(r)
		if r.outcome in ["killed", "broken"]: hunt_list.erase(p)
		else:
			_count("escaped", day)
			mark(p, "fight", day)
		_return(society, g)
		break
