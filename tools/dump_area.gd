extends SceneTree
## Prints terrace levels (and water/trees) around a tile, to plan things on the real ground.
## godot --headless --path . -s res://tools/dump_area.gd -- --at=1365,2286 --r=40 --step=2

func _initialize() -> void:
	var at := Vector2i(1365, 2286)
	var r := 40
	var step := 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var p := a.trim_prefix("--at=").split(",")
			at = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--r="):
			r = int(a.trim_prefix("--r="))
		elif a.begins_with("--step="):
			step = int(a.trim_prefix("--step="))
	var map: Node = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var g = map.ground
	var best := at
	var best_h := -1.0
	for y in range(at.y - r, at.y + r + 1, step):
		var line := ""
		for x in range(at.x - r, at.x + r + 1, step):
			var t := Vector2i(x, y)
			var h: float = g.ground_height(t)
			if h > best_h:
				best_h = h
				best = t
			var info: Dictionary = g.sample(t)
			var lv: int = g.terrace_level(t)
			var ch := str(lv % 10) if lv < 36 else "#"
			if info.kind <= 2:
				ch = "~"
			elif t == at:
				ch = "@"
			line += ch
		print(line)
	print("highest %s h=%.3f level %d" % [best, best_h, g.terrace_level(best)])
	print("here level %d cover %s" % [g.terrace_level(at), g.sample(at).cover])
	quit()
