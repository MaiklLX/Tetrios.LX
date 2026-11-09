extends SceneTree

const Campaign = preload("res://scripts/campaign_progress.gd")
const CampaignStore = preload("res://scripts/campaign_progress_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN PROGRESS TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var progress = Campaign.new()
	if not _check(progress.unlocked_node == 1 and progress.completed_nodes.is_empty(), "New campaign must begin at planet 001"):
		return
	if not _check(Campaign.TOTAL_PLANETS == 360 and Campaign.UNIVERSE_COUNT == 12, "Campaign catalog must contain 12 universes and 360 planets"):
		return
	var first := progress.get_planet_definition(1)
	var boss := progress.get_planet_definition(30)
	var next_universe := progress.get_planet_definition(31)
	var final_planet := progress.get_planet_definition(360)
	var speed_boss := progress.get_planet_definition(10)
	var score_boss := progress.get_planet_definition(20)
	var final_boss := progress.get_planet_definition(30)
	if not _check(first.universe_index == 0 and first.planet_in_universe == 1 and first.target_lines == 10, "First planet definition must be stable"):
		return
	if not _check(boss.is_boss and boss.planet_in_universe == 30 and boss.reward_marks == 5, "Every tenth planet must be a boss milestone"):
		return
	if not _check(next_universe.universe_index == 1 and next_universe.planet_in_universe == 1, "Planet 031 must start Universe 02"):
		return
	if not _check(final_planet.universe_index == 11 and final_planet.planet_in_universe == 30 and final_planet.reward_marks == 15, "Planet 360 must be the final campaign milestone"):
		return
	if not _check(speed_boss.boss_type == "guardian" and speed_boss.time_limit_seconds == 0 and speed_boss.target_score > 0, "Planet 010 must be a bounded guardian boss without a speed timer"):
		return
	if not _check(score_boss.boss_type == "champion" and score_boss.target_lines > 0 and score_boss.target_score > 0 and score_boss.time_limit_seconds == 0, "Planet 020 must require a bounded combination of lines and score"):
		return
	if not _check(final_boss.boss_type == "final" and final_boss.target_score > 0 and final_boss.target_lines > 0 and final_boss.time_limit_seconds == 0, "Planet 030 must combine lines and score without an artificial timer"):
		return
	var score_planet := progress.get_planet_definition(5)
	var survive_planet := progress.get_planet_definition(4)
	if not _check(survive_planet.objective_type == "survive" and survive_planet.target_lines == 0 and survive_planet.target_score == 0 and survive_planet.target_survive_seconds >= 45, "Planet 004 must be a survival-only mission with a clear time target"):
		return
	if not _check(score_planet.objective_type == "score" and score_planet.target_lines == 0 and score_planet.target_score > 0, "Planet 005 must be a score-only mission, not a combined grind"):
		return
	if not _check(first.objective_type == "lines" and first.target_score == 0, "Ordinary planets must use a focused line objective"):
		return
	var previous_universe_max := 0
	for universe_index in range(Campaign.UNIVERSE_COUNT):
		var universe_start := universe_index * Campaign.PLANETS_PER_UNIVERSE + 1
		var universe_end := universe_start + Campaign.PLANETS_PER_UNIVERSE - 1
		var easy: Dictionary = progress.get_planet_definition(universe_start)
		var hard: Dictionary = progress.get_planet_definition(universe_end)
		if not _check(int(hard.target_lines) <= 28 and int(hard.target_score) <= 2900, "Campaign objective values must remain inside a fair difficulty ceiling"):
			return
		if not _check(int(easy.target_lines) >= previous_universe_max - 2, "A new universe must not feel like a complete difficulty reset"):
			return
		previous_universe_max = int(hard.target_lines)
	if not _check(int(progress.get_planet_definition(10).target_score) > 0 and progress.get_planet_definition(10).objective_type == "boss_combo", "Boss planets must add a meaningful but bounded combined challenge"):
		return
	if not _check(progress.is_unlocked(1) and not progress.is_unlocked(2) and progress.get_planet_status(2) == "locked", "Only the current planet is initially available"):
		return
	var boss_progress = Campaign.new()
	boss_progress.import_legacy_progress(20, 0)
	var boss_score_gate: Dictionary = boss_progress.complete_planet(20, int(score_boss.target_lines), 0, 10.0)
	if not _check(not boss_score_gate.accepted and boss_score_gate.reason == "score_objective_not_met", "Score boss must reject a clear without the score quota"):
		return
	var boss_success: Dictionary = boss_progress.complete_planet(20, int(score_boss.target_lines), int(score_boss.target_score), 10.0)
	if not _check(boss_success.accepted, "Score boss must complete when both line and score objectives are met"):
		return
	var score_only_progress = Campaign.new()
	score_only_progress.import_legacy_progress(5, 0)
	var score_only_success: Dictionary = score_only_progress.complete_planet(5, 0, int(score_planet.target_score), 5000.0)
	if not _check(score_only_success.accepted, "Score-only missions must not require lines or impose a hidden timer"):
		return
	var survive_progress = Campaign.new()
	survive_progress.import_legacy_progress(4, 0)
	var early_survival: Dictionary = survive_progress.complete_planet(4, 0, 0, float(survive_planet.target_survive_seconds) - 1.0)
	if not _check(not early_survival.accepted and early_survival.reason == "survival_objective_not_met", "Survival planets must reject an early finish"):
		return
	var completed_survival: Dictionary = survive_progress.complete_planet(4, 0, 0, float(survive_planet.target_survive_seconds))
	if not _check(completed_survival.accepted, "Survival-only planets must complete after the required time without line or score quotas"):
		return
	var guardian_progress = Campaign.new()
	guardian_progress.import_legacy_progress(10, 0)
	var guardian_success: Dictionary = guardian_progress.complete_planet(10, int(speed_boss.target_lines), int(speed_boss.target_score), 9999.0)
	if not _check(guardian_success.accepted, "Guardian boss must be completable without a time limit when its objectives are met"):
		return
	var too_early: Dictionary = progress.complete_planet(2, 999)
	if not _check(not too_early.accepted and too_early.reason == "planet_not_current", "Future planets cannot be completed out of order"):
		return
	var insufficient: Dictionary = progress.complete_planet(1, 6)
	if not _check(not insufficient.accepted and insufficient.reason == "objective_not_met" and progress.unlocked_node == 1, "Incomplete objectives must not unlock the next planet"):
		return
	var completion: Dictionary = progress.complete_planet(1, 10, 0)
	if not _check(completion.accepted and completion.reward_marks == 1 and progress.unlocked_node == 2, "First planet completion must award marks and unlock planet 002"):
		return
	if not _check(progress.get_planet_status(1) == "completed" and progress.get_planet_status(2) == "current", "Planet states must update after completion"):
		return
	var duplicate: Dictionary = progress.complete_planet(1, 999)
	if not _check(not duplicate.accepted and duplicate.reason == "already_completed" and progress.campaign_marks == 1, "Rewards must not be claimable twice"):
		return
	var reward_summary: Dictionary = progress.get_reward_summary()
	if not _check(reward_summary.marks_earned == 1 and reward_summary.marks_available > reward_summary.marks_earned and reward_summary.completed_planets == 1 and reward_summary.total_planets == 360, "Campaign reward summary must expose earned/available marks and overall completion"):
		return
	var first_universe_summary: Dictionary = progress.get_universe_progress(0)
	if not _check(first_universe_summary.marks_earned == 1 and first_universe_summary.marks_available > 0, "Universe summary must expose its own earned and available marks"):
		return
	var snapshot := progress.to_save_data()
	var restored = Campaign.new()
	if not _check(restored.load_save_data(snapshot), "Valid campaign progress snapshot must restore"):
		return
	if not _check(restored.unlocked_node == 2 and restored.completed_nodes == [1] and restored.campaign_marks == 1 and restored.reward_receipts.has("1"), "Save/load must preserve progression and reward receipts"):
		return
	var before_bad_load := restored.to_save_data()
	var invalid := snapshot.duplicate(true)
	invalid.completed_nodes = [1, 3]
	if not _check(not restored.load_save_data(invalid) and restored.to_save_data() == before_bad_load, "Invalid save must not partially mutate live progress"):
		return
	invalid = snapshot.duplicate(true)
	invalid.reward_receipts.erase("1")
	if not _check(not restored.load_save_data(invalid) and restored.to_save_data() == before_bad_load, "Modern saves must reject a partial reward ledger"):
		return
	invalid = snapshot.duplicate(true)
	invalid.campaign_marks = 99
	if not _check(not restored.load_save_data(invalid) and restored.to_save_data() == before_bad_load, "Modern saves must reject reward totals that do not match receipts"):
		return
	var legacy = Campaign.new()
	if not _check(legacy.import_legacy_progress(12, 37), "Legacy Web campaign progress must import"):
		return
	if not _check(legacy.completed_nodes.size() == 11 and legacy.unlocked_node == 12 and legacy.campaign_marks == 37 and legacy.reward_receipts.is_empty(), "Legacy import must preserve node and marks without granting duplicate receipts"):
		return
	var universe_one: Dictionary = legacy.get_universe_progress(0)
	var universe_two: Dictionary = legacy.get_universe_progress(1)
	if not _check(universe_one.completed_count == 11 and universe_one.current and not universe_two.unlocked and not universe_two.current, "Universe summaries must reflect legacy sequential progress"):
		return
	var legacy_profile := {"campaign": {"unlocked_node": 12, "marks": 37}}
	var imported_profile = Campaign.new()
	if not _check(CampaignStore.import_legacy_profile(imported_profile, legacy_profile) and imported_profile.unlocked_node == 12 and imported_profile.campaign_marks == 37, "Profile store must map the legacy campaign section"):
		return
	var test_path := "user://campaign_progress_test.cfg"
	if not _check(CampaignStore.save_progress(progress, test_path), "Campaign store must write a profile snapshot"):
		return
	var disk_restored = Campaign.new()
	var disk_result: Dictionary = CampaignStore.load_progress(disk_restored, test_path)
	if not _check(disk_result.ok and disk_result.found and disk_restored.to_save_data() == progress.to_save_data(), "Campaign store must restore a persisted snapshot"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("Campaign progress tests passed: 360-node catalog, expanded bounded difficulty, line/score/survival missions, boss objectives, sequential unlocks, rewards, persistence and legacy import.")
	quit(0)
