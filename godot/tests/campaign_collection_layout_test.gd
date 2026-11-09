extends SceneTree

const CollectionLayout = preload("res://scripts/campaign_collection_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN COLLECTION LAYOUT TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var viewports := [
		Vector2(320.0, 568.0),
		Vector2(360.0, 640.0),
		Vector2(390.0, 844.0),
		Vector2(360.0, 540.0),
		Vector2(480.0, 600.0),
		Vector2(720.0, 1280.0),
		Vector2(320.0, 420.0),
		Vector2(240.0, 390.0)
	]
	for viewport in viewports:
		var layout: Dictionary = CollectionLayout.collection(viewport)
		var margin := float(layout.get("margin", 0.0))
		var gap := float(layout.get("gap", 0.0))
		var top := float(layout.get("top", 0.0))
		var cell_width := float(layout.get("cell_width", 0.0))
		var cell_height := float(layout.get("cell_height", 0.0))
		var detail: Rect2 = layout.get("detail_rect", Rect2())
		var inspect: Rect2 = layout.get("inspect_rect", Rect2())
		var grid_right := margin + 7.0 * cell_width + 6.0 * gap
		var grid_bottom := top + 7.0 * cell_height + 6.0 * gap
		if not _check(cell_width > 0.0 and cell_height >= 18.0, "All 7x7 collection cells must retain a positive, usable hit area at %s" % [viewport]):
			return
		if not _check(grid_right <= viewport.x - margin + 0.1, "Collection grid must remain within horizontal viewport bounds at %s" % [viewport]):
			return
		if not _check(grid_bottom <= detail.position.y - 7.0 + 0.1, "Collection grid must not overlap the details panel at %s" % [viewport]):
			return
		if not _check(inspect.position.x >= detail.position.x and inspect.end.x <= detail.end.x and inspect.position.y >= detail.position.y and inspect.end.y <= detail.end.y, "Inspect control must remain inside its detail panel at %s" % [viewport]):
			return
		var modal := CollectionLayout.reward_modal(viewport)
		if not _check(modal.position.x >= -0.1 and modal.position.y >= -0.1 and modal.end.x <= viewport.x + 0.1 and modal.end.y <= viewport.y + 0.1, "Reward preview modal must remain fully inside the viewport at %s" % [viewport]):
			return
	print("Campaign collection layout tests passed: 8 compact, short and desktop viewports.")
	quit(0)
