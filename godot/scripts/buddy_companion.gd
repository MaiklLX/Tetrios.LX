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
	var bob := 0.0 if state == "victory" else sin(elapsed * 3.2) * 2.0
	var origin := Vector2(0, bob)
	# Pixel shadow and little orange feet.
	draw_rect(Rect2(origin + Vector2(PIXEL * 2, PIXEL * 11), Vector2(PIXEL * 8, PIXEL)), Color(0.0, 0.0, 0.0, 0.22))
	_draw_row("..DDDDDDDD..", origin, 0)
	_draw_row(".DBBBBBBBBD.", origin, 1)
	_draw_row("DBCCCCCCCCBD", origin, 2)
	_draw_row("DBFFFFFFFFBD", origin, 3)
	_draw_row("DBFSSSSSSFBD", origin, 4)
	match state:
		"happy":
			_draw_row("DBFCSSSSCFBD", origin, 5)
			_draw_row("DBFSSMMMMFBD", origin, 6)
		"surprised":
			_draw_row("DBFSESSSEFBD", origin, 5)
			_draw_row("DBFSSSMMSSFBD", origin, 6)
		"victory":
			_draw_row("DBFCECCECFBD", origin, 5)
			_draw_row("DBFSSMMMMFBD", origin, 6)
		_:
			_draw_row("DBFSEFESSFBD", origin, 5)
			_draw_row("DBFSSMMSSFBD", origin, 6)
	_draw_row("DBFSSSSSSFBD", origin, 7)
	_draw_row("DBFFFFFFFFBD", origin, 8)
	_draw_row("DBBBBBBBBBBD", origin, 9)
	_draw_row(".DBBBBBBBBD.", origin, 10)
	_draw_row("..DD....DD..", origin, 11)
	_draw_row(".OO......OO.", origin, 12)
	_draw_row(".DD......DD.", origin, 13)
	_draw_badge(origin)
	draw_string(ThemeDB.fallback_font, origin + Vector2(PIXEL * 6, PIXEL * 16), "BUDDY", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#9bc9ed"))

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

func _draw_badge(origin: Vector2) -> void:
	var symbol := ""
	match state:
		"happy": symbol = "+"
		"surprised": symbol = "!"
		"victory": symbol = "*"
	if symbol != "":
		draw_string(ThemeDB.fallback_font, origin + Vector2(PIXEL * 13, PIXEL * 3), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, ORANGE)
