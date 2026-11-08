extends SceneTree


func _initialize() -> void:
	call_deferred("_run")

func _assert_mobile_arena_spacing(scene: Node, viewport_size: Vector2i, label: String) -> bool:
	var board: Rect2 = scene.get("board_rect")
	var hold: Rect2 = scene.get("hold_rect")
	var skill: Rect2 = scene.get("block_run_skill_rect")
	var drop: Rect2 = scene.get("drop_rect")
	if drop.size.x > 0.0:
		if drop.position.x < board.end.x + 20.5 or drop.end.y > board.end.y - 5.0:
			push_error("%s: DROP button must sit above and clear of the board frame (drop=%s board=%s)." % [label, str(drop), str(board)])
			return false
	var frame_top := board.position.y - 16.0
	if hold.position.x < 0.0 or hold.end.x > float(viewport_size.x) or hold.position.y < 0.0 or hold.end.y > frame_top:
		push_error("%s: HOLD/NEXT preview cards leave the screen or touch the board frame (hold=%s board=%s)." % [label, str(hold), str(board)])
		return false
	if bool(scene.get("block_run_active")):
		if skill.size.x <= 0.0 or skill.position.x < 0.0 or skill.end.x > float(viewport_size.x) or skill.position.y < 0.0 or skill.end.y > frame_top:
			push_error("%s: hero skill card leaves the screen or touches the board frame (skill=%s)." % [label, str(skill)])
			return false
		# Keep 6px breathing room between HUD, goals, previews, and board.
		var goals_top := board.position.y - 122.0
		var goals_bottom := goals_top + 24.0
		if goals_top < 114.0:
			push_error("%s: goal strip is too close to the score HUD (goal_top=%s)." % [label, str(goals_top)])
			return false
		if hold.position.y < goals_bottom + 4.0:
			push_error("%s: goal strip and preview row overlap (goals_bottom=%s hold_top=%s)." % [label, str(goals_bottom), str(hold.position.y)])
			return false
	return true

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
	await process_frame
	await process_frame
	if not await _capture(viewport, "02-classic-arena"):
		quit(1)
		return
	var classic_board_rect: Rect2 = scene.get("board_rect")
	var classic_drop_rect: Rect2 = scene.get("drop_rect")
	var classic_mode_button: Rect2 = scene.get("mode_button_rect")
	var classic_pause_button: Rect2 = scene.get("pause_rect")
	var classic_stats_left := Rect2(42.0, 60.0, (float(viewport.size.x) - 100.0) * 0.48, 58.0)
	var classic_stats_right := Rect2(float(viewport.size.x) * 0.52, 60.0, (float(viewport.size.x) - 100.0) * 0.48, 58.0)
	if classic_mode_button.intersects(classic_stats_left) or classic_mode_button.intersects(classic_stats_right) or classic_pause_button.intersects(classic_stats_left) or classic_pause_button.intersects(classic_stats_right):
		push_error("Arena top utility controls overlap the score/HUD cards at 720x1280.")
		quit(1)
		return
	if classic_drop_rect.size.x < 52.0 or classic_drop_rect.size.y < 60.0 or classic_drop_rect.position.x < classic_board_rect.end.x + 20.5 or classic_drop_rect.end.x > float(viewport.size.x) - 12.0 or classic_drop_rect.position.y < classic_board_rect.position.y or classic_drop_rect.end.y > classic_board_rect.end.y - 5.0 or classic_drop_rect.intersects(classic_board_rect):
		push_error("Visible Drop control is missing, undersized, clipped, or overlaps the 10x23 board at 720x1280.")
		quit(1)
		return
	var classic_model = scene.get("game")
	var classic_lock_serial_before: int = classic_model.lock_serial
	scene.call("_handle_tap", classic_drop_rect.get_center())
	if int(classic_model.lock_serial) != classic_lock_serial_before + 1:
		push_error("Tapping the prominent Drop control did not hard-drop and lock the active piece at 720x1280.")
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
	await process_frame
	scene.call("_layout")
	var mobile_stat_card := Rect2(18.0, 56.0, (360.0 - 36.0 - 10.0) * 0.5, 52.0)
	if int(scene.call("_stat_label_font_size", mobile_stat_card, "ОЧКИ • СИН. 2")) < 10:
		push_error("Score HUD label is unnecessarily reduced below 9px at 360x800.")
		quit(1)
		return
	if int(scene.call("_stat_label_font_size", mobile_stat_card, "К1 • Э1 • 17С")) < 10:
		push_error("Block Run HUD label is unnecessarily reduced below 9px at 360x800.")
		quit(1)
		return
	var mobile_board_rect: Rect2 = scene.get("board_rect")
	var mobile_drop_rect: Rect2 = scene.get("drop_rect")
	var mobile_mode_button: Rect2 = scene.get("mode_button_rect")
	var mobile_pause_button: Rect2 = scene.get("pause_rect")
	var mobile_stats_left := Rect2(42.0, 60.0, (float(viewport.size.x) - 100.0) * 0.48, 58.0)
	var mobile_stats_right := Rect2(float(viewport.size.x) * 0.52, 60.0, (float(viewport.size.x) - 100.0) * 0.48, 58.0)
	if mobile_mode_button.intersects(mobile_stats_left) or mobile_mode_button.intersects(mobile_stats_right) or mobile_pause_button.intersects(mobile_stats_left) or mobile_pause_button.intersects(mobile_stats_right):
		push_error("Arena top utility controls overlap the score/HUD cards at 360x800.")
		quit(1)
		return
	if mobile_drop_rect.size.x < 52.0 or mobile_drop_rect.size.y < 60.0 or mobile_drop_rect.position.x < mobile_board_rect.end.x + 20.5 or mobile_drop_rect.end.x > float(viewport.size.x) - 12.0 or mobile_drop_rect.position.y < mobile_board_rect.position.y or mobile_drop_rect.end.y > mobile_board_rect.end.y - 5.0 or mobile_drop_rect.intersects(mobile_board_rect):
		push_error("Visible Drop control is missing, undersized, clipped, or overlaps the 10x23 board at 360x800.")
		quit(1)
		return
	if not _assert_mobile_arena_spacing(scene, Vector2i(360, 800), "360x800 Block Run"):
		quit(1)
		return
	var mobile_model = scene.get("game")
	var mobile_lock_serial_before: int = mobile_model.lock_serial
	scene.call("_handle_tap", mobile_drop_rect.get_center())
	if int(mobile_model.lock_serial) != mobile_lock_serial_before + 1:
		push_error("Tapping the prominent Drop control did not hard-drop and lock the active piece at 360x800 (drop=%s, board=%s)." % [str(mobile_drop_rect), str(mobile_board_rect)])
		quit(1)
		return
	scene.call("_restart_current_run")
	await process_frame
	await process_frame
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "08-mobile-360-arena"):
		quit(1)
		return
	# Check a second common phone size to catch scaling and edge-clipping regressions.
	viewport.size = Vector2i(412, 915)
	await process_frame
	scene.call("_layout")
	if not _assert_mobile_arena_spacing(scene, Vector2i(412, 915), "412x915 Block Run"):
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "20-mobile-412-block-run-arena"):
		quit(1)
		return
	viewport.size = Vector2i(360, 800)
	await process_frame
	scene.call("_layout")
	block_run_session = scene.get("block_run_session")
	block_run_session.status = "failed"
	scene.get("game").game_over = true
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "09-mobile-360-results"):
		quit(1)
		return
	# Live campaign navigation: atlas → universe route → planet detail.
	scene.set("home_visible", false)
	scene.set("mode_select_visible", false)
	scene.set("secondary_screen", "")
	scene.set("campaign_screen", "atlas")
	scene.set("campaign_universe", 0)
	scene.set("campaign_planet", 1)
	scene.set("gravity_clock", 0.25)
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "21-live-campaign-atlas"):
		quit(1)
		return
	if scene.get("campaign_atlas_rects").size() != 12:
		push_error("Live campaign atlas must expose all 12 universe hit targets.")
		quit(1)
		return
	var frozen_campaign_clock: float = scene.get("gravity_clock")
	scene.call("_handle_tap", scene.get("campaign_atlas_rects")[0].get_center())
	await process_frame
	await process_frame
	if str(scene.get("campaign_screen")) != "route" or scene.get("campaign_node_rects").size() != 30:
		push_error("Selecting a universe must open its 30-node route.")
		quit(1)
		return
	if not await _capture(viewport, "22-live-campaign-universe-route"):
		quit(1)
		return
	# Locked nodes can be inspected, but cannot launch a campaign run.
	scene.call("_handle_tap", scene.get("campaign_node_rects")[1].get_center())
	await process_frame
	await process_frame
	if str(scene.get("campaign_screen")) != "planet" or int(scene.get("campaign_planet")) != 2:
		push_error("Locked planet nodes should still open their detail screen.")
		quit(1)
		return
	scene.call("_handle_tap", scene.get("campaign_start_rect").get_center())
	if bool(scene.get("mode_select_visible")):
		push_error("A locked campaign planet must not enter mode selection.")
		quit(1)
		return
	scene.call("_handle_tap", scene.get("campaign_back_rect").get_center())
	await process_frame
	await process_frame
	scene.call("_handle_tap", scene.get("campaign_node_rects")[0].get_center())
	await process_frame
	await process_frame
	if str(scene.get("campaign_screen")) != "planet" or int(scene.get("campaign_planet")) != 1:
		push_error("Selecting the open first planet must open its detail screen.")
		quit(1)
		return
	if not await _capture(viewport, "23-live-campaign-planet-detail"):
		quit(1)
		return
	if absf(float(scene.get("gravity_clock")) - frozen_campaign_clock) > 0.0001:
		push_error("Gameplay gravity clock advanced while navigating the campaign.")
		quit(1)
		return
	scene.call("_handle_tap", scene.get("campaign_start_rect").get_center())
	if not bool(scene.get("campaign_run_active")) or bool(scene.get("mode_select_visible")):
		push_error("Starting the unlocked planet must launch its campaign level directly.")
		quit(1)
		return
	var campaign_session = scene.get("mode_session")
	if campaign_session.mode_id != "campaign" or int(campaign_session.rules.get("target_lines", 0)) != 10:
		push_error("Planet 001 must launch a campaign session with its own ten-line objective.")
		quit(1)
		return
	await process_frame
	await process_frame
	if not await _capture(viewport, "24-live-campaign-level"):
		quit(1)
		return
	scene.get("game").lines = 10
	scene.get("game").score = int(scene.get("campaign_progress").get_planet_definition(1).target_score)
	campaign_session.update(0.0, 10, false, int(scene.get("game").score))
	scene.call("_process_campaign_completion")
	if int(scene.get("campaign_progress").unlocked_node) != 2 or int(scene.get("campaign_progress").campaign_marks) != 1:
		push_error("Completing planet 001 must grant one mark and unlock planet 002.")
		quit(1)
		return
	scene.queue_redraw()
	await process_frame
	await process_frame
	if not await _capture(viewport, "25-live-campaign-level-complete"):
		quit(1)
		return
	scene.call("_handle_tap", Vector2(180.0, 400.0))
	await process_frame
	await process_frame
	if str(scene.get("campaign_screen")) != "route" or bool(scene.get("campaign_run_active")):
		push_error("Campaign completion must return to the updated universe route.")
		quit(1)
		return
	if not await _capture(viewport, "26-live-campaign-progress"):
		quit(1)
		return
	scene.call("_handle_tap", scene.get("campaign_back_rect").get_center())
	await process_frame
	await process_frame
	scene.call("_handle_tap", scene.get("campaign_back_rect").get_center())
	await process_frame
	await process_frame
	if not bool(scene.get("home_visible")) or not str(scene.get("campaign_screen")).is_empty():
		push_error("Campaign back navigation must return cleanly to the Home hub.")
		quit(1)
		return
	# The following five screens are a static art-direction gallery, not live
	# commerce/profile UI. It lets the user review the complete visual language
	# before we connect navigation, inventory, currencies or persistent data.
	scene.queue_free()
	await process_frame
	viewport.size = Vector2i(720, 1280)
	var gallery_packed := load("res://scenes/ui_concept_gallery.tscn") as PackedScene
	if gallery_packed == null:
		push_error("UI concept gallery scene could not be loaded.")
		quit(1)
		return
	var gallery := gallery_packed.instantiate()
	if gallery.get_script() == null or not gallery.has_method("_draw"):
		push_error("UI concept gallery script did not load; refusing to save blank concept captures.")
		quit(1)
		return
	viewport.add_child(gallery)
	for screen in [
		{"id":"home","file":"10-concept-home-menu"},
		{"id":"shop","file":"11-concept-shop"},
		{"id":"heroes","file":"12-concept-hero-roster"},
		{"id":"upgrades","file":"13-concept-upgrades"},
		{"id":"block_run","file":"14-concept-block-run-hub"},
		{"id":"campaign","file":"15-concept-cosmic-atlas"},
		{"id":"universe_route","file":"16-concept-universe-route"},
		{"id":"planet_detail","file":"17-concept-planet-detail"},
		{"id":"daily","file":"18-concept-daily-calendar"}
	]:
		gallery.set("screen_id", screen.id)
		gallery.queue_redraw()
		await process_frame
		await process_frame
		if not await _capture(viewport, screen.file):
			quit(1)
			return
		if screen.id == "home":
			viewport.size = Vector2i(360, 800)
			gallery.queue_redraw()
			await process_frame
			await process_frame
			if not await _capture(viewport, "19-concept-home-360x800"):
				quit(1)
				return
			viewport.size = Vector2i(720, 1280)
			gallery.queue_redraw()
			await process_frame
			await process_frame
	print("Gameplay and secondary-screen concept captures completed.")
	quit(0)
