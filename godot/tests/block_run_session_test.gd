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
	var run = Session.new()
	run.start()
	if not _check(run.status == Session.STATUS_RUNNING and run.encounter.room == 1 and run.board.size() == 23, "Session must initialize a fresh encounter and 10x23 board"):
		return
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
	var clear := run.on_line_clear(3, 2, 1)
	if not _check(clear["accepted"] and clear["score_total"] > 0 and clear["monster_damage"] == 3 + 2 + 1, "Line clear must route score and card damage into the active encounter"):
		return
	if not _check(run.total_lines == 3 and run.encounter.enemy_hp < run.encounter.enemy_max_hp, "Line clear must update run progress and enemy HP"):
		return

	var line_goal_run = Session.new()
	line_goal_run.start()
	line_goal_run.goals = [line_goal_run.encounter.create_goal("lines", 0, 0, 0, 1, 0, 5, 900)]
	var line_goal_event := line_goal_run.on_line_clear(1, 0, 1)
	if not _check(line_goal_event.goal_events.size() == 1 and line_goal_event.goal_events[0].reward == 15, "Completing a line goal must award its exact generated reward"):
		return
	if not _check(line_goal_run.goals.size() == 1 and line_goal_run.goals[0].id != 900 and line_goal_run.goal_rewards_earned == 15, "A completed goal must be replaced immediately and rewards counted once"):
		return

	var survive_goal_run = Session.new()
	survive_goal_run.start()
	survive_goal_run.goals = [survive_goal_run.encounter.create_goal("survive", 0, 0, 0, 1, 0, 7, 901)]
	var survive_event := survive_goal_run.advance_second()
	if not _check(survive_event.goal_events.size() == 1 and survive_goal_run.run_seconds == 1, "Survive goals must settle on the run clock"):
		return

	var score_goal_run = Session.new()
	score_goal_run.start()
	score_goal_run.goals = [score_goal_run.encounter.create_goal("score", 0, 0, 0, 1, 0, 9, 902)]
	var score_event := score_goal_run.on_line_clear(1, 0, 1)
	if not _check(score_event.goal_events.size() == 1 and score_goal_run.score > 0, "Line-clear score must update score goals"):
		return

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
	print("Block Run session integration tests passed: three live goals, replacement, rewards, timer/score/line progress, combat, attacks and failure.")
	quit(0)
