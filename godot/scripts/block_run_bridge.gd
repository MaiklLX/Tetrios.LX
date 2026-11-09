class_name BlockBuddiesBlockRunBridge
extends RefCounted

const Board = preload("res://scripts/block_run_board.gd")

# The classic model owns the live piece and score. Block Run owns encounter
# rules and board mutations. These methods are the only supported boundary
# between their two 10x23 grids.
static func sync_model_to_session(model: BlockBuddiesModel, session: BlockBuddiesBlockRunSession) -> bool:
	if model == null or session == null or session.status != session.STATUS_RUNNING:
		return false
	if not _valid_model_grid(model.grid):
		return false
	var copied: Array = []
	for row in model.grid:
		var next_row: Array[int] = []
		for value in row:
			next_row.append(int(value))
		copied.append(next_row)
	session.board = copied
	return true

static func sync_session_to_model(session: BlockBuddiesBlockRunSession, model: BlockBuddiesModel) -> bool:
	if model == null or session == null or session.status != session.STATUS_RUNNING:
		return false
	if not Board._valid_grid(session.board):
		return false
	var copied: Array = []
	for row in session.board:
		var next_row: Array[int] = []
		for value in row:
			next_row.append(int(value))
		copied.append(next_row)
	model.grid = copied
	return true

static func _valid_model_grid(grid: Array) -> bool:
	if grid.size() != Board.HEIGHT:
		return false
	for row in grid:
		if typeof(row) != TYPE_ARRAY or row.size() != Board.WIDTH:
			return false
		for value in row:
			if typeof(value) != TYPE_INT or int(value) < Board.EMPTY or int(value) > Board.GARBAGE:
				return false
	return true

# Attempt a rescue against the latest live board. A rescue is accepted only
# if the current falling piece can actually occupy its spawn position after
# the board mutation; otherwise both systems remain terminal.
static func rescue_spawn_collision(model: BlockBuddiesModel, session: BlockBuddiesBlockRunSession) -> Dictionary:
	if not sync_model_to_session(model, session):
		return {"accepted":false,"rescued":false,"reason":"invalid_state"}
	var rescue: Dictionary = session.on_spawn_collision()
	if not bool(rescue.get("rescued", false)):
		return rescue
	if not sync_session_to_model(session, model):
		return {"accepted":false,"rescued":false,"reason":"invalid_rescue_board"}
	if model.resume_after_board_rescue():
		rescue["live_resumed"] = true
		return rescue
	session.status = session.STATUS_FAILED
	rescue["live_resumed"] = false
	rescue["reason"] = "spawn_still_blocked"
	return rescue
