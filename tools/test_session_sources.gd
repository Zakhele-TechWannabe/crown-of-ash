extends SceneTree
## Moving-source coefficients against the original 48-cycle periodic kernel.
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Practice = preload("res://src/qi_practice.gd")
const Store = preload("res://src/meridian_store.gd")
var failures := 0
func _initialize() -> void:
	kernel_equivalence()
	var compiler := Compiler.new()
	var store := Store.new()
	store.add_person()
	store.create(0,PackedByteArray([3,3,3,3,3,3,3,3,3]),1,100,"source-grid",0)
	var body := compiler.production_body(store,0)
	var worst := 0.0
	for route in ["A","B"]:
		var program := compiler.production_program(route)
		program.filter=.25
		for density in [1.0,2.2,5.3,8.0,15.0,32.0,64.0,128.0]:
			var sample := {"density":density,"purity":.75,"stability":.85,"corruption":.04}
			var net := compiler.compile(body,program,sample,0,true)
			for bin in [0,1,6,12,23,24]:
				var exact := compiler.periodic(net,net.program,net.sample,net.pressure_limit*float(bin)/compiler.BINS)
				var fast := compiler.table(net,bin)
				for i in exact.size():
					# Negligible side flows use a 0.00025 qu/cycle absolute bound.
					# Main delivery/intake/quality columns retain the 5% relative gate.
					var error := absf(fast[i]-exact[i])/maxf(.005 if i>=7 else .001,absf(exact[i]))
					worst=maxf(worst,error)
					if error>.050000001:
						failures+=1
						print("Source coefficient error route=%s density=%s bin=%d column=%d exact=%s fast=%s error=%s" % [route,density,bin,i,exact[i],fast[i],error])
	# A policy evaluation must preserve its owner, and match a detached clone.
	var before := compiler.accounting.state_hash(body.as_dictionary())
	var trial := compiler.production_trial(body)
	var reference := compiler.accounting.clone_model(body)
	var policy := compiler.production_program("B")
	var source := {"density":5.3,"purity":.75,"stability":1.0,"corruption":0.0}
	compiler.solve_day(trial,compiler.compile(trial,policy,source,0,true),100000)
	compiler.solve_day(reference,compiler.compile(reference,policy,source,0,true),100000)
	if compiler.accounting.state_hash(body.as_dictionary())!=before or compiler.accounting.state_hash(trial.as_dictionary())!=compiler.accounting.state_hash(reference.as_dictionary()):
		failures+=1
		print("Policy trial clone changed owner or diverged")
	# Transient opening strain heals today: its journal must remain eligible.
	var healing := compiler.production_body(store,0)
	healing.nodes[4].strain=.001
	var clean := {"density":5.3,"purity":1.0,"stability":1.0,"corruption":0.0}
	compiler.step(healing,compiler.live_network(healing,policy,clean),100000)
	if healing.nodes[4].strain!=0 or healing.session_cache.horizon<=0:
		failures+=1
		print("Transient strain discarded a valid next-day replay journal")
	var practice := Practice.new()
	body.residue=6500
	body.absorbed=6500
	body.nodes[4].strain=.3
	var bound := practice.unavoidable_strain(body)
	for route in ["A","B"]:
		for strength in [0.0,.25,1.0]:
			var option := compiler.production_program(route)
			option.filter=strength
			var future := compiler.production_trial(body)
			compiler.solve_day(future,compiler.compile(future,option,source,0,true),100000)
			if future.strain<bound or compiler.residual(future)!=0:
				failures+=1
				print("Policy rejection bound exceeded actual strain, or conservation failed")
	print("Moving source coefficient worst error %.4f%%; %s" % [worst*100,"PASS" if failures==0 else "FAIL"])
	quit(0 if failures==0 else 1)

# Compare the optimization bit-for-bit to the retained generic simultaneous
# allocator. Cover cross-linked chains, shared lanes, moments and health gates.
func kernel_equivalence() -> void:
	var compiler := Compiler.new()
	var store := Store.new()
	store.add_person()
	store.create(0,PackedByteArray([3,3,3,3,3,3,3,3,3]),1,100,"kernel-equality",0)
	var comparisons := 0
	for production in [false,true]:
		var body: Anatomy.Cultivator=compiler.production_body(store,0) if production else Anatomy.Cultivator.from_dictionary(Anatomy.create())
		for route: String in ["A","B","coordinated"]:
			var program := compiler.production_program("B" if route=="coordinated" else route) if production else compiler.accounting.manual("B" if route=="coordinated" else route)
			if route=="coordinated":
				var guide: Dictionary=compiler.accounting.vocabulary.Guide.duplicate(true)
				guide.operation="Guide"
				guide.targets=[2,4]
				program.operations.append(guide)
			for simple in [false,true]:
				for density in [2.2,128.0]:
					var sample := {"density":density,"purity":1.0 if simple else .75,"stability":1.0 if simple else .85,"corruption":0.0 if simple else .04}
					for canonical in [false,true]:
						var net := compiler.compile(body,program,sample,0,canonical)
						for context: Array in [[0,false],[8,true]]:
							var profile := compiler.flow_profile(net,int(context[0]),bool(context[1]))
							for fill in [0.0,.5,1.0]:
								compiler.optimize_independent_flows=false
								var generic := compiler.periodic(profile,profile.program,profile.sample,net.pressure_limit*fill)
								compiler.optimize_independent_flows=true
								var optimized := compiler.periodic(profile,profile.program,profile.sample,net.pressure_limit*fill)
								comparisons+=1
								if optimized!=generic:
									failures+=1
									print("Independent kernel mismatch production=%s route=%s canonical=%s simple=%s density=%s context=%s fill=%s" % [production,route,canonical,simple,density,context,fill])
	print("Independent simultaneous kernel: %d bit-exact comparisons" % comparisons)
