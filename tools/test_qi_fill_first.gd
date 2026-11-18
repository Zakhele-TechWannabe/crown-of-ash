extends SceneTree
const Reference = preload("res://src/circulation.gd")
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Population = preload("res://src/population.gd")
const Fixture = preload("res://tools/qi_cohort_fixture.gd")
const Save = preload("res://src/world_save.gd")

func _initialize() -> void:
	var reference := Reference.new()
	var compiler := Compiler.new()
	var sample := {"density":0.0,"quantity":0,"elements":[1,0,0,0,0],"purity":1.0,"polarity":0.0,"stability":1.0,"corruption":0.0}
	for reserve in [0,59000,69999,70000,70001,75000,90000,100000]:
		var state := Anatomy.Cultivator.from_dictionary(Anatomy.create())
		state.opening_work=500000
		state.work=500000
		state.reserve=reserve
		state.absorbed=state.work+reserve
		state.reserve_moments=[float(reserve),0.0,float(reserve),0.0]
		state.nodes[4].stored_quanta=reserve
		var copy := reference.clone_model(state)
		var program := reference.manual("A",0)
		reference.simulate_day_model(state,program,sample,0)
		compiler.solve_day(copy,compiler.compile(copy,program,sample),0)
		for body: Anatomy.Cultivator in [state,copy]:
			assert(body.reserve==reserve-maxi(0,reserve-70000)/2,"Half of surplus only")
			assert(compiler.residual(body)==0)
	# An older-law saved memo cannot match the new accounting signature.
	var state := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	var memo := Compiler.DayMemo.new()
	var net := compiler.compile(state,reference.manual("A"),sample)
	var signature := compiler.input_signature(state,net,0,memo)
	assert(signature[0]==.70)
	compiler.step(state,net,0)
	var old_memo := compiler.save_memo(state)
	old_memo.signature.pop_front() # The pre-floor signature had no law marker.
	var continued := reference.clone_model(state)
	compiler.restore_memo(continued,old_memo)
	var misses := compiler.day_misses
	compiler.step(continued,compiler.compile(continued,reference.manual("A"),sample),0)
	assert(compiler.day_misses==misses+1 and compiler.residual(continued)==0,"Old-law saved delta must solve afresh")
	var fractional := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	fractional.capacity=100001
	fractional.reserve=70003
	fractional.reserve_moments=[70003.0,0.0,70003.0,0.0]
	assert(reference.integration_draw(fractional,.70)==1,"Fractional protected capacity rounds up")
	var pop := Population.new()
	var mortal: int=pop.add_person("Floor mortal",20,pop.register_job("Floor test",[]))
	pop.spirit_root[mortal]=0
	var mortal_slots: PackedInt32Array=pop.society.meridian_store.slot.duplicate()
	pop.society.qi_practice.advance(pop.society,1)
	assert(pop.society.meridian_store.slot==mortal_slots,"Non-practitioners gain no integration state")
	var ids := Fixture.long_prepare(pop)
	for p in ids:
		var body: Anatomy.Cultivator=pop.society.qi_practice.body(pop.society,p)
		for edge in [5,6,7,8]:
			var duty := 0
			for op: Dictionary in body.retained_program.operations:
				if op.operation=="Guide" and edge in op.targets: duty+=int(op.duration)
			assert(duty>=30,"Authored manual includes complete return duty")
		# Accounted old-save reserve plus developed/damaged anatomy must survive.
		body.opening_work=500000
		body.work=500000
		body.reserve=75000
		body.absorbed=575000
		body.reserve_moments=[60000.0,0.0,75000.0,0.0]
		body.nodes[4].stored_quanta=75000
		body.edges[5].scar=.1
		body.edges[5].adaptation=.2
		body.retained_program.erase("manual_revision")
		body.retained_program.operations.pop_back()
		body.retained_program.filter=.43
	var saved: Dictionary=bytes_to_var(var_to_bytes(Save.capture(pop)))
	var copy_pop := Population.new()
	Save.restore(copy_pop,saved)
	for p in ids:
		var body: Anatomy.Cultivator=copy_pop.society.qi_practice.body(copy_pop.society,p)
		assert(body.retained_program.manual_revision==2 and body.retained_program.filter==.43,"Old manual schedule migrates, personal filter survives")
		assert(body.reserve==75000 and body.work==500000 and compiler.residual(body)==0)
		assert(body.reserve_moments==[60000.0,0.0,75000.0,0.0] and body.edges[5].scar==.1 and body.edges[5].adaptation==.2,"Manual migration preserves charged physical state")
	var migrated: Dictionary=bytes_to_var(var_to_bytes(Save.capture(copy_pop)))
	var again := Population.new()
	Save.restore(again,migrated)
	assert(Save.capture(again)==migrated,"Migrated saves round-trip exactly")
	copy_pop.tick_day(2)
	again.tick_span(2)
	first_difference(Save.capture(again),Save.capture(copy_pop))
	assert(Save.capture(again)==Save.capture(copy_pop),"Charged migrated save continues identically in daily and jump play")
	print("Qi fill first PASS")
	quit()

func first_difference(a: Variant, b: Variant, path: String = "state") -> bool:
	if a==b: return false
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if not b.has(key):
				print("MIGRATION missing ",path,".",key)
				return true
			if first_difference(a[key],b[key],path+"."+str(key)): return true
	elif a is Array and b is Array and a.size()==b.size():
		for i in a.size():
			if first_difference(a[i],b[i],path+"["+str(i)+"]"): return true
	else: print("MIGRATION mismatch ",path,": ",str(a).left(100)," / ",str(b).left(100))
	return true
