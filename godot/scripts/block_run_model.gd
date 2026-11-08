class_name BlockBuddiesBlockRunModel
extends RefCounted

# Source-grounded Block Run rules from site/index.html at main@38c61b606187b88ce8a48a1c6b71d264aecf4258.
# This model is deliberately independent of the Classic/Sprint/Marathon board model.
const MAX_CARD_RANK := 5
const CARD_DEFINITIONS: Array[Dictionary] = [
	{"id":"score","icon":"✦","name":"Ядро комбо","description":"За каждую линию подряд +15% очков.","effect":"score"},
	{"id":"shield","icon":"◈","name":"Квантовый щит","description":"Один раз спасает от проигрыша.","effect":"shield"},
	{"id":"mult","icon":"⚡","name":"Ускоритель мысли","description":"Падение деталей быстрее, очки ×1.5.","effect":"mult"},
	{"id":"slow","icon":"⟲","name":"Хроно-импульс","description":"Замедляет падение на 20%.","effect":"slow"},
	{"id":"resonance","icon":"✧","name":"Резонанс","description":"Каждая 4-я очищенная линия добавляет заряд уровня.","effect":"resonance"},
	{"id":"magnet","icon":"⬡","name":"Магнит линий","description":"За двойную очистку +250 очков.","effect":"magnet"},
	{"id":"glow","icon":"☼","name":"Солнечный заряд","description":"Мягкое свечение деталей даёт бонус +10%.","effect":"glow"},
	{"id":"echo","icon":"◉","name":"Эхо пустоты","description":"Каждая пятая линия добавляет заряд уровня.","effect":"echo"},
	{"id":"unstable","icon":"⌁","name":"Нестабильный блок","description":"Каждые 90 секунд +500 очков.","effect":"unstable"},
	{"id":"dust","icon":"✹","name":"Звёздная пыль","description":"За одиночную линию +100 очков.","effect":"dust"},
	{"id":"armor","icon":"⛨","name":"Обшивка титана","description":"Усиливает щит и добавляет заряд спасения.","effect":"armor"},
	{"id":"burst","icon":"↯","name":"Двойной разряд","description":"При очистке 3+ линий наносит монстру дополнительный урон и даёт +600 очков.","effect":"burst"},
	{"id":"prism","icon":"♢","name":"Призма цвета","description":"Новые детали переливаются разными оттенками.","effect":"prism"},
	{"id":"memory","icon":"⌬","name":"Кристалл памяти","description":"Порог следующего уровня растёт медленнее.","effect":"memory"},
	{"id":"hold","icon":"◌","name":"Грави-якорь","description":"Удержание детали доступно дважды.","effect":"hold","base_rank":2},
	{"id":"reactor","icon":"✺","name":"Реактор","description":"Каждые 10 линий +1 уровень бонусом.","effect":"reactor"},
	{"id":"comet","icon":"☄","name":"Кометный след","description":"За быстрый уровень +300 очков.","effect":"comet"},
	{"id":"rift","icon":"⟁","name":"Разлом","description":"После победы над монстром очищает нижний ряд.","effect":"rift"},
	{"id":"stable","icon":"⊹","name":"Стабилизатор","description":"Поворот деталей становится точнее.","effect":"stable"},
	{"id":"luck","icon":"❖","name":"Артефакт удачи","description":"Редкие детали приносят +20% очков.","effect":"luck"},
	{"id":"void","icon":"◍","name":"Тихая сингулярность","description":"Раз в уровень сжимает один полностью пустой ряд между блоками, не теряя детали.","effect":"void"},
	{"id":"gear","icon":"⚙","name":"Механизм повторения","description":"Каждый 5-й ход даёт +25 очков.","effect":"gear"},
	{"id":"flash","icon":"✴","name":"Фотонный клинок","description":"Очистка 2+ линий добавляет эффект вспышки.","effect":"flash"},
	{"id":"neuron","icon":"⌘","name":"Нейронный импульс","description":"Первые 30 секунд уровня очки ×1.25.","effect":"neuron"},
	{"id":"infinity","icon":"⟡","name":"Код бесконечности","description":"За каждую 10-ю линию +1 реликвия.","effect":"infinity"},
	{"id":"tide","icon":"⦿","name":"Лунный прилив","description":"Каждые 45 секунд +1 заряд уровня.","effect":"tide"},
	{"id":"fortress","icon":"♜","name":"Крепость данных","description":"Уменьшает скорость роста сложности.","effect":"fortress"},
	{"id":"shift","icon":"✣","name":"Сдвиг измерений","description":"Успешный поворот с шансом 25% даёт +25 очков; в Block Run бонус растёт с рангом.","effect":"shift"},
	{"id":"reserve","icon":"☷","name":"Энергетический запас","description":"Поглощает одну атаку монстра без мусорного ряда.","effect":"reserve"},
	{"id":"nova","icon":"✵","name":"Сверхновая","description":"При проигрыше один раз очищает нижнюю линию.","effect":"nova"},
	{"id":"aura","icon":"♧","name":"Живой кристалл","description":"Активные усиления создают светящуюся ауру вокруг падающей детали.","effect":"aura"},
	{"id":"hunter","icon":"⌖","name":"Охотник за линиями","description":"Очистка 2+ линий наносит дополнительный урон монстру.","effect":"hunter"},
	{"id":"mirror","icon":"◐","name":"Зеркальная матрица","description":"Каждые 7 линий зеркалит следующий блок.","effect":"mirror"},
	{"id":"loop","icon":"⚛","name":"Квантовая петля","description":"Порог уровня −1 линия (минимум 3).","effect":"loop"},
	{"id":"plasma","icon":"❂","name":"Плазменная волна","description":"Сбрасывает задержку падения при очистке.","effect":"plasma"}
]

const SYNERGIES: Array[Dictionary] = [
	{"ids":["score","mult"],"name":"КОМБО-РЕАКТОР","description":"+12% к очкам за очистку"},
	{"ids":["shield","armor"],"name":"ЖЕЛЕЗНАЯ КРЕПОСТЬ","description":"щит выдерживает дополнительные атаки"},
	{"ids":["slow","memory"],"name":"ХРОНОКОНТРОЛЬ","description":"атаки монстров приходят реже"}
]

const GOAL_LINES := "lines"
const GOAL_SCORE := "score"
const GOAL_SURVIVE := "survive"
const GOAL_LEVEL := "level"

var room := 1
var floor := 1
var boss := false
var enemy_hp := 0
var enemy_max_hp := 0
var attack_index := 0
var next_attack_seconds := 0
var defeated := 0
var card_ranks: Dictionary = {}
var reserve_charges := 0
var goals: Array[Dictionary] = []

func start_run() -> void:
	room = 1
	floor = 1
	boss = false
	defeated = 0
	attack_index = 0
	card_ranks.clear()
	reserve_charges = 0
	goals.clear()
	_start_room()

func _start_room() -> void:
	floor = int((room - 1) / 5) + 1
	boss = room % 5 == 0
	var hp := 18 + floor * 7 + room * 2 if boss else 5 + floor * 2 + int(room / 2)
	enemy_hp = hp
	enemy_max_hp = hp
	attack_index = 0
	next_attack_seconds = 20 if boss else maxi(23, 34 - floor * 2)

func current_attack_profile() -> Dictionary:
	var cycle: Array[String] = ["siege", "crossfire"] if boss else ["breach", "crossfire"]
	var attack_id := cycle[posmod(attack_index, cycle.size())]
	var profiles := {
		"breach":{"id":"breach","label":"БРЕШЬ · 1 РЯД","description":"Один мусорный ряд · один проход","rows":1,"holes":1},
		"crossfire":{"id":"crossfire","label":"ПЕРЕКРЁСТНЫЙ ЗАЛП · 2 РЯДА","description":"Два ряда · по два смещённых прохода","rows":2,"holes":2},
		"siege":{"id":"siege","label":"ОСАДА БОССА · 2 РЯДА","description":"Два ряда · узкий проход в каждом","rows":2,"holes":1}
	}
	return profiles[attack_id].duplicate(true)

func build_garbage_row(row_index: int) -> Array[int]:
	var profile := current_attack_profile()
	var row: Array[int] = []
	row.resize(10)
	row.fill(7)
	var seed_value := (room * 3 + attack_index * 5 + row_index * 2) % 10
	for hole_index in range(int(profile.holes)):
		row[(seed_value + hole_index * 4) % 10] = 0
	return row

func resolve_enemy_attack() -> Dictionary:
	var profile := current_attack_profile()
	var absorbed := reserve_charges > 0 and get_card_rank("reserve") > 0
	if absorbed:
		reserve_charges -= 1
	attack_index += 1
	var chrono := get_card_rank("slow") > 0 and get_card_rank("memory") > 0
	var base_interval := 20 if boss else 34 - floor * 2
	next_attack_seconds = maxi(12 if boss else 17, base_interval - (8 if chrono else 0))
	return {"absorbed":absorbed,"profile":profile,"rows":[] if absorbed else _build_rows_from_profile(profile, attack_index - 1)}

func _build_rows_from_profile(profile: Dictionary, attack_number: int) -> Array:
	var rows: Array = []
	for row_index in range(int(profile.rows)):
		var row: Array[int] = []
		row.resize(10)
		row.fill(7)
		var seed_value := (room * 3 + attack_number * 5 + row_index * 2) % 10
		for hole_index in range(int(profile.holes)):
			row[(seed_value + hole_index * 4) % 10] = 0
		rows.append(row)
	return rows

func damage_enemy(amount: int) -> Dictionary:
	if enemy_hp <= 0:
		return {"damaged":0,"defeated":false,"room":room,"floor":floor,"boss":boss}
	var applied := mini(enemy_hp, maxi(0, amount))
	enemy_hp -= applied
	if enemy_hp > 0:
		return {"damaged":applied,"defeated":false,"room":room,"floor":floor,"boss":boss}
	defeated += 1
	room += 1
	_start_room()
	return {"damaged":applied,"defeated":true,"room":room,"floor":floor,"boss":boss}

func choose_card(card_id: String) -> bool:
	if not has_card(card_id):
		return false
	var previous := get_card_rank(card_id)
	if previous >= MAX_CARD_RANK:
		return false
	card_ranks[card_id] = previous + 1
	if card_id == "reserve":
		reserve_charges = int(card_ranks[card_id])
	return true

func get_card_rank(card_id: String) -> int:
	return clampi(int(card_ranks.get(card_id, 0)), 0, MAX_CARD_RANK)

func has_card(card_id: String) -> bool:
	for card in CARD_DEFINITIONS:
		if str(card.id) == card_id:
			return true
	return false

func active_synergies() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for synergy in SYNERGIES:
		var active := true
		for card_id in synergy.ids:
			if get_card_rank(str(card_id)) <= 0:
				active = false
				break
		if active:
			result.append(synergy.duplicate(true))
	return result

func create_goal(goal_type: String, lines: int, score: int, run_seconds: int, level: int, target_roll: int, reward_roll: int, goal_id: int) -> Dictionary:
	var target := 0
	var label := ""
	match goal_type:
		GOAL_LINES:
			label = "Очистить линии"
			target = lines + 3 + posmod(target_roll, 4)
		GOAL_SCORE:
			label = "Набрать очки"
			target = score + 400 + posmod(target_roll, 601)
		GOAL_SURVIVE:
			label = "Продержаться, секунд"
			target = run_seconds + 15 + posmod(target_roll, 21)
		GOAL_LEVEL:
			label = "Достичь уровня"
			target = level + 1 + posmod(target_roll, 2)
		_:
			return {}
	return {"id":goal_id,"type":goal_type,"label":label,"target":target,"reward":10 + posmod(reward_roll, 16),"claimed":false}

func get_card_effect_description(card_id: String, requested_rank: int) -> String:
	var rank := clampi(requested_rank, 1, MAX_CARD_RANK)
	match card_id:
		"score": return "Комбо даёт +%d%% очков за шаг" % (15 * rank)
		"shield": return "Щит выдержит %d атаки" % (rank + get_card_rank("armor"))
		"mult": return "Множитель очков ×%.2f" % (1.0 + rank * 0.5)
		"slow": return "Падение деталей замедлено на %d мс за уровень" % (rank * 25)
		"resonance": return "Каждые 4 линии дают +%d заряд(а) уровня" % rank
		"magnet": return "За двойную очистку +%d очков" % (250 * rank)
		"glow": return "Свечение деталей: +%d%% к очкам" % (10 * rank)
		"echo": return "Эхо даёт +%d заряд(а) уровня" % rank
		"unstable": return "Каждые 90 секунд +%d очков" % (500 * rank)
		"dust": return "За одиночную линию +%d очков" % (100 * rank)
		"armor": return "Добавляет +%d дополнительный заряд щита" % rank
		"burst": return "За тройную очистку +%d очков" % (600 * rank)
		"hold": return "Удержание доступно %d раза" % (1 + rank)
		"memory": return "Порог уровня снижается на %d линию(и)" % rank
		"nova": return "Аварийное спасение очищает %d нижн. линию(и)" % rank
		"tide": return "Каждые 45 секунд +%d заряд(а) уровня" % rank
		"fortress": return "Замедляет рост сложности на %d%%" % (8 * rank)
		"rift": return "При победе над монстром очищает %d нижн. линию(и)" % rank
		"loop": return "Порог уровня −%d линию(и)" % rank
		"comet": return "Быстрый уровень приносит +%d очков" % (300 * rank)
		"gear": return "Каждая 5-я установленная фигура: +%d очков" % (25 * rank)
		"plasma": return "Сбрасывает задержку следующего падения"
		_: return ""

func card_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in CARD_DEFINITIONS:
		result.append(card.duplicate(true))
	return result
