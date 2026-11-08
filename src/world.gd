extends RefCounted
## A settlement's people are counts; policies guide their shared daily work.

const Land := preload("res://src/land.gd")
const DAY_LEN := 60.0
const DAYS_PER_YEAR := 12
const HOUSE_CAPACITY := 10
const POLICY_NAMES := [["Food", "Balanced", "Construction"], ["Lean", "Normal", "Generous"], ["Encourage", "Neutral", "Restrain"]]
const DESCRIPTIONS := [
	["More farmers; slower construction.", "Share work between food and shelter.", "More builders; fewer farmers."],
	["Eat less; fewer births and greater mortality.", "Ordinary meals and ordinary health.", "Eat more; healthier families and more births."],
	["More births, with extra food for families.", "Families grow at their natural pace.", "Fewer births and slightly lower food use."]
]
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var land := Land.new()
var population := 10
var food := 30.0
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
var labour := Vector2.ZERO
var project := -1
var site := Vector2i.ZERO
var work_left := 0.0
var birth_fraction := 0.0
var death_fraction := 0.0
var famine := false
var year_population := 10


## One family brings supplies and establishes a home and two fields.
func _init(seed_value: int = 41) -> void:
	land.build(seed_value)
	center = Vector2i(52, 39)
	_set_tile(center, Land.ROAD)
	roads.append(center)
	_found(Land.HOUSE)
	for i in 2:
		_found(Land.FIELD)
	_update_labour()
	_note("A family of 10 founds a settlement.")


## Shelter comes only from completed houses.
func housing() -> int:
	return houses.size() * HOUSE_CAPACITY


## Days resolve at fixed boundaries even when a large time step crosses several.
func step(dt: float) -> void:
	clock += maxf(0.0, dt)
	while clock >= DAY_LEN:
		clock -= DAY_LEN
		_daily()


## Working shares leave children, elders and idle people near home.
func _update_labour() -> void:
	var shares: Vector2 = [Vector2(0.55, 0.10), Vector2(0.40, 0.25), Vector2(0.25, 0.40)][policies[0]]
	labour = shares * population


## Meals reflect both ration size and support for growing families.
func food_need() -> float:
	return population * float([0.8, 1.0, 1.2][policies[1]]) * float([1.08, 1.0, 0.96][policies[2]])


## Crops reward land and labour; six percent of stored food spoils each day.
func _daily() -> void:
	_update_labour()
	var capacity := fields.size() * 18.0
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
	_construct()
	var surplus := clampf(food / maxf(1.0, need * 2.0), 0.0, 1.0)
	var shelter := clampf(float(housing()) / maxf(1.0, population), 0.0, 1.0)
	birth_fraction += population * 0.011 * surplus * shelter * float([1.5, 1.0, 0.4][policies[2]]) * float([0.7, 1.0, 1.2][policies[1]])
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


## Builders raise earth and thatch plots and their short connecting roads.
func _construct() -> void:
	if project < 0:
		var kind := -1
		if housing() < population + 2:
			kind = Land.HOUSE
		elif food < food_need() * 2.5:
			kind = Land.FIELD
		if kind < 0:
			return
		var candidate := _site()
		if candidate.x < 0:
			return
		project = kind
		site = candidate
		work_left = 12.0 if kind == Land.HOUSE else 8.0
	work_left -= labour.y
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
