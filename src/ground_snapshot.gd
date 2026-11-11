extends RefCounted
var w: int
var h: int
var heights: PackedByteArray
var water: PackedByteArray
var biome: PackedByteArray
var rivers: PackedByteArray
var directions: PackedByteArray
var data: Dictionary
const DIRECTIONS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
func _height(x: int, y: int) -> float:
	return float(heights.decode_u16((clampi(y, 0, h - 1) * w + clampi(x, 0, w - 1)) * 2)) / 30000.0
func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < w and cell.y >= 0 and cell.y < h
