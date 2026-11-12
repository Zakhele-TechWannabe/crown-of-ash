extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var p := preload("res://src/population.gd").new()
	var job := p.register_job("farmer", ["fields"])
	for i in 1200:
		p.add_person("Wang %d" % i, 30, job, i / 4)
		p.touch(i, "grain_farming.farming", 16, 5000)
		p.prepare_person(i)
	p.async_factions = true
	p.begin_day(7)
	var frames := 0
	while p.pending_day >= 0:
		p.process_batch(32)
		if p.society.faction_pending:
			frames += 1
			await process_frame
	assert(frames > 0 and not p.society.faction_pending)
	assert(p.society.factions.size() >= 300)
	print("PASS society batching: 1200 people, annual faction/position rebuild yielded across ", frames, " frames")
	quit()
