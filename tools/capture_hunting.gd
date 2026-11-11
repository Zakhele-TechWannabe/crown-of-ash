extends SceneTree
## Headless terrain-only fallback when no display server is available.
func _initialize() -> void:
	call_deferred("run")

func crop(g: Node2D, rect: Rect2i, path: String, far: bool = false) -> void:
	var scale := 32 if not far else 12
	var level: int = g.terrace_level(rect.get_center())
	var shift := roundi(level * g.exaggeration / 32.0)
	var projected := Rect2i(rect.position - Vector2i(0, shift), rect.size)
	var image := Image.create(rect.size.x * scale, rect.size.y * scale, false, Image.FORMAT_RGBA8)
	for cy in range(floori(projected.position.y / 64.0), ceili((projected.end.y + (0 if far else 45)) / 64.0)):
		for cx in range(floori(rect.position.x / 64.0), ceili(rect.end.x / 64.0)):
			var key := Vector2i(cx, cy)
			var chunk: Image
			var offset := (key * 64 - projected.position) * scale
			if far:
				chunk = g._far_image(key).duplicate()
				chunk.resize(64 * scale, 64 * scale, Image.INTERPOLATE_NEAREST)
			else:
				var baker: RefCounted = g._new_baker()
				baker.bake(key)
				chunk = baker.pending.image
				chunk.resize(64 * scale, chunk.get_height() * 2, Image.INTERPOLATE_NEAREST)
				offset.y += (int(baker.pending.min_y) - int(baker.pending.overflow)) * 2
			image.blend_rect(chunk, Rect2i(Vector2i.ZERO, chunk.get_size()), offset)
	assert(image.save_png(path) == OK)

func run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	await process_frame
	crop(map.ground, Rect2i(1772, 2295, 58, 34), "res://out/hunt-close.png")
	crop(map.ground, Rect2i(1720, 2250, 160, 90), "res://out/hunt-mid.png", true)
	crop(map.ground, Rect2i(1710, 2275, 58, 34), "res://out/hunt-trail.png")
	print("PASS hunting captures: headless terrain crops, close detailed and mid far LOD")
	quit()
