extends SceneTree

const Model = preload("res://scripts/game_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model: BlockBuddiesModel = Model.new()
	model.reset()
	assert(model.grid.size() == 20, "Board must contain 20 rows")
	assert(model.grid[0].size() == 10, "Board must contain 10 columns")
	assert(model.active_cells.size() == 4, "Every piece must contain four cells")

	var start_x := model.origin.x
	model.move_horizontal(-1)
	assert(model.origin.x == start_x - 1, "Horizontal movement should move one cell")

	model.rotate_piece()
	assert(model.active_cells.size() == 4, "Rotation must preserve all four cells")

	# Deterministic single-line clear fixture.
	model.reset()
	for x in range(Model.WIDTH):
		if x < 3 or x > 6:
			model.grid[19][x] = 1
	model.active_type = 0
	model.active_cells = Model.SHAPES[0].duplicate()
	model.origin = Vector2i(3, 18)
	model.hard_drop()
	assert(model.lines == 1, "Completing the bottom row must clear exactly one line")
	for x in range(Model.WIDTH):
		assert(model.grid[19][x] == -1, "Cleared row must be empty")
	assert(model.score >= 100, "A line clear must award score")

	print("Godot model tests passed: board, movement, rotation, line clear.")
	quit(0)
