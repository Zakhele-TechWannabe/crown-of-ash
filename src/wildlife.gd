extends RefCounted
## Coarse monthly cohorts and daily persistent beasts. Independent RNG preserves ecology across combat draws.
const Combat = preload("res://src/combat.gd")
const Body = preload("res://src/body_tempering.gd")
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wild/ecology.json"))
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wild/beasts.json"))
var species: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/wild/curated.json")).species
var society_ref: WeakRef
var economy_ref: WeakRef
var livestock: Dictionary = {}
var encounter_places: Dictionary = {}
var rng := RandomNumberGenerator.new()
var awakening_rng := RandomNumberGenerator.new()
var cells: Array[Dictionary] = []
var individuals: Array[Dictionary] = []
var history: Dictionary = {}
var encounters_by_decade: Dictionary = {}
var events: Array[Dictionary] = []
var used_names: Dictionary = {}
var next_id := 1
var day := 0
var month_day := 0
var initialized := false
var enabled := true
var totals := {"births":0,"predation":0,"deaths":0,"awakenings":0,"breakthroughs":0,"raids":0,"encounters":0,"human_deaths":0,"hunts":0}

func _init(society: RefCounted = null) -> void:
	if society: society_ref = weakref(society)

func seed(on_day: int = 0) -> void:
	if initialized: return
	initialized = true
	day = on_day
	month_day = on_day
	rng.seed = int(config.seed)
	awakening_rng.seed = int(config.seed) ^ 0x741ab
	for s: Dictionary in species:
		if s.get("domestic",false): livestock[s.sci] = int(s.get("start",0))
	for y in int(config.rows):
		for x in int(config.columns):
			var cell := {"position":Vector2(config.origin[0] + x * int(config.cell_size), config.origin[1] + y * int(config.cell_size)),"water":float(config.water),"shelter":float(config.shelter),"exposure":2 if (x + y * int(config.columns)) == 36 else (1 if (x + y * int(config.columns)) in [37,38,39] else 0),"capacity":0.0,"cohorts":{},"pressure":0.0}
			for s: Dictionary in species:
				if s.get("domestic", false): continue
				var count := int(s.get("start", 0)) * int(config.population_scale)
				if count <= 0: continue
				# Species starts describe the whole local valley, distributed without rounding losses.
				var index := y * int(config.columns) + x
				var n := count / 4 + int(index % 4 < count % 4) if float(index) in config.seed_cells else 0
				cell.cohorts[s.sci] = {"young":0,"adult":n,"old":0,"condition":1.0,"pending":0,"due":-1,"capacity":maxf(1, float(count) * float(config.capacity_multiplier) / 4.0)}
			cells.append(cell)
	for s: Dictionary in species:
		history[s.sci] = []
		if s.get("group", "") in config.persistent_groups:
			var remaining := int(s.get("start",0))
			for i in cells.size():
				while cohort_count(i,str(s.sci))>0 and remaining>0:
					promote(i,str(s.sci))
					remaining -= 1

func entry(sci: String) -> Dictionary:
	for s: Dictionary in species:
		if s.sci == sci: return s
	return {}

func cohort_count(cell: int, sci: String) -> int:
	var c: Dictionary = cells[cell].cohorts.get(sci, {})
	return int(c.get("young",0)) + int(c.get("adult",0)) + int(c.get("old",0))

func count(sci: String = "") -> int:
	var n := 0
	for i in cells.size():
		for id: String in cells[i].cohorts:
			if sci.is_empty() or sci == id: n += cohort_count(i,id)
	for b: Dictionary in individuals:
		if b.alive and (sci.is_empty() or b.species == sci): n += int(b.pack_size)
	return n

func remove_member(cell: int, sci: String) -> String:
	var c: Dictionary = cells[cell].cohorts.get(sci,{})
	for age: String in ["adult","young","old"]:
		if int(c.get(age,0)) > 0:
			c[age] -= 1
			return age
	return ""

func promote(cell: int, sci: String, awakened: bool = false) -> Dictionary:
	if individuals.filter(func(b: Dictionary) -> bool: return b.alive).size() >= int(rules.individual_cap): return {}
	var age_class := remove_member(cell,sci)
	if age_class.is_empty(): return {}
	var s := entry(sci)
	var name := individual_name(s)
	if name.is_empty():
		cells[cell].cohorts[sci][age_class] += 1
		return {}
	var age := float(s.lifespan_y) * float(config.initial_age_fraction)
	if age_class == "young": age = float(s.maturity_y) * .5
	if age_class == "old": age = float(s.lifespan_y) * .8
	var b := {"id":next_id,"species":sci,"name":name,"notable":false,"cell":cell,"position":cells[cell].position,"age":age,"biological_age":age,"age_class":age_class,"sex":rng.randi_range(0,1),"condition":float(cells[cell].cohorts[sci].condition),"reserves":1.0,"stamina":1.0,"harm":0.0,"alive":true,"pack_size":1,"awakened":awakened,"awakening_day":day if awakened else -1,"layer":0,"grades":[],"work":0.0,"layer_start":day,"method":int(s.instinct_method_cap),"practice":0.0,"medicine":{},"path":"spirit" if awakened else "latent","purity":.5,"resentment":0.0,"instability":0.0,"dark_months":0,"light_months":0,"recovery_months":0,"claim":-1,"memory":{},"event_trials":{},"last_trial":-int(rules.event_refractory),"harvested":false,"last_seen":day,"state":"resting"}
	if s.get("group", "") == "wolf" and not individuals.any(func(other: Dictionary) -> bool: return other.alive and other.species == sci and other.get("pack_leader",false)):
		b.pack_leader = true
		b.notable = true
	next_id += 1
	individuals.append(b)
	if awakened:
		totals.awakenings += 1
		log_event("awakening", b.name + " awakened")
	return b

func demote(b: Dictionary) -> bool:
	if b.awakened or not b.alive: return false
	cells[int(b.cell)].cohorts[b.species][b.age_class] += int(b.pack_size)
	individuals.erase(b)
	return true

func advance(on_day: int) -> void:
	if not enabled: return
	seed(day)
	while day < on_day:
		day += 1
		for b: Dictionary in individuals:
			if b.alive: daily(b)
		if day - month_day >= int(rules.month_days):
			monthly()
			month_day = day

func daily(b: Dictionary) -> void:
	if float(b.harm) >= 100.0:
		b.alive = false
		totals.deaths += int(b.pack_size)
		return
	var s := entry(b.species)
	var mult := float(rules.lifespan[int(b.layer)])
	b.age += 1.0 / float(rules.days_year)
	b.biological_age += 1.0 / (float(rules.days_year) * mult)
	var cell: Dictionary = cells[int(b.cell)]
	var season := mini(3, (day % 365) / 91)
	b.state = "denning" if s.get("group","") == "bear" and season == 3 else "foraging"
	var fed := float(config.season_food[season]) * float(cell.water) * float(cell.shelter)
	if s.get("group","") in config.predator_groups:
		fed = 0.0
		if rng.randf() < 1.0 / float(s.get("kill_interval", 8.3)):
			fed = float(rules.month_days)
			if not take_prey(int(b.cell), s): fed = 0.0
		# Carcass reserves bridge normal multi-day gaps between successful hunts.
		b.reserves = clampf(float(b.reserves) + fed - 1.0 / maxf(1,float(s.get("reserve_days",14))),0,1)
		fed = float(b.reserves)
	if b.state == "denning": fed = 1.0
	b.condition = clampf(float(b.condition) + (fed - .5) * float(config.condition_recovery) / float(rules.month_days),0,1)
	b.harm = maxf(0,float(b.harm) - float(config.wound_recovery_day) * float(b.condition))
	b.stamina = float(b.condition)
	b.last_seen = day
	b.position = Vector2(cell.position) + Vector2(sin(day * .13 + int(b.id)),cos(day * .11 + int(b.id))) * float(config.cell_size) * .35
	if society_ref and rng.randf() < float(config.encounter_day): encounter_near_work(b)
	if society_ref and s.get("group","") in ["wolf","fox","leopard","bear"] and b.condition < .7 and rng.randf() < float(config.raid_day): raid(b)
	b.practice = minf(1,float(b.practice) + float(b.condition) / float(rules.days_year))
	if b.biological_age > float(s.lifespan_y) or b.condition <= 0 or b.harm >= 100:
		b.alive = false
		totals.deaths += int(b.pack_size)
		return
	if b.awakened:
		b.work += float(b.condition) / float(rules.days_year) if b.claim >= 0 else 0.0
	else:
		var hazard := hazard_probability(int(cell.exposure),float(s.awakening_affinity),1.0 / float(rules.days_year))
		if awakening_rng.randf() < hazard:
			b.awakened = true
			b.path = "spirit"
			b.awakening_day = day
			b.layer_start = day
			totals.awakenings += 1
			log_event("awakening", b.name + " awakened")

func hazard_probability(exposure: int, affinity: float, years: float, sensitivity: float = 1.0) -> float:
	if exposure < 0 or years <= 0: return 0.0
	return 1.0 - exp(-minf(float(rules.hazard_cap),float(rules.hazards[mini(2,exposure)]) * affinity * minf(float(rules.sensitivity_cap),sensitivity)) * years)

func exceptional_trial(b: Dictionary, event_id: String) -> bool:
	if not b.alive: return false
	if b.event_trials.has(event_id): return false
	b.event_trials[event_id] = day
	if b.awakened or day - int(b.last_trial) < int(rules.event_refractory): return false
	b.last_trial = day
	if awakening_rng.randf() >= float(rules.event_chance): return false
	b.awakened = true
	b.path = "spirit"
	b.awakening_day = day
	b.layer_start = day
	totals.awakenings += 1
	return true

func prey_candidates(cell: int, predator: Dictionary) -> Array:
	var result: Array = []
	for offset in [0,-1,1,-int(config.columns),int(config.columns)]:
		var i := cell + int(offset)
		if i < 0 or i >= cells.size(): continue
		for tag: String in predator.get("eats",[]):
			for sci: String in config.prey_tags.get(tag,[]):
				var n := cohort_count(i,sci)
				if n > maxf(float(config.prey_refuge),float(cells[i].cohorts.get(sci,{}).get("capacity",0))*float(config.prey_refuge_fraction)): result.append([i,sci,n])
	return result

func take_prey(cell: int, predator: Dictionary) -> bool:
	var candidates := prey_candidates(cell,predator)
	if candidates.is_empty(): return false
	var row: Array = candidates[rng.randi_range(0,candidates.size()-1)]
	if rng.randf() > float(row[2])/(float(row[2])+float(config.predator_half_saturation)): return false
	var c: Dictionary = cells[int(row[0])].cohorts[row[1]]
	for age: String in ["young","old","adult"]:
		if int(c[age]) > 0:
			c[age] -= 1
			totals.predation += 1
			return true
	return false

func monthly() -> void:
	var season := mini(3,(day % 365) / 91)
	for i in cells.size():
		var cell: Dictionary = cells[i]
		cell.pressure *= .95
		for sci: String in cell.cohorts:
			var s := entry(sci)
			var c: Dictionary = cell.cohorts[sci]
			var n := cohort_count(i,sci)
			if int(c.due) >= 0 and day >= int(c.due):
				c.young += int(c.pending)
				totals.births += int(c.pending)
				c.pending = 0
				c.due = -1
				n = cohort_count(i,sci)
			if n <= 0: continue
			var food := 1.0
			if s.get("group","") in config.predator_groups:
				var prey := 0
				for row: Array in prey_candidates(i,s): prey += int(row[2])
				food = minf(1,float(prey)/maxf(1,n*float(config.predator_food_per_month)))
			var cap := float(c.capacity) * float(config.season_food[season]) * float(cell.water) * float(cell.shelter)
			c.condition = clampf(float(c.condition) + (food - n / maxf(1,cap)) * float(config.condition_recovery),0,1)
			var death_rate := float(config.mortality_year) / 12.0 + (1-food)*float(config.starvation_mortality) + maxf(0,n / maxf(1,cap) - 1) * float(config.crowding_mortality)
			var deaths := mini(n, stochastic(n * death_rate + float(c.old)/maxf(1,float(s.lifespan_y)*3)))
			for k in deaths:
				for age: String in ["old","young","adult"]:
					if int(c[age])>0:
						c[age] -= 1
						break
			totals.deaths += deaths
			if int(c.due) >= 0 and day >= int(c.due):
				c.young += int(c.pending)
				totals.births += int(c.pending)
				c.pending = 0
				c.due = -1
			if mini(11,(day % 365) * 12 / 365) == int(config.birth_month) and c.due < 0 and n >= 1  and float(c.condition) > .4:
				c.pending = stochastic(float(c.adult) * .5 * float(s.litter) * float(config.recruitment) * maxf(0,1.0-n/maxf(1,cap)))
				c.due = day + int(s.gestation)
			var mature := mini(int(c.young),stochastic(float(c.young) / maxf(1,float(s.maturity_y)*12)))
			c.young -= mature
			c.adult += mature
			var old := mini(int(c.adult),stochastic(float(c.adult)/maxf(1,float(s.lifespan_y)*12)))
			c.adult -= old
			c.old += old
			if s.get("group","") in config.predator_groups:
				for k in stochastic(n * float(config.prey_per_predator_month)): take_prey(i,s)
			var hazard := hazard_probability(int(cell.exposure),float(s.awakening_affinity),float(rules.month_days)/float(rules.days_year))
			var exposed := mini(cohort_count(i,sci),int(config.site_capacity[int(cell.exposure)]))
			var ambient := hazard_probability(0,float(s.awakening_affinity),float(rules.month_days)/float(rules.days_year))
			for k in stochastic(exposed*hazard+(cohort_count(i,sci)-exposed)*ambient,true): promote(i,sci,true)
			if float(c.condition) < .5 or n > cap:
				var j := clampi(i + (1 if i % int(config.columns) < int(config.columns)-1 else -1),0,cells.size()-1)
				var moving := mini(cohort_count(i,sci),stochastic(n * float(config.dispersal)))
				for k in moving:
					var age := remove_member(i,sci)
					if not age.is_empty(): cells[j].cohorts[sci][age] += 1
	# A monthly meeting can bring a population member into a temporary story.
	if society_ref and cells.size() > 36 and rng.randf() < float(config.population_encounter_month):
		var options: Array = []
		for sci: String in cells[36].cohorts:
			if cohort_count(36,sci) > 0: options.append(sci)
		if not options.is_empty():
			var visitor := promote(36,options[rng.randi_range(0,options.size()-1)])
			if not visitor.is_empty():
				encounter_near_work(visitor)
				if visitor.alive: demote(visitor)
	for b: Dictionary in individuals:
		if not b.alive: continue
		var s := entry(b.species)
		if mini(11,(day % 365)*12/365)==int(config.birth_month) and b.sex == 0 and b.condition > .5 and b.biological_age > float(s.maturity_y):
			var mates := individuals.filter(func(other: Dictionary) -> bool: return other.alive and other.species==b.species and other.sex != b.sex)
			if not mates.is_empty():
				var c: Dictionary = cells[int(b.cell)].cohorts[b.species]
				if c.due < 0:
					c.pending = int(s.litter)
					c.due = day + int(s.gestation)
		if not b.awakened: continue
		# Local sites admit one claimant; no global site search.
		if int(cells[int(b.cell)].exposure) > 0:
			var claimed := false
			for other: Dictionary in individuals:
				if other.alive and other.id != b.id and other.claim == b.cell: claimed = true; break
			if not claimed: b.claim = b.cell
		update_path(b,float(cells[int(b.cell)].get("corruption",0.0)))
		acquire_instinct(b)
		try_breakthrough(b)
	for s: Dictionary in species:
		var samples: Array = history.get(s.sci,[])
		history[s.sci] = samples
		samples.append(Vector2(day,count(s.sci)))
		if samples.size() > int(config.history_months): samples.pop_front()

func stochastic(value: float, awakening: bool = false) -> int:
	var stream := awakening_rng if awakening else rng
	return floori(value) + int(stream.randf() < fmod(value,1.0))

func update_path(b: Dictionary, corruption: float, injured: bool = false, human_hunt: bool = false) -> void:
	if human_hunt: b.instability = minf(1,float(b.instability)+float(rules.instability_hunt))
	if injured: b.resentment = minf(1,float(b.resentment)+float(rules.resentment_injury))
	elif b.condition > .5: b.resentment = maxf(0,float(b.resentment)-float(rules.resentment_recovery))
	if corruption <= 0 and b.condition > .5: b.instability = maxf(0,float(b.instability)-float(rules.instability_recovery))
	b.purity = clampf(float(b.purity)+float(rules.purity_clean)*(1-corruption)-float(rules.purity_corrupt)*corruption,0,1-float(b.instability))
	b.dark_months = int(b.dark_months)+1 if b.purity < float(rules.demonic_purity) and maxf(b.resentment,b.instability)>float(rules.demonic_pressure) else 0
	b.light_months = int(b.light_months)+1 if b.purity >= float(rules.spirit_purity) else 0
	b.recovery_months = int(b.recovery_months)+1 if b.purity >= float(rules.recover_purity) and maxf(b.resentment,b.instability)<float(rules.recover_pressure) else 0
	if b.dark_months >= int(rules.demonic_months): b.path = "demonic"
	elif b.path == "demonic":
		if b.recovery_months >= int(rules.recover_months): b.path = "spirit"
	elif b.light_months >= int(rules.spirit_months): b.path = "spirit"

func try_breakthrough(b: Dictionary) -> bool:
	var layer := int(b.layer)
	if not b.awakened or layer >= 9 or b.claim < 0 or b.condition < .7 or b.harm > 0: return false
	var body: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/body.json"))
	var years := float(rules.minimum_years[layer])
	if day - int(b.layer_start) < years * float(rules.days_year) or b.work < years or b.practice < 1: return false
	if int(b.method) < int(body.gate_method[layer]): return false
	var medicine: String = body.gate_medicine[layer]
	if not medicine.is_empty() and int(b.medicine.get(medicine,0)) <= 0: return false
	if not medicine.is_empty(): b.medicine[medicine] -= 1
	var q := 100.0 * (float(b.condition)*float(rules.quality_weights[0])+float(b.practice)*float(rules.quality_weights[1])+float(b.purity)*float(rules.quality_weights[2])+float(b.purity)*float(rules.quality_weights[3])+minf(1,float(entry(b.species).awakening_affinity)/2)*float(rules.quality_weights[4]))
	var grade := 0
	for threshold: float in rules.grade_thresholds:
		if q >= threshold: grade += 1
	b.grades.append(mini(grade,int(b.method)))
	b.layer += 1
	b.layer_start = day
	b.work = 0.0
	totals.breakthroughs += 1
	log_event("breakthrough", "%s reached %s" % [b.name,body.layer_names[layer]])
	return true

func profile(b: Dictionary) -> Dictionary:
	var base := Combat.beast(str(entry(b.species).combat_profile_id))
	var layer := int(b.layer)
	if layer == 0: return base
	var grade := 0.0
	for g: int in b.grades: grade += g
	grade /= maxf(1,b.grades.size())
	for key: String in ["power","guard"]: base[key] *= 1+float(rules.combat[key])*layer*(.8+.1*grade)
	for key: String in ["speed","breath"]: base[key] *= 1+float(rules.combat[key])*layer
	base.will = mini(3,int(base.will)+layer/3)
	return base

func harvest(b: Dictionary) -> Dictionary:
	if b.alive or b.harvested: return {}
	b.harvested = true
	var layer := int(b.layer)
	if layer == 0: return {"essence":0.0}
	var mean := 0.0
	for grade: int in b.grades: mean += float(rules.grade_factors[grade])
	mean /= maxf(1,b.grades.size())
	var budget := float(rules.essence_per_layer)*layer*mean
	var usable := budget*float(rules.processing_yield)*(float(rules.demonic_yield) if b.path == "demonic" else 1.0)
	var core := usable*float(rules.core_fraction) if layer >= 4 else 0.0
	return {"essence":budget,"usable":usable,"core":core,"tissues":usable-core,"lost":budget-usable,"core_kind":"stable beast core" if layer >= 7 else ("fragile core seed" if layer >= 4 else ""),"tainted":b.path == "demonic"}

func lifespan(b: Dictionary) -> float:
	return float(entry(b.species).lifespan_y)*float(rules.lifespan[int(b.layer)])

func log_event(kind: String, text: String) -> void:
	events.append({"day":day,"kind":kind,"text":text})
	if events.size() > 256: events.pop_front()
	if society_ref and society_ref.get_ref(): society_ref.get_ref().note(-1,"wild",text)

func summary() -> Dictionary:
	var paths := {"latent":[0,0,0,0,0,0,0,0,0,0],"spirit":[0,0,0,0,0,0,0,0,0,0],"demonic":[0,0,0,0,0,0,0,0,0,0]}
	var populations := {}
	var awakened := 0
	for s: Dictionary in species: populations[s.name] = count(s.sci)
	for b: Dictionary in individuals:
		if b.alive and b.awakened:
			awakened += 1
			paths[b.path][int(b.layer)] += 1
	return {"day":day,"total":count(),"populations":populations,"awakened":awakened,"layers_by_path":paths,"events":totals,"encounters_by_decade":encounters_by_decade}

func hunting_target() -> Dictionary:
	var candidates: Array[Dictionary] = []
	var center := Vector2(config.hunt_center[0],config.hunt_center[1])
	for i in cells.size():
		if Vector2(cells[i].position).distance_to(center) > float(config.hunt_radius): continue
		for sci: String in config.hunt_species:
			if cohort_count(i,sci)>0: candidates.append({"cell":i,"species":sci})
	for b: Dictionary in individuals:
		if b.alive and b.species in config.hunt_species and Vector2(b.position).distance_to(center)<float(config.hunt_radius): candidates.append(b)
	if candidates.is_empty() or rng.randf() > float(Combat.config.hunt_find): return {}
	return candidates[rng.randi_range(0,candidates.size()-1)]

func resolve_hunt(target: Dictionary, result: Dictionary) -> void:
	totals.hunts += 1
	if result.get("dead",false):
		totals.human_deaths += 1
		totals["hunt_deaths"] = int(totals.get("hunt_deaths",0)) + 1
	cells[int(target.cell)].pressure += 1.0
	if target.has("id"):
		target.harm = float(result.harm[1])
		if result.kill:
			target.alive = false
			var goods := harvest(target)
			if society_ref and not goods.is_empty() and not goods.get("tainted",false):
				var temper: RefCounted = society_ref.get_ref().temper
				if temper and int(target.layer)>=4:
					var id := "iron_bark" if int(target.layer)==4 else "beast_marrow"
					temper.medicine[id][int(result.ids[0])] += 1
	elif result.kill:
		remove_member(int(target.cell),str(target.species))
	if result.kill: log_event("hunt","A hunter brought down " + str(entry(target.species).name))

func encounter_motive(b: Dictionary, context: String) -> String:
	if context == "young": return "young"
	if context in ["cornered","wounded","kill","rut"]: return "own"
	if b.condition < .3: return "hunger"
	if b.path == "demonic" and not b.memory.is_empty(): return "revenge"
	return "flight"

func encounter_near_work(b: Dictionary) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	if store.size() == 0: return
	var candidates: Array[int] = []
	for id in store.size():
		if store.settlement[id] != 0 or not society.alive[id]: continue
		var exposed: bool = society.nature.habitat_of(id) in ["forest", "meadow"] or int(store.hunger[id]) >= 3
		for duty: String in store.schedules[store.job[id]]:
			if duty in config.encounter_duties: exposed = true
		if not exposed and not (store.age(id) >= int(config.wandering_age[0]) and store.age(id) < int(config.wandering_age[1])): continue
		var spot := contact_place(store,id)
		if not encounter_places.is_empty() and Vector2(b.position).distance_to(spot) > float(config.contact_range_tiles): continue
		candidates.append(id)
	if candidates.is_empty(): return
	var p: int = candidates[rng.randi_range(0,candidates.size()-1)]
	totals.encounters += 1
	var decade := str((day - 1) / 3650 + 1)
	encounters_by_decade[decade] = int(encounters_by_decade.get(decade,0)) + 1
	var context := "quiet"
	if b.harm > 0: context = "wounded"
	elif b.sex == 0 and mini(11,(day % 365)*12/365) == int(config.birth_month): context = "young"
	var motive := encounter_motive(b,context)
	if motive == "flight":
		b.state = "fleeing"
		society.record_fight({"kind":"wildlife","beast_id":b.id,"beast_species":b.species,"beast_position":b.position,"spot":contact_place(store,p),"day":day,"ids":[p,-1],"names":[store.names[p],b.name],"motives":["fear","fear"],"events":[{"t":"flee","i":1,"time":0.5}],"harm":[0.0,b.harm],"winner":0,"loser":1,"how":"escape","fates":["",""]})
		log_event("encounter", "%s saw %s leave the path" % [store.names[p],b.name])
		return
	var beast := profile(b)
	beast.motive = motive
	var person := Combat.person(society,p)
	person.motive = "fear"
	var r := Combat.fight(person,beast,{"ground":"forest","start_harm":[0.0,b.harm]},rng)
	r.merge({"kind":"wildlife","beast_id":b.id,"beast_species":b.species,"beast_position":b.position,"spot":contact_place(store,p),"day":day,"ids":[p,-1],"names":[person.name,b.name],"motives":["fear",motive]})
	b.harm = r.harm[1]
	if r.how == "death" and r.loser == 1: b.alive = false
	var fate := Combat._hurt(society,p,r.harm[0],-1,r)
	if fate == "dead": totals.human_deaths += 1
	r.fates = [fate,"dead" if not b.alive else ""]
	society.record_fight(r)
	log_event("encounter","%s met %s; %s" % [store.names[p],b.name,r.how])

func raid(b: Dictionary) -> void:
	if not economy_ref or not economy_ref.get_ref(): return
	var economy: RefCounted = economy_ref.get_ref()
	for sci: String in livestock:
		if int(livestock[sci])<=0: continue
		livestock[sci] -= 1
		b.reserves = 1.0
		b.condition = minf(1,float(b.condition)+.2)
		totals.raids += 1
		for good: String in config.raid_goods:
			if economy.stocks.has(good): economy.stocks[good] = maxf(0,float(economy.stocks[good])-float(config.raid_food))
		log_event("raid",b.name+" took an animal from the pens")
		return

## Only visible cells produce ambient representatives. These are visual samples, never extra animals.
func visuals(area: Rect2, minutes: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var tile_area := Rect2(area.position / 32.0, area.size / 32.0).grow(float(config.cell_size))
	for b: Dictionary in individuals:
		if b.alive and tile_area.has_point(b.position): result.append(b)
	for i in cells.size():
		if not tile_area.has_point(cells[i].position): continue
		for sci: String in cells[i].cohorts:
			var n := mini(3,cohort_count(i,sci))
			for j in n:
				var phase := float((i*71+j*13+sci.hash()) & 1023)
				var pos := Vector2(cells[i].position) + Vector2(sin(phase+minutes*.001),cos(phase+minutes*.0013))*float(config.cell_size)*.4
				result.append({"species":sci,"position":pos,"awakened":false})
	return result

func hunting_capacity() -> float:
	var cap := 0.0
	for cell: Dictionary in cells:
		for sci: String in config.hunt_species: cap += float(cell.cohorts.get(sci,{}).get("capacity",0.0))
	return cap

func individual_name(s: Dictionary) -> String:
	var traits: Array = rules.name_traits
	var marks: Array = rules.name_marks
	var candidate := ""
	for marking: String in traits:
		candidate = "the %s %s of the Eastern Hills" % [marking, str(s.name).to_lower()]
		if not used_names.has(candidate) and not individuals.any(func(b: Dictionary) -> bool: return b.name == candidate):
			used_names[candidate] = true
			return candidate
		for mark: String in marks:
			candidate = "the %s, %s %s of the Eastern Hills" % [marking, mark, str(s.name).to_lower()]
			if not used_names.has(candidate) and not individuals.any(func(b: Dictionary) -> bool: return b.name == candidate):
				used_names[candidate] = true
				return candidate
	for first: String in traits:
		for second: String in traits:
			if first == second: continue
			candidate = "the %s, %s %s of the Eastern Hills" % [first,second,str(s.name).to_lower()]
			if not used_names.has(candidate) and not individuals.any(func(b: Dictionary) -> bool: return b.name == candidate):
				used_names[candidate] = true
				return candidate
	return ""

func place(b: Dictionary) -> String:
	return "the spirit spring" if int(cells[int(b.cell)].exposure) == 2 else "the Eastern Hills"

func role(s: Dictionary) -> String:
	if str(s.diet) in ["omnivore", "omnivorous"]: return "omnivore"
	return "predator" if s.get("group", "") in config.predator_groups else "prey"

func trend(sci: String) -> String:
	var samples: Array = history.get(sci, [])
	if samples.size() < 2: return "steady"
	var before: float = samples[0].y
	var now := count(sci)
	return "up" if now > before * 1.05 else ("down" if now < before * .95 else "steady")

func description(b: Dictionary) -> String:
	if not b.awakened: return "Ordinary pack leader" if b.get("pack_leader",false) else "Ordinary animal"
	var body: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/body.json"))
	var grade := "ungraded" if b.grades.is_empty() else str(body.grade_names[int(b.grades[-1])])
	return "%s · layer %d · %s · %s" % [b.path, b.layer, body.layer_names[int(b.layer)-1] if b.layer > 0 else "untempered", grade]

## Animal-compatible catalysts: mineral bark at sites, spirit forage, and fallen cores.
func acquire_instinct(b: Dictionary) -> void:
	if b.claim < 0 or b.condition < .7 or b.harm > 0: return
	var exposure := int(cells[int(b.claim)].exposure)
	if exposure <= 0: return
	var years := (day - int(b.awakening_day)) / float(rules.days_year)
	if years >= float(rules.method_years[int(b.method)]) and awakening_rng.randf() < float(rules.method_month_chance) * exposure:
		b.method = mini(3, int(b.method) + 1)
		log_event("method", b.name + " learned a deeper instinctive regimen")
	if awakening_rng.randf() < float(rules.catalyst_month_chance) * exposure:
		var catalyst := "iron_bark" if b.layer < 4 else ("beast_marrow" if b.layer < 6 else "seven_leaf")
		b.medicine[catalyst] = mini(1, int(b.medicine.get(catalyst,0)) + 1)
	for remains: Dictionary in individuals:
		if remains.alive or remains.harvested or int(remains.cell) != int(b.cell) or int(remains.layer) < 4: continue
		if role(entry(b.species)) == "prey": continue
		var goods := harvest(remains)
		if float(goods.get("core",0)) > 0:
			b.medicine["beast_marrow"] = 1
			b.method = mini(3,int(b.method)+1)
			break

func repair_names() -> void:
	var seen := {}
	for b: Dictionary in individuals:
		if b.awakened and b.path == "latent": b.path = "spirit"
		var generic := "the %s of the eastern hills" % str(entry(b.species).name).to_lower()
		if str(b.name).to_lower() == generic or seen.has(b.name):
			var replacement := individual_name(entry(b.species))
			if not replacement.is_empty(): b.name = replacement
		seen[b.name] = true
		used_names[b.name] = true

## Fixed workplaces also work during headless simulation, when walkers are not animated.
func contact_place(store: RefCounted, person: int) -> Vector2:
	if int(store.hunger[person]) >= 3 and encounter_places.has("forest_edge"): return Vector2(encounter_places.forest_edge)
	for duty: String in store.schedules[store.job[person]]:
		if duty in config.encounter_duties and encounter_places.has(duty): return Vector2(encounter_places[duty])
	return Vector2(encounter_places.get("forest_edge",Vector2(config.hunt_center[0],config.hunt_center[1])))
