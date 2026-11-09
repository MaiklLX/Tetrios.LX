extends SceneTree

const Session = preload("res://scripts/mode_session.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = Session.new()
	assert(session.start("campaign"))
	session.rules["target_lines"] = 10
	session.rules["target_score"] = 500
	assert(session.update(1.0, 10, false, 400) == Session.STATUS_RUNNING, "Campaign boss must keep running until both objectives are met")
	assert(session.update(1.0, 10, false, 500) == Session.STATUS_COMPLETED, "Campaign boss must complete when line and score objectives are met")
	var timed = Session.new()
	assert(timed.start("campaign"))
	timed.rules["target_lines"] = 10
	timed.rules["time_limit_seconds"] = 5.0
	assert(timed.update(4.0, 9, false, 0) == Session.STATUS_RUNNING)
	assert(timed.update(1.0, 9, false, 0) == Session.STATUS_FAILED, "Timed boss must fail at its deadline when the objective is incomplete")

	var phased = Session.new()
	assert(phased.start("campaign"))
	phased.rules["target_lines"] = 12
	phased.rules["target_score"] = 1420
	phased.rules["boss_phases"] = [
		{"title":"Разведка заслона","target_lines":4,"target_score":0},
		{"title":"Перехват конвоя","target_lines":4,"target_score":450},
		{"title":"Разрыв блокады","target_lines":4,"target_score":970}
	]
	assert(phased.update(1.0, 4, false, 200) == Session.STATUS_RUNNING, "Boss must advance after phase one without completing the encounter")
	assert(phased.boss_phase_index == 1, "Boss phase index must advance to phase two")
	var phase_two: Dictionary = phased.boss_phase_progress(4, 200)
	assert(phase_two.title == "Перехват конвоя" and phase_two.lines == 0 and phase_two.score == 0, "Each phase must use a fresh progress baseline")
	assert(phased.update(1.0, 8, false, 649) == Session.STATUS_RUNNING, "Phase two must wait until both its line and score quotas are met")
	assert(phased.boss_phase_index == 1, "An incomplete phase must not advance")
	assert(phased.update(1.0, 8, false, 650) == Session.STATUS_RUNNING, "Boss must advance to its final phase after phase two")
	assert(phased.boss_phase_index == 2, "Boss must enter phase three")
	assert(phased.update(1.0, 12, false, 1619) == Session.STATUS_RUNNING, "Final boss phase must reject a near miss")
	assert(phased.update(1.0, 12, false, 1620) == Session.STATUS_COMPLETED, "Boss encounter must complete only after the final phase")
	assert(phased.boss_phase_index == 3, "Completed boss must consume all authored phases")
	print("Campaign boss session tests passed: combined objectives, timed failure, sequential phases and per-phase progress baselines.")
	quit(0)
