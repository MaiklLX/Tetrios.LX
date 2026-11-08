class_name BlockBuddiesModeSession
extends RefCounted

const Catalog = preload("res://scripts/mode_catalog.gd")

const STATUS_IDLE := "idle"
const STATUS_RUNNING := "running"
const STATUS_COMPLETED := "completed"
const STATUS_FAILED := "failed"

var mode_id := ""
var rules: Dictionary = {}
var status := STATUS_IDLE
var elapsed_seconds := 0.0

func start(requested_mode_id: String) -> bool:
	var selected_rules := Catalog.get_mode(requested_mode_id)
	if selected_rules.is_empty():
		return false
	mode_id = requested_mode_id
	rules = selected_rules
	elapsed_seconds = 0.0
	status = STATUS_RUNNING
	return true

func update(delta_seconds: float, total_lines: int, game_over: bool, total_score: int = 0) -> String:
	if status != STATUS_RUNNING:
		return status
	elapsed_seconds += maxf(delta_seconds, 0.0)
	var target_lines := int(rules.get("target_lines", 0))
	var target_score := int(rules.get("target_score", 0))
	var lines_complete := target_lines <= 0 or total_lines >= target_lines
	var score_complete := target_score <= 0 or total_score >= target_score
	if lines_complete and score_complete:
		status = STATUS_COMPLETED
		return status
	var time_limit := float(rules.get("time_limit_seconds", 0))
	if time_limit > 0.0 and elapsed_seconds >= time_limit:
		status = STATUS_FAILED
		return status
	if game_over:
		status = STATUS_FAILED
	return status

func remaining_lines(total_lines: int) -> int:
	var target_lines := int(rules.get("target_lines", 0))
	if target_lines <= 0:
		return 0
	return maxi(0, target_lines - total_lines)

func is_running() -> bool:
	return status == STATUS_RUNNING
