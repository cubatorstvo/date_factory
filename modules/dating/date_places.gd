class_name DatePlaces
extends RefCounted
## Static definitions for bookable date venues (home / cafe / park / restaurant).


static func places() -> Array:
	return [
		{
			"id": "home",
			"venue_id": "kitchen_table",
			"name": "У себя дома",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.0,
			"tags": ["уютно", "бесплатно", "требует подготовки"],
			"blurb": "Простая домашняя встреча. Дешёвая посуда, обычная еда и минимум церемоний.",
		},
		{
			"id": "cafe",
			"venue_id": "cheap_cafe",
			"name": "Кафе «Two Hearts»",
			"cost": 30,
			"requires_prep": false,
			"base_quality": 1.6,
			"tags": ["неформально", "кофе", "без подготовки"],
			"blurb": "Уличное кафе на главной. Недорого, без домашнего prep — просто приди и сядь.",
		},
		{
			"id": "park",
			"venue_id": "park",
			"name": "Парк Leisure",
			"cost": 0,
			"requires_prep": false,
			"base_quality": 1.8,
			"tags": weather_tags(),
			"blurb": "Бесплатная прогулка: утки, киоск и плед. Открывается с парковым районом.",
		},
		{
			"id": "restaurant",
			"venue_id": "restaurant",
			"name": "Ресторан «Two Hearts»",
			"cost": 90,
			"requires_prep": false,
			"base_quality": 2.4,
			"tags": ["формально", "высокая сервировка", "дорого"],
			"blurb": "Дорогой зал у парка. Бронь после unlock парка или venue restaurant.",
		},
		{
			"id": "cinema",
			"venue_id": "cinema_room",
			"name": "Кинотеатр Leisure",
			"cost": 45,
			"requires_prep": false,
			"base_quality": 2.0,
			"tags": ["медиа", "без подготовки", "короче обычного"],
			"blurb": "Сеанс на двоих: жанр → реакции → разговор. Открывается с парком или stage_3.",
		},
		{
			"id": "arcade",
			"venue_id": "cheap_cafe",
			"name": "Аркада «Перегруз»",
			"cost": 25,
			"requires_prep": false,
			"base_quality": 1.7,
			"tags": ["игра", "парный минигейм", "без подготовки"],
			"blurb": "Автомат «Парный перегруз»: совместный счёт и мягкий бонд. С парковым районом.",
		},
		{
			"id": "apt_cozy",
			"venue_id": "kitchen_table",
			"name": "Квартира «Уют»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.3,
			"tags": ["уютно", "тематическая", "дом"],
			"blurb": "Тёплая тематическая квартира. Открывается после первого клона или stage_4.",
		},
		{
			"id": "apt_modern",
			"venue_id": "kitchen_table",
			"name": "Квартира «Модерн»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.5,
			"tags": ["современно", "тематическая", "дом"],
			"blurb": "Холодный минимализм. Отдельный этаж через лифт.",
		},
		{
			"id": "apt_creative",
			"venue_id": "kitchen_table",
			"name": "Квартира «Креатив»",
			"cost": 0,
			"requires_prep": true,
			"base_quality": 1.4,
			"tags": ["творчески", "тематическая", "дом"],
			"blurb": "Яркая мастерская-квартира для свиданий и назначения агентства.",
		},
	]


static func place(id: String) -> Dictionary:
	for p in places():
		if str(p.get("id", "")) == id:
			return p
	return {}


static func homeware_label(level: int) -> String:
	match clampi(level, 1, 4):
		1:
			return "Что было в шкафу"
		2:
			return "Нормальный набор"
		3:
			return "Продуманная сервировка"
		4:
			return "Домашний ресторан"
		_:
			return "Простая посуда"


static func homeware_blurb(level: int) -> String:
	match clampi(level, 1, 4):
		1:
			return "Разномастная дешёвая посуда, простые стаканы."
		2:
			return "Одинаковые тарелки и стеклянные стаканы."
		3:
			return "Хорошие тарелки, бокалы, скатерть."
		4:
			return "Дорогая посуда и красивая композиция."
		_:
			return ""


static func home_quality(level: int, food_tier: int, drink_tier: int) -> float:
	var q := 0.6 + float(level) * 0.35
	q += float(food_tier) * 0.25
	q += float(drink_tier) * 0.15
	return q


static func food_options() -> Array:
	return [
		{"id": "simple_meal", "name": "Простая домашняя еда", "tier": 1, "blurb": "Сытно и без претензий."},
		{"id": "snack_plate", "name": "Закуски", "tier": 1, "blurb": "Лёгкая тарелка на двоих."},
		{"id": "nice_meal", "name": "Аккуратное блюдо", "tier": 2, "blurb": "Выглядит заботливее обычного ужина."},
		{"id": "dessert", "name": "Домашний десерт", "tier": 2, "blurb": "Сладкий жест без ресторана."},
	]


static func drink_options() -> Array:
	return [
		{"id": "water", "name": "Вода", "tier": 1, "blurb": "Честно и бесплатно."},
		{"id": "juice", "name": "Дешёвый сок", "tier": 2, "blurb": "Хоть какая-то церемония."},
		{"id": "wine", "name": "Недорогое вино", "tier": 3, "blurb": "Попытка сделать вечер особенным."},
	]


static func shop_catalog() -> Dictionary:
	return {
		"flower_shop": {
			"name": "Цветочный",
			"kind": "gift",
			"items": ["flower", "bouquet"],
		},
		"jewelry_shop": {
			"name": "Ювелирный",
			"kind": "gift",
			"items": ["bracelet", "gold_ring", "diamond"],
		},
		"gift_shop": {
			"name": "Подарки",
			"kind": "gift",
			"items": ["candy", "bear", "cake", "perfume"],
		},
		"clothing_shop": {
			"name": "Одежда",
			"kind": "outfit",
			"items": ["casual", "cheap_formal", "sport"],
		},
		"homeware_shop": {
			"name": "Дом и посуда",
			"kind": "homeware",
			"items": ["homeware_next"],
		},
		"bookstore": {
			"name": "Книжный Leisure",
			"kind": "gift",
			"items": ["paperback", "poetry_book", "rare_novel"],
		},
	}


static func clothing_shop_items() -> Array:
	## sport listed only after style unlock / ownership.
	var items: Array = []
	items.append("casual")
	items.append("cheap_formal")
	var sport_unlocked: bool = false
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.root.get_node_or_null("Game") if tree != null else null
	if game != null:
		var inv: Node = game.get("inventory") as Node
		if inv != null and inv.has_method("own_outfit") and bool(inv.call("own_outfit", &"sport")):
			sport_unlocked = true
		var ups: Node = game.get("upgrades") as Node
		if not sport_unlocked and ups != null:
			var owned: Variant = ups.get("owned")
			if owned is Array and (owned as Array).has(&"ward_style_sport"):
				sport_unlocked = true
	if sport_unlocked:
		items.append("sport")
	return items


static func is_restaurant_bookable() -> bool:
	## Expensive restaurant stays gated until venue or park district unlock.
	if Game == null or Game.facility == null:
		return false
	if Game.facility.is_venue_unlocked(&"restaurant"):
		return true
	return is_park_bookable()


static func is_park_bookable() -> bool:
	## Park date unlocks with park_leisure district (stage_2 / venue_park).
	if Game == null:
		return false
	if Game.city != null and Game.city.has_method("is_district_unlocked"):
		return bool(Game.city.call("is_district_unlocked", &"park_leisure"))
	if Game.facility != null:
		if Game.facility.is_venue_unlocked(&"park"):
			return true
		return Game.facility.has_flag("district_park_leisure")
	return false


static func is_leisure_unlocked() -> bool:
	## Gym / bookstore / cinema / arcade share park_leisure or stage_2+.
	if is_park_bookable():
		return true
	if Game == null:
		return false
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= 2


static func is_cinema_bookable() -> bool:
	if is_park_bookable():
		return true
	if Game == null:
		return false
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	if int(order.get(str(Game.stage_id), 1)) >= 3:
		return true
	if Game.facility != null and Game.facility.is_venue_unlocked(&"cinema_room"):
		return true
	return false


static func is_arcade_bookable() -> bool:
	return is_leisure_unlocked()


static func is_themed_apartment_bookable(place_id: String) -> bool:
	if not place_id.begins_with("apt_"):
		return false
	if Game == null or Game.city == null:
		return false
	if Game.city.has_method("is_apartment_unlocked"):
		return bool(Game.city.call("is_apartment_unlocked", StringName(place_id)))
	return false


static func is_agency_row_unlocked() -> bool:
	## Photo studio / barber / agency board — stage_3 or agency room.
	if Game == null:
		return false
	if Game.city != null and Game.city.has_method("is_district_unlocked"):
		if bool(Game.city.call("is_district_unlocked", CityDistricts.AGENCY_ROW)):
			return true
	if Game.facility != null:
		if Game.facility.room_unlocked(&"agency"):
			return true
		return Game.facility.has_flag("district_agency_row")
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= 3


static func current_weather() -> String:
	## Lightweight mood tag for park dates (no full weather sim).
	if Game == null or Game.time == null:
		return "clear"
	var day: int = int(Game.time.day)
	var mins: int = int(Game.time.clock_minutes())
	var bucket: int = day * 17 + int(mins / 60.0)
	if bucket % 5 == 0:
		return "rain"
	if mins >= 12 * 60 and mins < 17 * 60:
		return "warm"
	return "clear"


static func weather_tags() -> Array:
	match current_weather():
		"rain":
			return ["на улице", "бесплатно", "риск дождя"]
		"warm":
			return ["на улице", "бесплатно", "тепло", "мороженое"]
		_:
			return ["на улице", "бесплатно", "без подготовки", "утки"]
