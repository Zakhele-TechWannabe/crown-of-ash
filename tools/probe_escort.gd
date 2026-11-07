extends SceneTree
## Samples what foragers and their escorts are doing over the first days.
## godot --headless --path . -s res://tools/probe_escort.gd

const Realm := preload("res://src/realm.gd")


func _init() -> void:
	var r := Realm.new()
	r.setup(1)
	var counts := {}
	var t := 0.0
	while r.day <= 3:
		r.step(1.0 / 30.0)
		t += 1.0 / 30.0
		if t >= 2.0 and r.phase == Realm.DAY:
			t = 0.0
			for p in r.people:
				if p.job == "forage" or p.order == "escort":
					var k: String = "%s: %s" % [p.name, p.doing.get_slice(" ", 0) + " " + p.doing.get_slice(" ", 1)]
					counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for k in keys:
		print("%4d  %s" % [counts[k], k])
	for line in r.log:
		if ["escort", "safer", "Too many", "rest", "mended", "fallen"].any(func(w): return w in str(line[1])):
			print(line)
	quit()
