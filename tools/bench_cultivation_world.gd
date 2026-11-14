extends SceneTree
## Current-world baseline, not a claim of Stage 3 progression acceptance.
## Run serially after phase-2 checks on low-memory machines.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var life: Node2D = world.life
	life.set_process(false)
	life.population.async_factions = false
	life.paused = true
	var society: RefCounted = life.population.society
	society.lifespan_death_enabled = true
	var injuries := 0
	var deaths := 0
	var elapsed := 0
	for day in range(1,1096):
		var started := Time.get_ticks_usec()
		life.economy.advance_to(day * 1440.0)
		life.population.tick_day(day)
		life.minutes = day * 1440.0
		life._tend_the_dead()
		elapsed += Time.get_ticks_usec() - started
		for event: Dictionary in society.chronicle:
			if int(event.day) != day: continue
			if str(event.kind) == "setback" and "cultivation injury" in str(event.text): injuries += 1
			if str(event.kind) == "cultivation_death": deaths += 1
		if day % 365 == 0:
			var palace := PackedInt32Array([0,0,0,0,0,0,0,0,0,0])
			var elsewhere := palace.duplicate()
			var eligible := PackedInt32Array([0,0])
			var legacy_palace := PackedInt32Array()
			legacy_palace.resize(14)
			var legacy_elsewhere := legacy_palace.duplicate()
			for person in life.population.size():
				if not society.alive[person]: continue
				if society.temper.body_layer[person] < 9 or not society.revealed[person] or not life.population.spirit_root[person]: continue
				var at_palace: bool = society.fifty.member(person) and not society.fifty.away(person)
				eligible[0 if at_palace else 1] += 1
				if society.realm[person] == 2:
					if at_palace: legacy_palace[society.layer[person]] += 1
					else: legacy_elsewhere[society.layer[person]] += 1
				var report: Dictionary = society.meridian_report(person)
				var layer := int(report.get("layer",0))
				if at_palace: palace[layer] += 1
				else: elsewhere[layer] += 1
			print("BASELINE year=%d qualified_palace_elsewhere=%s production_certified_layer_histogram_palace=%s elsewhere=%s legacy_cultivation_injuries=%d production_cultivation_deaths=%d ms_per_day=%.3f" % [day / 365,eligible,palace,elsewhere,injuries,deaths,elapsed / float(day) / 1000.0])
			print("LEGACY Qi Condensation histogram layers_0_through_13 palace=%s elsewhere=%s" % [legacy_palace,legacy_elsewhere])
		if day % 30 == 0: await process_frame
	print("This is the current legacy-world baseline. Production sessions/certifications are not enabled; no after measurement exists.")
	quit()
