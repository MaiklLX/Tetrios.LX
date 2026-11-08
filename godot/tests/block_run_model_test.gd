extends SceneTree

const BlockRun = preload("res://scripts/block_run_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var run = BlockRun.new()
	run.start_run()
	if not _check(run.room == 1 and run.floor == 1 and not run.boss and run.enemy_hp == 7 and run.next_attack_seconds == 32, "Room 1 must match legacy HP and attack timer"):
		return
	if not _check(run.card_catalog().size() == 35, "All 35 original upgrade cards must be represented"):
		return
	if not _check(run.current_attack_profile().id == "breach" and run.current_attack_profile().rows == 1 and run.current_attack_profile().holes == 1, "Normal room attack zero must be Breach"):
		return
	var breach_rows: Array[int] = run.build_garbage_row(0)
	if not _check(breach_rows.size() == 10 and breach_rows.count(0) == 1 and breach_rows.count(7) == 9, "Breach row must contain one deterministic hole"):
		return
	var first_damage: Dictionary = run.damage_enemy(6)
	if not _check(not first_damage.defeated and run.enemy_hp == 1, "Enemy damage must clamp without premature defeat"):
		return
	var room_clear: Dictionary = run.damage_enemy(1)
	if not _check(room_clear.defeated and run.room == 2 and run.floor == 1 and run.enemy_hp == 8, "Defeating room one must advance and initialize room two"):
		return
	run.room = 5
	run._start_room()
	if not _check(run.floor == 1 and run.boss and run.enemy_hp == 35 and run.next_attack_seconds == 20, "Room five must be a boss with source-matched HP and timer"):
		return
	if not _check(run.current_attack_profile().id == "siege" and run.current_attack_profile().rows == 2 and run.current_attack_profile().holes == 1, "Boss attack zero must use Siege"):
		return
	var siege: Dictionary = run.resolve_enemy_attack()
	if not _check(siege.rows.size() == 2 and siege.rows[0].count(0) == 1 and run.next_attack_seconds == 20, "Boss attack resolution must create two one-hole rows and reset timer"):
		return
	run.attack_index = 1
	if not _check(run.current_attack_profile().id == "crossfire", "Second boss attack must be Crossfire"):
		return
	var crossfire: Dictionary = run.resolve_enemy_attack()
	if not _check(crossfire.rows.size() == 2 and crossfire.rows[0].count(0) == 2 and crossfire.rows[1].count(0) == 2, "Crossfire must create two rows with two holes each"):
		return
	if not _check(run.choose_card("score") and run.choose_card("mult") and run.active_synergies().size() == 1 and run.active_synergies()[0].name == "КОМБО-РЕАКТОР", "Score + Mult must activate the source synergy"):
		return
	if not _check(run.get_card_rank("score") == 1 and run.get_card_effect_description("score", 2) == "Комбо даёт +30% очков за шаг", "Card rank and rank description must scale correctly"):
		return
	for i in range(4):
		if not _check(run.choose_card("score"), "A card may be drafted up to five ranks"):
			return
	if not _check(run.get_card_rank("score") == 5 and not run.choose_card("score"), "Card rank five must be a hard cap"):
		return
	if not _check(not run.choose_card("not-a-card"), "Unknown cards must never enter the build"):
		return
	run.start_run()
	if not _check(run.card_ranks.is_empty() and run.room == 1 and run.defeated == 0, "New run must reset run-local cards and encounter progression"):
		return
	if not _check(run.choose_card("reserve") and run.reserve_charges == 1, "Reserve rank must grant an attack-absorption charge"):
		return
	var absorbed: Dictionary = run.resolve_enemy_attack()
	if not _check(absorbed.absorbed and absorbed.rows.is_empty() and run.reserve_charges == 0, "Reserve must absorb one attack without inserting garbage"):
		return
	run.choose_card("slow")
	run.choose_card("memory")
	if not _check(run.active_synergies().size() == 1 and run.active_synergies()[0].name == "ХРОНОКОНТРОЛЬ", "Slow + Memory must activate Chrono Control"):
		return
	var chrono_attack: Dictionary = run.resolve_enemy_attack()
	if not _check(run.next_attack_seconds == 24 and chrono_attack.rows.size() == 1, "Chrono synergy must extend the normal attack interval by eight seconds"):
		return
	var line_goal := run.create_goal(BlockRun.GOAL_LINES, 10, 0, 0, 1, 3, 15, 7)
	var score_goal := run.create_goal(BlockRun.GOAL_SCORE, 0, 1200, 0, 1, 600, 0, 8)
	var survive_goal := run.create_goal(BlockRun.GOAL_SURVIVE, 0, 0, 20, 1, 20, 1, 9)
	var level_goal := run.create_goal(BlockRun.GOAL_LEVEL, 0, 0, 0, 4, 1, 2, 10)
	if not _check(line_goal.target == 16 and line_goal.reward == 25, "Line goal target and reward bounds must match source"):
		return
	if not _check(score_goal.target == 2200 and score_goal.reward == 10, "Score goal target must match source range"):
		return
	if not _check(survive_goal.target == 55 and survive_goal.reward == 11, "Survival goal target must match source range"):
		return
	if not _check(level_goal.target == 6 and level_goal.reward == 12, "Level goal target must match source range"):
		return
	if not _check(run.create_goal("invalid", 0, 0, 0, 1, 0, 0, 0).is_empty(), "Unknown goal type must be rejected"):
		return
	print("Block Run model tests passed.")
	quit(0)
