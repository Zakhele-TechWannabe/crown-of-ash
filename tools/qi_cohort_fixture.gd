extends RefCounted
const Practice = preload("res://src/qi_practice.gd")
const Anatomy = preload("res://src/meridians.gd")
## Behaviour-only historical control; the same physical executor and laws.
class UnawarePractice extends Practice:
	func danger_response(_s: RefCounted, _p: int, _state: Anatomy.Cultivator, position: Vector2) -> Vector2:
		return position

## Force qualification and deterministic personality, leaving all execution live.
static func prepare(pop: RefCounted, count: int = 6) -> Array[int]:
	var s: RefCounted=pop.society
	s.qi_field.seed(pop.day)
	var ids: Array[int] = []
	var job: int=pop.register_job("Qi cohort",[])
	for i in count:
		var p: int=pop.add_person("Qi cohort %d" % i,20,job)
		ids.append(p)
		s.temper.body_layer[p]=9
		for grade in 9: s.temper.grades[p*9+grade]=3
		pop.spirit_root[p]=1
		pop.root_purity[p]=100
		s.revealed[p]=1
		pop.set_location(p,s.qi_field.landmarks[["Palace","Sect","Village"][i%3]])
		for weight in s.mind.WEIGHTS: s.mind._set_weight(p,weight,0)
		s.mind.heart_ready[p]=1
		s.mind._set_weight(p,s.mind.B2+s.mind.FEAR,3 if i%2==0 else -3)
		s.mind._set_weight(p,s.mind.B2+s.mind.AMBITION,-3 if i%2==0 else 3)
		s.mind._set_weight(p,s.mind.B2+s.mind.PRIDE,-3 if i%2==0 else 3)
	return ids

## Existing Palace members, identical to the live performance workload.
static func prepare_palace(pop: RefCounted) -> Array[int]:
	var s: RefCounted=pop.society
	s.qi_field.seed(pop.day)
	var palace: Array=s.fifty.people.keys()
	var ids: Array[int]=[]
	for i in 50:
		var p: int=palace[i]
		ids.append(p)
		s.temper.body_layer[p]=9
		for grade in 9: s.temper.grades[p*9+grade]=3
		pop.spirit_root[p]=1
		pop.root_purity[p]=100
		s.revealed[p]=1
		pop.set_location(p,s.qi_field.landmarks[["Palace","Sect","Village"][i%3]])
		for weight in s.mind.WEIGHTS: s.mind._set_weight(p,weight,0)
		s.mind.heart_ready[p]=1
		s.mind._set_weight(p,s.mind.B2+s.mind.FEAR,3 if i%2==0 else -3)
		s.mind._set_weight(p,s.mind.B2+s.mind.AMBITION,-3 if i%2==0 else 3)
		s.mind._set_weight(p,s.mind.B2+s.mind.PRIDE,-3 if i%2==0 else 3)
	return ids

static func danger_summary(s: RefCounted, ids: Array[int]) -> Dictionary:
	var result := {"sect_careful_deaths":0,"sect_greedy_deaths":0,"palace_living":0,"village_living":0,"palace_certified":0,"palace_last":-1,"responses":{}}
	for i in ids.size():
		var p: int=ids[i]
		if i%3==1 and not s.alive[p]: result["sect_careful_deaths" if i%2==0 else "sect_greedy_deaths"]+=1
		if i%3==0:
			result.palace_living+=int(s.alive[p])
			var day: int=s.meridian_report(p).achieved[0]
			result.palace_certified+=int(day>=0)
			result.palace_last=maxi(result.palace_last,day)
		if i%3==2: result.village_living+=int(s.alive[p])
		for action: String in s.qi_practice.records.get(p,{}).get("responses",{}):
			result.responses[action]=int(result.responses.get(action,0))+int(s.qi_practice.records[p].responses[action])
	return result

## Explicit long fixture: all-Perfect foundation, revealed root, two initial
## manuals at the Palace. No channel, pressure, qi or achievement endowments.
static func long_prepare(pop: RefCounted) -> Array[int]:
	var ids := prepare(pop,2)
	var s: RefCounted=pop.society
	for i in ids.size():
		var p: int=ids[i]
		pop.set_location(p,s.qi_field.landmarks.Palace)
		s.prepare_meridians(p,0)
		var state: RefCounted=s.qi_practice.body(s,p)
		s.qi_practice.records[p]={"return_days":0,"cycles":0,"last_reserve":0,"last_policy_day":0,"fixture":"ten-year Perfect Palace"}
		state.retained_program=s.qi_practice.program("A" if i==0 else "B",1.0)
	return ids

static func long_run(pop: RefCounted, days: int = 3650) -> Dictionary:
	pop.async_factions=false
	var ids := long_prepare(pop)
	var peak_core := 0.0
	var peak_pressure := 0.0
	var peak_draw := 0
	var peak_fill := 0.0
	var peak_growth := 0.0
	var peak_edges := PackedInt64Array()
	peak_edges.resize(24)
	for day in range(1,days+1):
		pop.tick_day(day)
		for p in ids:
			var r: Dictionary=pop.society.qi_practice.records[p]
			peak_core=maxf(peak_core,float(r.get("core_rate",0)))
			var state: RefCounted=pop.society.qi_practice.body(pop.society,p)
			for e in 24: peak_edges[e]=maxi(peak_edges[e],state.edges[e].daily_flow)
			var execution: Dictionary=state.milestones.get("daily_execution",{})
			peak_draw=maxi(peak_draw,int(execution.get("draw",0)))
			var fill := float(state.reserve+int(execution.get("draw",0))+state.residue)/maxi(1,state.capacity)
			peak_fill=maxf(peak_fill,fill)
			peak_growth=maxf(peak_growth,pop.society.qi_practice._compiler.accounting.enlargement_factor(fill))
			peak_pressure=maxf(peak_pressure,float(pop.society.qi_practice.body(pop.society,p).milestones.get("daily_execution",{}).get("pressure",0)))
	var reached := PackedInt32Array([-1,-1,-1,-1,-1,-1,-1,-1,-1])
	for p in ids:
		var report: Dictionary=pop.society.meridian_report(p)
		for layer in 9:
			if report.achieved[layer]>=0 and (reached[layer]<0 or report.achieved[layer]<reached[layer]): reached[layer]=report.achieved[layer]
	var ending: Array=[]
	for p in ids:
		var state: RefCounted=pop.society.qi_practice.body(pop.society,p)
		ending.append({"capacity":state.capacity,"reserve":state.reserve,"residue":state.residue,"draw":state.milestones.daily_execution.draw,"residual":pop.society.qi_practice._compiler.residual(state)})
	return {"fixture":true,"days":days,"ids":ids,"peak_draw":peak_draw,"peak_fill":peak_fill,"peak_growth":peak_growth,"ending":ending,"achieved":reached,"peak_edges":peak_edges,"peak_core":peak_core,"peak_pressure":peak_pressure,"bottleneck":"measured core circuit below 30 QU/hour" if reached[1]<0 else "retained pressure below 1.5" if reached[2]<0 else "see per-layer evidence"}
