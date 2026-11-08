extends SceneTree
const World := preload("res://src/world.gd")

func _init() -> void:
	var world := World.new()
	assert(world.population == 10 and world.fields.is_empty() and world.houses.size() == 1)
	assert(world.mark_field(Rect2i(44, 36, 2, 2), [0, 0, 0, 3]) == 0)
	assert(world.mark_field(Rect2i(44, 40, 2, 2), [0, 2, 1, 3]) == 1)
	assert(not world.can_mark(Rect2i(44, 36, 2, 2), true))
	assert(not world.can_mark(Rect2i(51, 38, 2, 2), true))
	assert(world.mark_housing(Rect2i(56, 38, 6, 4)))
	assert(world.mark_field(Rect2i(40, 36, 2, 2), [9, 2, 3, 4]) == 2)
	assert(world.mark_field(Rect2i(40, 40, 2, 2), [11, 11, 11, 11]) == 3)
	assert(world.granary.size() == World.CROPS.size())
	var years := 5
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--years="):
			years = maxi(1, int(argument.get_slice("=", 1)))
	for y in years:
		world.step(World.DAY_LEN * World.DAYS_PER_YEAR)
		for f in world.fields:
			var harvest: Array[String] = []
			for crop in World.CROPS.size():
				if f.last_harvest[crop] > 0:
					harvest.append("%s=%.2f" % [World.CROPS[crop].name, f.last_harvest[crop]])
			print("Year %d field %d: %s fertility=%.2f houses built=%d" % [y + 1, f.id, ", ".join(harvest) if not harvest.is_empty() else "harvest=0.00", world.average_fertility(f), world.houses.size() - 1])
		assert(world.population == 10)
	assert(world.average_fertility(world.fields[1]) > world.average_fertility(world.fields[0]))
	if years >= 5:
		assert(world.houses.size() == 7)
		assert(world.average_fertility(world.fields[3]) < 60)
		assert(world.fields[3].last_harvest[11] == 0)
	# A depleted spirit plot fails; winter turnips grow and potatoes stay idle.
	var probe := World.new()
	probe.mark_field(Rect2i(40, 40, 2, 2), [11, 11, 11, 11])
	for cell in probe.cells(probe.fields[0].rect):
		probe.land.fertility[probe.land.index(cell)] = 59
	probe.step(World.DAY_LEN * World.DAYS_PER_YEAR)
	assert(probe.granary[11] == 0)
	probe.remove_field(0)
	probe.day = 10
	probe.mark_field(Rect2i(40, 40, 2, 2), [4, 4, 4, 4])
	probe.step(World.DAY_LEN * 3)
	assert(probe.granary[4] > 0)
	probe.remove_field(1)
	probe.day = 10
	probe.mark_field(Rect2i(40, 40, 2, 2), [9, 9, 9, 9])
	assert(probe.fields[0].idle)
	probe.step(World.DAY_LEN * 3)
	assert(probe.granary[9] == 0)
	# Removing fields releases their cells; large fields progress a cell at a time.
	world.remove_field(0)
	assert(world.land.field_ids[world.land.index(Vector2i(44, 36))] == -1)
	var large := World.new()
	large.mark_field(Rect2i(20, 20, 12, 12))
	large.step(World.DAY_LEN)
	assert(large.land.at(Vector2i(20, 20)) == World.Land.TILLED)
	assert(large.land.at(Vector2i(31, 31)) == World.Land.GRASS)
	quit()
