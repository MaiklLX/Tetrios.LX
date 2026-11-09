extends SceneTree

const Campaign = preload("res://scripts/campaign_progress.gd")
const Achievements = preload("res://scripts/campaign_achievements.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN ACHIEVEMENT TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var fresh = Campaign.new()
	var initial: Dictionary = Achievements.get_summary(fresh)
	if not _check(initial.total_count == 36 and initial.unlocked_count == 0 and initial.remaining_count == 36, "Fresh campaign must expose 36 locked intermediate milestones"):
		return
	var first_universe: Array[Dictionary] = Achievements.get_achievements(fresh, 0)
	if not _check(first_universe.size() == 3 and first_universe[0].required_planet == 5 and first_universe[1].required_planet == 15 and first_universe[2].required_planet == 25, "Each universe must define milestones at planets 005, 015 and 025"):
		return
	if not _check(Achievements.get_achievements(fresh, 12).is_empty(), "Out-of-range universe lookup must fail safely"):
		return
	var progress = Campaign.new()
	if not _check(progress.import_legacy_progress(5, 0), "Fixture must import sequential progress through planet 004"):
		return
	var after_five: Dictionary = Achievements.get_summary(progress, 0)
	if not _check(after_five.unlocked_count == 1 and after_five.achievements[0].unlocked and not after_five.achievements[1].unlocked, "Completing planet 005 must unlock only the first intermediate milestone"):
		return
	if not _check(Achievements.get_summary(progress).unlocked_count == 1, "Campaign-wide summary must include earned milestones"):
		return
	var later = Campaign.new()
	if not _check(later.import_legacy_progress(25, 0), "Fixture must import progress through planet 024"):
		return
	var later_summary: Dictionary = Achievements.get_summary(later, 0)
	if not _check(later_summary.unlocked_count == 2 and later_summary.achievements[2].unlocked == false, "Planet 025 milestone must remain locked until planet 025 is completed"):
		return
	var completed = Campaign.new()
	if not _check(completed.import_legacy_progress(26, 0), "Fixture must import progress through planet 025"):
		return
	if not _check(Achievements.get_summary(completed, 0).unlocked_count == 3, "Completing planet 025 must unlock all three universe milestones"):
		return
	if not _check(Achievements.get_summary(completed, 1).unlocked_count == 0, "Milestones must not leak into the next universe"):
		return
	print("Campaign achievement tests passed: 36 milestones, 5/15/25 thresholds, universe isolation and safe summaries.")
	quit(0)
