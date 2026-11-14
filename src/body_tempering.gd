extends RefCounted
## Body Tempering: nine layers anyone can forge with drills, hardship and medicine. Tempering fills a layer, a gate
## names what the breakthrough needs, and each layer is stamped with a grade (Low, Middle, High, Perfect) for life.
## The method caps the grade; Perfect needs every layer below to be Perfect too. Training builds strain, rest clears it.
const WildSupply = preload("res://src/wild_supply.gd")
const LAYERS := 9
enum {LOW, MIDDLE, HIGH, PERFECT}

var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/body.json"))
var society_ref: WeakRef
var body_layer := PackedByteArray()
var grades := PackedByteArray()
var tempering := PackedFloat32Array()
var strain := PackedFloat32Array()
var method := PackedByteArray()
var hours := PackedByteArray()
var regimen_until := PackedInt32Array()
var teacher := PackedInt32Array()
var gate_since := PackedInt32Array()
var aim_doses := PackedByteArray()
var wild: RefCounted
var medicine: Dictionary = {}
var perfect_bodies := 0
var _labour_jobs: Dictionary = {}

func _init(society: RefCounted) -> void:
	society_ref = weakref(society)
	wild = WildSupply.new(society)
	for id: String in config.medicine_names: medicine[id] = PackedByteArray()

func add_person() -> void:
	body_layer.append(0)
	for l in LAYERS: grades.append(0)
	tempering.append(0.0)
	strain.append(0.0)
	method.append(0)
	hours.append(0)
	regimen_until.append(0)
	teacher.append(-1)
	gate_since.append(0)
	aim_doses.append(1)
	for id: String in medicine: medicine[id].append(0)

func layer_name(l: int) -> String:
	return str(config.layer_names[clampi(l - 1, 0, LAYERS - 1)])

func grade(p: int, l: int) -> int:
	return grades[p * LAYERS + l - 1]

func cost(l: int) -> float:
	return float(config.first_cost) * pow(float(config.cost_growth), l - 1)

## Tempering is stored in 32-bit floats, so a full layer can sit a hair below its cost.
func at_gate(p: int) -> bool:
	return body_layer[p] < LAYERS and tempering[p] >= cost(body_layer[p] + 1) - 0.01

func training(p: int, on_day: int) -> bool:
	return hours[p] > 0 and regimen_until[p] > on_day

## Average grade of the forged layers, 0 (Low) to 3 (Perfect); -1 when nothing is forged yet.
func body_grade(p: int) -> float:
	if body_layer[p] == 0: return -1.0
	var total := 0
	for l in body_layer[p]: total += grades[p * LAYERS + l]
	return float(total) / body_layer[p]

func perfect_so_far(p: int) -> bool:
	for l in body_layer[p]:
		if grades[p * LAYERS + l] < PERFECT: return false
	return true

## The best grade the next layer could be forged at, before talent and luck.
func grade_ceiling(p: int) -> int:
	var cap: int = int(config.method_grade_cap[method[p]])
	var l: int = body_layer[p]
	if l > 0:
		cap = mini(cap, grades[p * LAYERS + l - 1] + 1)
		if not perfect_so_far(p): cap = mini(cap, HIGH)
	return cap

func _labour_hours(p: int) -> float:
	var store: RefCounted = society_ref.get_ref().population
	var j: int = store.job[p]
	if not _labour_jobs.has(j):
		var heavy := false
		for duty: String in store.schedules[j]:
			if duty in config.labour_duties: heavy = true
		_labour_jobs[j] = heavy
	return float(config.labour_hours) if _labour_jobs[j] else 0.0

func age_factor(p: int) -> float:
	var years: int = society_ref.get_ref().population.age(p)
	return maxf(.2, 1.0 - float(config.age_slow_per_year) * maxi(0, years - int(config.age_full_until)))

## Tempering gained per day: drills under the person's method, plus a little from heavy labour in the outer layers.
func rate(p: int, on_day: int) -> float:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var will: float = store.attributes[p * 8 + 6] / 10.0
	var total := 0.0
	if training(p, on_day):
		var terrace: bool = society.fifty.member(p)
		var with_teacher := float(society.fifty.config.teacher_rate) if terrace else (float(config.teacher_rate) if teacher[p] >= 0 else 1.0)
		total += hours[p] * float(config.method_rate[method[p]]) * with_teacher
	if body_layer[p] < int(config.labour_max_layer): total += _labour_hours(p) * float(config.labour_rate)
	return total * will * age_factor(p) * spirit_root_factor(p) * society.fifty.training_factor(p, on_day)

## Even a hidden root helps tempering; awakening guides qi through the body.
func spirit_root_factor(p: int) -> float:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	if not store.spirit_root[p]: return 1.0
	var factor: float = 1.0 + float(config.spirit_root_rate) + float(config.spirit_root_purity) * store.root_purity[p] / 100.0
	return factor * (float(config.spirit_root_revealed) if society.revealed[p] else 1.0)

## What the gate of the next layer still lacks, or "" when the way is open.
func gate_need(p: int) -> String:
	var l: int = body_layer[p]
	if l >= LAYERS: return "the peak of the realm"
	var need_method: int = int(config.gate_method[l])
	if method[p] < need_method: return str(config.method_names[need_method])
	# Labour alone carries the body only through the first layers.
	if not training(p, society_ref.get_ref().population.day) and (l >= int(config.labour_max_layer) or _labour_hours(p) == 0): return "drills"
	var med: String = config.gate_medicine[l]
	if not med.is_empty() and medicine[med][p] < wild.units(med): return str(config.medicine_names[med])
	return ""

## The medicine a person should be laying in for their next gate, or "" if they have enough or are not close.
func wanted_medicine(p: int) -> String:
	var l: int = body_layer[p]
	if l >= LAYERS or method[p] < int(config.gate_method[l]): return ""
	var med: String = config.gate_medicine[l]
	if med.is_empty() or tempering[p] < cost(l + 1) * float(wild.config.prepare_from_progress): return ""
	return med if medicine[med][p] < aim_doses[p] * wild.units(med) else ""

func polish_goal(p: int) -> int:
	var store: RefCounted = society_ref.get_ref().population
	var goal: int = int(config.polish_days.default)
	for id: String in config.polish_days:
		if id != "default" and store.has_trait(p, id): goal = int(config.polish_days[id]) if id in ["impulsive", "restless"] else maxi(goal, int(config.polish_days[id]))
	var society: RefCounted = society_ref.get_ref()
	if society.fifty.member(p) and body_layer[p] > 0 and perfect_so_far(p): goal = maxi(goal, int(society.fifty.config.perfect_polish_days))
	return goal

func weekly(p: int, days: int, on_day: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	if store.age(p) < 12 or society.injury_until[p] > on_day: return
	if on_day % 365 < days: yearly(p)
	var drilling := training(p, on_day)
	if drilling:
		var load := hours[p] * float(config.strain_per_hour_day) * (float(config.teacher_strain) if teacher[p] >= 0 or society.fifty.member(p) else 1.0)
		strain[p] = maxf(0.0, strain[p] + days * (load - float(config.strain_recovery_per_day)))
		if strain[p] >= 1.0:
			strain[p] = .3
			regimen_until[p] = 0
			society.injury_until[p] = on_day + store.rng.randi_range(int(config.injury_days[0]), int(config.injury_days[1]))
			society.note(p, "injury", "%s tore a sinew training too hard and must rest" % store.names[p])
			return
		_learn(p, days, on_day)
	else: strain[p] = maxf(0.0, strain[p] - days * float(config.strain_recovery_per_day))
	if body_layer[p] >= LAYERS: return
	var need := cost(body_layer[p] + 1)
	tempering[p] = minf(need, tempering[p] + rate(p, on_day) * days)
	if not at_gate(p): return
	# At the gate: wait for what it needs, then polish the layer for as long as the person's temper allows.
	if gate_since[p] == 0:
		gate_since[p] = on_day
		var lacking := gate_need(p)
		if not lacking.is_empty() and lacking != "drills":
			society.note(p, "tempering_gate", "%s reached the gate of %s but needs %s" % [store.names[p], layer_name(body_layer[p] + 1), lacking])
	if not gate_need(p).is_empty():
		store.mood[p] = maxf(0, store.mood[p] - .001 * days)
		return
	if on_day - gate_since[p] >= polish_goal(p): break_through(p, on_day)

func break_through(p: int, on_day: int) -> int:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var l: int = body_layer[p]
	var med: String = config.gate_medicine[l]
	var points: float = float(config.grade_base) + store.rng.randf_range(-float(config.luck), float(config.luck))
	# Grade quality uses one unit per grade: five percentage points is 0.05.
	if store.spirit_root[p] and society.revealed[p]: points += float(config.spirit_root_grade_quality) / 100.0
	# Extra doses of medicine only help a body that can still forge High or better.
	if not med.is_empty():
		var held: int = medicine[med][p] / wild.units(med)
		var doses := clampi(mini(held, aim_doses[p]), 1, int(wild.config.max_doses)) if grade_ceiling(p) >= HIGH else 1
		medicine[med][p] -= doses * wild.units(med)
		points += float(wild.config.dose_bonus[doses - 1])
	var strong: bool = store.potential[p * 8] >= 17 and store.potential[p * 8 + 1] >= 17
	if store.constitution[p] == 1: points += float(config.talent_physique)
	elif strong: points += float(config.talent_strong)
	if society.fifty.member(p): points += float(society.fifty.config.teacher_grade) + float(society.fifty.config.grade_bonus)
	var t: int = teacher[p]
	if t >= 0 and training(p, on_day) and body_layer[t] > l and grade(t, l + 1) >= HIGH: points += float(config.teacher_grade)
	points += minf(float(config.polish_max), (on_day - gate_since[p]) / 365.0 * float(config.polish_per_year))
	var g := clampi(floori(points), LOW, grade_ceiling(p))
	var was_perfect := perfect_so_far(p)
	grades[p * LAYERS + l] = g
	body_layer[p] = l + 1
	tempering[p] = 0.0
	gate_since[p] = 0
	# Each layer raises the natural ceiling of strength or endurance; better grades raise it more.
	var attribute := 0 if l % 2 == 1 else 1
	store.potential[p * 8 + attribute] = mini(255, store.potential[p * 8 + attribute] + maxi(1, roundi(float(config.grade_gifts[g]))))
	if society.realm[p] < 2:
		society.realm[p] = 1
		society.layer[p] = body_layer[p]
	var words := "%s forged a %s %s (layer %d)" % [store.names[p], str(config.grade_names[g]).to_lower() + "-grade", layer_name(l + 1), l + 1]
	if g == PERFECT and was_perfect and l + 1 == LAYERS:
		perfect_bodies += 1
		words = "%s completed a Perfect body, every layer flawless%s" % [store.names[p], ", the first the valley has seen" if perfect_bodies == 1 else ""]
	elif g < PERFECT and was_perfect and l > 0 and grades[p * LAYERS] == PERFECT:
		words += "; the flawless foundation is broken, and High is now the limit"
	society.note(p, "tempering", words)
	return g

## Methods spread: worked out by hunters and fighters, taught by better-tempered friends, and written down from watching nature.
func _learn(p: int, days: int, on_day: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var t: int = teacher[p]
	if t >= 0 and method[t] > method[p]:
		var e: int = society.ties.find(t, p)
		var close: bool = society.master[p] == t or (e >= 0 and society.ties.opinion[e] >= float(config.share_manual_opinion))
		if method[t] == 1 or close:
			method[p] = method[t]
			society.note(p, "tempering_method", "%s learned %s from %s" % [store.names[p], config.method_names[method[p]], store.names[t]])
			return
	if method[p] == 0:
		var hunter: bool = "hunt" in store.schedules[store.job[p]]
		var chance: float = days * float(config.folk_drills_per_day) * store.comprehension[p] * (float(config.folk_drills_hunter_factor) if hunter else 1.0)
		if store.rng.randf() < chance:
			method[p] = 1
			society.note(p, "tempering_method", "%s worked out a set of folk drills from %s" % [store.names[p], "years of hunting" if hunter else "stubborn practice"])
			return
	if method[p] == 1 and body_layer[p] >= 3 and store.rng.randf() < days * float(config.nature_manual_per_day) * store.comprehension[p] * (2.0 if society.outdoors(p) else 1.0) * society.nature.insight(p):
		method[p] = 2
		var sights: Array = config.tempering_sights
		society.note(p, "tempering_method", "%s wrote a tempering manual after watching %s" % [store.names[p], sights[store.rng.randi_range(0, sights.size() - 1)]])
		return
	if body_layer[p] >= 7 and method[p] < 3 and store.comprehension[p] >= 1.5 and store.rng.randf() < days * float(config.complete_method_per_day):
		method[p] = 3
		society.note(p, "tempering_method", "%s wrote down a complete tempering method in a moment of insight" % store.names[p])

## Living Blood lets the body feel qi: a hidden root may wake. Checked once a year.
func yearly(p: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	if body_layer[p] >= 6 and not society.revealed[p] and society.population.spirit_root[p] and society.population.rng.randf() < float(config.blood_root_reveal_per_year):
		society.awaken(p, "the tempered blood began to feel qi")

## The brain commits a person to a regimen; it lasts months unless renewed.
func start_regimen(p: int, drill_hours: int, on_day: int) -> String:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	hours[p] = clampi(drill_hours, 1, int(config.max_hours))
	regimen_until[p] = on_day + int(config.regimen_weeks) * 7
	teacher[p] = find_teacher(p)
	if teacher[p] >= 0: society.ties.event(p, teacher[p], "teaching", on_day)
	var lacking := gate_need(p) if at_gate(p) else ""
	if not lacking.is_empty() and lacking != "drills": return "trained, but the gate of %s needs %s" % [layer_name(body_layer[p] + 1), lacking]
	return "drilled %d h a day under %s" % [hours[p], store.names[teacher[p]]] if teacher[p] >= 0 else "drilled %d h a day alone" % hours[p]

## The best-tempered person they are on good terms with, at least two layers ahead (or holding a better method).
func find_teacher(p: int) -> int:
	var society: RefCounted = society_ref.get_ref()
	var ties: RefCounted = society.ties
	var best := -1
	var best_value := 0
	var e: int = ties.head[p]
	while e >= 0:
		var other: int = ties.target[e]
		if society.alive[other] and ties.opinion[e] >= 10:
			var ahead: int = body_layer[other] - body_layer[p]
			if ahead >= int(config.teacher_min_gap) or (method[other] > method[p] and ahead >= 0):
				var value: int = body_layer[other] * 4 + method[other]
				if value > best_value:
					best = other
					best_value = value
		e = ties.next[e]
	return best

func lifespan(p: int) -> int:
	var mortal := int(config.mortal_lifespan)
	return mortal + (int(config.peak_lifespan) - mortal) * body_layer[p] / LAYERS

func qi_bonus(p: int) -> float:
	var g := body_grade(p)
	if g < 0 or body_layer[p] < LAYERS: return 0.0
	return float(config.qi_bonus_by_grade[roundi(g)])

## Plain words for the person page.
func describe(p: int) -> Dictionary:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var layers: Array = []
	for l in body_layer[p]: layers.append([layer_name(l + 1), config.grade_names[grades[p * LAYERS + l]]])
	var gate_reached := at_gate(p)
	return {"layer": body_layer[p], "name": layer_name(body_layer[p]) if body_layer[p] else "untempered", "layers": layers,
		"progress": tempering[p] / cost(mini(LAYERS, body_layer[p] + 1)), "method": config.method_names[method[p]],
		"training": training(p, store.day), "hours": hours[p], "teacher": "Heavenly Dao Palace · master teacher" if society.fifty.member(p) else (store.names[teacher[p]] if teacher[p] >= 0 and training(p, store.day) else ""),
		"strain": strain[p], "gate": gate_need(p) if gate_reached else "", "ceiling": config.grade_names[grade_ceiling(p)],
		"grade": config.grade_names[roundi(body_grade(p))] if body_layer[p] else "", "holds": holds(p)}

func holds(p: int) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in medicine:
		if medicine[id][p] > 0: out.append("%d %s" % [medicine[id][p], {"iron_bark": "iron-bark roots", "beast_marrow": "beast marrow", "seven_leaf": "seven-leaf herbs"}[id]])
	return out

func summary() -> Dictionary:
	var by_layer := PackedInt32Array()
	by_layer.resize(LAYERS + 1)
	var by_grade := PackedInt32Array()
	by_grade.resize(4)
	var methods := PackedInt32Array()
	methods.resize(4)
	var drilling := 0
	var wanting: Dictionary = {}
	var society: RefCounted = society_ref.get_ref()
	for p in body_layer.size():
		if not society.alive[p]: continue
		by_layer[body_layer[p]] += 1
		methods[method[p]] += 1
		if training(p, society.population.day): drilling += 1
		var want := wanted_medicine(p)
		if not want.is_empty(): wanting[want] = int(wanting.get(want, 0)) + 1
		for l in body_layer[p]: by_grade[grades[p * LAYERS + l]] += 1
	return {"layers": Array(by_layer), "grades": Array(by_grade), "methods": Array(methods), "drilling": drilling, "wanting": wanting, "wild": wild.summary()}
