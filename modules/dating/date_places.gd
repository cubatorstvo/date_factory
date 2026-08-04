class_name DatePlaces
extends RefCounted
## Static definitions for bookable date venues (home / restaurant).


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
			"id": "restaurant",
			"venue_id": "restaurant",
			"name": "Ресторан «Two Hearts»",
			"cost": 60,
			"requires_prep": false,
			"base_quality": 2.4,
			"tags": ["формально", "высокая сервировка", "дорого"],
			"blurb": "Уютный ресторан с хорошей сервировкой. Дороже, но надёжнее домашней встречи.",
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
			"items": ["flower", "bouquet"],
		},
		"jewelry_shop": {
			"name": "Ювелирный",
			"items": ["bracelet", "gold_ring", "diamond"],
		},
		"gift_shop": {
			"name": "Подарки",
			"items": ["candy", "bear", "cake", "perfume"],
		},
	}
