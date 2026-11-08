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
	if not _check(first.universe_index == 0 and first.planet_in_universe == 1 and first.target_lines == 8, "First planet definition must be stable"):
		return
	if not _check(boss.is_boss and boss.planet_in_universe == 30 and boss.reward_marks == 5, "Every tenth planet must be a boss milestone"):
		return
	if not _check(next_universe.universe_index == 1 and next_universe.planet_in_universe == 1, "Planet 031 must start Universe 02"):
		return
	if not _check(final_planet.universe_index == 11 and final_planet.planet_in_universe == 30 and final_planet.reward_marks == 15, "Planet 360 must be the final campaign milestone"):
		return
	if not _check(speed_boss.boss_type == "speed" and speed_boss.time_limit_seconds == 150 and speed_boss.target_score > 0, "Planet 010 must be a timed speed boss with a higher score target"):
		return
	if not _check(score_boss.boss_type == "score" and score_boss.target_score > 0 and score_boss.time_limit_seconds == 0, "Planet 020 must require both lines and score"):
		return
	if not _check(final_boss.boss_type == "final" and final_boss.target_score > 0 and final_boss.time_limit_seconds > 0, "Planet 030 must combine lines, score and time"):
		return
	var previous_score := 0
	var previous_lines := 0
	for node_id in range(1, Campaign.TOTAL_PLANETS + 1):
		var definition: Dictionary = progress.get_planet_definition(node_id)
		if not _check(int(definition.target_score) > previous_score, "Every planet must increase the score objective, including universe transitions"):
			return
		if not _check(int(definition.target_lines) >= previous_lines, "Line objectives must never decrease across the campaign"):
			return
		previous_score = int(definition.target_score)
		previous_lines = int(definition.target_lines)
	if not _check(int(progress.get_planet_definition(31).target_score) > int(progress.get_planet_definition(30).target_score), "New universe must continue beyond the previous universe boss"):
		return
	if not _check(int(progress.get_planet_definition(10).target_score) > int(progress.get_planet_definition(9).target_score) + 100, "Boss planet must have a substantial difficulty spike"):
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
	var speed_progress = Campaign.new()
	speed_progress.import_legacy_progress(10, 0)
	var speed_timeout: Dictionary = speed_progress.complete_planet(10, int(speed_boss.target_lines), int(speed_boss.target_score), float(speed_boss.time_limit_seconds) + 1.0)
	if not _check(not speed_timeout.accepted and speed_timeout.reason == "time_limit_exceeded", "Speed boss must reject a run beyond its time limit"):
		return
	var too_early: Dictionary = progress.complete_planet(2, 999)
	if not _check(not too_early.accepted and too_early.reason == "planet_not_current", "Future planets cannot be completed out of order"):
		return
	var insufficient: Dictionary = progress.complete_planet(1, 7)
	if not _check(not insufficient.accepted and insufficient.reason == "objective_not_met" and progress.unlocked_node == 1, "Incomplete objectives must not unlock the next planet"):
		return
	var completion: Dictionary = progress.complete_planet(1, 8, int(first.target_score))
	if not _check(completion.accepted and completion.reward_marks == 1 and progress.unlocked_node == 2, "First planet completion must award marks and unlock planet 002"):
		return
	if not _check(progress.get_planet_status(1) == "completed" and progress.get_planet_status(2) == "current", "Planet states must update after completion"):
		return
	var duplicate: Dictionary = progress.complete_planet(1, 999)
	if not _check(not duplicate.accepted and duplicate.reason == "already_completed" and progress.campaign_marks == 1, "Rewards must not be claimable twice"):
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
	print("Campaign progress tests passed: 360-node catalog, milestones, sequential unlocks, objective gates, idempotent rewards, atomic save/load, profile persistence and legacy import.")
	quit(0)
