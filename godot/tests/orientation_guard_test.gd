extends SceneTree

const Main = preload("res://scripts/main.gd")


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ORIENTATION TEST FAILED: " + message)
	quit(1)
	return false


func _run() -> void:
	var scene = Main.new()
	root.add_child(scene)
	await process_frame

	if not _check(scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_LANDSCAPE, Vector2(800.0, 360.0), true, true), "mobile landscape gameplay must show the guard"):
		return
	if not _check(scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_REVERSE_LANDSCAPE, Vector2(800.0, 360.0), true, true), "reverse landscape must also show the guard"):
		return
	if not _check(not scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_PORTRAIT, Vector2(360.0, 800.0), true, true), "portrait gameplay must remain active"):
		return
	if not _check(not scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_REVERSE_PORTRAIT, Vector2(360.0, 800.0), true, true), "reverse portrait must remain active"):
		return
	if not _check(not scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_LANDSCAPE, Vector2(800.0, 360.0), false, true), "desktop landscape must not be blocked"):
		return
	if not _check(not scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_LANDSCAPE, Vector2(800.0, 360.0), true, false), "menus and completed runs must not be blocked"):
		return
	if not _check(scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_SENSOR, Vector2(800.0, 360.0), true, true), "unknown/sensor orientation must use the physical viewport aspect as fallback"):
		return
	if not _check(not scene.call("_should_show_orientation_guard", DisplayServer.SCREEN_SENSOR, Vector2(360.0, 800.0), true, true), "sensor fallback must accept portrait viewport dimensions"):
		return

	scene.call("_select_mode", "classic")
	scene.set("gravity_clock", 0.31)
	var game = scene.get("game")
	var lock_serial_before: int = game.lock_serial
	scene.call("_apply_orientation_guard", true)
	if not _check(bool(scene.get("orientation_guard_active")) and bool(scene.get("paused")), "entering landscape must pause the same active run"):
		return
	var mode_session = scene.get("mode_session")
	var elapsed_before: float = mode_session.elapsed_seconds
	scene.call("_process", 1.5)
	if not _check(is_equal_approx(float(scene.get("gravity_clock")), 0.31), "gravity must not advance while the orientation guard is active"):
		return
	if not _check(is_equal_approx(float(mode_session.elapsed_seconds), elapsed_before), "mode timer must not advance while the orientation guard is active"):
		return
	scene.call("_toggle_pause")
	if not _check(bool(scene.get("paused")), "pause input must not dismiss the orientation guard"):
		return
	scene.call("_handle_tap", scene.get("drop_rect").get_center())
	if not _check(int(game.lock_serial) == lock_serial_before, "touch input must not mutate the board while the orientation guard is active"):
		return
	scene.call("_apply_orientation_guard", false)
	if not _check(not bool(scene.get("orientation_guard_active")) and not bool(scene.get("paused")), "returning to portrait must resume a run that was not manually paused"):
		return

	scene.set("paused", true)
	scene.call("_apply_orientation_guard", true)
	scene.call("_apply_orientation_guard", false)
	if not _check(bool(scene.get("paused")), "returning to portrait must preserve a manual pause that existed before rotation"):
		return

	scene.queue_free()
	print("Portrait-first orientation guard tests passed.")
	quit(0)
