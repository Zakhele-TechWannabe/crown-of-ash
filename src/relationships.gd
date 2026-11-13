extends RefCounted
## Directed, bounded adjacency lists. Memories and grudges exist only for notable ties.
const CAP := 48
const FRIEND := 1
const SWORN := 2
const ROMANCE := 4
const SPOUSE := 8
const DAO := 16
const MASTER := 32
const DISCIPLE := 64
const RIVAL := 128
const ENEMY := 256
const BENEFACTOR := 512
const DEBTOR := 1024
var head := PackedInt32Array()
var count := PackedByteArray()
var target := PackedInt32Array()
var next := PackedInt32Array()
var opinion := PackedFloat32Array()
var familiarity := PackedByteArray()
var trust := PackedByteArray()
var bonds := PackedInt32Array()
const RESOLUTION_PATHS := "apology, compensation, mediation, duel, time or nonlethal revenge"
# Sparse indexes point into packed pools; records are materialised only for UI.
var memory_index: Dictionary = {}
var memory_cause := PackedByteArray()
var memory_weight := PackedFloat32Array()
var memory_day := PackedInt32Array()
var memory_free := PackedInt32Array()
var grudge_index: Dictionary = {}
var grudge_cause := PackedByteArray()
var grudge_weight := PackedFloat32Array()
var grudge_inheritable := PackedByteArray()
var grudge_free := PackedInt32Array()
var causes: Array[String] = []
var compatibility_a := PackedInt64Array()
var compatibility_b := PackedInt64Array()
var compatibility_weight := PackedFloat32Array()
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/relationships.json"))

func add_person() -> void:
	head.append(-1)
	count.append(0)

func find(a: int, b: int) -> int:
	var e := head[a]
	while e >= 0:
		if target[e] == b: return e
		e = next[e]
	return -1

func tie(a: int, b: int, baseline: float = 0) -> int:
	if a == b: return -1
	var e := find(a, b)
	if e >= 0: return e
	if count[a] >= CAP:
		e = head[a]
		var weakest := e
		while e >= 0:
			if strength(e) < strength(weakest): weakest = e
			e = next[e]
		e = weakest
		clear_memories(e)
		clear_grudge(e)
		target[e] = b
		opinion[e] = baseline
		familiarity[e] = 0
		trust[e] = 0
		bonds[e] = 0
		return e
	e = target.size()
	target.append(b)
	next.append(head[a])
	head[a] = e
	count[a] += 1
	opinion.append(baseline)
	familiarity.append(0)
	trust.append(0)
	bonds.append(0)
	return e

func strength(e: int) -> float:
	return absf(opinion[e]) + familiarity[e] + trust[e] + (200 if bonds[e] & (SWORN | SPOUSE | MASTER | DISCIPLE) else 0)

func event(a: int, b: int, kind: String, day: int) -> void:
	if not rules.events.has(kind): return
	var e := tie(a, b)
	if e < 0: return
	var r: Dictionary = rules.events[kind]
	opinion[e] = clampf(opinion[e] + float(r.opinion), -100, 100)
	familiarity[e] = mini(100, familiarity[e] + int(r.get("familiarity", 3)))
	trust[e] = clampi(trust[e] + int(r.get("trust", 0)), 0, 100)
	bonds[e] |= int(r.get("bond", 0))
	if absf(float(r.opinion)) >= 8: remember(e, kind, float(r.opinion), day)
	if opinion[e] <= -60 and float(r.opinion) < 0:
		bonds[e] |= ENEMY
		set_grudge(e, absf(opinion[e]), kind, kind in ["betrayal", "killed_kin"])
	if kind in ["apology", "mediation", "duel", "revenge"] and has_grudge(e):
		var slot: int = grudge_index[e]
		grudge_weight[slot] *= .5
		if grudge_weight[slot] < 10:
			clear_grudge(e)
			bonds[e] &= ~ENEMY
	_refresh(e)

func _refresh(e: int) -> void:
	if opinion[e] >= 10: bonds[e] &= ~RIVAL
	if opinion[e] > -60 and not has_grudge(e): bonds[e] &= ~ENEMY
	if opinion[e] >= 40 and familiarity[e] >= 30: bonds[e] |= FRIEND
	else: bonds[e] &= ~FRIEND

func drift_person(a: int, population: RefCounted, days: int = 7) -> int:
	if compatibility_a.is_empty():
		for row: Array in rules.compatibility:
			compatibility_a.append(1 << int(population.trait_indices[row[0]]))
			compatibility_b.append(1 << int(population.trait_indices[row[1]]))
			compatibility_weight.append(float(row[2]))
	var a_traits: int = population.traits[a]
	var active := PackedInt32Array()
	for i in compatibility_a.size():
		if a_traits & compatibility_a[i]: active.append(i)
	var household: int = population.household[a]
	var job: int = population.job[a]
	var flags := 0
	var have_memories := not memory_index.is_empty()
	var have_grudges := not grudge_index.is_empty()
	var memory_decay := pow(.9995, days)
	var grudge_decay := pow(.9999, days)
	var e := head[a]
	while e >= 0:
		var b := target[e]
		var near: bool = household == population.household[b] or job == population.job[b] or population.locations[a].distance_squared_to(population.locations[b]) < 4096 or population.shared_work(a, b)
		var baseline := 0.0
		var b_traits: int = population.traits[b]
		for i: int in active:
			if b_traits & compatibility_b[i]: baseline += compatibility_weight[i]
		opinion[e] = move_toward(opinion[e], baseline, float(days) * .003)
		familiarity[e] = clampi(familiarity[e] + (1 if near else -1), 0, 100)
		if near: opinion[e] = minf(100, opinion[e] + float(days) * .025)
		if have_memories and memory_index.has(e):
			var base: int = memory_index[e]
			for slot in range(base, base + 3): memory_weight[slot] *= memory_decay
		if have_grudges and has_grudge(e):
			var slot: int = grudge_index[e]
			grudge_weight[slot] *= grudge_decay
			if grudge_weight[slot] < 10:
				clear_grudge(e)
				bonds[e] &= ~ENEMY
		if opinion[e] >= 40 and familiarity[e] >= 30: bonds[e] |= FRIEND
		elif bonds[e] & FRIEND: bonds[e] &= ~FRIEND
		if opinion[e] >= 50: flags |= 1
		if opinion[e] >= 20: flags |= 2
		if bonds[e] & RIVAL:
			if opinion[e] < 10: flags |= 4
			else: bonds[e] &= ~RIVAL
		e = next[e]
	return flags

func rows(a: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var e := head[a]
	while e >= 0:
		result.append({"entry": e, "person": target[e], "opinion": opinion[e], "familiarity": familiarity[e], "trust": trust[e], "bonds": bonds[e]})
		e = next[e]
	result.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return absf(x.opinion) > absf(y.opinion))
	return result

func bond_names(flags: int) -> String:
	var labels: Array[String] = []
	var names := ["friend", "sworn sibling", "romance", "spouse", "dao companion", "master", "disciple", "rival", "enemy", "benefactor", "debt of grace"]
	for i in names.size():
		if flags & (1 << i): labels.append(names[i])
	return ", ".join(labels)

func cause_id(kind: String) -> int:
	if causes.is_empty(): causes.assign(rules.events.keys())
	return causes.find(kind)

func remember(e: int, cause: String, weight: float, day: int) -> void:
	var base: int = memory_index.get(e, -1)
	if base < 0:
		if memory_free.is_empty():
			base = memory_weight.size()
			memory_weight.resize(base + 3)
			memory_cause.resize(base + 3)
			memory_day.resize(base + 3)
		else: base = memory_free[-1]; memory_free.resize(memory_free.size() - 1)
		memory_index[e] = base
		for slot in range(base, base + 3): memory_weight[slot] = 0
	var weakest := base
	for slot in range(base + 1, base + 3):
		if absf(memory_weight[slot]) < absf(memory_weight[weakest]) or (absf(memory_weight[slot]) == absf(memory_weight[weakest]) and memory_day[slot] < memory_day[weakest]): weakest = slot
	if absf(weight) >= absf(memory_weight[weakest]):
		memory_cause[weakest] = cause_id(cause)
		memory_weight[weakest] = weight
		memory_day[weakest] = day

func clear_memories(e: int) -> void:
	if not memory_index.has(e): return
	memory_free.append(int(memory_index[e]))
	memory_index.erase(e)

func memory_rows(e: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not memory_index.has(e): return result
	var base: int = memory_index[e]
	for slot in range(base, base + 3):
		if memory_weight[slot] != 0: result.append({"cause": causes[memory_cause[slot]], "weight": memory_weight[slot], "day": memory_day[slot]})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return absf(a.weight) > absf(b.weight))
	return result

func has_grudge(e: int) -> bool:
	return grudge_index.has(e)

func grudge_count() -> int:
	return grudge_index.size()

func grudge_intensity(e: int) -> float:
	return grudge_weight[int(grudge_index[e])] if has_grudge(e) else 0.0

func set_grudge(e: int, intensity: float, cause: String, inheritable: bool) -> void:
	var slot: int = grudge_index.get(e, -1)
	if slot < 0:
		if grudge_free.is_empty():
			slot = grudge_weight.size()
			grudge_weight.append(0)
			grudge_cause.append(0)
			grudge_inheritable.append(0)
		else: slot = grudge_free[-1]; grudge_free.resize(grudge_free.size() - 1)
		grudge_index[e] = slot
	grudge_weight[slot] = intensity
	grudge_cause[slot] = cause_id(cause)
	grudge_inheritable[slot] = int(inheritable)

func clear_grudge(e: int) -> void:
	if not has_grudge(e): return
	grudge_free.append(int(grudge_index[e]))
	grudge_index.erase(e)

func grudge_record(e: int) -> Dictionary:
	if not has_grudge(e): return {}
	var slot: int = grudge_index[e]
	return {"intensity": grudge_weight[slot], "cause": causes[grudge_cause[slot]], "inheritable": grudge_inheritable[slot] > 0, "resolution": RESOLUTION_PATHS}

func inherit_grudge(source: int, destination: int, factor: float) -> void:
	if not has_grudge(source): return
	var slot: int = grudge_index[source]
	if grudge_inheritable[slot]: set_grudge(destination, grudge_weight[slot] * factor, causes[grudge_cause[slot]], true)
