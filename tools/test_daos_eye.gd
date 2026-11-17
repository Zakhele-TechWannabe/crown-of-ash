extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	var world: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._go_to("Servants' Village", false)
	world.life.paused = true
	world.life.set_process(false)
	var eye: PanelContainer = world.ground_view.eye
	var store: RefCounted = world.life.population
	var s: RefCounted = store.society
	# Fixture includes enough people to exercise virtual scrolling, a sect member
	# physically in the village, a Palace member there, and someone out in the wild.
	while store.size() < 260:
		var p: int = store.add_person("Eye fixture %d" % store.size(), 24, 0)
		store.locations[p] = s.qi_field.landmarks.Village
	# Dedicated identities stay outside the Fifty even if the seeded population
	# already exceeds the performance fixture's minimum size.
	for i in 4:
		var p: int = store.add_person("Eye witness %d" % i, 24, 0)
		store.locations[p] = s.qi_field.landmarks.Village
	var sect_person: int = store.size() - 1
	var wild_person: int = store.size() - 2
	store.locations[wild_person] = Vector2.ZERO
	var faction: int = s.faction("sect", "eye:sect", "Eye fixture sect", PackedInt32Array([sect_person]), sect_person)
	s.memberships[sect_person] = PackedInt32Array([faction])
	s.realm[sect_person] = 4
	s.temper.body_layer[sect_person] = 9
	var palace_person: int = s.fifty.people.keys()[0]
	store.locations[palace_person] = s.qi_field.landmarks.Village
	s.temper.body_layer[palace_person] = 9
	var village_champion: int = store.size() - 4
	s.temper.body_layer[village_champion] = 8
	s.injury_until[village_champion] = store.day + 10
	s.qi_practice.records[village_champion] = {"wants_purer_qi": true}
	var dead_person: int = store.size() - 3
	s.die(dead_person, "killed", store.names[dead_person] + " was killed in an Eye test")
	s.archive.close() # Exercise the compressed archive as well as the recent chronicle.
	var dead_day: int = store.day
	var rng_state: int = store.rng.state
	var qi: Dictionary = s.qi_field.save_state()
	var authoritative: Dictionary = frozen(preload("res://src/world_save.gd").capture(store))
	for resolution: Vector2i in [Vector2i(1920,1080), Vector2i(1366,768)]:
		root.content_scale_size = resolution
		root.size = resolution
		await process_frame
		eye._layout()
		for tab: String in eye.TABS:
			eye.open_tab(tab)
			await create_timer(0.18).timeout
			await process_frame
			assert(eye.is_visible_in_tree())
			assert(eye.get_global_rect().end.x <= resolution.x)
			assert(eye.get_global_rect().end.y <= resolution.y, "Eye must fit %s %s: rect %s, minimum %s" % [resolution, tab, eye.get_global_rect(), eye.get_combined_minimum_size()])
			check_theme(eye)
			if tab == "people":
				for ranking: String in eye.RANKS:
					eye.rank = ranking
					eye.refresh()
					await process_frame
					eye.people_ids()
					eye.rank = "Strength"
				eye.refresh()
			if tab == "world":
				assert(("%.1f QU in all" % (s.qi_field.world_totals().total / 1000.0)) in labels(eye.content))
			if tab == "laws":
				for group: String in ["Heaven’s laws", "Laws of the valley", "Rules of your Palace"]:
					eye.law_book = group
					eye.refresh()
					await process_frame
					check_theme(eye)
			if tab == "dead":
				var tree: Tree = eye.content.find_children("*", "Tree", true, false)[0]
				assert(tree.get_root().get_child_count() == 1)
	assert(preload("res://src/world_save.gd").capture(store) == authoritative, "Opening every screen must preserve authoritative state")
	assert(store.rng.state == rng_state, "Eye must not advance RNG")
	assert(s.qi_field.save_state() == qi, "Eye must not mutate world qi")
	eye.rank = "Strength"
	var total := 0
	for p in store.size(): total += int(s.alive[p])
	eye.where = "all"
	assert(eye.people_ids().size() == total)
	var truth := {"village": 0, "sect": 0, "palace": 0, "wild": 0}
	for p in store.size():
		if not s.alive[p]: continue
		var place := "village" if eye.village_bounds.has_point(store.locations[p]) else "wild"
		for id: int in s.memberships.get(p, PackedInt32Array()):
			if s.factions[id].type == "sect": place = "sect"
		if s.fifty.member(p): place = "palace"
		truth[place] += 1
	var partition := 0
	for place: String in ["village", "sect", "palace", "wild"]:
		eye.where = place
		var ids: PackedInt32Array = eye.people_ids()
		partition += ids.size()
		assert(ids.size() == truth[place], "Where count must match living membership and actual position: " + place)
		for p: int in ids:
			assert(s.alive[p])
			if place == "village":
				assert(not s.fifty.member(p), "Village strongest excludes Palace")
				for id: int in s.memberships.get(p, PackedInt32Array()): assert(s.factions[id].type != "sect", "Village excludes sect")
		for i in range(1, ids.size()): assert(eye.measure(ids[i-1])[0] >= eye.measure(ids[i])[0])
	assert(partition == total)
	world.ground_view.ledger.open_tab("people")
	assert(eye.closing and world.ground_view.ledger.visible)
	eye.open_tab("people")
	assert(world.ground_view.ledger.closing and eye.visible)
	assert(eye.death_records().size() == store.size() - total)
	var dead: Array = eye.death_records().filter(func(r: Dictionary) -> bool: return r.person == dead_person)
	assert(dead.size() == 1 and dead[0].day == dead_day)
	assert(dead[0].cause.ends_with("was killed in an Eye test"))
	eye.query = "__no_such_person__"
	eye.open_tab("dead")
	assert(eye.content.find_children("*", "Tree", true, false)[0].get_root().get_child_count() == 0)
	eye.query = store.names[dead_person]
	eye.refresh()
	assert(eye.content.find_children("*", "Tree", true, false)[0].get_root().get_child_count() == 1)
	eye.query = ""

	eye.where = "village"
	assert(not eye.people_ids().has(sect_person) and not eye.people_ids().has(palace_person))
	assert(eye.people_ids()[0] == village_champion, "The village champion outranks villagers while stronger sect and Palace members are excluded")
	eye.where = "sect"
	assert(eye.people_ids().has(sect_person))
	eye.where = "wild"
	assert(eye.people_ids().has(wild_person))
	assert(s.qi_field.world_totals().total == s.qi_field._field_total + s.qi_field._reserve_total)
	eye.where = "all"
	for chip: String in ["women", "men", "children", "mortals", "cultivators", "injured", "wants"]:
		eye.only = {chip: true}
		var expected := 0
		for p in store.size():
			if not s.alive[p]: continue
			match chip:
				"women": expected += int(store.sex[p] == 1)
				"men": expected += int(store.sex[p] == 0)
				"children": expected += int(store.age(p) < 18)
				"mortals": expected += int(s.realm[p] == 0 and s.meridian_store.slot[p] < 0 and s.temper.body_layer[p] == 0)
				"cultivators": expected += int(s.realm[p] > 0 or s.meridian_store.slot[p] >= 0 or s.temper.body_layer[p] > 0)
				"injured": expected += int(s.damage[p] < 0.85 or s.injury_until[p] > store.day)
				"wants": expected += int(s.qi_practice.records.get(p, {}).get("wants_purer_qi", false))
		assert(eye.people_ids().size() == expected)
	eye.only.clear()
	eye.where = "all"
	eye.open_tab("people")
	await process_frame
	var virtual: Node = eye.content.find_children("*", "VBoxContainer", true, false).filter(func(n: Node) -> bool: return n.get_script() == preload("res://src/people_list.gd"))[0]
	assert(virtual.ids.size() > 250 and virtual.buttons.size() < 30)
	virtual.build_page(virtual.ids.size() - 5)
	assert(virtual.buttons[0].get_meta("person") == virtual.ids[virtual.ids.size() - 5])
	# Compare the authoritative next day, replaying from the same saved state.
	var save := preload("res://src/world_save.gd")
	var before: Dictionary = frozen(save.capture(store))
	store.tick_day(store.day + 1)
	var with_eye: Dictionary = frozen(save.capture(store))
	eye.hide()
	eye.dim.hide()
	save.restore(store, frozen(before))
	store.tick_day(store.day + 1)
	var without_eye: Dictionary = frozen(save.capture(store))
	if with_eye != without_eye:
		FileAccess.open("res://out/phase2/eye-open.json", FileAccess.WRITE).store_string(JSON.stringify(with_eye))
		FileAccess.open("res://out/phase2/eye-closed.json", FileAccess.WRITE).store_string(JSON.stringify(without_eye))
	assert(with_eye == without_eye, "A day with Eye open must equal a day without it")
	var source := FileAccess.get_file_as_string("res://src/daos_eye.gd")
	assert(not "add_theme_font_size_override" in source and not "Color(\"" in source)
	print("Dao's Eye PASS")
	world.queue_free()
	await process_frame
	quit()

func check_theme(node: Node) -> void:
	if node is Control and not node.theme_type_variation.is_empty():
		assert(node.theme_type_variation in preload("res://src/ui_theme.gd").build().get_type_list())
	for child: Node in node.get_children(): check_theme(child)

func labels(node: Node) -> String:
	var result: String = node.text + "\n" if node is Label else ""
	for child: Node in node.get_children(): result += labels(child)
	return result

# Packed arrays are reference values; use the real save serialization boundary
# so advancing the world cannot alter the replay's starting snapshot.
func frozen(state: Dictionary) -> Dictionary:
	return bytes_to_var(var_to_bytes(state))
