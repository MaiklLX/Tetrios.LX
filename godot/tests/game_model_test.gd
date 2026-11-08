extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Main = preload("res://scripts/main.gd")
const WebMigration = preload("res://scripts/web_save_migration.gd")
const Buddy = preload("res://scripts/buddy_companion.gd")
const ModeCatalog = preload("res://scripts/mode_catalog.gd")
const ModeSession = preload("res://scripts/mode_session.gd")

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
	# Mode catalog keeps mode definitions isolated from the classic model.
	var available_modes: Array[Dictionary] = ModeCatalog.list_modes()
	if not _check(available_modes.size() == 2, "The initial catalog should expose Classic and Sprint only"):
		return
	var classic_rules: Dictionary = ModeCatalog.get_mode("classic")
	if not _check(classic_rules.get("target_lines", -1) == 0 and classic_rules.get("time_limit_seconds", -1) == 0, "Classic must remain an unlimited default mode"):
		return
	if not _check(classic_rules.get("id", "") == ModeCatalog.DEFAULT_MODE_ID, "Classic must be the safe default mode"):
		return
	var sprint_rules: Dictionary = ModeCatalog.get_mode("sprint")
	if not _check(sprint_rules.get("target_lines", 0) == 40 and sprint_rules.get("time_limit_seconds", -1) == 0, "Sprint must use a clear 40-line objective without an unapproved timer"):
		return
	if not _check(ModeCatalog.get_mode("unknown").is_empty(), "Unknown mode IDs must not silently map to another mode"):
		return
	classic_rules["target_lines"] = 999
	if not _check(ModeCatalog.get_mode("classic").get("target_lines", -1) == 0, "Callers must not be able to mutate catalog definitions"):
		return

	# Mode session owns objective completion without changing the classic board model.
	var classic_session = ModeSession.new()
	if not _check(classic_session.start(ModeCatalog.DEFAULT_MODE_ID), "Classic session should start from the catalog default"):
		return
	classic_session.update(1.0, 40, false)
	if not _check(classic_session.status == ModeSession.STATUS_RUNNING, "Classic must remain active after forty lines"):
		return
	classic_session.update(0.0, 40, true)
	if not _check(classic_session.status == ModeSession.STATUS_FAILED, "Classic should fail only when the board model reports game over"):
		return
	var sprint_session = ModeSession.new()
	if not _check(sprint_session.start("sprint"), "Sprint session should start"):
		return
	sprint_session.update(0.0, 39, false)
	if not _check(sprint_session.status == ModeSession.STATUS_RUNNING and sprint_session.remaining_lines(39) == 1, "Sprint should remain active with one line remaining"):
		return
	sprint_session.update(0.0, 40, false)
	if not _check(sprint_session.status == ModeSession.STATUS_COMPLETED, "Sprint should complete exactly at its forty-line target"):
		return
	sprint_session.update(0.0, 45, true)
	if not _check(sprint_session.status == ModeSession.STATUS_COMPLETED, "A completed Sprint result must remain terminal"):
		return
	var invalid_session = ModeSession.new()
	if not _check(not invalid_session.start("missing") and invalid_session.status == ModeSession.STATUS_IDLE, "Unknown mode must not create a running session"):
		return

	# Main scene respects terminal mode state: Sprint freezes at its goal and restarts cleanly.
	var mode_main = Main.new()
	mode_main.game = Model.new()
	mode_main.game.reset()
	mode_main.mode_session = ModeSession.new()
	mode_main.mode_session.start("sprint")
	mode_main.buddy = Buddy.new()
	mode_main.game.lines = 40
	mode_main._sync_buddy_state()
	if not _check(mode_main.mode_session.status == ModeSession.STATUS_COMPLETED, "Main scene should register Sprint completion as soon as the target is reached"):
		return
	var completed_origin: Vector2i = mode_main.game.origin
	mode_main._process(3.0)
	if not _check(mode_main.game.origin == completed_origin, "Gravity must stop after Sprint completion"):
		return
	if not _check(not mode_main._handle_swipe(Vector2(10.0, 10.0), Vector2(10.0, 100.0)), "Gameplay swipes must be ignored after Sprint completion"):
		return
	mode_main._handle_tap(Vector2.ZERO)
	if not _check(mode_main.mode_session.status == ModeSession.STATUS_RUNNING and mode_main.game.lines == 0, "Tap after Sprint completion should restart the same mode cleanly"):
		return
	mode_main.free()

	# Buddy reactions are stateful, bounded, and return to idle cleanly.
	var buddy_probe = Buddy.new()
	buddy_probe.set_state("happy", 0.1)
	if not _check(buddy_probe.state == "happy", "Buddy should accept a supported reaction state"):
		return
	buddy_probe._process(0.11)
	if not _check(buddy_probe.state == "idle", "Timed Buddy reactions should return to idle"):
		return
	buddy_probe.set_state("not-a-state", 1.0)
	if not _check(buddy_probe.state == "idle", "Buddy should ignore unsupported reaction states"):
		return

	var feedback_probe = Main.new()
	feedback_probe.game = Model.new()
	feedback_probe.game.reset()
	feedback_probe.buddy = Buddy.new()
	feedback_probe._sync_buddy_state()
	feedback_probe.game.lines = 2
	feedback_probe._sync_buddy_state()
	if not _check(feedback_probe.clear_flash_count == 2 and feedback_probe.clear_flash_time > 0.0, "Line clears should trigger visible celebration feedback"):
		return
	if not _check(feedback_probe.buddy.state == "happy", "Single and double line clears should trigger Buddy happy reaction"):
		return
	feedback_probe.game.lines = 6
	feedback_probe._sync_buddy_state()
	if not _check(feedback_probe.clear_flash_count == 4 and feedback_probe.buddy.state == "victory", "Four-line clear should trigger the special Buddy bonus reaction"):
		return

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

	# Touch-first layout: no permanent control row; maximize the playfield
	# while keeping safe margins and the HUD/preview region clear.
	for viewport_size in [Vector2(360.0, 800.0), Vector2(375.0, 812.0), Vector2(412.0, 915.0), Vector2(450.0, 800.0), Vector2(720.0, 1280.0)]:
		var board_metrics: Dictionary = layout_probe._board_metrics(viewport_size)
		var responsive_board: Rect2 = board_metrics.board_rect
		if not _check(responsive_board.position.y >= 292.0, "Board must stay below the stats and preview region"):
			return
		if not _check(responsive_board.end.y <= viewport_size.y - 35.9, "Board must preserve a bottom safe margin"):
			return
		if not _check(responsive_board.position.x >= 31.9 and responsive_board.end.x <= viewport_size.x - 31.9, "Board must remain horizontally centered with side gutters"):
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
	# A fast long downward swipe is the sole touch hard-drop gesture.
	layout_probe.game.reset()
	if not _check(layout_probe._handle_swipe(Vector2(100.0, 100.0), Vector2(100.0, 400.0), 220), "Fast long downward swipe should be handled"):
		return
	var occupied_after_drop := 0
	for row in layout_probe.game.grid:
		for cell in row:
			if cell >= 0:
				occupied_after_drop += 1
	if not _check(occupied_after_drop >= 4, "Fast long downward swipe must lock the piece with a hard drop"):
		return
	# A slow drag over the same distance must remain soft drop.
	layout_probe.game.reset()
	if not _check(layout_probe._handle_swipe(Vector2(100.0, 100.0), Vector2(100.0, 400.0), 700), "Slow downward drag should be handled"):
		return
	var slow_drop_locked_cells := 0
	for row in layout_probe.game.grid:
		for cell in row:
			if cell >= 0:
				slow_drop_locked_cells += 1
	if not _check(slow_drop_locked_cells == 0, "Slow downward drag must not hard-drop or lock the piece"):
		return
	# A single board tap rotates only; it must never trigger hard drop.
	layout_probe.game.reset()
	layout_probe.board_rect = Rect2(0.0, 0.0, 380.0, 874.0)
	layout_probe.hold_rect = Rect2(400.0, 0.0, 80.0, 50.0)
	var before_tap_origin: Vector2i = layout_probe.game.origin
	var before_tap_cells: Array = layout_probe.game.active_cells.duplicate()
	layout_probe._handle_tap(Vector2(100.0, 100.0))
	if not _check(layout_probe.game.origin == before_tap_origin and layout_probe.game.active_cells != before_tap_cells, "Single board tap must rotate without dropping the piece"):
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

	# A blocked spawn must end the run; game-over must reject further moves and drops.
	var game_over_model: BlockBuddiesModel = Model.new()
	game_over_model.reset()
	for x in range(1, Model.WIDTH):
		game_over_model.grid[0][x] = 1
	game_over_model.hard_drop()
	if not _check(game_over_model.game_over, "A blocked next-piece spawn must trigger game over"):
		return
	var game_over_origin: Vector2i = game_over_model.origin
	var game_over_score: int = game_over_model.score
	game_over_model.move_horizontal(-1)
	game_over_model.hard_drop()
	if not _check(game_over_model.origin == game_over_origin and game_over_model.score == game_over_score, "Game over must reject movement and hard drop"):
		return
	game_over_model.reset()
	if not _check(not game_over_model.game_over and game_over_model.score == 0 and game_over_model.lines == 0 and game_over_model.level == 1, "Restart after game over must restore a fresh run"):
		return
	if not _check(game_over_model.held_type == -1 and not game_over_model.hold_used, "Restart after game over must clear Hold state"):
		return
	for y in range(Model.HEIGHT):
		for x in range(Model.WIDTH):
			if not _check(game_over_model.grid[y][x] == -1, "Restart after game over must clear the entire board"):
				return

	# Versioned snapshot round-trip must preserve a complete live run.
	var save_source: BlockBuddiesModel = Model.new()
	save_source.reset()
	save_source.hard_drop()
	save_source.hold_piece()
	save_source.move_horizontal(1)
	save_source.piece_bag.clear()
	save_source.peek_next_piece_type()
	if not _check(save_source.piece_bag.size() == Model.SHAPES.size(), "A preview at the seven-bag boundary must refill the full queue"):
		return
	var saved_state: Dictionary = save_source.to_save_data()
	var restored_model: BlockBuddiesModel = Model.new()
	restored_model.reset()
	if not _check(restored_model.load_save_data(saved_state), "A valid versioned snapshot must restore successfully"):
		return
	if not _check(restored_model.to_save_data() == saved_state, "Snapshot round-trip must preserve board, active piece, bag, Hold, and scoring state"):
		return

	# Malformed snapshots must be rejected without mutating the live model.
	var preserved_state: Dictionary = restored_model.to_save_data()
	var bad_version: Dictionary = saved_state.duplicate(true)
	bad_version["version"] = 999
	if not _check(not restored_model.load_save_data(bad_version), "Unknown snapshot versions must be rejected"):
		return
	if not _check(restored_model.to_save_data() == preserved_state, "Rejected version must not mutate the current run"):
		return
	var bad_grid: Dictionary = saved_state.duplicate(true)
	bad_grid["grid"][0].pop_back()
	if not _check(not restored_model.load_save_data(bad_grid), "Snapshots with malformed board dimensions must be rejected"):
		return
	if not _check(restored_model.to_save_data() == preserved_state, "Rejected board data must not partially overwrite the current run"):
		return
	var bad_bag: Dictionary = saved_state.duplicate(true)
	bad_bag["piece_bag"] = [0, 0]
	if not _check(not restored_model.load_save_data(bad_bag), "Snapshots with duplicate pieces in the bag must be rejected"):
		return
	if not _check(restored_model.to_save_data() == preserved_state, "Rejected bag data must leave the current run unchanged"):
		return
	var bad_level: Dictionary = saved_state.duplicate(true)
	bad_level["level"] = 99
	if not _check(not restored_model.load_save_data(bad_level), "Inconsistent level and line totals must be rejected"):
		return

	# Collision boundaries: horizontal I must not cross either side wall.
	var boundary_model: BlockBuddiesModel = Model.new()
	boundary_model.reset()
	boundary_model.active_type = 0
	boundary_model.active_cells.assign(Model.SHAPES[0])
	boundary_model.origin = Vector2i(0, 0)
	boundary_model.move_horizontal(-1)
	if not _check(boundary_model.origin.x == 0, "Active piece must not move beyond the left wall"):
		return
	boundary_model.origin = Vector2i(Model.WIDTH - 4, 0)
	boundary_model.move_horizontal(1)
	if not _check(boundary_model.origin.x == Model.WIDTH - 4, "Active piece must not move beyond the right wall"):
		return

	# A piece resting on the floor must lock on the next downward step.
	var lock_model: BlockBuddiesModel = Model.new()
	lock_model.reset()
	lock_model.active_type = 4
	lock_model.active_cells.assign(Model.SHAPES[4])
	lock_model.origin = Vector2i(4, Model.HEIGHT - 2)
	if not _check(lock_model._collides(lock_model.origin + Vector2i(0, 1), lock_model.active_cells), "A piece at the floor must detect the bottom boundary"):
		return
	var locked_type: int = lock_model.active_type
	lock_model.tick()
	if not _check(lock_model.grid[Model.HEIGHT - 2][4] == locked_type and lock_model.grid[Model.HEIGHT - 2][5] == locked_type and lock_model.grid[Model.HEIGHT - 1][4] == locked_type and lock_model.grid[Model.HEIGHT - 1][5] == locked_type, "Tick at the floor must lock all four cells into the board"):
		return
	if not _check(not lock_model.game_over and lock_model.active_cells.size() == 4, "Successful lock must spawn the next active piece"):
		return

	# Long deterministic run: 50 lock/spawn/line-clear cycles must preserve
	# board dimensions, avoid game over, and keep progression synchronized.
	var long_run_model: BlockBuddiesModel = Model.new()
	long_run_model.reset()
	for cycle in range(50):
		for x in range(Model.WIDTH):
			long_run_model.grid[Model.HEIGHT - 1][x] = 1 if x < 3 or x > 6 else -1
		long_run_model.active_type = 0
		long_run_model.active_cells.assign(Model.SHAPES[0])
		long_run_model.origin = Vector2i(3, 0)
		long_run_model.hard_drop()
		if not _check(not long_run_model.game_over, "Repeated lock and clear cycles must not cause a false game over"):
			return
		if not _check(long_run_model.grid.size() == Model.HEIGHT and long_run_model.grid[Model.HEIGHT - 1].size() == Model.WIDTH, "Board dimensions must remain stable throughout a long run"):
			return
		if not _check(long_run_model.lines == cycle + 1, "Line progression must remain synchronized after every repeated clear"):
			return
	if not _check(long_run_model.level == 6, "Fifty cleared lines must advance progression to level six"):
		return
	if not _check(long_run_model.grid[Model.HEIGHT - 1].count(-1) == Model.WIDTH, "The bottom row must be empty after each successful clear"):
		return

	print("Godot gameplay model tests passed: save/load validation, collision, lock, progression, seven-bag, Hold, preview, scoring, game over, and reset.")
	quit(0)
