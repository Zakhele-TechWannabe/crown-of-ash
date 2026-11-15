extends SceneTree
## Moving-source coefficients against the original 48-cycle periodic kernel.
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Practice = preload("res://src/qi_practice.gd")
const Store = preload("res://src/meridian_store.gd")
var failures := 0
func _initialize() -> void:
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
