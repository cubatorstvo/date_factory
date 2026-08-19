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
	catalog.location_formats = _formats()
	catalog.locations = _locations()
	catalog.outfits = _outfits()
	catalog.secondary_rules = _secondary()
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
	_save_group(catalog.location_formats, "res://date_system/content/location_formats")
	_save_group(catalog.locations, "res://date_system/content/locations")
	_save_group(catalog.outfits, "res://date_system/content/outfits")
	_save_group(catalog.secondary_rules, "res://date_system/content/secondary")
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
	stat.max_level = 8
	return stat


func _stats() -> Array[ProgressionStat]:
	return [
		_stat("muscle", "Мышца", "Физическая сила."),
		_stat("appearance", "Внешность", "Внешняя привлекательность."),
		_stat("capital", "Капитал", "Деньги и ресурсы."),
		_stat("aura", "Аура", "Присутствие и давление молчанием."),
	]


func _format(id: String, name: String) -> LocationFormat:
	var format := LocationFormat.new()
	format.id = StringName(id)
	format.display_name = name
	format.description = name
	format.enabled = true
	return format


func _formats() -> Array[LocationFormat]:
	return [
		_format("calm", "Спокойное"),
		_format("entertainment", "Развлекательное"),
		_format("game", "Игровое"),
		_format("culture", "Культурное"),
		_format("unusual", "Необычное"),
	]


func _location(
	id: String,
	name: String,
	quality: int,
	mode: DateTypes.LocationPreferenceMode,
	format_id: String = "",
	apartment_quality: bool = false,
	apartment_prep: bool = false
) -> DateLocation:
	var location: DateLocation = DateLocation.new()
	location.id = StringName(id)
	location.display_name = name
	location.description = name
	location.enabled = true
	location.base_quality_bonus = quality
	location.preference_mode = mode
	location.location_format_id = StringName(format_id)
	location.uses_apartment_quality = apartment_quality
	location.uses_apartment_preparation = apartment_prep
	return location


func _locations() -> Array[DateLocation]:
	var neutral := DateTypes.LocationPreferenceMode.NEUTRAL
	var thematic := DateTypes.LocationPreferenceMode.THEMATIC
	return [
		_location("apartment", "Квартира", 0, neutral, "", true, true),
		_location("cafe", "Кафе", 1, neutral),
		_location("restaurant", "Ресторан", 2, neutral),
		_location("park", "Парк", 1, thematic, "calm"),
		_location("cinema", "Кинотеатр", 1, thematic, "entertainment"),
		_location("arcade", "Аркада", 1, thematic, "game"),
		_location("museum", "Музей", 1, thematic, "culture"),
		_location("planetarium", "Планетарий", 1, thematic, "unusual"),
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


func _secondary() -> Array[SecondaryRule]:
	var variety := SecondaryRule.new()
	variety.id = &"variety"
	variety.display_name = "ЛЮБИТ РАЗНООБРАЗИЕ"
	variety.description = "Получить +1 тремя различными Tags за свидание."
	variety.enabled = true
	variety.condition_type = DateTypes.SecondaryConditionType.DISTINCT_SUCCESS_TAGS
	variety.condition_parameters = {
		"required_count": 3,
		"counted_phases": [
			int(DateTypes.DatePhase.OPENING),
			int(DateTypes.DatePhase.CORE),
			int(DateTypes.DatePhase.CLOSING),
		],
	}
	variety.success_score = 2
	variety.failure_score = 0
	var demanding := SecondaryRule.new()
	demanding.id = &"demanding"
	demanding.display_name = "ТРЕБОВАТЕЛЬНАЯ"
	demanding.description = "Завершить CORE с 0 ошибками."
	demanding.enabled = true
	demanding.condition_type = DateTypes.SecondaryConditionType.NO_FAILURES
	demanding.condition_parameters = {
		"counted_phases": [int(DateTypes.DatePhase.CORE)],
	}
	demanding.success_score = 2
	demanding.failure_score = 0
	return [variety, demanding]


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
		_unlock_move("raise_stakes", "Поднять ставки", "capital", 6, [
			_mapping("money_request", "risk", "Предложить удвоить сумму после немедленного доказательства истории."),
			_mapping("spontaneous_bet", "risk", "Удвоить ставку и усложнить условие проигравшему."),
		]),
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
	negatives: Array,
	secondary_id: String,
	favorites: Array,
	favorite_outfits: Array
) -> GirlProfile:
	var girl: GirlProfile = GirlProfile.new()
	girl.id = StringName(id)
	girl.display_name = name
	girl.description = name
	girl.enabled = true
	girl.relationship_min = rel_min
	girl.relationship_start = 0
	girl.relationship_max = rel_max
	girl.difficulty_preset_id = StringName(difficulty_id)
	var pos: Array[StringName] = []
	for item in positives:
		pos.append(StringName(str(item)))
	girl.positive_tag_ids = pos
	var neg: Array[StringName] = []
	for item in negatives:
		neg.append(StringName(str(item)))
	girl.negative_tag_ids = neg
	girl.secondary_rule_id = StringName(secondary_id)
	var fav: Array[StringName] = []
	for item in favorites:
		fav.append(StringName(str(item)))
	girl.favorite_location_format_ids = fav
	var fav_outfits: Array[StringName] = []
	for item in favorite_outfits:
		fav_outfits.append(StringName(str(item)))
	girl.favorite_outfit_ids = fav_outfits
	return girl


func _girls() -> Array[GirlProfile]:
	return [
		_girl("alina", "Алина", "starter", -5, 5, ["politeness", "directness", "care", "generosity", "composure", "humor"], ["flattery", "audacity", "dominance", "risk", "status", "cunning"], "variety", ["calm", "culture"], ["business"]),
		_girl("vika", "Вика", "late", -10, 10, ["audacity", "dominance", "risk"], ["politeness", "directness", "flattery", "generosity", "status", "care", "humor", "composure", "cunning"], "demanding", ["game", "unusual"], ["luxury"]),
	]


func _rules() -> DateRules:
	var rules := DateRules.new()
	rules.opening_episode_count = 1
	rules.core_episode_count = 3
	rules.closing_episode_count = 1
	rules.base_moves_per_episode = 3
	rules.allow_situation_repeats = false
	rules.show_locked_unlockable_moves = true
	rules.opening_choice_score = 0
	rules.core_positive_score = 1
	rules.core_negative_score = -1
	rules.closing_positive_score = 1
	rules.closing_negative_score = -1
	rules.reveal_tag_after_use = true
	rules.reveal_secondary_after_first_completed_date = true
	rules.secondary_counted_phases = [int(DateTypes.DatePhase.CORE)]
	rules.location_preference_success = 1
	rules.location_preference_failure = -1
	rules.apartment_unprepared_penalty = -1
	rules.apartment_quality_min = 0
	rules.apartment_quality_max = 3
	rules.min_distinct_base_tags_per_situation = 6
	return rules
