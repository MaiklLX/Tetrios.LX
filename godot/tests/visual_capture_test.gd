extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _save_capture(scene_name: String) -> bool:
	var directory := ProjectSettings.globalize_path("res://../artifacts/screenshots")
	var make_result := DirAccess.make_dir_recursive_absolute(directory)
	if make_result != OK and make_result != ERR_ALREADY_EXISTS:
		push_error("Could not create screenshot directory: %s" % make_result)
		return false
	var image := get_root().get_texture().get_image()
	if image.is_empty():
		push_error("Viewport image is empty; screenshot capture is unavailable in this runner.")
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
	var scene := packed.instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	if not _save_capture("01-mode-selector"):
		quit(1)
		return
	scene.call("_select_mode", "classic")
	await process_frame
	await process_frame
	if not _save_capture("02-classic-arena"):
		quit(1)
		return
	print("Visual smoke captures completed.")
	quit(0)
