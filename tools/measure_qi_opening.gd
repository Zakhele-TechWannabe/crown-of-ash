extends SceneTree
## Read-only law assay: fresh copies of the actual ten-year fixture bodies.
const Population = preload("res://src/population.gd")
const Fixture = preload("res://tools/qi_cohort_fixture.gd")
const Reference = preload("res://src/circulation.gd")
func _initialize() -> void:
	var pop := Population.new()
	var ids := Fixture.long_prepare(pop)
	var solver := Reference.new()
	solver.use_fast_paths=false
	for p in ids:
		var original: RefCounted=pop.society.qi_practice.body(pop.society,p)
		var sample: Dictionary=pop.society.qi_field.sample(pop.locations[p])
		var cycle_seconds := 0
		for op: Dictionary in original.retained_program.operations: cycle_seconds+=int(op.duration)
		for e in [5,7,8]:
			var active := 0
			for op: Dictionary in original.retained_program.operations:
				if op.operation in ["Guide","Split","Ground"] and e in op.targets: active+=int(op.duration)
			var edge: Reference.Anatomy.Edge=original.edges[e]
			# An hour may include one extra partial cycle: overestimate valve time.
			var seconds := (3600/cycle_seconds+1)*active
			var required := 30.0/(Reference.Anatomy.conductance(edge)*seconds)
			var safe: float=original.nodes[edge.source].safe_pressure
			print("BOUND route=%s edge=%s cycle=%d active=%d hourly_seconds_upper=%d required_delta_lower=%.6f equivalent_fill_lower=%.6f safe_source=%.6f hourly_QU_upper=%.6f" % [original.retained_program.id,edge.id,cycle_seconds,active,seconds,required,required/1.5,safe,Reference.Anatomy.conductance(edge)*seconds*safe])
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
			solver.simulate_day_model(state,original.retained_program,sample,int(sample.quantity))
			var flows: Array=[]
			for edge in [5,7,8]: flows.append(state.edges[edge].daily_flow)
			assert(solver.residual(state.as_dictionary())==0)
			assert(flows[0]<30000 and flows[1]<30000 and flows[2]<30000,"Possible qualifying hour: refine the opening search")
			print("OPENING route=%s fill=%.2f pressure=%.6f return_daily_quanta=%s residual=0" % [original.retained_program.id,percent/100.0,pressure,flows])
	print("STOP: no qualifying opening through 100% fill; no floor may be selected under the 80% condition")
	quit()
