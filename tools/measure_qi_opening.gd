extends SceneTree
## Opening assay. Overrides affect clones only, never seeded anatomy or saves.
const Population = preload("res://src/population.gd")
const Fixture = preload("res://tools/qi_cohort_fixture.gd")
const Reference = preload("res://src/circulation.gd")
func _initialize() -> void:
	var pop := Population.new()
	var ids := Fixture.long_prepare(pop)
	var factor := 1.0
	var feed_factor := 1.0
	var tail_factor := 1.0
	var wide_core := false
	var grade := 3
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tail-factor="): tail_factor=float(arg.trim_prefix("--tail-factor="))
		if arg.begins_with("--feed-factor="): feed_factor=float(arg.trim_prefix("--feed-factor="))
		if arg.begins_with("--factor="): factor=float(arg.trim_prefix("--factor="))
		if arg.begins_with("--grade="): grade=int(arg.trim_prefix("--grade="))
		if arg=="--wide-core": wide_core=true
	assert(grade>=0 and grade<=3 and factor>0 and feed_factor>0 and tail_factor>0)
	var solver := Reference.new()
	solver.use_fast_paths=false
	for p in ids:
		var original: RefCounted=pop.society.qi_practice.body(pop.society,p)
		var sample: Dictionary=pop.society.qi_field.sample(pop.locations[p])
		# Same individuals and keyed variation; change only foundation multipliers.
		for edge: Reference.Anatomy.Edge in original.edges:
			edge.capacity *= (.70+.60*grade/3.0)/1.30
			edge.conductivity *= (.80+.40*grade/3.0)/1.20
		for node: Reference.Anatomy.Compartment in original.nodes:
			node.safe_pressure=1.0+.5*grade/3.0
		original.nodes[4].volume=original.capacity/1000.0/original.nodes[4].safe_pressure
		for index in ([0,1,2,3,4,5,6,7,8] if wide_core else [5,6,7,8]):
			original.edges[index].capacity *= factor
			original.edges[index].conductivity *= factor
		for index in [6,7,8]:
			original.edges[index].capacity *= tail_factor
			original.edges[index].conductivity *= tail_factor
		for index in [0,1,2]:
			original.edges[index].capacity *= feed_factor
			original.edges[index].conductivity *= feed_factor
		print("ASSAY grade=%d factor=%.1f wide_core=%s feed=%.1f tail=%.1f manual_revision=%d" % [grade,factor,wide_core,feed_factor,tail_factor,int(original.retained_program.get("manual_revision",1))])
		var max_core := 0.0
		var opening := -1
		var cycle_seconds := 0
		for op: Dictionary in original.retained_program.operations: cycle_seconds+=int(op.duration)
		for e in [5,7,8]:
			var active := 0
			for op: Dictionary in original.retained_program.operations:
				if op.operation in ["Guide","Split","Ground"]:
					for target in op.targets:
						if int(target)==e:
							active+=int(op.duration)
							break
			var edge: Reference.Anatomy.Edge=original.edges[e]
			# An hour may include one extra partial cycle: overestimate valve time.
			var seconds := (3600/cycle_seconds+1)*active
			var required := 30.0/(Reference.Anatomy.conductance(edge)*seconds)
			var safe: float=original.nodes[edge.source].safe_pressure
			print("BOUND route=%s edge=%s cycle=%d active=%d hourly_seconds_upper=%d required_delta_lower=%.6f equivalent_fill_lower=%.6f safe_source=%.6f hourly_QU_upper=%.6f" % [original.retained_program.id,edge.id,cycle_seconds,active,seconds,required,required/safe,safe,Reference.Anatomy.conductance(edge)*seconds*safe])
		for percent in range(0,101,5):
			var state := solver.clone_model(original)
			# Reference has eight-node scratch arrays; unused limb nodes are empty.
			# The production manuals use only the first five core nodes.
			state.nodes.resize(8)
			state.opening_work=500000
			state.work=500000
			state.reserve=state.capacity*percent/100
			state.absorbed=state.work+state.reserve
			state.reserve_moments=[float(state.reserve),0.0,float(state.reserve),0.0]
			state.nodes[4].stored_quanta=state.reserve
			var pressure := solver.pressure(state.nodes[4])
			solver.simulate_day_model(state,pop.society.qi_practice.program(str(original.retained_program.id),float(original.retained_program.filter),true),sample,int(sample.quantity))
			var flows: Array=[]
			for edge in [0,1,2,3,4,5,6,7,8]: flows.append(state.edges[edge].daily_flow)
			# Same rule as certification: shared core edges, then the better branch.
			var shared := INF
			for edge in [0,5,6,7,8]: shared=minf(shared,state.edges[edge].daily_flow/4000.0)
			var core := 0.0
			for branch in [[1,2],[3,4]]: core=maxf(core,minf(shared,minf(state.edges[branch[0]].daily_flow,state.edges[branch[1]].daily_flow)/4000.0))
			max_core=maxf(max_core,core)
			if core>=30 and opening<0: opening=percent
			assert(solver.residual(state.as_dictionary())==0)

			print("OPENING route=%s fill=%.2f pressure=%.6f return_daily_quanta=%s core_QU_hour=%.6f residual=0" % [original.retained_program.id,percent/100.0,pressure,flows,core])
		print("SUMMARY grade=%d route=%s factor=%.1f max_core=%.6f first_core_threshold_percent=%d" % [grade,original.retained_program.id,factor,max_core,opening])
	print("Assay complete; daily totals are necessary bounds, not hourly certification.")
	quit()
