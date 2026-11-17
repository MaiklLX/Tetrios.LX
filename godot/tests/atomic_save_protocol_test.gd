extends SceneTree

const AtomicSave = preload("res://scripts/atomic_save_protocol.gd")


class MemoryStorage:
	extends RefCounted

	var files: Dictionary = {}
	var fail_operation := ""
	var operations: Array[String] = []

	func read_text(path: String) -> Dictionary:
		operations.append("read:" + path)
		if fail_operation == "read:" + path:
			fail_operation = ""
			return {"ok": false, "exists": false, "text": ""}
		return {"ok": true, "exists": files.has(path), "text": str(files.get(path, ""))}

	func write_text(path: String, contents: String) -> bool:
		operations.append("write:" + path)
		if fail_operation == "write:" + path:
			fail_operation = ""
			return false
		files[path] = contents
		return true

	func flush(path: String) -> bool:
		operations.append("flush:" + path)
		if fail_operation == "flush:" + path:
			fail_operation = ""
			return false
		return files.has(path)

	func replace_file(source_path: String, destination_path: String) -> bool:
		operations.append("replace:" + destination_path)
		if fail_operation == "replace:" + destination_path:
			fail_operation = ""
			return false
		if not files.has(source_path):
			return false
		# Model an atomic rename: destination changes only after success.
		files[destination_path] = files[source_path]
		files.erase(source_path)
		return true


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("ATOMIC SAVE TEST FAILED: " + message)
	quit(1)
	return false


func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return is_equal_approx(float(value), float(roundi(float(value))))
	return false


func _is_valid_profile(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var version: Variant = value.get("schema_version")
	var profile: Variant = value.get("profile")
	if typeof(profile) != TYPE_DICTIONARY:
		return false
	var coins: Variant = profile.get("coins")
	return _is_integer_number(version) and int(version) == 1 and _is_integer_number(coins) and int(coins) >= 0


func _profile(coins: int) -> Dictionary:
	return {"schema_version": 1, "profile": {"coins": coins}}


func _coins(serialized: String) -> int:
	var parsed: Variant = JSON.parse_string(serialized)
	if typeof(parsed) != TYPE_DICTIONARY:
		return -1
	return int(parsed.get("profile", {}).get("coins", -1))


func _run() -> void:
	var validator := Callable(self, "_is_valid_profile")
	var old_text := JSON.stringify(_profile(70))
	var prior_backup_text := JSON.stringify(_profile(60))
	var new_profile := _profile(80)

	print("Atomic save tests: successful rotation")
	var success_storage := MemoryStorage.new()
	success_storage.files["profile.json"] = old_text
	success_storage.files["profile.json.bak"] = prior_backup_text
	var success := AtomicSave.save_document(success_storage, "profile.json", new_profile, validator)
	print("Atomic save diagnostic: validator_valid=", validator.is_valid(), " candidate_valid=", validator.call(new_profile))
	print("Atomic save diagnostic: adapter_methods=", success_storage.has_method("read_text"), "/", success_storage.has_method("write_text"), "/", success_storage.has_method("flush"), "/", success_storage.has_method("replace_file"))
	print("Atomic save diagnostic: result=", success, " operations=", success_storage.operations, " files=", success_storage.files)
	if not _check(success.ok, "A valid candidate must be promoted"):
		return
	if not _check(_coins(success_storage.files["profile.json"]) == 80, "The new candidate must become active"):
		return
	if not _check(_coins(success_storage.files["profile.json.bak"]) == 70, "The previous active save must become the backup"):
		return

	print("Atomic save tests: invalid candidate has no storage side effects")
	var invalid_storage := MemoryStorage.new()
	invalid_storage.files["profile.json"] = old_text
	var invalid_candidate := {"schema_version": 2, "profile": {"coins": 999}}
	var invalid_result := AtomicSave.save_document(invalid_storage, "profile.json", invalid_candidate, validator)
	if not _check(not invalid_result.ok and invalid_storage.operations.is_empty(), "Unknown candidate schema must be rejected before storage is touched"):
		return
	if not _check(invalid_storage.files["profile.json"] == old_text, "Rejected candidate must leave active bytes unchanged"):
		return
	var fractional_storage := MemoryStorage.new()
	var fractional_candidate := {"schema_version": 1, "profile": {"coins": 80.5}}
	var fractional_result := AtomicSave.save_document(fractional_storage, "profile.json", fractional_candidate, validator)
	if not _check(not fractional_result.ok and fractional_storage.operations.is_empty(), "Fractional profile values must be rejected before storage is touched"):
		return

	print("Atomic save tests: backup promotion failure")
	var backup_failure := MemoryStorage.new()
	backup_failure.files["profile.json"] = old_text
	backup_failure.files["profile.json.bak"] = prior_backup_text
	backup_failure.fail_operation = "replace:profile.json.bak"
	var backup_failure_result := AtomicSave.save_document(backup_failure, "profile.json", new_profile, validator)
	if not _check(not backup_failure_result.ok, "Backup promotion failure must stop the save"):
		return
	if not _check(backup_failure.files["profile.json"] == old_text and backup_failure.files["profile.json.bak"] == prior_backup_text, "Backup failure must preserve both previous documents"):
		return

	print("Atomic save tests: interrupted active temp write")
	var temp_failure := MemoryStorage.new()
	temp_failure.files["profile.json"] = old_text
	temp_failure.files["profile.json.bak"] = prior_backup_text
	temp_failure.fail_operation = "flush:profile.json.tmp"
	var temp_failure_result := AtomicSave.save_document(temp_failure, "profile.json", new_profile, validator)
	if not _check(not temp_failure_result.ok, "An interrupted temp write must not be promoted"):
		return
	if not _check(temp_failure.files["profile.json"] == old_text and temp_failure.files["profile.json.bak"] == old_text, "The old active save must remain active and backed up after an interrupted write"):
		return

	print("Atomic save tests: active promotion failure")
	var promotion_failure := MemoryStorage.new()
	promotion_failure.files["profile.json"] = old_text
	promotion_failure.files["profile.json.bak"] = prior_backup_text
	promotion_failure.fail_operation = "replace:profile.json"
	var promotion_failure_result := AtomicSave.save_document(promotion_failure, "profile.json", new_profile, validator)
	if not _check(not promotion_failure_result.ok, "Active promotion failure must be reported"):
		return
	if not _check(promotion_failure.files["profile.json"] == old_text and promotion_failure.files["profile.json.bak"] == old_text, "A failed active replacement must retain the previous valid save"):
		return

	print("Atomic save tests: recover from valid backup without mutating storage")
	var recovery_storage := MemoryStorage.new()
	var future_text := JSON.stringify({"schema_version": 99, "profile": {"coins": 999}})
	recovery_storage.files["profile.json"] = future_text
	recovery_storage.files["profile.json.bak"] = old_text
	var recovery_before: Dictionary = recovery_storage.files.duplicate(true)
	var recovered := AtomicSave.recover(recovery_storage, "profile.json", validator)
	if not _check(recovered.ok and recovered.source == "backup" and recovered.needs_restore, "A valid backup must be offered when the active schema is unknown"):
		return
	if not _check(_coins(JSON.stringify(recovered.document)) == 70, "Recovery must return the last-known-good document"):
		return
	if not _check(recovery_storage.files == recovery_before, "Recovery must not auto-overwrite either stored document"):
		return

	print("Atomic save tests: unknown active schema cannot be overwritten")
	var protected_storage := MemoryStorage.new()
	protected_storage.files["profile.json"] = future_text
	protected_storage.files["profile.json.bak"] = old_text
	var protected_before: Dictionary = protected_storage.files.duplicate(true)
	var protected_result := AtomicSave.save_document(protected_storage, "profile.json", new_profile, validator)
	if not _check(not protected_result.ok and protected_result.error == "active_save_invalid_recovery_required", "Unknown active schema must require explicit recovery before saving"):
		return
	if not _check(protected_storage.files == protected_before, "A future-schema save must remain byte-for-byte untouched"):
		return

	print("Atomic save tests: backup-only recovery gate")
	var backup_only := MemoryStorage.new()
	backup_only.files["profile.json.bak"] = old_text
	var backup_only_before: Dictionary = backup_only.files.duplicate(true)
	var backup_only_recovery := AtomicSave.recover(backup_only, "profile.json", validator)
	var backup_only_save := AtomicSave.save_document(backup_only, "profile.json", new_profile, validator)
	if not _check(backup_only_recovery.ok and backup_only_recovery.source == "backup", "A backup-only state must remain recoverable"):
		return
	if not _check(not backup_only_save.ok and backup_only_save.error == "backup_only_recovery_required", "A backup-only state must not be silently replaced"):
		return
	if not _check(backup_only.files == backup_only_before, "Backup-only recovery must not mutate stored data"):
		return

	print("Atomic save tests: empty storage and unrecoverable storage")
	var empty_storage := MemoryStorage.new()
	var initial_save := AtomicSave.save_document(empty_storage, "profile.json", new_profile, validator)
	if not _check(initial_save.ok and _coins(empty_storage.files["profile.json"]) == 80 and not empty_storage.files.has("profile.json.bak"), "A first save may create the active document without a backup"):
		return
	var damaged_storage := MemoryStorage.new()
	damaged_storage.files["profile.json"] = "{broken"
	damaged_storage.files["profile.json.bak"] = "{also broken"
	var damaged_before: Dictionary = damaged_storage.files.duplicate(true)
	var damaged_recovery := AtomicSave.recover(damaged_storage, "profile.json", validator)
	if not _check(not damaged_recovery.ok and damaged_recovery.error == "no_valid_save", "Invalid active and backup documents must surface a recoverable error"):
		return
	if not _check(damaged_storage.files == damaged_before, "Unrecoverable documents must never be auto-reset or deleted"):
		return

	print("Atomic save protocol tests passed: validation-before-write, backup rotation, interrupted writes, failed promotion, future-schema preservation, backup recovery, and no auto-reset.")
	quit(0)
