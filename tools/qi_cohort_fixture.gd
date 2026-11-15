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
