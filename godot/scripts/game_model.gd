class_name BlockBuddiesModel
extends RefCounted

const WIDTH := 10
const HEIGHT := 23
const SHAPES: Array = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
]
const PALETTE: Array[Color] = [
	Color("#5cf5e8"), Color("#9d7cff"), Color("#ffc86b"),
	Color("#ff6f9e"), Color("#6ca8ff"), Color("#b6f27c"), Color("#ff9868")
]

var grid: Array = []
var active_cells: Array[Vector2i] = []
var active_type := 0
var origin := Vector2i(3, 0)
var score := 0
var lines := 0
var level := 1
var game_over := false
var held_type := -1
var hold_used := false
var piece_bag: Array[int] = []
var last_random_type := -1
# Ephemeral event cursor for deterministic gameplay-to-encounter dispatch.
var lock_serial := 0
var last_lock_cleared := 0

func reset() -> void:
	grid.clear()
	for y in range(HEIGHT):
		var row: Array = []
		for x in range(WIDTH):
			row.append(-1)
		grid.append(row)
	score = 0
	lines = 0
	level = 1
	game_over = false
	held_type = -1
	hold_used = false
	piece_bag.clear()
	last_random_type = -1
	lock_serial = 0
	last_lock_cleared = 0
	_spawn()

func _refill_piece_bag() -> void:
	piece_bag.clear()
	for piece_index in range(SHAPES.size()):
		piece_bag.append(piece_index)
	for i in range(piece_bag.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var swap_value := piece_bag[i]
		piece_bag[i] = piece_bag[j]
		piece_bag[j] = swap_value
	# Match the web source: no repeated piece at a seven-bag boundary.
	if piece_bag.size() > 1 and piece_bag[0] == last_random_type:
		var swap_index := randi_range(1, piece_bag.size() - 1)
		var first_value := piece_bag[0]
		piece_bag[0] = piece_bag[swap_index]
		piece_bag[swap_index] = first_value

func peek_next_piece_type() -> int:
	if piece_bag.is_empty():
		_refill_piece_bag()
	return piece_bag[0]

func _next_piece_type() -> int:
	if piece_bag.is_empty():
		_refill_piece_bag()
	var next_type: int = piece_bag.pop_front()
	last_random_type = next_type
	return next_type

func _centered_spawn_x(cells: Array) -> int:
	var shape_width := 0
	for cell in cells:
		shape_width = maxi(shape_width, cell.x + 1)
	return floori(float(WIDTH - shape_width) / 2.0)

func _spawn() -> void:
	active_type = _next_piece_type()
	active_cells.assign(SHAPES[active_type])
	origin = Vector2i(_centered_spawn_x(active_cells), 0)
	if _collides(origin, active_cells):
		game_over = true

func hold_piece() -> void:
	if game_over or hold_used:
		return
	var outgoing_type := active_type
	if held_type == -1:
		held_type = outgoing_type
		hold_used = true
		_spawn()
		return
	active_type = held_type
	held_type = outgoing_type
	active_cells.assign(SHAPES[active_type])
	origin = Vector2i(_centered_spawn_x(active_cells), 0)
	hold_used = true
	if _collides(origin, active_cells):
		game_over = true

func _collides(at: Vector2i, cells: Array) -> bool:
	for cell in cells:
		var p: Vector2i = at + cell
		if p.x < 0 or p.x >= WIDTH or p.y >= HEIGHT:
			return true
		if p.y >= 0 and grid[p.y][p.x] != -1:
			return true
	return false

func move_horizontal(direction: int) -> void:
	if game_over:
		return
	var next := origin + Vector2i(clampi(direction, -1, 1), 0)
	if not _collides(next, active_cells):
		origin = next

func rotate_piece() -> void:
	if game_over:
		return
	var rotated: Array[Vector2i] = []
	for cell in active_cells:
		rotated.append(Vector2i(-cell.y, cell.x))
	var min_x := 999
	var min_y := 999
	for cell in rotated:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	for i in range(rotated.size()):
		rotated[i] -= Vector2i(min_x, min_y)
	for kick in [0, -1, 1]:
		var candidate := origin + Vector2i(kick, 0)
		if not _collides(candidate, rotated):
			origin = candidate
			active_cells = rotated
			return

func soft_drop() -> void:
	if game_over:
		return
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		score += 1
	else:
		_lock_piece()

func hard_drop() -> void:
	if game_over:
		return
	var distance := 0
	while not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		distance += 1
	score += distance * 2
	_lock_piece()

func tick() -> void:
	if game_over:
		return
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
	else:
		_lock_piece()

func _lock_piece() -> void:
	for cell in active_cells:
		var p: Vector2i = origin + cell
		if p.y >= 0 and p.y < HEIGHT:
			grid[p.y][p.x] = active_type
	var cleared := 0
	var y: int = HEIGHT - 1
	while y >= 0:
		var full := true
		for x in range(WIDTH):
			if grid[y][x] == -1:
				full = false
				break
		if full:
			grid.remove_at(y)
			var new_row: Array = []
			for x in range(WIDTH):
				new_row.append(-1)
			grid.push_front(new_row)
			cleared += 1
			# Re-check this index: the row above has shifted into it.
		else:
			y -= 1
	if cleared > 0:
		lines += cleared
		var rewards := [0, 100, 300, 500, 800]
		score += rewards[mini(cleared, 4)] * level
		level = 1 + int(lines / 10)
	hold_used = false
	lock_serial += 1
	last_lock_cleared = cleared
	_spawn()


const SAVE_VERSION := 1

# JSON-safe snapshot only. File/storage ownership stays outside the model.
func to_save_data() -> Dictionary:
	var saved_grid: Array = []
	for row in grid:
		saved_grid.append(row.duplicate())
	var saved_cells: Array = []
	for cell in active_cells:
		saved_cells.append([cell.x, cell.y])
	return {
		"version": SAVE_VERSION,
		"grid": saved_grid,
		"active_type": active_type,
		"active_cells": saved_cells,
		"origin": [origin.x, origin.y],
		"score": score,
		"lines": lines,
		"level": level,
		"game_over": game_over,
		"held_type": held_type,
		"hold_used": hold_used,
		"piece_bag": piece_bag.duplicate(),
		"last_random_type": last_random_type
	}

func load_save_data(data: Dictionary) -> bool:
	# Validate into local candidates first. A rejected snapshot must not
	# partially overwrite the current live game.
	if typeof(data.get("version")) != TYPE_INT or int(data.get("version")) != SAVE_VERSION:
		return false
	var saved_grid: Variant = data.get("grid")
	var saved_cells: Variant = data.get("active_cells")
	var saved_origin: Variant = data.get("origin")
	var saved_bag: Variant = data.get("piece_bag")
	if typeof(saved_grid) != TYPE_ARRAY or saved_grid.size() != HEIGHT:
		return false
	if typeof(saved_cells) != TYPE_ARRAY or saved_cells.size() != 4:
		return false
	if typeof(saved_origin) != TYPE_ARRAY or saved_origin.size() != 2:
		return false
	if typeof(saved_bag) != TYPE_ARRAY or saved_bag.size() > SHAPES.size():
		return false

	var restored_grid: Array = []
	for row_value in saved_grid:
		if typeof(row_value) != TYPE_ARRAY or row_value.size() != WIDTH:
			return false
		var restored_row: Array = []
		for tile_value in row_value:
			if typeof(tile_value) != TYPE_INT or int(tile_value) < -1 or int(tile_value) >= SHAPES.size():
				return false
			restored_row.append(int(tile_value))
		restored_grid.append(restored_row)

	var restored_type: Variant = data.get("active_type")
	var restored_score: Variant = data.get("score")
	var restored_lines: Variant = data.get("lines")
	var restored_level: Variant = data.get("level")
	var restored_game_over: Variant = data.get("game_over")
	var restored_held_type: Variant = data.get("held_type")
	var restored_hold_used: Variant = data.get("hold_used")
	var restored_last_type: Variant = data.get("last_random_type")
	if typeof(restored_type) != TYPE_INT or int(restored_type) < 0 or int(restored_type) >= SHAPES.size():
		return false
	if typeof(restored_score) != TYPE_INT or int(restored_score) < 0:
		return false
	if typeof(restored_lines) != TYPE_INT or int(restored_lines) < 0:
		return false
	if typeof(restored_level) != TYPE_INT or int(restored_level) != 1 + int(int(restored_lines) / 10):
		return false
	if typeof(restored_game_over) != TYPE_BOOL or typeof(restored_hold_used) != TYPE_BOOL:
		return false
	if typeof(restored_held_type) != TYPE_INT or int(restored_held_type) < -1 or int(restored_held_type) >= SHAPES.size():
		return false
	if typeof(restored_last_type) != TYPE_INT or int(restored_last_type) < -1 or int(restored_last_type) >= SHAPES.size():
		return false
	if typeof(saved_origin[0]) != TYPE_INT or typeof(saved_origin[1]) != TYPE_INT:
		return false
	var restored_origin := Vector2i(int(saved_origin[0]), int(saved_origin[1]))
	if restored_origin.x < 0 or restored_origin.y < 0 or restored_origin.y >= HEIGHT:
		return false

	var restored_cells: Array[Vector2i] = []
	var unique_cells: Dictionary = {}
	for cell_value in saved_cells:
		if typeof(cell_value) != TYPE_ARRAY or cell_value.size() != 2:
			return false
		if typeof(cell_value[0]) != TYPE_INT or typeof(cell_value[1]) != TYPE_INT:
			return false
		var cell := Vector2i(int(cell_value[0]), int(cell_value[1]))
		if cell.x < 0 or cell.x > 3 or cell.y < 0 or cell.y > 3:
			return false
		var cell_key := "%d:%d" % [cell.x, cell.y]
		if unique_cells.has(cell_key):
			return false
		unique_cells[cell_key] = true
		var board_position := restored_origin + cell
		if board_position.x < 0 or board_position.x >= WIDTH or board_position.y < 0 or board_position.y >= HEIGHT:
			return false
		if not bool(restored_game_over) and restored_grid[board_position.y][board_position.x] != -1:
			return false
		restored_cells.append(cell)

	var restored_bag: Array[int] = []
	var unique_bag: Dictionary = {}
	for piece_value in saved_bag:
		if typeof(piece_value) != TYPE_INT or int(piece_value) < 0 or int(piece_value) >= SHAPES.size():
			return false
		if unique_bag.has(int(piece_value)):
			return false
		unique_bag[int(piece_value)] = true
		restored_bag.append(int(piece_value))

	# Commit only after every field and board invariant has passed.
	grid = restored_grid
	active_type = int(restored_type)
	active_cells = restored_cells
	origin = restored_origin
	score = int(restored_score)
	lines = int(restored_lines)
	level = int(restored_level)
	game_over = bool(restored_game_over)
	held_type = int(restored_held_type)
	hold_used = bool(restored_hold_used)
	piece_bag.assign(restored_bag)
	last_random_type = int(restored_last_type)
	return true

# Re-check the active piece after an encounter-owned board rescue.
func resume_after_board_rescue() -> bool:
	if not game_over:
		return true
	if _collides(origin, active_cells):
		return false
	game_over = false
	return true

func ghost_origin() -> Vector2i:
	var ghost := origin
	while not _collides(ghost + Vector2i(0, 1), active_cells):
		ghost.y += 1
	return ghost
