class_name BlockBuddiesCampaignPieceRuntime
extends RefCounted

# KT-537: isolated campaign-owned runtime. Never imported by the shared model.
const Model = preload("res://scripts/game_model.gd")
const SpecialPiece = preload("res://scripts/campaign_special_piece.gd")
const WIDTH := 10
const HEIGHT := 23
const RUNTIME_VERSION := 1
const SPECIAL_TYPE := 7

var grid: Array = []
var active_piece_id := -1
var active_cells: Array[Vector2i] = []
var rotation_index := 0
var origin := Vector2i.ZERO
var held_piece_id := -1
var hold_used := false
var game_over := false
var score := 0
var lines := 0
var lock_serial := 0
var piece_bag: Array[int] = []

func reset(spawn_initial_standard: bool = true) -> void:
	grid.clear()
	for y in range(HEIGHT):
		var row: Array[int] = []
		for x in range(WIDTH):
			row.append(-1)
		grid.append(row)
	active_piece_id = -1
	active_cells.clear()
	rotation_index = 0
	origin = Vector2i.ZERO
	held_piece_id = -1
	hold_used = false
	game_over = false
	score = 0
	lines = 0
	lock_serial = 0
	piece_bag.clear()
	_refill_bag()
	if spawn_initial_standard:
		spawn_next_standard()

func _refill_bag() -> void:
	piece_bag.clear()
	for index in range(Model.SHAPES.size()):
		piece_bag.append(index)
	for i in range(piece_bag.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var value := piece_bag[i]
		piece_bag[i] = piece_bag[j]
		piece_bag[j] = value

func _shape_for(piece_id: int, rotation: int = 0) -> Array[Vector2i]:
	if piece_id == SPECIAL_TYPE:
		return SpecialPiece.cells_for_rotation(rotation)
	if piece_id < 0 or piece_id >= Model.SHAPES.size():
		return []
	var cells: Array[Vector2i] = []
	for cell in Model.SHAPES[piece_id]:
		cells.append(cell)
	for _turn in range(posmod(rotation, 4)):
		var rotated: Array[Vector2i] = []
		for cell in cells:
			rotated.append(Vector2i(-cell.y, cell.x))
		cells = _normalize(rotated)
	return cells

func _normalize(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := 999
	var min_y := 999
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	var result: Array[Vector2i] = []
	for cell in cells:
		result.append(cell - Vector2i(min_x, min_y))
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return result

func _centered_origin(cells: Array[Vector2i]) -> Vector2i:
	var width := 0
	for cell in cells:
		width = maxi(width, cell.x + 1)
	return Vector2i(floori(float(WIDTH - width) / 2.0), 0)

func _collides(at: Vector2i, cells: Array[Vector2i]) -> bool:
	for cell in cells:
		var point := at + cell
		if point.x < 0 or point.x >= WIDTH or point.y < 0 or point.y >= HEIGHT:
			return true
		if grid[point.y][point.x] != -1:
			return true
	return false

func spawn_piece(piece_id: int) -> bool:
	if game_over or piece_id < 0 or piece_id > SPECIAL_TYPE:
		return false
	var next_cells := _shape_for(piece_id, 0)
	if next_cells.is_empty():
		return false
	var next_origin := _centered_origin(next_cells)
	if _collides(next_origin, next_cells):
		game_over = true
		return false
	active_piece_id = piece_id
	active_cells = next_cells
	rotation_index = 0
	origin = next_origin
	return true

func spawn_next_standard() -> bool:
	if game_over:
		return false
	if piece_bag.is_empty():
		_refill_bag()
	var next_id: int = int(piece_bag.pop_front())
	return spawn_piece(next_id)

func spawn_authored_special() -> bool:
	# Authored pieces may enter only an empty spawn slot; never discard a falling piece.
	if game_over or active_piece_id != -1 or not active_cells.is_empty():
		return false
	return spawn_piece(SPECIAL_TYPE)

func move_horizontal(direction: int) -> bool:
	if game_over or active_piece_id < 0:
		return false
	var candidate := origin + Vector2i(clampi(direction, -1, 1), 0)
	if _collides(candidate, active_cells):
		return false
	origin = candidate
	return true

func rotate_piece() -> bool:
	if game_over or active_piece_id < 0:
		return false
	var next_rotation := posmod(rotation_index + 1, 4)
	var next_cells := _shape_for(active_piece_id, next_rotation)
	var kicks: Array = SpecialPiece.WALL_KICKS if active_piece_id == SPECIAL_TYPE else [0, -1, 1]
	for kick in kicks:
		var candidate := origin + Vector2i(int(kick), 0)
		if not _collides(candidate, next_cells):
			origin = candidate
			active_cells = next_cells
			rotation_index = next_rotation
			return true
	return false

func hold_piece() -> bool:
	if game_over or hold_used or active_piece_id < 0:
		return false
	var outgoing := active_piece_id
	if held_piece_id == -1:
		held_piece_id = outgoing
		hold_used = true
		return spawn_next_standard()
	var incoming := held_piece_id
	var next_cells := _shape_for(incoming, 0)
	var next_origin := _centered_origin(next_cells)
	if _collides(next_origin, next_cells):
		game_over = true
		return false
	held_piece_id = outgoing
	active_piece_id = incoming
	active_cells = next_cells
	rotation_index = 0
	origin = next_origin
	hold_used = true
	return true

func soft_drop() -> bool:
	if game_over:
		return false
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		score += 1
		return true
	_lock_piece()
	return false

func hard_drop() -> int:
	if game_over:
		return 0
	var distance := 0
	while not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		distance += 1
	score += distance * 2
	_lock_piece()
	return distance

func tick() -> void:
	if game_over:
		return
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
	else:
		_lock_piece()

func _lock_piece() -> void:
	for cell in active_cells:
		var point := origin + cell
		grid[point.y][point.x] = active_piece_id
	var cleared := 0
	var y := HEIGHT - 1
	while y >= 0:
		var full := true
		for x in range(WIDTH):
			if grid[y][x] == -1:
				full = false
				break
		if full:
			grid.remove_at(y)
			var row: Array[int] = []
			for x in range(WIDTH):
				row.append(-1)
			grid.push_front(row)
			cleared += 1
		else:
			y -= 1
	if cleared > 0:
		lines += cleared
		var line_rewards := [0, 100, 300, 500, 800]
		score += line_rewards[mini(cleared, 4)]
	lock_serial += 1
	hold_used = false
	spawn_next_standard()

func snapshot() -> Dictionary:
	var saved_grid: Array = []
	for row in grid:
		saved_grid.append(row.duplicate())
	var saved_cells: Array = []
	for cell in active_cells:
		saved_cells.append([cell.x, cell.y])
	return {
		"version": RUNTIME_VERSION,
		"grid": saved_grid,
		"active_piece_id": active_piece_id,
		"active_cells": saved_cells,
		"rotation_index": rotation_index,
		"origin": [origin.x, origin.y],
		"held_piece_id": held_piece_id,
		"hold_used": hold_used,
		"game_over": game_over,
		"score": score,
		"lines": lines,
		"lock_serial": lock_serial,
		"piece_bag": piece_bag.duplicate()
	}

func restore(data: Dictionary) -> bool:
	# Strictly validate the entire snapshot before mutating this runtime.
	if typeof(data.get("version")) != TYPE_INT or int(data.version) != RUNTIME_VERSION:
		return false
	var saved_grid: Variant = data.get("grid")
	var saved_cells: Variant = data.get("active_cells")
	var saved_origin: Variant = data.get("origin")
	var saved_bag: Variant = data.get("piece_bag")
	if typeof(saved_grid) != TYPE_ARRAY or saved_grid.size() != HEIGHT:
		return false
	if typeof(saved_cells) != TYPE_ARRAY or typeof(saved_origin) != TYPE_ARRAY or saved_origin.size() != 2:
		return false
	if typeof(saved_bag) != TYPE_ARRAY or saved_bag.size() > Model.SHAPES.size():
		return false
	var candidate_grid: Array = []
	for row_value in saved_grid:
		if typeof(row_value) != TYPE_ARRAY or row_value.size() != WIDTH:
			return false
		var row: Array[int] = []
		for value in row_value:
			if typeof(value) != TYPE_INT or int(value) < -1 or int(value) > SPECIAL_TYPE:
				return false
			row.append(int(value))
		candidate_grid.append(row)
	var candidate_id: Variant = data.get("active_piece_id")
	var candidate_rotation: Variant = data.get("rotation_index")
	var candidate_hold: Variant = data.get("held_piece_id")
	var candidate_hold_used: Variant = data.get("hold_used")
	var candidate_over: Variant = data.get("game_over")
	var candidate_score: Variant = data.get("score")
	var candidate_lines: Variant = data.get("lines")
	var candidate_serial: Variant = data.get("lock_serial")
	if typeof(candidate_id) != TYPE_INT or int(candidate_id) < 0 or int(candidate_id) > SPECIAL_TYPE:
		return false
	if typeof(candidate_rotation) != TYPE_INT or int(candidate_rotation) < 0 or int(candidate_rotation) > 3:
		return false
	if typeof(candidate_hold) != TYPE_INT or int(candidate_hold) < -1 or int(candidate_hold) > SPECIAL_TYPE:
		return false
	if typeof(candidate_hold_used) != TYPE_BOOL or typeof(candidate_over) != TYPE_BOOL:
		return false
	if typeof(candidate_score) != TYPE_INT or int(candidate_score) < 0 or typeof(candidate_lines) != TYPE_INT or int(candidate_lines) < 0:
		return false
	if typeof(candidate_serial) != TYPE_INT or int(candidate_serial) < 0:
		return false
	if typeof(saved_origin[0]) != TYPE_INT or typeof(saved_origin[1]) != TYPE_INT:
		return false
	var candidate_origin := Vector2i(int(saved_origin[0]), int(saved_origin[1]))
	var candidate_cells: Array[Vector2i] = []
	for cell_value in saved_cells:
		if typeof(cell_value) != TYPE_ARRAY or cell_value.size() != 2 or typeof(cell_value[0]) != TYPE_INT or typeof(cell_value[1]) != TYPE_INT:
			return false
		candidate_cells.append(Vector2i(int(cell_value[0]), int(cell_value[1])))
	var expected_cells := _shape_for(int(candidate_id), int(candidate_rotation))
	if candidate_cells != expected_cells or expected_cells.is_empty():
		return false
	if candidate_origin.x < 0 or candidate_origin.y < 0 or candidate_origin.y >= HEIGHT:
		return false
	for cell in candidate_cells:
		var point := candidate_origin + cell
		if point.x < 0 or point.x >= WIDTH or point.y >= HEIGHT:
			return false
		if not bool(candidate_over) and candidate_grid[point.y][point.x] != -1:
			return false
	if int(candidate_hold) == SPECIAL_TYPE and int(candidate_id) == SPECIAL_TYPE:
		return false
	var candidate_bag: Array[int] = []
	var seen: Dictionary = {}
	for value in saved_bag:
		if typeof(value) != TYPE_INT or int(value) < 0 or int(value) >= Model.SHAPES.size() or seen.has(int(value)):
			return false
		seen[int(value)] = true
		candidate_bag.append(int(value))
	grid = candidate_grid
	active_piece_id = int(candidate_id)
	active_cells = candidate_cells
	rotation_index = int(candidate_rotation)
	origin = candidate_origin
	held_piece_id = int(candidate_hold)
	hold_used = bool(candidate_hold_used)
	game_over = bool(candidate_over)
	score = int(candidate_score)
	lines = int(candidate_lines)
	lock_serial = int(candidate_serial)
	piece_bag = candidate_bag
	return true
