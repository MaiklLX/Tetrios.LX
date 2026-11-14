class_name BlockBuddiesWebMigration
extends RefCounted

const HERO_IDS := ["plush", "prism", "blip", "pixel", "spark"]
const KNOWN_DIRECT_KEYS := [
	"coins", "bbCoins", "nrRelics", "bbCampaignMarks", "nrNode",
	"bbSelectedHero", "bb_equippedChestCosmetic", "bb_equippedChestCosmetics",
	"bbDailyQuests", "bbDailyArchive", "bbDailyChallengeCatalogSignature",
	"bbDailyChallengeAssignments", "bbDailyChallengeHistory",
	"bbDailyChallengeCompletedDate", "bbDailyReplayCompleted", "bbVisitStreak",
	"nrBest", "nrRuns", "nrDailyDone", "bb_haptics"
]

# Pure, read-only conversion. Input is a snapshot of localStorage key/value
# strings. This class never accesses the filesystem, localStorage, or user://.
static func parse_local_storage(raw: Dictionary) -> Dictionary:
	var result := {
		"ok": true,
		"requires_review": false,
		"errors": [],
		"warnings": [],
		"conflicts": [],
		"unknown_keys": [],
		"source_backup": raw.duplicate(true),
		"profile": {
			"schema_version": 1,
			"economy": {"coins": 0, "gems": 3, "relics": 0},
			"campaign": {"unlocked_node": 1, "marks": 0, "hero_perks": {}},
			"heroes": {"selected_id": "plush", "progress": {}},
			"inventory": {"consumables": {}, "permanent_perks": []},
			"cosmetics": {"owned": [], "equipped_by_hero": {}, "fragments": 0},
			"daily": {},
			"stats": {"best_score": 0, "runs": 0, "last_daily_run_date": ""},
			"settings": {"haptics": true}
		}
	}
	var profile: Dictionary = result["profile"]
	var economy: Dictionary = profile["economy"]
	var campaign: Dictionary = profile["campaign"]
	var heroes: Dictionary = profile["heroes"]
	var hero_progress: Dictionary = heroes["progress"]
	var inventory: Dictionary = profile["inventory"]
	var cosmetics: Dictionary = profile["cosmetics"]
	var daily: Dictionary = profile["daily"]
	var stats: Dictionary = profile["stats"]
	var settings: Dictionary = profile["settings"]

	# Coins: the Web runtime loads bb_coins. Other keys are legacy mirrors.
	var primary_coins: Variant = _read_value(raw, "bb_coins", true)
	var alias_coins: Variant = _read_value(raw, "coins", false)
	var mirror_coins: Variant = _read_value(raw, "bbCoins", false)
	var primary_valid: bool = _is_non_negative_int(primary_coins)
	var alias_valid: bool = _is_non_negative_int(alias_coins)
	var mirror_valid: bool = _is_non_negative_int(mirror_coins)
	if raw.has("bb_coins") and not primary_valid:
		_add_error(result, "bb_coins is present but is not a valid non-negative integer")
	elif primary_valid:
		economy["coins"] = int(primary_coins)
		for alias in [{"key":"coins","value":alias_coins,"valid":alias_valid},{"key":"bbCoins","value":mirror_coins,"valid":mirror_valid}]:
			if raw.has(alias.key) and (not alias.valid or int(alias.value) != int(primary_coins)):
				result["conflicts"].append({"field":"economy.coins","authoritative_key":"bb_coins","other_key":alias.key,"other_value":raw[alias.key]})
				result["requires_review"] = true
	elif alias_valid and mirror_valid and int(alias_coins) == int(mirror_coins):
		economy["coins"] = int(alias_coins)
		result["warnings"].append("bb_coins is absent; matching legacy coin aliases were used")
	elif alias_valid and not raw.has("bbCoins"):
		economy["coins"] = int(alias_coins)
		result["warnings"].append("bb_coins is absent; legacy coins key was used")
	elif mirror_valid and not raw.has("coins"):
		economy["coins"] = int(mirror_coins)
		result["warnings"].append("bb_coins is absent; bbCoins mirror was used")
	elif raw.has("coins") or raw.has("bbCoins"):
		_add_error(result, "Coin aliases disagree or are malformed and bb_coins is absent; manual reconciliation is required")

	_read_non_negative_json_int(raw, "bb_gems", economy, "gems", result, 3)
	_read_non_negative_raw_int(raw, "nrRelics", economy, "relics", result, 0)
	_read_non_negative_raw_int(raw, "bbCampaignMarks", campaign, "marks", result, 0)
	_read_positive_raw_int(raw, "nrNode", campaign, "unlocked_node", result, 1)
	_read_non_negative_raw_int(raw, "nrBest", stats, "best_score", result, 0)
	_read_non_negative_raw_int(raw, "nrRuns", stats, "runs", result, 0)

	var selected: Variant = _read_value(raw, "bbSelectedHero", false)
	if raw.has("bbSelectedHero"):
		if typeof(selected) == TYPE_STRING and HERO_IDS.has(selected):
			heroes["selected_id"] = selected
		else:
			_add_error(result, "bbSelectedHero contains an unknown hero id")

	for hero_id in HERO_IDS:
		var xp_key: String = "bb_xp_" + hero_id
		var level_key: String = "bb_heroLevel_" + hero_id
		var xp: Variant = _read_value(raw, xp_key, true)
		var hero_level: Variant = _read_value(raw, level_key, true)
		if hero_id == "plush":
			if not raw.has(xp_key):
				xp = _read_value(raw, "bb_xp", true)
			if not raw.has(level_key):
				hero_level = _read_value(raw, "bb_heroLevel", true)
		if raw.has(xp_key) or raw.has(level_key) or (hero_id == "plush" and (raw.has("bb_xp") or raw.has("bb_heroLevel"))):
			if not _is_non_negative_int(xp) or not _is_positive_int(hero_level):
				_add_error(result, "Invalid XP/level pair for hero " + hero_id)
			else:
				hero_progress[hero_id] = {"xp": int(xp), "level": int(hero_level)}
		var perk_key: String = "bb_bbCampaignPerks_" + hero_id
		if raw.has(perk_key):
			var perks: Variant = _read_value(raw, perk_key, true)
			if typeof(perks) != TYPE_DICTIONARY:
				_add_error(result, "Invalid campaign perk object for hero " + hero_id)
			else:
				campaign["hero_perks"][hero_id] = perks

	_copy_json_container(raw, "bb_inventory", inventory, "consumables", TYPE_DICTIONARY, result)
	_copy_json_container(raw, "bb_perks", inventory, "permanent_perks", TYPE_ARRAY, result)
	_copy_json_container(raw, "bb_chestCosmetics", cosmetics, "owned", TYPE_ARRAY, result)
	_copy_json_container(raw, "bb_equippedChestCosmetics", cosmetics, "equipped_by_hero", TYPE_DICTIONARY, result)
	_read_non_negative_json_int(raw, "bb_collectionFragments", cosmetics, "fragments", result, 0)
	_validate_consumables(inventory["consumables"], result)
	_validate_permanent_perks(inventory["permanent_perks"], result)
	_validate_campaign_perks(campaign["hero_perks"], result)

	if cosmetics["equipped_by_hero"].is_empty() and raw.has("bb_equippedChestCosmetic"):
		var legacy_cosmetic: Variant = _read_value(raw, "bb_equippedChestCosmetic", false)
		if typeof(legacy_cosmetic) == TYPE_STRING and not legacy_cosmetic.is_empty():
			cosmetics["equipped_by_hero"] = {str(heroes["selected_id"]): legacy_cosmetic}
			result["warnings"].append("Legacy single-slot cosmetic equip mapped to the selected hero; source key preserved")

	_copy_json_container(raw, "bbDailyQuests", daily, "quests_current", TYPE_DICTIONARY, result)
	_copy_json_container(raw, "bbDailyArchive", daily, "quest_archive", TYPE_DICTIONARY, result)
	_copy_json_container(raw, "bbDailyChallengeAssignments", daily, "challenge_assignments", TYPE_DICTIONARY, result)
	_copy_json_container(raw, "bbDailyChallengeHistory", daily, "challenge_history", TYPE_DICTIONARY, result)
	_copy_json_container(raw, "bbDailyReplayCompleted", daily, "replayed_dates", TYPE_ARRAY, result)
	_copy_json_container(raw, "bbVisitStreak", daily, "visit_streak", TYPE_DICTIONARY, result)
	if daily.has("visit_streak"):
		_validate_visit_streak(daily["visit_streak"], result)
	_copy_raw_string(raw, "bbDailyChallengeCatalogSignature", daily, "challenge_catalog_signature", result)
	_copy_raw_string(raw, "bbDailyChallengeCompletedDate", daily, "last_completed_date", result)
	_copy_raw_string(raw, "nrDailyDone", stats, "last_daily_run_date", result)
	var haptics: Variant = _read_value(raw, "bb_haptics", false)
	if raw.has("bb_haptics"):
		if haptics == "0":
			settings["haptics"] = false
		elif haptics == "1":
			settings["haptics"] = true
		else:
			_add_error(result, "bb_haptics must be 0 or 1")

	var reward_dates: Array[String] = []
	for key in raw.keys():
		var key_text := str(key)
		if key_text.begins_with("bbDailyRewardClaimed:"):
			var date_text := key_text.trim_prefix("bbDailyRewardClaimed:")
			if str(raw[key]) == "1" and _looks_like_date(date_text):
				reward_dates.append(date_text)
			else:
				_add_error(result, "Malformed daily reward marker: " + key_text)
	reward_dates.sort()
	daily["reward_claimed_dates"] = reward_dates
	_validate_equipped_cosmetics(cosmetics["equipped_by_hero"], result)
	if daily.has("quests_current"):
		_validate_daily_quests(daily["quests_current"], result)
	if daily.has("quest_archive"):
		_validate_daily_archive(daily["quest_archive"], result)
	_validate_daily_challenge_records(daily.get("challenge_assignments", {}), "bbDailyChallengeAssignments", false, result)
	_validate_daily_challenge_records(daily.get("challenge_history", {}), "bbDailyChallengeHistory", true, result)
	if daily.has("replayed_dates"):
		_validate_replayed_dates(daily["replayed_dates"], result)
	if daily.has("last_completed_date"):
		var completed_date := str(daily["last_completed_date"])
		if not completed_date.is_empty() and not _looks_like_date(completed_date):
			_add_error(result, "bbDailyChallengeCompletedDate must contain a valid date")
	_validate_daily_challenge_cross_consistency(daily, reward_dates, result)

	for key in raw.keys():
		var key_text := str(key)
		if key_text.begins_with("bb_bbCampaignPerks_"):
			var perk_hero_id := key_text.trim_prefix("bb_bbCampaignPerks_")
			if not HERO_IDS.has(perk_hero_id):
				_add_error(result, "Campaign perks reference an unknown hero: " + perk_hero_id)
		if not _is_known_key(key_text):
			result["unknown_keys"].append(key_text)
	result["unknown_keys"].sort()
	if not result["unknown_keys"].is_empty():
		result["warnings"].append("Unknown source keys were preserved in source_backup and were not imported")

	return result

static func _validate_consumables(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	for item_id in value.keys():
		if not ["quick", "shield", "magnet"].has(str(item_id)):
			_add_error(result, "Unknown consumable id: " + str(item_id))
		elif not _is_non_negative_int(value[item_id]):
			_add_error(result, "Consumable count must be a non-negative integer: " + str(item_id))

static func _validate_permanent_perks(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_ARRAY:
		return
	for perk_id in value:
		if typeof(perk_id) != TYPE_STRING or not ["heart", "rainbow", "lucky"].has(str(perk_id)):
			_add_error(result, "Unknown permanent perk id: " + str(perk_id))

static func _validate_campaign_perks(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	for hero_id in value.keys():
		if not HERO_IDS.has(str(hero_id)) or typeof(value[hero_id]) != TYPE_DICTIONARY:
			_add_error(result, "Invalid hero campaign-perk map: " + str(hero_id))
			continue
		for perk_id in value[hero_id].keys():
			if not ["guardian", "tactician", "scout"].has(str(perk_id)):
				_add_error(result, "Unknown campaign perk id: " + str(perk_id))
			elif not _is_non_negative_int(value[hero_id][perk_id]):
				_add_error(result, "Campaign perk rank must be a non-negative integer: " + str(perk_id))

static func _validate_equipped_cosmetics(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	for hero_id in value.keys():
		if not HERO_IDS.has(str(hero_id)) or typeof(value[hero_id]) != TYPE_STRING or str(value[hero_id]).is_empty():
			_add_error(result, "Invalid equipped cosmetic mapping for hero: " + str(hero_id))

static func _validate_daily_quests(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	if not value.has("date") or typeof(value["date"]) != TYPE_STRING or not _looks_like_date(value["date"]):
		_add_error(result, "bbDailyQuests must contain a valid date")
	if not value.has("quests") or typeof(value["quests"]) != TYPE_ARRAY:
		_add_error(result, "bbDailyQuests must contain a quests array")
		return
	_validate_daily_quest_entries(value["quests"], result)

static func _validate_daily_archive(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	if value.size() > 90:
		result["warnings"].append("Daily quest archive exceeds the Web 90-day save window; all entries were preserved without trimming")
	for date_key in value.keys():
		var date_text := str(date_key)
		var entry: Variant = value[date_key]
		if not _looks_like_date(date_text) or typeof(entry) != TYPE_DICTIONARY:
			_add_error(result, "bbDailyArchive contains an invalid date record: " + date_text)
			continue
		if typeof(entry.get("date")) != TYPE_STRING or str(entry.get("date")) != date_text:
			_add_error(result, "bbDailyArchive record date does not match its key: " + date_text)
		if typeof(entry.get("quests")) != TYPE_ARRAY:
			_add_error(result, "bbDailyArchive record must contain a quests array: " + date_text)
			continue
		_validate_daily_quest_entries(entry["quests"], result)

static func _validate_daily_quest_entries(quests: Array, result: Dictionary) -> void:
	for quest in quests:
		if typeof(quest) != TYPE_DICTIONARY:
			_add_error(result, "Daily quest entry must be an object")
			continue
		if typeof(quest.get("id")) != TYPE_STRING or str(quest.get("id")).is_empty() or typeof(quest.get("title")) != TYPE_STRING or str(quest.get("title")).is_empty():
			_add_error(result, "Daily quest must contain non-empty string id and title")
		if not _is_positive_int(quest.get("target")) or not _is_non_negative_int(quest.get("progress")):
			_add_error(result, "Daily quest target/progress must be valid non-negative integers")
		if not _is_non_negative_int(quest.get("reward")) or typeof(quest.get("claimed")) != TYPE_BOOL:
			_add_error(result, "Daily quest reward/claimed fields are malformed")

static func _validate_daily_challenge_records(value: Variant, source_key: String, is_history: bool, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	for date_key in value.keys():
		var date_text := str(date_key)
		var entry: Variant = value[date_key]
		if not _looks_like_date(date_text) or typeof(entry) != TYPE_DICTIONARY:
			_add_error(result, source_key + " contains an invalid date record: " + date_text)
			continue
		if typeof(entry.get("date")) != TYPE_STRING or str(entry.get("date")) != date_text:
			_add_error(result, source_key + " record date does not match its key: " + date_text)
		for field in ["title", "symbol", "desc", "goal", "rule", "mod"]:
			if typeof(entry.get(field)) != TYPE_STRING or str(entry.get(field)).strip_edges().is_empty():
				_add_error(result, source_key + " record is missing a non-empty " + field + ": " + date_text)
		if is_history:
			var status_value: Variant = entry.get("status")
			if typeof(status_value) != TYPE_STRING or not ["completed", "replayed"].has(str(status_value)):
				_add_error(result, source_key + " record has an invalid status: " + date_text)

static func _validate_replayed_dates(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_ARRAY:
		return
	var seen_dates := {}
	for date_value in value:
		if typeof(date_value) != TYPE_STRING or not _looks_like_date(str(date_value)):
			_add_error(result, "bbDailyReplayCompleted contains an invalid date")
			continue
		var date_text := str(date_value)
		if seen_dates.has(date_text):
			_add_error(result, "bbDailyReplayCompleted contains a duplicate date: " + date_text)
		seen_dates[date_text] = true


static func _validate_visit_streak(value: Variant, result: Dictionary) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	var streak: Dictionary = value
	var defaults := {
		"lastDate": "",
		"current": 0,
		"best": 0,
		"repairItems": 0,
		"brokenStreak": 0,
		"brokenOn": "",
		"lastRewardMilestone": 0
	}
	for field in defaults.keys():
		if not streak.has(field):
			streak[field] = defaults[field]
			result["warnings"].append("bbVisitStreak is missing " + str(field) + "; a safe default was applied to the import candidate")

	var dates_valid := true
	for field in ["lastDate", "brokenOn"]:
		var date_value: Variant = streak.get(field)
		if typeof(date_value) != TYPE_STRING or (not str(date_value).is_empty() and not _looks_like_date(str(date_value))):
			_add_error(result, "bbVisitStreak " + field + " must be empty or a valid calendar date")
			dates_valid = false

	var counters_valid := true
	for field in ["current", "best", "repairItems", "brokenStreak", "lastRewardMilestone"]:
		if not _is_non_negative_int(streak.get(field)):
			_add_error(result, "bbVisitStreak " + field + " must be a non-negative integer")
			counters_valid = false

	if counters_valid:
		var current_count := int(streak["current"])
		var best_count := int(streak["best"])
		var broken_count := int(streak["brokenStreak"])
		var reward_milestone := int(streak["lastRewardMilestone"])
		if best_count < max(current_count, broken_count):
			_add_error(result, "bbVisitStreak best must not be lower than current or brokenStreak")
		if reward_milestone > int(floor(float(best_count) / 7.0)):
			_add_error(result, "bbVisitStreak lastRewardMilestone exceeds the best-streak milestone")
		if (broken_count > 0) != (not str(streak["brokenOn"]).is_empty()):
			_add_error(result, "bbVisitStreak brokenStreak and brokenOn must be present together")

	if dates_valid and not str(streak["brokenOn"]).is_empty():
		if str(streak["lastDate"]).is_empty() or str(streak["brokenOn"]) > str(streak["lastDate"]):
			_add_error(result, "bbVisitStreak brokenOn cannot be later than lastDate")


static func _add_review_warning(result: Dictionary, message: String) -> void:
	result["requires_review"] = true
	result["warnings"].append(message)


static func _validate_daily_challenge_cross_consistency(daily: Dictionary, reward_dates: Array[String], result: Dictionary) -> void:
	var history: Variant = daily.get("challenge_history", {})
	var replayed_dates: Variant = daily.get("replayed_dates", [])
	var history_is_dictionary := typeof(history) == TYPE_DICTIONARY
	var replayed_is_array := typeof(replayed_dates) == TYPE_ARRAY
	var reward_lookup: Dictionary = {}
	var replay_lookup: Dictionary = {}

	for reward_date in reward_dates:
		reward_lookup[reward_date] = true
	if replayed_is_array:
		for replay_date in replayed_dates:
			if typeof(replay_date) == TYPE_STRING and _looks_like_date(str(replay_date)):
				replay_lookup[str(replay_date)] = true

	for reward_date in reward_dates:
		if not history_is_dictionary or not history.has(reward_date):
			_add_review_warning(result, "Daily reward marker has no matching challenge-history entry: " + reward_date)
			continue
		var reward_history: Variant = history[reward_date]
		if typeof(reward_history) == TYPE_DICTIONARY and str(reward_history.get("status", "")) != "completed":
			_add_review_warning(result, "Daily reward marker conflicts with challenge-history status: " + reward_date)
		if replay_lookup.has(reward_date):
			_add_review_warning(result, "A replay marker conflicts with a standard daily reward marker: " + reward_date)

	for replay_date in replay_lookup.keys():
		var replay_date_text := str(replay_date)
		if not history_is_dictionary or not history.has(replay_date_text):
			_add_review_warning(result, "Replay completion marker has no matching challenge-history entry: " + replay_date_text)
			continue
		var replay_history: Variant = history[replay_date_text]
		if typeof(replay_history) == TYPE_DICTIONARY and str(replay_history.get("status", "")) != "replayed":
			_add_review_warning(result, "Replay completion marker conflicts with challenge-history status: " + replay_date_text)

	if history_is_dictionary:
		for date_key in history.keys():
			var date_text := str(date_key)
			var entry: Variant = history[date_key]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var status := str(entry.get("status", ""))
			if status == "replayed" and not replay_lookup.has(date_text):
				_add_review_warning(result, "Challenge history marks a replay without a replay completion marker: " + date_text)
			elif status == "completed":
				if replay_lookup.has(date_text):
					_add_review_warning(result, "Completed challenge history conflicts with a replay completion marker: " + date_text)
				if not reward_lookup.has(date_text):
					_add_review_warning(result, "Completed challenge history has no per-date reward marker: " + date_text)

	var completed_date := str(daily.get("last_completed_date", ""))
	if not completed_date.is_empty():
		if not history_is_dictionary or not history.has(completed_date):
			_add_review_warning(result, "Last completed daily challenge has no matching history entry: " + completed_date)
		else:
			var completed_history: Variant = history[completed_date]
			if typeof(completed_history) == TYPE_DICTIONARY and str(completed_history.get("status", "")) != "completed":
				_add_review_warning(result, "Last completed daily challenge conflicts with its history status: " + completed_date)
		if not reward_lookup.has(completed_date):
			_add_review_warning(result, "Last completed daily challenge has no per-date reward marker: " + completed_date)
		if replay_lookup.has(completed_date):
			_add_review_warning(result, "Last completed daily challenge also appears in replay markers: " + completed_date)


static func _read_value(raw: Dictionary, key: String, json_encoded: bool) -> Variant:
	if not raw.has(key):
		return null
	var value: Variant = raw[key]
	if typeof(value) != TYPE_STRING:
		return value
	if json_encoded:
		var json_parser := JSON.new()
		var parse_error: Error = json_parser.parse(value)
		if parse_error != OK:
			return null
		return json_parser.data
	return value

static func _is_non_negative_int(value: Variant) -> bool:
	if typeof(value) == TYPE_STRING:
		return value.is_valid_int() and int(value) >= 0
	if typeof(value) == TYPE_INT:
		return int(value) >= 0
	if typeof(value) == TYPE_FLOAT:
		return is_finite(float(value)) and float(value) >= 0.0 and floor(float(value)) == float(value)
	return false

static func _is_positive_int(value: Variant) -> bool:
	return _is_non_negative_int(value) and int(value) > 0

static func _read_non_negative_json_int(raw: Dictionary, key: String, target: Dictionary, field: String, result: Dictionary, fallback: int) -> void:
	if not raw.has(key):
		return
	var value: Variant = _read_value(raw, key, true)
	if _is_non_negative_int(value):
		target[field] = int(value)
	else:
		_add_error(result, key + " must contain a JSON non-negative integer")

static func _read_non_negative_raw_int(raw: Dictionary, key: String, target: Dictionary, field: String, result: Dictionary, fallback: int) -> void:
	if not raw.has(key):
		return
	var value: Variant = _read_value(raw, key, false)
	if typeof(value) == TYPE_STRING and value.is_valid_int():
		value = int(value)
	if _is_non_negative_int(value):
		target[field] = int(value)
	else:
		_add_error(result, key + " must contain a non-negative integer")

static func _read_positive_raw_int(raw: Dictionary, key: String, target: Dictionary, field: String, result: Dictionary, fallback: int) -> void:
	_read_non_negative_raw_int(raw, key, target, field, result, fallback)
	if raw.has(key) and int(target.get(field, fallback)) < 1:
		_add_error(result, key + " must be at least 1")

static func _copy_json_container(raw: Dictionary, key: String, target: Dictionary, field: String, expected_type: int, result: Dictionary) -> void:
	if not raw.has(key):
		return
	var value: Variant = _read_value(raw, key, true)
	if typeof(value) != expected_type:
		_add_error(result, key + " contains malformed JSON or an unexpected data type")
	else:
		target[field] = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY else value

static func _copy_raw_string(raw: Dictionary, key: String, target: Dictionary, field: String, result: Dictionary) -> void:
	if not raw.has(key):
		return
	var value: Variant = _read_value(raw, key, false)
	if typeof(value) == TYPE_STRING:
		target[field] = value
	else:
		_add_error(result, key + " must be a string")

static func _looks_like_date(value: String) -> bool:
	if value.length() != 10 or value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
		return false
	var year_text := value.substr(0, 4)
	var month_text := value.substr(5, 2)
	var day_text := value.substr(8, 2)
	if not year_text.is_valid_int() or not month_text.is_valid_int() or not day_text.is_valid_int():
		return false
	var year := int(year_text)
	var month := int(month_text)
	var day := int(day_text)
	if year < 2000 or month < 1 or month > 12 or day < 1:
		return false
	var days_in_month := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var leap_year := (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
	if leap_year:
		days_in_month[1] = 29
	return day <= days_in_month[month - 1]

static func _is_known_key(key: String) -> bool:
	if KNOWN_DIRECT_KEYS.has(key):
		return true
	if key == "bb_coins" or key == "bb_gems" or key == "bb_inventory" or key == "bb_perks" or key == "bb_chestCosmetics" or key == "bb_equippedChestCosmetics" or key == "bb_collectionFragments":
		return true
	if key == "bb_xp" or key == "bb_heroLevel":
		return true
	if key.begins_with("bb_xp_") or key.begins_with("bb_heroLevel_") or key.begins_with("bb_bbCampaignPerks_"):
		return true
	if key.begins_with("bbDailyRewardClaimed:"):
		return true
	return false

static func _add_error(result: Dictionary, message: String) -> void:
	result["ok"] = false
	result["errors"].append(message)
