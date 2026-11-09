extends Node2D

# KT-535: isolated visual review screen for the campaign-only Cargo Hook.
# This scene is intentionally not referenced by the live game or normal modes.
const SpecialPiece = preload("res://scripts/campaign_special_piece.gd")

const BG_TOP := Color("#07172f")
const BG_BOTTOM := Color("#102e58")
const CYAN := Color("#65e6ef")
const GOLD := Color("#ffd16a")
const WHITE := Color("#f3f8ff")
const MUTED := Color("#9eb8d7")
const PANEL := Color("#102746")
const PANEL_EDGE := Color("#2e6086")

var font: Font = ThemeDB.fallback_font
var viewport_size := Vector2(720.0, 1280.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	viewport_size = get_viewport_rect().size
	_draw_backdrop()
	_draw_header()
	_draw_feature()
	_draw_rotation_gallery()
	_draw_footer()

func _draw_backdrop() -> void:
	for band in range(40):
		var t := float(band) / 39.0
		draw_rect(Rect2(0, viewport_size.y * t, viewport_size.x, viewport_size.y / 39.0 + 2.0), BG_TOP.lerp(BG_BOTTOM, t))
	for i in range(34):
		var x := fposmod(float(i * 137 + 41), viewport_size.x)
		var y := fposmod(float(i * 211 + 83), viewport_size.y)
		draw_circle(Vector2(x, y), 1.2 if i % 4 == 0 else 0.7, Color(0.55, 0.82, 1.0, 0.24))
	draw_circle(Vector2(620, 320), 190, Color(0.08, 0.78, 0.88, 0.055))
	draw_circle(Vector2(95, 940), 220, Color(0.28, 0.42, 1.0, 0.06))

func _panel(rect: Rect2, fill: Color, edge: Color, radius := 24) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.0, 0.015, 0.045, 0.42)
	shadow.set_corner_radius_all(radius)
	draw_style_box(shadow, Rect2(rect.position + Vector2(0, 8), rect.size))
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(2)
	box.border_color = edge
	draw_style_box(box, rect)
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.045)
	gloss.set_corner_radius_all(maxi(5, radius - 6))
	draw_style_box(gloss, Rect2(rect.position + Vector2(7, 6), Vector2(rect.size.x - 14, 5)))

func _text(value: String, pos: Vector2, size := 20, color := WHITE) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _center(value: String, y: float, size := 20, color := WHITE) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, Vector2((viewport_size.x - width) * 0.5, y), size, color)

func _draw_header() -> void:
	_panel(Rect2(24, 22, viewport_size.x - 48, 72), Color("#0d3154"), Color("#397f9e"), 22)
	_text("BLOCK BUDDIES", Vector2(46, 52), 17, CYAN)
	_text("КАТАЛОГ КАМПАНИИ", Vector2(46, 76), 12, MUTED)
	var tag := Rect2(viewport_size.x - 212, 37, 164, 40)
	_panel(tag, Color("#4b3a1c"), GOLD, 15)
	var tag_text := "ПРОТОТИП"
	var tag_width := font.get_string_size(tag_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	_text(tag_text, Vector2(tag.get_center().x - tag_width * 0.5, tag.get_center().y + 5), 15, GOLD)
	_center("ГРУЗОВОЙ КРЮК", 151, 34, WHITE)
	_center("ОСОБАЯ ФИГУРА • 5 БЛОКОВ", 184, 15, CYAN)

func _draw_feature() -> void:
	var panel := Rect2(28, 224, viewport_size.x - 56, 390)
	_panel(panel, Color("#0b223e"), Color("#36758e"), 28)
	_text("ФОРМА ПО УМОЛЧАНИЮ", Vector2(56, 268), 15, MUTED)
	var cells := SpecialPiece.cells_for_rotation(0)
	var size := 66.0
	var dimensions := SpecialPiece.dimensions(cells)
	var shape_size := Vector2(dimensions.x * size, dimensions.y * size)
	var origin := Vector2(panel.get_center().x - shape_size.x * 0.5, 315 + (245.0 - shape_size.y) * 0.5)
	_draw_piece(cells, origin, size)
	_panel(Rect2(56, 548, 184, 42), Color("#103c51"), Color("#2f94a5"), 14)
	_text("5 / 5  СЕКЦИЙ", Vector2(76, 575), 15, CYAN)
	_panel(Rect2(260, 548, 404, 42), Color("#3f321b"), Color("#9e7837"), 14)
	_text("АСИММЕТРИЧНАЯ • 4 УНИКАЛЬНЫХ ПОВОРОТА", Vector2(280, 575), 13, GOLD)

func _draw_rotation_gallery() -> void:
	_center("ЧЕТЫРЕ ПОЛОЖЕНИЯ", 660, 21, WHITE)
	_center("Каждый поворот сохраняет все пять блоков", 687, 13, MUTED)
	var card_width := 316.0
	var card_height := 210.0
	var positions := [
		Vector2(28, 720), Vector2(376, 720),
		Vector2(28, 952), Vector2(376, 952)
	]
	for rotation in range(4):
		var rect := Rect2(positions[rotation], Vector2(card_width, card_height))
		_panel(rect, PANEL, PANEL_EDGE, 22)
		var label := "ПОВОРОТ %d" % (rotation + 1)
		_text(label, rect.position + Vector2(22, 38), 15, CYAN)
		var cells := SpecialPiece.cells_for_rotation(rotation)
		var dimensions := SpecialPiece.dimensions(cells)
		var cell_size := 39.0
		var shape_size := Vector2(dimensions.x * cell_size, dimensions.y * cell_size)
		var center := Vector2(rect.get_center().x, rect.position.y + 125)
		var origin := center - shape_size * 0.5
		_draw_piece(cells, origin, cell_size)

func _draw_piece(cells: Array[Vector2i], origin: Vector2, cell_size: float) -> void:
	for cell in cells:
		var rect := Rect2(origin + Vector2(cell) * cell_size + Vector2(3, 3), Vector2(cell_size - 6, cell_size - 6))
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color("#06172a")
		shadow.set_corner_radius_all(9)
		draw_style_box(shadow, Rect2(rect.position + Vector2(0, 4), rect.size))
		var block := StyleBoxFlat.new()
		block.bg_color = Color("#137d9b")
		block.set_corner_radius_all(9)
		block.set_border_width_all(2)
		block.border_color = CYAN
		draw_style_box(block, rect)
		var shine := StyleBoxFlat.new()
		shine.bg_color = Color(0.72, 1.0, 1.0, 0.22)
		shine.set_corner_radius_all(5)
		draw_style_box(shine, Rect2(rect.position + Vector2(5, 5), Vector2(rect.size.x - 10, 5)))
		draw_circle(rect.position + Vector2(rect.size.x - 8, 9), 2.1, GOLD)

func _draw_footer() -> void:
	_panel(Rect2(28, 1190, viewport_size.x - 56, 58), Color("#0b2039"), Color("#315b78"), 18)
	_center("ТОЛЬКО ДЛЯ КАМПАНИИ  •  НЕ ВЛИЯЕТ НА CLASSIC И BLOCK RUN", 1225, 12, MUTED)

func preview_card_rect(rotation_index: int) -> Rect2:
	if rotation_index < 0 or rotation_index > 3:
		return Rect2()
	var positions := [Vector2(28, 720), Vector2(376, 720), Vector2(28, 952), Vector2(376, 952)]
	return Rect2(positions[rotation_index], Vector2(316, 210))

func preview_rotation_cells(rotation_index: int) -> Array[Vector2i]:
	return SpecialPiece.cells_for_rotation(rotation_index)
