extends Node2D
## Original pixel Buddy companion. Drawn in code so the project stays self-contained.
## States: idle, happy, surprised, victory.

const PIXEL := 7.0
const INK := Color("#08172d")
const BLUE := Color("#1769d2")
const BLUE_LIGHT := Color("#4da8ff")
const CYAN := Color("#62f2ff")
const WHITE := Color("#f4fbff")
const SCREEN := Color("#10253d")
const ORANGE := Color("#ffad4f")

var state := "idle"
var state_time := 0.0
var elapsed := 0.0

func set_state(next_state: String, duration: float = 1.25) -> void:
	if not ["idle", "happy", "surprised", "victory"].has(next_state):
		return
	state = next_state
	state_time = duration
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if state != "idle" and state_time > 0.0:
		state_time -= delta
		if state_time <= 0.0:
			state = "idle"
	queue_redraw()

func _draw() -> void:
	var bob := 0.0
	match state:
		"happy": bob = absf(sin(elapsed * 5.2)) * -3.0
		"surprised": bob = sin(elapsed * 4.0) * 1.2
		"victory": bob = sin(elapsed * 7.0) * 2.2
		_: bob = sin(elapsed * 3.2) * 1.8
	var origin := Vector2(0, bob)
	# Soft shadow and a rounded, dimensional Buddy cube.
	draw_ellipse_placeholder(origin + Vector2(43, 91), Vector2(38, 7), Color(0.01, 0.04, 0.12, 0.30))
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#1263d4")
	shell.set_corner_radius_all(19)
	shell.set_border_width_all(4)
	shell.border_color = Color("#8ceaff")
	shell.shadow_color = Color(0.0, 0.025, 0.12, 0.55)
	shell.shadow_size = 9
	shell.shadow_offset = Vector2(0, 6)
	draw_style_box(shell, Rect2(origin + Vector2(3, 3), Vector2(78, 78)))
	var face_gloss := StyleBoxFlat.new()
	face_gloss.bg_color = Color(0.55, 0.89, 1.0, 0.22)
	face_gloss.set_corner_radius_all(14)
	draw_style_box(face_gloss, Rect2(origin + Vector2(10, 9), Vector2(64, 16)))
	# Side shine gives the cube a toy-like, rounded plastic finish.
	draw_line(origin + Vector2(9, 27), origin + Vector2(9, 61), Color(0.65, 0.94, 1.0, 0.32), 2.0)
	draw_line(origin + Vector2(75, 27), origin + Vector2(75, 61), Color(0.02, 0.23, 0.67, 0.45), 2.0)
	var eye_y := 39.0
	if state == "surprised":
		draw_circle(origin + Vector2(27, eye_y), 6.0, Color("#09264b"))
		draw_circle(origin + Vector2(57, eye_y), 6.0, Color("#09264b"))
		draw_circle(origin + Vector2(27, eye_y), 2.0, Color("#ffffff"))
		draw_circle(origin + Vector2(57, eye_y), 2.0, Color("#ffffff"))
	else:
		draw_circle(origin + Vector2(27, eye_y), 5.5, Color("#09264b"))
		draw_circle(origin + Vector2(57, eye_y), 5.5, Color("#09264b"))
		draw_circle(origin + Vector2(28, eye_y - 2), 1.8, Color("#ffffff"))
		draw_circle(origin + Vector2(58, eye_y - 2), 1.8, Color("#ffffff"))
	draw_circle(origin + Vector2(17, 53), 5.0, Color(1.0, 0.47, 0.56, 0.55))
	draw_circle(origin + Vector2(67, 53), 5.0, Color(1.0, 0.47, 0.56, 0.55))
	if state == "surprised":
		draw_circle(origin + Vector2(42, 59), 5.0, Color("#09264b"))
	elif state == "happy" or state == "victory":
		draw_arc(origin + Vector2(42, 49), 13.0, 0.22, PI - 0.22, 24, Color("#09264b"), 3.2)
		draw_line(origin + Vector2(33, 59), origin + Vector2(51, 59), Color("#ffffff"), 1.5)
	else:
		draw_arc(origin + Vector2(42, 51), 9.0, 0.18, PI - 0.18, 20, Color("#09264b"), 2.8)
	# Tiny floating star changes with Buddy's reaction.
	var star_color := Color("#ffe36e")
	var star_center := origin + Vector2(88, 12 + sin(elapsed * 3.0) * 2.0)
	draw_colored_polygon(PackedVector2Array([star_center + Vector2(0,-8), star_center + Vector2(2,-2), star_center + Vector2(8,0), star_center + Vector2(2,2), star_center + Vector2(0,8), star_center + Vector2(-2,2), star_center + Vector2(-8,0), star_center + Vector2(-2,-2)]), star_color)
	var label_color := Color("#fff0b9") if state == "victory" else Color("#c9edff")
	draw_string(ThemeDB.fallback_font, origin + Vector2(43, 108), "BUDDY", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, label_color)

func draw_ellipse_placeholder(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _draw_row(pattern: String, origin: Vector2, row: int) -> void:
	for column in range(pattern.length()):
		var pixel := pattern.substr(column, 1)
		if pixel == ".":
			continue
		var color := INK
		match pixel:
			"D": color = INK
			"B": color = BLUE
			"C": color = CYAN
			"F": color = WHITE
			"S": color = SCREEN
			"E": color = CYAN
			"M": color = Color("#ff8fb2")
			"O": color = ORANGE
			"H": color = BLUE_LIGHT
		var rect := Rect2(origin + Vector2(column, row) * PIXEL, Vector2.ONE * PIXEL)
		draw_rect(rect, color)
		if pixel == "B" and row < 4:
			draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(PIXEL - 2, 1)), BLUE_LIGHT)

func _draw_blink(origin: Vector2) -> void:
	# A quick pixel blink keeps the companion feeling alive without changing
	# its silhouette or distracting from the playfield.
	var blink_phase := fposmod(elapsed, 3.8)
	if state == "surprised" or blink_phase < 3.68:
		return
	for eye_column in [4, 6]:
		var eye_rect := Rect2(origin + Vector2(eye_column * PIXEL + 1.0, 5.0 * PIXEL + 3.0), Vector2(PIXEL - 2.0, 2.0))
		draw_rect(eye_rect, SCREEN)
		draw_rect(Rect2(eye_rect.position + Vector2(1.0, 1.0), Vector2(eye_rect.size.x - 2.0, 1.0)), CYAN)

func _draw_badge(origin: Vector2) -> void:
	var symbol := ""
	match state:
		"happy": symbol = "+"
		"surprised": symbol = "!"
		"victory": symbol = "*"
	if symbol != "":
		draw_string(ThemeDB.fallback_font, origin + Vector2(PIXEL * 13, PIXEL * 3), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, ORANGE)
