class_name BlockBuddiesCampaignMechanics
extends RefCounted

# KT-531: data-only campaign mechanics registry.
# This layer assigns and validates authored rules; it never mutates the live board.

const UNIVERSE_MECHANICS := [
	{"id":"frontier_basics","name":"Освоение поля","intro":"Базовые правила, первые безопасные препятствия и обучение тактике.","family":"foundation","planned":false},
	{"id":"star_cargo","name":"Особые фигуры","intro":"Грузовые и составные фигуры меняют привычные способы укладки.","family":"special_pieces","planned":true},
	{"id":"thermal_zones","name":"Термические зоны","intro":"Опасные клетки и временные зоны давления меняют приоритеты очистки.","family":"hazards","planned":true},
	{"id":"frozen_cells","name":"Ледяные клетки","intro":"Замороженные клетки и скользящие элементы меняют контроль над полем.","family":"board_states","planned":true},
	{"id":"moon_construction","name":"Лунные конструкции","intro":"Стационарные блоки и узкие проходы требуют планировать укладку заранее.","family":"obstacles","planned":true},
	{"id":"wind_vectors","name":"Ветровые потоки","intro":"Потоки среды влияют на движение отдельных фигур по понятным правилам.","family":"piece_motion","planned":true},
	{"id":"time_sands","name":"Пески времени","intro":"Временные окна и темповые испытания проверяют точность решений.","family":"tempo","planned":true},
	{"id":"rift_portals","name":"Межмировые порталы","intro":"Порталы связывают участки поля и открывают необычные комбинации.","family":"board_links","planned":true},
	{"id":"sky_islands","name":"Островные поля","intro":"Разделённые зоны и нестандартная геометрия меняют привычные маршруты.","family":"board_geometry","planned":true},
	{"id":"drone_pressure","name":"Динамические дроны","intro":"Дроны создают предсказуемые подвижные препятствия и окна возможностей.","family":"dynamic_obstacles","planned":true},
	{"id":"cosmic_synthesis","name":"Синтез механик","intro":"Комбинации ранее освоенных правил проверяют мастерство игрока.","family":"combined","planned":true},
	{"id":"far_frontier","name":"Финальное испытание","intro":"Финальная проверка всех освоенных навыков без случайной нечестной сложности.","family":"mastery","planned":true}
]

# Daily-style modifiers are candidate definitions, not claims about the legacy
# Daily Challenge catalog. Source parity is audited before any live integration.
const MODIFIERS := {
	"accelerated_gravity":{"id":"accelerated_gravity","name":"Ускоренное падение","description":"Фигуры опускаются быстрее обычного.","family":"tempo","risk":1,"daily_candidate":true},
	"rotation_limit":{"id":"rotation_limit","name":"Ограничение поворотов","description":"На фигуру доступно ограниченное число поворотов.","family":"input","risk":2,"daily_candidate":true},
	"clear_surge":{"id":"clear_surge","name":"Импульс после очистки","description":"После очистки линий темп временно возрастает.","family":"tempo","risk":1,"daily_candidate":true},
	"hazard_cells":{"id":"hazard_cells","name":"Опасные клетки","description":"На поле присутствуют заранее показанные опасные клетки.","family":"hazards","risk":2,"daily_candidate":true},
	"unstable_layout":{"id":"unstable_layout","name":"Нестабильная конфигурация","description":"Стартовая конфигурация поля содержит особые препятствия.","family":"obstacles","risk":2,"daily_candidate":true},
	"ability_cooldown":{"id":"ability_cooldown","name":"Перезарядка умения","description":"Умение персонажа доступно реже обычного.","family":"hero","risk":1,"daily_candidate":true}
}

const COMPATIBLE_PAIRS := [
	["accelerated_gravity","ability_cooldown"],
	["clear_surge","rotation_limit"],
	["hazard_cells","ability_cooldown"]
]

static func get_universe_mechanic(universe_index: int) -> Dictionary:
	if universe_index < 0 or universe_index >= UNIVERSE_MECHANICS.size():
		return {}
	return UNIVERSE_MECHANICS[universe_index].duplicate(true)

static func get_modifier(modifier_id: String) -> Dictionary:
	if not MODIFIERS.has(modifier_id):
		return {}
	return MODIFIERS[modifier_id].duplicate(true)

static func are_compatible(first_id: String, second_id: String) -> bool:
	if first_id == second_id or not MODIFIERS.has(first_id) or not MODIFIERS.has(second_id):
		return false
	for pair in COMPATIBLE_PAIRS:
		if (pair[0] == first_id and pair[1] == second_id) or (pair[1] == first_id and pair[0] == second_id):
			return true
	return false

static func validate_modifier_set(modifier_ids: Array, is_boss: bool = false) -> Dictionary:
	var maximum := 2 if is_boss else 1
	if modifier_ids.size() > maximum:
		return {"valid":false,"reason":"modifier_limit_exceeded","maximum":maximum}
	var seen := {}
	for modifier_id in modifier_ids:
		if typeof(modifier_id) != TYPE_STRING or not MODIFIERS.has(modifier_id):
			return {"valid":false,"reason":"unknown_modifier"}
		if seen.has(modifier_id):
			return {"valid":false,"reason":"duplicate_modifier"}
		seen[modifier_id] = true
	if modifier_ids.size() == 2 and not are_compatible(str(modifier_ids[0]), str(modifier_ids[1])):
		return {"valid":false,"reason":"incompatible_modifiers"}
	return {"valid":true,"reason":"ok","maximum":maximum}

static func get_planet_mechanics(planet_definition: Dictionary) -> Dictionary:
	if planet_definition.is_empty():
		return {}
	var universe_index := int(planet_definition.get("universe_index", -1))
	var planet_number := int(planet_definition.get("planet_in_universe", 0))
	var is_boss := bool(planet_definition.get("is_boss", false))
	var world := get_universe_mechanic(universe_index)
	if world.is_empty() or planet_number < 1 or planet_number > 30:
		return {}
	var assigned: Array[String] = []
	# Ordinary planets get at most one optional modifier. Bosses can combine
	# two only through an explicit compatibility pair. The first universe is
	# kept introductory and modifier-free.
	if universe_index > 0:
		if is_boss:
			if planet_number == 10:
				assigned = ["accelerated_gravity","ability_cooldown"]
			elif planet_number == 20:
				assigned = ["clear_surge","rotation_limit"]
			elif planet_number == 30 and universe_index >= 9:
				assigned = ["hazard_cells","ability_cooldown"]
		elif planet_number in [8, 18, 28]:
			var cycle := (universe_index + int((planet_number - 8) / 10)) % 6
			var ids := ["accelerated_gravity","rotation_limit","clear_surge","hazard_cells","unstable_layout","ability_cooldown"]
			assigned = [ids[cycle]]
	var validation := validate_modifier_set(assigned, is_boss)
	var previews: Array[Dictionary] = []
	for modifier_id in assigned:
		previews.append(get_modifier(modifier_id))
	return {
		"universe_mechanic":world,
		"modifier_ids":assigned,
		"modifiers":previews,
		"modifier_limit":2 if is_boss else 1,
		"modifier_validation":validation,
		"mechanics_live":false,
		"preview_required":not assigned.is_empty()
	}
