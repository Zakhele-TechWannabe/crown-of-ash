extends SceneTree
## Measures main-thread streaming work while both LOD jobs run off-thread.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map.set_process(false)
	map.ground_view.set_process(false)
	map._go_to("Eastern Hunting Grounds", false)
	var ground: Node2D = map.ground
	var camera: Camera2D = map.ground_view.cam
	var total := 0.0
	var maximum := 0.0
	var frame_times: Array[float] = []
	Engine.max_fps = 60
	for frame in 360:
		camera.position.x += 12
		var started := Time.get_ticks_usec()
		ground.update_chunks(camera, 2)
		var elapsed := (Time.get_ticks_usec() - started) / 1000.0
		total += elapsed
		maximum = maxf(maximum, elapsed)
		await process_frame
		if frame >= 60:
			frame_times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	frame_times.sort()
	print("PAN full CPU frame: p95 %.2f ms, max %.2f ms" % [frame_times[int(frame_times.size() * 0.95)], frame_times[-1]])
	print("PAN streaming main thread: mean %.2f ms, max %.2f ms" % [total / 360, maximum])
	assert(maximum < 50, "Streaming must not synchronously rasterize chunks")
	print("PASS pan: both LODs use workers; bounded main-thread streaming")
	quit()
