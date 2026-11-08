extends SceneTree

const Effects = preload("res://scripts/campaign_effect_session.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN EFFECT SESSION TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var unsupported := Effects.new()
	if not _check(not unsupported.start("mirror"), "High-risk input effects must remain outside this adapter batch"):
		return

	var gravity := Effects.new()
	if not _check(gravity.start("gravity", 780), "Gravity adapter must start"):
		return
	gravity.advance_active_time(24.9)
	if not _check(gravity.drop_interval_ms == 780, "Gravity must not accelerate before 25 active seconds"):
		return
	gravity.advance_active_time(0.1)
	if not _check(gravity.drop_interval_ms == 725, "Gravity accelerates by the source-audited 55 ms every 25 seconds"):
		return
	gravity.advance_active_time(75.0)
	if not _check(gravity.drop_interval_ms == 560, "Large time steps must process every crossed gravity interval deterministically"):
		return

	var flip := Effects.new()
	flip.start("gravityFlip", 780)
	flip.on_line_clear(2)
	if not _check(flip.drop_interval_ms == 720 and flip.gravity_penalty_ms == 60, "Each cleared line accelerates gravity by 30 ms"):
		return
	flip.advance_active_time(29.9)
	if not _check(flip.drop_interval_ms == 720, "Gravity penalty must persist until the 30-second reset"):
		return
	flip.advance_active_time(0.1)
	if not _check(flip.drop_interval_ms == 780 and flip.gravity_penalty_ms == 0, "Accumulated gravity penalty resets at 30 active seconds"):
		return

	var artifact := Effects.new()
	artifact.start("artifactHunt")
	artifact.on_line_clear(3)
	if not _check(artifact.artifact_progress == 3, "Artifact progress accumulates cleared lines"):
		return
	var awakened := artifact.on_line_clear(1, 100)
	if not _check(awakened.score_multiplier == 1.5 and awakened.artifact_seconds_remaining == 8.0, "Four cleared lines awaken an eight-second 1.5x score window"):
		return
	artifact.advance_active_time(8.0)
	if not _check(artifact.on_line_clear(1).score_multiplier == 1.0, "Artifact multiplier expires after eight active seconds"):
		return

	var echo := Effects.new()
	echo.start("echoCombo")
	var echo_result := echo.on_line_clear(2, 300)
	if not _check(echo_result.echo_multiplier == 1.5 and echo_result.score_after_modifier == 450, "Echo multiplier grows by 0.25 per cleared line"):
		return
	echo.on_line_clear(8)
	if not _check(echo.echo_multiplier == 2.5, "Echo multiplier is capped at 2.5"):
		return
	echo.on_piece_locked(0)
	if not _check(echo.echo_multiplier == 1.0 and echo.echo_lines == 0, "Locking without a clear resets the echo chain"):
		return

	var comet := Effects.new()
	comet.start("comet")
	comet.advance_active_time(1.99)
	comet.on_piece_dropped()
	if not _check(comet.on_line_clear(1, 100).score_bonus == 200, "Comet grants 200 bonus points inside the two-second window"):
		return
	comet.advance_active_time(0.01)
	if not _check(comet.on_line_clear(1).score_bonus == 0, "Comet bonus expires at two seconds"):
		return

	var pulse := Effects.new()
	pulse.start("pulse", 780)
	var pulse_score := pulse.on_line_clear(1, 100)
	if not _check(pulse_score.score_multiplier == 1.5 and pulse_score.score_after_modifier == 150, "Pulse applies a 1.5x line-clear score multiplier"):
		return
	pulse.advance_active_time(5.0)
	if not _check(pulse.drop_interval_ms == 755, "Pulse accelerates gravity by 25 ms every five active seconds"):
		return
	pulse.advance_active_time(100.0)
	if not _check(pulse.drop_interval_ms == 180, "Pulse gravity respects the source minimum of 180 ms"):
		return

	print("Campaign isolated effect session tests passed.")
	quit(0)
