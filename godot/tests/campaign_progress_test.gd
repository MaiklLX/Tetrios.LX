extends SceneTree

const Campaign = preload("res://scripts/campaign_progress.gd")

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
	if not _check(first.universe_index == 0 and first.planet_in_universe == 1 and first.target_lines == 8, "First planet definition must be stable"):
		return
	if not _check(boss.is_boss and boss.planet_in_universe == 30 and boss.reward_marks == 5, "Every tenth planet must be a boss milestone"):
		return
	if not _check(next_universe.universe_index == 1 and next_universe.planet_in_universe == 1, "Planet 031 must start Universe 02"):
		return
	if not _check(final_planet.universe_index == 11 and final_planet.planet_in_universe == 30 and final_planet.reward_marks == 15, "Planet 360 must be the final campaign milestone"):
		return
	if not _check(progress.is_unlocked(1) and not progress.is_unlocked(2) and progress.get_planet_status(2) == "locked", "Only the current planet is initially available"):
		return
	var too_early: Dictionary = progress.complete_planet(2, 999)
	if not _check(not too_early.accepted and too_early.reason == "planet_not_current", "Future planets cannot be completed out of order"):
		return
	var insufficient: Dictionary = progress.complete_planet(1, 7)
	if not _check(not insufficient.accepted and insufficient.reason == "objective_not_met" and progress.unlocked_node == 1, "Incomplete objectives must not unlock the next planet"):
		return
	var completion: Dictionary = progress.complete_planet(1, 8)
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
	print("Campaign progress tests passed: 360-node catalog, milestones, sequential unlocks, objective gates, idempotent rewards, atomic save/load and legacy import.")
	quit(0)
