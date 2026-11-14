extends SceneTree
## Anatomy/state checks only. This does not assert Stage 3 session acceptance.
const Store = preload("res://src/meridian_store.gd")
const Population = preload("res://src/population.gd")
const Save = preload("res://src/world_save.gd")

func _initialize() -> void:
	var config := Store.definition()
	var identifiers := {}
	for node: Dictionary in config.nodes:
		assert(not identifiers.has(node.id))
		identifiers[node.id] = node
	assert(identifiers.size() == 16)
	var edge_ids := {}
	var reached := {"breath":true}
	for edge: Dictionary in config.edges:
		assert(not edge_ids.has(edge.id) and identifiers.has(edge.from_id) and identifiers.has(edge.to_id))
		edge_ids[edge.id] = true
		assert(edge.relevant_tempering_weights.size() == 9 and edge.affinity.size() == 5)
		assert(float(edge.seed_width) >= .7 and float(edge.seed_width) <= 1.4)
	for iteration in 16:
		for edge: Dictionary in config.edges:
			if reached.has(edge.from_id) and not edge.dormant: reached[edge.to_id] = true
	for id: String in ["lower","left_palm","right_palm","left_sole","right_sole","head"]: assert(reached.has(id), "Every ordinary terminal has a usable path")
	assert(not reached.has("middle") and not reached.has("upper"), "Future centres remain dormant")
	var low := Store.new()
	var perfect := Store.new()
	low.add_person()
	perfect.add_person()
	low.create(0,PackedByteArray([0,0,0,0,0,0,0,0,0]),1,90,"fixture",100)
	perfect.create(0,PackedByteArray([3,3,3,3,3,3,3,3,3]),1,90,"fixture",100)
	# Hold keyed anatomy constant: all-Perfect has the rulebook's 1.86x throughput.
	for edge in 24:
		var offset := edge * Store.EDGE_FLOATS
		assert(absf(perfect.edges[offset + Store.EdgeFloat.CAPACITY] / low.edges[offset + Store.EdgeFloat.CAPACITY] - 1.3 / .7) < 1e-10)
		if not config.edges[edge].dormant: assert(absf(perfect.capacity(0,edge) / low.capacity(0,edge) - 1.3 / .7) < 1e-10)
	var regional := Store.new()
	regional.add_person()
	regional.create(0,PackedByteArray([0,0,3,3,0,0,0,0,0]),1,90,"fixture",100)
	assert(regional.edges[10 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY] > low.edges[10 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY], "Sinew and bone support limbs")
	assert(regional.edges[1 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY] == low.edges[1 * Store.EDGE_FLOATS + Store.EdgeFloat.CAPACITY], "Limb grades do not inflate core channels")
	assert(Store.root_affinity(1 << 5) == PackedFloat64Array([0,.6,.4,0,0]))
	assert(Store.root_affinity(1 << 6) == PackedFloat64Array([0,.5,0,.5,0]))
	assert(Store.root_affinity(1 << 9)[2] == 1)
	var restored := Store.new()
	Save.restore(restored,bytes_to_var(var_to_bytes(Save.capture(perfect))))
	assert(Save.capture(restored) == Save.capture(perfect))
	var bad := restored.save_state()
	bad.mass.resize(0)
	assert(not restored.load_state(bad))
	assert(Save.capture(restored) == Save.capture(perfect), "Invalid saves cannot partially replace columns")
	var report := restored.report(0)
	report.nodes[0].pressure = 900
	assert(restored.report(0).nodes[0].pressure == 0, "Inspection is read-only")
	assert(report.layer == 0 and report.reserve == 0 and report.residue == 0)
	assert(report.achieved == PackedInt32Array([-1,-1,-1,-1,-1,-1,-1,-1,-1]))
	for edge: Dictionary in report.edges: assert(edge.flow_quanta == 0, "No invented execution evidence")
	var bulk := Store.new()
	for person in 250:
		bulk.add_person()
		bulk.create(person,PackedByteArray([2,2,2,2,2,2,2,2,2]),1,80,"bulk:%d" % person,0)
	assert(bulk.memory_bytes() < 8 * 1024 * 1024)
	var first := bulk.save_state()
	bulk.create(0,PackedByteArray([0,0,0,0,0,0,0,0,0]),1,50,"different",999)
	assert(first == bulk.save_state(), "Foundation seeds once, without resetting injury or development")
	var population := Population.new()
	var job: int = population.register_job("anatomy fixture", [])
	var person: int = population.add_person("Foundation",20,job)
	var society: RefCounted = population.society
	population.spirit_root[person] = 1
	assert(society.prepare_meridians(person,0) == -1)
	society.temper.body_layer[person] = 9
	assert(society.prepare_meridians(person,0) == -1, "A completed body still needs an awakened root")
	society.revealed[person] = 1
	var rng_state: int = population.rng.state
	assert(society.prepare_meridians(person,100) == 0)
	assert(population.rng.state == rng_state, "Anatomy does not consume the world RNG")
	assert(society.meridian_report(person).layer == 0)
	var copy := Population.new()
	Save.restore(copy,bytes_to_var(var_to_bytes(Save.capture(population))))
	assert(copy.society.meridian_store.save_state() == society.meridian_store.save_state(), "Society-side save recursion includes the packed store")
	var legacy := Save.capture(population)
	legacy.society.erase("meridian_store")
	legacy.society.qi[person] = 99999
	var old_copy := Population.new()
	var defaults := Save.capture(old_copy)
	Save.restore(old_copy,bytes_to_var(var_to_bytes(legacy)))
	Save.repair_columns(old_copy,defaults,old_copy.size())
	assert(old_copy.society.meridian_store.slot == PackedInt32Array([-1]))
	assert(old_copy.society.prepare_meridians(person,500) == 0)
	assert(old_copy.society.meridian_report(person).reserve == 0 and old_copy.society.meridian_report(person).layer == 0, "Legacy abstract qi creates no reserve or certification")
	Save.repair_meridians(old_copy.society, legacy.society)
	assert(old_copy.society.meridian_store.people.is_empty() and old_copy.society.meridian_store.slot == PackedInt32Array([-1]), "Loading legacy data into an already used world clears its previous anatomy")
	print("PASS Qi Condensation anatomy/state groundwork; %d bytes for 250 bodies. Session/progression acceptance is still pending." % bulk.memory_bytes())
	quit()
