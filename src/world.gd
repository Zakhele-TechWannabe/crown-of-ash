extends RefCounted
## A settlement's people are counts; policies guide their shared daily work.

const Land := preload("res://src/land.gd")
const DAY_LEN := 60.0
const DAYS_PER_YEAR := 12
const HOUSE_CAPACITY := 20
const POLICY_NAMES := [["Food", "Balanced", "Construction"], ["Lean", "Normal", "Generous"], ["Encourage", "Neutral", "Restrain"]]
const DESCRIPTIONS := [
	["More farmers; slower construction.", "Equal care for food, timber and shelter.", "More builders; fewer farmers."],
	["Eat less; fewer births and greater mortality.", "Ordinary meals and ordinary health.", "Eat more; healthier families and more births."],
	["More births, with extra food for families.", "Families grow at their natural pace.", "Fewer births and slightly lower food use."]
]
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var land := Land.new()
var population := 100
var food := 300.0
var wood := 100.0
var clock := 0.0
var day := 1
var year := 1
var policies: Array[int] = [1, 1, 1]
var houses: Array[Vector2i] = []
var fields: Array[Vector2i] = []
var roads: Array[Vector2i] = []
var center := Vector2i.ZERO
var revision := 0
var births := 0
var deaths := 0
var last_births := 0
var last_deaths := 0
var log: Array[String] = []
var labour := Vector3.ZERO
var project := -1
var site := Vector2i.ZERO
var work_left := 0.0
var birth_fraction := 0.0
var death_fraction := 0.0
var timber_work := 0.0
var famine := false
var year_population := 100


## Founding families bring supplies and establish their first huts and fields.
func _init(seed_value: int = 41) -> void:
	land.build(seed_value)
	var best := INF
	for y in range(20, 58):
		for x in range(38, 74):
			var p := Vector2i(x, y)
			if land.at(p) != Land.GRASS:
				continue
			var score := p.distance_squared_to(Vector2i(52, 39))
			if score < best:
				best = score
				center = p
	_set_tile(center, Land.ROAD)
	roads.append(center)
	for i in 5:
		_found(Land.HOUSE)
	for i in 8:
		_found(Land.FIELD)
	_update_labour()
	_note("100 people found a settlement.")


## Shelter comes only from completed houses.
func housing() -> int:
	return houses.size() * HOUSE_CAPACITY


## Days resolve at fixed boundaries even when a large time step crosses several.
func step(dt: float) -> void:
	clock += maxf(0.0, dt)
	while clock >= DAY_LEN:
		clock -= DAY_LEN
		_daily()


## Policy shares divide the whole population into three aggregate labour pools.
func _update_labour() -> void:
	var shares: Vector3 = [Vector3(0.7, 0.2, 0.1), Vector3(0.55, 0.25, 0.2), Vector3(0.4, 0.25, 0.35)][policies[0]]
	labour = shares * population


## Meals reflect both ration size and support for growing families.
func food_need() -> float:
	return population * float([0.8, 1.0, 1.2][policies[1]]) * float([1.08, 1.0, 0.96][policies[2]])


## Crops reward land and labour; six percent of stored food spoils each day.
func _daily() -> void:
	_update_labour()
	var capacity := fields.size() * 22.0
	food *= 0.94
	food += capacity * labour.x / (labour.x + fields.size() * 3.0)
	var need := food_need()
	var shortage := maxf(0.0, need - food) / maxf(1.0, need)
	food = maxf(0.0, food - need)
	if shortage > 0.0 and not famine:
		_note("Famine: meals fall short.")
	elif shortage == 0.0 and famine:
		_note("The settlement has food again.")
	famine = shortage > 0.0
	_cut_timber()
	_construct()
	var surplus := clampf(food / maxf(1.0, need * 2.0), 0.0, 1.0)
	var shelter := clampf(float(housing() - population) / 10.0, 0.0, 1.0)
	birth_fraction += population * 0.006 * surplus * shelter * float([1.5, 1.0, 0.4][policies[2]]) * float([0.7, 1.0, 1.2][policies[1]])
	death_fraction += population * (float([0.0015, 0.001, 0.0008][policies[1]]) + shortage * 0.04)
	var born := int(birth_fraction)
	var died := mini(population, int(death_fraction))
	birth_fraction -= born
	death_fraction -= died
	population += born - died
	births += born
	deaths += died
	day += 1
	if day > DAYS_PER_YEAR:
		last_births = births
		last_deaths = deaths
		_note("Year ends: population %d (%+d)." % [population, population - year_population])
		year_population = population
		births = 0
		deaths = 0
		day = 1
		year += 1
	_update_labour()


## Woodcutters harvest one nearby forest tile per twenty timber units.
func _cut_timber() -> void:
	timber_work += labour.y * 0.7
	while timber_work >= 20.0:
		var tree := Vector2i(-1, -1)
		var nearest := INF
		for y in range(maxi(0, center.y - 18), mini(Land.H, center.y + 19)):
			for x in range(maxi(0, center.x - 18), mini(Land.W, center.x + 19)):
				var p := Vector2i(x, y)
				var distance := p.distance_squared_to(center)
				if land.at(p) == Land.FOREST and distance < nearest:
					tree = p
					nearest = distance
		if tree.x < 0:
			timber_work = minf(timber_work, 20.0)
			return
		_set_tile(tree, Land.GRASS)
		wood += 20.0
		timber_work -= 20.0


## Builders fund one project at a time, including its short connecting road.
func _construct() -> void:
	if project < 0:
		var kind := -1
		if food < food_need() * 3.0:
			kind = Land.FIELD
		elif housing() < population + 15:
			kind = Land.HOUSE
		if kind < 0:
			return
		var candidate := _site()
		if candidate.x < 0:
			return
		var cost := 24.0 if kind == Land.HOUSE else 12.0
		if wood < cost:
			return
		wood -= cost
		project = kind
		site = candidate
		work_left = 45.0 if kind == Land.HOUSE else 30.0
	work_left -= labour.z
	if work_left <= 0.0:
		_complete(site, project)
		_note("A new %s is ready." % ("house" if project == Land.HOUSE else "field"))
		project = -1


## Search outward through grass lanes, reserving alternate plots for buildings.
func _site() -> Vector2i:
	var queue: Array[Vector2i] = [center]
	var seen := {center: true}
	var index := 0
	while index < queue.size():
		var lane := queue[index]
		index += 1
		for direction in DIRECTIONS:
			var p: Vector2i = lane + direction
			if seen.has(p) or land.at(p) not in [Land.GRASS, Land.ROAD]:
				continue
			seen[p] = true
			var offset := p - center
			if posmod(offset.x, 2) == 1 and posmod(offset.y, 2) == 1:
				return p
			queue.append(p)
	return Vector2i(-1, -1)


## Connect a completed plot to the founding road along reserved grass lanes.
func _complete(p: Vector2i, kind: int) -> void:
	var queue: Array[Vector2i] = [p]
	var parents := {p: p}
	var index := 0
	var reached := Vector2i(-1, -1)
	while index < queue.size() and reached.x < 0:
		var lane := queue[index]
		index += 1
		for direction in DIRECTIONS:
			var next: Vector2i = lane + direction
			if parents.has(next):
				continue
			if land.at(next) == Land.ROAD:
				parents[next] = lane
				reached = next
				break
			var offset := next - center
			if land.at(next) == Land.GRASS and not (posmod(offset.x, 2) == 1 and posmod(offset.y, 2) == 1):
				parents[next] = lane
				queue.append(next)
	if reached.x >= 0:
		var lane: Vector2i = parents[reached]
		while lane != p:
			_set_tile(lane, Land.ROAD)
			roads.append(lane)
			lane = parents[lane]
	_set_tile(p, kind)
	if kind == Land.HOUSE:
		houses.append(p)
	else:
		fields.append(p)


## Founding plots follow the same placement rules as later growth.
func _found(kind: int) -> void:
	var p := _site()
	if p.x >= 0:
		_complete(p, kind)


## A revision tells the renderer that its cached land has changed.
func _set_tile(p: Vector2i, kind: int) -> void:
	land.tiles[p.y * Land.W + p.x] = kind
	revision += 1


## The chronicle keeps recent dated milestones.
func _note(message: String) -> void:
	log.append("Y%d D%d · %s" % [year, day, message])
	if log.size() > 80:
		log.pop_front()
