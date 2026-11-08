extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Session = preload("res://scripts/block_run_session.gd")
const Bridge = preload("res://scripts/block_run_bridge.gd")
const Board = preload("res://scripts/block_run_board.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN BRIDGE TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var model = Model.new()
	model.reset()
	var session = Session.new()
	session.start()
	model.grid[22][0] = 3
	model.grid[21][9] = 5
	if not _check(Bridge.sync_model_to_session(model, session), "A valid live model board must sync into the encounter session"):
		return
	if not _check(session.board[22][0] == 3 and session.board[21][9] == 5, "Board sync must preserve every occupied tile and coordinate"):
		return
	session.board[22][0] = Board.GARBAGE
	session.board[21][9] = Board.EMPTY
	if not _check(Bridge.sync_session_to_model(session, model), "A valid encounter board must sync back into the live model"):
		return
	if not _check(model.grid[22][0] == Board.GARBAGE and model.grid[21][9] == Board.EMPTY, "Session mutations must return to the live model without coordinate drift"):
		return
	var before: Array = model.grid.duplicate(true)
	session.board[0].resize(1)
	if not _check(not Bridge.sync_session_to_model(session, model), "Malformed session boards must be rejected"):
		return
	if not _check(model.grid == before, "Rejected synchronization must not partially mutate the live model"):
		return
	model.grid = Model.new().grid
	model.reset()
	model.game_over = true
	if not _check(model.resume_after_board_rescue() and not model.game_over, "A clear live spawn must resume after a valid rescue"):
		return
	model.game_over = true
	var blocked_cell: Vector2i = model.origin + model.active_cells[0]
	model.grid[blocked_cell.y][blocked_cell.x] = 1
	if not _check(not model.resume_after_board_rescue() and model.game_over, "A still-blocked spawn must remain terminal after rescue validation"):
		return
	if not _check(not model.validate_active_piece_after_board_mutation() and model.game_over, "An enemy board shift that overlaps the falling piece must top out safely"):
		return
	print("Block Run live-board bridge tests passed.")
	quit(0)
