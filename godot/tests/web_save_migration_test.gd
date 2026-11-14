extends SceneTree

const WebMigration = preload("res://scripts/web_save_migration.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("WEB MIGRATION TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	print("Web migration tests: opening fixtures")
	var fixture_file := FileAccess.open("res://tests/fixtures/web_save_profiles.json", FileAccess.READ)
	if not _check(fixture_file != null, "Fixture file must be available"):
		return
	var fixtures: Dictionary = JSON.parse_string(fixture_file.get_as_text())
	fixture_file.close()
	if not _check(fixtures is Dictionary, "Fixture catalog must be valid JSON"):
		return

	print("Web migration tests: empty profile")
	var empty_import: Dictionary = WebMigration.parse_local_storage(fixtures["empty"]["local_storage"])
	if not _check(empty_import.ok and empty_import.profile.economy.coins == 0, "Empty profile must produce defaults"):
		return

	print("Web migration tests: typical profile")
	var typical_raw: Dictionary = fixtures["typical"]["local_storage"]
	var typical_before: Dictionary = typical_raw.duplicate(true)
	var typical_import: Dictionary = WebMigration.parse_local_storage(typical_raw)
	if not typical_import.ok or typical_import.requires_review:
		print("Typical migration errors: ", typical_import.errors)
		print("Typical migration warnings: ", typical_import.warnings)
		print("Typical migration conflicts: ", typical_import.conflicts)
	if not _check(typical_import.ok and not typical_import.requires_review, "Typical profile with matching aliases must validate"):
		return
	if not _check(typical_import.profile.economy.coins == 125 and typical_import.profile.economy.relics == 7, "Coin and relic balances must remain separate"):
		return
	if not _check(typical_import.profile.campaign.marks == 3 and typical_import.profile.campaign.unlocked_node == 12, "Campaign values must import independently"):
		return
	if not _check(typical_import.profile.heroes.selected_id == "prism" and typical_import.profile.heroes.progress.prism.xp == 90, "Selected hero and per-hero progression must import"):
		return
	if not _check(typical_import.profile.daily.reward_claimed_dates == ["2026-11-07"], "Reward idempotency markers must be retained"):
		return
	if not _check(typical_import.profile.daily.replayed_dates == ["2026-11-06"], "Valid replay completion dates must be retained"):
		return
	if not _check(typical_import.profile.daily.challenge_assignments["2026-11-08"]["mod"] == "gravity", "Daily challenge assignments must preserve the complete dated rule snapshot"):
		return
	if not _check(typical_import.profile.daily.challenge_history["2026-11-07"]["status"] == "completed" and typical_import.profile.daily.challenge_history["2026-11-06"]["status"] == "replayed", "Daily challenge history must preserve completed and replayed statuses"):
		return
	if not _check(typical_import.source_backup == typical_before and typical_raw == typical_before, "Parser must not mutate input and must preserve backup"):
		return

	print("Web migration tests: coin alias conflicts")
	var coin_conflict: Dictionary = WebMigration.parse_local_storage(fixtures["coin_conflict"]["local_storage"])
	if not _check(coin_conflict.ok and coin_conflict.requires_review and coin_conflict.profile.economy.coins == 125 and coin_conflict.conflicts.size() == 1, "Primary wallet must win while conflict is reported"):
		return
	var unresolved_coins: Dictionary = WebMigration.parse_local_storage(fixtures["coin_conflict_without_primary"]["local_storage"])
	if not _check(not unresolved_coins.ok, "Conflicting aliases without primary wallet must block import"):
		return

	print("Web migration tests: malformed JSON")
	var malformed: Dictionary = WebMigration.parse_local_storage(fixtures["malformed_json"]["local_storage"])
	if not _check(not malformed.ok and malformed.source_backup.bb_inventory == "{broken", "Malformed JSON must block import and preserve raw source"):
		return

	print("Web migration tests: legacy fallbacks")
	var legacy: Dictionary = WebMigration.parse_local_storage(fixtures["legacy_fallbacks"]["local_storage"])
	if not _check(legacy.ok and legacy.profile.heroes.progress.plush.xp == 30, "Legacy Plush progression must be supported as fallback"):
		return
	if not _check(legacy.profile.cosmetics.equipped_by_hero.plush == "old_hat", "Legacy cosmetic must map to selected hero"):
		return

	print("Web migration tests: unknown keys")
	var unknown: Dictionary = WebMigration.parse_local_storage(fixtures["unknown_key"]["local_storage"])
	if not _check(unknown.ok and unknown.unknown_keys.has("custom_mod_data") and unknown.source_backup.has("custom_mod_data"), "Unknown keys must be reported and retained in backup"):
		return

	print("Web migration tests: deterministic diagnostic ordering")
	var diagnostics_forward: Dictionary = {}
	diagnostics_forward["bb_coins"] = "20"
	diagnostics_forward["bbDailyRewardClaimed:2026-11-08"] = "1"
	diagnostics_forward["custom_z"] = "z"
	diagnostics_forward["bbDailyRewardClaimed:2026-11-07"] = "1"
	diagnostics_forward["custom_a"] = "a"
	var diagnostics_reverse: Dictionary = {}
	diagnostics_reverse["custom_a"] = "a"
	diagnostics_reverse["bbDailyRewardClaimed:2026-11-07"] = "1"
	diagnostics_reverse["custom_z"] = "z"
	diagnostics_reverse["bbDailyRewardClaimed:2026-11-08"] = "1"
	diagnostics_reverse["bb_coins"] = "20"
	var forward_diagnostics: Dictionary = WebMigration.parse_local_storage(diagnostics_forward)
	var reverse_diagnostics: Dictionary = WebMigration.parse_local_storage(diagnostics_reverse)
	var expected_reward_dates := ["2026-11-07", "2026-11-08"]
	var expected_unknown_keys := ["custom_a", "custom_z"]
	if not _check(forward_diagnostics.profile.daily.reward_claimed_dates == expected_reward_dates and reverse_diagnostics.profile.daily.reward_claimed_dates == expected_reward_dates, "Reward marker output must be sorted independently of source key insertion order"):
		return
	if not _check(forward_diagnostics.unknown_keys == expected_unknown_keys and reverse_diagnostics.unknown_keys == expected_unknown_keys, "Unknown-key diagnostics must be sorted independently of source key insertion order"):
		return
	if not _check(diagnostics_forward.bb_coins == "20" and diagnostics_reverse.bb_coins == "20", "Canonical diagnostic ordering must not mutate the source snapshot"):
		return

	print("Web migration tests: malformed reward marker")
	var bad_marker: Dictionary = WebMigration.parse_local_storage(fixtures["malformed_reward_marker"]["local_storage"])
	if not _check(not bad_marker.ok, "Malformed reward marker must block import"):
		return

	print("Web migration tests: adversarial inventory and daily schemas")
	var invalid_consumable: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_consumable"]["local_storage"])
	if not _check(not invalid_consumable.ok, "Unknown consumable ids must block migration"):
		return
	var invalid_perk: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_permanent_perk"]["local_storage"])
	if not _check(not invalid_perk.ok, "Unknown permanent perk ids must block migration"):
		return
	var invalid_hero_perks: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_hero_perk_map"]["local_storage"])
	if not _check(not invalid_hero_perks.ok, "Campaign perks for unknown heroes must block migration"):
		return
	var invalid_daily: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_daily_quest"]["local_storage"])
	if not _check(not invalid_daily.ok, "Daily quest records missing required fields must block migration"):
		return
	var orphan_reward: Dictionary = WebMigration.parse_local_storage(fixtures["reward_marker_without_history"]["local_storage"])
	if not _check(orphan_reward.ok and orphan_reward.requires_review, "Reward marker without matching history must require review without granting a reward"):
		return
	var invalid_archive: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_daily_archive_record"]["local_storage"])
	if not _check(not invalid_archive.ok, "Daily archive record date must match its key and contain a valid record"):
		return
	var invalid_calendar: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_calendar_date"]["local_storage"])
	if not _check(not invalid_calendar.ok, "Impossible calendar dates such as February 29 in a non-leap year must be rejected"):
		return
	var invalid_assignment: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_daily_challenge_assignment"]["local_storage"])
	if not _check(not invalid_assignment.ok, "Daily challenge assignment date must match its key and include a complete rule snapshot"):
		return
	var invalid_history_status: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_daily_challenge_history_status"]["local_storage"])
	if not _check(not invalid_history_status.ok, "Daily challenge history must use a known completed/replayed status"):
		return
	var invalid_replay_date: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_replay_date"]["local_storage"])
	if not _check(not invalid_replay_date.ok, "Replay completion dates must be real calendar dates"):
		return
	var duplicate_replay_dates: Dictionary = WebMigration.parse_local_storage(fixtures["duplicate_replay_dates"]["local_storage"])
	if not _check(not duplicate_replay_dates.ok, "Replay completion dates must not contain duplicates"):
		return
	var invalid_completed_date: Dictionary = WebMigration.parse_local_storage(fixtures["invalid_daily_completed_date"]["local_storage"])
	if not _check(not invalid_completed_date.ok, "Daily completion marker must be a valid calendar date"):
		return
	var large_archive: Dictionary = {}
	for day_index in range(91):
		var month := int(day_index / 28) + 1
		var day := day_index % 28 + 1
		var date_text := "2026-%02d-%02d" % [month, day]
		large_archive[date_text] = {"date": date_text, "quests": []}
	var large_archive_raw := {"bb_coins": "20", "bbDailyArchive": JSON.stringify(large_archive)}
	var large_archive_import: Dictionary = WebMigration.parse_local_storage(large_archive_raw)
	if not _check(large_archive_import.ok and large_archive_import.profile.daily.quest_archive.size() == 91, "Archives over 90 entries must be preserved in full and never trimmed during migration"):
		return
	if not _check(large_archive_import.warnings.size() > 0, "Archives over the Web 90-day save window must surface a preservation warning"):
		return

	print("Web migration parser tests passed: defaults, complete profile, alias conflicts, malformed JSON, legacy fallbacks, inventory and daily schema validation, reward idempotency, and source immutability.")
	quit(0)
