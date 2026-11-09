extends SceneTree

const Campaign = preload("res://scripts/campaign_progress.gd")
const Collection = preload("res://scripts/campaign_collection.gd")

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
	var first_relic: Dictionary = Collection.get_item(fresh, "universe_relic_01")
	if not _check(not first_relic.is_empty() and not first_relic.unlocked and first_relic.unlock_planet == 30, "Universe relic must remain locked until all 30 planets are completed"):
		return
	if not _check(str(first_relic.get("kind", "")) == "universe_relic" and str(first_boss.get("kind", "")) == "boss_insignia", "Relics and boss insignias must expose distinct visual categories"):
		return
	var final_crown: Dictionary = Collection.get_item(fresh, "campaign_crown")
	if not _check(str(final_crown.get("kind", "")) == "campaign_crown" and int(final_crown.get("unlock_planet", 0)) == Campaign.TOTAL_PLANETS, "Final crown must remain a distinct reward category tied to all 360 planets"):
		return
	var first_boss: Dictionary = Collection.get_item(fresh, "boss_insignia_010")
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
	print("Campaign collection tests passed: 12 universe relics, 36 boss insignias, final crown, locked states, per-universe unlocks and full completion.")
	quit(0)
