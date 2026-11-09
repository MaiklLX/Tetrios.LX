extends SceneTree

const Runtime = preload("res://scripts/campaign_piece_runtime.gd")
const Store = preload("res://scripts/campaign_piece_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN RUN STORE TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	seed(20261109)
	var path := "user://kt539_campaign_run_test.save"
	Store.clear_run(path)
	var source = Runtime.new()
	source.reset(false)
	if not _check(source.spawn_authored_special(), "Test fixture must spawn the authored Cargo Hook"):
		return
	if not _check(source.rotate_piece() and source.move_horizontal(-1), "Test fixture must preserve a non-default active pose"):
		return
	if not _check(source.hold_piece(), "Campaign Hold must accept special-to-standard"):
		return
	var expected := source.snapshot()
	if not _check(Store.save_run(31, source, path, 42.5), "Valid campaign snapshot must save with elapsed time"):
		return
	var saved_state: Dictionary = Store.load_latest_run_state(path)
	if not _check(int(saved_state.get("planet_id", 0)) == 31 and is_equal_approx(float(saved_state.get("elapsed_seconds", -1.0)), 42.5), "Latest checkpoint lookup must recover planet identity and elapsed time"):
		return
	var restored = Runtime.new()
	restored.reset()
	if not _check(Store.load_run(31, restored, path), "Matching planet checkpoint must load"):
		return
	if not _check(restored.snapshot() == expected, "Recovery must restore board, bag, Hold, score and active pose exactly"):
		return
	var preserved := restored.snapshot()
	if not _check(not Store.load_run(32, restored, path), "Checkpoint must not load into a different authored planet"):
		return
	if not _check(restored.snapshot() == preserved, "Wrong-planet rejection must not mutate the destination runtime"):
		return
	if not _check(not Store.save_run(0, source, path), "Invalid planet IDs must not overwrite a checkpoint"):
		return
	if not _check(restored.snapshot() == preserved, "Rejected save must leave the restored runtime unchanged"):
		return
	if not _check(Store.clear_run(path) and not FileAccess.file_exists(path), "Campaign checkpoint must be removable independently"):
		return
	if not _check(not Store.load_run(31, restored, path), "Missing checkpoint must fail closed"):
		return
	print("Campaign run store tests passed: isolated versioned envelope, exact recovery, planet binding, fail-closed validation and independent cleanup.")
	quit(0)
