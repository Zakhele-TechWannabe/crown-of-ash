extends SceneTree
const Save = preload("res://src/world_save.gd")
var prepared: Array[int] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node2D=load("res://world_map.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var life: Node2D=world.life
	life.set_process(false)
	life.population.async_factions=false
	life.paused=true
	var pop: RefCounted=life.population
	var s: RefCounted=pop.society
	s.qi_field.seed(0)
	var ordinary_palace: Array=s.fifty.people.keys()
	var initial: Dictionary = bytes_to_var(var_to_bytes(Save.capture(pop)))
	var economy_initial: Dictionary = bytes_to_var(var_to_bytes(Save.capture(life.economy)))
	for mode in ["baseline","unaware","cohort","sealed"]:
		if "--cohort-only" in OS.get_cmdline_user_args() and mode!="cohort": continue
		Save.restore(pop,bytes_to_var(var_to_bytes(initial)))
		Save.restore(life.economy,bytes_to_var(var_to_bytes(economy_initial)))
		s.law.rebuild_sight()
		if mode=="unaware": s.qi_practice=preload("res://tools/qi_cohort_fixture.gd").UnawarePractice.new()
		else: s.qi_practice=preload("res://src/qi_practice.gd").new()
		prepared.clear()
		if mode!="baseline":
			prepared=preload("res://tools/qi_cohort_fixture.gd").prepare_palace(pop)
		if mode=="sealed": s.qi_field.set_decree("Heavenly Origin",0)
		s.qi_practice.profile.fill(0)
		s.qi_practice._compiler.diagnose = "--diagnose" in OS.get_cmdline_user_args()
		var peaks: Dictionary = {}
		var elapsed := 0
		for day in range(1,731):
			var start := Time.get_ticks_usec()
			life.economy.advance_to(day*1440.0)
			pop.tick_day(day)
			elapsed+=Time.get_ticks_usec()-start
			if s.qi_practice._compiler.diagnose:
				for index in [1,2,4]:
					if prepared.is_empty(): continue
					var person: int=prepared[index]
					var state: RefCounted=s.qi_practice.body(s,person)
					if not peaks.has(person) or state.strain>peaks[person].strain:
						peaks[person]={"day":day,"strain":state.strain,"terms":state.milestones.get("danger_terms",{}).duplicate(true),"reserve":state.reserve,"capacity":state.capacity,"residue":state.residue,"integrity":state.nodes[4].integrity,"program":state.retained_program.duplicate(true),"location":pop.locations[person],"sample":s.qi_field.sample(pop.locations[person])}
			if day%30==0: await process_frame
			if day%365==0: print("LIVE progress %s day=%d" % [mode,day])
		print("LIVE %s ms/day %.3f" % [mode,elapsed/730000.0])
		print("LIVE PROFILE %s phases_usec=%s signatures=%d coefficients=%d day_hits=%d day_misses=%d network_hits=%d network_misses=%d" % [mode,s.qi_practice.profile,s.qi_practice._compiler.signature_usec,s.qi_practice._compiler.coefficient_usec,s.qi_practice._compiler.day_hits,s.qi_practice._compiler.day_misses,s.qi_practice._compiler.cache_hits,s.qi_practice._compiler.cache_misses])
		for i in mini(6,prepared.size()):
			var p := prepared[i]
			if s.meridian_report(p).is_empty():
				print("LIVE %s person=%d died before qualification" % [mode,p])
				continue
			var state: RefCounted=s.qi_practice.body(s,p)
			print("LIVE %s person=%d region=%s careful=%s achieved=%s residue=%d strain=%.6f opening=%d reserve=%d choices=%s" % [mode,p,["Palace","Sect","Village"][i%3],i%2==0,s.meridian_report(p).achieved,state.residue,state.max_strain,state.opening_work,state.reserve,state.choices])
		print("LIVE DANGER %s %s" % [mode,peaks])
		print("LIVE RESPONSES %s %s" % [mode,preload("res://tools/qi_cohort_fixture.gd").danger_summary(s,prepared)])
		if mode=="baseline":
			var counts := PackedInt32Array([0,0,0])
			var eligible := 0
			for p: int in ordinary_palace:
				var report: Dictionary=s.meridian_report(p)
				if report.is_empty(): continue
				eligible+=1
				for layer in 3: counts[layer]+=int(report.achieved[layer]>=0)
			print("LIVE ORDINARY Palace day=730 members=%d qualified=%d layer_1_2_3_count=%s" % [ordinary_palace.size(),eligible,counts])
		summarise(s,mode)
	world.queue_free()
	quit()

func summarise(s: RefCounted, mode: String) -> void:
	for region in 3:
		var counts := PackedInt32Array([0,0,0])
		var first := PackedInt32Array([-1,-1,-1])
		var last := PackedInt32Array([-1,-1,-1])
		var members := 0
		var living := 0
		var work := 0
		for i in prepared.size():
			if i%3!=region: continue
			members+=1
			var p: int=prepared[i]
			living+=int(s.alive[p])
			var report: Dictionary=s.meridian_report(p)
			if report.is_empty(): continue
			work+=s.qi_practice.body(s,p).work
			for layer in 3:
				var day: int=report.achieved[layer]
				if day<0: continue
				counts[layer]+=1
				first[layer]=day if first[layer]<0 else mini(first[layer],day)
				last[layer]=maxi(last[layer],day)
		print("LIVE SUMMARY mode=%s region=%s members=%d living=%d layer_1_2_3_count=%s first=%s last=%s work=%d" % [mode,["Palace","Sect","Village"][region],members,living,counts,first,last,work])
