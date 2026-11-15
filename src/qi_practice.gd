extends RefCounted
## One dated production coordinator. Bodies and compiled networks are transient;
## saves contain physical execution state and policy/evidence, never compiler caches.
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Store = preload("res://src/meridian_store.gd")
var profile := PackedInt64Array([0,0,0,0,0,0,0,0,0]) # execution, request, field, mismatch, writeback, certification/notes, preparation/sample, policy, settlement
var _compiler := Compiler.new()
var _bodies: Dictionary = {}
var records: Dictionary = {}
var _policy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cultivation/practice.json"))

func save_state() -> Dictionary:
	var saved := records.duplicate(true)
	for p: int in _bodies:
		saved[p]["memo"]=_compiler.save_memo(_bodies[p])
		saved[p].body = _compiler.accounting.serializable_state(_bodies[p].as_dictionary()).duplicate(true)
	return {"records":saved}

func load_state(saved: Dictionary) -> void:
	_compiler = Compiler.new()
	_bodies.clear()
	records = saved.get("records",{}).duplicate(true)

func body(s: RefCounted, p: int) -> Anatomy.Cultivator:
	if not _bodies.has(p):
		if records.has(p) and records[p].has("body"):
			var values: Dictionary = records[p].body.duplicate(true)
			var restored_nodes: Array = []
			var restored_edges: Array = []
			for node: Dictionary in values.nodes: restored_nodes.append(Anatomy.Compartment.from_dictionary(node))
			for edge: Dictionary in values.edges: restored_edges.append(Anatomy.Edge.from_dictionary(edge))
			values.nodes=restored_nodes
			values.edges=restored_edges
			_bodies[p] = Anatomy.Cultivator.from_dictionary(values)
			records[p].erase("body")
			_compiler.restore_memo(_bodies[p],records[p].get("memo",{}))
			records[p].erase("memo")
		else:
			_bodies[p] = _compiler.production_body(s.meridian_store,s.meridian_store.slot[p])
	return _bodies[p]

func traits(s: RefCounted, p: int) -> PackedFloat32Array:
	return s.mind.urges(p) if s.mind else PackedFloat32Array([0,0,.5,.5,.5,.5,.5,.5])

func program(route: String, filter_level: float) -> Dictionary:
	var result := _compiler.production_program(route)
	result.filter = filter_level
	return result

func select_program(s: RefCounted, p: int, state: Anatomy.Cultivator, sample: Dictionary, budget: int) -> void:
	if not state.retained_program.is_empty() and state.day-int(records[p].get("last_policy_day",state.day-90))<90: return
	var u := traits(s,p)
	if state.retained_program.is_empty():
		var route: String = _policy.palace_route if s.fifty and s.fifty.member(p) else _policy.default_route
		state.retained_program = program(route,clampf(.75+.5*u[2]-.4*u[6]-.25*u[3],0,1))
		records[p]["last_policy_day"]=state.day
		return
	records[p]["last_policy_day"]=state.day
	var step := clampf(.02+.12*u[7]+.10*u[4]-.08*u[2],.01,.20)
	var accepted := clampf(.10+.35*u[6]+.25*u[3]-.30*u[2],.05,.60)
	var current: Dictionary = state.retained_program
	var chosen := current
	var best := -INF
	var evaluated: Array = []
	var candidates: Array = []
	# Residue cannot purge before today's exposure; storage can grow at most
	# its funded 0.5% daily ceiling. If even this best case exceeds accepted
	# strain, every candidate is rejected, so retain the policy without trials.
	if unavoidable_strain(state)<=accepted:
		candidates=[current,program("A",1),program("B",.25),program(current.id,clampf(current.filter-step,0,1)),program(current.id,clampf(current.filter+step,0,1))]
	for candidate: Dictionary in candidates:
		if evaluated.has(candidate): continue
		evaluated.append(candidate)
		var trial := _compiler.production_trial(state)
		_compiler.solve_day(trial,_compiler.compile(trial,candidate,sample,0,true),budget)
		if trial.strain>accepted or trial.injuries>state.injuries: continue
		var score: float = trial.work-state.work-(trial.residue_added-state.residue_added)*u[2]-trial.strain*1000
		if score>best:
			best=score
			chosen=candidate
	if chosen!=current:
		s.meridian_store.expected_intake[s.meridian_store.slot[p]]=-1
	state.retained_program=chosen
	state.choices.append({"day":state.day,"route":chosen.id,"filter":chosen.filter})
	if state.choices.size()>16: state.choices.pop_front()

func unavoidable_strain(state: Anatomy.Cultivator) -> float:
	var ceiling := maxi(state.capacity,int(Anatomy.definition().initial_capacity_quanta)+(state.volume_work+floori(state.capacity*.005*20.0))/20)
	return state.nodes[4].strain+24.0*pow(float(state.residue)/ceiling,2)

func advance(s: RefCounted, until: int) -> void:
	var field: RefCounted = s.qi_field
	field.seed(field.day)
	while field.day<until:
		var participants := PackedInt32Array()
		# One source sample per occupied cell, not per body. The elemental
		# allocator retains individual stable IDs for its exact tie rules.
		var samples: Dictionary = {}
		var cells := PackedInt32Array()
		var positions := PackedVector2Array()
		var prepare_timer := Time.get_ticks_usec()
		for p in s.population.size():
			if not s.alive[p]: continue
			if s.prepare_meridians(p,field.day)<0: continue
			var state := body(s,p)
			state.day=field.day
			if not records.has(p): records[p]={"return_days":0,"cycles":0,"last_reserve":0}
			var position: Vector2 = s.population.locations[p]
			var cell: int = field.cell_at(position)
			if not samples.has(cell): samples[cell]=field.sample(position)
			var sample: Dictionary = samples[cell]
			var limit := mini(int(sample.quantity),ceili(Anatomy.capacity(state.edges[0])*14400*1000))
			if s.fifty and s.fifty.away(p): limit=0
			profile[6]+=Time.get_ticks_usec()-prepare_timer
			var policy_timer := Time.get_ticks_usec()
			select_program(s,p,state,sample,limit)
			profile[7]+=Time.get_ticks_usec()-policy_timer
			var timer := Time.get_ticks_usec()
			var row: int = s.meridian_store.slot[p]
			var expected: int = s.meridian_store.expected_intake[row]
			# Request the last observed absorption plus one 2% allocation bucket.
			# This permits rising throughput without predicting or solving twice.
			var demand := limit if expected<=0 else mini(limit,expected+maxi(2,ceili(expected*.02)))
			field.request("practice:%d" % p,position,field.split_mass(demand,Array(sample.elements)) if int(sample.quantity)>0 else PackedInt64Array([0,0,0,0,0]),1)
			participants.append(p)
			cells.append(cell)
			positions.append(position)
			profile[1]+=Time.get_ticks_usec()-timer
			prepare_timer=Time.get_ticks_usec()
		if participants.is_empty():
			field.advance(until)
			break
		var field_timer := Time.get_ticks_usec()
		field.advance(field.day+1)
		profile[2]+=Time.get_ticks_usec()-field_timer
		for i in participants.size():
			var p: int = participants[i]
			var state := body(s,p)
			var sample: Dictionary = samples[cells[i]]
			var budget := 0
			for part: int in field.allocations.get("practice:%d" % p,[]): budget+=part
			var absorbed := state.absorbed
			var injuries := state.injuries
			var deaths := state.deaths
			var timer := Time.get_ticks_usec()
			var net := _compiler.live_network(state,state.retained_program,sample)
			# Replay only a valid, funded transition; otherwise solve once with
			# the actual grant. Saved arithmetic preserves cold continuation.
			_compiler.step(state,net,budget)
			profile[0]+=Time.get_ticks_usec()-timer
			s.meridian_store.expected_intake[s.meridian_store.slot[p]]=state.absorbed-absorbed
			timer=Time.get_ticks_usec()
			field.settle_reservation("practice:%d" % p,positions[i],state.absorbed-absorbed,sample,false)
			assert(_compiler.residual(state)==0,"Production integer conservation")
			profile[8]+=Time.get_ticks_usec()-timer
			timer=Time.get_ticks_usec()
			writeback(s,p,state)
			profile[4]+=Time.get_ticks_usec()-timer
			timer=Time.get_ticks_usec()
			certify(s,p,state,field.day,injuries)
			if state.injuries>injuries:
				s.injury_until[p]=maxi(s.injury_until[p],field.day+21)
				s.note(p,"injury","%s suffered a qi deviation injury" % s.population.names[p],field.day)
			if state.deaths>deaths:
				s.die(p,"cultivation_death","%s died by qi deviation" % s.population.names[p])
			profile[5]+=Time.get_ticks_usec()-timer
		field._close_ledger()

func certify(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, opening_injuries: int) -> void:
	var row: int = s.meridian_store.slot[p]
	var base := row*Store.PERSON_INTS
	var layer: int = s.meridian_store.integers[base+Store.PersonInt.LAYER]
	var valid: bool = state.injuries==opening_injuries and state.deaths==0 and state.strain<=.20 and s.damage[p]>=.85 and s.injury_until[p]<=day
	for edge: Anatomy.Edge in state.edges:
		if edge.integrity<.85: valid=false
	for node: Anatomy.Compartment in state.nodes:
		if node.integrity<.85: valid=false
	var evidence: Dictionary = records[p]
	# The same four-hour core circuit must meet the threshold on every edge.
	var throughput := INF
	for e in [0,1,2,5,6,7,8]: throughput=minf(throughput,state.edges[e].daily_flow/4000.0)
	if valid and throughput>=30: evidence.return_days+=1
	var eligible: bool = layer==0 and valid and state.capacity>=100000 and state.opening_work>=500000 and state.settling_days>=30 and state.reserve>0 and float(state.residue)/state.capacity<=.10
	if layer==1: eligible=valid and evidence.return_days>=30
	# Layers 4–9 intentionally have no evaluator in Stage 3b.
	if layer==2:
		var daily: Dictionary = state.milestones.get("daily_execution",{})
		# One recorded session fill followed by its funded reserve-integration draw.
		if valid and float(daily.get("pressure",0))>=1.5 and float(daily.get("purity",0))>=.75 and float(daily.get("instability",1))<=.10 and int(daily.get("draw",0))>0 and int(daily.get("fill",0))>=int(daily.get("draw",0)):
			evidence.cycles+=1
		eligible=valid and evidence.cycles>=10
	evidence.last_reserve=state.reserve
	if eligible:
		layer+=1
		s.meridian_store.integers[base+Store.PersonInt.LAYER]=layer
		s.meridian_store.achieved[row*9+layer-1]=day
		s.note(p,"breakthrough","%s certified Qi Condensation layer %d" % [s.population.names[p],layer],day)
	# Legacy presentation columns are projections of certified physical state.
	if s.realm[p]<3:
		s.realm[p]=2
		s.layer[p]=layer
		s.qi[p]=state.reserve/1000.0

func writeback(s: RefCounted, p: int, state: Anatomy.Cultivator) -> void:
	s.meridian_store.writeback(s.meridian_store.slot[p],state,false)

func policy_report(p: int) -> Dictionary:
	var retained: Dictionary = {}
	if _bodies.has(p): retained=_bodies[p].retained_program
	elif records.has(p) and records[p].has("body"): retained=records[p].body.get("retained_program",{})
	if retained.is_empty(): return {}
	return {"route":_policy.names.get(retained.id,retained.id),"filter":retained.filter}
