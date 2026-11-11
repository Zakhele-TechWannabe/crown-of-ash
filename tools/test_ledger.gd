extends SceneTree
## Ledger instrumentation must preserve stocks and deterministic daily records.
func _initialize() -> void:
	var economy := preload("res://src/grain_economy.gd").new()
	var people: Array[Dictionary] = []
	for i in 20:
		people.append({"kind": 8 if i >= 18 else 0})
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sects/first_sect.json"))
	economy.setup(data, people, 718)
	assert(economy.daily_need() == 19.0)
	assert(is_equal_approx(economy.days_left(), 4500.0 / 19.0))
	economy.advance_to(720)
	assert(economy.flow_values("adults")[0] == 18.0)
	assert(economy.flow_values("children")[0] == 1.0)
	assert(people[0].rice_today == 1.0)
	economy.advance_to(1440)
	assert(economy.flow_values("adults")[0] == 0.0)
	assert(economy.stock_history.size() == 1)
	economy.advance_to(1100 * 1440.0)
	assert(economy.stock_history.size() == 730)
	assert(economy.harvest_history.size() == 3)
	var samples: Array[Vector2] = economy.stock_history.duplicate()
	samples.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	assert(samples[0].x == 371 and samples[-1].x == 1100)
	assert(is_equal_approx(economy.flow_values("adults")[3] + economy.flow_values("children")[3], 4500 + economy.flow_values("harvested")[3] - economy.flow_values("spoiled")[3] - economy.stock))
	print("PASS ledger: display need, split flows, daily reset, two-year ring, annual harvest, stock reconciliation")
	quit()
