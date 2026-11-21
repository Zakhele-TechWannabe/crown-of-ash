extends RefCounted
## Integer-energy, persistent-node reference solver. Each Guide phase takes its
## candidates from one opening snapshot and commits together. No scene dependencies.
const Anatomy = preload("res://src/meridians.gd")
const Field = preload("res://src/qi_field.gd")
const DT := 10
const RESERVE_FLOOR := .70

class Instruction extends RefCounted:
	var code: int
	var slices: int
	var targets: Array
	var error: float
	var name: String

var compiled_programs: Dictionary = {}

func compile_program(program: Dictionary, base_error: float) -> Array:
	var key := JSON.stringify([program.operations,base_error])
	if compiled_programs.has(key): return compiled_programs[key]
	assert(program.operations.size()<=32)
	var result: Array[Instruction] = []
	for operation: Dictionary in program.operations:
		assert(int(operation.duration)>=DT and int(operation.duration)%DT==0,"Operations use the fixed ten-second grid")
		assert(operation.targets.size()<=int(operation.get("max_lanes",4)),"Too many concurrent lanes")
		var op := Instruction.new()
		op.name = str(operation.operation)
		op.code = ["Absorb","Guide","Split","Ground","Filter","Stabilise","Integrate","Merge","Circulate"].find(op.name)
		assert(op.code>=0,"Unsupported operation")
		op.slices = int(operation.duration)/DT
		op.targets = operation.targets.duplicate()
		op.error = base_error+.10*maxf(0,float(operation.control_demand)-1.0)
		result.append(op)
	compiled_programs[key] = result
	return result

var use_fast_paths := true
var split_cache: Dictionary = {}
var interference_cache: Dictionary = {}
static var vocabulary: Dictionary = {}
var quiescent_cycles := 0
var simulation_usec := 0
var field_usec := 0

func manual(name: String, filter_override: float = -1.0) -> Dictionary:
	if vocabulary.is_empty(): vocabulary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/operations.json"))
	var config := Anatomy.definition()
	assert(config.sequences.has(name), "Unknown route")
	var sequence: Array = config.sequences[name]
	var operations: Array = []
	for entry: Array in sequence:
		var op: Dictionary = vocabulary[entry[0]].duplicate(true)
		op.operation = entry[0]
		op.targets = entry[1]
		op.source = "environment" if entry[0] == "Absorb" else "declared graph nodes"
		op.destination = "declared graph nodes" if entry[0] != "Ground" else "external earth sink"
		operations.append(op)
	return {"id":name,"operations":operations,"paths":[[0,1,2]] if name == "A" else [[0,1,2],[0,3,4,5,6]],"filter":filter_override if filter_override>=0 else float(config["filter_"+name]),"forced":false}

func total(node: Anatomy.Compartment) -> int:
	if node.quantity>=0: return node.quantity
	var sum := 0
	for mass: int in node.mass: sum += mass
	return sum

func pressure(node: Anatomy.Compartment) -> float:
	return (total(node)+node.stored_quanta+node.residue_quanta)/1000.0/maxf(.000001,node.volume)

func split(quantity: int, weights: Array) -> Array:
	var key := [quantity,weights[0],weights[1],weights[2],weights[3],weights[4]]
	if split_cache.has(key): return split_cache[key]
	var result := [0,0,0,0,0]
	var sum := 0
	for weight: int in weights: sum += weight
	if sum == 0:
		result.make_read_only()
		return result
	var used := 0
	var fractions: Array = []
	for e in 5:
		result[e] = quantity*int(weights[e])/sum
		used += int(result[e])
		fractions.append(quantity*int(weights[e])%sum)
	while used < quantity:
		var best := 0
		for e in 5:
			if int(fractions[e])>int(fractions[best]): best=e
		result[best] += 1
		fractions[best] = -1
		used += 1
	if split_cache.size()>=8192: split_cache.clear()
	result.make_read_only()
	split_cache[key] = result
	return result

func interference(mass: Array) -> float:
	if interference_cache.has(mass): return float(interference_cache[mass])
	var quantity := 0
	for value: int in mass: quantity += value
	if quantity==0: return 0.0
	var opposing := maxi(mini(int(mass[0]),int(mass[1])),mini(int(mass[1]),int(mass[4])))
	opposing = maxi(opposing,mini(int(mass[4]),int(mass[2])))
	opposing = maxi(opposing,mini(int(mass[2]),int(mass[3])))
	opposing = maxi(opposing,mini(int(mass[3]),int(mass[0])))
	var result := .40*opposing/quantity
	if interference_cache.size()>=8192: interference_cache.clear()
	interference_cache[mass.duplicate()] = result
	return result

func remove(node: Anatomy.Compartment, quantity: int) -> Dictionary:
	var opening := total(node)
	quantity = mini(quantity,opening)
	if quantity==0: return {"mass":[0,0,0,0,0],"moments":[0.0,0.0,0.0,0.0],"instability_moment":0.0}
	var mass: Array = node.mass if quantity==opening else split(quantity,node.mass)
	var moments := [0.0,0.0,0.0,0.0]
	node.hazard_valid = false
	node.quantity = opening-quantity
	var node_mass: Array = node.mass
	var node_moments: Array = node.moments
	if quantity==opening: node.mass = [0,0,0,0,0]
	else:
		for e in 5: node_mass[e] -= int(mass[e])
	for q in 4:
		moments[q] = node_moments[q]*float(quantity)/maxi(1,opening)
		node_moments[q] -= moments[q]
	var instability: float = node.instability_moment*float(quantity)/maxi(1,opening)
	node.instability_moment -= instability
	return {"mass":mass,"moments":moments,"instability_moment":instability}

func add(node: Anatomy.Compartment, packet: Dictionary) -> void:
	var incoming := 0
	for value: int in packet.mass: incoming += value
	if incoming==0: return
	var before := total(node)
	node.hazard_valid = false
	node.quantity = before+incoming
	var node_mass: Array = node.mass
	var node_moments: Array = node.moments
	var packet_mass: Array = packet.mass
	var packet_moments: Array = packet.moments
	if before==0:
		node.mass = packet_mass.duplicate()
		for q in 4: node_moments[q] += float(packet_moments[q])
		node.instability_moment += float(packet.get("instability_moment",interference(packet_mass)*incoming))
		return
	var packet_interference := interference(packet_mass)
	var unmixed: float = interference(node_mass)*before+packet_interference*incoming
	for e in 5: node_mass[e] += int(packet_mass[e])
	for q in 4: node_moments[q] += float(packet_moments[q])
	# Preserve prior stabilisation; only newly mixed opposing fractions add interference.
	node.instability_moment += float(packet.get("instability_moment",packet_interference*incoming))
	node.instability_moment += maxf(0,interference(node_mass)*(before+incoming)-unmixed)

func flow_model(state: Anatomy.Cultivator, indices: Array, forced: bool = false, dt: int = DT, gate: float = 1.0) -> void:
	if forced and dt>1:
		for second in dt: flow_model(state,indices,true,1,gate)
		return
	if use_fast_paths and not forced and indices.size()==1:
		flow_single(state,int(indices[0]),dt,gate)
		return
	if use_fast_paths and not forced and indices.size()==2 and flow_pair(state,mini(int(indices[0]),int(indices[1])),maxi(int(indices[0]),int(indices[1])),dt,gate): return
	indices = indices.duplicate()
	indices.sort()
	var candidates: Array = []
	var outflows := [0,0,0,0,0,0,0,0]
	var inflows := [0,0,0,0,0,0,0,0]
	for index: int in indices:
		var edge: Anatomy.Edge = state.edges[index]
		var source: Anatomy.Compartment = state.nodes[int(edge.source)]
		var destination: Anatomy.Compartment = state.nodes[int(edge.destination)]
		var ideal := minf(Anatomy.conductance(edge)*gate*maxf(0,pressure(source)-pressure(destination))*dt,Anatomy.capacity(edge)*dt*(2.0 if forced else 1.0))*1000.0+float(edge.remainder)
		var quantity := floori(ideal)
		edge.remainder = ideal-quantity
		candidates.append(quantity)
		outflows[int(edge.source)] += quantity
		inflows[int(edge.destination)] += quantity
	var packets: Array = []
	for i in indices.size():
		var edge: Anatomy.Edge = state.edges[int(indices[i])]
		var source: Anatomy.Compartment = state.nodes[int(edge.source)]
		var destination: Anatomy.Compartment = state.nodes[int(edge.destination)]
		var available := total(source)
		var headroom := maxi(0,floori(destination.volume*destination.safe_pressure*1000)-total(destination)-destination.stored_quanta-destination.residue_quanta)
		var scale := minf(1,float(available)/maxi(1,int(outflows[int(edge.source)])))
		if not forced: scale = minf(scale,float(headroom)/maxi(1,int(inflows[int(edge.destination)])))
		var quantity := floori(int(candidates[i])*scale)
		packets.append({"destination":int(edge.destination),"packet":remove(source,quantity)})
		state.circulated += quantity
		edge.practice += quantity/1000.0
		edge.daily_flow += quantity
		edge.peak_rate = maxf(edge.peak_rate,quantity/1000.0/dt)
		if forced:
			var overload := maxf(0,quantity/1000.0/dt/maxf(.0000001,Anatomy.capacity(edge))-1.0)
			edge.strain += overload*overload*dt/3600.0
			var loss := .02*maxf(0,edge.strain-.50)*dt/3600.0
			if edge.integrity>=.8 and edge.integrity-loss<.8: state.injuries += 1
			edge.integrity = maxf(0,edge.integrity-loss)
			edge.scar += .10*maxf(0,loss-.01)
			state.strain=maxf(state.strain,edge.strain)
			state.max_strain=maxf(state.max_strain,edge.strain)

	for packet: Dictionary in packets: add(state.nodes[int(packet.destination)],packet.packet)
	# Grounding is a terminal sink, not an extra copy of the inventory.
	var grounded := total(state.nodes[7])
	remove(state.nodes[7],grounded)
	state.grounded += grounded

# A single declared edge has no competing allocation. This is algebraically
# the same opening-state solver without temporary candidate and packet arrays.
func flow_single(state: Anatomy.Cultivator, index: int, dt: int, gate: float) -> void:
	var edge: Anatomy.Edge = state.edges[index]
	var source: Anatomy.Compartment = state.nodes[int(edge.source)]
	var destination: Anatomy.Compartment = state.nodes[int(edge.destination)]
	var ideal := minf(Anatomy.conductance(edge)*gate*maxf(0,pressure(source)-pressure(destination))*dt,Anatomy.capacity(edge)*dt)*1000.0+float(edge.remainder)
	var candidate := floori(ideal)
	edge.remainder = ideal-candidate
	var available := total(source)
	var headroom := maxi(0,floori(destination.volume*destination.safe_pressure*1000)-total(destination)-destination.stored_quanta-destination.residue_quanta)
	var scale := minf(1,float(available)/maxi(1,candidate))
	scale = minf(scale,float(headroom)/maxi(1,candidate))
	var quantity := floori(candidate*scale)
	if quantity>0:
		transfer_packet(source,destination,quantity)
		state.circulated += quantity
		edge.practice += quantity/1000.0
		edge.daily_flow += quantity
		edge.peak_rate = maxf(edge.peak_rate,quantity/1000.0/dt)
	var grounded := total(state.nodes[7])
	if grounded>0:
		remove(state.nodes[7],grounded)
		state.grounded += grounded

# Fuse removal and admission for the non-competing edge, preserving moment
# operations and mixing order while avoiding an intermediate packet dictionary.
func transfer_packet(source: Anatomy.Compartment, destination: Anatomy.Compartment, quantity: int) -> void:
	var opening := total(source)
	var before := total(destination)
	var mass: Array = source.mass if quantity==opening else split(quantity,source.mass)
	var source_mass: Array = source.mass
	var destination_mass: Array = destination.mass
	var source_moments: Array = source.moments
	var destination_moments: Array = destination.moments
	var unmixed := 0.0
	if before>0: unmixed = interference(destination_mass)*before+interference(mass)*quantity
	if quantity==opening: source.mass = [0,0,0,0,0]
	else:
		for e in 5: source_mass[e] -= int(mass[e])
	if before==0: destination.mass = mass.duplicate()
	else:
		for e in 5: destination_mass[e] += int(mass[e])
	for q in 4:
		var moment: float = source_moments[q]*float(quantity)/maxi(1,opening)
		source_moments[q] -= moment
		destination_moments[q] += moment
	var instability: float = source.instability_moment*float(quantity)/maxi(1,opening)
	source.instability_moment -= instability
	destination.instability_moment += instability
	if before>0: destination.instability_moment += maxf(0,interference(destination_mass)*(before+quantity)-unmixed)
	source.quantity = opening-quantity
	destination.quantity = before+quantity
	source.hazard_valid = false
	destination.hazard_valid = false

# Two lanes with distinct destinations and no chain can commit their packets
# directly after both candidates are calculated. Shared-source allocation keeps
# the reference solver's exact sequential availability and common denominator.
func flow_pair(state: Anatomy.Cultivator, first_index: int, second_index: int, dt: int, gate: float) -> bool:
	var first: Anatomy.Edge = state.edges[first_index]
	var second: Anatomy.Edge = state.edges[second_index]
	if first.destination==second.destination or first.destination==second.source or second.destination==first.source or first.source==first.destination or second.source==second.destination: return false
	var first_candidate := flow_candidate(state,first,dt,gate)
	var second_candidate := flow_candidate(state,second,dt,gate)
	var common := first_candidate+second_candidate if first.source==second.source else 0
	commit_candidate(state,first,first_candidate,common if common>0 else first_candidate,dt)
	commit_candidate(state,second,second_candidate,common if common>0 else second_candidate,dt)
	var grounded := total(state.nodes[7])
	if grounded>0:
		remove(state.nodes[7],grounded)
		state.grounded += grounded
	return true

func flow_candidate(state: Anatomy.Cultivator, edge: Anatomy.Edge, dt: int, gate: float) -> int:
	var source: Anatomy.Compartment = state.nodes[edge.source]
	var destination: Anatomy.Compartment = state.nodes[edge.destination]
	var ideal := minf(Anatomy.conductance(edge)*gate*maxf(0,pressure(source)-pressure(destination))*dt,Anatomy.capacity(edge)*dt)*1000.0+edge.remainder
	var candidate := floori(ideal)
	edge.remainder = ideal-candidate
	return candidate

func commit_candidate(state: Anatomy.Cultivator, edge: Anatomy.Edge, candidate: int, outflow: int, dt: int) -> void:
	var source: Anatomy.Compartment = state.nodes[edge.source]
	var destination: Anatomy.Compartment = state.nodes[edge.destination]
	var headroom := maxi(0,floori(destination.volume*destination.safe_pressure*1000)-total(destination)-destination.stored_quanta-destination.residue_quanta)
	var scale := minf(1,float(total(source))/maxi(1,outflow))
	scale = minf(scale,float(headroom)/maxi(1,candidate))
	var quantity := floori(candidate*scale)
	if quantity==0: return
	transfer_packet(source,destination,quantity)
	state.circulated += quantity
	edge.practice += quantity/1000.0
	edge.daily_flow += quantity
	edge.peak_rate = maxf(edge.peak_rate,quantity/1000.0/dt)

# Owner decision 2026-11-19: guided circulation. The cultivator uses the
# dantian's own pressure as a pump: every lane gains head h × p(dantian), so qi
# can climb back into a fuller dantian. Lanes leaving the dantian draw stored
# reserve as mobile qi (reserve and its moments debited atomically; residue
# never moves). Climbing against adverse pressure strains the channel.
static func circulation_law() -> Dictionary:
	if vocabulary.is_empty(): vocabulary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/operations.json"))
	return vocabulary.Circulate

func circulate_model(state: Anatomy.Cultivator, indices: Array, gate: float, elements: Array) -> void:
	if state.strain>.35: return
	var law := circulation_law()
	var head := float(law.head_per_dantian_pressure)*pressure(state.nodes[4])
	var uphill_strain := float(law.uphill_strain_per_QU)
	var candidates: Array = []
	var adverse: Array = []
	var outflows := {}
	var inflows := {}
	for index: int in indices:
		var edge: Anatomy.Edge = state.edges[index]
		var difference := pressure(state.nodes[edge.source])-pressure(state.nodes[edge.destination])
		var ideal := minf(Anatomy.conductance(edge)*gate*maxf(0,difference+head)*DT,Anatomy.capacity(edge)*DT)*1000.0+float(edge.remainder)
		var quantity := floori(ideal)
		edge.remainder = ideal-quantity
		candidates.append(quantity)
		adverse.append(maxf(0,-difference))
		outflows[edge.source] = int(outflows.get(edge.source,0))+quantity
		inflows[edge.destination] = int(inflows.get(edge.destination,0))+quantity
	# Withdraw only what the dantian lanes ask beyond the mobile packet already there.
	var dantian: Anatomy.Compartment = state.nodes[4]
	var withdrawal := mini(maxi(0,int(outflows.get(4,0))-total(dantian)),state.reserve)
	if withdrawal>0:
		var moments := [0.0,0.0,0.0,0.0]
		for q in 4:
			moments[q] = state.reserve_moments[q]*float(withdrawal)/state.reserve
			state.reserve_moments[q] -= moments[q]
		state.reserve -= withdrawal
		dantian.stored_quanta = state.reserve
		add(dantian,{"mass":split(withdrawal,elements),"moments":moments,"instability_moment":0.0})
	var packets: Array = []
	for i in indices.size():
		var edge: Anatomy.Edge = state.edges[int(indices[i])]
		var source: Anatomy.Compartment = state.nodes[edge.source]
		var destination: Anatomy.Compartment = state.nodes[edge.destination]
		var headroom := maxi(0,floori(destination.volume*destination.safe_pressure*1000)-total(destination)-destination.stored_quanta-destination.residue_quanta)
		var scale := minf(1,float(total(source))/maxi(1,int(outflows[edge.source])))
		scale = minf(scale,float(headroom)/maxi(1,int(inflows[edge.destination])))
		var quantity := floori(int(candidates[i])*scale)
		if quantity==0: continue
		packets.append({"destination":edge.destination,"packet":remove(source,quantity)})
		state.circulated += quantity
		edge.practice += quantity/1000.0
		edge.daily_flow += quantity
		edge.peak_rate = maxf(edge.peak_rate,quantity/1000.0/DT)
		if adverse[i]>0:
			edge.strain += uphill_strain*float(adverse[i])*quantity/1000.0
			state.strain = maxf(state.strain,edge.strain)
			state.max_strain = maxf(state.max_strain,edge.strain)
	for packet: Dictionary in packets: add(state.nodes[int(packet.destination)],packet.packet)

func process_model(state: Anatomy.Cultivator, indices: Array, operation: String, intensity: float) -> void:
	for index: int in indices:
		var node: Anatomy.Compartment = state.nodes[index]
		var limit: int = node.process_limit
		if limit<0:
			var connected := 0.0
			for edge: Anatomy.Edge in state.edges:
				if edge.source==index or edge.destination==index: connected += Anatomy.capacity(edge)
			limit = floori(connected*.7*DT*1000)
		var quantity := mini(total(node),limit)
		if quantity == 0: continue
		if use_fast_paths and quantity==total(node):
			process_whole(state,node,operation,intensity,quantity)
			continue
		var packet := remove(node,quantity)
		var remainder_key := "filter_remainder" if operation=="Filter" else "stabilise_remainder"
		var cost: float = quantity*(.15*intensity if operation=="Filter" else .02)+float(node[remainder_key])
		var loss := floori(cost)
		node[remainder_key] = cost-loss
		var retained := quantity-loss
		var purity := float(packet.moments[0])/quantity
		var corruption := float(packet.moments[3])/quantity
		if operation == "Filter":
			purity += .60*intensity*(1-purity)
			corruption *= 1.0-.70*intensity
		var stability := float(packet.moments[2])/quantity
		if operation == "Stabilise": stability = 1.0-(1-stability)*.60
		var moments := [retained*purity,packet.moments[1]*retained/quantity,retained*stability,retained*corruption]
		add(node,{"mass":split(retained,packet.mass),"moments":moments,"instability_moment":packet.instability_moment*retained/quantity*(.60 if operation=="Stabilise" else 1.0)})
		state.dissipated += quantity-retained

# Refinement commonly handles the entire small node packet. Preserve the same
# moment arithmetic, without allocating an intermediate node/packet pair.
func process_whole(state: Anatomy.Cultivator, node: Anatomy.Compartment, operation: String, intensity: float, quantity: int) -> void:
	var key := "filter_remainder" if operation=="Filter" else "stabilise_remainder"
	var cost: float = quantity*(.15*intensity if operation=="Filter" else .02)+float(node[key])
	var loss := floori(cost)
	node[key] = cost-loss
	var retained := quantity-loss
	var moments: Array = node.moments
	var packet := [0.0,0.0,0.0,0.0]
	for q in 4:
		packet[q] = moments[q]*float(quantity)/quantity
		moments[q] -= packet[q]
	var purity := float(packet[0])/quantity
	var corruption := float(packet[3])/quantity
	var stability := float(packet[2])/quantity
	if operation=="Filter":
		purity += .60*intensity*(1-purity)
		corruption *= 1.0-.70*intensity
	else: stability = 1.0-(1-stability)*.60
	var incoming := [retained*purity,packet[1]*retained/quantity,retained*stability,retained*corruption]
	if retained>0:
		for q in 4: moments[q] += float(incoming[q])
	var instability: float = node.instability_moment*float(quantity)/quantity
	node.instability_moment -= instability
	if retained>0: node.instability_moment += instability*retained/quantity*(.60 if operation=="Stabilise" else 1.0)
	node.mass = split(retained,node.mass).duplicate()
	node.quantity = retained
	node.hazard_valid = false
	state.dissipated += loss

func settle_model(state: Anatomy.Cultivator) -> void:
	var node: Anatomy.Compartment = state.nodes[4]
	var quantity := total(node)
	if quantity == 0: return
	var packet := remove(node,quantity)
	var purity: float = packet.moments[0]/quantity
	state.refined += quantity
	state.usable += quantity*purity
	state.purity_moment += packet.moments[0]
	state.instability_moment += float(packet.instability_moment)
	var opening_budget := mini(quantity,maxi(0,500000-int(state.opening_work)))
	var opening := refined_work_model(state,opening_budget,purity)
	state.opening_work += opening
	state.work += opening
	var remaining := quantity-opening_budget
	var stored := mini(remaining,maxi(0,int(state.capacity)-int(state.reserve)-int(state.residue)))
	state.reserve += stored
	for q in 4: state.reserve_moments[q] += packet.moments[q]*stored/quantity
	remaining -= stored
	state.pending_work += refined_work_model(state,remaining,purity)
	node.stored_quanta = state.reserve

# One saved fractional remainder across every work destination; integer inventory
# always partitions exactly, including opening and reserve integration.
func refined_work_model(state: Anatomy.Cultivator, quantity: int, purity: float) -> int:
	var exact := quantity*clampf(purity,0,1)+float(state.residue_remainder)
	var pure := mini(quantity,floori(exact))
	state.residue_remainder = exact-pure
	state.residue += quantity-pure
	state.residue_added += quantity-pure
	state.nodes[4].residue_quanta = state.residue
	state.nodes[4].hazard_valid = false
	return pure

func exposure_model(state: Anatomy.Cultivator, dt: int, _forced: bool) -> void:
	for node: Anatomy.Compartment in (state.nodes if state.exposure_nodes.is_empty() else state.exposure_nodes):
		var quantity := total(node)
		if quantity==0 and node.stored_quanta==0 and node.residue_quanta==0 and node.strain==0 and node.instability_moment<=.20:
			node.exposure_hours = 0.0
			continue
		if not node.hazard_valid:
			var p := (quantity+node.stored_quanta+node.residue_quanta)/1000.0/maxf(.000001,node.volume)
			var over := maxf(0,p/node.safe_pressure-1.0) if p>node.safe_pressure else 0.0
			var corruption := float(node.moments[3])/maxi(1,quantity) if node.moments[3]!=0 else 0.0
			var base := over*over
			# These margins only prove that the original max() returns exactly
			# zero; boundary cases still execute the full quality arithmetic.
			if not use_fast_paths or quantity==0 or node.moments[2]<quantity*.80000001 or node.instability_moment>quantity*.19999999:
				var instability := 1.0-float(node.moments[2])/maxi(1,quantity) if quantity>0 else 0.0
				instability = maxf(instability,float(node.instability_moment)/maxi(1,quantity))
				base += pow(maxf(0,instability-.20),2)
			if node.id == "dantian": base += pow(float(state.residue)/state.capacity,2)
			node.hazard_valid = true
			node.hazard_pressure = p
			node.hazard_base = base
			node.hazard_corruption = corruption
			node.hazard_occupied = quantity>0
			state.peak_pressure = maxf(state.peak_pressure,p)
			if quantity==0: node.exposure_hours = 0.0
		if not node.hazard_occupied and node.hazard_base==0 and node.hazard_corruption==0 and node.strain==0: continue
		node.exposure_hours = float(node.exposure_hours)+float(dt)/3600.0 if node.hazard_occupied else 0.0
		var danger: float = node.hazard_base+node.hazard_corruption*node.exposure_hours
		if danger==0 and node.strain==0: continue
		node.strain += danger*dt/3600.0
		var loss := .02*maxf(0,node.strain-.50)*dt/3600.0
		if loss>0 and node.integrity>=.8 and node.integrity-loss<.8: state.injuries += 1
		node.integrity = maxf(0,node.integrity-loss)
		node.scar += .10*maxf(0,loss-.01)
		state.max_strain = maxf(state.max_strain,node.strain)
		state.strain = maxf(state.strain,node.strain)
		if node.integrity <= 0 and state.deaths == 0: state.deaths = 1

# Once intake has stopped and every mobile packet has drained, no remaining
# instruction can move energy. Preserve the return valve's fractional rotation
# and the dantian's exact scalar strain recurrence, skipping empty graph work.
func finish_quiescent(state: Anatomy.Cultivator, instructions: Array, cycles: int) -> bool:
	var dantian: Anatomy.Compartment = state.nodes[4]
	if not dantian.hazard_valid or state.deaths>0: return false
	for node: Anatomy.Compartment in state.nodes:
		if total(node)!=0 or node.strain>.50 or node.integrity<=0 or node.instability_moment>.20 or node.exposure_hours!=0: return false
	var slices := 0
	var rotations: Array = []
	for op: Instruction in instructions:
		if op.code==0: continue # The strain stop skips Absorb, including exposure.
		slices += op.slices
		if op.code not in [1,2,3]: continue
		var gate := 1.0-clampf(op.error+.10,0,.60)
		for index: int in op.targets:
			var edge: Anatomy.Edge = state.edges[index]
			if edge.source!=4: continue
			var rate := minf(Anatomy.conductance(edge)*gate*maxf(0,pressure(dantian)-pressure(state.nodes[edge.destination]))*DT,Anatomy.capacity(edge)*DT)*1000.0
			rotations.append([edge,rate,op.slices])
	var increment := (dantian.hazard_base+dantian.hazard_corruption*0.0)*DT/3600.0
	# No integrity/scar threshold may be crossed by this shortcut. Near the
	# boundary the ordinary solver remains authoritative.
	if dantian.strain+increment*slices*cycles>=.499999: return false
	for cycle in cycles:
		for rotation: Array in rotations:
			var edge: Anatomy.Edge = rotation[0]
			for slice in int(rotation[2]):
				var ideal: float = float(rotation[1])+edge.remainder
				edge.remainder = ideal-floori(ideal)
	var strain := dantian.strain
	for slice in slices*cycles: strain += increment
	dantian.strain = strain
	state.strain = maxf(state.strain,strain)
	state.max_strain = maxf(state.max_strain,strain)
	quiescent_cycles += cycles
	return true

# Owner decision 2026-11-16: only a filled vessel is tempered.
# Keep the blocked storage allocation in its original reserve composition;
# it never enters refinement, residue production or irreversible work.
func enlargement_factor(fill: float) -> float:
	return clampf((fill-.60)/.30,0,1)

func storage_work_limit(state: Anatomy.Cultivator, peak_fill: float) -> int:
	return floori(state.capacity*.005*20.0*enlargement_factor(peak_fill))

func integration_draw(state: Anatomy.Cultivator, peak_fill: float) -> int:
	# Owner decision 2026-11-17: integrate half the reserve above the floor.
	var reserve_surplus := maxi(0,state.reserve-ceili(state.capacity*RESERVE_FLOOR))
	var draw := floori(reserve_surplus*float(Anatomy.definition().daily_reserve_integration_fraction))
	var old_limit := floori(state.capacity*.005*20.0)
	var purity := clampf(float(state.reserve_moments[0])/maxi(1,state.reserve),0,1)
	var pure := mini(draw,floori(draw*purity+state.residue_remainder))
	var available := state.pending_work+pure
	var blocked := mini(available,old_limit)-mini(available,storage_work_limit(state,peak_fill))
	# Retain the original mixed qi that would fund the rejected pure work.
	# Low funding below the gated ceiling is still fully usable. Choose the
	# integer draw producing the remaining pure work, using the saved remainder.
	if blocked<=0 or purity<=0: return draw
	var target := maxi(0,pure-blocked)
	var spent := clampi(ceili((target-state.residue_remainder)/purity),0,draw)
	if spent<draw and floori(spent*purity+state.residue_remainder)<target: spent+=1
	return spent

func simulate_day_model(state: Anatomy.Cultivator, program: Dictionary, sample: Dictionary, budget: int) -> void:
	state.day += 1
	var opening_refined: int = state.refined
	var peak_fill := float(state.reserve+state.residue)/maxi(1,state.capacity)
	var daily_peak_pressure := pressure(state.nodes[4])
	state.pending_work = 0
	state.strain = 0.0
	for edge: Anatomy.Edge in state.edges:
		edge.daily_flow = 0
		edge.peak_rate = 0.0
	for edge: Anatomy.Edge in state.edges:
		edge.cached_capacity = -1.0
		edge.cached_conductance = -1.0
		edge.cached_capacity = Anatomy.capacity(edge)
		edge.cached_conductance = Anatomy.conductance(edge)
	for index in state.nodes.size():
		var connected := 0.0
		for edge: Anatomy.Edge in state.edges:
			if edge.source==index or edge.destination==index: connected += Anatomy.capacity(edge)
		state.nodes[index].process_limit = floori(connected*.7*DT*1000)
	var config := Anatomy.definition()
	var control: float = config.control
	var base_error: float = .25*(1.0-float(config.operation_mastery))+.20*(1.0-float(config.understanding))+.15*float(config.emotional_disruption)-.10*control
	var instructions := compile_program(program,base_error)
	var used_nodes := []
	used_nodes.resize(state.nodes.size())
	used_nodes.fill(false)
	used_nodes[0] = true
	used_nodes[4] = true
	for op: Instruction in instructions:
		for index: int in op.targets:
			if op.code in [1,2,3,8]:
				used_nodes[state.edges[index].source] = true
				used_nodes[state.edges[index].destination] = true
			else: used_nodes[index] = true
	state.exposure_nodes.clear()
	for index in state.nodes.size():
		var node: Anatomy.Compartment = state.nodes[index]
		if used_nodes[index] or total(node)>0 or node.strain>0: state.exposure_nodes.append(node)
	var cycle_seconds := 0
	for op: Instruction in instructions: cycle_seconds += op.slices*DT
	var cycles: int = int(config.session_seconds)/maxi(DT,cycle_seconds)
	var admitted := 0
	var filter_intensity: float = program.filter
	var ambient_pressure := float(sample.density)/8.0
	var elements: Array = Array(sample.elements)
	var sample_purity: float = sample.purity
	var sample_polarity: float = sample.polarity
	var sample_stability: float = sample.stability
	var sample_corruption: float = sample.corruption
	for cycle in cycles:
		if use_fast_paths and state.strain>.35 and finish_quiescent(state,instructions,cycles-cycle): break
		for op: Instruction in instructions:
			for slice_index in op.slices:
				if state.deaths>0: break
				match op.code:
					0:
						var node: Anatomy.Compartment = state.nodes[0]
						var p := pressure(node)
						if p>=node.safe_pressure*.9 or state.strain>.35: continue
						var rate := minf(Anatomy.capacity(state.edges[0]),Anatomy.conductance(state.edges[0])*maxf(0,ambient_pressure-p))
						if state.strain>.20: rate *= .5
						var desired: float = rate*DT*1000+float(state.intake_remainder)
						state.intake_remainder = desired-floori(desired)
						var quantity := mini(budget-admitted,floori(desired))
						quantity = mini(quantity,maxi(0,floori((node.safe_pressure*.9-p)*node.volume*1000)))
						add(node,{"mass":split(quantity,elements),"moments":[quantity*sample_purity,quantity*sample_polarity,quantity*sample_stability,quantity*sample_corruption]})
						state.absorbed += quantity
						admitted += quantity
					1,2,3:
						var gate := 1.0-clampf(op.error+.10*minf(1,state.strain/.20),0,.60)
						if use_fast_paths and op.targets.size()==1: flow_single(state,int(op.targets[0]),DT,gate)
						else: flow_model(state,op.targets,false,DT,gate)
					4,5: process_model(state,op.targets,op.name,filter_intensity)
					6: settle_model(state)
					8: circulate_model(state,op.targets,1.0-clampf(op.error+.10*minf(1,state.strain/.20),0,.60),elements)
				var current_pressure := pressure(state.nodes[4])
				if current_pressure>=daily_peak_pressure:
					daily_peak_pressure = current_pressure
					peak_fill = float(state.reserve+state.residue)/maxi(1,state.capacity)
				exposure_model(state,DT,false)
	# The manual pays daily integration from its actual refined reserve. Stored
	# qi shares the dantian's volume and backpressure with incoming packets.
	var assigned_from_reserve := integration_draw(state,peak_fill)
	var reserve_purity: float = state.reserve_moments[0]/maxi(1,int(state.reserve))
	for q in 4: state.reserve_moments[q] *= float(state.reserve-assigned_from_reserve)/maxi(1,int(state.reserve))
	state.reserve -= assigned_from_reserve
	var remaining := int(state.pending_work)+refined_work_model(state,assigned_from_reserve,reserve_purity)
	var storage_work := mini(remaining,storage_work_limit(state,peak_fill))
	state.volume_work += storage_work
	state.work += storage_work
	state.capacity = int(config.initial_capacity_quanta)+int(state.volume_work)/20
	state.nodes[4].volume = state.capacity/1000.0/float(state.nodes[4].safe_pressure)
	remaining -= storage_work
	for edge: Anatomy.Edge in state.edges:
		var assigned := mini(2000,remaining) if edge.daily_flow>0 else 0
		remaining -= assigned
		edge.work += assigned
		state.work += assigned
		var u := float(edge.peak_rate)/maxf(.000001,Anatomy.capacity(edge))
		var stimulus := clampf((u-.25)/.35,0,1)*clampf((1.05-u)/.25,0,1)
		edge.adaptation += .001*stimulus*minf(1,assigned/2000.0)*(1-edge.adaptation/2)
	# Additional integration expenditure is irreversible work; adaptation remains capped.
	state.work += remaining
	state.edges[0].work += remaining
	state.pending_work = 0
	var stability: float = clampf(state.reserve_moments[2]/maxi(1,int(state.reserve)),0,1)
	var leakage: float = state.reserve*.002*(1.0-stability)+float(state.leak_remainder)
	var leak := floori(leakage)
	state.leak_remainder = leakage-leak
	for q in 4: state.reserve_moments[q] *= float(state.reserve-leak)/maxi(1,int(state.reserve))
	state.reserve -= leak
	state.nodes[4].stored_quanta = state.reserve
	state.dissipated += leak
	# Lodged residue continues exposing living tissue outside the four-hour
	# practice session. With no transfers, its danger is constant: integrate the
	# linear strain and the positive part of integrity loss analytically.
	var dantian: Anatomy.Compartment = state.nodes[4]
	var rest_hours := maxf(0,24.0-float(config.session_seconds)/3600.0)
	var residue_danger := pow(float(state.residue)/state.capacity,2)
	var initial_strain: float = dantian.strain
	var final_strain := initial_strain+residue_danger*rest_hours
	var damaging_hours := rest_hours if initial_strain>=.50 else maxf(0,rest_hours-(.50-initial_strain)/maxf(1e-30,residue_danger))
	var loss := .02*(maxf(0,initial_strain-.50)*damaging_hours+.5*residue_danger*damaging_hours*damaging_hours)
	if dantian.integrity>=.8 and dantian.integrity-loss<.8: state.injuries += 1
	dantian.integrity = maxf(0,dantian.integrity-loss)
	dantian.scar += .10*maxf(0,loss-.01)
	dantian.strain = final_strain
	state.strain = maxf(state.strain,final_strain)
	state.max_strain = maxf(state.max_strain,final_strain)
	if dantian.integrity<=0 and state.deaths==0: state.deaths = 1
	var purge_exact: float = state.residue*float(config.residue_purge_per_day)*state.purge_multiplier+state.purge_remainder
	var purge := mini(int(state.residue),floori(purge_exact))
	state.purge_remainder = purge_exact-floori(purge_exact)
	state.residue -= purge
	state.dissipated += purge
	state.nodes[4].residue_quanta = state.residue
	state.nodes[4].hazard_valid = false
	for layer in [3,6]:
		if state.reserve>0 and reserve_purity >= (.75 if layer==3 else .90) and not state.purity_checks.has(str(layer)):
			state.purity_checks[str(layer)] = state.day
	var healthy := true
	for edge: Anatomy.Edge in state.edges:
		if edge.strain>.20 or edge.integrity<.85: healthy=false
		edge.strain=maxf(0,edge.strain-.10)
		edge.integrity=minf(1,edge.integrity+.001)
	for node: Anatomy.Compartment in state.nodes:
		if node.strain>.20 or node.integrity<.85: healthy=false
		node.strain = maxf(0,node.strain-.10)
		node.integrity = minf(1,node.integrity+.001)
	if not healthy: state.recovery_days += 1
	if healthy and state.refined>opening_refined: state.settling_days += 1
	if state.opening_work>=500000 and state.settling_days>=30 and not state.milestones.has("retention"):
		if float(state.residue)/state.capacity>float(config.residue_wall): state.wall_days += 1
		elif healthy: state.milestones.retention = state.day

	for edge: Anatomy.Edge in state.edges:
		edge.cached_capacity = -1.0
		edge.cached_conductance = -1.0
	for node: Anatomy.Compartment in state.nodes: node.process_limit = -1

func residual_model(state: Anatomy.Cultivator) -> int:
	var inventory := 0
	for node: Anatomy.Compartment in state.nodes:
		for mass: int in node.mass: inventory += mass
	return int(state.absorbed)-int(state.reserve)-int(state.residue)-int(state.work)-int(state.dissipated)-int(state.grounded)-inventory

func clone_model(state: Anatomy.Cultivator) -> Anatomy.Cultivator:
	var values := state.as_dictionary()
	values.nodes = []
	values.edges = []
	for node: Anatomy.Compartment in state.nodes:
		values.nodes.append(Anatomy.Compartment.from_dictionary(node.as_dictionary().duplicate(true)))
	for edge: Anatomy.Edge in state.edges:
		values.edges.append(Anatomy.Edge.from_dictionary(edge.as_dictionary()))
	values.reserve_moments = state.reserve_moments.duplicate()
	values.milestones = state.milestones.duplicate()
	values.purity_checks = state.purity_checks.duplicate()
	# Foundation, retained instructions and choice history are read-only in a
	# simulated day; only mutable anatomy and current accounting need copies.
	return Anatomy.Cultivator.from_dictionary(values)

func serializable_state(state: Dictionary) -> Dictionary:
	var result := state.duplicate()
	result.nodes = []
	result.edges = []
	for node: Anatomy.Compartment in state.nodes: result.nodes.append(node.as_dictionary())
	for edge: Anatomy.Edge in state.edges: result.edges.append(edge.as_dictionary())
	return result

func clone_state(state: Dictionary) -> Dictionary:
	var result := serializable_state(state).duplicate(true)
	for i in result.nodes.size(): result.nodes[i] = Anatomy.Compartment.from_dictionary(result.nodes[i])
	for i in result.edges.size(): result.edges[i] = Anatomy.Edge.from_dictionary(result.edges[i])
	return result

func state_hash(state: Dictionary) -> String:
	return JSON.stringify(serializable_state(state)).sha256_text()

func advance_model(field: RefCounted, state: Anatomy.Cultivator, program: Dictionary, until: int, autonomous: bool = false) -> void:
	while state.day<until:
		var sample: Dictionary = field.sample(field.landmarks.Sect)
		if autonomous and not state.retained_program.is_empty():
			program = state.retained_program
		if autonomous and state.day%90==0:
			var traits: Dictionary = Anatomy.definition().personality
			var step := clampf(.02+.12*float(traits.curiosity)+.10*float(traits.restlessness)-.08*float(traits.fear),.01,.20)
			var accepted_strain := clampf(.10+.35*float(traits.ambition)+.25*float(traits.pride)-.30*float(traits.fear),.05,.60)
			var best := -INF
			var chosen := program
			for candidate: Dictionary in [program,manual("A"),manual("B"),manual(program.id,clampf(program.filter-step,0,1)),manual(program.id,clampf(program.filter+step,0,1))]:
				var trial := clone_model(state)
				simulate_day_model(trial,candidate,sample,int(sample.quantity))
				if trial.strain>accepted_strain: continue
				var score: float = trial.work-state.work-(trial.residue_added-state.residue_added)*float(traits.fear)-trial.strain*1000
				if score>best:
					best=score
					chosen=candidate
			state.choices.append({"day":state.day,"route":chosen.id,"filter":chosen.filter,"action":"retain" if chosen==program else "modify/select","reason":"one-day copied-state experiment: maximise permanent work, penalise residue by fear and current strain"})
			program=chosen
			state.retained_program = chosen
		var rollback := clone_model(state)
		var started := Time.get_ticks_usec()
		var opening_absorbed: int = state.absorbed
		var predicted := state
		simulate_day_model(predicted,program,sample,int(sample.quantity))
		simulation_usec += Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		var requested: int = predicted.absorbed-opening_absorbed
		field.request("cultivator",field.landmarks.Sect,PackedInt64Array(split(requested,Array(sample.elements))),0)
		field.advance(state.day)
		field_usec += Time.get_ticks_usec()-started
		var actual := 0
		for q: int in field.allocations.cultivator: actual += q
		if actual!=requested:
			predicted=rollback
			simulate_day_model(predicted,program,sample,actual)
		if predicted != state:
			for key: String in predicted.as_dictionary(): state.set(key,predicted.get(key))
		assert(residual_model(state)==0)
		assert(field.ledger.residual==0)

func safety(kind: String) -> Dictionary:
	var state := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	var node: Anatomy.Compartment = state.nodes[1]
	var fixture: Dictionary = Anatomy.definition().safety[kind]
	var initial := int(fixture.initial_quanta)
	node.mass[0]=initial
	node.moments=[float(initial),0.0,float(initial),0.0]
	state.peak_pressure = pressure(node)
	state.edges[8].integrity=float(fixture.ground_integrity)
	for second in 3600:
		flow_model(state,[8],false,1)
		exposure_model(state,1,true)
	return {"kind":kind,"peak_pressure":state.peak_pressure,"strain":node.strain,"integrity":node.integrity,"scar":node.scar,"failed_ground":1 if total(node)>0 and node.integrity<.8 else 0,"grounded":state.grounded/1000.0,"remaining":total(node)/1000.0,"residual":initial-state.grounded-total(node),"deaths":state.deaths,"injury":node.integrity<1.0}

func sync_state(state: Dictionary, model: Anatomy.Cultivator) -> void:
	state.clear()
	state.merge(model.as_dictionary())

func flow(state: Dictionary, indices: Array, forced: bool = false, dt: int = DT, gate: float = 1.0) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	flow_model(model,indices,forced,dt,gate)
	sync_state(state,model)

func process(state: Dictionary, indices: Array, operation: String, intensity: float) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	process_model(model,indices,operation,intensity)
	sync_state(state,model)

func settle(state: Dictionary) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	settle_model(model)
	sync_state(state,model)

func refined_work(state: Dictionary, quantity: int, purity: float) -> int:
	var model := Anatomy.Cultivator.from_dictionary(state)
	var result := refined_work_model(model,quantity,purity)
	sync_state(state,model)
	return result

func exposure(state: Dictionary, dt: int, forced: bool) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	exposure_model(model,dt,forced)
	sync_state(state,model)

func simulate_day(state: Dictionary, program: Dictionary, sample: Dictionary, budget: int) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	simulate_day_model(model,program,sample,budget)
	sync_state(state,model)

func residual(state: Dictionary) -> int:
	return residual_model(Anatomy.Cultivator.from_dictionary(state))

func advance(field: RefCounted, state: Dictionary, program: Dictionary, until: int, autonomous: bool = false) -> void:
	var model := Anatomy.Cultivator.from_dictionary(state)
	advance_model(field,model,program,until,autonomous)
	sync_state(state,model)
