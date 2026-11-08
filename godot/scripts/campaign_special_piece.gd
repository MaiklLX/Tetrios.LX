class_name BlockBuddiesCampaignSpecialPiece
extends RefCounted

# KT-534: first original campaign-only pentomino prototype.
# This data/geometry module is intentionally not referenced by game_model.gd.

const PIECE_ID := "cargo_hook"
const DISPLAY_NAME := "Грузовой крюк"
const BLOCK_COUNT := 5
const BASE_CELLS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, 2)
]
const WALL_KICKS := [0, -1, 1, -2, 2]

static func cells_for_rotation(rotation_index: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = BASE_CELLS.duplicate()
	var turns := posmod(rotation_index, 4)
	for _turn in range(turns):
		var rotated: Array[Vector2i] = []
		for cell in cells:
			rotated.append(Vector2i(-cell.y, cell.x))
		cells = _normalize(rotated)
	return cells

static func _normalize(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := 999
	var min_y := 999
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	var normalized: Array[Vector2i] = []
	for cell in cells:
		normalized.append(cell - Vector2i(min_x, min_y))
	normalized.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return normalized

static func dimensions(cells: Array[Vector2i]) -> Vector2i:
	var width := 0
	var height := 0
	for cell in cells:
		width = maxi(width, cell.x + 1)
		height = maxi(height, cell.y + 1)
	return Vector2i(width, height)

static func centered_spawn_origin(board_width: int, rotation_index: int = 0) -> Vector2i:
	var size := dimensions(cells_for_rotation(rotation_index))
	return Vector2i(floori(float(board_width - size.x) / 2.0), 0)

static func fits(
	board_width: int,
	board_height: int,
	origin: Vector2i,
	cells: Array[Vector2i],
	blocked_cells: Array = []
) -> bool:
	for cell in cells:
		var position := origin + cell
		if position.x < 0 or position.x >= board_width or position.y < 0 or position.y >= board_height:
			return false
		if blocked_cells.has(position):
			return false
	return true

static func try_rotate(
	board_width: int,
	board_height: int,
	origin: Vector2i,
	rotation_index: int,
	blocked_cells: Array = []
) -> Dictionary:
	var next_rotation := posmod(rotation_index + 1, 4)
	var next_cells := cells_for_rotation(next_rotation)
	for kick in WALL_KICKS:
		var candidate_origin := origin + Vector2i(kick, 0)
		if fits(board_width, board_height, candidate_origin, next_cells, blocked_cells):
			return {
				"accepted": true,
				"rotation": next_rotation,
				"origin": candidate_origin,
				"cells": next_cells
			}
	return {
		"accepted": false,
		"rotation": posmod(rotation_index, 4),
		"origin": origin,
		"cells": cells_for_rotation(rotation_index)
	}
