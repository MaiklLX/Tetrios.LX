class_name BlockBuddiesModel
extends RefCounted

const WIDTH := 10
const HEIGHT := 23
const SHAPES: Array = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
]
const PALETTE: Array[Color] = [
	Color("#5cf5e8"), Color("#9d7cff"), Color("#ffc86b"),
	Color("#ff6f9e"), Color("#6ca8ff"), Color("#b6f27c"), Color("#ff9868")
]

var grid: Array = []
var active_cells: Array[Vector2i] = []
var active_type := 0
var origin := Vector2i(3, 0)
var score := 0
var lines := 0
var level := 1
var game_over := false

func reset() -> void:
	grid.clear()
	for y in range(HEIGHT):
		var row: Array = []
		for x in range(WIDTH):
			row.append(-1)
		grid.append(row)
	score = 0
	lines = 0
	level = 1
	game_over = false
	_spawn()

func _spawn() -> void:
	active_type = randi() % SHAPES.size()
	active_cells = SHAPES[active_type].duplicate()
	origin = Vector2i(3, 0)
	if _collides(origin, active_cells):
		game_over = true

func _collides(at: Vector2i, cells: Array) -> bool:
	for cell in cells:
		var p: Vector2i = at + cell
		if p.x < 0 or p.x >= WIDTH or p.y >= HEIGHT:
			return true
		if p.y >= 0 and grid[p.y][p.x] != -1:
			return true
	return false

func move_horizontal(direction: int) -> void:
	if game_over:
		return
	var next := origin + Vector2i(clampi(direction, -1, 1), 0)
	if not _collides(next, active_cells):
		origin = next

func rotate_piece() -> void:
	if game_over:
		return
	var rotated: Array[Vector2i] = []
	for cell in active_cells:
		rotated.append(Vector2i(-cell.y, cell.x))
	var min_x := 999
	var min_y := 999
	for cell in rotated:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	for i in range(rotated.size()):
		rotated[i] -= Vector2i(min_x, min_y)
	for kick in [0, -1, 1, -2, 2]:
		var candidate := origin + Vector2i(kick, 0)
		if not _collides(candidate, rotated):
			origin = candidate
			active_cells = rotated
			return

func soft_drop() -> void:
	if game_over:
		return
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		score += 1
	else:
		_lock_piece()

func hard_drop() -> void:
	if game_over:
		return
	var distance := 0
	while not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
		distance += 1
	score += distance * 2
	_lock_piece()

func tick() -> void:
	if game_over:
		return
	if not _collides(origin + Vector2i(0, 1), active_cells):
		origin.y += 1
	else:
		_lock_piece()

func _lock_piece() -> void:
	for cell in active_cells:
		var p: Vector2i = origin + cell
		if p.y >= 0 and p.y < HEIGHT:
			grid[p.y][p.x] = active_type
	var cleared := 0
	for y in range(HEIGHT - 1, -1, -1):
		var full := true
		for x in range(WIDTH):
			if grid[y][x] == -1:
				full = false
				break
		if full:
			grid.remove_at(y)
			var new_row: Array = []
			for x in range(WIDTH):
				new_row.append(-1)
			grid.push_front(new_row)
			cleared += 1
			y += 1
	if cleared > 0:
		lines += cleared
		var rewards := [0, 100, 300, 500, 800]
		score += rewards[mini(cleared, 4)] * level
		level = 1 + int(lines / 10)
	_spawn()

func ghost_origin() -> Vector2i:
	var ghost := origin
	while not _collides(ghost + Vector2i(0, 1), active_cells):
		ghost.y += 1
	return ghost
