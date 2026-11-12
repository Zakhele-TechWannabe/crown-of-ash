extends SceneTree
## Run sequentially: godot --headless --path . -s tools/bench_population.gd
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var before := OS.get_static_memory_usage()
	var store := preload("res://src/population.gd").new()
	store.retain_events = false
	var farmer := store.register_job("farmer", ["fields", "chores"])
	var began := Time.get_ticks_usec()
	var ids: Array = store.catalogue.skills.keys()
	for i in 100000:
		var p := store.add_person("Resident %d" % i, 18 + i % 60, farmer, i / 4)
		store.touch(p, "grain_farming.farming", 13, 800)
		store.touch(p, "grain_farming.farming.paddy_rice", 13, 800)
		store.touch(p, "housekeeping.housekeeping", 8, 100)
		store.touch(p, "housekeeping.housekeeping.housekeeping_basics", 8, 100)
		store.touch(p, "grain_farming.nursery_care", 4, 100)
		store.touch(p, "housekeeping.sweeping", 4, 100)
		for j in 4: store.touch(p, ids[20 + j * 8], 16, 500)
		store.prepare_person(p)
	var build_ms := (Time.get_ticks_usec() - began) / 1000.0
	var memory := (OS.get_static_memory_usage() - before) / 1048576.0
	began = Time.get_ticks_usec()
	store.begin_day(1)
	var max_batch := 0
	while store.pending_day >= 0:
		var batch_began := Time.get_ticks_usec()
		store.process_batch(256)
		max_batch = maxi(max_batch, Time.get_ticks_usec() - batch_began)
	var elapsed := (Time.get_ticks_usec() - began) / 1000.0
	print("BENCH people=%d touched=%d build_ms=%.1f day_ms=%.1f max_batch_ms=%.2f memory_delta_MiB=%.2f total_static_MiB=%.2f" % [store.size(), store.skill_id.size(), build_ms, elapsed, max_batch / 1000.0, memory, OS.get_static_memory_usage() / 1048576.0])
	var list := preload("res://src/people_list.gd").new()
	root.add_child(list)
	var selected := PackedInt32Array()
	selected.resize(100000)
	for i in 100000: selected[i] = i
	list.setup(store, selected)
	await process_frame
	var worst := 0
	for page: int in [0, 100, 10000, 50000, 99980]:
		list.build_page(page)
		worst = maxi(worst, list.page_build_usec)
		assert(list.buttons.size() <= 30)
	print("BENCH UI rows=%d live_rows=%d worst_page_ms=%.3f" % [list.ids.size(), list.buttons.size(), worst / 1000.0])
	var passed := elapsed < 2000 and memory < 150 * 1000000.0 / 1048576.0 and worst < 100000
	print("PASS population benchmark" if passed else "FAIL population benchmark")
	quit(0 if passed else 1)
