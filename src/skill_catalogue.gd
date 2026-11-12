extends RefCounted
## One shared, validated catalogue. Numeric indices are stable within a load.
var spheres: Dictionary = {}
var domains: Dictionary = {}
var disciplines: Dictionary = {}
var skills: Dictionary = {}
var ids: Array[String] = []
var nodes: Array[Dictionary] = []
var indices: Dictionary = {}
var traits: Array = []
var activities: Dictionary = {}
var modifiers: Array = []
var rules: Dictionary = {}
var errors: Array[String] = []
var thresholds := PackedFloat64Array()

func read_json(path: String) -> Variant:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/skills/" + path + ".json"))
	if parsed == null:
		errors.append("Invalid JSON: " + path)
	return parsed

func _init() -> void:
	rules = read_json("rules")
	traits = read_json("traits")
	modifiers = read_json("modifiers")
	activities = read_json("activities")
	for sphere: Dictionary in read_json("spheres"):
		_register(spheres, sphere)
	for domain: Dictionary in read_json("domains"):
		_register(domains, domain)
		if not spheres.has(domain.sphere): errors.append("Unknown sphere: " + str(domain.id))
		var file: Dictionary = read_json("domains/" + str(domain.id))
		if file.id != domain.id: errors.append("Domain file mismatch: " + str(domain.id))
		for discipline: Dictionary in file.disciplines:
			_register(disciplines, discipline)
			if discipline.domain != domain.id: errors.append("Wrong domain: " + str(discipline.id))
			if not discipline.get("detailed", false): continue
			_add_skill(discipline)
			for specialisation: Dictionary in discipline.specialisations:
				if specialisation.discipline != discipline.id: errors.append("Wrong parent: " + str(specialisation.id))
				specialisation.attribute_thresholds = []
				for key: String in specialisation.attribute_requirements:
					specialisation.attribute_thresholds.append(Vector2i(rules.attributes.find(key), int(specialisation.attribute_requirements[key])))
				_add_skill(specialisation)
	for discipline: Dictionary in disciplines.values():
		for related: String in discipline.get("related_disciplines", []):
			if not disciplines.has(related): errors.append("Unknown spillover: " + related)
	for activity: Dictionary in activities.values():
		var parent: Dictionary = disciplines[activity.discipline]
		activity.discipline_index = indices[activity.discipline]
		activity.attribute_indices = []
		for key: String in parent.key_attributes: activity.attribute_indices.append(rules.attributes.find(key))
		if not skills.has(activity.specialisation) or not disciplines.has(activity.discipline):
			errors.append("Unknown activity skill: " + str(activity))
	for level in 51: thresholds.append(float(rules.xp_base) * pow(float(rules.xp_growth), level))
	for error: String in errors: push_error(error)
	assert(errors.is_empty(), "Skill catalogue validation failed")

func _register(target: Dictionary, row: Dictionary) -> void:
	if target.has(row.id): errors.append("Duplicate id: " + str(row.id))
	target[row.id] = row

func _add_skill(row: Dictionary) -> void:
	_register(skills, row)
	indices[row.id] = ids.size()
	ids.append(row.id)
	nodes.append(row)

func title(level: int) -> String:
	return str(rules.titles[0 if level == 0 else mini(10, (level - 1) / 5 + 1)])

func domain_for(skill: String) -> String:
	return skill.get_slice(".", 0)

func discipline_for(skill: String) -> String:
	return ".".join(skill.split(".").slice(0, 2))
