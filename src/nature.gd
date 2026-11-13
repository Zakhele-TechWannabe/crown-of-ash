extends RefCounted
## The valley's living catalogue: thousands of real species, and what the villagers have seen of them.
## Species come from data/wild/species.json (tools/build_species_catalogue.py). Nobody knows a species
## until someone sees it; people who watch nature closely build up the insight that writes manuals.
const SOURCE := "res://data/wild/species.json"
const HABITAT_OF_DUTY := {"fields": "field", "garden": "field", "hunt": "forest", "logs": "forest", "orchard": "forest", "herd": "meadow", "fishery": "stream"}
const SPOT_PER_WEEK := 0.35

static var _catalogue: Dictionary = {}
var species: Array = []
var society_ref: WeakRef
## Species id → {"day", "person"}: who first saw it in the valley.
var known: Dictionary = {}
var known_order: Array[int] = []
## Sightings per person: the more of nature someone has watched, the closer an insight.
var studied := PackedInt32Array()
## "habitat:month" → [ids, cumulative weights], built on first use.
var _pools: Dictionary = {}
var _index: Dictionary = {}


func _init(society: RefCounted) -> void:
	society_ref = weakref(society)
	species = load_catalogue().get("species", [])
	for i in species.size():
		_index[int(species[i].id)] = i


static func load_catalogue() -> Dictionary:
	if _catalogue.is_empty() and FileAccess.file_exists(SOURCE):
		_catalogue = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	return _catalogue


func add_person() -> void:
	studied.append(0)


func get_species(id: int) -> Dictionary:
	return species[_index[id]] if _index.has(id) else {}


func habitat_of(p: int) -> String:
	var store: RefCounted = society_ref.get_ref().store_ref.get_ref()
	for duty: String in store.schedules[store.job[p]]:
		if HABITAT_OF_DUTY.has(duty): return HABITAT_OF_DUTY[duty]
	return "village"


func _active(entry: Dictionary, month: int) -> bool:
	var months: Array = entry.get("months", [1, 12])
	var first := int(months[0])
	var last := int(months[1])
	return month >= first and month <= last if first <= last else (month >= first or month <= last)


## Everything that can be met in a habitat this month, weighted by how often it is recorded in the wild.
func _pool(habitat: String, month: int) -> Array:
	var key := "%s:%d" % [habitat, month]
	if not _pools.has(key):
		var ids := PackedInt32Array()
		var weights := PackedFloat32Array()
		var total := 0.0
		for entry: Dictionary in species:
			if entry.get("domestic", false) or not (habitat in entry.get("habitat", []) or habitat == "village") or not _active(entry, month): continue
			total += sqrt(maxf(1.0, float(entry.records)))
			ids.append(int(entry.id))
			weights.append(total)
		_pools[key] = [ids, weights, total]
	return _pools[key]


## Once a week, anyone out at work may notice something living.
func observe(p: int, days: int, on_day: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.store_ref.get_ref()
	if species.is_empty() or store.age(p) < 6 or store.rng.randf() > SPOT_PER_WEEK * days / 7.0: return
	var month := mini(12, (on_day % 365) * 12 / 365 + 1)
	var pool: Array = _pool(habitat_of(p), month)
	if pool[0].is_empty(): return
	var pick: float = store.rng.randf() * float(pool[2])
	var i: int = clampi(pool[1].bsearch(pick), 0, pool[0].size() - 1)
	var id: int = pool[0][i]
	studied[p] = mini(1 << 30, studied[p] + 1)
	if known.has(id): return
	known[id] = {"day": on_day, "person": p}
	known_order.append(id)
	var entry := get_species(id)
	if entry.tier == "individual" or int(entry.get("danger", 0)) >= 2 or entry.get("spirit_candidate", false):
		society.note(p, "sighting", "%s saw %s for the first time in the valley" % [store.names[p], _with_article(str(entry.name))])


## An insight from nature comes sooner to someone who has watched a great deal of it (up to three times as often).
func insight(p: int) -> float:
	return 1.0 + minf(2.0, studied[p] / 150.0)


func _with_article(words: String) -> String:
	return ("an " if words[0].to_lower() in "aeiou" else "a ") + words


## Counts for the Bestiary: [seen, total] per tier.
func tally() -> Dictionary:
	var result := {"individual": [0, 0], "population": [0, 0], "guild": [0, 0]}
	for entry: Dictionary in species:
		var row: Array = result[entry.tier]
		row[1] += 1
		if known.has(int(entry.id)): row[0] += 1
	return result
