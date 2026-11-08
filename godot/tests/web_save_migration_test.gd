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

	print("Web migration tests: malformed reward marker")
	var bad_marker: Dictionary = WebMigration.parse_local_storage(fixtures["malformed_reward_marker"]["local_storage"])
	if not _check(not bad_marker.ok, "Malformed reward marker must block import"):
		return

	print("Web migration parser tests passed: defaults, complete profile, alias conflicts, malformed JSON, legacy fallbacks, unknown keys, reward idempotency, and source immutability.")
	quit(0)
