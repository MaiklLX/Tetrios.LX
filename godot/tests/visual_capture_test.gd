extends SceneTree


func _initialize() -> void:
	call_deferred("_run")

func _capture(viewport: SubViewport, scene_name: String) -> bool:
	await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	if texture == null:
		push_error("SubViewport texture is unavailable for %s." % scene_name)
		return false
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("Rendered image is empty for %s." % scene_name)
		return false
	var directory := ProjectSettings.globalize_path("res://../artifacts/screenshots")
	var make_result := DirAccess.make_dir_recursive_absolute(directory)
	if make_result != OK and make_result != ERR_ALREADY_EXISTS:
		push_error("Could not create screenshot directory: %s" % make_result)
		return false
	var path := directory.path_join(scene_name + ".png")
	var save_result := image.save_png(path)
	if save_result != OK:
		push_error("Could not save screenshot %s: %s" % [path, save_result])
		return false
	print("SCREENSHOT_SAVED=", path, " SIZE=", image.get_width(), "x", image.get_height())
	return true

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene could not be loaded for visual capture.")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	get_root().add_child(viewport)
	var scene := packed.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	if not await _capture(viewport, "01-mode-selector"):
		quit(1)
		return
	scene.call("_select_mode", "classic")
	var buddy = scene.get("buddy")
	var buddy_test_model = scene.get("game")
	buddy_test_model.lines = 1
	scene.call("_sync_buddy_state")
	if buddy.state != "happy" or not buddy.visible:
		push_error("Buddy must remain visible and happy after a normal line clear.")
		quit(1)
		return
	buddy_test_model.lines = 5
	scene.call("_sync_buddy_state")
	if buddy.state != "victory" or not buddy.visible:
		push_error("Buddy must remain visible and celebrate a four-line clear.")
		quit(1)
		return
	buddy_test_model.lines = 0
	scene.set("buddy_last_lines", 0)
	buddy.set_state("idle", 0.0)
	scene.call("_sync_buddy_state")
	await process_frame
	await process_frame
	if not await _capture(viewport, "02-classic-arena"):
		quit(1)
		return
	var classic_board_rect: Rect2 = scene.get("board_rect")
	var classic_drop_rect: Rect2 = scene.get("drop_rect")
	if classic_drop_rect.size.x < 42.0 or classic_drop_rect.size.y < 44.0 or classic_drop_rect.position.x < classic_board_rect.end.x + 5.0 or classic_drop_rect.end.x > float(viewport.size.x) - 7.0 or classic_drop_rect.intersects(classic_board_rect):
		push_error("Visible Drop control is missing, undersized, or overlaps the 10x23 board at 720x1280.")
		quit(1)
		return
	var classic_model = scene.get("game")
	var lock_serial_before: int = classic_model.lock_serial
	scene.call("_handle_tap", classic_drop_rect.get_center())
	if int(classic_model.lock_serial) != lock_serial_before + 1:
		push_error("Tapping the visible Drop control did not hard-drop and lock the active piece.")
		quit(1)
		return
	scene.call("_select_mode", "classic")
	await process_frame
	await process_frame
	if not bool(scene.call("start_block_run_session")):
		push_error("Block Run session did not initialize for visual capture.")
		quit(1)
		return
	var block_run_session = scene.get("block_run_session")
	block_run_session.total_lines = 2
	block_run_session.score = 300
	block_run_session.run_seconds = 8
	block_run_session.encounter.next_attack_seconds = 17
	block_run_session.goals.clear()
	block_run_session.goals.append({"id":1,"type":"lines","label":"Очистить линии","target":5,"reward":15,"claimed":false})
	block_run_session.goals.append({"id":2,"type":"score","label":"Набрать очки","target":600,"reward":20,"claimed":false})
	block_run_session.goals.append({"id":3,"type":"survive","label":"Продержаться, секунд","target":20,"reward":12,"claimed":false})
	if not block_run_session.choose_card("score") or not block_run_session.choose_card("mult"):
		push_error("Could not prepare the synergy state for Block Run HUD capture.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "04-block-run-goals-hud"):
		quit(1)
		return
	var draft_event: Dictionary = block_run_session.on_line_clear(5, 0, 1)
	if draft_event.draft_cards.size() != 3:
		push_error("Block Run card draft did not open for visual capture.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "03-block-run-card-draft"):
		quit(1)
		return
	var capture_card_id := str(block_run_session.pending_card_draft[0].get("id", ""))
	if not block_run_session.choose_card(capture_card_id):
		push_error("Could not close the draft before hero skill visual capture.")
		quit(1)
		return
	if not bool(scene.call("configure_block_run_hero", "prism", 5)):
		push_error("Could not configure a level-five hero for skill HUD capture.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "05-block-run-hero-skill-ready"):
		quit(1)
		return
	var skill_result: Dictionary = scene.call("activate_block_run_hero_skill")
	if not bool(skill_result.get("accepted", false)) or int(block_run_session.hero_skill_cooldown_seconds) != 45:
		push_error("Hero skill did not activate with the expected cooldown for visual capture.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "06-block-run-hero-skill-cooldown"):
		quit(1)
		return
	block_run_session.goal_rewards_earned = 47
	block_run_session.goal_reward_receipts["capture-goal-1"] = {"id":"capture-goal-1","goal_id":1,"reward":25,"claimed":true}
	block_run_session.status = "failed"
	scene.get("game").game_over = true
	scene.call("_sync_buddy_state")
	var result_buddy = scene.get("buddy")
	if not result_buddy.visible or result_buddy.state != "surprised":
		push_error("Buddy must stay visible and react with surprise during game-over results.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "07-block-run-results"):
		quit(1)
		return
	scene.call("_restart_current_run")
	if bool(scene.get("game").game_over) or scene.get("block_run_session").status != "running":
		push_error("Block Run result restart did not initialize a fresh playable session.")
		quit(1)
		return
	# Capture a narrow portrait viewport as well as the desktop-sized reference.
	viewport.size = Vector2i(360, 800)
	scene.call("_layout")
	var mobile_board_rect: Rect2 = scene.get("board_rect")
	var mobile_drop_rect: Rect2 = scene.get("drop_rect")
	if mobile_drop_rect.size.x < 42.0 or mobile_drop_rect.size.y < 44.0 or mobile_drop_rect.position.x < mobile_board_rect.end.x + 5.0 or mobile_drop_rect.end.x > float(viewport.size.x) - 7.0 or mobile_drop_rect.intersects(mobile_board_rect):
		push_error("Visible Drop control is missing, undersized, or overlaps the 10x23 board at 360x800.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "08-mobile-360-arena"):
		quit(1)
		return
	block_run_session = scene.get("block_run_session")
	block_run_session.status = "failed"
	scene.get("game").game_over = true
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "09-mobile-360-results"):
		quit(1)
		return
	print("Visual smoke captures completed.")
	quit(0)
