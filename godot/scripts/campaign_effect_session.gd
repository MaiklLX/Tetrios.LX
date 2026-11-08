class_name BlockBuddiesCampaignEffectSession
extends RefCounted

# KT-533: isolated, deterministic adapters for source-audited Daily rules.
# This session is deliberately not connected to Classic, Block Run or the
# campaign scene yet. Callers own the active-time clock and apply returned
# outcomes only after a later gameplay integration checkpoint.

const SUPPORTED_MODIFIERS := ["gravity", "gravityFlip", "artifactHunt", "echoCombo", "comet", "pulse"]
const MIN_GRAVITY_MS := 150
const MIN_PULSE_GRAVITY_MS := 180

var modifier_id := ""
var active_seconds := 0.0
var drop_interval_ms := 780
var gravity_penalty_ms := 0
var artifact_progress := 0
var artifact_bonus_until := 0.0
var echo_lines := 0
var echo_multiplier := 1.0
var last_piece_drop_at := -1000000.0
var dropped_piece_count := 0

func start(next_modifier_id: String, initial_drop_interval_ms: int = 780) -> bool:
	if not SUPPORTED_MODIFIERS.has(next_modifier_id):
		return false
	modifier_id = next_modifier_id
	active_seconds = 0.0
	drop_interval_ms = maxi(MIN_GRAVITY_MS, initial_drop_interval_ms)
	gravity_penalty_ms = 0
	artifact_progress = 0
	artifact_bonus_until = 0.0
	echo_lines = 0
	echo_multiplier = 1.0
	last_piece_drop_at = -1000000.0
	dropped_piece_count = 0
	return true

func is_active() -> bool:
	return not modifier_id.is_empty()

func advance_active_time(delta_seconds: float) -> Dictionary:
	if not is_active() or delta_seconds <= 0.0:
		return {"accepted":false,"drop_interval_ms":drop_interval_ms}
	var previous := active_seconds
	active_seconds += delta_seconds
	var gravity_steps := 0
	if modifier_id == "gravity":
		gravity_steps = int(floor(active_seconds / 25.0) - floor(previous / 25.0))
		for _step in range(gravity_steps):
			drop_interval_ms = maxi(MIN_GRAVITY_MS, drop_interval_ms - 55)
	elif modifier_id == "gravityFlip":
		var reset_count := int(floor(active_seconds / 30.0) - floor(previous / 30.0))
		for _step in range(reset_count):
			drop_interval_ms += gravity_penalty_ms
			gravity_penalty_ms = 0
	return {
		"accepted":true,
		"elapsed":active_seconds,
		"gravity_steps":gravity_steps,
		"drop_interval_ms":drop_interval_ms,
		"gravity_penalty_ms":gravity_penalty_ms,
		"artifact_active":active_seconds < artifact_bonus_until
	}

func on_piece_dropped() -> Dictionary:
	if not is_active():
		return {"accepted":false,"drop_interval_ms":drop_interval_ms,"piece_count":dropped_piece_count}
	last_piece_drop_at = active_seconds
	dropped_piece_count += 1
	var pulse_triggered := modifier_id == "pulse" and dropped_piece_count % 5 == 0
	if pulse_triggered:
		drop_interval_ms = maxi(MIN_PULSE_GRAVITY_MS, drop_interval_ms - 25)
	return {
		"accepted":true,
		"piece_count":dropped_piece_count,
		"pulse_triggered":pulse_triggered,
		"drop_interval_ms":drop_interval_ms
	}

func on_piece_locked(cleared_lines: int) -> Dictionary:
	if not is_active():
		return {"accepted":false,"score_multiplier":1.0,"score_bonus":0}
	if modifier_id == "echoCombo" and cleared_lines <= 0:
		echo_lines = 0
		echo_multiplier = 1.0
	return {"accepted":true,"echo_multiplier":echo_multiplier}

func on_line_clear(cleared_lines: int, base_score: int = 0) -> Dictionary:
	if not is_active() or cleared_lines <= 0:
		return {"accepted":false,"score_multiplier":1.0,"score_bonus":0,"drop_interval_ms":drop_interval_ms}
	var multiplier := 1.0
	var bonus := 0
	match modifier_id:
		"gravityFlip":
			var old_interval := drop_interval_ms
			drop_interval_ms = maxi(MIN_GRAVITY_MS, drop_interval_ms - 30 * cleared_lines)
			gravity_penalty_ms += old_interval - drop_interval_ms
		"artifactHunt":
			artifact_progress += cleared_lines
			while artifact_progress >= 4 and active_seconds >= artifact_bonus_until:
				artifact_progress -= 4
				artifact_bonus_until = active_seconds + 8.0
			if active_seconds < artifact_bonus_until:
				multiplier *= 1.5
		"echoCombo":
			echo_lines += cleared_lines
			echo_multiplier = minf(2.5, 1.0 + echo_lines * 0.25)
			multiplier *= echo_multiplier
		"comet":
			if (active_seconds - last_piece_drop_at) >= 0.0 and (active_seconds - last_piece_drop_at) < (2.0 - 0.0001):
				bonus = 200
		"pulse":
			multiplier *= 1.5
	if modifier_id == "artifactHunt" and active_seconds < artifact_bonus_until:
		multiplier = 1.5
	return {
		"accepted":true,
		"score_multiplier":multiplier,
		"score_bonus":bonus,
		"drop_interval_ms":drop_interval_ms,
		"gravity_penalty_ms":gravity_penalty_ms,
		"artifact_progress":artifact_progress,
		"artifact_seconds_remaining":maxf(0.0, artifact_bonus_until - active_seconds),
		"echo_multiplier":echo_multiplier,
		"score_after_modifier":roundi(base_score * multiplier) + bonus
	}

func snapshot() -> Dictionary:
	return {
		"modifier_id":modifier_id,
		"active_seconds":active_seconds,
		"drop_interval_ms":drop_interval_ms,
		"gravity_penalty_ms":gravity_penalty_ms,
		"artifact_progress":artifact_progress,
		"artifact_bonus_until":artifact_bonus_until,
		"echo_lines":echo_lines,
		"echo_multiplier":echo_multiplier,
		"last_piece_drop_at":last_piece_drop_at,
		"dropped_piece_count":dropped_piece_count
	}
