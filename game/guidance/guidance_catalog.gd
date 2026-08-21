class_name GuidanceCatalog
extends RefCounted

const ID_OBJECTIVES_INTRO: StringName = &"objectives_intro"
const ID_DATING_INTRO: StringName = &"dating_intro"
const ID_LOCAL_OBJECTS_INTRO: StringName = &"local_objects_intro"
const ID_LOCKED_MOVES_INTRO: StringName = &"locked_moves_intro"
const ID_RIVAL_INTRO: StringName = &"rival_intro"
const ID_FACTORY_INTRO: StringName = &"factory_intro"
const ID_STAGE_2: StringName = &"stage_2_city_expansion"
const ID_STAGE_3: StringName = &"stage_3_work_promotion"
const ID_STAGE_4: StringName = &"stage_4_city_expansion"
const ID_STAGE_5: StringName = &"stage_5_factory_unlocked"
const ID_STAGE_6: StringName = &"stage_6_world_goal"
const ID_WORLD_REACHED: StringName = &"world_reached"

var _tutorials: Dictionary = {}
var _milestones: Dictionary = {}


func _init() -> void:
	_tutorials[ID_OBJECTIVES_INTRO] = _tutorial(
		ID_OBJECTIVES_INTRO,
		"Главная цель",
		"В блоке ЦЕЛЬ показан путь по текущему этапу кампании. Выполняй подцели по порядку. Строка «Следующий шаг» показывает ближайшее действие, которое двигает основной сюжет."
	)
	_tutorials[ID_DATING_INTRO] = _tutorial(
		ID_DATING_INTRO,
		"Свидание",
		"В каждом эпизоде выбери один ход. Известные предпочтения девушки окрашивают теги ходов. Базовые, открываемые и локальные ходы дают разные способы получить нужный тег. Текущий прогресс Комбо показан в интерфейсе свидания."
	)
	_tutorials[ID_LOCAL_OBJECTS_INTRO] = _tutorial(
		ID_LOCAL_OBJECTS_INTRO,
		"Локальные ходы",
		"Объекты места свидания дают постоянные локальные ходы. После выбора одного хода объект считается использованным до конца текущего свидания. Сохраняй полезные объекты для эпизодов, где базовые варианты подходят хуже."
	)
	_tutorials[ID_LOCKED_MOVES_INTRO] = _tutorial(
		ID_LOCKED_MOVES_INTRO,
		"Прокачка открывает новые ходы",
		"Некоторые ходы становятся доступны на нужном уровне характеристики. Требование показывает нужный уровень и текущее значение. Повышение характеристик расширяет набор решений на будущих свиданиях и влияет на соревнования."
	)
	_tutorials[ID_RIVAL_INTRO] = _tutorial(
		ID_RIVAL_INTRO,
		"Соперники",
		"Перед вызовом показываются взнос, награда и шанс победы. Основная характеристика соревнования повышает этот шанс. Сюжетный соперник открывает путь к сюжетной девушке, а обычные соперники остаются повторяемой активностью города."
	)
	_tutorials[ID_FACTORY_INTRO] = _tutorial(
		ID_FACTORY_INTRO,
		"Date Factory",
		"Клоны автоматически работают вместе с игровым временем. Ползунок распределяет их между заработком денег и свиданиями. Свидания клонов увеличивают Рейтинг и охват текущего масштаба фабрики. Заполнение охвата открывает следующее расширение."
	)
	_milestones[ID_STAGE_2] = _milestone(
		ID_STAGE_2,
		"ГОРОД РАСШИРЕН",
		PackedStringArray([
			"Этап города: 1 → 2",
			"Открыт Ресторан",
			"Появились новые девушки",
			"Появились новые соперники",
			"Перерыв между свиданиями и обычными соперниками: 3 → 2 дня",
		])
	)
	_milestones[ID_STAGE_3] = _milestone(
		ID_STAGE_3,
		"ПОВЫШЕНИЕ НА РАБОТЕ",
		PackedStringArray([
			"Оплата работы: 100 → 200",
			"Новая цель: Редактор журнала",
		])
	)
	_milestones[ID_STAGE_4] = _milestone(
		ID_STAGE_4,
		"ГОРОД РАСШИРЕН",
		PackedStringArray([
			"Этап города: 2 → 3",
			"Появились новые девушки",
			"Появились новые соперники",
			"Перерыв между свиданиями и обычными соперниками: 2 → 1 день",
			"Новая цель: Учёная",
		])
	)
	_milestones[ID_STAGE_5] = _milestone(
		ID_STAGE_5,
		"DATE FACTORY ЗАПУЩЕНА",
		PackedStringArray([
			"Получено 10 клонов",
			"Открыто распределение клонов между работой и свиданиями",
			"Открыта экспансия фабрики",
			"Новая цель: Президент",
		])
	)
	_milestones[ID_STAGE_6] = _milestone(
		ID_STAGE_6,
		"ФИНАЛЬНЫЙ ЭТАП",
		PackedStringArray([
			"Главная цель: Date Factory",
			"Доведи мировой охват фабрики до 100%",
		])
	)
	_milestones[ID_WORLD_REACHED] = _milestone(
		ID_WORLD_REACHED,
		"МИР ОХВАЧЕН",
		PackedStringArray([
			"Date Factory достигла 100% мирового охвата.",
		])
	)


func get_tutorial(id: StringName) -> TutorialDefinition:
	return _tutorials.get(id) as TutorialDefinition


func get_milestone(id: StringName) -> MilestoneDefinition:
	return _milestones.get(id) as MilestoneDefinition


func milestone_for_stage_enter(stage: int) -> StringName:
	match stage:
		2:
			return ID_STAGE_2
		3:
			return ID_STAGE_3
		4:
			return ID_STAGE_4
		5:
			return ID_STAGE_5
		6:
			return ID_STAGE_6
		_:
			return &""


func _tutorial(id: StringName, title: String, body: String) -> TutorialDefinition:
	var definition: TutorialDefinition = TutorialDefinition.new()
	definition.id = id
	definition.title = title
	definition.body = body
	return definition


func _milestone(id: StringName, title: String, body_lines: PackedStringArray) -> MilestoneDefinition:
	var definition: MilestoneDefinition = MilestoneDefinition.new()
	definition.id = id
	definition.title = title
	definition.body_lines = body_lines
	return definition
