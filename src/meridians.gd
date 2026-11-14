extends RefCounted
## Standalone eight-node laboratory anatomy. No live society state is changed.
const Body = preload("res://src/body_tempering.gd")
class FoundationOwner extends RefCounted:
	var wildlife: RefCounted

class Compartment extends RefCounted:
	var process_limit := -1
	var id: String
	var mass: Array = []
	var moments: Array = []
	var volume: float
	var safe_pressure: float
	var integrity: float
	var scar: float
	var strain: float
	var instability_moment: float
	var exposure_hours: float
	var filter_remainder: float
	var stabilise_remainder: float
	var stored_quanta: int
	var residue_quanta: int
	var quantity: int = -1
	var hazard_valid := false
	var hazard_pressure := 0.0
	var hazard_base := 0.0
	var hazard_corruption := 0.0
	var hazard_occupied := false

	func as_dictionary() -> Dictionary:
		return {"id":id,"mass":mass,"moments":moments,"volume":volume,"safe_pressure":safe_pressure,"integrity":integrity,"scar":scar,"strain":strain,"instability_moment":instability_moment,"exposure_hours":exposure_hours,"filter_remainder":filter_remainder,"stabilise_remainder":stabilise_remainder,"stored_quanta":stored_quanta,"residue_quanta":residue_quanta,"quantity":quantity}

	static func from_dictionary(values: Dictionary) -> Compartment:
		var result := Compartment.new()
		for key: String in values: result.set(key,values[key])
		return result

class Edge extends RefCounted:
	var cached_capacity := -1.0
	var cached_conductance := -1.0
	var id: String
	var source: int
	var destination: int
	var capacity: float
	var conductivity: float
	var openness: float
	var integrity: float
	var scar: float
	var adaptation: float
	var strain: float
	var practice: float
	var work: int
	var remainder: float
	var daily_flow: int
	var peak_rate: float

	func as_dictionary() -> Dictionary:
		return {"id":id,"source":source,"destination":destination,"capacity":capacity,"conductivity":conductivity,"openness":openness,"integrity":integrity,"scar":scar,"adaptation":adaptation,"strain":strain,"practice":practice,"work":work,"remainder":remainder,"daily_flow":daily_flow,"peak_rate":peak_rate}

	static func from_dictionary(values: Dictionary) -> Edge:
		var result := Edge.new()
		for key: String in values: result.set(key,values[key])
		return result

class Cultivator extends RefCounted:
	var exposure_nodes: Array[Compartment] = []
	var nodes: Array[Compartment] = []
	var day: int
	var edges: Array[Edge] = []
	var foundation: Array = []
	var intake_remainder: float
	var leak_remainder: float
	var residue: int
	var residue_added: int
	var residue_remainder: float
	var purge_remainder: float
	var purge_multiplier: float
	var wall_days: int
	var purity_checks: Dictionary = {}
	var reserve: int
	var reserve_moments: Array = []
	var capacity: int
	var opening_work: int
	var volume_work: int
	var work: int
	var absorbed: int
	var circulated: int
	var refined: int
	var usable: float
	var dissipated: int
	var grounded: int
	var purity_moment: float
	var instability_moment: float
	var strain: float
	var max_strain: float
	var peak_pressure: float
	var recovery_days: int
	var failed: int
	var injuries: int
	var deaths: int
	var settling_days: int
	var milestones: Dictionary = {}
	var choices: Array = []
	var pending_work: int
	var retained_program: Dictionary = {}

	func as_dictionary() -> Dictionary:
		return {"nodes":nodes,"day":day,"edges":edges,"foundation":foundation,"intake_remainder":intake_remainder,"leak_remainder":leak_remainder,"residue":residue,"residue_added":residue_added,"residue_remainder":residue_remainder,"purge_remainder":purge_remainder,"purge_multiplier":purge_multiplier,"wall_days":wall_days,"purity_checks":purity_checks,"reserve":reserve,"reserve_moments":reserve_moments,"capacity":capacity,"opening_work":opening_work,"volume_work":volume_work,"work":work,"absorbed":absorbed,"circulated":circulated,"refined":refined,"usable":usable,"dissipated":dissipated,"grounded":grounded,"purity_moment":purity_moment,"instability_moment":instability_moment,"strain":strain,"max_strain":max_strain,"peak_pressure":peak_pressure,"recovery_days":recovery_days,"failed":failed,"injuries":injuries,"deaths":deaths,"settling_days":settling_days,"milestones":milestones,"choices":choices,"pending_work":pending_work,"retained_program":retained_program}

	static func from_dictionary(values: Dictionary) -> Cultivator:
		var result := Cultivator.new()
		for key: String in values:
			if key=="nodes": result.nodes.assign(values[key])
			elif key=="edges": result.edges.assign(values[key])
			else: result.set(key,values[key])
		return result

static var cached_definition: Dictionary = {}

static func definition() -> Dictionary:
	if cached_definition.is_empty(): cached_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/lab.json"))
	return cached_definition

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
		nodes.append(Compartment.from_dictionary({"id":id,"mass":[0,0,0,0,0],"moments":[0.0,0.0,0.0,0.0],"volume":float(config.node_volume),"safe_pressure":float(config.node_safe_pressure),"integrity":1.0,"scar":0.0,"strain":0.0,"instability_moment":0.0,"exposure_hours":0.0,"filter_remainder":0.0,"stabilise_remainder":0.0}))
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
		edges.append(Edge.from_dictionary({"id":spec.id,"source":spec.source,"destination":spec.destination,"capacity":.020*width*(.70+.60*grade),"conductivity":.010*conductivity*(.80+.40*grade),"openness":1.0,"integrity":1.0,"scar":0.0,"adaptation":0.0,"strain":0.0,"practice":0.0,"work":0,"remainder":0.0,"daily_flow":0,"peak_rate":0.0}))
	return {"nodes":nodes,"day":0,"edges":edges,"foundation":Array(foundation.grades),"intake_remainder":0.0,"leak_remainder":0.0,"residue":0,"residue_added":0,"residue_remainder":0.0,"purge_remainder":0.0,"purge_multiplier":1.0,"wall_days":0,"purity_checks":{},"reserve":0,"reserve_moments":[0.0,0.0,0.0,0.0],"capacity":int(config.initial_capacity_quanta),"opening_work":0,"volume_work":0,"work":0,"absorbed":0,"circulated":0,"refined":0,"usable":0.0,"dissipated":0,"grounded":0,"purity_moment":0.0,"instability_moment":0.0,"strain":0.0,"max_strain":0.0,"peak_pressure":0.0,"recovery_days":0,"failed":0,"injuries":0,"deaths":0,"settling_days":0,"milestones":{},"choices":[]}

static func capacity(edge: Edge) -> float:
	if edge.cached_capacity>=0: return edge.cached_capacity
	return edge.capacity * edge.openness * edge.integrity * (1.0-.60*edge.scar) * (1.0+edge.adaptation)

static func conductance(edge: Edge) -> float:
	if edge.cached_conductance>=0: return edge.cached_conductance
	return edge.conductivity * edge.openness * edge.openness * edge.integrity * (1.0-.50*edge.scar) * 1.15
