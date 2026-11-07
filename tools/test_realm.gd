extends SceneTree
## Lets realms run for ten days by themselves, with the warband sent at each village in turn and a sensible
## build order, and reports how far each got.
## godot --headless --path . -s res://tools/test_realm.gd

const Realm := preload("res://src/realm.gd")


func _init() -> void:
	for seed_val in [1, 2, 3]:
		var r := Realm.new()
		r.setup(seed_val)
		for id in ["gate", "beds", "fletcher", "mill", "shutters", "barracks", "bell"]:
			r.queue_upgrade(0, id)
		var frames := 0
		var order := [2, 1, 3, 6, 4, 5, 7]
		while r.phase in [Realm.DAY, Realm.NIGHT] and r.day <= 10 and frames < 60 * 60 * 40:
			if r.target < 0:
				for h in order:
					if not r.land.holdings[h].claimed:
						r.send_warband(h)
						break
			r.step(1.0 / 30.0)
			frames += 1
		var held := r.holdings_owned().map(func(h): return r.land.holdings[h].name)
		print("realm %d: %s day %d  people %d  food %.0f wood %.0f arrows %d  held %s  dead %d  built %s" % [seed_val,
			["", "", "LOST on", "WON on"][r.phase] if r.phase >= 2 else "reached", r.day, r.people.size(), r.stock.food,
			r.stock.wood, r.stock.arrows, ", ".join(held), r.dead.size(), ",".join(r.built[0].keys())])
		for l in r.log.slice(maxi(0, r.log.size() - 5)):
			print("      day %d: %s" % l)
	quit()
