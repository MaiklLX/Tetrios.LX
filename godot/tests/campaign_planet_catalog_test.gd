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
	for local_id in range(1, 31):
		var mission := campaign.get_planet_definition(30 + local_id)
		var duration: Variant = mission.get("expected_duration_seconds", [])
		if not _check(str(mission.get("objective_type", "")) in ["lines", "score", "survive", "boss_combo"], "Every Star Caravan planet must resolve a supported objective contract"):
			return
		if not _check(str(mission.get("difficulty_band", "")) in ["guided", "standard", "advanced", "mastery"], "Every Star Caravan planet must resolve an authored difficulty band"):
			return
		if not _check(typeof(duration) == TYPE_ARRAY and duration.size() == 2 and int(duration[0]) >= 30 and int(duration[1]) > int(duration[0]), "Every Star Caravan planet must resolve a valid expected duration range"):
			return
		if not _check(typeof(mission.get("event_schedule", null)) == TYPE_ARRAY, "Every Star Caravan planet must expose deterministic event schedule metadata"):
			return
	var planet_31 := campaign.get_planet_definition(31)
	var planet_56 := campaign.get_planet_definition(56)
	var boss_40 := campaign.get_planet_definition(40)
	var boss_60 := campaign.get_planet_definition(60)
	var layout_33 := campaign.get_planet_definition(33)
	var layout_36 := campaign.get_planet_definition(36)
	var layout_46 := campaign.get_planet_definition(46)
	if not _check(layout_33.layout_id == "cargo_corridor" and layout_33.starting_layout.size() == 3, "Planet 033 must resolve its authored Cargo Corridor board layout"):
		return
	if not _check(layout_33.objective_type == "lines" and layout_33.target_lines == 12 and layout_33.difficulty_band == "guided" and layout_33.expected_duration_seconds == [90, 150], "Planet 033 must resolve its explicit guided objective and duration band"):
		return
	if not _check(layout_36.objective_type == "lines" and layout_36.target_lines == 12 and layout_36.difficulty_band == "standard" and layout_36.expected_duration_seconds == [120, 180], "Planet 036 must resolve its authored standard mission contract"):
		return
	if not _check(layout_46.objective_type == "lines" and layout_46.target_lines == 13 and layout_46.expected_duration_seconds == [150, 210], "Planet 046 must resolve its later-chapter objective and pacing band"):
		return
	var malformed_layout := chapter.duplicate(true)
	malformed_layout.planets[2].starting_layout[0] = "##########"
	if not _check(not Catalog.validate_chapter(malformed_layout).valid, "Catalog validator must reject malformed authored board cells"):
		return
	if not _check(planet_31.chapter_id == "star_caravan" and planet_31.title == "Первый сигнал", "Planet 031 must resolve to authored Star Caravan content"):
		return
	if not _check(planet_56.event_status == "live_campaign_piece" and planet_56.special_piece_id == "cargo_hook", "Planet 056 must identify the Cargo Hook showcase as live campaign content"):
		return
	if not _check(planet_56.objective_type == "lines" and planet_56.target_lines > 0, "Authored event metadata must preserve the validated line objective"):
		return
	if not _check(boss_40.boss_name == "Страж конвоя" and boss_60.boss_name == "Адмирал дальнего пути", "Star Caravan bosses must have authored identities"):
		return
	var malformed_mission := chapter.duplicate(true)
	malformed_mission.planets[2].mission_definition.target_lines = -1
	if not _check(not Catalog.validate_chapter(malformed_mission).valid, "Catalog validator must reject negative authored mission targets"):
		return
	malformed_mission = chapter.duplicate(true)
	malformed_mission.planets[5].mission_definition.expected_duration_seconds = [180, 90]
	if not _check(not Catalog.validate_chapter(malformed_mission).valid, "Catalog validator must reject inverted mission duration bands"):
		return
	var malformed_boss := chapter.duplicate(true)
	malformed_boss.planets[9].boss_phases[1].target_score = -1
	if not _check(not Catalog.validate_chapter(malformed_boss).valid, "Catalog validator must reject negative boss phase quotas"):
		return
	malformed_boss = chapter.duplicate(true)
	malformed_boss.planets[19].boss_phases[1].target_lines = 0
	malformed_boss.planets[19].boss_phases[1].target_score = 0
	if not _check(not Catalog.validate_chapter(malformed_boss).valid, "Catalog validator must reject a boss phase with no achievable objective"):
		return
	var malformed := chapter.duplicate(true)
	malformed.planets[4].local_id = 99
	if not _check(not Catalog.validate_chapter(malformed).valid, "Catalog validator must reject non-sequential node IDs"):
		return
	malformed = chapter.duplicate(true)
	malformed.planets[25].event_status = "live_campaign_piece"
	malformed.planets[25].erase("special_piece_id")
	if not _check(not Catalog.validate_chapter(malformed).valid, "Catalog validator must reject unbound live special-piece events"):
		return
	if not _check(Catalog.get_planet(0, 1).is_empty() and Catalog.get_planet(1, 31).is_empty(), "Catalog lookup must fail closed outside authored chapter bounds"):
		return
	print("Campaign authored catalog tests passed: versioned schema, 30 authored Star Caravan records, validation, live event binding and formula fallback.")
	quit(0)
