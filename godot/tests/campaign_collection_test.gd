extends SceneTree

const Campaign = preload("res://scripts/campaign_progress.gd")
const Collection = preload("res://scripts/campaign_collection.gd")
const ProgressStore = preload("res://scripts/campaign_progress_store.gd")
const RewardQueue = preload("res://scripts/campaign_reward_reveal_queue.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN COLLECTION TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var fresh = Campaign.new()
	var empty: Dictionary = Collection.get_collection_summary(fresh)
	if not _check(empty.total_count == 49 and empty.unlocked_count == 0 and empty.items.size() == 49, "Fresh campaign must expose 12 relics, 36 boss insignias and one final crown, all locked"):
		return
	var null_summary: Dictionary = Collection.get_collection_summary(null)
	if not _check(null_summary.total_count == 49 and null_summary.unlocked_count == 0, "Collection summary must safely handle a missing progress model"):
		return
	var relic_visual_variants: Dictionary = {}
	var boss_visual_variants: Dictionary = {}
	for collection_item in empty.items:
		var item_kind := str(collection_item.get("kind", ""))
		var visual_variant := int(collection_item.get("visual_variant", -1))
		if item_kind == "universe_relic":
			if not _check(visual_variant >= 1 and visual_variant <= 12 and not relic_visual_variants.has(visual_variant), "Every universe relic must have its own stable visual variant"):
				return
			relic_visual_variants[visual_variant] = true
		elif item_kind == "boss_insignia":
			if not _check(visual_variant == int(collection_item.get("planet_id", 0)) and not boss_visual_variants.has(visual_variant), "Every boss insignia must have a unique visual variant tied to its boss planet"):
				return
			boss_visual_variants[visual_variant] = true
	if not _check(relic_visual_variants.size() == 12 and boss_visual_variants.size() == 36, "All 12 relics and 36 boss insignias must have unique visual identities"):
		return
	var first_relic: Dictionary = Collection.get_item(fresh, "universe_relic_01")
	if not _check(not first_relic.is_empty() and not first_relic.unlocked and first_relic.unlock_planet == 30, "Universe relic must remain locked until all 30 planets are completed"):
		return
	var first_boss: Dictionary = Collection.get_item(fresh, "boss_insignia_010")
	if not _check(str(first_relic.get("kind", "")) == "universe_relic" and str(first_boss.get("kind", "")) == "boss_insignia", "Relics and boss insignias must expose distinct visual categories"):
		return
	var final_crown: Dictionary = Collection.get_item(fresh, "campaign_crown")
	if not _check(str(final_crown.get("kind", "")) == "campaign_crown" and int(final_crown.get("unlock_planet", 0)) == Campaign.TOTAL_PLANETS and int(final_crown.get("visual_variant", -1)) == 0, "Final crown must remain a distinct reward category tied to all 360 planets"):
		return
	if not _check(not first_boss.is_empty() and not first_boss.unlocked and first_boss.planet_id == 10, "Boss insignia must be tied to its exact boss planet"):
		return
	if not _check(Collection.get_item(fresh, "not_a_real_item").is_empty(), "Unknown collection item IDs must not resolve"):
		return
	var first_universe = Campaign.new()
	if not _check(first_universe.import_legacy_progress(31, 30), "Test fixture must import completed first-universe progress"):
		return
	var first_universe_collection: Dictionary = Collection.get_collection_summary(first_universe)
	if not _check(first_universe_collection.unlocked_count == 4, "Completing a universe must unlock its relic and all three defeated boss insignias"):
		return
	if not _check(Collection.get_item(first_universe, "universe_relic_01").unlocked and Collection.get_item(first_universe, "boss_insignia_010").unlocked and Collection.get_item(first_universe, "boss_insignia_020").unlocked and Collection.get_item(first_universe, "boss_insignia_030").unlocked, "Universe completion must expose all four corresponding collection items"):
		return
	if not _check(not Collection.get_item(first_universe, "universe_relic_02").unlocked, "Completing one universe must not unlock another universe's relic"):
		return
	var boss_unlock_progress = Campaign.new()
	if not _check(boss_unlock_progress.import_legacy_progress(10, 9), "Boss reveal fixture must import progress immediately before planet 010"):
		return
	var before_boss_unlock: Dictionary = Collection.get_collection_summary(boss_unlock_progress)
	var boss_definition: Dictionary = boss_unlock_progress.get_planet_definition(10)
	var boss_result: Dictionary = boss_unlock_progress.complete_planet(10, int(boss_definition.get("target_lines", 0)), int(boss_definition.get("target_score", 0)), 0.0)
	if not _check(bool(boss_result.get("accepted", false)), "Boss reveal fixture must complete planet 010"):
		return
	var boss_reveals: Array[String] = Collection.get_newly_unlocked_ids(before_boss_unlock, Collection.get_collection_summary(boss_unlock_progress))
	if not _check(boss_reveals == ["boss_insignia_010"], "Defeating a boss must queue exactly its newly unlocked insignia"):
		return
	var universe_unlock_progress = Campaign.new()
	if not _check(universe_unlock_progress.import_legacy_progress(30, 29), "Universe reveal fixture must import progress immediately before planet 030"):
		return
	var before_universe_unlock: Dictionary = Collection.get_collection_summary(universe_unlock_progress)
	var universe_boss_definition: Dictionary = universe_unlock_progress.get_planet_definition(30)
	var universe_result: Dictionary = universe_unlock_progress.complete_planet(30, int(universe_boss_definition.get("target_lines", 0)), int(universe_boss_definition.get("target_score", 0)), 0.0)
	if not _check(bool(universe_result.get("accepted", false)), "Universe reveal fixture must complete planet 030"):
		return
	var universe_reveals: Array[String] = Collection.get_newly_unlocked_ids(before_universe_unlock, Collection.get_collection_summary(universe_unlock_progress))
	if not _check(universe_reveals == ["universe_relic_01", "boss_insignia_030"], "Completing a universe must reveal both its relic and final boss insignia"):
		return
	var final_progress = Campaign.new()
	if not _check(final_progress.import_legacy_progress(Campaign.TOTAL_PLANETS, 500), "Test fixture must import progress up to the final planet"):
		return
	var final_definition: Dictionary = final_progress.get_planet_definition(Campaign.TOTAL_PLANETS)
	var final_result: Dictionary = final_progress.complete_planet(Campaign.TOTAL_PLANETS, int(final_definition.get("target_lines", 0)), int(final_definition.get("target_score", 0)), 0.0)
	if not _check(final_result.accepted and final_progress.campaign_complete, "Final planet completion must close the campaign"):
		return
	var final_collection: Dictionary = Collection.get_collection_summary(final_progress)
	if not _check(final_collection.unlocked_count == 49 and final_collection.total_count == 49 and is_equal_approx(float(final_collection.completion_ratio), 1.0), "Completing all 360 planets must unlock the full collection and final crown"):
		return
	if not _check(Collection.get_item(final_progress, "campaign_crown").unlocked, "Campaign crown must unlock only after all 360 planets"):
		return
	var store_path := "user://campaign_collection_pending_test.cfg"
	var pending_ids: Array[String] = ["universe_relic_01", "boss_insignia_030"]
	if not _check(ProgressStore.save_progress(first_universe, store_path, pending_ids), "Campaign store must save pending reward reveal IDs alongside progress"):
		return
	var restored_progress = Campaign.new()
	var restored_save: Dictionary = ProgressStore.load_progress(restored_progress, store_path)
	if not _check(bool(restored_save.get("ok", false)) and restored_save.get("pending_reward_reveals", []) == pending_ids, "Pending reward reveals must survive save and reload in their original order"):
		return
	var appended_ids: Array[String] = RewardQueue.append_unique(pending_ids, ["boss_insignia_030", "boss_insignia_010", ""])
	if not _check(appended_ids == ["universe_relic_01", "boss_insignia_030", "boss_insignia_010"], "New rewards must append once, preserve order and ignore empty IDs"):
		return
	var sanitized_ids: Array[String] = RewardQueue.sanitize(first_universe, ["boss_insignia_030", "unknown_reward", "universe_relic_01", "boss_insignia_030", ""])
	if not _check(sanitized_ids == pending_ids, "Restored reveal queue must discard unknown, empty and duplicate IDs without reordering valid rewards"):
		return
	var first_ack: Dictionary = RewardQueue.acknowledge_first(first_universe, pending_ids, store_path)
	if not _check(bool(first_ack.get("ok", false)) and first_ack.get("acknowledged_id", "") == "universe_relic_01" and first_ack.get("pending_reward_reveals", []) == ["boss_insignia_030"], "Acknowledging a reveal must consume exactly the first reward and persist the remainder"):
		return
	var after_first_ack = Campaign.new()
	var after_first_ack_save: Dictionary = ProgressStore.load_progress(after_first_ack, store_path)
	if not _check(bool(after_first_ack_save.get("ok", false)) and after_first_ack_save.get("pending_reward_reveals", []) == ["boss_insignia_030"], "A restart after the first acknowledgement must restore only the next unacknowledged reward"):
		return
	var second_ack: Dictionary = RewardQueue.acknowledge_first(after_first_ack, ["boss_insignia_030"], store_path)
	if not _check(bool(second_ack.get("ok", false)) and second_ack.get("acknowledged_id", "") == "boss_insignia_030" and second_ack.get("pending_reward_reveals", []).is_empty(), "The second acknowledgement must clear only the final reward"):
		return
	var after_second_ack = Campaign.new()
	var after_second_ack_save: Dictionary = ProgressStore.load_progress(after_second_ack, store_path)
	if not _check(bool(after_second_ack_save.get("ok", false)) and after_second_ack_save.get("pending_reward_reveals", []).is_empty(), "A restart after all acknowledgements must not replay completed reveals"):
		return
	var failed_ack: Dictionary = RewardQueue.acknowledge_first(first_universe, pending_ids, "user://missing_reward_queue_dir/save.cfg")
	if not _check(not bool(failed_ack.get("ok", true)) and failed_ack.get("pending_reward_reveals", []) == pending_ids, "A failed save must leave the original reward queue intact and unacknowledged"):
		return
	var legacy_store_path := "user://campaign_collection_legacy_test.cfg"
	var legacy_config := ConfigFile.new()
	legacy_config.set_value("campaign", "progress", first_universe.to_save_data())
	if not _check(legacy_config.save(legacy_store_path) == OK, "Legacy save fixture must be writable"):
		return
	var legacy_progress = Campaign.new()
	var legacy_load: Dictionary = ProgressStore.load_progress(legacy_progress, legacy_store_path)
	if not _check(bool(legacy_load.get("ok", false)) and legacy_load.get("pending_reward_reveals", []).is_empty(), "Older saves without a pending reveal field must load with an empty queue"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_store_path))
	print("Campaign collection tests passed: 12 universe relics, 36 boss insignias, final crown, locked states, per-universe unlocks and full completion.")
	quit(0)
