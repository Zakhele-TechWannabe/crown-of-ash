extends SceneTree
## Prints terrace levels (and water/trees) around a tile, to plan things on the real ground.
## godot --headless --path . -s res://tools/dump_area.gd -- --at=1365,2286 --r=40 --step=2

func _initialize() -> void:
	var at := Vector2i(1365, 2286)
	var r := 40
	var step := 2
	var trail := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var p := a.trim_prefix("--at=").split(",")
			at = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--r="):
			r = int(a.trim_prefix("--r="))
		elif a == "--trail":
			trail = true
		elif a.begins_with("--step="):
			step = int(a.trim_prefix("--step="))
	var map: Node = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var g = map.ground
	if trail:
		var routes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/roads/hunting_trails.json"))
		var points: Array = routes.paths[0].points
		for i in range(0, points.size(), 80):
			var t := Vector2i(points[i][0], points[i][1])
			print("trail %d %s height %.3f level %d" % [i, t, g.ground_height(t), g.terrace_level(t)])
		var first := Vector2i(points[0][0], points[0][1])
		var last := Vector2i(points[-1][0], points[-1][1])
		print("trail climb %d -> %d (%d levels)" % [g.terrace_level(first), g.terrace_level(last), g.terrace_level(last) - g.terrace_level(first)])
		quit()
		return
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
