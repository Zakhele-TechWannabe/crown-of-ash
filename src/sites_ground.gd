extends "res://src/sect_ground.gd"
## Immutable after setup. Chunk buckets bound lookup work to local overlays.
var hunting := preload("res://src/hunting_ground.gd").new()
var buckets: Dictionary = {}
var destinations: Dictionary = {}
var sites: Array[RefCounted] = []

func setup(is_dry: Callable) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sites/index.json"))
	source = str(manifest.get("sect", source))
	super.setup(is_dry)
	hunting.setup()
	for argument: String in OS.get_cmdline_args():
		if argument.ends_with("build_roads.gd"):
			return
	for file: String in manifest.sites:
		var site := preload("res://src/sect_ground.gd").new()
		site.source = "res://data/sites/" + file
		site.setup(is_dry)
		sites.append(site)
		labels.append_array(site.labels)
		# Site buildings stand, level their ground and keep trees off, like the sect's own.
		standing.append_array(site.standing)
		plinth.merge(site.plinth)
		standing_tiles.merge(site.standing_tiles)
		var rect: Rect2i = Rect2i(site.center + site.bounds.position, site.bounds.size)
		for y in range(floori(rect.position.y / 64.0), floori((rect.end.y - 1) / 64.0) + 1):
			for x in range(floori(rect.position.x / 64.0), floori((rect.end.x - 1) / 64.0) + 1):
				var key := Vector2i(x, y)
				if not buckets.has(key):
					buckets[key] = []
				buckets[key].append(site)
	for name: String in manifest.destinations:
		var at: Array = manifest.destinations[name]
		destinations[name] = Vector2i(int(at[0]), int(at[1]))

func overlay_at(at: Vector2i) -> RefCounted:
	var key := Vector2i(floori(at.x / 64.0), floori(at.y / 64.0))
	for site: RefCounted in buckets.get(key, []):
		if site.has_tile(at) or site.level_at(at) >= 0:
			return site
	return null

func has_tile(at: Vector2i) -> bool:
	return super.has_tile(at) or overlay_at(at) != null

func level_at(at: Vector2i) -> int:
	var site := overlay_at(at)
	return site.level_at(at) if site != null and site.level_at(at) >= 0 else super.level_at(at)

func height_at(at: Vector2i) -> float:
	var site := overlay_at(at)
	return site.height_at(at) if site != null else super.height_at(at)

func surface_at(at: Vector2i) -> String:
	var site := overlay_at(at)
	return site.surface_at(at) if site != null else super.surface_at(at)

func draw_tile(image: Image, tile: Vector2i, pos: Vector2i) -> void:
	var site := overlay_at(tile)
	if site != null:
		site.draw_tile(image, tile, pos)
	else:
		super.draw_tile(image, tile, pos)

func far_color(tile: Vector2i) -> Color:
	var site := overlay_at(tile)
	return site.far_color(tile) if site != null else super.far_color(tile)

func site_height(tile: Vector2i, natural: float) -> float:
	return hunting.cached_height(tile, natural)
