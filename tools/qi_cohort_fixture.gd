extends RefCounted
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
