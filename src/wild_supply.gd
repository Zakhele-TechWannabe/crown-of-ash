extends RefCounted
## What the forest and the spring can give to tempering bodies: iron-bark patches, a beast herd, seven-leaf herbs.
## Everything regrows slowly and the valley's richness scales it all, so ambition can outrun supply.
const Combat = preload("res://src/combat.gd")
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/wild.json"))
var society_ref: WeakRef
var richness := 0.5
var patch_stock := PackedFloat32Array()
var patch_last_taker := PackedInt32Array()
var herd := 0.0
var herd_cap := 0.0
var herbs := 0.0
## This year's tallies, reset each new year; last_year keeps the finished one for reports.
var year_stats: Dictionary = {}
var last_year: Dictionary = {}
var stats_year := -1

func _init(society: RefCounted) -> void:
	society_ref = weakref(society)
	richness = float(config.richness)
	var bark: Dictionary = config.iron_bark
	for patch in bark.patches.size():
		patch_stock.append(float(bark.cap_per_patch) * richness)
		patch_last_taker.append(-1)
	refresh_herd()
	herbs = float(config.seven_leaf.cap) * richness
	_reset_stats()

func _reset_stats() -> void:
	year_stats = {"roots_taken": 0, "stripped_trips": 0, "hunts": 0, "kills": 0, "hunt_injuries": 0, "herbs_taken": 0, "herb_misses": 0}

func units(medicine: String) -> int:
	return int(config.dose_units[medicine])

## Regrowth for the whole valley, once per society week.
func week(days: int, on_day: int) -> void:
	if on_day / 365 != stats_year:
		if stats_year >= 0: last_year = year_stats.duplicate()
		stats_year = on_day / 365
		_reset_stats()
	var years := days / 365.0
	var bark: Dictionary = config.iron_bark
	var cap := float(bark.cap_per_patch) * richness
	for patch in patch_stock.size():
		patch_stock[patch] = minf(cap, patch_stock[patch] + float(bark.regrow_per_patch_year) * richness * years)
	refresh_herd()
	var leaf: Dictionary = config.seven_leaf
	herbs = minf(float(leaf.cap) * richness, herbs + float(leaf.per_year) * richness * years)

## One trip to the forest: the gatherer checks two patches they know and takes from the fuller.
func gather_bark(p: int) -> Dictionary:
	var rng: RandomNumberGenerator = society_ref.get_ref().population.rng
	var a := rng.randi_range(0, patch_stock.size() - 1)
	var b := rng.randi_range(0, patch_stock.size() - 1)
	var patch := a if patch_stock[a] >= patch_stock[b] else b
	var taken := mini(int(config.iron_bark.take_per_trip), floori(patch_stock[patch]))
	var place: String = config.iron_bark.patches[patch]
	var before: int = patch_last_taker[patch]
	if taken <= 0:
		year_stats.stripped_trips += 1
		return {"taken": 0, "place": place, "stripped_by": before}
	patch_stock[patch] -= taken
	patch_last_taker[patch] = p
	year_stats.roots_taken += taken
	return {"taken": taken, "place": place, "stripped_by": -1, "emptied": patch_stock[patch] < 1.0}

## A hunt: first find a beast (a thinned herd is harder to find), then fight it (see combat.gd). Deer run,
## boars and bears fight back, and stronger, better-tempered, more skilled hunters do better.
func hunt(p: int) -> Dictionary:
	var society: RefCounted = society_ref.get_ref()
	var store: RefCounted = society.population
	year_stats.hunts += 1
	var wildlife: RefCounted = society.wildlife
	wildlife.seed(store.day)
	herd = wildlife.count("Cervus nippon") + wildlife.count("Sus scrofa")
	var target: Dictionary = wildlife.hunting_target()
	if target.is_empty(): return {"kill":false,"hurt":false,"dead":false}
	var kind: String = wildlife.entry(target.species).combat_profile_id
	var fight: Dictionary = Combat.hunt(society, p, kind, wildlife.profile(target) if target.has("id") else {}, float(target.get("harm",0)), bool(target.get("awakened",false)))
	wildlife.resolve_hunt(target, fight)
	if fight.kill:
		herd -= 1.0
		year_stats.kills += 1
	if fight.hurt or fight.dead: year_stats.hunt_injuries += 1
	return fight

func gather_herb(p: int) -> bool:
	if herbs >= 1.0:
		herbs -= 1.0
		year_stats.herbs_taken += 1
		return true
	year_stats.herb_misses += 1
	return false

func bark_total() -> float:
	var total := 0.0
	for stock in patch_stock: total += stock
	return total

func summary() -> Dictionary:
	return {"bark_in_patches": snappedf(bark_total(), .1), "herd": snappedf(herd, .1), "herd_cap": herd_cap, "herbs": snappedf(herbs, .1),
		"last_year": last_year}

## Read the huntable population directly, including before the first society week.
func refresh_herd() -> void:
	var wildlife: RefCounted = society_ref.get_ref().wildlife
	if wildlife == null: return
	wildlife.seed(society_ref.get_ref().population.day)
	herd_cap = wildlife.hunting_capacity()
	herd = 0.0
	for sci: String in wildlife.config.hunt_species: herd += wildlife.count(sci)
