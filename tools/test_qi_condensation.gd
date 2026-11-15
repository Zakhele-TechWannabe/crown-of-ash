extends SceneTree
## Anatomy contracts and prepared-cohort live integration checks.
const Store = preload("res://src/meridian_store.gd")
const Population = preload("res://src/population.gd")
const Save = preload("res://src/world_save.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config := Store.definition()
	var identifiers := {}
	for node: Dictionary in config.nodes:
		assert(not identifiers.has(node.id))
		identifiers[node.id] = node
	assert(identifiers.size() == 16)
	var edge_ids := {}
	var reached := {"breath":true}
	for edge: Dictionary in config.edges:
		assert(not edge_ids.has(edge.id) and identifiers.has(edge.from_id) and identifiers.has(edge.to_id))
		edge_ids[edge.id] = true
		assert(edge.relevant_tempering_weights.size() == 9 and edge.affinity.size() == 5)
		assert(float(edge.seed_width) >= .7 and float(edge.seed_width) <= 1.4)
	for iteration in 16:
		for edge: Dictionary in config.edges:
			if reached.has(edge.from_id) and not edge.dormant: reached[edge.to_id] = true
	for id: String in ["lower","left_palm","right_palm","left_sole","right_sole","head"]: assert(reached.has(id), "Every ordinary terminal has a usable path")
	assert(not reached.has("middle") and not reached.has("upper"), "Future centres remain dormant")
	var low := Store.new()
	var perfect := Store.new()
	low.add_person()
	perfect.add_person()
	low.create(0,PackedByteArray([0,0,0,0,0,0,0,0,0]),1,90,"fixture",100)
	perfect.create(0,PackedByteArray([3,3,3,3,3,3,3,3,3]),1,90,"fixture",100)
	# Hold keyed anatomy constant: all-Perfect has the rulebook's 1.86x throughput.
	for edge in 24:
		var offset := edge * Store.EDGE_FLOATS
		assert(absf(perfect.edges[offset + Store.EdgeFloat.CAPACITY] / low.edges[offset + Store.EdgeFloat.CAPACITY] - 1.3 / .7) < 1e-10)
		if not config.edges[edge].dormant: assert(absf(perfect.capacity(0,edge) / low.capacity(0,edge) - 1.3 / .7) < 1e-10)
	var regional := Store.new()
	regional.add_person()
	regional.create(0,PackedByteArray([0,0,3,3,0,0,0,0,0]),1,90,"fixture",100)
	assert(regional.edges[10 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY] > low.edges[10 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY], "Sinew and bone support limbs")
	assert(regional.edges[1 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY] == low.edges[1 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY], "Limb grades do not inflate core channels")
	assert(Store.root_affinity(1 << 5) == PackedFloat64Array([0,.6,.4,0,0]))
	assert(Store.root_affinity(1 << 6) == PackedFloat64Array([0,.5,0,.5,0]))
	assert(Store.root_affinity(1 << 9)[2] == 1)
	var restored := Store.new()
	Save.restore(restored,bytes_to_var(var_to_bytes(Save.capture(perfect))))
	assert(Save.capture(restored) == Save.capture(perfect))
	var bad := restored.save_state()
	bad.mass.resize(0)
	assert(not restored.load_state(bad))
	assert(Save.capture(restored) == Save.capture(perfect), "Invalid saves cannot partially replace columns")
	var report := restored.report(0)
	report.nodes[0].pressure = 900
	assert(restored.report(0).nodes[0].pressure == 0, "Inspection is read-only")
	assert(report.layer == 0 and report.reserve == 0 and report.residue == 0)
	assert(report.achieved == PackedInt32Array([-1,-1,-1,-1,-1,-1,-1,-1,-1]))
	for edge: Dictionary in report.edges: assert(edge.flow_quanta == 0, "No invented execution evidence")
	var bulk := Store.new()
	for person in 250:
		bulk.add_person()
		bulk.create(person,PackedByteArray([2,2,2,2,2,2,2,2,2]),1,80,"bulk:%d" % person,0)
	assert(bulk.memory_bytes() < 8 * 1024 * 1024)
	var first := bulk.save_state()
	bulk.create(0,PackedByteArray([0,0,0,0,0,0,0,0,0]),1,50,"different",999)
	assert(first == bulk.save_state(), "Foundation seeds once, without resetting injury or development")
	var population := Population.new()
	var job: int = population.register_job("anatomy fixture", [])
	var person: int = population.add_person("Foundation",20,job)
	var society: RefCounted = population.society
	population.spirit_root[person] = 1
	assert(society.prepare_meridians(person,0) == -1)
	society.temper.body_layer[person] = 9
	assert(society.prepare_meridians(person,0) == -1, "A completed body still needs an awakened root")
	society.revealed[person] = 1
	var rng_state: int = population.rng.state
	assert(society.prepare_meridians(person,100) == 0)
	assert(population.rng.state == rng_state, "Anatomy does not consume the world RNG")
	assert(society.meridian_report(person).layer == 0)
	var copy := Population.new()
	Save.restore(copy,bytes_to_var(var_to_bytes(Save.capture(population))))
	assert(copy.society.meridian_store.save_state() == society.meridian_store.save_state(), "Society-side save recursion includes the packed store")
	var legacy := Save.capture(population)
	legacy.society.erase("meridian_store")
	legacy.society.erase("qi_practice")
	legacy.society.qi[person] = 99999
	var old_copy := Population.new()
	var defaults := Save.capture(old_copy)
	Save.restore(old_copy,bytes_to_var(var_to_bytes(legacy)))
	Save.repair_columns(old_copy,defaults,old_copy.size())
	assert(old_copy.society.meridian_store.slot == PackedInt32Array([-1]))
	assert(old_copy.society.prepare_meridians(person,500) == 0)
	assert(old_copy.society.meridian_report(person).reserve == 0 and old_copy.society.meridian_report(person).layer == 0, "Legacy abstract qi creates no reserve or certification")
	Save.repair_meridians(old_copy.society, legacy.society)
	assert(old_copy.society.meridian_store.people.is_empty() and old_copy.society.meridian_store.slot == PackedInt32Array([-1]), "Loading legacy data into an already used world clears its previous anatomy")
	danger_sense()
	deviation_handling()
	live_cohort()
	await world_cohort()
	print("PASS Qi Condensation anatomy, live cohort, deviation, save and world daily/jump; %d packed bytes for 250 bodies." % bulk.memory_bytes())
	quit()

func live_cohort() -> void:
	var pop := Population.new()
	var ids: Array[int] = preload("res://tools/qi_cohort_fixture.gd").prepare(pop)
	pop.async_factions=false
	var initial: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var s: RefCounted=pop.society
	var absorbed := 0
	for day in range(1,731):
		pop.tick_day(day)
		var total := 0
		for p in ids: total+=s.qi_practice.body(s,p).absorbed
		assert(total-absorbed==int(s.qi_field.ledger.withdrawals),"Net field withdrawals equal actual body intake")
		absorbed=total
	for i in ids.size():
		var state: RefCounted=s.qi_practice.body(s,ids[i])
		assert(s.qi_practice._compiler.residual(state)==0)
		print("COHORT region=%s careful=%s achieved=%s residue=%d strain=%.6f" % [["Palace","Sect","Village"][i%3],i%2==0,s.meridian_report(ids[i]).achieved,state.residue,state.max_strain])
	var greedy: RefCounted=s.qi_practice.body(s,ids[1])
	var careful: RefCounted=s.qi_practice.body(s,ids[4])
	# A late frightened response can reverse final residue ordering. Historical
	# danger must still distinguish the reckless policy from early caution.
	assert(greedy.max_strain>careful.max_strain and careful.max_strain<.20,"Early caution limits peak danger")
	assert(s.qi_practice.records[ids[1]].responses.get("pause",0)>0,"Even a greedy person can eventually heed danger")
	assert(float(greedy.residue)/greedy.capacity<.045 and float(careful.residue)/careful.capacity<.045,"Pausing and safer sessions lower both ending loads")
	var palace_day: int=s.meridian_report(ids[0]).achieved[0]
	var village_day: int=s.meridian_report(ids[2]).achieved[0]
	assert(palace_day>=0 and (village_day<0 or palace_day<village_day),"Palace physical source certifies retention sooner")
	var saved: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy := Population.new()
	Save.restore(copy,saved)
	assert(Save.capture(copy)==saved,"Physical state survives cache-free round trip")
	for p in ids: copy.society.qi_practice.body(copy.society,p)
	assert(Save.capture(copy)==saved,"Rebuilding body objects grants no qi or evidence")
	for day in range(731,738): pop.tick_day(day)
	copy.tick_span(737)
	difference(Save.capture(copy),Save.capture(pop))
	assert(Save.capture(copy)==Save.capture(pop),"Live daily/jump and cold-cache continuation agree")

	var sealed := Population.new()
	Save.restore(sealed,initial)
	sealed.society.qi_field.set_decree("Heavenly Origin",0)
	for day in range(1,731): sealed.tick_day(day)
	var sealed_day: int=sealed.society.meridian_report(ids[0]).achieved[0]
	print("COHORT sealing palace layer1 open=%d sealed=%d" % [palace_day,sealed_day])
	var open_work: int=s.qi_practice.body(s,ids[0]).work
	var sealed_work: int=sealed.society.qi_practice.body(sealed.society,ids[0]).work
	print("COHORT sealing Palace work open=%d sealed=%d" % [open_work,sealed_work])
	assert(sealed_work<open_work,"Sealing slows Palace permanent development; existing ambient qi remains available")

func world_cohort() -> void:
	var world: Node2D=load("res://world_map.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var life: Node2D=world.life
	life.set_process(false)
	life.paused=true
	var pop: RefCounted=life.population
	pop.async_factions=false
	var cohort: Array[int]=preload("res://tools/qi_cohort_fixture.gd").prepare_palace(pop)
	var initial_pop: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var initial_economy: Dictionary=bytes_to_var(var_to_bytes(Save.capture(life.economy)))
	for day in range(1,731):
		life.economy.advance_to(day*1440.0)
		pop.tick_day(day)
		if day%30==0: await process_frame
	var outcomes: Dictionary=preload("res://tools/qi_cohort_fixture.gd").danger_summary(pop.society,cohort)
	print("DANGER ACCEPTANCE ",outcomes)
	# At least 7/8 careful sect people survive; reckless deaths remain permitted.
	assert(outcomes.sect_careful_deaths<=1,"Careful sect survival >=87.5%")
	assert(outcomes.sect_careful_deaths+outcomes.sect_greedy_deaths<8,"Sect deaths improve on baseline eight")
	assert(outcomes.palace_living==17 and outcomes.village_living==16,"No Palace/village survival regression")
	assert(outcomes.palace_certified==17 and outcomes.palace_last<=730,"All Palace certifications within baseline last day 721 + nine days")
	assert(outcomes.responses.get("pause",0)>0 and outcomes.responses.get("ignore",0)>0,"Personality produces caution and ignored warnings")
	var daily_pop: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var daily_economy: Dictionary=bytes_to_var(var_to_bytes(Save.capture(life.economy)))
	Save.restore(pop,bytes_to_var(var_to_bytes(initial_pop)))
	Save.restore(life.economy,bytes_to_var(var_to_bytes(initial_economy)))
	pop.society.law.rebuild_sight()
	life.economy.coarse_population=true
	while pop.day<730:
		life._skip_week(730)
		if pop.day%70==0: await process_frame
	life.economy.coarse_population=false
	difference(Save.capture(pop),daily_pop)
	assert(Save.capture(pop)==daily_pop,"Full running world daily equals jump")
	assert(Save.capture(life.economy)==daily_economy,"Daily and jump economy agree")
	print("PASS full running world prepared-cohort daily/jump, two years")
	Save.restore(pop,bytes_to_var(var_to_bytes(initial_pop)))
	Save.restore(life.economy,bytes_to_var(var_to_bytes(initial_economy)))
	pop.society.law.rebuild_sight()
	pop.society.qi_field.set_decree("Heavenly Origin",0)
	for day in range(1,731):
		life.economy.advance_to(day*1440.0)
		pop.tick_day(day)
		if day%30==0: await process_frame
	var sealed: Dictionary=preload("res://tools/qi_cohort_fixture.gd").danger_summary(pop.society,cohort)
	print("DANGER SEALED ACCEPTANCE ",sealed)
	assert(sealed.sect_careful_deaths<=1 and sealed.sect_careful_deaths+sealed.sect_greedy_deaths<8)
	assert(sealed.palace_living==17 and sealed.village_living==16)
	assert(sealed.palace_certified==17 and sealed.palace_last<=730)
	world.queue_free()

func difference(a: Variant, b: Variant, path: String = "state") -> bool:
	if a==b: return false
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if not b.has(key):
				print("MISMATCH missing %s.%s" % [path,key])
				return true
			if difference(a[key],b[key],path+"."+str(key)): return true
	elif a is Array and b is Array and a.size()==b.size():
		for i in a.size():
			if difference(a[i],b[i],path+"["+str(i)+"]"): return true
	else: print("MISMATCH %s: %s / %s" % [path,str(a).left(160),str(b).left(160)])
	return true

func deviation_handling() -> void:
	var pop := Population.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").prepare(pop,2)
	var s: RefCounted=pop.society
	var p: int=ids[0]
	s.prepare_meridians(p,0)
	var state: RefCounted=s.qi_practice.body(s,p)
	# Explicit fixture charge, accounted as prior intake; no production endowment.
	state.absorbed=500000
	state.residue=500000
	state.nodes[4].residue_quanta=500000
	var traveller: int=ids[1]
	s.prepare_meridians(traveller,0)
	var resting: RefCounted=s.qi_practice.body(s,traveller)
	resting.absorbed=50000
	resting.reserve=50000
	resting.reserve_moments=[50000.0,0.0,50000.0,0.0]
	resting.nodes[4].stored_quanta=50000
	s.fifty.journeys[traveller]={"due":99999}
	pop.tick_day(1)
	resting=s.qi_practice.body(s,traveller)
	assert(resting.absorbed==50000 and resting.work>0,"Travel allows funded internal upkeep without ambient intake")
	assert(s.qi_practice._compiler.residual(resting)==0)
	state=s.qi_practice.body(s,p)
	assert(state.deaths>0 and not s.alive[p],"Compiler deviation uses Society death handling")
	var injury := false
	var death := false
	for event: Dictionary in s.chronicle:
		injury=injury or (event.person==p and "qi deviation injury" in event.text)
		death=death or (event.person==p and "died by qi deviation" in event.text)
	assert(injury and death and s.injury_until[p]>1,"Deviation injury and death are dated and chronicled")

func danger_sense() -> void:
	var pop := Population.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").prepare(pop,2)
	var s: RefCounted=pop.society
	for p in ids:
		s.prepare_meridians(p,0)
		var state: RefCounted=s.qi_practice.body(s,p)
		s.qi_practice.records[p]={"return_days":0,"cycles":0,"last_reserve":0}
		state.day=50
		state.residue=6200
		state.nodes[4].strain=.02
		state.retained_program=s.qi_practice.program("B",.25)
	var snapshot: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy := Population.new()
	Save.restore(copy,snapshot)
	var rng: int=pop.rng.state
	for p in ids:
		s.qi_practice.danger_response(s,p,s.qi_practice.body(s,p),pop.locations[p])
		copy.society.qi_practice.danger_response(copy.society,p,copy.society.qi_practice.body(copy.society,p),copy.locations[p])
		assert(s.qi_practice.records[p]==copy.society.qi_practice.records[p],"Danger decisions reproduce from cold save")
	assert(pop.rng.state==rng,"Danger sense does not consume shared randomness")
	assert(s.qi_practice.records[ids[0]].danger_decisions[0].action=="pause")
	assert(s.qi_practice.records[ids[1]].danger_decisions[0].action=="ignore")
