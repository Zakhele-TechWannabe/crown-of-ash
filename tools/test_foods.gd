extends SceneTree
const Economy = preload("res://src/grain_economy.gd")

func village() -> RefCounted:
	var e := Economy.new()
	var people: Array[Dictionary] = []
	for i in 20:
		people.append({"kind": 0 if i < 8 else (8 if i >= 18 else 1), "food_work": "" if i < 8 or i >= 18 else ["garden", "garden", "orchard", "herd", "herd", "fishery", "hunt", "kitchen", "logs", "kitchen"][i - 8]})
	e.setup(JSON.parse_string(FileAccess.get_file_as_string("res://data/sects/first_sect.json")), people, 718)
	return e

func _initialize() -> void:
	var e := village()
	assert(e.goods.size() == 78)
	for id: String in e.goods:
		var g: Dictionary = e.goods[id]
		assert(g.has("source") and not g.seasons.is_empty() and not g.description.is_empty())
		assert(g.seasonal_spoilage >= 0 and g.seasonal_spoilage <= 1)
	assert(e.quantity("vegetables") > 0 and e.quantity("pantry") > 0)
	assert(e.stocks.sea_fish == 0)
	# Fresh roots leave the pantry before durable beans within a vegetable course.
	e._eat_group("vegetables", 0.1, "adults")
	assert(e.stocks.soybeans == e.goods.soybeans.starting_rations)
	# Recipes are limited by the least available ingredient and log both sides.
	e.stocks.soybeans = 0.6
	var tofu_before: float = e.stocks.tofu
	e._recipe("tofu", {"soybeans": 0.6}, 2.0)
	assert(is_zero_approx(e.stocks.soybeans))
	assert(is_equal_approx(e.stocks.tofu - tofu_before, 1.0))
	assert(e.node_flow("soybeans", "processed")[3] > 0)
	var daily := village()
	var jump := village()
	var pantry_year := 0.0
	for day in 1095:
		daily.advance_to((day + 1) * 1440.0)
		if day >= 30:
			for group: String in ["grains", "vegetables", "fruit", "meat", "fish", "pantry"]:
				assert(daily.quantity(group) > 0, "Empty group: " + group + " day " + str(day))
		if day % 365 == 198:
			assert(daily.quantity("vegetables") * 2 > 300)
			assert(daily.quantity("fruit") * 2 > 50)
			assert((daily.quantity("meat") + daily.quantity("fish")) * 2 > 80)
			var stocked := 0
			var seasonal_count := 0
			for id: String in daily.goods:
				if "vegetables" in daily.goods[id].category_path and "Autumn" in daily.goods[id].seasons:
					seasonal_count += 1
					if daily.stocks[id] > 1: stocked += 1
			assert(stocked > seasonal_count / 2)
		if day % 365 == 364:
			assert(daily.quantity("pantry") > pantry_year)
			pantry_year = daily.quantity("pantry")
		assert(daily.people.size() == 20 and daily.hungry_count == 0)
		for p: Dictionary in daily.people:
			assert(p.diet_variety >= 1 and p.contentment >= 0 and p.contentment <= 1)
		for id: String in daily.stocks:
			assert(float(daily.stocks[id]) >= -0.000001)
	jump.advance_to(1095 * 1440.0)
	assert(daily.stocks == jump.stocks and daily.chronicle == jump.chronicle)
	assert(daily.flows == jump.flows and daily.people == jump.people)
	assert(jump.stocks.sea_fish == 0)
	for group: String in ["vegetables", "fruit", "meat", "fish", "pantry"]:
		assert(jump.node_flow(group, "harvested")[3] > 0)
		assert(jump.node_flow(group, "adults")[3] > 0)
	for id: String in jump.goods:
		var balance: float = float(jump.goods[id].starting_rations) + jump.node_flow(id, "harvested")[3] - jump.node_flow(id, "processed")[3] - jump.node_flow(id, "adults")[3] - jump.node_flow(id, "children")[3] - jump.node_flow(id, "spoiled")[3]
		assert(is_equal_approx(balance, float(jump.stocks[id])), "Balance: " + id)
	var plain := village()
	plain.no_farmers = true
	plain.stock = 5000.0
	plain.advance_to(10 * 1440.0)
	assert(plain.people[0].diet_variety == 1 and plain.people[0].mood == "plain fare")
	assert(plain.hungry_count == 0)
	var seasonal := village()
	seasonal._food_production()
	assert(seasonal.node_flow("peach", "harvested")[3] == 0)
	assert(seasonal.node_flow("bamboo_shoots", "harvested")[3] > 0)
	seasonal.day = 92
	seasonal._food_production()
	assert(seasonal.node_flow("peach", "harvested")[3] > 0)
	assert(seasonal.node_flow("water_spinach", "harvested")[3] > 0)
	assert("First peaches" in seasonal.chronicle[-1])
	var winter := village()
	winter.day = 300
	winter._food_production()
	assert(winter.node_flow("vegetables", "harvested")[3] == 0)
	assert(winter.node_flow("meat", "harvested")[3] == 0)
	assert(winter.node_flow("tofu", "harvested")[3] > 0)
	for p: Dictionary in winter.people:
		p.food_work = ""
	var before: Dictionary = winter.stocks.duplicate()
	winter._food_production()
	assert(before == winter.stocks)
	print("PASS foods: catalogue, fresh-first meals, recipes, staffing, winter stores, no deaths/hunger, three-year deterministic accounting")
	quit()
