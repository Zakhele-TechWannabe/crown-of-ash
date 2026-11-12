extends SceneTree
## The brain and heart: inheritance, scars, emotions, decisions with reasons, and a cost benchmark.
const Population = preload("res://src/population.gd")

func _init() -> void:
	var p: RefCounted = Population.new()
	var j: int = p.register_job("field hand", ["fields"])
	for i in 40: p.add_person("Person %d" % i, 18 + i % 30, j, i / 4)
	var s: RefCounted = p.society
	var mind: RefCounted = s.mind
	assert(mind != null, "Mind is enabled by default")
	s.seed()
	# Hearts: founders are distinct; a child sits near the parents' average.
	var a: PackedFloat32Array = mind.urges(0)
	var b: PackedFloat32Array = mind.urges(1)
	assert(a != b, "Founders have their own temperaments")
	p.sex[0] = 1
	p.sex[1] = 0
	s.spouse[0] = 1
	s.spouse[1] = 0
	var child: int = p.add_child("Wang Lan", 0, 1)
	var close := 0
	for i in mind.WEIGHTS:
		var mean: float = (mind.weight(0, i) + mind.weight(1, i)) / 2.0
		if absf(mind.weight(child, i) - mean) < 0.6: close += 1
	assert(close > mind.WEIGHTS * 0.95, "Child heart blends parents with small mutation (%d close)" % close)
	# Scars change the heart for life.
	var before: float = mind.weight(2, mind.B2 + mind.FEAR)
	s.social_event(2, 3, "betrayal")
	assert(mind.weight(2, mind.B2 + mind.FEAR) > before, "Betrayal leaves a lasting wariness")
	assert(mind.emotion[2 * 4 + mind.ANGER] > 0.5 and mind.interrupt[2] == 1, "Betrayal angers and interrupts")
	# Emotions fade with momentum: anger quickly, grief slowly.
	mind.emotion[4 * 4 + mind.ANGER] = 1.0
	mind.emotion[4 * 4 + mind.GRIEF] = 1.0
	for w in 8: mind.weekly(4, 7, 7 * w + 3, 40)
	assert(mind.emotion[4 * 4 + mind.ANGER] < 0.15 and mind.emotion[4 * 4 + mind.GRIEF] > 0.85, "Anger fades in weeks, grief over a year")
	# Decisions carry reasons, and people differ.
	for i in 40:
		s.ties.event(i, (i + 1) % 40, "saved_life", 1)
		s.ties.event(i, (i + 3) % 40, "saved_life", 1)
	var kinds: Dictionary = {}
	for round in 12:
		for i in 40:
			var record: Dictionary = mind.decide(i, 30 + round)
			assert(not record.reasons.is_empty() and record.urges.size() == 2, "Every decision keeps its reasons")
			kinds[record.option] = true
	assert(kinds.size() >= 3, "People choose differently: %s" % str(kinds.keys()))
	# A grudge makes confronting or reconciling possible.
	var e: int = s.ties.tie(5, 6)
	s.ties.opinion[e] = -70
	s.ties.set_grudge(e, 70, "theft", false)
	var options: Array = mind._options(5, mind.urges(5))
	var names: Array = options.map(func(o: Dictionary) -> int: return o.option)
	assert(mind.Option.CONFRONT in names and mind.Option.RECONCILE in names, "Grudges open confront and reconcile")
	var described: Dictionary = mind.describe(5)
	assert(described.feelings.size() == 4 and described.urges.size() == 2)
	# Cost: decisions per millisecond on this machine.
	var big: RefCounted = Population.new()
	var bj: int = big.register_job("field hand", ["fields"])
	for i in 2000: big.add_person("P%d" % i, 18 + i % 40, bj, i / 5)
	for i in 2000:
		for k in 8: big.society.ties.event(i, (i * 7 + k * 13 + 1) % 2000, "shared_work", 1)
	var began := Time.get_ticks_usec()
	for i in 2000: big.society.mind.decide(i, 100)
	var per := (Time.get_ticks_usec() - began) / 2000.0
	print("BENCH MIND decision_us=%.1f per_week_2000=%.1fms per_week_100k_monthly=%.0fms" % [per, per * 2000 / 4 / 1000.0, per * 100000 / 26 / 1000.0])
	assert(per < 400.0, "A decision stays well under half a millisecond")
	print("PASS mind")
	quit()
