class_name BlockBuddiesBlockRunSession
extends RefCounted

const Encounter = preload("res://scripts/block_run_model.gd")
const Effects = preload("res://scripts/block_run_effects.gd")
const Board = preload("res://scripts/block_run_board.gd")
const GOAL_TYPES: Array[String] = ["lines", "score", "survive", "level"]

const STATUS_RUNNING := "running"
const STATUS_FAILED := "failed"

var encounter: BlockBuddiesBlockRunModel
var board: Array = []
var status := STATUS_RUNNING
var run_seconds := 0
var total_lines := 0
var score := 0
var level_charge := 0
var need_lines := 5
var drop_interval_ms := 780
var relics := 0
var placement_count := 0
var hold_used := 0
var shield_charges := 0
var nova_used := false
var goals: Array[Dictionary] = []
var next_goal_id := 0
var goal_rewards_earned := 0
var hero_skill_cooldown_seconds := 0

func start() -> void:
	encounter = Encounter.new()
	encounter.start_run()
	board = _empty_board()
	status = STATUS_RUNNING
	run_seconds = 0
	total_lines = 0
	score = 0
	level_charge = 0
	need_lines = 5
	drop_interval_ms = 780
	relics = 0
	placement_count = 0
	hold_used = 0
	shield_charges = 0
	nova_used = false
	goals.clear()
	next_goal_id = 0
	goal_rewards_earned = 0
	hero_skill_cooldown_seconds = 0
	for goal_index in range(3):
		goals.append(_create_goal())

func _empty_board() -> Array:
	var result: Array = []
	for y in range(Board.HEIGHT):
		var row: Array[int] = []
		row.resize(Board.WIDTH)
		row.fill(Board.EMPTY)
		result.append(row)
	return result

func _create_goal() -> Dictionary:
	var goal_type := GOAL_TYPES[randi_range(0, GOAL_TYPES.size() - 1)]
	var goal := encounter.create_goal(
		goal_type,
		total_lines,
		score,
		run_seconds,
		1 + int(level_charge / maxi(1, need_lines)),
		randi_range(0, 600),
		randi_range(0, 1000),
		next_goal_id
	)
	next_goal_id += 1
	return goal

func _goal_value(goal: Dictionary) -> int:
	match str(goal.get("type", "")):
		"lines":
			return total_lines
		"score":
			return score
		"survive":
			return run_seconds
		"level":
			return 1 + int(level_charge / maxi(1, need_lines))
	return 0

func _settle_completed_goals() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for index in range(goals.size()):
		var goal := goals[index]
		if bool(goal.get("claimed", false)) or _goal_value(goal) < int(goal.get("target", 0)):
			continue
		var completed := goal.duplicate(true)
		completed["claimed"] = true
		var reward := int(completed.get("reward", 0))
		goal_rewards_earned += reward
		var replacement := _create_goal()
		goals[index] = replacement
		events.append({
			"completed": completed,
			"reward": reward,
			"replacement": replacement.duplicate(true)
		})
	return events

func goal_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for goal in goals:
		var state := goal.duplicate(true)
		state["value"] = _goal_value(goal)
		state["complete"] = _goal_value(goal) >= int(goal.get("target", 0))
		result.append(state)
	return result

func choose_card(card_id: String) -> bool:
	if status != STATUS_RUNNING or not encounter.choose_card(card_id):
		return false
	var draft := Effects.on_card_drafted(encounter.card_ranks, card_id, need_lines, drop_interval_ms, hold_used)
	need_lines = int(draft.need_lines)
	drop_interval_ms = int(draft.drop_ms)
	hold_used = int(draft.hold_used)
	if card_id == "shield" or card_id == "armor":
		shield_charges = int(draft.shield_charges)
	return true

func on_piece_locked() -> Dictionary:
	if status != STATUS_RUNNING:
		return {"accepted":false,"score_bonus":0,"goal_events":[]}
	placement_count += 1
	var result := Effects.on_piece_locked(encounter.card_ranks, placement_count)
	score += int(result.score_bonus)
	var goal_events := _settle_completed_goals()
	return {
		"accepted":true,
		"score_bonus":int(result.score_bonus),
		"hold_limit":int(result.hold_limit),
		"goal_events":goal_events
	}

func on_line_clear(cleared: int, combo_after_clear: int, level: int) -> Dictionary:
	if status != STATUS_RUNNING or cleared <= 0:
		return {"accepted":false,"defeated":false,"score":0,"monster_damage":0,"goal_events":[]}
	var next_total := total_lines + cleared
	var result := Effects.on_line_clear(
		encounter.card_ranks,
		cleared,
		next_total,
		combo_after_clear,
		level,
		run_seconds,
		need_lines
	)
	total_lines = next_total
	score += int(result.score)
	level_charge += int(result.level_charge)
	relics += int(result.relics_added)
	var damage := encounter.damage_enemy(int(result.monster_damage))
	var rows_cleared := 0
	if bool(damage.defeated):
		var rift_rows := int(Effects.on_monster_defeated(encounter.card_ranks).bottom_rows_to_clear)
		var clear_result := Board.clear_bottom_rows(board, rift_rows)
		rows_cleared = int(clear_result.cleared)
	var goal_events := _settle_completed_goals()
	return {
		"accepted":true,
		"score":int(result.score),
		"score_total":score,
		"monster_damage":int(damage.damaged),
		"enemy_defeated":bool(damage.defeated),
		"room":encounter.room,
		"floor":encounter.floor,
		"boss":encounter.boss,
		"rift_rows_cleared":rows_cleared,
		"level_charge":int(result.level_charge),
		"relics_added":int(result.relics_added),
		"flash":bool(result.flash),
		"reset_drop":bool(result.reset_drop),
		"goal_events":goal_events
	}

func advance_second() -> Dictionary:
	if status != STATUS_RUNNING:
		return {"accepted":false,"attack":false,"failed":status == STATUS_FAILED,"goal_events":[]}
	run_seconds += 1
	hero_skill_cooldown_seconds = maxi(0, hero_skill_cooldown_seconds - 1)
	var timer_effect := Effects.on_timer_second(encounter.card_ranks, run_seconds)
	score += int(timer_effect.score_bonus)
	level_charge += int(timer_effect.level_charge)
	var goal_events := _settle_completed_goals()
	encounter.next_attack_seconds -= 1
	if encounter.next_attack_seconds > 0:
		return {
			"accepted":true,
			"attack":false,
			"score_bonus":int(timer_effect.score_bonus),
			"level_charge":int(timer_effect.level_charge),
			"goal_events":goal_events
		}
	var attack := encounter.resolve_enemy_attack()
	var insertion := {"valid":true,"overflow":false,"inserted":0}
	if not bool(attack.absorbed):
		insertion = Board.insert_garbage_rows(board, attack.rows)
	if not bool(insertion.valid) or bool(insertion.overflow):
		status = STATUS_FAILED
	return {
		"accepted":true,
		"attack":true,
		"attack_id":str(attack.profile.id),
		"absorbed":bool(attack.absorbed),
		"rows_inserted":int(insertion.inserted),
		"overflow":bool(insertion.overflow),
		"failed":status == STATUS_FAILED,
		"score_bonus":int(timer_effect.score_bonus),
		"level_charge":int(timer_effect.level_charge),
		"goal_events":goal_events
	}


func use_hero_skill(hero_id: String, hero_level: int) -> Dictionary:
	if status != STATUS_RUNNING:
		return {"accepted":false,"reason":"run_not_active"}
	if hero_level < 5:
		return {"accepted":false,"reason":"locked"}
	if hero_skill_cooldown_seconds > 0:
		return {"accepted":false,"reason":"cooldown","remaining":hero_skill_cooldown_seconds}
	var tier := 1 + int((hero_level - 5) / 5)
	var result := {"accepted":true,"hero_id":hero_id,"tier":tier,"cooldown":45,"enemy_damage":0,"enemy_defeated":false,"rows_cleared":0,"level_charge_added":0,"attack_delay_added":0,"score_bonus":0}
	match hero_id:
		"plush":
			var rows := mini(Board.HEIGHT, 2 + tier)
			for y in range(rows):
				board[y].fill(Board.EMPTY)
			result.rows_cleared = rows
		"prism":
			var prism_damage := 8 + tier * 5
			var prism_hit := encounter.damage_enemy(prism_damage)
			result.enemy_damage = int(prism_hit.damaged)
			result.enemy_defeated = bool(prism_hit.defeated)
			if bool(prism_hit.defeated):
				var prism_rift_rows := mini(3, int(Effects.on_monster_defeated(encounter.card_ranks).bottom_rows_to_clear))
				var prism_cleared := Board.clear_bottom_rows(board, prism_rift_rows)
				result.rows_cleared = int(prism_cleared.cleared)
		"spark":
			var spark_damage := 12 + tier * 5
			var spark_hit := encounter.damage_enemy(spark_damage)
			result.enemy_damage = int(spark_hit.damaged)
			result.enemy_defeated = bool(spark_hit.defeated)
			if bool(spark_hit.defeated):
				var spark_rift_rows := mini(3, int(Effects.on_monster_defeated(encounter.card_ranks).bottom_rows_to_clear))
				var spark_cleared := Board.clear_bottom_rows(board, spark_rift_rows)
				result.rows_cleared = int(spark_cleared.cleared)
		"blip":
			var delay := 12 + tier * 4
			encounter.next_attack_seconds += delay
			result.attack_delay_added = delay
		"pixel":
			var cleared := Board.clear_bottom_rows(board, tier)
			result.rows_cleared = int(cleared.cleared)
			level_charge += tier
			result.level_charge_added = tier
		_:
			return {"accepted":false,"reason":"unknown_hero"}
	hero_skill_cooldown_seconds = 45
	result["cooldown_remaining"] = hero_skill_cooldown_seconds
	return result


func on_spawn_collision() -> Dictionary:
	if status != STATUS_RUNNING:
		return {"accepted":false,"rescued":false,"rescue_type":"","rows_cleared":0}
	var rescue := Effects.on_spawn_collision(encounter.card_ranks, shield_charges, nova_used)
	if not bool(rescue.rescued):
		return {"accepted":true,"rescued":false,"rescue_type":"","rows_cleared":0}
	shield_charges = int(rescue.shield_charges_remaining)
	var rows_cleared := 0
	if str(rescue.rescue_type) == "shield":
		var start_row := int(rescue.shield_start_row)
		var row_count := int(rescue.shield_randomized_rows)
		var fill_probability := float(rescue.shield_fill_probability)
		var seed_value := room_seed()
		for row_index in range(start_row, mini(Board.HEIGHT, start_row + row_count)):
			var row: Array[int] = []
			row.resize(Board.WIDTH)
			row.fill(Board.EMPTY)
			for x in range(Board.WIDTH):
				var roll := float((seed_value + row_index * 37 + x * 17) % 1000) / 1000.0
				if roll < fill_probability:
					row[x] = Board.GARBAGE
			board[row_index] = row
	elif str(rescue.rescue_type) == "nova":
		rows_cleared = int(Board.clear_bottom_rows(board, int(rescue.bottom_rows_to_clear)).cleared)
		nova_used = true
	return {
		"accepted":true,
		"rescued":true,
		"rescue_type":str(rescue.rescue_type),
		"rows_cleared":rows_cleared,
		"shield_charges_remaining":shield_charges,
		"nova_used":nova_used,
		"iron_fortress":bool(rescue.iron_fortress)
	}

func room_seed() -> int:
	return encounter.room * 97 + encounter.floor * 31 + run_seconds * 13 + placement_count * 7

func add_relics(amount: int) -> void:
	relics += maxi(0, amount)
