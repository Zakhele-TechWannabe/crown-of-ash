extends RefCounted
## A grass plain with tiles reserved for settlement growth.

enum { GRASS, ROAD, FIELD, HOUSE }
const W := 104
const H := 78
const T := 32.0

var tiles := PackedByteArray()


## The founding plain is clear for every seed.
func build(_seed_value: int) -> void:
	tiles.resize(W * H)
	tiles.fill(GRASS)


## Cells outside the plain cannot be settled.
func at(c: Vector2i) -> int:
	return tiles[c.y * W + c.x] if _in(c.x, c.y) else -1


## Only cells within the map can change.
func _in(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


## The middle of a tile in drawing coordinates.
func center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * T
