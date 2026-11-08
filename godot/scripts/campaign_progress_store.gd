class_name BlockBuddiesCampaignProgressStore
extends RefCounted

const DEFAULT_PATH := "user://block_buddies_campaign_v1.cfg"

static func save_progress(progress: BlockBuddiesCampaignProgress, path: String = DEFAULT_PATH) -> bool:
	if progress == null:
		return false
	var config := ConfigFile.new()
	config.set_value("campaign", "progress", progress.to_save_data())
	return config.save(path) == OK

static func load_progress(progress: BlockBuddiesCampaignProgress, path: String = DEFAULT_PATH) -> Dictionary:
	if progress == null:
		return {"ok": false, "found": false, "reason": "missing_progress_model"}
	if not FileAccess.file_exists(path):
		return {"ok": true, "found": false, "reason": "no_save"}
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return {"ok": false, "found": true, "reason": "file_read_failed"}
	var data: Variant = config.get_value("campaign", "progress", null)
	if typeof(data) != TYPE_DICTIONARY or not progress.load_save_data(data):
		return {"ok": false, "found": true, "reason": "invalid_campaign_save"}
	return {"ok": true, "found": true, "reason": "loaded"}

static func import_legacy_profile(progress: BlockBuddiesCampaignProgress, profile: Dictionary) -> bool:
	if progress == null:
		return false
	var campaign: Variant = profile.get("campaign", {})
	if typeof(campaign) != TYPE_DICTIONARY:
		return false
	var unlocked_node: Variant = campaign.get("unlocked_node", 1)
	var marks: Variant = campaign.get("marks", 0)
	if typeof(unlocked_node) != TYPE_INT or typeof(marks) != TYPE_INT:
		return false
	return progress.import_legacy_progress(int(unlocked_node), int(marks))
