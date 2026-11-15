extends SceneTree
const Compiler = preload("res://src/session_compiler.gd")
const Store = preload("res://src/meridian_store.gd")
const Field = preload("res://src/qi_field.gd")
const DAYS := 1095

func _initialize() -> void:
	var budget_failed := false
	var store := Store.new()
	var field := Field.new()
	field.seed(0,"production-budget-probe")
	var sample: Dictionary = field.sample(field.landmarks.Palace)
	for i in 50:
		store.add_person()
		store.create(i,PackedByteArray([2,2,2,2,2,2,2,2,2]),31,100,"bench-%d"%i,0)
	for route: String in ["A","B"]:
		var compiler := Compiler.new()
		var bodies: Array = []
		var networks: Array = []
		var program := compiler.production_program(route)
		var setup_times: Array[int] = []
		var started := Time.get_ticks_usec()
		for row in 50:
			var body_started := Time.get_ticks_usec()
			var body := compiler.production_body(store,row)
			bodies.append(body)
			networks.append(compiler.compile(body,program,sample,1))
			setup_times.append(Time.get_ticks_usec()-body_started)
		var compilation := Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		for day in DAYS:
			for i in 50: compiler.step(bodies[i],networks[i],int(sample.quantity))
		var elapsed := Time.get_ticks_usec()-started
		var hit_rate := 100.0*compiler.day_hits/(compiler.day_hits+compiler.day_misses)
		var coefficient := compiler.coefficient_usec
		var slowest_compilation := 0
		for i in 50: slowest_compilation = maxi(slowest_compilation,setup_times[i]+networks[i].build_usec)
		for body in bodies: assert(compiler.residual(body)==0)
		var replay := compiler.production_body(store,0)
		compiler.advance(replay,networks[0],sample,DAYS)
		assert(compiler.accounting.state_hash(bodies[0].as_dictionary())==compiler.accounting.state_hash(replay.as_dictionary()),"16-node daily == jump")
		var usec := float(elapsed)/(50*DAYS)
		if float(elapsed+compilation)/(50*DAYS)>40 or slowest_compilation>50000: budget_failed = true
		print("16-node Palace route=%s bodies=50 days=%d execution_us/person-day=%.3f initial_compilation_ms=%.3f coefficient_ms=%.3f amortized_us=%.3f budget_us=40 conserved=true hit_rate=%.2f%% compile_ms/body=%.3f max_compile_ms/body=%.3f" % [route,DAYS,usec,compilation/1000.0,coefficient/1000.0,float(elapsed+compilation)/(50*DAYS),hit_rate,(compilation+coefficient)/50000.0,slowest_compilation/1000.0])
	print("Session compiler budget ","FAIL" if budget_failed else "PASS")
	quit(1 if budget_failed else 0)
