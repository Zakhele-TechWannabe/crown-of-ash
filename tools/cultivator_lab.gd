extends SceneTree
const EngineData = preload("res://src/circulation.gd")
const Anatomy = preload("res://src/meridians.gd")
const Field = preload("res://src/qi_field.gd")
var lines: Array[String] = []
var initial: Dictionary
var reversed_initial: Dictionary
func say(value: String) -> void:
	lines.append(value)
	print(value)
func run_route(route: String, reversed_branches: bool = false, autonomous: bool = false) -> Dictionary:
	var field := Field.new()
	field.seed(0,"cultivator-lab")
	print("Running %s%s%s" % [route," reversed" if reversed_branches else "", " autonomous" if autonomous else ""])
	var state: Dictionary = (reversed_initial if reversed_branches else initial).duplicate(true)
	EngineData.advance(field,state,EngineData.manual(route),1095,autonomous)
	state.field_hash = JSON.stringify(field.save_state()).sha256_text()
	return state
func describe(label: String, state: Dictionary) -> void:
	say("%s: absorbed %.3f; circulated %.3f; refined %.3f; usable %.3f; dissipated %.3f QU" % [label,state.absorbed/1000.0,state.circulated/1000.0,state.refined/1000.0,state.usable/1000.0,state.dissipated/1000.0])
	say("reserve %.3f; paid work %.3f; capacity %.3f; opening work %.3f; dantian development %.3f QU; purity %.6f; instability %.6f" % [state.reserve/1000.0,state.work/1000.0,state.capacity/1000.0,state.opening_work/1000.0,(state.capacity-100000)/1000.0,state.reserve_moments[0]/maxf(1,state.reserve),state.instability_moment/maxf(1,state.refined)])
	say("peak pressure %.6f; max strain %.6f; recovery days %d; failed %d; injuries %d; deaths %d; residual %d; milestones %s" % [state.peak_pressure,state.max_strain,state.recovery_days,state.failed,state.injuries,state.deaths,EngineData.residual(state),JSON.stringify(state.milestones)])
	var inventory := 0
	for node: Dictionary in state.nodes: inventory += EngineData.total(node)
	say("grounded %.3f QU; remaining in graph %.3f QU" % [state.grounded/1000.0,inventory/1000.0])
	for edge: Dictionary in state.edges:
		say("  %s capacity %.6f QU/s; conductivity %.6f; openness %.3f; adaptation %.6f; integrity %.6f; scar %.6f; practiced %.3f QU" % [edge.id,Anatomy.capacity(edge),Anatomy.conductance(edge),edge.openness,edge.adaptation,edge.integrity,edge.scar,edge.practice])
func _initialize() -> void:
	initial = Anatomy.create()
	reversed_initial = Anatomy.create(true)
	say("Crown of Ash — Stage 2 node-flow reference laboratory, 1095 authoritative days at Sect spring")
	var a := run_route("A")
	var b := run_route("B")
	describe("Route A",a)
	describe("Route B",b)
	var autonomous := run_route("A",false,true)
	describe("Autonomous",autonomous)
	say("Autonomous choices: "+JSON.stringify(autonomous.choices))
	var reverse_a := run_route("A",true)
	var reverse_b := run_route("B",true)
	describe("Reversed A",reverse_a)
	describe("Reversed B",reverse_b)
	var reversal: bool = (a.usable-b.usable)*(reverse_a.usable-reverse_b.usable)<0
	say("Usable-output ranking reversed: %s%s" % [reversal,"" if reversal else "; landscape still too uniform on this objective"])
	for kind in ["cautious","overloaded","damaged"]: say("Safety: "+JSON.stringify(EngineData.safety(kind)))
	var field := Field.new()
	field.seed(0,"cultivator-lab")
	var daily := initial.duplicate(true)
	for day in range(1,1096): EngineData.advance(field,daily,EngineData.manual("A"),day)
	daily.field_hash = JSON.stringify(field.save_state()).sha256_text()
	say("Daily hash: "+EngineData.state_hash(daily))
	say("Jump hash:  "+EngineData.state_hash(a))
	assert(EngineData.state_hash(daily)==EngineData.state_hash(a))
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
	DirAccess.make_dir_recursive_absolute("res://out")
	var report := FileAccess.open("res://out/cultivator_lab.txt",FileAccess.WRITE)
	report.store_string("\n".join(lines)+"\n")
	quit()
