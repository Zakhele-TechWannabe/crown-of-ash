extends SceneTree
## Compare the same founding landscape under two government policies.

const World := preload("res://src/world.gd")


## Each fixed step is one second; reports describe the year just completed.
func _init() -> void:
	var years := 5
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--years="):
			years = maxi(1, int(argument.get_slice("=", 1)))
	for mix in [[1, 1, 1], [0, 2, 0]]:
		var world := World.new()
		world.policies.assign(mix)
		print("Policies: %s / %s / %s" % [World.POLICY_NAMES[0][mix[0]], World.POLICY_NAMES[1][mix[1]], World.POLICY_NAMES[2][mix[2]]])
		var starting_houses := world.houses.size()
		var starting_fields := world.fields.size()
		for y in years:
			for tick in int(World.DAY_LEN * World.DAYS_PER_YEAR):
				world.step(1.0)
			print("Year %d: population=%d food=%.0f wood=%.0f houses=%d fields=%d births=%d deaths=%d" % [y + 1, world.population, world.food, world.wood, world.houses.size(), world.fields.size(), world.last_births, world.last_deaths])
			assert(world.population > 0 and world.population < 1000)
		if years >= 5:
			assert(world.houses.size() > starting_houses)
			assert(world.fields.size() > starting_fields)
	quit()
