extends RefCounted
## Evidence comes from committed sessions, never predictions or anatomy potential.
const Anatomy = preload("res://src/meridians.gd")
const Store = preload("res://src/meridian_store.gd")
const CORE_SHARED = [0,5,6,7,8]
const CORE_BRANCHES = [[1,2],[3,4]]
const LIMBS = [[9,10],[12,13],[15,16],[18,19]]
const EMPTY = {}
# Owner decision 2026-11-19: the cultivation world's known "full vessel" is
# 97.5% of a body's own safe pressure. Treasures may raise vessel_limit later.
const FULL_VESSEL := .975
# Foundation tiers by safe pressure: ordinary < 1.33 <= genius < 1.5 <= heavenly-gifted.
const VESSEL_TIERS = [[1.5,"heavenly-gifted"],[1.333,"genius"],[0.0,"ordinary"]]
# Owner standards 2026-11-19 for ordinary foundations; the section-9 strict
# numbers (90 QU/hour, error 0.08, 70% release) remain distinctions to record.
const OUTPUT_RATE := 35.0
const CONTROL_ERROR := .15
const CORE_RATE := 75.0 # strict 150 QU/hour is the legendary distinction
const NAMES = ["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth"]

static func phase(s: RefCounted, p: int, r: Dictionary) -> int:
	if not r.has("trial_phase"):
		r.trial_phase=floori(Store.variation(s.population.names[p],str(p),"certification schedule")*100000)%7
	return int(r.trial_phase)

static func usable(state: Anatomy.Cultivator, path: Array) -> bool:
	for e: int in path:
		if Anatomy.capacity(state.edges[e])<=0 or Anatomy.conductance(state.edges[e])<=0 or state.edges[e].integrity<.85: return false
	return true

static func observe(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, opening_injuries: int, r: Dictionary) -> void:
	if int(r.get("evidence_day",-1))==day: return
	r.evidence_day=day
	var row: int=s.meridian_store.slot[p]
	var base := row*Store.PERSON_INTS
	var layer: int=s.meridian_store.integers[base+Store.PersonInt.LAYER]
	var daily: Dictionary=state.milestones.get("daily_execution",EMPTY)
	var hours: float=float(daily.get("seconds",14400))/3600.0
	var valid: bool=bool(daily.get("stable",true)) and state.injuries==opening_injuries and state.deaths==0 and state.strain<=.20 and s.damage[p]>=.85 and s.injury_until[p]<=day and s.temper.body_layer[p]>=9 and s.revealed[p]>0 and s.population.spirit_root[p]>0
	# The executor checked every edge/node before recovery. A matching body
	# revision reuses that proof; pulses and external anatomy edits invalidate it.
	if valid and int(daily.get("health_revision",-1))!=state.session_revision:
		for edge: Anatomy.Edge in state.edges:
			if edge.integrity<.85 or edge.strain>.20: valid=false
		for node: Anatomy.Compartment in state.nodes:
			if node.integrity<.85 or node.strain>.20: valid=false
	var throughput := 0.0
	var shared := INF
	var divisor := maxf(1,hours*1000)
	for e: int in CORE_SHARED:
		shared=minf(shared,state.edges[e].daily_flow/divisor)
		if shared==0: break
	if shared>0:
		for branch: Array in CORE_BRANCHES:
			var rate := shared
			for e: int in branch: rate=minf(rate,state.edges[e].daily_flow/divisor)
			throughput=maxf(throughput,rate)

	r.core_rate=throughput
	r.clean=valid
	var safe: float=state.nodes[4].safe_pressure
	var full: bool=float(daily.get("pressure",0))>=safe*float(r.get("vessel_limit",FULL_VESSEL))-1e-9
	if full: r.vessel_pressure=maxf(float(r.get("vessel_pressure",0)),float(daily.get("pressure",0)))
	var cycle: bool=valid and hours>=2 and full and float(daily.get("purity",0))>=.75 and float(daily.get("instability",1))<=.10 and int(daily.get("draw",0))>0 and int(daily.get("fill",0))>=int(daily.get("draw",0))
	if not valid: r.return_days=0
	elif hours>=2 and throughput>=30: r.return_days=int(r.get("return_days",0))+1
	if cycle: r.cycles=int(r.get("cycles",0))+1
	var hourly_rate: float=daily.get("hourly_core",0.0)
	r.output_rate=hourly_rate
	if valid and hours>=2 and hourly_rate>=OUTPUT_RATE and state.capacity>=400000: r.output_days=int(r.get("output_days",0))+1
	# The declaration is the actual sampled source before filtering. A source
	# has a mixed elemental recipe when two positive components are present.
	var source: Dictionary=r.get("declared_source",EMPTY)
	var mixed: bool=source.get("mixed",false)
	if not source.has("mixed"):
		var components := 0
		for value: float in source.get("elements",[]):
			if value>0: components+=1
		mixed=components>=2
	if valid and hours>=2 and mixed:
		r.mixed_processed=int(r.get("mixed_processed",0))+int(daily.get("qualified_mixed",0))
	# QU/hour while both branches run, not averaged over the whole session.
	# Days without the split drill keep the last drilled rate.
	var drilled: bool=float(daily.get("simultaneous_seconds",0))>0
	var simultaneous: float=int(daily.get("simultaneous",0))/maxf(1,float(daily.get("simultaneous_seconds",0))/3.6) if drilled else float(r.get("branch_rate",0))
	r.branch_rate=simultaneous
	r.control_error=float(daily.get("control_error",1))
	if drilled and valid and hours>=2 and simultaneous>=25 and r.control_error<=CONTROL_ERROR: r.coordination_days=int(r.get("coordination_days",0))+1
	var release: Dictionary=r.get("release_today",EMPTY)
	if valid and release.get("day",-1)==day and release.get("success",false): r.release_tests=int(r.get("release_tests",0))+1
	r.last_reserve=state.reserve
	# Early certificates need no terminal/integration trial construction. Common
	# processing/coordination/release evidence above is still retained.
	if layer<3:
		var early := false
		match layer:
			0: early=valid and state.capacity>=100000 and state.opening_work>=500000 and state.settling_days>=30 and state.reserve>0 and float(state.residue)/state.capacity<=.10
			1: early=int(r.get("return_days",0))>=30
			2: early=int(r.get("cycles",0))>=10 and state.reserve_moments[0]/maxi(1,state.reserve)>=.75
		if early: attempt(s,p,state,day,r,valid)
		project(s,p,state,base)
		return
	var terminals: Dictionary=r.get("terminals",{})
	var test: Dictionary=r.get("distribution_today",EMPTY)
	if valid and hours>=2 and test.get("day",-1)==day and test.get("success",false):
		var terminal := int(test.terminal)
		if usable(state,LIMBS[terminal]): terminals[str(terminal)]={"day":day,"quanta":int(test.delivered)}

	r.terminals=terminals
	var purity: float=state.reserve_moments[0]/maxi(1,state.reserve)
	# Integrated work exercises fill/draw, filtering and both branches now.
	# The dated 1.5-pressure proof remains an ability while storage and routes
	# remain sound; a larger reservoir need not be filled to its rim each day.
	var controlled_draw: bool=int(daily.get("draw",0))>0 and int(daily.get("fill",0))>=int(daily.get("draw",0)) and float(daily.get("instability",1))<=.10
	var intact: bool=valid and hours>=2 and purity>=.90 and float(state.residue)/state.capacity<=.10 and state.opening_work>=500000 and state.settling_days>=30 and int(r.get("return_days",0))>=30 and int(r.get("cycles",0))>=10 and controlled_draw and hourly_rate>=OUTPUT_RATE and int(daily.get("qualified_mixed",0))>0 and terminals.size()==4 and int(r.get("output_days",0))>=30 and int(r.get("mixed_processed",0))>=1000000 and int(r.get("coordination_days",0))>=30 and int(r.get("release_tests",0))>=10 and release.get("success",false) and simultaneous>=25 and r.control_error<=CONTROL_ERROR and usable(state,[9,10,12,13,15,16,18,19])

	if intact and throughput>=CORE_RATE and state.capacity>=1000000: r.integrated_days=int(r.get("integrated_days",0))+1
	var ready := false
	match layer:
		0: ready=valid and state.capacity>=100000 and state.opening_work>=500000 and state.settling_days>=30 and state.reserve>0 and float(state.residue)/state.capacity<=.10
		1: ready=int(r.get("return_days",0))>=30
		2: ready=int(r.get("cycles",0))>=10 and purity>=.75
		3: ready=terminals.size()==4 and usable(state,[9,10,12,13,15,16,18,19])
		4: ready=int(r.get("output_days",0))>=30 and state.capacity>=400000 and hourly_rate>=OUTPUT_RATE and hours>=2
		5: ready=int(r.get("mixed_processed",0))>=1000000 and purity>=.90
		6: ready=int(r.get("coordination_days",0))>=30 and simultaneous>=25 and r.control_error<=CONTROL_ERROR and hours>=2
		7: ready=int(r.get("release_tests",0))>=10 and release.get("day",-1)==day and release.get("success",false)
		8: ready=int(r.get("integrated_days",0))>=90 and intact and throughput>=CORE_RATE and state.capacity>=1000000

	# Early layers retain their historical dates. Later trials use a keyed
	# weekly slot; a completed record quota can still fail its current physical trial.
	var near := false
	match layer:
		3: near=terminals.size()==4
		4: near=int(r.get("output_days",0))>=30
		5: near=int(r.get("mixed_processed",0))>=1000000
		6: near=int(r.get("coordination_days",0))>=30
		7: near=int(r.get("release_tests",0))>=10
		8: near=int(r.get("integrated_days",0))>=90
	var scheduled: bool=layer<3 or (day+phase(s,p,r))%7==0
	if layer<9 and scheduled and (ready or near):
		attempt(s,p,state,day,r,valid and ready)
	project(s,p,state,base)

static func project(s: RefCounted, p: int, state: Anatomy.Cultivator, base: int) -> void:
	if s.realm[p]<3:
		s.realm[p]=2
		s.layer[p]=s.meridian_store.integers[base+Store.PersonInt.LAYER]
		s.qi[p]=state.reserve/1000.0

static func attempt(s: RefCounted, p: int, state: Anatomy.Cultivator, day: int, r: Dictionary, passed: bool) -> void:
	if int(r.get("attempt_day",-1))==day: return
	r.attempt_day=day
	var row: int=s.meridian_store.slot[p]
	var base := row*Store.PERSON_INTS
	var layer: int=s.meridian_store.integers[base+Store.PersonInt.LAYER]
	if layer>=9: return
	var attempts: Array=r.get("attempts",[])
	attempts.append({"day":day,"layer":layer+1,"passed":passed,"core_rate":r.get("core_rate",0.0),"purity":state.reserve_moments[0]/maxi(1,state.reserve)})
	r.attempts=attempts
	# Today's committed session is the trial: no second practice day or RNG.
	var pulse: Dictionary=r.get("distribution_today",EMPTY) if layer==3 else r.get("release_today",EMPTY)
	if not passed and not (pulse.get("day",-1)==day and not pulse.get("success",false)):
		state.nodes[4].strain+=.005
		state.strain=maxf(state.strain,state.nodes[4].strain)
		state.max_strain=maxf(state.max_strain,state.strain)
		state.session_revision+=1
	if passed:
		s.meridian_store.integers[base+Store.PersonInt.LAYER]=layer+1
		s.meridian_store.achieved[row*9+layer]=day
		s.note(p,"breakthrough","%s certified the %s layer of Qi Condensation" % [s.population.names[p],NAMES[layer]],day)
	elif not (layer==7 and int(r.get("last_release_note",-1))==day):
		s.note(p,"cultivation_trial","%s failed the %s trial" % [s.population.names[p],"discharge" if layer==7 else NAMES[layer]+" layer"],day)

static func measured(label: String, value: float, target: float, units: String = "") -> String:
	return "[%s] %s: %s/%s%s" % ["met" if value>=target else "partial" if value>0 else "missing",label,str(snappedf(value,.01)),str(target),units]

static func lines(layer: int, r: Dictionary, report: Dictionary) -> Array[String]:
	var result: Array[String]=[]
	if layer>=9: return result
	match layer+1:
		1:
			result.append(measured("capacity",report.capacity/1000.0,100," QU"))
			result.append(measured("opening work",float(r.get("opening_work",0))/1000,500," QU"))
			result.append(measured("settling",int(r.get("settling_days",0)),30," days"))
			result.append("[%s] residue wall: %.1f/10%%" % ["met" if float(report.residue)/maxi(1,report.capacity)<=.10 else "partial",100.0*report.residue/maxi(1,report.capacity)])
		2: result.append(measured("circuit sustains 30 QU/hour",int(r.get("return_days",0)),30," days"))
		3:
			result.append(measured("controlled fill–draw, vessel ≥97.5% full",int(r.get("cycles",0)),10," cycles"))
			result.append(measured("purity",report.purity,.75))
		4:
			for i in 4:
				result.append(measured(["left palm","right palm","left sole","right sole"][i],int(r.get("terminals",{}).get(str(i),{}).get("quanta",0))/1000.0,.02," QU delivered"))
		5:
			result.append(measured("one hour at 35 QU/hour",int(r.get("output_days",0)),30," days"))
			result.append(measured("capacity",report.capacity/1000.0,400," QU"))
		6:
			result.append(measured("mixed source filtered to purity ≥0.90, corruption ≤0.02",float(r.get("mixed_processed",0))/1000,1000," QU"))
			result.append(measured("reserve purity",report.purity,.90))
		7: result.append(measured("simultaneous branches ≥25 QU/hour; error ≤0.15",int(r.get("coordination_days",0)),30," days"))
		8: result.append(measured("controlled 0.10 QU release at one tile, ≥30%, no overpressure",int(r.get("release_tests",0)),10," tests"))
		9:
			result.append(measured("integrated practice, earlier functions intact",int(r.get("integrated_days",0)),90," days"))
			result.append(measured("capacity",report.capacity/1000.0,1000," QU"))
			result.append(measured("core circuit",float(r.get("core_rate",0)),75," QU/hour"))
	result.append("[met] no injury through the span: clean" if r.get("clean",false) else "[missing] no injury through the span")
	return result

## The distinction a cultivator's vessel earned: tier by the pressure actually held.
static func vessel_tier(r: Dictionary) -> String:
	var held := float(r.get("vessel_pressure",0))
	if held<=0: return ""
	for tier: Array in VESSEL_TIERS:
		if held>=float(tier[0])*FULL_VESSEL-1e-9: return "%s vessel (%.2f)" % [tier[1],held]
	return ""
