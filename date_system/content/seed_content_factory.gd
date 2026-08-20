class_name SeedContentFactory
extends RefCounted

const TAG_SCRIPT := "res://date_system/content/date_tag.gd"
const MOVE_SCRIPT := "res://date_system/content/date_move.gd"
const MAPPING_SCRIPT := "res://date_system/content/date_move_situation_mapping.gd"
const REQ_SCRIPT := "res://date_system/content/unlock_requirement.gd"


func build_catalog() -> DateContentCatalog:
	var catalog := DateContentCatalog.new()
	catalog.tags = _tags()
	catalog.progression_stats = _stats()
	catalog.local_objects = _local_objects()
	catalog.locations = _locations()
	catalog.outfits = _outfits()
	catalog.situations = _situations()
	catalog.moves = _moves()
	catalog.girl_difficulty_presets = _difficulties()
	catalog.girls = _girls()
	catalog.date_rules = _rules()
	return catalog


func export_to_disk() -> void:
	var catalog := build_catalog()
	_save_group(catalog.tags, "res://date_system/content/tags")
	_save_group(catalog.progression_stats, "res://date_system/content/progression")
	_save_group(catalog.local_objects, "res://date_system/content/local_objects")
	_save_group(catalog.locations, "res://date_system/content/locations")
	_save_group(catalog.outfits, "res://date_system/content/outfits")
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


func _stat(id: String, name: String, description: String) -> ProgressionStat:
	var stat := ProgressionStat.new()
	stat.id = StringName(id)
	stat.display_name = name
	stat.description = description
	stat.min_level = 0
	stat.max_level = 5
	return stat


func _stats() -> Array[ProgressionStat]:
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
	]


func _location(
	id: String,
	name: String,
	enabled: bool,
	apartment_prep: bool,
	local_object_ids: Array
) -> DateLocation:
	var location: DateLocation = DateLocation.new()
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


func _locations() -> Array[DateLocation]:
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


func _outfit(id: String, name: String, bonus: int, price: int) -> Outfit:
	var outfit := Outfit.new()
	outfit.id = StringName(id)
	outfit.display_name = name
	outfit.description = name
	outfit.enabled = true
	outfit.score_bonus = bonus
	outfit.price = price
	return outfit


func _outfits() -> Array[Outfit]:
	return [
		_outfit("casual", "Повседневный", 0, 0),
		_outfit("business", "Деловой", 1, 500),
		_outfit("luxury", "Роскошный", 2, 800),
	]


func _situation(id: String, name: String, text: String, phase: DateTypes.DatePhase) -> DateSituation:
	var situation := DateSituation.new()
	situation.id = StringName(id)
	situation.display_name = name
	situation.description = name
	situation.situation_text = text
	situation.enabled = true
	situation.allowed_phases = [int(phase)]
	situation.weight = 1.0
	return situation


func _situations() -> Array[DateSituation]:
	return [
		_situation("appearance_question", "Оценка внешности", "В начале встречи девушка спрашивает:\n«Ну что, как я выгляжу?»", DateTypes.DatePhase.OPENING),
		_situation("money_request", "Просьба о деньгах", "К вам подходит незнакомец и просит денег на срочную проблему.", DateTypes.DatePhase.CORE),
		_situation("rival_provocation", "Провокация самца", "К вам подходит другой самец, заявляет, что рейтинг героя выглядит подозрительно, и начинает провоцировать.", DateTypes.DatePhase.CORE),
		_situation("spontaneous_bet", "Пари", "Девушка предлагает пари: проигравший выполняет условие победителя.", DateTypes.DatePhase.CORE),
		_situation("date_verdict", "Оценка свидания", "Перед расставанием девушка спрашивает:\n«Ну и как тебе сегодняшний вечер?»", DateTypes.DatePhase.CLOSING),
	]


func _mapping(situation_id: String, tag_id: String, option_text: String) -> DateMoveSituationMapping:
	var mapping := DateMoveSituationMapping.new()
	mapping.situation_id = StringName(situation_id)
	mapping.tag_id = StringName(tag_id)
	mapping.option_text = option_text
	var tag_name: String = tag_id
	mapping.positive_result_text = "Ей это откликается. Тег «%s» работает в её пользу." % tag_name
	mapping.negative_result_text = "Ей это режет. Тег «%s» играет против вас." % tag_name
	return mapping


func _base_move(id: String, name: String, mappings: Array) -> DateMove:
	var move := DateMove.new()
	move.id = StringName(id)
	move.display_name = name
	move.description = name
	move.kind = DateTypes.DateMoveKind.BASE
	move.enabled = true
	move.max_uses_per_date = 0
	var typed: Array[DateMoveSituationMapping] = []
	for mapping in mappings:
		typed.append(mapping)
	move.situation_mappings = typed
	return move


func _unlock_move(id: String, name: String, stat_id: String, level: int, mappings: Array) -> DateMove:
	var move := DateMove.new()
	move.id = StringName(id)
	move.display_name = name
	move.description = name
	move.kind = DateTypes.DateMoveKind.UNLOCKABLE
	move.enabled = true
	move.max_uses_per_date = 1
	var requirement := UnlockRequirement.new()
	requirement.stat_id = StringName(stat_id)
	requirement.required_level = level
	move.unlock_requirement = requirement
	var typed: Array[DateMoveSituationMapping] = []
	for mapping in mappings:
		typed.append(mapping)
	move.situation_mappings = typed
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
	move.local_tag_id = StringName(tag_id)
	move.local_option_text = option_text
	move.local_positive_result_text = positive_text
	move.local_negative_result_text = negative_text
	if not stat_id.is_empty():
		var requirement: UnlockRequirement = UnlockRequirement.new()
		requirement.stat_id = StringName(stat_id)
		requirement.required_level = level
		move.unlock_requirement = requirement
	return move


func _moves() -> Array[DateMove]:
	return [
		_base_move("say_directly", "Сказать прямо", [
			_mapping("appearance_question", "directness", "Сказать, что именно в её образе нравится и что вызывает вопросы."),
			_mapping("money_request", "directness", "Спросить, на что конкретно нужны деньги."),
			_mapping("rival_provocation", "directness", "Сказать самцу, что он мешает свиданию и должен уйти."),
			_mapping("spontaneous_bet", "directness", "Сразу сказать своё мнение об идее пари."),
			_mapping("date_verdict", "directness", "Сказать, что именно в вечере понравилось и что хотелось бы изменить."),
		]),
		_base_move("compliment", "Сделать комплимент", [
			_mapping("appearance_question", "politeness", "Сказать, что она отлично выглядит."),
			_mapping("spontaneous_bet", "flattery", "Сказать, что она наверняка победит."),
			_mapping("date_verdict", "flattery", "Сказать, что это было идеальное свидание."),
		]),
		_base_move("support", "Поддержать", [
			_mapping("appearance_question", "care", "Спросить, нравится ли образ ей самой, и поддержать её выбор."),
			_mapping("money_request", "generosity", "Дать незнакомцу небольшую сумму."),
			_mapping("spontaneous_bet", "politeness", "Согласиться на предложенные девушкой правила."),
			_mapping("date_verdict", "care", "Сказать, что главное — понравился ли вечер ей самой."),
		]),
		_base_move("smooth", "Сгладить ситуацию", [
			_mapping("appearance_question", "flattery", "Сказать, что к её образу невозможно придраться."),
			_mapping("money_request", "politeness", "Вежливо отказать и пожелать удачи."),
			_mapping("rival_provocation", "composure", "Спокойно предложить завершить конфликт и разойтись."),
		]),
		_base_move("tease", "Подколоть", [
			_mapping("appearance_question", "humor", "Сказать, что ожидал увидеть что-то хуже."),
			_mapping("money_request", "cunning", "Попросить сначала доказать историю, а потом вернуться к вопросу денег."),
			_mapping("rival_provocation", "humor", "Высмеять его претензию."),
			_mapping("spontaneous_bet", "audacity", "Добавить унизительное условие для проигравшего."),
			_mapping("date_verdict", "humor", "Сказать, что бывало и хуже."),
		]),
		_base_move("take_initiative", "Взять инициативу", [
			_mapping("money_request", "dominance", "Самому определить сумму и закончить разговор."),
			_mapping("rival_provocation", "dominance", "Самому назначить способ выяснить, кто прав."),
			_mapping("spontaneous_bet", "dominance", "Самому переписать условия пари."),
			_mapping("date_verdict", "dominance", "Сразу назначить следующую встречу."),
		]),
		_base_move("refuse", "Отказаться", [
			_mapping("money_request", "composure", "Спокойно отказать и закончить разговор."),
			_mapping("rival_provocation", "cunning", "Отказаться участвовать в провокации и предложить проверить рейтинг через официальный сервис."),
			_mapping("spontaneous_bet", "composure", "Спокойно отказаться от пари."),
		]),
		_base_move("accept_challenge", "Принять вызов", [
			_mapping("rival_provocation", "risk", "Принять предложенное соревнование."),
			_mapping("spontaneous_bet", "risk", "Согласиться на исходные условия пари."),
		]),
		_base_move("pay", "Заплатить", [
			_mapping("money_request", "generosity", "Оплатить всю заявленную сумму."),
			_mapping("rival_provocation", "status", "Предложить самцу деньги за завершение конфликта."),
			_mapping("spontaneous_bet", "status", "Сделать денежную ставку существенно выше предложенной."),
		]),
		_base_move("show_off", "Показать себя", [
			_mapping("appearance_question", "status", "Перевести разговор на собственный образ и сравнить его с её образом."),
			_mapping("money_request", "status", "Дать крупную сумму так, чтобы это заметили окружающие."),
			_mapping("rival_provocation", "status", "Назвать свой рейтинг и предложить сравнить показатели."),
			_mapping("spontaneous_bet", "status", "Сказать, что предложенная ставка слишком мала."),
			_mapping("date_verdict", "status", "Сказать, что для первого раза она справилась неплохо."),
		]),
		_unlock_move("punch", "Дать в жбан", "muscle", 4, [
			_mapping("rival_provocation", "dominance", "Дать самцу в жбан."),
		]),
		_unlock_move("solve_with_money", "Решить деньгами", "capital", 3, [
			_mapping("money_request", "generosity", "Полностью оплатить проблему незнакомца и его следующий день."),
			_mapping("rival_provocation", "status", "Предложить самцу сумму, за которую он сам объявит поражение."),
			_mapping("spontaneous_bet", "status", "Заменить условие пари на крупную денежную ставку."),
		]),
		_unlock_move("play_with_looks", "Сыграть внешностью", "appearance", 3, [
			_mapping("appearance_question", "audacity", "Предложить сначала оценить твой образ."),
			_mapping("rival_provocation", "status", "Продемонстрировать себя и предложить сравнить результат."),
			_mapping("date_verdict", "flattery", "Сказать, что вечер выглядел хорошо, потому что вы хорошо смотрелись вместе."),
		]),
		_unlock_move("silent_pressure", "Молча продавить", "aura", 3, [
			_mapping("money_request", "dominance", "Смотреть на незнакомца до завершения разговора с его стороны."),
			_mapping("rival_provocation", "dominance", "Смотреть на самца до его отступления."),
			_mapping("date_verdict", "composure", "Выдержать паузу до реакции девушки."),
		]),
		_unlock_move("raise_stakes", "Поднять ставки", "capital", 5, [
			_mapping("money_request", "risk", "Предложить удвоить сумму после немедленного доказательства истории."),
			_mapping("spontaneous_bet", "risk", "Удвоить ставку и усложнить условие проигравшему."),
		]),
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
		_difficulty("starter", "Стартовая", "Высокая совместимость с базовым арсеналом героя. Подходит для первых девушек игры.", 6, 0),
		_difficulty("early", "Ранняя", "Небольшая вероятность получить полностью неподходящий набор базовых ходов.", 5, 1),
		_difficulty("mid", "Средняя", "Прокачка героя и подготовка к свиданию начинают заметно влиять на стабильность результата.", 4, 2),
		_difficulty("late", "Поздняя", "Базовый набор регулярно оставляет игрока без положительного тега. Развитый арсенал становится важной частью свидания.", 3, 3),
		_difficulty("elite", "Элитная", "Очень узкий набор положительных реакций. Рассчитана на сильно развитого героя и полноценную подготовку.", 2, 4),
	]


func _girl(
	id: String,
	name: String,
	difficulty_id: String,
	rel_min: int,
	rel_max: int,
	positives: Array,
	description: String = ""
) -> GirlProfile:
	var girl: GirlProfile = GirlProfile.new()
	girl.id = StringName(id)
	girl.display_name = name
	girl.description = name if description.is_empty() else description
	girl.enabled = true
	girl.relationship_min = rel_min
	girl.relationship_start = 0
	girl.relationship_max = rel_max
	girl.difficulty_preset_id = StringName(difficulty_id)
	var pos: Array[StringName] = []
	for item in positives:
		pos.append(StringName(str(item)))
	girl.positive_tag_ids = pos
	girl.sync_negative_tags(_tags())
	return girl

func _girls() -> Array[GirlProfile]:
	return [
		_girl("alina", "Алина", "starter", 0, 5, ["politeness", "directness", "care", "generosity", "composure", "humor"]),
		_girl("marina", "Марина", "mid", 0, 5, ["care", "composure", "directness", "humor"], "держит спокойный тон и предпочитает ясную заботу без суеты"),
		_girl("girl_actress", "Актриса", "early", 0, 5, ["flattery", "audacity", "generosity", "status", "humor"], "любит внимание, эффектность, уверенность и человека, который умеет поддерживать ощущение шоу"),
		_girl("vika", "Вика", "early", 0, 5, ["audacity", "dominance", "risk", "humor", "cunning"]),
		_girl("dasha", "Даша", "mid", 0, 5, ["audacity", "risk", "humor", "dominance"], "любит дерзкие ставки и человека, который не боится задать тон"),
		_girl("girl_mine_boss", "Начальница шахты", "mid", 0, 5, ["directness", "dominance", "generosity", "composure"], "ценит конкретику, контроль ситуации и людей, которые не начинают суетиться под давлением"),
		_girl("katya", "Катя", "mid", 0, 5, ["directness", "risk", "humor", "cunning"], "любит спонтанность, игры, подколы и быстрые нестандартные решения"),
		_girl("girl_magazine_editor", "Редактор журнала", "mid", 0, 5, ["directness", "status", "composure", "cunning"], "профессионально оценивает людей и любит, когда собеседник умеет держать позицию и выбирать слова"),
		_girl("lera", "Лера", "mid", 0, 5, ["politeness", "flattery", "status", "composure"], "любит красивую спокойную подачу, хороший вкус и социальную уверенность"),
		_girl("kira", "Кира", "mid", 0, 10, ["directness", "audacity", "cunning", "composure"], "режет лишнее напрямую, проверяет наглостью и держит самообладание дольше, чем удобно"),
		_girl("olya", "Оля", "mid", 0, 5, ["generosity", "status", "care", "politeness"], "ценит щедрый жест, статус и вежливый уход за атмосферой"),
		_girl("girl_scientist", "Учёная", "mid", 0, 5, ["directness", "composure", "cunning", "care"], "ценит ясность, спокойствие, наблюдательность и необычные решения"),
		_girl("sonya", "Соня", "late", 0, 5, ["audacity", "risk", "humor"], "поздняя необязательная девушка, которая любит хаос, риск и человека, способного превратить свидание в историю"),
		_girl("nika", "Ника", "mid", 0, 5, ["cunning", "directness", "audacity", "composure"], "проверяет собеседника прямым ходом и обходным правилом"),
		_girl("rita", "Рита", "mid", 0, 5, ["status", "dominance", "generosity", "risk"], "любит дорогой жест, контроль сцены и риск напоказ"),
		_girl("eva", "Ева", "mid", 0, 10, ["status", "dominance", "risk", "generosity"], "занимает зал статусом, щедрым жестом и ставкой, которую нельзя тихо отменить"),
		_girl("girl_president", "Президент", "late", 0, 5, ["dominance", "status", "composure"], "максимально статусная ручная сюжетная цель; ценит контроль, положение и абсолютное самообладание"),
	]

func _rules() -> DateRules:
	var rules := DateRules.new()
	rules.opening_episode_count = 1
	rules.core_episode_count = 3
	rules.closing_episode_count = 1
	rules.base_moves_per_episode = 3
	rules.allow_situation_repeats = false
	rules.show_locked_unlockable_moves = true
	rules.opening_positive_score = 1
	rules.opening_negative_score = -1
	rules.core_positive_score = 1
	rules.core_negative_score = -1
	rules.closing_positive_score = 1
	rules.closing_negative_score = -1
	rules.reveal_tag_after_use = true
	rules.combo_required_distinct_success_tags = 3
	rules.combo_bonus_score = 1
	rules.combo_max_rewards_per_date = 1
	rules.apartment_unprepared_penalty = -1
	rules.min_distinct_base_tags_per_situation = 6
	return rules
