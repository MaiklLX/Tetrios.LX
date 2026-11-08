extends SceneTree

const Session = preload("res://scripts/block_run_session.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN SESSION TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	seed(471)
	print("KT471 TEST: before initial run")
	var run = Session.new()
	run.start()
	if not _check(run.status == Session.STATUS_RUNNING and run.encounter.room == 1 and run.board.size() == 23, "Session must initialize a fresh encounter and 10x23 board"):
		return
	print("KT471 TEST: initial goals created")
	if not _check(run.goals.size() == 3 and run.goal_states().size() == 3, "A new run must begin with exactly three active goals"):
		return
	var goal_ids: Dictionary = {}
	for goal in run.goals:
		if not _check(int(goal.reward) >= 10 and int(goal.reward) <= 25 and int(goal.target) > 0, "Generated goals must use source reward and positive target ranges"):
			return
		if not _check(not goal_ids.has(int(goal.id)), "Active goal IDs must be unique"):
			return
		goal_ids[int(goal.id)] = true
	if not _check(run.choose_card("score") and run.choose_card("burst") and run.choose_card("hunter"), "Session must draft valid cards into its isolated encounter"):
		return
	print("KT471 TEST: before initial line clear")
	var clear := run.on_line_clear(3, 2, 1)
	print("KT471 TEST: initial line clear settled")
	if not _check(clear["accepted"] and clear["score_total"] > 0 and clear["monster_damage"] == 3 + 2 + 1, "Line clear must route score and card damage into the active encounter"):
		return
	if not _check(run.total_lines == 3 and run.encounter.enemy_hp < run.encounter.enemy_max_hp, "Line clear must update run progress and enemy HP"):
		return

	print("KT471 TEST: initial combat passed")
	var line_goal_run = Session.new()
	line_goal_run.start()
	line_goal_run.goals.clear()
	line_goal_run.goals.append(line_goal_run.encounter.create_goal("lines", 0, 0, 0, 1, 0, 5, 900))
	var line_goal_event := line_goal_run.on_line_clear(3, 0, 1)
	if not _check(line_goal_event.goal_events.size() == 1 and line_goal_event.goal_events[0].reward == 15, "Completing a line goal must award its exact generated reward"):
		return
	if not _check(line_goal_run.goals.size() == 1 and line_goal_run.goals[0].id != 900 and line_goal_run.goal_rewards_earned == 15, "A completed goal must be replaced immediately and rewards counted once"):
		return

	print("KT471 TEST: line goal passed")
	var survive_goal_run = Session.new()
	survive_goal_run.start()
	survive_goal_run.goals.clear()
	survive_goal_run.goals.append(survive_goal_run.encounter.create_goal("survive", 0, 0, 0, 1, 0, 7, 901))
	var survive_event: Dictionary = {}
	for second in range(15):
		survive_event = survive_goal_run.advance_second()
	if not _check(survive_event.goal_events.size() == 1 and survive_goal_run.run_seconds == 15, "Survive goals must settle when the source-defined minimum timer target is reached"):
		return

	print("KT471 TEST: survive goal passed")
	var score_goal_run = Session.new()
	score_goal_run.start()
	score_goal_run.goals.clear()
	score_goal_run.goals.append(score_goal_run.encounter.create_goal("score", 0, 0, 0, 1, 0, 9, 902))
	var score_event := score_goal_run.on_line_clear(4, 0, 1)
	if not _check(score_event.goal_events.size() == 1 and score_goal_run.score > 0, "Line-clear score must update score goals"):
		return

	print("KT471 TEST: score goal passed")
	var attack_run = Session.new()
	attack_run.start()
	attack_run.encounter.next_attack_seconds = 1
	var attack := attack_run.advance_second()
	if not _check(attack["attack"] and attack["attack_id"] == "breach" and attack["rows_inserted"] == 1 and attack_run.board[22].count(7) == 9, "Attack timer must resolve Breach and insert its garbage row into the session board"):
		return
	var reserve_run = Session.new()
	reserve_run.start()
	if not _check(reserve_run.choose_card("reserve"), "Reserve card must draft"):
		return
	reserve_run.encounter.next_attack_seconds = 1
	var absorbed := reserve_run.advance_second()
	if not _check(absorbed["attack"] and absorbed["absorbed"] and reserve_run.board[22].count(7) == 0, "Reserve must absorb an attack without changing the board"):
		return
	var overflow_run = Session.new()
	overflow_run.start()
	overflow_run.board[0][0] = 2
	overflow_run.encounter.next_attack_seconds = 1
	var overflow := overflow_run.advance_second()
	if not _check(overflow["overflow"] and overflow["failed"] and overflow_run.status == Session.STATUS_FAILED, "Garbage overflow must end the run instead of silently losing board cells"):
		return
	var stopped := overflow_run.advance_second()
	if not _check(not stopped["accepted"], "A failed run must reject later timer events"):
		return

	print("KT472 TEST: source-matched hero abilities")
	var locked_skill_run = Session.new()
	locked_skill_run.start()
	var locked_skill := locked_skill_run.use_hero_skill("plush", 4)
	if not _check(not locked_skill.accepted and locked_skill.reason == "locked", "Hero skills must remain locked below level five"):
		return
	var plush_run = Session.new()
	plush_run.start()
	plush_run.board[0][0] = 3
	plush_run.board[1][1] = 4
	var plush_skill := plush_run.use_hero_skill("plush", 5)
	if not _check(plush_skill.accepted and plush_skill.rows_cleared == 3 and plush_run.board[0][0] == -1 and plush_run.board[2][0] == -1, "Plush must clear the top 2+tier rows"):
		return
	var prism_run = Session.new()
	prism_run.start()
	var prism_hp: int = prism_run.encounter.enemy_hp
	var prism_skill := prism_run.use_hero_skill("prism", 5)
	if not _check(prism_skill.enemy_damage == mini(prism_hp, 13) and prism_run.hero_skill_cooldown_seconds == 45, "Prism must deal 8+tier*5 damage and start a 45-second cooldown"):
		return
	var blip_run = Session.new()
	blip_run.start()
	var attack_before: int = blip_run.encounter.next_attack_seconds
	var blip_skill := blip_run.use_hero_skill("blip", 10)
	if not _check(blip_skill.attack_delay_added == 20 and blip_run.encounter.next_attack_seconds == attack_before + 20, "Blip must delay the next attack by 12+tier*4 seconds"):
		return
	var pixel_run = Session.new()
	pixel_run.start()
	pixel_run.board[22].fill(7)
	var pixel_skill := pixel_run.use_hero_skill("pixel", 10)
	if not _check(pixel_skill.rows_cleared == 2 and pixel_skill.level_charge_added == 2 and pixel_run.level_charge == 2 and pixel_run.board[22].count(7) == 0, "Pixel must clear tier bottom rows and add matching level charge"):
		return
	var spark_run = Session.new()
	spark_run.start()
	var spark_hp: int = spark_run.encounter.enemy_hp
	var spark_skill := spark_run.use_hero_skill("spark", 5)
	if not _check(spark_skill.enemy_damage == mini(spark_hp, 17), "Spark must deal 12+tier*5 damage"):
		return
	var cooldown_skill := spark_run.use_hero_skill("spark", 5)
	if not _check(not cooldown_skill.accepted and cooldown_skill.reason == "cooldown" and cooldown_skill.remaining == 45, "Hero skill must reject repeated activation during cooldown"):
		return
	var cooldown_elapsed := spark_run.advance_second()
	if not _check(cooldown_elapsed.accepted and spark_run.hero_skill_cooldown_seconds == 44, "Hero cooldown must decrease in real run seconds"):
		return


	print("KT473 TEST: Shield and Nova rescue mutations")
	var shield_rescue_run = Session.new()
	shield_rescue_run.start()
	if not _check(shield_rescue_run.choose_card("shield"), "Shield card must draft before rescue"):
		return
	var shield_before: int = shield_rescue_run.shield_charges
	var shield_rescue := shield_rescue_run.on_spawn_collision()
	if not _check(shield_rescue.rescued and shield_rescue.rescue_type == "shield" and shield_rescue.shield_charges_remaining == shield_before - 1, "Shield must consume exactly one charge and rescue the spawn collision"):
		return
	var shield_changed := false
	for y in range(20, 23):
		for x in range(10):
			if shield_rescue_run.board[y][x] == 7:
				shield_changed = true
	if not _check(shield_changed, "Shield rescue must mutate its source-defined bottom three-row zone"):
		return
	if not _check(shield_rescue_run.board[0].count(7) == 0 and shield_rescue_run.board[0].count(-1) == 10, "Shield must also clear the upper spawn area as in the Web source"):
		return
	var fortress_run = Session.new()
	fortress_run.start()
	if not _check(fortress_run.choose_card("shield") and fortress_run.choose_card("armor"), "Shield and Armor must draft for Iron Fortress"):
		return
	var fortress_rescue := fortress_run.on_spawn_collision()
	if not _check(fortress_rescue.rescued and fortress_rescue.iron_fortress and fortress_run.shield_charges == 1, "Iron Fortress must use five randomized rows and consume one of the combined charges"):
		return
	var nova_run = Session.new()
	nova_run.start()
	if not _check(nova_run.choose_card("nova"), "Nova card must draft before emergency rescue"):
		return
	nova_run.board[22].fill(7)
	var nova_rescue := nova_run.on_spawn_collision()
	if not _check(nova_rescue.rescued and nova_rescue.rescue_type == "nova" and nova_rescue.rows_cleared == 1 and nova_run.board[22].count(7) == 0 and nova_run.nova_used, "Nova must clear its ranked number of bottom rows exactly once"):
		return
	var nova_again := nova_run.on_spawn_collision()
	if not _check(not nova_again.rescued and nova_run.nova_used, "Nova must not rescue a second spawn collision"):
		return

	print("Block Run session integration tests passed: three live goals, replacement, rewards, timer/score/line progress, combat, attacks and failure.")
	quit(0)
