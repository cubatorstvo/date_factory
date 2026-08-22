class_name SeedContentFactory
extends RefCounted

const TAG_SCRIPT := "res://date_system/content/date_tag.gd"
const MOVE_SCRIPT := "res://date_system/content/date_move.gd"
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
		_local_object("cafe__barista", "Бариста", "Бариста в кафе — заказ и выбор.", ["cafe__barista__lady_first", "cafe__barista__best_item"]),
		_local_object("cafe__board_games", "Настольные игры", "Полка настольных игр в кафе.", ["cafe__board_games__set_trap", "cafe__board_games__ridiculous_game"]),
		_local_object("cafe__window", "Окно", "Окно кафе, которое можно приоткрыть или распахнуть.", ["cafe__window__fresh_air", "cafe__window__open_to_street"]),
		_local_object("leisure_center__claw_machine", "Автомат-хватайка", "Автомат-хватайка с игрушками.", ["leisure_center__claw_machine__get_toy", "leisure_center__claw_machine__study_mechanism"]),
		_local_object("leisure_center__racing_arcade", "Гоночный автомат", "Гоночный автомат в центре досуга.", ["leisure_center__racing_arcade__max_difficulty", "leisure_center__racing_arcade__winner_wish"]),
		_local_object("leisure_center__air_hockey", "Аэрохоккей", "Стол аэрохоккея для соревнования.", ["leisure_center__air_hockey__play_seriously", "leisure_center__air_hockey__world_final"]),
		_local_object("leisure_center__prize_counter", "Стойка призов", "Стойка призов за жетоны.", ["leisure_center__prize_counter__gift_prize", "leisure_center__prize_counter__giant_trophy"]),
		_local_object("restaurant__waiter", "Официант", "Официант ресторана.", ["restaurant__waiter__lady_first", "restaurant__waiter__set_service_order"]),
		_local_object("restaurant__tasting_set", "Дегустационный сет", "Фирменный дегустационный сет.", ["restaurant__tasting_set__signature_set", "restaurant__tasting_set__trust_the_chef"]),
		_local_object("restaurant__live_music", "Живая музыка", "Живая музыка в зале ресторана.", ["restaurant__live_music__dedication", "restaurant__live_music__tip_performance"]),
		_local_object("restaurant__open_kitchen", "Открытая кухня", "Открытая кухня, где можно говорить с шефом.", ["restaurant__open_kitchen__adjust_for_her", "restaurant__open_kitchen__ask_chef"]),
		_local_object("apartment__plaid", "Плед", "Плед для уюта в квартире.", ["apartment__plaid__get_comfortable"]),
		_local_object("apartment__tv", "Телевизор", "Телевизор в квартире.", ["apartment__tv__ridiculous_show"]),
		_local_object("apartment__record_player", "Проигрыватель", "Проигрыватель в квартире.", ["apartment__record_player__quiet_music"]),
		_local_object("apartment__no_filter_cards", "Карточки «Без фильтров»", "Карточки с прямыми вопросами.", ["apartment__no_filter_cards__honest_question"]),
		_local_object("apartment__tea_set", "Чайный сервиз", "Чайный сервиз для аккуратной сервировки.", ["apartment__tea_set__serve_tea"]),
		_local_object("apartment__mini_fridge", "Мини-холодильник", "Мини-холодильник со запасом для гостя.", ["apartment__mini_fridge__best_stock"]),
		_local_object("apartment__large_mirror", "Большое зеркало", "Большое зеркало в квартире.", ["apartment__large_mirror__compliment_reflection"]),
		_local_object("apartment__collection_display", "Витрина коллекции", "Витрина с главным предметом коллекции.", ["apartment__collection_display__show_centerpiece"]),
		_local_object("apartment__karaoke", "Караоке", "Караоке-система в квартире.", ["apartment__karaoke__sing_first"]),
		_local_object("apartment__game_console", "Игровая консоль", "Игровая консоль для соревнования.", ["apartment__game_console__no_mercy"]),
		_local_object("apartment__darts", "Дартс", "Дартс с небольшой ставкой.", ["apartment__darts__hard_throw"]),
		_local_object("apartment__chess_table", "Шахматный столик", "Шахматный столик для короткой партии.", ["apartment__chess_table__prepared_trap"]),
	]

func _location(
	id: String,
	name: String,
	enabled: bool,
	apartment_prep: bool,
	local_object_ids: Array,
	price: int = 0
) -> DateVenue:
	var location: DateVenue = DateVenue.new()
	location.id = StringName(id)
	location.display_name = name
	location.description = name
	location.enabled = enabled
	location.uses_apartment_preparation = apartment_prep
	location.price = price
	var typed: Array[StringName] = []
	for item in local_object_ids:
		typed.append(StringName(str(item)))
	location.local_object_ids = typed
	return location

func _venues() -> Array[DateVenue]:
	return [
		_location("apartment", "Квартира", true, true, [], 0),
		_location("cafe", "Кафе", true, false, ["cafe__barista", "cafe__board_games", "cafe__window"], 20),
		_location("leisure_center", "Центр досуга", true, false, [
			"leisure_center__claw_machine",
			"leisure_center__racing_arcade",
			"leisure_center__air_hockey",
			"leisure_center__prize_counter",
		], 40),
		_location("restaurant", "Ресторан", true, false, [
			"restaurant__waiter",
			"restaurant__tasting_set",
			"restaurant__live_music",
			"restaurant__open_kitchen",
		], 60),
	]

func _outfit(id: String, name: String, price: int, stat_id: String = "", min_story_stage: int = 1, outfit_move_id: String = "", tier: int = 0) -> Outfit:
	var outfit := Outfit.new()
	outfit.id = StringName(id)
	outfit.display_name = name
	outfit.description = name
	outfit.enabled = true
	outfit.price = price
	outfit.stat_id = StringName(stat_id)
	outfit.stat_bonus = 1 if not stat_id.is_empty() else 0
	outfit.min_story_stage = min_story_stage
	outfit.tier = tier
	outfit.outfit_move_id = StringName(outfit_move_id)
	return outfit

func _outfits() -> Array[Outfit]:
	return [
		_outfit("casual", "Повседневная", 0, "", 1, "", 0),
		_outfit("sport", "Спортивный комплект", 250, "muscle", 2, "", 1),
		_outfit("stylish", "Стильный комплект", 250, "appearance", 2, "", 1),
		_outfit("business", "Деловой костюм", 250, "capital", 2, "", 1),
		_outfit("minimal_black", "Минималистичный чёрный образ", 250, "aura", 2, "", 1),
		_outfit("wrestling", "Борцовка", 700, "muscle", 3, "outfit_flex_bicep", 1),
		_outfit("magician", "Костюм фокусника", 700, "appearance", 3, "outfit_card_trick", 1),
		_outfit("luxury", "Роскошный костюм", 700, "capital", 3, "outfit_premium_card", 1),
		_outfit("leather_jacket", "Кожаная куртка", 700, "aura", 3, "outfit_dramatic_entrance", 1),
		_outfit("stunt", "Костюм каскадёра", 1200, "muscle", 4, "outfit_dangerous_idea", 1),
		_outfit("model", "Модельный образ", 1200, "appearance", 4, "outfit_beautiful_couple", 1),
		_outfit("philanthropist", "Образ филантропа", 1200, "capital", 4, "outfit_pay_extra", 1),
		_outfit("black_turtleneck", "Чёрная водолазка", 1200, "aura", 4, "outfit_silent_hold", 1),
	]

func _situation(id: String, name: String, text: String, phase: DateTypes.DatePhase, base_move_ids: Array = [], venue_ids: Array = []) -> DateSituation:
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
	var venues: Array[StringName] = []
	for venue_id in venue_ids:
		venues.append(StringName(str(venue_id)))
	situation.allowed_venue_ids = venues
	return situation



func _situations() -> Array[DateSituation]:
	return [
		_situation("appearance_question", "Ты не такой, как я представляла", "Девушка пару секунд рассматривает тебя. «Хм. Я тебя почему-то вообще другим представляла.»", DateTypes.DatePhase.OPENING, [
			"appearance_question__better_live",
			"appearance_question__more_surprises",
			"appearance_question__better_or_worse",
			"appearance_question__get_used_to_it",
			"appearance_question__scale",
			"appearance_question__update_image",
		]),
		_situation("awkward_silence", "Пауза затянулась", "Вы уже встретились, но первые десять секунд оба молчите. Пауза начинает жить собственной жизнью.", DateTypes.DatePhase.OPENING, [
			"awkward_silence__minute_of_silence",
			"awkward_silence__beautiful_pause",
			"awkward_silence__how_arrived",
			"awkward_silence__pleasant_start",
			"awkward_silence__professional_silence",
			"awkward_silence__awkward_question",
		]),
		_situation("why_me", "Почему именно я?", "Девушка спрашивает: «А почему ты вообще решил позвать именно меня?»", DateTypes.DatePhase.OPENING, [
			"why_me__most_interesting",
			"why_me__liked_invited",
			"why_me__same_level",
			"why_me__rare_quest",
			"why_me__theory",
			"why_me__good_evening",
		]),
		_situation("first_compliment", "Она делает первый комплимент", "Девушка неожиданно говорит: «Кстати, сегодня ты хорошо выглядишь.»", DateTypes.DatePhase.OPENING, [
			"first_compliment__simple_thanks",
			"first_compliment__i_know",
			"first_compliment__because_of_you",
			"first_compliment__official_review",
			"first_compliment__independent_expertise",
			"first_compliment__surprise",
		]),
		_situation("phone_reminder", "Телефон сдаёт тебя с потрохами", "Экран телефона загорается крупным напоминанием: «НЕ НАЧИНАТЬ С РАССКАЗА ПРО СЕБЯ». Девушка успевает прочитать.", DateTypes.DatePhase.OPENING, [
			"phone_reminder__technology_script",
			"phone_reminder__other_person",
			"phone_reminder__already_broke",
			"phone_reminder__ignore_evidence",
			"phone_reminder__organized_failures",
			"phone_reminder__do_exactly_that",
		]),
		_situation("takes_control", "Она берёт всё на себя", "С первых минут девушка начинает решать за двоих: что выбрать, куда двигаться и о чём говорить дальше.", DateTypes.DatePhase.OPENING, [
			"takes_control__take_one_decision",
			"takes_control__official_tour",
			"takes_control__your_route",
			"takes_control__if_convenient",
			"takes_control__split_decisions",
			"takes_control__decide_everything",
		]),
		_situation("money_request", "Кто платит?", "Возникает вопрос расходов. Девушка смотрит на тебя: «Ну и как делим?»", DateTypes.DatePhase.CORE, [
			"money_request__pay_all",
			"money_request__bill_is_mine",
			"money_request__next_expense_yours",
			"money_request__split_half",
			"money_request__your_preference",
			"money_request__i_decided",
		]),
		_situation("spontaneous_bet", "Спонтанное пари", "Девушка предлагает поспорить на небольшую ставку и ждёт твоей реакции.", DateTypes.DatePhase.CORE, [
			"spontaneous_bet__accept_blind",
			"spontaneous_bet__raise_stakes",
			"spontaneous_bet__negotiate_terms",
			"spontaneous_bet__set_prize",
			"spontaneous_bet__greatest_person",
			"spontaneous_bet__loser_gets_prize",
		]),
		_situation("rival_provocation", "Провокация соперника", "Другой мужчина вклинивается в разговор и явно пытается задеть тебя при девушке.", DateTypes.DatePhase.CORE, [
			"rival_provocation__put_in_place",
			"rival_provocation__no_reaction",
			"rival_provocation__repeat_it",
			"rival_provocation__you_are_interrupting",
			"rival_provocation__brave_attempt",
			"rival_provocation__opinion_has_no_weight",
		]),
		_situation("terrible_joke", "Ужасная шутка", "Девушка рассказывает откровенно плохую шутку. Пауза после панчлайна становится отдельным событием.", DateTypes.DatePhase.CORE, [
			"terrible_joke__worse_punchline",
			"terrible_joke__that_was_awful",
			"terrible_joke__laugh_with_her",
			"terrible_joke__delivery_saved_it",
			"terrible_joke__repeat_for_record",
			"terrible_joke__even_worse_joke",
		]),
		_situation("embarrassing_hobby", "Стыдное увлечение", "Девушка признаётся: «Ладно, только не смейся…» — и рассказывает про немного странное хобби.", DateTypes.DatePhase.CORE, [
			"embarrassing_hobby__ask_without_mockery",
			"embarrassing_hobby__hobby_suits_you",
			"embarrassing_hobby__strange_but_interesting",
			"embarrassing_hobby__thanks_for_telling",
			"embarrassing_hobby__elite_hobby",
			"embarrassing_hobby__help_with_hobby",
		]),
		_situation("stranger_flirts", "К ней подкатывает другой", "Посторонний человек начинает явно флиртовать с девушкой прямо во время вашего свидания.", DateTypes.DatePhase.CORE, [
			"stranger_flirts__she_is_with_me",
			"stranger_flirts__take_a_number",
			"stranger_flirts__let_her_handle",
			"stranger_flirts__rate_pickup",
			"stranger_flirts__you_are_interrupting",
			"stranger_flirts__if_she_wants",
		], ["cafe", "leisure_center", "restaurant"]),
		_situation("small_rule", "Маленькое нарушение", "Девушка замечает формальное ограничение и предлагает слегка его обойти ради удобства или интереса.", DateTypes.DatePhase.CORE, [
			"small_rule__agree_immediately",
			"small_rule__follow_rule",
			"small_rule__legal_loophole",
			"small_rule__charm_staff",
			"small_rule__check_problem",
			"small_rule__pay_normal_option",
		], ["cafe", "leisure_center", "restaurant"]),
		_situation("small_lie", "Маленькая ложь", "Девушка признаётся, что немного приукрасила один факт о себе при знакомстве.", DateTypes.DatePhase.CORE, [
			"small_lie__why_lied",
			"small_lie__great_betrayal",
			"small_lie__no_more_tricks",
			"small_lie__move_on",
			"small_lie__value_confession",
			"small_lie__press_service",
		]),
		_situation("friends_dilemma", "Чужая проблема", "Девушка рассказывает про подругу, которая соврала человеку «ради его же блага», и спрашивает, нормально ли это.", DateTypes.DatePhase.CORE, [
			"friends_dilemma__can_understand",
			"friends_dilemma__lie_is_lie",
			"friends_dilemma__ask_the_person",
			"friends_dilemma__useful_lie",
			"friends_dilemma__truth_and_responsibility",
			"friends_dilemma__fix_consequences",
		]),
		_situation("staff_conflict", "Она спорит с персоналом", "Возникает небольшая проблема с обслуживанием, и девушка начинает разбираться с сотрудником заведения.", DateTypes.DatePhase.CORE, [
			"staff_conflict__explain_problem",
			"staff_conflict__demand_fix",
			"staff_conflict__lower_temperature",
			"staff_conflict__what_would_satisfy",
			"staff_conflict__call_manager",
			"staff_conflict__cover_difference",
		], ["cafe", "leisure_center", "restaurant"]),
		_situation("compatibility_test", "Тест на совместимость", "Девушка вспоминает тест на совместимость, который недавно нашла: «Если мы застрянем в лифте на три часа, кто первым начнёт бесить другого?»", DateTypes.DatePhase.CORE, [
			"compatibility_test__annoy_on_purpose",
			"compatibility_test__you_annoy_me",
			"compatibility_test__annoyance_schedule",
			"compatibility_test__test_it",
			"compatibility_test__two_hours",
			"compatibility_test__elevator_rules",
		]),
		_situation("lost_in_hand", "Потерянная вещь", "Девушка начинает искать небольшую вещь. Через несколько секунд становится очевидно, что она всё это время держит её в руке.", DateTypes.DatePhase.CORE, [
			"lost_in_hand__search_together",
			"lost_in_hand__point_softly",
			"lost_in_hand__what_in_hand",
			"lost_in_hand__wait_for_notice",
			"lost_in_hand__international_search",
			"lost_in_hand__gone_forever",
		]),
		_situation("mistaken_married", "Вас приняли за супругов", "Незнакомец уверенно замечает: «Сразу видно — вы уже лет десять вместе.»", DateTypes.DatePhase.CORE, [
			"mistaken_married__eleven_hard_years",
			"mistaken_married__still_tolerates",
			"mistaken_married__with_her_possible",
			"mistaken_married__clarify_first_date",
			"mistaken_married__what_gave_us_away",
			"mistaken_married__under_control",
		], ["cafe", "leisure_center", "restaurant"]),
		_situation("take_photo", "Сфоткаемся?", "Девушка предлагает сделать совместную фотографию.", DateTypes.DatePhase.CORE, [
			"take_photo__good_with_you",
			"take_photo__confident_pose",
			"take_photo__how_you_want",
			"take_photo__luxury_frame",
			"take_photo__normal_photo",
			"take_photo__stupid_photo",
		]),
		_situation("big_money", "Большие деньги", "Девушка спрашивает: «Представь, завтра у тебя появляется очень большая сумма денег. Что делаешь первым?»", DateTypes.DatePhase.CORE, [
			"big_money__give_to_close_people",
			"big_money__visible_from_space",
			"big_money__x10_project",
			"big_money__secure_people",
			"big_money__money_makes_money",
			"big_money__invest_in_evening",
		]),
		_situation("choose_for_me", "Выбери за меня", "Девушка просит тебя принять за неё небольшое решение.", DateTypes.DatePhase.CORE, [
			"choose_for_me__choose_immediately",
			"choose_for_me__suspicious_destiny",
			"choose_for_me__two_questions",
			"choose_for_me__choose_and_explain",
			"choose_for_me__choose_without_arguing",
			"choose_for_me__better_for_her",
		]),
		_situation("friend_call", "Звонит её подруга", "Девушке звонит подруга, понимает, что та на свидании, и просит: «А ну дай его сюда на секунду.» Тебе передают разговор.", DateTypes.DatePhase.CORE, [
			"friend_call__introduce",
			"friend_call__board_interview",
			"friend_call__ask_weaknesses",
			"friend_call__she_is_fine",
			"friend_call__looks_great",
			"friend_call__interview_passed",
		]),
		_situation("lights_out", "Выключается свет", "Свет внезапно гаснет. На несколько секунд место свидания оказывается в темноте.", DateTypes.DatePhase.CORE, [
			"lights_out__romance_mode",
			"lights_out__are_you_okay",
			"lights_out__continue_in_dark",
			"lights_out__take_charge",
			"lights_out__practical_solution",
			"lights_out__give_light",
		]),
		_situation("date_verdict", "Ну и как тебе вечер?", "Перед расставанием девушка спрашивает: «Ну и как тебе сегодняшний вечер?»", DateTypes.DatePhase.CLOSING, [
			"date_verdict__liked_it",
			"date_verdict__best_part_you",
			"date_verdict__were_you_comfortable",
			"date_verdict__good_no_analysis",
			"date_verdict__premium_event",
			"date_verdict__glad_spent_time",
		]),
		_situation("see_again", "Увидимся ещё?", "Девушка спрашивает: «Ну… повторим когда-нибудь?»", DateTypes.DatePhase.CLOSING, [
			"see_again__yes_again",
			"see_again__after_company",
			"see_again__if_you_want",
			"see_again__tomorrow_free",
			"see_again__repeat",
			"see_again__something_different",
		]),
		_situation("honest_question", "Один честный вопрос", "Девушка задерживается перед уходом: «Можно честный вопрос? Ты часто делаешь вид, что увереннее, чем есть?»", DateTypes.DatePhase.CLOSING, [
			"honest_question__sometimes_yes",
			"honest_question__why_important",
			"honest_question__confidence_skill",
			"honest_question__when_useful",
			"honest_question__honest_thanks",
			"honest_question__expensive_trim",
		]),
		_situation("lost_wallet", "Чужой кошелёк", "На выходе вы находите чужой кошелёк. Внутри есть деньги и данные владельца.", DateTypes.DatePhase.CLOSING, [
			"lost_wallet__give_to_staff",
			"lost_wallet__find_owner",
			"lost_wallet__call_business_card",
			"lost_wallet__pay_delivery",
			"lost_wallet__return_it",
			"lost_wallet__i_will_handle",
		], ["cafe", "leisure_center", "restaurant"]),
		_situation("simple_goodbye", "Просто «пока»", "Встреча закончилась. Девушка совершенно обычно говорит: «Ладно. Пока.»", DateTypes.DatePhase.CLOSING, [
			"simple_goodbye__good_evening",
			"simple_goodbye__write_when_home",
			"simple_goodbye__final_compliment",
			"simple_goodbye__dont_miss_me",
			"simple_goodbye__see_you",
			"simple_goodbye__theatrical_bow",
		]),
		_situation("sudden_rain", "Начинается дождь", "Вы уже собираетесь расходиться, когда внезапно начинается сильный дождь.", DateTypes.DatePhase.CLOSING, [
			"sudden_rain__give_umbrella",
			"sudden_rain__call_taxi",
			"sudden_rain__wait_it_out",
			"sudden_rain__walk_in_rain",
			"sudden_rain__car_to_door",
			"sudden_rain__run_for_cover",
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
	move.fixed_positive_result_text = _base_positive_result(tag_id)
	move.fixed_negative_result_text = _base_negative_result(tag_id)
	return move


func _base_positive_result(tag_id: String) -> String:
	match tag_id:
		"politeness":
			return "Ей нравится твоя корректность."
		"directness":
			return "Прямота ей нравится."
		"care":
			return "Она ценит заботу."
		"generosity":
			return "Щедрый жест ей нравится."
		"composure":
			return "Спокойствие ей нравится."
		"humor":
			return "Она смеётся — шутка попала в её вкус."
		"audacity":
			return "Наглость её цепляет."
		"dominance":
			return "Уверенный контроль ей нравится."
		"risk":
			return "Ей нравится готовность рискнуть."
		"cunning":
			return "Она оценивает находчивость."
		"flattery":
			return "Лесть попадает в цель."
		"status":
			return "Демонстрация статуса производит впечатление."
		_:
			return ""


func _base_negative_result(tag_id: String) -> String:
	match tag_id:
		"politeness":
			return "Ей кажется, что ты слишком церемонишься."
		"directness":
			return "Прямота кажется ей грубой."
		"care":
			return "Забота кажется ей лишней."
		"generosity":
			return "Она воспринимает щедрость как лишнее давление."
		"composure":
			return "Спокойствие кажется ей безразличием."
		"humor":
			return "Шутка ей не заходит."
		"audacity":
			return "Наглость её раздражает."
		"dominance":
			return "Ей не нравится, что ты командуешь."
		"risk":
			return "Она считает риск лишним."
		"cunning":
			return "Хитрость ей не нравится."
		"flattery":
			return "Лесть кажется ей натянутой."
		"status":
			return "Пафос её раздражает."
		_:
			return ""



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
	move.max_uses_per_date = 1
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
		_base_move("appearance_question__better_live", "Уверенно улыбнуться: «Главное, что вживую лучше.»", "flattery", "Уверенно улыбнуться: «Главное, что вживую лучше.»"),
		_base_move("appearance_question__more_surprises", "«Дай минуту — стану ещё неожиданнее.»", "audacity", "«Дай минуту — стану ещё неожиданнее.»"),
		_base_move("appearance_question__better_or_worse", "Спросить прямо: «Лучше или хуже?»", "directness", "Спросить прямо: «Лучше или хуже?»"),
		_base_move("appearance_question__get_used_to_it", "Спокойно ответить: «Ничего, привыкнешь.»", "composure", "Спокойно ответить: «Ничего, привыкнешь.»"),
		_base_move("appearance_question__scale", "«Фотографии плохо передают масштаб.»", "status", "«Фотографии плохо передают масштаб.»"),
		_base_move("appearance_question__update_image", "«Тогда обнови представление.»", "dominance", "«Тогда обнови представление.»"),
		_base_move("awkward_silence__minute_of_silence", "«Предлагаю считать это минутой молчания по нашей неловкости.»", "humor", "«Предлагаю считать это минутой молчания по нашей неловкости.»"),
		_base_move("awkward_silence__beautiful_pause", "«Я просто ждал, когда ты первой нарушишь красивую паузу.»", "flattery", "«Я просто ждал, когда ты первой нарушишь красивую паузу.»"),
		_base_move("awkward_silence__how_arrived", "«Ну что, как добралась?»", "politeness", "«Ну что, как добралась?»"),
		_base_move("awkward_silence__pleasant_start", "«Хочешь, я организую нам что-нибудь приятное для разгона?»", "generosity", "«Хочешь, я организую нам что-нибудь приятное для разгона?»"),
		_base_move("awkward_silence__professional_silence", "«Ну что, будем молчать профессионально или уже знакомиться?»", "audacity", "«Ну что, будем молчать профессионально или уже знакомиться?»"),
		_base_move("awkward_silence__awkward_question", "«Могу начать сразу с самого неловкого вопроса.»", "risk", "«Могу начать сразу с самого неловкого вопроса.»"),
		_base_move("why_me__most_interesting", "«Потому что ты показалась самой интересной.»", "flattery", "«Потому что ты показалась самой интересной.»"),
		_base_move("why_me__liked_invited", "«Понравилась. Позвал.»", "directness", "«Понравилась. Позвал.»"),
		_base_move("why_me__same_level", "«Показалась человеком моего уровня. Решил проверить.»", "status", "«Показалась человеком моего уровня. Решил проверить.»"),
		_base_move("why_me__rare_quest", "«Мне выпал редкий квест. Решил не отказываться.»", "humor", "«Мне выпал редкий квест. Решил не отказываться.»"),
		_base_move("why_me__theory", "«Хотел проверить одну теорию о тебе.»", "cunning", "«Хотел проверить одну теорию о тебе.»"),
		_base_move("why_me__good_evening", "«Хотел сделать тебе хороший вечер.»", "generosity", "«Хотел сделать тебе хороший вечер.»"),
		_base_move("first_compliment__simple_thanks", "«Спасибо. Правда приятно.»", "politeness", "«Спасибо. Правда приятно.»"),
		_base_move("first_compliment__i_know", "«Знаю. Но от тебя звучит особенно убедительно.»", "audacity", "«Знаю. Но от тебя звучит особенно убедительно.»"),
		_base_move("first_compliment__because_of_you", "«После тебя трудно выглядеть плохо.»", "flattery", "«После тебя трудно выглядеть плохо.»"),
		_base_move("first_compliment__official_review", "«Запишем это как официальный положительный отзыв.»", "humor", "«Запишем это как официальный положительный отзыв.»"),
		_base_move("first_compliment__independent_expertise", "«Наконец-то независимая экспертиза подтвердила.»", "status", "«Наконец-то независимая экспертиза подтвердила.»"),
		_base_move("first_compliment__surprise", "«Спасибо. За такое с меня приятный сюрприз сегодня.»", "generosity", "«Спасибо. За такое с меня приятный сюрприз сегодня.»"),
		_base_move("phone_reminder__technology_script", "«Отлично. Техника уже пишет мне сценарий свидания.»", "humor", "«Отлично. Техника уже пишет мне сценарий свидания.»"),
		_base_move("phone_reminder__other_person", "«Это напоминание вообще для другого человека.»", "cunning", "«Это напоминание вообще для другого человека.»"),
		_base_move("phone_reminder__already_broke", "«Да. И я уже нарушил инструкцию.»", "audacity", "«Да. И я уже нарушил инструкцию.»"),
		_base_move("phone_reminder__ignore_evidence", "«Игнорируем улику и продолжаем.»", "composure", "«Игнорируем улику и продолжаем.»"),
		_base_move("phone_reminder__organized_failures", "«У меня даже провалы организованы заранее.»", "status", "«У меня даже провалы организованы заранее.»"),
		_base_move("phone_reminder__do_exactly_that", "«Раз всё вскрылось, начну именно с рассказа о себе.»", "risk", "«Раз всё вскрылось, начну именно с рассказа о себе.»"),
		_base_move("takes_control__take_one_decision", "«Стоп. Одно решение теперь моё.»", "dominance", "«Стоп. Одно решение теперь моё.»"),
		_base_move("takes_control__official_tour", "«Отлично, я официально на экскурсии. Веди.»", "humor", "«Отлично, я официально на экскурсии. Веди.»"),
		_base_move("takes_control__your_route", "«Ладно, сегодня твой маршрут.»", "composure", "«Ладно, сегодня твой маршрут.»"),
		_base_move("takes_control__if_convenient", "«Если тебе так удобнее — я не против.»", "politeness", "«Если тебе так удобнее — я не против.»"),
		_base_move("takes_control__split_decisions", "«Договоримся: половину выбираешь ты, половину — я.»", "cunning", "«Договоримся: половину выбираешь ты, половину — я.»"),
		_base_move("takes_control__decide_everything", "«Сегодня вообще всё решай ты. Проверим, куда попадём.»", "risk", "«Сегодня вообще всё решай ты. Проверим, куда попадём.»"),
		_base_move("money_request__pay_all", "«Я оплачу всё.»", "generosity", "«Я оплачу всё.»"),
		_base_move("money_request__bill_is_mine", "«Счёт мой. Даже обсуждать нечего.»", "status", "«Счёт мой. Даже обсуждать нечего.»"),
		_base_move("money_request__next_expense_yours", "«Сейчас плачу я, следующий расход — на тебе.»", "cunning", "«Сейчас плачу я, следующий расход — на тебе.»"),
		_base_move("money_request__split_half", "«Пополам.»", "directness", "«Пополам.»"),
		_base_move("money_request__your_preference", "«Как тебе удобнее разделить?»", "politeness", "«Как тебе удобнее разделить?»"),
		_base_move("money_request__i_decided", "«Сегодня плачу я. Решено.»", "dominance", "«Сегодня плачу я. Решено.»"),
		_base_move("spontaneous_bet__accept_blind", "Согласиться, даже не уточняя условия.", "risk", "Согласиться, даже не уточняя условия."),
		_base_move("spontaneous_bet__raise_stakes", "Сразу поднять ставку.", "audacity", "Сразу поднять ставку."),
		_base_move("spontaneous_bet__negotiate_terms", "Сначала выторговать условия в свою пользу.", "cunning", "Сначала выторговать условия в свою пользу."),
		_base_move("spontaneous_bet__set_prize", "Самому назначить, что получает победитель.", "dominance", "Самому назначить, что получает победитель."),
		_base_move("spontaneous_bet__greatest_person", "«Проигравший официально признаёт победителя величайшим человеком вечера.»", "humor", "«Проигравший официально признаёт победителя величайшим человеком вечера.»"),
		_base_move("spontaneous_bet__loser_gets_prize", "«Если проиграешь, всё равно получишь приз.»", "generosity", "«Если проиграешь, всё равно получишь приз.»"),
		_base_move("rival_provocation__put_in_place", "Жёстко поставить его на место.", "dominance", "Жёстко поставить его на место."),
		_base_move("rival_provocation__no_reaction", "Вообще не дать ему реакции.", "composure", "Вообще не дать ему реакции."),
		_base_move("rival_provocation__repeat_it", "Подойти ближе: «Повтори.»", "audacity", "Подойти ближе: «Повтори.»"),
		_base_move("rival_provocation__you_are_interrupting", "Сказать прямо: «Ты мешаешь. Иди дальше.»", "directness", "Сказать прямо: «Ты мешаешь. Иди дальше.»"),
		_base_move("rival_provocation__brave_attempt", "Похвалить его за очень смелую попытку испортить вечер.", "humor", "Похвалить его за очень смелую попытку испортить вечер."),
		_base_move("rival_provocation__opinion_has_no_weight", "Дать понять, что его мнение здесь ничего не весит.", "status", "Дать понять, что его мнение здесь ничего не весит."),
		_base_move("terrible_joke__worse_punchline", "Договорить панчлайн ещё хуже.", "humor", "Договорить панчлайн ещё хуже."),
		_base_move("terrible_joke__that_was_awful", "Честно сказать: «Это было ужасно.»", "directness", "Честно сказать: «Это было ужасно.»"),
		_base_move("terrible_joke__laugh_with_her", "Засмеяться просто потому, что ей самой смешно.", "care", "Засмеяться просто потому, что ей самой смешно."),
		_base_move("terrible_joke__delivery_saved_it", "«Твоя подача спасла эту шутку.»", "flattery", "«Твоя подача спасла эту шутку.»"),
		_base_move("terrible_joke__repeat_for_record", "«Повтори. Хочу убедиться, что услышал правильно.»", "audacity", "«Повтори. Хочу убедиться, что услышал правильно.»"),
		_base_move("terrible_joke__even_worse_joke", "Ответить ещё более плохой шуткой.", "risk", "Ответить ещё более плохой шуткой."),
		_base_move("embarrassing_hobby__ask_without_mockery", "Расспросить о хобби без стёба.", "care", "Расспросить о хобби без стёба."),
		_base_move("embarrassing_hobby__hobby_suits_you", "«Тебе даже такое хобби идёт.»", "flattery", "«Тебе даже такое хобби идёт.»"),
		_base_move("embarrassing_hobby__strange_but_interesting", "«Звучит странно. Но интересно.»", "directness", "«Звучит странно. Но интересно.»"),
		_base_move("embarrassing_hobby__thanks_for_telling", "Поблагодарить, что она рассказала.", "politeness", "Поблагодарить, что она рассказала."),
		_base_move("embarrassing_hobby__elite_hobby", "Объявить её хобби неожиданно элитарным занятием.", "status", "Объявить её хобби неожиданно элитарным занятием."),
		_base_move("embarrassing_hobby__help_with_hobby", "Предложить как-нибудь достать что-нибудь полезное для её хобби.", "generosity", "Предложить как-нибудь достать что-нибудь полезное для её хобби."),
		_base_move("stranger_flirts__she_is_with_me", "Вклиниться: «Она сейчас со мной.»", "dominance", "Вклиниться: «Она сейчас со мной.»"),
		_base_move("stranger_flirts__take_a_number", "Предложить незнакомцу взять номерок.", "humor", "Предложить незнакомцу взять номерок."),
		_base_move("stranger_flirts__let_her_handle", "Спокойно дать девушке самой разобраться.", "composure", "Спокойно дать девушке самой разобраться."),
		_base_move("stranger_flirts__rate_pickup", "Поставить незнакомцу оценку за подкат.", "audacity", "Поставить незнакомцу оценку за подкат."),
		_base_move("stranger_flirts__you_are_interrupting", "Сказать прямо: «Ты мешаешь нашему свиданию.»", "directness", "Сказать прямо: «Ты мешаешь нашему свиданию.»"),
		_base_move("stranger_flirts__if_she_wants", "Отойти на шаг: «Если ей интересно — продолжайте.»", "risk", "Отойти на шаг: «Если ей интересно — продолжайте.»"),
		_base_move("small_rule__agree_immediately", "Согласиться сразу.", "risk", "Согласиться сразу."),
		_base_move("small_rule__follow_rule", "Предложить всё-таки соблюдать правило.", "politeness", "Предложить всё-таки соблюдать правило."),
		_base_move("small_rule__legal_loophole", "Найти обход, который формально разрешён.", "cunning", "Найти обход, который формально разрешён."),
		_base_move("small_rule__charm_staff", "Предложить сначала обаятельно договориться с тем, кто следит за правилом.", "flattery", "Предложить сначала обаятельно договориться с тем, кто следит за правилом."),
		_base_move("small_rule__check_problem", "Спокойно проверить, действительно ли правило сейчас кому-то мешает.", "composure", "Спокойно проверить, действительно ли правило сейчас кому-то мешает."),
		_base_move("small_rule__pay_normal_option", "Оплатить нормальный вариант, который решает вопрос без нарушения.", "generosity", "Оплатить нормальный вариант, который решает вопрос без нарушения."),
		_base_move("small_lie__why_lied", "Спросить прямо, зачем она соврала.", "directness", "Спросить прямо, зачем она соврала."),
		_base_move("small_lie__great_betrayal", "Объявить это крупнейшим предательством вечера.", "humor", "Объявить это крупнейшим предательством вечера."),
		_base_move("small_lie__no_more_tricks", "Сказать, что дальше лучше без таких фокусов.", "dominance", "Сказать, что дальше лучше без таких фокусов."),
		_base_move("small_lie__move_on", "Спокойно принять признание и двигаться дальше.", "composure", "Спокойно принять признание и двигаться дальше."),
		_base_move("small_lie__value_confession", "Сказать, что ценишь, что она призналась.", "politeness", "Сказать, что ценишь, что она призналась."),
		_base_move("small_lie__press_service", "«У меня тоже есть пресс-служба, которая иногда улучшает факты.»", "status", "«У меня тоже есть пресс-служба, которая иногда улучшает факты.»"),
		_base_move("friends_dilemma__can_understand", "«Если она действительно пыталась защитить человека, я могу понять.»", "care", "«Если она действительно пыталась защитить человека, я могу понять.»"),
		_base_move("friends_dilemma__lie_is_lie", "«Ложь остаётся ложью.»", "directness", "«Ложь остаётся ложью.»"),
		_base_move("friends_dilemma__ask_the_person", "«Сначала спросил бы самого человека, чего он хочет.»", "politeness", "«Сначала спросил бы самого человека, чего он хочет.»"),
		_base_move("friends_dilemma__useful_lie", "«Иногда правильная ложь полезнее неправильной правды.»", "cunning", "«Иногда правильная ложь полезнее неправильной правды.»"),
		_base_move("friends_dilemma__truth_and_responsibility", "«Надо было сказать правду и взять ответственность за последствия.»", "dominance", "«Надо было сказать правду и взять ответственность за последствия.»"),
		_base_move("friends_dilemma__fix_consequences", "«Если уж соврала ради него — потом помоги исправить последствия.»", "generosity", "«Если уж соврала ради него — потом помоги исправить последствия.»"),
		_base_move("staff_conflict__explain_problem", "Спокойно объяснить сотруднику, в чём проблема.", "politeness", "Спокойно объяснить сотруднику, в чём проблема."),
		_base_move("staff_conflict__demand_fix", "Поддержать её и потребовать исправить ситуацию.", "dominance", "Поддержать её и потребовать исправить ситуацию."),
		_base_move("staff_conflict__lower_temperature", "Снизить градус и дождаться нормального решения.", "composure", "Снизить градус и дождаться нормального решения."),
		_base_move("staff_conflict__what_would_satisfy", "Спросить девушку, какой исход её реально устроит.", "care", "Спросить девушку, какой исход её реально устроит."),
		_base_move("staff_conflict__call_manager", "Попросить менеджера и закрыть вопрос без долгой сцены.", "status", "Попросить менеджера и закрыть вопрос без долгой сцены."),
		_base_move("staff_conflict__cover_difference", "Предложить самому покрыть мелкую разницу и продолжить вечер.", "generosity", "Предложить самому покрыть мелкую разницу и продолжить вечер."),
		_base_move("compatibility_test__annoy_on_purpose", "«Я начну бесить специально, чтобы не тянуть.»", "humor", "«Я начну бесить специально, чтобы не тянуть.»"),
		_base_move("compatibility_test__you_annoy_me", "«Скорее всего ты меня.»", "directness", "«Скорее всего ты меня.»"),
		_base_move("compatibility_test__annoyance_schedule", "«Составлю график раздражения, чтобы мы не пересекались.»", "cunning", "«Составлю график раздражения, чтобы мы не пересекались.»"),
		_base_move("compatibility_test__test_it", "«Предлагаю однажды проверить экспериментально.»", "risk", "«Предлагаю однажды проверить экспериментально.»"),
		_base_move("compatibility_test__two_hours", "«Ты первые два часа точно не успеешь мне надоесть.»", "flattery", "«Ты первые два часа точно не успеешь мне надоесть.»"),
		_base_move("compatibility_test__elevator_rules", "«Через десять минут я введу правила поведения в лифте.»", "dominance", "«Через десять минут я введу правила поведения в лифте.»"),
		_base_move("lost_in_hand__search_together", "Начать искать вместе, старательно не замечая предмет в её руке.", "humor", "Начать искать вместе, старательно не замечая предмет в её руке."),
		_base_move("lost_in_hand__point_softly", "Мягко показать на предмет: «Кажется, он уже нашёлся.»", "care", "Мягко показать на предмет: «Кажется, он уже нашёлся.»"),
		_base_move("lost_in_hand__what_in_hand", "Спросить: «А что у тебя сейчас в руке?»", "cunning", "Спросить: «А что у тебя сейчас в руке?»"),
		_base_move("lost_in_hand__wait_for_notice", "Подождать пару секунд, пока она сама заметит.", "composure", "Подождать пару секунд, пока она сама заметит."),
		_base_move("lost_in_hand__international_search", "Предложить объявить предмет в международный розыск.", "audacity", "Предложить объявить предмет в международный розыск."),
		_base_move("lost_in_hand__gone_forever", "С серьёзным лицом сказать, что вещь, похоже, ушла навсегда.", "risk", "С серьёзным лицом сказать, что вещь, похоже, ушла навсегда."),
		_base_move("mistaken_married__eleven_hard_years", "Подыграть: «Одиннадцать тяжёлых лет.»", "humor", "Подыграть: «Одиннадцать тяжёлых лет.»"),
		_base_move("mistaken_married__still_tolerates", "Кивнуть: «И всё ещё терпит меня.»", "audacity", "Кивнуть: «И всё ещё терпит меня.»"),
		_base_move("mistaken_married__with_her_possible", "«С такой — можно и поверить.»", "flattery", "«С такой — можно и поверить.»"),
		_base_move("mistaken_married__clarify_first_date", "Вежливо уточнить, что вы пока только на свидании.", "politeness", "Вежливо уточнить, что вы пока только на свидании."),
		_base_move("mistaken_married__what_gave_us_away", "Спросить незнакомца, что именно вас выдало.", "cunning", "Спросить незнакомца, что именно вас выдало."),
		_base_move("mistaken_married__under_control", "Уверенно кивнуть: «Да. И у нас всё под контролем.»", "dominance", "Уверенно кивнуть: «Да. И у нас всё под контролем.»"),
		_base_move("take_photo__good_with_you", "«С тобой кадр и так получится удачным.»", "flattery", "«С тобой кадр и так получится удачным.»"),
		_base_move("take_photo__confident_pose", "Принять максимально самоуверенную позу.", "audacity", "Принять максимально самоуверенную позу."),
		_base_move("take_photo__how_you_want", "Сначала спросить, как ей самой хочется выглядеть на фото.", "care", "Сначала спросить, как ей самой хочется выглядеть на фото."),
		_base_move("take_photo__luxury_frame", "Сделать максимально пафосный совместный кадр.", "status", "Сделать максимально пафосный совместный кадр."),
		_base_move("take_photo__normal_photo", "Спокойно согласиться на обычное фото.", "politeness", "Спокойно согласиться на обычное фото."),
		_base_move("take_photo__stupid_photo", "Предложить сделать нарочно максимально дурацкий кадр.", "risk", "Предложить сделать нарочно максимально дурацкий кадр."),
		_base_move("big_money__give_to_close_people", "«Часть сразу отдам близким.»", "generosity", "«Часть сразу отдам близким.»"),
		_base_move("big_money__visible_from_space", "«Куплю что-нибудь, что видно из космоса.»", "status", "«Куплю что-нибудь, что видно из космоса.»"),
		_base_move("big_money__x10_project", "«Вложу в проект, который может сделать x10 или исчезнуть.»", "risk", "«Вложу в проект, который может сделать x10 или исчезнуть.»"),
		_base_move("big_money__secure_people", "«Сначала обеспечу тех, за кого отвечаю.»", "care", "«Сначала обеспечу тех, за кого отвечаю.»"),
		_base_move("big_money__money_makes_money", "«Сначала заставлю деньги заработать ещё денег.»", "cunning", "«Сначала заставлю деньги заработать ещё денег.»"),
		_base_move("big_money__invest_in_evening", "«Прямо сейчас вложил бы часть в хороший вечер с тобой.»", "flattery", "«Прямо сейчас вложил бы часть в хороший вечер с тобой.»"),
		_base_move("choose_for_me__choose_immediately", "Выбрать сразу, без голосования.", "dominance", "Выбрать сразу, без голосования."),
		_base_move("choose_for_me__suspicious_destiny", "Выбрать самый подозрительный вариант и объявить это знаком судьбы.", "humor", "Выбрать самый подозрительный вариант и объявить это знаком судьбы."),
		_base_move("choose_for_me__two_questions", "Задать ей два вопроса и вычислить, чего она на самом деле хочет.", "cunning", "Задать ей два вопроса и вычислить, чего она на самом деле хочет."),
		_base_move("choose_for_me__choose_and_explain", "Выбрать и сразу объяснить почему.", "directness", "Выбрать и сразу объяснить почему."),
		_base_move("choose_for_me__choose_without_arguing", "Спокойно выбрать и не спорить, если она потом передумает.", "composure", "Спокойно выбрать и не спорить, если она потом передумает."),
		_base_move("choose_for_me__better_for_her", "Выбрать вариант, который лучше для неё, даже если тебе менее удобно.", "generosity", "Выбрать вариант, который лучше для неё, даже если тебе менее удобно."),
		_base_move("friend_call__introduce", "Вежливо представиться.", "politeness", "Вежливо представиться."),
		_base_move("friend_call__board_interview", "Говорить так, будто проходишь собеседование в совет директоров.", "status", "Говорить так, будто проходишь собеседование в совет директоров."),
		_base_move("friend_call__ask_weaknesses", "Сразу спросить подругу, какие у девушки слабые места.", "audacity", "Сразу спросить подругу, какие у девушки слабые места."),
		_base_move("friend_call__she_is_fine", "Сказать, что у её подруги всё хорошо и можно не переживать.", "care", "Сказать, что у её подруги всё хорошо и можно не переживать."),
		_base_move("friend_call__looks_great", "Сообщить, что её подруга сегодня выглядит великолепно.", "flattery", "Сообщить, что её подруга сегодня выглядит великолепно."),
		_base_move("friend_call__interview_passed", "Закончить: «Всё, собеседование прошёл. Возвращаю телефон.»", "dominance", "Закончить: «Всё, собеседование прошёл. Возвращаю телефон.»"),
		_base_move("lights_out__romance_mode", "Объявить, что вечер официально перешёл в режим романтики.", "humor", "Объявить, что вечер официально перешёл в режим романтики."),
		_base_move("lights_out__are_you_okay", "Сразу спросить, всё ли у неё нормально.", "care", "Сразу спросить, всё ли у неё нормально."),
		_base_move("lights_out__continue_in_dark", "Предложить продолжить свидание в полной темноте.", "risk", "Предложить продолжить свидание в полной темноте."),
		_base_move("lights_out__take_charge", "Взять на себя поиск света или выхода.", "dominance", "Взять на себя поиск света или выхода."),
		_base_move("lights_out__practical_solution", "Быстро найти практическое решение: щиток, фонарь или персонал.", "cunning", "Быстро найти практическое решение: щиток, фонарь или персонал."),
		_base_move("lights_out__give_light", "Уступить ей единственный источник света, самому остаться в темноте.", "generosity", "Уступить ей единственный источник света, самому остаться в темноте."),
		_base_move("date_verdict__liked_it", "«Мне понравилось.»", "directness", "«Мне понравилось.»"),
		_base_move("date_verdict__best_part_you", "«Лучшей частью вечера была ты.»", "flattery", "«Лучшей частью вечера была ты.»"),
		_base_move("date_verdict__were_you_comfortable", "«А тебе было комфортно?»", "care", "«А тебе было комфортно?»"),
		_base_move("date_verdict__good_no_analysis", "«Хорошо. Без лишнего анализа.»", "composure", "«Хорошо. Без лишнего анализа.»"),
		_base_move("date_verdict__premium_event", "«Мероприятие уверенно держит премиальный уровень.»", "status", "«Мероприятие уверенно держит премиальный уровень.»"),
		_base_move("date_verdict__glad_spent_time", "«Рад, что потратил этот вечер именно на тебя.»", "generosity", "«Рад, что потратил этот вечер именно на тебя.»"),
		_base_move("see_again__yes_again", "«Да. Хочу увидеться ещё.»", "directness", "«Да. Хочу увидеться ещё.»"),
		_base_move("see_again__after_company", "«После такой компании — обязательно.»", "flattery", "«После такой компании — обязательно.»"),
		_base_move("see_again__if_you_want", "«Если тебе тоже хочется — да.»", "care", "«Если тебе тоже хочется — да.»"),
		_base_move("see_again__tomorrow_free", "«Завтра свободна?»", "audacity", "«Завтра свободна?»"),
		_base_move("see_again__repeat", "Кивнуть: «Повторим.»", "composure", "Кивнуть: «Повторим.»"),
		_base_move("see_again__something_different", "Предложить в следующий раз сделать что-нибудь совсем непривычное.", "risk", "Предложить в следующий раз сделать что-нибудь совсем непривычное."),
		_base_move("honest_question__sometimes_yes", "«Да. Иногда.»", "directness", "«Да. Иногда.»"),
		_base_move("honest_question__why_important", "«Почему тебе это показалось важным?»", "care", "«Почему тебе это показалось важным?»"),
		_base_move("honest_question__confidence_skill", "«Уверенность тоже навык. Иногда её просто включаешь.»", "composure", "«Уверенность тоже навык. Иногда её просто включаешь.»"),
		_base_move("honest_question__when_useful", "«Только когда это полезно.»", "cunning", "«Только когда это полезно.»"),
		_base_move("honest_question__honest_thanks", "Честно ответить и поблагодарить за прямой вопрос.", "politeness", "Честно ответить и поблагодарить за прямой вопрос."),
		_base_move("honest_question__expensive_trim", "«Я не притворяюсь. Это дорогая комплектация.»", "status", "«Я не притворяюсь. Это дорогая комплектация.»"),
		_base_move("lost_wallet__give_to_staff", "Отнести кошелёк сотруднику заведения.", "politeness", "Отнести кошелёк сотруднику заведения."),
		_base_move("lost_wallet__find_owner", "Самому попытаться найти владельца по данным внутри.", "care", "Самому попытаться найти владельца по данным внутри."),
		_base_move("lost_wallet__call_business_card", "Позвонить по визитке внутри и быстро проверить, чей кошелёк.", "cunning", "Позвонить по визитке внутри и быстро проверить, чей кошелёк."),
		_base_move("lost_wallet__pay_delivery", "Оплатить доставку кошелька владельцу за свой счёт.", "generosity", "Оплатить доставку кошелька владельцу за свой счёт."),
		_base_move("lost_wallet__return_it", "Сказать: «Чужое. Возвращаем.»", "directness", "Сказать: «Чужое. Возвращаем.»"),
		_base_move("lost_wallet__i_will_handle", "Забрать организацию на себя: «Я разберусь и верну.»", "dominance", "Забрать организацию на себя: «Я разберусь и верну.»"),
		_base_move("simple_goodbye__good_evening", "Улыбнуться: «Пока. Хорошего вечера.»", "politeness", "Улыбнуться: «Пока. Хорошего вечера.»"),
		_base_move("simple_goodbye__write_when_home", "«Напиши, когда доберёшься.»", "care", "«Напиши, когда доберёшься.»"),
		_base_move("simple_goodbye__final_compliment", "Оставить напоследок короткий красивый комплимент.", "flattery", "Оставить напоследок короткий красивый комплимент."),
		_base_move("simple_goodbye__dont_miss_me", "Подмигнуть: «Старайся не скучать.»", "audacity", "Подмигнуть: «Старайся не скучать.»"),
		_base_move("simple_goodbye__see_you", "Спокойно кивнуть: «До встречи.»", "composure", "Спокойно кивнуть: «До встречи.»"),
		_base_move("simple_goodbye__theatrical_bow", "Сделать торжественный поклон, будто закрываешь спектакль.", "risk", "Сделать торжественный поклон, будто закрываешь спектакль."),
		_base_move("sudden_rain__give_umbrella", "Отдать ей зонт, самому остаться под дождём.", "care", "Отдать ей зонт, самому остаться под дождём."),
		_base_move("sudden_rain__call_taxi", "Предложить вызвать ей такси за свой счёт.", "generosity", "Предложить вызвать ей такси за свой счёт."),
		_base_move("sudden_rain__wait_it_out", "Предложить спокойно переждать.", "composure", "Предложить спокойно переждать."),
		_base_move("sudden_rain__walk_in_rain", "Пойти под дождём так, будто всё было запланировано.", "audacity", "Пойти под дождём так, будто всё было запланировано."),
		_base_move("sudden_rain__car_to_door", "Вызвать машину прямо к выходу и не мокнуть вообще.", "status", "Вызвать машину прямо к выходу и не мокнуть вообще."),
		_base_move("sudden_rain__run_for_cover", "Предложить добежать до ближайшего укрытия.", "risk", "Предложить добежать до ближайшего укрытия."),
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
		_local_move("cafe__barista__lady_first", "Попросить сначала принять заказ девушки", "politeness", "Попросить сначала принять заказ девушки", "Ей нравится спокойная вежливость в обычной ситуации.", "Ей кажется, что ты слишком церемонишься из-за простой покупки кофе."),
		_local_move("cafe__barista__best_item", "Спросить, что здесь реально самое вкусное", "directness", "Спросить, что здесь реально самое вкусное", "Ей нравится простой вопрос без изучения меню как документации.", "Ей кажется, что ты слишком легко отдаёшь выбор незнакомому человеку."),
		_local_move("cafe__board_games__set_trap", "Выбрать игру и быстро заманить её в ловушку", "cunning", "Выбрать игру и быстро заманить её в ловушку", "Её веселит, что спокойная игра сразу превратилась в маленькую дуэль.", "Она замечает подвох и считает такой старт слишком расчётливым."),
		_local_move("cafe__board_games__ridiculous_game", "Взять самую нелепую игру и начать до чтения правил", "humor", "Взять самую нелепую игру и начать до чтения правил", "Она включается в хаос и смеётся над происходящим.", "Ей хотелось хотя бы понять правила до начала катастрофы."),
		_local_move("cafe__window__fresh_air", "Слегка приоткрыть окно, заметив, что ей душно", "care", "Слегка приоткрыть окно, заметив, что ей душно", "Она замечает, что ты обратил внимание на её комфорт.", "Ей кажется, что ты слишком внимательно контролируешь каждую мелочь."),
		_local_move("cafe__window__open_to_street", "Распахнуть окно и продолжить разговор будто теперь участвует вся улица", "audacity", "Распахнуть окно и продолжить разговор будто теперь участвует вся улица", "Её смешит неожиданно публичный поворот разговора.", "Она предпочла бы оставить ваше свидание внутри помещения."),
		_local_move("leisure_center__claw_machine__get_toy", "Попытаться достать игрушку, которая ей понравилась", "care", "Попытаться достать игрушку, которая ей понравилась", "Ей приятно, что ты сразу превратил её интерес в маленькую цель.", "Она считает, что игрушка не стоила такого количества усилий."),
		_local_move("leisure_center__claw_machine__study_mechanism", "Изучить механизм и выбрать лучший момент для захвата", "cunning", "Изучить механизм и выбрать лучший момент для захвата", "Ей нравится, как быстро ты превращаешь автомат в решаемую задачу.", "Она хотела просто поиграть, а не наблюдать инженерный аудит автомата."),
		_local_move("leisure_center__racing_arcade__max_difficulty", "Выбрать максимальную сложность и отключить помощь", "risk", "Выбрать максимальную сложность и отключить помощь", "Ей нравится сразу поднять ставки.", "Она считает, что сначала можно было хотя бы понять управление."),
		_local_move("leisure_center__racing_arcade__winner_wish", "Предложить маленькое желание победителю", "audacity", "Предложить маленькое желание победителю", "Дерзкое условие делает гонку для неё интереснее.", "Ей не нравится добавлять обязательства к обычной игре."),
		_local_move("leisure_center__air_hockey__play_seriously", "Играть всерьёз и вообще не поддаваться", "dominance", "Играть всерьёз и вообще не поддаваться", "Ей нравится настоящее соревнование без скидок.", "Она считает, что ты слишком серьёзно воспринял маленькую игру."),
		_local_move("leisure_center__air_hockey__world_final", "Комментировать матч будто идёт финал чемпионата мира", "humor", "Комментировать матч будто идёт финал чемпионата мира", "Она смеётся и начинает подыгрывать комментатору.", "Ей хотелось слышать хотя бы звук самой игры."),
		_local_move("leisure_center__prize_counter__gift_prize", "Потратить выигранные жетоны на приз для неё", "generosity", "Потратить выигранные жетоны на приз для неё", "Маленький подарок ей приятен.", "Она предпочла бы, чтобы ты выбрал что-нибудь себе."),
		_local_move("leisure_center__prize_counter__giant_trophy", "Забрать самый огромный приз и нести его как трофей", "status", "Забрать самый огромный приз и нести его как трофей", "Её веселит, насколько серьёзно ты относишься к своему новому символу победы.", "Она считает гигантский трофей слишком заметным даже для тебя."),
		_local_move("restaurant__waiter__lady_first", "Попросить сначала обслужить девушку", "politeness", "Попросить сначала обслужить девушку", "Ей нравится естественная вежливость без лишнего спектакля.", "Она считает такую церемонию лишней.", "appearance", 1),
		_local_move("restaurant__waiter__set_service_order", "Взять организацию заказа на себя и задать порядок подачи", "dominance", "Взять организацию заказа на себя и задать порядок подачи", "Ей нравится, как уверенно ты организовал ситуацию.", "Она не хотела, чтобы обычный заказ превращался в командование персоналом.", "muscle", 3),
		_local_move("restaurant__tasting_set__signature_set", "Заказать фирменный сет ресторана как очевидный выбор", "status", "Заказать фирменный сет ресторана как очевидный выбор", "Ей нравится уверенный выбор премиального варианта.", "Она считает, что впечатление от цены для тебя важнее самого вечера.", "capital", 3),
		_local_move("restaurant__tasting_set__trust_the_chef", "Довериться выбору шефа и спокойно ждать сюрприз", "composure", "Довериться выбору шефа и спокойно ждать сюрприз", "Ей нравится, что ты не пытаешься контролировать каждую деталь.", "Она предпочла бы заранее понимать, что именно принесут.", "aura", 3),
		_local_move("restaurant__live_music__dedication", "Попросить музыканта посвятить ей композицию", "flattery", "Попросить музыканта посвятить ей композицию", "Красивый публичный комплимент ей нравится.", "Она считает такое внимание слишком демонстративным.", "appearance", 3),
		_local_move("restaurant__live_music__tip_performance", "Хорошо отблагодарить музыканта за отдельное исполнение", "generosity", "Хорошо отблагодарить музыканта за отдельное исполнение", "Ей нравится щедро оценить чужую работу.", "Она считает, что ты слишком легко превращаешь впечатления в расходы.", "capital", 1),
		_local_move("restaurant__open_kitchen__adjust_for_her", "Попросить изменить блюдо с учётом её вкусов", "care", "Попросить изменить блюдо с учётом её вкусов", "Она замечает, что ты запомнил её предпочтения и подумал о комфорте.", "Она считает, что ради неё совсем не обязательно менять работу кухни.", "aura", 1),
		_local_move("restaurant__open_kitchen__ask_chef", "Спросить шефа напрямую, что он сам здесь заказал бы", "directness", "Спросить шефа напрямую, что он сам здесь заказал бы", "Ей нравится получить простой ответ прямо от человека, который знает меню лучше всех.", "Она считает, что можно было выбрать самостоятельно.", "muscle", 1),
		_local_move("apartment__plaid__get_comfortable", "Предложить ей плед и устроиться поудобнее", "care", "Предложить ей плед и устроиться поудобнее", "Ей приятно, что ты подумал о её комфорте.", "Она считает, что ей и так было нормально."),
		_local_move("apartment__tv__ridiculous_show", "Включить что-нибудь настолько нелепое, что это уже интересно", "humor", "Включить что-нибудь настолько нелепое, что это уже интересно", "Она быстро включается в совместный просмотр абсурда.", "Она не понимает, почему из всего доступного ты выбрал именно это."),
		_local_move("apartment__record_player__quiet_music", "Поставить спокойную музыку и позволить паузе просто существовать", "composure", "Поставить спокойную музыку и позволить паузе просто существовать", "Ей нравится момент без необходимости постоянно заполнять тишину.", "Пауза кажется ей скорее неловкой, чем уютной."),
		_local_move("apartment__no_filter_cards__honest_question", "Вытянуть вопрос и ответить без ухода от темы", "directness", "Вытянуть вопрос и ответить без ухода от темы", "Ей нравится, что игра действительно приводит к честному разговору.", "Она считает вопрос слишком прямым для такого момента."),
		_local_move("apartment__tea_set__serve_tea", "Нормально сервировать чай вместо случайной кружки", "politeness", "Нормально сервировать чай вместо случайной кружки", "Ей нравится аккуратное внимание к простой детали.", "Она считает, что обычный чай получил слишком много церемоний."),
		_local_move("apartment__mini_fridge__best_stock", "Достать лучший запас специально для неё", "generosity", "Достать лучший запас специально для неё", "Ей нравится, что ты оставил хорошее именно для гостя.", "Она считает такой жест слишком демонстративным."),
		_local_move("apartment__large_mirror__compliment_reflection", "Подвести её к зеркалу и красиво отметить, как она выглядит", "flattery", "Подвести её к зеркалу и красиво отметить, как она выглядит", "Комплимент попадает точно в нужный момент.", "Она считает сцену слишком специально подготовленной для комплимента."),
		_local_move("apartment__collection_display__show_centerpiece", "Показать самый впечатляющий предмет своей коллекции", "status", "Показать самый впечатляющий предмет своей коллекции", "Ей нравится увидеть вещь, которой ты действительно гордишься.", "Она воспринимает экскурсию как демонстрацию достижений."),
		_local_move("apartment__karaoke__sing_first", "Первым начать петь, не проверяя, насколько это хорошая идея", "audacity", "Первым начать петь, не проверяя, насколько это хорошая идея", "Ей нравится, что ты сразу снимаешь неловкость собственным примером.", "Она считает, что проверка идеи всё-таки не помешала бы."),
		_local_move("apartment__game_console__no_mercy", "Запустить соревнование и предупредить, что поддаваться не будешь", "dominance", "Запустить соревнование и предупредить, что поддаваться не будешь", "Ей нравится честное соревнование без скидок.", "Она считает, что ты слишком быстро превратил отдых в матч."),
		_local_move("apartment__darts__hard_throw", "Предложить усложнённый бросок с небольшой ставкой", "risk", "Предложить усложнённый бросок с небольшой ставкой", "Ей нравится добавить обычной игре немного риска.", "Она считает усложнение совершенно ненужным."),
		_local_move("apartment__chess_table__prepared_trap", "Быстро устроить позицию с заранее подготовленной ловушкой", "cunning", "Быстро устроить позицию с заранее подготовленной ловушкой", "Ей нравится обнаружить, что короткая партия уже была маленькой схемой.", "Она считает подготовленную ловушку слишком нечестным стартом."),
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
