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

	var hold_probe = _main_probe()
	if not _check(hold_probe.start_block_run_session(), "Hold-collision probe session must initialize"):
		return
	hold_probe.game.grid[0].fill(2)
	hold_probe.game.hold_piece()
	if not _check(hold_probe.game.game_over, "A blocked replacement spawn from Hold must be detected by the model"):
		return
	hold_probe._process_block_run_events()
	if not _check(hold_probe.block_run_session.status == "failed", "A Hold-triggered spawn collision must reach Block Run rescue/failure handling even without a lock event"):
		return
	hold_probe.free()

	var shield_probe = _main_probe()
	if not _check(shield_probe.start_block_run_session(), "Shield rescue probe must initialize"):
		return
	if not _check(shield_probe.block_run_session.choose_card("shield"), "Shield must be drafted before the live rescue"):
		return
	var shield_spawn: Vector2i = shield_probe.game.origin + shield_probe.game.active_cells[0]
	shield_probe.game.grid[shield_spawn.y][shield_spawn.x] = 2
	shield_probe.game.game_over = true
	shield_probe._process_block_run_events()
	if not _check(shield_probe.block_run_session.status == "running" and not shield_probe.game.game_over, "Shield must clear the blocked spawn area and resume the live run"):
		return
	if not _check(shield_probe.block_run_session.shield_charges == 0 and shield_probe.game.grid[0][shield_spawn.x] == -1, "Live Shield rescue must consume one charge and remove the blocking top-row tile"):
		return
	shield_probe.free()

	var nova_probe = _main_probe()
	if not _check(nova_probe.start_block_run_session(), "Nova rescue probe must initialize"):
		return
	if not _check(nova_probe.block_run_session.choose_card("nova"), "Nova must be drafted before the live rescue"):
		return
	var nova_spawn: Vector2i = nova_probe.game.origin + nova_probe.game.active_cells[0]
	nova_probe.game.grid[nova_spawn.y][nova_spawn.x] = 3
	nova_probe.game.game_over = true
	nova_probe._process_block_run_events()
	if not _check(nova_probe.block_run_session.status == "running" and not nova_probe.game.game_over, "Nova bottom-row clear must shift the blocked spawn area clear and resume the live run"):
		return
	if not _check(nova_probe.block_run_session.nova_used and nova_probe.game.grid[0][nova_spawn.x] == -1, "Live Nova rescue must be consumed once and clear the spawn obstruction"):
		return
	nova_probe.free()
	print("Block Run live gameplay integration tests passed.")

	quit(0)
