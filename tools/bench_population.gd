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
	for a in 100000:
		for offset in range(1, 41): store.society.ties.tie(a, (a + offset) % 100000)
	var memory := (OS.get_static_memory_usage() - before) / 1048576.0
	began = Time.get_ticks_usec()
	store.begin_day(1)
	var max_batch := 0
	while store.pending_day >= 0:
		var batch_began := Time.get_ticks_usec()
		store.process_batch(256)
		max_batch = maxi(max_batch, Time.get_ticks_usec() - batch_began)
	var elapsed := (Time.get_ticks_usec() - began) / 1000.0
	var day_samples: Array[float] = [elapsed]
	for next_day in [2, 3]:
		began = Time.get_ticks_usec()
		store.tick_day(next_day)
		day_samples.append((Time.get_ticks_usec() - began) / 1000.0)
	day_samples.sort()
	elapsed = day_samples[1]
	var rust_start := Time.get_ticks_usec()
	store.pending_day = 365
	for a in 100000: store._rust_person(a, 30)
	store.pending_day = -1
	var monthly_rust_ms := (Time.get_ticks_usec() - rust_start) / 1000.0
	print("BENCH RUST monthly_ms=%.1f amortized_ms_per_day=%.1f" % [monthly_rust_ms, monthly_rust_ms / 30.0])
	var week_samples: Array[float] = []
	var social_max_batch := 0
	store.society.last_year = 0 # Annual rebuilding has its own batching test.
	for next_day in [7, 14, 21]:
		var social_start := Time.get_ticks_usec()
		store.day = next_day
		store.society.begin_tick(next_day)
		while store.society.social_pending:
			var batch_start := Time.get_ticks_usec()
			store.society.process_tick(32)
			social_max_batch = maxi(social_max_batch, Time.get_ticks_usec() - batch_start)
		week_samples.append((Time.get_ticks_usec() - social_start) / 1000.0)
	week_samples.sort()
	var weekly_ms := week_samples[1]
	memory = (OS.get_static_memory_usage() - before) / 1048576.0
	print("BENCH people=%d touched=%d build_ms=%.1f day_ms=%.1f max_batch_ms=%.2f memory_delta_MiB=%.2f total_static_MiB=%.2f" % [store.size(), store.skill_id.size(), build_ms, elapsed, max_batch / 1000.0, memory, OS.get_static_memory_usage() / 1048576.0])
	print("BENCH SOCIAL ties=%d weekly_ms=%.1f amortized_ms_per_day=%.1f total_day_ms=%.1f memory_MiB=%.2f max_32_batch_ms=%.2f" % [store.society.ties.target.size(), weekly_ms, weekly_ms / 7.0, elapsed + weekly_ms / 7.0 + monthly_rust_ms / 30.0, memory, social_max_batch / 1000.0])
	print("BENCH SAMPLES day_ms=%s weekly_ms=%s (median of three; sorted)" % [day_samples, week_samples])
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
	var passed := elapsed + weekly_ms / 7.0 + monthly_rust_ms / 30.0 < 2000 and memory < 200 * 1000000.0 / 1048576.0 and worst < 100000
	print("PASS population benchmark" if passed else "FAIL population benchmark")
	quit(0 if passed else 1)
