extends SceneTree

const Model = preload("res://scripts/game_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model: BlockBuddiesModel = Model.new()
	model.reset()
	assert(model.grid.size() == 23, "Board must contain 23 rows")
	assert(model.grid[0].size() == 10, "Board must contain 10 columns")
	assert(model.active_cells.size() == 4, "Every piece must contain four cells")
	assert(model._centered_spawn_x(Model.SHAPES[0]) == 3, "I piece spawn must be centered")
	assert(model._centered_spawn_x(Model.SHAPES[4]) == 4, "O piece spawn must be centered")
	assert(model._centered_spawn_x(Model.SHAPES[1]) == 3, "T piece spawn must be centered")

	# The source uses a seven-bag and forbids repeats across bag boundaries.
	var bag_sequence: Array[int] = [model.active_type]
	for i in range(6):
		bag_sequence.append(model._next_piece_type())
	var unique_types: Dictionary = {}
	for piece_type in bag_sequence:
		unique_types[piece_type] = true
	assert(unique_types.size() == 7, "A seven-bag must contain every tetromino exactly once")
	var previous_type: int = bag_sequence[6]
	var boundary_type: int = model._next_piece_type()
	assert(boundary_type != previous_type, "Seven-bag boundary must not repeat the previous piece")

	var start_x := model.origin.x
	model.move_horizontal(-1)
	assert(model.origin.x == start_x - 1, "Horizontal movement should move one cell")

	model.rotate_piece()
	assert(model.active_cells.size() == 4, "Rotation must preserve all four cells")

	# Deterministic single-line clear fixture.
	model.reset()
	for x in range(Model.WIDTH):
		if x < 3 or x > 6:
			model.grid[22][x] = 1
	model.active_type = 0
	model.active_cells = Model.SHAPES[0].duplicate()
	model.origin = Vector2i(3, 0)
	model.hard_drop()
	assert(model.lines == 1, "Completing the bottom row must clear exactly one line")
	for x in range(Model.WIDTH):
		assert(model.grid[22][x] == -1, "Cleared row must be empty")
	assert(model.score >= 100, "A line clear must award score")

	print("Godot model tests passed: board, movement, rotation, line clear.")
	quit(0)
