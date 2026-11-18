extends RefCounted
## One dated production coordinator. Bodies and compiled networks are transient;
## saves contain physical execution state and policy/evidence, never compiler caches.
const Compiler = preload("res://src/session_compiler.gd")
const Anatomy = preload("res://src/meridians.gd")
const Certification = preload("res://src/qi_certification.gd")
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
		var state: Anatomy.Cultivator=_bodies[p]
		if not state.retained_program.is_empty() and int(state.retained_program.get("manual_revision",1))<int(_policy.manual_revision):
			# Rebuild authored schedules; retain personal filtering and all physical
			# inventory, damage, adaptation and dated achievements. Old memos and
			# predicted intake belong to the superseded instruction schedule.
			state.retained_program=program(str(state.retained_program.id),float(state.retained_program.filter))
			# This is a newly restored body: discard the obsolete execution
			# journal and its transient revision, just like a cold compilation.
			# A revision bump without a journal would be lost on the next save.
			state.session_cache=null
			state.session_cache_owner=0
			state.session_revision=0
			s.meridian_store.expected_intake[s.meridian_store.slot[p]]=-1
	return _bodies[p]

func traits(s: RefCounted, p: int) -> PackedFloat32Array:
	return s.mind.urges(p) if s.mind else PackedFloat32Array([0,0,.5,.5,.5,.5,.5,.5])

func program(route: String, filter_level: float) -> Dictionary:
	var result := _compiler.production_program(route)
	result.filter = filter_level
	return result

func select_program(s: RefCounted, p: int, state: Anatomy.Cultivator, sample: Dictionary, budget: int) -> void:
	if not state.retained_program.is_empty() and state.day-int(records[p].get("last_policy_day",state.day-90))<90: return
	if records[p].get("wants_purer_qi",false) and not state.retained_program.is_empty():
		records[p]["last_policy_day"]=state.day
		return
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

## Only observations of this body enter the warning; no trial of future days.
func danger_response(s: RefCounted, p: int, state: Anatomy.Cultivator, position: Vector2) -> Vector2:
	var r: Dictionary = records[p]
	if r.get("practice_origin",position)!=position:
		r.erase("practice_offset")
	var load := float(state.residue)/maxi(1,state.capacity)
	var trend := state.nodes[4].strain-float(r.get("observed_strain",0.0))
	r.observed_strain=state.nodes[4].strain
	var hurt := state.injuries>int(r.get("observed_injuries",0))
	r.observed_injuries=state.injuries
	if state.day<int(r.get("pause_until",0)): return position
	if load<.045 and trend<=.002 and not hurt: return position
	if state.day<int(r.get("review_after",0)): return position
	# Heart founding belongs to the existing mind lifecycle, never to sensing.
	var u := traits(s,p) if s.mind and s.mind.heart_ready[p] else PackedFloat32Array([0,0,.5,.5,.5,.5,.5,.5])
	var diligent: bool = s.population.has_trait(p,"diligent")
	# Keyed noise models imperfect perception without consuming anyone's RNG.
	var noise := Store.variation(str(p),str(state.day),"danger")-1.0
	var perceived := load*(1+noise*.12)
	var threshold := .061-.012*u[2]+.006*u[6]+.004*u[3]
	if perceived<threshold and trend<=.003 and not hurt: return position
	r.review_after=state.day+7
	var action := "ignore"
	var reason := "residue load feels unsafe"
	if trend>.002: reason="strain rising despite nightly recovery"
	if hurt: reason="recent qi injury"
	var caution: float = u[2]+(.15 if diligent else 0)-.55*u[6]-.40*u[3]
	if caution+noise*.15>0 or noise>.20-.04*u[7]+.02*u[4]:
		r.wants_purer_qi=true
		r.session_fraction=.5 if u[4]+u[7]>.9 else .25
		r.pause_until=state.day+(14 if load>.06 or hurt else 7)
		action="pause"
		# Practice within walking distance of today's site only. No relocation.
		var best: Dictionary=s.qi_field.sample(position)
		var spot := position
		for offset in [Vector2(24,0),Vector2(-24,0),Vector2(0,24),Vector2(0,-24)]:
			if s.law==null or s.law.grid==null: continue
			if s.law.walk_path(Vector2i(position.round()),Vector2i((position+offset).round())).is_empty(): continue
			var sample: Dictionary=s.qi_field.sample(position+offset)
			if float(sample.purity)>float(best.purity)+.01:
				best=sample
				spot=position+offset
		r.practice_offset=spot-position
		r.practice_origin=position
		s.meridian_store.expected_intake[s.meridian_store.slot[p]]=-1
	var counts: Dictionary=r.get("responses",{})
	counts[action]=int(counts.get(action,0))+1
	if action=="pause":
		for response in ["filter","shorten","seek_purer"]: counts[response]=int(counts.get(response,0))+1
		if r.get("practice_offset",Vector2.ZERO)!=Vector2.ZERO: counts["local_spot"]=int(counts.get("local_spot",0))+1
	r.responses=counts
	var history: Array=r.get("danger_decisions",[])
	history.append({"day":state.day,"action":action,"reason":reason,"residue_fraction":load,"strain_trend":trend})
	if history.size()>16: history.pop_front()
	r.danger_decisions=history
	if state.day-int(r.get("last_warning_note",-90))>=90:
		r.last_warning_note=state.day
		s.note(p,"cultivation_warning",("%s stopped cultivating, feeling their dantian clog" if action=="pause" else "%s ignored the warning signs") % s.population.names[p],state.day)
	return position

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
		var declarations: Dictionary = {}
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
			position=danger_response(s,p,state,position)
			position+=records[p].get("practice_offset",Vector2.ZERO)
			var cell: int = field.cell_at(position)
			if not samples.has(cell): samples[cell]=field.sample(position)
			var sample: Dictionary = samples[cell]
			var limit := mini(int(sample.quantity),ceili(Anatomy.capacity(state.edges[0])*14400*1000))
			if s.fifty and s.fifty.away(p): limit=0
			profile[6]+=Time.get_ticks_usec()-prepare_timer
			var policy_timer := Time.get_ticks_usec()
			select_program(s,p,state,sample,limit)
			if records[p].get("wants_purer_qi",false) and (float(state.retained_program.filter)<.95 or state.retained_program.get("session_fraction",1.0)!=records[p].session_fraction):
				# Programs are compiler cache keys: replace, never mutate a held key.
				state.retained_program=state.retained_program.duplicate(true)
				state.retained_program.filter=maxf(float(state.retained_program.filter),.95)
				state.retained_program["session_fraction"]=records[p].session_fraction
			if state.day<int(records[p].get("pause_until",0)): limit=0
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
			var active := drill_program(s,p,state)
			var net := _compiler.live_network(state,active,sample)
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
			if not declarations.has(cells[i]):
				var components := 0
				for value: float in sample.elements:
					if value>0: components+=1
				declarations[cells[i]]={"elements":sample.elements.duplicate(),"purity":sample.purity,"corruption":sample.corruption,"mixed":components>=2}
			# A cell declaration is immutable and shared by today's recipients.
			records[p]["declared_source"]=declarations[cells[i]]
			var certified: int=s.meridian_store.integers[s.meridian_store.slot[p]*Store.PERSON_INTS+Store.PersonInt.LAYER]
			var can_trial: bool=field.day>int(records[p].get("pause_until",-1)) and float(state.milestones.get("daily_execution",{}).get("seconds",0))>=7200
			if can_trial and int(records[p].get("distribution_drill",-1))>=0:
				distribution(s,p,state,field.day,int(records[p].distribution_drill))
				assert(_compiler.residual(state)==0,"Distribution integer conservation")
			if can_trial and certified>=7 and (field.day+Certification.phase(s,p,records[p]))%7==0:
				release(s,p,state,field.day)
				assert(_compiler.residual(state)==0,"Release integer conservation")
			certify(s,p,state,field.day,injuries)
			var writeback_started := Time.get_ticks_usec()
			writeback(s,p,state)
			var writeback_elapsed := Time.get_ticks_usec()-writeback_started
			profile[4]+=writeback_elapsed
			timer+=writeback_elapsed
			if state.injuries>injuries:
				s.injury_until[p]=maxi(s.injury_until[p],field.day+21)
				s.note(p,"injury","%s suffered a qi deviation injury" % s.population.names[p],field.day)
			if state.deaths>deaths:
				s.die(p,"cultivation_death","%s died by qi deviation" % s.population.names[p])
			profile[5]+=Time.get_ticks_usec()-timer
		field._close_ledger()

func certify(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, opening_injuries: int) -> void:
	Certification.observe(s,p,state,day,opening_injuries,records[p])

func writeback(s: RefCounted, p: int, state: Anatomy.Cultivator) -> void:
	s.meridian_store.writeback(s.meridian_store.slot[p],state,false)

func policy_report(p: int) -> Dictionary:
	var retained: Dictionary = {}
	if _bodies.has(p): retained=_bodies[p].retained_program
	elif records.has(p) and records[p].has("body"): retained=records[p].body.get("retained_program",{})
	var r: Dictionary=records.get(p,{})
	var result := {"danger_sense":"resting after warning" if int(r.get("pause_until",0))>int(r.get("evidence_day",0)) else ("seeking purer qi" if r.get("wants_purer_qi",false) else "quiet"),"evidence":r.duplicate(true)}
	# Keep reports compact: execution bodies and memo are persistence details.
	result.evidence.erase("body")
	result.evidence.erase("memo")
	if not retained.is_empty(): result.merge({"route":_policy.names.get(retained.id,retained.id),"filter":retained.filter})
	return result

## Drills are immutable day programs; the selected personal manual is retained.
func drill_program(s: RefCounted, p: int, state: Anatomy.Cultivator) -> Dictionary:
	var r: Dictionary=records[p]
	r.distribution_drill=-1
	var layer: int=s.meridian_store.integers[s.meridian_store.slot[p]*Store.PERSON_INTS+Store.PersonInt.LAYER]
	var record_hourly := layer>=4
	if bool(state.milestones.get("hourly_trial",false))!=record_hourly:
		state.milestones["hourly_trial"]=record_hourly
		_compiler.invalidate(state)
	var offset := Certification.phase(s,p,r)
	if layer<3 or (state.day+offset)%7!=0: return state.retained_program
	if _compiler.accounting.vocabulary.is_empty(): _compiler.accounting.manual("A")
	var active: Dictionary=state.retained_program.duplicate(true)
	var terminal: int=((state.day+offset)/7)%4
	r.distribution_drill=terminal
	var ops: Array=[]
	for op: Dictionary in active.operations:
		var copy := op.duplicate(true)
		if copy.operation=="Guide" and copy.targets==[1]:
			copy.operation="Split"
			copy.targets=[1,3]
			copy.control_demand=2
		if copy.operation=="Guide" and copy.targets==[2]: copy.targets=[2,4]
		if copy.operation=="Integrate":
			for edge: int in [4]+Certification.LIMBS[terminal]:
				var guide: Dictionary=_compiler.accounting.vocabulary.Guide.duplicate(true)
				guide.operation="Guide"
				guide.targets=[edge]
				ops.append(guide)
		ops.append(copy)
	active.operations=ops
	return active

## A bounded, paid pulse through the actual lower-to-palm path. Projection is
## dissipated (including controlled delivery) rather than usable ambient qi.
func release(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int) -> Dictionary:
	return _pulse(s,p,state,day,[5,6,7,9,10],true)

func distribution(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, terminal: int) -> Dictionary:
	var paths := [[5,6,7,9,10],[5,6,7,12,13],[15,16],[18,19]]
	var result := _pulse(s,p,state,day,paths[terminal],false)
	if not result.has("terminal"): result["terminal"]=terminal
	return result

func _pulse(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, path: Array, projected: bool) -> Dictionary:
	var r: Dictionary=records[p]
	if _compiler.accounting.vocabulary.is_empty(): _compiler.accounting.manual("A")
	var operation: Dictionary=_compiler.accounting.vocabulary.Release
	var today_key := "release_today" if projected else "distribution_today"
	var history_key := "release_history" if projected else "distribution_history"
	var note_key := "last_release_note" if projected else "last_distribution_note"
	var opening_injuries := state.injuries
	var result := {"operation":"Release" if projected else "Distribute","day":day,"requested":int(operation.quantity_quanta),"spent":0,"delivered":0,"distance_tiles":int(operation.distance_tiles) if projected else 0,"overpressure":false,"success":false}
	var origin: Vector2=s.population.locations[p]+r.get("practice_offset",Vector2.ZERO)
	result["origin"]=origin
	result["target"]=origin+Vector2.RIGHT*float(result.distance_tiles)
	result.distance_tiles=origin.distance_to(result.target)
	var layer: int=s.meridian_store.integers[s.meridian_store.slot[p]*Store.PERSON_INTS+Store.PersonInt.LAYER]
	if layer<1: return result
	if r.get(today_key,{}).get("day",-1)==day: return r[today_key]
	var settled: bool=not (s.fifty and s.fifty.away(p))
	for node: Anatomy.Compartment in state.nodes:
		state.strain=maxf(state.strain,node.strain)
		if _compiler.accounting.total(node)>0: settled=false
		if _compiler.accounting.pressure(node)>node.safe_pressure:
			result.overpressure=true
			settled=false
	if settled and s.alive[p] and state.deaths==0 and state.reserve>=100 and Certification.usable(state,path) and state.strain<=.20:
		var purity: float=state.reserve_moments[0]/maxi(1,state.reserve)
		var stability: float=clampf(state.reserve_moments[2]/maxi(1,state.reserve),0,1)
		var coherence := 1+4*clampf(float(Anatomy.definition().operation_mastery),0,1)
		var moments: Array=[]
		for q in 4:
			moments.append(state.reserve_moments[q]*100.0/state.reserve)
			state.reserve_moments[q]-=moments[q]
		state.reserve-=100
		state.nodes[4].stored_quanta=state.reserve
		# Detached mobile packets retain the live body's geometry, pressure and
		# damage. Only the funded pulse is mobile; reserve cannot be drawn twice.
		var trial := _compiler.production_trial(state)
		# The daily kernel already paid 24h of background residue exposure.
		# Preserve its pressure occupancy, adding only pulse-specific danger.
		trial.residue=0
		for node: Anatomy.Compartment in trial.nodes:
			node.mass=node.mass.duplicate()
			node.moments=node.moments.duplicate()
		_compiler.accounting.add(trial.nodes[4],{"mass":[100,0,0,0,0],"moments":moments})
		var delivered := 0
		var base_error: float=clampf(.25*(1-float(Anatomy.definition().operation_mastery))+.20*(1-float(Anatomy.definition().understanding))+.15*float(Anatomy.definition().emotional_disruption)-.10*float(Anatomy.definition().control),0,.60)
		var error := clampf(base_error+.10*clampf(state.strain/.20,0,1),0,.60)
		for step in int(operation.assay_cycles):
			if trial.strain>.35 or trial.deaths>0: break
			for edge: int in path:
				error=maxf(error,clampf(base_error+.10*clampf(trial.strain/.20,0,1),0,.60))
				var channel: Anatomy.Edge=trial.edges[edge]
				var candidate := _compiler.accounting.flow_candidate(trial,channel,10,1-error)
				_compiler.accounting.commit_candidate(trial,channel,candidate,candidate,10)
				_compiler.accounting.exposure_model(trial,10,false)
				for index: int in [trial.edges[edge].source,trial.edges[edge].destination]:
					if _compiler.accounting.pressure(trial.nodes[index])>trial.nodes[index].safe_pressure: result.overpressure=true
				if trial.strain>.35 or trial.deaths>0: break
			var terminal: Anatomy.Compartment=trial.nodes[trial.edges[path[-1]].destination]
			delivered+=_compiler.accounting.total(terminal)
			terminal.mass=[0,0,0,0,0]
			terminal.moments=[0.0,0.0,0.0,0.0]
			terminal.quantity=-1
			terminal.hazard_valid=false
		var strained_nodes: Array[int]=[]
		var outside_strain := 0.0
		for i in state.nodes.size():
			state.nodes[i].strain=trial.nodes[i].strain
			state.nodes[i].integrity=trial.nodes[i].integrity
			state.nodes[i].scar=trial.nodes[i].scar
			state.nodes[i].hazard_valid=false
			if i!=4 and state.nodes[i].strain>0:
				strained_nodes.append(i)
				outside_strain=maxf(outside_strain,state.nodes[i].strain)
		state.milestones["release_strain_nodes"]=strained_nodes
		state.milestones["release_strain"]=outside_strain
		state.injuries=trial.injuries
		state.deaths=trial.deaths
		state.strain=maxf(state.strain,trial.strain)
		state.max_strain=maxf(state.max_strain,trial.max_strain)
		var route_flows: Array[int]=[]
		for edge: int in path:
			var moved: int=trial.edges[edge].daily_flow-state.edges[edge].daily_flow
			route_flows.append(moved)
			state.circulated+=moved
			state.edges[edge].practice+=moved/1000.0
		result["route_flow_quanta"]=route_flows
		state.dissipated+=100
		state.nodes[4].hazard_valid=false
		state.session_revision+=1
		result.spent=100
		result["stability"]=stability
		result["purity"]=purity
		result["control_error"]=error
		result["coherence_length"]=coherence
		result.delivered=floori(delivered*purity*purity*stability*(1-error)*exp(-float(result.distance_tiles)/coherence)) if projected else delivered
		result.success=result.delivered>=(70 if projected else 20) and not result.overpressure and state.injuries==opening_injuries and state.deaths==0 and state.strain<=.20
	if not result.success:
		state.nodes[4].strain+=.005
		state.strain=maxf(state.strain,state.nodes[4].strain)
		state.max_strain=maxf(state.max_strain,state.strain)
		state.session_revision+=1
	r[today_key]=result
	var tests: Array=r.get(history_key,[])
	tests.append(result)
	r[history_key]=tests
	if not result.success and int(r.get(note_key,-90))+90<=day:
		r[note_key]=day
		s.note(p,"cultivation_trial",("%s failed the discharge trial" if projected else "%s failed the distribution trial") % s.population.names[p],day)
	return result
