class_name BlockBuddiesCampaignRewardRevealQueue
extends RefCounted

const CampaignStore = preload("res://scripts/campaign_progress_store.gd")
const CampaignCollection = preload("res://scripts/campaign_collection.gd")

static func append_unique(pending_ids: Array[String], reward_ids: Array[String]) -> Array[String]:
	var result: Array[String] = pending_ids.duplicate()
	for reward_id in reward_ids:
		if not reward_id.is_empty() and not result.has(reward_id):
			result.append(reward_id)
	return result

static func sanitize(progress: BlockBuddiesCampaignProgress, pending_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if progress == null or typeof(pending_value) != TYPE_ARRAY:
		return result
	for value in pending_value:
		if typeof(value) != TYPE_STRING:
			continue
		var reward_id := str(value)
		if reward_id.is_empty() or result.has(reward_id):
			continue
		if CampaignCollection.get_item(progress, reward_id).is_empty():
			continue
		result.append(reward_id)
	return result

static func acknowledge_first(progress: BlockBuddiesCampaignProgress, pending_ids: Array[String], path: String = CampaignStore.DEFAULT_PATH) -> Dictionary:
	if progress == null:
		return {"ok": false, "reason": "missing_progress", "pending_reward_reveals": pending_ids.duplicate()}
	if pending_ids.is_empty():
		return {"ok": false, "reason": "empty_queue", "pending_reward_reveals": []}
	var remaining: Array[String] = pending_ids.duplicate()
	var acknowledged_id: String = str(remaining.pop_front())
	if not CampaignStore.save_progress(progress, path, remaining):
		return {"ok": false, "reason": "save_failed", "acknowledged_id": "", "pending_reward_reveals": pending_ids.duplicate()}
	return {"ok": true, "reason": "acknowledged", "acknowledged_id": acknowledged_id, "pending_reward_reveals": remaining}
