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
	daily["reward_claimed_dates"] = reward_dates

	for key in raw.keys():
		var key_text := str(key)
		if not _is_known_key(key_text):
			result["unknown_keys"].append(key_text)
	if not result["unknown_keys"].is_empty():
		result["warnings"].append("Unknown source keys were preserved in source_backup and were not imported")

	return result

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
	if value.length() != 10:
		return false
	return value.substr(4, 1) == "-" and value.substr(7, 1) == "-"

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
