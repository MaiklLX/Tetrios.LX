extends SceneTree

const SpecialPiece = preload("res://scripts/campaign_special_piece.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN SPECIAL PIECE TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var base := SpecialPiece.cells_for_rotation(0)
	if not _check(base.size() == 5 and SpecialPiece.BLOCK_COUNT == 5, "Cargo Hook must contain exactly five blocks"):
		return
	if not _check(SpecialPiece.PIECE_ID == "cargo_hook", "Prototype must have a stable campaign-only ID"):
		return

	var seen_rotations: Dictionary = {}
	for rotation in range(4):
		var cells := SpecialPiece.cells_for_rotation(rotation)
		if not _check(cells.size() == 5, "Every rotation must preserve all five blocks"):
			return
		if not _check(SpecialPiece.dimensions(cells).x <= 3 and SpecialPiece.dimensions(cells).y <= 3, "Every normalized rotation must fit inside a 3x3 box"):
			return
		var keys: Array[String] = []
		for cell in cells:
			keys.append("%d:%d" % [cell.x, cell.y])
		seen_rotations[",".join(keys)] = true
	if not _check(seen_rotations.size() == 4, "Asymmetric Cargo Hook must expose four distinct rotations"):
		return
	if not _check(SpecialPiece.cells_for_rotation(4) == base, "Rotation index must wrap deterministically"):
		return

	var spawn := SpecialPiece.centered_spawn_origin(10)
	if not _check(spawn == Vector2i(3, 0), "Base shape must spawn centered on the 10-column board"):
		return
	if not _check(SpecialPiece.fits(10, 23, spawn, base), "Clear spawn area must accept the piece"):
		return
	if not _check(not SpecialPiece.fits(10, 23, Vector2i(-1, 0), base), "Piece may not spawn beyond the left wall"):
		return
	if not _check(not SpecialPiece.fits(10, 23, Vector2i(3, 21), base), "Piece may not extend below the board"):
		return
	if not _check(not SpecialPiece.fits(10, 23, spawn, base, [spawn + base[0]]), "Occupied board cells must block placement"):
		return

	var centered_rotation := SpecialPiece.try_rotate(10, 23, spawn, 0)
	if not _check(centered_rotation.accepted and centered_rotation.rotation == 1, "Rotation must advance one quarter-turn"):
		return
	if not _check(centered_rotation.cells.size() == 5, "Successful rotation must retain five blocks"):
		return

	var wall_rotation := SpecialPiece.try_rotate(10, 23, Vector2i(8, 5), 0)
	if not _check(wall_rotation.accepted and wall_rotation.origin.x < 8, "Rotation near the right wall must use a horizontal wall kick"):
		return
	if not _check(SpecialPiece.fits(10, 23, wall_rotation.origin, wall_rotation.cells), "Wall-kicked rotation must remain inside the board"):
		return

	var blocked_rotation := SpecialPiece.try_rotate(10, 23, spawn, 0, [spawn + SpecialPiece.cells_for_rotation(1)[0], spawn + SpecialPiece.cells_for_rotation(1)[1], spawn + SpecialPiece.cells_for_rotation(1)[2], spawn + SpecialPiece.cells_for_rotation(1)[3], spawn + SpecialPiece.cells_for_rotation(1)[4]])
	if not _check(not blocked_rotation.accepted and blocked_rotation.rotation == 0 and blocked_rotation.origin == spawn, "Fully blocked rotation must leave the original pose unchanged"):
		return

	print("Campaign special piece prototype tests passed.")
	quit(0)
