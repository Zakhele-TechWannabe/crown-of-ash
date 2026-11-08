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
	for y in 5:
		world.step(World.DAY_LEN * World.DAYS_PER_YEAR)
		for f in world.fields:
			print("Year %d field %d: Wheat=%.2f Barley=%.2f Beans=%.2f fertility=%.2f houses built=%d" % [y + 1, f.id, f.last_harvest[0], f.last_harvest[1], f.last_harvest[2], world.average_fertility(f), world.houses.size() - 1])
		assert(world.population == 10)
	assert(world.average_fertility(world.fields[1]) > world.average_fertility(world.fields[0]))
	assert(world.houses.size() == 7)
	# Removing fields releases their cells; large fields progress a cell at a time.
	world.remove_field(0)
	assert(world.land.field_ids[world.land.index(Vector2i(44, 36))] == -1)
	var large := World.new()
	large.mark_field(Rect2i(20, 20, 12, 12))
	large.step(World.DAY_LEN)
	assert(large.land.at(Vector2i(20, 20)) == World.Land.TILLED)
	assert(large.land.at(Vector2i(31, 31)) == World.Land.GRASS)
	quit()
