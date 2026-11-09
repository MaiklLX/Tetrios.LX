class_name BlockBuddiesCampaignCollectionLayout
extends RefCounted

static func collection(viewport: Vector2) -> Dictionary:
	var width := maxf(1.0, viewport.x)
	var height := maxf(1.0, viewport.y)
	var compact := width <= 480.0
	var short_screen := height < 560.0
	var columns := 5 if width <= 360.0 else (6 if compact else 7)
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
	var max_scroll := maxf(0.0, content_height - grid_viewport.size.y)
	var visible_rows := maxi(1, int(floor((grid_viewport.size.y + gap) / (cell_height + gap))))
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

static func reward_modal(viewport: Vector2) -> Rect2:
	var width := minf(maxf(180.0, viewport.x - 24.0), 360.0)
	var height := minf(maxf(240.0, viewport.y - 32.0), 356.0)
	return Rect2((viewport - Vector2(width, height)) * 0.5, Vector2(width, height))
