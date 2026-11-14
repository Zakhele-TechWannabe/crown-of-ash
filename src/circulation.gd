extends RefCounted
## Integer-energy, persistent-node reference solver. Each Guide phase takes its
## candidates from one opening snapshot and commits together. No scene dependencies.
const Anatomy = preload("res://src/meridians.gd")
const Field = preload("res://src/qi_field.gd")
const DT := 10

static func manual(name: String, filter_override: float = -1.0) -> Dictionary:
	var vocabulary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/operations.json"))
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

static func total(node: Dictionary) -> int:
	var sum := 0
	for mass: int in node.mass: sum += mass
	return sum

static func pressure(node: Dictionary) -> float:
	return (total(node)+int(node.get("stored_quanta",0)))/1000.0/maxf(.000001,node.volume)

static func split(quantity: int, weights: Array) -> Array:
	var result := [0,0,0,0,0]
	var sum := 0
	for weight: int in weights: sum += weight
	if sum == 0: return result
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
	return result

static func interference(mass: Array) -> float:
	var quantity := 0
	for value: int in mass: quantity += value
	if quantity==0: return 0.0
	var opposing := 0
	for pair: Array in [[0,1],[1,4],[4,2],[2,3],[3,0]]:
		opposing = maxi(opposing,mini(int(mass[pair[0]]),int(mass[pair[1]])))
	return .40*opposing/quantity

static func remove(node: Dictionary, quantity: int) -> Dictionary:
	var opening := total(node)
	quantity = mini(quantity,opening)
	var mass := split(quantity,node.mass)
	var moments := [0.0,0.0,0.0,0.0]
	for e in 5: node.mass[e] -= int(mass[e])
	for q in 4:
		moments[q] = node.moments[q]*float(quantity)/maxi(1,opening)
		node.moments[q] -= moments[q]
	var instability: float = node.instability_moment*float(quantity)/maxi(1,opening)
	node.instability_moment -= instability
	return {"mass":mass,"moments":moments,"instability_moment":instability}

static func add(node: Dictionary, packet: Dictionary) -> void:
	var incoming := 0
	for value: int in packet.mass: incoming += value
	if incoming==0: return
	var before := total(node)
	var unmixed: float = interference(node.mass)*before+interference(packet.mass)*incoming
	for e in 5: node.mass[e] += int(packet.mass[e])
	for q in 4: node.moments[q] += float(packet.moments[q])
	# Preserve prior stabilisation; only newly mixed opposing fractions add interference.
	node.instability_moment += float(packet.get("instability_moment",interference(packet.mass)*incoming))
	node.instability_moment += maxf(0,interference(node.mass)*(before+incoming)-unmixed)

static func flow(state: Dictionary, indices: Array, forced: bool = false, dt: int = DT, gate: float = 1.0) -> void:
	if forced and dt>1:
		for second in dt: flow(state,indices,true,1,gate)
		return
	indices = indices.duplicate()
	indices.sort()
	var candidates: Array = []
	var outflows := [0,0,0,0,0,0,0,0]
	var inflows := [0,0,0,0,0,0,0,0]
	for index: int in indices:
		var edge: Dictionary = state.edges[index]
		var source: Dictionary = state.nodes[int(edge.source)]
		var destination: Dictionary = state.nodes[int(edge.destination)]
		var ideal := minf(Anatomy.conductance(edge)*gate*maxf(0,pressure(source)-pressure(destination))*dt,Anatomy.capacity(edge)*dt*(2.0 if forced else 1.0))*1000.0+float(edge.remainder)
		var quantity := floori(ideal)
		edge.remainder = ideal-quantity
		candidates.append(quantity)
		outflows[int(edge.source)] += quantity
		inflows[int(edge.destination)] += quantity
	var packets: Array = []
	for i in indices.size():
		var edge: Dictionary = state.edges[int(indices[i])]
		var source: Dictionary = state.nodes[int(edge.source)]
		var destination: Dictionary = state.nodes[int(edge.destination)]
		var available := total(source)
		var headroom := maxi(0,floori(destination.volume*destination.safe_pressure*1000)-total(destination)-int(destination.get("stored_quanta",0)))
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

static func process(state: Dictionary, indices: Array, operation: String, intensity: float) -> void:
	for index: int in indices:
		var node: Dictionary = state.nodes[index]
		var connected := 0.0
		for edge: Dictionary in state.edges:
			if int(edge.source)==index or int(edge.destination)==index: connected += Anatomy.capacity(edge)
		var quantity := mini(total(node),floori(connected*.7*DT*1000))
		if quantity == 0: continue
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

static func settle(state: Dictionary) -> void:
	var node: Dictionary = state.nodes[4]
	var quantity := total(node)
	if quantity == 0: return
	var packet := remove(node,quantity)
	var purity: float = packet.moments[0]/quantity
	state.refined += quantity
	state.usable += quantity*purity
	state.purity_moment += packet.moments[0]
	state.instability_moment += float(packet.instability_moment)
	var opening := mini(quantity,maxi(0,500000-int(state.opening_work)))
	state.opening_work += opening
	state.work += opening
	var remaining := quantity-opening
	# Reserve first, then a declared integration budget. No double credit.
	var stored := mini(remaining,maxi(0,int(state.capacity)-int(state.reserve)))
	state.reserve += stored
	node.stored_quanta = state.reserve
	for q in 4: state.reserve_moments[q] += packet.moments[q]*stored/quantity
	remaining -= stored
	state.pending_work += remaining

static func exposure(state: Dictionary, dt: int, _forced: bool) -> void:
	for node: Dictionary in state.nodes:
		var p := pressure(node)
		state.peak_pressure = maxf(state.peak_pressure,p)
		var over := maxf(0,p/node.safe_pressure-1.0)
		var corruption := float(node.moments[3])/maxi(1,total(node))
		var instability := 1.0-float(node.moments[2])/maxi(1,total(node)) if total(node)>0 else 0.0
		node.exposure_hours = float(node.exposure_hours)+float(dt)/3600.0 if total(node)>0 else 0.0
		instability = maxf(instability,float(node.instability_moment)/maxi(1,total(node)))
		var danger := over*over+corruption*float(node.exposure_hours)+pow(maxf(0,instability-.20),2)
		node.strain += danger*dt/3600.0
		var loss := .02*maxf(0,node.strain-.50)*dt/3600.0
		if loss>0 and node.integrity>=.8 and node.integrity-loss<.8: state.injuries += 1
		node.integrity = maxf(0,node.integrity-loss)
		node.scar += .10*maxf(0,loss-.01)
		state.max_strain = maxf(state.max_strain,node.strain)
		state.strain = maxf(state.strain,node.strain)
		if node.integrity <= 0 and state.deaths == 0: state.deaths = 1

static func simulate_day(state: Dictionary, program: Dictionary, sample: Dictionary, budget: int) -> void:
	state.day += 1
	var opening_refined: int = state.refined
	state.pending_work = 0
	state.strain = 0.0
	for edge: Dictionary in state.edges:
		edge.daily_flow = 0
		edge.peak_rate = 0.0
	var config := Anatomy.definition()
	var control: float = config.control
	var base_error: float = .25*(1.0-float(config.operation_mastery))+.20*(1.0-float(config.understanding))+.15*float(config.emotional_disruption)-.10*control
	var cycle_seconds := 0
	for instruction: Dictionary in program.operations:
		assert(int(instruction.duration)>=DT and int(instruction.duration)%DT==0, "Operations use the fixed ten-second grid")
		assert(instruction.targets.size()<=4, "At most four concurrent lanes")
		cycle_seconds += int(instruction.duration)
	var cycles: int = int(config.session_seconds)/maxi(DT,cycle_seconds)
	var admitted := 0
	assert(program.operations.size()<=32)
	for instruction: Dictionary in program.operations:
		assert(instruction.operation in ["Absorb","Guide","Split","Merge","Ground","Filter","Stabilise","Integrate"], "Unsupported operation")
	for cycle in cycles:
		for op: Dictionary in program.operations:
			for slice_index in int(op.duration)/DT:
				if state.deaths>0: break
				match str(op.operation):
					"Absorb":
						var node: Dictionary = state.nodes[0]
						var p := pressure(node)
						if p>=node.safe_pressure*.9 or state.strain>.35: continue
						var rate := minf(Anatomy.capacity(state.edges[0]),Anatomy.conductance(state.edges[0])*maxf(0,float(sample.density)/8.0-p))
						if state.strain>.20: rate *= .5
						var desired: float = rate*DT*1000+float(state.intake_remainder)
						state.intake_remainder = desired-floori(desired)
						var quantity := mini(budget-admitted,floori(desired))
						quantity = mini(quantity,maxi(0,floori((node.safe_pressure*.9-p)*node.volume*1000)))
						var moments: Array = []
						for key in ["purity","polarity","stability","corruption"]: moments.append(quantity*float(sample[key]))
						add(node,{"mass":split(quantity,Array(sample.elements)),"moments":moments})
						state.absorbed += quantity
						admitted += quantity
					"Guide","Split","Ground": flow(state,op.targets,false,DT,1.0-clampf(base_error+.10*maxf(0,float(op.control_demand)-1.0)+.10*minf(1,state.strain/.20),0,.60))
					"Filter","Stabilise": process(state,op.targets,op.operation,program.filter)
					"Integrate": settle(state)
				exposure(state,DT,false)
	# The manual pays daily integration from its actual refined reserve. Stored
	# qi shares the dantian's volume and backpressure with incoming packets.
	var assigned_from_reserve := floori(state.reserve*float(config.daily_reserve_integration_fraction))
	for q in 4: state.reserve_moments[q] *= float(state.reserve-assigned_from_reserve)/maxi(1,int(state.reserve))
	state.reserve -= assigned_from_reserve
	var remaining := int(state.pending_work)+assigned_from_reserve
	var storage_work := mini(remaining, floori(state.capacity*.005*20.0))
	state.volume_work += storage_work
	state.work += storage_work
	state.capacity = int(config.initial_capacity_quanta)+int(state.volume_work)/20
	state.nodes[4].volume = state.capacity/1000.0/float(state.nodes[4].safe_pressure)
	remaining -= storage_work
	for edge: Dictionary in state.edges:
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
	var healthy := true
	for edge: Dictionary in state.edges:
		if edge.strain>.20 or edge.integrity<.85: healthy=false
		edge.strain=maxf(0,edge.strain-.10)
		edge.integrity=minf(1,edge.integrity+.001)
	for node: Dictionary in state.nodes:
		if node.strain>.20 or node.integrity<.85: healthy=false
		node.strain = maxf(0,node.strain-.10)
		node.integrity = minf(1,node.integrity+.001)
	if not healthy: state.recovery_days += 1
	if healthy and state.refined>opening_refined: state.settling_days += 1
	if state.opening_work>=500000 and state.settling_days>=30 and not state.milestones.has("retention"): state.milestones.retention = state.day

static func residual(state: Dictionary) -> int:
	var inventory := 0
	for node: Dictionary in state.nodes: inventory += total(node)
	return int(state.absorbed)-int(state.reserve)-int(state.work)-int(state.dissipated)-int(state.grounded)-inventory

static func state_hash(state: Dictionary) -> String:
	return JSON.stringify(state).sha256_text()

static func advance(field: RefCounted, state: Dictionary, program: Dictionary, until: int, autonomous: bool = false) -> void:
	while state.day<until:
		var sample: Dictionary = field.sample(field.landmarks.Sect)
		if autonomous and state.has("retained_program"):
			program = state.retained_program
		if autonomous and state.day%90==0:
			var traits: Dictionary = Anatomy.definition().personality
			var step := clampf(.02+.12*float(traits.curiosity)+.10*float(traits.restlessness)-.08*float(traits.fear),.01,.20)
			var accepted_strain := clampf(.10+.35*float(traits.ambition)+.25*float(traits.pride)-.30*float(traits.fear),.05,.60)
			var best := -INF
			var chosen := program
			for candidate: Dictionary in [program,manual("A"),manual("B"),manual(program.id,clampf(program.filter-step,0,1)),manual(program.id,clampf(program.filter+step,0,1))]:
				var trial := state.duplicate(true)
				simulate_day(trial,candidate,sample,int(sample.quantity))
				if trial.max_strain>accepted_strain: continue
				var score: float = trial.usable-state.usable-(trial.max_strain-state.max_strain)*1000
				if score>best:
					best=score
					chosen=candidate
			state.choices.append({"day":state.day,"route":chosen.id,"filter":chosen.filter,"action":"retain" if chosen==program else "modify/select","reason":"one-day copied-state experiment: maximise delivered pure qi, penalise added strain"})
			program=chosen
			state.retained_program = chosen
		var predicted := state.duplicate(true)
		simulate_day(predicted,program,sample,int(sample.quantity))
		var requested: int = predicted.absorbed-state.absorbed
		field.request("cultivator",field.landmarks.Sect,PackedInt64Array(split(requested,Array(sample.elements))),0)
		field.advance(state.day+1)
		var actual := 0
		for q: int in field.allocations.cultivator: actual += q
		if actual!=requested:
			predicted=state.duplicate(true)
			simulate_day(predicted,program,sample,actual)
		state.clear()
		state.merge(predicted,true)
		assert(residual(state)==0)
		assert(field.ledger.residual==0)

static func safety(kind: String) -> Dictionary:
	var state := Anatomy.create()
	var node: Dictionary = state.nodes[1]
	var fixture: Dictionary = Anatomy.definition().safety[kind]
	var initial := int(fixture.initial_quanta)
	node.mass[0]=initial
	node.moments=[float(initial),0.0,float(initial),0.0]
	state.peak_pressure = pressure(node)
	state.edges[8].integrity=float(fixture.ground_integrity)
	for second in 3600:
		flow(state,[8],false,1)
		exposure(state,1,true)
	return {"kind":kind,"peak_pressure":state.peak_pressure,"strain":node.strain,"integrity":node.integrity,"scar":node.scar,"failed_ground":1 if total(node)>0 and node.integrity<.8 else 0,"grounded":state.grounded/1000.0,"remaining":total(node)/1000.0,"residual":initial-state.grounded-total(node),"deaths":state.deaths,"injury":node.integrity<1.0}
