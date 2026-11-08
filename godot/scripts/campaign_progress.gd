class_name BlockBuddiesCampaignProgress
extends RefCounted

const SAVE_VERSION := 1
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
	var target_lines := 8 + int((node_id - 1) / 12)
	var reward := 1 + (4 if boss else 0) + (10 if node_id == TOTAL_PLANETS else 0)
	var boss_type := "none"
	if boss:
		boss_type = "speed" if planet_in_universe == 10 else ("score" if planet_in_universe == 20 else "final")
	var difficulty_tier := int(node_id / 10)
	# Every planet raises the score bar; each completed ten-planet stretch adds a lasting difficulty jump.
	var target_score := 500 + node_id * 22 + difficulty_tier * 150
	var time_limit := 150 if boss_type == "speed" else (180 if boss_type == "final" else 0)
	return {
		"node_id": node_id,
		"universe_index": universe_index,
		"universe_number": universe_index + 1,
		"universe_name": UNIVERSE_NAMES[universe_index],
		"planet_in_universe": planet_in_universe,
		"planet_name": "ПЛАНЕТА %03d" % node_id,
		"is_boss": boss,
		"boss_type": boss_type,
		"target_lines": target_lines,
		"target_score": target_score,
		"time_limit_seconds": time_limit,
		"reward_marks": reward
	}

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
	return {
		"unlocked": unlocked,
		"current": is_current,
		"completed": completed_count == PLANETS_PER_UNIVERSE,
		"completed_count": completed_count,
		"total": PLANETS_PER_UNIVERSE
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
	if cleared_lines < target_lines:
		return {"accepted": false, "reason": "objective_not_met", "remaining_lines": target_lines - cleared_lines}
	var target_score := int(definition.get("target_score", 0))
	if score < target_score:
		return {"accepted": false, "reason": "score_objective_not_met", "remaining_score": target_score - score}
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
	unlocked_node = int(candidate_unlocked)
	completed_nodes = restored_nodes
	campaign_marks = int(candidate_marks)
	reward_receipts = restored_receipts
	campaign_complete = bool(candidate_complete)
	return true
