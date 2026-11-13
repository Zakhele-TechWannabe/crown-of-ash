extends SceneTree
## The species catalogue loads, tiers it, and villagers come to know the valley by working in it.
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var fields := p.register_job("field hand", ["fields"])
	var scribe := p.register_job("scribe", ["chores"])
	p.add_person("Wang Erniu", 20, fields)
	p.add_person("Li Shan", 20, scribe)
	var nature: RefCounted = p.society.nature
	assert(nature.species.size() > 6000, "Thousands of species: %d" % nature.species.size())
	var tally: Dictionary = nature.tally()
	assert(tally.individual[1] >= 20 and tally.population[1] >= 400 and tally.guild[1] >= 5000)
	var wolf: Dictionary = {}
	for entry: Dictionary in nature.species:
		assert(entry.tier in ["individual", "population", "guild"] and entry.has("habitat") and entry.has("months"))
		if entry.sci == "Canis lupus": wolf = entry
	assert(wolf.tier == "individual" and int(wolf.gestation) == 63 and float(wolf.food_kg) == 3.5, "Curated field numbers win")
	assert(nature.habitat_of(0) == "field" and nature.habitat_of(1) == "village")
	for week in 52 * 10:
		nature.observe(0, 7, 120 + week * 7)
	assert(nature.known.size() > 30, "Ten years in the fields: %d species seen" % nature.known.size())
	assert(nature.insight(0) > 1.5 and nature.insight(1) == 1.0)
	for id: int in nature.known:
		var habitat: Array = nature.get_species(id).habitat
		assert("field" in habitat, "Seen in the fields: %s" % nature.get_species(id).name)
	print("PASS nature: %d species (%s), %d seen in ten years of field work, insight ×%.2f" % [nature.species.size(), str(tally), nature.known.size(), nature.insight(0)])
	quit()
