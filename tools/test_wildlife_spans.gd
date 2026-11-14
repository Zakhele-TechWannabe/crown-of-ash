extends SceneTree
const Population = preload("res://src/population.gd")
const Economy = preload("res://src/grain_economy.gd")
const Save = preload("res://src/world_save.gd")

func village() -> RefCounted:
	var store := Population.new()
	var job := store.register_job("forest worker", ["logs"])
	for i in 20: store.add_person("Worker %d" % i, 25, job, i)
	store.society.seed()
	return store

func _initialize() -> void:
	var daily := village()
	var jumped := village()
	var daily_food := Economy.new()
	var jump_food := Economy.new()
	for food: RefCounted in [daily_food, jump_food]:
		food.stocks = {"pork":1000.0,"mutton":1000.0,"chicken":1000.0}
	daily.society.wildlife.economy_ref = weakref(daily_food)
	jumped.society.wildlife.economy_ref = weakref(jump_food)
	# Exercise raids as well as contacts without relying on their rare baseline roll.
	for store: RefCounted in [daily, jumped]: store.society.wildlife.config.raid_day = 0.02
	for day in range(1, 3655):
		daily.day = day
		daily.society.tick(day)
		if day % 7 == 0:
			jumped.day = day
			jumped.society.tick(day)
	assert(daily_food.stocks == jump_food.stocks, "Raid stock effects match across spans")
	assert(Save.capture(daily.society.wildlife) == Save.capture(jumped.society.wildlife), "Ecology, encounters and RNG match across spans")
	assert(daily.society.chronicle == jumped.society.chronicle, "Contact chronicles match across spans")
	assert(daily.society.fights == jumped.society.fights, "Fight staging matches across spans")
	assert(daily.society.injury_until == jumped.society.injury_until, "Injuries use the same village tick date")
	assert(daily.society.alive == jumped.society.alive and daily.attributes == jumped.attributes, "Village harm matches across spans")
	assert(daily.society.wildlife.totals.encounters > 0 and daily.society.wildlife.totals.raids > 0)
	print("PASS wildlife spans: ecology, contacts, raids, village harm, chronicle and fight staging")
	quit()
