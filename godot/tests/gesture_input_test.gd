extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Main = preload("res://scripts/main.gd")
const ModeSession = preload("res://scripts/mode_session.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("GESTURE INPUT TEST FAILED: " + message)
	quit(1)
	return false

func _make_probe() -> Node2D:
	var probe = Main.new()
	get_root().add_child(probe)
	probe.game = Model.new()
	probe.game.reset()
	probe.mode_session = ModeSession.new()
	probe.mode_session.start("classic")
	probe.home_visible = false
	probe.mode_select_visible = false
	probe.secondary_screen = ""
	probe.campaign_screen = ""
	probe.paused = false
	probe.screen_size = Vector2(720.0, 1280.0)
	var metrics: Dictionary = probe._board_metrics(probe.screen_size)
	probe.board_rect = metrics.board_rect
	probe.drop_rect = probe._drop_button_layout(probe.screen_size, probe.board_rect)
	probe.mode_button_rect = Rect2(24.0, 12.0, 82.0, 36.0)
	probe.pause_rect = Rect2(660.0, 12.0, 36.0, 36.0)
	probe.hold_rect = Rect2(18.0, 145.0, 120.0, 70.0)
	probe.block_run_skill_rect = Rect2()
	return probe

func _run() -> void:
	seed(20261109)
	var probe := _make_probe()
	var board_center: Vector2 = probe.board_rect.get_center()
	var tall_metrics: Dictionary = probe._board_metrics(Vector2(720.0, 1600.0))
	if not _check(float(tall_metrics.cell) >= 50.0 and tall_metrics.board_rect.end.y < 1600.0, "Tall phone layout must enlarge the board while staying inside the expanded viewport"):
		return
	if not _check(probe._classify_arena_swipe(Vector2(90.0, 8.0)) == "horizontal", "A clearly horizontal swipe must be classified as movement"):
		return
	if not _check(probe._classify_arena_swipe(Vector2(5.0, -70.0)) == "vertical", "A clearly vertical upward swipe must be classified as rotation"):
		return
	if not _check(probe._classify_arena_swipe(Vector2(65.0, -58.0)) == "ambiguous", "A diagonal swipe must not be guessed as movement or rotation"):
		return
	var left_gutter := Vector2(4.0, board_center.y)
	var right_gutter := Vector2(716.0, board_center.y)
	if not _check(not probe.board_rect.has_point(left_gutter) and probe._arena_gesture_start_is_valid(left_gutter), "Free left gutter must accept gestures even though it is outside the board"):
		return
	if not _check(not probe.board_rect.has_point(right_gutter) and probe._arena_gesture_start_is_valid(right_gutter), "Free right gutter must accept gestures even though it is outside the board"):
		return
	if not _check(not probe._arena_gesture_start_is_valid(probe.drop_rect.get_center()), "Dedicated DROP control must remain a tap target, not a swipe surface"):
		return
	if not _check(not probe._arena_gesture_start_is_valid(probe.mode_button_rect.get_center()) and not probe._arena_gesture_start_is_valid(probe.pause_rect.get_center()) and not probe._arena_gesture_start_is_valid(probe.hold_rect.get_center()), "Mode, pause and hold controls must remain reserved tap targets"):
		return

	var start_x: int = probe.game.origin.x
	if not _check(probe._handle_swipe(left_gutter, left_gutter + Vector2(80.0, 0.0)), "A horizontal swipe beginning in the free left gutter must be handled"):
		return
	if not _check(probe.game.origin.x > start_x, "A left-gutter swipe must move the active piece immediately"):
		return

	var shape_before: Array[Vector2i] = probe.game.active_cells.duplicate()
	if not _check(probe._handle_swipe(right_gutter, right_gutter + Vector2(65.0, -58.0)), "An ambiguous diagonal swipe must be consumed safely"):
		return
	if not _check(probe.game.active_cells == shape_before, "An ambiguous diagonal swipe must not rotate the active piece"):
		return
	if not _check(probe._handle_swipe(right_gutter, right_gutter + Vector2(0.0, -70.0)), "A clearly vertical rotation swipe beginning in the free right gutter must be handled"):
		return
	if not _check(probe.game.active_cells != shape_before, "A right-gutter swipe must rotate the active piece"):
		return

	var lock_before: int = probe.game.lock_serial
	probe._hard_drop_active_piece()
	if not _check(probe.game.lock_serial == lock_before + 1 and not probe.game.game_over, "Hard drop must lock exactly one piece and spawn the next piece"):
		return
	# Use a deterministic non-square piece so immediate rotation is observable.
	probe.game.active_type = 1
	probe.game.active_cells.assign(Model.SHAPES[1])
	probe.game.origin = Vector2i(3, 0)
	var post_drop_x: int = probe.game.origin.x
	if not _check(probe._handle_swipe(left_gutter, left_gutter + Vector2(80.0, 0.0)) and probe.game.origin.x > post_drop_x, "Horizontal movement must work immediately after hard drop without a shared cooldown"):
		return
	var post_move_shape: Array[Vector2i] = probe.game.active_cells.duplicate()
	if not _check(probe._handle_swipe(right_gutter, right_gutter + Vector2(0.0, -60.0)) and probe.game.active_cells != post_move_shape, "Rotation must work immediately after hard drop without a shared cooldown"):
		return

	probe.queue_free()
	print("Full-screen free-area gestures, reserved control targets, and immediate post-drop move/rotate checks passed.")
	quit(0)
