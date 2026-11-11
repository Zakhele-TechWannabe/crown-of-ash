extends RefCounted
## Authoritative ledger. Only fixed calendar events mutate the economy.
const EFFECT := [1.0, 0.85, 0.6, 0.35, 0.2]
const HUNGER := ["Fed", "Hungry", "Weak", "Starving", "Starving(long)"]
const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]
var stock := 4500.0
var field_area := 0
var seed_value := 718
var people: Array[Dictionary] = []
var order: Array[int] = []
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
var stock_history: Array[Vector2] = []
var harvest_history: Array[Vector2] = []
var history_cursor := 0

func daily_need() -> float:
	var total := 0.0
	for p: Dictionary in people:
		total += 0.5 if int(p.kind) == 8 else 1.0
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
	seed_value = world_seed
	for field: Dictionary in data.fields:
		field_area += int(field.rect[2]) * int(field.rect[3])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var adults: Array[int] = []
	for n in people.size():
		people[n].hunger = 0
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
	_weather()

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
	return field_area * (8000.0 / 3300.0) * clampf(care() if work > 0 or day > 1 else 1.0, 0.3, 1.1) * weather

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
		var wild := minf(need, 0.3) if int(p.hunger) >= 3 else 0.0
		p.foraged += wild
		flow("foraged", wild)
		var eaten := minf(stock, need * share - wild) if need * share > wild else 0.0
		stock -= eaten
		consumed += eaten
		p.rice_today = eaten
		flow("children" if int(p.kind) == 8 else "adults", eaten)
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
		note("spirit rice below %d days" % (7 if level == 0 else 30))
	warning = level
	if stock <= 0.000001 and not crisis:
		stock = 0.0
		note("granary empty; %d villagers hungry" % hungry_count)
		crisis = true
	elif stock > 0:
		crisis = false

func _finish_day() -> void:
	var labor := 0.0
	if not no_farmers:
		var autumn := day > 182 and day <= 273
		for p: Dictionary in people:
			var hunger := int(p.hunger)
			if int(p.kind) == 0:
				# Starving farmers still put in half a day; at harvest the food is right in front of them.
				labor += maxf(EFFECT[hunger], 0.5) if autumn else (EFFECT[hunger] if hunger < 3 else EFFECT[hunger] * 0.5)
			elif autumn and hunger >= 2 and int(p.kind) != 8:
				# Hungry villagers of any trade join the harvest.
				labor += 0.5
	if day <= 182:
		work += labor
	elif day <= 273:
		if day == 183:
			harvest = forecast()
		var batch := minf(harvest, labor * 12.0)
		harvest -= batch
		stock += batch
		produced += batch
		flow("harvested", batch)
		if harvest <= 0.000001 and batch > 0:
			note("harvest brought in: %d jin of spirit rice" % roundi(produced * 2))
	if day in [91, 182, 273, 365]:
		if day == 91:
			note("fields planted (care %d%%)" % roundi(care() * 100))
		elif day == 182:
			note("tending complete (care %d%%)" % roundi(care() * 100))
		elif day == 273 and harvest > 0.000001:
			note("uncollected harvest lost: %d jin of spirit rice" % roundi(harvest * 2))
			harvest = 0.0
		var loss := stock * 0.02
		stock -= loss
		spoiled += loss
		flow("spoiled", loss)
		note("spirit rice spoilage %d jin" % roundi(loss * 2))
	_thresholds()
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
		summaries.append("Year %d: stock %.2f | harvest %.2f | consumed %.2f | spoilage %.2f | balance %+.2f | minimum %.2f | hungry %d" % [year, stock, produced, consumed, spoiled, produced - consumed - spoiled, minimum, hungry_count])
