extends SceneTree

const Mechanics = preload("res://scripts/campaign_mechanics.gd")
const Campaign = preload("res://scripts/campaign_progress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN MECHANICS TEST FAILED: " + message)
	quit(1)
	return false

func _run() -> void:
	if not _check(Mechanics.UNIVERSE_MECHANICS.size() == 12, "All twelve universes must define a distinct mechanic family"):
		return
	if not _check(Mechanics.get_universe_mechanic(1).family == "special_pieces", "Universe two must introduce the special-piece family"):
		return
	if not _check(Mechanics.get_universe_mechanic(-1).is_empty() and Mechanics.get_universe_mechanic(12).is_empty(), "Invalid universe indexes must be rejected"):
		return
	if not _check(Mechanics.validate_modifier_set(["accelerated_gravity"]).valid, "An ordinary planet may carry one modifier"):
		return
	if not _check(not Mechanics.validate_modifier_set(["accelerated_gravity","ability_cooldown"]).valid, "Ordinary planets must never stack modifiers"):
		return
	if not _check(Mechanics.validate_modifier_set(["accelerated_gravity","ability_cooldown"], true).valid, "Bosses may use explicitly compatible pairs"):
		return
	if not _check(not Mechanics.validate_modifier_set(["accelerated_gravity","rotation_limit"], true).valid, "Bosses must reject incompatible combinations"):
		return
	if not _check(not Mechanics.validate_modifier_set(["hazard_cells","hazard_cells"], true).valid, "Duplicate modifiers must be rejected"):
		return
	if not _check(not Mechanics.validate_modifier_set(["unknown_effect"]).valid, "Unknown modifier IDs must be rejected"):
		return
	var campaign := Campaign.new()
	var first := Mechanics.get_planet_mechanics(campaign.get_planet_definition(1))
	var second_universe_intro := Mechanics.get_planet_mechanics(campaign.get_planet_definition(31))
	var second_universe_modifier := Mechanics.get_planet_mechanics(campaign.get_planet_definition(38))
	var second_universe_boss := Mechanics.get_planet_mechanics(campaign.get_planet_definition(40))
	var final_universe_boss := Mechanics.get_planet_mechanics(campaign.get_planet_definition(360))
	if not _check(first.universe_mechanic.id == "frontier_basics" and first.modifier_ids.is_empty(), "Opening universe must remain a clean learning environment"):
		return
	if not _check(second_universe_intro.universe_mechanic.id == "star_cargo", "Universe two must expose its own mechanic identity"):
		return
	if not _check(second_universe_modifier.modifier_ids.size() == 1 and second_universe_modifier.preview_required, "Ordinary campaign modifier must be assigned deterministically and previewed"):
		return
	if not _check(second_universe_boss.modifier_ids.size() == 2 and second_universe_boss.modifier_validation.valid, "Boss modifier pair must be explicitly compatible"):
		return
	if not _check(final_universe_boss.modifier_ids.size() == 2 and final_universe_boss.modifier_validation.valid, "Final universe boss may combine only a validated pair"):
		return
	if not _check(not second_universe_boss.mechanics_live, "KT-531 registry must not silently alter live gameplay before effect integration"):
		return
	print("Campaign mechanics registry tests passed.")
	quit(0)
