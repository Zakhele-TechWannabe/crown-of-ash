extends RefCounted
## Sparse active effects; no per-person allocations until an effect is applied.
var active: Dictionary = {}
var instant_handler: Callable

func apply(person: int, definition: Dictionary, day: int) -> void:
	var duration: Dictionary = definition.duration
	if duration.unit == "instant" or (duration.unit == "permanent" and definition.effect in ["potential_raise", "attribute_gain", "flat_xp", "insight_roll"]):
		if instant_handler.is_valid(): instant_handler.call(person, definition)
		return
	var effect := definition.duplicate(true)
	effect.expires = -1 if duration.unit == "permanent" else day + int(duration.value) * (365 if duration.unit == "years" else 1)
	if not active.has(person): active[person] = []
	active[person].append(effect)

func value(person: int, target: String, effect: String, day: int, default_value: float = 1.0) -> float:
	if not active.has(person): return default_value
	var product := 1.0
	var matched := false
	var highest := 1.0 if effect.ends_with("multiplier") else 0.0
	var diminishing := 0.0
	var addition := 0.0
	for row: Dictionary in active[person]:
		if int(row.expires) >= 0 and day >= int(row.expires): continue
		if row.effect != effect: continue
		if row.target != "all_learning" and row.target != target and not target.begins_with(str(row.target) + "."): continue
		matched = true
		match str(row.stacking):
			"highest": highest = maxf(highest, float(row.value))
			"add": addition += float(row.value)
			"diminishing": diminishing += float(row.value) - 1.0
			_: product *= float(row.value)
	if not matched: return default_value
	return product * (highest if highest > 0 else 1.0 if effect.ends_with("multiplier") else 0.0) * (1.0 + diminishing / (1.0 + absf(diminishing) * 0.5)) + addition

func expire(day: int) -> void:
	for person: int in active.keys():
		var kept: Array = []
		for row: Dictionary in active[person]:
			if int(row.expires) < 0 or day < int(row.expires): kept.append(row)
		if kept.is_empty(): active.erase(person)
		else: active[person] = kept
