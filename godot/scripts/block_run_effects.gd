class_name BlockBuddiesBlockRunEffects
extends RefCounted

# Deterministic event calculations audited against legacy site/index.html.
# This layer returns outcomes; the scene/board integration applies them later.
const MAX_CARD_RANK := 5

static func _rank(ranks: Dictionary, card_id: String) -> int:
	return clampi(int(ranks.get(card_id, 0)), 0, MAX_CARD_RANK)

static func on_card_drafted(ranks: Dictionary, card_id: String, current_need_lines: int, current_drop_ms: int, current_hold_used: int) -> Dictionary:
	var next_need := current_need_lines
	var next_drop := current_drop_ms
	var next_shield_charges := 0
	var next_reserve_charges := 0
	if card_id == "loop":
		next_need = maxi(3, current_need_lines - 1)
	if card_id == "slow":
		next_drop = maxi(150, current_drop_ms - 30)
	if card_id == "shield" or card_id == "armor":
		next_shield_charges = _rank(ranks, "shield") + _rank(ranks, "armor")
	if card_id == "reserve":
		next_reserve_charges = _rank(ranks, "reserve")
	return {
		"need_lines":next_need,
		"drop_ms":next_drop,
		"hold_used":0 if card_id == "hold" else current_hold_used,
		"shield_charges":next_shield_charges,
		"reserve_charges":next_reserve_charges
	}

static func hold_limit(ranks: Dictionary) -> int:
	return 1 + _rank(ranks, "hold")

static func on_piece_locked(ranks: Dictionary, placement_count: int) -> Dictionary:
	var gear_bonus := 0
	if _rank(ranks, "gear") > 0 and placement_count > 0 and placement_count % 5 == 0:
		gear_bonus = 25 * _rank(ranks, "gear")
	return {"score_bonus":gear_bonus,"hold_limit":hold_limit(ranks)}

static func on_line_clear(ranks: Dictionary, cleared: int, total_lines_after_clear: int, combo_after_clear: int, level: int, run_seconds: int, need_lines: int) -> Dictionary:
	var count := clampi(cleared, 0, 4)
	if count <= 0:
		return {"score":0,"score_multiplier":1.0,"monster_damage":0,"level_charge":0,"relics_added":0,"flash":false,"reset_drop":false}
	var multiplier := 1.0
	multiplier *= 1.0 + 0.5 * _rank(ranks, "mult")
	multiplier *= 1.0 + float(combo_after_clear) * 0.15 * _rank(ranks, "score")
	multiplier *= 1.0 + 0.1 * _rank(ranks, "glow")
	if run_seconds < 30 and _rank(ranks, "neuron") > 0:
		multiplier *= 1.25
	if _rank(ranks, "score") > 0 and _rank(ranks, "mult") > 0:
		multiplier *= 1.12
	var base_scores := [0, 100, 300, 500, 800]
	var score_total := roundi(float(base_scores[count] * maxi(1, level)) * multiplier)
	if count == 1:
		score_total += 100 * _rank(ranks, "dust")
	if count >= 2:
		score_total += 250 * _rank(ranks, "magnet")
	if count >= 3:
		score_total += 600 * _rank(ranks, "burst")
	var level_charge := 0
	if _rank(ranks, "resonance") > 0 and total_lines_after_clear % 4 < count:
		level_charge += _rank(ranks, "resonance")
	if _rank(ranks, "echo") > 0 and total_lines_after_clear % 5 < count:
		level_charge += _rank(ranks, "echo")
	if _rank(ranks, "reactor") > 0 and total_lines_after_clear % 10 < count:
		level_charge += need_lines * _rank(ranks, "reactor")
	var relics_added := _rank(ranks, "infinity") if _rank(ranks, "infinity") > 0 and total_lines_after_clear % 10 < count else 0
	var monster_damage := count * (1 + floori(float(_rank(ranks, "score")) / 3.0))
	if count >= 3:
		monster_damage += _rank(ranks, "burst") * 2
	if count >= 2:
		monster_damage += _rank(ranks, "hunter")
	return {
		"score":score_total,
		"score_multiplier":multiplier,
		"monster_damage":monster_damage,
		"level_charge":level_charge,
		"relics_added":relics_added,
		"flash":count >= 2 and _rank(ranks, "flash") > 0,
		"reset_drop":_rank(ranks, "plasma") > 0
	}

static func on_timer_second(ranks: Dictionary, run_seconds: int) -> Dictionary:
	var level_charge := 0
	var score_bonus := 0
	if run_seconds > 0 and run_seconds % 45 == 0:
		level_charge = _rank(ranks, "tide")
	if run_seconds > 0 and run_seconds % 90 == 0:
		score_bonus = 500 * _rank(ranks, "unstable")
	return {"level_charge":level_charge,"score_bonus":score_bonus}

static func on_level_up(ranks: Dictionary, current_need_lines: int, new_level: int, current_drop_ms: int) -> Dictionary:
	var chrono_synergy := _rank(ranks, "slow") > 0 and _rank(ranks, "memory") > 0
	var next_need := ceili(float(current_need_lines) * 1.12 + float(new_level - 1) * 0.12)
	next_need -= _rank(ranks, "memory")
	next_need -= _rank(ranks, "loop")
	if chrono_synergy:
		next_need -= 1
	next_need = clampi(next_need, 3, 8)
	var next_drop := current_drop_ms - 48 - new_level * 3
	next_drop += 15 * _rank(ranks, "fortress")
	next_drop += 25 * _rank(ranks, "slow")
	if chrono_synergy:
		next_drop += 12
	next_drop = maxi(130, next_drop)
	return {
		"next_need_lines":next_need,
		"next_drop_ms":next_drop,
		"void_compression_attempt":_rank(ranks, "void") > 0,
		"comet_requires_source_review":_rank(ranks, "comet") > 0,
		"comet_score_bonus":0
	}

static func on_rotation(ranks: Dictionary, deterministic_roll: float) -> Dictionary:
	var rank := _rank(ranks, "stable")
	var max_kick := mini(4, 1 + rank) if rank > 0 else 1
	var shift_bonus := 25 * _rank(ranks, "shift") if _rank(ranks, "shift") > 0 and deterministic_roll >= 0.0 and deterministic_roll < 0.25 else 0
	return {"max_kick_distance":max_kick,"score_bonus":shift_bonus}

static func on_piece_spawn(ranks: Dictionary, total_lines: int, any_boost_active: bool) -> Dictionary:
	return {
		"mirror_next_piece":total_lines > 0 and total_lines % 7 == 0 and _rank(ranks, "mirror") > 0,
		"prism_visual":_rank(ranks, "prism") > 0,
		"aura_visual":any_boost_active and _rank(ranks, "aura") > 0
	}

static func on_spawn_collision(ranks: Dictionary, shield_charges: int, nova_used: bool) -> Dictionary:
	var shield_rank := _rank(ranks, "shield")
	var armor_rank := _rank(ranks, "armor")
	if shield_rank + armor_rank > 0 and shield_charges > 0:
		return {
			"rescued":true,
			"rescue_type":"shield",
			"shield_charges_remaining":shield_charges - 1,
			"bottom_rows_to_clear":0,
			"iron_fortress":shield_rank > 0 and armor_rank > 0,
			"shield_fill_probability":0.10 if shield_rank > 0 and armor_rank > 0 else 0.22,
			"shield_clear_rows":6 if shield_rank > 0 and armor_rank > 0 else 4
		}
	var nova_rank := _rank(ranks, "nova")
	if nova_rank > 0 and not nova_used:
		return {
			"rescued":true,
			"rescue_type":"nova",
			"shield_charges_remaining":shield_charges,
			"bottom_rows_to_clear":maxi(1, nova_rank),
			"iron_fortress":false,
			"shield_fill_probability":0.0,
			"shield_clear_rows":0
		}
	return {"rescued":false,"rescue_type":"","shield_charges_remaining":shield_charges,"bottom_rows_to_clear":0,"iron_fortress":false,"shield_fill_probability":0.0,"shield_clear_rows":0}

static func on_monster_defeated(ranks: Dictionary) -> Dictionary:
	return {"bottom_rows_to_clear":mini(3, _rank(ranks, "rift"))}
