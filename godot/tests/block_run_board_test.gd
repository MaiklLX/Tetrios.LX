extends SceneTree

const Board = preload("res://scripts/block_run_board.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN BOARD TEST FAILED: " + message)
	quit(1)
	return false

func _grid() -> Array:
	var grid: Array = []
	for y in range(Board.HEIGHT):
		var row: Array[int] = []
		row.resize(Board.WIDTH)
		row.fill(Board.EMPTY)
		grid.append(row)
	return grid

func _run() -> void:
	var grid := _grid()
	var breach: Array[int] = []
	breach.resize(Board.WIDTH)
	breach.fill(Board.GARBAGE)
	breach[4] = 0
	var insert := Board.insert_garbage_rows(grid, [breach])
	if not _check(insert["valid"] and not insert["overflow"] and insert["inserted"] == 1, "Garbage insertion must preserve a valid empty board"):
		return
	if not _check(grid[Board.HEIGHT - 1][4] == 0 and grid[Board.HEIGHT - 1].count(Board.GARBAGE) == 9, "Garbage row must enter at the bottom without altering its hole"):
		return
	var dirty := _grid()
	dirty[0][0] = 2
	var overflow := Board.insert_garbage_rows(dirty, [breach])
	if not _check(overflow["valid"] and overflow["overflow"] and dirty[Board.HEIGHT - 1][4] == 0, "Occupied top cells must report overflow when garbage pushes the board upward"):
		return
	var invalid := Board.insert_garbage_rows(_grid(), [[7,7,7]])
	if not _check(not invalid["valid"] and invalid["inserted"] == 0, "Malformed garbage rows must be rejected atomically"):
		return
	var clear_grid := _grid()
	clear_grid[Board.HEIGHT - 1][0] = 3
	clear_grid[Board.HEIGHT - 2][1] = 4
	var clear := Board.clear_bottom_rows(clear_grid, 2)
	if not _check(clear["valid"] and clear["cleared"] == 2 and clear_grid[Board.HEIGHT - 1].count(Board.EMPTY) == Board.WIDTH and clear_grid[Board.HEIGHT - 2].count(Board.EMPTY) == Board.WIDTH, "Bottom-row rescue must clear rows and preserve board height"):
		return
	var rescue := Board.build_rescue_rows(5, 18, 2, 3)
	if not _check(rescue.size() == 5 and rescue[0].count(0) == 0 and rescue[0].count(Board.GARBAGE) == 8, "Rescue rows must preserve deterministic holes and fill count"):
		return
	if not _check(Board.build_rescue_rows(1, 0, 1, 0)[0].count(Board.GARBAGE) == 9, "Single-hole rescue pattern must leave exactly one passage"):
		return
	print("Block Run board mutation tests passed.")
	quit(0)
