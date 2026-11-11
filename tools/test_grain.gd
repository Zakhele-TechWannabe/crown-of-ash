extends SceneTree
const Economy = preload("res://src/grain_economy.gd")

func make_economy(no_farmers: bool = false) -> RefCounted:
	var economy := Economy.new()
	economy.no_farmers = no_farmers
	var residents: Array[Dictionary] = []
	for n in 20:
		residents.append({"kind": 0 if n < 8 else (8 if n >= 18 else 1)})
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sects/first_sect.json"))
	economy.setup(data, residents, 718)
	return economy

func _initialize() -> void:
	var daily: RefCounted = make_economy()
	var jump: RefCounted = make_economy()
	for d in 3 * 365:
		var before: float = daily.produced
		daily.advance_to((d + 1) * 1440.0)
		assert(daily.minimum > 0)
		if d % 365 < 182 or d % 365 > 272:
			if d % 365 != 364:
				assert(daily.produced == before, "Grain outside autumn")
	jump.advance_to(3 * 365 * 1440.0)
	assert(daily.stock == jump.stock)
	assert(daily.chronicle == jump.chronicle)
	assert(daily.summaries == jump.summaries)
	assert(jump.stock > 2500 and jump.stock < 9000)
	var half: RefCounted = make_economy()
	for step in 3 * 365 * 2:
		half.advance_to((step + 1) * 720.0)
	assert(half.stock == jump.stock and half.chronicle == jump.chronicle)
	var crisis: RefCounted = make_economy(true)
	crisis.advance_to(365 * 3 * 1440.0)
	assert(crisis.stock == 0 and crisis.people.size() == 20)
	for p: Dictionary in crisis.people:
		# Foraged food covers 60% of a child's share, so children hover at hungry; adults starve and forage.
		assert(p.foraged > 0 and p.hunger >= (1 if int(p.kind) == 8 else 3))
	var shortage: RefCounted = make_economy()
	shortage.stock = 1.0
	shortage.advance_to(720)
	# Rationing gives everyone a short share; children are served first so they're never worse off than adults.
	assert(shortage.people[18].hunger <= shortage.people[7].hunger and shortage.people[19].hunger <= shortage.people[7].hunger, "Children must eat first")
	assert(shortage.hungry_count >= 18)
	shortage.advance_to(3 * 1440.0 + 720)
	assert(shortage.people[0].hunger == 4)
	shortage.stock = 100.0
	shortage.advance_to(4 * 1440.0 + 720)
	assert(shortage.people[0].hunger == 3, "Recovery takes multiple meals")
	var boundary: RefCounted = make_economy()
	boundary.advance_to(182 * 1440.0)
	assert(boundary.produced == 0)
	boundary.advance_to(183 * 1440.0)
	assert(boundary.produced > 0)
	print("PASS grain: balance, hunger/foraging, survival, deterministic daily/half-day/jump ledger, autumn-only harvest")
	quit()
