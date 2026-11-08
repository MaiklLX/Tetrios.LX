extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Main = preload("res://scripts/main.gd")

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
	var layout_probe = Main.new()
	var narrow_gutter: Dictionary = layout_probe._buddy_layout_for_gutter(60.0)
	if not _check(not narrow_gutter.visible, "Buddy must hide when the left gutter is too narrow"):
		return
	var previous_scale := 0.0
	for gutter_width in [70.0, 85.0, 120.0, 220.0]:
		var layout: Dictionary = layout_probe._buddy_layout_for_gutter(gutter_width)
		if not _check(layout.visible, "Buddy should remain visible when the gutter meets its minimum width"):
			return
		var buddy_right := 8.0 + 98.0 * float(layout.scale)
		if not _check(buddy_right <= gutter_width - 8.0 + 0.01, "Buddy must preserve an 8px gap before the playfield"):
			return
		if not _check(float(layout.scale) >= previous_scale, "Buddy scale must not shrink as the gutter gets wider"):
			return
		previous_scale = float(layout.scale)
	var wide_gutter: Dictionary = layout_probe._buddy_layout_for_gutter(220.0)
	if not _check(wide_gutter.visible and is_equal_approx(wide_gutter.scale, 1.0), "Buddy must use full size when the gutter is wide"):
		return

	# Gravity accelerates with level but never exceeds the safe minimum speed.
	var level_one_interval: float = layout_probe._gravity_interval_for_level(1)
	var level_five_interval: float = layout_probe._gravity_interval_for_level(5)
	var level_twenty_interval: float = layout_probe._gravity_interval_for_level(20)
	if not _check(is_equal_approx(level_one_interval, 0.78), "Level one must use the baseline gravity interval"):
		return
	if not _check(level_five_interval < level_one_interval, "Gravity must accelerate as the level increases"):
		return
	if not _check(is_equal_approx(level_twenty_interval, 0.08), "Gravity must respect the minimum interval floor"):
		return

	# Phone-safe layout: controls stay inside the viewport and the board
	# remains between the stats/previews region and the control row.
	for viewport_size in [Vector2(360.0, 800.0), Vector2(375.0, 812.0), Vector2(412.0, 915.0), Vector2(450.0, 800.0), Vector2(720.0, 1280.0)]:
		var control_metrics: Dictionary = layout_probe._control_metrics(viewport_size.x, viewport_size.y)
		if not _check(float(control_metrics.start_x) >= 11.9, "Control row must keep a safe left margin on phone widths"):
			return
		if not _check(float(control_metrics.start_x) + float(control_metrics.total) <= viewport_size.x - 11.9, "Control row must not overflow the right edge"):
			return
		var board_metrics: Dictionary = layout_probe._board_metrics(viewport_size, float(control_metrics.button_y))
		var responsive_board: Rect2 = board_metrics.board_rect
		if not _check(responsive_board.position.y >= 292.0, "Board must stay below the stats and preview region"):
			return
		if not _check(responsive_board.end.y <= float(control_metrics.button_y) - 17.9, "Board must keep clearance above the control row"):
			return
		if not _check(responsive_board.position.x >= 35.9 and responsive_board.end.x <= viewport_size.x - 35.9, "Board must remain horizontally centered with side gutters"):
			return
	layout_probe.game = Model.new()
	layout_probe.game.reset()
	layout_probe.pause_rect = Rect2(10.0, 10.0, 50.0, 50.0)
	layout_probe.resume_rect = Rect2(100.0, 100.0, 100.0, 50.0)
	layout_probe._handle_tap(Vector2(20.0, 20.0))
	if not _check(layout_probe.paused, "Pause button tap must freeze the run"):
		return
	layout_probe._handle_tap(Vector2(150.0, 120.0))
	if not _check(not layout_probe.paused, "Resume button tap must unfreeze the run"):
		return
	layout_probe.game.game_over = true
	layout_probe._toggle_pause()
	if not _check(not layout_probe.paused, "Pause must not activate after game over"):
		return
	layout_probe.game = Model.new()
	layout_probe.game.reset()
	layout_probe.board_rect = Rect2(0.0, 0.0, 380.0, 874.0)
	var swipe_start_x: int = layout_probe.game.origin.x
	if not _check(layout_probe._handle_swipe(Vector2(100.0, 100.0), Vector2(176.0, 100.0)), "Horizontal board swipe should be handled"):
		return
	if not _check(layout_probe.game.origin.x == swipe_start_x + 2, "Horizontal swipe distance should map to bounded cell movement"):
		return
	var swipe_start_y: int = layout_probe.game.origin.y
	if not _check(layout_probe._handle_swipe(Vector2(100.0, 100.0), Vector2(100.0, 172.0)), "Downward board swipe should be handled"):
		return
	if not _check(layout_probe.game.origin.y == swipe_start_y + 2, "Downward swipe should soft-drop by the corresponding number of cells"):
		return
	layout_probe.game.active_type = 1
	layout_probe.game.active_cells.assign(Model.SHAPES[1])
	var cells_before_swipe_rotate: Array = layout_probe.game.active_cells.duplicate()
	if not _check(layout_probe._handle_swipe(Vector2(100.0, 100.0), Vector2(100.0, 40.0)), "Upward board swipe should be handled"):
		return
	if not _check(layout_probe.game.active_cells != cells_before_swipe_rotate, "Upward swipe should rotate the active piece"):
		return
	if not _check(not layout_probe._handle_swipe(Vector2(500.0, 100.0), Vector2(420.0, 100.0)), "Swipes beginning outside the board must not steal button taps"):
		return
	layout_probe.free()
	var model: BlockBuddiesModel = Model.new()
	model.reset()
	if not _check(model.grid.size() == 23, "Board must contain 23 rows"):
		return
	if not _check(model.grid[0].size() == 10, "Board must contain 10 columns"):
		return
	if not _check(model.active_cells.size() == 4, "Spawned piece must contain four cells"):
		return

	# Preview must report the real next piece without consuming it.
	var preview_model: BlockBuddiesModel = Model.new()
	preview_model.reset()
	var preview_type := preview_model.peek_next_piece_type()
	var preview_bag_size := preview_model.piece_bag.size()
	if not _check(preview_type == preview_model.peek_next_piece_type(), "Next-piece preview must remain stable until spawn"):
		return
	if not _check(preview_model.piece_bag.size() == preview_bag_size, "Reading the preview must not consume the piece bag"):
		return
	if not _check(preview_model._next_piece_type() == preview_type, "The spawned piece must match the displayed Next preview"):
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

	var first_held_type := model.active_type
	model.hold_piece()
	if not _check(model.held_type == first_held_type and model.hold_used, "First Hold must store the active piece"):
		return
	var piece_after_hold := model.active_type
	var stored_type := model.held_type
	model.hold_piece()
	if not _check(model.active_type == piece_after_hold and model.held_type == stored_type, "Hold must be limited to once per falling piece"):
		return
	model.hard_drop()
	if not _check(not model.hold_used, "Locking a piece must re-enable Hold for the next piece"):
		return
	var next_spawned_type := model.active_type
	model.hold_piece()
	if not _check(model.active_type == first_held_type and model.held_type == next_spawned_type, "Second Hold must swap the stored and active pieces"):
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

	# Ten consecutive single-line clears must advance the level exactly once.
	var progression_model: BlockBuddiesModel = Model.new()
	progression_model.reset()
	for clear_index in range(10):
		for x in range(Model.WIDTH):
			progression_model.grid[22][x] = 1 if x < 3 or x > 6 else -1
		progression_model.active_type = 0
		progression_model.active_cells.assign(Model.SHAPES[0])
		progression_model.origin = Vector2i(3, 0)
		progression_model.hard_drop()
	if not _check(progression_model.lines == 10, "Ten cleared lines must be counted cumulatively"):
		return
	if not _check(progression_model.level == 2, "Every ten cleared lines must advance the level"):
		return
	if not _check(progression_model.score == 1440, "Line-clear and hard-drop scoring must remain consistent through the level transition"):
		return
	progression_model.reset()
	if not _check(progression_model.lines == 0 and progression_model.level == 1 and progression_model.score == 0, "Restart must reset run score, lines, and level"):
		return

	# Multi-line clear fixtures: vertical I completes two, three, or four rows.
	for clear_count in [2, 3, 4]:
		var multi_model: BlockBuddiesModel = Model.new()
		multi_model.reset()
		for row_offset in range(clear_count):
			var row_y: int = Model.HEIGHT - 1 - row_offset
			for x in range(Model.WIDTH):
				if x != 3:
					multi_model.grid[row_y][x] = 1
		multi_model.active_type = 0
		multi_model.active_cells.assign(Model.SHAPES[0])
		multi_model.origin = Vector2i(3, 0)
		multi_model.rotate_piece()
		multi_model.hard_drop()
		var expected_rewards := [0, 100, 300, 500, 800]
		if not _check(multi_model.lines == clear_count, "Multi-line fixture must clear the requested number of rows"):
			return
		if not _check(multi_model.score == expected_rewards[clear_count] + 38, "Two-, three-, and four-line clears must award the correct base reward plus hard-drop points"):
			return
		var surviving_piece_cells: int = 4 - clear_count
		for row_offset in range(clear_count):
			var row_y: int = Model.HEIGHT - 1 - row_offset
			for x in range(Model.WIDTH):
				var expected_cell: int = 0 if row_offset < surviving_piece_cells and x == 3 else -1
				if not _check(multi_model.grid[row_y][x] == expected_cell, "Rows must compact correctly after a multi-line clear"):
					return

	# Four-line clear at level two must apply the level multiplier.
	var level_two_model: BlockBuddiesModel = Model.new()
	level_two_model.reset()
	level_two_model.lines = 10
	level_two_model.level = 2
	for row_offset in range(4):
		var row_y: int = Model.HEIGHT - 1 - row_offset
		for x in range(Model.WIDTH):
			if x != 3:
				level_two_model.grid[row_y][x] = 1
	level_two_model.active_type = 0
	level_two_model.active_cells.assign(Model.SHAPES[0])
	level_two_model.origin = Vector2i(3, 0)
	level_two_model.rotate_piece()
	level_two_model.hard_drop()
	if not _check(level_two_model.lines == 14 and level_two_model.level == 2, "Four-line clear at level two must preserve cumulative progression"):
		return
	if not _check(level_two_model.score == 1638, "Four-line clear at level two must award 800 points multiplied by two, plus hard-drop points"):
		return

	print("Godot model tests passed: 10x23 board, seven-bag, movement, rotation, Hold, preview, 1-4 line clears, scoring, level progression, and reset.")
	quit(0)
