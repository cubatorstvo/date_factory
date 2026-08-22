class_name SeedContentFactory
extends RefCounted

const TAG_SCRIPT := "res://date_system/content/date_tag.gd"
const MOVE_SCRIPT := "res://date_system/content/date_move.gd"
const MAPPING_SCRIPT := "res://date_system/content/date_move_situation_mapping.gd"
const REQ_SCRIPT := "res://date_system/content/unlock_requirement.gd"


func build_catalog() -> DateContentCatalog:
	var catalog := DateContentCatalog.new()
	catalog.tags = _tags()
	catalog.characteristics = _stats()
	catalog.local_objects = _local_objects()
	catalog.date_venues = _venues()
	catalog.outfits = _outfits()
	catalog.traits = _traits()
	catalog.situations = _situations()
	catalog.moves = _moves()
	catalog.girl_difficulty_presets = _difficulties()
	catalog.girls = _girls()
	catalog.date_rules = _rules()
	return catalog


func export_to_disk() -> void:
	var catalog := build_catalog()
	_save_group(catalog.tags, "res://date_system/content/tags")
	_save_group(catalog.characteristics, "res://date_system/content/characteristics")
	_save_group(catalog.local_objects, "res://date_system/content/local_objects")
	_save_group(catalog.date_venues, "res://date_system/content/venues")
	_save_group(catalog.outfits, "res://date_system/content/outfits")
	_save_group(catalog.traits, "res://date_system/content/traits")
	_save_group(catalog.situations, "res://date_system/content/situations")
	_save_group(catalog.moves, "res://date_system/content/moves")
	_save_group(catalog.girl_difficulty_presets, "res://date_system/content/girl_difficulty")
	_save_group(catalog.girls, "res://date_system/content/girls")
	ResourceSaver.save(catalog.date_rules, "res://date_system/content/rules/date_rules.tres")
	ResourceSaver.save(catalog, "res://date_system/content/catalog/date_content_catalog.tres")


func _save_group(items: Array, folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for item in items:
		var path: String = "%s/%s.tres" % [folder, String(item.id)]
		item.resource_path = path
		ResourceSaver.save(item, path)


func _tag(id: String, name: String, description: String) -> DateTag:
	var tag := DateTag.new()
	tag.id = StringName(id)
	tag.display_name = name
	tag.description = description
	tag.enabled = true
	return tag


func _tags() -> Array[DateTag]:
	return [
		_tag("politeness", "УЧТИВОСТЬ", "Вежливость, уважение, мягкая поддержка."),
		_tag("directness", "ПРЯМОЛИНЕЙНОСТЬ", "Прямая речь без украшений."),
		_tag("flattery", "ПОДХАЛИМАЖ", "Угодливая похвала и сглаживание."),
		_tag("audacity", "НАГЛОСТЬ", "Колкость, дерзость, провокация."),
		_tag("dominance", "ДОМИНИРОВАНИЕ", "Контроль ситуации и давления."),
		_tag("risk", "АЗАРТ", "Готовность к риску и пари."),
		_tag("generosity", "ЩЕДРОСТЬ", "Деньги и материальная помощь."),
		_tag("status", "СТАТУС", "Демонстрация положения и ресурсов."),
		_tag("care", "ЗАБОТА", "Внимание к комфорту, состоянию и интересам другого человека."),
		_tag("humor", "ЮМОР", "Реакция через шутку, иронию или превращение ситуации в комедию."),
		_tag("composure", "САМООБЛАДАНИЕ", "Спокойствие, выдержка и отсутствие суеты под давлением ситуации."),
		_tag("cunning", "ХИТРОСТЬ", "Решение ситуации через обходной ход, проверку условий или использование правил в свою пользу."),
	]


func _stat(id: String, name: String, description: String) -> CharacteristicDefinition:
	var stat := CharacteristicDefinition.new()
	stat.id = StringName(id)
	stat.display_name = name
	stat.description = description
	stat.min_level = 0
	stat.max_level = 5
	return stat


func _stats() -> Array[CharacteristicDefinition]:
	return [
		_stat("muscle", "Мышца", "Физическая сила. Открывает силовые ходы и повышает шанс победы в силовых соревнованиях."),
		_stat("appearance", "Внешность", "Внешняя привлекательность. Открывает специальные ходы и повышает шанс победы в соревнованиях на внешность."),
		_stat("capital", "Капитал", "Деньги и ресурсы героя. Открывает дорогие ходы и повышает шанс победы в соревнованиях на капитал."),
		_stat("aura", "Аура", "Способность давить присутствием и управлять вниманием. Открывает соответствующие ходы и повышает шанс победы в соревнованиях на ауру."),
	]


func _local_object(id: String, name: String, description: String, move_ids: Array) -> DateLocalObject:
	var local_object: DateLocalObject = DateLocalObject.new()
	local_object.id = StringName(id)
	local_object.display_name = name
	local_object.description = description
	local_object.enabled = true
	var typed: Array[StringName] = []
	for item in move_ids:
		typed.append(StringName(str(item)))
	local_object.move_ids = typed
	return local_object


func _local_objects() -> Array[DateLocalObject]:
	return [
		_local_object("window", "Окно", "Окно, которое можно приоткрыть или распахнуть.", ["local_window_audacity", "local_window_care"]),
		_local_object("sofa", "Диван", "Диван, на котором можно задать позу и темп разговора.", ["local_sofa_composure", "local_sofa_dominance"]),
		_local_object("tv", "Телевизор", "Телевизор с передачами и роликами под руку.", ["local_tv_humor", "local_tv_cunning"]),
		_local_object("jukebox", "Музыкальный автомат", "Музыкальный автомат с чужими и своими композициями.", ["local_jukebox_humor", "local_jukebox_audacity"]),
		_local_object("barista", "Бариста", "Бариста, который может принести десерт или подыграть истории.", ["local_barista_generosity", "local_barista_cunning"]),
		_local_object("waiter", "Официант", "Официант, через которого заказывают десерт и «то самое».", ["local_waiter_generosity", "local_waiter_status"]),
		_local_object("piano", "Рояль", "Рояль в зале — сыграть самому или занять место музыканта.", ["local_piano_humor", "local_piano_dominance"]),
		_local_object("emperor_chair", "Массажное кресло «Император»", "Закрытый каталог Кати: странное дорогое кресло с несколькими режимами.", ["local_emperor_care", "local_emperor_status", "local_emperor_humor"]),
	]


func _location(
	id: String,
	name: String,
	enabled: bool,
	apartment_prep: bool,
	local_object_ids: Array
) -> DateVenue:
	var location: DateVenue = DateVenue.new()
	location.id = StringName(id)
	location.display_name = name
	location.description = name
	location.enabled = enabled
	location.uses_apartment_preparation = apartment_prep
	var typed: Array[StringName] = []
	for item in local_object_ids:
		typed.append(StringName(str(item)))
	location.local_object_ids = typed
	return location


func _venues() -> Array[DateVenue]:
	return [
		_location("apartment", "Квартира", true, true, ["window", "sofa"]),
		_location("cafe", "Кафе", true, false, ["window", "jukebox", "barista"]),
		_location("restaurant", "Ресторан", true, false, ["window", "waiter", "piano"]),
		_location("park", "Парк", false, false, []),
		_location("cinema", "Кинотеатр", false, false, []),
		_location("arcade", "Аркада", false, false, []),
		_location("museum", "Музей", false, false, []),
		_location("planetarium", "Планетарий", false, false, []),
	]


func _outfit(id: String, name: String, price: int, stat_id: String = "", min_story_stage: int = 1, outfit_move_id: String = "") -> Outfit:
	var outfit := Outfit.new()
	outfit.id = StringName(id)
	outfit.display_name = name
	outfit.description = name
	outfit.enabled = true
	outfit.price = price
	outfit.stat_id = StringName(stat_id)
	outfit.stat_bonus = 1 if not stat_id.is_empty() else 0
	outfit.min_story_stage = min_story_stage
	outfit.outfit_move_id = StringName(outfit_move_id)
	return outfit


func _outfits() -> Array[Outfit]:
	return [
		_outfit("casual", "Повседневная", 0),
		_outfit("sport", "Спортивный комплект", 250, "muscle", 1),
		_outfit("stylish", "Стильный комплект", 250, "appearance", 1),
		_outfit("business", "Деловой костюм", 250, "capital", 1),
		_outfit("minimal_black", "Минималистичный чёрный образ", 250, "aura", 1),
		_outfit("wrestling", "Борцовка", 700, "muscle", 2, "outfit_flex_bicep"),
		_outfit("magician", "Костюм фокусника", 700, "appearance", 2, "outfit_card_trick"),
		_outfit("luxury", "Роскошный костюм", 700, "capital", 2, "outfit_premium_card"),
		_outfit("leather_jacket", "Кожаная куртка", 700, "aura", 2, "outfit_dramatic_entrance"),
		_outfit("stunt", "Костюм каскадёра", 1200, "muscle", 4, "outfit_dangerous_idea"),
		_outfit("model", "Модельный образ", 1200, "appearance", 4, "outfit_beautiful_couple"),
		_outfit("philanthropist", "Образ филантропа", 1200, "capital", 4, "outfit_pay_extra"),
		_outfit("black_turtleneck", "Чёрная водолазка", 1200, "aura", 4, "outfit_silent_hold"),
	]


func _situation(id: String, name: String, text: String, phase: DateTypes.DatePhase, base_move_ids: Array = []) -> DateSituation:
	var situation := DateSituation.new()
	situation.id = StringName(id)
	situation.display_name = name
	situation.description = name
	situation.situation_text = text
	situation.enabled = true
	situation.allowed_phases = [int(phase)]
	situation.weight = 1.0
	var typed: Array[StringName] = []
	for move_id in base_move_ids:
		typed.append(StringName(str(move_id)))
	situation.base_move_ids = typed
	return situation


func _situations() -> Array[DateSituation]:
	return [
		_situation("appearance_question", "Оценка внешности", "В начале встречи девушка спрашивает:\n«Ну что, как я выгляжу?»", DateTypes.DatePhase.OPENING, [
			"appearance_question__compliment",
			"appearance_question__tease",
			"appearance_question__say_directly",
			"appearance_question__show_off",
			"appearance_question__support",
			"appearance_question__smooth",
		]),
		_situation("money_request", "Просьба о деньгах", "К вам подходит незнакомец и просит денег на срочную проблему.", DateTypes.DatePhase.CORE, [
			"money_request__pay",
			"money_request__refuse",
			"money_request__say_directly",
			"money_request__take_initiative",
			"money_request__show_off",
			"money_request__tease",
		]),
		_situation("rival_provocation", "Провокация самца", "К вам подходит другой самец, заявляет, что рейтинг героя выглядит подозрительно, и начинает провоцировать.", DateTypes.DatePhase.CORE, [
			"rival_provocation__tease",
			"rival_provocation__refuse",
			"rival_provocation__say_directly",
			"rival_provocation__show_off",
			"rival_provocation__accept_challenge",
			"rival_provocation__smooth",
		]),
		_situation("spontaneous_bet", "Пари", "Девушка предлагает пари: проигравший выполняет условие победителя.", DateTypes.DatePhase.CORE, [
			"spontaneous_bet__tease",
			"spontaneous_bet__pay",
			"spontaneous_bet__refuse",
			"spontaneous_bet__say_directly",
			"spontaneous_bet__take_initiative",
			"spontaneous_bet__accept_challenge",
		]),
		_situation("date_verdict", "Оценка свидания", "Перед расставанием девушка спрашивает:\n«Ну и как тебе сегодняшний вечер?»", DateTypes.DatePhase.CLOSING, [
			"date_verdict__compliment",
			"date_verdict__tease",
			"date_verdict__say_directly",
			"date_verdict__take_initiative",
			"date_verdict__show_off",
			"date_verdict__support",
		]),
	]


func _base_move(id: String, name: String, tag_id: String, option_text: String) -> DateMove:
	var move := DateMove.new()
	move.id = StringName(id)
	move.display_name = name
	move.description = name
	move.kind = DateTypes.DateMoveKind.BASE
	move.enabled = true
	move.max_uses_per_date = 0
	move.fixed_tag_id = StringName(tag_id)
	move.fixed_option_text = option_text
	move.fixed_positive_result_text = "Ей это откликается. Тег «%s» работает в её пользу." % tag_id
	move.fixed_negative_result_text = "Ей это режет. Тег «%s» играет против вас." % tag_id
	return move


func _characteristic_move(id: String, name: String, tag_id: String, option_text: String, positive_text: String, negative_text: String, stat_id: String, level: int) -> DateMove:
	return _fixed_move(id, name, DateTypes.DateMoveKind.CHARACTERISTIC, tag_id, option_text, positive_text, negative_text, stat_id, level)


func _outfit_move(id: String, name: String, tag_id: String, option_text: String, positive_text: String, negative_text: String) -> DateMove:
	return _fixed_move(id, name, DateTypes.DateMoveKind.OUTFIT, tag_id, option_text, positive_text, negative_text, "", 0)


func _fixed_move(id: String, name: String, kind: DateTypes.DateMoveKind, tag_id: String, option_text: String, positive_text: String, negative_text: String, stat_id: String, level: int) -> DateMove:
	var move := DateMove.new()
	move.id = StringName(id)
	move.display_name = name
	move.description = name
	move.kind = kind
	move.enabled = true
	move.max_uses_per_date = 1
	move.fixed_tag_id = StringName(tag_id)
	move.fixed_option_text = option_text
	move.fixed_positive_result_text = positive_text
	move.fixed_negative_result_text = negative_text
	if not stat_id.is_empty():
		var requirement := UnlockRequirement.new()
		requirement.stat_id = StringName(stat_id)
		requirement.required_level = level
		move.unlock_requirement = requirement
	return move


func _local_move(
	id: String,
	name: String,
	tag_id: String,
	option_text: String,
	positive_text: String,
	negative_text: String,
	stat_id: String = "",
	level: int = 0
) -> DateMove:
	var move: DateMove = DateMove.new()
	move.id = StringName(id)
	move.display_name = name
	move.description = name
	move.kind = DateTypes.DateMoveKind.LOCAL
	move.enabled = true
	move.max_uses_per_date = 0
	move.fixed_tag_id = StringName(tag_id)
	move.fixed_option_text = option_text
	move.fixed_positive_result_text = positive_text
	move.fixed_negative_result_text = negative_text
	if not stat_id.is_empty():
		var requirement: UnlockRequirement = UnlockRequirement.new()
		requirement.stat_id = StringName(stat_id)
		requirement.required_level = level
		move.unlock_requirement = requirement
	return move


func _moves() -> Array[DateMove]:
	return [
		_base_move("appearance_question__compliment", "Сделать комплимент", "politeness", "Сказать, что она отлично выглядит."),
		_base_move("appearance_question__tease", "Подколоть", "humor", "Сказать, что ожидал увидеть что-то хуже."),
		_base_move("appearance_question__say_directly", "Сказать прямо", "directness", "Сказать, что именно в её образе нравится и что вызывает вопросы."),
		_base_move("appearance_question__show_off", "Показать себя", "status", "Перевести разговор на собственный образ и сравнить его с её образом."),
		_base_move("appearance_question__support", "Поддержать", "care", "Спросить, нравится ли образ ей самой, и поддержать её выбор."),
		_base_move("appearance_question__smooth", "Сгладить ситуацию", "flattery", "Сказать, что к её образу невозможно придраться."),
		_base_move("money_request__pay", "Заплатить", "generosity", "Оплатить всю заявленную сумму."),
		_base_move("money_request__refuse", "Отказаться", "composure", "Спокойно отказать и закончить разговор."),
		_base_move("money_request__say_directly", "Сказать прямо", "directness", "Спросить, на что конкретно нужны деньги."),
		_base_move("money_request__take_initiative", "Взять инициативу", "dominance", "Самому определить сумму и закончить разговор."),
		_base_move("money_request__show_off", "Показать себя", "status", "Дать крупную сумму так, чтобы это заметили окружающие."),
		_base_move("money_request__tease", "Подколоть", "cunning", "Попросить сначала доказать историю, а потом вернуться к вопросу денег."),
		_base_move("rival_provocation__tease", "Подколоть", "humor", "Высмеять его претензию."),
		_base_move("rival_provocation__refuse", "Отказаться", "cunning", "Отказаться участвовать в провокации и предложить проверить рейтинг через официальный сервис."),
		_base_move("rival_provocation__say_directly", "Сказать прямо", "directness", "Сказать самцу, что он мешает свиданию и должен уйти."),
		_base_move("rival_provocation__show_off", "Показать себя", "status", "Назвать свой рейтинг и предложить сравнить показатели."),
		_base_move("rival_provocation__accept_challenge", "Принять вызов", "risk", "Принять предложенное соревнование."),
		_base_move("rival_provocation__smooth", "Сгладить ситуацию", "composure", "Спокойно предложить завершить конфликт и разойтись."),
		_base_move("spontaneous_bet__tease", "Подколоть", "audacity", "Добавить унизительное условие для проигравшего."),
		_base_move("spontaneous_bet__pay", "Заплатить", "status", "Сделать денежную ставку существенно выше предложенной."),
		_base_move("spontaneous_bet__refuse", "Отказаться", "composure", "Спокойно отказаться от пари."),
		_base_move("spontaneous_bet__say_directly", "Сказать прямо", "directness", "Сразу сказать своё мнение об идее пари."),
		_base_move("spontaneous_bet__take_initiative", "Взять инициативу", "dominance", "Самому переписать условия пари."),
		_base_move("spontaneous_bet__accept_challenge", "Принять вызов", "risk", "Согласиться на исходные условия пари."),
		_base_move("date_verdict__compliment", "Сделать комплимент", "flattery", "Сказать, что это было идеальное свидание."),
		_base_move("date_verdict__tease", "Подколоть", "humor", "Сказать, что бывало и хуже."),
		_base_move("date_verdict__say_directly", "Сказать прямо", "directness", "Сказать, что именно в вечере понравилось и что хотелось бы изменить."),
		_base_move("date_verdict__take_initiative", "Взять инициативу", "dominance", "Сразу назначить следующую встречу."),
		_base_move("date_verdict__show_off", "Показать себя", "status", "Сказать, что для первого раза она справилась неплохо."),
		_base_move("date_verdict__support", "Поддержать", "care", "Сказать, что главное — понравился ли вечер ей самой."),
		_characteristic_move("char_say_plain", "Сказать по-простому", "directness", "Сказать всё прямо, без лишних конструкций.", "Прямолинейность без обёртки ей зашла.", "Сказал слишком прямо — ей это режет.", "muscle", 1),
		_characteristic_move("char_stress_test", "Проверить на прочность", "risk", "Предложить немедленно проверить идею на практике, даже если это выглядит сомнительно.", "Готовность сразу проверить идею ей зашла.", "Предложил проверить идею на практике — ей это слишком рискованно.", "muscle", 3),
		_characteristic_move("char_force_argument", "Силовой аргумент", "dominance", "Продемонстрировать физическое превосходство как окончательный аргумент.", "Силовой аргумент закрыл тему — ей это зашло.", "Показал физическое превосходство — ей это слишком грубо.", "muscle", 5),
		_characteristic_move("char_gallantry", "Включить галантность", "politeness", "Принять максимально учтивый вид и повести себя безупречно воспитанно.", "Галантность к месту — ей приятно.", "Включил галантность слишком театрально — ей это фальшиво.", "appearance", 1),
		_characteristic_move("char_polished_compliment", "Красиво подать комплимент", "flattery", "Сделать комплимент так, будто это профессионально подготовленная презентация.", "Комплимент подан как витрина — ей это зашло.", "Комплимент прозвучал как презентация — ей это слишком подобострастно.", "appearance", 3),
		_characteristic_move("char_play_with_looks", "Сыграть внешностью", "audacity", "Демонстративно использовать собственную внешность как аргумент.", "Сыграл внешностью как аргументом — ей это зашло.", "Выставил внешность аргументом — ей это слишком нагло.", "appearance", 5),
		_characteristic_move("char_cover_expenses", "Взять расходы на себя", "generosity", "Немедленно предложить оплатить вопрос за свой счёт.", "Взял расходы на себя — ей это приятно.", "Сразу предложил всё оплатить — ей это покупка настроения.", "capital", 1),
		_characteristic_move("char_propose_scheme", "Предложить схему", "cunning", "Предложить подозрительно эффективную схему, в которой формально все остаются в выигрыше.", "Схема звучит ловко — ей это зашло.", "Предложил схему, в которой все «в выигрыше» — ей это слишком скользко.", "capital", 3),
		_characteristic_move("char_status_solve", "Решить вопрос статусом", "status", "Небрежно задействовать деньги, связи или статус как решение ситуации.", "Статус закрыл вопрос — ей это зашло.", "Решил вопрос статусом — ей это слишком демонстративно.", "capital", 5),
		_characteristic_move("char_support_mode", "Включить поддержку", "care", "Переключиться в режим уверенной и спокойной поддержки.", "Спокойная поддержка к месту — ей спокойнее.", "Включил режим поддержки — ей это кажется лишней опекой.", "aura", 1),
		_characteristic_move("char_joke_relief", "Разрядить шуткой", "humor", "Снять напряжение уместной или неуместной шуткой.", "Шутка сняла напряжение — ей смешно.", "Шутка не попала — ей это ломает тон.", "aura", 3),
		_characteristic_move("char_hold_pause", "Выдержать паузу", "composure", "Молча выдерживать ситуацию до тех пор, пока первой не сдастся она.", "Выдержал паузу — ей это спокойствие по делу.", "Молча ждал, пока она сдастся — ей это давление.", "aura", 5),
		_outfit_move("outfit_flex_bicep", "Напрячь бицепс без причины", "dominance", "Внезапно перевести внимание на собственную физическую форму.", "Внезапный акцент на форме зашёл как контроль сцены.", "Напряг бицепс без причины — ей это слишком театрально."),
		_outfit_move("outfit_card_trick", "Показать фокус с исчезновением", "humor", "Достать реквизит и немедленно устроить карточный фокус.", "Карточный фокус сработал как шутка — ей смешно.", "Достал реквизит посреди разговора — ей это не к месту."),
		_outfit_move("outfit_premium_card", "Показать премиальную карту", "status", "Небрежно продемонстрировать максимально статусный способ оплаты.", "Премиальная карта закрыла вопрос статусом — ей это зашло.", "Показал премиальную карту — ей это слишком демонстративно."),
		_outfit_move("outfit_dramatic_entrance", "Сделать демонстративный выход", "audacity", "На несколько секунд превратить обычную ситуацию в собственную сцену.", "Демонстративный выход зашёл как наглость к месту.", "Превратил ситуацию в собственную сцену — ей это слишком нагло."),
		_outfit_move("outfit_dangerous_idea", "Предложить опасную идею", "risk", "Немедленно предложить сделать что-нибудь неоправданно рискованное.", "Опасная идея зашла как ставка.", "Предложил неоправданный риск — ей это слишком лихо."),
		_outfit_move("outfit_beautiful_couple", "Объявить вас красивой парой", "flattery", "Вслух констатировать, насколько эффектно вы смотритесь вместе.", "Комплимент паре зашёл.", "Объявил вас красивой парой слишком презентационно — ей это льстит не к месту."),
		_outfit_move("outfit_pay_extra", "Оплатить что-нибудь лишнее", "generosity", "Демонстративно потратить деньги на вещь, которую никто не просил покупать.", "Лишняя покупка сработала как щедрый жест.", "Оплатил то, что никто не просил — ей это покупка настроения."),
		_outfit_move("outfit_silent_hold", "Молча выдержать ситуацию", "composure", "Сохранять абсолютное спокойствие до тех пор, пока неловко не станет всем остальным.", "Молчаливое спокойствие закрыло паузу — ей это по делу.", "Держал молчание, пока неловко не стало всем — ей это давление."),
		_local_move("local_window_audacity", "Распахнуть окно", "audacity", "Распахнуть окно настежь и продолжить разговор с улицей.", "Окно настежь, улица в разговоре — ей это зашло.", "Распахнул окно настежь — ей слишком шумно и демонстративно."),
		_local_move("local_window_care", "Приоткрыть окно", "care", "Слегка приоткрыть окно для свежего воздуха.", "Свежий воздух к месту — ей спокойнее.", "Приоткрыл окно «для воздуха» — ей это кажется лишней заботой не к месту."),
		_local_move("local_sofa_composure", "Откинуться на диван", "composure", "Откинуться на диван и невозмутимо продолжить разговор.", "Откинулся и держишь тон — ей это спокойствие по делу.", "Откинулся на диван слишком расслабленно — ей это выглядит как равнодушие."),
		_local_move("local_sofa_dominance", "Занять центр дивана", "dominance", "Пересесть в центр дивана и самому задать темп разговору.", "Занял центр дивана и темп разговора — ей это зашло.", "Пересел в центр и задал темп — ей это слишком навязано.", "aura", 2),
		_local_move("local_tv_humor", "Неуместная передача", "humor", "Включить максимально неуместную передачу и сделать вид, что так и было задумано.", "Неуместная передача сработала как шутка — ей смешно.", "Включил неуместную передачу — ей это выглядит как сбой, а не юмор."),
		_local_move("local_tv_cunning", "Подтверждающий ролик", "cunning", "Найти ролик, который неожиданно подтверждает твою версию.", "Ролик неожиданно подтвердил твою версию — ей это ловко.", "Подобрал ролик «в подтверждение» — ей это выглядит как подтасовка."),
		_local_move("local_jukebox_humor", "Неуместная песня", "humor", "Поставить максимально неуместную песню.", "Неуместная песня попала в тон — ей смешно.", "Поставил максимально неуместную песню — ей это ломает вечер."),
		_local_move("local_jukebox_audacity", "Переключить музыку", "audacity", "Переключить музыку на свой выбор посреди чужой композиции.", "Переключил чужую композицию на свою — ей это зашло как наглость к месту.", "Перебил чужую песню своим выбором — ей это грубо."),
		_local_move("local_barista_generosity", "Фирменный десерт", "generosity", "Заказать девушке фирменный десерт.", "Фирменный десерт к месту — ей приятно.", "Заказал фирменный десерт — ей это кажется покупкой настроения."),
		_local_move("local_barista_cunning", "Подыграть истории", "cunning", "Попросить бариста подыграть твоей истории.", "Бариста подыграл истории — ей это ловко.", "Попросил бариста подыграть — ей это выглядит как постановка.", "aura", 2),
		_local_move("local_waiter_generosity", "Дорогой десерт", "generosity", "Заказать для неё самый дорогой десерт.", "Самый дорогой десерт к месту — ей приятно.", "Заказал самый дорогой десерт — ей это слишком демонстративно."),
		_local_move("local_waiter_status", "То самое", "status", "Попросить принести «то самое», будто ты здесь постоянный гость.", "«То самое» принесли как постоянному гостю — ей это зашло.", "Попросил «то самое» как завсегдатай — ей это выглядит как игра в статус.", "capital", 2),
		_local_move("local_piano_humor", "Пафосный марш", "humor", "Сыграть одним пальцем максимально пафосный марш.", "Пафосный марш одним пальцем сработал — ей смешно.", "Сыграл пафосный марш одним пальцем — ей это не смешно, а жалко."),
		_local_move("local_piano_dominance", "Занять рояль", "dominance", "Попросить музыканта уступить тебе рояль и занять его место.", "Занял рояль вместо музыканта — ей это зашло как контроль сцены.", "Попросил уступить рояль — ей это слишком театрально и навязчиво.", "aura", 3),
		_local_move("local_emperor_care", "Предложить массаж", "care", "Включить нормальный режим и предложить ей расслабиться.", "Нормальный режим и забота зашли — она расслабляется.", "Предложение массажа выглядит лишним — ей это не забота."),
		_local_move("local_emperor_status", "Назвать цену кресла", "status", "Небрежно сообщить, сколько стоило это чудовище.", "Цена кресла сработала как статус — ей это впечатлило.", "Назвать цену кресла выглядит хвастовством — ей это лишнее."),
		_local_move("local_emperor_humor", "Включить режим «Космонавт»", "humor", "Запустить максимальную программу и попытаться сохранить достоинство.", "Режим «Космонавт» сработал как шутка — ей смешно.", "Максимальная программа выглядит нелепо — ей это не юмор."),
	]


func _difficulty(id: String, name: String, description: String, positive_count: int, order: int) -> GirlDifficultyPreset:
	var preset := GirlDifficultyPreset.new()
	preset.id = StringName(id)
	preset.display_name = name
	preset.description = description
	preset.enabled = true
	preset.positive_tag_count = positive_count
	preset.sort_order = order
	return preset


func _difficulties() -> Array[GirlDifficultyPreset]:
	return [
		_difficulty("wide", "Широкая", "Онбординг Dating Core: почти всегда есть положительный тег в базовом наборе.", 8, 0),
		_difficulty("easy", "Лёгкая", "Ранний City Stage: очень дружелюбный набор положительных реакций.", 7, 1),
		_difficulty("starter", "Стартовая", "Высокая совместимость с базовым арсеналом героя. Подходит для первых девушек игры.", 6, 2),
		_difficulty("early", "Ранняя", "Небольшая вероятность получить полностью неподходящий набор базовых ходов.", 5, 3),
		_difficulty("mid", "Средняя", "Прокачка героя и подготовка к свиданию начинают заметно влиять на стабильность результата.", 4, 4),
		_difficulty("late", "Поздняя", "Базовый набор регулярно оставляет игрока без положительного тега. Развитый арсенал становится важной частью свидания.", 3, 5),
		_difficulty("elite", "Элитная", "Очень узкий набор положительных реакций. Рассчитана на сильно развитого героя и полноценную подготовку.", 2, 6),
	]

func _trait(id: String, name: String, description: String, kind: GirlTrait.Kind, characteristic_id: String = "", location_id: String = "") -> GirlTrait:
	var girl_trait := GirlTrait.new()
	girl_trait.id = StringName(id)
	girl_trait.display_name = name
	girl_trait.description = description
	girl_trait.enabled = true
	girl_trait.kind = kind
	girl_trait.characteristic_id = StringName(characteristic_id)
	girl_trait.date_venue_id = StringName(location_id)
	return girl_trait


func _traits() -> Array[GirlTrait]:
	return [
		_trait("loves_strong", "Любит сильных", "Первый за свидание положительный ход с требованием Мышца даёт +1.", GirlTrait.Kind.CHARACTERISTIC, "muscle"),
		_trait("values_appearance", "Ценит внешность", "Первый за свидание положительный ход с требованием Внешность даёт +1.", GirlTrait.Kind.CHARACTERISTIC, "appearance"),
		_trait("loves_wealthy", "Любит обеспеченных", "Первый за свидание положительный ход с требованием Капитал даёт +1.", GirlTrait.Kind.CHARACTERISTIC, "capital"),
		_trait("senses_aura", "Чувствует ауру", "Первый за свидание положительный ход с требованием Аура даёт +1.", GirlTrait.Kind.CHARACTERISTIC, "aura"),
		_trait("homebody", "Домоседка", "Свидание в Квартире даёт +1 к итогу.", GirlTrait.Kind.VENUE, "", "apartment"),
		_trait("loves_cafe", "Любит кафе", "Свидание в Кафе даёт +1 к итогу.", GirlTrait.Kind.VENUE, "", "cafe"),
		_trait("loves_restaurants", "Любит рестораны", "Свидание в Ресторане даёт +1 к итогу.", GirlTrait.Kind.VENUE, "", "restaurant"),
	]


func _girl(
	id: String,
	name: String,
	difficulty_id: String,
	positives: Array,
	trait_id: String,
	description: String = ""
) -> GirlProfile:
	var girl: GirlProfile = GirlProfile.new()
	girl.id = StringName(id)
	girl.display_name = name
	girl.description = name if description.is_empty() else description
	girl.enabled = true
	girl.difficulty_preset_id = StringName(difficulty_id)
	girl.trait_id = StringName(trait_id)
	var pos: Array[StringName] = []
	for item in positives:
		pos.append(StringName(str(item)))
	girl.positive_tag_ids = pos
	if GirlCatalog.is_story_girl_id(girl.id):
		girl.initial_known_tag_count = 0
	else:
		girl.initial_known_tag_count = 2
	return girl


func _girls() -> Array[GirlProfile]:
	return [
		_girl("alina", "Алина", "wide", ["politeness", "directness", "care", "generosity", "composure", "humor", "risk", "dominance"], "homebody", "Тренер городского спортзала. Считает, что почти любую жизненную проблему можно решить ещё одним подходом."),
		_girl("marina", "Марина", "easy", ["care", "composure", "directness", "humor", "politeness", "flattery", "status"], "senses_aura", "Продавец магазина одежды. Знает ассортимент лучше владельца и всегда знает, что можно провести как «служебную необходимость»."),
		_girl("girl_actress", "Актриса", "early", ["flattery", "audacity", "generosity", "status", "humor"], "values_appearance", "любит внимание, эффектность, уверенность и человека, который умеет поддерживать ощущение шоу"),
		_girl("vika", "Вика", "easy", ["audacity", "dominance", "risk", "humor", "cunning", "directness", "care"], "values_appearance", "Бариста Café. Видела достаточно неудачных свиданий, чтобы научиться быстро перезапускать разговор."),
		_girl("dasha", "Даша", "starter", ["audacity", "risk", "humor", "dominance", "politeness", "composure"], "loves_strong", "Менеджер клиентского сервиса. Профессионально умеет превращать катастрофический разговор в просто неловкий."),
		_girl("girl_mine_boss", "Начальница шахты", "mid", ["directness", "dominance", "generosity", "composure"], "loves_restaurants", "ценит конкретику, контроль ситуации и людей, которые не начинают суетиться под давлением"),
		_girl("katya", "Катя", "mid", ["directness", "risk", "humor", "cunning"], "loves_cafe", "Продавец мебельного магазина. Имеет доступ к закрытому каталогу вещей, которые нормальному человеку в квартире не нужны."),
		_girl("girl_magazine_editor", "Редактор журнала", "mid", ["directness", "status", "composure", "cunning"], "senses_aura", "профессионально оценивает людей и любит, когда собеседник умеет держать позицию и выбирать слова"),
		_girl("lera", "Лера", "mid", ["politeness", "flattery", "status", "composure"], "loves_restaurants", "Работает в клининговом сервисе. Уверена, что большинство проблем дома начинается с того, что кто-то давно не убирался."),
		_girl("kira", "Кира", "mid", ["directness", "audacity", "cunning", "composure"], "loves_strong", "Стилист. Умеет за короткое время сделать человека визуально убедительнее, чем он есть на самом деле."),
		_girl("olya", "Оля", "mid", ["generosity", "status", "care", "politeness"], "loves_wealthy", "Предпринимательница. Любой свободный час воспринимает как подозрительно плохо монетизированный ресурс."),
		_girl("girl_scientist", "Учёная", "mid", ["directness", "composure", "cunning", "care"], "loves_cafe", "ценит ясность, спокойствие, наблюдательность и необычные решения"),
		_girl("sonya", "Соня", "late", ["audacity", "risk", "humor"], "homebody", "VIP-менеджер Restaurant. Может организовать постоянному гостю немного больше возможностей, чем предусмотрено обычным обслуживанием."),
		_girl("nika", "Ника", "mid", ["cunning", "directness", "audacity", "composure"], "senses_aura", "Директор магазина одежды. Считает один комплект одежды недостаточной подготовкой к серьёзному вечеру."),
		_girl("rita", "Рита", "mid", ["status", "dominance", "generosity", "risk"], "loves_wealthy", "Организатор мероприятий. Если что-то нужно устроить срочно, у неё уже есть номер человека, который это сделает."),
		_girl("eva", "Ева", "mid", ["status", "dominance", "risk", "generosity"], "loves_restaurants", "Рекрутер и профессиональный интервьюер. Быстро понимает людей по нескольким реакциям и учит героя замечать то же самое."),
		_girl("girl_president", "Президент", "late", ["dominance", "status", "composure"], "loves_wealthy", "максимально статусная ручная сюжетная цель; ценит контроль, положение и абсолютное самообладание"),
	]
func _rules() -> DateRules:
	var rules := DateRules.new()
	rules.opening_episode_count = 1
	rules.core_episode_count = 3
	rules.closing_episode_count = 1
	rules.base_moves_per_episode = 3
	rules.allow_situation_repeats = false
	rules.positive_move_score = 1
	rules.negative_move_score = -1
	rules.reveal_tag_after_use = true
	rules.combo_required_distinct_success_tags = 3
	rules.combo_bonus_score = 1
	rules.combo_max_rewards_per_date = 1
	rules.apartment_unprepared_penalty = -1
	rules.min_distinct_base_tags_per_situation = 6
	return rules
