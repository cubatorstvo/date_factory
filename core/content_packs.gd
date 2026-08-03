class_name ContentPacks
extends RefCounted
## All replaceable content packs. Edit here to expand/replace systems without touching APIs.


static func balance() -> Dictionary:
	return {
		"start_money": 40.0,
		"start_attention": 3.0,
		"max_attention_base": 3.0,
		"job_pay": 25.0,
		"manual_date_seconds": 60.0,
		"auto_date_seconds": 12.0,
		"relation_thresholds": [0.0, 10.0, 25.0, 50.0, 90.0],
		"stage_popularity": {
			"stage_2": 5.0,
			"stage_3": 20.0,
			"stage_4": 50.0,
			"stage_5": 110.0,
			"stage_6": 220.0,
		},
		"finale_need_dates": 40,
		"finale_need_popularity": 300.0,
		"postgame_goals": [
			{"id": "dates_100", "label": "Провести 100 свиданий", "type": "dates", "target": 100},
			{"id": "pop_1000", "label": "Набрать 1000 популярности", "type": "popularity", "target": 1000},
			{"id": "zero_scandal", "label": "Снизить скандал до 0", "type": "scandal_max", "target": 0},
			{"id": "clones_8", "label": "Иметь 8 клонов", "type": "clones", "target": 8},
		],
	}


static func builtin_names() -> PackedStringArray:
	return PackedStringArray([
		"Пельмень", "Nagibator", "DedInside", "MegaBoss", "КираЧат", "ВасяКрип",
		"Лолипоп", "Шаурма", "Борщ", "Котлета", "Пиксель", "Глюкоза",
		"Капибара", "Суши", "Тостер", "Утюг", "Мопед", "Батон",
		"Чипсы", "Кактус", "Пончик", "Йогурт", "Редиска", "Комета",
		"Бублик", "Сметана", "Пельмеш", "Хлебушек", "Ватрушка", "Кефир",
		"Алиса", "Марина", "Соня", "Лера", "Ника", "Даша", "Полина", "Катя",
		"Юля", "Настя", "Вика", "Оля", "Таня", "Лиза", "Ира", "Женя",
		"Мила", "Аня", "Света", "Рита", "Кира", "Зоя", "Вера", "Лада",
	])


static func gifts() -> Dictionary:
	var list := [
		_g("flower", "Один цветок", "cheap", 5, 1, ["sincere", "cheap"], Color(1, 0.4, 0.6)),
		_g("bouquet", "Букет", "romantic", 15, 2, ["romantic", "sincere"], Color(1, 0.2, 0.5)),
		_g("candy", "Коробка конфет", "tasty", 12, 2, ["tasty", "cheap"], Color(0.6, 0.3, 0.1)),
		_g("bear", "Плюшевый медведь", "cheap", 18, 2, ["sincere", "cute"], Color(0.8, 0.6, 0.3)),
		_g("coffee_coupon", "Купон на кофе", "cheap", 8, 1, ["cheap", "casual"], Color(0.5, 0.3, 0.1)),
		_g("perfume", "Духи", "fashion", 35, 3, ["fashion", "luxury"], Color(0.7, 0.5, 0.9)),
		_g("bracelet", "Браслет", "fashion", 40, 3, ["fashion", "romantic"], Color(0.9, 0.8, 0.2)),
		_g("shoes", "Туфли", "fashion", 55, 3, ["fashion"], Color(0.2, 0.2, 0.2)),
		_g("rare_dress", "Редкое платье", "fashion", 90, 4, ["fashion", "luxury"], Color(0.9, 0.1, 0.4)),
		_g("sport_food", "Спортивное питание", "useful", 30, 3, ["sport", "useful"], Color(0.2, 0.8, 0.3)),
		_g("dark_candle", "Мрачная свеча", "dark", 22, 3, ["dark", "weird"], Color(0.3, 0.1, 0.4)),
		_g("skull", "Коллекционный череп", "dark", 45, 4, ["dark", "weird", "scandal"], Color(0.85, 0.85, 0.8)),
		_g("cake", "Домашний торт", "tasty", 20, 3, ["tasty", "sincere"], Color(1, 0.7, 0.8)),
		_g("rare_ingredient", "Редкий ингредиент", "tasty", 60, 4, ["tasty", "tech"], Color(0.9, 0.5, 0.1)),
		_g("phone", "Новый телефон", "tech", 120, 4, ["tech", "media"], Color(0.2, 0.2, 0.3)),
		_g("robo_pet", "Робот-питомец", "tech", 150, 5, ["tech", "weird"], Color(0.4, 0.8, 1)),
		_g("gold_ring", "Золотое кольцо", "luxury", 200, 5, ["luxury", "romantic"], Color(1, 0.85, 0.2)),
		_g("diamond", "Бриллиант", "luxury", 350, 6, ["luxury"], Color(0.7, 0.9, 1)),
		_g("car_key", "Ключ без автомобиля", "absurd", 80, 3, ["absurd", "scandal"], Color(0.9, 0.9, 0.1)),
		_g("hero_statue", "Маленькая статуя героя", "absurd", 100, 4, ["absurd", "media"], Color(0.6, 0.6, 0.7)),
		_g("named_star", "Именная звезда", "luxury", 280, 5, ["luxury", "media"], Color(1, 1, 0.6)),
		_g("moon_chunk", "Кусок Луны", "absurd", 400, 6, ["absurd", "space", "tech"], Color(0.8, 0.8, 0.9)),
		_g("personal_planet", "Персональная планета", "absurd", 800, 8, ["absurd", "space", "luxury"], Color(0.3, 0.5, 1)),
		_g("romance_cert", "Сертификат «романтика»", "absurd", 500, 7, ["absurd", "media", "scandal"], Color(1, 0.3, 0.6)),
	]
	var out := {}
	for g in list:
		out[g["id"]] = g
	return out


static func _g(id: String, name: String, category: String, price: float, quality: float, tags: Array, color: Color) -> Dictionary:
	return {
		"id": id, "name": name, "category": category, "price": price, "quality": quality,
		"tags": tags, "color": [color.r, color.g, color.b],
	}


static func outfits() -> Dictionary:
	var list := [
		_o("casual", "Повседневный", "casual", 0, 1, Color(0.4, 0.6, 0.9)),
		_o("cheap_formal", "Дешёвый формальный", "formal", 20, 2, Color(0.3, 0.3, 0.35)),
		_o("sport", "Спортивный", "sport", 35, 3, Color(0.2, 0.8, 0.3)),
		_o("gothic", "Готический", "gothic", 45, 3, Color(0.15, 0.05, 0.2)),
		_o("fashion", "Модный", "fashion", 70, 4, Color(0.9, 0.2, 0.6)),
		_o("business", "Деловой", "business", 80, 4, Color(0.1, 0.15, 0.3)),
		_o("luxury", "Роскошный", "luxury", 150, 5, Color(0.85, 0.7, 0.2)),
		_o("science", "Научный", "science", 90, 4, Color(0.3, 0.8, 0.9)),
		_o("media", "Медийный", "media", 110, 5, Color(1, 0.4, 0.2)),
		_o("space", "Космический", "space", 200, 6, Color(0.4, 0.4, 1)),
		_o("final_absurd", "Абсурдный финальный", "absurd", 300, 8, Color(1, 0.1, 0.8)),
	]
	var out := {}
	for o in list:
		out[o["id"]] = o
	return out


static func _o(id: String, name: String, style: String, price: float, quality: float, color: Color) -> Dictionary:
	return {"id": id, "name": name, "style": style, "price": price, "quality": quality, "color": [color.r, color.g, color.b]}


static func venues() -> Dictionary:
	var list := [
		_v("kitchen_table", "Кухонный стол", 0, 1, 1, ["calm", "cheap"], "stage_1"),
		_v("cheap_cafe", "Дешёвое кафе", 10, 2, 1, ["casual", "cheap"], "stage_2"),
		_v("park", "Парк", 5, 2, 1, ["calm", "sport"], "stage_2"),
		_v("cinema_room", "Кино-комната", 20, 3, 2, ["media", "casual"], "stage_3"),
		_v("restaurant", "Ресторан", 40, 4, 2, ["luxury", "tasty"], "stage_3"),
		_v("photo_studio", "Фотостудия", 35, 3, 2, ["media", "fashion", "scandal"], "stage_4"),
		_v("luxury_hall", "Роскошный зал", 80, 6, 3, ["luxury", "media"], "stage_4"),
		_v("lab_capsule", "Лабораторная капсула", 50, 4, 3, ["tech", "science"], "stage_4"),
		_v("conveyor", "Конвейер свиданий", 15, 2, 6, ["mass", "tech"], "stage_5"),
		_v("orbital_hall", "Орбитальный зал", 200, 8, 2, ["space", "luxury", "tech"], "stage_6"),
	]
	var out := {}
	for v in list:
		out[v["id"]] = v
	return out


static func _v(id: String, name: String, cost: float, quality: float, capacity: int, tags: Array, stage: String) -> Dictionary:
	return {"id": id, "name": name, "cost": cost, "quality": quality, "capacity": capacity, "tags": tags, "unlock_stage": stage}


static func girls() -> Dictionary:
	return {
		"neighbor": _girl("neighbor", "Соседка", Color(0.95, 0.75, 0.7), ["calm"], ["sincere", "cheap", "calm"], ["luxury", "scandal"],
			"Снижает стоимость базовых свиданий и ускоряет восстановление внимания.", "miss_harem",
			{"date_cost_mult": 0.85, "attention_regen": 0.25}, "stage_1", 0),
		"fitness": _girl("fitness", "Фитнес-блогерша", Color(0.3, 0.9, 0.4), ["sport"], ["sport", "useful", "active"], ["cheap"],
			"Повышает запас внимания и ускоряет клонов.", "hate_cheap_outfit",
			{"max_attention": 1.0, "clone_speed": 0.15}, "stage_2", 8),
		"goth": _girl("goth", "Готическая критикесса", Color(0.35, 0.15, 0.45), ["chaos"], ["dark", "weird", "scandal"], ["luxury"],
			"Часть скандала превращается в популярность.", "needs_imperfection",
			{"scandal_to_pop": 0.2}, "stage_2", 12),
		"streamer": _girl("streamer", "Стримерша", Color(1.0, 0.35, 0.55), ["media"], ["media", "fashion", "weird"], ["calm"],
			"Больше популярности от событий; сильнее с Twitch.", "fail_can_pop",
			{"event_pop_mult": 1.35}, "stage_2", 15),
		"business": _girl("business", "Бизнесвумен", Color(0.15, 0.2, 0.35), ["business"], ["luxury", "business"], ["cheap"],
			"Больше денег и дешевле найм менеджеров.", "needs_income_growth",
			{"money_mult": 1.2, "staff_cost_mult": 0.85}, "stage_3", 22),
		"fashionista": _girl("fashionista", "Модница", Color(0.95, 0.3, 0.7), ["fashion"], ["fashion", "luxury"], ["sport"],
			"Открывает автогардероб и усиливает наряды.", "no_repeat_outfit",
			{"outfit_mult": 1.25, "unlock_auto_wardrobe": true}, "stage_3", 28),
		"chef": _girl("chef", "Шеф-повар", Color(1.0, 0.55, 0.2), ["tasty"], ["tasty", "sincere"], ["tech"],
			"Дешевле рестораны и производит еду.", "needs_ingredient",
			{"restaurant_cost_mult": 0.7, "food_income": 5.0}, "stage_3", 35),
		"lawyer": _girl("lawyer", "Юристка", Color(0.55, 0.55, 0.65), ["business"], ["business", "order"], ["chaos", "scandal"],
			"Меньше штрафов от скандалов и ошибок клонов.", "hates_chaos",
			{"scandal_penalty_mult": 0.6, "clone_error_mult": 0.75}, "stage_4", 50),
		"scientist": _girl("scientist", "Учёная", Color(0.35, 0.85, 0.95), ["science"], ["tech", "science"], ["cheap"],
			"Открывает клонирование и ускоряет его.", "wants_experiments",
			{"unlock_clones": true, "clone_cost_mult": 0.8}, "stage_3", 40),
		"star": _girl("star", "Звезда кино", Color(1.0, 0.85, 0.3), ["luxury", "media"], ["luxury", "media"], ["cheap"],
			"Сильный доход от популярности и спонсоры.", "big_scandal_on_fail",
			{"pop_money_mult": 1.5, "unlock_sponsors": true}, "stage_5", 100),
		"alien": _girl("alien", "Инопланетянка", Color(0.4, 1.0, 0.6), ["space"], ["space", "tech", "weird"], ["sincere"],
			"Множит поздние линии и открывает орбитальный сектор.", "misreads_gifts",
			{"line_mult": 1.4, "unlock_orbital": true}, "stage_5", 140),
		"algorithm": _girl("algorithm", "Алгоритм Любви", Color(1.0, 0.2, 0.9), ["space", "science"], ["absurd", "tech", "space"], [],
			"Снимает ограничения и открывает бесконечный режим.", "finale_only",
			{"unlock_postgame": true, "remove_caps": true}, "stage_6", 280),
	}


static func _girl(id: String, archetype: String, color: Color, tags: Array, likes: Array, dislikes: Array, bonus: String, rule: String, effects: Dictionary, stage: String, pop_need: float) -> Dictionary:
	var hair_styles := {"neighbor": "bob", "fitness": "pony", "goth": "long", "streamer": "short", "business": "bun", "fashionista": "long", "chef": "bun", "lawyer": "bob", "scientist": "short", "star": "long", "alien": "short", "algorithm": "bun"}
	var hair_cols := {
		"neighbor": [0.35, 0.2, 0.12], "fitness": [0.15, 0.1, 0.08], "goth": [0.05, 0.05, 0.08],
		"streamer": [0.9, 0.2, 0.55], "business": [0.1, 0.08, 0.08], "fashionista": [0.7, 0.15, 0.4],
		"chef": [0.25, 0.12, 0.08], "lawyer": [0.2, 0.15, 0.12], "scientist": [0.4, 0.55, 0.7],
		"star": [0.85, 0.7, 0.35], "alien": [0.3, 0.9, 0.5], "algorithm": [0.9, 0.2, 0.85],
	}
	return {
		"id": id, "archetype": archetype, "color": [color.r, color.g, color.b], "tags": tags,
		"likes": likes, "dislikes": dislikes, "bonus_desc": bonus, "special_rule": rule,
		"effects": effects, "unlock_stage": stage, "popularity_need": pop_need,
		"hair_style": hair_styles.get(id, "bob"),
		"hair_color": hair_cols.get(id, [0.2, 0.12, 0.08]),
		"eye_color": [0.25, 0.4, 0.55],
		"lines": [
			"Ну... привет?",
			"Интересный подход к романтике.",
			"Ты правда всё это автоматизируешь?",
			"Ок, я в деле. Почти.",
			"Легендарный статус. Не подведи систему.",
		],
	}


static func staff_roles() -> Dictionary:
	return {
		"messenger": {"id": "messenger", "name": "Менеджер переписки", "cost": 80, "stage": "stage_2", "effect": "auto_messages"},
		"stylist": {"id": "stylist", "name": "Стилист", "cost": 120, "stage": "stage_4", "effect": "auto_outfit"},
		"buyer": {"id": "buyer", "name": "Закупщик подарков", "cost": 100, "stage": "stage_4", "effect": "auto_buy_gifts"},
		"coordinator": {"id": "coordinator", "name": "Координатор свиданий", "cost": 150, "stage": "stage_4", "effect": "auto_assign_dates"},
		"pr": {"id": "pr", "name": "PR-менеджер", "cost": 160, "stage": "stage_5", "effect": "reduce_scandal"},
		"tech": {"id": "tech", "name": "Техник клонов", "cost": 140, "stage": "stage_4", "effect": "clone_recover"},
		"lawyer": {"id": "lawyer_staff", "name": "Юрист", "cost": 180, "stage": "stage_5", "effect": "event_discount"},
	}


static func rooms() -> Dictionary:
	return {
		"apartment": {"id": "apartment", "name": "Квартира", "stage": "stage_1", "pos": [0, 0, 0]},
		"neighbor_apt": {"id": "neighbor_apt", "name": "Квартира соседки", "stage": "stage_1", "pos": [0, 0, -10]},
		"office_nook": {"id": "office_nook", "name": "Рабочий уголок", "stage": "stage_2", "pos": [8, 0, 0]},
		"agency": {"id": "agency", "name": "Агентство", "stage": "stage_3", "pos": [18, 0, 0]},
		"mansion": {"id": "mansion", "name": "Особняк / гарем", "stage": "stage_4", "pos": [32, 0, 0]},
		"factory": {"id": "factory", "name": "Фабрика", "stage": "stage_5", "pos": [48, 0, 0]},
		"orbital": {"id": "orbital", "name": "Орбитальный сектор", "stage": "stage_6", "pos": [68, 0, 8]},
	}
