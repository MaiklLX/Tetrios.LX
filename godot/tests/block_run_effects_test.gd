extends SceneTree

const Effects = preload("res://scripts/block_run_effects.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("BLOCK RUN EFFECT TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var ranks := {
		"score":3,"mult":1,"glow":1,"neuron":1,"dust":1,"magnet":1,
		"burst":2,"hunter":1,"resonance":2,"echo":1,"reactor":1,
		"infinity":1,"flash":1,"plasma":1
	}
	var clear := Effects.on_line_clear(ranks, 3, 10, 2, 2, 12, 5)
	if not _check(clear["score"] > 0 and clear["score_multiplier"] > 1.0, "Line-clear scoring must combine rank-based multipliers"):
		return
	if not _check(clear["monster_damage"] == 3 * 2 + 4 + 1, "Score rank three, Burst and Hunter must add the source-matched monster damage"):
		return
	if not _check(clear["level_charge"] == 2 + 1 + 5, "Resonance, Echo and Reactor must contribute on their respective line boundaries"):
		return
	if not _check(clear["relics_added"] == 1 and clear["flash"] and clear["reset_drop"], "Infinity, Flash and Plasma must fire on a three-line clear"):
		return
	var single := Effects.on_line_clear({"dust":2}, 1, 1, 1, 1, 35, 5)
	if not _check(single["score"] == 300 and single["monster_damage"] == 1, "Single clear must add Dust and base monster damage"):
		return
	var empty_clear := Effects.on_line_clear({"dust":2}, 0, 0, 0, 1, 0, 5)
	if not _check(empty_clear["score"] == 0 and empty_clear["monster_damage"] == 0, "No clear must not grant card rewards"):
		return
	var timer45 := Effects.on_timer_second({"tide":2,"unstable":1}, 45)
	var timer90 := Effects.on_timer_second({"tide":2,"unstable":1}, 90)
	if not _check(timer45["level_charge"] == 2 and timer45["score_bonus"] == 0, "Tide must grant charge every 45 seconds"):
		return
	if not _check(timer90["level_charge"] == 2 and timer90["score_bonus"] == 500, "Tide and Unstable must both resolve on the 90-second boundary"):
		return
	var level_up := Effects.on_level_up({"memory":1,"loop":1,"slow":1,"fortress":1,"void":1,"comet":1}, 5, 2, 760)
	if not _check(level_up["next_need_lines"] == 3, "Memory, Loop and Chrono Control must reduce the next level threshold with a floor of three"):
		return
	if not _check(level_up["next_drop_ms"] == 760 - 48 - 6 + 15 + 25 + 12, "Slow, Fortress and Chrono Control must affect level-up gravity interval"):
		return
	if not _check(level_up["void_compression_attempt"] and level_up["comet_requires_source_review"] and level_up["comet_score_bonus"] == 0, "Void must request compression and Comet must remain gated for source-bug review"):
		return
	var loop_draft := Effects.on_card_drafted({"loop":1}, "loop", 6, 760, 0)
	var slow_draft := Effects.on_card_drafted({"slow":1}, "slow", 6, 760, 0)
	var shield_draft := Effects.on_card_drafted({"shield":1,"armor":2}, "armor", 6, 760, 0)
	var reserve_draft := Effects.on_card_drafted({"reserve":2}, "reserve", 6, 760, 0)
	var hold_draft := Effects.on_card_drafted({"hold":1}, "hold", 6, 760, 2)
	if not _check(loop_draft["need_lines"] == 5 and slow_draft["drop_ms"] == 730, "Loop and Slow must apply their immediate draft-time adjustments"):
		return
	if not _check(shield_draft["shield_charges"] == 3 and reserve_draft["reserve_charges"] == 2 and hold_draft["hold_used"] == 0, "Shield, Reserve and Hold must initialize their run-local draft state"):
		return
	var rotation := Effects.on_rotation({"stable":3,"shift":2}, 0.1)
	if not _check(rotation["max_kick_distance"] == 4 and rotation["score_bonus"] == 50, "Stable and Shift must use bounded kicks and deterministic 25-percent trigger"):
		return
	var no_shift := Effects.on_rotation({"shift":2}, 0.25)
	if not _check(no_shift["score_bonus"] == 0, "Shift must not trigger at or above the 25-percent boundary"):
		return
	var spawn := Effects.on_piece_spawn({"mirror":1,"prism":1,"aura":1}, 14, true)
	if not _check(spawn["mirror_next_piece"] and spawn["prism_visual"] and spawn["aura_visual"], "Mirror, Prism and Aura must expose the correct spawn/render effects"):
		return
	if not _check(Effects.hold_limit({"hold":3}) == 4 and Effects.hold_limit({"hold":3}, "pixel", 10) == 3 and Effects.hold_limit({"hold":3}, "pixel", 15) == 4, "Hold rank must increase the per-piece hold limit"):
		return
	var shield := Effects.on_spawn_collision({"shield":2,"armor":1}, 3, false)
	if not _check(shield["rescued"] and shield["shield_charges_remaining"] == 2 and shield["iron_fortress"] and shield["shield_randomized_rows"] == 5 and shield["shield_start_row"] == 18, "Shield + Armor must use the Iron Fortress rescue pattern"):
		return
	var nova := Effects.on_spawn_collision({"nova":2}, 0, false)
	if not _check(nova["rescued"] and nova["rescue_type"] == "nova" and nova["bottom_rows_to_clear"] == 2, "Nova must rescue once and clear rows according to rank"):
		return
	var spent_nova := Effects.on_spawn_collision({"nova":2}, 0, true)
	if not _check(not spent_nova["rescued"], "Nova must not trigger again after its one-time rescue"):
		return
	if not _check(Effects.on_monster_defeated({"rift":5})["bottom_rows_to_clear"] == 3, "Rift must cap its room-clear effect at three rows"):
		return
	if not _check(Effects.on_piece_locked({"gear":2}, 10)["score_bonus"] == 50 and Effects.on_piece_locked({"hold":3}, 10, "pixel", 10)["hold_limit"] == 3, "Gear must award rank-scaled score and Pixel must retain its hero-specific Hold override"):
		return
	print("Block Run event effect tests passed.")
	quit(0)
