extends SceneTree
## Body tempering: drills fill layers, gates hold, grades obey the method cap and the Perfect rule, strain injures.
const Population = preload("res://src/population.gd")

func _init() -> void:
	var p: RefCounted = Population.new()
	var j: int = p.register_job("field hand", ["fields"])
	var idle: int = p.register_job("scribe", ["chores"])
	for i in 30: p.add_person("Person %d" % i, 18 + i % 20, j if i < 20 else idle, i / 4)
	var s: RefCounted = p.society
	var t: RefCounted = s.temper
	assert(t != null, "Body tempering is enabled by default")
	s.seed()
	# Identical bodies isolate the root's hidden and revealed advantages.
	p.spirit_root[29] = 0
	t.hours[29] = 2
	t.regimen_until[29] = 1000
	var unrooted: float = t.rate(29, 1)
	p.spirit_root[29] = 1
	p.root_purity[29] = 100
	s.revealed[29] = 0
	var hidden: float = t.rate(29, 1)
	s.revealed[29] = 1
	assert(hidden > unrooted and t.rate(29, 1) > hidden, "Rooted bodies outpace unrooted; revealed beats hidden")
	for method in 4:
		t.body_layer[29] = 0
		t.method[29] = method
		assert(t.break_through(29, 1) <= int(t.config.method_grade_cap[method]), "Root quality never bypasses method cap")
	var base: float = t.config.grade_base
	var luck: float = t.config.luck
	t.config.grade_base = .98
	t.config.luck = 0.0
	p.constitution[29] = 0
	p.potential[29 * 8] = 10
	t.method[29] = 1
	t.teacher[29] = -1
	t.body_layer[29] = 0
	t.gate_since[29] = 1
	s.revealed[29] = 0
	var hidden_grade: int = t.break_through(29, 1)
	t.body_layer[29] = 0
	t.gate_since[29] = 1
	s.revealed[29] = 1
	assert(t.break_through(29, 1) > hidden_grade, "Revealed roots give a small grade quality push")
	t.config.grade_base = base
	t.config.luck = luck
	assert(not s.body_ready(29), "Qi still needs all nine layers")
	# Labour hardens a field hand through the first layers only.
	for w in 520: t.weekly(0, 7, 7 * w + 1)
	assert(t.body_layer[0] == 2 and t.grade(0, 1) == t.LOW, "Labour reaches Dense Flesh at Low grade (got layer %d)" % t.body_layer[0])
	assert(t.rate(0, 7 * 521) == 0.0 and t.gate_need(0) == "folk drills", "Past layer 2, labour is not enough: %s" % t.gate_need(0))
	# A scribe who never drills goes nowhere.
	for w in 100: t.weekly(25, 7, 7 * w + 1)
	assert(t.body_layer[25] == 0, "No drills and no labour, no tempering")
	# Drills with folk drills reach Steel Sinew but stop at the Iron Bone gate without a manual and medicine.
	t.method[1] = 1
	var observe: float = t.config.nature_manual_per_day
	t.config.nature_manual_per_day = 0.0
	var day := 1
	for w in 1500:
		day = 7 * w + 1
		if not t.training(1, day): t.start_regimen(1, 2, day)
		s.injury_until[1] = 0
		t.weekly(1, 7, day)
	assert(t.body_layer[1] == 3, "Folk drills reach Steel Sinew (got %d)" % t.body_layer[1])
	assert(t.gate_need(1) == "a tempering manual", "Iron Bone needs a manual: %s" % t.gate_need(1))
	for l in 3: assert(t.grade(1, l + 1) <= t.MIDDLE, "Folk drills cap the grade at Middle")
	# Nobody hands out manuals: one is written from watching nature.
	t.config.nature_manual_per_day = 1.0
	t.weekly(1, 7, day + 7)
	assert(t.method[1] == 2, "Watching nature writes a tempering manual")
	t.config.nature_manual_per_day = observe
	assert(t.gate_need(1) == "iron-bark baths", "Then it needs medicine: %s" % t.gate_need(1))
	t.medicine["iron_bark"][1] = 3
	assert(t.gate_need(1) == "iron-bark baths", "A bath takes four roots")
	t.medicine["iron_bark"][1] = 8
	t.aim_doses[1] = 2
	t.grades[1 * 9 + 2] = t.MIDDLE
	t.gate_since[1] = 1
	t.break_through(1, day + 400)
	assert(t.body_layer[1] == 4 and t.medicine["iron_bark"][1] == 0, "Medicine opens the gate and extra doses are used up: %d left" % t.medicine["iron_bark"][1])
	# The forest gives, runs out and regrows.
	var forest: RefCounted = t.wild
	var taken := 0
	var stripped := 0
	for trip in 40:
		var r: Dictionary = forest.gather_bark(6)
		taken += r.taken
		if r.taken == 0: stripped += 1
	assert(taken > 0 and stripped > 0, "Patches give roots and then are stripped (%d taken, %d stripped)" % [taken, stripped])
	var before: float = forest.bark_total()
	forest.week(365, 400)
	assert(forest.bark_total() > before, "Patches regrow over a year")
	var herd_before: float = forest.herd
	var kills := 0
	for h in 200: kills += int(forest.hunt(7).kill)
	assert(kills > 0 and forest.herd < herd_before, "Hunting thins the herd (%d kills)" % kills)
	# Someone near their next gate gathers for it through the brain.
	t.method[8] = 2
	t.body_layer[8] = 3
	t.tempering[8] = t.cost(4)
	forest.patch_stock.fill(8.0)
	assert(t.wanted_medicine(8) == "iron_bark", "Close to Iron Bone, they want iron-bark")
	var outcome: String = s.mind._act(8, {"option": s.mind.Option.GATHER, "target": -1, "medicine": "iron_bark"}, 500)
	assert(t.medicine["iron_bark"][8] > 0, "Gathering brings roots home: %s" % outcome)
	# Perfect is all or nothing: once a layer misses it, High is the ceiling for good.
	t.method[2] = 3
	p.constitution[2] = 1
	t.body_layer[2] = 2
	t.grades[2 * 9] = t.PERFECT
	t.grades[2 * 9 + 1] = t.PERFECT
	assert(t.grade_ceiling(2) == t.PERFECT, "Perfect foundation keeps Perfect open")
	t.grades[2 * 9 + 1] = t.HIGH
	assert(t.grade_ceiling(2) == t.HIGH, "A missed Perfect caps the rest at High")
	t.grades[2 * 9] = t.LOW
	t.grades[2 * 9 + 1] = t.LOW
	assert(t.grade_ceiling(2) == t.MIDDLE, "At most one grade above the layer below")
	# Too many hours without a teacher tears a sinew.
	t.method[3] = 1
	t.start_regimen(3, 4, 1)
	t.teacher[3] = -1
	t.regimen_until[3] = 100000
	var hurt := false
	for w in 30:
		t.weekly(3, 7, 7 * w + 2)
		if s.injury_until[3] > 7 * w + 2: hurt = true
	assert(hurt, "Overtraining injures")
	# The brain offers tempering and carries it out.
	var options: Array = s.mind._options(5, s.mind.urges(5))
	assert(options.any(func(o: Dictionary) -> bool: return o.option == s.mind.Option.TRAIN), "Training is an option")
	var record: String = s.mind._act(5, {"option": s.mind.Option.TRAIN, "target": -1, "hours": 2}, 10)
	assert(t.training(5, 11) and record.contains("drilled"), "Choosing to train starts a regimen")
	assert(s.lifespan(1) > 70, "Tempering lengthens a mortal life")
	print("BODY summary %s" % JSON.stringify(t.summary()))
	print("PASS test_body")
	quit()
