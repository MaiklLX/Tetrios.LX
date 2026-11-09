extends Node2D

const CELL := 38.0
const BOARD_W := 10
const BOARD_H := 23
const Model = preload("res://scripts/game_model.gd")
const Buddy = preload("res://scripts/buddy_companion.gd")
const ModeSession = preload("res://scripts/mode_session.gd")
const ModeCatalog = preload("res://scripts/mode_catalog.gd")
const CampaignProgress = preload("res://scripts/campaign_progress.gd")
const CampaignAchievements = preload("res://scripts/campaign_achievements.gd")
const CampaignCollection = preload("res://scripts/campaign_collection.gd")
const CampaignStore = preload("res://scripts/campaign_progress_store.gd")
const CampaignCollectionLayout = preload("res://scripts/campaign_collection_layout.gd")
const CampaignRewardQueue = preload("res://scripts/campaign_reward_reveal_queue.gd")
const CampaignRuntime = preload("res://scripts/campaign_piece_runtime.gd")
const CampaignRunStore = preload("res://scripts/campaign_piece_store.gd")
const CampaignSpecialPiece = preload("res://scripts/campaign_special_piece.gd")
const BlockRunSession = preload("res://scripts/block_run_session.gd")
const BlockRunBridge = preload("res://scripts/block_run_bridge.gd")

var game: BlockBuddiesModel
var campaign_progress: BlockBuddiesCampaignProgress
var campaign_run_active := false
var campaign_run_planet_id := 0
var campaign_completion_processed := false
var campaign_last_reward_marks := 0
var campaign_piece_runtime: BlockBuddiesCampaignPieceRuntime
const CARGO_HOOK_PLANET_ID := 31
var mode_session: BlockBuddiesModeSession
var block_run_session: BlockBuddiesBlockRunSession
var block_run_active := false
var block_run_last_lock_serial := 0
var block_run_last_lines := 0
var block_run_clock := 0.0
var block_run_hero_id := "plush"
var block_run_hero_level := 1
var block_run_skill_rect := Rect2()
var block_run_draft_rects: Array[Rect2] = []
var mode_select_visible := false
var home_visible := false
var secondary_screen := ""
var home_campaign_rect := Rect2()
var home_block_run_rect := Rect2()
var home_tasks_rect := Rect2()
var home_collection_rect := Rect2()
var campaign_collection_from_home := false
var home_heroes_rect := Rect2()
var home_shop_rect := Rect2()
var home_upgrades_rect := Rect2()
var secondary_back_rect := Rect2()

var campaign_screen := ""
var campaign_universe := 0
var campaign_planet := 1
var campaign_atlas_rects: Array[Rect2] = []
var campaign_collection_rect := Rect2()
var campaign_collection_item_rects: Array[Rect2] = []
var campaign_collection_selected := 0
var campaign_collection_inspect_rect := Rect2()
var campaign_collection_grid_viewport_rect := Rect2()
var campaign_collection_scroll_offset := 0.0
var campaign_route_scroll_offset := 0.0
var campaign_route_scroll_max := 0.0
var campaign_route_scroll_viewport_rect := Rect2()
var campaign_collection_reveal_queue: Array[String] = []
var campaign_collection_reveal_active := false
var campaign_collection_reveal_time := 0.0
var campaign_collection_preview_active := false
var campaign_node_rects: Array[Rect2] = []
var campaign_start_rect := Rect2()
var campaign_back_rect := Rect2()
var campaign_launch_pending := false
var mode_button_rect := Rect2()
var classic_mode_rect := Rect2()
var sprint_mode_rect := Rect2()
var marathon_mode_rect := Rect2()
var gravity_clock := 0.0
var gravity_interval := 0.78
var font: Font
var board_rect := Rect2()
var screen_size := Vector2(720, 1280)
var buddy: Node2D
var buddy_last_lines := 0
var clear_flash_time := 0.0
var clear_flash_count := 0
var ambient_time := 0.0
var paused := false
var pause_rect := Rect2()
var resume_rect := Rect2()
var hold_rect := Rect2()
var drop_rect := Rect2()
var touch_start := Vector2.ZERO
var touch_start_msec := 0
var touch_active := false
var touch_feedback_position := Vector2.ZERO
var touch_feedback_time := 0.0
var tutorial_active := false
var tutorial_context := ""
var tutorial_step := 0
var tutorial_home_completed := false
var tutorial_gameplay_completed := false
var tutorial_next_rect := Rect2()
var tutorial_skip_rect := Rect2()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and _campaign_runtime_active() and mode_session != null and mode_session.is_running():
		paused = true
		queue_redraw()

func _clear_campaign_checkpoint() -> void:
	if not CampaignRunStore.clear_run():
		push_warning("Campaign run checkpoint could not be cleared.")

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	game = Model.new()
	game.reset()
	campaign_progress = CampaignProgress.new()
	var campaign_load: Dictionary = CampaignStore.load_progress(campaign_progress)
	if not bool(campaign_load.get("ok", false)):
		push_warning("Campaign progress save could not be loaded: " + str(campaign_load.get("reason", "unknown")))
	else:
		campaign_collection_reveal_queue = CampaignRewardQueue.sanitize(campaign_progress, campaign_load.get("pending_reward_reveals", []))
	home_visible = true
	mode_select_visible = false
	mode_session = ModeSession.new()
	buddy = Buddy.new()
	add_child(buddy)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_load_tutorial_state()
	set_process(true)
	_clear_campaign_checkpoint()

func _layout() -> void:
	screen_size = get_viewport_rect().size
	var board_metrics := _board_metrics(screen_size)
	board_rect = board_metrics.board_rect
	drop_rect = _drop_button_layout(screen_size, board_rect)
	# Keep the top utility controls in their own compact row. The score/HUD
	# begins below it, so the buttons never collide with labels on portrait screens.
	pause_rect = Rect2(screen_size.x - 60.0, 12.0, 36.0, 36.0)
	var resume_width := minf(220.0, screen_size.x - 64.0)
	resume_rect = Rect2(screen_size.x * 0.5 - resume_width * 0.5, screen_size.y * 0.5 + 42.0, resume_width, 54.0)
	mode_button_rect = Rect2(24.0, 12.0, 82.0, 36.0)
	var mode_layout := _mode_select_layout(screen_size)
	var home_layout := _home_layout(screen_size)
	home_campaign_rect = home_layout.campaign
	home_block_run_rect = home_layout.block_run
	home_tasks_rect = home_layout.tasks
	home_collection_rect = home_layout.collection
	home_heroes_rect = home_layout.heroes
	home_shop_rect = home_layout.shop
	home_upgrades_rect = home_layout.upgrades
	secondary_back_rect = Rect2(18.0, 16.0, 94.0, 42.0)
	classic_mode_rect = mode_layout.classic
	sprint_mode_rect = mode_layout.sprint
	marathon_mode_rect = mode_layout.marathon
	if is_instance_valid(buddy):
		var buddy_layout := _buddy_layout_for_gutter(board_rect.position.x)
		buddy.scale = Vector2.ONE * buddy_layout.scale * 1.28
		# Anchor the companion flush to the left gutter; never let its sprite intrude into the board frame.
		buddy.position = Vector2(0.0, board_rect.position.y + 18.0)
		var result_overlay_visible := paused or _active_game_over() or (mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED)
		buddy.visible = buddy_layout.visible and not home_visible and secondary_screen.is_empty() and campaign_screen.is_empty() and not mode_select_visible and campaign_screen.is_empty() and not _block_run_draft_is_open() and not result_overlay_visible
	queue_redraw()


func _home_layout(viewport: Vector2) -> Dictionary:
	var width := viewport.x - 36.0
	var left := 18.0
	var top := maxf(118.0, viewport.y * 0.15)
	var card_height := clampf(viewport.y * 0.145, 108.0, 132.0)
	var gap := 14.0
	var tab_gap := 8.0
	var tab_width := (width - tab_gap * 2.0) / 3.0
	return {
		"campaign": Rect2(left, top + 96.0, width, card_height),
		"block_run": Rect2(left, top + 96.0 + card_height + gap, width, card_height),
		"tasks": Rect2(left, top + 96.0 + (card_height + gap) * 2.0, (width - 8.0) * 0.5, 82.0),
		"collection": Rect2(left + (width + 8.0) * 0.5, top + 96.0 + (card_height + gap) * 2.0, (width - 8.0) * 0.5, 82.0),
		"heroes": Rect2(left, viewport.y - 92.0, tab_width, 58.0),
		"shop": Rect2(left + tab_width + tab_gap, viewport.y - 92.0, tab_width, 58.0),
		"upgrades": Rect2(left + (tab_width + tab_gap) * 2.0, viewport.y - 92.0, tab_width, 58.0)
	}

func _mode_select_layout(viewport: Vector2) -> Dictionary:
	var card_width := minf(300.0, viewport.x - 48.0)
	var left := viewport.x * 0.5 - card_width * 0.5
	var center_y := viewport.y * 0.5
	return {
		"classic": Rect2(left, center_y - 128.0, card_width, 82.0),
		"sprint": Rect2(left, center_y - 36.0, card_width, 82.0),
		"marathon": Rect2(left, center_y + 56.0, card_width, 82.0),
		"title_y": center_y - 210.0,
		"subtitle_y": center_y - 182.0,
		"instruction_y": center_y + 178.0
	}

func _board_metrics(viewport: Vector2) -> Dictionary:
	# With touch-first input there is no permanent control strip or large title banner.
	# Reserve compact HUD + enlarged HOLD/NEXT cards, then reclaim the remaining height.
	var board_top_min := 236.0
	var available_height := maxf(230.0, viewport.y - board_top_min - 36.0)
	# Tall mobile screens should spend their extra height on a larger board,
	# not leave the playfield floating in a narrow, letterboxed canvas.
	var cell := minf((viewport.x - 64.0) / BOARD_W, minf((viewport.y * 0.78) / BOARD_H, available_height / BOARD_H))
	var board_size := Vector2(cell * BOARD_W, cell * BOARD_H)
	# Reserve a little more breathing room on the DROP side without shrinking the 10x23 playfield.
	var horizontal_bias := 21.0 if viewport.x <= 480.0 else 0.0
	var board_position := Vector2(maxf(12.0, (viewport.x - board_size.x) * 0.5 - horizontal_bias), maxf((viewport.y - board_size.y) * 0.5 + 22.0, board_top_min))
	return {
		"cell": cell,
		"board_rect": Rect2(board_position, board_size)
	}

func _drop_button_layout(viewport: Vector2, board: Rect2) -> Rect2:
	# A broader touch target sits lower and left, with clear breathing room at both edges.
	var right_margin := 12.0
	var frame_gap := 21.0
	var width := minf(96.0, viewport.x - board.end.x - frame_gap - right_margin)
	if width < 52.0:
		return Rect2()
	var height := 60.0
	var lift := 8.0
	return Rect2(Vector2(board.end.x + frame_gap, board.end.y - height - lift), Vector2(width, height))

func _buddy_layout_for_gutter(gutter_width: float) -> Dictionary:
	return {
		"scale": clampf((gutter_width - 16.0) / 98.0, 0.55, 1.0),
		"visible": gutter_width >= 70.0
	}

func _gravity_interval_for_level(current_level: int) -> float:
	# A steady arcade ramp with a safe floor keeps late-game input readable.
	return maxf(0.08, 0.78 * pow(0.85, maxi(1, current_level) - 1))

func _process(delta: float) -> void:
	ambient_time = fmod(ambient_time + delta, 1000.0)
	if campaign_collection_reveal_active:
		campaign_collection_reveal_time += delta
		queue_redraw()
	if clear_flash_time > 0.0:
		clear_flash_time = maxf(0.0, clear_flash_time - delta)
		queue_redraw()
	if touch_feedback_time > 0.0:
		touch_feedback_time = maxf(0.0, touch_feedback_time - delta)
		queue_redraw()
	if game == null:
		return
	if block_run_active:
		_process_block_run_events()
		_advance_block_run_clock(delta if not paused and not mode_select_visible and not home_visible and secondary_screen.is_empty() and campaign_screen.is_empty() else 0.0)
	if mode_session != null and not mode_select_visible and not home_visible and secondary_screen.is_empty() and campaign_screen.is_empty() and not block_run_active:
		mode_session.update(delta if not paused else 0.0, _active_lines(), _active_game_over(), _active_score())
		_process_campaign_completion()
	if not mode_select_visible and not home_visible and secondary_screen.is_empty() and campaign_screen.is_empty() and not _active_game_over() and not paused and not _block_run_draft_is_open() and (mode_session == null or mode_session.is_running()):
		gravity_interval = float(block_run_session.drop_interval_ms) / 1000.0 if block_run_active and block_run_session != null else _gravity_interval_for_level(_active_level())
		gravity_clock += delta
		if gravity_clock >= gravity_interval:
			gravity_clock = 0.0
			if _campaign_runtime_active():
				campaign_piece_runtime.tick()
			else:
				game.tick()
			if mode_session != null and not block_run_active:
				mode_session.update(0.0, _active_lines(), _active_game_over(), _active_score())
			if block_run_active:
				_process_block_run_events()
			queue_redraw()
	_sync_buddy_state()

func _campaign_runtime_active() -> bool:
	return campaign_run_active and campaign_piece_runtime != null

func _active_game_over() -> bool:
	return campaign_piece_runtime.game_over if _campaign_runtime_active() else game.game_over

func _active_lines() -> int:
	return campaign_piece_runtime.lines if _campaign_runtime_active() else game.lines

func _active_score() -> int:
	return campaign_piece_runtime.score if _campaign_runtime_active() else game.score

func _active_level() -> int:
	return 1 if _campaign_runtime_active() else game.level

func _active_held_piece_id() -> int:
	return campaign_piece_runtime.held_piece_id if _campaign_runtime_active() else game.held_type

func _active_next_piece_id() -> int:
	if _campaign_runtime_active():
		return int(campaign_piece_runtime.piece_bag[0]) if not campaign_piece_runtime.piece_bag.is_empty() else -1
	return game.peek_next_piece_type()

func _active_grid() -> Array:
	return campaign_piece_runtime.grid if _campaign_runtime_active() else game.grid

func _move_piece_horizontal(direction: int) -> bool:
	if _campaign_runtime_active():
		return campaign_piece_runtime.move_horizontal(direction)
	game.move_horizontal(direction)
	return true

func _rotate_active_piece() -> bool:
	if _campaign_runtime_active():
		return campaign_piece_runtime.rotate_piece()
	game.rotate_piece()
	return true

func _soft_drop_active_piece() -> bool:
	if _campaign_runtime_active():
		return campaign_piece_runtime.soft_drop()
	game.soft_drop()
	return true

func _hard_drop_active_piece() -> int:
	if _campaign_runtime_active():
		return campaign_piece_runtime.hard_drop()
	game.hard_drop()
	return 0

func _hold_active_piece() -> bool:
	if _campaign_runtime_active():
		return campaign_piece_runtime.hold_piece()
	game.hold_piece()
	return true

func _campaign_planet_uses_cargo_hook(node_id: int) -> bool:
	if node_id == CARGO_HOOK_PLANET_ID:
		return true
	if campaign_progress == null:
		return false
	var definition: Dictionary = campaign_progress.get_planet_definition(node_id)
	return str(definition.get("special_piece_id", "")) == "cargo_hook" and str(definition.get("event_status", "")) == "live_campaign_piece"

func _reset_campaign_piece_runtime() -> bool:
	campaign_piece_runtime = CampaignRuntime.new()
	campaign_piece_runtime.reset(false)
	var definition: Dictionary = campaign_progress.get_planet_definition(campaign_run_planet_id) if campaign_progress != null else {}
	var authored_layout: Variant = definition.get("starting_layout", [])
	if not authored_layout.is_empty() and not campaign_piece_runtime.apply_authored_starting_layout(authored_layout):
		push_error("Authored campaign starting layout failed validation at runtime.")
		return false
	if _campaign_planet_uses_cargo_hook(campaign_run_planet_id):
		return campaign_piece_runtime.spawn_authored_special()
	return campaign_piece_runtime.spawn_next_standard()

func _campaign_ghost_origin() -> Vector2i:
	var ghost: Vector2i = campaign_piece_runtime.origin
	while not campaign_piece_runtime._collides(ghost + Vector2i(0, 1), campaign_piece_runtime.active_cells):
		ghost.y += 1
	return ghost

func configure_block_run_hero(hero_id: String, hero_level: int) -> bool:
	if not ["plush", "prism", "blip", "pixel", "spark"].has(hero_id) or hero_level < 1:
		return false
	block_run_hero_id = hero_id
	block_run_hero_level = hero_level
	queue_redraw()
	return true

func activate_block_run_hero_skill() -> Dictionary:
	if not block_run_active or block_run_session == null or paused or game.game_over or _block_run_draft_is_open() or block_run_session.status != BlockRunSession.STATUS_RUNNING:
		return {"accepted":false,"reason":"run_not_active"}
	if not BlockRunBridge.sync_model_to_session(game, block_run_session):
		block_run_session.status = BlockRunSession.STATUS_FAILED
		game.game_over = true
		return {"accepted":false,"reason":"sync_failed"}
	var result: Dictionary = block_run_session.use_hero_skill(block_run_hero_id, block_run_hero_level)
	if not bool(result.get("accepted", false)):
		return result
	if not BlockRunBridge.sync_session_to_model(block_run_session, game) or not game.validate_active_piece_after_board_mutation():
		block_run_session.status = BlockRunSession.STATUS_FAILED
		game.game_over = true
		result["accepted"] = false
		result["reason"] = "live_board_validation_failed"
	queue_redraw()
	return result

func start_block_run_session() -> bool:
	if game == null:
		return false
	block_run_session = BlockRunSession.new()
	block_run_session.start()
	block_run_active = true
	block_run_last_lock_serial = game.lock_serial
	block_run_last_lines = game.lines
	block_run_clock = 0.0
	return BlockRunBridge.sync_model_to_session(game, block_run_session)

func _process_block_run_events() -> void:
	if not block_run_active or block_run_session == null or block_run_session.status != BlockRunSession.STATUS_RUNNING or _block_run_draft_is_open():
		return
	# Hold can trigger a replacement-piece spawn collision without locking a
	# piece, so rescue/failure must be evaluated independently of lock_serial.
	if game.game_over:
		var immediate_rescue: Dictionary = BlockRunBridge.rescue_spawn_collision(game, block_run_session)
		if not bool(immediate_rescue.get("rescued", false)) or not bool(immediate_rescue.get("live_resumed", false)):
			block_run_session.status = BlockRunSession.STATUS_FAILED
			game.game_over = true
		queue_redraw()
		return
	if game.lock_serial == block_run_last_lock_serial:
		return
	# A model action can lock at most one piece. Refuse to guess if an event
	# cursor ever jumps, because silently dropping encounter events is unsafe.
	if game.lock_serial != block_run_last_lock_serial + 1:
		block_run_session.status = BlockRunSession.STATUS_FAILED
		game.game_over = true
		return
	if not BlockRunBridge.sync_model_to_session(game, block_run_session):
		block_run_session.status = BlockRunSession.STATUS_FAILED
		game.game_over = true
		return
	block_run_session.on_piece_locked()
	var cleared := maxi(0, game.lines - block_run_last_lines)
	block_run_last_lock_serial = game.lock_serial
	block_run_last_lines = game.lines
	if cleared > 0:
		block_run_session.on_line_clear(cleared, 0, game.level)
		if not BlockRunBridge.sync_session_to_model(block_run_session, game):
			block_run_session.status = BlockRunSession.STATUS_FAILED
			game.game_over = true
			return
	if game.game_over:
		var rescue: Dictionary = BlockRunBridge.rescue_spawn_collision(game, block_run_session)
		if not bool(rescue.get("rescued", false)) or not bool(rescue.get("live_resumed", false)):
			block_run_session.status = BlockRunSession.STATUS_FAILED
			game.game_over = true
	queue_redraw()

func _advance_block_run_clock(delta: float) -> void:
	if not block_run_active or block_run_session == null or delta <= 0.0 or block_run_session.status != BlockRunSession.STATUS_RUNNING or _block_run_draft_is_open():
		return
	block_run_clock += delta
	while block_run_clock >= 1.0 and block_run_session.status == BlockRunSession.STATUS_RUNNING and not _block_run_draft_is_open():
		block_run_clock -= 1.0
		if not BlockRunBridge.sync_model_to_session(game, block_run_session):
			block_run_session.status = BlockRunSession.STATUS_FAILED
			game.game_over = true
			break
		var event: Dictionary = block_run_session.advance_second()
		if bool(event.get("failed", false)) or block_run_session.status != BlockRunSession.STATUS_RUNNING:
			game.game_over = true
			break
		if not BlockRunBridge.sync_session_to_model(block_run_session, game):
			block_run_session.status = BlockRunSession.STATUS_FAILED
			game.game_over = true
			break
		if not game.validate_active_piece_after_board_mutation():
			block_run_session.status = BlockRunSession.STATUS_FAILED
			break
	queue_redraw()


func _restart_current_run() -> void:
	if campaign_run_active:
		_clear_campaign_checkpoint()
	if not campaign_run_active:
		game.reset()
	# Campaign owns a separate board and piece lifecycle; the shared model stays untouched.
	# Retry replays the authored opening piece only on its designated campaign planet.
	# The mode lifecycle must also return to running when restarting Block Run;
	# otherwise its completed status blocks the first touch on the new run.
	if mode_session != null:
		mode_session.start(mode_session.mode_id if not mode_session.mode_id.is_empty() else "classic")
		if campaign_run_active and mode_session.mode_id == "campaign":
			var campaign_definition := campaign_progress.get_planet_definition(campaign_run_planet_id)
			mode_session.rules["target_lines"] = int(campaign_definition.get("target_lines", 8))
			mode_session.rules["target_score"] = int(campaign_definition.get("target_score", 0))
			mode_session.rules["target_survive_seconds"] = float(campaign_definition.get("target_survive_seconds", 0))
			mode_session.rules["time_limit_seconds"] = float(campaign_definition.get("time_limit_seconds", 0))
			mode_session.rules["boss_phases"] = campaign_definition.get("boss_phases", []).duplicate(true)
			campaign_completion_processed = false
			if not _reset_campaign_piece_runtime():
				push_error("Campaign piece runtime could not restart the authored planet.")
	if block_run_active:
		start_block_run_session()
	paused = false
	gravity_clock = 0.0
	buddy_last_lines = 0
	clear_flash_time = 0.0
	clear_flash_count = 0
	buddy.set_state("idle", 0.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and (campaign_collection_reveal_active or (campaign_screen == "collection" and campaign_collection_preview_active)):
			_dismiss_campaign_collection_modal()
			return
		if mode_select_visible:
			if event.keycode == KEY_ESCAPE:
				mode_select_visible = false
				if campaign_launch_pending:
					campaign_screen = "planet"
					home_visible = false
				else:
					home_visible = true
				queue_redraw()
			elif event.keycode == KEY_1:
				_select_mode("classic")
			elif event.keycode == KEY_2:
				_select_mode("sprint")
			elif event.keycode == KEY_3:
				_select_mode("marathon")
			return
		if home_visible or not secondary_screen.is_empty() or not campaign_screen.is_empty():
			return
		if _block_run_draft_is_open():
			if event.keycode == KEY_1:
				_select_block_run_draft(0)
			elif event.keycode == KEY_2:
				_select_block_run_draft(1)
			elif event.keycode == KEY_3:
				_select_block_run_draft(2)
			return
		if event.keycode == KEY_Q and block_run_active:
			activate_block_run_hero_skill()
			return
		if event.keycode == KEY_M:
			_open_mode_select()
			return
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			return
		if (paused or _mode_finished()) and event.keycode != KEY_R:
			return
		match event.keycode:
			KEY_LEFT, KEY_A: _move_piece_horizontal(-1)
			KEY_RIGHT, KEY_D: _move_piece_horizontal(1)
			KEY_DOWN, KEY_S: _soft_drop_active_piece()
			KEY_UP, KEY_W, KEY_X, KEY_SPACE: _rotate_active_piece()
			KEY_ENTER: _hard_drop_active_piece()
			KEY_C: _hold_active_piece()
			KEY_R:
				_restart_current_run()
		_sync_buddy_state()
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and campaign_screen == "collection" and not campaign_collection_reveal_active and not campaign_collection_preview_active and campaign_collection_grid_viewport_rect.has_point(event.position) and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_scroll_campaign_collection_rows(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_start_msec = Time.get_ticks_msec()
			touch_active = true
			touch_feedback_position = event.position
			touch_feedback_time = 0.18
			queue_redraw()
		elif touch_active:
			var touch_duration_msec := Time.get_ticks_msec() - touch_start_msec
			touch_active = false
			touch_feedback_position = event.position
			touch_feedback_time = 0.18
			if not _handle_swipe(touch_start, event.position, touch_duration_msec):
				_handle_tap(event.position)
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		touch_feedback_position = event.position
		touch_feedback_time = 0.18
		_handle_tap(event.position)
		queue_redraw()

func _arena_gesture_start_is_valid(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, screen_size).has_point(point):
		return false
	# Keep explicit controls as tap targets. The remaining active play surface,
	# including the gutters around the 10x23 board, can steer the falling piece.
	for control_rect in [mode_button_rect, pause_rect, hold_rect, drop_rect, block_run_skill_rect]:
		if control_rect.size.x > 0.0 and control_rect.size.y > 0.0 and control_rect.has_point(point):
			return false
	return true

func _classify_arena_swipe(delta: Vector2) -> String:
	var horizontal := absf(delta.x)
	var vertical := absf(delta.y)
	var horizontal_threshold := maxf(34.0, board_rect.size.x / BOARD_W * 0.85)
	var vertical_threshold := maxf(46.0, board_rect.size.x / BOARD_W)
	# A strong dominant axis is required. Diagonal thumb travel is common on
	# phones and must never be mistaken for an intentional rotation.
	if horizontal >= horizontal_threshold and horizontal >= vertical * 1.45:
		return "horizontal"
	if vertical >= vertical_threshold and vertical >= horizontal * 1.45:
		return "vertical"
	if maxf(horizontal, vertical) >= minf(horizontal_threshold, vertical_threshold):
		return "ambiguous"
	return "none"

func _handle_swipe(start: Vector2, finish: Vector2, duration_msec: int = 250) -> bool:
	if tutorial_active:
		return start.distance_to(finish) >= 24.0
	if campaign_screen == "collection" and not campaign_collection_reveal_active and not campaign_collection_preview_active:
		var collection_delta := finish - start
		if campaign_collection_grid_viewport_rect.has_point(start) and absf(collection_delta.x) >= 28.0 and absf(collection_delta.x) > absf(collection_delta.y) * 1.2:
			_scroll_campaign_collection_rows(1 if collection_delta.x < 0.0 else -1)
			return true
	if campaign_screen == "route":
		var route_delta := finish - start
		if campaign_route_scroll_viewport_rect.has_point(start) and absf(route_delta.y) >= 32.0 and absf(route_delta.y) > absf(route_delta.x) * 1.2:
			_scroll_campaign_route(1 if route_delta.y < 0.0 else -1)
			return true
	if mode_select_visible or home_visible or not secondary_screen.is_empty() or not campaign_screen.is_empty() or game == null or _active_game_over() or paused or _mode_finished() or _block_run_draft_is_open() or not _arena_gesture_start_is_valid(start):
		return false
	var delta := finish - start
	var gesture_axis := _classify_arena_swipe(delta)
	if gesture_axis == "none":
		return false
	if gesture_axis == "ambiguous":
		# Consume a deliberate diagonal drag without turning it into a tap or
		# guessing whether the player meant to move, rotate or drop.
		return true
	if gesture_axis == "horizontal":
		var steps := clampi(roundi(absf(delta.x) / maxf(board_rect.size.x / BOARD_W, 1.0)), 1, 3)
		var direction := 1 if delta.x > 0.0 else -1
		for i in range(steps):
			_move_piece_horizontal(direction)
	elif delta.y > 0.0:
		# Hard drop requires both a decisive travel distance and a quick,
		# clearly vertical gesture. Slow downward drags remain soft-drop input.
		var is_quick_drop := delta.y >= board_rect.size.y * 0.22 and duration_msec <= 420
		if is_quick_drop:
			_hard_drop_active_piece()
		else:
			var drops := clampi(roundi(delta.y / maxf(44.0, board_rect.size.x / BOARD_W)), 1, 4)
			for i in range(drops):
				_soft_drop_active_piece()
				if _active_game_over():
					break
	else:
		_rotate_active_piece()
	_sync_buddy_state()
	queue_redraw()
	return true

func _toggle_pause() -> void:
	if game == null or _active_game_over() or _mode_finished() or mode_select_visible or home_visible or not secondary_screen.is_empty() or not campaign_screen.is_empty():
		return
	paused = not paused
	queue_redraw()

func _handle_tap(point: Vector2) -> void:
	if tutorial_active:
		if tutorial_skip_rect.has_point(point):
			_finish_tutorial()
		elif tutorial_next_rect.has_point(point):
			_advance_tutorial()
		queue_redraw()
		return
	if campaign_collection_reveal_active and campaign_screen.is_empty():
		_dismiss_campaign_collection_modal()
		return
	if home_visible:
		if home_campaign_rect.has_point(point):
			campaign_screen = "atlas"
			campaign_universe = 0
			campaign_planet = 1
			home_visible = false
		elif home_block_run_rect.has_point(point):
			home_visible = false
			mode_select_visible = true
		elif home_heroes_rect.has_point(point):
			_open_secondary_screen("heroes")
		elif home_shop_rect.has_point(point):
			_open_secondary_screen("shop")
		elif home_upgrades_rect.has_point(point):
			_open_secondary_screen("upgrades")
		elif home_tasks_rect.has_point(point):
			_open_secondary_screen("daily")
		elif home_collection_rect.has_point(point):
			campaign_screen = "collection"
			campaign_collection_selected = 0
			campaign_collection_scroll_offset = 0.0
			campaign_collection_from_home = true
			home_visible = false
			_begin_next_campaign_collection_reveal()
		queue_redraw()
		return
	if not campaign_screen.is_empty():
		if campaign_screen == "collection":
			if campaign_collection_reveal_active or campaign_collection_preview_active:
				_dismiss_campaign_collection_modal()
			elif campaign_back_rect.has_point(point):
				if campaign_collection_from_home:
					campaign_screen = ""
					home_visible = true
					campaign_collection_from_home = false
				else:
					campaign_screen = "atlas"
			elif campaign_collection_inspect_rect.has_point(point):
				campaign_collection_preview_active = true
			else:
				for index in range(campaign_collection_item_rects.size()):
					if campaign_collection_item_rects[index].has_point(point):
						if campaign_collection_selected == index:
							campaign_collection_preview_active = true
						else:
							campaign_collection_selected = index
							var collection_layout: Dictionary = CampaignCollectionLayout.collection_strip(screen_size)
							campaign_collection_scroll_offset = CampaignCollectionLayout.scroll_offset_for_index(collection_layout, index, campaign_collection_scroll_offset)
						break
		elif campaign_collection_rect.has_point(point) and campaign_screen == "atlas":
			campaign_screen = "collection"
			campaign_collection_selected = 0
			campaign_collection_scroll_offset = 0.0
			campaign_collection_from_home = false
			_begin_next_campaign_collection_reveal()
		elif campaign_back_rect.has_point(point):
			if campaign_screen == "planet":
				campaign_screen = "route"
			elif campaign_screen == "route":
				campaign_screen = "atlas"
			else:
				campaign_screen = ""
				home_visible = true
		elif campaign_screen == "atlas":
			for index in range(campaign_atlas_rects.size()):
				if campaign_atlas_rects[index].has_point(point):
					campaign_universe = index
					campaign_route_scroll_offset = 0.0
					campaign_screen = "route"
					break
		elif campaign_screen == "route":
			for index in range(campaign_node_rects.size()):
				if campaign_node_rects[index].has_point(point):
					campaign_planet = index + 1
					campaign_screen = "planet"
					break
		elif campaign_screen == "planet" and campaign_start_rect.has_point(point) and _campaign_planet_is_unlocked(campaign_universe, campaign_planet):
			_start_campaign_planet()
		queue_redraw()
		return
	if not secondary_screen.is_empty():
		if secondary_back_rect.has_point(point):
			secondary_screen = ""
			home_visible = true
		queue_redraw()
		return
	if mode_select_visible:
		if secondary_back_rect.has_point(point):
			mode_select_visible = false
			if campaign_launch_pending:
				campaign_screen = "planet"
				home_visible = false
			else:
				home_visible = true
			queue_redraw()
			return
		if classic_mode_rect.has_point(point):
			_select_mode("classic")
		elif sprint_mode_rect.has_point(point):
			_select_mode("sprint")
		elif marathon_mode_rect.has_point(point):
			_select_mode("marathon")
		queue_redraw()
		return
	if _block_run_draft_is_open():
		for index in range(block_run_draft_rects.size()):
			if block_run_draft_rects[index].has_point(point):
				_select_block_run_draft(index)
				break
		return
	if mode_button_rect.has_point(point):
		_open_mode_select()
		return
	if _active_game_over() or _mode_finished():
		if campaign_run_active and mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED:
			_return_to_campaign_route()
		else:
			_restart_current_run()
	elif pause_rect.has_point(point):
		_toggle_pause()
	elif paused:
		if resume_rect.has_point(point):
			paused = false
	else:
		# The dedicated DROP target wins hit-testing on narrow portrait layouts.
		# It is separate from the board gesture area, so a normal board tap still rotates.
		if drop_rect.has_point(point):
			_hard_drop_active_piece()
		elif block_run_active and block_run_skill_rect.has_point(point):
			activate_block_run_hero_skill()
		elif hold_rect.has_point(point):
			_hold_active_piece()
		elif board_rect.has_point(point):
			_rotate_active_piece()
	_sync_buddy_state()
	queue_redraw()

func _select_mode(requested_mode_id: String) -> void:
	if not ModeCatalog.is_valid_mode(requested_mode_id):
		return
	if campaign_run_active:
		_clear_campaign_checkpoint()
	game.reset()
	if mode_session == null:
		mode_session = ModeSession.new()
	mode_session.start(requested_mode_id)
	mode_select_visible = false
	home_visible = false
	secondary_screen = ""
	campaign_screen = ""
	campaign_launch_pending = false
	campaign_run_active = false
	campaign_piece_runtime = null
	campaign_run_planet_id = 0
	campaign_completion_processed = false
	paused = false
	gravity_clock = 0.0
	buddy_last_lines = 0
	clear_flash_time = 0.0
	clear_flash_count = 0
	if is_instance_valid(buddy):
		buddy.set_state("idle", 0.0)
	if not tutorial_gameplay_completed:
		tutorial_active = true
		tutorial_context = "gameplay"
		tutorial_step = 0
	queue_redraw()


func _open_secondary_screen(screen_id: String) -> void:
	if not ["heroes", "shop", "upgrades", "daily"].has(screen_id):
		return
	secondary_screen = screen_id
	home_visible = false
	mode_select_visible = false
	paused = false
	queue_redraw()

func _open_mode_select() -> void:
	mode_select_visible = true
	home_visible = false
	secondary_screen = ""
	paused = false
	queue_redraw()

func _mode_finished() -> bool:
	return mode_session != null and not mode_session.is_running()

func _sync_buddy_state() -> void:
	if game == null:
		return
	if mode_session != null and not mode_select_visible:
		mode_session.update(0.0, _active_lines(), _active_game_over())
		_process_campaign_completion()
	if not is_instance_valid(buddy):
		return
	var buddy_layout := _buddy_layout_for_gutter(board_rect.position.x)
	var result_overlay_visible := paused or _active_game_over() or (mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED)
	buddy.visible = buddy_layout.visible and not home_visible and secondary_screen.is_empty() and campaign_screen.is_empty() and not mode_select_visible and not _block_run_draft_is_open() and not result_overlay_visible
	if _active_game_over():
		if buddy.state != "surprised":
			buddy.set_state("surprised", 0.0)
		return
	if _active_lines() > buddy_last_lines:
		var cleared := _active_lines() - buddy_last_lines
		clear_flash_count = cleared
		clear_flash_time = 0.72 if cleared < 4 else 1.05
		buddy.set_state("victory" if cleared >= 4 else "happy", 1.5)
		buddy_last_lines = _active_lines()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#070d1c"))
	_draw_backdrop()
	if home_visible:
		_draw_home_hub()
		_draw_tutorial_overlay()
		return
	if not campaign_screen.is_empty():
		_draw_campaign_screen()
		_draw_tutorial_overlay()
		return
	if not secondary_screen.is_empty():
		_draw_secondary_screen()
		_draw_tutorial_overlay()
		return
	if mode_select_visible:
		_draw_mode_select()
		_draw_tutorial_overlay()
		return
	_draw_header()
	_draw_stats()
	_draw_piece_previews()
	_draw_board()
	_draw_drop_button()
	if block_run_active and block_run_session != null:
		_draw_block_run_goals()
	if _block_run_draft_is_open():
		_draw_block_run_draft()
		return
	if mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED:
		_draw_mode_complete()
	elif _active_game_over():
		_draw_game_over()
	elif paused:
		_draw_pause_overlay()
	if campaign_collection_reveal_active and campaign_screen.is_empty() and not campaign_collection_reveal_queue.is_empty():
		_draw_campaign_collection_reward_modal(CampaignCollection.get_item(campaign_progress, campaign_collection_reveal_queue[0]), true)
	_draw_touch_feedback()
	_draw_tutorial_overlay()


func _load_tutorial_state() -> void:
	var config := ConfigFile.new()
	config.load("user://tutorial.cfg")
	tutorial_home_completed = bool(config.get_value("tutorial", "home_completed", false))
	tutorial_gameplay_completed = bool(config.get_value("tutorial", "gameplay_completed", false))
	if not tutorial_home_completed:
		tutorial_active = true
		tutorial_context = "home"
		tutorial_step = 0


func _save_tutorial_state() -> void:
	var config := ConfigFile.new()
	config.load("user://tutorial.cfg")
	config.set_value("tutorial", "home_completed", tutorial_home_completed)
	config.set_value("tutorial", "gameplay_completed", tutorial_gameplay_completed)
	var save_error := config.save("user://tutorial.cfg")
	if save_error != OK:
		push_warning("Tutorial completion could not be saved: " + str(save_error))


func _finish_tutorial() -> void:
	if tutorial_context == "home":
		tutorial_home_completed = true
	elif tutorial_context == "gameplay":
		tutorial_gameplay_completed = true
	_save_tutorial_state()
	tutorial_active = false
	tutorial_context = ""
	tutorial_step = 0
	tutorial_next_rect = Rect2()
	tutorial_skip_rect = Rect2()
	queue_redraw()


func _advance_tutorial() -> void:
	if tutorial_context == "home":
		match tutorial_step:
			0:
				home_visible = false
				campaign_screen = "atlas"
				tutorial_step = 1
			1:
				campaign_universe = 0
				campaign_route_scroll_offset = 0.0
				campaign_screen = "route"
				tutorial_step = 2
			2:
				campaign_screen = "collection"
				campaign_collection_selected = 0
				campaign_collection_scroll_offset = 0.0
				campaign_collection_from_home = true
				tutorial_step = 3
			_:
				campaign_screen = ""
				home_visible = true
				_finish_tutorial()
	elif tutorial_context == "gameplay":
		if tutorial_step < 2:
			tutorial_step += 1
		else:
			_finish_tutorial()
	queue_redraw()


func _tutorial_copy() -> Dictionary:
	if tutorial_context == "home":
		match tutorial_step:
			0: return {"title":"ТВОЯ ИГРА — ТВОЙ МАРШРУТ","lines":["Кампания — большое путешествие по планетам.","Block Run — отдельный забег с усилениями.","Нажимай «Далее», и я покажу основные разделы."]}
			1: return {"title":"КОСМИЧЕСКИЙ АТЛАС","lines":["Здесь собраны 12 вселенных и 360 планет.","Открывай миры последовательно — каждый со своим характером.","Далее покажу, как устроен путь внутри вселенной."]}
			2: return {"title":"ПОДЪЁМ К ВЕРШИНЕ","lines":["Планета 001 начинается внизу маршрута.","Проводи вверх, чтобы подниматься к новым испытаниям.","Розовые крупные узлы отмечают боссов."]}
			_: return {"title":"ТВОИ ТРОФЕИ","lines":["Награды стали крупнее — листай их влево и вправо.","Выбирай трофей, чтобы увидеть его описание.","Теперь покажу управление прямо во время игры."]}
	if tutorial_context == "gameplay":
		match tutorial_step:
			0: return {"title":"СЧЁТ И ПОДСКАЗКИ","lines":["Верхние карточки показывают очки и цель уровня.","Над полем — запасная и следующая фигура.","Следи за целью: она подскажет, к чему идти."]}
			1: return {"title":"ИГРОВОЕ ПОЛЕ","lines":["Здесь собирай линии и освобождай пространство.","Призрачная фигура показывает место приземления.","Не спеши: сначала оцени, куда лучше поставить блок."]}
			_: return {"title":"УПРАВЛЕНИЕ ПАЛЬЦЕМ","lines":["Свайп влево / вправо — перемещение фигуры.","Короткий чёткий свайп вверх — поворот; вниз — ускорение.","Длинный быстрый свайп вниз — сброс. Кнопки HOLD и DROP тоже доступны."]}
	return {"title":"ПОДСКАЗКА","lines":["Изучи экран и попробуй основные действия."]}


func _tutorial_target_rect() -> Rect2:
	if tutorial_context == "home":
		if tutorial_step == 0:
			return home_campaign_rect.merge(home_block_run_rect)
		if tutorial_step == 1 and not campaign_atlas_rects.is_empty():
			return campaign_atlas_rects[0]
		if tutorial_step == 2:
			return campaign_route_scroll_viewport_rect
		if tutorial_step == 3:
			return campaign_collection_grid_viewport_rect
	elif tutorial_context == "gameplay":
		if tutorial_step == 0:
			return Rect2(14.0, 48.0, screen_size.x - 28.0, 64.0)
		if tutorial_step == 1:
			return board_rect
		return drop_rect.merge(hold_rect)
	return Rect2()


func _draw_tutorial_overlay() -> void:
	if not tutorial_active:
		return
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.025, 0.07, 0.62))
	var target := _tutorial_target_rect()
	if target.size.x > 0.0 and target.size.y > 0.0:
		draw_rect(target.grow(7.0), Color("#ffd05a"), false, 3.0, true)
		var target_center := target.get_center()
		draw_circle(target_center, 5.0, Color("#fff0b9"))
	var bubble_width := minf(520.0, screen_size.x - 28.0)
	var bubble_height := 174.0 if screen_size.y >= 560.0 else 150.0
	var bubble := Rect2(Vector2((screen_size.x - bubble_width) * 0.5, screen_size.y - bubble_height - 28.0), Vector2(bubble_width, bubble_height))
	_draw_soft_panel(bubble, Color("#102b58"), Color("#ffd05a"), 20, 14)
	var pointer_x := clampf(target.get_center().x, bubble.position.x + 24.0, bubble.end.x - 24.0) if target.size.x > 0.0 else bubble.get_center().x
	var pointer := PackedVector2Array([Vector2(pointer_x - 12.0, bubble.position.y + 1.0), Vector2(pointer_x + 12.0, bubble.position.y + 1.0), Vector2(pointer_x, bubble.position.y - 13.0)])
	draw_colored_polygon(pointer, Color("#ffd05a"))
	var copy := _tutorial_copy()
	draw_string(font, bubble.position + Vector2(16.0, 30.0), str(copy.title), HORIZONTAL_ALIGNMENT_LEFT, bubble.size.x - 32.0, 15, Color("#fff0b9"))
	var body_lines: Array = copy.get("lines", [])
	for index in range(mini(body_lines.size(), 3)):
		draw_string(font, bubble.position + Vector2(16.0, 58.0 + float(index) * 21.0), str(body_lines[index]), HORIZONTAL_ALIGNMENT_LEFT, bubble.size.x - 32.0, 10, Color("#e0f2ff"))
	var tutorial_button_width := minf(112.0, (bubble.size.x - 42.0) * 0.5)
	tutorial_skip_rect = Rect2(bubble.position.x + 14.0, bubble.end.y - 46.0, tutorial_button_width, 34.0)
	tutorial_next_rect = Rect2(bubble.end.x - 14.0 - tutorial_button_width, bubble.end.y - 46.0, tutorial_button_width, 34.0)
	_draw_pill(tutorial_skip_rect, Color("#1b426f"), Color("#719ac1"), 10)
	_center_text_in_rect("ПРОПУСТИТЬ", tutorial_skip_rect, 8, Color("#d5eaff"))
	_draw_pill(tutorial_next_rect, Color("#a56b20"), Color("#ffe18a"), 10)
	_center_text_in_rect("ДАЛЕЕ  ›", tutorial_next_rect, 10, Color("#ffffff"))


func _draw_touch_feedback() -> void:
	if touch_feedback_time <= 0.0:
		return
	var progress := 1.0 - touch_feedback_time / 0.18
	var radius := 8.0 + progress * 24.0
	var alpha := (1.0 - progress) * 0.62
	draw_circle(touch_feedback_position, radius, Color(0.58, 0.91, 1.0, alpha * 0.12))
	draw_arc(touch_feedback_position, radius, 0.0, TAU, 32, Color(0.72, 0.96, 1.0, alpha), 2.0, true)
	draw_circle(touch_feedback_position, 3.0 + (1.0 - progress) * 2.0, Color(1.0, 1.0, 1.0, alpha * 0.75))

func _draw_soft_panel(rect: Rect2, fill: Color, edge: Color = Color("#7dcfff"), radius: int = 18, shadow_size: int = 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = edge
	style.shadow_color = Color(0.015, 0.035, 0.12, 0.42)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 5)
	draw_style_box(style, rect)

func _draw_pill(rect: Rect2, fill: Color, edge: Color, radius: int = 16) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = edge
	style.shadow_color = Color(0.01, 0.025, 0.08, 0.35)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	draw_style_box(style, rect)

func _draw_backdrop() -> void:
	var top := Color("#123e91")
	var bottom := Color("#071b58")
	for band in range(28):
		var t := float(band) / 27.0
		draw_rect(Rect2(0, screen_size.y * t, screen_size.x, screen_size.y / 27.0 + 2.0), top.lerp(bottom, t))
	var pulse := 0.5 + 0.5 * sin(ambient_time * 0.65)
	draw_circle(Vector2(screen_size.x * 0.18, screen_size.y * 0.29), screen_size.x * 0.34, Color(0.12, 0.50, 1.0, 0.19))
	draw_circle(Vector2(screen_size.x * 0.82, screen_size.y * 0.56), screen_size.x * 0.37, Color(0.62, 0.16, 0.92, 0.15))
	draw_circle(Vector2(screen_size.x * 0.50, screen_size.y * 0.91), screen_size.x * 0.46, Color(0.02, 0.75, 0.94, 0.13))
	for i in range(54):
		var sx := float((i * 73 + 19) % 997) / 997.0
		var sy := float((i * 139 + 47) % 991) / 991.0
		var drift := fmod(ambient_time * (3.0 + float(i % 4) * 1.5) + float(i * 17), screen_size.y + 24.0)
		var point := Vector2(sx * screen_size.x, fmod(sy * screen_size.y + drift, screen_size.y))
		var twinkle := 0.35 + 0.55 * (0.5 + 0.5 * sin(ambient_time * 1.6 + float(i)))
		draw_circle(point, 1.4 if i % 4 else 2.5, Color(0.72, 0.91, 1.0, twinkle * 0.72))
	var hills := PackedVector2Array([Vector2(0, screen_size.y * 0.88), Vector2(screen_size.x * 0.18, screen_size.y * 0.82), Vector2(screen_size.x * 0.38, screen_size.y * 0.91), Vector2(screen_size.x * 0.62, screen_size.y * 0.84), Vector2(screen_size.x, screen_size.y * 0.90), Vector2(screen_size.x, screen_size.y), Vector2(0, screen_size.y)])
	draw_colored_polygon(hills, Color("#102d72"))
	draw_circle(Vector2(screen_size.x * 0.12, screen_size.y * 0.9), 42.0, Color(0.08, 0.72, 0.82, 0.28 + pulse * 0.08))
	draw_circle(Vector2(screen_size.x * 0.88, screen_size.y * 0.88), 58.0, Color(0.48, 0.23, 0.87, 0.24))
func _draw_header() -> void:
	# During active play the title banner is intentionally hidden. The compact
	# mode switch and pause affordance remain available without stealing arena space.
	_draw_mode_button()
	_draw_pause_button()
func _draw_mode_button() -> void:
	_draw_pill(mode_button_rect, Color("#1767c8"), Color("#8beaff"), 12)
	var label := "РЕЖИМ"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, mode_button_rect.get_center() + Vector2(-width * 0.5, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffffff"))
func _mode_display_name(mode_id: String) -> String:
	match mode_id:
		"classic": return "КЛАССИКА"
		"sprint": return "СПРИНТ"
		"marathon": return "МАРАФОН"
		"campaign": return "КАМПАНИЯ"
		_: return "РЕЖИМ"


func _draw_home_hub() -> void:
	var layout := _home_layout(screen_size)
	_center_text("BLOCK BUDDIES", 54.0, 29, Color("#fff0b9"))
	_center_text("ТВОЯ ВСЕЛЕННАЯ ПРИКЛЮЧЕНИЙ", 78.0, 10, Color("#c4edff"))
	var profile := Rect2(18.0, 104.0, screen_size.x - 36.0, 54.0)
	_draw_soft_panel(profile, Color("#174d9b"), Color("#76dcff"), 17, 8)
	draw_string(font, profile.position + Vector2(16.0, 23.0), "BUDDY  •  УРОВЕНЬ 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffffff"))
	draw_string(font, profile.position + Vector2(16.0, 42.0), "✦  120 МОНЕТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffe18a"))
	_draw_soft_panel(home_campaign_rect, Color("#1268b5"), Color("#64e2ff"), 22, 12)
	draw_string(font, home_campaign_rect.position + Vector2(18.0, 37.0), "КОСМИЧЕСКАЯ КАМПАНИЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffffff"))
	draw_string(font, home_campaign_rect.position + Vector2(18.0, 64.0), "12 ВСЕЛЕННЫХ  •  360 ПЛАНЕТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d7f5ff"))
	draw_string(font, home_campaign_rect.end - Vector2(34.0, 22.0), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#fff0a8"))
	_draw_soft_panel(home_block_run_rect, Color("#74469d"), Color("#ffca68"), 22, 12)
	draw_string(font, home_block_run_rect.position + Vector2(18.0, 37.0), "BLOCK RUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#ffffff"))
	draw_string(font, home_block_run_rect.position + Vector2(18.0, 64.0), "СОБИРАЙ УСИЛЕНИЯ И ПОБЕЖДАЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f5e6ff"))
	draw_string(font, home_block_run_rect.end - Vector2(34.0, 22.0), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#fff0a8"))
	_draw_soft_panel(home_tasks_rect, Color("#14548d"), Color("#79e5db"), 18, 8)
	draw_string(font, home_tasks_rect.position + Vector2(10.0, 29.0), "ЕЖЕДНЕВНЫЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffffff"))
	draw_string(font, home_tasks_rect.position + Vector2(10.0, 48.0), "ЗАДАНИЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffffff"))
	_draw_soft_panel(home_collection_rect, Color("#59451f"), Color("#ffd05a"), 18, 8)
	var collection_summary: Dictionary = CampaignCollection.get_collection_summary(campaign_progress)
	var collection_count := int(collection_summary.get("unlocked_count", 0))
	var collection_total := int(collection_summary.get("total_count", 49))
	draw_string(font, home_collection_rect.position + Vector2(10.0, 29.0), "★ ПОЛКА НАГРАД", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#fff0b9"))
	draw_string(font, home_collection_rect.position + Vector2(10.0, 49.0), "%02d / %02d ПОЛУЧЕНО" % [collection_count, collection_total], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ffe2a0"))
	_draw_soft_panel(home_heroes_rect, Color("#155c9c"), Color("#7bdfff"), 16, 7)
	_draw_soft_panel(home_shop_rect, Color("#8b541e"), Color("#ffd16c"), 16, 7)
	_draw_soft_panel(home_upgrades_rect, Color("#6c4a9c"), Color("#d2aaff"), 16, 7)
	_center_text_in_rect("ГЕРОИ", home_heroes_rect, 11, Color("#ffffff"))
	_center_text_in_rect("МАГАЗИН", home_shop_rect, 11, Color("#ffffff"))
	_center_text_in_rect("УЛУЧШЕНИЯ", home_upgrades_rect, 10, Color("#ffffff"))
	_center_text("ВЫБЕРИ СВОЁ ПРИКЛЮЧЕНИЕ", screen_size.y - 112.0, 10, Color("#b9eaff"))

func _draw_secondary_screen() -> void:
	_draw_soft_panel(secondary_back_rect, Color("#155c9c"), Color("#7bdfff"), 14, 6)
	draw_string(font, secondary_back_rect.position + Vector2(12.0, 27.0), "‹  ДОМОЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffffff"))
	var heading := "ГЕРОИ" if secondary_screen == "heroes" else ("МАГАЗИН" if secondary_screen == "shop" else ("УЛУЧШЕНИЯ" if secondary_screen == "upgrades" else "ЕЖЕДНЕВНЫЕ ЗАДАНИЯ"))
	_center_text(heading, screen_size.y * 0.32, 27, Color("#fff0b9"))
	var subtitle := "СКОРО: КОЛЛЕКЦИЯ BUDDY И ИХ СПОСОБНОСТИ" if secondary_screen == "heroes" else ("СКОРО: КОСМЕТИКА И ПОЛЕЗНЫЕ ПРЕДМЕТЫ" if secondary_screen == "shop" else ("СКОРО: ПРОКАЧКА ГЕРОЕВ И ИХ УМЕНИЙ" if secondary_screen == "upgrades" else "ТВОИ ЦЕЛИ ОБНОВЛЯЮТСЯ КАЖДЫЙ ДЕНЬ"))
	_center_text(subtitle, screen_size.y * 0.32 + 38.0, 11, Color("#c4edff"))
	var panel := Rect2(22.0, screen_size.y * 0.43, screen_size.x - 44.0, 150.0)
	_draw_soft_panel(panel, Color("#174d89"), Color("#64d9f2"), 20, 10)
	_center_text("РАЗДЕЛ ПОДГОТАВЛИВАЕТСЯ", panel.position.y + 62.0, 16, Color("#ffffff"))
	_center_text("МЫ СОХРАНИЛИ МЕСТО ДЛЯ ПОЛНОЦЕННОГО", panel.position.y + 91.0, 10, Color("#d4efff"))
	_center_text("ИНТЕРФЕЙСА — БЕЗ ПУСТЫХ КНОПОК", panel.position.y + 110.0, 10, Color("#d4efff"))

func _center_text_in_rect(value: String, rect: Rect2, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(rect.get_center().x - width * 0.5, rect.get_center().y + size * 0.35), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)



func _start_campaign_planet() -> void:
	var node_id := _campaign_global_planet_id(campaign_universe, campaign_planet)
	if campaign_progress == null or not _campaign_planet_is_unlocked(campaign_universe, campaign_planet):
		return
	var definition := campaign_progress.get_planet_definition(node_id)
	if definition.is_empty():
		return
	if mode_session == null:
		mode_session = ModeSession.new()
	if not mode_session.start("campaign"):
		return
	mode_session.rules["target_lines"] = int(definition.target_lines)
	mode_session.rules["target_score"] = int(definition.get("target_score", 0))
	mode_session.rules["target_survive_seconds"] = float(definition.get("target_survive_seconds", 0))
	mode_session.rules["time_limit_seconds"] = float(definition.get("time_limit_seconds", 0))
	mode_session.rules["boss_phases"] = definition.get("boss_phases", []).duplicate(true)
	campaign_run_planet_id = node_id
	_clear_campaign_checkpoint()
	if not _reset_campaign_piece_runtime():
		push_error("Campaign piece runtime could not spawn the authored planet piece.")
		campaign_piece_runtime = null
		return
	campaign_run_active = true
	campaign_completion_processed = false
	campaign_last_reward_marks = 0
	block_run_active = false
	mode_select_visible = false
	home_visible = false
	secondary_screen = ""
	campaign_screen = ""
	paused = false
	gravity_clock = 0.0
	buddy_last_lines = 0
	clear_flash_time = 0.0
	clear_flash_count = 0
	if is_instance_valid(buddy):
		buddy.set_state("idle", 0.0)
	queue_redraw()

func _process_campaign_completion() -> void:
	if not campaign_run_active or campaign_completion_processed or mode_session == null or mode_session.status != ModeSession.STATUS_COMPLETED:
		return
	var previous_collection: Dictionary = CampaignCollection.get_collection_summary(campaign_progress)
	var result: Dictionary = campaign_progress.complete_planet(campaign_run_planet_id, _active_lines(), _active_score(), mode_session.elapsed_seconds)
	if bool(result.get("accepted", false)):
		campaign_last_reward_marks = int(result.get("reward_marks", 0))
		var current_collection: Dictionary = CampaignCollection.get_collection_summary(campaign_progress)
		var newly_unlocked: Array[String] = CampaignCollection.get_newly_unlocked_ids(previous_collection, current_collection)
		campaign_collection_reveal_queue = CampaignRewardQueue.append_unique(campaign_collection_reveal_queue, newly_unlocked)
		if campaign_screen.is_empty() and not campaign_collection_reveal_queue.is_empty():
			_begin_next_campaign_collection_reveal()
		if not CampaignStore.save_progress(campaign_progress, CampaignStore.DEFAULT_PATH, campaign_collection_reveal_queue):
			push_warning("Campaign progress could not be saved to user profile storage.")
	campaign_completion_processed = true
	_clear_campaign_checkpoint()
	queue_redraw()

func _return_to_campaign_route() -> void:
	if campaign_run_planet_id < 1:
		return
	campaign_universe = int((campaign_run_planet_id - 1) / CampaignProgress.PLANETS_PER_UNIVERSE)
	campaign_planet = ((campaign_run_planet_id - 1) % CampaignProgress.PLANETS_PER_UNIVERSE) + 1
	campaign_screen = "route"
	_clear_campaign_checkpoint()
	campaign_run_active = false
	campaign_piece_runtime = null
	campaign_completion_processed = false
	mode_select_visible = false
	home_visible = false
	paused = false
	queue_redraw()

func _campaign_universe_name(index: int) -> String:
	var names := ["ЗЕЛЁНЫЕ РАВНИНЫ", "КАРАВАН ЗВЁЗД", "ОГНЕННЫЕ ЗЕМЛИ", "ЛЕДЯНАЯ КОРОНА", "ЛУННАЯ КОЛОНИЯ", "КРЫЛЬЯ ЭКСПЕДИЦИИ", "ПЕСКИ ВРЕМЕНИ", "ВРАТА МЕЖДУМИРЬЯ", "НЕБЕСНЫЙ АРХИПЕЛАГ", "СТАНЦИЯ ДРОНОВ", "КОСМИЧЕСКИЙ РАЗЛОМ", "ДАЛЬНИЙ РУБЕЖ"]
	return names[clampi(index, 0, names.size() - 1)]

func _campaign_global_planet_id(universe_index: int, planet_number: int) -> int:
	return universe_index * CampaignProgress.PLANETS_PER_UNIVERSE + planet_number

func _campaign_planet_is_unlocked(universe_index: int, planet_number: int) -> bool:
	if campaign_progress == null:
		return universe_index == 0 and planet_number == 1
	var node_id := _campaign_global_planet_id(universe_index, planet_number)
	return campaign_progress.get_planet_status(node_id) == "current"

func _draw_campaign_screen() -> void:
	campaign_back_rect = Rect2(16.0, 14.0, 104.0, 40.0)
	_draw_soft_panel(campaign_back_rect, Color("#155c9c"), Color("#7bdfff"), 14, 6)
	draw_string(font, campaign_back_rect.position + Vector2(11.0, 26.0), "‹  НАЗАД", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffffff"))
	if campaign_screen == "atlas":
		_draw_campaign_atlas()
	elif campaign_screen == "collection":
		_draw_campaign_collection()
	elif campaign_screen == "route":
		_draw_campaign_route()
	else:
		_draw_campaign_planet()

func _draw_campaign_atlas() -> void:
	campaign_collection_rect = Rect2()
	_center_text("КОСМИЧЕСКИЙ АТЛАС", 104.0, 23, Color("#fff0b9"))
	_center_text("12 ВСЕЛЕННЫХ  •  360 ПЛАНЕТ", 128.0, 10, Color("#c4edff"))
	campaign_atlas_rects.clear()
	var compact := screen_size.x <= 480.0
	var columns := 2 if compact else 3
	var gap := 7.0
	var margin := 14.0 if compact else 22.0
	var card_w := (screen_size.x - margin * 2.0 - gap * float(columns - 1)) / float(columns)
	var card_h := 82.0 if compact else 166.0
	var top := 151.0
	for index in range(12):
		var col := index % columns
		var row := index / columns
		var rect := Rect2(margin + float(col) * (card_w + gap), top + float(row) * (card_h + gap), card_w, card_h)
		campaign_atlas_rects.append(rect)
		var universe_progress: Dictionary = campaign_progress.get_universe_progress(index) if campaign_progress != null else {"unlocked": index == 0, "current": index == 0, "completed": false, "completed_count": 0}
		var unlocked := bool(universe_progress.get("unlocked", false))
		var is_current := bool(universe_progress.get("current", false))
		var is_completed := bool(universe_progress.get("completed", false))
		var fills := [Color("#286e69"),Color("#246d83"),Color("#a44f35"),Color("#356b9e"),Color("#88704a"),Color("#3b62a0"),Color("#8a6740"),Color("#67519a"),Color("#397f8c"),Color("#53647d"),Color("#5c4c98"),Color("#87527e")]
		var accents := [Color("#83edbf"),Color("#55ddff"),Color("#ff9a68"),Color("#a8e5ff"),Color("#ffd05a"),Color("#8ebcff"),Color("#e4c18c"),Color("#a77bff"),Color("#8af0e8"),Color("#b6c9df"),Color("#c1a5ff"),Color("#ff8fbd")]
		_draw_soft_panel(rect, fills[index] if unlocked else fills[index].darkened(0.42), accents[index] if unlocked else Color("#5c7394"), 13, 5)
		var orb := Vector2(rect.position.x + (29.0 if compact else 48.0), rect.get_center().y)
		draw_circle(orb, 17.0 if compact else 28.0, Color(accents[index].r, accents[index].g, accents[index].b, 0.20))
		draw_arc(orb, 14.0 if compact else 24.0, 0.0, TAU, 36, accents[index], 1.5, true)
		draw_circle(orb, 7.0 if compact else 12.0, accents[index])
		var tx := rect.position.x + (53.0 if compact else 86.0)
		var title_size := 8 if compact else 11
		draw_string(font, Vector2(tx, rect.position.y + (25.0 if compact else 34.0)), "ВСЕЛЕННАЯ %02d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, accents[index])
		draw_string(font, Vector2(tx, rect.position.y + (43.0 if compact else 59.0)), _campaign_universe_name(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 8 if compact else 10, Color("#ffffff"))
		draw_string(font, Vector2(tx, rect.position.y + (62.0 if compact else 83.0)), "ПЛАНЕТЫ %03d–%03d" % [index * 30 + 1, (index + 1) * 30], HORIZONTAL_ALIGNMENT_LEFT, -1, 8 if compact else 9, Color("#d7eaff"))
		draw_string(font, Vector2(tx, rect.position.y + (75.0 if compact else 112.0)), "ПРОЙДЕНА" if is_completed else ("ТЕКУЩАЯ" if is_current else ("ОТКРЫТА" if unlocked else "ЗАКРЫТА")), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ffd05a") if is_current else (Color("#8ef4d3") if is_completed else Color("#9bb2d0")))
	_center_text("ПЕРВЫЙ МИР ДОСТУПЕН ДЛЯ ИССЛЕДОВАНИЯ", screen_size.y - 14.0, 9, Color("#b9eaff"))

func _draw_campaign_collection() -> void:
	var summary: Dictionary = CampaignCollection.get_collection_summary(campaign_progress)
	var items: Array = summary.get("items", [])
	var unlocked_count := int(summary.get("unlocked_count", 0))
	var total_count := int(summary.get("total_count", 49))
	var layout: Dictionary = CampaignCollectionLayout.collection_strip(screen_size)
	var compact := bool(layout.compact)
	_center_text("ПОЛКА НАГРАД", float(layout.title_y), 22 if not compact else 19, Color("#fff0b9"))
	_center_text("ТВОИ ДОСТИЖЕНИЯ  •  %02d / %02d" % [unlocked_count, total_count], float(layout.subtitle_y), 10 if not compact else 9, Color("#c4edff"))
	var legend_y := float(layout.legend_y)
	var legend_start := screen_size.x * 0.5 - 89.5
	for legend in [
		{"label": "РЕЛИКВИИ", "color": Color("#55ddcf"), "width": 64.0},
		{"label": "БОССЫ", "color": Color("#ff91bd"), "width": 53.0},
		{"label": "КОРОНА", "color": Color("#ffd05a"), "width": 62.0}
	]:
		draw_circle(Vector2(legend_start + 4.0, legend_y - 3.0), 3.0, legend.color)
		draw_string(font, Vector2(legend_start + 12.0, legend_y), legend.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#d7eaff"))
		legend_start += legend.width
	var grid_viewport: Rect2 = layout.grid_viewport_rect
	campaign_collection_grid_viewport_rect = grid_viewport
	var gap := float(layout.gap)
	var card_width := float(layout.card_width)
	var card_height := float(layout.card_height)
	var stride := card_width + gap
	campaign_collection_scroll_offset = clampf(campaign_collection_scroll_offset, 0.0, float(layout.max_scroll))
	campaign_collection_item_rects.clear()
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var rect := Rect2(grid_viewport.position.x + float(index) * stride - campaign_collection_scroll_offset, grid_viewport.position.y + (grid_viewport.size.y - card_height) * 0.5, card_width, card_height)
		var visible_cell := rect.end.x >= grid_viewport.position.x and rect.position.x <= grid_viewport.end.x
		campaign_collection_item_rects.append(rect if visible_cell else Rect2())
		if not visible_cell:
			continue
		var unlocked := bool(item.get("unlocked", false))
		var selected := index == campaign_collection_selected
		var kind := str(item.get("kind", ""))
		var universe_number := int(item.get("universe_number", 0))
		var visual_variant := int(item.get("visual_variant", 0))
		var planet_id := int(item.get("planet_id", 0))
		var accent := _collection_universe_accent(kind, universe_number, planet_id)
		var muted_accent := accent if unlocked else accent.darkened(0.66).lerp(Color("#7186a5"), 0.55)
		var fill := muted_accent.darkened(0.78) if unlocked else muted_accent.darkened(0.88)
		_draw_soft_panel(rect, fill, Color("#fff0b9") if selected else muted_accent, 13, 4 if selected else 2)
		if selected:
			draw_rect(rect.grow(1.5), Color("#fff0b9"), false, 2.0, true)
		var emblem_center := Vector2(rect.get_center().x, rect.position.y + card_height * 0.39)
		var emblem_radius := minf(35.0, card_width * 0.31)
		draw_circle(emblem_center, emblem_radius + 8.0, Color(muted_accent.r, muted_accent.g, muted_accent.b, 0.12))
		_draw_collection_emblem(emblem_center, emblem_radius, kind, muted_accent, visual_variant, planet_id)
		if not unlocked:
			var lock_center := Vector2(rect.end.x - 12.0, rect.position.y + 12.0)
			draw_circle(lock_center, 8.0, Color("#172b4c"))
			draw_arc(lock_center + Vector2(0.0, -1.0), 3.7, PI, TAU, 12, Color("#a9bdd5"), 1.3, true)
			draw_rect(Rect2(lock_center + Vector2(-3.4, -0.2), Vector2(6.8, 5.0)), Color("#a9bdd5"))
		var short_label := "РЕЛИКВИЯ %02d" % universe_number if kind == "universe_relic" else ("ГЛАВНЫЙ ТРОФЕЙ" if kind == "campaign_crown" else "БОСС %03d" % planet_id)
		draw_string(font, Vector2(rect.position.x + 5.0, rect.end.y - 13.0), short_label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 8 if compact else 9, Color("#ffffff") if unlocked else Color("#8095b2"))
	var selected_item: Dictionary = items[clampi(campaign_collection_selected, 0, items.size() - 1)] if not items.is_empty() else {}
	var detail_rect: Rect2 = layout.detail_rect
	_draw_soft_panel(detail_rect, Color("#102f68"), Color("#55ddff"), 15, 5)
	campaign_collection_inspect_rect = layout.inspect_rect
	if not selected_item.is_empty():
		var is_unlocked := bool(selected_item.get("unlocked", false))
		var selected_kind := str(selected_item.get("kind", ""))
		var selected_universe_number := int(selected_item.get("universe_number", 0))
		var selected_planet := int(selected_item.get("planet_id", 0))
		var accent := _collection_universe_accent(selected_kind, selected_universe_number, selected_planet)
		var detail_icon_center := Vector2(detail_rect.position.x + 48.0, detail_rect.get_center().y)
		_draw_collection_emblem(detail_icon_center, minf(32.0, detail_rect.size.y * 0.24), selected_kind, accent, int(selected_item.get("visual_variant", 0)), selected_planet)
		var text_left := detail_rect.position.x + 88.0
		var text_width := maxf(44.0, campaign_collection_inspect_rect.position.x - text_left - 10.0)
		var category := "РЕЛИКВИЯ %02d" % selected_universe_number if selected_kind == "universe_relic" else ("БОСС" if selected_kind == "boss_insignia" else "ГЛАВНАЯ НАГРАДА")
		var status := category + (" • ПОЛУЧЕНО" if is_unlocked else " • ВПЕРЕДИ")
		draw_string(font, Vector2(text_left, detail_rect.position.y + 22.0), status, HORIZONTAL_ALIGNMENT_LEFT, text_width, 8 if compact else 9, Color("#8ef4d3") if is_unlocked else Color("#ffd05a"))
		draw_string(font, Vector2(text_left, detail_rect.position.y + 47.0), str(selected_item.get("title", "НАГРАДА")), HORIZONTAL_ALIGNMENT_LEFT, text_width, 11 if compact else 13, Color("#ffffff"))
		draw_string(font, Vector2(text_left, detail_rect.position.y + 68.0), str(selected_item.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT, text_width, 8 if compact else 9, Color("#c4edff"))
		var unlock_planet := int(selected_item.get("unlock_planet", 0))
		var requirement := "УСЛОВИЕ: 360 ПЛАНЕТ" if selected_kind == "campaign_crown" else ("УСЛОВИЕ: 30 ПЛАНЕТ" if selected_kind == "universe_relic" else "УСЛОВИЕ: БОСС %03d" % unlock_planet)
		draw_string(font, Vector2(text_left, detail_rect.end.y - 10.0), requirement, HORIZONTAL_ALIGNMENT_LEFT, text_width, 7 if compact else 8, Color("#ffd77a"))
		_draw_soft_panel(campaign_collection_inspect_rect, Color("#174d79"), Color("#8fe8ff"), 10, 3)
		_center_text("ОСМОТР", campaign_collection_inspect_rect.position.y + campaign_collection_inspect_rect.size.y * 0.67, 8, Color("#ffffff"))
	var scroll_visual: Dictionary = CampaignCollectionLayout.scrollbar_strip(layout, campaign_collection_scroll_offset)
	var scroll_track: Rect2 = scroll_visual.get("track", Rect2())
	var scroll_thumb: Rect2 = scroll_visual.get("thumb", Rect2())
	if scroll_track.size.x > 0.0 and scroll_thumb.size.x > 0.0:
		draw_line(scroll_track.position, Vector2(scroll_track.end.x, scroll_track.position.y), Color(0.42, 0.62, 0.82, 0.28), 2.0, true)
		draw_line(scroll_thumb.position, Vector2(scroll_thumb.end.x, scroll_thumb.position.y), Color("#8fe8ff"), 3.0, true)
	_center_text("ЛИСТАЙ НАГРАДЫ ПО ГОРИЗОНТАЛИ" if float(layout.max_scroll) > 0.5 else "ВЫБЕРИ НАГРАДУ ДЛЯ ПРОСМОТРА", float(layout.footer_y), 8, Color("#b9eaff"))
	if campaign_collection_reveal_active or campaign_collection_preview_active:
		var modal_item := selected_item
		var is_new_reward := campaign_collection_reveal_active
		if is_new_reward and not campaign_collection_reveal_queue.is_empty():
			modal_item = CampaignCollection.get_item(campaign_progress, campaign_collection_reveal_queue[0])
		_draw_campaign_collection_reward_modal(modal_item, is_new_reward)


func _scroll_campaign_collection_rows(direction: int) -> void:
	if direction == 0:
		return
	var layout: Dictionary = CampaignCollectionLayout.collection_strip(screen_size)
	var stride := float(layout.get("card_width", 0.0)) + float(layout.get("gap", 0.0))
	var max_scroll := float(layout.get("max_scroll", 0.0))
	if stride <= 0.0 or max_scroll <= 0.0:
		return
	campaign_collection_scroll_offset = clampf(campaign_collection_scroll_offset + float(direction) * stride * 2.0, 0.0, max_scroll)
	queue_redraw()


func _scroll_campaign_route(direction: int) -> void:
	if direction == 0 or campaign_route_scroll_max <= 0.0:
		return
	campaign_route_scroll_offset = clampf(campaign_route_scroll_offset + float(direction) * 90.0, 0.0, campaign_route_scroll_max)
	queue_redraw()


func _begin_next_campaign_collection_reveal() -> void:
	if campaign_collection_reveal_queue.is_empty():
		return
	var next_id := campaign_collection_reveal_queue[0]
	var summary: Dictionary = CampaignCollection.get_collection_summary(campaign_progress)
	var items: Array = summary.get("items", [])
	for index in range(items.size()):
		if str(items[index].get("id", "")) == next_id:
			campaign_collection_selected = index
			break
	var collection_layout: Dictionary = CampaignCollectionLayout.collection_strip(screen_size)
	campaign_collection_scroll_offset = CampaignCollectionLayout.scroll_offset_for_index_strip(collection_layout, campaign_collection_selected, campaign_collection_scroll_offset)
	campaign_collection_reveal_active = true
	campaign_collection_preview_active = false
	campaign_collection_reveal_time = 0.0


func _dismiss_campaign_collection_modal() -> void:
	if campaign_collection_reveal_active:
		var acknowledgement: Dictionary = CampaignRewardQueue.acknowledge_first(campaign_progress, campaign_collection_reveal_queue)
		if not bool(acknowledgement.get("ok", false)):
			push_warning("Pending campaign reward reveal could not be acknowledged: " + str(acknowledgement.get("reason", "unknown")))
			queue_redraw()
			return
		campaign_collection_reveal_queue = acknowledgement.get("pending_reward_reveals", [])
		campaign_collection_reveal_active = false
		campaign_collection_reveal_time = 0.0
		if not campaign_collection_reveal_queue.is_empty():
			_begin_next_campaign_collection_reveal()
	else:
		campaign_collection_preview_active = false
	queue_redraw()


func _draw_campaign_collection_reward_modal(item: Dictionary, is_new_reward: bool) -> void:
	if item.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.015, 0.025, 0.07, 0.82))
	var panel := CampaignCollectionLayout.reward_modal(screen_size)
	_draw_soft_panel(panel, Color("#0b1d42"), _collection_universe_accent(str(item.get("kind", "")), int(item.get("universe_number", 0)), int(item.get("planet_id", 0))), 22, 12)
	var kind := str(item.get("kind", ""))
	var universe_number := int(item.get("universe_number", 0))
	var planet_id := int(item.get("planet_id", 0))
	var visual_variant := int(item.get("visual_variant", 0))
	var accent := _collection_universe_accent(kind, universe_number, planet_id)
	var heading := "НОВАЯ НАГРАДА!" if is_new_reward else "ОСМОТР ТРОФЕЯ"
	draw_string(font, Vector2(panel.position.x + 10.0, panel.position.y + 31.0), heading, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, 15, Color("#fff0b9"))
	var emblem_center := Vector2(panel.get_center().x, panel.position.y + panel.size.y * 0.355)
	var reveal_progress := clampf(campaign_collection_reveal_time / 0.7, 0.0, 1.0) if is_new_reward else 1.0
	var emblem_scale := 0.78 + 0.22 * reveal_progress
	var emblem_radius := minf(43.0, panel.size.y * 0.12) * emblem_scale
	var pulse := 0.5 + 0.5 * sin(ambient_time * 3.2)
	draw_circle(emblem_center, emblem_radius + 14.0 + pulse * 4.0, Color(accent.r, accent.g, accent.b, 0.10))
	draw_arc(emblem_center, emblem_radius + 13.0 + pulse * 4.0, 0.0, TAU, 56, Color(accent.r, accent.g, accent.b, 0.68), 2.0, true)
	if is_new_reward:
		var burst_radius := emblem_radius + 13.0 + reveal_progress * 28.0
		var burst_alpha := 1.0 - reveal_progress
		draw_arc(emblem_center, burst_radius, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, burst_alpha), 2.2, true)
		for sparkle in range(12):
			var angle := TAU * float(sparkle) / 12.0 + ambient_time * 0.18
			var sparkle_pos := emblem_center + Vector2.from_angle(angle) * (emblem_radius + 17.0 + pulse * 5.0)
			draw_line(sparkle_pos - Vector2(3.0, 0.0), sparkle_pos + Vector2(3.0, 0.0), accent.lightened(0.35), 1.5)
			draw_line(sparkle_pos - Vector2(0.0, 3.0), sparkle_pos + Vector2(0.0, 3.0), accent.lightened(0.35), 1.5)
	_draw_collection_emblem(emblem_center, emblem_radius, kind, accent, visual_variant, planet_id)
	var status := "ПОЛУЧЕНО" if bool(item.get("unlocked", false)) else "ЕЩЁ ВПЕРЕДИ"
	draw_string(font, Vector2(panel.position.x + 14.0, panel.position.y + panel.size.y * 0.585), status, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 28.0, 9, Color("#8ef4d3") if bool(item.get("unlocked", false)) else Color("#ffd05a"))
	draw_string(font, Vector2(panel.position.x + 10.0, panel.position.y + panel.size.y * 0.665), str(item.get("title", "НАГРАДА")), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, 14, Color("#ffffff"))
	draw_string(font, Vector2(panel.position.x + 18.0, panel.position.y + panel.size.y * 0.745), str(item.get("description", "")), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 36.0, 8, Color("#c4edff"))
	var instruction := "КОСНИСЬ, ЧТОБЫ ПРОДОЛЖИТЬ" if is_new_reward else "КОСНИСЬ, ЧТОБЫ ЗАКРЫТЬ"
	draw_string(font, Vector2(panel.position.x + 10.0, panel.end.y - 16.0), instruction, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, 8, Color("#fff0b9"))

func _collection_universe_accent(kind: String, universe_number: int, planet_id: int) -> Color:
	if kind == "campaign_crown":
		return Color("#ffd05a")
	var universe_colors := [
		Color("#83edbf"), Color("#55ddff"), Color("#ff9a68"), Color("#a8e5ff"),
		Color("#ffd05a"), Color("#8ebcff"), Color("#e4c18c"), Color("#a77bff"),
		Color("#8af0e8"), Color("#b6c9df"), Color("#c1a5ff"), Color("#ff8fbd")
	]
	var color_index := clampi(universe_number - 1, 0, universe_colors.size() - 1)
	var accent: Color = universe_colors[color_index]
	if kind == "boss_insignia":
		var boss_step := int((planet_id - 1) / 10) % 3
		accent = accent.lightened(0.06 * boss_step)
	return accent


func _draw_collection_emblem(center: Vector2, radius: float, kind: String, accent: Color, visual_variant: int = 0, planet_id: int = 0) -> void:
	if kind == "universe_relic":
		match visual_variant:
			1: # Green Plains — living sprout
				var leaf_a := PackedVector2Array([center + Vector2(0, 1), center + Vector2(-radius, -radius * 0.72), center + Vector2(-radius * 0.12, -radius * 0.42)])
				var leaf_b := PackedVector2Array([center + Vector2(0, 1), center + Vector2(radius, -radius * 0.9), center + Vector2(radius * 0.18, -radius * 0.35)])
				draw_colored_polygon(leaf_a, accent.darkened(0.28))
				draw_colored_polygon(leaf_b, accent.darkened(0.12))
				draw_line(center + Vector2(0, radius), center + Vector2(0, -radius * 0.45), accent.lightened(0.35), 1.8)
			2: # Star Caravan — compass
				var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.3, -radius * 0.25), center + Vector2(radius, 0), center + Vector2(radius * 0.3, radius * 0.25), center + Vector2(0, radius), center + Vector2(-radius * 0.3, radius * 0.25), center + Vector2(-radius, 0), center + Vector2(-radius * 0.3, -radius * 0.25)])
				draw_colored_polygon(points, accent.darkened(0.42))
				draw_polyline(points, accent, 1.5, true)
				draw_line(center + Vector2(-radius * 0.72, 0), center + Vector2(radius * 0.72, 0), accent.lightened(0.4), 1.0)
			3: # Ashen Sun — solar core
				for ray in range(8):
					var angle := TAU * float(ray) / 8.0
					draw_line(center + Vector2.from_angle(angle) * radius * 0.55, center + Vector2.from_angle(angle) * radius, accent, 1.5)
				draw_circle(center, radius * 0.48, accent.darkened(0.3))
				draw_arc(center, radius * 0.48, 0, TAU, 24, accent.lightened(0.45), 1.4, true)
			4: # Ice Crown — snowflake
				for ray in range(6):
					var angle := TAU * float(ray) / 6.0 - PI * 0.5
					var direction := Vector2.from_angle(angle)
					draw_line(center - direction * radius * 0.82, center + direction * radius * 0.82, accent, 1.6)
					for side in [-1.0, 1.0]:
						var branch := center + direction * radius * 0.48
						draw_line(branch, branch + direction.rotated(side * 0.72) * radius * 0.28, accent.lightened(0.28), 1.1)
			5: # Lunar Archive — crescent
				draw_circle(center, radius * 0.82, accent.darkened(0.22))
				draw_circle(center + Vector2(radius * 0.38, -radius * 0.16), radius * 0.72, Color("#102f68"))
				draw_circle(center + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.12, accent.lightened(0.45))
			6: # Expedition — feather
				var feather := PackedVector2Array([center + Vector2(-radius * 0.78, radius * 0.8), center + Vector2(-radius * 0.38, -radius * 0.82), center + Vector2(radius * 0.7, -radius * 0.45), center + Vector2(radius * 0.38, radius * 0.42)])
				draw_colored_polygon(feather, accent.darkened(0.3))
				draw_polyline(feather, accent, 1.5, true)
				draw_line(center + Vector2(-radius * 0.7, radius * 0.72), center + Vector2(radius * 0.58, -radius * 0.32), accent.lightened(0.4), 1.2)
			7: # Sands of Time — hourglass
				var glass := PackedVector2Array([center + Vector2(-radius * 0.72, -radius), center + Vector2(radius * 0.72, -radius), center + Vector2(radius * 0.12, 0), center + Vector2(radius * 0.72, radius), center + Vector2(-radius * 0.72, radius), center + Vector2(-radius * 0.12, 0)])
				draw_colored_polygon(glass, accent.darkened(0.42))
				draw_polyline(glass, accent, 1.5, true)
				draw_circle(center + Vector2(0, radius * 0.46), radius * 0.12, accent.lightened(0.35))
			8: # Between Worlds — portal
				draw_arc(center, radius * 0.82, 0, TAU, 32, accent, 2.0, true)
				draw_arc(center, radius * 0.55, 0, TAU, 32, accent.lightened(0.3), 1.4, true)
				draw_line(center + Vector2(-radius * 0.2, -radius * 0.45), center + Vector2(radius * 0.2, radius * 0.45), accent, 1.4)
			9: # Sky Archipelago — three floating isles
				draw_circle(center + Vector2(-radius * 0.42, radius * 0.18), radius * 0.34, accent.darkened(0.2))
				draw_circle(center + Vector2(radius * 0.35, radius * 0.24), radius * 0.29, accent)
				draw_circle(center + Vector2(0, -radius * 0.4), radius * 0.25, accent.lightened(0.3))
				draw_arc(center + Vector2(0, radius * 0.16), radius * 0.82, PI * 0.1, PI * 0.9, 16, accent, 1.2, true)
			10: # Drone Station — mechanical gear
				draw_circle(center, radius * 0.7, accent.darkened(0.3))
				for tooth in range(8):
					var angle := TAU * float(tooth) / 8.0
					draw_line(center + Vector2.from_angle(angle) * radius * 0.58, center + Vector2.from_angle(angle) * radius, accent, 2.0)
				draw_circle(center, radius * 0.25, Color("#102f68"))
				draw_arc(center, radius * 0.25, 0, TAU, 20, accent.lightened(0.4), 1.2, true)
			11: # Cosmic Rift — fractured shard
				var shard := PackedVector2Array([center + Vector2(-radius * 0.18, -radius), center + Vector2(radius * 0.72, -radius * 0.12), center + Vector2(radius * 0.12, radius), center + Vector2(-radius * 0.72, radius * 0.12)])
				draw_colored_polygon(shard, accent.darkened(0.35))
				draw_polyline(shard, accent, 1.6, true)
				draw_line(center + Vector2(-radius * 0.18, -radius * 0.6), center + Vector2(radius * 0.1, radius * 0.62), accent.lightened(0.42), 1.2)
			_: # Far Frontier — beacon
				var beacon := PackedVector2Array([center + Vector2(-radius * 0.36, radius), center + Vector2(-radius * 0.2, -radius * 0.35), center + Vector2(radius * 0.2, -radius * 0.35), center + Vector2(radius * 0.36, radius)])
				draw_colored_polygon(beacon, accent.darkened(0.3))
				draw_polyline(beacon, accent, 1.5, true)
				draw_line(center + Vector2(-radius, -radius * 0.78), center + Vector2(-radius * 0.38, -radius * 0.48), accent.lightened(0.35), 1.2)
				draw_line(center + Vector2(radius, -radius * 0.78), center + Vector2(radius * 0.38, -radius * 0.48), accent.lightened(0.35), 1.2)
	elif kind == "boss_insignia":
		var universe_number := clampi(int((visual_variant - 1) / 30) + 1, 1, 12)
		var boss_rank := clampi(int((planet_id - 1) / 10) % 3 + 1, 1, 3)
		match universe_number % 4:
			0:
				var shield := PackedVector2Array([center + Vector2(-radius * 0.82, -radius * 0.68), center + Vector2(radius * 0.82, -radius * 0.68), center + Vector2(radius * 0.62, radius * 0.25), center + Vector2(0, radius), center + Vector2(-radius * 0.62, radius * 0.25)])
				draw_colored_polygon(shield, accent.darkened(0.42))
				draw_polyline(shield, accent, 1.5, true)
			1:
				var hex := PackedVector2Array([center + Vector2(-radius * 0.5, -radius * 0.88), center + Vector2(radius * 0.5, -radius * 0.88), center + Vector2(radius, 0), center + Vector2(radius * 0.5, radius * 0.88), center + Vector2(-radius * 0.5, radius * 0.88), center + Vector2(-radius, 0)])
				draw_colored_polygon(hex, accent.darkened(0.42))
				draw_polyline(hex, accent, 1.5, true)
			2:
				draw_circle(center, radius * 0.82, accent.darkened(0.42))
				draw_arc(center, radius * 0.82, 0, TAU, 32, accent, 1.5, true)
			_:
				var diamond := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.78, 0), center + Vector2(0, radius), center + Vector2(-radius * 0.78, 0)])
				draw_colored_polygon(diamond, accent.darkened(0.42))
				draw_polyline(diamond, accent, 1.5, true)
		match boss_rank:
			1:
				draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius * 0.48), center + Vector2(radius * 0.4, radius * 0.35), center + Vector2(-radius * 0.4, radius * 0.35)]), accent.lightened(0.38))
			2:
				draw_line(center + Vector2(-radius * 0.52, 0), center + Vector2(radius * 0.52, 0), accent.lightened(0.5), 2.0)
				draw_line(center + Vector2(0, -radius * 0.52), center + Vector2(0, radius * 0.52), accent.lightened(0.5), 2.0)
				draw_circle(center, radius * 0.18, accent.lightened(0.45))
			_:
				for ray in range(8):
					var angle := TAU * float(ray) / 8.0
					draw_line(center + Vector2.from_angle(angle) * radius * 0.22, center + Vector2.from_angle(angle) * radius * 0.58, accent.lightened(0.48), 1.3)
				draw_circle(center, radius * 0.18, accent.lightened(0.3))
	else:
		var crown := PackedVector2Array([center + Vector2(-radius, -radius * 0.12), center + Vector2(-radius * 0.62, radius * 0.22), center + Vector2(-radius * 0.38, -radius * 0.62), center + Vector2(0, -radius * 0.08), center + Vector2(radius * 0.38, -radius * 0.62), center + Vector2(radius * 0.62, radius * 0.22), center + Vector2(radius, -radius * 0.12), center + Vector2(radius * 0.78, radius * 0.82), center + Vector2(-radius * 0.78, radius * 0.82)])
		draw_colored_polygon(crown, accent.darkened(0.25))
		draw_polyline(crown, accent, 1.8, true)
		draw_circle(center + Vector2(0, -radius * 0.05), radius * 0.16, accent.lightened(0.5))

func _draw_campaign_route() -> void:
	var compact := screen_size.x <= 480.0
	_center_text(_campaign_universe_name(campaign_universe), 104.0, 17 if compact else 25, Color("#fff0b9"))
	_center_text("ВСЕЛЕННАЯ %02d  •  30 ПЛАНЕТ" % (campaign_universe + 1), 128.0, 10, Color("#c4edff"))
	var planet_origin := Vector2(screen_size.x * 0.5, 190.0 if compact else 225.0)
	draw_circle(planet_origin, 42.0 if compact else 66.0, Color("#2a9ed1"))
	draw_circle(planet_origin + Vector2(-13.0, -15.0), 13.0 if compact else 20.0, Color(1,1,1,0.18))
	draw_arc(planet_origin + Vector2(0, 5), 39.0 if compact else 62.0, 0.2, 2.7, 64, Color("#165b9b"), 6.0 if compact else 9.0, true)
	for island in [Vector2(-18,-4), Vector2(16,13), Vector2(-4,25)]:
		draw_circle(planet_origin + island * (1.0 if compact else 1.5), 7.0 if compact else 12.0, Color("#8de5b5"))
	var panel_top := 252.0 if compact else 326.0
	var panel_bottom := screen_size.y - 24.0
	var panel := Rect2(14.0, panel_top, screen_size.x - 28.0, panel_bottom - panel_top)
	_draw_soft_panel(panel, Color("#102f68"), Color("#55ddff"), 18, 8)
	draw_string(font, panel.position + Vector2(12, 24), "ПУТЬ К ВЕРШИНЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11 if compact else 16, Color("#ffffff"))
	draw_string(font, panel.position + Vector2(12, 43), "30 планет • боссы на рубежах 010 / 020 / 030", HORIZONTAL_ALIGNMENT_LEFT, -1, 7 if compact else 10, Color("#c4edff"))
	var achievement_summary: Dictionary = CampaignAchievements.get_summary(campaign_progress, campaign_universe)
	var achievement_items: Array = achievement_summary.get("achievements", [])
	var next_achievement: Dictionary = {}
	for achievement in achievement_items:
		if not bool(achievement.get("unlocked", false)):
			next_achievement = achievement
			break
	var achievement_count := int(achievement_summary.get("unlocked_count", 0))
	var achievement_total := int(achievement_summary.get("total_count", 0))
	var milestone_label := "ВСЕ РУБЕЖИ ПРОЙДЕНЫ" if next_achievement.is_empty() else "СЛЕДУЮЩАЯ ОТМЕТКА: %s • %02d" % [str(next_achievement.get("title", "РУБЕЖ")), int(next_achievement.get("planet_in_universe", 0))]
	draw_string(font, panel.position + Vector2(12, 59), "%s  (%d/%d)" % [milestone_label, achievement_count, achievement_total], HORIZONTAL_ALIGNMENT_LEFT, -1, 7 if compact else 9, Color("#ffd77a"))
	campaign_node_rects.clear()
	var node_area_top := panel.position.y + 83.0
	var node_area_height := maxf(100.0, panel.size.y - 112.0)
	campaign_route_scroll_viewport_rect = Rect2(panel.position.x + 8.0, node_area_top - 14.0, panel.size.x - 16.0, node_area_height + 20.0)
	var step_y := 70.0 if compact else 86.0
	var content_height := step_y * 14.0 + 80.0
	campaign_route_scroll_max = maxf(0.0, content_height - node_area_height)
	campaign_route_scroll_offset = clampf(campaign_route_scroll_offset, 0.0, campaign_route_scroll_max)
	# Scroll offset is climb progress: zero shows Planet 001 at the bottom;
	# swiping upward moves the camera toward the final boss at the top.
	var visual_offset := campaign_route_scroll_max - campaign_route_scroll_offset
	var positions: Array[Vector2] = []
	for index in range(30):
		var pair_row := index / 2
		var row := 14 - pair_row
		var col := index % 2 if pair_row % 2 == 0 else 1 - (index % 2)
		var x := panel.position.x + panel.size.x * (0.29 if col == 0 else 0.71)
		var y := node_area_top + float(row) * step_y - visual_offset
		positions.append(Vector2(x, y))
	var clip_rect := campaign_route_scroll_viewport_rect
	for index in range(29):
		var a: Vector2 = positions[index]
		var b: Vector2 = positions[index + 1]
		var bounds := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y))).grow(8.0)
		if bounds.intersects(clip_rect):
			draw_line(a, b, Color("#5c91c4"), 2.0)
	for index in range(30):
		var pos := positions[index]
		var node_id := _campaign_global_planet_id(campaign_universe, index + 1)
		var node_status := campaign_progress.get_planet_status(node_id) if campaign_progress != null else ("current" if node_id == 1 else "locked")
		var unlocked := node_status == "current"
		var completed := node_status == "completed"
		var boss := (index + 1) % 10 == 0
		var milestone := (index + 1) in [5, 15, 25]
		var node_radius := (12.0 if compact else 17.0) if milestone or boss else (10.0 if compact else 14.0)
		var node_rect := Rect2(pos - Vector2.ONE * (node_radius + 5.0), Vector2.ONE * (node_radius + 5.0) * 2.0)
		campaign_node_rects.append(node_rect)
		if not clip_rect.grow(22.0).has_point(pos):
			continue
		draw_circle(pos, node_radius + (5.0 if boss else 2.0), Color("#371d43") if boss else Color("#102d58"))
		draw_circle(pos, node_radius, Color("#145d61") if completed else (Color("#9a6b22") if unlocked else (Color("#543052") if boss else Color("#193e70"))))
		var node_accent := Color("#8ef4d3") if completed else (Color("#ffd05a") if unlocked else (Color("#ff8fbd") if boss else (Color("#55ddff") if milestone else Color("#496b9c"))))
		draw_arc(pos, node_radius, 0.0, TAU, 32, node_accent, 2.0 if not boss else 3.0, true)
		if completed:
			draw_line(pos + Vector2(-4,0), pos + Vector2(-1,4), Color("#ffffff"), 2.0)
			draw_line(pos + Vector2(-1,4), pos + Vector2(5,-4), Color("#ffffff"), 2.0)
		elif unlocked:
			draw_circle(pos, 3.0, Color("#ffffff"))
		elif boss:
			draw_line(pos + Vector2(-4,-4), pos + Vector2(4,4), Color("#ff8fbd"), 2.0)
			draw_line(pos + Vector2(4,-4), pos + Vector2(-4,4), Color("#ff8fbd"), 2.0)
		draw_string(font, pos + Vector2(-14, node_radius + 14), "%03d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 28, 8 if compact else 10, Color("#d7eaff"))
	if campaign_route_scroll_max > 0.5:
		var track := Rect2(panel.end.x - 8.0, node_area_top, 2.0, node_area_height)
		var thumb_height := maxf(28.0, track.size.y * node_area_height / content_height)
		var progress := campaign_route_scroll_offset / campaign_route_scroll_max
		var thumb_y := track.position.y + (track.size.y - thumb_height) * (1.0 - progress)
		draw_line(track.position, Vector2(track.position.x, track.end.y), Color(0.42, 0.62, 0.82, 0.28), 2.0, true)
		draw_line(Vector2(track.position.x, thumb_y), Vector2(track.position.x, thumb_y + thumb_height), Color("#8fe8ff"), 3.0, true)
	_center_text("ПРОВЕДИ ВВЕРХ — ПОДНИМАЙСЯ К ФИНАЛЬНОМУ БОССУ", screen_size.y - 7.0, 8, Color("#b9eaff"))


func _campaign_briefing_lines(value: String, max_chars: int, max_lines: int) -> Array[String]:
	var words := value.split(" ", false)
	var result: Array[String] = []
	var current := ""
	for word in words:
		var candidate := word if current.is_empty() else current + " " + word
		if candidate.length() > max_chars and not current.is_empty():
			result.append(current)
			current = word
			if result.size() >= max_lines:
				break
		else:
			current = candidate
	if result.size() < max_lines and not current.is_empty():
		result.append(current)
	return result

func _draw_campaign_planet() -> void:
	var node_id := _campaign_global_planet_id(campaign_universe, campaign_planet)
	var definition: Dictionary = campaign_progress.get_planet_definition(node_id) if campaign_progress != null else {"target_lines": 8, "reward_marks": 1}
	var planet_status := campaign_progress.get_planet_status(node_id) if campaign_progress != null else ("current" if node_id == 1 else "locked")
	var unlocked := planet_status == "current"
	var completed := planet_status == "completed"
	var compact := screen_size.x <= 480.0
	var authored_title := str(definition.get("title", "ПЛАНЕТА %03d" % node_id))
	var briefing := str(definition.get("briefing", "Выполни задание и продолжи путешествие."))
	_center_text("ПЛАНЕТА %03d" % node_id, 96.0 if compact else 104.0, 20 if compact else 24, Color("#fff0b9"))
	_center_text(authored_title, 124.0 if compact else 136.0, 13 if compact else 18, Color("#ffffff"))
	_center_text(_campaign_universe_name(campaign_universe), 146.0 if compact else 160.0, 9 if compact else 10, Color("#c4edff"))
	var center := Vector2(screen_size.x * 0.5, screen_size.y * 0.30)
	draw_circle(center, 80.0 if compact else 88.0, Color(0.25,0.72,1.0,0.08))
	draw_arc(center, 67.0 if compact else 73.0, 0.1, TAU + 0.1, 72, Color(0.72,0.9,1.0,0.62), 2.0, true)
	draw_circle(center, 49.0 if compact else 54.0, Color("#2a9ed1"))
	draw_circle(center + Vector2(-15,-16), 14.0, Color(1,1,1,0.18))
	draw_arc(center + Vector2(0,5), 47.0, 0.2, 2.7, 64, Color("#165b9b"), 7.0, true)
	for island in [Vector2(-22,-5),Vector2(16,13),Vector2(-4,30)]:
		draw_circle(center + island, 9.0, Color("#8de5b5"))
	var info_top := screen_size.y * (0.48 if compact else 0.49)
	var info_height := 178.0 if compact else 184.0
	var info := Rect2(16.0 if compact else 20.0, info_top, screen_size.x - (32.0 if compact else 40.0), info_height)
	_draw_soft_panel(info, Color("#102f68"), Color("#55ddff"), 17, 7)
	draw_string(font, info.position + Vector2(13,21), "ЦЕЛЬ УРОВНЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#55ddff"))
	var boss_type := str(definition.get("boss_type", "none"))
	var objective_type := str(definition.get("objective_type", "lines"))
	var objective_label := "БОСС • СОВМЕЩЁННОЕ ИСПЫТАНИЕ" if objective_type == "boss_combo" else ("ВЫЖИВИ ПОД НАПРЯЖЕНИЕМ" if objective_type == "survive" else ("НАБЕРИ ОЧКИ" if objective_type == "score" else "ОЧИСТИ ЛИНИИ"))
	if boss_type == "final":
		objective_label = "ФИНАЛЬНЫЙ БОСС • ИСПЫТАНИЕ МАСТЕРСТВА"
	draw_string(font, info.position + Vector2(13,43), objective_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9 if compact else 10, Color("#ffb4d2") if boss_type != "none" else Color("#ffffff"))
	var briefing_lines := _campaign_briefing_lines(briefing, 43 if compact else 78, 3)
	for index in range(briefing_lines.size()):
		draw_string(font, info.position + Vector2(13,68.0 + index * 14.0), briefing_lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 8 if compact else 10, Color("#d9edff"))
	var requirement := ""
	if int(definition.get("target_lines", 0)) > 0:
		requirement = "ЛИНИИ %d" % int(definition.target_lines)
	if int(definition.get("target_score", 0)) > 0:
		requirement += "  •  ОЧКИ %d" % int(definition.target_score)
	if int(definition.get("target_survive_seconds", 0)) > 0:
		requirement = "ВЫЖИВИ %d СЕКУНД" % int(definition.target_survive_seconds)
	if requirement.is_empty():
		requirement = "ВЫПОЛНИ ЗАДАНИЕ"
	draw_string(font, info.position + Vector2(13,info_height - 22.0), requirement + "  •  +" + str(definition.get("reward_marks", 1)) + " МЕТОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 8 if compact else 9, Color("#ffd05a"))
	if str(definition.get("event_status", "none")) == "live_campaign_piece":
		draw_string(font, info.position + Vector2(13,info_height - 6.0), "ОСОБАЯ ФИГУРА  •  ГРУЗОВОЙ КРЮК", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ffd05a"))
	elif boss_type != "none":
		draw_string(font, info.position + Vector2(13,info_height - 6.0), "КОМАНДИР  •  " + str(definition.get("boss_name", "СТРАЖ")), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ffb4d2"))
	var milestone_achievement: Dictionary = {}
	var universe_achievements: Array[Dictionary] = CampaignAchievements.get_achievements(campaign_progress, campaign_universe)
	for achievement in universe_achievements:
		if int(achievement.get("required_planet", -1)) == node_id:
			milestone_achievement = achievement
			break
	if not milestone_achievement.is_empty():
		var reward_rect := Rect2(info.position.x, info.end.y + 9.0, info.size.x, 48.0)
		var reward_unlocked := bool(milestone_achievement.get("unlocked", false))
		var reward_edge := Color("#8ef4d3") if reward_unlocked else Color("#ffd05a")
		_draw_soft_panel(reward_rect, Color("#145b59") if reward_unlocked else Color("#59451f"), reward_edge, 12, 5)
		var reward_status := "ОТМЕТКА ПОЛУЧЕНА" if reward_unlocked else "НАГРАДА ЗА РУБЕЖ"
		draw_string(font, reward_rect.position + Vector2(11.0, 17.0), reward_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, reward_edge)
		draw_string(font, reward_rect.position + Vector2(11.0, 35.0), str(milestone_achievement.get("title", "ЗНАК ПУТИ")) + "  •  " + str(milestone_achievement.get("reward_label", "Знак пути")), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ffffff"))
	campaign_start_rect = Rect2(24.0, screen_size.y * 0.75, screen_size.x - 48.0, 54.0)
	_draw_soft_panel(campaign_start_rect, Color("#1767c8") if unlocked else Color("#344c70"), Color("#55ddff") if unlocked else Color("#657c9a"), 17, 7)
	_center_text_in_rect("НАЧАТЬ УРОВЕНЬ" if unlocked else ("УРОВЕНЬ ПРОЙДЕН" if completed else "УРОВЕНЬ ЗАКРЫТ"), campaign_start_rect, 12, Color("#ffffff"))
	_center_text("ПРОГРЕСС ОТКРЫТИЯ БУДЕТ СОХРАНЯТЬСЯ", screen_size.y * 0.87, 8, Color("#b9eaff"))


func _draw_mode_select() -> void:
	var layout := _mode_select_layout(screen_size)
	_draw_soft_panel(secondary_back_rect, Color("#155c9c"), Color("#7bdfff"), 14, 6)
	draw_string(font, secondary_back_rect.position + Vector2(12.0, 27.0), "‹  ДОМОЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffffff"))
	_center_text("ВЫБЕРИ РЕЖИМ", layout.title_y, 29, Color("#fff0b9"))
	_center_text("СОБЕРИ КОМБО И ПОЗНАКОМЬСЯ С BUDDY!", layout.subtitle_y, 11, Color("#c4edff"))
	_draw_mode_card(classic_mode_rect, "1  •  КЛАССИКА", "Играй в своём ритме и набирай очки.", Color("#42d9ff"))
	_draw_mode_card(sprint_mode_rect, "2  •  СПРИНТ", "Очисти 40 линий на скорость.", Color("#ffca52"))
	_draw_mode_card(marathon_mode_rect, "3  •  МАРАФОН", "Большое испытание на 100 линий.", Color("#ff8b79"))
	_center_text("НАЖМИ НА КАРТОЧКУ  •  1 / 2 / 3", layout.instruction_y, 12, Color("#b7eaff"))
func _draw_mode_card(rect: Rect2, title: String, description: String, accent: Color) -> void:
	var fill := Color("#1355a8") if accent == Color("#42d9ff") else (Color("#7347a8") if accent == Color("#ff8b79") else Color("#9a5b19"))
	_draw_soft_panel(rect, fill, accent.lightened(0.25), 22, 12)
	draw_circle(rect.position + Vector2(rect.size.x - 26.0, 23.0), 8.0, Color(accent.r, accent.g, accent.b, 0.22))
	draw_string(font, rect.position + Vector2(18.0, 36.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))
	draw_string(font, rect.position + Vector2(18.0, 64.0), description, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f0f5ff"))
func _is_line_objective_mode() -> bool:
	return mode_session != null and (int(mode_session.rules.get("target_lines", 0)) > 0 or int(mode_session.rules.get("target_score", 0)) > 0 or float(mode_session.rules.get("target_survive_seconds", 0)) > 0.0)

func _objective_progress_ratio() -> float:
	if not _is_line_objective_mode():
		return 0.0
	if campaign_run_active and mode_session.has_boss_phases():
		var phase: Dictionary = mode_session.boss_phase_progress(_active_lines(), _active_score())
		var phase_lines := int(phase.get("target_lines", 0))
		var phase_score := int(phase.get("target_score", 0))
		var line_ratio := 1.0 if phase_lines <= 0 else clampf(float(phase.get("lines", 0)) / float(phase_lines), 0.0, 1.0)
		var score_ratio := 1.0 if phase_score <= 0 else clampf(float(phase.get("score", 0)) / float(phase_score), 0.0, 1.0)
		return minf(line_ratio, score_ratio)
	var target_survive := float(mode_session.rules.get("target_survive_seconds", 0))
	if target_survive > 0.0:
		return clampf(mode_session.elapsed_seconds / target_survive, 0.0, 1.0)
	var target_lines := int(mode_session.rules.get("target_lines", 0))
	var target_score := int(mode_session.rules.get("target_score", 0))
	var line_ratio := 1.0 if target_lines <= 0 else clampf(float(_active_lines()) / float(target_lines), 0.0, 1.0)
	var score_ratio := 1.0 if target_score <= 0 else clampf(float(_active_score()) / float(target_score), 0.0, 1.0)
	return minf(line_ratio, score_ratio)

func _format_elapsed_time(total_seconds: float) -> String:
	var safe_seconds := maxi(0, floori(total_seconds))
	var minutes := safe_seconds / 60
	var seconds := safe_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _draw_stats() -> void:
	# Wider, balanced HUD cards keep values readable on narrow portrait screens.
	var top := 56.0
	var outer := 18.0
	var gap := 14.0
	var card_width := (screen_size.x - outer * 2.0 - gap) * 0.5
	var card_height := 52.0
	var score_value := block_run_session.score if block_run_active and block_run_session != null else _active_score()
	var synergy_count := block_run_session.encounter.active_synergies().size() if block_run_active and block_run_session != null else 0
	var score_label := "ОЧКИ" if synergy_count == 0 else "ОЧКИ • СИН. %d" % synergy_count
	var score_display := str(score_value)
	var campaign_score_target := int(mode_session.rules.get("target_score", 0)) if campaign_run_active and mode_session != null else 0
	var campaign_survive_target := float(mode_session.rules.get("target_survive_seconds", 0)) if campaign_run_active and mode_session != null else 0.0
	if campaign_score_target > 0:
		score_label = "ОЧКИ / ЦЕЛЬ"
		score_display = "%d / %d" % [score_value, campaign_score_target]
	var score_rect := Rect2(outer, top, card_width, card_height)
	_stat_card(score_rect, score_label, score_display, Color("#45d9f5"))
	if campaign_score_target > 0:
		var score_track := Rect2(score_rect.position + Vector2(12.0, 46.0), Vector2(score_rect.size.x - 24.0, 3.0))
		draw_rect(score_track, Color(0.12, 0.19, 0.27, 1.0))
		var score_ratio := clampf(float(score_value) / float(campaign_score_target), 0.0, 1.0)
		if score_ratio > 0.0:
			draw_rect(Rect2(score_track.position, Vector2(score_track.size.x * score_ratio, score_track.size.y)), Color("#45d9f5"))
	var progress_rect := Rect2(outer + card_width + gap, top, card_width, card_height)
	if block_run_active and block_run_session != null:
		var encounter = block_run_session.encounter
		var attack_label := "%dС" % encounter.next_attack_seconds
		var encounter_label := "БОСС • %s" % attack_label if encounter.boss else "К%d • Э%d • %s" % [encounter.room, encounter.floor, attack_label]
		_stat_card(progress_rect, encounter_label, "ВР %d / %d" % [encounter.enemy_hp, encounter.enemy_max_hp], Color("#ff9b57"))
		var hp_ratio := clampf(float(encounter.enemy_hp) / float(maxi(1, encounter.enemy_max_hp)), 0.0, 1.0)
		var hp_track := Rect2(progress_rect.position + Vector2(12.0, 46.0), Vector2(progress_rect.size.x - 24.0, 3.0))
		draw_rect(hp_track, Color(0.12, 0.19, 0.27, 1.0))
		if hp_ratio > 0.0:
			draw_rect(Rect2(hp_track.position, Vector2(hp_track.size.x * hp_ratio, hp_track.size.y)), Color("#ff9b57"))
	elif _is_line_objective_mode():
		var target := int(mode_session.rules.get("target_lines", 0))
		var score_target := int(mode_session.rules.get("target_score", 0))
		var survive_target := float(mode_session.rules.get("target_survive_seconds", 0))
		var elapsed_label := _format_elapsed_time(mode_session.elapsed_seconds)
		var mode_label := _mode_display_name(mode_session.mode_id)
		var objective_value := "%d / %d" % [mini(_active_lines(), target), target] if target > 0 else ("%d / %d СЕК" % [mini(floori(mode_session.elapsed_seconds), int(survive_target)), int(survive_target)] if survive_target > 0.0 else "%d / %d" % [mini(_active_score(), score_target), score_target])
		if campaign_run_active and mode_session.has_boss_phases():
			var phase_progress: Dictionary = mode_session.boss_phase_progress(_active_lines(), _active_score())
			mode_label = "ФАЗА %d/%d • %s" % [int(phase_progress.get("index", 1)), int(phase_progress.get("count", 3)), str(phase_progress.get("title", "БОСС")).left(9)]
			var phase_lines := int(phase_progress.get("target_lines", 0))
			var phase_score := int(phase_progress.get("target_score", 0))
			if phase_lines > 0 and phase_score > 0:
				objective_value = "Л %d/%d  О %d/%d" % [int(phase_progress.get("lines", 0)), phase_lines, int(phase_progress.get("score", 0)), phase_score]
			elif phase_lines > 0:
				objective_value = "ЛИНИИ %d/%d" % [int(phase_progress.get("lines", 0)), phase_lines]
			else:
				objective_value = "ОЧКИ %d/%d" % [int(phase_progress.get("score", 0)), phase_score]
		_stat_card(progress_rect, mode_label + " • " + elapsed_label, objective_value, Color("#ff9b57") if campaign_run_active and mode_session.has_boss_phases() else Color("#f6d65b"))
		var track := Rect2(progress_rect.position + Vector2(12.0, 46.0), Vector2(progress_rect.size.x - 24.0, 3.0))
		draw_rect(track, Color(0.12, 0.19, 0.27, 1.0))
		if _objective_progress_ratio() > 0.0:
			draw_rect(Rect2(track.position, Vector2(track.size.x * _objective_progress_ratio(), track.size.y)), Color("#45d9f5"))
	else:
		_stat_card(progress_rect, "УРОВЕНЬ / ЛИНИИ", "%d / %d" % [_active_level(), _active_lines()], Color("#f6d65b"))

func _stat_label_font_size(rect: Rect2, label: String) -> int:
	# Choose the largest readable label size that fits before the accent marker.
	var available_width := maxf(24.0, rect.size.x - 38.0)
	for candidate in [12, 11, 10]:
		if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, candidate).x <= available_width:
			return candidate
	return 10

func _stat_card(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_soft_panel(rect, Color("#124b99"), accent.lightened(0.18), 15, 4)
	var label_size := _stat_label_font_size(rect, label)
	draw_string(font, rect.position + Vector2(12, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color("#d9f0ff"))
	draw_string(font, rect.position + Vector2(12, 41), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))
	draw_circle(rect.position + Vector2(rect.size.x - 14.0, 14.0), 4.5, accent)
func _block_run_goal_ratio(goal: Dictionary) -> float:
	var target := maxi(1, int(goal.get("target", 1)))
	return clampf(float(goal.get("value", 0)) / float(target), 0.0, 1.0)

func _block_run_goal_short_label(goal: Dictionary) -> String:
	match str(goal.get("type", "")):
		"lines": return "ЛИНИИ"
		"score": return "ОЧКИ"
		"survive": return "ВРЕМЯ"
		"level": return "УРОВЕНЬ"
	return "ЦЕЛЬ"

func _draw_block_run_goals() -> void:
	var states := block_run_session.goal_states()
	if states.is_empty():
		return
	# Compact 28px goal strip sits above the 72px preview row, including on 360x800 phones.
	var top := board_rect.position.y - 122.0
	var gap := 10.0
	var outer := 18.0
	var width := (screen_size.x - outer * 2.0 - gap * 2.0) / 3.0
	for index in range(mini(3, states.size())):
		var goal: Dictionary = states[index]
		var rect := Rect2(outer + index * (width + gap), top, width, 24.0)
		var ratio := _block_run_goal_ratio(goal)
		_draw_soft_panel(rect, Color("#0b2850"), Color("#3d82b5"), 8, 1)
		var label := _block_run_goal_short_label(goal)
		var progress := "%d/%d" % [int(goal.get("value", 0)), int(goal.get("target", 1))]
		var reward := "+%d" % int(goal.get("reward", 0))
		draw_string(font, rect.position + Vector2(6.0, 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a9d8f2"))
		var progress_width := font.get_string_size(progress, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(font, rect.position + Vector2(rect.size.x - progress_width - 5.0, 10.0), progress, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffffff"))
		var track_width := maxf(18.0, rect.size.x - 48.0)
		var track := Rect2(rect.position + Vector2(6.0, 14.0), Vector2(track_width, 2.0))
		draw_rect(track, Color("#1b3b60"))
		if ratio > 0.0:
			draw_rect(Rect2(track.position, Vector2(track.size.x * ratio, track.size.y)), Color("#45d9f5"))
		draw_string(font, rect.position + Vector2(rect.size.x - 34.0, 23.0), reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#f6d65b"))

func _draw_piece_previews() -> void:
	var card_height := 72.0
	var top := board_rect.position.y - card_height - 22.0
	if block_run_active:
		var slot_outer := 14.0
		var slot_gap := 12.0
		var slot_width := minf((screen_size.x - slot_outer * 2.0 - slot_gap * 2.0) / 3.0, 164.0)
		var total_width := slot_width * 3.0 + slot_gap * 2.0
		var start_x := (screen_size.x - total_width) * 0.5
		hold_rect = Rect2(start_x, top, slot_width, card_height)
		block_run_skill_rect = Rect2(start_x + (slot_width + slot_gap) * 2.0, top, slot_width, card_height)
		_draw_preview_card(hold_rect, "ЗАПАС", _active_held_piece_id())
		_draw_preview_card(Rect2(start_x + slot_width + slot_gap, top, slot_width, card_height), "ДАЛЕЕ", _active_next_piece_id())
		_draw_block_run_skill_card(block_run_skill_rect)
	else:
		var card_width := minf(164.0, (screen_size.x - 36.0 - 14.0) * 0.5)
		var gap := 14.0
		var total_width := card_width * 2.0 + gap
		var start_x := (screen_size.x - total_width) * 0.5
		hold_rect = Rect2(start_x, top, card_width, card_height)
		block_run_skill_rect = Rect2()
		_draw_preview_card(hold_rect, "ЗАПАС", _active_held_piece_id())
		_draw_preview_card(Rect2(start_x + card_width + gap, top, card_width, card_height), "ДАЛЕЕ", _active_next_piece_id())

func _draw_drop_button() -> void:
	if drop_rect.size.x < 42.0:
		return
	var enabled := not paused and not _active_game_over() and not _mode_finished() and not _block_run_draft_is_open()
	var fill := Color("#e9782d") if enabled else Color("#35445a")
	var edge := Color("#ffe0a0") if enabled else Color("#8294a9")
	_draw_soft_panel(drop_rect, fill, edge, 15, 8)
	var label_size := 12 if drop_rect.size.x >= 72.0 else 9
	var label_width := font.get_string_size("DROP", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	draw_colored_polygon(PackedVector2Array([
		Vector2(drop_rect.get_center().x - 7.0, drop_rect.position.y + 9.0),
		Vector2(drop_rect.get_center().x + 7.0, drop_rect.position.y + 9.0),
		Vector2(drop_rect.get_center().x, drop_rect.position.y + 18.0)
	]), Color("#fff7e8") if enabled else Color("#c8d2df"))
	draw_string(font, drop_rect.get_center() + Vector2(-label_width * 0.5, 40.0), "DROP", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color("#fff8ed") if enabled else Color("#d0d8e4"))

func _hero_display_name(hero_id: String) -> String:
	match hero_id:
		"plush": return "ПЛЮШ"
		"prism": return "ПРИЗМА"
		"blip": return "БЛИП"
		"pixel": return "ПИКСЕЛЬ"
		"spark": return "ИСКРА"
		_: return "ГЕРОЙ"

func _draw_block_run_skill_card(rect: Rect2) -> void:
	if not block_run_active or block_run_session == null:
		block_run_skill_rect = Rect2()
		return
	var ready := block_run_hero_level >= 5 and block_run_session.hero_skill_cooldown_seconds <= 0 and block_run_session.status == BlockRunSession.STATUS_RUNNING and not paused and not _block_run_draft_is_open()
	var unlocked := block_run_hero_level >= 5
	var remaining := block_run_session.hero_skill_cooldown_seconds
	var hero_label := _hero_display_name(block_run_hero_id)
	var state := "ЗАКРЫТО · УР. 5" if not unlocked else ("ГОТОВО · ТАП" if ready else "ОТКАТ · %d С" % remaining)
	var accent := Color("#ffd45c") if ready else (Color("#66839e") if not unlocked else Color("#43b7dc"))
	var pulse := 0.5 + 0.5 * sin(ambient_time * 4.2)
	if ready:
		var glow := Color("#ffd45c")
		glow.a = 0.12 + pulse * 0.12
		_draw_soft_panel(rect.grow(2.0), glow, Color("#ffd45c", 0.25 + pulse * 0.45), 16, 11)
	_draw_soft_panel(rect, Color("#102e4b") if ready else Color("#0b1d31"), accent, 15, 5)
	var icon_center := Vector2(rect.end.x - 16.0, rect.position.y + 17.0)
	if ready:
		draw_circle(icon_center, 11.0 + pulse * 1.2, Color("#ffcf4d", 0.16 + pulse * 0.12))
		draw_circle(icon_center, 8.0, Color("#7d5312"))
		draw_string(font, icon_center + Vector2(-5.0, 5.0), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff2b0"))
	else:
		draw_circle(icon_center, 8.0, Color("#29465f"))
		draw_string(font, icon_center + Vector2(-4.0, 4.0), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent)
	draw_string(font, rect.position + Vector2(8.0, 17.0), hero_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f4f8ff"))
	draw_string(font, rect.position + Vector2(8.0, 37.0), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 9 if ready else 8, accent)

func _draw_preview_card(rect: Rect2, label: String, piece_type: int) -> void:
	_draw_soft_panel(rect, Color("#17488a"), Color("#71cfff"), 15, 3)
	# Keep the label in a dedicated upper-left lane; center the tetromino in the
	# lower-right lane so labels and piece cells never collide on 360px screens.
	draw_string(font, rect.position + Vector2(9, 19), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9f4ff"))
	if piece_type < 0:
		draw_string(font, rect.position + Vector2(rect.size.x - 28.0, 43), "—", HORIZONTAL_ALIGNMENT_CENTER, 30, 18, Color("#b7dfff"))
		return
	var cells: Array = CampaignSpecialPiece.cells_for_rotation(0) if piece_type == 7 else BlockBuddiesModel.SHAPES[piece_type]
	var min_x := 999
	var min_y := 999
	var max_x := -999
	var max_y := -999
	for cell_pos in cells:
		min_x = mini(min_x, cell_pos.x)
		min_y = mini(min_y, cell_pos.y)
		max_x = maxi(max_x, cell_pos.x)
		max_y = maxi(max_y, cell_pos.y)
	# Fit the actual tetromino bounds instead of reserving a fixed 4x4 square.
	# Compact shapes (T/L/O) become noticeably larger; tall I pieces still fit safely.
	var shape_width := float(max_x - min_x + 1)
	var shape_height := float(max_y - min_y + 1)
	var mini_cell := minf(16.0, minf((rect.size.x - 40.0) / shape_width, (rect.size.y - 30.0) / shape_height))
	var piece_size := Vector2(shape_width * mini_cell, shape_height * mini_cell)
	var piece_origin := Vector2(rect.position.x + rect.size.x - 30.0, rect.position.y + rect.size.y * 0.67) - piece_size * 0.5
	for cell_pos in cells:
		var mini_rect := Rect2(piece_origin + Vector2(cell_pos.x - min_x, cell_pos.y - min_y) * mini_cell, Vector2.ONE * mini_cell).grow(-0.7)
		if piece_type == 7:
			_draw_campaign_special_block(mini_rect)
		else:
			_draw_block(mini_rect, BlockBuddiesModel.PALETTE[piece_type])
func _draw_board() -> void:
	var frame := board_rect.grow(13)
	_draw_soft_panel(frame.grow(3), Color("#103d83"), Color("#9aeaff"), 24, 18)
	_draw_soft_panel(board_rect.grow(3), Color("#071b45"), Color("#4eaaff"), 15, 8)
	var cell := board_rect.size.x / BOARD_W
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var rect := Rect2(board_rect.position + Vector2(x, y) * cell, Vector2.ONE * cell).grow(-1.0)
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = Color("#081b40")
			empty_style.set_corner_radius_all(4)
			empty_style.set_border_width_all(1)
			empty_style.border_color = Color("#174276")
			draw_style_box(empty_style, rect)
			var tile: int = _active_grid()[y][x]
			if tile == 7:
				_draw_campaign_special_block(rect.grow(-0.5))
			elif tile >= 0:
				_draw_block(rect.grow(-0.5), BlockBuddiesModel.PALETTE[tile])
	var ghost := _campaign_ghost_origin() if _campaign_runtime_active() else game.ghost_origin()
	var rendered_cells: Array = campaign_piece_runtime.active_cells if _campaign_runtime_active() else game.active_cells
	for cell_pos in rendered_cells:
		var p: Vector2i = ghost + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-2.0)
			_draw_soft_panel(rect, Color(0.55, 0.83, 1.0, 0.10), Color(0.65, 0.91, 1.0, 0.24), 6, 0)
	for cell_pos in rendered_cells:
		var active_origin: Vector2i = campaign_piece_runtime.origin if _campaign_runtime_active() else game.origin
		var p: Vector2i = active_origin + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-1.3)
			if _campaign_runtime_active() and campaign_piece_runtime.active_piece_id == 7:
				_draw_campaign_special_block(rect)
			else:
				_draw_block(rect, BlockBuddiesModel.PALETTE[game.active_type if not _campaign_runtime_active() else campaign_piece_runtime.active_piece_id])
	_draw_line_clear_feedback()
func _draw_line_clear_feedback() -> void:
	if clear_flash_time <= 0.0:
		return
	var strength := clampf(clear_flash_time / 0.72, 0.0, 1.0)
	var accent := Color("#ffcf65") if clear_flash_count >= 4 else Color("#62f2ff")
	var frame := board_rect.grow(13.0)
	draw_rect(frame.grow(2.0), Color(accent.r, accent.g, accent.b, 0.035 + strength * 0.12), false, 2.0)
	# Keep the celebration on the cabinet frame so it never covers the
	# preview cards, active piece, or touch targets.
	var edge_y := frame.position.y + 2.0
	draw_line(Vector2(frame.position.x + 8.0, edge_y), Vector2(frame.end.x - 8.0, edge_y), Color(accent.r, accent.g, accent.b, strength * 0.72), 2.0)

func _draw_block(rect: Rect2, color: Color) -> void:
	_draw_soft_panel(rect, color.darkened(0.08), color.lightened(0.52), 6, 5)
	var shine := StyleBoxFlat.new()
	shine.bg_color = Color(1, 1, 1, 0.22)
	shine.set_corner_radius_all(4)
	draw_style_box(shine, Rect2(rect.position + Vector2(3, 2), Vector2(rect.size.x - 6, maxf(3.0, rect.size.y * 0.18))))
	draw_circle(rect.position + Vector2(rect.size.x - 6, 6), 1.5, Color(1, 1, 1, 0.45))

func _draw_campaign_special_block(rect: Rect2) -> void:
	_draw_block(rect, Color("#25b8c8"))
	# Gold fastener keeps the live piece visually consistent with its approved preview.
	draw_circle(rect.position + Vector2(rect.size.x - 6.0, 6.0), 2.0, Color("#ffd05a"))
func _draw_pause_button() -> void:
	_draw_pill(pause_rect, Color("#1467bd"), Color("#a4eaff"), 12)
	var center := pause_rect.get_center()
	if paused:
		var triangle := PackedVector2Array([center + Vector2(-4, -8), center + Vector2(7, 0), center + Vector2(-4, 8)])
		draw_colored_polygon(triangle, Color("#ffffff"))
	else:
		_draw_pill(Rect2(center + Vector2(-7, -8), Vector2(5, 16)), Color("#ffffff"), Color("#d4f5ff"), 3)
		_draw_pill(Rect2(center + Vector2(2, -8), Vector2(5, 16)), Color("#ffffff"), Color("#d4f5ff"), 3)
func _draw_overlay_panel(rect: Rect2, accent: Color) -> void:
	_draw_soft_panel(rect.grow(2.0), Color("#154b91"), accent.lightened(0.2), 25, 18)
	draw_rect(Rect2(rect.position + Vector2(12, 10), Vector2(rect.size.x - 24, 5)), Color(1, 1, 1, 0.15))
func _block_run_draft_is_open() -> bool:
	return block_run_active and block_run_session != null and not block_run_session.pending_card_draft.is_empty()

func _select_block_run_draft(index: int) -> void:
	if not _block_run_draft_is_open() or index < 0 or index >= block_run_session.pending_card_draft.size():
		return
	var card_id := str(block_run_session.pending_card_draft[index].get("id", ""))
	if block_run_session.choose_card(card_id):
		gravity_clock = 0.0
		queue_redraw()

func _draw_block_run_draft() -> void:
	var cards := block_run_session.pending_card_draft
	var panel_width := minf(620.0, screen_size.x - 28.0)
	var panel_height := minf(620.0, screen_size.y - 36.0)
	var panel := Rect2(Vector2((screen_size.x - panel_width) * 0.5, (screen_size.y - panel_height) * 0.5), Vector2(panel_width, panel_height))
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.02, 0.08, 0.22, 0.78))
	_draw_overlay_panel(panel, Color("#ffd05a"))
	var title_y := panel.position.y + 52.0
	var title := "ВЫБЕРИ УСИЛЕНИЕ!"
	var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, Vector2(panel.get_center().x - title_width * 0.5, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#fff2bd"))
	var subtitle := "УРОВЕНЬ %d  •  ОДНА КАРТА ДЛЯ ТВОЕГО ЗАБЕГА" % block_run_session.level
	var subtitle_width := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, Vector2(panel.get_center().x - subtitle_width * 0.5, title_y + 25.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d5eeff"))
	block_run_draft_rects.clear()
	var gap := 10.0
	var card_top := title_y + 48.0
	var bottom_margin := 28.0
	var card_height := minf(132.0, (panel.end.y - bottom_margin - card_top - gap * 2.0) / 3.0)
	var accents := [Color("#44d9ff"), Color("#ffca52"), Color("#ff8ab5")]
	var fills := [Color("#1455a6"), Color("#885019"), Color("#773f9c")]
	for index in range(mini(3, cards.size())):
		var card: Dictionary = cards[index]
		var rect := Rect2(panel.position.x + 14.0, card_top + index * (card_height + gap), panel_width - 28.0, card_height)
		block_run_draft_rects.append(rect)
		_draw_soft_panel(rect, fills[index], accents[index], 19, 9)
		draw_circle(rect.position + Vector2(30.0, 34.0), 19.0, Color(1, 1, 1, 0.14))
		var icon_text := str(card.get("icon", "✦"))
		draw_string(font, rect.position + Vector2(16.0, 42.0), icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#fff3c5"))
		var card_id := str(card.get("id", ""))
		var current_rank := block_run_session.encounter.get_card_rank(card_id)
		var next_rank := mini(5, current_rank + 1)
		var card_title := str(card.get("name", card_id))
		var title_size := 16 if panel_width > 400.0 else 13
		draw_string(font, rect.position + Vector2(58.0, 29.0), card_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color("#ffffff"))
		var description := block_run_session.encounter.get_card_effect_description(card_id, next_rank)
		if description.is_empty():
			description = str(card.get("description", "Усиление карты"))
		draw_string(font, rect.position + Vector2(58.0, 54.0), description.left(58), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f0f5ff"))
		var rank_label := "НОВАЯ КАРТА" if current_rank == 0 else "РАНГ %d  →  %d ★" % [current_rank, next_rank]
		draw_string(font, rect.position + Vector2(58.0, 78.0), rank_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#fff0a8"))
		draw_string(font, rect.end - Vector2(28.0, 18.0), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffffff"))
	var hint := "НАЖМИ НА КАРТУ  •  КЛАВИШИ 1 / 2 / 3"
	var hint_width := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(panel.get_center().x - hint_width * 0.5, panel.end.y - 10.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d5eeff"))
func _draw_pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, 128.0), Vector2(320.0, 256.0))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#45d9f5"))
	_center_text("ПАУЗА", screen_size.y * 0.5 - 38.0, 34, Color("#f4f8ff"))
	_center_text("ЗАБЕГ ПРИОСТАНОВЛЕН", screen_size.y * 0.5 - 8.0, 13, Color("#83a3bd"))
	draw_rect(resume_rect, Color("#102c45"))
	draw_rect(resume_rect, Color("#45d9f5"), false, 2.0)
	var label := "ПРОДОЛЖИТЬ"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, resume_rect.get_center() + Vector2(-width * 0.5, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4f8ff"))

func _draw_mode_complete() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, 118.0), Vector2(320.0, 236.0))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#f6d65b"))
	var mode_name := _mode_display_name(mode_session.mode_id)
	var target := int(mode_session.rules.get("target_lines", 0))
	_center_text(mode_name + " • ВЫПОЛНЕНО", screen_size.y * 0.5 - 56.0, 23, Color("#f4f8ff"))
	if target > 0:
		_center_text("ОЧИЩЕНО ЛИНИЙ • %d" % target, screen_size.y * 0.5 - 22.0, 14, Color("#45d9f5"))
	elif float(mode_session.rules.get("target_survive_seconds", 0)) > 0.0:
		_center_text("ВЫЖИВИ • %d СЕКУНД" % int(mode_session.rules.get("target_survive_seconds", 0)), screen_size.y * 0.5 - 22.0, 14, Color("#45d9f5"))
	else:
		_center_text("ЦЕЛЬ ПО ОЧКАМ • %d" % int(mode_session.rules.get("target_score", 0)), screen_size.y * 0.5 - 22.0, 14, Color("#45d9f5"))
	_center_text("ВРЕМЯ  •  " + _format_elapsed_time(mode_session.elapsed_seconds), screen_size.y * 0.5 + 10.0, 15, Color("#f6d65b"))
	_center_text("ОЧКИ  •  %d" % _active_score(), screen_size.y * 0.5 + 42.0, 17, Color("#c0d3e2"))
	if campaign_run_active:
		_center_text("НАГРАДА  •  +%d МЕТОК" % campaign_last_reward_marks, screen_size.y * 0.5 + 72.0, 13, Color("#ffd05a"))
		_center_text("НАЖМИ, ЧТОБЫ ВЕРНУТЬСЯ К КАРТЕ", screen_size.y * 0.5 + 104.0, 10, Color("#b9eaff"))
	else:
		_center_text("НАЖМИ, ЧТОБЫ СЫГРАТЬ ЕЩЁ", screen_size.y * 0.5 + 88.0, 13, Color("#ffcf6b"))

func _game_over_title() -> String:
	return _mode_display_name(mode_session.mode_id) + " — НЕ ВЫПОЛНЕН" if _is_line_objective_mode() else "ИГРА ОКОНЧЕНА"

func _game_over_progress_label() -> String:
	if _is_line_objective_mode():
		var target_lines := int(mode_session.rules.get("target_lines", 0))
		var target_score := int(mode_session.rules.get("target_score", 0))
		var target_survive := float(mode_session.rules.get("target_survive_seconds", 0))
		if target_survive > 0.0:
			return "ВЫЖИВАНИЕ  •  %s / %s" % [_format_elapsed_time(mode_session.elapsed_seconds), _format_elapsed_time(target_survive)]
		if target_lines > 0 and target_score > 0:
			return "ЛИНИИ %d/%d  •  ОЧКИ %d/%d" % [mini(_active_lines(), target_lines), target_lines, mini(_active_score(), target_score), target_score]
		if target_score > 0:
			return "ОЧКИ  •  %d / %d" % [mini(_active_score(), target_score), target_score]
		return "ЛИНИИ  •  %d / %d" % [mini(_active_lines(), target_lines), target_lines]
	return "ОЧИЩЕНО ЛИНИЙ  •  %d" % _active_lines()

func _game_over_time_label() -> String:
	if _is_line_objective_mode():
		return "ВРЕМЯ  •  " + _format_elapsed_time(mode_session.elapsed_seconds)
	return ""

func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	if block_run_active and block_run_session != null:
		_draw_block_run_results()
		return
	var has_objective := _is_line_objective_mode()
	var panel_height := 320.0 if has_objective else 284.0
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, panel_height * 0.5), Vector2(320.0, panel_height))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#ff9b57"))
	if has_objective:
		_center_text(_game_over_title(), screen_size.y * 0.5 - 88.0, 29, Color("#f4f8ff"))
		_center_text(_game_over_progress_label(), screen_size.y * 0.5 - 44.0, 16, Color("#c0d3e2"))
		_center_text(_game_over_time_label(), screen_size.y * 0.5 - 8.0, 16, Color("#f6d65b"))
		_center_text("ОЧКИ  •  %d" % _active_score(), screen_size.y * 0.5 + 30.0, 20, Color("#45d9f5"))
		_center_text("ЕЩЁ ОДИН ЗАБЕГ?", screen_size.y * 0.5 + 91.0, 13, Color("#ffb477"))
	else:
		_center_text(_game_over_title(), screen_size.y * 0.5 - 70.0, 34, Color("#f4f8ff"))
		_center_text("ОЧКИ", screen_size.y * 0.5 - 30.0, 12, Color("#83a3bd"))
		_center_text(str(_active_score()), screen_size.y * 0.5 + 2.0, 28, Color("#45d9f5"))
		_center_text(_game_over_progress_label(), screen_size.y * 0.5 + 36.0, 13, Color("#c0d3e2"))
		_center_text("НАЖМИ, ЧТОБЫ НАЧАТЬ ЗАНОВО", screen_size.y * 0.5 + 88.0, 13, Color("#ffb477"))


func _draw_block_run_results() -> void:
	var panel_width := minf(360.0, screen_size.x - 36.0)
	var panel_height := 386.0
	var panel := Rect2(Vector2((screen_size.x - panel_width) * 0.5, (screen_size.y - panel_height) * 0.5), Vector2(panel_width, panel_height))
	_draw_overlay_panel(panel, Color("#ff9b57"))
	var session := block_run_session
	var room_text := "КОМНАТА %d  •  ЭТАЖ %d" % [session.encounter.room, session.encounter.floor]
	var elapsed := _format_elapsed_time(session.run_seconds)
	_center_text("ЗАБЕГ ЗАВЕРШЁН", panel.position.y + 48.0, 27, Color("#f4f8ff"))
	_center_text(room_text, panel.position.y + 82.0, 13, Color("#83a3bd"))
	_center_text("ОЧКИ", panel.position.y + 126.0, 11, Color("#83a3bd"))
	_center_text(str(session.score), panel.position.y + 160.0, 29, Color("#45d9f5"))
	_center_text("ЛИНИИ  •  %d     ВРЕМЯ  •  %s" % [session.total_lines, elapsed], panel.position.y + 198.0, 13, Color("#c0d3e2"))
	draw_line(Vector2(panel.position.x + 28.0, panel.position.y + 222.0), Vector2(panel.end.x - 28.0, panel.position.y + 222.0), Color(0.25, 0.52, 0.7, 0.5), 1.0)
	_center_text("НАГРАДЫ ЗА ВЫПОЛНЕННЫЕ ЦЕЛИ", panel.position.y + 254.0, 11, Color("#83a3bd"))
	_center_text("МОНЕТЫ  •  +%d" % session.goal_rewards_earned, panel.position.y + 289.0, 24, Color("#f6d65b"))
	_center_text("ЦЕЛЕЙ ВЫПОЛНЕНО  •  %d" % session.goal_reward_receipts.size(), panel.position.y + 316.0, 11, Color("#c0d3e2"))
	_center_text("НАЖМИ, ЧТОБЫ НАЧАТЬ НОВЫЙ ЗАБЕГ", panel.position.y + 360.0, 11, Color("#ffb477"))

func _center_text(value: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((screen_size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
