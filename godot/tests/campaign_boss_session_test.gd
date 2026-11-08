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
	print("Campaign boss session tests passed: combined objectives and timed failure.")
	quit(0)
