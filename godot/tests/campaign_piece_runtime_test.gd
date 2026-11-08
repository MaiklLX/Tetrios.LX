extends SceneTree

const Runtime = preload("res://scripts/campaign_piece_runtime.gd")
const Model = preload("res://scripts/game_model.gd")
const Special = preload("res://scripts/campaign_special_piece.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN PIECE RUNTIME TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	seed(20261109)
	var runtime = Runtime.new()
	runtime.reset()
	if not _check(runtime.grid.size() == 23 and runtime.grid[0].size() == 10, "Campaign runtime must own an independent 10×23 board"):
		return
	if not _check(runtime.active_piece_id >= 0 and runtime.active_cells.size() == 4, "Runtime must start with a standard four-cell piece"):
		return
	if not _check(not runtime.spawn_authored_special(), "Authored special spawn must not discard a falling standard piece"):
		return
	runtime.reset(false)
	if not _check(runtime.spawn_authored_special() and runtime.active_piece_id == Runtime.SPECIAL_TYPE and runtime.active_cells.size() == 5, "Authored campaign event must explicitly spawn the five-cell Cargo Hook"):
		return
	if not _check(runtime.origin.x == 3 and runtime.rotation_index == 0, "Cargo Hook must spawn centered with base orientation"):
		return
	if not _check(runtime.rotate_piece() and runtime.rotation_index == 1 and runtime.active_cells.size() == 5, "Special rotation must retain all five cells"):
		return
	var previous_origin: Vector2i = runtime.origin
	var previous_rotation: int = runtime.rotation_index
	var previous_cells: Array[Vector2i] = runtime.active_cells.duplicate()
	for y in range(Runtime.HEIGHT):
		for x in range(Runtime.WIDTH):
			runtime.grid[y][x] = 0
	# Clear the active piece's footprint so the fixture can prove blocked rotation is atomic.
	for cell in runtime.active_cells:
		runtime.grid[(runtime.origin + cell).y][(runtime.origin + cell).x] = -1
	var blocked := runtime.rotate_piece()
	if not _check(not blocked and runtime.origin == previous_origin and runtime.rotation_index == previous_rotation and runtime.active_cells == previous_cells, "Blocked rotation must preserve the exact previous pose"):
		return
	runtime.reset(false)
	if not _check(runtime.spawn_authored_special(), "Special piece must spawn from an explicitly empty authored spawn slot"):
		return
	var special_id: int = runtime.active_piece_id
	if not _check(runtime.hold_piece() and runtime.held_piece_id == special_id and runtime.active_piece_id < 7 and runtime.active_cells.size() == 4, "Hold must safely move special→standard"):
		return
	var standard_id: int = runtime.active_piece_id
	if not _check(not runtime.hold_piece(), "Hold must be limited to once per active piece"):
		return
	# Complete the current standard piece, then swap standard→special.
	runtime.hard_drop()
	if not _check(not runtime.game_over and runtime.hold_used == false, "Locking must reset Hold eligibility and spawn a standard piece"):
		return
	if not _check(runtime.hold_piece() and runtime.active_piece_id == special_id and runtime.held_piece_id == standard_id and runtime.active_cells.size() == 5, "Hold must safely move standard→special"):
		return
	var snap := runtime.snapshot()
	var restored = Runtime.new()
	restored.reset()
	if not _check(restored.restore(snap) and restored.snapshot() == snap, "Campaign snapshot must round-trip special identity, geometry and Hold state"):
		return
	var preserved := restored.snapshot()
	var malformed := snap.duplicate(true)
	malformed.active_cells[0] = [9, 9]
	if not _check(not restored.restore(malformed) and restored.snapshot() == preserved, "Malformed geometry must be rejected without partial mutation"):
		return
	malformed = snap.duplicate(true)
	malformed.active_piece_id = 99
	if not _check(not restored.restore(malformed) and restored.snapshot() == preserved, "Unknown special-piece IDs must fail closed"):
		return
	malformed = snap.duplicate(true)
	malformed.grid[0].pop_back()
	if not _check(not restored.restore(malformed) and restored.snapshot() == preserved, "Malformed board dimensions must fail closed"):
		return
	# A special piece can clear a line and must use the same row compaction rules.
	var clear_runtime = Runtime.new()
	clear_runtime.reset()
	for x in range(Runtime.WIDTH):
		if x != 4:
			clear_runtime.grid[22][x] = 0
	clear_runtime.active_piece_id = Runtime.SPECIAL_TYPE
	clear_runtime.active_cells = Special.cells_for_rotation(0)
	clear_runtime.rotation_index = 0
	clear_runtime.origin = Vector2i(3, 20)
	if not _check(not clear_runtime._collides(clear_runtime.origin, clear_runtime.active_cells), "Line-clear fixture must have a valid special-piece placement"):
		return
	clear_runtime.hard_drop()
	if not _check(clear_runtime.lines == 1, "Five-cell special piece must participate in standard line-clear resolution"):
		return
	# Shared game model contract remains seven four-cell shapes.
	if not _check(Model.SHAPES.size() == 7, "Shared gameplay model must retain exactly seven standard tetrominoes"):
		return
	for shape in Model.SHAPES:
		if not _check(shape.size() == 4, "Every shared standard shape must remain four cells"):
			return
	if not _check(Model.SHAPES.size() == 7 and Model.WIDTH == Runtime.WIDTH and Model.HEIGHT == Runtime.HEIGHT, "Campaign runtime must reuse board dimensions without modifying shared model"):
		return
	print("Campaign piece runtime tests passed: isolated board, authored Cargo Hook spawn, rotation, collision, Hold both directions, lock/line clear, strict snapshot validation and seven-piece shared-model isolation.")
	quit(0)
