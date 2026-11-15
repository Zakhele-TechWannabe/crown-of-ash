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
	var initial: Dictionary = bytes_to_var(var_to_bytes(Save.capture(pop)))
	var economy_initial: Dictionary = bytes_to_var(var_to_bytes(Save.capture(life.economy)))
	for mode in ["baseline","cohort","sealed"]:
		Save.restore(pop,initial)
		Save.restore(life.economy,economy_initial)
		s.law.rebuild_sight()
		prepared.clear()
		if mode!="baseline":
			var palace: Array = s.fifty.people.keys()
			for i in 50:
				var p: int = palace[i]
				prepared.append(p)
				s.temper.body_layer[p]=9
				for grade in 9: s.temper.grades[p*9+grade]=3
				pop.spirit_root[p]=1
				pop.root_purity[p]=100
				s.revealed[p]=1
				var region: String = ["Palace","Sect","Village"][i%3]
				pop.set_location(p,s.qi_field.landmarks[region])
				# Fix the heart's output biases, while keeping production policy intact.
				for weight in s.mind.WEIGHTS: s.mind._set_weight(p,weight,0)
				s.mind.heart_ready[p]=1
				s.mind._set_weight(p,s.mind.B2+s.mind.FEAR,3 if i%2==0 else -3)
				s.mind._set_weight(p,s.mind.B2+s.mind.AMBITION,-3 if i%2==0 else 3)
				s.mind._set_weight(p,s.mind.B2+s.mind.PRIDE,-3 if i%2==0 else 3)
		if mode=="sealed": s.qi_field.set_decree("Heavenly Origin",0)
		var elapsed := 0
		for day in range(1,731):
			var start := Time.get_ticks_usec()
			life.economy.advance_to(day*1440.0)
			pop.tick_day(day)
			elapsed+=Time.get_ticks_usec()-start
			if day%30==0: await process_frame
			if day%365==0: print("LIVE progress %s day=%d" % [mode,day])
		print("LIVE %s ms/day %.3f" % [mode,elapsed/730000.0])
		for i in mini(6,prepared.size()):
			var p := prepared[i]
			if s.meridian_report(p).is_empty():
				print("LIVE %s person=%d died before qualification" % [mode,p])
				continue
			var state: RefCounted=s.qi_practice.body(s,p)
			print("LIVE %s person=%d region=%s careful=%s achieved=%s residue=%d strain=%.6f opening=%d reserve=%d choices=%s" % [mode,p,["Palace","Sect","Village"][i%3],i%2==0,s.meridian_report(p).achieved,state.residue,state.max_strain,state.opening_work,state.reserve,state.choices])
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
