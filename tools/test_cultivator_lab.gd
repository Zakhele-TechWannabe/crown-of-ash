extends SceneTree
const Lab = preload("res://src/circulation.gd")
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
	var reordered := opening.duplicate(true)
	Lab.flow(opening,[1,3])
	Lab.flow(reordered,[3,1])
	assert(opening==reordered,"Simultaneous branch transfers ignore insertion order")
	var total_mass := 0
	for node: Dictionary in opening.nodes: total_mass += Lab.total(node)
	assert(total_mass==51,"Competing branches cannot duplicate source energy")
	assert(Lab.total(opening.nodes[4])==0,"One slice cannot teleport through a chain")
	for node: Dictionary in opening.nodes:
		for mass: int in node.mass: assert(mass>=0)
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
	Lab.flow(full,[2])
	assert(Lab.total(full.nodes[4])>0,"Drawing the reserve permits admission again")
	var forced := Anatomy.create()
	forced.nodes[1].mass=[1000000,0,0,0,0]
	for second in 3600: Lab.flow(forced,[8],true,1)
	assert(forced.edges[8].integrity<1.0 and forced.max_strain>.5,"Forced flow damages through sustained overload")
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
