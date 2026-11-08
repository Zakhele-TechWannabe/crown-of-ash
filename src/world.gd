extends RefCounted
const Land := preload("res://src/land.gd")
const DAY_LEN := 60.0
const DAYS_PER_YEAR := 12
const CROP_NAMES := ["Wheat", "Barley", "Beans", "Fallow"]
const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]
const POLICY_NAMES := ["Fields", "Balanced", "Building"]
const BASE_YIELD := [4.0, 2.8, 1.8, 0.0]
const SOIL_EFFECT := [-10.0, -4.0, 9.0, 3.0]
var land := Land.new()
var population := 10
var clock := 0.0
var day := 1
var year := 1
var focus := 1
var houses: Array[Vector2i] = []
var zones: Array[Rect2i] = []
var fields: Array[Dictionary] = []
var center := Vector2i(52, 39)
var revision := 0
var log: Array[String] = []
var labour := Vector2.ZERO
var site := Vector2i(-1, -1)
var work_left := 0.0
var granary := PackedFloat32Array([0, 0, 0])
var next_id := 0
var assignments: Array[Dictionary] = []

func _init(seed_value: int = 41) -> void:
	land.build(seed_value)
	mark_housing(Rect2i(center - Vector2i.ONE, Vector2i(2, 2)))
	_finish_house(center - Vector2i.ONE)
	site = Vector2i(-1, -1)
	_note("A family of 10 settles here.")
	_allocate()

func season() -> int:
	return (day - 1) / 3

func cells(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			result.append(Vector2i(x, y))
	return result

func can_mark(rect: Rect2i, _field: bool) -> bool:
	if rect.size.x < 2 or rect.size.y < 2 or rect.size.x > 12 or rect.size.y > 12:
		return false
	for p in cells(rect):
		if land.at(p) != Land.GRASS:
			return false
		var i := land.index(p)
		if land.field_ids[i] >= 0 or land.housing[i] != 0:
			return false
		if site.x >= 0 and Rect2i(site, Vector2i(2, 2)).has_point(p):
			return false
	return true

func mark_field(rect: Rect2i, plan: Array = [0, 2, 1, 3]) -> int:
	if not can_mark(rect, true):
		return -1
	var id := next_id
	next_id += 1
	var f := {"id": id, "rect": rect, "plan": plan.duplicate(), "previous": -1, "stage": "Ploughing", "cursor": 0, "crop": int(plan[season()]), "harvest": [0.0, 0.0, 0.0], "last_harvest": [0.0, 0.0, 0.0]}
	fields.append(f)
	if f.crop == 3:
		f.stage = "Fallow"
	for p in cells(rect):
		land.field_ids[land.index(p)] = id
		land.crops[land.index(p)] = f.crop
	revision += 1
	_allocate()
	return id

func mark_housing(rect: Rect2i) -> bool:
	if not can_mark(rect, false):
		return false
	zones.append(rect)
	for p in cells(rect):
		land.housing[land.index(p)] = 1
	revision += 1
	_allocate()
	return true

func remove_field(id: int) -> void:
	for f in fields:
		if f.id != id:
			continue
		for p in cells(f.rect):
			var i := land.index(p)
			land.field_ids[i] = -1
			land.tiles[i] = Land.GRASS
			land.crops[i] = 3
			land.growth[i] = 0
		fields.erase(f)
		revision += 1
		break
	_allocate()

func average_fertility(f: Dictionary) -> float:
	var total := 0.0
	for p in cells(f.rect):
		total += land.fertility[land.index(p)]
	return total / (f.rect.size.x * f.rect.size.y)

func average_growth(f: Dictionary) -> float:
	var total := 0.0
	for p in cells(f.rect):
		total += land.growth[land.index(p)]
	return total / (f.rect.size.x * f.rect.size.y)

func step(dt: float) -> void:
	_allocate()
	clock += maxf(0, dt)
	while clock >= DAY_LEN:
		clock -= DAY_LEN
		_daily()

func _find_site() -> Vector2i:
	for zone in zones:
		for p in cells(zone):
			var valid := true
			for q in cells(Rect2i(p, Vector2i(2, 2))):
				if not zone.has_point(q) or land.at(q) != Land.GRASS:
					valid = false
			if valid:
				return p
	return Vector2i(-1, -1)

func _allocate() -> void:
	if site.x < 0:
		site = _find_site()
		if site.x >= 0:
			work_left = 10
	var active: Array[Dictionary] = []
	for f in fields:
		if f.stage != "Fallow" and f.stage != "Done":
			active.append(f)
	var farmers := [8, 5, 2][focus] as int
	if active.is_empty():
		farmers = 0
	var builders := 10 - farmers if site.x >= 0 else 0
	if site.x < 0 and not active.is_empty():
		farmers = 10
	labour = Vector2(farmers, builders)
	assignments.clear()
	for n in 10:
		if n < farmers:
			var f: Dictionary = active[n % active.size()]
			var plots := cells(f.rect)
			assignments.append({"task": 0, "cell": plots[(int(f.cursor) + n / active.size()) % plots.size()], "field": f.id})
		elif n < farmers + builders:
			assignments.append({"task": 1, "cell": site + Vector2i(n % 2, 1)})
		else:
			assignments.append({"task": 2, "cell": houses[n % houses.size()] if not houses.is_empty() else center})

func _daily() -> void:
	_allocate()
	for f in fields:
		var workers := 0
		for a in assignments:
			if a.task == 0 and a.field == f.id:
				workers += 1
		_work_field(f, workers)
	if site.x >= 0:
		work_left -= labour.y
		if work_left <= 0:
			_finish_house(site)
			site = Vector2i(-1, -1)
	day += 1
	if day > DAYS_PER_YEAR:
		day = 1
		year += 1
		for f in fields:
			f.last_harvest = f.harvest.duplicate()
			f.harvest = [0.0, 0.0, 0.0]
	if (day - 1) % 3 == 0:
		for f in fields:
			_begin_season(f)
	revision += 1
	_allocate()

func _work_field(f: Dictionary, workers: int) -> void:
	var plots := cells(f.rect)
	var crop := int(f.crop)
	if f.stage == "Fallow":
		for p in plots:
			var i := land.index(p)
			land.fertility[i] = minf(100, land.fertility[i] + 1)
		return
	# Each worker handles eight cells per day; small fields can finish several stages.
	var budget := workers * 8
	while budget > 0 and f.stage not in ["Done", "Fallow"]:
		var p: Vector2i = plots[int(f.cursor)]
		var i := land.index(p)
		match f.stage:
			"Ploughing": land.tiles[i] = Land.TILLED
			"Sowing":
				land.crops[i] = crop
				land.growth[i] = 0.1
			"Tending": land.growth[i] = minf(1, land.growth[i] + 0.9)
			"Harvesting":
				var amount: float = BASE_YIELD[crop] * land.fertility[i] / 100.0
				granary[crop] += amount
				f.harvest[crop] += amount
				land.fertility[i] = clampf(land.fertility[i] + SOIL_EFFECT[crop] - (6.0 if f.previous == crop else 0.0), 0, 100)
				land.growth[i] = 0
		f.cursor += 1
		budget -= 1
		if f.cursor >= plots.size():
			f.cursor = 0
			match f.stage:
				"Ploughing":
					f.stage = "Sowing"
					_note("Field %d ploughed." % f.id)
				"Sowing":
					f.stage = "Tending"
					_note("Field %d sown with %s." % [f.id, CROP_NAMES[crop]])
					break
				"Tending":
					if land.growth[i] >= 0.99:
						f.stage = "Harvesting"
					break
				"Harvesting":
					f.stage = "Done"
					f.previous = crop
					_note("Field %d harvested %s: %.1f this year." % [f.id, CROP_NAMES[crop], f.harvest[crop]])

func _begin_season(f: Dictionary) -> void:
	var crop := int(f.plan[season()])
	# Unfinished work carries over; large fields must not restart each season.
	if f.stage not in ["Done", "Fallow"]:
		return
	f.crop = crop
	f.cursor = 0
	f.stage = "Fallow" if crop == 3 else "Sowing"
	for p in cells(f.rect):
		var i := land.index(p)
		if land.tiles[i] == Land.GRASS and crop != 3:
			f.stage = "Ploughing"
		land.crops[i] = crop
		land.growth[i] = 0

func _finish_house(p: Vector2i) -> void:
	houses.append(p)
	for q in cells(Rect2i(p, Vector2i(2, 2))):
		land.tiles[land.index(q)] = Land.HOUSE
	revision += 1
	_note("House built.")

func _note(message: String) -> void:
	log.append("Y%d D%d · %s" % [year, day, message])
	if log.size() > 80:
		log.pop_front()
