extends Node2D

# Static, code-drawn UI exploration. This is deliberately separate from the
# live game scene: it previews the visual language without wiring economy or saves.
@export_enum("home", "shop", "heroes", "upgrades", "block_run", "campaign", "daily") var screen_id := "home"
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
		"campaign": _draw_campaign()
		"daily": _draw_daily()
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
	draw_style_box(shadow, Rect2(rect.position + Vector2(0, 9), rect.size))
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
	# Compact command center: all primary destinations and daily loops fit in one
	# portrait viewport. Detailed content lives on the destination screens.
	var w := viewport_size.x
	var margin := 30.0
	var gap := 10.0
	# Brand / Buddy hero strip
	_panel(Rect2(margin, 108, w - margin * 2, 126), Color("#102f68"), Color("#53dfff"), 22)
	_buddy(Vector2(104, 171), 0.48)
	_text("BLOCK BUDDIES", Vector2(160, 157), 27, WHITE)
	_text("СОБИРАЙ ФИГУРЫ • ОТКРЫВАЙ МИРЫ", Vector2(160, 187), 13, PALE)
	_text("✦  8 031", Vector2(w - 160, 145), 17, GOLD)
	_text("◈  3", Vector2(w - 160, 174), 15, CYAN)
	# Three large, instantly recognizable game modes
	var mode_y := 246.0
	var mode_h := 88.0
	var mode_names := ["КАМПАНИЯ", "БЛОК-РАН", "ЕЖЕДНЕВНЫЙ ВЫЗОВ"]
	var mode_subs := ["Планеты и путешествия", "Рогалик • герои • боссы", "Испытание дня и награды"]
	var mode_fills := [Color("#124e80"), Color("#343078"), Color("#51401e")]
	var mode_accents := [CYAN, VIOLET, GOLD]
	for i in range(3):
		var y := mode_y + i * (mode_h + gap)
		var rect := Rect2(margin, y, w - margin * 2, mode_h)
		_panel(rect, mode_fills[i], mode_accents[i], 20)
		_draw_mode_icon(Vector2(86, y + mode_h * 0.5), i, 0.72)
		_text(mode_names[i], Vector2(150, y + 38), 20, WHITE)
		_text(mode_subs[i], Vector2(150, y + 63), 13, PALE)
		draw_string(font, Vector2(w - 70, y + 54), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, mode_accents[i])
	# Daily missions: three thin progress rows in one shared surface
	var tasks_y := 540.0
	_panel(Rect2(margin, tasks_y, w - margin * 2, 218), Color("#102b59"), Color("#4e9bc8"), 20)
	_text("ЕЖЕДНЕВНЫЕ ЗАДАНИЯ", Vector2(52, tasks_y + 31), 17, CYAN)
	_text("3 цели • награды за прогресс", Vector2(w - 255, tasks_y + 30), 11, PALE)
	var task_names := ["Очистить 8 линий", "Набрать 2 000 очков", "Сыграть 4 партии"]
	var task_progress := ["6 / 8", "0 / 2 000", "0 / 4"]
	for i in range(3):
		var y := tasks_y + 48 + i * 54
		if i > 0:
			draw_line(Vector2(50, y - 5), Vector2(w - 50, y - 5), Color("#41628d"), 1)
		_text(task_names[i], Vector2(54, y + 17), 14, WHITE)
		_text(task_progress[i], Vector2(w - 145, y + 17), 12, PALE)
		var bar := Rect2(54, y + 27, w - 108, 5)
		draw_rect(bar, Color("#2a4266"))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * [0.75, 0.0, 0.0][i], bar.size.y)), [CYAN, VIOLET, GOLD][i])
	# Streak strip: a concise retention hook, not another large card
	var streak_y := 770.0
	_panel(Rect2(margin, streak_y, w - margin * 2, 68), Color("#28285c"), Color("#a77bff"), 18)
	_draw_flame(Vector2(76, streak_y + 34), 0.62)
	_text("11 ДНЕЙ ПОДРЯД", Vector2(126, streak_y + 29), 18, GOLD)
	_text("Зайди завтра, чтобы усилить серию", Vector2(126, streak_y + 51), 12, PALE)
	# Secondary destinations as three compact icon tiles
	var utility_y := 850.0
	var utility_gap := 10.0
	var utility_w := (w - margin * 2 - utility_gap * 2) / 3.0
	var utility_names := ["ГЕРОИ", "МАГАЗИН", "УСИЛЕНИЯ"]
	var utility_fills := [Color("#164c83"), Color("#175e76"), Color("#49377d")]
	for i in range(3):
		var x := margin + i * (utility_w + utility_gap)
		_panel(Rect2(x, utility_y, utility_w, 104), utility_fills[i], [CYAN, Color("#8ef4d3"), VIOLET][i], 17)
		_draw_utility_icon(Vector2(x + utility_w * 0.5, utility_y + 36), i)
		_center_card_text(utility_names[i], Rect2(x, utility_y, utility_w, 80), utility_y + 83, 12, WHITE)
	# Wallet and lifetime stats share one compact footer row
	var footer_y := 966.0
	_panel(Rect2(margin, footer_y, w - margin * 2, 66), Color("#102b55"), Color("#397cae"), 17)
	_text("ЗОЛОТО  8 031", Vector2(54, footer_y + 27), 15, GOLD)
	_text("КРИСТАЛЛЫ  3", Vector2(w * 0.49, footer_y + 27), 15, CYAN)
	_text("РЕКОРД 28 872", Vector2(54, footer_y + 51), 11, PALE)
	_text("19 ЗАПУСКОВ  •  6 ДОСТИЖЕНИЙ", Vector2(w * 0.49, footer_y + 51), 11, PALE)
	_draw_bottom_nav("ГЛАВНАЯ")

func _draw_mode_icon(center: Vector2, mode: int, scale := 1.0) -> void:
	var s := scale
	match mode:
		0:
			draw_circle(center, 27*s, Color("#0c2c58"))
			draw_arc(center, 23*s, 0, TAU, 48, CYAN, 3*s, true)
			for i in range(3):
				var a := TAU * float(i) / 3.0 - PI/2
				draw_circle(center + Vector2(cos(a),sin(a))*15*s, 6*s, [CYAN,GOLD,PINK][i])
		1:
			for cell in [Vector2(-12,-12),Vector2(5,-12),Vector2(5,5),Vector2(22,5)]:
				var r := Rect2(center + cell*s, Vector2(15,15)*s)
				draw_rect(r, VIOLET)
				draw_rect(r, Color("#e5d7ff"), false, 2*s)
		2:
			_draw_flame(center, 0.48*s)
			draw_arc(center, 27*s, 0, TAU, 48, GOLD, 2*s, true)

func _draw_flame(center: Vector2, scale := 1.0) -> void:
	var s := scale
	var flame := PackedVector2Array([center+Vector2(0,-27)*s,center+Vector2(17,-7)*s,center+Vector2(14,16)*s,center+Vector2(0,25)*s,center+Vector2(-15,14)*s,center+Vector2(-13,-3)*s,center+Vector2(-5,-15)*s,center+Vector2(-4,2)*s])
	draw_colored_polygon(flame, Color("#ff8a36"))
	draw_circle(center + Vector2(1,10)*s, 7*s, GOLD)

func _draw_utility_icon(center: Vector2, kind: int) -> void:
	match kind:
		0:
			_hero_portrait(center, 0, 0.34)
		1:
			draw_rect(Rect2(center+Vector2(-21,-17),Vector2(42,34)), Color("#25b7a8"))
			draw_rect(Rect2(center+Vector2(-12,-23),Vector2(24,10)), Color("#8ef4d3"), false, 3)
			draw_circle(center+Vector2(10,1),7,GOLD)
		2:
			for i in range(3):
				draw_circle(center+Vector2(-17+i*17,0),8,[CYAN,VIOLET,GOLD][i])
			draw_arc(center,25,0,TAU,40,Color("#c6b4ff"),3,true)

func _draw_shop() -> void:
	_center("МАГАЗИН", 156, 32, GOLD)
	_center("Новые образы и приятные бонусы", 188, 14, PALE)
	var names := ["НЕОНОВЫЙ БАДДИ", "ЗВЁЗДНЫЙ НАБОР", "МЯГКИЙ СЛЕД", "КОСМИЧЕСКИЙ ШЛЕМ", "ОРБИТАЛЬНЫЙ СЛЕД", "ЗОЛОТОЙ КОНТУР"]
	var prices := ["250 ✦", "490 ✦", "180 ✦", "320 ✦", "210 ✦", "600 ✦"]
	var fills := [Color("#145eaf"), Color("#71439c"), Color("#a15c1b"), Color("#176d78"), Color("#58469b"), Color("#94651d")]
	var accents := [CYAN, PINK, GOLD, Color("#8ef4d3"), VIOLET, GOLD]
	for i in range(6):
		var y := 220.0 + i * 145.0
		var rect := Rect2(34, y, viewport_size.x - 68, 126)
		_panel(rect, fills[i], accents[i], 22)
		_buddy(Vector2(108, y + 62), 0.43)
		_text(names[i], Vector2(170, y + 43), 16, WHITE)
		_text("Облик и косметика", Vector2(170, y + 68), 12, PALE)
		_button(Rect2(170, y + 79, 152, 36), prices[i], Color("#8d5a17"), GOLD, 14)
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
		_hero_portrait(rect.position + Vector2(rect.size.x * 0.5, 66), i, 0.62)
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

func _hero_portrait(center: Vector2, hero: int, scale := 1.0) -> void:
	var s := scale
	var colors := [Color("#1686df"), Color("#8c62dc"), Color("#27b9a5"), Color("#d28b35"), Color("#e45d91")]
	var accents := [CYAN, Color("#e4c7ff"), Color("#a4ffe2"), GOLD, PINK]
	var body := Rect2(center - Vector2(43, 42) * s, Vector2(86, 84) * s)
	match hero:
		0:
			draw_circle(center + Vector2(-31, -37) * s, 15 * s, accents[hero])
			draw_circle(center + Vector2(31, -37) * s, 15 * s, accents[hero])
			var box := StyleBoxFlat.new()
			box.bg_color = colors[hero]
			box.set_corner_radius_all(int(25 * s))
			draw_style_box(box, body)
		1:
			var points := PackedVector2Array([center + Vector2(0,-54)*s, center + Vector2(48,-8)*s, center + Vector2(30,43)*s, center + Vector2(-30,43)*s, center + Vector2(-48,-8)*s])
			draw_colored_polygon(points, colors[hero])
			draw_polyline(PackedVector2Array([points[0], points[2], points[4], points[0]]), accents[hero], 3.0 * s, true)
		2:
			draw_line(center + Vector2(0,-39)*s, center + Vector2(0,-58)*s, accents[hero], 4.0*s)
			draw_circle(center + Vector2(0,-61)*s, 8*s, accents[hero])
			var box2 := StyleBoxFlat.new()
			box2.bg_color = colors[hero]
			box2.set_corner_radius_all(int(13*s))
			draw_style_box(box2, body)
		3:
			var points3 := PackedVector2Array([center+Vector2(-30,-48)*s,center+Vector2(20,-48)*s,center+Vector2(20,-28)*s,center+Vector2(43,-28)*s,center+Vector2(43,30)*s,center+Vector2(22,30)*s,center+Vector2(22,48)*s,center+Vector2(-30,48)*s,center+Vector2(-30,25)*s,center+Vector2(-45,25)*s,center+Vector2(-45,-28)*s,center+Vector2(-30,-28)*s])
			draw_colored_polygon(points3, colors[hero])
		4:
			var star := PackedVector2Array()
			for j in range(10):
				var a := -PI/2.0 + TAU * float(j) / 10.0
				var radius := (51.0 if j % 2 == 0 else 39.0) * s
				star.append(center + Vector2(cos(a), sin(a)) * radius)
			draw_colored_polygon(star, colors[hero])
	for eye_x in [-13.0, 13.0]:
		draw_circle(center + Vector2(eye_x, -2) * s, 4.5*s, Color("#092b61"))
		draw_circle(center + Vector2(eye_x-1,-4)*s, 1.5*s, WHITE)
	draw_arc(center + Vector2(0, 9)*s, 10*s, 0.25, 2.9, 18, Color("#092b61"), 2.5*s, true)

func _draw_campaign() -> void:
	_center("КОСМИЧЕСКИЙ АТЛАС", 150, 30, GOLD)
	_center("Исследуй вселенные и открывай новые миры", 183, 14, PALE)
	var titles := ["ТУМАННОСТЬ ИСКР", "КРИСТАЛЬНАЯ ВСЕЛЕННАЯ", "ТЕНЕВОЙ РУБЕЖ"]
	var subtitles := ["Зелёные луны • 3 планеты", "Мир сияющих осколков", "Неизведанный сектор"]
	var colors := [Color("#1c78a9"), Color("#624b9f"), Color("#773e75")]
	var accents := [CYAN, VIOLET, PINK]
	for i in range(3):
		var y := 225.0 + i * 260.0
		_panel(Rect2(30, y, viewport_size.x - 60, 224), colors[i], accents[i], 26)
		draw_circle(Vector2(130, y+92), 66, Color(0.3,0.8,1,0.16))
		draw_circle(Vector2(130, y+92), 43, Color(0.7,0.5,1,0.22))
		draw_circle(Vector2(130, y+92), 23, accents[i])
		for p in range(3):
			var a := TAU * float(p) / 3.0 + 0.6
			var planet := Vector2(130, y+92) + Vector2(cos(a),sin(a))*78
			draw_circle(planet, 10 + p*2, [CYAN,GOLD,PINK][p])
		_text(titles[i], Vector2(225, y+70), 17, WHITE)
		_text(subtitles[i], Vector2(225, y+99), 12, PALE)
		_text("ПРОГРЕСС  %d / 3 ПЛАНЕТЫ" % (i+1), Vector2(225, y+132), 11, GOLD)
		_button(Rect2(225, y+150, 190, 43), "ОТКРЫТЬ ВСЕЛЕННУЮ", Color("#0878d6"), accents[i], 12)
	_draw_bottom_nav("ИГРАТЬ")

func _draw_daily() -> void:
	_center("ЕЖЕДНЕВНЫЙ ВЫЗОВ", 150, 30, GOLD)
	_center("Новая миссия каждый день • серия наград", 183, 14, PALE)
	_panel(Rect2(34, 218, viewport_size.x-68, 174), Color("#174d98"), CYAN, 24)
	_text("ЗАДАНИЕ СЕГОДНЯ", Vector2(58, 260), 18, GOLD)
	_text("Очисти 12 линий за один забег", Vector2(58, 300), 16, WHITE)
	_text("Награда: 75 ✦  •  сложность: средняя", Vector2(58, 334), 13, PALE)
	_button(Rect2(58, 350, 190, 32), "НАЧАТЬ", Color("#0878d6"), CYAN, 13)
	_panel(Rect2(34, 420, viewport_size.x-68, 590), Color("#123e82"), Color("#8deaff"), 24)
	_center("НОЯБРЬ 2026", 466, 22, WHITE)
	var days := ["ПН","ВТ","СР","ЧТ","ПТ","СБ","ВС"]
	for col in range(7):
		_center_card_text(days[col], Rect2(38+col*92, 0, 90, 20), 505, 11, PALE)
	for day in range(30):
		var col := day % 7
		var row := day / 7
		var x := 48.0 + col * 91.0
		var y := 530.0 + row * 91.0
		var active := day == 7
		var complete := day < 7
		var fill := Color("#9a6b22") if active else (Color("#176b83") if complete else Color("#17376b"))
		_panel(Rect2(x, y, 76, 70), fill, GOLD if active else (CYAN if complete else Color("#496c9d")), 12)
		_center_card_text(str(day+1), Rect2(x, y, 76, 50), y+29, 18, WHITE)
		if complete:
			draw_circle(Vector2(x+58,y+53), 5, Color("#8ef4d3"))
		elif active:
			draw_circle(Vector2(x+58,y+53), 5, GOLD)
	_text("● Выполнено     ● Сегодня     ○ Впереди", Vector2(58, 975), 12, PALE)
	_draw_bottom_nav("ИГРАТЬ")
