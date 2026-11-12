extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var job := p.register_job("farmer", ["fields"])
	p.add_person("Pacing adult", 18, job)
	p.comprehension[0] = 1
	p.xp_traits[0] = 1
	p.traits[0] = 0
	p.hunger[0] = 0
	p.mood[0] = .7
	var entry := p.touch(0, "grain_farming.farming", 0)
	var reached: Dictionary = {}
	for day in range(1, 10951):
		p.pending_day = day
		p.day = day - 1
		# A standard full-time, appropriately challenging eight-hour practice day.
		p._gain(0, entry, 2.5 * 8 * .4, 15, 35)
		var level: int = p.skill_level[entry]
		if level not in reached: reached[level] = day
		if day % 3650 == 0: print("PACING year=%d level=%d" % [day / 365, level])
	assert(int(reached.get(11, 99999)) >= 730 and int(reached.get(11, 99999)) <= 1095)
	assert(int(reached.get(16, 99999)) >= 9 * 365 and int(reached.get(16, 99999)) <= 12 * 365)
	assert(int(reached.get(26, 99999)) >= 25 * 365)
	assert(int(reached.get(31, 99999)) >= 30 * 365)
	assert(p.skill_level[entry] == 30, "Master needs insight even after lifetime practice")
	var master_day := -1
	for day in range(10951, 35 * 365 + 1):
		p.pending_day = day
		p.day = day - 1
		if day >= 31 * 365: p.skill_gate[entry] |= 1
		p._gain(0, entry, 2.5 * 8 * .4, 15, 35)
		if p.skill_level[entry] >= 31:
			master_day = day
			break
	assert(master_day >= 30 * 365 and master_day <= 35 * 365)
	print("MASTER_PACING day=%d years=%.2f (insight from year 31; no XP grants)" % [master_day, master_day / 365.0])
	print("PASS pacing milestones ", reached)
	quit()
