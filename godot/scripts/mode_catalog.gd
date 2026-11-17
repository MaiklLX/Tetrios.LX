class_name BlockBuddiesModeCatalog
extends RefCounted

# Definitions are data-only at this stage. Session execution and UI selection
# will be connected in later, separately tested milestones.
const DEFAULT_MODE_ID := "classic"
const MODES := {
	"classic": {
		"id": "classic",
		"name": "Classic",
		"description": "Классическая игра без ограничения по времени и числу линий.",
		"target_lines": 0,
		"time_limit_seconds": 0,
		"starting_level": 1,
		"level_lines": 10
	},
	"sprint": {
		"id": "sprint",
		"name": "Sprint",
		"description": "Гонка до 40 очищенных линий.",
		"target_lines": 40,
		"time_limit_seconds": 0,
		"starting_level": 1,
		"level_lines": 10
	},
	"marathon": {
		"id": "marathon",
		"name": "Marathon",
		"description": "Длинный забег до 100 очищенных линий.",
		"target_lines": 100,
		"time_limit_seconds": 0,
		"starting_level": 1,
		"level_lines": 10
	}
}

static func list_modes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mode_id in MODES:
		result.append(MODES[mode_id].duplicate(true))
	return result

static func get_mode(mode_id: String) -> Dictionary:
	if not MODES.has(mode_id):
		return {}
	return MODES[mode_id].duplicate(true)

static func is_valid_mode(mode_id: String) -> bool:
	return MODES.has(mode_id)
