extends SceneTree
const Save = preload("res://src/world_save.gd")
const TEMP := "user://tests/world.save"

func _initialize() -> void:
	call_deferred("_run")

func build() -> Node2D:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	map.set_process(false)
	map.life.set_process(false)
	map._go_to("Servants' Village", false)
	return map

func advance(map: Node2D, days: int) -> void:
	for day in days:
		map.life.economy.advance_to(map.life.minutes + 1440.0)
		map.life.population.tick_span(map.life.population.day + 1)
		map.life.minutes += 1440.0
		map.life._tend_the_dead()

func _run() -> void:
	assert(not Save.enabled())
	var a := build()
	advance(a, 60)
	assert(Save.write(a) == ERR_UNAVAILABLE)
	assert(not Save.read(a))
	assert(Save.write(a, TEMP) == OK)
	assert(Save.write(a, TEMP) == OK)
	assert(FileAccess.file_exists(TEMP + ".bak"))
	var b := build()
	assert(Save.read(b, TEMP))
	var envelope := Save.read_envelope(TEMP)
	var older: Dictionary = envelope.duplicate(true)
	older.state.life.population.society.temper.erase("aim_doses")
	older.state.life.population.society.temper.unknown_future_field = true
	store_envelope(older)
	assert(Save.read(b, TEMP))
	assert(b.life.population.society.temper.aim_doses.size() == b.life.population.size())
	store_envelope({"version": 999})
	assert(Save.read(b, TEMP), "An unsupported primary falls back to the previous save")
	assert(Save.capture(a.life) == Save.capture(b.life), "All script state survives the round trip")
	assert(a.life.minutes == b.life.minutes)
	assert(a.life.population.day == b.life.population.day)
	assert(a.life.people.size() == b.life.people.size())
	assert(a.life.population.size() == b.life.population.size())
	assert(a.life.population.rng.state == b.life.population.rng.state)
	assert(a.life.population.names == b.life.population.names)
	assert(a.life.population.birth_day == b.life.population.birth_day)
	assert(a.life.population.society.alive == b.life.population.society.alive)
	assert(a.life.population.society.ties.bonds == b.life.population.society.ties.bonds)
	assert(a.life.population.society.temper.body_layer == b.life.population.society.temper.body_layer)
	assert(a.life.population.society.law.guardians == b.life.population.society.law.guardians)
	assert(a.life.economy.stocks == b.life.economy.stocks)
	assert(a.life.population.society.chronicle.size() == b.life.population.society.chronicle.size())
	advance(a, 30)
	advance(b, 30)
	assert(a.life.population.society.summary() == b.life.population.society.summary())
	assert(a.life.economy.stocks == b.life.economy.stocks)
	assert(a.life.population.rng.state == b.life.population.rng.state)
	for building: Dictionary in a.life.sect.standing:
		if building.kind != "gate": continue
		if building.origin.x in [1263, 1461]: assert(building.side_passage)
	for g: Dictionary in a.life.population.society.law.guardians:
		if g.gate in ["West Gate", "East Gate"]:
			var other: Dictionary = a.life.population.society.law.guardians[int(g.partner)]
			assert(g.post.x == other.post.x and g.post.y != other.post.y)
			assert(g.facing == ("west" if g.gate == "West Gate" else "east"))
	var sheet := Image.create(320, 220, false, Image.FORMAT_RGBA8)
	sheet.fill(preload("res://src/palette.gd").PAPER)
	for i in 2:
		var art: Image = preload("res://src/workplace_art.gd")._build("gate" if i == 0 else "gate_side", 7, 2, 0)
		sheet.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), Vector2i(15 + i * 150, 30))
	for i in 3:
		var guardian := preload("res://src/guardian_art.gd").image("guarding", ["south", "west", "east"][i])
		sheet.blend_rect(guardian, Rect2i(Vector2i.ZERO, guardian.get_size()), Vector2i(50 + i * 80, 170))
	DirAccess.make_dir_recursive_absolute("res://out/ui")
	sheet.save_png("res://out/ui/gate_sheet.png")
	a.free()
	b.free()
	print("PASS save: 60 day round trip and 30 day deterministic continuation; gate sheet rendered")
	quit()


func store_envelope(envelope: Dictionary) -> void:
	var file := FileAccess.open(TEMP, FileAccess.WRITE)
	assert(file != null)
	file.store_buffer(var_to_bytes(envelope))
	file.close()
