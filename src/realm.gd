extends RefCounted
## Crown of Ash as pure data: an empire against the walking dead. People live by themselves — farming, chopping,
## foraging, building, keeping watch, fighting, cultivating — and you set jobs, rules and buildings, and send the
## warband to win back the land. Units are pixels.
##
## The living are people, each with a name. The dead are numbers: the map is cut into blocks and each block holds a
## count of them, so there can be millions. Anyone in the open in a block with the dead is fighting them.

const Land := preload("res://src/land.gd")
const T := Land.T

const DAY_LEN := 300.0
const NIGHT_LEN := 130.0
const DOOR_HP := 60.0
const PLANK_HP := 120.0
const ALTAR_HP := 700.0
const WALL_HP := 160.0
const GATE_HP := 240.0
const STAKE_WOOD := 0.25             # wood per palisade cell
const STAKE_WORK := 2.5              # seconds of work per palisade cell
const TOWERS := 4
const WOUNDED := 50.0                # below this, people go home to rest...
const MENDED := 90.0                 # ...and stay in bed until they're back to this
const WARBAND_MIN := 3
const BLOCK := 4                     # the dead are counted in blocks of 4x4 cells
const BW := (Land.W + BLOCK - 1) / BLOCK
const BH := (Land.H + BLOCK - 1) / BLOCK
const BITE := 6.0                    # harm one of the dead does each second to someone it reaches
const GRIP := 3                      # the most of them that can reach one person at once
const ZOMBIE_HP := 100.0
const LAYERS := 9                    # Body Refinement, first layer to ninth
const CULT_NEED := 120.0             # seconds of full-time cultivation for the first layer

enum { DAY, NIGHT, LOST, WON }

const JOBS := ["farm", "chop", "forage", "build", "guard", "soldier", "cultivate", "rest"]
const JOB_INFO := {
	"farm": "Works the village fields by day: food",
	"chop": "Fells trees for wood — the axe is loud",
	"forage": "Searches ruined cottages and brings back what they find",
	"build": "Builds the village's works and mends the gate",
	"guard": "Watches from the hall with a bow and shoots what comes close",
	"soldier": "Fights: clears the dead near home or marches with the warband",
	"cultivate": "Tempers the body full-time: climbs the layers of Body Refinement",
	"rest": "Stays in the hall and gets their strength back",
}
const TRAITS := {
	"Quiet": "Keeps calm and steady",
	"Strong": "Hits harder and takes less harm",
	"Skilled": "Works twice as fast",
	"Keen-eyed": "A sharper eye and a better shot",
}
const SYLLABLES := ["a", "ba", "bo", "da", "di", "e", "fa", "ga", "ji", "ka", "ki", "ko", "la", "le", "lu", "ma", "mi",
	"na", "ni", "nyo", "o", "ra", "ri", "sa", "si", "ta", "tu", "wa", "ya", "ze", "zu"]

## What a soldier is trained as. Militia is everyone's start; the rest need a barracks where they live.
const UNITS := {
	"militia": {"name": "Militia", "dmg": 30.0, "armor": 1.0, "reach": 0.0, "cost": {}, "time": 0.0, "info": "Spear and buckler, no training"},
	"spearman": {"name": "Spearman", "dmg": 55.0, "armor": 0.8, "reach": 18.0, "cost": {"wood": 2}, "time": 30.0, "info": "A long spear: strikes before the dead can reach"},
	"archer": {"name": "Archer", "dmg": 25.0, "armor": 1.0, "reach": 0.0, "cost": {"wood": 3}, "time": 30.0, "info": "Shoots from 280 paces (uses arrows); weak up close"},
	"man_at_arms": {"name": "Man-at-arms", "dmg": 75.0, "armor": 0.45, "reach": 0.0, "cost": {"wood": 4, "food": 4}, "time": 45.0, "info": "Mail and a sword: hits hard, hard to kill"},
}
const ORDERS := {
	"fields": "Clears the dead standing near home, keeps watch at night",
	"warband": "Marches when you send the warband to a village",
}
const HALL_WORKS := ["mill", "fletcher", "chapel", "barracks", "bell"]

## Works each village's hall can hold — prebuilt places, unlocked by building.
const UPGRADES := [
	{"id": "palisade", "name": "Palisade", "cost": {}, "work": 0.0, "info": "Raises the marked wall ring a stake at a time (wood as it goes). Roads get gates."},
	{"id": "towers", "name": "Towers", "cost": {"wood": 5}, "work": 24.0, "info": "Corner towers, one at a time: guards on them see and shoot much further"},
	{"id": "gate", "name": "Hall door bars", "cost": {"wood": 3}, "work": 15.0, "info": "The hall door gets three planks"},
	{"id": "shutters", "name": "Shutters", "cost": {"wood": 4}, "work": 18.0, "info": "Every window shuttered: no light gets out"},
	{"id": "beds", "name": "Straw beds", "cost": {"wood": 3}, "work": 15.0, "info": "Sleep twice as fast"},
	{"id": "mill", "name": "Mill", "cost": {"wood": 5}, "work": 22.0, "info": "Farmers grow half again as much"},
	{"id": "fletcher", "name": "Fletcher", "cost": {"wood": 4}, "work": 20.0, "info": "Builders turn wood into arrows"},
	{"id": "chapel", "name": "Chapel", "cost": {"wood": 5, "food": 3}, "work": 25.0, "info": "Wounds heal faster; +1 herbs a day"},
	{"id": "barracks", "name": "Barracks", "cost": {"wood": 6, "food": 4}, "work": 28.0, "info": "Soldiers who live here can train as spearmen, archers or men-at-arms"},
	{"id": "bell", "name": "Bell", "cost": {"wood": 4, "food": 4}, "work": 25.0, "info": "Refugees hear it: a newcomer every two days"},
]

var land: Land
var rng := RandomNumberGenerator.new()
var phase := DAY
var day := 1
var clock := 0.0
var clock_all := 0.0                 # seconds since the realm began
var step_dt := 0.0
var stock := {"food": 200.0, "wood": 40.0, "arrows": 60, "herbs": 10}
var rules := {"hearths": false, "rations": "normal", "close_gate": true}
var built := {}                      # holding → {upgrade id: true}
var queue := {}                      # holding → [upgrade ids]
var progress := {}                   # holding → {upgrade id: seconds of work}
var bell_t := {}                     # holding → days since the last refugee
var marked := {}                     # house index → true: forage here first
var target := -1                     # the holding the warband is sent to win back
var altar_hp := ALTAR_HP
var people: Array = []
var horde := PackedInt32Array()      # block → how many of the dead stand there
var marches: Array = []              # {b, n, goal, t}: the night's packs on the move
var march_n := PackedInt32Array()    # block → how many of the marching packs are in it
var danger := PackedByteArray()      # block → 1 while any of the dead are in it
var block_open := PackedByteArray()  # block → 1 if the dead can cross it
var hold_blocks := {}                # holding → [blocks]
var inner := {}                      # block → the holding whose palisade it lies wholly inside
var walls_of := {}                   # holding → [its palisade cells]
var hurt_walls := {}                 # palisade cell → true while it needs mending
var wall_blocks := {}                # block → [palisade cells in it]
var doors := {}                      # house → its door cell
var block_fields := {}               # goal block → distance to it from every block
var hurt_acc := {}                   # block → part of a kill dealt so far
var spots := {}                      # block → block_spot
var house_grid := PackedInt32Array() # cell → the house standing on it, or -1
var rooms := {}                      # holding → [Vector2]: somewhere to sleep, one for each person
var shots: Array = []
var noises: Array = []
var log: Array = []
var events: Array = []
var gates := {}                      # holding → its hall's door cell
var beds := {}                       # holding → [Vector2]
var posts := {}                      # holding → [Vector2]
var slots := {}                      # holding → {upgrade id: Vector2}
var woods := {}                      # holding → [forest cells near it]
var walls := {}                      # Vector2i → {h, hp, up, gate, open, work, in}: each village's marked palisade
var rings := {}                      # holding → Rect2i its palisade runs round
var towers := {}                     # holding → [Vector2] the four corner tower spots
var tower_count := {}                # holding → towers built


func setup(seed_val: int) -> void:
	rng.seed = seed_val
	land = Land.new()
	land.build(seed_val)
	house_grid.resize(Land.W * Land.H)
	house_grid.fill(-1)
	for i in land.houses.size():
		var r: Rect2i = land.houses[i].rect
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				house_grid[y * Land.W + x] = i
	for c in land.openings:
		var o: Dictionary = land.openings[c]
		o.open = false
		o.planks = 0
		o.hp = DOOR_HP if o.kind == "door" else 0.0
	for h in land.holdings.size():
		_plan_ring(h)
	for h in land.holdings.size():
		var hr := land.hall_rect(h)
		built[h] = {}
		queue[h] = []
		progress[h] = {}
		bell_t[h] = 0.0
		beds[h] = []
		posts[h] = []
		slots[h] = {}
		rooms[h] = []
		for c in land.openings:
			var o: Dictionary = land.openings[c]
			if o.house != land.holdings[h].hall:
				continue
			if o.kind == "door":
				gates[h] = c
			posts[h].append(land.center(c) + (land.center(_hall_center(h)) - land.center(c)).normalized() * T)
		for k in mini(6, hr.size.x - 2):
			beds[h].append(land.center(Vector2i(hr.position.x + 1 + k, hr.position.y + 1)))
		# somewhere to sleep for everyone: every floor cell of the holding's houses, hall first
		for i in land.holdings[h].houses:
			var r: Rect2i = land.houses[i].rect
			for y in range(r.position.y + 1, r.end.y - 1):
				for x in range(r.position.x + 1, r.end.x - 1):
					rooms[h].append(land.center(Vector2i(x, y)))
		for u in UPGRADES:
			slots[h][u.id] = hall_pos(h)
		for k in HALL_WORKS.size():
			slots[h][HALL_WORKS[k]] = land.center(Vector2i(hr.position.x + 1 + (k % 3) * 2 + (k / 3), hr.end.y - 2 - k / 3))
		woods[h] = []
		var p: Vector2i = land.holdings[h].center
		for y in range(p.y - 18, p.y + 19):
			for x in range(p.x - 18, p.x + 19):
				if land.at(Vector2i(x, y)) == Land.FOREST and _forest_edge(Vector2i(x, y)):
					woods[h].append(Vector2i(x, y))
	_blocks()
	# the capital's hundred: most work the land, some keep watch or carry spears, some cultivate
	var plan := {"farm": 22, "chop": 14, "build": 12, "forage": 6, "guard": 10, "soldier": 14, "cultivate": 12, "rest": 10}
	for job in plan:
		for k in plan[job]:
			var s := _add_person(0, job, TRAITS.keys()[rng.randi() % TRAITS.size()])
			if job == "soldier" and k >= 8:
				s.order = "warband"
	# the dead hold every city and the crypt, more the further from the capital; more wander the wilds
	for h in range(1, land.holdings.size()):
		var crypt: bool = land.holdings[h].crypt
		var far: float = Vector2(land.holdings[h].center - land.holdings[0].center).length() / 30.0
		var count := 400 if crypt else int(40 + far * 30) + rng.randi_range(0, 20)
		var a := land.holding_area(h)
		var core := Rect2i(land.holdings[h].center - Vector2i(5, 4), Vector2i(11, 9))
		for k in count:
			var area := core if rng.randf() < 0.5 else a
			var b := block_of(Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1)))
			if block_open[b] == 1:
				horde[b] += 1
	var home := block_of(land.holdings[0].center)
	var wild := 0
	while wild < 40:
		var b := rng.randi() % (BW * BH)
		if block_open[b] == 0 or _bdist(b, home) < 6:
			continue
		# a band in the wilds, spilling into the blocks around it
		for o in [0, 1, -1, BW, -BW]:
			var nb: int = b + o
			if nb >= 0 and nb < BW * BH and block_open[nb] == 1 and rng.randf() < 0.6:
				horde[nb] += rng.randi_range(1, 6)
		wild += 1
	note("Ala Kambara stands alone, a hundred souls. The dead hold the empire, from the Golden Coast to the Black Crypt in the Nyoka peaks.")


## Every village has its wall ring marked out from the start; building it is the Palisade work. Where a road
## crosses the ring there's a gate. Trees in the way are cleared.
func _plan_ring(h: int) -> void:
	towers[h] = []
	tower_count[h] = 0
	if land.holdings[h].crypt:
		return
	var r := land.holding_area(h).intersection(Rect2i(0, 0, Land.W, Land.H))
	rings[h] = r
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not land.in_ring(h, c):
				continue
			# the ring is every cell of the octagon with open ground beside it (diagonals too, so it's sealed)
			var out := Vector2i.ZERO
			var edge := false
			for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				if not land.in_ring(h, c + o):
					edge = true
					if out == Vector2i.ZERO and (o.x == 0 or o.y == 0):
						out = o
			if not edge:
				continue
			var t := land.at(c)
			if t in [Land.WALL, Land.FLOOR, Land.DOOR, Land.WINDOW, Land.WATER, Land.ROCK]:
				continue                                 # houses, water and rock need no stakes
			if out == Vector2i.ZERO:
				var d: Vector2i = c - land.holdings[h].center
				out = Vector2i(signi(d.x), 0) if absi(d.x) * land.holdings[h].half.y >= absi(d.y) * land.holdings[h].half.x else Vector2i(0, signi(d.y))
			var inn := -out
			for k in [c, c + inn]:
				if land.at(k) == Land.FOREST:
					land.tiles[k.y * Land.W + k.x] = Land.GRASS
			walls[c] = {"h": h, "hp": 0.0, "up": false, "gate": t == Land.ROAD, "open": false, "work": 0.0, "in": inn}
	# a gate on every side (except a side lying on the edge of the world), in the middle if no road made one
	var mid := r.get_center()
	for side in [[Vector2i(0, -1), r.position.y > 0], [Vector2i(0, 1), r.end.y < Land.H],
			[Vector2i(-1, 0), r.position.x > 0], [Vector2i(1, 0), r.end.x < Land.W]]:
		if not side[1]:
			continue
		var cells: Array = walls.keys().filter(func(c): return walls[c].h == h and walls[c].in == -side[0])
		if cells.is_empty() or cells.any(func(c): return walls[c].gate):
			continue
		cells.sort_custom(func(a, b): return a.distance_squared_to(mid) < b.distance_squared_to(mid))
		walls[cells[0]].gate = true
	# towers stand inside the four cut corners
	var hd: Dictionary = land.holdings[h]
	var cut := land.cut(h)
	for q in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var k: Vector2i = hd.center + q * (hd.half - Vector2i(cut / 2 + 2, cut / 2 + 2))
		if land.at(k) in [Land.FOREST, Land.WATER, Land.ROCK, Land.SAND]:
			land.tiles[k.y * Land.W + k.x] = Land.GRASS
		towers[h].append(land.center(k))


func wall_max(w: Dictionary) -> float:
	return GATE_HP if w.gate else WALL_HP


func wall_standing(w: Variant) -> bool:
	return w != null and w.up and float(w.hp) > 0.0


func stakes(h: int) -> Vector2i:
	var done := 0
	var all := 0
	for c in walls:
		if walls[c].h == h:
			all += 1
			if walls[c].up:
				done += 1
	return Vector2i(done, all)


func _forest_edge(c: Vector2i) -> bool:
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if land.at(c + o) in [Land.GRASS, Land.ROAD, Land.FIELD]:
			return true
	return false


func _hall_center(h: int) -> Vector2i:
	var r := land.hall_rect(h)
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)


func hall_pos(h: int) -> Vector2:
	return land.center(_hall_center(h))


func _add_person(home: int, job: String, kind: String) -> Dictionary:
	var at := hall_pos(home) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-20, 20))
	var s := {"name": _new_name(), "home": home, "p": at, "v": Vector2.ZERO, "face": Vector2.RIGHT, "hp": 100.0, "max_hp": 100.0,
		"hunger": rng.randf_range(70.0, 95.0), "energy": rng.randf_range(70.0, 95.0), "job": job, "trait": kind, "doing": "", "goal": at,
		"path": [], "carry": {}, "house": -1, "busy": 0.0, "cd": rng.randf() * 2.0, "sneak": false, "asleep": false, "hurt_t": 0.0,
		"step": 0.0, "noise_t": 0.0, "spot": Vector2i(-1, -1), "color": Color.from_hsv(rng.randf(), 0.4, 0.8),
		"unit": "militia", "order": "fields", "train": "", "train_t": 0.0, "resting": false, "avoid": {},
		"bed": people.size(), "layer": 0, "qi": 0.0, "talent": snappedf(clampf(rng.randfn(1.0, 0.3), 0.4, 2.0), 0.01)}
	people.append(s)
	return s


## Names made from sounds: two or three syllables, never the same twice.
func _new_name() -> String:
	var used := {}
	for s in people:
		used[s.name] = true
	for k in 50:
		var n := ""
		for i in rng.randi_range(2, 3):
			n += SYLLABLES[rng.randi() % SYLLABLES.size()]
		n = n.capitalize()
		if not used.has(n) and n.length() <= 9:
			return n
	return "Nameless %d" % people.size()


func note(text: String) -> void:
	for l in log.slice(maxi(0, log.size() - 6)):
		if l[1] == text:
			return
	log.append([day, text])
	if log.size() > 50:
		log = log.slice(log.size() - 50)
	_ev("note", Vector2.ZERO, {"text": text})


func _ev(k: String, at: Vector2 = Vector2.ZERO, extra := {}) -> void:
	var e := {"k": k, "p": at}
	e.merge(extra)
	events.append(e)


func night_ratio() -> float:
	if phase == NIGHT:
		return clampf(minf(clock, NIGHT_LEN - clock) / 8.0, 0.0, 1.0)
	return clampf((clock - (DAY_LEN - 20.0)) / 20.0, 0.0, 0.8)


func time_left() -> float:
	return (DAY_LEN if phase == DAY else NIGHT_LEN) - clock


func holdings_owned() -> Array:
	var out := []
	for h in land.holdings.size():
		if land.holdings[h].claimed:
			out.append(h)
	return out


func dead_in(h: int) -> int:
	var n := 0
	for b in hold_blocks[h]:
		n += dead_at(b)
	return n


func has_built(h: int, id: String) -> bool:
	return built[h].has(id)


# ---------------------------------------------------------------- the land

func opening(c: Vector2i) -> Dictionary:
	return land.openings.get(c, {})


func door_max(o: Dictionary) -> float:
	return DOOR_HP + int(o.planks) * PLANK_HP


func _walk_person(c: Vector2i) -> bool:
	var w: Variant = walls.get(c)
	if wall_standing(w) and not w.gate:
		return false
	var t := land.at(c)
	return not (land.impassable(t) or t == Land.WINDOW or t == Land.FOREST)


func _walk_dead(c: Vector2i, calm := false) -> bool:
	var w: Variant = walls.get(c)
	if wall_standing(w):
		return w.gate and w.open
	var t := land.at(c)
	if land.impassable(t):
		return false
	if t == Land.DOOR:
		return bool(opening(c).open) or float(opening(c).hp) <= 0.0
	if t == Land.WINDOW:
		return not calm and int(opening(c).planks) == 0
	return true


func clear_at(c: Vector2i) -> bool:
	var t := land.at(c)
	if t == Land.WATER:
		return true                                      # you can see across the river
	return t != Land.WALL and t != Land.FOREST and t != Land.ROCK and _walk_dead(c)


## Home is any house of the holding someone lives in.
func at_home(s: Dictionary) -> bool:
	var i := house_of(s.p)
	return i >= 0 and land.houses[i].holding == s.home


func home_pos(s: Dictionary) -> Vector2:
	var list: Array = rooms[s.home]
	return list[int(s.bed) % list.size()] if not list.is_empty() else hall_pos(s.home)


func in_any_hall(s: Dictionary) -> bool:
	var i := house_of(s.p)
	return i >= 0 and land.holdings[land.houses[i].holding].claimed


func house_of(p: Vector2) -> int:
	var c := land.cell(p)
	if c.x < 0 or c.y < 0 or c.x >= Land.W or c.y >= Land.H:
		return -1
	return house_grid[c.y * Land.W + c.x]


func crates_left(house: int) -> int:
	return land.crates.filter(func(c): return c.house == house and not c.searched).size()


# ---------------------------------------------------------------- step

func step(dt: float) -> void:
	events.clear()
	if phase in [LOST, WON]:
		return
	clock += dt
	clock_all += dt
	step_dt = dt
	if phase == DAY and clock >= DAY_LEN:
		phase = NIGHT
		clock = 0.0
		_rise()
		_ev("night")
		note("Night %d falls.%s" % [day, " Hearths are lit." if rules.hearths else ""])
	elif phase == NIGHT and clock >= NIGHT_LEN:
		day += 1
		phase = DAY
		clock = 0.0
		_dawn()
		_ev("dawn")
	_rank_posts()
	for s in people:
		_person(s, dt)
	_hordes(dt)
	people = people.filter(func(s): return s.hp > 0.0)
	_campaign(dt)
	for sh in shots:
		sh[2] -= dt
	shots = shots.filter(func(sh): return sh[2] > 0.0)
	for n in noises:
		n[2] -= dt
	noises = noises.filter(func(n): return n[2] > 0.0)
	if people.is_empty():
		phase = LOST
		note("No one is left to hold the land.")
		_ev("lost")


func _dawn() -> void:
	# the night's packs stop where daylight finds them and stand there
	for m in marches:
		horde[m.b] += m.n
	marches.clear()
	_recount()
	for cr in land.crates:
		if cr.searched and rng.randf() < 0.2:
			cr.searched = false
	for s in people:
		s.avoid = {}                                     # a new day: worth another look
	for h in holdings_owned():
		if has_built(h, "chapel"):
			stock.herbs += 1
		if has_built(h, "bell"):
			bell_t[h] += 1.0
			if bell_t[h] >= 2.0:
				bell_t[h] = 0.0
				var pick: String = TRAITS.keys()[rng.randi() % TRAITS.size()]
				var s := _add_person(h, "rest", pick)
				s.p = land.center(land.holdings[h].center + Vector2i(0, 9))
				note("%s heard the bell of %s and came in from the road. (%s)" % [s.name, land.holdings[h].name, pick])
				_ev("joined", s.p)
	note("Day %d. %d souls, %d of %d cities held." % [day, people.size(), holdings_owned().size(), land.holdings.size() - 1])


# ---------------------------------------------------------------- the warband

func send_warband(h: int) -> String:
	if land.holdings[h].claimed:
		return "That village is already yours"
	var band := people.filter(func(s): return s.job == "soldier" and s.order == "warband").size()
	if target != h and band < WARBAND_MIN:
		return "A warband needs %d soldiers (it has %d)" % [WARBAND_MIN, band]
	target = h if target != h else -1
	if target >= 0:
		note("The warband is ordered to %s." % land.holdings[h].name)
	return ""


func _campaign(dt: float) -> void:
	if target < 0:
		return
	var h := target
	var a := land.holding_area(h)
	var there := people.filter(func(s): return s.job == "soldier" and s.order == "warband" and a.has_point(land.cell(s.p)))
	if there.is_empty():
		return
	if dead_in(h) > 0:
		return
	if land.holdings[h].crypt:
		if altar_hp > 0.0:
			return
		phase = WON
		note("The Black Crypt is broken. The dead will rise no more. The realm is yours.")
		_ev("won")
		return
	land.holdings[h].claimed = true
	target = -1
	note("%s is ours again! Move villagers there to settle it." % land.holdings[h].name)
	_ev("claimed", hall_pos(h))


# ---------------------------------------------------------------- villagers

func _person(s: Dictionary, dt: float) -> void:
	s.cd -= dt
	s.hurt_t -= dt
	var drain: float = 1.0 + (0.5 if s.doing == "tempering the body" else 0.0) + 0.05 * s.layer
	s.hunger = maxf(0.0, s.hunger - dt * 100.0 / 620.0 * drain)
	if s.hunger <= 0.0:
		s.hp -= dt * 0.7
	if not s.asleep:
		s.energy = maxf(0.0, s.energy - dt * 100.0 / 480.0)
	if s.hp < s.max_hp * WOUNDED / 100.0 and not s.resting:
		s.resting = true
		note("%s is badly hurt and goes home to rest." % s.name)
	elif s.hp >= s.max_hp * MENDED / 100.0 and s.resting:
		s.resting = false
	if s.hp < s.max_hp and s.hunger > 50.0:
		s.hp = minf(s.max_hp, s.hp + dt * 0.05 * (1.0 + 0.2 * s.layer))   # small wounds close; a tempered body faster
	if in_any_hall(s):
		var half: bool = rules.rations == "half"
		if s.hunger < 45.0 and stock.food >= (0.5 if half else 1.0):
			stock.food -= 0.5 if half else 1.0
			s.hunger = minf(100.0, s.hunger + (30.0 if half else 50.0))
		if s.hp < s.max_hp * 0.6 and stock.herbs > 0:
			stock.herbs -= 1
			s.hp = minf(s.max_hp, s.hp + 35.0)
		if s.hp < s.max_hp and s.hunger > 30.0:
			# rest in bed heals far faster than standing about; the chapel doubles it
			s.hp = minf(s.max_hp, s.hp + dt * (0.28 if s.asleep else 0.08) * (2.0 if has_built(s.home, "chapel") else 1.0) * (1.0 + 0.2 * s.layer))
	_decide(s, dt)
	_walk(s, dt)


func _decide(s: Dictionary, dt: float) -> void:
	# the dead in the block where they stand: soldiers and well-tempered cultivators fight, the rest run home
	var n := 0 if _sheltered(s) else dead_at(block_at(s.p))
	if n > 0:
		var brave: bool = (s.job == "soldier" or s.layer >= 3 or (s.trait == "Strong" and n <= 2)) and not s.resting
		if brave:
			s.doing = "fight"
		elif s.doing != "flee":
			s.doing = "flee"
	elif s.doing in ["fight", "flee"]:
		s.doing = ""
	match s.doing:
		"fight":
			s.asleep = false
			s.path = []
			s.goal = s.p
			_temper(s, dt * 0.3)
			return
		"flee":
			s.asleep = false
			if at_home(s):
				s.doing = ""
			else:
				_go(s, home_pos(s))
			return
	var dusk := phase == DAY and time_left() < 30.0
	if phase == NIGHT or dusk:
		if (s.job == "guard" or (s.job == "soldier" and s.order == "fields")) and s.energy > 15.0 and not s.resting and _post_index(s) < tower_count[s.home] + 6:
			_deposit_if_home(s)
			_guard(s, dt)
			return
		if not at_home(s):
			s.doing = "heading home"
			_deposit_if_home(s)
			_go(s, home_pos(s))
			return
		_deposit_if_home(s)
		_sleep(s, dt)
		return
	if s.energy < 20.0 or s.resting:
		if at_home(s):
			_deposit_if_home(s)
			_sleep(s, dt)
			if s.resting and s.asleep:
				s.doing = "resting their wounds"
		else:
			s.doing = "going home to rest" if s.resting else "heading home"
			_go(s, home_pos(s))
		return
	s.asleep = false
	match s.job:
		"farm":
			_farm(s, dt)
		"chop":
			_chop(s, dt)
		"forage":
			_forage(s, dt)
		"build":
			_build(s, dt)
		"guard":
			_guard(s, dt)
		"soldier":
			_soldier(s, dt)
		"cultivate":
			_cultivate(s, dt)
		_:
			if s.energy < 90.0:
				_sleep(s, dt)
			else:
				_idle(s)


## Safe behind a door the dead haven't broken.
func _sheltered(s: Dictionary) -> bool:
	var i := house_of(s.p)
	if i < 0:
		return false
	var d: Variant = doors.get(i)
	return d == null or float(land.openings[d].hp) > 0.0


func _idle(s: Dictionary) -> void:
	s.doing = "idle"
	if s.p.distance_to(s.goal) < 6.0 or not land.hall_rect(s.home).has_point(land.cell(s.goal)):
		s.busy += step_dt
		if s.busy < 4.0 and land.hall_rect(s.home).has_point(land.cell(s.goal)):
			return                                    # stand about a while before wandering on
		s.busy = 0.0
		s.goal = hall_pos(s.home) + Vector2(rng.randf_range(-60, 60), rng.randf_range(-30, 30))
		s.path = []
	_go(s, s.goal)


func _sleep(s: Dictionary, dt: float) -> void:
	var bed := home_pos(s)
	if s.p.distance_to(bed) > 8.0:
		s.doing = "going to bed"
		s.asleep = false
		_go(s, bed)
		return
	s.doing = "asleep"
	s.asleep = true
	s.path = []
	s.goal = s.p
	s.energy = minf(100.0, s.energy + dt * 100.0 / (45.0 if has_built(s.home, "beds") else 90.0))


func _work_at(s: Dictionary, at: Vector2) -> bool:
	if s.p.distance_to(at) > 14.0:
		_go(s, at)
		return false
	s.path = []
	s.goal = s.p
	return true


func _speed(s: Dictionary) -> float:
	return (2.0 if s.trait == "Skilled" else 1.0) * (1.0 + 0.05 * s.layer)


func _farm(s: Dictionary, dt: float) -> void:
	var fields: Array = land.holdings[s.home].fields
	if fields.is_empty():
		_idle(s)
		return
	if s.spot == Vector2i(-1, -1) or not s.spot in fields:
		s.spot = fields[rng.randi() % fields.size()]
	s.doing = "working the fields"
	if _work_at(s, land.center(s.spot)):
		_temper(s, dt * 0.1)
		stock.food += dt * 0.03 * _speed(s) * (1.5 if has_built(s.home, "mill") else 1.0)
		s.busy += dt
		if s.busy > 6.0:
			s.busy = 0.0
			s.spot = fields[rng.randi() % fields.size()]


func _chop(s: Dictionary, dt: float) -> void:
	var w: Array = woods[s.home]
	if w.is_empty():
		_idle(s)
		return
	if s.spot == Vector2i(-1, -1) or not s.spot in w:
		var best: Variant = w[0]
		var bd := 1e9
		for c in w:
			var d := land.center(c).distance_to(hall_pos(s.home)) + rng.randf_range(0, 200)
			if d < bd:
				bd = d
				best = c
		s.spot = best
	# stand beside the tree
	var stand := land.center(s.spot)
	for o in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		if _walk_person(s.spot + o):
			stand = land.center(s.spot + o)
			break
	s.doing = "chopping wood"
	if _work_at(s, stand):
		_temper(s, dt * 0.1)
		stock.wood += dt * 0.035 * _speed(s)
		s.noise_t -= dt
		if s.noise_t <= 0.0:
			s.noise_t = 2.5
			_noise(s.p, 70.0 if s.trait == "Quiet" else 130.0)
			_ev("chop", s.p)


func _guard(s: Dictionary, dt: float) -> void:
	s.asleep = false
	s.doing = "on watch"
	var k := _post_index(s)
	var on_tower: bool = k < tower_count[s.home]
	var list: Array = posts[s.home]
	var post: Vector2 = towers[s.home][k] if on_tower else (list[k % list.size()] if not list.is_empty() else hall_pos(s.home))
	if on_tower:
		s.doing = "on watch on a tower"
	if s.p.distance_to(post) > 10.0:
		_go(s, post)
	else:
		s.path = []
		s.goal = s.p
	if s.cd <= 0.0 and stock.arrows > 0:
		var reach := (300.0 if s.trait == "Keen-eyed" else 230.0) * (1.6 if on_tower else 1.0)
		var b := _nearest_dead(s.p, reach, [])
		if b < 0:
			s.cd = 0.5                                # nothing in reach: look again in a moment
		else:
			s.cd = 1.4
			stock.arrows -= 1
			if rng.randf() < 0.6:
				stock.arrows += 1                         # gathered again in the morning
			var at := block_center(b) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
			s.face = (at - s.p).normalized()
			shots.append([s.p, at, 0.08])
			_ev("arrow", s.p)
			if rng.randf() < (0.85 if s.trait == "Keen-eyed" else 0.65) * (1.0 + 0.04 * s.layer):
				_kill(b, 1)


## Guards take the towers first, then the hall's windows. Soldiers off duty stand behind the guards.
func _post_index(s: Dictionary) -> int:
	return int(s.get("post", 0))


func _rank_posts() -> void:
	var n := {}
	for job in ["guard", "soldier"]:
		for s in people:
			if s.job == job:
				s.post = int(n.get(s.home, 0))
				n[s.home] = s.post + 1

func armor(s: Dictionary) -> float:
	return float(UNITS[s.unit].armor) if s.job == "soldier" else 1.0


## Soldiers set to train walk to their barracks by day and come back as the new kind.
func train(s: Dictionary, kind: String) -> String:
	if s.job != "soldier":
		return "Only soldiers train"
	if kind != "militia" and not has_built(s.home, "barracks"):
		return "%s needs a barracks" % land.holdings[s.home].name
	if s.unit == kind:
		return "Already " + UNITS[kind].name
	if s.train != "":
		return "Already training"
	var u: Dictionary = UNITS[kind]
	for k in u.cost:
		if float(stock[k]) < float(u.cost[k]):
			return "Not enough " + k
	for k in u.cost:
		stock[k] -= u.cost[k]
	if kind == "militia":
		s.unit = kind
		return ""
	s.train = kind
	s.train_t = 0.0
	note("%s goes to the barracks to train as %s." % [s.name, u.name.to_lower()])
	return ""


func set_order(s: Dictionary, order: String) -> void:
	s.order = order
	s.ward = null
	s.path = []


func _soldier(s: Dictionary, dt: float) -> void:
	if s.train != "":
		var u: Dictionary = UNITS[s.train]
		s.doing = "training as " + u.name.to_lower()
		if _work_at(s, slots[s.home].barracks):
			s.train_t += dt
			if s.train_t >= float(u.time):
				s.unit = s.train
				s.train = ""
				note("%s is now %s." % [s.name, "an archer" if s.unit == "archer" else "a " + u.name.to_lower()])
				_ev("built", s.p)
		return
	if s.order == "fields":
		_patrol(s, dt)
		return
	if target < 0:
		_guard(s, dt)
		return
	var h := target
	var b := _nearest_dead(s.p, 1e9, hold_blocks[h])
	if b >= 0:
		s.doing = "marching on " + land.holdings[h].name
		_go(s, block_spot(b))
		return
	if land.holdings[h].crypt and altar_hp > 0.0:
		s.doing = "breaking the crypt's altar"
		if _work_at(s, hall_pos(h)) and s.cd <= 0.0:
			s.cd = 0.8
			altar_hp -= 40.0 * (1.4 if s.trait == "Strong" else 1.0) * (1.0 + 0.35 * s.layer)
			_ev("hit", hall_pos(h))
		return
	s.doing = "marching to " + land.holdings[h].name
	_go(s, hall_pos(h))


## Fields order: clear the dead standing near home, a few at a time, then walk the fields.
func _patrol(s: Dictionary, dt: float) -> void:
	s.scan_t = float(s.get("scan_t", 0.0)) - dt
	var b: int = s.get("aim", -1)
	if s.scan_t <= 0.0 or (b >= 0 and dead_at(b) == 0):
		s.scan_t = 1.0
		var near: Array = []
		var hb := block_of(land.holdings[s.home].center)
		for k in BW * BH:
			if dead_at(k) > 0 and dead_at(k) <= 6 and _bdist(k, hb) <= 8:
				near.append(k)
		b = _nearest_dead(s.p, 1e9, near) if not near.is_empty() else -1
		s.aim = b
	if b >= 0:
		s.doing = "clearing the dead near " + land.holdings[s.home].name
		_go(s, block_spot(b))
		return
	var fields: Array = land.holdings[s.home].fields
	if fields.is_empty():
		_guard(s, dt)
		return
	s.doing = "patrolling the fields"
	_temper(s, dt * 0.05)
	s.busy += dt
	if s.spot == Vector2i(-1, -1) or not s.spot in fields or s.busy > 9.0:
		s.busy = 0.0
		s.spot = fields[rng.randi() % fields.size()]
	_go(s, land.center(s.spot))


func _build(s: Dictionary, dt: float) -> void:
	var h: int = s.home
	if gates.has(h):
		var o: Dictionary = land.openings[gates[h]]
		if float(o.hp) < door_max(o) - 1.0 and stock.wood >= 1.0:
			s.doing = "mending the gate"
			if _work_at(s, land.center(gates[h]) + (hall_pos(h) - land.center(gates[h])).normalized() * T):
				s.busy += dt * _speed(s)
				if s.busy > 4.0:
					s.busy = 0.0
					stock.wood -= 1.0
					o.hp = door_max(o)
					o.open = false
					_noise(s.p, 150.0)
			return
	if _mend_wall(s, dt):
		return
	var up: Variant = _next_upgrade(h)
	if up != null and up.id == "palisade":
		_raise_palisade(s, dt, up)
		return
	if up == null:
		if has_built(h, "fletcher") and stock.wood > 4.0 and stock.arrows < 40:
			s.doing = "making arrows"
			if _work_at(s, slots[h].fletcher):
				s.busy += dt * _speed(s)
				if s.busy > 15.0:
					s.busy = 0.0
					stock.wood -= 1.0
					stock.arrows += 2
			return
		_idle(s)
		return
	s.doing = "building: " + up.name
	if _work_at(s, work_spot(h, up.id)):
		_temper(s, dt * 0.1)
		progress[h][up.id] = float(progress[h].get(up.id, 0.0)) + dt * _speed(s)
		if fmod(float(progress[h][up.id]), 1.5) < dt * _speed(s):
			_noise(s.p, 90.0)
		if float(progress[h][up.id]) >= float(up.work):
			_finish(h, up)


func work_spot(h: int, id: String) -> Vector2:
	if id == "towers":
		return towers[h][mini(tower_count[h], TOWERS - 1)] if not towers[h].is_empty() else hall_pos(h)
	return slots[h][id]


func _mend_wall(s: Dictionary, dt: float) -> bool:
	if stock.wood < STAKE_WOOD:
		return false
	var best: Variant = null
	var bd := 1e9
	for c in hurt_walls.keys():
		var w: Dictionary = walls[c]
		if not w.up or float(w.hp) >= wall_max(w) - 1.0:
			hurt_walls.erase(c)
			continue
		if w.h != s.home:
			continue
		var d := land.center(c).distance_to(s.p)
		if d < bd:
			bd = d
			best = c
	if best == null:
		return false
	var w: Dictionary = walls[best]
	s.doing = "mending the %s" % ("gate" if w.gate else "palisade")
	if _work_at(s, land.center(best + w.in)):
		s.busy += dt * _speed(s)
		if s.busy > 3.0:
			s.busy = 0.0
			stock.wood -= STAKE_WOOD
			w.hp = wall_max(w)
			w.open = false
			_noise(s.p, 120.0)
	return true


func _raise_palisade(s: Dictionary, dt: float, up: Dictionary) -> void:
	var h: int = s.home
	if s.spot == Vector2i(-1, -1) or not walls.has(s.spot) or walls[s.spot].up or walls[s.spot].h != h:
		s.spot = Vector2i(-1, -1)
		var bd := 1e9
		for c in walls_of.get(h, []):
			var w: Dictionary = walls[c]
			if not w.up:
				var d := land.center(c).distance_to(s.p) + (0.0 if float(w.work) > 0.0 else 40.0)
				if d < bd:
					bd = d
					s.spot = c
		if s.spot == Vector2i(-1, -1):
			_finish(h, up)
			return
	if stock.wood < STAKE_WOOD:
		s.doing = "waiting for wood for the palisade"
		_idle(s)
		return
	var w: Dictionary = walls[s.spot]
	s.doing = "raising the palisade"
	if _work_at(s, land.center(s.spot + w.in)):
		w.work = float(w.work) + dt * _speed(s)
		s.noise_t -= dt
		if s.noise_t <= 0.0:
			s.noise_t = 1.5
			_noise(s.p, 110.0)
			_ev("chop", s.p)
		if float(w.work) >= STAKE_WORK:
			w.up = true
			w.hp = wall_max(w)
			w.work = 0.0
			stock.wood -= STAKE_WOOD


func _next_upgrade(h: int) -> Variant:
	for id in queue[h]:
		var up: Dictionary = upgrade(id)
		if progress[h].has(id):
			return up
		var ok := true
		for k in up.cost:
			if float(stock[k]) < float(up.cost[k]):
				ok = false
		if ok:
			for k in up.cost:
				stock[k] -= up.cost[k]
			progress[h][id] = 0.0
			return up
	return null


func upgrade(id: String) -> Dictionary:
	for u in UPGRADES:
		if u.id == id:
			return u
	return {}


func _finish(h: int, up: Dictionary) -> void:
	if up.id == "towers":
		tower_count[h] += 1
		progress[h].erase("towers")
		_ev("built", towers[h][tower_count[h] - 1])
		note("%s: tower %d of %d built." % [land.holdings[h].name, tower_count[h], TOWERS])
		if tower_count[h] < TOWERS:
			return
	built[h][up.id] = true
	queue[h].erase(up.id)
	progress[h].erase(up.id)
	note("%s: %s built." % [land.holdings[h].name, up.name])
	_ev("built", slots[h][up.id])
	match up.id:
		"gate":
			var o: Dictionary = land.openings[gates[h]]
			o.planks = 3
			o.hp = door_max(o)
		"shutters":
			for c in land.openings:
				var o: Dictionary = land.openings[c]
				if o.kind == "window" and o.house == land.holdings[h].hall:
					o.planks = 3
					o.hp = 3 * PLANK_HP


func queue_upgrade(h: int, id: String) -> String:
	if not land.holdings[h].claimed:
		return "Win this village back first"
	if has_built(h, id):
		return "Already built"
	if id in ["palisade", "towers"] and land.holdings[h].crypt:
		return "Nothing to wall here"
	if id in queue[h]:
		queue[h].erase(id)
		return "Taken off the list"
	queue[h].append(id)
	return ""


func move_home(s: Dictionary, h: int) -> String:
	if not land.holdings[h].claimed:
		return "That village isn't ours yet"
	s.home = h
	s.path = []
	s.spot = Vector2i(-1, -1)
	note("%s moves to %s." % [s.name, land.holdings[h].name])
	return ""


# ---------------------------------------------------------------- foraging

## Foragers search houses in our cities, and out past them any house where none of the dead stand.
func _forage(s: Dictionary, dt: float) -> void:
	var carried := 0
	for k in s.carry:
		carried += int(s.carry[k])
	if carried >= 6 or time_left() < 50.0:
		s.doing = "bringing things home"
		if at_home(s):
			_deposit_if_home(s)
			s.house = -1
			if time_left() < 50.0:
				_idle(s)
		else:
			_go(s, home_pos(s))
		return
	if s.house >= 0 and dead_at(block_of(land.houses[s.house].rect.get_center())) > 0:
		s.avoid[s.house] = true
		s.house = -1
	if s.house < 0 or crates_left(s.house) == 0:
		s.house = _pick_house(s)
		if s.house < 0:
			if not at_home(s):
				s.doing = "heading home"
				_go(s, home_pos(s))
				return
			_idle(s)
			s.doing = "nothing safe left to search"
			return
	var cr: Variant = null
	var bd := 1e9
	for c in land.crates:
		if c.house == s.house and not c.searched:
			var d := land.center(c.cell).distance_to(s.p)
			if d < bd:
				bd = d
				cr = c
	if cr == null:
		return
	var spot := land.center(cr.cell)
	s.doing = "searching " + land.holdings[land.houses[s.house].holding].name
	if s.p.distance_to(spot) > 20.0:
		_go(s, spot)
		return
	s.path = []
	s.goal = s.p
	s.busy += dt
	if s.busy >= 1.4:
		s.busy = 0.0
		_loot(s, cr)


func _pick_house(s: Dictionary) -> int:
	var best := -1
	var bd := 1e9
	for i in land.houses.size():
		var hol: int = land.houses[i].holding
		if land.holdings[hol].crypt or crates_left(i) == 0 or s.avoid.has(i):
			continue
		if dead_at(block_of(land.houses[i].rect.get_center())) > 0:
			continue
		var d := land.center(land.houses[i].rect.get_center()).distance_to(s.p)
		if marked.has(i):
			d -= 20000.0
		elif not land.holdings[hol].claimed:
			d += 900.0
		if d < bd:
			bd = d
			best = i
	return best


func _loot(s: Dictionary, cr: Dictionary) -> void:
	cr.searched = true
	var got: Array[String] = []
	for item in [["food", 0.55, 1, 3], ["wood", 0.4, 1, 2], ["arrows", 0.35, 2, 5], ["herbs", 0.25, 1, 1]]:
		var n := rng.randi_range(item[2], item[3]) if rng.randf() < item[1] else 0
		if n > 0:
			s.carry[item[0]] = int(s.carry.get(item[0], 0)) + n
			got.append("%d %s" % [n, item[0]])
	_ev("loot", s.p, {"text": "+" + ", +".join(got) if not got.is_empty() else "nothing"})
	if rng.randf() < 0.05 and people.size() < 150:
		var pick: String = TRAITS.keys()[rng.randi() % TRAITS.size()]
		var n2 := _add_person(s.home, "rest", pick)
		n2.p = s.p + Vector2(14, 0)
		note("%s found %s hiding in a cottage. (%s)" % [s.name, n2.name, pick])
		_ev("joined", s.p)


func _deposit_if_home(s: Dictionary) -> void:
	if s.carry.is_empty() or not in_any_hall(s):
		return
	var parts: Array[String] = []
	for k in s.carry:
		stock[k] = stock[k] + s.carry[k]
		parts.append("%d %s" % [s.carry[k], k])
	note("%s brought home %s." % [s.name, ", ".join(parts)])
	s.carry = {}


# ---------------------------------------------------------------- walking

func _go(s: Dictionary, to: Vector2) -> void:
	var moved := land.cell(s.goal) != land.cell(to)
	if moved or (s.path.is_empty() and clock_all >= float(s.get("retry", 0.0))):
		s.path = _route(land.cell(s.p), land.cell(to), s.job != "soldier")
		if s.path.is_empty():
			s.retry = clock_all + 2.0                # no way there just now: try again in a little while
	s.goal = to


func _route(a: Vector2i, b: Vector2i, wary := false) -> Array:
	if a == b:
		return [b]                                    # same cell: walk straight to the spot
	var ab := block_of(a)
	var bb := block_of(b)
	var start := a.y * Land.W + a.x
	var end := b.y * Land.W + b.x
	var prev := PackedInt32Array()
	prev.resize(Land.W * Land.H)
	prev.fill(-1)
	prev[start] = start
	var q := PackedInt32Array()
	q.resize(Land.W * Land.H)
	q[0] = start
	var tail := 1
	var head := 0
	while head < tail:
		var i := q[head]
		head += 1
		if i == end:
			break
		var x := i % Land.W
		for n in [i + 1 if x < Land.W - 1 else -1, i - 1 if x > 0 else -1, i + Land.W, i - Land.W]:
			if n < 0 or n >= Land.W * Land.H or prev[n] != -1:
				continue
			var c := Vector2i(n % Land.W, n / Land.W)
			if n != end and not _walk_person(c):
				continue
			if wary:
				var nb := block_of(c)
				if nb != ab and nb != bb and danger[nb] == 1:
					continue                          # the wary walk round the blocks where the dead stand
			prev[n] = i
			q[tail] = n
			tail += 1
	var out: Array = []
	if prev[end] == -1:
		return out
	var cur := end
	while cur != start:
		out.push_front(Vector2i(cur % Land.W, cur / Land.W))
		cur = prev[cur]
	return out

func _walk(s: Dictionary, dt: float) -> void:
	if s.asleep or s.path.is_empty():
		s.v = Vector2.ZERO
		return
	var c: Vector2i = s.path[0]
	var tgt: Vector2 = land.center(c) if s.path.size() > 1 else s.goal
	if land.at(c) == Land.DOOR and not opening(c).open and float(opening(c).hp) > 0.0:
		opening(c).open = true
		_ev("door", land.center(c))
	var wg: Variant = walls.get(c)
	if wall_standing(wg) and wg.gate and not wg.open:
		wg.open = true
		_ev("door", land.center(c))
	var speed: float = (230.0 if s.doing == "flee" else 125.0) * (1.0 + 0.04 * s.layer)
	var d: Vector2 = tgt - s.p
	if d.length() < 6.0:
		s.path.pop_front()
		_close_gate_behind(s, c)
		return
	s.v = d.normalized() * speed
	s.face = d.normalized()
	s.p += s.v * dt
	s.step += dt * speed * 0.08


func _close_gate_behind(s: Dictionary, passed: Vector2i) -> void:
	if not rules.close_gate:
		return
	var wg: Variant = walls.get(passed)
	if wall_standing(wg) and wg.gate and wg.open:
		wg.open = false
		return
	var o: Variant = land.openings.get(passed)
	if o != null and o.kind == "door" and o.open and float(o.hp) > 0.0:
		o.open = false



func _noise(at: Vector2, radius: float) -> void:
	noises.append([at, radius, 0.6])

# ---------------------------------------------------------------- cultivation

## Body Refinement: tempering flesh and bone, layer by layer. Each layer needs more than the last; talent speeds
## it. Full-time cultivators gain fastest, labour and fighting give a little.
func qi_need(layer: int) -> float:
	return CULT_NEED * pow(1.6, layer)


func _temper(s: Dictionary, amount: float) -> void:
	if s.layer >= LAYERS or s.hunger < 30.0:
		return
	s.qi += amount * s.talent
	if s.qi >= qi_need(s.layer):
		s.qi = 0.0
		s.layer += 1
		s.max_hp = 100.0 + 25.0 * s.layer
		s.hp = minf(s.max_hp, s.hp + 25.0)
		note("%s breaks through to Body Refinement, layer %d." % [s.name, s.layer])
		_ev("breakthrough", s.p)


func realm_name(s: Dictionary) -> String:
	return "Mortal" if s.layer == 0 else "Body Refinement %d" % s.layer


## How hard someone fights: blows a second, in hit points of the dead.
func power(s: Dictionary) -> float:
	var base := float(UNITS[s.unit].dmg) / 0.7 if s.job == "soldier" else 15.0
	return base * (1.0 + 0.35 * s.layer) * (1.4 if s.trait == "Strong" else 1.0)


func _cultivate(s: Dictionary, dt: float) -> void:
	if s.layer >= LAYERS:
		s.doing = "at the peak of Body Refinement"
		_idle(s)
		return
	var k: int = people.find(s) % 12
	var spot := hall_pos(s.home) + Vector2(cos(k * TAU / 12.0) * 150.0, sin(k * TAU / 12.0) * 110.0 + 150.0)
	s.doing = "tempering the body"
	if _work_at(s, spot):
		_temper(s, dt)


# ---------------------------------------------------------------- the dead, counted in blocks

func block_of(c: Vector2i) -> int:
	return clampi(c.y / BLOCK, 0, BH - 1) * BW + clampi(c.x / BLOCK, 0, BW - 1)


func block_at(p: Vector2) -> int:
	return block_of(land.cell(p))


func block_rect(b: int) -> Rect2i:
	return Rect2i((b % BW) * BLOCK, (b / BW) * BLOCK, BLOCK, BLOCK)


func block_center(b: int) -> Vector2:
	return (Vector2(b % BW, b / BW) * BLOCK + Vector2(BLOCK, BLOCK) / 2.0) * T


## Where someone heading into a block makes for: its open cell nearest the middle.
func block_spot(b: int) -> Vector2:
	if not spots.has(b):
		var best := block_center(b)
		var bd := 1e9
		var r := block_rect(b)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				var d := land.center(c).distance_to(block_center(b))
				if d < bd and not land.impassable(land.at(c)) and land.at(c) != Land.FOREST and house_grid[y * Land.W + x] < 0:
					bd = d
					best = land.center(c)
		spots[b] = best
	return spots[b]


func _bdist(a: int, b: int) -> int:
	return maxi(absi(a % BW - b % BW), absi(a / BW - b / BW))


func dead_at(b: int) -> int:
	return horde[b] + march_n[b]


func _recount() -> void:
	march_n.fill(0)
	for m in marches:
		march_n[m.b] += m.n


func dead_total() -> int:
	var n := 0
	for v in horde:
		n += v
	for m in marches:
		n += m.n
	return n


## Which blocks the dead can cross, which lie inside each palisade, and which hold its wall.
func _blocks() -> void:
	horde.resize(BW * BH)
	horde.fill(0)
	danger.resize(BW * BH)
	danger.fill(0)
	march_n.resize(BW * BH)
	march_n.fill(0)
	block_open.resize(BW * BH)
	for b in BW * BH:
		var open := 0
		var r := block_rect(b)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if not land.at(Vector2i(x, y)) in [Land.WATER, Land.ROCK]:
					open += 1
		block_open[b] = 1 if open >= BLOCK * BLOCK / 3 else 0
	for h in land.holdings.size():
		hold_blocks[h] = []
		var a := land.holding_area(h)
		for b in BW * BH:
			if a.has_point(block_rect(b).get_center()):
				hold_blocks[h].append(b)
			if h in rings:
				var r := block_rect(b)
				var all_in := true
				for y in range(r.position.y, r.end.y):
					for x in range(r.position.x, r.end.x):
						if not land.in_ring(h, Vector2i(x, y), 1):
							all_in = false
				if all_in:
					inner[b] = h
	for c in walls:
		if not walls_of.has(walls[c].h):
			walls_of[walls[c].h] = []
		walls_of[walls[c].h].append(c)
		var b := block_of(c)
		if not wall_blocks.has(b):
			wall_blocks[b] = []
		wall_blocks[b].append(c)
	for c in land.openings:
		if land.openings[c].kind == "door":
			doors[land.openings[c].house] = c


## Nightfall: packs rise from the graveyards and the crypt and set off for one of our cities.
func _rise() -> void:
	var owned := holdings_owned()
	var packs := 2 + day / 2 + owned.size() + (1 if altar_hp > 0.0 else 0)
	for k in packs:
		var from := block_of(land.graves[rng.randi() % land.graves.size()])
		if altar_hp > 0.0 and rng.randf() < 0.35:
			from = block_of(land.holdings[land.holdings.size() - 1].center)
		var goal: int = owned[rng.randi() % owned.size()]
		marches.append({"b": from, "n": rng.randi_range(4, 6 + day), "goal": goal, "t": rng.randf_range(0.0, 5.0)})
	_recount()


func _hordes(dt: float) -> void:
	for b in BW * BH:
		danger[b] = 1 if dead_at(b) > 0 else 0
	# packs on the march: a block every few seconds, by the shortest way the dead can walk
	for m in marches:
		m.t -= dt
		if m.t > 0.0:
			continue
		m.t = 5.0
		var to := _next_block(m.b, block_of(land.hall_rect(m.goal).get_center()))
		if to < 0:
			continue
		if inner.get(to, -1) >= 0 and inner.get(m.b, -1) != inner[to] and wall_blocks.has(m.b) and not _breach(m.b):
			continue                                      # the palisade holds them: they batter it (below)
		m.b = to
	_recount()
	# the dead batter walls and doors where they stand
	for b in wall_blocks:
		var n := dead_at(b)
		if n > 0 and not _breach(b):
			var best: Variant = null
			for c in wall_blocks[b]:
				if wall_standing(walls[c]) and land.holdings[walls[c].h].claimed and (best == null or float(walls[c].hp) < float(walls[best].hp)):
					best = c
			if best != null:
				_bash_wall(best, minf(n, 20) * 1.5 * dt)
	var occupied := {}
	for s in people:
		occupied[house_of(s.p)] = true
	for i in doors:
		var c: Vector2i = doors[i]
		var o: Dictionary = land.openings[c]
		if float(o.hp) <= 0.0 or not land.holdings[land.houses[i].holding].claimed:
			continue
		var n := dead_at(block_of(c))
		if n > 0 and occupied.has(i):
			_bash(c, minf(n, 10) * 1.5 * dt)
	# and fall on anyone in the open where they stand
	var by := {}
	for s in people:
		if _sheltered(s):
			continue
		var b := block_at(s.p)
		if danger[b] == 0:
			continue
		if not by.has(b):
			by[b] = []
		by[b].append(s)
	for b in by:
		var n := dead_at(b)
		if n <= 0:
			continue
		var here: Array = by[b]
		var on_each := mini(GRIP, ceili(float(n) / here.size()))
		var kills := 0.0
		for s in here:
			var harm: float = on_each * BITE * dt * armor(s) * (0.6 if s.trait == "Strong" else 1.0) / (1.0 + 0.15 * s.layer)
			s.hp -= harm
			s.asleep = false
			if s.hurt_t <= 0.0:
				s.hurt_t = 0.5
				_ev("hurt", s.p)
			kills += power(s) * dt / ZOMBIE_HP
			if s.hp <= 0.0:
				note("%s has fallen." % s.name)
				_ev("died", s.p)
		hurt_acc[b] = float(hurt_acc.get(b, 0.0)) + kills
		var k := int(hurt_acc[b])
		if k > 0:
			hurt_acc[b] -= k
			_kill(b, k)


## A broken stretch of palisade, an open gate or one never raised lets the dead through this block.
func _breach(b: int) -> bool:
	for c in wall_blocks[b]:
		var w: Dictionary = walls[c]
		if not land.holdings[w.h].claimed or not w.up or float(w.hp) <= 0.0 or (w.gate and w.open):
			return true
	return false


func _kill(b: int, k: int) -> void:
	for m in marches:
		if k > 0 and m.b == b:
			var d := mini(k, m.n)
			m.n -= d
			k -= d
	marches = marches.filter(func(m): return m.n > 0)
	_recount()
	var d2 := mini(k, horde[b])
	horde[b] -= d2
	for i in mini(d2 + 1, 3):
		_ev("kill", block_center(b) + Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50)))


## The next block toward a goal, over blocks the dead can cross.
func _next_block(from: int, goal: int) -> int:
	if from == goal:
		return -1
	if not block_fields.has(goal):
		var f := PackedInt32Array()
		f.resize(BW * BH)
		f.fill(-1)
		f[goal] = 0
		var q := [goal]
		var head := 0
		while head < q.size():
			var c: int = q[head]
			head += 1
			for o in [1, -1, BW, -BW]:
				var n: int = c + o
				if n < 0 or n >= BW * BH or (absi(o) == 1 and n / BW != c / BW) or f[n] != -1 or block_open[n] == 0:
					continue
				f[n] = f[c] + 1
				q.append(n)
		block_fields[goal] = f
	var fld: PackedInt32Array = block_fields[goal]
	var best := -1
	var bd := fld[from] if fld[from] >= 0 else 1 << 30
	for o in [1, -1, BW, -BW]:
		var n: int = from + o
		if n < 0 or n >= BW * BH or (absi(o) == 1 and n / BW != from / BW) or fld[n] < 0:
			continue
		if fld[n] < bd:
			bd = fld[n]
			best = n
	return best


## The nearest block with dead in it, within reach (and among the given blocks, if any are given).
func _nearest_dead(p: Vector2, reach: float, among: Array) -> int:
	var best := -1
	var bd := reach
	if among.is_empty():
		var c := block_at(p)
		var k := mini(int(reach / (BLOCK * T)) + 1, maxi(BW, BH))
		for y in range(maxi(0, c / BW - k), mini(BH, c / BW + k + 1)):
			for x in range(maxi(0, c % BW - k), mini(BW, c % BW + k + 1)):
				var b := y * BW + x
				if dead_at(b) > 0 and block_center(b).distance_to(p) < bd:
					bd = block_center(b).distance_to(p)
					best = b
		return best
	for b in among:
		if dead_at(b) <= 0:
			continue
		var d := block_center(b).distance_to(p)
		if d < bd:
			bd = d
			best = b
	return best


func _bash_wall(c: Vector2i, dmg: float) -> void:
	var w: Dictionary = walls[c]
	w.hp = float(w.hp) - dmg
	hurt_walls[c] = true
	_ev("bang", land.center(c))
	_noise(land.center(c), 220.0)
	if float(w.hp) <= 0.0:
		w.hp = 0.0
		w.open = false
		_ev("break", land.center(c))
		note("The %s of %s is broken through!" % ["gate" if w.gate else "palisade", land.holdings[w.h].name])


func _bash(c: Vector2i, dmg: float) -> void:
	var o: Dictionary = land.openings[c]
	o.hp = float(o.hp) - dmg
	_ev("bang", land.center(c))
	_noise(land.center(c), 280.0)
	if o.kind == "window":
		while int(o.planks) > 0 and float(o.hp) <= (int(o.planks) - 1) * PLANK_HP:
			o.planks = int(o.planks) - 1
			_ev("break", land.center(c))
	elif float(o.hp) <= 0.0:
		o.hp = 0.0
		o.planks = 0
		o.open = true
		_ev("break", land.center(c))
		for h in gates:
			if gates[h] == c and land.holdings[h].claimed:
				note("The gate of %s is broken!" % land.holdings[h].name)
