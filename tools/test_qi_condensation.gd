extends SceneTree
## Anatomy contracts and prepared-cohort live integration checks.
const Store = preload("res://src/meridian_store.gd")
const Population = preload("res://src/population.gd")
const Save = preload("res://src/world_save.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	health_proofs()
	hourly_windows()
	if "--assay-only" in OS.get_cmdline_user_args():
		release_contracts()
		certification_contracts()
		quit()
		return
	if "--active-only" in OS.get_cmdline_user_args():
		await active_world_replay()
		quit()
		return
	if "--long-only" in OS.get_cmdline_user_args():
		long_reachability()
		quit()
		return
	release_contracts()
	certification_contracts()
	long_reachability()
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
	await active_world_replay()
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
	assert(sealed_day>palace_day and sealed_work<=open_work,"Sealing delays retention; protected reserve need not fund development")

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
	resting.absorbed=90000
	resting.reserve=90000
	resting.reserve_moments=[90000.0,0.0,90000.0,0.0]
	resting.nodes[4].stored_quanta=90000
	s.fifty.journeys[traveller]={"due":99999}
	pop.tick_day(1)
	resting=s.qi_practice.body(s,traveller)
	assert(resting.absorbed==90000 and resting.work>0,"Travel allows funded internal upkeep without ambient intake")
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

func long_reachability() -> void:
	var pop := Population.new()
	var result: Dictionary=preload("res://tools/qi_cohort_fixture.gd").long_run(pop)
	print("LONG FIXTURE ",result)
	assert(result.fixture and result.days==3650)
	if result.achieved[1]<0:
		assert(result.peak_core<30,"Recorded bottleneck: qualifying core never reaches 30 QU/hour")
		for layer in range(1,9): assert(result.achieved[layer]<0,"Later layers cannot skip the recorded return-circuit bottleneck")
	if result.achieved[2]<0:
		assert(result.peak_pressure<1.5,"Recorded bottleneck: safe storage/backpressure prevents 1.5 retained pressure")
	for p: int in result.ids:
		var s: RefCounted=pop.society
		assert(s.qi_practice._compiler.residual(s.qi_practice.body(s,p))==0)
		print("LONG READOUT ",preload("res://src/person_book.gd").cultivation_readout(s.meridian_report(p)))
	var saved: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy := Population.new()
	Save.restore(copy,saved)
	assert(Save.capture(copy)==saved,"Long fixture new evidence and dated certifications round-trip")

func certification_contracts() -> void:
	var pop := Population.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").long_prepare(pop)
	var s: RefCounted=pop.society
	var p: int=ids[0]
	var state: RefCounted=s.qi_practice.body(s,p)
	var r: Dictionary=s.qi_practice.records[p]
	# Four historical terminal records suggest readiness, but the current route
	# is blocked. This explicit evidence fixture exercises a scheduled failure.
	var trial_row: int=s.meridian_store.slot[p]
	s.meridian_store.integers[trial_row*Store.PERSON_INTS+Store.PersonInt.LAYER]=3
	r.terminals={"0":{"day":0,"quanta":20},"1":{"day":0,"quanta":20},"2":{"day":0,"quanta":20},"3":{"day":0,"quanta":20}}
	state.edges[10].openness=0
	var trial_day: int=7-preload("res://src/qi_certification.gd").phase(s,p,r)
	var snapshot: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy := Population.new()
	Save.restore(copy,snapshot)
	var rng: int=pop.rng.state
	preload("res://src/qi_certification.gd").observe(s,p,state,trial_day,0,r)
	preload("res://src/qi_certification.gd").observe(copy.society,p,copy.society.qi_practice.body(copy.society,p),trial_day,0,copy.society.qi_practice.records[p])
	assert(Save.capture(pop)==Save.capture(copy),"Failed trial deterministic, saved and costs strain")
	assert(pop.rng.state==rng and state.strain>=.005 and r.attempts.size()==1)
	preload("res://src/qi_certification.gd").observe(s,p,state,trial_day,0,r)
	assert(r.attempts.size()==1,"A date cannot be attempted twice")
	var row: int=s.meridian_store.slot[p]
	var base := row*Store.PERSON_INTS
	# Negative boundary contracts use explicit evidence fixtures, not claimed
	# physical reachability. High historic counters cannot bypass purity walls.
	for layer in [2,5]:
		s.meridian_store.integers[base+Store.PersonInt.LAYER]=layer
		state.reserve=1000
		state.reserve_moments=[500.0,0.0,1000.0,0.0]
		r.cycles=10
		r.mixed_processed=1000000
		r.evidence_day=-1
		r.attempt_day=-1
		state.strain=0
		preload("res://src/qi_certification.gd").observe(s,p,state,trial_day,0,r)
		assert(s.meridian_store.integers[base+Store.PersonInt.LAYER]==layer,"Purity walls remain binding")
	# Retention residue wall cannot be bypassed by paid work or settling.
	s.meridian_store.integers[base+Store.PersonInt.LAYER]=0
	state.opening_work=500000
	state.settling_days=30
	state.residue=11000
	r.evidence_day=-1
	preload("res://src/qi_certification.gd").observe(s,p,state,10,0,r)
	assert(s.meridian_store.integers[base+Store.PersonInt.LAYER]==0)
	# Non-default persistence boundary fixture. These are storage witnesses,
	# not natural certifications or part of the reachability report.
	r.terminals={"0":{"day":4,"quanta":20}}
	r.output_days=17
	r.coordination_days=19
	r.release_tests=3
	r.integrated_days=27
	var saved: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var restored := Population.new()
	Save.restore(restored,saved)
	assert(Save.capture(restored)==saved,"All new non-default evidence fields survive save/load")

func release_contracts() -> void:
	var pop := Population.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").long_prepare(pop)
	var s: RefCounted=pop.society
	var p: int=ids[0]
	var state: RefCounted=s.qi_practice.body(s,p)
	var row: int=s.meridian_store.slot[p]
	assert(s.qi_practice.release(s,p,state,1).spent==0,"Release cannot create qi in an uncharged uncertified body")
	# Explicitly charged transient assay, separate from reachability fixture.
	s.meridian_store.integers[row*Store.PERSON_INTS+Store.PersonInt.LAYER]=1
	state.reserve=100000
	state.absorbed=100000
	state.reserve_moments=[100000.0,0.0,100000.0,0.0]
	state.nodes[4].stored_quanta=100000
	var saved: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy := Population.new()
	Save.restore(copy,saved)
	s.qi_practice._compiler.accounting.vocabulary={} # fresh-process vocabulary cache
	var result: Dictionary=s.qi_practice.release(s,p,state,2)
	assert(result==copy.society.qi_practice.release(copy.society,p,copy.society.qi_practice.body(copy.society,p),2),"Transient assay reproduces from cold save")
	assert(Save.capture(pop)==Save.capture(copy),"Release histories and physical state round-trip deterministically")
	assert(result.spent==100 and result.delivered<=100 and state.reserve==99900)
	assert(s.qi_practice._compiler.residual(state)==0 and state.dissipated==100,"All released energy is paid and dissipated exactly once")
	state.reserve_moments=[state.reserve*.5,0.0,float(state.reserve),0.0]
	var impure: Dictionary=s.qi_practice.release(s,p,state,3)
	assert(not impure.success and impure.delivered<=25 and state.strain>=.005,"Impurity squared and failed-release strain apply")
	assert(s.qi_practice._compiler.residual(state)==0)
	state.reserve_moments=[float(state.reserve),0.0,0.0,0.0]
	var unstable: Dictionary=s.qi_practice.release(s,p,state,4)
	assert(not unstable.success and float(state.milestones.get("release_strain",0))>0,"Unstable pulse commits real limb strain")
	var opening_outside: float=state.milestones.release_strain
	var opening_recovery: int=state.recovery_days
	s.meridian_store.integers[row*Store.PERSON_INTS+Store.PersonInt.LAYER]=3
	var phase: int=preload("res://src/qi_certification.gd").phase(s,p,s.qi_practice.records[p])
	state.day=7-phase
	var drill: Dictionary=s.qi_practice.drill_program(s,p,state)
	assert(drill!=state.retained_program and drill.operations.size()<=32,"Drill appends within the bounded vocabulary")
	assert(s.qi_practice.records[p].distribution_drill>=0)
	var sample: Dictionary=s.qi_field.sample(pop.locations[p])
	# Restore pure quality for the separate charged transport fixture.
	state.reserve_moments[0]=float(state.reserve)
	state.reserve_moments[2]=float(state.reserve)
	for terminal in 4:
		state.day=(terminal+4)*7-phase
		drill=s.qi_practice.drill_program(s,p,state)
		assert(s.qi_practice.records[p].distribution_drill==terminal)
		s.qi_practice._compiler.step(state,s.qi_practice._compiler.live_network(state,drill,sample),int(sample.quantity))
		assert(s.qi_practice._compiler.residual(state)==0,"Every appended limb drill executes with conserved integer energy")
	for day in 3:
		s.qi_practice._compiler.step(state,s.qi_practice._compiler.live_network(state,state.retained_program,sample),int(sample.quantity))
	assert(float(state.milestones.get("release_strain",0))==0,"Pulse strain heals through normal nightly recovery")
	assert(state.recovery_days-opening_recovery==ceili(maxf(0,opening_outside-.20)/.10),"Memo refresh preserves the actual recovery span")
	# Fully accounted charge for independent four-terminal transport assays.
	state.absorbed+=100000-state.reserve
	state.reserve=100000
	state.nodes[4].stored_quanta=100000
	state.reserve_moments=[100000.0,0.0,100000.0,0.0]
	for terminal in 4:
		var delivery: Dictionary=s.qi_practice.distribution(s,p,state,100+terminal,terminal)
		assert(delivery.success and delivery.delivered>=20,"Every anatomical terminal receives a real finite pulse")
		assert(s.qi_practice._compiler.residual(state)==0)
	print("RELEASE ASSAY ",result," impure=",impure," unstable=",unstable," outside_strain=",opening_outside)

## Explicit injected layer flags exercise future coordinator paths; these are
## never included in the natural-reachability fixture or its achievement table.
func active_world_replay() -> void:
	await process_frame
	var world: Node2D=load("res://world_map.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var life: Node2D=world.life
	life.set_process(false)
	life.paused=true
	var pop: RefCounted=life.population
	pop.async_factions=false
	var s: RefCounted=pop.society
	s.qi_practice=preload("res://tools/qi_cohort_fixture.gd").UnawarePractice.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").prepare_palace(pop)
	var active: Array[int]=[ids[0],ids[3]]
	for i in active.size():
		var p: int=active[i]
		s.prepare_meridians(p,0)
		var state: RefCounted=s.qi_practice.body(s,p)
		s.qi_practice.records[p]={"return_days":0,"cycles":0,"last_policy_day":0,"fixture":"injected layer flag for active replay only"}
		s.meridian_store.integers[s.meridian_store.slot[p]*Store.PERSON_INTS+Store.PersonInt.LAYER]=3 if i==0 else 7
		state.reserve=100000
		state.absorbed=600000
		state.work=500000
		state.opening_work=500000
		state.settling_days=30
		state.nodes[4].stored_quanta=100000
		state.reserve_moments=[100000.0,0.0,100000.0,0.0]
		state.retained_program=s.qi_practice.program("A" if i==0 else "B",1.0)
		assert(s.qi_practice._compiler.residual(state)==0,"Explicit prior opening work and reserve are fully accounted")
	var checkpoint: Dictionary
	var checkpoint_economy: Dictionary
	var drills := 0
	var invalid_days := {active[0]:0,active[1]:0}
	for day in range(1,36):
		life.economy.advance_to(day*1440.0)
		pop.tick_day(day)
		for p in active:
			drills+=int(s.qi_practice.records[p].get("distribution_drill",-1)>=0)
			invalid_days[p]+=int(not s.qi_practice.records[p].get("clean",false))
			assert(s.qi_practice._compiler.residual(s.qi_practice.body(s,p))==0)
		if day==18:
			checkpoint=bytes_to_var(var_to_bytes(Save.capture(pop)))
			checkpoint_economy=bytes_to_var(var_to_bytes(Save.capture(life.economy)))
		await process_frame
	var paid := 0
	for event: Dictionary in s.qi_practice.records[active[1]].release_history: paid+=int(event.spent)
	assert(drills>=8 and paid>=400,"Future drills and paid releases actually execute")
	for p in active:
		var deliveries: Array=[]
		var delivered_targets := {}
		for event: Dictionary in s.qi_practice.records[p].get("distribution_history",[]):
			deliveries.append([event.terminal,event.spent,event.delivered,event.success])
			if event.success: delivered_targets[event.terminal]=true
		var terminals: int=s.qi_practice.records[p].get("terminals",{}).size()
		print("ACTIVE DISTRIBUTION ",p," ",deliveries," certified_terminal_records=",terminals," invalid_days=",invalid_days[p]," damage=",s.damage[p]," injury_until=",s.injury_until[p])
		assert(delivered_targets.size()==4,"Finite recorded pulses exercise all four terminals")
		assert(terminals==4 or invalid_days[p]>0,"Missing certification records require recorded invalid practice days")
	assert(s.meridian_report(active[0]).achieved[3]>=0,"Healthy injected layer-3 actor certifies actual fourth-layer evidence")

	var daily: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var daily_economy: Dictionary=bytes_to_var(var_to_bytes(Save.capture(life.economy)))
	Save.restore(pop,bytes_to_var(var_to_bytes(checkpoint)))
	Save.restore(life.economy,bytes_to_var(var_to_bytes(checkpoint_economy)))
	s.law.rebuild_sight()
	life.economy.coarse_population=true
	while pop.day<35:
		life._skip_week(35)
		await process_frame
	life.economy.coarse_population=false
	difference(Save.capture(pop),daily)
	assert(Save.capture(pop)==daily,"Active distribution/split/release world daily equals jump after cold restore")
	assert(Save.capture(life.economy)==daily_economy)
	print("PASS active coordinator world replay: injected flags, %d drill-days, %d paid release records; not reachability evidence" % [drills,s.qi_practice.records[active[1]].release_history.size()])
	world.queue_free()

func hourly_windows() -> void:
	var compiler = preload("res://src/session_compiler.gd")
	var bins: Array=[]
	for hour in 4:
		var row: Array=[]
		row.resize(9)
		row.fill(0)
		bins.append(row)
	# One complete qualifying hour counts even when the daily average is low.
	for e in [0,1,2,5,6,7,8]: bins[0][e]=90000
	assert(compiler.hourly_core_rate(bins,14400)==90)
	assert(compiler.hourly_core_rate(bins,1800)==0,"A partial hour cannot certify output")
	# Equal day totals on different hours are not a sustained circuit.
	for e in [0,1,2,6,7,8]: bins[0][e]=360000
	bins[0][5]=0
	bins[1][5]=360000
	assert(compiler.hourly_core_rate(bins,14400)==0)
	for hour in bins: hour.fill(0)
	for e in [0,3,4,5,6,7,8]: bins[0][e]=90000
	assert(compiler.hourly_core_rate(bins,14400)==90,"The alternative complete circuit also qualifies")
	for e in [1,2,3,4]: bins[0][e]=45000
	assert(compiler.hourly_core_rate(bins,14400)==45,"Two partial circuits cannot be summed")

func health_proofs() -> void:
	var pop := Population.new()
	var ids: Array[int]=preload("res://tools/qi_cohort_fixture.gd").long_prepare(pop)
	var s: RefCounted=pop.society
	var p: int=ids[0]
	var state: RefCounted=s.qi_practice.body(s,p)
	state.absorbed=600000
	state.reserve=100000
	state.nodes[4].stored_quanta=100000
	state.reserve_moments=[100000.0,0.0,100000.0,0.0]
	state.work=500000
	state.opening_work=500000
	state.settling_days=30
	var sample: Dictionary=s.qi_field.sample(pop.locations[p])
	s.qi_practice._compiler.step(state,s.qi_practice._compiler.live_network(state,state.retained_program,sample),int(sample.quantity))
	assert(state.milestones.daily_execution.stable and state.milestones.daily_execution.has("health_revision"))
	state.nodes[1].integrity=.5
	s.qi_practice._compiler.invalidate(state)
	s.qi_practice.certify(s,p,state,state.day,0)
	assert(s.meridian_report(p).layer==0,"An anatomical revision invalidates the execution health proof")
