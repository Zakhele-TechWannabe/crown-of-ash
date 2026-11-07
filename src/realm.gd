extends RefCounted
## Crown of Ash as pure data: a realm of villages against the walking dead. Villagers live by themselves —
## farming, chopping, foraging, building, keeping watch, fighting — and you set jobs, rules and buildings, and send
## the warband to win back the land. Units are pixels.
##
## The dead don't know where anyone is. They see what's in front of them (little in the dark, much more where a
## hearth shows through an open window) and go to look wherever they hear a noise.

const Land := preload("res://src/land.gd")
const T := Land.T

const DAY_LEN := 300.0
const NIGHT_LEN := 130.0
const SR := 11.0
const ZR := 12.0
const DOOR_HP := 60.0
const PLANK_HP := 120.0
const ALTAR_HP := 700.0
const WALL_HP := 160.0
const GATE_HP := 240.0
const STAKE_WOOD := 0.25             # wood per palisade cell
const STAKE_WORK := 2.5              # seconds of work per palisade cell
const TOWERS := 4

enum { DAY, NIGHT, LOST, WON }
enum { IDLE, WANDER, INVESTIGATE, CHASE }

const JOBS := ["farm", "chop", "forage", "build", "guard", "soldier", "rest"]
const JOB_INFO := {
	"farm": "Works the village fields by day: food",
	"chop": "Fells trees for wood — the axe is loud",
	"forage": "Searches ruined cottages and brings back what they find",
	"build": "Builds the village's works and mends the gate",
	"guard": "Watches from the hall with a bow and shoots what comes close",
	"soldier": "Fights: escorts foragers, guards the fields or marches with the warband",
	"rest": "Stays in the hall and gets their strength back",
}
const TRAITS := {
	"Quiet": "Makes half the noise",
	"Strong": "Hits harder and takes less harm",
	"Skilled": "Works twice as fast",
	"Keen-eyed": "A sharper eye and a better shot",
}
const NAMES := ["Aldric", "Bryn", "Cedric", "Edith", "Gareth", "Hilda", "Isolde", "Jory", "Maud", "Osric", "Rowan",
	"Sybil", "Tamsin", "Ulric", "Wynn", "Agnes", "Bertram", "Elena", "Godric", "Leofa", "Merrick", "Nell", "Piers", "Rosamund"]

## What a soldier is trained as. Militia is everyone's start; the rest need a barracks where they live.
const UNITS := {
	"militia": {"name": "Militia", "dmg": 45.0, "armor": 1.0, "reach": 0.0, "cost": {}, "time": 0.0, "info": "Spear and buckler, no training"},
	"spearman": {"name": "Spearman", "dmg": 55.0, "armor": 0.8, "reach": 18.0, "cost": {"wood": 2}, "time": 30.0, "info": "A long spear: strikes before the dead can reach"},
	"archer": {"name": "Archer", "dmg": 25.0, "armor": 1.0, "reach": 0.0, "cost": {"wood": 3}, "time": 30.0, "info": "Shoots from 280 paces (uses arrows); weak up close"},
	"man_at_arms": {"name": "Man-at-arms", "dmg": 75.0, "armor": 0.45, "reach": 0.0, "cost": {"wood": 4, "food": 4}, "time": 45.0, "info": "Mail and a sword: hits hard, hard to kill"},
}
const ORDERS := {
	"escort": "Walks beside a forager and fights whatever comes for them",
	"fields": "Patrols the village's fields and woodcutters",
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
var stock := {"food": 12.0, "wood": 6.0, "arrows": 10, "herbs": 2}
var rules := {"hearths": false, "rations": "normal", "close_gate": true}
var built := {}                      # holding → {upgrade id: true}
var queue := {}                      # holding → [upgrade ids]
var progress := {}                   # holding → {upgrade id: seconds of work}
var bell_t := {}                     # holding → days since the last refugee
var marked := {}                     # house index → true: forage here first
var target := -1                     # the holding the warband is sent to win back
var altar_hp := ALTAR_HP
var people: Array = []
var dead: Array = []                 # the undead
var shots: Array = []
var noises: Array = []
var log: Array = []
var events: Array = []
var herds_left := 0
var herd_t := 0.0
var fields_cache := {}
var pass_calm := PackedByteArray()
var pass_alert := PackedByteArray()
var pass_sight := PackedByteArray()
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
		for c in land.openings:
			var o: Dictionary = land.openings[c]
			if o.house != land.holdings[h].hall:
				continue
			if o.kind == "door":
				gates[h] = c
			posts[h].append(land.center(c) + (land.center(_hall_center(h)) - land.center(c)).normalized() * T)
		for k in mini(6, hr.size.x - 2):
			beds[h].append(land.center(Vector2i(hr.position.x + 1 + k, hr.position.y + 1)))
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
	var jobs := ["farm", "farm", "chop", "forage", "build", "guard", "soldier", "soldier"]
	var traits := ["Skilled", "Quiet", "Strong", "Quiet", "Skilled", "Keen-eyed", "Strong", "Strong"]
	for k in jobs.size():
		_add_person(0, jobs[k], traits[k])
	people[6].order = "escort"
	people[7].order = "fields"
	# the dead hold every hamlet, and the crypt
	for h in range(1, land.holdings.size()):
		var crypt: bool = land.holdings[h].crypt
		# the further from Ashford, the more of them — and the crypt is a fortress
		var far: float = Vector2(land.holdings[h].center - land.holdings[0].center).length() / 30.0
		var count := 16 if crypt else int(5 + far * 4) + rng.randi_range(0, 2)
		var brutes := 4 if crypt else (1 if far > 0.9 else 0)
		var made := 0
		while made < count:
			var a := land.holding_area(h).grow(-3)
			var c := Vector2i(rng.randi_range(a.position.x, a.end.x - 1), rng.randi_range(a.position.y, a.end.y - 1))
			if land.at(c) in [Land.WALL, Land.WINDOW, Land.FOREST]:
				continue
			var kind := "brute" if made < brutes else ("runner" if rng.randf() < 0.15 * far else "walker")
			var z := _make_dead(land.center(c), kind, IDLE)
			made += 1
			z.lurker = h
	note("Ashford stands alone. The dead hold every village from here to the Black Crypt.")


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
			if not (x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1):
				continue
			var c := Vector2i(x, y)
			var t := land.at(c)
			if t in [Land.WALL, Land.FLOOR, Land.DOOR, Land.WINDOW]:
				continue
			var inn := Vector2i(1 if x == r.position.x else (-1 if x == r.end.x - 1 else 0), 0)
			if inn == Vector2i.ZERO:
				inn = Vector2i(0, 1 if y == r.position.y else -1)
			for k in [c, c + inn]:
				if land.at(k) == Land.FOREST:
					land.tiles[k.y * Land.W + k.x] = Land.GRASS
			walls[c] = {"h": h, "hp": 0.0, "up": false, "gate": t == Land.ROAD, "open": false, "work": 0.0, "in": inn}
	for k in [r.position + Vector2i(1, 1), Vector2i(r.end.x - 2, r.position.y + 1), Vector2i(r.position.x + 1, r.end.y - 2), r.end - Vector2i(2, 2)]:
		if land.at(k) == Land.FOREST:
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
	var used := people.map(func(s): return s.name)
	var name: String = NAMES[0]
	for n in NAMES:
		if not n in used:
			name = n
			break
	var at := hall_pos(home) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-20, 20))
	var s := {"name": name, "home": home, "p": at, "v": Vector2.ZERO, "face": Vector2.RIGHT, "hp": 100.0, "hunger": 85.0,
		"energy": 90.0, "job": job, "trait": kind, "doing": "", "goal": at, "path": [], "carry": {}, "house": -1, "busy": 0.0,
		"cd": 0.0, "sneak": false, "asleep": false, "hurt_t": 0.0, "step": 0.0, "noise_t": 0.0, "spot": Vector2i(-1, -1),
		"color": Color.from_hsv(rng.randf(), 0.4, 0.8),
		"unit": "militia", "order": "fields", "train": "", "train_t": 0.0, "ward": null}
	people.append(s)
	return s


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
	var a := land.holding_area(h)
	return dead.filter(func(z): return a.has_point(land.cell(z.p))).size()


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
	return not (t == Land.WALL or t == Land.WINDOW or t == Land.FOREST)


func _walk_dead(c: Vector2i, calm := false) -> bool:
	var w: Variant = walls.get(c)
	if wall_standing(w):
		return w.gate and w.open
	var t := land.at(c)
	if t == Land.WALL:
		return false
	if t == Land.DOOR:
		return bool(opening(c).open) or float(opening(c).hp) <= 0.0
	if t == Land.WINDOW:
		return not calm and int(opening(c).planks) == 0
	return true


func clear_at(c: Vector2i) -> bool:
	var t := land.at(c)
	return t != Land.WALL and t != Land.FOREST and _walk_dead(c)


func _los(a: Vector2, b: Vector2) -> bool:
	if pass_sight.is_empty():
		_passability()
	var d := b - a
	var n := int(d.length() / 10.0) + 1
	for i in range(1, n):
		var p := a + d * (float(i) / n)
		var x := int(p.x / T)
		var y := int(p.y / T)
		if x < 0 or y < 0 or x >= Land.W or y >= Land.H or pass_sight[y * Land.W + x] == 0:
			return false
	return true


func at_home(s: Dictionary) -> bool:
	return land.hall_rect(s.home).has_point(land.cell(s.p))


func in_any_hall(s: Dictionary) -> bool:
	for h in holdings_owned():
		if land.hall_rect(h).has_point(land.cell(s.p)):
			return true
	return false


func house_of(p: Vector2) -> int:
	var c := land.cell(p)
	for i in land.houses.size():
		if land.houses[i].rect.has_point(c):
			return i
	return -1


func crates_left(house: int) -> int:
	return land.crates.filter(func(c): return c.house == house and not c.searched).size()


# ---------------------------------------------------------------- step

func step(dt: float) -> void:
	events.clear()
	if phase in [LOST, WON]:
		return
	clock += dt
	if phase == DAY and clock >= DAY_LEN:
		phase = NIGHT
		clock = 0.0
		herds_left = 2 + day / 2 + holdings_owned().size() + (0 if altar_hp <= 0.0 else 1)
		herd_t = 6.0
		_ev("night")
		note("Night %d falls.%s" % [day, " Hearths are lit." if rules.hearths else ""])
	elif phase == NIGHT and clock >= NIGHT_LEN:
		day += 1
		phase = DAY
		clock = 0.0
		_dawn()
		_ev("dawn")
	for s in people:
		_person(s, dt)
	people = people.filter(func(s): return s.hp > 0.0)
	if phase == NIGHT:
		_herds(dt)
	_dead_step(dt)
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
	dead = dead.filter(func(z): return z.state == CHASE or z.get("lurker", -1) >= 0)
	for cr in land.crates:
		if cr.searched and rng.randf() < 0.2:
			cr.searched = false
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
	note("Day %d. %d souls, %d of 7 villages held." % [day, people.size(), holdings_owned().size()])


# ---------------------------------------------------------------- the warband

func send_warband(h: int) -> String:
	if land.holdings[h].claimed:
		return "That village is already yours"
	if target != h and not people.any(func(s): return s.job == "soldier" and s.order == "warband"):
		return "No soldier has the warband order"
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
	s.hunger = maxf(0.0, s.hunger - dt * 100.0 / 620.0)
	if s.hunger <= 0.0:
		s.hp -= dt * 0.7
	if not s.asleep:
		s.energy = maxf(0.0, s.energy - dt * 100.0 / 480.0)
	if in_any_hall(s):
		var half: bool = rules.rations == "half"
		if s.hunger < 45.0 and stock.food >= (0.5 if half else 1.0):
			stock.food -= 0.5 if half else 1.0
			s.hunger = minf(100.0, s.hunger + (30.0 if half else 50.0))
		if s.hp < 60.0 and stock.herbs > 0:
			stock.herbs -= 1
			s.hp = minf(100.0, s.hp + 35.0)
		if s.hp < 100.0 and s.hunger > 30.0:
			s.hp = minf(100.0, s.hp + dt * (1.5 if has_built(s.home, "chapel") else 0.6))
	_decide(s, dt)
	_walk(s, dt)


func _decide(s: Dictionary, dt: float) -> void:
	var threat: Variant = _chaser_of(s)
	if threat != null and s.doing != "flee" and s.doing != "fight":
		var n := dead.filter(func(z): return z.state == CHASE and z.target == s).size()
		if s.job == "soldier" or (s.trait == "Strong" and n <= 2) or (n == 1 and s.hp > 50.0):
			s.doing = "fight"
		else:
			s.doing = "flee"
	match s.doing:
		"fight":
			if threat == null:
				s.doing = ""
				return
			s.asleep = false
			_melee(s, threat)
			return
		"flee":
			s.asleep = false
			if in_any_hall(s) or threat == null:
				s.doing = ""
				return
			_go(s, hall_pos(s.home))
			return
	var dusk := phase == DAY and time_left() < 30.0
	if phase == NIGHT or dusk:
		if (s.job == "guard" or s.job == "soldier") and s.energy > 15.0 and _post_index(s) < tower_count[s.home]:
			_deposit_if_home(s)
			_guard(s, dt)
			return
		if not at_home(s):
			s.doing = "heading home"
			_deposit_if_home(s)
			_go(s, hall_pos(s.home))
			if not at_home(s):
				return
		_deposit_if_home(s)
		if (s.job == "guard" or s.job == "soldier") and s.energy > 15.0:
			_guard(s, dt)
		else:
			_sleep(s, dt)
		return
	if s.energy < 20.0 or s.hp < 35.0:
		if at_home(s):
			_sleep(s, dt)
		else:
			s.doing = "heading home"
			_go(s, hall_pos(s.home))
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
		_:
			if s.energy < 90.0:
				_sleep(s, dt)
			else:
				_idle(s)


func _idle(s: Dictionary) -> void:
	s.doing = "idle"
	if s.p.distance_to(s.goal) < 6.0 or not land.hall_rect(s.home).has_point(land.cell(s.goal)):
		s.goal = hall_pos(s.home) + Vector2(rng.randf_range(-60, 60), rng.randf_range(-30, 30))
		s.path = []
	_go(s, s.goal)


func _sleep(s: Dictionary, dt: float) -> void:
	var list: Array = beds[s.home]
	var mine := people.filter(func(o): return o.home == s.home)
	var bed: Vector2 = list[mine.find(s) % list.size()] + Vector2(0, (mine.find(s) / list.size()) * 10.0)
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
	return 2.0 if s.trait == "Skilled" else 1.0


func _farm(s: Dictionary, dt: float) -> void:
	var fields: Array = land.holdings[s.home].fields
	if fields.is_empty():
		_idle(s)
		return
	if s.spot == Vector2i(-1, -1) or not s.spot in fields:
		s.spot = fields[rng.randi() % fields.size()]
	s.doing = "working the fields"
	if _work_at(s, land.center(s.spot)):
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
		var best: Variant = null
		var bd := reach
		for z in dead:
			var d: float = z.p.distance_to(s.p)
			if d < bd and (z.state in [CHASE, INVESTIGATE] or d < 120.0) and _clear_shot(s.p, z.p):
				bd = d
				best = z
		if best != null:
			s.cd = 1.4
			stock.arrows -= 1
			if rng.randf() < 0.6:
				stock.arrows += 1                         # gathered again in the morning
			s.face = (best.p - s.p).normalized()
			shots.append([s.p, best.p, 0.08])
			_noise(s.p, 50.0)
			_ev("arrow", s.p)
			if rng.randf() < (0.85 if s.trait == "Keen-eyed" else 0.65):
				_hit(best, 120.0, s.face * 150.0)


## Guards take the towers first, then the hall's windows. Soldiers off duty stand behind the guards.
func _post_index(s: Dictionary) -> int:
	var k := 0
	for o in people:
		if o.home != s.home or o == s:
			continue
		if o.job == "guard" and (s.job == "soldier" or people.find(o) < people.find(s)):
			k += 1
		elif o.job == "soldier" and s.job == "soldier" and people.find(o) < people.find(s):
			k += 1
	return k


## Archers shoot out through their own windows; walls, shut doors and trees stop arrows.
func _clear_shot(a: Vector2, b: Vector2) -> bool:
	var d := b - a
	var n := int(d.length() / 10.0) + 1
	for i in range(1, n):
		var c := land.cell(a + d * (float(i) / n))
		var t := land.at(c)
		if t == Land.WALL or t == Land.FOREST:
			return false
		if t == Land.DOOR and not bool(opening(c).open) and float(opening(c).hp) > 0.0:
			return false
	return true


func _melee(s: Dictionary, z: Dictionary) -> void:
	var u: Dictionary = UNITS[s.unit] if s.job == "soldier" else UNITS.militia
	var d: float = s.p.distance_to(z.p)
	s.face = (z.p - s.p).normalized()
	if s.job == "soldier" and s.unit == "archer" and stock.arrows > 0 and d > 45.0:
		if d < 280.0 and _clear_shot(s.p, z.p):
			s.path = []
			s.goal = s.p
			if s.cd <= 0.0:
				s.cd = 1.1
				stock.arrows -= 1
				if rng.randf() < 0.5:
					stock.arrows += 1
				shots.append([s.p, z.p, 0.08])
				_noise(s.p, 50.0)
				_ev("arrow", s.p)
				if rng.randf() < (0.85 if s.trait == "Keen-eyed" else 0.7):
					_hit(z, 110.0, s.face * 150.0)
			return
		_go(s, z.p)
		return
	if d < SR + ZR + 14.0 + float(u.reach):
		s.path = []
		s.goal = s.p
		if s.cd <= 0.0:
			s.cd = 0.7
			_hit(z, float(u.dmg) * (1.4 if s.trait == "Strong" else 1.0), s.face * 160.0)
			_noise(s.p, 60.0)
	elif s.job == "soldier":
		_go(s, z.p)


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


## Guards fight what is hunting their people or has come right up to them — they don't go picking fights.
func _threat(guard: Dictionary, wards: Array, reach: float) -> Variant:
	var best: Variant = null
	var bd := 1e9
	for z in dead:
		var hunting: bool = z.state == CHASE and (z.target == guard or wards.has(z.target))
		for w in wards + [guard]:
			var d: float = z.p.distance_to(w.p)
			if (d < reach * 0.45 or (hunting and d < reach)) and d < bd:
				bd = d
				best = z
	return best


func _engage(s: Dictionary, z: Dictionary, what: String) -> void:
	s.doing = what
	s.asleep = false
	if s.p.distance_to(z.p) < 240.0 and z.state != CHASE:
		z.state = CHASE                                  # they turn on whoever comes at them
		z.target = s
		_rouse(z, s)
	_melee(s, z)


func _ward(s: Dictionary) -> Variant:
	var w: Variant = s.ward
	if w != null and people.has(w) and w.job == "forage":
		return w
	s.ward = null
	var best: Variant = null
	var bn := 99
	for f in people:
		if f.job != "forage":
			continue
		var n := people.filter(func(o): return o.job == "soldier" and o.ward == f).size() + (0 if f.home == s.home else 2)
		if n < bn:
			bn = n
			best = f
	s.ward = best
	return best


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
	match s.order:
		"escort":
			var f: Variant = _ward(s)
			if f != null:
				var z: Variant = _threat(s, [f], 240.0)
				if z != null:
					_engage(s, z, "defending " + f.name)
					return
				s.doing = "escorting " + f.name
				if s.p.distance_to(f.p) > 45.0:
					_go(s, f.p - f.face * 26.0)
				else:
					s.path = []
				return
			_patrol(s, dt)
			return
		"fields":
			_patrol(s, dt)
			return
	if target < 0:
		_guard(s, dt)
		return
	var h := target
	var a := land.holding_area(h)
	# fight the nearest of the dead in that village
	var best: Variant = null
	var bd := 1e9
	for z in dead:
		if not a.has_point(land.cell(z.p)):
			continue
		var d: float = z.p.distance_to(s.p)
		if d < bd:
			bd = d
			best = z
	if best != null:
		s.doing = "fighting at " + land.holdings[h].name
		if s.p.distance_to(best.p) < 220.0 and best.state != CHASE:
			best.state = CHASE                            # the dead turn to meet them
			best.target = s
		_melee(s, best)
		_go(s, best.p)
		return
	if land.holdings[h].crypt and altar_hp > 0.0:
		s.doing = "breaking the crypt's altar"
		if _work_at(s, hall_pos(h)) and s.cd <= 0.0:
			s.cd = 0.8
			altar_hp -= 40.0 * (1.4 if s.trait == "Strong" else 1.0)
			_noise(s.p, 200.0)
			_ev("hit", hall_pos(h))
		return
	s.doing = "marching to " + land.holdings[h].name
	_go(s, hall_pos(h))


## Fields order: walk the village's fields and fight anything that comes near the people working outside.
func _patrol(s: Dictionary, dt: float) -> void:
	var wards: Array = []
	for o in people:
		if o.home == s.home and o.job in ["farm", "chop", "build"] and not in_any_hall(o):
			wards.append(o)
	var z: Variant = _threat(s, wards, 300.0)
	if z != null:
		_engage(s, z, "guarding the fields")
		return
	var fields: Array = land.holdings[s.home].fields
	if fields.is_empty():
		_guard(s, dt)
		return
	s.doing = "patrolling the fields"
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
					_touch(gates[h])
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
	for c in walls:
		var w: Dictionary = walls[c]
		if w.h != s.home or not w.up or float(w.hp) >= wall_max(w) - 1.0:
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
			_touch(best)
			_noise(s.p, 120.0)
	return true


func _raise_palisade(s: Dictionary, dt: float, up: Dictionary) -> void:
	var h: int = s.home
	if s.spot == Vector2i(-1, -1) or not walls.has(s.spot) or walls[s.spot].up or walls[s.spot].h != h:
		s.spot = Vector2i(-1, -1)
		var bd := 1e9
		for c in walls:
			var w: Dictionary = walls[c]
			if w.h == h and not w.up:
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
			_touch(s.spot)
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
			_touch(gates[h])
		"shutters":
			for c in land.openings:
				var o: Dictionary = land.openings[c]
				if o.kind == "window" and o.house == land.holdings[h].hall:
					o.planks = 3
					o.hp = 3 * PLANK_HP
					_touch(c)


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
			_go(s, hall_pos(s.home))
		return
	if s.house < 0 or crates_left(s.house) == 0:
		s.house = _pick_house(s)
		if s.house < 0:
			s.doing = "nothing left to search"
			_idle(s)
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
	s.doing = "searching " + land.holdings[land.houses[s.house].holding].name
	if s.p.distance_to(land.center(cr.cell)) > 20.0:
		_go(s, land.center(cr.cell))
		return
	s.path = []
	s.goal = s.p
	s.busy += dt
	if s.busy >= 1.4:
		s.busy = 0.0
		_noise(s.p, 30.0 if s.trait == "Quiet" else 60.0)
		_loot(s, cr)


func _pick_house(s: Dictionary) -> int:
	var best := -1
	var bd := 1e9
	for i in land.houses.size():
		var hol: int = land.houses[i].holding
		if land.holdings[hol].crypt or crates_left(i) == 0:
			continue
		var d := land.center(land.houses[i].rect.get_center()).distance_to(s.p)
		if marked.has(i):
			d -= 20000.0
		elif not land.holdings[hol].claimed:
			d += 900.0 + dead_in(hol) * 300.0               # the dead still hold it: only if nothing else
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
	if rng.randf() < 0.05 and people.size() < 30:
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
	if s.path.is_empty() or land.cell(s.goal) != land.cell(to):
		s.path = _route(land.cell(s.p), land.cell(to))
	s.goal = to


func _route(a: Vector2i, b: Vector2i) -> Array:
	if a == b:
		return [b]                                    # same cell: walk straight to the spot
	var prev := {a: a}
	var q: Array[Vector2i] = [a]
	var head := 0
	while head < q.size():
		var c := q[head]
		head += 1
		if c == b:
			break
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + o
			if prev.has(n) or n.x < 0 or n.y < 0 or n.x >= Land.W or n.y >= Land.H or (not _walk_person(n) and n != b):
				continue
			prev[n] = c
			q.append(n)
	var out: Array = []
	if not prev.has(b):
		return out
	var cur := b
	while cur != a:
		out.push_front(cur)
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
		_touch(c)
		_noise(land.center(c), 110.0)
		_ev("door", land.center(c))
	var wg: Variant = walls.get(c)
	if wall_standing(wg) and wg.gate and not wg.open:
		wg.open = true
		_touch(c)
		_noise(land.center(c), 110.0)
		_ev("door", land.center(c))
	var near := dead.any(func(z): return z.p.distance_to(s.p) < 260.0)
	s.sneak = near and s.doing != "flee" and s.job != "soldier"
	var speed := 230.0 if s.doing == "flee" else (70.0 if s.sneak else 125.0)
	var d: Vector2 = tgt - s.p
	if d.length() < 6.0:
		s.path.pop_front()
		_close_gate_behind(s, c)
		return
	s.v = d.normalized() * speed
	s.face = d.normalized()
	s.p += s.v * dt
	s.step += dt * speed * 0.08
	if not s.sneak:
		s.noise_t -= dt
		if s.noise_t <= 0.0 and s.job != "chop":
			s.noise_t = 0.35 if s.doing == "flee" else 0.6
			_noise(s.p, 230.0 if s.doing == "flee" else (35.0 if s.trait == "Quiet" else 60.0))


func _close_gate_behind(s: Dictionary, passed: Vector2i) -> void:
	if not rules.close_gate:
		return
	var wg: Variant = walls.get(passed)
	if wall_standing(wg) and wg.gate and wg.open:
		var r2 := Rect2(passed.x * T, passed.y * T, T, T).grow(ZR)
		if not dead.any(func(z): return r2.has_point(z.p)):
			wg.open = false
			_touch(passed)
			_noise(land.center(passed), 80.0)
		return
	for h in gates:
		if gates[h] != passed:
			continue
		var o: Dictionary = land.openings[passed]
		if o.open and float(o.hp) > 0.0:
			var r := Rect2(passed.x * T, passed.y * T, T, T).grow(ZR)
			if not dead.any(func(z): return r.has_point(z.p)):
				o.open = false
				_touch(passed)
				_noise(land.center(passed), 80.0)


func _chaser_of(s: Dictionary) -> Variant:
	var best: Variant = null
	var bd := 1e9
	for z in dead:
		if z.state == CHASE and z.target == s:
			var d: float = z.p.distance_to(s.p)
			if d < bd:
				bd = d
				best = z
	return best


func _hit(z: Dictionary, dmg: float, knock: Vector2) -> void:
	z.hp -= dmg
	z.v += knock
	z.stun = 0.4
	_ev("hit", z.p)
	if z.hp <= 0.0:
		dead.erase(z)
		_ev("kill", z.p)


# ---------------------------------------------------------------- noise and sight

func _noise(at: Vector2, radius: float) -> void:
	noises.append([at, radius, 0.6])
	for z in dead:
		if z.state == CHASE:
			continue
		var d: float = z.p.distance_to(at)
		var r := radius if _los(z.p, at) else radius * 0.55
		if d < r:
			z.state = INVESTIGATE
			z.goal = at + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
			z.look = 0.0


func sight_of(s: Dictionary) -> float:
	var dark := night_ratio() > 0.5
	var r := 105.0 if dark else 240.0
	if dark and house_of(s.p) >= 0:
		r = 40.0
		if rules.hearths and in_any_hall(s) and not has_built(s.home, "shutters"):
			r = 420.0                                      # the hearth shows through the windows
	if s.sneak:
		r *= 0.6
	if s.asleep:
		r *= 0.5
	return r


func _sees(z: Dictionary, s: Dictionary) -> bool:
	var d: Vector2 = s.p - z.p
	if d.length() > sight_of(s):
		return false
	if z.state != CHASE and absf(z.face.angle_to(d)) > 1.2:
		return false
	return _los(z.p, s.p)


# ---------------------------------------------------------------- the dead

func _make_dead(at: Vector2, kind: String, state: int) -> Dictionary:
	var hpv: float = {"walker": 100.0, "runner": 70.0, "brute": 260.0}[kind]
	var z := {"p": at, "v": Vector2.ZERO, "hp": hpv, "kind": kind, "state": state, "goal": at, "home": at,
		"face": Vector2.RIGHT.rotated(rng.randf() * TAU), "sus": 0.0, "lost": 0.0, "look": 0.0, "attack_t": 0.0,
		"stun": 0.0, "step": rng.randf() * 10.0, "herd": false, "target": null, "lurker": -1}
	dead.append(z)
	return z


## At night the dead rise from the graveyards (and the crypt) and drift toward the smell of the living.
func _herds(dt: float) -> void:
	herd_t -= dt
	if herd_t > 0.0 or herds_left <= 0 or clock > NIGHT_LEN - 20.0:
		return
	herds_left -= 1
	herd_t = rng.randf_range(8.0, 16.0)
	var from: Vector2i = land.graves[rng.randi() % land.graves.size()]
	if altar_hp > 0.0 and rng.randf() < 0.35:
		from = land.holdings[land.holdings.size() - 1].center
	var owned := holdings_owned()
	var to: Vector2 = hall_pos(owned[rng.randi() % owned.size()]) + Vector2(rng.randf_range(-200, 200), rng.randf_range(-160, 160))
	for k in rng.randi_range(3, 3 + day / 2):
		var kind := "walker"
		if day >= 3 and rng.randf() < 0.1 + day * 0.02:
			kind = "runner"
		elif day >= 6 and rng.randf() < 0.07:
			kind = "brute"
		var z := _make_dead(land.center(from) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40)), kind, WANDER)
		z.goal = to
		z.herd = true


func _field(target_cell: Vector2i, calm: bool) -> PackedInt32Array:
	var key := Vector3i(target_cell.x, target_cell.y, int(calm))
	if fields_cache.has(key) and clock - float(fields_cache[key][1]) < (3.0 if calm else 1.2) and fields_cache[key][2] == phase:
		return fields_cache[key][0]
	var f := PackedInt32Array()
	f.resize(Land.W * Land.H)
	f.fill(-1)
	if target_cell.x < 0 or target_cell.y < 0 or target_cell.x >= Land.W or target_cell.y >= Land.H:
		return f
	if pass_calm.is_empty():
		_passability()
	var open := pass_calm if calm else pass_alert
	var q := PackedInt32Array()
	q.resize(Land.W * Land.H)
	var start := target_cell.y * Land.W + target_cell.x
	q[0] = start
	var tail := 1
	f[start] = 0
	var head := 0
	while head < tail:
		var i := q[head]
		head += 1
		var x := i % Land.W
		var nd := f[i] + 1
		for n in [i + 1 if x < Land.W - 1 else -1, i - 1 if x > 0 else -1, i + Land.W, i - Land.W]:
			if n < 0 or n >= Land.W * Land.H or f[n] != -1 or open[n] == 0:
				continue
			f[n] = nd
			q[tail] = n
			tail += 1
	if fields_cache.size() > 60:
		fields_cache.clear()
	fields_cache[key] = [f, clock, phase]
	return f


## Where the dead can walk, cell by cell — refreshed a few times a second for the flow fields.
func _passability() -> void:
	pass_calm.resize(Land.W * Land.H)
	pass_sight.resize(Land.W * Land.H)
	pass_alert.resize(Land.W * Land.H)
	pass_sight.resize(Land.W * Land.H)
	for y in Land.H:
		for x in Land.W:
			var c := Vector2i(x, y)
			pass_alert[y * Land.W + x] = 0 if land.tiles[y * Land.W + x] == Land.WALL else 1
			_touch(c)


## A door, window or stretch of wall changed: update what the dead can see and walk through there.
func _touch(c: Vector2i) -> void:
	if pass_calm.is_empty():
		return
	var i := c.y * Land.W + c.x
	pass_calm[i] = 1 if _walk_dead(c, true) else 0
	pass_sight[i] = 1 if clear_at(c) else 0


func _toward(z: Dictionary, goal: Vector2) -> Vector2:
	var calm: bool = int(z.state) in [IDLE, WANDER]
	if z.p.distance_squared_to(goal) < 62500.0 and _los(z.p, goal):
		return (goal - z.p).normalized()
	var f := _field(land.cell(goal), calm)
	var c := land.cell(z.p)
	if c.x < 0 or c.y < 0 or c.x >= Land.W or c.y >= Land.H:
		return (goal - z.p).normalized()
	var best := f[c.y * Land.W + c.x]
	if best <= 0:
		return (goal - z.p).normalized()
	var dir := Vector2.ZERO
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + o
		if n.x < 0 or n.y < 0 or n.x >= Land.W or n.y >= Land.H:
			continue
		var d := f[n.y * Land.W + n.x]
		if d >= 0 and d < best:
			best = d
			dir = land.center(n) - z.p
	return dir.normalized() if dir != Vector2.ZERO else (goal - z.p).normalized()


func _slide(at: Vector2, d: Vector2, calm: bool) -> Vector2:
	var out := at
	for axis in 2:
		var mv := Vector2(d.x, 0) if axis == 0 else Vector2(0, d.y)
		if not _blocked(out + mv, calm):
			out += mv
	return out


func _blocked(at: Vector2, calm: bool) -> bool:
	var c0 := land.cell(at - Vector2(ZR, ZR))
	var c1 := land.cell(at + Vector2(ZR, ZR))
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			if _walk_dead(Vector2i(x, y), calm):
				continue
			var rect := Rect2(x * T, y * T, T, T)
			var q := Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
			if q.distance_squared_to(at) < ZR * ZR:
				return true
	return false


func _dead_step(dt: float) -> void:
	var speeds := {"walker": 44.0, "runner": 120.0, "brute": 36.0}
	for z in dead:
		z.stun = maxf(0.0, z.stun - dt)
		z.attack_t -= dt
		if int(z.state) == IDLE and not people.any(func(s): return z.p.distance_squared_to(s.p) < 250000.0):
			z.sus = maxf(0.0, z.sus - dt * 0.4)          # nobody about: they just stand and sway
			if rng.randf() < dt * 0.3:
				z.face = Vector2.RIGHT.rotated(rng.randf() * TAU)
			z.v = Vector2.ZERO
			continue
		var seen: Variant = null
		for s in people:
			if z.p.distance_squared_to(s.p) < 180000.0 and _sees(z, s):
				seen = s
				break
		if seen != null:
			var close := 1.0 - clampf(z.p.distance_to(seen.p) / sight_of(seen), 0.0, 1.0)
			z.sus = minf(1.0, z.sus + dt * (0.8 + close * 2.5))
			if z.sus >= 1.0 and z.state != CHASE:
				z.state = CHASE
				z.target = seen
				z.lost = 0.0
				_ev("noticed", z.p)
				_rouse(z, seen)
				if seen.job != "soldier":
					note("The dead have seen %s!" % seen.name)
			elif z.state != CHASE:
				z.face = z.face.slerp((seen.p - z.p).normalized(), minf(1.0, dt * 2.0))
		elif z.state != CHASE:
			z.sus = maxf(0.0, z.sus - dt * 0.4)
		var spd: float = speeds[z.kind]
		var want := Vector2.ZERO
		match int(z.state):
			IDLE:
				if rng.randf() < dt * 0.3:
					z.face = Vector2.RIGHT.rotated(rng.randf() * TAU)
				want = z.face * 0.15 if z.p.distance_to(z.home) < 50.0 else (z.home - z.p).normalized() * 0.3
			WANDER:
				want = _toward(z, z.goal) * 0.6
				if z.p.distance_to(z.goal) < 40.0:
					z.state = INVESTIGATE
					z.look = 0.0
			INVESTIGATE:
				if z.p.distance_to(z.goal) > 24.0:
					want = _toward(z, z.goal) * 0.85
				else:
					z.look += dt
					if fmod(z.look, 1.2) < dt:
						z.face = z.face.rotated(rng.randf_range(1.5, 3.0))
					if z.look > 6.0:
						if z.lurker >= 0:
							z.state = IDLE
						else:
							z.state = WANDER
							z.goal = z.p + Vector2(rng.randf_range(-400, 400), rng.randf_range(-300, 300))
							z.goal = z.goal.clamp(Vector2(40, 40), Vector2(Land.W, Land.H) * T - Vector2(40, 40))
			CHASE:
				var tgt: Variant = z.target
				if tgt == null or not people.has(tgt):
					z.state = INVESTIGATE
					z.look = 0.0
				else:
					if _los(z.p, tgt.p) and z.p.distance_to(tgt.p) < sight_of(tgt) * 1.6 + 60.0:
						z.goal = tgt.p
						z.lost = 0.0
					else:
						z.lost += dt
						if z.lost > 4.0:
							z.state = INVESTIGATE
							z.look = 0.0
							z.sus = 0.4
					want = _toward(z, z.goal)
					spd *= 1.25
		if int(z.state) in [CHASE, INVESTIGATE] and want != Vector2.ZERO:
			var ahead := land.cell(z.p + want * (ZR + 8.0))
			var t := land.at(ahead)
			if walls.has(ahead) and not _walk_dead(ahead):
				want = Vector2.ZERO
				if z.attack_t <= 0.0:
					z.attack_t = 1.0
					_bash_wall(ahead, 40.0 if z.kind == "brute" else 12.0)
			elif (t == Land.DOOR or t == Land.WINDOW) and not _walk_dead(ahead):
				want = Vector2.ZERO
				if z.attack_t <= 0.0:
					z.attack_t = 1.0
					_bash(ahead, 40.0 if z.kind == "brute" else 12.0)
		if z.stun > 0.0:
			want = Vector2.ZERO
		if land.at(land.cell(z.p)) == Land.WINDOW:
			spd *= 0.35
		elif land.at(land.cell(z.p)) == Land.FOREST:
			spd *= 0.6
		z.v = z.v.lerp(want * spd, 1.0 - exp(-6.0 * dt))
		if z.v.length() > 5.0:
			z.face = z.face.slerp(z.v.normalized(), minf(1.0, dt * 4.0))
		if z.v.length_squared() > 0.5:
			z.p = _slide(z.p, z.v * dt, int(z.state) in [IDLE, WANDER])
		z.step += dt * z.v.length() * 0.08
		for s in people:
			if z.p.distance_to(s.p) < SR + ZR + 4.0 and z.attack_t <= 0.0 and z.stun <= 0.0:
				z.attack_t = 1.0 if z.kind != "runner" else 0.7
				z.state = CHASE
				z.target = s
				s.asleep = false
				if s.hurt_t <= 0.0:
					s.hp -= (12.0 if z.kind != "brute" else 28.0) * (0.6 if s.trait == "Strong" else 1.0) * armor(s)
					s.hurt_t = 0.35
					_ev("hurt", s.p)
					if s.hp <= 0.0:
						note("%s has fallen." % s.name)
						_ev("died", s.p)
				break
	# shoulder each other apart: only neighbours in the same or adjacent cells can touch
	var grid := {}
	for z in dead:
		var k := land.cell(z.p)
		if grid.has(k):
			grid[k].append(z)
		else:
			grid[k] = [z]
	for k in grid:
		var here: Array = grid[k]
		for nb in [k, k + Vector2i(1, 0), k + Vector2i(1, 1), k + Vector2i(0, 1), k + Vector2i(-1, 1)]:
			if not grid.has(nb):
				continue
			var there: Array = grid[nb]
			for i in here.size():
				for j in (range(i + 1, there.size()) if nb == k else range(there.size())):
					var a: Dictionary = here[i]
					var b: Dictionary = there[j]
					var d: Vector2 = a.p - b.p
					var l := d.length()
					if l < ZR * 2.0 and l > 0.01:
						var push := d / l * (ZR * 2.0 - l) * 0.5
						a.p = _slide(a.p, push, false)
						b.p = _slide(b.p, -push, false)


## The dead lurking in a village come as a pack when one of them finds someone.
func _rouse(z: Dictionary, s: Dictionary) -> void:
	if int(z.lurker) < 0:
		return
	for o in dead:
		if o.lurker == z.lurker and o.state != CHASE and o.p.distance_to(z.p) < 280.0:
			o.state = INVESTIGATE
			o.goal = s.p
			o.look = 0.0


func _bash_wall(c: Vector2i, dmg: float) -> void:
	var w: Dictionary = walls[c]
	w.hp = float(w.hp) - dmg
	_ev("bang", land.center(c))
	_noise(land.center(c), 220.0)
	if float(w.hp) <= 0.0:
		w.hp = 0.0
		w.open = false
		_touch(c)
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
			_touch(c)
			_ev("break", land.center(c))
	elif float(o.hp) <= 0.0:
		o.hp = 0.0
		o.planks = 0
		o.open = true
		_touch(c)
		_ev("break", land.center(c))
		for h in gates:
			if gates[h] == c and land.holdings[h].claimed:
				note("The gate of %s is broken!" % land.holdings[h].name)
