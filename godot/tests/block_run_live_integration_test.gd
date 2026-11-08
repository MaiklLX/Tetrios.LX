extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Main = preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN LIVE INTEGRATION TEST FAILED: " + message)
	quit(1)
	return false

func _main_probe() -> Node:
	var probe = Main.new()
	probe.game = Model.new()
	probe.game.reset()
	probe.mode_select_visible = false
	return probe

func _run() -> void:
	var probe = _main_probe()
	if not _check(probe.start_block_run_session(), "Live Block Run session must initialize from the current model board"):
		return
	# Force a deterministic line-progress delta, then lock one real model piece.
	probe.game.lines = 2
	probe.game.hard_drop()
	probe._process_block_run_events()
	if not _check(probe.block_run_session.placement_count == 1, "A live piece lock must dispatch exactly one placement event"):
		return
	if not _check(probe.block_run_session.total_lines == 2, "A lock carrying a line-progress delta must dispatch the line-clear event"):
		return
	probe._process_block_run_events()
	if not _check(probe.block_run_session.placement_count == 1 and probe.block_run_session.total_lines == 2, "Repeated frame processing must not dispatch the same lock or clear twice"):
		return
	probe.block_run_session.encounter.next_attack_seconds = 1
	probe._advance_block_run_clock(1.0)
	if not _check(probe.game.grid[22].count(7) == 9 and probe.block_run_session.board[22].count(7) == 9, "A timed enemy attack must mutate the live model board through the bridge"):
		return
	probe.free()

	var overflow_probe = _main_probe()
	if not _check(overflow_probe.start_block_run_session(), "Overflow probe session must initialize"):
		return
	overflow_probe.game.grid[0][0] = 4
	overflow_probe.block_run_session.encounter.next_attack_seconds = 1
	overflow_probe._advance_block_run_clock(1.0)
	if not _check(overflow_probe.block_run_session.status == "failed" and overflow_probe.game.game_over, "A garbage attack that pushes an occupied top row out must fail the live run"):
		return
	overflow_probe.free()
	print("Block Run live gameplay integration tests passed.")
	quit(0)
