extends SceneTree

const Model = preload("res://scripts/game_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	seed(20261105)
	var model: BlockBuddiesModel = Model.new()
	model.reset()
	if not _check(model.grid.size() == 23, "Board must contain 23 rows"):
		return
	if not _check(model.grid[0].size() == 10, "Board must contain 10 columns"):
		return
	if not _check(model.active_cells.size() == 4, "Spawned piece must contain four cells"):
		return
	for piece_index in range(Model.SHAPES.size()):
		if not _check(Model.SHAPES[piece_index].size() == 4, "Every tetromino definition must contain four cells"):
			return
	if not _check(model._centered_spawn_x(Model.SHAPES[0]) == 3, "I piece spawn must be centered"):
		return
	if not _check(model._centered_spawn_x(Model.SHAPES[4]) == 4, "O piece spawn must be centered"):
		return
	if not _check(model._centered_spawn_x(Model.SHAPES[1]) == 3, "T piece spawn must be centered"):
		return

	# The source uses a seven-bag and forbids repeats across bag boundaries.
	var bag_sequence: Array[int] = [model.active_type]
	for i in range(6):
		bag_sequence.append(model._next_piece_type())
	var unique_types: Dictionary = {}
	for piece_type in bag_sequence:
		unique_types[piece_type] = true
	if not _check(unique_types.size() == 7, "A seven-bag must contain every tetromino exactly once"):
		return
	var previous_type: int = bag_sequence[6]
	var boundary_type: int = model._next_piece_type()
	if not _check(boundary_type != previous_type, "Seven-bag boundary must not repeat the previous piece"):
		return

	var start_x := model.origin.x
	model.move_horizontal(-1)
	if not _check(model.origin.x == start_x - 1, "Horizontal movement should move one cell"):
		return

	model.rotate_piece()
	if not _check(model.active_cells.size() == 4, "Rotation must preserve all four cells"):
		return

	# Deterministic single-line clear fixture.
	model.reset()
	for x in range(Model.WIDTH):
		if x < 3 or x > 6:
			model.grid[22][x] = 1
	model.active_type = 0
	model.active_cells.assign(Model.SHAPES[0])
	model.origin = Vector2i(3, 0)
	model.hard_drop()
	if not _check(model.lines == 1, "Completing the bottom row must clear exactly one line"):
		return
	for x in range(Model.WIDTH):
		if not _check(model.grid[22][x] == -1, "Cleared row must be empty"):
			return
	if not _check(model.score >= 100, "A line clear must award score"):
		return

	print("Godot model tests passed: 10x23 board, seven-bag, spawn centering, movement, rotation, and line clear.")
	quit(0)
