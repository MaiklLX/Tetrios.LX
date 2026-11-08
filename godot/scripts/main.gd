extends Node2D

const CELL := 38.0
const BOARD_W := 10
const BOARD_H := 23
const Model = preload("res://scripts/game_model.gd")
const Buddy = preload("res://scripts/buddy_companion.gd")
const ModeSession = preload("res://scripts/mode_session.gd")
const ModeCatalog = preload("res://scripts/mode_catalog.gd")

var game: BlockBuddiesModel
var mode_session: BlockBuddiesModeSession
var mode_select_visible := true
var mode_button_rect := Rect2()
var classic_mode_rect := Rect2()
var sprint_mode_rect := Rect2()
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
	pause_rect = Rect2(screen_size.x - 64.0, 42.0, 42.0, 42.0)
	var resume_width := minf(220.0, screen_size.x - 64.0)
	resume_rect = Rect2(screen_size.x * 0.5 - resume_width * 0.5, screen_size.y * 0.5 + 42.0, resume_width, 54.0)
	mode_button_rect = Rect2(24.0, 42.0, 82.0, 42.0)
	var mode_card_width := minf(300.0, screen_size.x - 48.0)
	classic_mode_rect = Rect2(screen_size.x * 0.5 - mode_card_width * 0.5, screen_size.y * 0.5 - 92.0, mode_card_width, 92.0)
	sprint_mode_rect = Rect2(screen_size.x * 0.5 - mode_card_width * 0.5, screen_size.y * 0.5 + 20.0, mode_card_width, 92.0)
	if is_instance_valid(buddy):
		var buddy_layout := _buddy_layout_for_gutter(board_rect.position.x)
		buddy.scale = Vector2.ONE * buddy_layout.scale
		buddy.position = Vector2(8.0, board_rect.position.y + 18.0)
		buddy.visible = buddy_layout.visible
	queue_redraw()

func _board_metrics(viewport: Vector2) -> Dictionary:
	# With touch-first input there is no permanent control strip: give that
	# space back to the playfield while preserving room for HUD and previews.
	var board_top_min := 292.0
	var available_height := maxf(230.0, viewport.y - board_top_min - 36.0)
	var cell := minf((viewport.x - 64.0) / BOARD_W, minf((viewport.y * 0.68) / BOARD_H, available_height / BOARD_H))
	var board_size := Vector2(cell * BOARD_W, cell * BOARD_H)
	var board_position := Vector2((viewport.x - board_size.x) * 0.5, maxf((viewport.y - board_size.y) * 0.5 + 22.0, board_top_min))
	return {
		"cell": cell,
		"board_rect": Rect2(board_position, board_size)
	}

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
	if mode_session != null and not mode_select_visible:
		mode_session.update(delta if not paused else 0.0, game.lines, game.game_over)
	if not mode_select_visible and not game.game_over and not paused and (mode_session == null or mode_session.is_running()):
		gravity_interval = _gravity_interval_for_level(game.level)
		gravity_clock += delta
		if gravity_clock >= gravity_interval:
			gravity_clock = 0.0
			game.tick()
			if mode_session != null:
				mode_session.update(0.0, game.lines, game.game_over)
			queue_redraw()
	_sync_buddy_state()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if mode_select_visible:
			if event.keycode == KEY_1:
				_select_mode("classic")
			elif event.keycode == KEY_2:
				_select_mode("sprint")
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
				game.reset()
				if mode_session != null:
					mode_session.start(mode_session.mode_id if not mode_session.mode_id.is_empty() else "classic")
				paused = false
				gravity_clock = 0.0
				buddy_last_lines = 0
				clear_flash_time = 0.0
				clear_flash_count = 0
				buddy.set_state("idle", 0.0)
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
	if mode_select_visible or game == null or game.game_over or paused or _mode_finished() or not board_rect.has_point(start):
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
		queue_redraw()
		return
	if mode_button_rect.has_point(point):
		_open_mode_select()
		return
	if game.game_over or _mode_finished():
		game.reset()
		if mode_session != null:
			mode_session.start(mode_session.mode_id if not mode_session.mode_id.is_empty() else "classic")
		paused = false
		gravity_clock = 0.0
		buddy_last_lines = 0
		clear_flash_time = 0.0
		clear_flash_count = 0
		buddy.set_state("idle", 0.0)
	elif pause_rect.has_point(point):
		_toggle_pause()
	elif paused:
		if resume_rect.has_point(point):
			paused = false
	else:
		if hold_rect.has_point(point):
			game.hold_piece()
		elif board_rect.has_point(point):
			# A single unambiguous tap always rotates; hard drop is swipe-only.
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
	if mode_session != null and mode_session.status == ModeSession.STATUS_COMPLETED:
		_draw_mode_complete()
	elif game.game_over:
		_draw_game_over()
	elif paused:
		_draw_pause_overlay()

func _draw_backdrop() -> void:
	# Layered arcade atmosphere: restrained radial light, pixel stars and slow
	# drifting signal particles. All geometry is procedural; no external art.
	var pulse := 0.5 + 0.5 * sin(ambient_time * 0.7)
	var glow_center := Vector2(screen_size.x * 0.5, screen_size.y * 0.43)
	draw_circle(glow_center, screen_size.x * 0.44, Color(0.025, 0.12, 0.23, 0.12 + pulse * 0.025))
	for i in range(8):
		var radius := 90.0 + i * 48.0
		var alpha := 0.025 + pulse * 0.008 if i < 3 else 0.018
		draw_arc(glow_center, radius, 0, TAU, 96, Color(0.16, 0.55, 0.86, alpha), 1.0)
	for i in range(34):
		var seed_x := float((i * 73 + 19) % 997) / 997.0
		var seed_y := float((i * 139 + 47) % 991) / 991.0
		var drift := fmod(ambient_time * (5.0 + float(i % 4) * 2.0) + float(i * 17), screen_size.y + 24.0)
		var point := Vector2(seed_x * screen_size.x, fmod(seed_y * screen_size.y + drift, screen_size.y))
		var twinkle := 0.25 + 0.45 * (0.5 + 0.5 * sin(ambient_time * 1.4 + float(i)))
		var pixel_size := 1.0 if i % 3 else 2.0
		draw_rect(Rect2(point, Vector2.ONE * pixel_size), Color(0.31, 0.76, 1.0, twinkle * 0.42))
	draw_circle(glow_center, 3.0 + pulse * 1.5, Color(0.25, 0.82, 1.0, 0.16 + pulse * 0.12))

func _draw_header() -> void:
	_center_text("BLOCK BUDDIES", 62.0, 36, Color("#f5f8ff"))
	var mode_name := "Classic" if mode_session == null else str(mode_session.rules.get("name", "Classic"))
	_center_text("ARCADE • %s MODE" % mode_name.to_upper(), 105.0, 15, Color("#72a6c8"))
	draw_line(Vector2(42, 128), Vector2(screen_size.x - 42, 128), Color(0.22, 0.48, 0.68, 0.35), 1.0)
	_draw_mode_button()
	_draw_pause_button()

func _draw_mode_button() -> void:
	draw_rect(mode_button_rect, Color(0.055, 0.09, 0.15, 0.94))
	draw_rect(mode_button_rect, Color("#45d9f5"), false, 1.5)
	var label := "MODE"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, mode_button_rect.get_center() + Vector2(-width * 0.5, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#eaf7ff"))

func _draw_mode_select() -> void:
	_center_text("CHOOSE YOUR MODE", screen_size.y * 0.5 - 148.0, 26, Color("#f4f8ff"))
	_center_text("PICK A RUN STYLE", screen_size.y * 0.5 - 120.0, 12, Color("#83a3bd"))
	_draw_mode_card(classic_mode_rect, "1  •  CLASSIC", "Endless play. No line or time limit.", Color("#45d9f5"))
	_draw_mode_card(sprint_mode_rect, "2  •  SPRINT", "Race to clear 40 lines.", Color("#f6d65b"))
	_center_text("TAP A CARD  •  M TO CHANGE MODE", screen_size.y * 0.5 + 150.0, 12, Color("#72a6c8"))

func _draw_mode_card(rect: Rect2, title: String, description: String, accent: Color) -> void:
	draw_rect(rect, Color(0.055, 0.09, 0.15, 0.97))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), accent)
	draw_rect(rect, Color(0.28, 0.46, 0.62, 0.55), false, 1.0)
	draw_string(font, rect.position + Vector2(18.0, 38.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#f4f8ff"))
	draw_string(font, rect.position + Vector2(18.0, 66.0), description, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9bb6ca"))

func _draw_stats() -> void:
	var top := 154.0
	_stat_card(Rect2(42, top, (screen_size.x - 100) * 0.48, 70), "SCORE", str(game.score), Color("#45d9f5"))
	_stat_card(Rect2(screen_size.x * 0.52, top, (screen_size.x - 100) * 0.48, 70), "LEVEL  /  LINES", "%d  /  %d" % [game.level, game.lines], Color("#f6d65b"))

func _stat_card(rect: Rect2, label: String, value: String, accent: Color) -> void:
	draw_rect(rect, Color(0.055, 0.09, 0.15, 0.94))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), accent)
	draw_rect(rect, Color(0.28, 0.46, 0.62, 0.35), false, 1.0)
	draw_string(font, rect.position + Vector2(14, 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#83a3bd"))
	draw_string(font, rect.position + Vector2(14, 54), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f4f8ff"))

func _draw_piece_previews() -> void:
	var card_width := minf(164.0, (screen_size.x - 36.0) * 0.5)
	var card_height := 46.0
	var gap := 12.0
	var total_width := card_width * 2.0 + gap
	var start_x := (screen_size.x - total_width) * 0.5
	var top := board_rect.position.y - card_height - 10.0
	hold_rect = Rect2(start_x, top, card_width, card_height)
	_draw_preview_card(hold_rect, "HOLD", game.held_type)
	_draw_preview_card(Rect2(start_x + card_width + gap, top, card_width, card_height), "NEXT", game.peek_next_piece_type())

func _draw_preview_card(rect: Rect2, label: String, piece_type: int) -> void:
	draw_rect(rect, Color(0.045, 0.085, 0.14, 0.96))
	draw_rect(rect, Color(0.20, 0.48, 0.68, 0.55), false, 1.0)
	draw_string(font, rect.position + Vector2(10, 28), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#83a3bd"))
	if piece_type < 0:
		draw_string(font, rect.position + Vector2(112, 29), "—", HORIZONTAL_ALIGNMENT_CENTER, 30, 18, Color("#66839e"))
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
	var mini_cell := minf(9.0, (rect.size.x - 56.0) / 4.0)
	var piece_size := Vector2((max_x - min_x + 1) * mini_cell, (max_y - min_y + 1) * mini_cell)
	var piece_origin := Vector2(rect.position.x + rect.size.x - 34.0, rect.get_center().y) - piece_size * 0.5
	for cell_pos in cells:
		var mini_rect := Rect2(piece_origin + Vector2(cell_pos.x - min_x, cell_pos.y - min_y) * mini_cell, Vector2.ONE * mini_cell).grow(-0.7)
		draw_rect(mini_rect, BlockBuddiesModel.PALETTE[piece_type])

func _draw_board() -> void:
	var frame := board_rect.grow(13)
	# A layered cabinet frame gives the playfield a distinct arcade-machine
	# silhouette without reducing the 10x23 playable area.
	draw_rect(frame.grow(5), Color(0.04, 0.30, 0.52, 0.045))
	draw_rect(frame, Color(0.018, 0.035, 0.068, 0.99))
	draw_rect(frame, Color(0.16, 0.42, 0.64, 0.72), false, 1.0)
	draw_rect(board_rect.grow(3), Color(0.025, 0.055, 0.09, 0.98))
	draw_rect(board_rect.grow(3), Color(0.22, 0.66, 0.88, 0.38), false, 1.0)
	draw_line(frame.position + Vector2(8, 5), Vector2(frame.end.x - 8, frame.position.y + 5), Color(0.35, 0.78, 1.0, 0.24), 1.0)
	var cell := board_rect.size.x / BOARD_W
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var rect := Rect2(board_rect.position + Vector2(x, y) * cell, Vector2.ONE * cell).grow(-1.5)
			draw_rect(rect, Color(0.035, 0.065, 0.105, 0.94))
			draw_rect(rect, Color(0.18, 0.32, 0.43, 0.25), false, 1.0)
			var tile: int = game.grid[y][x]
			if tile >= 0:
				_draw_block(rect, BlockBuddiesModel.PALETTE[tile])
	var ghost := game.ghost_origin()
	for cell_pos in game.active_cells:
		var p: Vector2i = ghost + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-2.0)
			draw_rect(rect, Color(0.45, 0.75, 0.9, 0.12))
			draw_rect(rect, Color(0.5, 0.82, 1.0, 0.32), false, 1.0)
	for cell_pos in game.active_cells:
		var p: Vector2i = game.origin + cell_pos
		if p.y >= 0:
			var rect := Rect2(board_rect.position + Vector2(p) * cell, Vector2.ONE * cell).grow(-1.5)
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
	draw_rect(rect, color.darkened(0.28))
	draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), color)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.end.x - 3, rect.position.y + 3), color.lightened(0.45), 2.0)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.position.x + 3, rect.end.y - 3), color.lightened(0.24), 2.0)
	draw_line(Vector2(rect.position.x + 3, rect.end.y - 3), rect.end - Vector2(3, 3), color.darkened(0.32), 2.0)

func _draw_pause_button() -> void:
	draw_rect(pause_rect, Color("#10243a"))
	draw_rect(pause_rect, Color("#45d9f5"), false, 2.0)
	var center := pause_rect.get_center()
	if paused:
		var triangle := PackedVector2Array([
			center + Vector2(-5, -10),
			center + Vector2(9, 0),
			center + Vector2(-5, 10)
		])
		draw_colored_polygon(triangle, Color("#f4f8ff"))
	else:
		draw_rect(Rect2(center + Vector2(-8, -10), Vector2(5, 20)), Color("#f4f8ff"))
		draw_rect(Rect2(center + Vector2(3, -10), Vector2(5, 20)), Color("#f4f8ff"))

func _draw_overlay_panel(rect: Rect2, accent: Color) -> void:
	draw_rect(rect.grow(9.0), Color(accent.r, accent.g, accent.b, 0.07))
	draw_rect(rect, Color("#081525"))
	draw_rect(rect, Color(0.20, 0.52, 0.72, 0.72), false, 1.5)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), accent)
	draw_line(rect.position + Vector2(16.0, 14.0), Vector2(rect.end.x - 16.0, rect.position.y + 14.0), Color(0.58, 0.82, 0.96, 0.12), 1.0)

func _draw_pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, 128.0), Vector2(320.0, 256.0))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#45d9f5"))
	_center_text("PAUSED", screen_size.y * 0.5 - 38.0, 34, Color("#f4f8ff"))
	_center_text("YOUR RUN IS ON HOLD", screen_size.y * 0.5 - 8.0, 13, Color("#83a3bd"))
	draw_rect(resume_rect, Color("#102c45"))
	draw_rect(resume_rect, Color("#45d9f5"), false, 2.0)
	var label := "RESUME"
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, resume_rect.get_center() + Vector2(-width * 0.5, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4f8ff"))

func _draw_mode_complete() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, 118.0), Vector2(320.0, 236.0))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#f6d65b"))
	_center_text("SPRINT COMPLETE", screen_size.y * 0.5 - 56.0, 27, Color("#f4f8ff"))
	_center_text("40 LINES CLEARED", screen_size.y * 0.5 - 12.0, 16, Color("#45d9f5"))
	_center_text("SCORE  •  %d" % game.score, screen_size.y * 0.5 + 28.0, 17, Color("#c0d3e2"))
	_center_text("TAP ANYWHERE TO PLAY AGAIN", screen_size.y * 0.5 + 88.0, 13, Color("#ffcf6b"))

func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.02, 0.04, 0.82))
	var panel := Rect2(screen_size * 0.5 - Vector2(160.0, 142.0), Vector2(320.0, 284.0))
	panel.position.x = maxf(20.0, panel.position.x)
	panel.size.x = minf(320.0, screen_size.x - 40.0)
	_draw_overlay_panel(panel, Color("#ff9b57"))
	_center_text("RUN OVER", screen_size.y * 0.5 - 70.0, 34, Color("#f4f8ff"))
	_center_text("SCORE", screen_size.y * 0.5 - 30.0, 12, Color("#83a3bd"))
	_center_text(str(game.score), screen_size.y * 0.5 + 2.0, 28, Color("#45d9f5"))
	_center_text("LINES CLEARED  •  %d" % game.lines, screen_size.y * 0.5 + 36.0, 13, Color("#c0d3e2"))
	_center_text("TAP ANYWHERE TO PLAY AGAIN", screen_size.y * 0.5 + 88.0, 13, Color("#ffb477"))

func _center_text(value: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((screen_size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
