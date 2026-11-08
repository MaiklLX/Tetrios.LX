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

	main_scene.set("campaign_run_planet_id", 31)
	if not _check(bool(main_scene.call("_reset_campaign_piece_runtime")), "Planet 031 must initialize its authored campaign runtime"):
		return
	main_scene.set("campaign_run_active", true)
	var runtime: Variant = main_scene.get("campaign_piece_runtime")
	if not _check(runtime.active_piece_id == 7 and runtime.active_cells.size() == 5, "Planet 031 must explicitly spawn the five-cell Cargo Hook"):
		return
	if not _check(bool(main_scene.call("_rotate_active_piece")), "Campaign input router must rotate the isolated special piece"):
		return
	if not _check(int(main_scene.call("_hard_drop_active_piece")) >= 0 and runtime.active_piece_id >= 0 and runtime.active_piece_id < 7, "Locking Cargo Hook must continue with a standard campaign piece"):
		return
	if not _check(shared_game.grid == shared_grid and shared_game.origin == shared_origin and shared_game.active_type == shared_type, "Campaign gameplay must not mutate the shared Classic model"):
		return

	main_scene.set("campaign_run_active", false)
	var campaign_origin: Vector2i = runtime.origin
	var classic_origin: Vector2i = shared_game.origin
	if not _check(bool(main_scene.call("_move_piece_horizontal", 1)), "Non-campaign input must continue to route to the shared standard model"):
		return
	if not _check(runtime.origin == campaign_origin and shared_game.origin != classic_origin, "Classic input must not mutate the isolated campaign runtime"):
		return

	main_scene.set("campaign_run_planet_id", 1)
	if not _check(bool(main_scene.call("_reset_campaign_piece_runtime")), "Ordinary campaign planet must initialize its dedicated runtime"):
		return
	main_scene.set("campaign_run_active", true)
	runtime = main_scene.get("campaign_piece_runtime")
	if not _check(runtime.active_piece_id >= 0 and runtime.active_piece_id < 7 and runtime.active_cells.size() == 4, "Ordinary campaign planets must begin with a standard four-cell piece"):
		return
	main_scene.queue_free()
	print("Campaign live integration passed: Planet 031 authored Cargo Hook, campaign-only input/render state, standard follow-up piece, Classic model isolation and ordinary-planet standard spawn.")
	quit(0)
