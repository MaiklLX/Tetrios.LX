extends SceneTree

const MainScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN LIVE INTEGRATION TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var main_scene: Node = MainScene.instantiate()
	root.add_child(main_scene)
	await process_frame
	var shared_game: Variant = main_scene.get("game")
	var shared_grid: Array = shared_game.grid.duplicate(true)
	var shared_origin: Vector2i = shared_game.origin
	var shared_type: int = shared_game.active_type
	var progress: Variant = main_scene.get("campaign_progress")
	progress.reset()

	# Exercise the real campaign launch path on an ordinary unlocked planet.
	main_scene.set("campaign_universe", 0)
	main_scene.set("campaign_planet", 1)
	main_scene.call("_start_campaign_planet")
	if not _check(bool(main_scene.get("campaign_run_active")), "Planet 001 must launch through the live campaign entry point"):
		return
	var runtime: Variant = main_scene.get("campaign_piece_runtime")
	if not _check(runtime.active_piece_id >= 0 and runtime.active_piece_id < 7 and runtime.active_cells.size() == 4, "Ordinary campaign planets must start with a standard four-cell piece"):
		return
	if not _check(shared_game.grid == shared_grid and shared_game.origin == shared_origin and shared_game.active_type == shared_type, "Campaign launch must not reset or mutate the shared Classic model"):
		return

	# Retry must also stay inside the campaign-owned runtime.
	main_scene.call("_restart_current_run")
	if not _check(bool(main_scene.get("campaign_run_active")) and shared_game.grid == shared_grid and shared_game.origin == shared_origin and shared_game.active_type == shared_type, "Campaign retry must not reset or mutate the shared Classic model"):
		return

	# Unlock the next universe in the in-memory test fixture, then launch Planet 031.
	progress.import_legacy_progress(31, 0)
	main_scene.set("campaign_universe", 1)
	main_scene.set("campaign_planet", 1)
	main_scene.call("_start_campaign_planet")
	if not _check(bool(main_scene.get("campaign_run_active")), "Unlocked Planet 031 must launch through the live campaign entry point"):
		return
	runtime = main_scene.get("campaign_piece_runtime")
	if not _check(runtime.active_piece_id == 7 and runtime.active_cells.size() == 5, "Planet 031 must explicitly spawn the five-cell Cargo Hook"):
		return
	if not _check(bool(main_scene.call("_rotate_active_piece")), "Campaign input router must rotate the isolated special piece"):
		return
	if not _check(int(main_scene.call("_hard_drop_active_piece")) >= 0 and runtime.active_piece_id >= 0 and runtime.active_piece_id < 7, "Locking Cargo Hook must continue with a standard campaign piece"):
		return
	if not _check(shared_game.grid == shared_grid and shared_game.origin == shared_origin and shared_game.active_type == shared_type, "Campaign gameplay must not mutate the shared Classic model"):
		return

	# KT-543.1: the authored catalog schedules Cargo Hook on Star Caravan planets 056 and 057.
	progress.import_legacy_progress(56, 0)
	main_scene.set("campaign_universe", 1)
	main_scene.set("campaign_planet", 26)
	main_scene.call("_start_campaign_planet")
	runtime = main_scene.get("campaign_piece_runtime")
	if not _check(bool(main_scene.get("campaign_run_active")) and runtime.active_piece_id == 7 and runtime.active_cells.size() == 5, "Authored Planet 056 must launch with the five-cell Cargo Hook"):
		return
	progress.import_legacy_progress(57, 0)
	main_scene.set("campaign_planet", 27)
	main_scene.call("_start_campaign_planet")
	runtime = main_scene.get("campaign_piece_runtime")
	if not _check(bool(main_scene.get("campaign_run_active")) and runtime.active_piece_id == 7 and runtime.active_cells.size() == 5, "Authored Planet 057 must launch with the five-cell Cargo Hook"):
		return

	# KT-545: Planet 033 must start from its authored deterministic Cargo Corridor board.
	main_scene.call("_return_to_campaign_route")
	progress.import_legacy_progress(33, 0)
	main_scene.set("campaign_universe", 1)
	main_scene.set("campaign_planet", 3)
	main_scene.call("_start_campaign_planet")
	runtime = main_scene.get("campaign_piece_runtime")
	var layout_cells := 0
	for row in runtime.grid:
		for value in row:
			if int(value) >= 0:
				layout_cells += 1
	if not _check(bool(main_scene.get("campaign_run_active")) and layout_cells == 26 and runtime.active_piece_id >= 0 and runtime.active_piece_id < 7, "Planet 033 must launch with its authored board and a standard active piece"):
		return
	# KT-545.2: verify the other authored layout families through the real launch path.
	main_scene.call("_return_to_campaign_route")
	progress.import_legacy_progress(36, 0)
	main_scene.set("campaign_planet", 6)
	main_scene.call("_start_campaign_planet")
	runtime = main_scene.get("campaign_piece_runtime")
	layout_cells = 0
	for row in runtime.grid:
		for value in row:
			if int(value) >= 0:
				layout_cells += 1
	if not _check(bool(main_scene.get("campaign_run_active")) and layout_cells == 27 and runtime.active_piece_id >= 0 and runtime.active_piece_id < 7, "Planet 036 must launch its authored Offset Bay layout with a standard piece"):
		return
	main_scene.call("_return_to_campaign_route")
	progress.import_legacy_progress(46, 0)
	main_scene.set("campaign_planet", 16)
	main_scene.call("_start_campaign_planet")
	runtime = main_scene.get("campaign_piece_runtime")
	layout_cells = 0
	for row in runtime.grid:
		for value in row:
			if int(value) >= 0:
				layout_cells += 1
	if not _check(bool(main_scene.get("campaign_run_active")) and layout_cells == 27 and runtime.active_piece_id >= 0 and runtime.active_piece_id < 7, "Planet 046 must launch its authored Staggered Joint layout with a standard piece"):
		return

	main_scene.set("campaign_run_active", false)
	var campaign_origin: Vector2i = runtime.origin
	var classic_origin: Vector2i = shared_game.origin
	if not _check(bool(main_scene.call("_move_piece_horizontal", 1)), "Non-campaign input must continue to route to the shared standard model"):
		return
	if not _check(runtime.origin == campaign_origin and shared_game.origin != classic_origin, "Classic input must not mutate the isolated campaign runtime"):
		return

	# KT-544B: Planet 040 is a live three-phase boss encounter, isolated to Campaign.
	progress.import_legacy_progress(40, 0)
	main_scene.set("campaign_universe", 1)
	main_scene.set("campaign_planet", 10)
	main_scene.call("_start_campaign_planet")
	if not _check(bool(main_scene.get("campaign_run_active")), "Unlocked Planet 040 must launch its authored boss encounter"):
		return
	var boss_session: Variant = main_scene.get("mode_session")
	var boss_runtime: Variant = main_scene.get("campaign_piece_runtime")
	if not _check(boss_session.has_boss_phases() and boss_session.rules.boss_phases.size() == 3, "Planet 040 must load three authored boss phases"):
		return
	boss_runtime.lines = 4
	boss_runtime.score = 200
	boss_session.update(1.0, boss_runtime.lines, false, boss_runtime.score)
	if not _check(boss_session.boss_phase_index == 1 and boss_session.status == "running", "Completing the first phase must advance but not finish the boss"):
		return
	boss_runtime.lines = 8
	boss_runtime.score = 650
	boss_session.update(1.0, boss_runtime.lines, false, boss_runtime.score)
	if not _check(boss_session.boss_phase_index == 2 and boss_session.status == "running", "Completing the second phase must enter the final boss phase"):
		return
	boss_runtime.lines = 12
	boss_runtime.score = 1620
	boss_session.update(1.0, boss_runtime.lines, false, boss_runtime.score)
	main_scene.call("_process_campaign_completion")
	if not _check(boss_session.status == "completed" and progress.unlocked_node == 41 and progress.campaign_marks == 5, "The final phase must complete Planet 040 and grant its boss reward exactly once"):
		return

	main_scene.queue_free()
	print("Campaign live integration passed: real Planet 001/031 launch, campaign retry isolation, authored Cargo Hook, standard follow-up piece, Classic model isolation, standard-mode routing and live three-phase Planet 040 boss completion.")
	quit(0)
