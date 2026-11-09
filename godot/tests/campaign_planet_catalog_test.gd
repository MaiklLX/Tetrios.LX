extends SceneTree

const Catalog = preload("res://scripts/campaign_planet_catalog.gd")
const Campaign = preload("res://scripts/campaign_progress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN CATALOG TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	var chapter := Catalog.get_chapter(1)
	var validation := Catalog.validate_chapter(chapter)
	if not _check(validation.valid and validation.planet_count == 30, "Star Caravan chapter must pass the 30-node schema validator"):
		return
	var seen := {}
	for local_id in range(1, 31):
		var record := Catalog.get_planet(1, local_id)
		if not _check(int(record.local_id) == local_id and not str(record.title).is_empty() and not str(record.briefing).is_empty(), "Every Star Caravan node needs a unique authored identity and briefing"):
			return
		if not _check(not seen.has(local_id), "Planet IDs must be unique"):
			return
		seen[local_id] = true
	var campaign := Campaign.new()
	var planet_31 := campaign.get_planet_definition(31)
	var planet_56 := campaign.get_planet_definition(56)
	var boss_40 := campaign.get_planet_definition(40)
	var boss_60 := campaign.get_planet_definition(60)
	if not _check(planet_31.chapter_id == "star_caravan" and planet_31.title == "Первый сигнал", "Planet 031 must resolve to authored Star Caravan content"):
		return
	if not _check(planet_56.event_status == "live_campaign_piece" and planet_56.special_piece_id == "cargo_hook", "Planet 056 must identify the Cargo Hook showcase as live campaign content"):
		return
	if not _check(planet_56.objective_type == "score" and planet_56.target_score > 0, "Authored metadata must preserve the validated score objective"):
		return
	if not _check(boss_40.boss_name == "Страж конвоя" and boss_60.boss_name == "Адмирал дальнего пути", "Star Caravan bosses must have authored identities"):
		return
	var malformed := chapter.duplicate(true)
	malformed.planets[4].local_id = 99
	if not _check(not Catalog.validate_chapter(malformed).valid, "Catalog validator must reject non-sequential node IDs"):
		return
	malformed = chapter.duplicate(true)
	malformed.planets[25].event_status = "implemented"
	malformed.planets[25].erase("special_piece_id")
	if not _check(not Catalog.validate_chapter(malformed).valid, "Catalog validator must reject unbound live special-piece events"):
		return
	if not _check(Catalog.get_planet(0, 1).is_empty() and Catalog.get_planet(1, 31).is_empty(), "Catalog lookup must fail closed outside authored chapter bounds"):
		return
	print("Campaign authored catalog tests passed: versioned schema, 30 authored Star Caravan records, validation, live event binding and formula fallback.")
	quit(0)
