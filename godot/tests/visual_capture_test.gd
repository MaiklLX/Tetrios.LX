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
	await process_frame
	await process_frame
	if not await _capture(viewport, "02-classic-arena"):
		quit(1)
		return
	if not bool(scene.call("start_block_run_session")):
		push_error("Block Run session did not initialize for visual capture.")
		quit(1)
		return
	var block_run_session = scene.get("block_run_session")
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
	print("Visual smoke captures completed.")
	quit(0)
