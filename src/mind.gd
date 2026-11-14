extends RefCounted
## How people decide. The brain scores the options that fit a person's life (each a product of 0–1 questions);
## the heart, a tiny inherited network that is never trained, pushes those scores with urges nobody designed.
## Emotions carry momentum between decisions, life goals bias choices for years, and every decision keeps its reasons.
## Cost: one decision per person every few weeks (staggered), or at once when a strong feeling interrupts.
const Combat = preload("res://src/combat.gd")
const INPUTS := 16
const HIDDEN := 8
const URGES := 8
const W1 := 0
const B1 := INPUTS * HIDDEN
const W2 := B1 + HIDDEN
const B2 := W2 + HIDDEN * URGES
const WEIGHTS := B2 + URGES
const SCALE := 32.0
const URGE_NAMES := ["spite", "longing", "fear", "pride", "restlessness", "devotion", "ambition", "curiosity"]
const INPUT_NAMES := ["mood", "hunger", "anger", "grief", "joy", "fear", "age", "loneliness", "masterless", "spirit root",
	"realm", "reputation", "grudge", "friendship", "children", "bias"]
const EMOTIONS := ["anger", "grief", "joy", "fear"]
enum {SPITE, LONGING, FEAR, PRIDE, RESTLESS, DEVOTION, AMBITION, CURIOSITY}
enum {ANGER, GRIEF, JOY, AFRAID}
enum Option {ROUTINE, COURT, SEEK_MASTER, CULTIVATE, EXPLORE, CONFRONT, RECONCILE, HELP, GOSSIP, TRAIN, GATHER, HUNT}
const OPTION_NAMES := ["keep to the daily routine", "court", "seek a master", "cultivate in earnest", "explore the wilds",
	"confront", "make peace with", "help", "gossip about", "temper the body", "gather tempering herbs", "hunt a beast for marrow"]
enum Goal {NONE, MARRY, FIND_MASTER, ASCEND, MASTER_CRAFT, AVENGE, PROVIDE, TEMPER}
const GOAL_NAMES := ["", "find a spouse", "find a master", "break through", "master a craft", "settle a grudge", "provide for the family", "temper the body"]
const GOAL_OPTION := [-1, Option.COURT, Option.SEEK_MASTER, Option.CULTIVATE, Option.ROUTINE, Option.CONFRONT, Option.HELP, Option.TRAIN]

var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/mind.json"))
var society_ref: WeakRef
var heart := PackedByteArray()
var heart_ready := PackedByteArray()
var emotion := PackedFloat32Array()
var goal := PackedByteArray()
var goal_target := PackedInt32Array()
var goal_since := PackedInt32Array()
var interrupt := PackedByteArray()
var last_choice := PackedByteArray()
var child_count := PackedByteArray()
var refused_until := PackedInt32Array()
var recent: Array[Dictionary] = []
var decisions := 0
var choice_counts := PackedInt32Array()
var decide_usec := 0
var _tanh := PackedFloat32Array()
var _sigmoid := PackedFloat32Array()
var _trait_bias: Dictionary = {}

func _init(society: RefCounted) -> void:
	society_ref = weakref(society)
	choice_counts.resize(Option.size())
	# Lookup-table curves keep transcendental maths out of the decision loop.
	for i in 257:
		var x := (i - 128) / 32.0
		_tanh.append(tanh(x))
		_sigmoid.append(1.0 / (1.0 + exp(-x)))
	for id: String in config.trait_urges:
		var bias := PackedFloat32Array()
		bias.resize(URGES)
		for urge: String in config.trait_urges[id]: bias[URGE_NAMES.find(urge)] = float(config.trait_urges[id][urge])
		_trait_bias[id] = bias

func add_person() -> void:
	heart.resize(heart.size() + WEIGHTS)
	heart_ready.append(0)
	for e in 4: emotion.append(0.0)
	goal.append(Goal.NONE)
	goal_target.append(-1)
	goal_since.append(0)
	interrupt.append(0)
	last_choice.append(Option.ROUTINE)
	child_count.append(0)
	refused_until.append(0)

func _curve(table: PackedFloat32Array, x: float) -> float:
	return table[clampi(int(x * 32.0) + 128, 0, 256)]

func _set_weight(p: int, i: int, value: float) -> void:
	heart.encode_s8(p * WEIGHTS + i, clampi(roundi(value * SCALE), -127, 127))

func weight(p: int, i: int) -> float:
	return heart.decode_s8(p * WEIGHTS + i) / SCALE

## Founders get a random temperament shaped by their traits; it is theirs for life.
func _found_heart(p: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var spread := float(config.founder_weight_spread)
	for i in WEIGHTS: _set_weight(p, i, store.rng.randfn(0.0, spread))
	for id: String in _trait_bias:
		if store.has_trait(p, id):
			var bias: PackedFloat32Array = _trait_bias[id]
			for u in URGES: _set_weight(p, B2 + u, weight(p, B2 + u) + bias[u])
	heart_ready[p] = 1

## A child's heart blends both parents' and mutates, so families grow temperaments nobody designed.
func inherit(child: int, mother: int, father: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	for parent: int in [mother, father]:
		if parent >= 0 and not heart_ready[parent]: _found_heart(parent)
	for parent: int in [mother, father]:
		if parent >= 0: child_count[parent] = mini(255, child_count[parent] + 1)
	var mutation := float(config.mutation)
	for i in WEIGHTS:
		var total := 0.0
		var count := 0
		for parent: int in [mother, father]:
			if parent >= 0:
				total += weight(parent, i)
				count += 1
		_set_weight(child, i, (total / count if count else 0.0) + store.rng.randfn(0.0, mutation))
	heart_ready[child] = 1

## Strong experiences leave a lasting mark on the heart (a betrayal makes someone wary for life).
func scar(p: int, urge: int, amount: float) -> void:
	if not heart_ready[p]: _found_heart(p)
	_set_weight(p, B2 + urge, weight(p, B2 + urge) + amount)

func feel(p: int, which: int, amount: float) -> void:
	var at := p * 4 + which
	emotion[at] = clampf(emotion[at] + amount, 0.0, 1.0)
	if emotion[at] >= float(config.interrupt_emotion): interrupt[p] = 1

func inputs(p: int) -> PackedFloat32Array:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var ties: RefCounted = society.ties
	var x := PackedFloat32Array()
	x.resize(INPUTS)
	var years: int = store.age(p)
	x[0] = store.mood[p]
	x[1] = minf(store.hunger[p] / 4.0, 1.0)
	for e in 4: x[2 + e] = emotion[p * 4 + e]
	x[6] = minf(years / 80.0, 1.0)
	x[7] = 1.0 if years >= 18 and society.spouse[p] < 0 else 0.0
	x[8] = 1.0 if years >= 12 and years < 35 and society.master[p] < 0 else 0.0
	x[9] = float(society.revealed[p])
	x[10] = society.realm[p] / 5.0
	x[11] = clampf(society.reputation[p] / 100.0, -1.0, 1.0)
	var grudge := 0.0
	var friend := 0.0
	var e: int = ties.head[p]
	while e >= 0:
		friend = maxf(friend, ties.opinion[e])
		if ties.has_grudge(e): grudge = maxf(grudge, ties.grudge_intensity(e))
		e = ties.next[e]
	x[12] = minf(grudge / 100.0, 1.0)
	x[13] = maxf(friend, 0.0) / 100.0
	x[14] = minf(child_count[p] / 4.0, 1.0)
	x[15] = 1.0
	return x

func urges(p: int) -> PackedFloat32Array:
	if not heart_ready[p]: _found_heart(p)
	var x := inputs(p)
	var hidden := PackedFloat32Array()
	hidden.resize(HIDDEN)
	var base := p * WEIGHTS
	for h in HIDDEN:
		var sum := heart.decode_s8(base + B1 + h) / SCALE
		for i in INPUTS: sum += x[i] * heart.decode_s8(base + W1 + h * INPUTS + i) / SCALE
		hidden[h] = _curve(_tanh, sum)
	var out := PackedFloat32Array()
	out.resize(URGES)
	for u in URGES:
		var sum := heart.decode_s8(base + B2 + u) / SCALE
		for h in HIDDEN: sum += hidden[h] * heart.decode_s8(base + W2 + u * HIDDEN + h) / SCALE
		out[u] = _curve(_sigmoid, sum)
	return out

## Weekly upkeep for everyone (emotions fade); a full decision on the person's turn or after an interrupt.
func weekly(p: int, days: int, on_day: int, n: int) -> void:
	var decay: Dictionary = config.emotion_decay_per_week
	var weeks := days / 7.0
	for e in 4: emotion[p * 4 + e] *= pow(1.0 - float(decay[EMOTIONS[e]]), weeks)
	var society: RefCounted = society_ref.get_ref()
	if society.population.age(p) < 12: return
	var every := int(config.decide_every_weeks) if n <= int(config.large_population) else int(config.large_decide_every_weeks)
	if interrupt[p] or (p + on_day / 7) % maxi(1, every) == 0:
		interrupt[p] = 0
		decide(p, on_day)

func decide(p: int, on_day: int) -> Dictionary:
	var began := Time.get_ticks_usec()
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var urge := urges(p)
	_review_goal(p, urge, on_day)
	var options: Array[Dictionary] = _options(p, urge)
	var best := 0
	for i in options.size():
		if options[i].score > options[best].score: best = i
	var chosen: Dictionary = options[best]
	var impulse := ""
	var impulsiveness := 0.1 + 0.4 * urge[RESTLESS] + (0.2 if store.has_trait(p, "impulsive") else 0.0)
	if store.rng.randf() < float(config.pure_impulse):
		chosen = options[store.rng.randi_range(0, options.size() - 1)]
		impulse = "a sudden impulse"
	elif options.size() > 1 and store.rng.randf() < impulsiveness:
		# Impulsive people take a near-best option, weighted by score.
		var pool: Array[Dictionary] = []
		var total := 0.0
		for option: Dictionary in options:
			if option.score >= options[best].score * float(config.near_best):
				pool.append(option)
				total += option.score
		var roll: float = store.rng.randf() * total
		for option: Dictionary in pool:
			roll -= option.score
			if roll <= 0:
				chosen = option
				break
		if chosen != options[best]: impulse = "impulse"
	var outcome := _act(p, chosen, on_day)
	decisions += 1
	choice_counts[chosen.option] += 1
	last_choice[p] = chosen.option
	var top := _top_urges(urge)
	var record := {"day": on_day, "person": p, "option": OPTION_NAMES[chosen.option], "target": chosen.target, "score": snappedf(chosen.score, .01),
		"reasons": chosen.reasons, "urges": top, "goal": GOAL_NAMES[goal[p]], "impulse": impulse, "outcome": outcome,
		"alternatives": _alternatives(options, chosen)}
	recent.append(record)
	if recent.size() > int(config.recent_decisions): recent.pop_front()
	if chosen.option != Option.ROUTINE and society.archive: society.archive.decision(record)
	decide_usec += Time.get_ticks_usec() - began
	return record

func _top_urges(urge: PackedFloat32Array) -> Array:
	var order: Array = range(URGES)
	order.sort_custom(func(a: int, b: int) -> bool: return urge[a] > urge[b])
	return [[URGE_NAMES[order[0]], snappedf(urge[order[0]], .01)], [URGE_NAMES[order[1]], snappedf(urge[order[1]], .01)]]

func _alternatives(options: Array[Dictionary], chosen: Dictionary) -> Array:
	var rest: Array = []
	for option: Dictionary in options:
		if option != chosen: rest.append([OPTION_NAMES[option.option], snappedf(option.score, .01)])
	rest.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rest.slice(0, 3)

## Score = product of the brain's questions × the heart's push × mood momentum × the life goal's pull.
func _option(p: int, kind: int, target: int, questions: Array, push: Dictionary, urge: PackedFloat32Array) -> Dictionary:
	var society: RefCounted = society_ref.get_ref()
	var trip := "day"
	if society.law and society.population.settlement[p] == 0 and (kind == Option.CULTIVATE or (kind == Option.GATHER and society.temper.wanted_medicine(p) == "seven_leaf")):
		var law: RefCounted = society.law
		var caution := clampf(float(law.config.caution_base) + float(law.config.caution_base) * emotion[p * 4 + AFRAID] - float(law.config.drive_discount) * (urge[AMBITION] + urge[SPITE] + urge[PRIDE] + minf(society.population.hunger[p], 1.0)), 0.0, 1.0)
		trip = "night" if caution >= float(law.config.night_caution) else "day"
		var place := "spring" if kind == Option.CULTIVATE and society.realm[p] < 2 else ("peak" if kind == Option.CULTIVATE else "seven_leaf")
		questions.append(["safe from the guardians", 1.0 - law.danger(society, p, place, trip == "night") * caution])
	var score := 1.0
	for q: Array in questions: score *= clampf(q[1], 0.0, 1.0)
	var heart_push := 1.0
	var strongest := ""
	var strongest_value := 0.0
	for name: String in push:
		var effect: float = float(push[name]) * (urge[URGE_NAMES.find(name)] - 0.5) * 2.0
		heart_push += effect * 0.5
		if effect > strongest_value:
			strongest_value = effect
			strongest = name
	score *= clampf(heart_push, 0.15, 2.5)
	var anger := emotion[p * 4 + ANGER]
	var grief := emotion[p * 4 + GRIEF]
	var joy := emotion[p * 4 + JOY]
	var fear := emotion[p * 4 + AFRAID]
	match kind:
		Option.ROUTINE: score *= 1.0 + 0.6 * fear + 0.4 * grief
		Option.CONFRONT, Option.GOSSIP: score *= (1.0 + anger) * (1.0 - 0.5 * fear)
		Option.COURT, Option.HELP: score *= (1.0 - 0.5 * anger) * (1.0 + 0.5 * joy) * (1.0 - 0.5 * grief)
		Option.EXPLORE: score *= (1.0 - 0.7 * fear) * (1.0 + 0.3 * joy) * (1.0 - 0.5 * grief)
		_: score *= 1.0 - 0.4 * grief
	if goal[p] != Goal.NONE and (GOAL_OPTION[goal[p]] == kind or (goal[p] == Goal.TEMPER and kind in [Option.GATHER, Option.HUNT])): score *= float(config.goal_bonus)
	var reasons: Array = []
	for q: Array in questions: reasons.append([q[0], snappedf(q[1], .01)])
	if not strongest.is_empty(): reasons.append(["heart: " + strongest, snappedf(strongest_value, .01)])
	if anger >= .3: reasons.append(["anger", snappedf(anger, .01)])
	if grief >= .3: reasons.append(["grief", snappedf(grief, .01)])
	if joy >= .3: reasons.append(["joy", snappedf(joy, .01)])
	if fear >= .3: reasons.append(["fear", snappedf(fear, .01)])
	return {"option": kind, "target": target, "score": score, "trip": trip, "reasons": reasons}

## Training still makes sense without a method (that is how drills are learned), much less while waiting on medicine.
func _way_forward(temper: RefCounted, lacking: String) -> float:
	if lacking.is_empty() or lacking == "drills": return 1.0
	return float(config.train_without_medicine) if lacking in temper.config.medicine_names.values() else float(config.train_without_method)

func _ramp(x: float, low: float, high: float) -> float:
	return clampf((x - low) / (high - low), 0.0, 1.0)

func _options(p: int, urge: PackedFloat32Array) -> Array[Dictionary]:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var ties: RefCounted = society.ties
	var years: int = store.age(p)
	var mood: float = store.mood[p]
	var options: Array[Dictionary] = []
	# Habit: most weeks most people simply do their work; something has to pull them away.
	var routine := _option(p, Option.ROUTINE, -1, [["contentment", 0.4 + 0.6 * mood]], {"restlessness": -0.8, "ambition": -0.3}, urge)
	routine.score *= float(config.habit)
	options.append(routine)
	# One pass over the person's ties finds every candidate target.
	var sweetheart := -1
	var sweet_opinion := 10.0
	var teacher := -1
	var teacher_value := 0.0
	var foe := -1
	var foe_opinion := -10.0
	var friend := -1
	var friend_opinion := 30.0
	var needy := -1
	var e: int = ties.head[p]
	while e >= 0:
		var other: int = ties.target[e]
		var opinion: float = ties.opinion[e]
		if society.alive[other] and store.settlement[other] == store.settlement[p]:
			if years >= 16 and society.spouse[p] < 0 and society.spouse[other] < 0 and store.sex[other] != store.sex[p] and opinion > sweet_opinion \
					and store.age(other) >= 16 and absi(store.age(other) - years) <= int(society.events.marriage_age_gap) and not society.marriage_related(p, other):
				sweetheart = other
				sweet_opinion = opinion
			if opinion >= 20 and society.master[p] < 0 and years < 35 and refused_until[p] <= store.day:
				var standing: float = society.realm[other] * 20.0 + store.best_level[other] - store.best_level[p]
				if standing > teacher_value:
					teacher = other
					teacher_value = standing
			if opinion < foe_opinion or (ties.has_grudge(e) and opinion < 0):
				foe = other
				foe_opinion = opinion
			if opinion > friend_opinion:
				friend = other
				friend_opinion = opinion
			if opinion >= 20 and (store.hunger[other] > 0 or society.injury_until[other] > store.day): needy = other
		e = ties.next[e]
	if sweetheart >= 0:
		options.append(_option(p, Option.COURT, sweetheart, [["feelings", _ramp(sweet_opinion, 0, 50)], ["age", 1.0 if years >= 18 and years <= 45 else 0.4],
			["loneliness", 0.6 + 0.4 * float(years >= 18)]], {"longing": 1.2, "fear": -0.5, "pride": -0.2}, urge))
	if teacher >= 0:
		options.append(_option(p, Option.SEEK_MASTER, teacher, [["respect", _ramp(ties.opinion[ties.find(p, teacher)], 15, 60)],
			["what they could teach", _ramp(teacher_value, 0, 12)], ["youth", 1.0 if years < 25 else 0.5]], {"ambition": 1.0, "devotion": 0.5, "pride": -0.4}, urge))
	options.append(_option(p, Option.CULTIVATE, -1, [["spirit root", 1.0 if society.revealed[p] else (0.1 if society.temper else 0.25)], ["health", 0.0 if society.injury_until[p] > store.day else 1.0],
		["free time", 1.0 - minf(store.hunger[p] / 2.0, 1.0)]], {"ambition": 1.0, "pride": 0.4, "curiosity": 0.2}, urge))
	if years >= 14 and years <= 60 and not society.fifty.member(p):
		options.append(_option(p, Option.EXPLORE, -1, [["daring", 1.0 - 0.7 * emotion[p * 4 + AFRAID]], ["fed", 1.0 if store.hunger[p] == 0 else 0.3],
			["time away from work", float(config.explore_time_away)]],
			{"curiosity": 1.0, "restlessness": 0.8, "fear": -1.0}, urge))
	if foe >= 0:
		var grievance := _ramp(-foe_opinion, 10, 80)
		options.append(_option(p, Option.CONFRONT, foe, [["grievance", grievance], ["temper", 0.3 + 0.7 * emotion[p * 4 + ANGER]]],
			{"spite": 1.2, "pride": 0.6, "fear": -0.8, "devotion": -0.3}, urge))
		options.append(_option(p, Option.RECONCILE, foe, [["grievance", grievance], ["calm", 1.0 - emotion[p * 4 + ANGER]], ["willingness", 0.5]],
			{"devotion": 1.0, "pride": -0.8, "spite": -0.8}, urge))
		if friend >= 0 and friend != foe:
			options.append(_option(p, Option.GOSSIP, foe, [["dislike", _ramp(-foe_opinion, 0, 60)], ["a willing ear", _ramp(friend_opinion, 30, 80)]],
				{"spite": 0.8, "curiosity": 0.4, "devotion": -0.4}, urge))
	var temper: RefCounted = society.temper
	if temper and years >= 12 and years <= int(config.temper_max_age) and temper.body_layer[p] < temper.LAYERS:
		var at_gate: bool = temper.at_gate(p)
		var lacking: String = temper.gate_need(p) if at_gate else ""
		var train := _option(p, Option.TRAIN, -1, [["health", 0.0 if society.injury_until[p] > store.day else 1.0], ["rested", 1.0 - minf(temper.strain[p], 1.0)],
			["time after work", float(config.train_time_after_work)], ["a way forward", _way_forward(temper, lacking)],
			["already drilling", float(config.train_renew) if temper.training(p, store.day) else 1.0]], {"ambition": 1.0, "pride": 0.6, "restlessness": 0.3, "fear": -0.3}, urge)
		train["hours"] = 1 + roundi(2.0 * urge[AMBITION] + urge[PRIDE])
		options.append(train)
		# Stuck at a gate for want of medicine, the daily routine stops feeling like enough.
		if at_gate and lacking in temper.config.medicine_names.values(): options[0].score *= float(config.routine_when_blocked)
		# Ambitious, proud people lay in extra doses to forge a better grade, if their body can still reach High.
		var drive: float = urge[AMBITION] + urge[PRIDE]
		if not society.fifty.member(p): temper.aim_doses[p] = 1 if temper.grade_ceiling(p) < temper.HIGH else 1 + int(drive > 1.1) + int(drive > 1.4)
		var want: String = temper.wanted_medicine(p)
		var urgency := 1.0 if at_gate else 0.6
		var away: float = float(config.gate_time_away) if at_gate else float(config.explore_time_away)
		if want == "beast_marrow":
			options.append(_option(p, Option.HUNT, -1, [["need", urgency], ["health", 0.0 if society.injury_until[p] > store.day else 1.0],
				["nerve", 1.0 - 0.7 * emotion[p * 4 + AFRAID]], ["strength", 0.6 + _ramp(store.attributes[p * 8], 8, 16) * 0.4], ["time away from work", away]],
				{"ambition": 0.8, "restlessness": 0.5, "pride": 0.4, "fear": -1.0}, urge))
		elif not want.is_empty():
			var gather := _option(p, Option.GATHER, -1, [["need", urgency], ["health", 0.0 if society.injury_until[p] > store.day else 1.0], ["time away from work", away]],
				{"ambition": 0.8, "curiosity": 0.3, "fear": -0.2}, urge)
			gather["medicine"] = want
			options.append(gather)
	var helped := needy if needy >= 0 else friend
	if helped >= 0:
		options.append(_option(p, Option.HELP, helped, [["need", 1.0 if helped == needy else float(config.visit_friend_need)], ["bond", _ramp(ties.opinion[ties.find(p, helped)], 20, 80)]],
			{"devotion": 1.0, "ambition": -0.2}, urge))
	return options

## Carries out the choice through the society's own rules, so a decision can still fail.
func _act(p: int, chosen: Dictionary, on_day: int) -> String:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var ties: RefCounted = society.ties
	var t: int = chosen.target
	match chosen.option:
		Option.COURT:
			ties.event(p, t, "courtship", on_day)
			# Courtship only warms the other side if they are not cold to it.
			var back: int = ties.find(t, p)
			if back < 0 or ties.opinion[back] > -10: ties.event(t, p, "courtship", on_day)
			if society.marry(p, t):
				feel(p, JOY, 0.6)
				feel(t, JOY, 0.6)
				return "married"
			return "courting"
		Option.SEEK_MASTER:
			if society.accept(t, p):
				feel(p, JOY, 0.4)
				return "accepted"
			feel(p, ANGER, 0.05)
			# A refusal stings; they will not ask anyone again for a while.
			refused_until[p] = on_day + int(config.refusal_cooldown_days)
			return "refused"
		Option.CULTIVATE:
			if society.law and store.settlement[p] == 0:
				var breach: Dictionary = society.law.trespass(society, p, "spring" if society.realm[p] < 2 else "peak", chosen.get("trip", "night") == "night")
				if breach.seen: return "guardians: " + str(breach.outcome)
			society.site[p] = maxi(society.site[p], 1 if society.realm[p] < 2 else 2)
			society.cultivate(p, 3)
			if society.fifty.member(p): return "meditated at the terrace qi seat"
			return "meditated at a qi spot" if society.revealed[p] else "sat in meditation"
		Option.EXPLORE:
			if store.rng.randf() < float(config.explore_injury):
				society.injury_until[p] = on_day + store.rng.randi_range(14, 60)
				feel(p, AFRAID, 0.4)
				return "hurt in the wilds"
			if not society.revealed[p] and store.spirit_root[p] and store.rng.randf() < float(config.explore_spirit_fruit):
				society.awaken(p, "a spirit fruit found while exploring the Eastern Hunting Grounds")
				return "found a spirit fruit"
			if society.technique[p] < 2 and store.rng.randf() < float(config.explore_manual):
				society.technique[p] = maxi(society.technique[p], 1)
				society.technique_element[p] = store.rng.randi_range(0, 9)
				society.note(p, "manual", "%s found a damaged Yellow breathing manual while exploring" % store.names[p])
				return "found a manual"
			if society.temper and society.temper.method[p] < 2 and store.rng.randf() < float(society.temper.config.explore_tempering_manual):
				society.temper.method[p] = 2
				society.note(p, "tempering_method", "%s found a tempering manual in ruins while exploring" % store.names[p])
				return "found a tempering manual"
			feel(p, JOY, 0.1)
			return "came back with nothing but stories"
		Option.CONFRONT:
			var anger: float = emotion[p * 4 + ANGER]
			emotion[p * 4 + ANGER] *= 0.4
			var target_urges := urges(t)
			if target_urges[SPITE] > 0.6 or target_urges[PRIDE] > 0.7:
				ties.event(p, t, "festival_insult", on_day)
				ties.event(t, p, "festival_insult", on_day)
				feel(t, ANGER, 0.4)
				# Angry enough, a bitter quarrel comes to blows.
				if store.rng.randf() < float(Combat.config.bitter_blows) * (0.5 + anger):
					Combat.between(society, p, t, "brawl")
					return "came to blows" if society.alive[p] else "was killed"
				society.childhood.parent_fight(t)
				society.note(p, "confrontation", "%s confronted %s and it turned bitter" % [store.names[p], store.names[t]])
				return "it turned bitter"
			Combat.between(society, p, t, "spar")
			return "settled in a duel"
		Option.RECONCILE:
			ties.event(p, t, "apology", on_day)
			var back: int = ties.find(t, p)
			if back >= 0 and ties.opinion[back] > -60:
				ties.event(t, p, "mediation", on_day)
				society.note(p, "reconciliation", "%s made peace with %s" % [store.names[p], store.names[t]])
				return "peace made"
			return "rebuffed"
		Option.HELP:
			ties.event(t, p, "kindness", on_day)
			society.reputation[p] = minf(100.0, society.reputation[p] + 0.5)
			feel(p, JOY, 0.1)
			return "helped"
		Option.GOSSIP:
			# The rumour reaches one listener and becomes their belief, true or not.
			var listener := -1
			var best := 30.0
			var e: int = ties.head[p]
			while e >= 0:
				if ties.target[e] != t and ties.opinion[e] > best:
					best = ties.opinion[e]
					listener = ties.target[e]
				e = ties.next[e]
			if listener >= 0:
				var heard: int = ties.tie(listener, t)
				if heard >= 0: ties.opinion[heard] = maxf(-100.0, ties.opinion[heard] - 4.0)
				ties.event(listener, p, "meal", on_day)
			society.reputation[t] = maxf(-100.0, society.reputation[t] - 0.5)
			return "spread a rumour"
		Option.TRAIN:
			var regimen: String = society.temper.start_regimen(p, int(chosen.get("hours", 2)), on_day)
			# Now and then the drills end in a spar with a friend or rival: it stops at hurt, and builds the tie.
			if store.rng.randf() < float(Combat.config.training_spar):
				var partner := _sparring_partner(p, on_day)
				if partner >= 0:
					Combat.between(society, p, partner, "spar")
					return regimen + ", then sparred"
			return regimen
		Option.GATHER:
			var temper: RefCounted = society.temper
			if chosen.get("medicine", "") == "seven_leaf":
				if society.law and store.settlement[p] == 0:
					var breach: Dictionary = society.law.trespass(society, p, "seven_leaf", chosen.get("trip", "night") == "night")
					if breach.seen: return "guardians: " + str(breach.outcome)
				if temper.wild.gather_herb(p):
					temper.medicine["seven_leaf"][p] += 1
					society.note(p, "gathering", "%s picked a seven-leaf herb at the spirit spring" % store.names[p])
					return "picked a seven-leaf herb"
				feel(p, ANGER, 0.1)
				return "found no seven-leaf herb at the spring"
			var trip: Dictionary = temper.wild.gather_bark(p)
			if trip.taken == 0:
				feel(p, ANGER, 0.1)
				return "found %s stripped bare" % trip.place
			temper.medicine["iron_bark"][p] += trip.taken
			if trip.get("emptied", false): society.note(p, "gathering", "%s took the last iron-bark from %s" % [store.names[p], trip.place])
			return "gathered %d iron-bark roots at %s" % [trip.taken, trip.place]
		Option.HUNT:
			var hunt: Dictionary = society.temper.wild.hunt(p)
			if hunt.dead: return "was killed hunting"
			if hunt.hurt:
				society.note(p, "injury", "%s was hurt by %s while hunting and must rest" % [store.names[p], hunt.names[1]])
				return "was hurt hunting"
			if hunt.kill:
				society.temper.medicine["beast_marrow"][p] += 1
				society.note(p, "hunt", "%s brought down %s for marrow broth" % [store.names[p], hunt.names[1]])
				feel(p, JOY, 0.2)
				return "brought down a beast"
			return "came back empty-handed"
	return "carried on"

## Life goals are chosen from the heart's strongest fitting urge and checked whenever the person decides.
func _review_goal(p: int, urge: PackedFloat32Array, on_day: int) -> void:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var years: int = store.age(p)
	var done := false
	match goal[p]:
		Goal.MARRY: done = society.spouse[p] >= 0
		Goal.FIND_MASTER: done = society.master[p] >= 0
		Goal.ASCEND: done = society.realm[p] * 10 + society.layer[p] > goal_target[p]
		Goal.MASTER_CRAFT: done = store.best_level[p] >= goal_target[p]
		Goal.AVENGE: done = _max_grudge(p) <= 0.0
		Goal.PROVIDE: done = on_day - goal_since[p] > 3650
		Goal.TEMPER: done = society.temper != null and society.temper.body_layer[p] > goal_target[p]
	if done:
		society.note(p, "goal", "%s fulfilled a long-held wish to %s" % [store.names[p], GOAL_NAMES[goal[p]]])
		feel(p, JOY, 0.5)
		goal[p] = Goal.NONE
	elif goal[p] != Goal.NONE and on_day - goal_since[p] < 3650 * 2: return
	var wants: Dictionary = {}
	if years >= 16 and society.spouse[p] < 0: wants[Goal.MARRY] = urge[LONGING]
	if years >= 12 and years < 35 and society.master[p] < 0: wants[Goal.FIND_MASTER] = (urge[DEVOTION] + urge[AMBITION]) / 2.0
	if society.revealed[p]: wants[Goal.ASCEND] = urge[AMBITION] + 0.2
	if years >= 14: wants[Goal.MASTER_CRAFT] = urge[PRIDE] * 0.6 + urge[AMBITION] * 0.4
	if _max_grudge(p) > 30.0: wants[Goal.AVENGE] = urge[SPITE] + 0.1
	if child_count[p] > 0: wants[Goal.PROVIDE] = urge[DEVOTION]
	if society.temper and years >= 12 and years <= 50 and society.temper.body_layer[p] < society.temper.LAYERS: wants[Goal.TEMPER] = urge[AMBITION] * 0.5 + urge[PRIDE] * 0.5
	var pick := Goal.NONE
	var strength := 0.55
	for g: int in wants:
		if wants[g] > strength:
			pick = g
			strength = wants[g]
	goal[p] = pick
	goal_since[p] = on_day
	goal_target[p] = society.realm[p] * 10 + society.layer[p] if pick == Goal.ASCEND else (mini(50, store.best_level[p] + 5) if pick == Goal.MASTER_CRAFT else -1)
	if pick == Goal.TEMPER: goal_target[p] = society.temper.body_layer[p]

## Someone p knows well enough to spar with: grown enough, alive, not resting an injury. Rivals first.
func _sparring_partner(p: int, on_day: int) -> int:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	var ties: RefCounted = society.ties
	var best := -1
	var best_score := 0.0
	var e: int = ties.head[p]
	while e >= 0:
		var q: int = ties.target[e]
		if store.settlement[q] == store.settlement[p] and society.alive[q] and store.age(q) >= 12 and society.injury_until[q] <= on_day and ties.familiarity[e] >= 30:
			var score: float = ties.familiarity[e] + (60.0 if ties.bonds[e] & ties.RIVAL else 0.0) + store.rng.randf() * 20.0
			if score > best_score:
				best_score = score
				best = q
		e = ties.next[e]
	return best

func _max_grudge(p: int) -> float:
	var ties: RefCounted = society_ref.get_ref().ties
	var worst := 0.0
	var e: int = ties.head[p]
	while e >= 0:
		if ties.has_grudge(e): worst = maxf(worst, ties.grudge_intensity(e))
		e = ties.next[e]
	return worst

## Plain-language summary for the person page: feelings, strongest urges, life goal, recent decisions.
func describe(p: int) -> Dictionary:
	var urge := urges(p)
	var feelings: Array = []
	for e in 4: feelings.append([EMOTIONS[e], emotion[p * 4 + e]])
	var mine: Array = []
	for i in range(recent.size() - 1, -1, -1):
		if recent[i].person == p:
			mine.append(recent[i])
			if mine.size() >= 6: break
	return {"feelings": feelings, "urges": _top_urges(urge), "all_urges": urge, "goal": GOAL_NAMES[goal[p]], "recent": mine}
