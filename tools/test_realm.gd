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
		var order := [2, 1, 3, 6, 4, 5, 7]
		while r.phase in [Realm.DAY, Realm.NIGHT] and r.day <= days and frames < 60 * 60 * 60:
			if r.day >= 3 and r.people.size() > 1 and not r.people.any(func(p): return p.order == "warband" and p.job == "soldier"):
				var sol := r.people.filter(func(p): return p.job == "soldier")
				if not sol.is_empty():
					r.set_order(sol[-1], "warband")
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
				var ring: Rect2i = r.rings[0]
				var near := r.dead.filter(func(z): return ring.grow(4).has_point(r.land.cell(z.p))).size()
				print("  dawn %d: people %d food %.0f wood %.0f dead %d (near Ashford %d, lurkers %d)" % [r.day, r.people.size(), r.stock.food, r.stock.wood, r.dead.size(), near, r.dead.filter(func(z): return z.lurker >= 0).size()])
			frames += 1
		var held := r.holdings_owned().map(func(h): return r.land.holdings[h].name)
		print("realm %d: %s day %d  people %d  food %.0f wood %.0f arrows %d  held %s  dead %d  built %s" % [seed_val,
			["", "", "LOST on", "WON on"][r.phase] if r.phase >= 2 else "reached", r.day, r.people.size(), r.stock.food,
			r.stock.wood, r.stock.arrows, ", ".join(held), r.dead.size(), ",".join(r.built[0].keys())])
		var st := r.stakes(0)
		print("      palisade %d/%d  towers %d  units %s" % [st.x, st.y, r.tower_count[0], ", ".join(r.people.filter(func(p): return p.job == "soldier").map(func(p): return "%s %s %s" % [p.name, p.unit, p.order]))])
		for l in r.log.slice(maxi(0, r.log.size() - 8)):
			print("      day %d: %s" % l)
	quit()
