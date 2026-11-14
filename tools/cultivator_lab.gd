extends SceneTree
const EngineData = preload("res://src/circulation.gd")
const Anatomy = preload("res://src/meridians.gd")
const Field = preload("res://src/qi_field.gd")
var solver := EngineData.new()
var worker_limit := maxi(1,mini(4,OS.get_processor_count()))
var simulation_usec_total := 0
var field_usec_total := 0
var quiescent_total := 0
var lines: Array[String] = []
var initial: Dictionary
var reversed_initial: Dictionary
var started := Time.get_ticks_msec()
func say(value: String) -> void:
	lines.append(value)
	print(value)
func run_route(route: String, reversed_branches: bool = false, autonomous: bool = false, daily: bool = false) -> Dictionary:
	var worker_solver := EngineData.new()
	var field := Field.new()
	field.seed(0,"cultivator-lab")
	print("Running %s%s%s" % [route," reversed" if reversed_branches else "", " autonomous" if autonomous else ""])
	var state: Dictionary = worker_solver.clone_state(reversed_initial if reversed_branches else initial)
	if daily:
		for day in range(1,1096): worker_solver.advance(field,state,worker_solver.manual(route),day,autonomous)
	else: worker_solver.advance(field,state,worker_solver.manual(route),1095,autonomous)
	state.field_hash = JSON.stringify(field.save_state()).sha256_text()
	return {"state":state,"simulation_usec":worker_solver.simulation_usec,"field_usec":worker_solver.field_usec,"quiescent":worker_solver.quiescent_cycles}
# One process with a bounded worker count. Only immutable JSON definitions and
# initial templates are shared; each worker owns its mutable solver and field.
func run_batch(jobs: Array) -> Array:
	var result: Array = []
	for offset in range(0,jobs.size(),worker_limit):
		var workers: Array[Thread] = []
		for index in range(offset,mini(offset+worker_limit,jobs.size())):
			var job: Array = jobs[index]
			var worker := Thread.new()
			var status := worker.start(run_route.bind(job[0],job[1],job[2],job[3]))
			assert(status==OK,"Could not start laboratory worker")
			workers.append(worker)
		for worker: Thread in workers:
			var measured: Dictionary = worker.wait_to_finish()
			simulation_usec_total += int(measured.simulation_usec)
			field_usec_total += int(measured.field_usec)
			quiescent_total += int(measured.quiescent)
			result.append(measured.state)
	return result

func describe(label: String, state: Dictionary) -> void:
	say("%s: absorbed %.3f; circulated %.3f; refined %.3f; usable %.3f; dissipated %.3f QU" % [label,state.absorbed/1000.0,state.circulated/1000.0,state.refined/1000.0,state.usable/1000.0,state.dissipated/1000.0])
	say("reserve %.3f; paid work %.3f; capacity %.3f; opening work %.3f; dantian development %.3f QU; purity %.6f; instability %.6f" % [state.reserve/1000.0,state.work/1000.0,state.capacity/1000.0,state.opening_work/1000.0,(state.capacity-100000)/1000.0,state.reserve_moments[0]/maxf(1,state.reserve),state.instability_moment/maxf(1,state.refined)])
	say("peak pressure %.6f; max strain %.6f; recovery days %d; failed %d; injuries %d; deaths %d; residual %d; milestones %s" % [state.peak_pressure,state.max_strain,state.recovery_days,state.failed,state.injuries,state.deaths,solver.residual(state),JSON.stringify(state.milestones)])
	say("SUMMARY %s usable %.3f; permanent %.3f; residue %.3f; max strain %.6f; recovery %d; injuries %d; retention %s; wall days %d; purity %.6f; technique power %.3f; purity checks %s" % [label,state.usable/1000.0,state.work/1000.0,state.residue/1000.0,state.max_strain,state.recovery_days,state.injuries,str(state.milestones.get("retention","unmet")),state.wall_days,state.reserve_moments[0]/maxf(1,state.reserve),state.reserve/1000.0*pow(state.reserve_moments[0]/maxf(1,state.reserve),2),JSON.stringify(state.purity_checks)])
	var purity: float = state.reserve_moments[0]/maxf(1,state.reserve)
	for layer in [3,6]:
		say("  Layer %d purity wall: %s now; first met day %s (purity check only)" % [layer,"met" if purity>=(.75 if layer==3 else .90) else "not met",str(state.purity_checks.get(str(layer),"never"))])
	var inventory := 0
	for node: Anatomy.Compartment in state.nodes: inventory += solver.total(node)
	say("grounded %.3f QU; remaining in graph %.3f QU" % [state.grounded/1000.0,inventory/1000.0])
	for edge: Anatomy.Edge in state.edges:
		say("  %s capacity %.6f QU/s; conductivity %.6f; openness %.3f; adaptation %.6f; integrity %.6f; scar %.6f; practiced %.3f QU" % [edge.id,Anatomy.capacity(edge),Anatomy.conductance(edge),edge.openness,edge.adaptation,edge.integrity,edge.scar,edge.practice])
func _initialize() -> void:
	var configured_workers := OS.get_environment("CROWN_LAB_WORKERS")
	if not configured_workers.is_empty(): worker_limit = clampi(int(configured_workers),1,worker_limit)
	initial = Anatomy.create()
	reversed_initial = Anatomy.create(true)
	say("Crown of Ash — Stage 2 node-flow reference laboratory, 1095 authoritative days at Sect spring")
	# Warm shared read-only vocabulary before workers start.
	solver.manual("A")
	solver.manual("B")
	say("Worker limit: %d (one Godot process)" % worker_limit)
	var ordinary := run_batch([["A",false,false,false],["B",false,false,false],["A",false,true,false],["A",true,false,false]])
	var a: Dictionary = ordinary[0]
	var b: Dictionary = ordinary[1]
	describe("Route A",a)
	describe("Route B",b)
	var autonomous: Dictionary = ordinary[2]
	describe("Autonomous",autonomous)
	say("Autonomous choices: "+JSON.stringify(autonomous.choices))
	var last := run_batch([["B",true,false,false],["A",false,false,true]])
	var reverse_a: Dictionary = ordinary[3]
	var reverse_b: Dictionary = last[0]
	describe("Reversed A",reverse_a)
	describe("Reversed B",reverse_b)
	var reversal: bool = (a.usable-b.usable)*(reverse_a.usable-reverse_b.usable)<0
	for objective in ["usable","work","residue","max_strain"]:
		say("Ranking reversal %s: %s" % [objective,(float(a[objective])-float(b[objective]))*(float(reverse_a[objective])-float(reverse_b[objective]))<0])
	say("Retention-day ranking reversed: %s" % [(int(a.milestones.get("retention",1096))-int(b.milestones.get("retention",1096)))*(int(reverse_a.milestones.get("retention",1096))-int(reverse_b.milestones.get("retention",1096)))<0])
	assert(reversal,"The reversed anatomy must reverse usable output")
	assert(a.recovery_days==0 and a.max_strain<.05,"Careful practice stays near zero strain")
	assert(autonomous.max_strain>0 and autonomous.recovery_days>0,"Greedy practice pays strain and recovery costs")
	say("Usable-output ranking reversed: %s%s" % [reversal,"" if reversal else "; landscape still too uniform on this objective"])
	for kind in ["cautious","overloaded","damaged"]: say("Safety: "+JSON.stringify(solver.safety(kind)))
	var daily: Dictionary = last[1]
	say("Daily hash: "+solver.state_hash(daily))
	say("Jump hash:  "+solver.state_hash(a))
	assert(solver.state_hash(daily)==solver.state_hash(a))
	var output_difference: float = absf(a.usable-b.usable)/maxf(1,a.usable)
	var development_difference: float = absf(a.volume_work-b.volume_work)/maxf(1,a.volume_work)
	var recovery_difference: float = absf(a.recovery_days-b.recovery_days)/float(a.recovery_days) if a.recovery_days>0 else 0.0
	var milestone_gap := 0
	for key: String in a.milestones:
		if b.milestones.has(key): milestone_gap=maxi(milestone_gap,absi(int(a.milestones[key])-int(b.milestones[key])))
	var purity_difference: float = absf(a.reserve_moments[0]/maxf(1,a.reserve)-b.reserve_moments[0]/maxf(1,b.reserve))
	say("Differences: usable %.2f%%; dantian development %.2f%%; purity %.6f; recovery %.2f%% (nonzero baseline required); milestone gap %d days" % [output_difference*100,development_difference*100,purity_difference,recovery_difference*100,milestone_gap])
	say("Responsible mechanisms: narrow abdominal serial path versus lumbar bypass; shared inlet; Filter 15% loss and purity transformation; extra Split/Merge time and coordination gate closure.")
	say("Milestone scope: retention is tested; return/condensation/distribution require additional certification tests. Safety starts with an explicitly charged chest and uses the same graph-flow and damage solver on a one-second grid. Gate precision follows section 13 execution error; additional branches add unfamiliar transitions.")
	say("MEANINGFULLY DIFFERENT" if output_difference>=.15 or development_difference>=.15 or purity_difference>=.05 or recovery_difference>=.20 or milestone_gap>=90 else "NOT YET MEANINGFULLY DIFFERENT")
	say("Quiescent cycles skipped: %d" % quiescent_total)
	say("Profile simulation %.3f s; field %.3f s" % [simulation_usec_total/1000000.0,field_usec_total/1000000.0])
	say("Wall seconds: %.3f" % ((Time.get_ticks_msec()-started)/1000.0))
	DirAccess.make_dir_recursive_absolute("res://out")
	var report := FileAccess.open("res://out/cultivator_lab.txt",FileAccess.WRITE)
	report.store_string("\n".join(lines)+"\n")
	quit()
