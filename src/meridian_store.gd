extends RefCounted
## Production anatomy storage. Rows are allocated only for qualified people.
## This is a state contract, not a cultivation session executor.
const NODES := 16
const EDGES := 24
const NODE_FLOATS := 12
const EDGE_FLOATS := 12
const EDGE_INTS := 4
const PERSON_INTS := 16
const PERSON_FLOATS := 9
enum NodeFloat {PURITY, POLARITY, STABILITY, CORRUPTION, VOLUME, SAFE_PRESSURE, INTEGRITY, SCAR, INSTABILITY, STRAIN, FILTER_REMAINDER, STABILISE_REMAINDER}
enum EdgeFloat {CAPACITY, CONDUCTIVITY, OPENNESS, INTEGRITY, SCAR, ADAPTATION, STRAIN, PRACTICE, REMAINDER, PEAK_RATE, PEAK_PRESSURE, AFFINITY}
enum EdgeInt {FLOW, OPENING_WORK, INTEGRATION_WORK, PRACTICE_EVIDENCE}
enum PersonInt {DAY, REVISION, LAYER, RESERVE, CAPACITY, RESIDUE, OPENING_WORK, VOLUME_WORK, WORK, ABSORBED, DISSIPATED, GROUNDED, SETTLING_DAYS, INJURIES, DEATHS, MANUAL}
enum PersonFloat {RESERVE_PURITY, RESERVE_POLARITY, RESERVE_STABILITY, RESERVE_CORRUPTION, INTAKE_REMAINDER, LEAK_REMAINDER, RESIDUE_REMAINDER, PURGE_REMAINDER, ROOT_PURITY}

static var _definition: Dictionary = {}
var slot := PackedInt32Array()
var people := PackedInt32Array()
var nodes := PackedFloat64Array()
var mass := PackedInt64Array()
var edges := PackedFloat64Array()
var edge_energy := PackedInt64Array()
var reserve_mass := PackedInt64Array()
var integers := PackedInt64Array()
var fractions := PackedFloat64Array()
var achieved := PackedInt32Array()

static func definition() -> Dictionary:
	if _definition.is_empty():
		_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/anatomy.json"))
		assert(_definition.nodes.size() == NODES and _definition.edges.size() == EDGES)
	return _definition

func add_person() -> void:
	slot.append(-1)

## Stable keyed variation; independent of shared RNG consumption and population order.
static func variation(seed_key: String, edge_id: String, draw: String) -> float:
	var value := 2166136261
	for byte: int in (seed_key + ":" + edge_id + ":" + draw).to_utf8_buffer():
		value = ((value ^ byte) * 16777619) & 0xffffffff
	return .75 + .5 * float(value) / 4294967295.0

## Grades use BodyTempering's permanent 0..3 scale. No global foundation average.
func create(person: int, grades: PackedByteArray, root_bits: int, root_purity: int, seed_key: String, on_day: int) -> int:
	assert(person >= 0 and person < slot.size() and grades.size() == 9 and root_bits > 0)
	if slot[person] >= 0: return slot[person]
	var row := people.size()
	slot[person] = row
	people.append(person)
	nodes.resize((row + 1) * NODES * NODE_FLOATS)
	mass.resize((row + 1) * NODES * 5)
	edges.resize((row + 1) * EDGES * EDGE_FLOATS)
	edge_energy.resize((row + 1) * EDGES * EDGE_INTS)
	reserve_mass.resize((row + 1) * 5)
	integers.resize((row + 1) * PERSON_INTS)
	fractions.resize((row + 1) * PERSON_FLOATS)
	achieved.resize((row + 1) * 9)
	for layer in 9: achieved[row * 9 + layer] = -1
	var config := definition()
	var storage_grade := (grades[7] + grades[8]) / 6.0
	for index in NODES:
		var offset := (row * NODES + index) * NODE_FLOATS
		var spec: Dictionary = config.nodes[index]
		var grade := float(grades[0]) / 3 if spec.kind == "interface" else storage_grade
		nodes[offset + NodeFloat.VOLUME] = float(spec.volume_seed)
		nodes[offset + NodeFloat.SAFE_PRESSURE] = float(spec.safe_pressure_seed) + .5 * grade
		nodes[offset + NodeFloat.INTEGRITY] = 1
		if spec.kind == "storage": nodes[offset + NodeFloat.VOLUME] /= nodes[offset + NodeFloat.SAFE_PRESSURE]
	for index in EDGES:
		var spec: Dictionary = config.edges[index]
		var grade := 0.0
		var weight := 0.0
		for layer in 9:
			grade += grades[layer] / 3.0 * float(spec.relevant_tempering_weights[layer])
			weight += float(spec.relevant_tempering_weights[layer])
		grade /= weight
		var offset := (row * EDGES + index) * EDGE_FLOATS
		edges[offset + EdgeFloat.CAPACITY] = .020 * float(spec.seed_width) * variation(seed_key, spec.id, "width") * (.70 + .60 * grade)
		edges[offset + EdgeFloat.CONDUCTIVITY] = .010 * float(spec.seed_conductivity) * variation(seed_key, spec.id, "conductivity") * (.80 + .40 * grade)
		edges[offset + EdgeFloat.OPENNESS] = 0 if spec.dormant else .85 + .30 * (variation(seed_key, spec.id, "opening") - .75)
		edges[offset + EdgeFloat.INTEGRITY] = 1
		var affinity := root_affinity(root_bits)
		var compatibility := 0.0
		var affinity_sum := 0.0
		for element in 5:
			compatibility += affinity[element] * float(spec.affinity[element])
			affinity_sum += float(spec.affinity[element])
		compatibility /= maxf(.000001, affinity_sum)
		edges[offset + EdgeFloat.AFFINITY] = clampf(.65 + .50 * compatibility, .65, 1.15)
	integers[row * PERSON_INTS + PersonInt.DAY] = on_day
	integers[row * PERSON_INTS + PersonInt.REVISION] = 1
	integers[row * PERSON_INTS + PersonInt.CAPACITY] = 100000
	# Preserve separation potential for the executor, not an intake multiplier.
	fractions[row * PERSON_FLOATS + PersonFloat.ROOT_PURITY] = root_purity / 100.0
	return row

static func root_affinity(bits: int) -> PackedFloat64Array:
	var result := PackedFloat64Array([0, 0, 0, 0, 0])
	for element in 5:
		if bits & (1 << element): result[element] = 1
	# Existing ten positions: Metal, Wood, Water, Fire, Earth, Wind,
	# Thunder, Ice, Light, Shadow. Derived roots retain their five-phase basis.
	if bits & (1 << 5):
		result[1] = maxf(result[1], .6)
		result[2] = maxf(result[2], .4)
	if bits & (1 << 6):
		result[1] = maxf(result[1], .5)
		result[3] = maxf(result[3], .5)
	if bits & ((1 << 7) | (1 << 9)): result[2] = 1
	if bits & (1 << 8): result[3] = 1
	return result

func capacity(row: int, edge: int) -> float:
	var offset := (row * EDGES + edge) * EDGE_FLOATS
	return edges[offset + EdgeFloat.CAPACITY] * edges[offset + EdgeFloat.OPENNESS] * edges[offset + EdgeFloat.INTEGRITY] * (1 - .60 * edges[offset + EdgeFloat.SCAR]) * (1 + edges[offset + EdgeFloat.ADAPTATION])

func conductance(row: int, edge: int) -> float:
	var offset := (row * EDGES + edge) * EDGE_FLOATS
	return edges[offset + EdgeFloat.CONDUCTIVITY] * pow(edges[offset + EdgeFloat.OPENNESS], 2) * edges[offset + EdgeFloat.INTEGRITY] * (1 - .50 * edges[offset + EdgeFloat.SCAR]) * edges[offset + EdgeFloat.AFFINITY]

## Presentation adapters allocate only when someone asks to inspect one person.
## Zero flow is intentionally reported until an executor records real transfers.
func report(person: int) -> Dictionary:
	if person < 0 or person >= slot.size() or slot[person] < 0: return {}
	var row := slot[person]
	var config := definition()
	var node_report: Array = []
	for index in NODES:
		var offset := (row * NODES + index) * NODE_FLOATS
		var quantity := 0
		for element in 5: quantity += mass[(row * NODES + index) * 5 + element]
		var occupied := quantity
		if config.nodes[index].kind == "storage": occupied += integers[row * PERSON_INTS + PersonInt.RESERVE] + integers[row * PERSON_INTS + PersonInt.RESIDUE]
		node_report.append({"id":config.nodes[index].id,"quanta":quantity,"pressure":occupied / 1000.0 / maxf(.000001, nodes[offset + NodeFloat.VOLUME]),"integrity":nodes[offset + NodeFloat.INTEGRITY],"scar":nodes[offset + NodeFloat.SCAR],"dormant":config.nodes[index].kind == "dormant"})
	var edge_report: Array = []
	for index in EDGES:
		var offset := (row * EDGES + index) * EDGE_FLOATS
		edge_report.append({"id":config.edges[index].id,"flow_quanta":edge_energy[(row * EDGES + index) * EDGE_INTS + EdgeInt.FLOW],"capacity_qu_per_second":capacity(row,index),"conductance":conductance(row,index),"strain":edges[offset + EdgeFloat.STRAIN],"integrity":edges[offset + EdgeFloat.INTEGRITY],"scar":edges[offset + EdgeFloat.SCAR]})
	var reserve := integers[row * PERSON_INTS + PersonInt.RESERVE]
	return {"person_id":person,"day":integers[row * PERSON_INTS + PersonInt.DAY],"anatomy_revision":integers[row * PERSON_INTS + PersonInt.REVISION],"laws_version":int(config.laws_version),"nodes":node_report,"edges":edge_report,"reserve":reserve,"capacity":integers[row * PERSON_INTS + PersonInt.CAPACITY],"residue":integers[row * PERSON_INTS + PersonInt.RESIDUE],"purity":fractions[row * PERSON_FLOATS + PersonFloat.RESERVE_PURITY] / maxi(1,reserve),"layer":integers[row * PERSON_INTS + PersonInt.LAYER],"achieved":achieved.slice(row * 9, (row + 1) * 9)}

func save_state() -> Dictionary:
	return {"schema_version":1,"slot":slot.duplicate(),"people":people.duplicate(),"nodes":nodes.duplicate(),"mass":mass.duplicate(),"edges":edges.duplicate(),"edge_energy":edge_energy.duplicate(),"reserve_mass":reserve_mass.duplicate(),"integers":integers.duplicate(),"fractions":fractions.duplicate(),"achieved":achieved.duplicate()}

## Validate the complete shape before changing any authoritative column.
func load_state(state: Dictionary) -> bool:
	if int(state.get("schema_version",0)) != 1: return false
	if not state.get("slot") is PackedInt32Array or not state.get("people") is PackedInt32Array: return false
	var count: int = state.people.size()
	for spec: Array in [["nodes",TYPE_PACKED_FLOAT64_ARRAY,NODES * NODE_FLOATS],["mass",TYPE_PACKED_INT64_ARRAY,NODES * 5],["edges",TYPE_PACKED_FLOAT64_ARRAY,EDGES * EDGE_FLOATS],["edge_energy",TYPE_PACKED_INT64_ARRAY,EDGES * EDGE_INTS],["reserve_mass",TYPE_PACKED_INT64_ARRAY,5],["integers",TYPE_PACKED_INT64_ARRAY,PERSON_INTS],["fractions",TYPE_PACKED_FLOAT64_ARRAY,PERSON_FLOATS],["achieved",TYPE_PACKED_INT32_ARRAY,9]]:
		if typeof(state.get(spec[0])) != int(spec[1]) or state[spec[0]].size() != count * int(spec[2]): return false
	for person in state.slot.size():
		var row: int = state.slot[person]
		if row < -1 or row >= count: return false
		if row >= 0 and state.people[row] != person: return false
	for row in count:
		var person: int = state.people[row]
		if person < 0 or person >= state.slot.size() or state.slot[person] != row: return false
	for key: String in ["nodes","edges","fractions"]:
		for value: float in state[key]:
			if not is_finite(value): return false
	for key: String in ["mass","edge_energy","reserve_mass"]:
		for value: int in state[key]:
			if value < 0: return false
	for key: String in ["slot","people","nodes","mass","edges","edge_energy","reserve_mass","integers","fractions","achieved"]: set(key, state[key].duplicate())
	return true

func memory_bytes() -> int:
	return slot.size() * 4 + people.size() * 4 + (nodes.size() + mass.size() + edges.size() + edge_energy.size() + reserve_mass.size() + integers.size() + fractions.size()) * 8 + achieved.size() * 4
