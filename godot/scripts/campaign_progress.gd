class_name BlockBuddiesCampaignProgress
extends RefCounted

const SAVE_VERSION := 1
const PlanetCatalog = preload("res://scripts/campaign_planet_catalog.gd")
const UNIVERSE_COUNT := 12
const PLANETS_PER_UNIVERSE := 30
const TOTAL_PLANETS := UNIVERSE_COUNT * PLANETS_PER_UNIVERSE
const UNIVERSE_NAMES := [
	"ЗЕЛЁНЫЕ РАВНИНЫ", "КАРАВАН ЗВЁЗД", "ОГНЕННЫЕ ЗЕМЛИ", "ЛЕДЯНАЯ КОРОНА",
	"ЛУННАЯ КОЛОНИЯ", "КРЫЛЬЯ ЭКСПЕДИЦИИ", "ПЕСКИ ВРЕМЕНИ", "ВРАТА МЕЖДУМИРЬЯ",
	"НЕБЕСНЫЙ АРХИПЕЛАГ", "СТАНЦИЯ ДРОНОВ", "КОСМИЧЕСКИЙ РАЗЛОМ", "ДАЛЬНИЙ РУБЕЖ"
]

var unlocked_node := 1
var completed_nodes: Array[int] = []
var campaign_marks := 0
var reward_receipts: Dictionary = {}
var campaign_complete := false

func reset() -> void:
	unlocked_node = 1
	completed_nodes.clear()
	campaign_marks = 0
	reward_receipts.clear()
	campaign_complete = false

func get_planet_definition(node_id: int) -> Dictionary:
	if node_id < 1 or node_id > TOTAL_PLANETS:
		return {}
	var universe_index := int((node_id - 1) / PLANETS_PER_UNIVERSE)
	var planet_in_universe := ((node_id - 1) % PLANETS_PER_UNIVERSE) + 1
	var boss := planet_in_universe % 10 == 0
	# Difficulty grows in small, bounded chapter steps. It never compounds per planet.
	var chapter_step := mini(universe_index, 6)
	var local_step := int((planet_in_universe - 1) / 10)
	var line_target := 10 + chapter_step * 2 + local_step
	var score_target := 900 + chapter_step * 220 + local_step * 160
	var objective_type := "lines"
	var boss_type := "none"
	var target_lines := line_target
	var target_score := 0
	var target_survive_seconds := 0
	if planet_in_universe in [4, 14, 24]:
		objective_type = "survive"
		target_lines = 0
		target_survive_seconds = 45 + chapter_step * 5 + local_step * 10
	if planet_in_universe in [5, 15, 25]:
		objective_type = "score"
		target_lines = 0
		target_score = score_target
	if boss:
		objective_type = "boss_combo"
		target_lines = line_target
		target_score = score_target + 300
		boss_type = "guardian" if planet_in_universe == 10 else ("champion" if planet_in_universe == 20 else "final")
	var difficulty_band := "guided" if planet_in_universe <= 9 else ("standard" if planet_in_universe <= 19 else ("advanced" if planet_in_universe <= 29 else "mastery"))
	var duration_floor := 90 + local_step * 30
	var expected_duration := [duration_floor, duration_floor + 60]
	var reward := 1 + (4 if boss else 0) + (10 if node_id == TOTAL_PLANETS else 0)
	var definition := {
		"node_id": node_id,
		"universe_index": universe_index,
		"universe_number": universe_index + 1,
		"universe_name": UNIVERSE_NAMES[universe_index],
		"planet_in_universe": planet_in_universe,
		"planet_name": "ПЛАНЕТА %03d" % node_id,
		"is_boss": boss,
		"boss_type": boss_type,
		"objective_type": objective_type,
		"target_lines": target_lines,
		"target_score": target_score,
		"target_survive_seconds": target_survive_seconds,
		"difficulty_band": difficulty_band,
		"expected_duration_seconds": expected_duration,
		"event_schedule": [],
		"time_limit_seconds": 0,
		"reward_marks": reward
	}
	var authored := PlanetCatalog.get_planet(universe_index, planet_in_universe)
	if not authored.is_empty():
		definition.merge(authored, true)
		definition["chapter_id"] = "star_caravan"
		definition["chapter_title"] = "Караван звёзд"
		definition["content_status"] = "authored_foundation"
		var mission: Variant = authored.get("mission_definition", {})
		if typeof(mission) == TYPE_DICTIONARY and not mission.is_empty():
			definition.merge(mission, true)
	return definition

func is_unlocked(node_id: int) -> bool:
	if node_id < 1 or node_id > TOTAL_PLANETS:
		return false
	return campaign_complete or node_id <= unlocked_node

func is_completed(node_id: int) -> bool:
	return completed_nodes.has(node_id)

func get_planet_status(node_id: int) -> String:
	if is_completed(node_id):
		return "completed"
	if not is_unlocked(node_id):
		return "locked"
	return "current"

func get_universe_progress(universe_index: int) -> Dictionary:
	if universe_index < 0 or universe_index >= UNIVERSE_COUNT:
		return {}
	var first_node := universe_index * PLANETS_PER_UNIVERSE + 1
	var last_node := first_node + PLANETS_PER_UNIVERSE - 1
	var completed_count := 0
	for node_id in completed_nodes:
		if node_id >= first_node and node_id <= last_node:
			completed_count += 1
	var unlocked := campaign_complete or first_node <= unlocked_node
	var is_current := unlocked and not campaign_complete and unlocked_node >= first_node and unlocked_node <= last_node
	var marks_earned := 0
	var marks_available := 0
	for node_id in range(first_node, last_node + 1):
		var definition := get_planet_definition(node_id)
		var reward := int(definition.get("reward_marks", 0))
		marks_available += reward
		if is_completed(node_id):
			var receipt: Dictionary = reward_receipts.get(str(node_id), {})
			marks_earned += int(receipt.get("reward_marks", reward if reward_receipts.is_empty() else 0))
	return {
		"unlocked": unlocked,
		"current": is_current,
		"completed": completed_count == PLANETS_PER_UNIVERSE,
		"completed_count": completed_count,
		"total": PLANETS_PER_UNIVERSE,
		"marks_earned": marks_earned,
		"marks_available": marks_available
	}

func get_reward_summary() -> Dictionary:
	var marks_available := 0
	var boss_marks_available := 0
	for node_id in range(1, TOTAL_PLANETS + 1):
		var definition := get_planet_definition(node_id)
		var reward := int(definition.get("reward_marks", 0))
		marks_available += reward
		if bool(definition.get("is_boss", false)):
			boss_marks_available += reward
	var marks_earned := 0
	var boss_marks_earned := 0
	for node_id in completed_nodes:
		var definition := get_planet_definition(node_id)
		var receipt: Dictionary = reward_receipts.get(str(node_id), {})
		var reward := int(receipt.get("reward_marks", int(definition.get("reward_marks", 0)) if reward_receipts.is_empty() else 0))
		marks_earned += reward
		if bool(definition.get("is_boss", false)):
			boss_marks_earned += reward
	return {
		"marks_earned": marks_earned,
		"marks_available": marks_available,
		"marks_remaining": maxi(0, marks_available - marks_earned),
		"boss_marks_earned": boss_marks_earned,
		"boss_marks_available": boss_marks_available,
		"completed_planets": completed_nodes.size(),
		"total_planets": TOTAL_PLANETS,
		"completion_ratio": float(completed_nodes.size()) / float(TOTAL_PLANETS)
	}

func complete_planet(node_id: int, cleared_lines: int, score: int = 0, elapsed_seconds: float = 0.0) -> Dictionary:
	if node_id < 1 or node_id > TOTAL_PLANETS:
		return {"accepted": false, "reason": "invalid_planet"}
	if completed_nodes.has(node_id) or reward_receipts.has(str(node_id)):
		return {"accepted": false, "reason": "already_completed", "reward_marks": 0}
	if campaign_complete or node_id != unlocked_node:
		return {"accepted": false, "reason": "planet_not_current"}
	var definition := get_planet_definition(node_id)
	var target_lines := int(definition.target_lines)
	if target_lines > 0 and cleared_lines < target_lines:
		return {"accepted": false, "reason": "objective_not_met", "remaining_lines": target_lines - cleared_lines}
	var target_score := int(definition.get("target_score", 0))
	if target_score > 0 and score < target_score:
		return {"accepted": false, "reason": "score_objective_not_met", "remaining_score": target_score - score}
	var target_survive := float(definition.get("target_survive_seconds", 0))
	if target_survive > 0.0 and elapsed_seconds < target_survive:
		return {"accepted": false, "reason": "survival_objective_not_met", "remaining_seconds": target_survive - elapsed_seconds}
	var time_limit := float(definition.get("time_limit_seconds", 0))
	if time_limit > 0.0 and elapsed_seconds > time_limit:
		return {"accepted": false, "reason": "time_limit_exceeded"}
	var reward := int(definition.reward_marks)
	completed_nodes.append(node_id)
	campaign_marks += reward
	reward_receipts[str(node_id)] = {
		"node_id": node_id,
		"reward_marks": reward,
		"claimed": true
	}
	if node_id == TOTAL_PLANETS:
		campaign_complete = true
	else:
		unlocked_node = node_id + 1
	return {
		"accepted": true,
		"node_id": node_id,
		"reward_marks": reward,
		"campaign_complete": campaign_complete,
		"next_unlocked_node": unlocked_node
	}

# Older Web saves store the next unlocked node and campaign marks, but no
# per-planet receipts. Prior nodes are imported as completed without re-awarding.
func import_legacy_progress(legacy_unlocked_node: int, legacy_marks: int) -> bool:
	if legacy_unlocked_node < 1 or legacy_unlocked_node > TOTAL_PLANETS or legacy_marks < 0:
		return false
	reset()
	unlocked_node = legacy_unlocked_node
	campaign_marks = legacy_marks
	for node_id in range(1, legacy_unlocked_node):
		completed_nodes.append(node_id)
	return true

func to_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked_node": unlocked_node,
		"completed_nodes": completed_nodes.duplicate(),
		"campaign_marks": campaign_marks,
		"reward_receipts": reward_receipts.duplicate(true),
		"campaign_complete": campaign_complete
	}

func load_save_data(data: Dictionary) -> bool:
	# Validate a complete candidate before changing the live progress object.
	if typeof(data.get("version")) != TYPE_INT or int(data.version) != SAVE_VERSION:
		return false
	var candidate_unlocked: Variant = data.get("unlocked_node")
	var candidate_nodes: Variant = data.get("completed_nodes")
	var candidate_marks: Variant = data.get("campaign_marks")
	var candidate_receipts: Variant = data.get("reward_receipts")
	var candidate_complete: Variant = data.get("campaign_complete")
	if typeof(candidate_unlocked) != TYPE_INT or int(candidate_unlocked) < 1 or int(candidate_unlocked) > TOTAL_PLANETS:
		return false
	if typeof(candidate_nodes) != TYPE_ARRAY or typeof(candidate_marks) != TYPE_INT or int(candidate_marks) < 0:
		return false
	if typeof(candidate_receipts) != TYPE_DICTIONARY or typeof(candidate_complete) != TYPE_BOOL:
		return false
	var restored_nodes: Array[int] = []
	for index in range(candidate_nodes.size()):
		var value: Variant = candidate_nodes[index]
		if typeof(value) != TYPE_INT or int(value) != index + 1:
			return false
		restored_nodes.append(int(value))
	if bool(candidate_complete):
		if restored_nodes.size() != TOTAL_PLANETS or int(candidate_unlocked) != TOTAL_PLANETS:
			return false
	elif restored_nodes.size() != int(candidate_unlocked) - 1:
		return false
	var restored_receipts: Dictionary = {}
	for key in candidate_receipts.keys():
		var node_text := str(key)
		if not node_text.is_valid_int():
			return false
		var node_id := int(node_text)
		var receipt: Variant = candidate_receipts[key]
		if not restored_nodes.has(node_id) or typeof(receipt) != TYPE_DICTIONARY:
			return false
		if int(receipt.get("node_id", -1)) != node_id or typeof(receipt.get("reward_marks")) != TYPE_INT or int(receipt.reward_marks) < 0 or receipt.get("claimed") != true:
			return false
		restored_receipts[node_text] = receipt.duplicate(true)
	if not restored_receipts.is_empty():
		if restored_receipts.size() != restored_nodes.size():
			return false
		var receipt_total := 0
		for receipt_value in restored_receipts.values():
			receipt_total += int(receipt_value.get("reward_marks", 0))
		if receipt_total != int(candidate_marks):
			return false
	unlocked_node = int(candidate_unlocked)
	completed_nodes = restored_nodes
	campaign_marks = int(candidate_marks)
	reward_receipts = restored_receipts
	campaign_complete = bool(candidate_complete)
	return true
