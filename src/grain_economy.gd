extends RefCounted
## Authoritative ledger. Only fixed calendar events mutate the economy.
const EFFECT := [1.0, 0.85, 0.6, 0.35, 0.2]
const HUNGER := ["Fed", "Hungry", "Weak", "Starving", "Starving(long)"]
const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]
# Compatibility totals refer to mortal food; quantities remain internal rations.
var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/goods.json"))
var goods: Dictionary = {}
var stocks: Dictionary = {"common_rice": 4500.0, "spirit_rice": 0.0}
var areas: Dictionary = {}
var standing: Dictionary = {}
var histories: Dictionary = {}
var annual_histories: Dictionary = {}
var stock: float:
	get: return mortal_food()
	set(value):
		# Compatibility/debug override sets the total edible reserve.
		for id: String in goods:
			if "mortals" in goods[id].edible_by:
				stocks[id] = 0.0
		stocks["common_rice"] = value

func mortal_food() -> float:
	var total := 0.0
	for id: String in goods:
		if "mortals" in goods[id].edible_by:
			total += float(stocks[id])
	return total if not goods.is_empty() else float(stocks.common_rice)

func descendants(id: String) -> Array[String]:
	var result: Array[String] = []
	for good: String in goods:
		if good == id or id in goods[good].category_path:
			result.append(good)
	return result

func quantity(id: String) -> float:
	var total := 0.0
	for good: String in descendants(id):
		total += float(stocks[good])
	return total

func edible_quantity(id: String) -> float:
	var total := 0.0
	for good: String in descendants(id):
		if "mortals" in goods[good].edible_by:
			total += float(stocks[good])
	return total

func good_forecast(id: String) -> float:
	var total := 0.0
	for good: String in descendants(id):
		total += float(areas[good]) * float(goods[good].yield_rations_per_mu) * clampf(care() if work > 0 or day > 1 else 1.0, 0.3, 2.5 if population != null else 1.1) * weather
	return total

func node_flow(id: String, key: String) -> Array:
	var values := [0.0, 0.0, 0.0, 0.0]
	for good: String in descendants(id):
		var row := flow_values(good + ":" + key)
		for i in 4:
			values[i] += float(row[i])
	return values

func record_good(id: String, key: String, value: float) -> void:
	flow(id + ":" + key, value)
	if "mortals" in goods[id].edible_by:
		flow(key, value)
var field_area := 0
var seed_value := 718
var people: Array[Dictionary] = []
var coarse_population := false
var population: RefCounted
var skill_event_cursor := 0
var order: Array[int] = []
## Population ids that walk the map; everyone else is fed and counted from the population.
var walker_ids: Dictionary = {}
var chronicle: Array[String] = []
var summaries: Array[String] = []
var year := 1
var day := 1
var work := 0.0
var weather := 1.0
var harvest := 0.0
var produced := 0.0
var consumed := 0.0
var spoiled := 0.0
var minimum := 4500.0
var no_farmers := false
var bad_harvest := false
var pause_on_crisis := false
var rationing := false
var crisis := false
var warning := 2
var hungry_count := 0
var flows: Dictionary = {}
var yesterday_flows: Dictionary = {}

func yesterday_flow(id: String, key: String) -> float:
	var total := 0.0
	for good: String in descendants(id):
		total += float(yesterday_flows.get(good + ":" + key, 0.0))
	return total

var stock_history: Array[Vector2] = []
var harvest_history: Array[Vector2] = []
var history_cursor := 0

func daily_need() -> float:
	var total := 0.0
	for p: Dictionary in people:
		total += 0.5 if int(p.kind) == 8 else 1.0
	if population != null:
		for id in population.size():
			if walker_ids.has(id): continue
			if population.society.alive[id]: total += .5 if population.age(id) < 18 else 1.0
	return total

func days_left() -> float:
	return stock / maxf(daily_need(), 0.001)

func days_to_harvest() -> int:
	return maxi(0, 183 - day) if day <= 273 else 365 - day + 183

func flow(key: String, amount: float) -> void:
	var absolute := (year - 1) * 365 + day
	var period := [absolute, (year - 1) * 4 + season(), year, 0]
	if not flows.has(key):
		flows[key] = [0.0, 0.0, 0.0, 0.0, period.duplicate()]
	var row: Array = flows[key]
	for i in 4:
		if row[4][i] != period[i]:
			row[i] = 0.0
		row[4][i] = period[i]
		row[i] += amount

func flow_values(key: String) -> Array:
	var absolute := (year - 1) * 365 + day
	var period := [absolute, (year - 1) * 4 + season(), year, 0]
	var values := [0.0, 0.0, 0.0, 0.0]
	if flows.has(key):
		for i in 4:
			if flows[key][4][i] == period[i]:
				values[i] = flows[key][i]
	return values

var next_event := 720.0

func setup(data: Dictionary, residents: Array[Dictionary], world_seed: int) -> void:
	people = residents
	if population != null:
		population.society.wildlife.economy_ref = weakref(self)
		if not residents.is_empty() and residents[0].has("wildlife_places"):
			population.society.wildlife.encounter_places = residents[0].wildlife_places.duplicate()
	for good: Dictionary in catalogue.goods:
		goods[good.id] = good
		stocks[good.id] = float(good.starting_rations)
		areas[good.id] = 0
		standing[good.id] = 0.0
		histories[good.id] = []
		annual_histories[good.id] = []
	seed_value = world_seed
	for field: Dictionary in data.fields:
		var area := int(field.rect[2]) * int(field.rect[3])
		field_area += area
		areas[field.get("crop", "common_rice")] += area
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var adults: Array[int] = []
	for n in people.size():
		people[n].hunger = 0
		people[n].diet_variety = 0
		people[n].contentment = 0.6
		people[n].mood = "content"
		people[n].foraged = 0.0
		people[n].rice_today = 0.0
		if int(people[n].kind) == 8:
			order.append(n)
		else:
			adults.append(n)
	for i in range(adults.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var old := adults[i]
		adults[i] = adults[j]
		adults[j] = old
	order.append_array(adults)
	for p: Dictionary in people: walker_ids[int(p.get("id", -1))] = true
	_weather()

## Walkers died or arrived: rebuild who eats in which order.
func walkers_changed() -> void:
	order.clear()
	walker_ids.clear()
	var adults: Array[int] = []
	for n in people.size():
		walker_ids[int(people[n].id)] = true
		if int(people[n].kind) == 8: order.append(n)
		else: adults.append(n)
	order.append_array(adults)

func season() -> int:
	return 0 if day <= 91 else (1 if day <= 182 else (2 if day <= 273 else 3))

func note(message: String) -> void:
	chronicle.append("Y%d %s: %s" % [year, SEASONS[season()], message])

func _weather() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + year * 104729
	weather = rng.randf_range(0.6, 0.75) if rng.randi_range(0, 7) == 0 else rng.randf_range(0.9, 1.1)
	if bad_harvest and year == 1:
		weather = 0.6
	if weather < 0.8:
		note("poor seasonal weather; forecast down %d%%" % roundi((1.0 - weather) * 100))

func care() -> float:
	return work / (8.0 * minf(day, 182))

func forecast() -> float:
	var total := 0.0
	for id: String in goods:
		if "mortals" in goods[id].edible_by:
			total += good_forecast(id)
	return total

func advance_to(minutes: float) -> void:
	while next_event <= minutes:
		var absolute_day := int(next_event / 1440.0)
		year = absolute_day / 365 + 1
		day = absolute_day % 365 + 1
		if int(next_event) % 1440 == 720:
			_meal()
			next_event += 720.0
		else:
			# Midnight belongs to the preceding day's work and season end.
			absolute_day -= 1
			year = absolute_day / 365 + 1
			day = absolute_day % 365 + 1
			_finish_day()
			next_event += 720.0
			if day == 365:
				year += 1
				day = 1
				work = 0.0
				produced = 0.0
				consumed = 0.0
				spoiled = 0.0
				minimum = stock
				_weather()

	year = int(minutes / 1440.0) / 365 + 1
	day = int(minutes / 1440.0) % 365 + 1

## Share of a full ration everyone gets, so the stock lasts until the harvest comes in (never below 0.6).
func ration() -> float:
	var until_harvest := 0
	if day < 183:
		until_harvest = 183 + 30 - day
	elif day > 273:
		until_harvest = 365 - day + 183 + 30
	if until_harvest == 0:
		return 1.0
	return clampf(stock / (until_harvest * daily_need()), 0.6, 1.0)

func _meal() -> void:
	var hungry := 0
	var share := ration()
	if share < 1.0 and not rationing:
		note("rationing: %d%% portions until the harvest" % roundi(share * 100))
	elif share >= 1.0 and rationing:
		note("rationing ends")
	rationing = share < 1.0
	for n: int in order:
		var p: Dictionary = people[n]
		var need := 0.5 if int(p.kind) == 8 else 1.0
		var wild := minf(need, 0.3) if int(p.hunger) >= 3 and (population == null or population.age(int(p.id)) >= 12) else 0.0
		p.foraged += wild
		flow("foraged", wild)
		var eaten := minf(stock, need * share - wild) if need * share > wild else 0.0
		var remaining := eaten
		var groups: Dictionary = {}
		var key := "children" if int(p.kind) == 8 else "adults"
		# A bowl of staple, seasonal greens, occasional protein and orchard fruit.
		for course: Array in [["vegetables", 0.30], ["meat", 0.08 if day % 3 != 0 else 0.0], ["fish", 0.08 if day % 3 == 0 else 0.0], ["fruit", 0.08], ["pantry", 0.04], ["grains", 0.50]]:
			var taken := _eat_group(str(course[0]), minf(remaining, eaten * float(course[1])), key)
			remaining -= taken
			if taken > 0.000001:
				groups[course[0]] = true
		# Shortages substitute from any edible store, still using the most perishable first.
		remaining -= _eat_group("food", remaining, key, groups)
		p.diet_variety = groups.size()
		var comfort := 1.0 if groups.size() >= 4 else (0.65 if groups.size() >= 2 else 0.3)
		p.contentment = lerpf(float(p.contentment), comfort * minf(1.0, eaten / need), 0.12)
		p.mood = "well fed" if float(p.contentment) >= 0.78 else ("content" if float(p.contentment) >= 0.45 else "plain fare")
		# Condiments and tea accompany meals but cannot replace a hunger ration.
		for seasoning: String in ["soy_sauce", "vinegar", "cooking_oil", "tea", "rice_wine"]:
			if seasoning == "rice_wine" and int(p.kind) == 8:
				continue
			var used := minf(float(stocks[seasoning]), 0.0015 * need)
			stocks[seasoning] -= used
			record_good(seasoning, key, used)
		consumed += eaten
		p.rice_today = eaten
		var got := eaten + wild
		if got >= need - 0.000001:
			p.hunger = maxi(0, int(p.hunger) - 1)
		elif got >= need * 0.6 - 0.000001:
			# Short rations keep people hungry but on their feet.
			p.hunger = 1 if int(p.hunger) <= 1 else int(p.hunger) - 1
		else:
			p.hunger = mini(4, int(p.hunger) + 1)
		if int(p.hunger) > 0:
			hungry += 1
	if population != null:
		for id in population.size():
			if walker_ids.has(id): continue
			if not population.society.alive[id]: continue
			var need := .5 if population.age(id) < 18 else 1.0
			var eaten := _eat_group("food", need * share, "children" if population.age(id) < 18 else "adults")
			consumed += eaten
			population.hunger[id] = maxi(0, population.hunger[id] - 1) if eaten >= need * .99 else mini(4, population.hunger[id] + 1)
			population.mood[id] = lerpf(population.mood[id], eaten / need * .7, .12)
			hungry += int(population.hunger[id] > 0)
	if hungry > 0 and hungry_count == 0:
		note("hunger begins; %d villagers hungry" % hungry)
	elif hungry == 0 and hungry_count > 0:
		note("everyone fed and recovered")
	hungry_count = hungry
	_thresholds()

func _thresholds() -> void:
	minimum = minf(minimum, stock)
	var level := 0 if stock < 7 * daily_need() else (1 if stock < 30 * daily_need() else 2)
	if level < warning:
		note("food below %d days" % (7 if level == 0 else 30))
	warning = level
	if stock <= 0.000001 and not crisis:
		stock = 0.0
		note("granary empty; %d villagers hungry" % hungry_count)
		crisis = true
	elif stock > 0:
		crisis = false

func _finish_day() -> void:
	if population != null:
		population.society.stores_years = stock / maxf(1, daily_need() * 365)
		population.sync_walkers(people)
		if population.size() <= 1000 and not coarse_population: population.tick_day((year - 1) * 365 + day)
		while skill_event_cursor < population.events.size():
			var event: Dictionary = population.events[skill_event_cursor]
			if event.get("source", "") != "society": note(event.text)
			skill_event_cursor += 1
	_food_production()
	_material_production()
	var labor := 0.0
	if not no_farmers:
		var autumn := day > 182 and day <= 273
		for p: Dictionary in people:
			if population and population.age(int(p.id)) < 12: continue
			var hunger := int(p.hunger)
			if int(p.kind) == 0:
				# Starving farmers still put in half a day; at harvest the food is right in front of them.
				labor += (maxf(EFFECT[hunger], 0.5) if autumn else (EFFECT[hunger] if hunger < 3 else EFFECT[hunger] * 0.5)) * _skill_output(p, "fields")
			elif autumn and hunger >= 2 and int(p.kind) != 8:
				# Hungry villagers of any trade join the harvest.
				labor += 0.5 * (population.society.childhood.work_fraction(int(p.id)) if population else 1.0)
	if population != null and not no_farmers:
		for id in population.size():
			if walker_ids.has(id): continue
			if population.age(id) < 12 or not population.society.alive[id]: continue
			if "fields" in population.schedules[population.job[id]]: labor += EFFECT[population.hunger[id]] * population.output(id, "fields") * population.society.childhood.work_fraction(id) * (.5 if population.age(id) < 18 else 1)
	if day <= 182:
		work += labor
	elif day <= 273:
		if day == 183:
			for id: String in goods:
				standing[id] = good_forecast(id)
		var remaining := 0.0
		for id: String in goods:
			remaining += float(standing[id])
		var capacity := labor * 20.0
		for id: String in goods:
			var batch := minf(float(standing[id]), capacity * float(standing[id]) / maxf(remaining, 0.001))
			standing[id] -= batch
			stocks[id] += batch
			record_good(id, "harvested", batch)
			if float(standing[id]) <= 0.000001 and batch > 0:
				note("Harvest brought in: %d jin of %s" % [roundi(node_flow(id, "harvested")[2] * 2), goods[id].name])
			if "mortals" in goods[id].edible_by:
				produced += batch
		harvest = float(standing.common_rice)

	if day in [91, 182, 273, 365]:
		if day == 91:
			note("fields planted (care %d%%)" % roundi(care() * 100))
		elif day == 182:
			note("tending complete (care %d%%)" % roundi(care() * 100))
		elif day == 273 and harvest > 0.000001:
			note("uncollected harvest lost: %d jin of common rice" % roundi(harvest * 2))
			harvest = 0.0
		for id: String in goods:
			var loss := float(stocks[id]) * float(goods[id].seasonal_spoilage)
			stocks[id] -= loss
			record_good(id, "spoiled", loss)
			if "mortals" in goods[id].edible_by:
				spoiled += loss
			if loss >= 1.0 and "grains" in goods[id].category_path:
				note("%s spoilage %d jin" % [goods[id].name, roundi(loss * 2)])
			if day == 273:
				standing[id] = 0.0

	_thresholds()
	for id: String in goods:
		histories[id].append(Vector2((year - 1) * 365 + day, float(stocks[id])))
		if histories[id].size() > 730:
			histories[id].pop_front()
		if day == 365:
			annual_histories[id].append(Vector2(year, node_flow(id, "harvested")[2]))
	var sample := Vector2((year - 1) * 365 + day, stock)
	if stock_history.size() < 730:
		stock_history.append(sample)
	else:
		stock_history[history_cursor] = sample
		history_cursor = (history_cursor + 1) % 730
	for p: Dictionary in people:
		p.rice_today = 0.0
	if day == 365:
		harvest_history.append(Vector2(year, produced))
		for group: String in ["grains", "vegetables", "fruit", "meat", "fish", "pantry", "wood", "earth", "metal", "fibre", "other_materials"]:
			var units := "jin / pieces" if group in ["wood", "earth", "metal", "fibre", "other_materials"] else "jin"
			summaries.append("Year %d %s: stored %.2f %s | produced %.2f | eaten %.2f | processed %.2f | spoiled %.2f" % [year, group, quantity(group) * 2, units, node_flow(group, "harvested")[2] * 2, (node_flow(group, "adults")[2] + node_flow(group, "children")[2]) * 2, node_flow(group, "processed")[2] * 2, node_flow(group, "spoiled")[2] * 2])
		summaries.append("Year %d: stock %.2f | harvest %.2f | consumed %.2f | spoilage %.2f | balance %+.2f | minimum %.2f | hungry %d" % [year, stock, produced, consumed, spoiled, produced - consumed - spoiled - flow_values("processed")[2], minimum, hungry_count])

	yesterday_flows.clear()
	for key: String in flows:
		yesterday_flows[key] = flow_values(key)[0]

func after_harvest_days() -> float:
	var incoming := forecast()
	if day >= 183 and day <= 273:
		incoming = 0.0
		for id: String in goods:
			if "mortals" in goods[id].edible_by:
				incoming += float(standing[id])
	return (stock + incoming - daily_need() * days_to_harvest()) / maxf(0.001, daily_need())

# Food stocks use the existing internal ration accounting convention (one ration = two jin).
func _eat_group(group: String, wanted: float, key: String, groups: Dictionary = {}) -> float:
	var remaining := wanted
	while remaining > 0.000001:
		var chosen := ""
		for id: String in goods:
			if group not in goods[id].category_path or "mortals" not in goods[id].edible_by or float(stocks[id]) <= 0.000001:
				continue
			if chosen.is_empty() or float(goods[id].seasonal_spoilage) > float(goods[chosen].seasonal_spoilage) or (goods[id].seasonal_spoilage == goods[chosen].seasonal_spoilage and float(stocks[id]) > float(stocks[chosen])):
				chosen = id
		if chosen.is_empty():
			break
		var portion := minf(remaining, float(stocks[chosen]))
		stocks[chosen] -= portion
		remaining -= portion
		record_good(chosen, key, portion)
		groups[goods[chosen].category_path[1]] = true
	return wanted - remaining

func _add_food(id: String, batch: float) -> void:
	stocks[id] += batch
	record_good(id, "harvested", batch)
	if "mortals" in goods[id].edible_by:
		produced += batch

func _recipe(output: String, ingredients: Dictionary, batch: float) -> void:
	var possible := batch
	for id: String in ingredients:
		possible = minf(possible, float(stocks[id]) / float(ingredients[id]))
	if possible <= 0.000001:
		return
	for id: String in ingredients:
		var used := possible * float(ingredients[id])
		stocks[id] = maxf(0.0, float(stocks[id]) - used)
		record_good(id, "processed", used)
	_add_food(output, possible)

func _food_production() -> void:
	if no_farmers:
		return
	var workers: Dictionary = {}
	var raw_workers: Dictionary = {}
	for p: Dictionary in people:
		if population and population.age(int(p.id)) < 12: continue
		var facility := str(p.get("food_work", ""))
		raw_workers[facility] = float(raw_workers.get(facility, 0.0)) + EFFECT[int(p.hunger)]
		workers[facility] = float(workers.get(facility, 0.0)) + EFFECT[int(p.hunger)] * _skill_output(p, facility)
	for id: String in goods:
		var g: Dictionary = goods[id]
		if "food" not in g.category_path or not g.has("facility") or SEASONS[season()] not in g.seasons:
			continue
		var staffing := float(workers.get(g.facility, 0.0)) / maxf(1.0, float(raw_workers.get(g.facility, 0.0)))
		if g.facility == "apiary":
			staffing = float(workers.get("orchard", 0.0)) / maxf(1.0, float(raw_workers.get("orchard", 0.0)))
		var batch := float(g.daily_yield) * staffing
		if id in ["pork", "venison", "wild_boar"] and season() == 2:
			batch *= 2.0
		if batch > 0:
			_add_food(id, batch)
	if float(workers.get("kitchen", 0.0)) <= 0:
		return
	var kitchen_efficiency: float = float(workers.kitchen) / maxf(1.0, float(raw_workers.kitchen))
	_recipe("tofu", {"soybeans": 0.6}, 0.35 * kitchen_efficiency)
	_recipe("soy_sauce", {"soybeans": 0.8, "salt": 0.05}, 0.025 * kitchen_efficiency)
	_recipe("vinegar", {"common_rice": 1.0}, 0.02 * kitchen_efficiency)
	_recipe("rice_wine", {"common_rice": 1.0}, 0.025 * kitchen_efficiency)
	_recipe("cooking_oil", {"soybeans": 2.0}, 0.02 * kitchen_efficiency)
	# Keep generous fresh reserves; the kitchen dries, salts and pickles the excess.
	for id: String in goods:
		var group: String = goods[id].category_path[1]
		var output := ""
		match group:
			"vegetables": output = "dried_mushrooms" if goods[id].icon == "mushroom" else "pickled_vegetables"
			"fruit": output = "dried_fruit"
			"meat": output = "cured_pork" if id in ["pork", "wild_boar"] else ""
			"fish": output = "salted_fish"
		if not output.is_empty():
			var surplus := maxf(0.0, float(stocks[id]) - 65.0)
			_recipe(output, {id: 1.25}, surplus * 0.06 * kitchen_efficiency)
	if day == 92:
		note("First peaches ripen in the village orchard")
	elif day == 183:
		note("Autumn slaughter; the kitchen salts fish and cures pork for winter")
	elif day == 273:
		note("Pickling done; jars and dried provisions fill the winter pantry")

# Materials share the ledger's half-unit storage convention; UI converts to jin/pieces.
func _material_production() -> void:
	var staffing: Dictionary = {}
	var raw_workers: Dictionary = {}
	for person: Dictionary in people:
		if population and population.age(int(person.id)) < 12: continue
		var trade := str(person.get("material_work", ""))
		raw_workers[trade] = float(raw_workers.get(trade, 0.0)) + EFFECT[int(person.hunger)]
		staffing[trade] = float(staffing.get(trade, 0.0)) + EFFECT[int(person.hunger)] * _skill_output(person, trade)
		if person.get("food_work", "") == "hunt":
			raw_workers["hunt"] = EFFECT[int(person.hunger)]
			staffing["hunt"] = EFFECT[int(person.hunger)] * _skill_output(person, "hunt")
	for id: String in goods:
		var g: Dictionary = goods[id]
		if "materials" not in g.category_path or g.get("trade_only", false) or g.grade != "mortal" or SEASONS[season()] not in g.seasons:
			continue
		var hands := float(staffing.get(g.facility, 0.0)) / maxf(1.0, float(raw_workers.get(g.facility, 0.0)))
		if hands <= 0:
			continue
		if g.has("recipe"):
			_recipe(id, g.recipe, float(g.recipe_batch) * hands)
		elif not g.has("gather_days") or (day >= int(g.gather_days[0]) and day <= int(g.gather_days[1])):
			_add_food(id, float(g.daily_yield) * hands * (1.5 if g.facility == "woodcutting" and season() == 2 else 1.0))
	for id: String in ["firewood", "tools", "cloth"]:
		var wanted := (1.4 if season() == 3 else 0.7) if id == "firewood" else 0.025
		var used := minf(float(stocks[id]), wanted)
		stocks[id] = maxf(0.0, float(stocks[id]) - used)
		record_good(id, "processed", used)
	if year == 1 and day == 1:
		if node_flow("bricks", "harvested")[3] > 0: note("First bricks fired in the village kiln")
		if node_flow("iron_ingots", "harvested")[3] > 0: note("First iron smelted in the bloomery")
	if day == 273 and float(stocks.firewood) >= 130:
		note("Winter woodpile ready; cooking and heating fuel sheltered")

func _skill_output(person: Dictionary, duty: String) -> float:
	if population == null or not person.has("id") or not population.catalogue.activities.has(duty): return 1.0
	var output: float = population.output(int(person.id), duty) * population.society.childhood.work_fraction(int(person.id))
	if duty in ["fields", "garden"] and population.has_trait(int(person.id), "green_thumb"): output *= 1.1
	return output
