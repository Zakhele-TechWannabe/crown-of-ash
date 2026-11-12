extends SceneTree
func _initialize() -> void:
	var p := preload("res://src/population.gd").new()
	var job := p.register_job("farmer", ["fields"])
	for i in 12:
		p.add_person("Wang %d" % i, 500 - i * 40, job, i)
		if i > 0: p.society.father[i] = i - 1
	p.sex[0] = 1
	p.parent_id[1] = 0
	p.society.father[1] = -1
	p.society.seed()
	var id: int = p.society.faction_keys["clan:0"]
	assert(p.society.factions[id].members.size() == 12, "Clans retain descendants beyond eight generations")
	var clans := 0
	for faction: Dictionary in p.society.factions:
		if faction.type == "clan" and not faction.members.is_empty(): clans += 1
	assert(clans == 1, "Do not create overlapping clans for each qualifying ancestor")
	p.society.refresh_factions()
	assert(p.society.factions[id].members.size() == 12)
	print("PASS clans: twelve living generations, maternal surname link, one canonical founder and stable rebuilding")
	quit()
