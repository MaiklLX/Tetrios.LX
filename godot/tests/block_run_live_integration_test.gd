extends SceneTree

const Model = preload("res://scripts/game_model.gd")
const Main = preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN LIVE INTEGRATION TEST FAILED: " + message)
	quit(1)
	return false

func _main_probe() -> Node:
	var probe = Main.new()
	probe.game = Model.new()
	probe.game.reset()
	probe.mode_select_visible = false
	return probe

func _run() -> void:
	var probe = _main_probe()
	if not _check(probe.start_block_run_session(), "Live Block Run session must initialize from the current model board"):
		return
	# Force a deterministic line-progress delta, then lock one real model piece.
	probe.game.lines = 2
	probe.game.hard_drop()
	probe._process_block_run_events()
	if not _check(probe.block_run_session.placement_count == 1, "A live piece lock must dispatch exactly one placement event"):
		return
	if not _check(probe.block_run_session.total_lines == 2, "A lock carrying a line-progress delta must dispatch the line-clear event"):
		return
	probe._process_block_run_events()
	if not _check(probe.block_run_session.placement_count == 1 and probe.block_run_session.total_lines == 2, "Repeated frame processing must not dispatch the same lock or clear twice"):
		return
	probe.block_run_session.encounter.next_attack_seconds = 1
	probe._advance_block_run_clock(1.0)
	if not _check(probe.game.grid[22].count(7) == 9 and probe.block_run_session.board[22].count(7) == 9, "A timed enemy attack must mutate the live model board through the bridge"):
		return
	probe.free()

	var overflow_probe = _main_probe()
	if not _check(overflow_probe.start_block_run_session(), "Overflow probe session must initialize"):
		return
	overflow_probe.game.grid[0][0] = 4
	overflow_probe.block_run_session.encounter.next_attack_seconds = 1
	overflow_probe._advance_block_run_clock(1.0)
	if not _check(overflow_probe.block_run_session.status == "failed" and overflow_probe.game.game_over, "A garbage attack that pushes an occupied top row out must fail the live run"):
		return
	overflow_probe.free()

	var hold_probe = _main_probe()
	if not _check(hold_probe.start_block_run_session(), "Hold-collision probe session must initialize"):
		return
	hold_probe.game.grid[0].fill(2)
	hold_probe.game.hold_piece()
	if not _check(hold_probe.game.game_over, "A blocked replacement spawn from Hold must be detected by the model"):
		return
	hold_probe._process_block_run_events()
	if not _check(hold_probe.block_run_session.status == "failed", "A Hold-triggered spawn collision must reach Block Run rescue/failure handling even without a lock event"):
		return
	hold_probe.free()

	var shield_probe = _main_probe()
	if not _check(shield_probe.start_block_run_session(), "Shield rescue probe must initialize"):
		return
	if not _check(shield_probe.block_run_session.choose_card("shield"), "Shield must be drafted before the live rescue"):
		return
	var shield_spawn: Vector2i = shield_probe.game.origin + shield_probe.game.active_cells[0]
	shield_probe.game.grid[shield_spawn.y][shield_spawn.x] = 2
	shield_probe.game.game_over = true
	shield_probe._process_block_run_events()
	if not _check(shield_probe.block_run_session.status == "running" and not shield_probe.game.game_over, "Shield must clear the blocked spawn area and resume the live run"):
		return
	if not _check(shield_probe.block_run_session.shield_charges == 0 and shield_probe.game.grid[0][shield_spawn.x] == -1, "Live Shield rescue must consume one charge and remove the blocking top-row tile"):
		return
	shield_probe.free()

	var nova_probe = _main_probe()
	if not _check(nova_probe.start_block_run_session(), "Nova rescue probe must initialize"):
		return
	if not _check(nova_probe.block_run_session.choose_card("nova"), "Nova must be drafted before the live rescue"):
		return
	# A horizontal I piece occupies only the top spawn row; clearing one
	# bottom row shifts the obstruction down and opens this spawn footprint.
	nova_probe.game.active_type = 0
	nova_probe.game.active_cells.assign(Model.SHAPES[0])
	nova_probe.game.origin = Vector2i(3, 0)
	var nova_spawn: Vector2i = nova_probe.game.origin + nova_probe.game.active_cells[0]
	nova_probe.game.grid[nova_spawn.y][nova_spawn.x] = 3
	nova_probe.game.game_over = true
	nova_probe._process_block_run_events()
	if not _check(nova_probe.block_run_session.status == "running" and not nova_probe.game.game_over, "Nova bottom-row clear must shift the blocked spawn area clear and resume the live run"):
		return
	if not _check(nova_probe.block_run_session.nova_used and nova_probe.game.grid[0][nova_spawn.x] == -1, "Live Nova rescue must be consumed once and clear the spawn obstruction"):
		return
	nova_probe.free()
	var draft_probe = _main_probe()
	if not _check(draft_probe.start_block_run_session(), "Live draft probe session must initialize"):
		return
	var live_draft: Dictionary = draft_probe.block_run_session.on_line_clear(5, 0, 1)
	if not _check(live_draft.draft_cards.size() == 3 and draft_probe._block_run_draft_is_open(), "A live level-up must open the native card draft overlay state"):
		return
	draft_probe.block_run_draft_rects.append(Rect2(20.0, 20.0, 180.0, 80.0))
	var live_selected_id := str(draft_probe.block_run_session.pending_card_draft[0].id)
	draft_probe._handle_tap(Vector2(40.0, 40.0))
	if not _check(not draft_probe._block_run_draft_is_open() and draft_probe.block_run_session.encounter.get_card_rank(live_selected_id) == 1, "Tapping a visible draft card must apply one rank and resume the encounter"):
		return
	draft_probe.free()

	var hud_probe = _main_probe()
	if not _check(hud_probe.start_block_run_session(), "HUD probe session must initialize"):
		return
	var line_goal := {"type":"lines","value":3,"target":6,"reward":15}
	var score_goal := {"type":"score","value":900,"target":900,"reward":20}
	if not _check(is_equal_approx(hud_probe._block_run_goal_ratio(line_goal), 0.5), "Goal HUD progress must clamp and scale current value against target"):
		return
	if not _check(is_equal_approx(hud_probe._block_run_goal_ratio(score_goal), 1.0), "Completed goal HUD progress must cap at 100 percent"):
		return
	if not _check(hud_probe._block_run_goal_short_label(line_goal) == "ЛИНИИ" and hud_probe._block_run_goal_short_label({"type":"survive"}) == "ВРЕМЯ", "Goal HUD must use compact Russian labels for goal families"):
		return
	if not _check(hud_probe.block_run_session.goal_states().size() == 3 and hud_probe.block_run_session.encounter.next_attack_seconds > 0, "Live encounter HUD must receive three goals and a positive attack countdown"):
		return
	if not _check(hud_probe.block_run_session.encounter.active_synergies().is_empty(), "No synergy should be shown before its card pair is drafted"):
		return
	if not _check(hud_probe.block_run_session.choose_card("score") and hud_probe.block_run_session.choose_card("mult") and hud_probe.block_run_session.encounter.active_synergies().size() == 1, "HUD synergy state must activate after both matching cards are drafted"):
		return
	hud_probe.free()

	var locked_probe = _main_probe()
	if not _check(locked_probe.start_block_run_session(), "Locked-skill probe session must initialize"):
		return
	locked_probe.configure_block_run_hero("plush", 4)
	var locked_result: Dictionary = locked_probe.activate_block_run_hero_skill()
	if not _check(not bool(locked_result.get("accepted", false)) and str(locked_result.get("reason", "")) == "locked", "Hero skill must remain locked below level five"):
		return
	locked_probe.free()

	for hero_id in ["plush", "prism", "blip", "pixel", "spark"]:
		var skill_probe = _main_probe()
		if not _check(skill_probe.start_block_run_session(), "Hero skill live probe must initialize for " + hero_id):
			return
		if not _check(skill_probe.configure_block_run_hero(hero_id, 5), "Known hero profile must configure for " + hero_id):
			return
		var skill_result: Dictionary = skill_probe.activate_block_run_hero_skill()
		if not _check(bool(skill_result.get("accepted", false)), "Live skill must activate for " + hero_id + ": " + str(skill_result)):
			return
		if not _check(skill_probe.block_run_session.hero_skill_cooldown_seconds == 45, "Hero skill must start the shared 45-second cooldown for " + hero_id):
			return
		if not _check(skill_probe.game.grid.size() == 23 and skill_probe.block_run_session.board.size() == 23, "Skill mutation must preserve the live 10x23 board for " + hero_id):
			return
		var repeated_result: Dictionary = skill_probe.activate_block_run_hero_skill()
		if not _check(not bool(repeated_result.get("accepted", false)) and str(repeated_result.get("reason", "")) == "cooldown", "Repeated activation must be rejected during cooldown for " + hero_id):
			return
		skill_probe.block_run_session.encounter.next_attack_seconds = 1000
		for second in range(45):
			skill_probe.block_run_session.advance_second()
		if not _check(skill_probe.block_run_session.hero_skill_cooldown_seconds == 0, "Cooldown must expire after 45 active run seconds for " + hero_id):
			return
		skill_probe.free()

	var paused_skill_probe = _main_probe()
	if not _check(paused_skill_probe.start_block_run_session(), "Paused-skill probe must initialize"):
		return
	paused_skill_probe.configure_block_run_hero("blip", 5)
	paused_skill_probe.paused = true
	var paused_skill_result: Dictionary = paused_skill_probe.activate_block_run_hero_skill()
	if not _check(not bool(paused_skill_result.get("accepted", false)), "Hero skill must not activate while paused"):
		return
	paused_skill_probe.paused = false
	paused_skill_probe.block_run_session.pending_card_draft.append({"id":"test-draft"})
	var draft_skill_result: Dictionary = paused_skill_probe.activate_block_run_hero_skill()
	if not _check(not bool(draft_skill_result.get("accepted", false)), "Hero skill must not activate while a card draft is open"):
		return
	paused_skill_probe.free()

	var progression_probe = _main_probe()
	if not _check(progression_probe.start_block_run_session(), "Live encounter progression probe must initialize"):
		return
	if not _check(progression_probe.configure_block_run_hero("prism", 5), "Prism must configure for the live encounter progression probe"):
		return
	var progression_session = progression_probe.block_run_session
	var starting_room: int = progression_session.encounter.room
	progression_session.encounter.enemy_hp = 1
	var prism_finish: Dictionary = progression_probe.activate_block_run_hero_skill()
	if not _check(bool(prism_finish.get("accepted", false)) and bool(prism_finish.get("enemy_defeated", false)), "Live Prism activation must defeat a one-HP encounter enemy"):
		return
	if not _check(progression_session.encounter.room == starting_room + 1 and progression_session.encounter.enemy_hp == progression_session.encounter.enemy_max_hp, "Live hero victory must advance the encounter and initialize the next enemy"):
		return
	if not _check(progression_session.hero_skill_cooldown_seconds == 45, "Encounter progression must preserve the activated hero cooldown"):
		return
	progression_probe.free()

	var receipt_probe = _main_probe()
	if not _check(receipt_probe.start_block_run_session(), "Live reward receipt probe must initialize"):
		return
	var receipt_session = receipt_probe.block_run_session
	receipt_session.goals[0] = {"id":700,"type":"lines","label":"ТЕСТ ЛИНИЙ","target":1,"reward":17,"claimed":false}
	# Build a real one-row clear: the horizontal I piece fills the four-cell gap
	# in the bottom row, so the model itself must increment the line counter.
	receipt_probe.game.active_type = 0
	receipt_probe.game.active_cells.assign(Model.SHAPES[0])
	receipt_probe.game.origin = Vector2i(3, 0)
	for column in range(Model.WIDTH):
		if column < 3 or column > 6:
			receipt_probe.game.grid[Model.HEIGHT - 1][column] = 2
	var receipt_lock_before: int = receipt_probe.game.lock_serial
	receipt_probe.game.hard_drop()
	if not _check(receipt_probe.game.lines == 1 and receipt_probe.game.last_lock_cleared == 1, "A real horizontal-I lock must clear the prepared bottom row in the gameplay model"):
		return
	if not _check(receipt_probe.game.lock_serial == receipt_lock_before + 1, "The real line-clear fixture must produce exactly one piece-lock event"):
		return
	receipt_probe._process_block_run_events()
	if not _check(receipt_session.total_lines == 1 and receipt_session.goal_reward_receipts.has("block-run-goal:700"), "A real live line-clear event must complete the active goal and issue its reward receipt"):
		return
	if not _check(receipt_session.goal_rewards_earned == 17 and receipt_session.pending_goal_reward_total() == 17, "Live goal completion must record the exact pending reward once"):
		return
	var live_receipt: Dictionary = receipt_session.claim_goal_reward("block-run-goal:700")
	if not _check(bool(live_receipt.get("accepted", false)) and int(live_receipt.get("reward", 0)) == 17, "The live goal receipt must be claimable exactly once"):
		return
	var duplicate_live_receipt: Dictionary = receipt_session.claim_goal_reward("block-run-goal:700")
	if not _check(not bool(duplicate_live_receipt.get("accepted", false)) and receipt_session.goal_rewards_claimed == 17 and receipt_session.pending_goal_reward_total() == 0, "Repeated live receipt claims must not duplicate the reward"):
		return
	receipt_probe.free()

	print("Block Run live gameplay integration tests passed: live hero progression and exactly-once goal receipts.")

	quit(0)
