extends RefCounted
## Ground-tile positions, integer thousandths of QU, one authoritative daily clock.
## Requests are independent elemental demands; queued requests settle on the next crossed day.
var _config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/qi/field.json"))
var _terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/qi/backgrounds.json"))
var _vein_rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/qi/veins.json"))
var _mass := PackedInt64Array()
var _totals := PackedInt64Array()
var _moments := PackedInt64Array()
var _remainders := PackedInt32Array()
var _biomes := PackedByteArray()
var _templates: Array[PackedInt64Array] = []
var _qualities: Array[PackedInt64Array] = []
var _active := PackedInt32Array()
var _baseline_cells := PackedInt32Array()
var _baseline_mass := PackedInt64Array()
var _baseline_moments := PackedInt64Array()
var _active_flags := PackedByteArray()
var _source_flags := PackedByteArray()
var _requests: Dictionary = {}
var _request_pool: Dictionary = {}
var _nodes: Array[Dictionary] = []
var _outlets: Array[Dictionary] = []
var _edges: Array[Dictionary] = []
var _seed := ""
var _initialized := false
var _element_totals := PackedInt64Array([0,0,0,0,0])
var _field_total := 0
var _reserve_total := 0
var day := 0
var ledger: Dictionary = {}
var allocations: Dictionary = {}
var landmarks: Dictionary = {}
var generation_usec := 0
var heaven: RefCounted
var _decrees: Dictionary = {}
var _thefts: Array = []
var decree_auto_pay := true
var _decree_rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/qi/decrees.json"))


func cell_at(position: Vector2) -> int:
	var p := Vector2i((position + Vector2.ONE * 0.5) / float(_config.ground_scale))
	return clampi(p.y, 0, int(_config.height) - 1) * int(_config.width) + clampi(p.x, 0, int(_config.width) - 1)

func position_of(cell: int) -> Vector2:
	return Vector2(cell % int(_config.width), cell / int(_config.width)) * float(_config.ground_scale)

static func stable_key(value: String) -> int:
	var result: int = 2166136261
	for byte: int in value.to_utf8_buffer(): result = ((result ^ byte) * 16777619) & 0x7fffffff
	return result

func seed(on_day: int = 0, world_seed: String = "") -> void:
	if _initialized: return
	var started := Time.get_ticks_usec()
	var atlas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_zi-xue-718.json"))
	_seed = str(atlas.seed) if world_seed.is_empty() else world_seed
	day = on_day
	var count := int(_config.width) * int(_config.height)
	var base := Marshalls.base64_to_raw(atlas.biome)
	var rivers := Marshalls.base64_to_raw(atlas.river)
	_biomes.resize(count)
	_mass.resize(count * 5)
	_totals.resize(count)
	_moments.resize(count * 4)
	_remainders.resize(count * 10)
	_active_flags.resize(count)
	_source_flags.resize(count)
	for river in 2:
		for biome: Dictionary in _terrain.biomes:
			var weights: Array = biome.weights.duplicate()
			if river: weights[2] += int(_terrain.river_water_weight)
			_templates.append(split_mass(roundi(float(biome.density) * float(_config.volume) * float(_config.quanta_per_qu)), weights))
			_qualities.append(PackedInt64Array([roundi(float(biome.purity) * float(_config.quality_scale)), roundi(float(biome.polarity) * float(_config.quality_scale)), roundi(float(biome.stability) * float(_config.quality_scale)), roundi(float(biome.corruption) * float(_config.quality_scale))]))
	for cell in count:
		_biomes[cell] = base[cell] + (_terrain.biomes.size() if rivers[cell] > 0 else 0)
		var total := 0
		for e in 5:
			_mass[cell * 5 + e] = _templates[_biomes[cell]][e]
			total += _mass[cell * 5 + e]
			_element_totals[e] += _mass[cell * 5 + e]
		for q in 4: _moments[cell * 4 + q] = total * _qualities[_biomes[cell]][q]
		_totals[cell] = total
		_field_total += total
	var palace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_config.heaven_site))
	var sect: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_config.sect_site))
	landmarks.Palace = Vector2(palace.center[0], palace.center[1])
	var center := Vector2(sect.center[0], sect.center[1])
	for building: Dictionary in sect.buildings:
		if building.get("name", "") == _config.spring_name:
			landmarks.Sect = center + Vector2(building.rect[0] + building.rect[2] / 2.0, building.rect[1] + building.rect[3] / 2.0)
	assert(landmarks.has("Sect"), "Sect spirit spring anchor missing")
	add_vein("Heavenly Origin", landmarks.Palace, int(_config.heaven_grade), true)
	add_vein("Sect spring", landmarks.Sect, int(_config.sect_grade))
	for site: Dictionary in sect.food_sites:
		var at := center + Vector2(site.at[0], site.at[1])
		if site.id == _config.village_site: landmarks.Village = at
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_config.site_manifest))
	var hunting: Array = manifest.destinations[_config.hunting_destination]
	for grade: float in _vein_rules.hunting_grades:
		add_vein("Hunting branch %d" % int(grade), Vector2(hunting[0],hunting[1]) + Vector2(float(_config.ground_scale) * grade, 0), int(grade))
	var candidates := PackedInt32Array()
	for cell in count:
		var b := int(base[cell])
		if b not in _vein_rules.placement_biomes and rivers[cell] == 0: continue
		for repeat in int(_vein_rules.mountain_weight if b in [11,12,13] else _vein_rules.other_weight): candidates.append(cell)
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_key(_seed + str(_config.seed_salt))
	var used: Dictionary = {}
	for n in int(_vein_rules.generated_count):
		var cell: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		while used.has(cell): cell = candidates[rng.randi_range(0, candidates.size() - 1)]
		used[cell] = true
		var roll := rng.randi_range(1, 100)
		var grade := 1
		for weight: float in _vein_rules.grade_weights:
			roll -= int(weight)
			if roll <= 0: break
			grade += 1
		add_vein("Vein %d" % n, position_of(cell), grade)
	_initialized = true
	# Generated prehistory: ambient source footprints are paid out of finite geological reserves.
	_open_ledger()
	ledger.phase = "World formation"
	for n in _nodes.size():
		_emit(n, int(_nodes[n].reserve))
		# Geological replenishment paid for the initial ambient endowment.
		var node: Dictionary = _nodes[n]
		var restored := 0
		for e in 5:
			var part: int = node.capacity_elements[e] - node.reserve_elements[e]
			node.reserve_elements[e] += part
			ledger.sources[n].regenerated_elements[e] += part
			restored += part
		node.reserve += restored
		_reserve_total += restored
		ledger.regeneration += restored
		ledger.sources[n].regeneration += restored
	_close_ledger()
	_active.sort()
	for cell in _active:
		_baseline_cells.append(cell)
		for e in 5: _baseline_mass.append(_mass[cell * 5 + e])
		for q in 4: _baseline_moments.append(_moments[cell * 4 + q])
	generation_usec = Time.get_ticks_usec() - started

func split_mass(quantity: int, weights: Array) -> PackedInt64Array:
	var total := 0
	for weight: Variant in weights: total += int(weight)
	var result := PackedInt64Array()
	var left := quantity
	for e in 5:
		var part: int = quantity * int(weights[e]) / total
		result.append(part)
		left -= part
	for e in left: result[e % 5] += 1
	return result

func add_vein(id: String, position: Vector2, grade: int, heavenly: bool = false) -> void:
	var spec: Dictionary = _vein_rules.grades[grade - 1]
	var root := _nodes.size()
	var cell := cell_at(position)
	var composition: Array = [1,1,1,1,1] if heavenly else Array(_templates[_biomes[cell]])
	var quality: PackedInt64Array = PackedInt64Array([int(_config.quality_scale),0,int(_config.quality_scale),0]) if heavenly else _qualities[_biomes[cell]]
	var capacity := int(spec.reserve) * int(_config.quanta_per_qu)
	_nodes.append({"id":id,"position":position,"grade":grade,"reserve":capacity,"capacity":capacity,"reserve_elements":split_mass(capacity,composition),"capacity_elements":split_mass(capacity,composition),"integrity":1000,"heavenly":heavenly,"emergency":false,"composition":composition,"quality":quality,"outlets":PackedInt32Array()})
	_reserve_total += capacity
	var previous := -1
	for branch in (1 if heavenly else 2):
		var offset := Vector2(_vein_rules.branch_offset_cells[0], _vein_rules.branch_offset_cells[1]) * float(_config.ground_scale) * branch
		var outlet_cell := cell_at(position + offset)
		var footprint := PackedInt32Array()
		var targets := PackedInt64Array()
		var kernel_weights := PackedInt64Array()
		var origin := Vector2(outlet_cell % int(_config.width), outlet_cell / int(_config.width))
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var p := origin + Vector2(dx, dy)
				if p.x < 0 or p.y < 0 or p.x >= int(_config.width) or p.y >= int(_config.height): continue
				var weight := pow(maxf(0, 1.0 - Vector2(dx,dy).length() / float(_vein_rules.kernel_radius)), 2)
				if weight <= 0: continue
				var c := int(p.y) * int(_config.width) + int(p.x)
				footprint.append(c)
				kernel_weights.append(roundi(weight * float(_vein_rules.kernel_weight_scale)))
				_source_flags[c] = 1
				var bonus := split_mass(roundi(float(spec.bonus) * weight * float(_config.volume) * float(_config.quanta_per_qu)), composition)
				for e in 5: targets.append(_templates[_biomes[c]][e] + bonus[e])
		var outlet := _outlets.size()
		_nodes[root].outlets.append(outlet)
		_outlets.append({"node":root,"cell":outlet_cell,"cells":footprint,"targets":targets,"weights":kernel_weights,"edge":_edges.size()})
		_edges.append({"from":previous,"to":outlet,"node":root,"limit":int(spec.output) * int(_config.quanta_per_qu) * int(_config.emergency_multiplier),"integrity":1000})
		previous = outlet

func _activate(cell: int) -> void:
	if _active_flags[cell]: return
	_active_flags[cell] = 1
	_active.append(cell)

func _add(cell: int, element: int, quantity: int, quality: PackedInt64Array) -> void:
	_mass[cell * 5 + element] += quantity
	_element_totals[element] += quantity
	_totals[cell] += quantity
	for q in 4: _moments[cell * 4 + q] += quantity * quality[q]
	_field_total += quantity
	_activate(cell)

func _remove(cell: int, element: int, quantity: int) -> void:
	var total := cell_mass(cell)
	if quantity <= 0: return
	for q in 4:
		var moment := _moments[cell * 4 + q]
		_moments[cell * 4 + q] -= (moment / total) * quantity + (moment % total) * quantity / total
	_mass[cell * 5 + element] -= quantity
	_element_totals[element] -= quantity
	_totals[cell] -= quantity
	_field_total -= quantity
	_activate(cell)

func cell_mass(cell: int) -> int:
	return _totals[cell]

func _open_ledger() -> void:
	ledger = {"day":day,"opening_field":_field_total,"opening_reserves":_reserve_total,"source_output":0,"regeneration":0,"background_recovery":0,"withdrawals":0,"tap_withdrawals":0,"dispersion":0,"residual":0,"sources":[],"opening_elements":_element_totals.duplicate(),"source_elements":PackedInt64Array([0,0,0,0,0]),"recovery_elements":PackedInt64Array([0,0,0,0,0]),"tap_elements":PackedInt64Array([0,0,0,0,0]),"withdrawal_elements":PackedInt64Array([0,0,0,0,0]),"dispersion_elements":PackedInt64Array([0,0,0,0,0])}
	for node: Dictionary in _nodes:
		ledger.sources.append({"id":node.id,"opening":node.reserve,"regeneration":0,"emitted":0,"tapped":0,"tapped_elements":PackedInt64Array([0,0,0,0,0]),"closing":node.reserve,"opening_elements":node.reserve_elements.duplicate(),"regenerated_elements":PackedInt64Array([0,0,0,0,0]),"emitted_elements":PackedInt64Array([0,0,0,0,0])})

func _close_ledger() -> void:
	for n in _nodes.size():
		ledger.sources[n].closing = _nodes[n].reserve
		ledger.sources[n].closing_elements = _nodes[n].reserve_elements.duplicate()
	ledger.closing_elements = _element_totals.duplicate()
	ledger.element_residuals = PackedInt64Array()
	for e in 5:
		var residual: int = ledger.opening_elements[e] + ledger.source_elements[e] + ledger.recovery_elements[e] - ledger.withdrawal_elements[e] + ledger.tap_elements[e] - ledger.dispersion_elements[e] - _element_totals[e]
		ledger.element_residuals.append(residual)
		assert(residual == 0)
	ledger.closing_field = _field_total
	ledger.closing_reserves = _reserve_total
	ledger.residual = int(ledger.opening_field) + int(ledger.opening_reserves) + int(ledger.regeneration) + int(ledger.background_recovery) - int(ledger.withdrawals) - int(ledger.dispersion) - _field_total - _reserve_total
	assert(ledger.residual == 0)

func _emit(node_index: int, budget: int) -> void:
	var node: Dictionary = _nodes[node_index]
	var reserve_elements: PackedInt64Array = node.reserve_elements
	var source_elements: PackedInt64Array = ledger.source_elements
	var emitted_elements: PackedInt64Array = ledger.sources[node_index].emitted_elements
	var quality: PackedInt64Array = node.quality
	budget = mini(budget, int(node.reserve))
	var level := _node_level(node_index) if ledger.has("daily") else 100
	var rated_budget := budget
	budget = budget * level / 100
	if ledger.has("daily") and not node.outlets.is_empty():
		var trunk: Dictionary = _edges[_outlets[int(node.outlets[0])].edge]
		budget = mini(budget,int(trunk.limit) * int(trunk.integrity) / 1000)
	for outlet_index: int in node.outlets:
		var outlet: Dictionary = _outlets[outlet_index]
		var cells: PackedInt32Array = outlet.cells
		var targets: PackedInt64Array = outlet.targets
		var weights: PackedInt64Array = outlet.weights
		if budget <= 0: break
		var edge: Dictionary = _edges[outlet.edge]
		# A serial outlet spends the upstream budget before the downstream branch.
		var available := rated_budget
		if ledger.has("daily"):
			var path_limit := int(edge.limit) * int(edge.integrity) / 1000
			if int(edge.from) >= 0:
				var upstream: Dictionary = _edges[_outlets[int(edge.from)].edge]
				path_limit = mini(path_limit, int(upstream.limit) * int(upstream.integrity) / 1000)
			available = mini(rated_budget, path_limit)
		var deficits := PackedInt64Array()
		var rooms := PackedInt64Array([0,0,0,0,0])
		var total := 0
		for i in cells.size():
			var c: int = cells[i]
			for e in 5:
				var deficit := maxi(0, int(targets[i * 5 + e]) - _mass[c * 5 + e])
				deficits.append(deficit)
				rooms[e] += deficit
				total += deficit
		if total <= 0: continue
		available = mini(budget,mini(available,total) * level / 100)
		var quotas: PackedInt64Array = reserve_elements if available >= total else split_mass(available, node.composition)
		# Most healthy outlets can replace the entire daily dispersion. Transfer
		# those deficits directly, without five weighted allocation workspaces.
		var fill_all := true
		for e in 5:
			if rooms[e] > mini(quotas[e],int(reserve_elements[e])): fill_all = false
		if fill_all:
			for i in cells.size():
				var c: int = cells[i]
				var added := 0
				for e in 5:
					var part := deficits[i * 5 + e]
					_mass[c * 5 + e] += part
					added += part
				for q in 4: _moments[c * 4 + q] += added * int(quality[q])
				_totals[c] += added
				if added > 0: _activate(c)
			for e in 5:
				reserve_elements[e] -= rooms[e]
				_element_totals[e] += rooms[e]
				source_elements[e] += rooms[e]
				emitted_elements[e] += rooms[e]
			_field_total += total
			node.reserve -= total
			_reserve_total -= total
			ledger.source_output += total
			ledger.sources[node_index].emitted += total
			budget -= total
			continue
		var additions := PackedInt64Array()
		additions.resize(cells.size())
		var emitted := 0
		for e in 5:
			var room := rooms[e]
			var amount := mini(mini(quotas[e],room),int(reserve_elements[e]))
			if amount <= 0: continue
			var capacities := PackedInt64Array()
			for i in cells.size(): capacities.append(deficits[i * 5 + e])
			var shares := capacities if amount == room else weighted_fill(amount,capacities,weights)
			for i in cells.size():
				_mass[cells[i] * 5 + e] += shares[i]
				additions[i] += shares[i]
			_element_totals[e] += amount
			emitted += amount
			reserve_elements[e] -= amount
			source_elements[e] += amount
			emitted_elements[e] += amount
		for i in cells.size():
			var c: int = cells[i]
			var added := additions[i]
			if added <= 0: continue
			for q in 4: _moments[c * 4 + q] += added * int(quality[q])
			_totals[c] += added
			_field_total += added
			_activate(c)
		node.reserve = int(node.reserve) - emitted
		_reserve_total -= emitted
		ledger.source_output += emitted
		ledger.sources[node_index].emitted += emitted
		budget -= emitted

	node.reserve_elements = reserve_elements
	ledger.source_elements = source_elements
	ledger.sources[node_index].emitted_elements = emitted_elements

func advance(on_day: int) -> void:
	self.seed(day)
	var cycles: Dictionary = {}
	var recovery_denominator := int(_config.recovery_denominator)
	var dispersion_denominator := int(_config.dispersion_denominator)
	var recovery_numerator := int(_config.recovery_numerator)
	var dispersion_numerator := int(_config.dispersion_numerator)
	while day < on_day:
		day += 1
		_pay_decrees()
		_open_ledger()
		ledger.daily = true
		ledger.phase = "daily"
		_active.sort()
		var recovery_elements: PackedInt64Array = ledger.recovery_elements
		var dispersion_elements: PackedInt64Array = ledger.dispersion_elements
		for cell in _active:
			var template: PackedInt64Array = _templates[_biomes[cell]]
			var quality: PackedInt64Array = _qualities[_biomes[cell]]
			var recovered := 0
			var dispersed := 0
			var opening := _totals[cell]
			for e in 5:
				var index := cell * 5 + e
				var delta := template[e] - _mass[index]
				if delta == 0: continue
				var remainder_index := index * 2 + (0 if delta > 0 else 1)
				var denominator := (recovery_denominator if delta > 0 else dispersion_denominator)
				var numerator := (recovery_numerator if delta > 0 else dispersion_numerator)
				var work := absi(delta) * numerator + _remainders[remainder_index]
				var amount: int = work / denominator
				_remainders[remainder_index] = work % denominator
				if delta > 0:
					_mass[index] += amount
					_element_totals[e] += amount
					recovered += amount
					recovery_elements[e] += amount
				else:
					_mass[index] -= amount
					_element_totals[e] -= amount
					dispersed += amount
					dispersion_elements[e] += amount
			for q in 4:
				var moment := _moments[cell * 4 + q]
				if moment == opening * quality[q]:
					_moments[cell * 4 + q] = (opening + recovered - dispersed) * quality[q]
				else:
					if dispersed > 0: moment -= (moment / opening) * dispersed + (moment % opening) * dispersed / opening
					_moments[cell * 4 + q] = moment + recovered * quality[q]
			_totals[cell] += recovered - dispersed
			_field_total += recovered - dispersed
			ledger.background_recovery += recovered
			ledger.dispersion += dispersed
		ledger.recovery_elements = recovery_elements
		ledger.dispersion_elements = dispersion_elements
		for n in _nodes.size():
			var node: Dictionary = _nodes[n]
			var output := int(_vein_rules.grades[int(node.grade) - 1].output) * int(_config.quanta_per_qu)
			var regen_parts := split_mass(output * int(node.integrity) / 1000,node.composition)
			var regen := 0
			var reserve_parts: PackedInt64Array = node.reserve_elements
			var capacity_parts: PackedInt64Array = node.capacity_elements
			var regenerated_parts := PackedInt64Array([0,0,0,0,0])
			for e in 5:
				var part := mini(regen_parts[e],capacity_parts[e] - reserve_parts[e])
				reserve_parts[e] += part
				regen += part
				regenerated_parts[e] = part
			node.reserve_elements = reserve_parts
			ledger.sources[n].regenerated_elements = regenerated_parts
			node.reserve = int(node.reserve) + regen
			_reserve_total += regen
			ledger.regeneration += regen
			ledger.sources[n].regeneration = regen
			var multiplier := int(_config.emergency_multiplier) if node.emergency else 1
			_emit(n, output * int(node.integrity) / 1000 * multiplier)
		_settle()
		_close_ledger()
		_prune_active()
		# Skip only witnessed exact cycles of the complete field state, with no queued consumers.
		if on_day - day > 400 and day % 200 == 0 and _requests.is_empty() and _decrees.is_empty():
			var state := save_state()
			state.erase("day")
			state.erase("ledger")
			state.erase("allocations")
			var digest := HashingContext.new()
			digest.start(HashingContext.HASH_SHA256)
			digest.update(var_to_bytes(state))
			var key := digest.finish().hex_encode()
			if cycles.has(key):
				var period := day - int(cycles[key])
				var skipped: int = ((on_day - day) / period) * period
				day += skipped
				ledger.day = day
			else:
				if cycles.size() >= 512: cycles.erase(cycles.keys()[0])
				cycles[key] = day

func request(consumer_id: String, position: Vector2, elemental_demand: PackedInt64Array, priority: int, tap: bool = false) -> void:
	self.seed(day)
	assert(elemental_demand.size() == 5)
	assert(not _requests.has(consumer_id), "One request per stable consumer ID per step")
	for amount in elemental_demand: assert(amount >= 0)
	if not _request_pool.has(consumer_id): _request_pool[consumer_id]={}
	var entry: Dictionary = _request_pool[consumer_id]
	entry.cell=cell_at(position)
	entry.demand=elemental_demand.duplicate()
	entry.priority=priority
	entry.tap=tap
	_requests[consumer_id]=entry

func _settle() -> void:
	allocations = {}
	var ids: Array = _requests.keys()
	# Resolve taps against the opening reserve, by priority and stable node ID.
	var taps: Array = []
	for id: String in ids:
		var r: Dictionary = _requests[id]
		if not r.get("tap",false): continue
		var n := -1
		for o: Dictionary in _outlets:
			if int(o.cell) == int(r.cell):
				n = int(o.node)
				break
		allocations[id] = PackedInt64Array([0,0,0,0,0])
		if n >= 0: taps.append({"id":id,"node":n,"priority":int(r.priority)})
	taps.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.node != b.node: return int(a.node) < int(b.node)
		if a.priority != b.priority: return int(a.priority) < int(b.priority)
		return str(a.id) < str(b.id))
	var tap_cursor := 0
	while tap_cursor < taps.size():
		var first: Dictionary = taps[tap_cursor]
		var end := tap_cursor + 1
		while end < taps.size() and taps[end].node == first.node and taps[end].priority == first.priority: end += 1
		var n := int(first.node)
		var node: Dictionary = _nodes[n]
		var parts: PackedInt64Array = node.reserve_elements
		for e in 5:
			var demand := 0
			for i in range(tap_cursor,end): demand += int(_requests[taps[i].id].demand[e])
			if demand == 0: continue
			var available := mini(demand,parts[e])
			var left := available
			var ranked: Array = []
			for i in range(tap_cursor,end):
				var id: String = taps[i].id
				var fraction := proportional(int(_requests[id].demand[e]),available,demand)
				allocations[id][e] = fraction[0]
				left -= fraction[0]
				ranked.append([id,fraction[1],stable_key("%s:%d:tap:%d:%d:%s" % [_seed,day,n,e,id])])
			ranked.sort_custom(func(a: Array,b: Array) -> bool:
				if a[1] != b[1]: return int(a[1]) > int(b[1])
				if a[2] != b[2]: return int(a[2]) < int(b[2])
				return str(a[0]) < str(b[0]))
			for i in left: allocations[ranked[i][0]][e] += 1
			parts[e] -= available
			ledger.sources[n].tapped_elements[e] += available
			ledger.tap_elements[e] += available
			ledger.withdrawal_elements[e] += available
			node.reserve -= available
			_reserve_total -= available
			ledger.tap_withdrawals += available
			ledger.sources[n].tapped += available
			ledger.withdrawals += available
		node.reserve_elements = parts
		for i in range(tap_cursor,end):
			var id: String = taps[i].id
			var amount := 0
			for e in 5: amount += int(allocations[id][e])
			if amount > 0:
				_thefts.append({"consumer_id":id,"day":day,"amount":amount,"node":node.id})
				if _thefts.size() > int(_decree_rules.theft_limit): _thefts.pop_front()
		tap_cursor = end
	for id: String in ids:
		if _requests[id].get("tap",false): _requests.erase(id)
	ids = _requests.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra: Dictionary = _requests[a]
		var rb: Dictionary = _requests[b]
		if ra.cell != rb.cell: return int(ra.cell) < int(rb.cell)
		if ra.priority != rb.priority: return int(ra.priority) < int(rb.priority)
		return a < b)
	var cursor := 0
	while cursor < ids.size():
		var first: Dictionary = _requests[ids[cursor]]
		var end := cursor
		while end < ids.size() and _requests[ids[end]].cell == first.cell and _requests[ids[end]].priority == first.priority: end += 1
		for i in range(cursor,end): allocations[ids[i]] = PackedInt64Array([0,0,0,0,0])
		for e in 5:
			var demand := 0
			for i in range(cursor,end): demand += int(_requests[ids[i]].demand[e])
			if demand == 0: continue
			var level := _region_level(int(first.cell))
			var scaled := 0
			for i in range(cursor,end):
				_requests[ids[i]].demand[e] = int(_requests[ids[i]].demand[e]) * level / 100
				scaled += int(_requests[ids[i]].demand[e])
			demand = scaled
			if demand == 0: continue
			var available := mini(demand, _mass[int(first.cell) * 5 + e])
			if available==demand:
				# Co-located, fully funded batch: no proportional ranking or ties.
				for i in range(cursor,end): allocations[ids[i]][e]=_requests[ids[i]].demand[e]
				_remove(int(first.cell),e,available)
				ledger.withdrawals+=available
				ledger.withdrawal_elements[e]+=available
				continue
			var left := available
			var ranked: Array = []
			for i in range(cursor,end):
				var id: String = ids[i]
				var fraction := proportional(int(_requests[id].demand[e]),available,demand)
				var share: int = fraction[0]
				allocations[id][e] = share
				left -= share
				ranked.append([id,fraction[1],stable_key("%s:%d:%d:%d:%s" % [_seed,day,first.cell,e,id])])
			ranked.sort_custom(func(a: Array,b: Array) -> bool:
				if a[1] != b[1]: return int(a[1]) > int(b[1])
				if a[2] != b[2]: return int(a[2]) < int(b[2])
				return str(a[0]) < str(b[0]))
			for i in left: allocations[ranked[i][0]][e] += 1
			_remove(int(first.cell), e, available)
			ledger.withdrawals += available
			ledger.withdrawal_elements[e] += available
		cursor = end
	_requests.clear()

## Release control only; actual energy still goes through the shared outlet budget and ledger.
func set_emergency_output(node: int, enabled: bool) -> void:
	self.seed(day)
	_nodes[node].emergency = enabled

func damage_source(node: int, amount: int) -> void:
	self.seed(day)
	if _nodes[node].heavenly: return
	_nodes[node].integrity = clampi(int(_nodes[node].integrity) - amount, 0, 1000)

func damage_edge(edge: int, amount: int) -> void:
	self.seed(day)
	if _nodes[int(_edges[edge].node)].heavenly: return
	_edges[edge].integrity = clampi(int(_edges[edge].integrity) - amount, 0, 1000)

func sample(position: Vector2, on_day: int = -1) -> Dictionary:
	self.seed(day)
	# Sampling is read-only: future samples must be coordinated through advance().
	assert(on_day < 0 or on_day == day, "Sample only the authoritative current day")
	var cell := cell_at(position)
	var mass := cell_mass(cell)
	var components := PackedInt64Array()
	for e in 5: components.append(_mass[cell * 5 + e])
	var density := float(mass) / float(_config.quanta_per_qu) / float(_config.volume)
	var category := 0
	for threshold: float in _config.density_thresholds:
		if density < threshold: break
		category += 1
	var result := {"cell":cell,"day":day,"elements":components,"quantity":mass,"volume":_config.volume,"density":density,"description":_config.density_names[category]}
	for q in 4: result[["purity","polarity","stability","corruption"][q]] = float(_moments[cell * 4 + q]) / float(maxi(1,mass)) / float(_config.quality_scale)
	var nearest := -1
	var distance := float(_vein_rules.kernel_radius) * float(_config.ground_scale)
	for outlet: Dictionary in _outlets:
		var d := position.distance_to(position_of(outlet.cell))
		if d < distance:
			nearest = int(outlet.node)
			distance = d
	if nearest >= 0:
		var node: Dictionary = _nodes[nearest]
		result.source = node.id
		result.grade = _vein_rules.grades[int(node.grade) - 1].name
		result.reserve = float(node.reserve) / float(node.capacity)
	return result

func describe(position: Vector2) -> String:
	var s := sample(position)
	var order: Array = [0,1,2,3,4]
	order.sort_custom(func(a: int,b: int) -> bool: return s.elements[a] > s.elements[b])
	var text := "%s · density %.1f · %s %.0f%%, %s %.0f%%" % [s.description,s.density,_terrain.elements[order[0]],100.0 * s.elements[order[0]] / maxi(1,s.quantity),_terrain.elements[order[1]],100.0 * s.elements[order[1]] / maxi(1,s.quantity)]
	var balanced := true
	for e in 5:
		if absf(float(s.elements[e]) / maxi(1,s.quantity) - 0.2) > 0.015: balanced = false
	if balanced: text = "%s · density %.1f · balanced: every element about 20%%" % [s.description,s.density]
	if s.has("source"): text += " · %s · %s vein, reserve %.0f%%" % [s.source,s.grade,100.0 * s.reserve]
	return text

func graph() -> Dictionary:
	self.seed(day)
	return {"nodes":_nodes.duplicate(true),"outlets":_outlets.duplicate(true),"edges":_edges.duplicate(true)}

func memory_bytes() -> int:
	return _mass.size() * 8 + _totals.size() * 8 + _moments.size() * 8 + _remainders.size() * 4 + _biomes.size() + _active_flags.size() + _source_flags.size() + _active.size() * 4 + _baseline_cells.size() * 4 + _baseline_mass.size() * 8 + _baseline_moments.size() * 8 + var_to_bytes(graph()).size()

func save_state() -> Dictionary:
	self.seed(day)
	var cells := PackedInt32Array()
	var masses := PackedInt64Array()
	var moments := PackedInt64Array()
	var remainders := PackedInt32Array()
	_active.sort()
	for cell in _active:
		var baseline := _baseline_cells.bsearch(cell)
		var generated := baseline < _baseline_cells.size() and _baseline_cells[baseline] == cell
		var changed := false
		for e in 5:
			var original := _baseline_mass[baseline * 5 + e] if generated else _templates[_biomes[cell]][e]
			if _mass[cell * 5 + e] != original: changed = true
			if _remainders[(cell * 5 + e) * 2] != 0 or _remainders[(cell * 5 + e) * 2 + 1] != 0: changed = true
		for q in 4:
			var original := _baseline_moments[baseline * 4 + q] if generated else cell_mass(cell) * _qualities[_biomes[cell]][q]
			if _moments[cell * 4 + q] != original: changed = true
		if not changed: continue
		cells.append(cell)
		for e in 5:
			masses.append(_mass[cell * 5 + e])
			for kind in 2: remainders.append(_remainders[(cell * 5 + e) * 2 + kind])
		for q in 4: moments.append(_moments[cell * 4 + q])
	var reserves := PackedInt64Array()
	var reserve_elements := PackedInt64Array()
	var damage := PackedInt32Array()
	var edges := PackedInt32Array()
	var emergency := PackedByteArray()
	for node: Dictionary in _nodes:
		reserves.append(node.reserve)
		reserve_elements.append_array(node.reserve_elements)
		damage.append(node.integrity)
		emergency.append(int(node.emergency))
	for edge: Dictionary in _edges: edges.append(edge.integrity)
	return {"decrees":_decrees.duplicate(true),"thefts":_thefts.duplicate(true),"auto_pay":decree_auto_pay,"schema":_config.schema,"seed":_seed,"day":day,"cells":cells,"mass":masses,"moments":moments,"remainders":remainders,"reserves":reserves,"reserve_elements":reserve_elements,"integrity":damage,"edges":edges,"emergency":emergency,"requests":_requests.duplicate(true),"ledger":ledger.duplicate(true),"allocations":allocations.duplicate(true)}

func load_state(state: Dictionary, on_day: int) -> void:
	allocations = {}
	_initialized = false
	_field_total = 0
	_element_totals = PackedInt64Array([0,0,0,0,0])
	_reserve_total = 0
	_templates.clear()
	_qualities.clear()
	_active.clear()
	_baseline_cells.clear()
	_baseline_mass.clear()
	_baseline_moments.clear()
	_active_flags.clear()
	_source_flags.clear()
	_remainders.clear()
	_nodes.clear()
	_outlets.clear()
	_edges.clear()
	_requests.clear()
	_decrees.clear()
	_thefts.clear()
	landmarks.clear()
	self.seed(on_day, str(state.get("seed", "")))
	if state.is_empty(): return
	if int(state.get("schema",0)) != int(_config.schema): return
	var cells: PackedInt32Array = state.get("cells",PackedInt32Array())
	if state.get("mass",[]).size() != cells.size() * 5 or state.get("moments",[]).size() != cells.size() * 4 or state.get("remainders",[]).size() != cells.size() * 10: return
	if state.get("reserves",[]).size() != _nodes.size() or state.get("integrity",[]).size() != _nodes.size() or state.get("edges",[]).size() != _edges.size(): return
	day = on_day
	_decrees = state.get("decrees",{}).duplicate(true)
	_thefts = state.get("thefts",[]).duplicate(true)
	decree_auto_pay = state.get("auto_pay",true)
	for i in cells.size():
		var cell: int = cells[i]
		if cell < 0 or cell >= _biomes.size(): continue
		_field_total -= cell_mass(cell)
		for e in 5:
			_element_totals[e] -= _mass[cell * 5 + e]
			_mass[cell * 5 + e] = maxi(0,int(state.mass[i * 5 + e]))
			_element_totals[e] += _mass[cell * 5 + e]
			for kind in 2:
				var denominator := int(_config.recovery_denominator if kind == 0 else _config.dispersion_denominator)
				_remainders[(cell * 5 + e) * 2 + kind] = clampi(int(state.remainders[(i * 5 + e) * 2 + kind]),0,denominator - 1)
		var loaded_total := 0
		for e in 5: loaded_total += _mass[cell * 5 + e]
		_totals[cell] = loaded_total
		for q in 4:
			var bound := cell_mass(cell) * int(_config.quality_scale)
			_moments[cell * 4 + q] = clampi(int(state.moments[i * 4 + q]),-bound if q == 1 else 0,bound)
		var total := 0
		for e in 5: total += _mass[cell * 5 + e]
		_totals[cell] = total
		_field_total += total
		_activate(cell)
	_reserve_total = 0
	for i in _nodes.size():
		_nodes[i].reserve = clampi(int(state.reserves[i]),0,int(_nodes[i].capacity))
		var parts := split_mass(int(_nodes[i].reserve),_nodes[i].composition)
		if state.get("reserve_elements",[]).size() == _nodes.size() * 5:
			var saved_parts := PackedInt64Array()
			var sum := 0
			for e in 5:
				var amount := clampi(int(state.reserve_elements[i * 5 + e]),0,int(_nodes[i].capacity_elements[e]))
				saved_parts.append(amount)
				sum += amount
			if sum == int(_nodes[i].reserve): parts = saved_parts
		_nodes[i].reserve_elements = parts
		_nodes[i].emergency = bool(state.emergency[i]) if state.get("emergency",[]).size() == _nodes.size() else false
		_nodes[i].integrity = 1000 if _nodes[i].heavenly else clampi(int(state.integrity[i]),0,1000)
		_reserve_total += int(_nodes[i].reserve)
	for i in _edges.size(): _edges[i].integrity = 1000 if _nodes[int(_edges[i].node)].heavenly else clampi(int(state.edges[i]),0,1000)
	for id: String in state.get("requests",{}):
		var r: Dictionary = state.requests[id]
		if not r.get("demand") is PackedInt64Array or r.demand.size() != 5: continue
		if int(r.get("cell",-1)) < 0 or int(r.cell) >= _biomes.size(): continue
		var valid := true
		for amount: int in r.demand:
			if amount < 0: valid = false
		if valid: _requests[id] = r.duplicate(true)

	var saved_ledger: Dictionary = state.get("ledger",{})
	if int(saved_ledger.get("day",-1)) == day and int(saved_ledger.get("closing_field",-1)) == _field_total and int(saved_ledger.get("closing_reserves",-1)) == _reserve_total:
		ledger = saved_ledger.duplicate(true)
	else:
		_open_ledger()
		ledger.phase = "restored snapshot"
		_close_ledger()
	allocations = {}
	for id: String in state.get("allocations",{}):
		var receipt: Variant = state.allocations[id]
		if not receipt is PackedInt64Array or receipt.size() != 5: continue
		var valid := true
		for amount: int in receipt:
			if amount < 0: valid = false
		if valid: allocations[id] = receipt.duplicate()

func density_at_cell(cell: int, element: int = -1) -> float:
	var quantity := cell_mass(cell) if element < 0 else _mass[cell * 5 + element]
	return float(quantity) / float(_config.quanta_per_qu) / float(_config.volume)

func _prune_active() -> void:
	var kept := PackedInt32Array()
	for cell in _active:
		if _source_flags[cell]:
			kept.append(cell)
			continue
		var dirty := false
		for e in 5:
			if _mass[cell * 5 + e] != _templates[_biomes[cell]][e] or _remainders[(cell * 5 + e) * 2] != 0 or _remainders[(cell * 5 + e) * 2 + 1] != 0: dirty = true
		if dirty:
			kept.append(cell)
		else:
			_active_flags[cell] = 0
			# Preserve altered qualities in the save even when elemental mass is at background.
			for q in 4:
				if _moments[cell * 4 + q] != cell_mass(cell) * _qualities[_biomes[cell]][q]: dirty = true
			if dirty:
				kept.append(cell)
				_active_flags[cell] = 1
	_active = kept

## Exact a*b/divisor without overflowing a 64-bit intermediate (a,b <= divisor).
static func proportional(a: int, b: int, divisor: int) -> PackedInt64Array:
	if a == 0 or b == 0: return PackedInt64Array([0,0])
	if a <= 9223372036854775807 / b: return PackedInt64Array([a * b / divisor,a * b % divisor])
	var quotient := 0
	var remainder := 0
	var term_quotient: int = b / divisor
	var term_remainder: int = b % divisor
	while a > 0:
		if a & 1:
			quotient += term_quotient
			if remainder >= divisor - term_remainder:
				remainder -= divisor - term_remainder
				quotient += 1
			else: remainder += term_remainder
		a >>= 1
		if a == 0: break
		term_quotient *= 2
		if term_remainder >= divisor - term_remainder:
			term_remainder -= divisor - term_remainder
			term_quotient += 1
		else: term_remainder *= 2
	return PackedInt64Array([quotient,remainder])

static func weighted_fill(quantity: int, capacity: PackedInt64Array, weights: PackedInt64Array) -> PackedInt64Array:
	var result := PackedInt64Array()
	result.resize(capacity.size())
	while quantity > 0:
		var weight := 0
		for i in capacity.size():
			if result[i] < capacity[i]: weight += weights[i]
		if weight == 0: break
		var opening := quantity
		for i in capacity.size():
			if result[i] >= capacity[i]: continue
			var share := mini(capacity[i] - result[i],opening * weights[i] / weight)
			result[i] += share
			quantity -= share
		# Deterministic sub-quantum remainder; saturated receivers are excluded.
		for i in capacity.size():
			if quantity <= 0: break
			if result[i] < capacity[i]:
				result[i] += 1
				quantity -= 1
	return result

## Target: node index/name, or {id: String, cells: Array[int]}. Levels: 1/.75/.5/.25/0.
func set_decree(target: Variant, level: float) -> void:
	self.seed(day)
	assert(level in [0.0,0.25,0.5,0.75,1.0])
	var record: Dictionary
	if target is Dictionary:
		record = {"id":"region:" + str(target.id),"cells":target.cells.duplicate(),"node":-1}
	else:
		var n := int(target) if target is int else -1
		if target is String:
			for i in _nodes.size():
				if _nodes[i].id == target: n = i
		assert(n >= 0 and n < _nodes.size())
		record = {"id":str(_nodes[n].id),"node":n,"cells":[]}
	if level == 1.0:
		_decrees.erase(record.id)
		return
	record.level = roundi(level * 100)
	var cost: float = float(_decree_rules.region) if int(record.node) < 0 else float(_decree_rules.grades[int(_nodes[int(record.node)].grade) - 1])
	record.upkeep = cost * (float(_decree_rules.throttle_multiplier) if level > 0 else 1.0)
	record.next_due = day + 365
	_decrees[record.id] = record

func decrees() -> Array:
	var result: Array = []
	var keys := _decrees.keys()
	keys.sort()
	for key: String in keys: result.append(_decrees[key].duplicate(true))
	return result

func thefts() -> Array:
	return _thefts.duplicate(true)

func _node_level(n: int) -> int:
	return int(_decrees.get(str(_nodes[n].id),{}).get("level",100))

func _region_level(cell: int) -> int:
	var level := 100
	for d: Dictionary in _decrees.values():
		if int(d.node) < 0 and cell in d.cells: level = mini(level,int(d.level))
	return level

func _pay_decrees() -> void:
	if not _decrees.is_empty() and heaven != null and heaven.has_method("income_until"): heaven.income_until(day)
	for d: Dictionary in decrees():
		if day < int(d.next_due): continue
		if decree_auto_pay and heaven != null and float(heaven.will) >= float(d.upkeep):
			heaven.will -= float(d.upkeep)
			_decrees[d.id].next_due += 365
		elif float(d.upkeep) == 0:
			_decrees[d.id].next_due += 365
		else:
			_decrees.erase(d.id)
			if heaven != null:
				var society: RefCounted = heaven.society_ref.get_ref()
				society.note(-1,"dao","The qi decree on %s lapsed: its yearly Heaven's Will upkeep was unpaid." % d.id,day)

func world_totals() -> Dictionary:
	var elements := _element_totals.duplicate()
	for node: Dictionary in _nodes:
		for e in 5: elements[e] += int(node.reserve_elements[e])
	return {"land":_field_total,"veins":_reserve_total,"total":_field_total + _reserve_total,"elements":elements}

## Return unused ordinary allocations at their reservation position and quality.
## The receipt is consumed once; net withdrawals remain the actual body intake.
func settle_reservation(id: String, position: Vector2, used: int, quality: Dictionary, close: bool = true) -> void:
	var receipt: PackedInt64Array = allocations.get(id, PackedInt64Array([0,0,0,0,0]))
	var total := 0
	for part in receipt: total += part
	assert(used >= 0 and used <= total)
	var consumed := PackedInt64Array([0,0,0,0,0])
	var left := used
	if total>0:
		for e in 5:
			consumed[e]=proportional(receipt[e],used,total)[0]
			left-=consumed[e]
		for e in 5:
			if left>0 and consumed[e]<receipt[e]:
				consumed[e]+=1
				left-=1
	var moments := PackedInt64Array()
	for key: String in ["purity","polarity","stability","corruption"]: moments.append(roundi(float(quality[key])*float(_config.quality_scale)))
	for e in 5:
		var returned := receipt[e]-consumed[e]
		_add(cell_at(position),e,returned,moments)
		ledger.withdrawals -= returned
		ledger.withdrawal_elements[e] -= returned
	allocations.erase(id)
	if close: _close_ledger()
