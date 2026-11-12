class_name BlockBuddiesCampaignCollectionLayout
extends RefCounted

static func collection(viewport: Vector2) -> Dictionary:
	var width := maxf(1.0, viewport.x)
	var height := maxf(1.0, viewport.y)
	var compact := width <= 480.0
	var short_screen := height < 560.0
	var columns := 4 if width <= 320.0 else (5 if width <= 390.0 else (6 if compact else 7))
	var margin := 10.0 if width <= 360.0 else (13.0 if compact else 24.0)
	var gap := 4.0 if width <= 360.0 else 4.0
	var top := 130.0 if short_screen else 160.0
	var detail_height := 68.0 if short_screen else 78.0
	var detail_bottom_gap := 14.0 if short_screen else 21.0
	var detail_rect := Rect2(12.0, height - detail_bottom_gap - detail_height, maxf(1.0, width - 24.0), detail_height)
	var grid_viewport := Rect2(margin, top, maxf(1.0, width - margin * 2.0), maxf(1.0, detail_rect.position.y - top - 8.0))
	var cell_width := (width - margin * 2.0 - gap * float(columns - 1)) / float(columns)
	var cell_height := minf(56.0, cell_width * 0.9) if compact else minf(76.0, maxf(18.0, (grid_viewport.size.y - gap * 6.0) / 7.0))
	var inspect_width := minf(80.0, maxf(64.0, detail_rect.size.x * 0.27))
	var inspect_rect := Rect2(detail_rect.end.x - inspect_width - 8.0, detail_rect.position.y + (detail_height - 36.0) * 0.5, inspect_width, 36.0 if not short_screen else 32.0)
	var row_count := int(ceil(49.0 / float(columns)))
	var content_height := float(row_count) * cell_height + float(maxi(0, row_count - 1)) * gap
	var visible_rows := maxi(1, int(floor((grid_viewport.size.y + gap) / (cell_height + gap))))
	var max_scroll := float(maxi(0, row_count - visible_rows)) * (cell_height + gap)
	return {
		"compact": compact,
		"short_screen": short_screen,
		"columns": columns,
		"row_count": row_count,
		"visible_rows": visible_rows,
		"scrollable": max_scroll > 0.5,
		"grid_viewport_rect": grid_viewport,
		"content_height": content_height,
		"max_scroll": max_scroll,
		"margin": margin,
		"gap": gap,
		"top": top,
		"cell_width": cell_width,
		"cell_height": cell_height,
		"detail_rect": detail_rect,
		"inspect_rect": inspect_rect,
		"title_y": 70.0 if short_screen else 101.0,
		"subtitle_y": 94.0 if short_screen else 126.0,
		"legend_y": 115.0 if short_screen else 145.0,
		"footer_y": height - 8.0
	}


static func scroll_offset_for_index(layout: Dictionary, item_index: int, current_offset: float = 0.0) -> float:
	var columns := int(layout.get("columns", 0))
	var visible_rows := int(layout.get("visible_rows", 0))
	var row_step := float(layout.get("cell_height", 0.0)) + float(layout.get("gap", 0.0))
	if columns <= 0 or visible_rows <= 0 or row_step <= 0.0:
		return 0.0
	var target_row := maxi(0, item_index) / columns
	var first_visible_row := maxi(0, roundi(current_offset / row_step))
	if target_row < first_visible_row:
		first_visible_row = target_row
	elif target_row >= first_visible_row + visible_rows:
		first_visible_row = target_row - visible_rows + 1
	return clampf(float(first_visible_row) * row_step, 0.0, float(layout.get("max_scroll", 0.0)))

static func reward_modal(viewport: Vector2) -> Rect2:
	var width := minf(maxf(180.0, viewport.x - 24.0), 360.0)
	var height := minf(maxf(240.0, viewport.y - 32.0), 356.0)
	return Rect2((viewport - Vector2(width, height)) * 0.5, Vector2(width, height))


static func scrollbar(layout: Dictionary, scroll_offset: float) -> Dictionary:
	if not bool(layout.get("scrollable", false)):
		return {"track": Rect2(), "thumb": Rect2()}
	var grid: Rect2 = layout.get("grid_viewport_rect", Rect2())
	var row_count := maxi(1, int(layout.get("row_count", 1)))
	var visible_rows := clampi(int(layout.get("visible_rows", 1)), 1, row_count)
	var max_scroll := maxf(0.0, float(layout.get("max_scroll", 0.0)))
	var track := Rect2(grid.end.x + 3.0, grid.position.y + 2.0, 2.0, maxf(1.0, grid.size.y - 4.0))
	var thumb_height := minf(track.size.y, maxf(18.0, track.size.y * float(visible_rows) / float(row_count)))
	var progress := clampf(scroll_offset / max_scroll, 0.0, 1.0) if max_scroll > 0.0 else 0.0
	var thumb_y := track.position.y + (track.size.y - thumb_height) * progress
	return {"track": track, "thumb": Rect2(track.position.x - 0.5, thumb_y, 3.0, thumb_height)}

static func collection_strip(viewport: Vector2) -> Dictionary:
	var width := maxf(1.0, viewport.x)
	var height := maxf(1.0, viewport.y)
	var compact := width <= 480.0
	var short_screen := height < 560.0
	var top := 108.0 if short_screen else maxf(142.0, (height - 480.0) * 0.5)
	var margin := 10.0 if width <= 360.0 else 16.0
	var carousel_height := 150.0 if short_screen else 220.0
	var detail_height := 94.0 if short_screen else 154.0
	var gap := 12.0
	var grid := Rect2(margin, top, maxf(1.0, width - margin * 2.0), carousel_height)
	var detail := Rect2(12.0, grid.end.y + gap, maxf(1.0, width - 24.0), detail_height)
	var card_width := clampf(grid.size.x * 0.22, 82.0, 142.0)
	var card_height := maxf(80.0, carousel_height - 10.0)
	var content_width := 49.0 * card_width + 48.0 * gap
	var max_scroll := maxf(0.0, content_width - grid.size.x)
	var inspect_width := minf(76.0, maxf(62.0, detail.size.x * 0.22))
	var inspect_height := 34.0 if not short_screen else 30.0
	var inspect := Rect2(detail.end.x - inspect_width - 7.0, detail.position.y + (detail.size.y - inspect_height) * 0.5, inspect_width, inspect_height)
	return {
		"compact": compact,
		"short_screen": short_screen,
		"grid_viewport_rect": grid,
		"detail_rect": detail,
		"inspect_rect": inspect,
		"card_width": card_width,
		"card_height": card_height,
		"gap": gap,
		"content_width": content_width,
		"max_scroll": max_scroll,
		"title_y": top - 62.0,
		"subtitle_y": top - 38.0,
		"legend_y": top - 14.0,
		"footer_y": detail.end.y + 18.0
	}


static func scroll_offset_for_index_strip(layout: Dictionary, item_index: int, current_offset: float = 0.0) -> float:
	var grid: Rect2 = layout.get("grid_viewport_rect", Rect2())
	var card_width := float(layout.get("card_width", 0.0))
	var stride := card_width + float(layout.get("gap", 0.0))
	var max_scroll := float(layout.get("max_scroll", 0.0))
	if stride <= 0.0 or card_width <= 0.0 or grid.size.x <= 0.0:
		return 0.0
	var left := float(maxi(0, item_index)) * stride
	var right := left + card_width
	var offset := current_offset
	if left < offset:
		offset = left
	elif right > offset + grid.size.x:
		offset = right - grid.size.x
	return clampf(offset, 0.0, max_scroll)


static func scrollbar_strip(layout: Dictionary, scroll_offset: float) -> Dictionary:
	var grid: Rect2 = layout.get("grid_viewport_rect", Rect2())
	var max_scroll := float(layout.get("max_scroll", 0.0))
	var content_width := float(layout.get("content_width", 0.0))
	if max_scroll <= 0.5 or content_width <= 0.0 or grid.size.x <= 0.0:
		return {"track": Rect2(), "thumb": Rect2()}
	var track := Rect2(grid.position.x + 4.0, grid.end.y - 4.0, maxf(1.0, grid.size.x - 8.0), 2.0)
	var thumb_width := minf(track.size.x, maxf(24.0, track.size.x * grid.size.x / content_width))
	var progress := clampf(scroll_offset / max_scroll, 0.0, 1.0)
	var thumb_x := track.position.x + (track.size.x - thumb_width) * progress
	return {"track": track, "thumb": Rect2(thumb_x, track.position.y - 0.5, thumb_width, 3.0)}

