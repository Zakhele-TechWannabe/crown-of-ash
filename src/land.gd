extends RefCounted
## Packed cell state; only marked fields receive daily updates.
enum { GRASS, TILLED, HOUSE }
const W := 104
const H := 78
const T := 32.0
var tiles := PackedByteArray()
var field_ids := PackedInt32Array()
var crops := PackedByteArray()
var fertility := PackedFloat32Array()
var growth := PackedFloat32Array()
var housing := PackedByteArray()

func build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	tiles.resize(W * H)
	field_ids.resize(W * H)
	crops.resize(W * H)
	fertility.resize(W * H)
	growth.resize(W * H)
	housing.resize(W * H)
	field_ids.fill(-1)
	crops.fill(3)
	for i in W * H:
		fertility[i] = rng.randf_range(66, 74)

func at(c: Vector2i) -> int:
	return tiles[index(c)] if _in(c.x, c.y) else -1

func index(c: Vector2i) -> int:
	return c.y * W + c.x

func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H

func center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * T
