extends SceneTree
## godot --headless --path . --script tools/bench_bake.gd -- --n=3
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var count := 3
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--n="):
			count = maxi(1, int(arg.trim_prefix("--n=")))
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map.set_process(false)
	map.ground_view.set_process(false)
	var ground: Node2D = map.ground
	for region: String in ["ordinary", "forest"]:
		var origin := Vector2i(20, 32) if region == "ordinary" else Vector2i(27, 36)
		var detailed := 0.0
		var far := 0.0
		for i in count:
			var key := origin + Vector2i(i % 3, i / 3)
			var baker: RefCounted = ground._new_baker()
			baker.bake(key)
			detailed += baker.pending.elapsed
			ground.far_cache.clear()
			ground.far_lru.clear()
			var started := Time.get_ticks_usec()
			ground._far_image(key)
			far += (Time.get_ticks_usec() - started) / 1000.0
		print("BENCH %s N=%d detailed=%.2f ms/chunk far=%.2f ms/chunk" % [region, count, detailed / count, far / count])
	quit()
