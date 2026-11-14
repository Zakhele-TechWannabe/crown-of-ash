extends RefCounted
## Standalone eight-node laboratory anatomy. No live society state is changed.
const Body = preload("res://src/body_tempering.gd")
class FoundationOwner extends RefCounted:
	var wildlife: RefCounted

static func definition() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/lab.json"))

static func create(reversed_branches: bool = false) -> Dictionary:
	var config := definition()
	# Load the actual BodyTempering storage contract, including all nine permanent grades.
	var owner := FoundationOwner.new()
	var foundation := Body.new(owner)
	foundation.add_person()
	foundation.body_layer[0] = Body.LAYERS
	for i in Body.LAYERS: foundation.grades[i] = int(config.foundation[i])
	var nodes: Array = []
	for id: String in config.nodes:
		nodes.append({"id":id,"mass":[0,0,0,0,0],"moments":[0.0,0.0,0.0,0.0],"volume":float(config.node_volume),"safe_pressure":float(config.node_safe_pressure),"integrity":1.0,"scar":0.0,"strain":0.0,"instability_moment":0.0,"exposure_hours":0.0,"filter_remainder":0.0,"stabilise_remainder":0.0})
	nodes[4].volume = float(config.initial_capacity_quanta)/1000.0/float(nodes[4].safe_pressure)
	nodes[4].stored_quanta = 0
	var edges: Array = []
	for spec: Dictionary in config.edges:
		var grade := 0.0
		var weight := 0.0
		for i in Body.LAYERS:
			grade += foundation.grade(0,i+1) * float(spec.weights[i]) / 3.0
			weight += float(spec.weights[i])
		grade /= weight
		var width := float(spec.width)
		var conductivity := float(spec.conductivity)
		if reversed_branches and config.reversed_edges.has(spec.id):
			width = float(config.reversed_edges[spec.id].width)
			conductivity = float(config.reversed_edges[spec.id].conductivity)
		edges.append({"id":spec.id,"source":spec.source,"destination":spec.destination,"capacity":.020*width*(.70+.60*grade),"conductivity":.010*conductivity*(.80+.40*grade),"openness":1.0,"integrity":1.0,"scar":0.0,"adaptation":0.0,"strain":0.0,"practice":0.0,"work":0,"remainder":0.0,"daily_flow":0,"peak_rate":0.0})
	return {"nodes":nodes,"day":0,"edges":edges,"foundation":Array(foundation.grades),"intake_remainder":0.0,"leak_remainder":0.0,"reserve":0,"reserve_moments":[0.0,0.0,0.0,0.0],"capacity":int(config.initial_capacity_quanta),"opening_work":0,"volume_work":0,"work":0,"absorbed":0,"circulated":0,"refined":0,"usable":0.0,"dissipated":0,"grounded":0,"purity_moment":0.0,"instability_moment":0.0,"strain":0.0,"max_strain":0.0,"peak_pressure":0.0,"recovery_days":0,"failed":0,"injuries":0,"deaths":0,"settling_days":0,"milestones":{},"choices":[]}

static func capacity(edge: Dictionary) -> float:
	return edge.capacity * edge.openness * edge.integrity * (1.0-.60*edge.scar) * (1.0+edge.adaptation)

static func conductance(edge: Dictionary) -> float:
	return edge.conductivity * edge.openness * edge.openness * edge.integrity * (1.0-.50*edge.scar) * 1.15
