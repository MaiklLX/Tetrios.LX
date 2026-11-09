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
var boss_phase_index := 0
var boss_phase_start_lines := 0
var boss_phase_start_score := 0

func start(requested_mode_id: String) -> bool:
	var selected_rules := Catalog.get_mode(requested_mode_id)
	if selected_rules.is_empty():
		return false
	mode_id = requested_mode_id
	rules = selected_rules
	elapsed_seconds = 0.0
	boss_phase_index = 0
	boss_phase_start_lines = 0
	boss_phase_start_score = 0
	status = STATUS_RUNNING
	return true

func update(delta_seconds: float, total_lines: int, game_over: bool, total_score: int = 0) -> String:
	if status != STATUS_RUNNING:
		return status
	elapsed_seconds += maxf(delta_seconds, 0.0)
	var boss_phases: Variant = rules.get("boss_phases", [])
	if typeof(boss_phases) == TYPE_ARRAY and not boss_phases.is_empty():
		if boss_phase_index >= boss_phases.size():
			status = STATUS_COMPLETED
			return status
		var phase: Dictionary = boss_phases[boss_phase_index]
		var phase_lines := maxi(0, total_lines - boss_phase_start_lines)
		var phase_score := maxi(0, total_score - boss_phase_start_score)
		var required_lines := int(phase.get("target_lines", 0))
		var required_score := int(phase.get("target_score", 0))
		var phase_complete := (required_lines <= 0 or phase_lines >= required_lines) and (required_score <= 0 or phase_score >= required_score)
		if phase_complete:
			boss_phase_index += 1
			boss_phase_start_lines = total_lines
			boss_phase_start_score = total_score
			if boss_phase_index >= boss_phases.size():
				status = STATUS_COMPLETED
				return status
		return status
	var target_lines := int(rules.get("target_lines", 0))
	var target_score := int(rules.get("target_score", 0))
	var target_survive := float(rules.get("target_survive_seconds", 0))
	if target_survive > 0.0 and elapsed_seconds >= target_survive:
		status = STATUS_COMPLETED
		return status
	var lines_complete := target_lines <= 0 or total_lines >= target_lines
	var score_complete := target_score <= 0 or total_score >= target_score
	if (target_lines > 0 or target_score > 0) and lines_complete and score_complete:
		status = STATUS_COMPLETED
		return status
	var time_limit := float(rules.get("time_limit_seconds", 0))
	if time_limit > 0.0 and elapsed_seconds >= time_limit:
		status = STATUS_FAILED
		return status
	if game_over:
		status = STATUS_FAILED
	return status

func has_boss_phases() -> bool:
	var phases: Variant = rules.get("boss_phases", [])
	return typeof(phases) == TYPE_ARRAY and not phases.is_empty()

func current_boss_phase() -> Dictionary:
	if not has_boss_phases():
		return {}
	var phases: Array = rules.get("boss_phases", [])
	if boss_phase_index < 0 or boss_phase_index >= phases.size():
		return {}
	return phases[boss_phase_index].duplicate(true)

func boss_phase_progress(total_lines: int, total_score: int) -> Dictionary:
	var phase := current_boss_phase()
	if phase.is_empty():
		return {}
	var phases: Array = rules.get("boss_phases", [])
	return {
		"index": boss_phase_index + 1,
		"count": phases.size(),
		"title": str(phase.get("title", "ФАЗА")),
		"lines": maxi(0, total_lines - boss_phase_start_lines),
		"target_lines": int(phase.get("target_lines", 0)),
		"score": maxi(0, total_score - boss_phase_start_score),
		"target_score": int(phase.get("target_score", 0))
	}

func remaining_lines(total_lines: int) -> int:
	var target_lines := int(rules.get("target_lines", 0))
	if target_lines <= 0:
		return 0
	return maxi(0, target_lines - total_lines)

func is_running() -> bool:
	return status == STATUS_RUNNING
