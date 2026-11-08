extends SceneTree
## Lets realms run for ten days by themselves, with the warband sent at each village in turn and a sensible
## build order, and reports how far each got.
## godot --headless --path . -s res://tools/test_realm.gd

const Realm := preload("res://src/realm.gd")


func _init() -> void:
	var days := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--days="):
			days = int(a.get_slice("=", 1))
	for seed_val in ([1, 2] if not "--one" in OS.get_cmdline_user_args() else [1]):
		var r := Realm.new()
		r.setup(seed_val)
		for id in ["gate", "beds", "fletcher", "mill", "palisade", "towers", "barracks", "bell"]:
			r.queue_upgrade(0, id)
		var trained := false
		var frames := 0
		var order := [3, 6, 1, 4, 5, 7, 2, 8]
		while r.phase in [Realm.DAY, Realm.NIGHT] and r.day <= days and frames < 60 * 60 * 60:
			# from day 3, newcomers (and the guard) are raised as a warband once there are enough of them
			if r.day >= 3:
				var band := r.people.filter(func(p): return p.order == "warband" and p.job == "soldier")
				var spare := r.people.filter(func(p): return p.job in ["rest", "guard"])
				if band.size() + spare.size() >= Realm.WARBAND_MIN and band.size() < Realm.WARBAND_MIN:
					for p in spare.slice(0, Realm.WARBAND_MIN - band.size()):
						p.job = "soldier"
						r.set_order(p, "warband")
			if r.target < 0 and r.day >= 3:
				for h in order:
					if not r.land.holdings[h].claimed:
						r.send_warband(h)
						break
			if not trained and r.has_built(0, "barracks"):
				trained = true
				for p in r.people:
					if p.job == "soldier":
						r.train(p, "man_at_arms")
						break
			var d0 := r.day
			r.step(1.0 / 30.0)
			if r.day != d0:
				var hb := r.block_of(r.land.holdings[0].center)
				var near := 0
				for b in Realm.BW * Realm.BH:
					if r._bdist(b, hb) <= 6:
						near += r.dead_at(b)
				var layers := r.people.map(func(p): return p.layer)
				print("  dawn %d: people %d food %.0f wood %.0f arrows %d dead %d (near the capital %d)  cultivated %d, best layer %d" % [r.day, r.people.size(),
					r.stock.food, r.stock.wood, r.stock.arrows, r.dead_total(), near, layers.filter(func(l): return l > 0).size(), layers.max()])
			frames += 1
		var held := r.holdings_owned().map(func(h): return r.land.holdings[h].name)
		print("realm %d: %s day %d  people %d  food %.0f wood %.0f arrows %d  held %s  dead %d  built %s" % [seed_val,
			["", "", "LOST on", "WON on"][r.phase] if r.phase >= 2 else "reached", r.day, r.people.size(), r.stock.food,
			r.stock.wood, r.stock.arrows, ", ".join(held), r.dead_total(), ",".join(r.built[0].keys())])
		var st := r.stakes(0)
		print("      palisade %d/%d  towers %d  soldiers %d" % [st.x, st.y, r.tower_count[0], r.people.filter(func(p): return p.job == "soldier").size()])
		for l in r.log.slice(maxi(0, r.log.size() - 8)):
			print("      day %d: %s" % l)
	quit()
