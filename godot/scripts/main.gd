extends Node2D

const CELL := 38.0
const BOARD_W := 10
const BOARD_H := 23
const Model = preload("res://scripts/game_model.gd")
const Buddy = preload("res://scripts/buddy_companion.gd")

var game: BlockBuddiesModel
var gravity_clock := 0.0
var gravity_interval := 0.78
var font: Font
var board_rect := Rect2()
var controls: Dictionary = {}
var screen_size := Vector2(720, 1280)
var buddy: Node2D
var buddy_last_lines := 0

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	game = Model.new()
	game.reset()
	buddy = Buddy.new()
	add_child(buddy)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_process(true)

func _layout() -> void:
	screen_size = get_viewport_rect().size
	var cell := minf((screen_size.x - 72.0) / BOARD_W, (screen_size.y * 0.58) / BOARD_H)
	var board_size := Vector2(cell * BOARD_W, cell * BOARD_H)
	board_rect = Rect2((screen_size - board_size) * 0.5 + Vector2(0, 22), board_size)
	var button_y := screen_size.y - minf(148.0, screen_size.y * 0.13)
	var button_h := 76.0
	var gap := 12.0
	var widths := [92.0, 92.0, 92.0, 112.0]
	var total: float = widths[0] + widths[1] + widths[2] + widths[3] + gap * 3.0
	var x: float = (screen_size.x - total) * 0.5
	if is_instance_valid(buddy):
		# Fit Buddy into the actual left gutter on phones instead of hiding it
		# until tablet widths. Keep a small clear gap before the playfield.
		var buddy_scale := clampf((board_rect.position.x - 16.0) / 98.0, 0.55, 1.0)
		buddy.scale = Vector2.ONE * buddy_scale
		buddy.position = Vector2(8.0, board_rect.position.y + 18.0)
		buddy.visible = board_rect.position.x >= 70.0
	controls = {
		"left": Rect2(x, button_y, widths[0], button_h),
		"right": Rect2(x + widths[0] + gap, button_y, widths[1], button_h),
		"rotate": Rect2(x + (widths[0] + gap) * 2.0, button_y, widths[2], button_h),
		"drop": Rect2(x + (widths[0] + gap) * 3.0, button_y, widths[3], button_h)
	}
	queue_redraw()

func _process(delta: float) -> void:
	if game == null:
		return
	if not game.game_over:
		gravity_clock += delta
		if gravity_clock >= gravity_interval:
			gravity_clock = 0.0
			game.tick()
			queue_redraw()
	_sync_buddy_state()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A: game.move_horizontal(-1)
			KEY_RIGHT, KEY_D: game.move_horizontal(1)
			KEY_DOWN, KEY_S: game.soft_drop()
			KEY_UP, KEY_W, KEY_X, KEY_SPACE: game.rotate_piece()
			KEY_ENTER: game.hard_drop()
			KEY_R:
				game.reset()
				gravity_clock = 0.0
				buddy_last_lines = 0
				buddy.set_state("idle", 0.0)
		_sync_buddy_state()
		queue_redraw()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(point: Vector2) -> void:
	if game.game_over:
		game.reset()
		gravity_clock = 0.0
		buddy_last_lines = 0
		buddy.set_state("idle", 0.0)
	elif controls.left.has_point(point):
		game.move_horizontal(-1)
	elif controls.right.has_point(point):
		game.move_horizontal(1)
	elif controls.rotate.has_point(point):
		game.rotate_piece()
	elif controls.drop.has_point(point):
		game.hard_drop()
	elif board_rect.has_point(point):
		if point.x < board_rect.get_center().x:
			game.move_horizontal(-1)
		else:
			game.move_horizontal(1)
	_sync_buddy_state()
	queue_redraw()

func _sync_buddy_state() -> void:
	if not is_instance_valid(buddy) or game == null:
		return
	if game.game_over:
		if buddy.state != "surprised":
			buddy.set_state("surprised", 0.0)
		return
	if game.lines > buddy_last_lines:
		var cleared := game.lines - buddy_last_lines
		buddy.set_state("victory" if cleared >= 4 else "happy", 1.5)
		buddy_last_lines = game.lines

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#070d1c"))
	_draw_backdrop()
	_draw_header()
	_draw_stats()
	_draw_board()
	_draw_controls()
	if game.game_over:
		_draw_game_over()

func _draw_backdrop() -> void:
	for i in range(7):
		var radius := 110.0 + i * 44.0
		draw_arc(Vector2(screen_size.x * 0.5, screen_size.y * 0.43), radius, 0, TAU, 96, Color(0.16, 0.43, 0.72, 0.035), 2.0)
	draw_circle(Vector2(screen_size.x * 0.5, screen_size.y * 0.42), 4.0, Color(0.25, 0.82, 1.0, 0.22))

func _draw_header() -> void:
	_center_text("BLOCK BUDDIES", 62.0, 36, Color("#f5f8ff"))
	_center_text("ARCADE • CLASSIC MODE", 105.0, 15, Color("#72a6c8"))
	draw_line(Vector2(42, 128), Vector2(screen_size.x - 42, 128), Color(0.22, 0.48, 0.68, 0.35), 1.0)

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

func _draw_board() -> void:
	var frame := board_rect.grow(10)
	draw_rect(frame, Color(0.025, 0.045, 0.08, 0.98))
	draw_rect(frame, Color(0.20, 0.55, 0.78, 0.48), false, 2.0)
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

func _draw_block(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color.darkened(0.28))
	draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), color)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.end.x - 3, rect.position.y + 3), color.lightened(0.45), 2.0)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.position.x + 3, rect.end.y - 3), color.lightened(0.24), 2.0)
	draw_line(Vector2(rect.position.x + 3, rect.end.y - 3), rect.end - Vector2(3, 3), color.darkened(0.32), 2.0)

func _draw_controls() -> void:
	for key in controls:
		var rect: Rect2 = controls[key]
		var accent := Color("#45d9f5") if key == "drop" else Color("#28435d")
		draw_rect(rect, Color(0.055, 0.10, 0.17, 0.96))
		draw_rect(rect, accent, false, 2.0)
		var label: String = str({"left": "◀", "right": "▶", "rotate": "ROTATE", "drop": "DROP"}[key])
		var size := 18 if key == "rotate" else 25
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, rect.get_center() + Vector2(-width * 0.5, size * 0.34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#f3f8ff"))
	_center_text("TAP SIDES TO MOVE  •  TAP ROTATE  •  DROP TO LOCK", screen_size.y - 34, 11, Color("#66839e"))

func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2(0, 0), screen_size), Color(0.01, 0.02, 0.04, 0.78))
	_center_text("RUN OVER", screen_size.y * 0.47, 38, Color("#ffffff"))
	_center_text("TAP ANYWHERE TO PLAY AGAIN", screen_size.y * 0.47 + 48, 16, Color("#45d9f5"))

func _center_text(value: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((screen_size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
