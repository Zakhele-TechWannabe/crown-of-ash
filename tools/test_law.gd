extends SceneTree
## Law geometry, sight, work passes, lethal fights, trails and permanent stone states.
const Combat = preload("res://src/combat.gd")
const Art = preload("res://src/guardian_art.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	map.life.set_process(false)
	var life: Node2D = map.life
	var s: RefCounted = life.population.society
	var law: RefCounted = s.law
	var center: Vector2i = life.sect.center
	assert(life.sect.inside_grounds(center + Vector2i(0, 15)), "Plaza is inside")
	assert(life.sect.inside_grounds(center + Vector2i(50, -36)), "Spring is inside")
	for b: Dictionary in life.sect.data.buildings:
		if b.kind != "cave": continue
		var r: Array = b.rect
		assert(life.sect.inside_grounds(center + Vector2i(int(r[0]), int(r[1]))), "Seclusion caves belong to the grounds")
	assert(not life.sect.inside_grounds(life.square), "Village is outside")
	assert(not life.sect.inside_grounds(Vector2i(1100, 2318)), "West Road is outside")
	assert(law.guardians.size() == 6, "Mountain, West and East gates each have two swordsmen: %d" % law.guardians.size())
	for g: Dictionary in law.guardians:
		assert(law.guardians[int(g.partner)].gate == g.gate, "Each post has a partner")
		assert(g.state == "guarding" and g.tile == g.post, "Starts on plinth")
		for at: Vector2i in g.night: assert(Vector2(at).distance_to(Vector2(g.post)) <= 6.0, "Night sight capped")
	var test_post: Vector2i = center + Vector2i(0, 20)
	assert(law.line_clear(test_post, center + Vector2i(0, 5)), "Open plaza has sight")
	assert(not law.line_clear(test_post, center + Vector2i(0, -26)), "Main hall blocks sight")
	var worker: Dictionary = life.people[2]
	var original: Vector2i = worker.work
	worker.work = law.nearest(center + Vector2i(0, 15))
	assert(law.has_pass(worker.id, worker.work, 540, 0), "Work pass during work hours")
	assert(not law.has_pass(worker.id, worker.work, 1380, 0), "No work pass at night")
	assert(not law.has_pass(worker.id, center + Vector2i(50, -36), 540, 0), "No pass elsewhere")
	worker.work = original
	var p: int = worker.id
	law.mark(p, "spring", 0)
	var entry: Dictionary = law.hunt_list[p]
	assert(is_equal_approx(law.priority(entry, 30), law.priority(entry, 0) / 2.0), "Priority halves in thirty days")
	law.advance(s, 22)
	assert(not law.hunt_list.has(p), "Cold trail dropped")
	var g: Dictionary = law.guardians[0]
	law.guardians[int(g.partner)].state = "pursuing"
	assert(not law.can_leave(g, 0), "Partner stays home")
	law.guardians[int(g.partner)].state = "guarding"
	g.energy = 20.0
	assert(not law.can_leave(g, 0), "Reserve is required")
	g.energy = 0.0
	law.freeze(s, g)
	law.advance(s, 23)
	assert(g.state == "frozen", "Frozen stone cannot recharge")
	g.state = "guarding"
	g.energy = 100.0
	# Wear carries into combat; only stone resting on its plinth mends.
	g.harm = 65.0
	assert(not law.can_leave(g, 0), "Wounded stone stays home")
	law.advance(s, 24)
	assert(is_equal_approx(g.harm, 63.0), "Plinth mends configured harm")
	g.tile = g.post + Vector2i(1, 0)
	law.advance(s, 25)
	assert(is_equal_approx(g.harm, 63.0), "No mending off plinth")
	g.state = "broken"
	g.tile = g.post
	law.advance(s, 26)
	assert(is_equal_approx(g.harm, 63.0), "Rubble never mends")
	var card: PanelContainer = map.ground_view.guardian_card
	card.open(g)
	assert(card.visible and card.guardian.state == "broken", "Rubble card opens")
	g.state = "guarding"
	g.harm = 35.0
	card.open(g)
	assert(card.visible and card.guardian.harm == 35.0, "Guardian card opens")
	card.hide()
	g.harm = 0.0
	law.last_day = 23
	var rng := RandomNumberGenerator.new()
	rng.seed = 781
	var mortal := {"name": "mortal", "person": 0, "power": 10.0, "guard": 10.0, "speed": 5.0, "breath": 8.0, "will": 9, "motive": "own", "lethal": true, "verb": "strikes"}
	var deaths := 0
	for i in 1000:
		var r := Combat.fight(Combat.beast("stone swordsman"), mortal, {"start_harm": [35.0, 0.0]}, rng)
		assert(r.harm[0] >= 35.0, "Fight starts from retained harm")
		if r.harm[1] >= 100.0: deaths += 1
	assert(deaths > 900, "Mortals almost always die once caught")
	var body: RefCounted = s.temper
	body.body_layer[p] = 9
	for i in 9: body.grades[p * 9 + i] = body.PERFECT
	life.population.birth_day[p] = life.population.day - 25 * 365
	for a in 3: life.population.attributes[p * 8 + a] = 10.0
	var perfected := Combat.person(s, p)
	print("LAW perfected fighter=%s" % perfected)
	perfected.lethal = true
	perfected.will = Combat.NEVER
	var wins := 0
	for i in 1000:
		var r := Combat.fight(Combat.beast("stone swordsman"), perfected, {}, rng)
		if r.harm[0] >= 100.0: wins += 1
	print("LAW perfected wins=%d/1000; day danger=%.3f night danger=%.3f" % [wins, law.danger(s, p, "plaza", false), law.danger(s, p, "plaza", true)])
	assert(wins > 250 and wins < 800, "Perfected Body can contest stone")
	# Standing in an open watched stretch isolates exposure from route length and terrain banks.
	var open_tile := Vector2i.ZERO
	var best_cover := INF
	for post: Dictionary in law.guardians:
		for at: Vector2i in post.sight:
			if law.blocked.has(at) or law.visible(at, true) or Vector2(at).distance_to(Vector2(post.post)) > 20.0: continue
			var c: float = law.cover(at, false)
			if c < best_cover:
				best_cover = c
				open_tile = at
	assert(open_tile != Vector2i.ZERO, "A watched open stretch exists")
	var actual_route: Array = law.route("plaza")
	law.routes["plaza"] = [open_tile]
	body.body_layer[p] = 0
	life.population.birth_day[p] = life.population.day - 25 * 365
	var seen := 0
	var killed := 0
	var night_seen := 0
	for i in 1000:
		s.alive[p] = 1
		s.injury_until[p] = 0
		for post: Dictionary in law.guardians:
			post.energy = 100.0
			post.harm = 0.0
			post.state = "guarding"
			post.tile = post.post
		var r: Dictionary = law.trespass(s, p, "plaza", false)
		if r.seen: seen += 1
		if r.outcome == "killed": killed += 1
		assert(r.seen or not law.hunt_list.has(p) or law.hunt_list[p].day == life.population.day, "Only sightings add trails")
		if r.outcome == "escaped": assert(law.hunt_list.has(p), "Seen escape leaves a trail")
		for post: Dictionary in law.guardians:
			post.state = "guarding"
			post.energy = 100.0
		s.alive[p] = 1
		var nr: Dictionary = law.trespass(s, p, "plaza", true)
		if nr.seen: night_seen += 1
	print("LAW open stretch: day seen=%d killed=%d; night seen=%d" % [seen, killed, night_seen])
	assert(seen > 500 and killed > seen / 2, "Most open daylight breaches are seen and most caught mortals die")
	assert(night_seen < seen / 3, "Darkness hides distant trespass")
	law.routes["plaza"] = actual_route
	body.body_layer[p] = 9
	var broken := false
	for i in 100:
		s.alive[p] = 1
		s.injury_until[p] = 0
		for a in 3: life.population.attributes[p * 8 + a] = 10.0
		g.state = "pursuing"
		g.energy = 100.0
		var result: Dictionary = law.battle(s, g, p)
		if g.state == "broken":
			broken = true
			break
	assert(broken, "A perfected fighter can actually break stone through Combat.fight")
	law.hunt_list.clear()
	law.advance(s, 24)
	assert(g.state == "broken" and not law.awake(g), "Broken stone stays broken")
	# A short reachable trail can be pursued; an adult tempered housemate joins.
	var escort: Dictionary = law.guardians[2]
	law.guardians[3].state = "guarding"
	escort.state = "guarding"
	escort.energy = 100.0
	escort.harm = 0.0
	var old_home: Vector2i = worker.home
	worker.home = law.nearest(escort.post)
	s.alive[p] = 1
	body.body_layer[p] = 0
	var q: int = (p + 1) % life.population.size()
	s.alive[q] = 1
	life.population.household[q] = life.population.household[p]
	life.population.birth_day[q] = life.population.day - 25 * 365
	body.body_layer[q] = 3
	law.mark(p, "spring", 25)
	var pursuits: int = law.totals.pursuits
	law.advance(s, 25)
	assert(law.totals.pursuits == pursuits + 1, "A nearby trail gets a daily pursuit")
	assert(s.breaches[-1].get("pursuit", false), "Village pursuit is staged from its breach record")
	assert(q in s.breaches[-1].fight.defenders, "Tempered adult kin join")
	worker.home = old_home
	life.minutes = 540.0
	life.breaches_seen = s.breach_count - 1
	life._advance_law(1.0)
	assert(not life.law_stages.is_empty() and worker.get("law_scene", false), "Village pursuit becomes a visible scene")
	assert(not worker.hidden and worker.activity == "facing a stone swordsman", "A defender is visible at home")
	life.start_skip(1)
	assert(life.law_stages.is_empty(), "Skipping closes active law scenes")
	life.cancel_skip()
	assert(life.breaches_seen == s.breach_count, "Skipping does not replay old breaches")
	var sheet := Image.create(22 * 5, 34, false, Image.FORMAT_RGBA8)
	var states := ["plinth", "guarding", "pursuing", "frozen", "broken"]
	for i in states.size(): sheet.blend_rect(Art.image(states[i]), Rect2i(0, 0, 22, 34), Vector2i(i * 22, 0))
	sheet.resize(880, 272, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute("res://out/ui")
	sheet.save_png("res://out/ui/guardian_sheet.png")
	var mask := Image.create(life.sect.bounds.size.x, life.sect.bounds.size.y, false, Image.FORMAT_RGBA8)
	for at: Vector2i in life.sect.grounds: mask.set_pixelv(at - center - life.sect.bounds.position, preload("res://src/palette.gd").JADE)
	mask.save_png("res://out/ui/grounds_mask.png")
	print("PASS law: grounds, gate pairs, sight, passes, lethal stone, trails, energy and permanent states")
	map.free()
	quit()
