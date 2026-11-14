extends RefCounted
## Reusable admission trials. Policies supply age limits, weights and a threshold; histories belong to people.
var records: Dictionary = {}

func test(society: RefCounted, p: int, policy: Dictionary) -> Dictionary:
	var store: RefCounted = society.population
	var urges: PackedFloat32Array = society.mind.urges(p) if society.mind else PackedFloat32Array([0, 0, .5, .5, .5, .5, .5, .5])
	var potential := 0.0
	for a in 8: potential += store.potential[p * 8 + a] / 8.0
	var talent: float = clampf(store.comprehension[p] * 25 + potential * 2 + (store.luck[p] - .8) * 25, 0, 100)
	var body: float = clampf((store.attributes[p * 8] + store.attributes[p * 8 + 1] + store.attributes[p * 8 + 2]) * 2 + (society.temper.body_layer[p] * 3 if society.temper else 0), 0, 100)
	var will: float = clampf(store.attributes[p * 8 + 6] * 4 + urges[5] * 40 - urges[2] * 20, 0, 100)
	var character := 60.0
	for trait_id: String in ["cruel", "cruelty", "treacherous", "treachery", "deceitful"]:
		if store.has_trait(p, trait_id): character -= 25
	for trait_id: String in ["kind", "loyal", "honest", "impartial"]:
		if store.has_trait(p, trait_id): character += 10
	var scores := {"talent": talent, "body": body, "will": will, "character": clampf(character, 0, 100)}
	var total := 0.0
	var weight_sum := 0.0
	for trial: String in scores:
		var weight := float(policy.weights.get(trial, 0))
		total += scores[trial] * weight
		weight_sum += weight
	total /= maxf(.001, weight_sum)
	var age: int = store.age(p)
	var record := {"day": store.day, "policy": str(policy.get("id", "sect")), "scores": scores, "total": total,
		"passed": age >= int(policy.age_min) and age <= int(policy.age_max) and total >= float(policy.threshold)}
	if not records.has(p): records[p] = []
	records[p].append(record)
	return record
