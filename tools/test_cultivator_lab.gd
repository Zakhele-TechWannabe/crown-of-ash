extends SceneTree
const LabScript = preload("res://src/circulation.gd")
var Lab := LabScript.new()
const Anatomy = preload("res://src/meridians.gd")
const Field = preload("res://src/qi_field.gd")
func _initialize() -> void:
	assert(Lab.manual("A")==Lab.manual("A"))
	var opening := Anatomy.create()
	opening.nodes[1].mass = [3,7,11,13,17]
	opening.nodes[1].moments = [40.0,0.0,50.0,0.0]
	for index in [1,3]:
		opening.edges[index].conductivity=100.0
		opening.edges[index].capacity=100.0
	var reordered := Lab.clone_state(opening)
	Lab.flow(opening,[1,3])
	Lab.flow(reordered,[3,1])
	assert(Lab.state_hash(opening)==Lab.state_hash(reordered),"Simultaneous branch transfers ignore insertion order")
	var total_mass := 0
	for node: Anatomy.Compartment in opening.nodes: total_mass += Lab.total(node)
	assert(total_mass==51,"Competing branches cannot duplicate source energy")
	assert(Lab.total(opening.nodes[4])==0,"One slice cannot teleport through a chain")
	for node: Anatomy.Compartment in opening.nodes:
		for mass: int in node.mass: assert(mass>=0)
	var fast := Lab.clone_state(opening)
	var reference := Lab.clone_state(opening)
	Lab.flow(fast,[2])
	Lab.use_fast_paths = false
	Lab.flow(reference,[2])
	Lab.use_fast_paths = true
	assert(Lab.state_hash(fast)==Lab.state_hash(reference),"Single-edge solver matches simultaneous reference")
	fast = Anatomy.create()
	fast.nodes[2].mass = [33,27,11,9,5]
	fast.nodes[2].moments = [60.1,1.3,70.7,2.1]
	fast.nodes[2].instability_moment = 4.2
	reference = Lab.clone_state(fast)
	Lab.process(fast,[2],"Filter",.37)
	Lab.use_fast_paths = false
	Lab.process(reference,[2],"Filter",.37)
	Lab.use_fast_paths = true
	assert(Lab.state_hash(fast)==Lab.state_hash(reference),"Whole-packet refinement matches reference arithmetic")
	var opening_work := Anatomy.create()
	opening_work.absorbed = 1000
	Lab.add(opening_work.nodes[4],{"mass":[1000,0,0,0,0],"moments":[500.0,0.0,1000.0,0.0]})
	Lab.settle(opening_work)
	assert(opening_work.opening_work==500 and opening_work.residue==500 and Lab.residual(opening_work)==0,"Opening consumes only pure work")
	var empty := Anatomy.create()
	Lab.simulate_day(empty,Lab.manual("B"),{"density":0.0,"quantity":0,"elements":[0,0,0,0,0],"purity":1.0,"polarity":0.0,"stability":1.0,"corruption":0.0},0)
	assert(empty.absorbed==0 and empty.refined==0 and empty.settling_days==0 and Lab.residual(empty)==0,"No source, no credit")
	var mixed := Anatomy.create()
	mixed.absorbed=1000
	Lab.add(mixed.nodes[2],{"mass":[500,0,0,0,0],"moments":[500.0,0.0,500.0,0.0]})
	Lab.add(mixed.nodes[2],{"mass":[0,500,0,0,0],"moments":[500.0,0.0,500.0,0.0]})
	assert(absf(mixed.nodes[2].instability_moment/1000.0-.20)<.000001)
	Lab.process(mixed,[2],"Stabilise",0)
	assert(mixed.nodes[2].instability_moment/Lab.total(mixed.nodes[2])<.20)
	assert(mixed.dissipated>0 and Lab.residual(mixed)==0,"Stabilisation must spend energy")
	var full := Anatomy.create()
	full.reserve=75000
	full.reserve_moments=[75000.0,0.0,75000.0,0.0]
	full.nodes[4].stored_quanta=75000
	full.nodes[2].mass=[800,0,0,0,0]
	Lab.flow(full,[2])
	assert(Lab.total(full.nodes[4])==0,"Refined reserve must exert backpressure")
	full.reserve=0
	full.nodes[4].stored_quanta=0
	full.reserve_moments=[0.0,0.0,0.0,0.0]
	full.residue = 75000
	full.nodes[4].residue_quanta = 75000
	Lab.flow(full,[2])
	assert(Lab.total(full.nodes[4])==0,"Residue occupies the same pressure and headroom as reserve")
	full.residue = 0
	full.nodes[4].residue_quanta = 0
	Lab.flow(full,[2])
	assert(Lab.total(full.nodes[4])>0,"Drawing the reserve permits admission again")
	var forced := Anatomy.create()
	forced.nodes[1].mass=[1000000,0,0,0,0]
	for second in 3600: Lab.flow(forced,[8],true,1)
	assert(forced.edges[8].integrity<1.0 and forced.max_strain>.5,"Forced flow damages through sustained overload")
	var dirty := Anatomy.create()
	dirty.absorbed = 1000
	assert(Lab.refined_work(dirty,1000,.75)==750)
	dirty.work = 750
	assert(dirty.residue==250 and Lab.residual(dirty)==0,"Impure work lodges as conserved residue")
	var blocked := Anatomy.create()
	blocked.opening_work = 500000
	blocked.work = 500000
	blocked.settling_days = 30
	blocked.residue = 20000
	blocked.absorbed = 520000
	blocked.nodes[4].residue_quanta = 20000
	Lab.simulate_day(blocked,Lab.manual("A"),{"density":0.0,"quantity":0,"elements":[0,0,0,0,0],"purity":1.0,"polarity":0.0,"stability":1.0,"corruption":0.0},0)
	assert(blocked.wall_days==1 and not blocked.milestones.has("retention"),"Residue stalls retention")
	assert(blocked.max_strain>0 and blocked.recovery_days==1,"Residue creates deterministic strain during ordinary practice")
	assert(blocked.residue<20000 and blocked.dissipated>0 and Lab.residual(blocked)==0,"Purge conserves energy")
	var reserve_work := Anatomy.create()
	reserve_work.opening_work = 500000
	reserve_work.work = 500000
	reserve_work.absorbed = 501000
	reserve_work.reserve = 1000
	reserve_work.reserve_moments = [500.0,0.0,1000.0,0.0]
	reserve_work.nodes[4].stored_quanta = 1000
	var empty_sample := {"density":0.0,"quantity":0,"elements":[0,0,0,0,0],"purity":1.0,"polarity":0.0,"stability":1.0,"corruption":0.0}
	Lab.simulate_day(reserve_work,Lab.manual("A"),empty_sample,0)
	assert(reserve_work.work==500250 and reserve_work.reserve==500 and reserve_work.residue==248,"Reserve integration also partitions pure work and residue before purge")
	assert(Lab.residual(reserve_work)==0)
	for day in 4:
		if blocked.injuries>0: break
		Lab.simulate_day(blocked,Lab.manual("A"),empty_sample,0)
	assert(blocked.injuries>0 and Lab.residual(blocked)==0,"Persistent residue reaches injury through strain and integrity")
	var sample := {"density":4.0,"quantity":1000000,"elements":[1000,2000,3000,4000,5000],"purity":.90,"polarity":0.0,"stability":.97,"corruption":0.0}
	for route in ["A","B"]:
		var optimized := Anatomy.create()
		var reference_session := Lab.clone_state(optimized)
		for day in 10:
			Lab.simulate_day(optimized,Lab.manual(route),sample,1000000)
			Lab.use_fast_paths = false
			Lab.simulate_day(reference_session,Lab.manual(route),sample,1000000)
			Lab.use_fast_paths = true
			if Lab.state_hash(optimized)!=Lab.state_hash(reference_session):
				var actual := Lab.serializable_state(optimized)
				var expected := Lab.serializable_state(reference_session)
				for key in actual:
					if actual[key]!=expected[key]: print("DIFF ",route," day ",day," ",key," actual ",actual[key]," expected ",expected[key])
			assert(Lab.state_hash(optimized)==Lab.state_hash(reference_session),"Optimized sessions preserve the exact general recurrence")
	var stopped := Anatomy.create()
	stopped.residue = 5000
	stopped.absorbed = 5000
	stopped.nodes[4].residue_quanta = 5000
	stopped.nodes[4].strain = .36
	var stopped_reference := Lab.clone_state(stopped)
	var no_source := sample.duplicate(true)
	no_source.density = 0.0
	Lab.simulate_day(stopped,Lab.manual("B"),no_source,0)
	Lab.use_fast_paths = false
	Lab.simulate_day(stopped_reference,Lab.manual("B"),no_source,0)
	Lab.use_fast_paths = true
	assert(Lab.state_hash(stopped)==Lab.state_hash(stopped_reference),"Quiescent fast-forward preserves scalar recurrences exactly")
	assert(Lab.quiescent_cycles>0)
	var field := Field.new()
	field.seed(0,"cultivator-lab")
	var a := Anatomy.create()
	Lab.advance(field,a,Lab.manual("A"),90)
	field = Field.new()
	field.seed(0,"cultivator-lab")
	var b := Anatomy.create()
	for day in range(1,91):
		Lab.advance(field,b,Lab.manual("A"),day)
		assert(Lab.residual(b)==0)
	assert(Lab.state_hash(a)==Lab.state_hash(b),"Daily == jump; deterministic replay")
	assert(a.deaths==0 and a.injuries==0)
	var cautious := Lab.safety("cautious")
	var overloaded := Lab.safety("overloaded")
	var damaged := Lab.safety("damaged")
	assert(cautious.strain==0 and not cautious.injury)
	assert(overloaded.peak_pressure>cautious.peak_pressure and overloaded.injury)
	assert(damaged.strain>overloaded.strain and damaged.injury)
	assert(damaged.failed_ground==1)
	for fixture: Dictionary in [cautious,overloaded,damaged]: assert(absf(fixture.residual)<.000001)
	print("Cultivator lab PASS: deterministic, conserved, daily == jump, pressure-driven safety")
	quit()
