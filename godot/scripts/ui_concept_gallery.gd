extends Node2D

# Static, code-drawn UI exploration. This is deliberately separate from the
# live game scene: it previews the visual language without wiring economy or saves.
@export_enum("home", "shop", "heroes", "upgrades", "block_run") var screen_id := "home"
var viewport_size := Vector2(720.0, 1280.0)
var font: Font = ThemeDB.fallback_font

const BLUE := Color("#1767c8")
const CYAN := Color("#55ddff")
const GOLD := Color("#ffd05a")
const PINK := Color("#ff8fbd")
const VIOLET := Color("#a77bff")
const WHITE := Color("#fff8e8")
const PALE := Color("#d8efff")
const DEEP := Color("#0b2e72")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) if self is Control else null
	queue_redraw()

func _draw() -> void:
	viewport_size = get_viewport_rect().size
	_draw_backdrop()
	_draw_top_bar()
	match screen_id:
		"home": _draw_home()
		"shop": _draw_shop()
		"heroes": _draw_heroes()
		"upgrades": _draw_upgrades()
		"block_run": _draw_block_run()
		_: _draw_home()

func _draw_backdrop() -> void:
	for band in range(32):
		var t := float(band) / 31.0
		draw_rect(Rect2(0, viewport_size.y * t, viewport_size.x, viewport_size.y / 31.0 + 2.0), Color("#267bd7").lerp(Color("#142d79"), t))
	draw_circle(Vector2(viewport_size.x * 0.16, viewport_size.y * 0.30), viewport_size.x * 0.36, Color(0.25, 0.78, 1.0, 0.15))
	draw_circle(Vector2(viewport_size.x * 0.88, viewport_size.y * 0.54), viewport_size.x * 0.32, Color(0.75, 0.38, 1.0, 0.13))
	var hills := PackedVector2Array([Vector2(0, viewport_size.y * 0.89), Vector2(viewport_size.x * 0.22, viewport_size.y * 0.84), Vector2(viewport_size.x * 0.48, viewport_size.y * 0.91), Vector2(viewport_size.x * 0.76, viewport_size.y * 0.85), Vector2(viewport_size.x, viewport_size.y * 0.90), Vector2(viewport_size.x, viewport_size.y), Vector2(0, viewport_size.y)])
	draw_colored_polygon(hills, Color("#163c8b"))

func _panel(rect: Rect2, fill: Color, accent: Color, radius := 24) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.015, 0.06, 0.20, 0.38)
	shadow.set_corner_radius_all(radius)
	draw_style_box(shadow, rect.translated(Vector2(0, 9)))
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(2)
	box.border_color = accent
	draw_style_box(box, rect)
	var shine := StyleBoxFlat.new()
	shine.bg_color = Color(1, 1, 1, 0.10)
	shine.set_corner_radius_all(maxi(4, radius - 5))
	draw_style_box(shine, Rect2(rect.position + Vector2(7, 6), Vector2(rect.size.x - 14, 7)))

func _text(value: String, pos: Vector2, size := 20, color := WHITE) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _center(value: String, y: float, size := 24, color := WHITE) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, Vector2((viewport_size.x - width) * 0.5, y), size, color)

func _button(rect: Rect2, label: String, fill := BLUE, accent := CYAN, size := 20) -> void:
	_panel(rect, fill, accent, 20)
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(label, Vector2(rect.get_center().x - width * 0.5, rect.get_center().y + size * 0.34), size, WHITE)

func _top_bar() -> void:
	_panel(Rect2(24, 22, viewport_size.x - 48, 68), Color("#1454a5"), Color("#8deaff"), 22)
	_text("BLOCK BUDDIES", Vector2(46, 64), 24, WHITE)
	_panel(Rect2(viewport_size.x - 190, 35, 148, 42), Color("#925d16"), GOLD, 18)
	_text("✦  1 250", Vector2(viewport_size.x - 170, 63), 18, Color("#fff0b0"))

func _draw_top_bar() -> void:
	_top_bar()

func _buddy(center: Vector2, scale := 1.0, expression := "happy") -> void:
	var s := scale
	draw_circle(center + Vector2(0, 18 * s), 64 * s, Color(0.01, 0.06, 0.20, 0.28))
	var body := Rect2(center - Vector2(54, 54) * s, Vector2(108, 108) * s)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color("#0871c9")
	shadow.set_corner_radius_all(int(26 * s))
	shadow.set_border_width_all(maxi(2, int(3 * s)))
	shadow.border_color = Color("#b2f3ff")
	draw_style_box(shadow, body)
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.22)
	gloss.set_corner_radius_all(int(19 * s))
	draw_style_box(gloss, Rect2(body.position + Vector2(9, 7) * s, Vector2(body.size.x - 18 * s, 19 * s)))
	for eye_x in [-20.0, 20.0]:
		draw_circle(center + Vector2(eye_x, -5) * s, 7 * s, Color("#092b61"))
		draw_circle(center + Vector2(eye_x - 2, -8) * s, 2.2 * s, WHITE)
	if expression == "happy":
		draw_arc(center + Vector2(0, 10) * s, 17 * s, 0.25, 2.9, 24, Color("#092b61"), 3.5 * s, true)
	else:
		draw_line(center + Vector2(-10, 17) * s, center + Vector2(10, 17) * s, Color("#092b61"), 3 * s)
	draw_circle(center + Vector2(-37, 15) * s, 8 * s, Color(1.0, 0.48, 0.62, 0.45))
	draw_circle(center + Vector2(37, 15) * s, 8 * s, Color(1.0, 0.48, 0.62, 0.45))
	draw_circle(center + Vector2(48, -48) * s, 9 * s, GOLD)

func _draw_home() -> void:
	_center("ПРИВЕТ, ИГРОК!", 156, 28, Color("#fff0b4"))
	_center("ТВОЙ МИР БЛОКОВ И ПРИКЛЮЧЕНИЙ", 190, 14, PALE)
	_buddy(Vector2(viewport_size.x * 0.5, 355), 1.35)
	_center("ПОИГРАЕМ?", 478, 30, WHITE)
	_button(Rect2(74, 520, viewport_size.x - 148, 82), "ИГРАТЬ", Color("#0878d6"), Color("#a9f3ff"), 28)
	var labels := ["МАГАЗИН", "ГЕРОИ", "УЛУЧШЕНИЯ"]
	var fills := [Color("#8a4bb3"), Color("#116da7"), Color("#a15b19")]
	var accents := [PINK, CYAN, GOLD]
	for i in range(3):
		var x := 34.0 + i * (viewport_size.x - 68.0) / 3.0
		var width := (viewport_size.x - 92.0) / 3.0
		_button(Rect2(x, 636, width, 94), labels[i], fills[i], accents[i], 15)
	_panel(Rect2(36, 770, viewport_size.x - 72, 176), Color("#164b98"), Color("#78dfff"), 24)
	_text("ЕЖЕДНЕВНОЕ ПРИКЛЮЧЕНИЕ", Vector2(60, 812), 17, GOLD)
	_text("Выполни 3 задания и забери награду", Vector2(60, 850), 14, PALE)
	_button(Rect2(60, 875, 210, 48), "ОТКРЫТЬ", Color("#7950ad"), PINK, 15)
	_draw_bottom_nav("ГЛАВНАЯ")

func _draw_shop() -> void:
	_center("МАГАЗИН", 156, 32, GOLD)
	_center("Новые образы и приятные бонусы", 188, 14, PALE)
	var names := ["НЕОНОВЫЙ БАДДИ", "ЗВЁЗДНЫЙ НАБОР", "МЯГКИЙ СЛЕД"]
	var prices := ["250 ✦", "490 ✦", "180 ✦"]
	var fills := [Color("#145eaf"), Color("#71439c"), Color("#a15c1b")]
	var accents := [CYAN, PINK, GOLD]
	for i in range(3):
		var y := 238.0 + i * 190.0
		var rect := Rect2(34, y, viewport_size.x - 68, 160)
		_panel(rect, fills[i], accents[i], 24)
		_buddy(Vector2(112, y + 77), 0.55)
		_text(names[i], Vector2(180, y + 54), 18, WHITE)
		_text("Косметический предмет", Vector2(180, y + 82), 13, PALE)
		_button(Rect2(180, y + 101, 172, 43), prices[i], Color("#8d5a17"), GOLD, 16)
	_draw_bottom_nav("МАГАЗИН")

func _draw_heroes() -> void:
	_center("ТВОИ ГЕРОИ", 156, 32, GOLD)
	_center("Выбери напарника для забега", 188, 14, PALE)
	var names := ["ПЛЮШ", "ПРИЗМА", "БЛИП", "ПИКСЕЛЬ", "ИСКРА"]
	var colors := [Color("#1378cf"), Color("#8152bb"), Color("#1b9d9b"), Color("#a36a23"), Color("#b54c7c")]
	var accents := [CYAN, VIOLET, Color("#8ef4d3"), GOLD, PINK]
	for i in range(5):
		var col := i % 2
		var row := i / 2
		var x := 34.0 + col * (viewport_size.x - 84.0) * 0.5
		var y := 236.0 + row * 202.0
		var rect := Rect2(x, y, (viewport_size.x - 102.0) * 0.5, 174)
		_panel(rect, colors[i], accents[i], 22)
		_buddy(rect.position + Vector2(rect.size.x * 0.5, 66), 0.54, "happy" if i % 2 == 0 else "calm")
		_center_card_text(names[i], rect, y + 143, 18, WHITE)
		_center_card_text("УРОВЕНЬ  %d" % (i + 1), rect, y + 164, 10, PALE)
	_button(Rect2(90, 880, viewport_size.x - 180, 62), "ВЫБРАТЬ ГЕРОЯ", Color("#0878d6"), CYAN, 19)
	_draw_bottom_nav("ГЕРОИ")

func _center_card_text(value: String, rect: Rect2, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, Vector2(rect.get_center().x - width * 0.5, y), size, color)

func _draw_upgrades() -> void:
	_center("МАСТЕРСКАЯ", 156, 32, GOLD)
	_center("Усиливай способности своего Buddy", 188, 14, PALE)
	_buddy(Vector2(viewport_size.x * 0.5, 330), 0.92)
	var upgrades := [{"name":"ЭНЕРГИЯ","level":"УР. 3  →  4","price":"120 ✦","color":CYAN},{"name":"ЗАЩИТА","level":"УР. 2  →  3","price":"90 ✦","color":GOLD},{"name":"БОНУС ОЧКОВ","level":"УР. 1  →  2","price":"150 ✦","color":PINK}]
	for i in range(upgrades.size()):
		var item: Dictionary = upgrades[i]
		var y := 460.0 + i * 128.0
		var rect := Rect2(34, y, viewport_size.x - 68, 104)
		_panel(rect, Color("#174e98"), item.color, 21)
		_text(item.name, Vector2(58, y + 38), 17, WHITE)
		_text(item.level, Vector2(58, y + 69), 13, PALE)
		_button(Rect2(viewport_size.x - 210, y + 25, 150, 54), item.price, Color("#8c5918"), GOLD, 17)
	_draw_bottom_nav("ГЕРОИ")

func _draw_block_run() -> void:
	_center("BLOCK RUN", 156, 34, GOLD)
	_center("Рогалик-забег: комнаты, враги и награды", 188, 14, PALE)
	_panel(Rect2(34, 226, viewport_size.x - 68, 186), Color("#184d9a"), CYAN, 25)
	_buddy(Vector2(140, 320), 0.70, "happy")
	_text("ПЕРВЫЙ ЭТАЖ", Vector2(230, 292), 20, WHITE)
	_text("Комната 1 из 5", Vector2(230, 326), 15, PALE)
	_text("Босс ждёт в конце этажа", Vector2(230, 356), 13, GOLD)
	_center("МАРШРУТ ПРИКЛЮЧЕНИЯ", 468, 20, WHITE)
	for i in range(5):
		var x := 70.0 + i * (viewport_size.x - 140.0) / 4.0
		var color := GOLD if i == 4 else CYAN
		draw_circle(Vector2(x, 555), 27, Color("#124b91"))
		draw_arc(Vector2(x, 555), 27, 0, TAU, 40, color, 4, true)
		_text("Б" if i == 4 else str(i + 1), Vector2(x - 6, 562), 17, WHITE)
		if i < 4:
			draw_line(Vector2(x + 28, 555), Vector2(x + (viewport_size.x - 140.0) / 4.0 - 28, 555), Color("#7bcfff"), 5)
	_panel(Rect2(38, 630, viewport_size.x - 76, 168), Color("#75439e"), PINK, 24)
	_text("ЦЕЛИ ЗАБЕГА", Vector2(62, 672), 18, WHITE)
	_text("Очисти 5 линий  •  +15 монет", Vector2(62, 712), 14, PALE)
	_text("Набери 600 очков  •  +20 монет", Vector2(62, 744), 14, PALE)
	_button(Rect2(74, 850, viewport_size.x - 148, 76), "НАЧАТЬ ЗАБЕГ", Color("#0878d6"), CYAN, 24)
	_draw_bottom_nav("ИГРАТЬ")

func _draw_bottom_nav(active: String) -> void:
	var rect := Rect2(24, viewport_size.y - 104, viewport_size.x - 48, 72)
	_panel(rect, Color("#103c80"), Color("#78dfff"), 24)
	var items := ["ГЛАВНАЯ", "ИГРАТЬ", "ГЕРОИ", "МАГАЗИН"]
	for i in range(items.size()):
		var x := rect.position.x + 18.0 + i * (rect.size.x - 36.0) / 4.0
		var color := GOLD if items[i] == active else PALE
		_text(items[i], Vector2(x, rect.position.y + 43), 12, color)
