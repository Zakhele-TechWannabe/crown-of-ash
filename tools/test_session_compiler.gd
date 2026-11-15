extends SceneTree
## Full three-year comparison; intentionally fails if any acceptance bound is missed.
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Reference = preload("res://src/circulation.gd")
const Field = preload("res://src/qi_field.gd")
var failures: Array[String] = []
var comparisons: Array = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func check_reuse_contracts() -> void:
	var compiler := Compiler.new()
	var reference := Reference.new()
	var field := Field.new()
	field.seed(0,"reuse-contract")
	var sample: Dictionary = field.sample(field.landmarks.Palace).duplicate(true)
	sample.purity = 1.0
	var body := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	var program := reference.manual("A",0)
	var net := compiler.compile(body,program,sample)
	for day in 40:
		compiler.step(body,net,int(sample.quantity))
		check(compiler.residual(body)==0,"reuse contract conservation")
		var memo: Compiler.DayMemo = body.session_cache
		check(memo.age<compiler.REFRESH_DAYS,"forced refresh bound")
	check(compiler.day_hits>0 and compiler.day_misses>=2,"reuse and periodic refresh exercised")
	var misses := compiler.day_misses
	var previous_revision := body.session_revision
	compiler.set_edge_capacity(body,1,body.edges[1].capacity*.5)
	check(body.session_revision>previous_revision,"capacity edit bumps revision")
	var cold := reference.clone_model(body)
	cold.session_revision = body.session_revision
	var fresh := Compiler.new()
	var cold_net := fresh.compile(cold,program,sample,body.session_revision)
	fresh.step(cold,cold_net,int(sample.quantity))
	compiler.step(body,net,int(sample.quantity))
	check(compiler.day_misses==misses+1,"revision invalidates last-day cache")
	check(reference.state_hash(body.as_dictionary())==reference.state_hash(cold.as_dictionary()),"held network refresh equals cold compilation")
	var changed_sample := sample.duplicate(true)
	changed_sample.purity = .8 # A decree/source-quality change must select a new network.
	var changed_net := compiler.compile(body,program,changed_sample)
	check(changed_net!=net,"source quality included in compiled cache")
	misses = compiler.day_misses
	compiler.step(body,changed_net,int(changed_sample.quantity))
	check(compiler.day_misses==misses+1,"source change invalidates daily reuse")
	body.nodes[1].integrity = .79
	body.injuries += 1
	compiler.invalidate(body)
	misses = compiler.day_misses
	compiler.step(body,changed_net,int(changed_sample.quantity))
	compiler.step(body,changed_net,int(changed_sample.quantity))
	check(compiler.day_misses==misses+2,"injured body cannot replay an unhealed transition")

func check_live_reuse() -> void:
	var compiler := Compiler.new()
	var fresh := Compiler.new()
	var reference := Reference.new()
	var field := Field.new()
	field.seed(0,"live-reuse")
	var sample: Dictionary = field.sample(field.landmarks.Palace)
	var state := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	var program := reference.manual("A",0)
	var network := compiler.compile(state,program,sample,0,true)
	var metadata := sample.duplicate(true)
	metadata.day+=1
	metadata.quantity+=1
	check(compiler.compile(state,program,metadata,0,true)==network,"live key ignores date and inventory metadata")
	for day in 100: compiler.step(state,compiler.compile(state,program,sample,0,true),int(sample.quantity))
	var clone := reference.clone_model(state)
	clone.milestones=state.milestones.duplicate(true)
	fresh.restore_memo(clone,compiler.save_memo(state))
	check(fresh.save_memo(clone)==compiler.save_memo(state),"replay arithmetic survives persistence")
	for day in 40:
		compiler.step(state,compiler.compile(state,program,sample,0,true),int(sample.quantity))
		fresh.step(clone,fresh.compile(clone,program,sample,0,true),int(sample.quantity))
		check(reference.state_hash(state.as_dictionary())==reference.state_hash(clone.as_dictionary()),"live cold replay matches warm execution")
		check(compiler.residual(state)==0 and fresh.residual(clone)==0,"live replay integer conservation")
	check(compiler.day_hits>0,"live canonical memo reuse exercised")

func _initialize() -> void:
	check_reuse_contracts()
	check_live_reuse()
	if "--reuse-only" in OS.get_cmdline_user_args():
		for failure: String in failures: print("FAIL: ",failure)
		print("Session reuse contracts ","PASS" if failures.is_empty() else "FAIL")
		quit(0 if failures.is_empty() else 1)
		return
	var reference := Reference.new()
	for reversed in [false,true]:
		for route: String in ["A","B"]:
			var field := Field.new()
			field.seed(0,"cultivator-lab")
			var exact := Anatomy.Cultivator.from_dictionary(Anatomy.create(reversed))
			var fast := Anatomy.Cultivator.from_dictionary(Anatomy.create(reversed))
			var replay := Anatomy.Cultivator.from_dictionary(Anatomy.create(reversed))
			var live_compiler := Compiler.new()
			var live := Anatomy.Cultivator.from_dictionary(Anatomy.create(reversed))
			var compiler := Compiler.new()
			var program := reference.manual(route)
			var sample: Dictionary = field.sample(field.landmarks.Sect)
			var network := compiler.compile(fast,program,sample)
			check(compiler.compile(fast,program,sample)==network,"compiled coefficient cache hit")
			for day in range(1,1096):
				reference.advance_model(field,exact,program,day)
				compiler.step(fast,network,int(sample.quantity))
				live_compiler.step(live,live_compiler.live_network(live,program,sample),int(sample.quantity))
				check(live_compiler.residual(live)==0,"canonical integer conservation")
				check(compiler.residual(fast)==0,"integer conservation")
			compiler.advance(replay,network,sample,1095)
			check(reference.state_hash(fast.as_dictionary())==reference.state_hash(replay.as_dictionary()),"daily == jump")
			comparisons.append([reversed,route,fast.usable,exact.usable,fast.work,exact.work])
			var label := ("reversed" if reversed else "normal")+"/"+route
			var pairs: Array = []
			for metric: String in ["usable","work","refined","residue"]:
				var x := float(exact.get(metric))
				var y := float(fast.get(metric))
				var error := absf(y-x)/maxf(1,absf(x))
				pairs.append("%s=%.3f/%.3f (%.2f%%)" % [metric,y/1000,x/1000,error*100])
				var tolerance := .10 if metric=="residue" else .05
				check(error<=tolerance,label+" "+metric+" exceeds tolerance")
				check(absf(float(live.get(metric))-x)/maxf(1,absf(x))<=tolerance,label+" canonical "+metric+" exceeds tolerance")
			var exact_retention := int(exact.milestones.get("retention",0))
			var fast_retention := int(fast.milestones.get("retention",0))
			check((exact_retention==0)==(fast_retention==0),label+" retention reachability")
			check(absi(exact_retention-fast_retention)<=maxi(30,ceili(exact_retention*.1)),label+" retention date")
			check((exact.max_strain==0)==(fast.max_strain==0),label+" strain zero/nonzero")
			check(absf(exact.max_strain-fast.max_strain)<=maxf(.001,exact.max_strain*.25),label+" strain exceeds 25%")
			check((exact.recovery_days==0)==(fast.recovery_days==0),label+" recovery zero/nonzero")
			check(absi(exact.recovery_days-fast.recovery_days)<=maxi(1,ceili(exact.recovery_days*.25)),label+" recovery exceeds 25%")
			check(absf(exact.max_strain-live.max_strain)<=maxf(.001,exact.max_strain*.25),label+" canonical strain bound")
			check((exact.recovery_days==0)==(live.recovery_days==0),label+" canonical recovery zero/nonzero")
			check(absi(exact.recovery_days-live.recovery_days)<=maxi(1,ceili(exact.recovery_days*.25)),label+" canonical recovery bound")
			check(absi(exact_retention-int(live.milestones.get("retention",0)))<=maxi(30,ceili(exact_retention*.1)),label+" canonical retention bound")
			print(label," canonical usable=",live.usable," work=",live.work," refined=",live.refined," residue=",live.residue," strain=",live.max_strain," recovery=",live.recovery_days," retention=",live.milestones.get("retention",0))
			print(label," compiled/reference ",", ".join(pairs)," retention=",fast_retention,"/",exact_retention," strain=",fast.max_strain,"/",exact.max_strain," recovery=",fast.recovery_days,"/",exact.recovery_days)
	for offset in [0,2]:
		for metric in [2,4]:
			check(signf(comparisons[offset][metric]-comparisons[offset+1][metric])==signf(comparisons[offset][metric+1]-comparisons[offset+1][metric+1]),"route ranking and reversal")
	var safety_compiler := Compiler.new()
	var cautious := safety_compiler.safety("cautious")
	var overloaded := safety_compiler.safety("overloaded")
	var damaged := safety_compiler.safety("damaged")
	check(cautious.strain==0 and not cautious.injury,"cautious safety")
	check(overloaded.injury and damaged.injury and damaged.strain>overloaded.strain,"pressure-driven injury")
	check(damaged.deaths>0,"integrity-driven death")
	for result: Dictionary in [cautious,overloaded,damaged]: check(result.residual==0,"safety conservation")
	for failure: String in failures: print("BOUND MISSED: ",failure)
	print("Session compiler ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
