class_name ContentPacksProgress
extends RefCounted
## Stages, upgrades, events packs (split for maintainability).


static func stages() -> Dictionary:
	return {
		"stage_1": {
			"id": "stage_1", "name": "Одинокая квартира", "order": 1,
			"goal": "Проведи свидание с соседкой, набери ⭐ и открой жёлтую дверь расширения.",
			"unlock_next": "stage_2", "next_cost": 60,
			"rooms": ["apartment", "neighbor_apt", "lab"], "venues": ["kitchen_table", "cheap_cafe"],
			"girls": ["neighbor"],
		},
		"stage_2": {
			"id": "stage_2", "name": "Популярный парень", "order": 2,
			"goal": "Найми менеджера переписки в телефоне и знакомься с новыми девушками.",
			"unlock_next": "stage_3", "next_cost": 200,
			"rooms": ["apartment", "neighbor_apt", "lab", "office_nook"], "venues": ["kitchen_table", "cheap_cafe", "park"],
			"girls": ["neighbor", "fitness", "goth", "streamer"],
		},
		"stage_3": {
			"id": "stage_3", "name": "Операционный штаб", "order": 3,
			"goal": "Собери аппарат вокруг одного тела: персонал, залы, учёная.",
			"unlock_next": "stage_4", "next_cost": 500,
			"rooms": ["apartment", "neighbor_apt", "lab", "office_nook", "agency"],
			"venues": ["kitchen_table", "cheap_cafe", "park", "cinema_room", "restaurant", "photo_studio"],
			"girls": ["neighbor", "fitness", "goth", "streamer", "business", "fashionista", "chef", "scientist"],
		},
		"stage_4": {
			"id": "stage_4", "name": "Проект «Второй Я»", "order": 4,
			"goal": "4A лаборатория → 4B приёмка дубля → 4C первая параллель.",
			"unlock_next": "stage_5", "next_cost": 1200,
			"rooms": ["apartment", "neighbor_apt", "lab", "office_nook", "agency", "mansion"],
			"venues": ["kitchen_table", "cheap_cafe", "park", "cinema_room", "restaurant", "photo_studio", "luxury_hall", "lab_capsule"],
			"girls": ["neighbor", "fitness", "goth", "streamer", "business", "fashionista", "chef", "scientist", "lawyer"],
		},
		"stage_5": {
			"id": "stage_5", "name": "Фабрика свиданий", "order": 5,
			"goal": "Запусти конвейер и открой Инопланетянку.",
			"unlock_next": "stage_6", "next_cost": 3000,
			"rooms": ["apartment", "neighbor_apt", "lab", "office_nook", "agency", "mansion", "factory"],
			"venues": ["kitchen_table", "cheap_cafe", "park", "cinema_room", "restaurant", "photo_studio", "luxury_hall", "lab_capsule", "conveyor"],
			"girls": ["neighbor", "fitness", "goth", "streamer", "business", "fashionista", "chef", "scientist", "lawyer", "star", "alien"],
		},
		"stage_6": {
			"id": "stage_6", "name": "Корпорация любви", "order": 6,
			"goal": "Собери мегамашину и проведи финальное свидание.",
			"unlock_next": "", "next_cost": 0,
			"rooms": ["apartment", "neighbor_apt", "lab", "office_nook", "agency", "mansion", "factory", "orbital"],
			"venues": ["kitchen_table", "cheap_cafe", "park", "cinema_room", "restaurant", "photo_studio", "luxury_hall", "lab_capsule", "conveyor", "orbital_hall"],
			"girls": ["neighbor", "fitness", "goth", "streamer", "business", "fashionista", "chef", "scientist", "lawyer", "star", "alien", "algorithm"],
		},
	}


static func upgrades() -> Dictionary:
	var out: Dictionary = {}
	var defs: Array = []
	# Hero
	defs.append_array([
		_u("hero_attention_1", "Больше внимания I", "hero", 40, "stage_1", {"max_attention": 1}),
		_u("hero_attention_2", "Больше внимания II", "hero", 120, "stage_2", {"max_attention": 1}),
		_u("hero_attention_3", "Больше внимания III", "hero", 300, "stage_4", {"max_attention": 2}),
		_u("hero_date_quality_1", "Харизма I", "hero", 50, "stage_1", {"manual_quality": 0.5}),
		_u("hero_date_quality_2", "Харизма II", "hero", 150, "stage_3", {"manual_quality": 0.5}),
		_u("hero_speed_1", "Быстрые ноги", "hero", 60, "stage_2", {"move_speed": 0.15}),
		_u("hero_carry_2", "Два предмета", "hero", 200, "stage_3", {"carry_slots": 1}),
		_u("hero_forgive", "Меньше штрафа за ответ", "hero", 90, "stage_2", {"bad_choice_mult": 0.7}),
		_u("hero_first_pop", "Первое впечатление", "hero", 70, "stage_1", {"first_date_pop": 2}),
		_u("hero_skip_phase", "Быстрое ручное свидание", "hero", 250, "stage_4", {"fast_manual": true}),
	])
	# Search
	defs.append_array([
		_u("search_more_1", "Больше анкет I", "search", 55, "stage_2", {"candidate_slots": 1}),
		_u("search_more_2", "Больше анкет II", "search", 140, "stage_3", {"candidate_slots": 2}),
		_u("search_rare", "Шанс редкой девушки", "search", 180, "stage_3", {"rare_chance": 0.1}),
		_u("search_fast", "Быстрое подтверждение", "search", 100, "stage_2", {"confirm_speed": 0.25}),
		_u("search_filter", "Автофильтр", "search", 160, "stage_3", {"auto_filter": true}),
		_u("search_pref", "Поиск по предпочтениям", "search", 220, "stage_4", {"pref_search": true}),
		_u("search_mass", "Массовый набор", "search", 400, "stage_5", {"mass_candidates": 5}),
		_u("search_orbit", "Межпланетный поиск", "search", 900, "stage_6", {"candidate_slots": 5}),
	])
	# Messages
	defs.append_array([
		_u("msg_attention", "Экономные сообщения", "messages", 70, "stage_2", {"msg_attention_cost": -0.25}),
		_u("msg_yes", "Выше шанс согласия", "messages", 90, "stage_2", {"accept_chance": 0.1}),
		_u("msg_auto", "Автоответы+", "messages", 130, "stage_3", {"auto_msg_quality": 0.2}),
		_u("msg_parallel", "Параллельные диалоги", "messages", 200, "stage_3", {"parallel_chats": 2}),
		_u("msg_fix", "Исправление ошибок менеджера", "messages", 160, "stage_4", {"manager_error_mult": 0.5}),
		_u("msg_instant", "Мгновенное повторное", "messages", 280, "stage_5", {"instant_redate": true}),
	])
	# Wardrobe
	defs.append_array([
		_u("ward_style_sport", "Стиль: спорт", "wardrobe", 40, "stage_2", {"unlock_outfit": "sport"}),
		_u("ward_style_gothic", "Стиль: готика", "wardrobe", 45, "stage_2", {"unlock_outfit": "gothic"}),
		_u("ward_style_fashion", "Стиль: мода", "wardrobe", 80, "stage_3", {"unlock_outfit": "fashion"}),
		_u("ward_style_business", "Стиль: деловой", "wardrobe", 85, "stage_3", {"unlock_outfit": "business"}),
		_u("ward_style_luxury", "Стиль: роскошь", "wardrobe", 160, "stage_4", {"unlock_outfit": "luxury"}),
		_u("ward_style_science", "Стиль: наука", "wardrobe", 100, "stage_3", {"unlock_outfit": "science"}),
		_u("ward_style_media", "Стиль: медиа", "wardrobe", 140, "stage_4", {"unlock_outfit": "media"}),
		_u("ward_style_space", "Стиль: космос", "wardrobe", 260, "stage_5", {"unlock_outfit": "space"}),
		_u("ward_auto", "Автоподбор", "wardrobe", 180, "stage_4", {"auto_outfit": true}),
		_u("ward_fast", "Быстрое переодевание", "wardrobe", 120, "stage_3", {"dress_speed": 0.3}),
		_u("ward_copies", "Запас комплектов", "wardrobe", 200, "stage_4", {"outfit_copies": 2}),
		_u("ward_repeat", "Меньше штрафа за повтор", "wardrobe", 150, "stage_4", {"repeat_penalty_mult": 0.5}),
		_u("ward_instant", "Мгновенная смена", "wardrobe", 350, "stage_5", {"instant_outfit": true}),
	])
	# Gifts
	defs.append_array([
		_u("gift_price_1", "Скидка на подарки I", "gifts", 60, "stage_1", {"gift_price_mult": 0.9}),
		_u("gift_price_2", "Скидка на подарки II", "gifts", 160, "stage_3", {"gift_price_mult": 0.85}),
		_u("gift_quality", "Качество подарков", "gifts", 100, "stage_2", {"gift_quality": 0.5}),
		_u("gift_auto", "Автозакупка", "gifts", 180, "stage_4", {"auto_buy_gifts": true}),
		_u("gift_storage", "Большой склад", "gifts", 140, "stage_3", {"gift_cap": 20}),
		_u("gift_craft", "Производство дорогих", "gifts", 400, "stage_5", {"craft_gifts": true}),
		_u("gift_match", "Персональный подбор", "gifts", 250, "stage_4", {"smart_gifts": true}),
		_u("gift_named", "Именные предметы", "gifts", 300, "stage_5", {"named_gifts": true}),
		_u("gift_teleport", "Телепорт подарков", "gifts", 700, "stage_6", {"teleport_gifts": true}),
	])
	# Venues
	defs.append_array([
		_u("venue_table_upgrade", "Улучшить кухонный стол", "venues", 35, "stage_1", {"venue_quality:kitchen_table": 1}),
		_u("venue_cafe", "Открыть кафе", "venues", 80, "stage_2", {"unlock_venue": "cheap_cafe"}),
		_u("venue_park", "Благоустроить парк", "venues", 50, "stage_2", {"unlock_venue": "park"}),
		_u("venue_cinema", "Кино-комната", "venues", 150, "stage_3", {"unlock_venue": "cinema_room"}),
		_u("venue_resto", "Ресторан", "venues", 220, "stage_3", {"unlock_venue": "restaurant"}),
		_u("venue_photo", "Фотостудия", "venues", 260, "stage_3", {"unlock_venue": "photo_studio"}),
		_u("venue_luxury", "Роскошный зал", "venues", 450, "stage_4", {"unlock_venue": "luxury_hall"}),
		_u("venue_lab", "Лабораторная капсула", "venues", 320, "stage_4", {"unlock_venue": "lab_capsule"}),
		_u("venue_conveyor", "Конвейер", "venues", 800, "stage_5", {"unlock_venue": "conveyor"}),
		_u("venue_orbital", "Орбитальный зал", "venues", 1500, "stage_6", {"unlock_venue": "orbital_hall"}),
		_u("venue_capacity", "Больше столиков", "venues", 300, "stage_4", {"global_capacity": 1}),
		_u("venue_speed", "Короче свидания", "venues", 200, "stage_3", {"date_time_mult": 0.85}),
		_u("venue_quality", "Сервис+", "venues", 240, "stage_4", {"venue_quality_all": 0.5}),
		_u("venue_cost", "Дешевле места", "venues", 180, "stage_3", {"venue_cost_mult": 0.85}),
		_u("venue_clean", "Автоуборка", "venues", 160, "stage_4", {"auto_clean": true}),
	])
	# Clones
	defs.append_array([
		_u("clone_slot_1", "Слот клона I", "clones", 200, "stage_4", {"clone_slots": 1}),
		_u("clone_slot_2", "Слот клона II", "clones", 350, "stage_4", {"clone_slots": 1}),
		_u("clone_slot_3", "Слот клона III", "clones", 500, "stage_5", {"clone_slots": 2}),
		_u("clone_slot_4", "Слот клона IV", "clones", 800, "stage_5", {"clone_slots": 2}),
		_u("clone_mass", "Массовые клоны", "clones", 1200, "stage_6", {"clone_slots": 3}),
		_u("clone_reliability", "Надёжность", "clones", 220, "stage_4", {"clone_error_mult": 0.7}),
		_u("clone_quality", "Качество общения", "clones", 240, "stage_4", {"clone_quality": 0.5}),
		_u("clone_fatigue", "Меньше усталость", "clones", 200, "stage_4", {"clone_fatigue_mult": 0.7}),
		_u("clone_spec", "Специализации", "clones", 280, "stage_5", {"clone_specs": true}),
		_u("clone_autoprep", "Автоподготовка", "clones", 320, "stage_5", {"clone_autoprep": true}),
		_u("clone_group", "Групповое управление", "clones", 400, "stage_5", {"clone_groups": true}),
		_u("clone_instant", "Клон без ожидания", "clones", 900, "stage_6", {"clone_instant": true}),
	])
	# PR
	defs.append_array([
		_u("pr_passive", "Пассивный PR", "pr", 180, "stage_5", {"scandal_decay": 0.2}),
		_u("pr_convert", "Скандал → популярность", "pr", 260, "stage_5", {"scandal_to_pop": 0.15}),
		_u("pr_fines", "Меньше штрафов", "pr", 200, "stage_5", {"fine_mult": 0.7}),
		_u("pr_choices", "Доп. решения событий", "pr", 240, "stage_5", {"extra_event_choices": true}),
		_u("pr_sponsors", "Спонсоры", "pr", 350, "stage_5", {"sponsors": true}),
		_u("pr_shield", "Защита от провала", "pr", 400, "stage_5", {"fail_shield": true}),
		_u("pr_energy", "Скандал в энергию", "pr", 700, "stage_6", {"scandal_energy": true}),
	])
	# Harem / living
	defs.append_array([
		_u("harem_rooms", "Больше комнат", "harem", 300, "stage_4", {"harem_rooms": 2}),
		_u("harem_bonus", "Сильнее бонусы", "harem", 350, "stage_4", {"girl_bonus_mult": 1.15}),
		_u("harem_auto", "Автоподдержка отношений", "harem", 450, "stage_5", {"auto_relations": true}),
		_u("harem_cosmetic", "Косметические слоты", "harem", 200, "stage_4", {"cosmetic_slots": 1}),
		_u("harem_common", "Общие зоны", "harem", 250, "stage_4", {"common_areas": true}),
		_u("harem_synergy", "Синергии архетипов", "harem", 400, "stage_5", {"synergies": true}),
	])
	# Final tech
	defs.append_array([
		_u("final_auto_dates", "Полностью автосвидания", "final", 1000, "stage_6", {"full_auto_dates": true}),
		_u("final_megamachine_1", "Мегамашина: каркас", "final", 800, "stage_6", {"mega_part": 1}),
		_u("final_megamachine_2", "Мегамашина: сердце", "final", 1000, "stage_6", {"mega_part": 2}),
		_u("final_megamachine_3", "Мегамашина: ядро", "final", 1200, "stage_6", {"mega_part": 3}),
		_u("final_lines", "Доп. автолинии", "final", 900, "stage_6", {"extra_lines": 2}),
	])
	for d in defs:
		out[d["id"]] = d
	return out


static func _u(id: String, name: String, category: String, cost: float, stage: String, effects: Dictionary) -> Dictionary:
	return {"id": id, "name": name, "category": category, "cost": cost, "unlock_stage": stage, "effects": effects}


static func events() -> Dictionary:
	var templates := [
		{"id": "prep_gift_swap", "name": "Перепутаны подарки", "cat": "prep",
			"blurb": "Клону вручили чужой подарок. Что делаем?",
			"choices": [
				{"id": "return", "label": "Вернуть правильный подарок", "money": -15, "scandal": -1, "popularity": 1},
				{"id": "apologize", "label": "Извиниться и купить новый", "money": -40, "scandal": -2, "popularity": 2},
				{"id": "risk", "label": "Оставить как есть", "money": 0, "scandal": 3, "popularity": 1},
			]},
		{"id": "prep_no_clothes", "name": "Закончилась одежда", "cat": "prep",
			"blurb": "В гардеробе пусто. Свидание через минуту.",
			"choices": [
				{"id": "buy", "label": "Срочно купить комплект", "money": -50, "scandal": 0, "popularity": 1},
				{"id": "borrow", "label": "Одолжить у соседки", "money": -10, "scandal": 1, "popularity": 0},
				{"id": "as_is", "label": "Отправить как есть", "money": 0, "scandal": 2, "popularity": -1},
			]},
		{"id": "prep_same_outfit", "name": "Два клона — один комплект", "cat": "prep",
			"blurb": "Оба клона надели одно и то же. Гости уже смотрят.",
			"choices": [
				{"id": "split", "label": "Развести по разным залам", "money": -20, "scandal": -1, "popularity": 1},
				{"id": "buy", "label": "Купить второй комплект", "money": -60, "scandal": -2, "popularity": 2},
				{"id": "meme", "label": "Сделать парный контент", "money": 15, "scandal": 2, "popularity": 4},
			]},
		{"id": "prep_bad_style", "name": "Стилист ошибся", "cat": "prep",
			"blurb": "Образ получился мимо вкуса девушки.",
			"choices": [
				{"id": "fix", "label": "Переодеть вручную", "money": -10, "scandal": -1, "popularity": 1},
				{"id": "fire", "label": "Оштрафовать стилиста", "money": 20, "scandal": 0, "popularity": 0},
				{"id": "keep", "label": "Оставить — вдруг зайдёт", "money": 0, "scandal": 2, "popularity": 2},
			]},
		{"id": "prep_bulk_junk", "name": "Партия бесполезных подарков", "cat": "prep",
			"blurb": "Склад забит странными сувенирами.",
			"choices": [
				{"id": "sell", "label": "Продать со скидкой", "money": 25, "scandal": 0, "popularity": 0},
				{"id": "meme", "label": "Раздать как мем-мерч", "money": 5, "scandal": 1, "popularity": 3},
				{"id": "trash", "label": "Выбросить", "money": -5, "scandal": -1, "popularity": 0},
			]},
		{"id": "sched_double", "name": "Две девушки одновременно", "cat": "schedule",
			"blurb": "Два свидания пересеклись в одном зале.",
			"choices": [
				{"id": "split", "label": "Развести по разным местам", "money": -25, "scandal": -2, "popularity": 1},
				{"id": "delay", "label": "Задержать одно на час", "money": -10, "scandal": 1, "popularity": 0},
				{"id": "chaos", "label": "Пусть разбираются сами", "money": 0, "scandal": 4, "popularity": 2},
			]},
		{"id": "sched_late", "name": "Клон опоздал", "cat": "schedule",
			"blurb": "Клон застрял в лифте. Девушка ждёт.",
			"choices": [
				{"id": "pay", "label": "Компенсировать деньгами", "money": -35, "scandal": -1, "popularity": 1},
				{"id": "speed", "label": "Ускорить следующее", "money": -15, "scandal": 0, "popularity": 2},
				{"id": "blame", "label": "Свалить на пробки", "money": 0, "scandal": 2, "popularity": 0},
			]},
		{"id": "sched_busy", "name": "Столик занят", "cat": "schedule",
			"blurb": "Бронь сгорела — зал занят чужой компанией.",
			"choices": [
				{"id": "move", "label": "Перенести в другое место", "money": -20, "scandal": 0, "popularity": 1},
				{"id": "upgrade", "label": "Доплатить за лучший зал", "money": -60, "scandal": -1, "popularity": 3},
				{"id": "park", "label": "Уйти в парк", "money": 0, "scandal": 1, "popularity": 0},
			]},
		{"id": "sched_manager_date", "name": "Менеджер назначил свидание себе", "cat": "schedule",
			"blurb": "Менеджер переписки записал себя в слот свидания.",
			"choices": [
				{"id": "fire", "label": "Отстранить на день", "money": -10, "scandal": 0, "popularity": 0},
				{"id": "laugh", "label": "Посмеяться и отменить", "money": 0, "scandal": 1, "popularity": 1},
				{"id": "allow", "label": "Пусть идёт — вдруг контент", "money": 10, "scandal": 3, "popularity": 3},
			]},
		{"id": "sched_long", "name": "Свидание слишком длинное", "cat": "schedule",
			"blurb": "Пара сидит уже третий час. Очередь растёт.",
			"choices": [
				{"id": "cut", "label": "Мягко завершить", "money": 0, "scandal": 1, "popularity": 0},
				{"id": "bonus", "label": "Дать бонус за качество", "money": -20, "scandal": -1, "popularity": 3},
				{"id": "wait", "label": "Пусть длится", "money": 5, "scandal": 0, "popularity": 2},
			]},
		{"id": "media_viral", "name": "Ролик стал вирусным", "cat": "media",
			"blurb": "Короткое видео с клоном набрало миллион просмотров.",
			"choices": [
				{"id": "cash", "label": "Монетизировать хайп", "money": 80, "scandal": 1, "popularity": 5},
				{"id": "brand", "label": "Сделать серию роликов", "money": -30, "scandal": 0, "popularity": 8},
				{"id": "low", "label": "Приглушить шум", "money": 0, "scandal": -2, "popularity": 2},
			]},
		{"id": "media_fail_news", "name": "Провал в новостях", "cat": "media",
			"blurb": "Местный канал высмеял ваш операционный штаб.",
			"choices": [
				{"id": "pr", "label": "Заплатить PR", "money": -70, "scandal": -3, "popularity": 1},
				{"id": "own", "label": "Признать и пошутить", "money": 0, "scandal": 1, "popularity": 3},
				{"id": "double", "label": "Удвоить скандал ради хайпа", "money": 20, "scandal": 5, "popularity": 6},
			]},
		{"id": "media_sponsor", "name": "Спонсор со странным условием", "cat": "media",
			"blurb": "Спонсор даёт деньги, если клоны носят его логотип на лице.",
			"choices": [
				{"id": "accept", "label": "Принять контракт", "money": 120, "scandal": 2, "popularity": 2},
				{"id": "negotiate", "label": "Торговаться о логотипе", "money": 40, "scandal": 0, "popularity": 1},
				{"id": "refuse", "label": "Отказаться", "money": 0, "scandal": -1, "popularity": 0},
			]},
		{"id": "media_clone_fan", "name": "Зрители любят конкретного клона", "cat": "media",
			"blurb": "Чат просит ставить одного и того же клона на все элитные свидания.",
			"choices": [
				{"id": "star", "label": "Сделать его звездой линии", "money": -20, "scandal": 0, "popularity": 5},
				{"id": "rotate", "label": "Чередовать клонов", "money": 0, "scandal": -1, "popularity": 2},
				{"id": "ignore", "label": "Игнорировать чат", "money": 10, "scandal": 1, "popularity": 0},
			]},
		{"id": "media_meme_fit", "name": "Наряд стал мемом", "cat": "media",
			"blurb": "Смешной костюм разлетелся по сети.",
			"choices": [
				{"id": "print", "label": "Тиражировать наряд", "money": 30, "scandal": 1, "popularity": 4},
				{"id": "change", "label": "Срочно сменить стиль", "money": -40, "scandal": -2, "popularity": 1},
				{"id": "lean", "label": "Стать брендом мема", "money": 15, "scandal": 3, "popularity": 6},
			]},
		{"id": "ask_gift", "name": "Просьба: принести подарок", "cat": "personal",
			"blurb": "Она хочет, чтобы именно ты принёс подарок лично.",
			"choices": [
				{"id": "yes", "label": "Пойти самому", "money": -25, "scandal": -1, "popularity": 3},
				{"id": "clone", "label": "Послать дубля — для неё это всё равно ты", "money": -10, "scandal": 1, "popularity": 1},
				{"id": "no", "label": "Отказать", "money": 0, "scandal": 0, "popularity": -1},
			]},
		{"id": "ask_room", "name": "Просьба: улучшить место", "cat": "personal",
			"blurb": "Она хочет красивее обстановку для ваших встреч. Это про твой статус.",
			"choices": [
				{"id": "invest", "label": "Вложиться в ремонт", "money": -80, "scandal": -1, "popularity": 4},
				{"id": "cheap", "label": "Косметический ремонт", "money": -30, "scandal": 0, "popularity": 2},
				{"id": "later", "label": "Позже", "money": 0, "scandal": 1, "popularity": -1},
			]},
		{"id": "ask_manual", "name": "Просьба: только ты", "cat": "personal",
			"blurb": "Она чувствует автопилот и просит встречу «по-настоящему». Для неё дубли — всё равно ты.",
			"choices": [
				{"id": "yes", "label": "Согласиться лично", "money": 0, "scandal": -1, "popularity": 3},
				{"id": "delay", "label": "Перенести на завтра", "money": -5, "scandal": 0, "popularity": 1},
				{"id": "no", "label": "Отказать", "money": 0, "scandal": 1, "popularity": -2},
			]},
		{"id": "ask_quiet", "name": "Просьба: тишина", "cat": "personal",
			"blurb": "Соседка просит на час отключить шумную линию.",
			"choices": [
				{"id": "pause", "label": "Поставить линию на паузу", "money": -15, "scandal": -1, "popularity": 1},
				{"id": "earplugs", "label": "Купить беруши соседям", "money": -20, "scandal": 0, "popularity": 2},
				{"id": "no", "label": "Не останавливать работу", "money": 10, "scandal": 2, "popularity": 0},
			]},
		{"id": "ask_clone", "name": "Дубль уже занят", "cat": "personal",
			"blurb": "Один «ты» на свидании, другая зовёт «тебя» же. Она не должна узнать, что вас двое.",
			"choices": [
				{"id": "yes", "label": "Подменить другим дублем", "money": -10, "scandal": 0, "popularity": 2},
				{"id": "premium", "label": "Пойти сам и сорвать другое", "money": 0, "scandal": 1, "popularity": 1},
				{"id": "random", "label": "Кинуть жребий между дублями", "money": 0, "scandal": 1, "popularity": -1},
			]},
		{"id": "ask_scandal", "name": "Просьба: снизить скандал", "cat": "personal",
			"blurb": "Партнёрша просит утихомирить шумиху вокруг вас.",
			"choices": [
				{"id": "pr", "label": "Заплатить PR", "money": -90, "scandal": -4, "popularity": 0},
				{"id": "quiet", "label": "На неделю без эфиров", "money": -20, "scandal": -2, "popularity": -1},
				{"id": "no", "label": "Скандал — это реклама", "money": 15, "scandal": 2, "popularity": 3},
			]},
		{"id": "tech_copy", "name": "Дубли синхронизировались", "cat": "tech",
			"blurb": "Два «тебя» говорят одними фразами. Если девушки сравнят переписки — конец мифу.",
			"choices": [
				{"id": "reboot", "label": "Перезапустить матрицу", "money": -30, "scandal": -1, "popularity": 1},
				{"id": "recolor", "label": "Сменить цвет и имя", "money": -20, "scandal": 0, "popularity": 2},
				{"id": "twins", "label": "Сыграть в «вездесущий я»", "money": 35, "scandal": 2, "popularity": 3},
			]},
		{"id": "tech_wrong_color", "name": "Дубль вышел не тем", "cat": "tech",
			"blurb": "Матрица выдала кислотно-зелёного «тебя». Девушка ждёт привычный образ.",
			"choices": [
				{"id": "recolor", "label": "Перекрасить", "money": -25, "scandal": -1, "popularity": 1},
				{"id": "brand", "label": "Оставить как бренд", "money": 10, "scandal": 1, "popularity": 3},
				{"id": "refund", "label": "Списать и создать нового", "money": -50, "scandal": 0, "popularity": 0},
			]},
		{"id": "tech_one_outfit", "name": "Гардероб выдаёт один образ", "cat": "tech",
			"blurb": "Автоматика одевает все дубли в один костюм.",
			"choices": [
				{"id": "reset", "label": "Сбросить систему", "money": -35, "scandal": -1, "popularity": 1},
				{"id": "manual", "label": "Одевать вручную", "money": -10, "scandal": 0, "popularity": 0},
				{"id": "uniform", "label": "Объявить фирменный лук", "money": 20, "scandal": 2, "popularity": 2},
			]},
		{"id": "tech_random_names", "name": "Подарки получают случайные имена", "cat": "tech",
			"blurb": "Склад печатает на коробках чужие названия: «торт» оказывается «ключом от Луны».",
			"choices": [
				{"id": "fix", "label": "Починить базу названий", "money": -40, "scandal": -2, "popularity": 1},
				{"id": "joke", "label": "Оставить как шутку бренда", "money": 15, "scandal": 1, "popularity": 3},
				{"id": "relabel", "label": "Переклеить этикетки вручную", "money": -15, "scandal": -1, "popularity": 0},
			]},
		{"id": "tech_reverse", "name": "Конвейер едет назад", "cat": "tech",
			"blurb": "Лента пошла назад. Дубли возвращаются на старт вместо свиданий.",
			"choices": [
				{"id": "flip", "label": "Развернуть вручную", "money": -20, "scandal": -1, "popularity": 1},
				{"id": "engineer", "label": "Вызвать техника", "money": -55, "scandal": -2, "popularity": 2},
				{"id": "ride", "label": "Снять ролик про баг", "money": 25, "scandal": 2, "popularity": 4},
			]},
		{"id": "absurd_planet", "name": "Требуют маленькую планету", "cat": "absurd",
			"blurb": "Она просит подарок «персональная планета». Абсурдный жест статуса альфы.",
			"choices": [
				{"id": "buy", "label": "Купить планету", "money": -400, "scandal": 1, "popularity": 8},
				{"id": "fake", "label": "Подарить глобус с лентой", "money": -30, "scandal": 2, "popularity": 1},
				{"id": "no", "label": "Вежливо отказать", "money": 0, "scandal": 0, "popularity": -2},
			]},
		{"id": "absurd_delegation", "name": "Инопланетная делегация", "cat": "absurd",
			"blurb": "Гости с другой планеты хотят увидеть тебя — легенду межгалактического масштаба.",
			"choices": [
				{"id": "tour", "label": "Принять лично", "money": -40, "scandal": 1, "popularity": 7},
				{"id": "vip", "label": "VIP-приём за доплату", "money": 90, "scandal": 2, "popularity": 4},
				{"id": "hide", "label": "Спрятаться за дублем", "money": 0, "scandal": -1, "popularity": -1},
			]},
		{"id": "absurd_algo_prefs", "name": "Алгоритм меняет предпочтения", "cat": "absurd",
			"blurb": "Алгоритм Любви внезапно решил, что все любят скандал.",
			"choices": [
				{"id": "adapt", "label": "Подстроиться", "money": -20, "scandal": 2, "popularity": 4},
				{"id": "rollback", "label": "Откатить настройки", "money": -60, "scandal": -2, "popularity": 1},
				{"id": "chaos", "label": "Усилить хаос", "money": 30, "scandal": 5, "popularity": 5},
			]},
		{"id": "absurd_scandal_object", "name": "Скандал стал предметом", "cat": "absurd",
			"blurb": "Скандал материализовался в коробку. Её можно сложить на склад.",
			"choices": [
				{"id": "store", "label": "Спрятать на складе", "money": -10, "scandal": -3, "popularity": 0},
				{"id": "sell", "label": "Продать коллекционерам", "money": 70, "scandal": 1, "popularity": 2},
				{"id": "open", "label": "Открыть при всех", "money": 0, "scandal": 4, "popularity": 5},
			]},
		{"id": "absurd_clone_clones", "name": "Дубли хотят дублей", "cat": "absurd",
			"blurb": "Твои копии устроили митинг: им нужны помощники, чтобы ты стал ещё вездесущее.",
			"choices": [
				{"id": "make", "label": "Создать ещё дублей", "money": -100, "scandal": 1, "popularity": 3},
				{"id": "calm", "label": "Успокоить премией", "money": -50, "scandal": -1, "popularity": 1},
				{"id": "no", "label": "Отказать и держать строй", "money": 0, "scandal": 2, "popularity": 0},
			]},
	]
	var out: Dictionary = {}
	for t in templates:
		var eid := str(t["id"])
		out[eid] = {
			"id": t["id"],
			"name": t["name"],
			"category": t["cat"],
			"blurb": t["blurb"],
			"choices": t["choices"],
			"requires": _event_requires(eid),
		}
	_apply_alpha_lore(out)
	return out


static func _event_requires(id: String) -> Dictionary:
	## Gates: no clone plots before you actually have doubles.
	match id:
		"prep_same_outfit", "sched_late", "media_viral", "media_sponsor", "media_clone_fan", \
		"tech_copy", "tech_wrong_color", "tech_one_outfit", "tech_random_names", "tech_reverse", \
		"ask_clone", "absurd_clone_clones":
			return {"clones_min": 1, "min_stage": 4, "needs_scientist": true}
		"prep_gift_swap", "prep_no_clothes", "prep_bad_style":
			return {"min_stage": 2}
		"sched_manager_date":
			return {"min_stage": 2, "needs_staff": true}
		"sched_double":
			return {"clones_min": 1, "min_stage": 4, "needs_scientist": true}
		"absurd_planet", "absurd_delegation", "absurd_algo_prefs", "absurd_scandal_object":
			return {"min_stage": 5}
		_:
			return {"min_stage": 2}


static func _apply_alpha_lore(out: Dictionary) -> void:
	## Hard rule: doubles are YOU. Girls never "pick a clone" — they think it's the same man.
	var lore := {
		"prep_gift_swap": {
			"name": "Не тот подарок",
			"blurb": "Ты схватил не ту коробку по дороге на свидание. Она уже ждёт.",
			"choices": [
				{"id": "return", "label": "Срочно заменить подарок", "money": -15, "scandal": -1, "popularity": 1},
				{"id": "apologize", "label": "Купить другой и извиниться", "money": -40, "scandal": -2, "popularity": 2},
				{"id": "risk", "label": "Выдать это за шутку", "money": 0, "scandal": 3, "popularity": 1},
			],
		},
		"prep_same_outfit": {
			"name": "Два «ты» — один лук",
			"blurb": "Два твоих дубля вышли в одинаковом. Если их увидят рядом — легенда «один мужчина» треснет.",
			"choices": [
				{"id": "split", "label": "Развести по разным районам", "money": -20, "scandal": -1, "popularity": 1},
				{"id": "buy", "label": "Срочно сменить образ одному", "money": -60, "scandal": -2, "popularity": 2},
				{"id": "meme", "label": "Сыграть в «вездесущий стиль»", "money": 15, "scandal": 2, "popularity": 4},
			],
		},
		"sched_double": {
			"name": "Два свидания в одно время",
			"blurb": "Ты (оригинал) и твой дубль записаны на одно и то же время. Девушки не должны встретиться.",
			"choices": [
				{"id": "split", "label": "Развести локации", "money": -25, "scandal": -2, "popularity": 1},
				{"id": "delay", "label": "Отложить одно на час", "money": -10, "scandal": 1, "popularity": 0},
				{"id": "chaos", "label": "Рискнуть и надеяться", "money": 0, "scandal": 4, "popularity": 2},
			],
		},
		"sched_late": {
			"name": "Дубль застрял в лифте",
			"blurb": "Один из «тебя» застрял. Девушка ждёт «тебя» и не знает про дублей.",
			"choices": [
				{"id": "pay", "label": "Компенсировать и извиниться как ты", "money": -35, "scandal": -1, "popularity": 1},
				{"id": "speed", "label": "Подменить другим дублем незаметно", "money": -15, "scandal": 0, "popularity": 2},
				{"id": "blame", "label": "Списать на пробки", "money": 0, "scandal": 2, "popularity": 0},
			],
		},
		"sched_long": {
			"name": "Свидание затянулось",
			"blurb": "Ты засиделся. Следующая девушка уже пишет «ты где?».",
			"choices": [
				{"id": "cut", "label": "Мягко завершить", "money": 0, "scandal": 1, "popularity": 0},
				{"id": "bonus", "label": "Остаться — качество важнее", "money": -20, "scandal": -1, "popularity": 3},
				{"id": "wait", "label": "Послать дубля на следующую", "money": 5, "scandal": 0, "popularity": 2},
			],
		},
		"media_viral": {
			"name": "Ты стал вирусным",
			"blurb": "Ролик, где «ты» (на самом деле дубль) творишь чудеса, набрал миллион просмотров.",
			"choices": [
				{"id": "cash", "label": "Монетизировать хайп", "money": 80, "scandal": 1, "popularity": 5},
				{"id": "brand", "label": "Серия «вездесущий я»", "money": -30, "scandal": 0, "popularity": 8},
				{"id": "low", "label": "Приглушить, пока не спалились", "money": 0, "scandal": -2, "popularity": 2},
			],
		},
		"media_fail_news": {
			"name": "Провал в новостях",
			"blurb": "Тебя высмеяли в эфире. Репутация альфы под ударом.",
			"choices": [
				{"id": "pr", "label": "Заплатить PR", "money": -70, "scandal": -3, "popularity": 1},
				{"id": "own", "label": "Признать и пошутить", "money": 0, "scandal": 1, "popularity": 3},
				{"id": "double", "label": "Удвоить скандал ради хайпа", "money": 20, "scandal": 5, "popularity": 6},
			],
		},
		"media_sponsor": {
			"name": "Спонсор со странным условием",
			"blurb": "Спонсор платит, если на всех твоих свиданиях будет его логотип. Девушки должны видеть одного и того же тебя.",
			"choices": [
				{"id": "accept", "label": "Принять контракт", "money": 120, "scandal": 2, "popularity": 2},
				{"id": "negotiate", "label": "Торговаться", "money": 40, "scandal": 0, "popularity": 1},
				{"id": "refuse", "label": "Отказаться", "money": 0, "scandal": -1, "popularity": 0},
			],
		},
		"media_clone_fan": {
			"name": "Чат требует «того самого тебя»",
			"blurb": "Зрители помешались на одном образе. Они думают, что это всегда ты — и так и должно быть.",
			"choices": [
				{"id": "star", "label": "Держать этот образ везде", "money": -20, "scandal": 0, "popularity": 5},
				{"id": "rotate", "label": "Чередовать луки осторожно", "money": 0, "scandal": -1, "popularity": 2},
				{"id": "ignore", "label": "Игнорировать чат", "money": 10, "scandal": 1, "popularity": 0},
			],
		},
		"ask_gift": {
			"name": "Просьба: принести подарок",
			"blurb": "Она хочет, чтобы именно ты (как она думает — один-единственный) принёс подарок лично.",
			"choices": [
				{"id": "yes", "label": "Пойти самому", "money": -25, "scandal": -1, "popularity": 3},
				{"id": "clone", "label": "Послать дубля — для неё это всё равно ты", "money": -10, "scandal": 1, "popularity": 1},
				{"id": "no", "label": "Отказать", "money": 0, "scandal": 0, "popularity": -1},
			],
		},
		"ask_room": {
			"name": "Просьба: улучшить место",
			"blurb": "Она хочет красивее обстановку для ваших встреч. Это про твой статус, не про «заведение».",
		},
		"ask_manual": {
			"name": "Просьба: только ты",
			"blurb": "Она чувствует фальшь автопилота и просит встречу «по-настоящему». Для неё дубли — всё равно ты; для тебя это внимание.",
			"choices": [
				{"id": "yes", "label": "Согласиться лично", "money": 0, "scandal": -1, "popularity": 3},
				{"id": "delay", "label": "Перенести на завтра", "money": -5, "scandal": 0, "popularity": 1},
				{"id": "no", "label": "Отказать", "money": 0, "scandal": 1, "popularity": -2},
			],
		},
		"ask_clone": {
			"name": "Дубль {double} уже занят",
			"blurb": "Расписание трещит: один «ты» на свидании, другая девушка зовёт «тебя» же. Нужно решить, кого подменить — она не должна узнать, что вас двое.",
			"choices": [
				{"id": "yes", "label": "Подменить другим дублем",
					"money": -10, "scandal": 0, "popularity": 2},
				{"id": "premium", "label": "Пойти сам и сорвать другое",
					"money": 0, "scandal": 1, "popularity": 1},
				{"id": "random", "label": "Кинуть жребий между дублями",
					"money": 0, "scandal": 1, "popularity": -1},
			],
		},
		"tech_copy": {
			"name": "Дубли синхронизировались",
			"blurb": "Два «тебя» начали говорить одними фразами. Если девушки сравнят переписки — конец мифу.",
		},
		"tech_wrong_color": {
			"name": "Дубль вышел не тем",
			"blurb": "Матрица выдала кислотно-зелёного «тебя». Девушка ждёт привычный образ.",
		},
		"absurd_clone_clones": {
			"name": "Дубли хотят дублей",
			"blurb": "Твои копии устроили митинг: им нужны помощники, чтобы ты стал ещё вездесущее. Абсурд, но это твоя империя.",
		},
		"media_meme_fit": {
			"blurb": "Твой наряд стал мемом. Альфа-бренд или срочная смена имиджа?",
		},
	}
	for id in lore.keys():
		if not out.has(id):
			continue
		var patch: Dictionary = lore[id]
		for k in patch.keys():
			out[id][k] = patch[k]
