class_name BlockBuddiesCampaignCollection
extends RefCounted

const Campaign = preload("res://scripts/campaign_progress.gd")

const UNIVERSE_RELIC_TITLES := [
	"Сердце равнин", "Компас каравана", "Искра пепельного солнца", "Осколок ледяной короны",
	"Лунный архив", "Перо экспедиции", "Песочные часы", "Ключ междумирья",
	"Звёздный фрагмент", "Ядро станции", "Осколок разлома", "Знак дальнего рубежа"
]

const UNIVERSE_RELIC_DESCRIPTIONS := [
	"Память о покорении Зелёных равнин.",
	"Знак доверия звёздного каравана.",
	"Трофей за покорение Огненных земель.",
	"Холодный знак выдержки и мастерства.",
	"Свидетельство освоения лунной колонии.",
	"Память о смелости дальней экспедиции.",
	"Реликвия тех, кто не потерял путь во времени.",
	"Ключ, открывающий дорогу между мирами.",
	"Фрагмент небесного архипелага.",
	"Знак победы над испытаниями станции.",
	"Осколок, вынесенный из космического разлома.",
	"Последняя печать на пути к дальнему рубежу."
]

static func get_collection_summary(progress: BlockBuddiesCampaignProgress) -> Dictionary:
	if progress == null:
		return {"unlocked_count": 0, "total_count": 49, "items": []}
	var items: Array[Dictionary] = []
	var unlocked_count := 0
	for universe_index in range(Campaign.UNIVERSE_COUNT):
		var universe_progress: Dictionary = progress.get_universe_progress(universe_index)
		var unlocked := bool(universe_progress.get("completed", false))
		if unlocked:
			unlocked_count += 1
		items.append({
			"id": "universe_relic_%02d" % (universe_index + 1),
			"kind": "universe_relic",
			"universe_number": universe_index + 1,
			"visual_variant": universe_index + 1,
			"title": UNIVERSE_RELIC_TITLES[universe_index],
			"description": UNIVERSE_RELIC_DESCRIPTIONS[universe_index],
			"unlock_planet": (universe_index + 1) * Campaign.PLANETS_PER_UNIVERSE,
			"unlocked": unlocked
		})
		for boss_step in [10, 20, 30]:
			var boss_node: int = universe_index * Campaign.PLANETS_PER_UNIVERSE + int(boss_step)
			var boss_definition: Dictionary = progress.get_planet_definition(boss_node)
			var boss_unlocked := progress.is_completed(boss_node)
			if boss_unlocked:
				unlocked_count += 1
			items.append({
				"id": "boss_insignia_%03d" % boss_node,
				"kind": "boss_insignia",
				"universe_number": universe_index + 1,
				"planet_id": boss_node,
				"visual_variant": boss_node,
				"title": str(boss_definition.get("boss_name", "Знак командира")),
				"description": "Знак за победу над командиром на планете %03d." % boss_node,
				"unlock_planet": boss_node,
				"unlocked": boss_unlocked
			})
	var campaign_crown_unlocked := progress.campaign_complete
	if campaign_crown_unlocked:
		unlocked_count += 1
	items.append({
		"id": "campaign_crown",
		"kind": "campaign_crown",
		"title": "Корона дальнего пути",
		"description": "Главная реликвия за завершение всех 360 планет.",
		"unlock_planet": Campaign.TOTAL_PLANETS,
		"visual_variant": 0,
		"unlocked": campaign_crown_unlocked
	})
	return {
		"unlocked_count": unlocked_count,
		"total_count": items.size(),
		"completion_ratio": float(unlocked_count) / float(items.size()),
		"items": items
	}

static func get_item(progress: BlockBuddiesCampaignProgress, item_id: String) -> Dictionary:
	var summary := get_collection_summary(progress)
	for item in summary.items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}
