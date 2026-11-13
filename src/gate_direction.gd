extends RefCounted
## Read lanes outside the footprint: the old atlas stamp inside remains collision-only.
static func east_west(source: RefCounted, origin: Vector2i, w: int, h: int) -> bool:
	var center := Vector2(origin - source.center) + Vector2(w, h) * 0.5
	var nearest := float(maxi(w, h) + 4)
	var tangent := Vector2.ZERO
	var paths: Array = source.data.get("paths", []).duplicate()
	if source.data.has("road"): paths.append(source.data.road)
	for path: Dictionary in paths:
		var points: Array = path.points
		for i in range(1, points.size()):
			var a := Vector2(float(points[i - 1][0]), float(points[i - 1][1]))
			var b := Vector2(float(points[i][0]), float(points[i][1]))
			var distance := center.distance_to(Geometry2D.get_closest_point_to_segment(center, a, b))
			if distance < nearest and a != b:
				nearest = distance
				tangent = b - a
	if tangent != Vector2.ZERO: return absf(tangent.x) > absf(tangent.y)
	var horizontal := 0
	var vertical := 0
	for y in range(-1, h + 2):
		for x in [-2, w + 1]:
			if source.surface_at(origin + Vector2i(x, y)) in ["earth", "paving", "bridge", "stairs"]: horizontal += 1
	for x in range(-1, w + 2):
		for y in [-2, h + 1]:
			if source.surface_at(origin + Vector2i(x, y)) in ["earth", "paving", "bridge", "stairs"]: vertical += 1
	if horizontal == vertical: return h > w
	return horizontal > vertical
