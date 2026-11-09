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
		var columns := int(layout.get("columns", 0))
		var row_count := int(layout.get("row_count", 0))
		var visible_rows := int(layout.get("visible_rows", 0))
		var cell_width := float(layout.get("cell_width", 0.0))
		var cell_height := float(layout.get("cell_height", 0.0))
		var detail: Rect2 = layout.get("detail_rect", Rect2())
		var inspect: Rect2 = layout.get("inspect_rect", Rect2())
		var grid_viewport: Rect2 = layout.get("grid_viewport_rect", Rect2())
		var expected_columns := 4 if viewport.x <= 320.0 else (5 if viewport.x <= 390.0 else (6 if viewport.x <= 480.0 else 7))
		var grid_right := margin + float(columns) * cell_width + float(columns - 1) * gap
		if not _check(columns == expected_columns and row_count == int(ceil(49.0 / float(columns))), "Collection should switch to a wider-cell grid on narrow viewports at %s" % [viewport]):
			return
		if not _check(cell_width >= 38.0 and cell_height >= 32.0, "Compact collection cells must remain large enough for touch interaction at %s" % [viewport]):
			return
		if not _check(minf(11.0, cell_width * 0.27) >= 10.5, "Compact grid must preserve near-full reward emblem size instead of shrinking artwork at %s" % [viewport]):
			return
		if not _check(visible_rows >= 1 and grid_viewport.size.y > 0.0, "Collection must expose at least one complete row at %s" % [viewport]):
			return
		if not _check(grid_right <= viewport.x - margin + 0.1, "Collection grid must remain within horizontal viewport bounds at %s" % [viewport]):
			return
		if not _check(grid_viewport.position.y == top and grid_viewport.end.y <= detail.position.y - 7.0 + 0.1, "Scrollable grid viewport must not overlap the details panel at %s" % [viewport]):
			return
		if not _check(inspect.position.x >= detail.position.x and inspect.end.x <= detail.end.x and inspect.position.y >= detail.position.y and inspect.end.y <= detail.end.y, "Inspect control must remain inside its detail panel at %s" % [viewport]):
			return
		var max_scroll := float(layout.get("max_scroll", -1.0))
		var row_step := cell_height + gap
		if not _check(max_scroll >= 0.0 and (max_scroll == 0.0 or absf(max_scroll / row_step - roundf(max_scroll / row_step)) < 0.001), "Collection scroll must snap to complete rows at %s" % [viewport]):
			return
		if not _check(bool(layout.get("scrollable", false)) == (max_scroll > 0.5), "Scroll affordance must match actual overflow at %s" % [viewport]):
			return
		var last_item_offset := CollectionLayout.scroll_offset_for_index(layout, 48, 0.0)
		var first_visible_row := roundi(last_item_offset / row_step)
		var last_item_row := 48 / columns
		if not _check(last_item_row >= first_visible_row and last_item_row < first_visible_row + visible_rows, "Newly revealed final reward must be brought into the visible grid rows at %s" % [viewport]):
			return
		var first_item_offset := CollectionLayout.scroll_offset_for_index(layout, 0, max_scroll)
		if not _check(first_item_offset == 0.0, "Selecting the first reward must scroll the collection back to its first row at %s" % [viewport]):
			return
		for item_index in range(49):
			var selected_offset := CollectionLayout.scroll_offset_for_index(layout, item_index, max_scroll * 0.5)
			var selected_first_row := roundi(selected_offset / row_step)
			var selected_row := item_index / columns
			if not _check(selected_row >= selected_first_row and selected_row < selected_first_row + visible_rows, "Every selected reward must be scrolled into view at index %d on %s" % [item_index, viewport]):
				return
			if not _check(selected_offset >= -0.1 and selected_offset <= max_scroll + 0.1, "Selection scrolling must stay within scroll bounds at index %d on %s" % [item_index, viewport]):
				return
		var scroll_visual: Dictionary = CollectionLayout.scrollbar(layout, 0.0)
		if bool(layout.get("scrollable", false)):
			var track: Rect2 = scroll_visual.get("track", Rect2())
			var thumb: Rect2 = scroll_visual.get("thumb", Rect2())
			var end_visual: Dictionary = CollectionLayout.scrollbar(layout, max_scroll)
			var end_thumb: Rect2 = end_visual.get("thumb", Rect2())
			if not _check(not track.is_empty() and not thumb.is_empty() and track.position.x >= grid_viewport.end.x and track.end.y <= grid_viewport.end.y + 0.1, "Scroll indicator must stay in the grid gutter at %s" % [viewport]):
				return
			if not _check(thumb.position.y >= track.position.y - 0.1 and thumb.end.y <= track.end.y + 0.1 and end_thumb.end.y >= thumb.end.y, "Scroll thumb must remain on its track and move downward with scroll offset at %s" % [viewport]):
				return
		else:
			var empty_track: Rect2 = scroll_visual.get("track", Rect2())
			var empty_thumb: Rect2 = scroll_visual.get("thumb", Rect2())
			if not _check(empty_track.is_empty() and empty_thumb.is_empty(), "Non-scrollable grid must not show a scroll indicator at %s" % [viewport]):
				return
		var modal := CollectionLayout.reward_modal(viewport)
		if not _check(modal.position.x >= -0.1 and modal.position.y >= -0.1 and modal.end.x <= viewport.x + 0.1 and modal.end.y <= viewport.y + 0.1, "Reward preview modal must remain fully inside the viewport at %s" % [viewport]):
			return
	print("Campaign collection layout tests passed: responsive 4x13 / 5x10 / 6x9 / 7x7 grids, preserved reward emblem scale, selection visibility, scrollbar geometry and 8 viewport sizes.")
	quit(0)
