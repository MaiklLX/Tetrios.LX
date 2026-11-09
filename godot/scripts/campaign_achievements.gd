class_name BlockBuddiesCampaignAchievements
extends RefCounted

const Progress = preload("res://scripts/campaign_progress.gd")
const MILESTONE_PLANETS := [5, 15, 25]
const MILESTONE_NAMES := ["ПЕРВЫЙ РУБЕЖ", "ПОЛОВИНА ПУТИ", "ПЕРЕД ФИНАЛОМ"]
const MILESTONE_DESCRIPTIONS := [
	"Пройди первые пять планет вселенной.",
	"Заверши пятнадцать планет вселенной.",
	"Открой путь к финальному боссу вселенной."
]

static func get_achievements(progress: Variant, universe_index: int = -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if progress == null or not (progress is Progress):
		return result
	var first_universe := 0 if universe_index < 0 else universe_index
	var last_universe := Progress.UNIVERSE_COUNT - 1 if universe_index < 0 else universe_index
	if first_universe < 0 or last_universe >= Progress.UNIVERSE_COUNT:
		return result
	for current_universe in range(first_universe, last_universe + 1):
		var first_node := current_universe * Progress.PLANETS_PER_UNIVERSE + 1
		for milestone_index in range(MILESTONE_PLANETS.size()):
			var required_node: int = first_node + MILESTONE_PLANETS[milestone_index] - 1
			var achievement_id := "universe_%02d_milestone_%02d" % [current_universe + 1, MILESTONE_PLANETS[milestone_index]]
			result.append({
				"id": achievement_id,
				"universe_index": current_universe,
				"universe_number": current_universe + 1,
				"required_planet": required_node,
				"planet_in_universe": MILESTONE_PLANETS[milestone_index],
				"title": MILESTONE_NAMES[milestone_index],
				"description": MILESTONE_DESCRIPTIONS[milestone_index],
				"reward_label": "Знак пути",
				"unlocked": progress.is_completed(required_node)
			})
	return result

static func get_summary(progress: Variant, universe_index: int = -1) -> Dictionary:
	var achievements := get_achievements(progress, universe_index)
	var unlocked_count := 0
	for achievement in achievements:
		if bool(achievement.unlocked):
			unlocked_count += 1
	return {
		"unlocked_count": unlocked_count,
		"total_count": achievements.size(),
		"remaining_count": achievements.size() - unlocked_count,
		"completion_ratio": float(unlocked_count) / float(achievements.size()) if not achievements.is_empty() else 0.0,
		"achievements": achievements
	}
