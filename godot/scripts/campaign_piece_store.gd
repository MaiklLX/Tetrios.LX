class_name BlockBuddiesCampaignRunStore
extends RefCounted

# KT-539: campaign-only checkpoint storage. Never reads or writes the shared
# Classic / Sprint / Marathon / Block Run save formats.
const Runtime = preload("res://scripts/campaign_piece_runtime.gd")
const STORE_VERSION := 1
const DEFAULT_PATH := "user://campaign_run_v1.save"

static func _validated_payload(planet_id: int, snapshot: Dictionary) -> Dictionary:
	if planet_id < 1 or planet_id > 360:
		return {}
	var probe = Runtime.new()
	probe.reset()
	if not probe.restore(snapshot):
		return {}
	return {
		"store_version": STORE_VERSION,
		"planet_id": planet_id,
		"runtime": snapshot.duplicate(true)
	}

static func save_run(planet_id: int, runtime: Variant, path: String = DEFAULT_PATH, elapsed_seconds: float = 0.0) -> bool:
	if runtime == null or not runtime is BlockBuddiesCampaignPieceRuntime:
		return false
	var payload := _validated_payload(planet_id, runtime.snapshot())
	if payload.is_empty() or path.is_empty() or not is_finite(elapsed_seconds) or elapsed_seconds < 0.0:
		return false
	payload["elapsed_seconds"] = elapsed_seconds
	if payload.is_empty() or path.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(payload, false)
	file.flush()
	var write_ok := file.get_error() == OK
	file.close()
	return write_ok

static func load_run_state(planet_id: int, path: String = DEFAULT_PATH) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var payload: Variant = file.get_var(false)
	var read_ok := file.get_error() == OK
	file.close()
	if not read_ok or typeof(payload) != TYPE_DICTIONARY:
		return {}
	if typeof(payload.get("store_version")) != TYPE_INT or int(payload.store_version) != STORE_VERSION:
		return {}
	if typeof(payload.get("planet_id")) != TYPE_INT or int(payload.planet_id) != planet_id:
		return {}
	if typeof(payload.get("elapsed_seconds")) not in [TYPE_FLOAT, TYPE_INT]:
		return {}
	var elapsed := float(payload.elapsed_seconds)
	if not is_finite(elapsed) or elapsed < 0.0:
		return {}
	var saved_runtime: Variant = payload.get("runtime")
	if typeof(saved_runtime) != TYPE_DICTIONARY:
		return {}
	var probe = Runtime.new()
	probe.reset()
	if not probe.restore(saved_runtime):
		return {}
	return {"runtime": saved_runtime.duplicate(true), "elapsed_seconds": elapsed}

static func load_run(planet_id: int, runtime: Variant, path: String = DEFAULT_PATH) -> bool:
	if runtime == null or not runtime is BlockBuddiesCampaignPieceRuntime:
		return false
	var state := load_run_state(planet_id, path)
	if state.is_empty():
		return false
	# The destination is mutated only after the complete envelope and runtime
	# snapshot have passed validation.
	return runtime.restore(state.runtime)

static func clear_run(path: String = DEFAULT_PATH) -> bool:
	if path.is_empty():
		return false
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
