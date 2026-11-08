class_name BlockBuddiesBlockRunSession
extends RefCounted

const Encounter = preload("res://scripts/block_run_model.gd")
const Effects = preload("res://scripts/block_run_effects.gd")
const Board = preload("res://scripts/block_run_board.gd")

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

func _empty_board() -> Array:
	var result: Array = []
	for y in range(Board.HEIGHT):
		var row: Array[int] = []
		row.resize(Board.WIDTH)
		row.fill(Board.EMPTY)
		result.append(row)
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
		return {"accepted":false,"score_bonus":0}
	placement_count += 1
	var result := Effects.on_piece_locked(encounter.card_ranks, placement_count)
	score += int(result.score_bonus)
	return {"accepted":true,"score_bonus":int(result.score_bonus),"hold_limit":int(result.hold_limit)}

func on_line_clear(cleared: int, combo_after_clear: int, level: int) -> Dictionary:
	if status != STATUS_RUNNING or cleared <= 0:
		return {"accepted":false,"defeated":false,"score":0,"monster_damage":0}
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
		"reset_drop":bool(result.reset_drop)
	}

func advance_second() -> Dictionary:
	if status != STATUS_RUNNING:
		return {"accepted":false,"attack":false,"failed":status == STATUS_FAILED}
	run_seconds += 1
	var timer_effect := Effects.on_timer_second(encounter.card_ranks, run_seconds)
	score += int(timer_effect.score_bonus)
	level_charge += int(timer_effect.level_charge)
	encounter.next_attack_seconds -= 1
	if encounter.next_attack_seconds > 0:
		return {"accepted":true,"attack":false,"score_bonus":int(timer_effect.score_bonus),"level_charge":int(timer_effect.level_charge)}
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
		"level_charge":int(timer_effect.level_charge)
	}

func add_relics(amount: int) -> void:
	relics += maxi(0, amount)
