extends Node2D

const CELL := 38.0
const BOARD_W := 10
const BOARD_H := 23
const Model = preload("res://scripts/game_model.gd")
const Buddy = preload("res://scripts/buddy_companion.gd")
const ModeSession = preload("res://scripts/mode_session.gd")
const ModeCatalog = preload("res://scripts/mode_catalog.gd")
const BlockRunSession = preload("res://scripts/block_run_session.gd")
const BlockRunBridge = preload("res://scripts/block_run_bridge.gd")

var game: BlockBuddiesModel
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
var mode_select_visible := true
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

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	game = Model.new()
	game.reset()
	mode_session = ModeSession.new()
	buddy = Buddy.new()
	add_child(buddy)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_process(true)

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
	classic_mode_rect = mode_layout.classic
	sprint_mode_rect = mode_layout.sprint
	marathon_mode_rect = mode_layout.marathon
	if is_instance_valid(buddy):
		var buddy_layout := _buddy_layout_for_gutter(board_rect.position.x)
		buddy.scale = Vector2.ONE * buddy_layout.scale * 1.28
		# Anchor the companion flush to the left gutter; never let its sprite intrude into the board frame.
		buddy.position = Vector2(0.0, board_rect.position.y + 18.0)
		var result_overlay_visible := paused or game.game_over or (mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED)
		buddy.visible = buddy_layout.visible and not _block_run_draft_is_open() and not result_overlay_visible
	queue_redraw()

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
	var board_top_min := 224.0
	var available_height := maxf(230.0, viewport.y - board_top_min - 36.0)
	var cell := minf((viewport.x - 64.0) / BOARD_W, minf((viewport.y * 0.68) / BOARD_H, available_height / BOARD_H))
	var board_size := Vector2(cell * BOARD_W, cell * BOARD_H)
	var board_position := Vector2((viewport.x - board_size.x) * 0.5, maxf((viewport.y - board_size.y) * 0.5 + 22.0, board_top_min))
	return {
		"cell": cell,
		"board_rect": Rect2(board_position, board_size)
	}

func _drop_button_layout(viewport: Vector2, board: Rect2) -> Rect2:
	# Keep a prominent hard-drop target in the right gutter without reducing or covering the 10x23 board.
	var width := minf(84.0, viewport.x - board.end.x - 14.0)
	if width < 42.0:
		return Rect2()
	var height := 52.0
	return Rect2(Vector2(board.end.x + 6.0, board.end.y - height - 6.0), Vector2(width, height))

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
	if clear_flash_time > 0.0:
		clear_flash_time = maxf(0.0, clear_flash_time - delta)
		queue_redraw()
	if game == null:
		return
	if block_run_active:
		_process_block_run_events()
		_advance_block_run_clock(delta if not paused and not mode_select_visible else 0.0)
	if mode_session != null and not mode_select_visible and not block_run_active:
		mode_session.update(delta if not paused else 0.0, game.lines, game.game_over)
	if not mode_select_visible and not game.game_over and not paused and not _block_run_draft_is_open() and (mode_session == null or mode_session.is_running()):
		gravity_interval = float(block_run_session.drop_interval_ms) / 1000.0 if block_run_active and block_run_session != null else _gravity_interval_for_level(game.level)
		gravity_clock += delta
		if gravity_clock >= gravity_interval:
			gravity_clock = 0.0
			game.tick()
			if mode_session != null and not block_run_active:
				mode_session.update(0.0, game.lines, game.game_over)
			if block_run_active:
				_process_block_run_events()
			queue_redraw()
	_sync_buddy_state()

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
	game.reset()
	# The mode lifecycle must also return to running when restarting Block Run;
	# otherwise its completed status blocks the first touch on the new run.
	if mode_session != null:
		mode_session.start(mode_session.mode_id if not mode_session.mode_id.is_empty() else "classic")
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
		if mode_select_visible:
			if event.keycode == KEY_1:
				_select_mode("classic")
			elif event.keycode == KEY_2:
				_select_mode("sprint")
			elif event.keycode == KEY_3:
				_select_mode("marathon")
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
			KEY_LEFT, KEY_A: game.move_horizontal(-1)
			KEY_RIGHT, KEY_D: game.move_horizontal(1)
			KEY_DOWN, KEY_S: game.soft_drop()
			KEY_UP, KEY_W, KEY_X, KEY_SPACE: game.rotate_piece()
			KEY_ENTER: game.hard_drop()
			KEY_C: game.hold_piece()
			KEY_R:
				_restart_current_run()
		_sync_buddy_state()
		queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_start_msec = Time.get_ticks_msec()
			touch_active = true
		elif touch_active:
			var touch_duration_msec := Time.get_ticks_msec() - touch_start_msec
			touch_active = false
			if not _handle_swipe(touch_start, event.position, touch_duration_msec):
				_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_swipe(start: Vector2, finish: Vector2, duration_msec: int = 250) -> bool:
	if mode_select_visible or game == null or game.game_over or paused or _mode_finished() or _block_run_draft_is_open() or not board_rect.has_point(start):
		return false
	var delta := finish - start
	var threshold := 36.0
	if maxf(absf(delta.x), absf(delta.y)) < threshold:
		return false
	if absf(delta.x) > absf(delta.y):
		var steps := clampi(roundi(absf(delta.x) / maxf(board_rect.size.x / BOARD_W, 1.0)), 1, 3)
		var direction := 1 if delta.x > 0.0 else -1
		for i in range(steps):
			game.move_horizontal(direction)
	elif delta.y > 0.0:
		# Hard drop requires both a decisive travel distance and a quick
		# gesture. Slow downward drags remain soft-drop input.
		var is_quick_drop := delta.y >= board_rect.size.y * 0.22 and duration_msec <= 350
		if is_quick_drop:
			game.hard_drop()
		else:
			var drops := clampi(roundi(delta.y / threshold), 1, 4)
			for i in range(drops):
				game.soft_drop()
				if game.game_over:
					break
	else:
		game.rotate_piece()
	_sync_buddy_state()
	queue_redraw()
	return true

func _toggle_pause() -> void:
	if game == null or game.game_over or _mode_finished() or mode_select_visible:
		return
	paused = not paused
	queue_redraw()

func _handle_tap(point: Vector2) -> void:
	if mode_select_visible:
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
	if game.game_over or _mode_finished():
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
			game.hard_drop()
		elif block_run_active and block_run_skill_rect.has_point(point):
			activate_block_run_hero_skill()
		elif hold_rect.has_point(point):
			game.hold_piece()
		elif board_rect.has_point(point):
			game.rotate_piece()
	_sync_buddy_state()
	queue_redraw()

func _select_mode(requested_mode_id: String) -> void:
	if not ModeCatalog.is_valid_mode(requested_mode_id):
		return
	game.reset()
	if mode_session == null:
		mode_session = ModeSession.new()
	mode_session.start(requested_mode_id)
	mode_select_visible = false
	paused = false
	gravity_clock = 0.0
	buddy_last_lines = 0
	clear_flash_time = 0.0
	clear_flash_count = 0
	if is_instance_valid(buddy):
		buddy.set_state("idle", 0.0)
	queue_redraw()

func _open_mode_select() -> void:
	mode_select_visible = true
	paused = false
	queue_redraw()

func _mode_finished() -> bool:
	return mode_session != null and not mode_session.is_running()

func _sync_buddy_state() -> void:
	if game == null:
		return
	if mode_session != null and not mode_select_visible:
		mode_session.update(0.0, game.lines, game.game_over)
	if not is_instance_valid(buddy):
		return
	var buddy_layout := _buddy_layout_for_gutter(board_rect.position.x)
	var result_overlay_visible := paused or game.game_over or (mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED)
	buddy.visible = buddy_layout.visible and not _block_run_draft_is_open() and not result_overlay_visible
	if game.game_over:
		if buddy.state != "surprised":
			buddy.set_state("surprised", 0.0)
		return
	if game.lines > buddy_last_lines:
		var cleared := game.lines - buddy_last_lines
		clear_flash_count = cleared
		clear_flash_time = 0.72 if cleared < 4 else 1.05
		buddy.set_state("victory" if cleared >= 4 else "happy", 1.5)
		buddy_last_lines = game.lines

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#070d1c"))
	_draw_backdrop()
	if mode_select_visible:
		_draw_mode_select()
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
	elif game.game_over:
		_draw_game_over()
	elif paused:
		_draw_pause_overlay()


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
		_: return "РЕЖИМ"

func _draw_mode_select() -> void:
	var layout := _mode_select_layout(screen_size)
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
	return mode_session != null and int(mode_session.rules.get("target_lines", 0)) > 0

func _objective_progress_ratio() -> float:
	if not _is_line_objective_mode():
		return 0.0
	var target := int(mode_session.rules.get("target_lines", 0))
	if target <= 0:
		return 0.0
	return clampf(float(game.lines) / float(target), 0.0, 1.0)

func _format_elapsed_time(total_seconds: float) -> String:
	var safe_seconds := maxi(0, floori(total_seconds))
	var minutes := safe_seconds / 60
	var seconds := safe_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _draw_stats() -> void:
	# Wider, balanced HUD cards keep values readable on narrow portrait screens.
	var top := 56.0
	var outer := 18.0
	var gap := 10.0
	var card_width := (screen_size.x - outer * 2.0 - gap) * 0.5
	var card_height := 52.0
	var score_value := block_run_session.score if block_run_active and block_run_session != null else game.score
	var synergy_count := block_run_session.encounter.active_synergies().size() if block_run_active and block_run_session != null else 0
	var score_label := "ОЧКИ" if synergy_count == 0 else "ОЧКИ • СИНЕРГИИ %d" % synergy_count
	_stat_card(Rect2(outer, top, card_width, card_height), score_label, str(score_value), Color("#45d9f5"))
	var progress_rect := Rect2(outer + card_width + gap, top, card_width, card_height)
	if block_run_active and block_run_session != null:
		var encounter = block_run_session.encounter
		var attack_label := "УДАР %dС" % encounter.next_attack_seconds
		var encounter_label := "БОСС • %s" % attack_label if encounter.boss else "К%d • Э%d • %s" % [encounter.room, encounter.floor, attack_label]
		_stat_card(progress_rect, encounter_label, "ВР %d / %d" % [encounter.enemy_hp, encounter.enemy_max_hp], Color("#ff9b57"))
		var hp_ratio := clampf(float(encounter.enemy_hp) / float(maxi(1, encounter.enemy_max_hp)), 0.0, 1.0)
		var hp_track := Rect2(progress_rect.position + Vector2(12.0, 46.0), Vector2(progress_rect.size.x - 24.0, 3.0))
		draw_rect(hp_track, Color(0.12, 0.19, 0.27, 1.0))
		if hp_ratio > 0.0:
			draw_rect(Rect2(hp_track.position, Vector2(hp_track.size.x * hp_ratio, hp_track.size.y)), Color("#ff9b57"))
	elif _is_line_objective_mode():
		var target := int(mode_session.rules.get("target_lines", 40))
		var elapsed_label := _format_elapsed_time(mode_session.elapsed_seconds)
		var mode_label := _mode_display_name(mode_session.mode_id)
		_stat_card(progress_rect, mode_label + " • " + elapsed_label, "%d / %d" % [mini(game.lines, target), target], Color("#f6d65b"))
		var track := Rect2(progress_rect.position + Vector2(12.0, 46.0), Vector2(progress_rect.size.x - 24.0, 3.0))
		draw_rect(track, Color(0.12, 0.19, 0.27, 1.0))
		if _objective_progress_ratio() > 0.0:
			draw_rect(Rect2(track.position, Vector2(track.size.x * _objective_progress_ratio(), track.size.y)), Color("#45d9f5"))
	else:
		_stat_card(progress_rect, "УРОВЕНЬ / ЛИНИИ", "%d / %d" % [game.level, game.lines], Color("#f6d65b"))

func _stat_card(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_soft_panel(rect, Color("#124b99"), accent.lightened(0.18), 15, 7)
	var label_size := 8 if label.length() > 17 else 10
	draw_string(font, rect.position + Vector2(12, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color("#c9eaff"))
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
	# Compact 24px goal strip sits above the 72px preview row, including on 360x800 phones.
	var top := board_rect.position.y - 116.0
	var gap := 6.0
	var outer := 18.0
	var width := (screen_size.x - outer * 2.0 - gap * 2.0) / 3.0
	for index in range(mini(3, states.size())):
		var goal: Dictionary = states[index]
		var rect := Rect2(outer + index * (width + gap), top, width, 24.0)
		var ratio := _block_run_goal_ratio(goal)
		_draw_soft_panel(rect, Color("#0b2850"), Color("#3d82b5"), 8, 2)
		var label := _block_run_goal_short_label(goal)
		var progress := "%d/%d" % [int(goal.get("value", 0)), int(goal.get("target", 1))]
		var reward := "+%d" % int(goal.get("reward", 0))
		draw_string(font, rect.position + Vector2(6.0, 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#a9d8f2"))
		var progress_width := font.get_string_size(progress, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(font, rect.position + Vector2(rect.size.x - progress_width - 5.0, 10.0), progress, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ffffff"))
		var track_width := maxf(18.0, rect.size.x - 48.0)
		var track := Rect2(rect.position + Vector2(6.0, 14.0), Vector2(track_width, 3.0))
		draw_rect(track, Color("#1b3b60"))
		if ratio > 0.0:
			draw_rect(Rect2(track.position, Vector2(track.size.x * ratio, track.size.y)), Color("#45d9f5"))
		draw_string(font, rect.position + Vector2(rect.size.x - 34.0, 22.0), reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#f6d65b"))

func _draw_piece_previews() -> void:
	var card_height := 72.0
	var top := board_rect.position.y - card_height - 16.0
	if block_run_active:
		var slot_width := minf((screen_size.x - 36.0) / 3.0, 164.0)
		var slot_gap := 8.0
		var total_width := slot_width * 3.0 + slot_gap * 2.0
		var start_x := (screen_size.x - total_width) * 0.5
		hold_rect = Rect2(start_x, top, slot_width, card_height)
		block_run_skill_rect = Rect2(start_x + (slot_width + slot_gap) * 2.0, top, slot_width, card_height)
		_draw_preview_card(hold_rect, "ЗАПАС", game.held_type)
		_draw_preview_card(Rect2(start_x + slot_width + slot_gap, top, slot_width, card_height), "ДАЛЕЕ", game.peek_next_piece_type())
		_draw_block_run_skill_card(block_run_skill_rect)
	else:
		var card_width := minf(164.0, (screen_size.x - 36.0) * 0.5)
		var gap := 12.0
		var total_width := card_width * 2.0 + gap
		var start_x := (screen_size.x - total_width) * 0.5
		hold_rect = Rect2(start_x, top, card_width, card_height)
		block_run_skill_rect = Rect2()
		_draw_preview_card(hold_rect, "ЗАПАС", game.held_type)
		_draw_preview_card(Rect2(start_x + card_width + gap, top, card_width, card_height), "ДАЛЕЕ", game.peek_next_piece_type())

func _draw_drop_button() -> void:
	if drop_rect.size.x < 42.0:
		return
	var enabled := not paused and not game.game_over and not _mode_finished() and not _block_run_draft_is_open()
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
	var remaining := block_run_session.hero_skill_cooldown_seconds
	var hero_label := _hero_display_name(block_run_hero_id)
	var state := "ЗАКРЫТО · УР. 5" if block_run_hero_level < 5 else ("ГОТОВО" if ready else "ОТКАТ · %d С" % remaining)
	var accent := Color("#45d9f5") if ready else Color("#66839e")
	draw_rect(rect, Color("#0b1d31"))
	draw_rect(rect, accent, false, 1.5)
	draw_string(font, rect.position + Vector2(8.0, 17.0), "✦ " + hero_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f4f8ff"))
	draw_string(font, rect.position + Vector2(8.0, 34.0), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, accent)

func _draw_preview_card(rect: Rect2, label: String, piece_type: int) -> void:
	_draw_soft_panel(rect, Color("#17488a"), Color("#71cfff"), 15, 6)
	# Keep the label in a dedicated upper-left lane; center the tetromino in the
	# lower-right lane so labels and piece cells never collide on 360px screens.
	draw_string(font, rect.position + Vector2(9, 19), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9f4ff"))
	if piece_type < 0:
		draw_string(font, rect.position + Vector2(rect.size.x - 28.0, 43), "—", HORIZONTAL_ALIGNMENT_CENTER, 30, 18, Color("#b7dfff"))
		return
	var cells: Array = BlockBuddiesModel.SHAPES[piece_type]
	var min_x := 999
	var min_y := 999
	var max_x := -999
	var max_y := -999
	for cell_pos in cells:
		min_x = mini(min_x, cell_pos.x)
		min_y = mini(min_y, cell_pos.y)
		max_x = maxi(max_x, cell_pos.x)
		max_y = maxi(max_y, cell_pos.y)
	var mini_cell := minf(12.0, minf((rect.size.x - 56.0) / 4.0, (rect.size.y - 24.0) / 4.0))
	var piece_size := Vector2((max_x - min_x + 1) * mini_cell, (max_y - min_y + 1) * mini_cell)
	var piece_origin := Vector2(rect.position.x + rect.size.x - 30.0, rect.position.y + rect.size.y * 0.67) - piece_size * 0.5
	for cell_pos in cells:
		var mini_rect := Rect2(piece_origin + Vector2(cell_pos.x - min_x, cell_pos.y - min_y) * mini_cell, Vector2.ONE * mini_cell).grow(-0.7)
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
			var tile: int = game.grid[y][x]
			if tile >= 0:
				var tile_color: Color = Color("#aebbd1") if tile == 7 else BlockBuddiesModel.PALETTE[tile]
				_draw_block(rect.grow(-0.5), tile_color)
	var ghost := game.ghost_origin()
	for cell_pos in game.active_cells:
		var p: Vector2i = ghost + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-2.0)
			_draw_soft_panel(rect, Color(0.55, 0.83, 1.0, 0.10), Color(0.65, 0.91, 1.0, 0.24), 6, 0)
	for cell_pos in game.active_cells:
		var p: Vector2i = game.origin + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-1.3)
			_draw_block(rect, BlockBuddiesModel.PALETTE[game.active_type])
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
	var target := int(mode_session.rules.get("target_lines", game.lines))
	_center_text(mode_name + " • ВЫПОЛНЕНО", screen_size.y * 0.5 - 56.0, 23, Color("#f4f8ff"))
	_center_text("ОЧИЩЕНО ЛИНИЙ • %d" % target, screen_size.y * 0.5 - 22.0, 14, Color("#45d9f5"))
	_center_text("ВРЕМЯ  •  " + _format_elapsed_time(mode_session.elapsed_seconds), screen_size.y * 0.5 + 10.0, 15, Color("#f6d65b"))
	_center_text("ОЧКИ  •  %d" % game.score, screen_size.y * 0.5 + 42.0, 17, Color("#c0d3e2"))
	_center_text("НАЖМИ, ЧТОБЫ СЫГРАТЬ ЕЩЁ", screen_size.y * 0.5 + 88.0, 13, Color("#ffcf6b"))

func _game_over_title() -> String:
	return _mode_display_name(mode_session.mode_id) + " — НЕ ВЫПОЛНЕН" if _is_line_objective_mode() else "ИГРА ОКОНЧЕНА"

func _game_over_progress_label() -> String:
	if _is_line_objective_mode():
		var target := int(mode_session.rules.get("target_lines", 40))
		return "ЛИНИИ  •  %d / %d" % [mini(game.lines, target), target]
	return "ОЧИЩЕНО ЛИНИЙ  •  %d" % game.lines

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
		_center_text("ОЧКИ  •  %d" % game.score, screen_size.y * 0.5 + 30.0, 20, Color("#45d9f5"))
		_center_text("ЕЩЁ ОДИН ЗАБЕГ?", screen_size.y * 0.5 + 91.0, 13, Color("#ffb477"))
	else:
		_center_text(_game_over_title(), screen_size.y * 0.5 - 70.0, 34, Color("#f4f8ff"))
		_center_text("ОЧКИ", screen_size.y * 0.5 - 30.0, 12, Color("#83a3bd"))
		_center_text(str(game.score), screen_size.y * 0.5 + 2.0, 28, Color("#45d9f5"))
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
