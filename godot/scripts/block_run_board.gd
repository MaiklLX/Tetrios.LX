class_name BlockBuddiesBlockRunBoard
extends RefCounted

const WIDTH := 10
const HEIGHT := 23
const EMPTY := -1
const GARBAGE := 7

static func _valid_grid(grid: Array) -> bool:
	if grid.size() != HEIGHT:
		return false
	for row in grid:
		if typeof(row) != TYPE_ARRAY or row.size() != WIDTH:
			return false
		for value in row:
			if typeof(value) != TYPE_INT or int(value) < EMPTY or int(value) > GARBAGE:
				return false
	return true

static func insert_garbage_rows(grid: Array, rows: Array) -> Dictionary:
	if not _valid_grid(grid):
		return {"valid":false,"overflow":false,"inserted":0}
	var normalized: Array = []
	for row in rows:
		if typeof(row) != TYPE_ARRAY or row.size() != WIDTH:
			return {"valid":false,"overflow":false,"inserted":0}
		var copy: Array[int] = []
		for value in row:
			if typeof(value) != TYPE_INT or int(value) < EMPTY or int(value) > GARBAGE:
				return {"valid":false,"overflow":false,"inserted":0}
			copy.append(int(value))
		normalized.append(copy)
	var next_grid: Array = grid.duplicate(true)
	var overflow := false
	var inserted := 0
	for row in normalized:
		var outgoing: Array = next_grid.pop_front()
		for value in outgoing:
			if int(value) != EMPTY:
				overflow = true
		next_grid.append(row.duplicate())
		inserted += 1
	grid.assign(next_grid)
	return {"valid":true,"overflow":overflow,"inserted":inserted}

static func clear_bottom_rows(grid: Array, requested_count: int) -> Dictionary:
	if not _valid_grid(grid):
		return {"valid":false,"cleared":0}
	var count := clampi(requested_count, 0, HEIGHT)
	for i in range(count):
		grid.pop_back()
		var empty_row: Array[int] = []
		empty_row.resize(WIDTH)
		empty_row.fill(EMPTY)
		grid.push_front(empty_row)
	return {"valid":true,"cleared":count}

static func build_rescue_rows(row_count: int, start_row: int, hole_count: int, seed_value: int, garbage_fill: int = GARBAGE) -> Array[Array]:
	var result: Array[Array] = []
	var safe_holes := clampi(hole_count, 1, WIDTH - 1)
	for row_index in range(clampi(row_count, 0, HEIGHT)):
		var row: Array[int] = []
		row.resize(WIDTH)
		row.fill(EMPTY)
		for x in range(WIDTH):
			var position := (x + seed_value + row_index * 3) % WIDTH
			if position >= safe_holes:
				row[x] = garbage_fill
		result.append(row)
	return result
