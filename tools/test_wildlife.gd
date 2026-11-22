extends SceneTree
const Wildlife = preload("res://src/wildlife.gd")
const Save = preload("res://src/world_save.gd")
const Population = preload("res://src/population.gd")
const Combat = preload("res://src/combat.gd")

func _initialize() -> void:
	var w := Wildlife.new()
	w.seed()
	assert(w.count()>0)
	assert(w.count("Panthera tigris")==0,"Absent species never spawn")
	for s: Dictionary in w.species:
		assert(s.cultivation_eligible and s.form_ids.size()==2 and not s.anatomy_tags.is_empty())
		assert(Combat.config.beasts.has(s.combat_profile_id))
	var names := {}
	for animal: Dictionary in w.individuals:
		assert(not names.has(animal.name), "Unique individual names")
		names[animal.name] = true
	var ledger := FileAccess.get_file_as_string("res://src/village_ledger.gd")
	for heading: String in ["Species catalogue", "Populations", "Awakened beasts", "Iron-bark patches", "Last year in the forest"]:
		assert(heading in ledger)
	assert('"LIFESPAN"' not in ledger)
	var silhouettes := {}
	var groups := {}
	for animal_species: Dictionary in w.species:
		if w.count(animal_species.sci) <= 0 or groups.has(animal_species.group): continue
		groups[animal_species.group] = true
		var texture: Texture2D = preload("res://src/beast_art.gd").texture(animal_species.group)
		var pixels := texture.get_image().get_data().hex_encode()
		assert(not silhouettes.has(pixels), "Distinct silhouette per present species group")
		silhouettes[pixels] = animal_species.group
	var n := w.count()
	var b := w.promote(36,"Cervus nippon")
	assert(not b.is_empty() and w.count()==n)
	assert(w.profile(b)==Combat.beast("sika deer"),"L0 parity")
	assert(w.demote(b) and w.count()==n,"Promotion and demotion conserve counts")
	b = w.promote(36,"Cervus nippon",true)
	assert(not w.demote(b),"Awakened identity is persistent")
	assert(w.hazard_probability(-1,1,1)==0 and w.hazard_probability(2,1,0)==0)
	var trials := 1000000
	var observed := 0
	var probability := w.hazard_probability(2,1,1)
	for i in trials: observed += int(w.awakening_rng.randf()<probability)
	assert(absf(observed-trials*probability)<5*sqrt(trials*probability),"Annual hazard statistical confidence")
	assert(is_equal_approx(1-pow(1-w.hazard_probability(2,1,1.0/365),365),probability),"Timestep invariant hazard")
	b.claim = 36
	b.condition = 1.0
	b.practice = 1.0
	b.work = 100.0
	assert(not w.try_breakthrough(b),"Work cannot bypass minimum time")
	w.day = 365
	assert(w.try_breakthrough(b))
	var grades: Array = b.grades.duplicate()
	assert(b.layer==1)
	var biological: float = b.biological_age
	w.daily(b)
	assert(b.biological_age>biological and b.biological_age<biological+1.0/365,"No rejuvenation")
	assert(is_equal_approx(w.lifespan(b),float(w.entry(b.species).lifespan_y)*1.2))
	w.update_path(b,0,false,true)
	assert(b.path!="demonic","One human kill never makes a demonic path")
	b.instability = .9
	b.purity = .1
	for i in 2: w.update_path(b,1)
	assert(b.path!="demonic")
	w.update_path(b,1)
	assert(b.path=="demonic")
	b.instability=0.0
	b.resentment=0.0
	b.purity=.9
	for i in 5: w.update_path(b,0)
	assert(b.path=="demonic","Recovery requires six secure months")
	w.update_path(b,0)
	assert(b.path=="spirit" and b.grades==grades,"Grades survive purification")
	b.layer=4
	b.grades=[1,1,1,1]
	b.method=3
	b.work=100
	b.layer_start=-10000
	b.medicine={}
	assert(not w.try_breakthrough(b),"Medicine remains mandatory")
	var forcing := w.rules.duplicate(true)
	w.rules.method_month_chance = 1.0
	w.rules.catalyst_month_chance = 1.0
	b.awakening_day = -10000
	b.method = 1
	b.layer = 3
	b.layer_start = -10000
	b.work = 100.0
	b.harm = 0.0
	w.acquire_instinct(b)
	assert(w.try_breakthrough(b) and b.layer > 3, "Natural catalysts and learned methods unlock layer four")
	w.rules = forcing
	b.alive=false
	var demon: Dictionary=b.duplicate(true)
	demon.path="demonic"
	var goods:=w.harvest(b)
	var tainted:=w.harvest(demon)
	assert(is_equal_approx(float(goods.core)+float(goods.tissues)+float(goods.lost),float(goods.essence)))
	assert(tainted.usable<goods.usable and tainted.tainted)
	assert(w.harvest(b).is_empty(),"No duplicate core")
	var event_beast:=w.promote(36,"Cervus nippon")
	w.exceptional_trial(event_beast,"storm")
	var rng_state:=w.awakening_rng.state
	w.exceptional_trial(event_beast,"storm")
	assert(w.awakening_rng.state==rng_state,"Exceptional event cannot reroll")
	assert(w.encounter_motive(b,"young")=="young")
	assert(w.encounter_motive(b,"quiet")=="flight")
	var tiger: Dictionary = b.duplicate(true)
	tiger.species="Panthera tigris"
	tiger.layer=9
	tiger.grades=[1,1,1,1,1,1,1,1,1]
	var stats:=w.profile(tiger)
	assert(is_equal_approx(float(stats.power),98.6) and is_equal_approx(float(stats.guard),64.02),"Independent L9 tiger arithmetic")
	assert(not w.try_breakthrough(tiger),"Body Tempering is terminal")
	tiger.alive=true
	tiger.condition=0.0
	tiger.harm=100.0
	w.daily(tiger)
	assert(not tiger.alive,"High layers remain vulnerable to wounds")
	var state:=Save.capture(w)
	var copy:=Wildlife.new()
	Save.restore(copy,state)
	assert(Save.capture(copy)==state)
	w.advance(w.day+30)
	copy.advance(copy.day+30)
	assert(Save.capture(w)==Save.capture(copy),"30-day deterministic continuation")
	var population:=Population.new()
	population.society.wildlife.seed(0)
	population.day=12345
	Save.repair_wildlife(population.society,{},population.day)
	assert(population.day==12345 and population.society.wildlife.day==12345 and population.society.wildlife.count()>0,"Existing worlds migrate at their current date")
	var exposed := Population.new()
	var job := exposed.register_job("forest worker", ["logs"])
	for i in 8: exposed.add_person("Worker %d" % i,25,job,i)
	exposed.society.seed()
	exposed.society.wildlife.seed()
	exposed.society.wildlife.encounter_places = {"logs":Vector2(100000,100000)}
	exposed.society.wildlife.encounter_near_work(exposed.society.wildlife.individuals[0])
	assert(exposed.society.wildlife.totals.encounters == 0, "Distant workers never meet a local animal")
	exposed.society.wildlife.encounter_places = {}
	exposed.society.wildlife.advance(3650)
	assert(exposed.society.wildlife.totals.encounters > 0, "Seeded decade includes wildlife encounters")
	# A rate, not a count: any change to the shared random stream moves single deaths around.
	assert(exposed.society.wildlife.totals.human_deaths <= maxi(2, roundi(exposed.society.wildlife.totals.encounters * 0.02)), "Seeded ordinary decade keeps deaths rare")
	print("ENCOUNTER10 ", exposed.society.wildlife.totals)
	var ecology:=Wildlife.new()
	ecology.seed()
	var before:=ecology.count("Cervus nippon")
	var refuge: float = ecology.config.prey_refuge_fraction
	ecology.config.prey_refuge_fraction=0.0
	var prey_eaten:=false
	for attempt in 20: prey_eaten = ecology.take_prey(36,ecology.entry("Canis lupus")) or prey_eaten
	assert(prey_eaten,"Available prey supports predation")
	ecology.config.prey_refuge_fraction=refuge
	assert(ecology.totals.predation>0)
	for i in 100:
		var target:=ecology.hunting_target()
		if not target.is_empty(): ecology.resolve_hunt(target,{"kill":true})
	assert(ecology.count("Cervus nippon")<before,"Hunting draws real animals")
	var recovery:=Wildlife.new()
	Save.restore(recovery,Save.capture(ecology))
	recovery.config=ecology.config.duplicate(true)
	recovery.config.predator_groups=[]
	var depleted:=recovery.count("Cervus nippon")
	recovery.advance(365*5)
	assert(recovery.count("Cervus nippon")>depleted,"Deer recover after hunting stops")
	var thinned:=ecology.count("Cervus nippon")
	ecology.advance(365*50)
	print("WILDLIFE50 ",JSON.stringify(ecology.summary()))
	assert(ecology.count()>0 and ecology.count()<100000,"Bounded 50-year ecosystem")
	assert(ecology.count("Cervus nippon")>100,"Deer persist through predator pressure")
	assert(ecology.totals.births>0 and ecology.totals.awakenings>0)
	print("PASS wildlife: schema, hazards, conservation, gates, lifespan, paths, remains, persistence, hunting and 50 years")
	quit()
