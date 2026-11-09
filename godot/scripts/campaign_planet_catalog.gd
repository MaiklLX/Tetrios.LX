class_name BlockBuddiesCampaignPlanetCatalog
extends RefCounted

# KT-543.1 — versioned authored chapter data. Runtime effects are opt-in and
# must be implemented separately before an event_id is allowed to mutate play.
const SCHEMA_VERSION := 1
const STAR_CARAVAN_UNIVERSE := 1

const CHAPTERS := {
	STAR_CARAVAN_UNIVERSE: {
		"schema_version": SCHEMA_VERSION,
		"universe_index": STAR_CARAVAN_UNIVERSE,
		"chapter_id": "star_caravan",
		"chapter_title": "Караван звёзд",
		"signature_mechanic": "cargo_hook",
		"content_status": "authored_foundation",
		"planets": [
			{"local_id":1,"title":"Первый сигнал","briefing":"Караван выходит на маршрут. Освой поле и найди спокойный ритм укладки.","mission_tag":"intro","event_id":"","event_status":"none"},
			{"local_id":2,"title":"Первые контейнеры","briefing":"Собери линии без спешки: грузовой путь начинается с точности.","mission_tag":"practice","event_id":"","event_status":"none"},
			{"local_id":3,"title":"Чистый коридор","briefing":"Освободи пространство для следующей партии фигур.","mission_tag":"precision","event_id":"","event_status":"none"},
			{"local_id":4,"title":"Дежурство на борту","briefing":"Удерживай поле в рабочем состоянии, пока караван проходит опасный сектор.","mission_tag":"survival","event_id":"","event_status":"none"},
			{"local_id":5,"title":"Оплата за доставку","briefing":"Набери нужное количество очков за аккуратные очистки.","mission_tag":"score","event_id":"","event_status":"none"},
			{"local_id":6,"title":"Узкий пролёт","briefing":"Планируй укладку заранее: свободное место скоро понадобится.","mission_tag":"precision","event_id":"","event_status":"none"},
			{"local_id":7,"title":"Поток грузов","briefing":"Сохраняй темп и не заполняй верхние ряды.","mission_tag":"flow","event_id":"","event_status":"none"},
			{"local_id":8,"title":"Маршрутный маяк","briefing":"Проверь стабильность укладки перед входом в сектор каравана.","mission_tag":"setup","event_id":"","event_status":"none"},
			{"local_id":9,"title":"Проверка экипажа","briefing":"Последняя тренировка перед встречей с первым стражем маршрута.","mission_tag":"mastery","event_id":"","event_status":"none"},
			{"local_id":10,"title":"Страж конвоя","briefing":"Страж проверяет и объём очистки, и качество набранных очков.","mission_tag":"boss_guardian","event_id":"convoy_guardian","event_status":"briefing_only","boss_name":"Страж конвоя","boss_phase":"single"},
			{"local_id":11,"title":"После тревоги","briefing":"Караван продолжает путь. Верни полю безопасную форму.","mission_tag":"recovery","event_id":"","event_status":"none"},
			{"local_id":12,"title":"Смена построения","briefing":"Чередуй формы и оставляй место для длинных комбинаций.","mission_tag":"practice","event_id":"","event_status":"none"},
			{"local_id":13,"title":"Точный расчёт","briefing":"Каждая очистка важна: не трать пространство впустую.","mission_tag":"precision","event_id":"","event_status":"none"},
			{"local_id":14,"title":"Тихая вахта","briefing":"Продержись до конца опасного участка маршрута.","mission_tag":"survival","event_id":"","event_status":"none"},
			{"local_id":15,"title":"Премия навигатора","briefing":"Докажи мастерство результатом, а не только количеством линий.","mission_tag":"score","event_id":"","event_status":"none"},
			{"local_id":16,"title":"Сложный стык","briefing":"Собирай линии так, чтобы не запирать будущие фигуры.","mission_tag":"precision","event_id":"","event_status":"none"},
			{"local_id":17,"title":"Резервный отсек","briefing":"Подготовь свободный объём поля для неожиданного груза.","mission_tag":"setup","event_id":"","event_status":"none"},
			{"local_id":18,"title":"Тяговый импульс","briefing":"Проверь устойчивость темпа на длинной серии очисток.","mission_tag":"tempo","event_id":"","event_status":"none"},
			{"local_id":19,"title":"Передача смены","briefing":"Сохрани контроль над полем перед испытанием чемпиона.","mission_tag":"mastery","event_id":"","event_status":"none"},
			{"local_id":20,"title":"Чемпион каравана","briefing":"Чемпион требует выдержки: выполни обе части задания без гонки со временем.","mission_tag":"boss_champion","event_id":"caravan_champion","event_status":"briefing_only","boss_name":"Чемпион каравана","boss_phase":"single"},
			{"local_id":21,"title":"Новый сектор","briefing":"После победы маршрут меняется. Освой новый ритм укладки.","mission_tag":"recovery","event_id":"","event_status":"none"},
			{"local_id":22,"title":"Грузовой баланс","briefing":"Сочетай безопасную высоту поля с эффективными очистками.","mission_tag":"efficiency","event_id":"","event_status":"none"},
			{"local_id":23,"title":"Длинная связка","briefing":"Строй последовательности очисток, не теряя контроля над верхом поля.","mission_tag":"combo","event_id":"","event_status":"none"},
			{"local_id":24,"title":"Красная вахта","briefing":"Переживи заключительный участок перед особой доставкой.","mission_tag":"survival","event_id":"","event_status":"none"},
			{"local_id":25,"title":"Контракт на скорость мысли","briefing":"Набери целевой результат точными решениями и чистым полем.","mission_tag":"score","event_id":"","event_status":"none"},
			{"local_id":26,"title":"Особая доставка","briefing":"Грузовой крюк возвращается в маршрут как ключевой элемент кампании.","mission_tag":"special_piece","event_id":"cargo_hook_showcase","event_status":"live_campaign_piece","special_piece_id":"cargo_hook"},
			{"local_id":27,"title":"Манёвр сцепки","briefing":"Подготовь место и используй нестандартную геометрию с умом.","mission_tag":"special_piece_mastery","event_id":"cargo_hook_mastery","event_status":"live_campaign_piece","special_piece_id":"cargo_hook"},
			{"local_id":28,"title":"Сборка конвоя","briefing":"Сочетай обычные фигуры и подготовку к особой доставке.","mission_tag":"setup","event_id":"","event_status":"none"},
			{"local_id":29,"title":"Последний сигнал","briefing":"Перед финалом маршрута проверь каждое решение и оставь запас пространства.","mission_tag":"mastery","event_id":"","event_status":"none"},
			{"local_id":30,"title":"Адмирал дальнего пути","briefing":"Финальный командир каравана проверяет весь накопленный опыт главы.","mission_tag":"boss_final","event_id":"caravan_admiral","event_status":"briefing_only","boss_name":"Адмирал дальнего пути","boss_phase":"single"}
		]
	}
}

static func get_chapter(universe_index: int) -> Dictionary:
	if not CHAPTERS.has(universe_index):
		return {}
	return CHAPTERS[universe_index].duplicate(true)

static func get_planet(universe_index: int, local_id: int) -> Dictionary:
	var chapter := get_chapter(universe_index)
	if chapter.is_empty() or local_id < 1 or local_id > chapter.planets.size():
		return {}
	return chapter.planets[local_id - 1].duplicate(true)

static func validate_chapter(chapter: Dictionary) -> Dictionary:
	if int(chapter.get("schema_version", -1)) != SCHEMA_VERSION:
		return {"valid":false,"reason":"unsupported_schema"}
	if int(chapter.get("universe_index", -1)) < 0 or str(chapter.get("chapter_id", "")).is_empty():
		return {"valid":false,"reason":"invalid_chapter_identity"}
	var planets: Variant = chapter.get("planets")
	if typeof(planets) != TYPE_ARRAY or planets.size() != 30:
		return {"valid":false,"reason":"chapter_must_have_30_planets"}
	for index in range(planets.size()):
		var planet: Variant = planets[index]
		if typeof(planet) != TYPE_DICTIONARY:
			return {"valid":false,"reason":"invalid_planet_record","local_id":index + 1}
		if int(planet.get("local_id", -1)) != index + 1:
			return {"valid":false,"reason":"non_sequential_planet_id","local_id":index + 1}
		for required_key in ["title", "briefing", "mission_tag", "event_status"]:
			if str(planet.get(required_key, "")).strip_edges().is_empty():
				return {"valid":false,"reason":"missing_"+required_key,"local_id":index + 1}
		var event_status := str(planet.event_status)
		if event_status != "none" and str(planet.get("event_id", "")).strip_edges().is_empty():
			return {"valid":false,"reason":"missing_event_id","local_id":index + 1}
		if not ["none", "briefing_only", "live_campaign_piece", "implemented"].has(event_status):
			return {"valid":false,"reason":"unknown_event_status","local_id":index + 1}
		if event_status == "live_campaign_piece" and str(planet.get("special_piece_id", "")) != "cargo_hook":
			return {"valid":false,"reason":"unbound_live_event","local_id":index + 1}
		var boss := index + 1 in [10, 20, 30]
		if boss != planet.has("boss_name"):
			return {"valid":false,"reason":"boss_metadata_mismatch","local_id":index + 1}
	return {"valid":true,"reason":"ok","planet_count":planets.size()}
