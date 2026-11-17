class_name BlockBuddiesAtomicSave
extends RefCounted

# Storage-agnostic save protocol. This class never opens files and never
# accesses user://, res://, localStorage, or platform storage directly.
# A concrete adapter must implement read_text, write_text, flush and
# replace_file. replace_file must be atomic and leave the destination intact
# when it returns false.

static func recover(adapter: Object, path: String, validator: Callable) -> Dictionary:
	if not _adapter_ready(adapter) or path.is_empty():
		return _failure("invalid_adapter_or_path")

	var active_read: Dictionary = _read_text(adapter, path)
	if not active_read.ok:
		return _failure("active_read_failed")

	if active_read.exists:
		var active_document: Dictionary = _decode_document(active_read.text, validator)
		if active_document.ok:
			return {
				"ok": true,
				"source": "active",
				"document": active_document.document,
				"needs_restore": false,
				"warning": ""
			}

	var backup_read: Dictionary = _read_text(adapter, path + ".bak")
	if not backup_read.ok:
		return _failure("backup_read_failed")

	if backup_read.exists:
		var backup_document: Dictionary = _decode_document(backup_read.text, validator)
		if backup_document.ok:
			return {
				"ok": true,
				"source": "backup",
				"document": backup_document.document,
				"needs_restore": true,
				"warning": "A valid backup is available; the active document was not changed."
			}

	return _failure("no_valid_save")


static func save_document(adapter: Object, path: String, candidate: Dictionary, validator: Callable) -> Dictionary:
	if not _adapter_ready(adapter) or path.is_empty():
		return _failure("invalid_adapter_or_path")
	if not _document_is_valid(candidate, validator):
		return _failure("candidate_rejected")

	var serialized := JSON.stringify(candidate)
	var candidate_round_trip: Dictionary = _decode_document(serialized, validator)
	if not candidate_round_trip.ok:
		return _failure("candidate_round_trip_rejected")

	var backup_path := path + ".bak"
	var backup_temp_path := backup_path + ".tmp"
	var active_temp_path := path + ".tmp"
	var active_read: Dictionary = _read_text(adapter, path)
	if not active_read.ok:
		return _failure("active_read_failed")
	var backup_read: Dictionary = _read_text(adapter, backup_path)
	if not backup_read.ok:
		return _failure("backup_read_failed")

	if active_read.exists:
		var active_document: Dictionary = _decode_document(active_read.text, validator)
		if not active_document.ok:
			return _failure("active_save_invalid_recovery_required")
		# Preserve the current valid active save before promoting a new one.
		if not _write_verified(adapter, backup_temp_path, active_read.text, validator):
			return _failure("backup_temp_write_failed")
		if not _replace_file(adapter, backup_temp_path, backup_path):
			return _failure("backup_promotion_failed")
	elif backup_read.exists:
		# A backup-only state must be explicitly recovered before a new save;
		# never silently replace the only known-good copy with a fresh profile.
		return _failure("backup_only_recovery_required")

	if not _write_verified(adapter, active_temp_path, serialized, validator):
		return _failure("active_temp_write_failed")
	if not _replace_file(adapter, active_temp_path, path):
		return _failure("active_promotion_failed")

	return {
		"ok": true,
		"active_path": path,
		"backup_path": backup_path
	}


static func _adapter_ready(adapter: Object) -> bool:
	if adapter == null:
		return false
	for method_name in ["read_text", "write_text", "flush", "replace_file"]:
		if not adapter.has_method(method_name):
			return false
	return true


static func _document_is_valid(document: Dictionary, validator: Callable) -> bool:
	if not validator.is_valid():
		return false
	var validation_result: Variant = validator.call(document.duplicate(true))
	return typeof(validation_result) == TYPE_BOOL and bool(validation_result)


static func _decode_document(serialized: String, validator: Callable) -> Dictionary:
	var parsed: Variant = JSON.parse_string(serialized)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _failure("invalid_json_document")
	var document: Dictionary = parsed
	if not _document_is_valid(document, validator):
		return _failure("document_schema_rejected")
	return {"ok": true, "document": document}


static func _read_text(adapter: Object, path: String) -> Dictionary:
	if not adapter.has_method("read_text"):
		return _failure("adapter_read_method_missing")
	var response: Variant = adapter.call("read_text", path)
	if typeof(response) != TYPE_DICTIONARY:
		return _failure("adapter_read_contract_invalid")
	if typeof(response.get("ok")) != TYPE_BOOL or not bool(response.get("ok")):
		return _failure("adapter_read_failed")
	if typeof(response.get("exists")) != TYPE_BOOL or typeof(response.get("text")) != TYPE_STRING:
		return _failure("adapter_read_contract_invalid")
	return {
		"ok": true,
		"exists": bool(response.get("exists")),
		"text": str(response.get("text"))
	}


static func _write_verified(adapter: Object, path: String, contents: String, validator: Callable) -> bool:
	if not _call_bool(adapter, "write_text", [path, contents]):
		return false
	if not _call_bool(adapter, "flush", [path]):
		return false
	var read_back: Dictionary = _read_text(adapter, path)
	if not read_back.ok or not read_back.exists or read_back.text != contents:
		return false
	return _decode_document(read_back.text, validator).ok


static func _replace_file(adapter: Object, source_path: String, destination_path: String) -> bool:
	return _call_bool(adapter, "replace_file", [source_path, destination_path])


static func _call_bool(adapter: Object, method_name: String, arguments: Array) -> bool:
	if adapter == null or not adapter.has_method(method_name):
		return false
	var result: Variant = adapter.callv(method_name, arguments)
	return typeof(result) == TYPE_BOOL and bool(result)


static func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error": error_code}
