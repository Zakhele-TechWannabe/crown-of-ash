extends RefCounted
## Script-owned state only. References stay attached to the freshly built world.
const PATH := "user://saves/world.save"
const VERSION := 1
const CHILDREN := [
	"population", "society", "ties", "mind", "temper", "nature", "wild",
	"qi_field", "wildlife", "archive", "economy", "law", "modifiers", "childhood", "fifty", "admission",
]
const SKIP := [
	"world", "sect", "grid", "palace", "contexts", "path_requests", "catalogue", "config", "rules", "given_names",
	"goods", "species", "stock", "draw_order", "nearby_views", "view_cell", "routes",
	"tree_view", "tree_view_key", "workplace_sprites", "person_art", "child_art", "atlas", "cliffs",
	"heights", "food_places", "food_patches", "material_places", "material_patches", "square", "well",
	"shrine", "granary", "blocked", "residents", "walk_paths", "household_names", "household_names_day",
	"household_names_size", "spatial_cells", "cached_domains", "cached_skills", "statistics_day", "statistics_entries", "learning_rates",
	"level_rates", "practice_floors", "base_xp_hour", "green_thumb_mask", "trait_indices", "prepared_tasks", "compatibility_a",
	"compatibility_b", "compatibility_weight",
]

static func enabled() -> bool:
	if DisplayServer.get_name() == "headless": return false
	for arg: String in OS.get_cmdline_user_args():
		if arg in ["--no-save", "--headless-sim"] or arg.begins_with("--shot="): return false
	return true

static func fields(object: Object) -> Array[String]:
	var result: Array[String] = []
	var script: Script = object.get_script()
	if script == null: return result
	for property: Dictionary in script.get_script_property_list():
		var key := str(property.name)
		if key in SKIP or key.begins_with("_") or not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: continue
		# Configuration is always read from the current resource files.
		if key == "events" and script.resource_path.ends_with("society.gd"): continue
		result.append(key)
	return result

static func capture(object: Object, ancestors: Array = []) -> Dictionary:
	if object.get_script() and object.get_script().resource_path.ends_with("qi_field.gd"): return object.save_state()
	var result := {}
	var chain := ancestors + [object]
	for key: String in fields(object):
		var value: Variant = object.get(key)
		if key == "population" and object.get_script().resource_path.ends_with("grain_economy.gd"): continue
		if value is RandomNumberGenerator:
			result[key] = {"rng_state": value.state, "rng_seed": value.seed}
		elif value is Object:
			if key in CHILDREN and not value in chain and not value is Node:
				result[key] = capture(value, chain)
		elif typeof(value) not in [TYPE_CALLABLE, TYPE_SIGNAL] and not (value is Array and not value.is_empty() and value[0] is Object):
			result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	if object.get_script().resource_path.ends_with("law.gd"):
		for guardian: Dictionary in result.get("guardians", []):
			guardian.erase("sight")
			guardian.erase("night")
	return result

static func restore(object: Object, state: Dictionary, ancestors: Array = []) -> void:
	if object.get_script() and object.get_script().resource_path.ends_with("qi_field.gd"):
		object.load_state(state, int(state.get("day", 0)))
		return
	var chain := ancestors + [object]
	for key: String in fields(object):
		if not state.has(key): continue
		var value: Variant = object.get(key)
		if key == "population" and object.get_script().resource_path.ends_with("grain_economy.gd"): continue
		if value is RandomNumberGenerator:
			value.seed = state[key].rng_seed
			value.state = state[key].rng_state
		elif value is Object:
			if key in CHILDREN and not value in chain and not value is Node and state[key] is Dictionary:
				restore(value, state[key], chain)
		elif not (key in CHILDREN and value == null):
			object.set(key, state[key])

## Older saves seed wildlife at their date without replaying elapsed years or changing other state.
static func repair_wildlife(society: RefCounted, saved: Dictionary, on_day: int) -> void:
	if not saved.has("wildlife"):
		var economy_ref: WeakRef = society.wildlife.economy_ref
		society.wildlife = preload("res://src/wildlife.gd").new(society)
		society.wildlife.economy_ref = economy_ref
		society.wildlife.seed(on_day)
	society.wildlife.repair_names()
	# The field starts at the saved date; historical cultivation remains abstract.
	if not saved.has("qi_field"): society.qi_field.load_state({}, on_day)

static func write(map: Node2D, path: String = PATH) -> Error:
	if path == PATH and not enabled(): return ERR_UNAVAILABLE
	if not is_instance_valid(map.life): return ERR_UNAVAILABLE
	# Coroutine stacks are not serializable; retry once a faction refresh has yielded its final state.
	if map.life.population.society.faction_pending: return ERR_BUSY
	var archive: RefCounted = map.life.population.society.archive
	if archive: archive.close()
	var state := {"life": capture(map.life), "on_ground": map.on_ground,
		"map_position": map.cam.position, "map_zoom": map.cam.zoom,
		"book_section": map.ground_view.ledger.current,
		"ground_position": map.ground_view.cam.position, "ground_zoom": map.ground_view.cam.zoom}
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK: return error
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_buffer(var_to_bytes({"version": VERSION, "saved_at": Time.get_unix_time_from_system(), "state": state}))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"): DirAccess.remove_absolute(path + ".bak")
		error = DirAccess.rename_absolute(path, path + ".bak")
		if error != OK: return error
	return DirAccess.rename_absolute(path + ".tmp", path)

static func read_envelope(path: String) -> Dictionary:
	if path in [PATH, PATH + ".bak"] and not enabled(): return {}
	if not FileAccess.file_exists(path): return {}
	var envelope: Variant = bytes_to_var(FileAccess.get_file_as_bytes(path))
	if not envelope is Dictionary or envelope.get("version", 0) != VERSION: return {}
	var state: Variant = envelope.get("state")
	if not state is Dictionary or not state.get("life") is Dictionary: return {}
	var people: Variant = state.life.get("population")
	if not people is Dictionary or not people.get("names") is Array: return {}
	return envelope


static func read(map: Node2D, path: String = PATH) -> bool:
	if path == PATH and not enabled(): return false
	for candidate: String in [path, path + ".bak"]:
		var envelope := read_envelope(candidate)
		if envelope.is_empty(): continue
		var state: Dictionary = envelope.state
		var defaults := capture(map.life)
		restore(map.life, state.life)
		repair_wildlife(map.life.population.society, state.life.population.society, map.life.population.day)
		repair_columns(map.life.population, defaults.population, map.life.population.size())
		map.life.population.society.fifty.repair(state.life.population.society.get("fifty", {}))
		for n in map.life.population.jobs.size():
			if map.life.population.jobs[n] == "heaven's disciple":
				map.life.population.jobs[n] = "Heavenly Dao Palace disciple"
		for walker: Dictionary in map.life.people:
			if walker.get("job", "") == "heaven's disciple": walker.job = "Heavenly Dao Palace disciple"
		for event: Dictionary in map.life.population.society.chronicle:
			event.text = str(event.text).replace("Heaven's Terrace", "Heavenly Dao Palace").replace("Heaven’s Terrace", "Heavenly Dao Palace")
		map.life.palace.people.clear()
		map.life.palace.routes.clear()
		map.life.palace.sync(map.life.population)
		map.life.contexts[0].people = map.life.people
		map.life.economy.people = map.life.people
		map.life.routes.clear()
		map.life.nearby_views.clear()
		map.life.tree_view.clear()
		map.life.view_cell = Vector2i(-999999, -999999)
		map.life.tree_view_key = Rect2i()
		for stage: Dictionary in map.life.law_stages:
			var index: int = map.life.walker_of(int(stage.r.person))
			if index >= 0: stage.walker = map.life.people[index]
		map.life.population.spatial_cells.clear()
		for person in map.life.population.size():
			if map.life.population.age(person) < 12:
				var child_job: int = map.life.population.register_job("child", [])
				map.life.population.schedules[child_job] = []
				map.life.population.job[person] = child_job
			map.life.population.set_location(person, map.life.population.locations[person])
			var xp := 1.0
			var output := 0.0
			var mood_bonus := 0.0
			for trait_index in map.life.population.catalogue.traits.size():
				if map.life.population.traits[person] & (1 << trait_index):
					var trait_data: Dictionary = map.life.population.catalogue.traits[trait_index]
					xp *= float(trait_data.xp_multiplier)
					output += float(trait_data.output_bonus)
					mood_bonus += float(trait_data.mood_bonus)
			map.life.population.xp_traits[person] = xp
			map.life.population.output_traits[person] = output
			map.life.population.mood_traits[person] = mood_bonus
		map.life.population.household_names_day = -1
		map.life.population.statistics_day = -1
		map.life.population.prepared_tasks.clear()
		for duties: Array in map.life.population.schedules:
			var tasks: Array = []
			for duty: String in duties: tasks.append(map.life.population.catalogue.activities[duty])
			map.life.population.prepared_tasks.append(tasks)
		var law: RefCounted = map.life.population.society.law
		if law:
			law.rebuild_sight()
			law.residents.clear()
			for p: Dictionary in map.life.people: law.residents[int(p.id)] = p
		if state.get("on_ground", false): map._go_to("Servants' Village", false)
		else: map.show_map()
		map.cam.position = state.get("map_position", map.cam.position)
		map.cam.zoom = state.get("map_zoom", map.cam.zoom)
		map.ground_view.cam.position = state.get("ground_position", map.ground_view.cam.position)
		map.ground_view.cam.zoom = state.get("ground_zoom", map.ground_view.cam.zoom)
		map.ground_view.ledger.current = state.get("book_section", "cultivators")
		map.ground_view.entered_once = true
		return true
	return false


## Column strides come from the subsystem's allocation contract, including flat attribute/heart matrices.
static func repair_columns(object: Object, defaults: Dictionary, count: int) -> void:
	var columns: Dictionary = {
		"population.gd": ["names", "sex", "birth_day", "household", "locations", "settlement", "district", "job", "person_versions", "potential", "attributes", "comprehension", "spirit_root", "root_purity", "root_grade", "constitution", "luck", "traits", "xp_traits", "output_traits", "mood_traits", "mood", "hunger", "tool_quality", "parent_id", "head", "practice_entries", "best_level", "best_skill", "recently_levelled", "insights", "last_insight_day", "stuck", "last_rust_check"],
		"society.gd": ["father", "spouse", "master", "joined", "revealed", "awakening_age", "realm", "layer", "qi", "technique", "technique_element", "site", "injury_until", "bottleneck_since", "damage", "last_birth", "due_day", "twins", "rivalry", "guilt", "resources", "reputation", "alive"],
		"relationships.gd": ["head", "count"],
		"mind.gd": ["heart", "heart_ready", "emotion", "goal", "goal_target", "goal_since", "interrupt", "last_choice", "child_count", "refused_until"],
		"body_tempering.gd": ["body_layer", "grades", "tempering", "strain", "method", "hours", "regimen_until", "teacher", "gate_since", "aim_doses"],
		"nature.gd": ["studied"],
		"childhood.gd": ["interests", "talent_given", "hungry_days", "potential_lost", "watching", "watching_day"],
	}
	var strides := {"attributes": 8, "potential": 8, "practice_entries": 6, "grades": 9, "heart": preload("res://src/mind.gd").WEIGHTS, "emotion": 4}
	var script_name: String = object.get_script().resource_path.get_file()
	for key: String in columns.get(script_name, []):
		var values: Variant = object.get(key)
		var stride := int(strides.get(key, 1))
		var template: Variant = defaults.get(key, [])
		var before: int = values.size()
		values.resize(count * stride)
		for i in range(before, values.size()):
			if not template.is_empty():
				var default: Variant = template[i % mini(stride, template.size())]
				values[i] = default.duplicate(true) if default is Dictionary else default
		object.set(key, values)
	if script_name == "body_tempering.gd":
		for key: String in object.config.medicine_names:
			if not object.medicine.has(key): object.medicine[key] = PackedByteArray()
			var doses: PackedByteArray = object.medicine[key]
			doses.resize(count)
			object.medicine[key] = doses
	for key: String in ["society", "ties", "mind", "temper", "nature", "childhood"]:
		if key in object and object.get(key) != null:
			repair_columns(object.get(key), defaults.get(key, {}), count)
