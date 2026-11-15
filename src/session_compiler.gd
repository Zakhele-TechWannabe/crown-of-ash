extends RefCounted
## Experimental lumped periodic-network executor. Not connected to Society.
## Energy boundaries use integer quanta; the periodic flow solve uses floats.
const Anatomy = preload("res://src/meridians.gd")
const Reference = preload("res://src/circulation.gd")
const Store = preload("res://src/meridian_store.gd")
var accounting := Reference.new()
var routes: Dictionary = {}
var cache_hits := 0
var cache_misses := 0
var day_hits := 0
var day_misses := 0
var coefficient_usec := 0
var identity := get_instance_id()
var initial_capacity := int(Anatomy.definition().initial_capacity_quanta)
const REFRESH_DAYS := 30

const BINS := 24
const RELAX := 96
const STEPS := 4

class Network extends RefCounted:
	var build_usec := 0
	var healthy := true
	var instructions: Array = []
	var capacity := PackedFloat64Array()
	var conductance := PackedFloat64Array()
	var volume := PackedFloat64Array()
	var safe := PackedFloat64Array()
	var source := PackedInt32Array()
	var destination := PackedInt32Array()
	var tables: Dictionary = {}
	var program: Dictionary
	var sample: Dictionary
	var used_edges := PackedInt32Array()
	var cycles: int
	var pressure_limit: float
	var seconds: float

## A revision is scoped to one body; route content and sample are also keyed.
## Caller must invalidate/revise after structural changes or sample changes.
func compile(state: Anatomy.Cultivator, program: Dictionary, sample: Dictionary, revision: int = 0) -> Network:
	var signature: Array = [program, sample, revision+state.session_revision]
	for edge: Anatomy.Edge in state.edges:
		signature.append([edge.source,edge.destination,edge.capacity,edge.conductivity,edge.openness,edge.integrity,edge.scar,edge.adaptation])
	for node: Anatomy.Compartment in state.nodes: signature.append([node.volume if node.id!="dantian" else 0.0,node.safe_pressure])
	var key := JSON.stringify(signature)
	if routes.has(key):
		cache_hits += 1
		return routes[key]
	cache_misses += 1
	var net := Network.new()
	net.program = program.duplicate(true)
	net.sample = sample.duplicate(true)
	var config := Anatomy.definition()
	var error: float = .25*(1.0-float(config.operation_mastery))+.20*(1.0-float(config.understanding))+.15*float(config.emotional_disruption)-.10*float(config.control)
	net.instructions = accounting.compile_program(program,error)
	for op: Reference.Instruction in net.instructions:
		if op.code in [1,2,3]:
			for index: int in op.targets:
				if not net.used_edges.has(index): net.used_edges.append(index)
	net.used_edges.sort()
	for edge: Anatomy.Edge in state.edges:
		if edge.strain>0 or edge.integrity<1: net.healthy = false
		net.capacity.append(Anatomy.capacity(edge))
		net.conductance.append(Anatomy.conductance(edge))
		net.source.append(edge.source)
		net.destination.append(edge.destination)
	for node: Anatomy.Compartment in state.nodes:
		if node.strain>0 or node.integrity<1: net.healthy = false
		net.volume.append(node.volume)
		net.safe.append(node.safe_pressure)
	for op: Reference.Instruction in net.instructions: net.seconds += op.slices*10.0
	net.cycles = int(config.session_seconds/net.seconds)
	net.pressure_limit = minf(net.safe[4],float(sample.density)/8.0)

	# Keep compilation memory bounded. Networks already held by callers survive eviction.
	if routes.size()>=128: routes.clear()
	routes[key] = net
	return net

func table(net: Network, bin: int) -> PackedFloat64Array:
	if not net.tables.has(bin):
		var started := Time.get_ticks_usec()
		net.tables[bin] = periodic(net,net.program,net.sample,net.pressure_limit*float(bin)/BINS)
		var elapsed := Time.get_ticks_usec()-started
		net.build_usec += elapsed
		coefficient_usec += elapsed
	return net.tables[bin]

class EdgeDelta extends RefCounted:
	var flow: int
	var peak: float
	var practice: float
	var work: int
	var adaptation: float
	var strain: float
	var integrity: float
	var scar: float

class DayMemo extends RefCounted:
	var network: Network
	var signature: Array
	var age := 0
	var horizon := 0
	var d_absorbed: int
	var d_circulated: int
	var d_refined: int
	var d_usable: float
	var d_dissipated: int
	var d_grounded: int
	var d_work: int
	var d_opening_work: int
	var d_volume_work: int
	var d_residue: int
	var d_residue_added: int
	var d_reserve: int
	var d_purity_moment: float
	var d_instability_moment: float
	var d_recovery_days: int
	var d_settling_days: int
	var d_wall_days: int
	var remainders: Array = []
	var moments: Array = []
	var edges: Array = []
	var node_delta: Array = []
	var strain: float
	var pressure: float
	var initial_strain: float
	var revision := 0
	var input_network := 0
	var check_events := true
	var reserve_anchor := -1.0
	var residue_anchor := -1.0
	var reserve_bucket := 0
	var residue_bucket := 0
	var indices := PackedInt32Array()

# External anatomical edits must call invalidate (or use set_edge_capacity).
# Injury and 0.05 adaptation thresholds invalidate automatically. Storage growth
# is continuous bookkeeping; its pressure is included in the input buckets.
func invalidate(state: Anatomy.Cultivator) -> void:
	state.session_revision += 1

func set_edge_capacity(state: Anatomy.Cultivator, index: int, capacity: float) -> void:
	if state.edges[index].capacity!=capacity:
		state.edges[index].capacity = capacity
		invalidate(state)

func input_signature(state: Anatomy.Cultivator, net: Network, budget: int, memo: DayMemo) -> Array:
	var reserve_ratio := float(state.reserve)/state.capacity
	var residue_ratio := float(state.residue)/state.capacity
	if absf(reserve_ratio-memo.reserve_anchor)>.01:
		memo.reserve_anchor = reserve_ratio
		memo.reserve_bucket += 1
	if absf(residue_ratio-memo.residue_anchor)>.001:
		memo.residue_anchor = residue_ratio
		memo.residue_bucket += 1
	return [net.get_instance_id(),state.session_revision,budget,memo.residue_bucket,memo.reserve_bucket,floori(state.nodes[4].strain*500),state.purge_multiplier,state.opening_work>=500000,floori(10000*state.reserve_moments[0]/maxi(1,state.reserve)),roundi(10000*state.reserve_moments[2]/maxi(1,state.reserve))]

func step(state: Anatomy.Cultivator, net: Network, budget: int) -> void:
	var memo: DayMemo = state.session_cache if state.session_cache_owner==identity else null
	if memo==null:
		memo = DayMemo.new()
		state.session_cache = memo
		state.session_cache_owner = identity

	if memo.input_network!=net.get_instance_id():
		memo.input_network = net.get_instance_id()
		memo.network = net
		memo.revision = state.session_revision
	elif memo.revision!=state.session_revision:
		memo.network = compile(state,net.program,net.sample,state.session_revision)
		memo.revision = state.session_revision
	var effective := memo.network
	var signature := input_signature(state,net,budget,memo)

	if memo.signature==signature and memo.age<memo.horizon:
		day_hits += 1
		memo.age += 1
		replay_day(state,memo)
		return
	day_misses += 1
	memo.signature = signature
	memo.age = 0
	var before: Array = [state.absorbed,state.circulated,state.refined,state.usable,state.dissipated,state.grounded,state.work,state.opening_work,state.volume_work,state.residue,state.residue_added,state.reserve,state.purity_moment,state.instability_moment,state.recovery_days,state.settling_days,state.wall_days]
	var node: Anatomy.Compartment = state.nodes[4]
	var before_node := [node.strain,node.integrity,node.scar]
	memo.initial_strain = node.strain
	var before_edges: Array = []
	memo.indices = effective.used_edges
	for index: int in memo.indices:
		var edge: Anatomy.Edge = state.edges[index]
		before_edges.append([edge.daily_flow,edge.peak_rate,edge.practice,edge.work,edge.adaptation,edge.strain,edge.integrity,edge.scar])

	solve_day(state,effective,budget)

	if state.injuries>0 and node.integrity!=before_node[1]: invalidate(state)
	memo.d_absorbed = state.absorbed-before[0]
	memo.d_circulated = state.circulated-before[1]
	memo.d_refined = state.refined-before[2]
	memo.d_usable = state.usable-before[3]
	memo.d_dissipated = state.dissipated-before[4]
	memo.d_grounded = state.grounded-before[5]
	memo.d_work = state.work-before[6]
	memo.d_opening_work = state.opening_work-before[7]
	memo.d_volume_work = state.volume_work-before[8]
	memo.d_residue = state.residue-before[9]
	memo.d_residue_added = state.residue_added-before[10]
	memo.d_reserve = state.reserve-before[11]
	memo.d_purity_moment = state.purity_moment-before[12]
	memo.d_instability_moment = state.instability_moment-before[13]
	memo.d_recovery_days = state.recovery_days-before[14]
	memo.d_settling_days = state.settling_days-before[15]
	memo.d_wall_days = state.wall_days-before[16]
	memo.remainders = [state.intake_remainder,state.leak_remainder,state.residue_remainder,state.purge_remainder]
	memo.moments.clear()
	for q in 4: memo.moments.append(state.reserve_moments[q]/maxi(1,state.reserve))
	memo.node_delta = [node.strain-before_node[0],node.integrity-before_node[1],node.scar-before_node[2]]
	memo.check_events = not state.milestones.has("retention") or state.purity_checks.size()<2
	memo.strain = state.strain
	memo.pressure = state.peak_pressure
	memo.edges.clear()
	for i in memo.indices.size():
		var edge: Anatomy.Edge = state.edges[memo.indices[i]]
		var previous: Array = before_edges[i]
		var change := EdgeDelta.new()
		if (edge.adaptation!=previous[4] and floori(edge.adaptation*20)!=floori(float(previous[4])*20)) or edge.integrity!=previous[6]: invalidate(state)
		change.flow = edge.daily_flow
		change.peak = edge.peak_rate
		change.practice = edge.practice-previous[2]
		change.work = edge.work-previous[3]
		change.adaptation = edge.adaptation-previous[4]
		change.strain = edge.strain-previous[5]
		change.integrity = edge.integrity-previous[6]
		change.scar = edge.scar-previous[7]
		memo.edges.append(change)
	set_horizon(state,memo)
	# A damaged inactive compartment must heal through the solver, too.
	if not effective.healthy or state.injuries>0: memo.horizon = 0

func set_horizon(state: Anatomy.Cultivator, memo: DayMemo) -> void:
	memo.horizon = REFRESH_DAYS-1
	if absf(memo.d_reserve)>maxi(2,state.reserve/600) or absf(memo.strain-.10)<=.005 or absf(memo.strain-.20)<=.005:
		memo.horizon = 0
	if state.opening_work<500000 and memo.d_opening_work>0:
		memo.horizon = mini(memo.horizon,maxi(0,(500000-state.opening_work-1)/memo.d_opening_work))
	if memo.d_reserve<0: memo.horizon = mini(memo.horizon,state.reserve/-memo.d_reserve)
	if memo.d_residue<0: memo.horizon = mini(memo.horizon,state.residue/-memo.d_residue)
	for i in memo.indices.size():
		var change: EdgeDelta = memo.edges[i]
		if change.adaptation>0:
			var adaptation: float = state.edges[memo.indices[i]].adaptation
			var next := (floori(adaptation*20)+1)/20.0
			memo.horizon = mini(memo.horizon,maxi(0,floori((next-adaptation)/change.adaptation)))

func replay_day(state: Anatomy.Cultivator, memo: DayMemo) -> void:
	state.day += 1
	state.absorbed += memo.d_absorbed
	state.circulated += memo.d_circulated
	state.refined += memo.d_refined
	state.usable += memo.d_usable
	state.dissipated += memo.d_dissipated
	if memo.d_grounded!=0: state.grounded += memo.d_grounded
	state.work += memo.d_work
	if memo.d_opening_work!=0: state.opening_work += memo.d_opening_work
	state.volume_work += memo.d_volume_work
	state.residue += memo.d_residue
	state.residue_added += memo.d_residue_added
	state.reserve += memo.d_reserve
	state.purity_moment += memo.d_purity_moment
	if memo.d_instability_moment!=0: state.instability_moment += memo.d_instability_moment
	if memo.d_recovery_days!=0: state.recovery_days += memo.d_recovery_days
	state.settling_days += memo.d_settling_days
	if memo.d_wall_days!=0: state.wall_days += memo.d_wall_days
	state.intake_remainder = memo.remainders[0]
	state.leak_remainder = memo.remainders[1]
	state.residue_remainder = memo.remainders[2]
	state.purge_remainder = memo.remainders[3]
	for q in 4: state.reserve_moments[q] = state.reserve*memo.moments[q]
	state.capacity = initial_capacity+state.volume_work/20
	var node: Anatomy.Compartment = state.nodes[4]
	node.volume = state.capacity/1000.0/node.safe_pressure
	var initial := node.strain
	if memo.node_delta[0]!=0: node.strain = maxf(0,node.strain+memo.node_delta[0])
	if memo.node_delta[1]!=0: node.integrity = clampf(node.integrity+memo.node_delta[1],0,1)
	if memo.node_delta[2]!=0: node.scar += memo.node_delta[2]
	node.stored_quanta = state.reserve
	node.residue_quanta = state.residue
	node.hazard_valid = false
	state.strain = maxf(0,memo.strain+initial-memo.initial_strain)
	state.max_strain = maxf(state.max_strain,state.strain)
	state.peak_pressure = maxf(state.peak_pressure,memo.pressure)
	# Daily flow/peak already equal the cached absolute values. Route/revision
	# changes run solve_day, resetting them; only cumulative edge fields add here.
	for i in memo.indices.size():
		var edge: Anatomy.Edge = state.edges[memo.indices[i]]
		var change: EdgeDelta = memo.edges[i]
		edge.practice += change.practice
		if change.work!=0: edge.work += change.work
		if change.adaptation!=0:
			var band := floori(edge.adaptation*20)
			edge.adaptation += change.adaptation
			if floori(edge.adaptation*20)!=band: invalidate(state)
		if change.strain!=0: edge.strain += change.strain
		if change.integrity!=0: edge.integrity += change.integrity
		if change.scar!=0: edge.scar += change.scar
	if not memo.check_events: return
	# Date-valued events are evaluated against today's state, never replayed as
	# absolute dates from the cached solve.
	var purity: float = state.reserve_moments[0]/maxi(1,state.reserve)
	for layer in [3,6]:
		if state.reserve>0 and purity>=(.75 if layer==3 else .90) and not state.purity_checks.has(str(layer)):
			state.purity_checks[str(layer)] = state.day
	if state.opening_work>=500000 and state.settling_days>=30 and not state.milestones.has("retention"):
		if float(state.residue)/state.capacity<=float(Anatomy.definition().residue_wall) and state.strain<=.20:
			state.milestones.retention = state.day

## Compilation is explicit so benchmark includes execution without serialization.
func solve_day(state: Anatomy.Cultivator, net: Network, budget: int) -> void:
	state.day += 1
	var opening_refined := state.refined
	state.pending_work = 0
	state.strain = 0
	var remaining_budget := budget
	# Refine time only where lodged residue can approach the recovery threshold.
	var phases := STEPS if float(state.residue)/state.capacity>.025 or state.nodes[4].strain>0 else 1
	for edge: Anatomy.Edge in state.edges:
		edge.daily_flow = 0
		edge.peak_rate = 0
	for phase in phases:
		var opening_residue := state.residue
		var pressure_ratio := clampf(float(state.reserve+state.residue)/maxi(1,state.capacity),0,1)
		var position := clampf(pressure_ratio*net.safe[4]/maxf(1e-30,net.pressure_limit),0,1)*BINS
		var lo := mini(BINS-1,floori(position))
		var weight := position-lo
		var a := table(net,lo)
		var b := table(net,lo+1)
		var delivery := (a[1]*(1-weight)+b[1]*weight)*net.cycles*1000/phases
		var admission := (a[0]*(1-weight)+b[0]*weight)*net.cycles*1000/phases
		var factor := minf(1,float(maxi(0,remaining_budget))/maxf(1,admission))
		if state.deaths>0 or state.strain>.35: factor = 0
		elif state.strain>.20: factor *= .5
		var admitted := floori(admission*factor+state.intake_remainder)
		state.intake_remainder = admission*factor+state.intake_remainder-admitted
		var settled := mini(admitted,floori(delivery*factor))
		var purity := (a[2]*(1-weight)+b[2]*weight)/maxf(1e-30,a[1]*(1-weight)+b[1]*weight)
		var settled_stability := (a[3]*(1-weight)+b[3]*weight)/maxf(1e-30,a[1]*(1-weight)+b[1]*weight)
		var corruption := (a[4]*(1-weight)+b[4]*weight)/maxf(1e-30,a[1]*(1-weight)+b[1]*weight)
		remaining_budget -= admitted
		state.absorbed += admitted
		var grounded := mini(admitted-settled,floori((a[6]*(1-weight)+b[6]*weight)*net.cycles*1000/phases*factor))
		state.grounded += grounded
		state.dissipated += admitted-settled-grounded
		settle_lumped(state,settled,purity,settled_stability,corruption)
		for e: int in net.used_edges:
			var edge: Anatomy.Edge = state.edges[e]
			var moved := floori((a[7+e]*(1-weight)+b[7+e]*weight)*net.cycles*1000/phases*factor)
			edge.daily_flow += moved
			edge.practice += moved/1000.0
			edge.peak_rate = maxf(edge.peak_rate,(a[7+net.source.size()+e]*(1-weight)+b[7+net.source.size()+e]*weight)*factor)
			state.circulated += moved
		expose_storage(state,float(Anatomy.definition().session_seconds)/phases/3600,opening_residue)
	var config := Anatomy.definition()
	# The manual pays daily integration from its actual refined reserve. Stored
	# qi shares the dantian's volume and backpressure with incoming packets.
	var assigned_from_reserve := floori(state.reserve*float(config.daily_reserve_integration_fraction))
	var reserve_purity: float = state.reserve_moments[0]/maxi(1,int(state.reserve))
	for q in 4: state.reserve_moments[q] *= float(state.reserve-assigned_from_reserve)/maxi(1,int(state.reserve))
	state.reserve -= assigned_from_reserve
	var remaining := int(state.pending_work)+accounting.refined_work_model(state,assigned_from_reserve,reserve_purity)
	var storage_work := mini(remaining, floori(state.capacity*.005*20.0))
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

## Convenience entry point validates current structural coefficients on each call.
## Hold a Network only while its body revision and source qualities stay fixed.
func simulate_day_model(state: Anatomy.Cultivator, program: Dictionary, sample: Dictionary, budget: int, revision: int = 0) -> void:
	step(state,compile(state,program,sample,revision),budget)

func advance(state: Anatomy.Cultivator, net: Network, sample: Dictionary, until: int) -> void:
	while state.day<until: step(state,net,int(sample.quantity))

func residual(state: Anatomy.Cultivator) -> int:
	return accounting.residual_model(state)

## Detached 16-node body adapter; Stage 3b will own packed-column writeback.
## Internal ordering keeps the lower dantian in the reference accounting slot.
func production_body(store: RefCounted, row: int) -> Anatomy.Cultivator:
	var state := Anatomy.Cultivator.new()
	state.purge_multiplier = 1
	state.reserve_moments = [0.0,0.0,0.0,0.0]
	var config := Store.definition()
	var order: Array[String] = ["breath","chest","abdominal","lumbar","lower"]
	for node: Dictionary in config.nodes:
		if not order.has(node.id): order.append(node.id)
	for id: String in order:
		var original := -1
		for i in config.nodes.size():
			if config.nodes[i].id==id: original=i
		var offset := (row*Store.NODES+original)*Store.NODE_FLOATS
		var node := Anatomy.Compartment.new()
		node.id = "dantian" if id=="lower" else id
		node.mass = [0,0,0,0,0]
		for e in 5: node.mass[e] = store.mass[(row*Store.NODES+original)*5+e]
		node.moments = []
		for q in 4: node.moments.append(store.nodes[offset+q])
		node.volume = store.nodes[offset+Store.NodeFloat.VOLUME]
		node.safe_pressure = store.nodes[offset+Store.NodeFloat.SAFE_PRESSURE]
		node.integrity = store.nodes[offset+Store.NodeFloat.INTEGRITY]
		node.scar = store.nodes[offset+Store.NodeFloat.SCAR]
		node.strain = store.nodes[offset+Store.NodeFloat.STRAIN]
		state.nodes.append(node)
	for index in Store.EDGES:
		var spec: Dictionary = config.edges[index]
		var offset := (row*Store.EDGES+index)*Store.EDGE_FLOATS
		var edge := Anatomy.Edge.new()
		edge.id = spec.id
		edge.source = order.find(spec.from_id)
		edge.destination = order.find(spec.to_id)
		edge.capacity = store.edges[offset+Store.EdgeFloat.CAPACITY]
		# Anatomy applies the laboratory's 1.15 affinity in its accessor.
		edge.conductivity = store.edges[offset+Store.EdgeFloat.CONDUCTIVITY]*store.edges[offset+Store.EdgeFloat.AFFINITY]/1.15
		edge.openness = store.edges[offset+Store.EdgeFloat.OPENNESS]
		edge.integrity = store.edges[offset+Store.EdgeFloat.INTEGRITY]
		edge.scar = store.edges[offset+Store.EdgeFloat.SCAR]
		edge.adaptation = store.edges[offset+Store.EdgeFloat.ADAPTATION]
		state.edges.append(edge)
	var base := row*Store.PERSON_INTS
	state.day = store.integers[base+Store.PersonInt.DAY]
	state.reserve = store.integers[base+Store.PersonInt.RESERVE]
	state.residue = store.integers[base+Store.PersonInt.RESIDUE]
	state.capacity = store.integers[base+Store.PersonInt.CAPACITY]
	state.absorbed = store.integers[base+Store.PersonInt.ABSORBED]
	state.work = store.integers[base+Store.PersonInt.WORK]
	state.opening_work = store.integers[base+Store.PersonInt.OPENING_WORK]
	state.volume_work = store.integers[base+Store.PersonInt.VOLUME_WORK]
	state.nodes[4].stored_quanta = state.reserve
	state.nodes[4].residue_quanta = state.residue
	return state

func production_program(route: String) -> Dictionary:
	var program := accounting.manual(route).duplicate(true)
	# The production lumbar path has two edges rather than four laboratory edges.
	var operations: Array = []
	for op: Dictionary in program.operations:
		var copy := op.duplicate(true)
		if route=="B":
			if op.operation=="Guide" and op.targets==[4]: continue
			if op.operation=="Guide" and op.targets==[6]: continue
			if op.operation=="Guide" and op.targets==[2,5]: copy.targets=[2,4]
		if op.operation=="Guide" and op.targets==[7]: copy.targets=[8]
		if op.operation=="Ground": continue # Production graph has no external earth sink edge.
		operations.append(copy)
	program.operations = operations
	return program

## Charged safety fixture uses a bounded one-minute integration of the same
## grounding pressure law. Damage is driven solely by accumulated exposure.
func safety(kind: String) -> Dictionary:
	var state := Anatomy.Cultivator.from_dictionary(Anatomy.create())
	var fixture: Dictionary = Anatomy.definition().safety[kind]
	var initial := int(fixture.initial_quanta)
	state.nodes[1].mass = [initial,0,0,0,0]
	state.nodes[1].moments = [float(initial),0.0,float(initial),0.0]
	state.edges[8].integrity = fixture.ground_integrity
	for minute in 60:
		accounting.flow_model(state,[8],false,60)
		accounting.exposure_model(state,60,false)
	return {"strain":state.max_strain,"integrity":state.nodes[1].integrity,"deaths":state.deaths,"injury":state.nodes[1].integrity<1,"residual":initial-state.grounded-accounting.total(state.nodes[1])}

## Quantized periodic kernel: preserves the per-operation floor/remainder effects
## before reducing a network to daily coefficients. It never simulates a day.
func periodic(net: Network, program: Dictionary, sample: Dictionary, backpressure: float) -> PackedFloat64Array:
	# Scalar moments suffice for transport/refinement. Concurrent lanes read one
	# opening inventory and share source/destination headroom before committing.
	var count := net.volume.size()
	var amount := PackedInt64Array()
	var pure := PackedFloat64Array()
	var stable := PackedFloat64Array()
	var corrupt := PackedFloat64Array()
	var filter_rem := PackedFloat64Array()
	var stabilise_rem := PackedFloat64Array()
	var remainder := PackedFloat64Array()
	amount.resize(count)
	pure.resize(count)
	stable.resize(count)
	corrupt.resize(count)
	filter_rem.resize(count)
	stabilise_rem.resize(count)
	remainder.resize(net.source.size())
	var result := PackedFloat64Array()
	result.resize(7+2*net.source.size())
	var limits := PackedInt64Array()
	limits.resize(count)
	for i in count:
		var connected := 0.0
		for e in net.source.size():
			if net.source[e]==i or net.destination[e]==i: connected += net.capacity[e]
		limits[i] = floori(connected*.7*10000)
	var outgoing := PackedInt64Array()
	var incoming := PackedInt64Array()
	var candidates := PackedInt64Array()
	var moved := PackedInt64Array()
	var qp := PackedFloat64Array()
	var qs := PackedFloat64Array()
	var qc := PackedFloat64Array()
	outgoing.resize(count)
	incoming.resize(count)
	candidates.resize(4)
	moved.resize(4)
	qp.resize(4)
	qs.resize(4)
	qc.resize(4)
	var density: float = sample.density
	var sample_purity: float = sample.purity
	var sample_stability: float = sample.stability
	var sample_corruption: float = sample.corruption
	var simple_quality := sample_stability==1 and sample_corruption==0
	var filter_intensity: float = program.filter
	var intake_rem := 0.0
	# The production bypass is two edges shorter than the laboratory bypass.
	# Retain 32 warmup cycles there; the longer laboratory pipe needs 64.
	var measured := 16 if net.volume.size()>8 else 32
	var relaxation := 48 if net.volume.size()>8 else (RELAX if net.instructions.size()>=12 else 64)
	for iteration in relaxation:
		var measure := iteration>=relaxation-measured
		for op: Reference.Instruction in net.instructions:
			for slice in op.slices:
				if op.code==0:
					var p := amount[0]/1000.0/net.volume[0]
					if p>=net.safe[0]*.9: continue
					var rate := minf(net.capacity[0],net.conductance[0]*maxf(0,density/8-p))
					var desired := rate*10000+intake_rem
					intake_rem = desired-floori(desired)
					var q := mini(floori(desired),maxi(0,floori((net.safe[0]*.9-p)*net.volume[0]*1000)))
					amount[0] += q
					pure[0] += q*sample_purity
					if not simple_quality:
						stable[0] += q*sample_stability
						corrupt[0] += q*sample_corruption
					if measure: result[0] += q
				elif op.code in [1,2,3]:
					if op.targets.size()==1:
						var e: int = op.targets[0]
						var a := net.source[e]
						var b := net.destination[e]
						var difference := amount[a]/1000.0/net.volume[a]+(backpressure if a==4 else 0.0)-amount[b]/1000.0/net.volume[b]-(backpressure if b==4 else 0.0)
						var gate := 1-clampf(op.error,0,.60)
						var ideal := minf(net.capacity[e],net.conductance[e]*gate*maxf(0,difference))*10000+remainder[e]
						var q := floori(ideal)
						remainder[e] = ideal-q
						q = mini(q,mini(amount[a],maxi(0,floori(net.volume[b]*(net.safe[b]-(backpressure if b==4 else 0.0))*1000)-amount[b])))
						var p := pure[a]*q/maxi(1,amount[a])
						var st := 0.0 if simple_quality else stable[a]*q/maxi(1,amount[a])
						var c := 0.0 if simple_quality else corrupt[a]*q/maxi(1,amount[a])
						amount[a] -= q
						pure[a] -= p
						if not simple_quality:
							stable[a] -= st
							corrupt[a] -= c
						if count==8 and b==7:
							if measure: result[6] += q
						else:
							amount[b] += q
							pure[b] += p
							if not simple_quality:
								stable[b] += st
								corrupt[b] += c
						if measure:
							result[7+e] += q
							result[7+net.source.size()+e] = maxf(result[7+net.source.size()+e],q/10000.0)
						continue
					outgoing.fill(0)
					incoming.fill(0)
					var gate := 1-clampf(op.error,0,.60)
					for j in op.targets.size():
						var e: int = op.targets[j]
						var source := net.source[e]
						var destination := net.destination[e]
						var difference := amount[source]/1000.0/net.volume[source]+(backpressure if source==4 else 0.0)-amount[destination]/1000.0/net.volume[destination]-(backpressure if destination==4 else 0.0)
						var ideal := minf(net.capacity[e],net.conductance[e]*gate*maxf(0,difference))*10000+remainder[e]
						var q := floori(ideal)
						remainder[e] = ideal-q
						candidates[j] = q
						outgoing[net.source[e]] += q
						incoming[net.destination[e]] += q
					for j in op.targets.size():
						var e: int = op.targets[j]
						var a := net.source[e]
						var b := net.destination[e]
						var headroom := maxi(0,floori(net.volume[b]*(net.safe[b]-(backpressure if b==4 else 0.0))*1000)-amount[b])
						var scale := minf(1,minf(float(amount[a])/maxi(1,outgoing[a]),float(headroom)/maxi(1,incoming[b])))
						var q := floori(candidates[j]*scale)
						moved[j] = q
						qp[j] = pure[a]*q/maxi(1,amount[a])
						if not simple_quality:
							qs[j] = stable[a]*q/maxi(1,amount[a])
							qc[j] = corrupt[a]*q/maxi(1,amount[a])
					# All moments are sampled before any lane commits.
					for j in op.targets.size():
						var e: int = op.targets[j]
						var a := net.source[e]
						var b := net.destination[e]
						amount[a] -= moved[j]
						pure[a] -= qp[j]
						if not simple_quality:
							stable[a] -= qs[j]
							corrupt[a] -= qc[j]
						amount[b] += moved[j]
						pure[b] += qp[j]
						if not simple_quality:
							stable[b] += qs[j]
							corrupt[b] += qc[j]
						if measure:
							result[7+e] += moved[j]
							result[7+net.source.size()+e] = maxf(result[7+net.source.size()+e],moved[j]/10000.0)
					if count==8:
						if measure: result[6] += amount[7]
						amount[7] = 0
						pure[7] = 0
						stable[7] = 0
						corrupt[7] = 0
				elif op.code in [4,5]:
					for i: int in op.targets:
						var q := mini(amount[i],limits[i])
						if q==0: continue
						var cost := q*(.15*filter_intensity if op.code==4 else .02)+(filter_rem[i] if op.code==4 else stabilise_rem[i])
						var loss := floori(cost)
						if op.code==4: filter_rem[i] = cost-loss
						else: stabilise_rem[i] = cost-loss
						var p := pure[i]/amount[i]
						var st := 1.0 if simple_quality else stable[i]/amount[i]
						var c := 0.0 if simple_quality else corrupt[i]/amount[i]
						if op.code==4:
							pure[i] += (q-loss)*(p+.60*filter_intensity*(1-p))-q*p
							corrupt[i] += (q-loss)*c*(1-.70*filter_intensity)-q*c
							stable[i] -= loss*st
						else:
							stable[i] += (q-loss)*(1-(1-st)*.60)-q*st
							pure[i] -= loss*p
							corrupt[i] -= loss*c
						amount[i] -= loss
				elif op.code==6:
					if measure:
						result[1] += amount[4]
						result[2] += pure[4]
						result[3] += amount[4] if simple_quality else stable[4]
						result[4] += corrupt[4]
					amount[4] = 0
					pure[4] = 0
					stable[4] = 0
					corrupt[4] = 0
	for i in 7+net.source.size(): result[i] /= measured*1000.0
	return result

func settle_lumped(state: Anatomy.Cultivator, quantity: int, purity: float, stability: float, corruption: float) -> void:
	if quantity==0: return
	state.refined += quantity
	state.usable += quantity*purity
	state.purity_moment += quantity*purity
	var opening_budget := mini(quantity,maxi(0,500000-state.opening_work))
	var opening := accounting.refined_work_model(state,opening_budget,purity)
	state.opening_work += opening
	state.work += opening
	var remaining := quantity-opening_budget
	var stored := mini(remaining,maxi(0,state.capacity-state.reserve-state.residue))
	state.reserve += stored
	state.reserve_moments[0] += stored*purity
	state.reserve_moments[2] += stored*stability
	state.reserve_moments[3] += stored*corruption
	remaining -= stored
	state.pending_work += accounting.refined_work_model(state,remaining,purity)
	state.nodes[4].stored_quanta = state.reserve

func expose_storage(state: Anatomy.Cultivator, hours: float, opening_residue: int) -> void:
	var node: Anatomy.Compartment = state.nodes[4]
	var pressure := float(state.reserve+state.residue)/1000/maxf(1e-6,node.volume)
	state.peak_pressure = maxf(state.peak_pressure,pressure)
	var start := float(opening_residue)/state.capacity
	var finish := float(state.residue)/state.capacity
	# Integrate the quadratic danger of the linear lodged-residue ramp exactly.
	var danger := pow(maxf(0,pressure/node.safe_pressure-1),2)+(start*start+start*finish+finish*finish)/3
	var initial := node.strain
	var damaging_hours := hours if initial>=.5 else maxf(0,hours-(.5-initial)/maxf(1e-30,danger))
	var loss := .02*(maxf(0,initial-.5)*damaging_hours+.5*danger*damaging_hours*damaging_hours)
	node.strain += danger*hours
	if node.integrity>=.8 and node.integrity-loss<.8: state.injuries += 1
	node.integrity = maxf(0,node.integrity-loss)
	node.scar += .10*maxf(0,loss-.01)
	state.strain = maxf(state.strain,node.strain)
	state.max_strain = maxf(state.max_strain,node.strain)
	if node.integrity<=0 and state.deaths==0: state.deaths=1
