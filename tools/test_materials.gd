extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map.life.set_process(false)
	var e: RefCounted = map.life.economy
	assert(e.descendants("materials").size() == 47)
	var claimed: Dictionary = {}
	for patch: Dictionary in map.life.food_patches:
		for tile: Vector2i in patch.tiles: claimed[tile] = true
	for patch: Dictionary in map.life.material_patches:
		assert(patch.tiles.size() == 24)
		var surrounding_low := 1000
		var surrounding_high := -1000
		for dy in range(-16, 17, 4):
			for dx in range(-16, 17, 4):
				var level: int = map.ground.terrace_level(patch.tiles[0] + Vector2i(dx, dy))
				surrounding_low = mini(surrounding_low, level)
				surrounding_high = maxi(surrounding_high, level)
		if patch.kind in ["mine", "quarry"]:
			assert(surrounding_high > surrounding_low, "Mine/quarry must meet a real slope")
		if patch.kind == "clay":
			var water_distance := 1000.0
			for dy in range(-60, 61, 4):
				for dx in range(-60, 61, 4):
					var tile: Vector2i = patch.tiles[0] + Vector2i(dx, dy)
					if int(map.ground.sample(tile).kind) <= 2:
						water_distance = minf(water_distance, Vector2(dx, dy).length())
			print("CLAY nearest water %.1f tiles" % water_distance)
			assert(water_distance <= 60)
		print("TERRAIN %s surrounding levels %d..%d" % [patch.kind, surrounding_low, surrounding_high])
		assert(not map.life.grid.get_point_path(map.life.square, patch.tile).is_empty())
		for tile: Vector2i in patch.tiles:
			assert(not claimed.has(tile))
			assert(map.ground.natural_dry(tile))
			assert(map.life.sect.surface_at(tile) in ["", "grass", "garden"])
			assert(map.life.sect.art[map.life.sect.index_at(tile)] < 0)
			claimed[tile] = true
	var residents: Array[Dictionary] = map.life.people.duplicate(true)
	var jump := preload("res://src/grain_economy.gd").new()
	jump.population = preload("res://src/population.gd").new()
	jump.population.seed_residents(residents)
	jump.setup(map.life.sect.data, residents, 718)
	for d in 1095:
		e.advance_to((d + 1) * 1440.0)
		assert(e.hungry_count == 0 and e.people.size() == 20 and e.days_left() > 90)
		assert(e.stocks.firewood > 0 and e.stocks.tools > 0 and e.stocks.cloth > 0)
		if d == 198:
			var seen_stocks: Dictionary = {}
			for id: String in ["fieldstone", "cut_stone", "granite", "sand", "coal"]:
				assert(not seen_stocks.has(e.stocks[id]), "Distinct material reserves: " + id)
				seen_stocks[e.stocks[id]] = true
			assert(e.yesterday_flow("materials", "harvested") > 0)
		for id: String in e.descendants("materials"):
			assert(float(e.stocks[id]) >= 0)
			if e.goods[id].grade == "spirit": assert(e.stocks[id] == 0)
		if d % 365 == 198:
			for group: String in ["wood", "earth", "metal", "fibre", "other_materials"]:
				print("MATERIAL DAY200 Y%d %s %.2f" % [d / 365 + 1, group, e.quantity(group) * 2])
	jump.advance_to(1095 * 1440.0)
	assert(e.stocks == jump.stocks and e.flows == jump.flows and e.chronicle == jump.chronicle)
	assert(e.population.skill_level == jump.population.skill_level and e.population.skill_xp == jump.population.skill_xp and e.population.attributes == jump.population.attributes, "Daily stepping and time jumps preserve population growth")
	for id: String in e.descendants("materials"):
		assert(is_equal_approx(float(e.goods[id].starting_rations) + e.node_flow(id,"harvested")[3] - e.node_flow(id,"processed")[3], float(e.stocks[id])))
	for id: String in e.descendants("materials"):
		if e.goods[id].get("trade_only", false):
			assert(e.stocks[id] == 0)
		elif e.goods[id].grade == "mortal":
			assert(float(e.stocks[id]) > float(e.goods[id].starting_rations), "Material reserve should grow: " + id)
	var winter_ore: float = jump.stocks.iron_ore
	jump.day = 320
	jump._material_production()
	assert(jump.stocks.iron_ore <= winter_ore)
	jump.stocks.pine_logs = 0
	var planks_before: float = jump.stocks.planks
	jump._recipe("planks", {"pine_logs": 1}, 10)
	assert(jump.stocks.planks == planks_before)
	print("PASS materials: dry separate reachable sites, mortal-only production, three-year comfort, fuel/upkeep, recipes, deterministic balances")
	quit()
