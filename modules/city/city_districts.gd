class_name CityDistricts
extends RefCounted
## City hub district unlock flags (Pass 1–4) + gate UI copy.

const MAIN_STREET := &"main_street"
const PARK_LEISURE := &"park_leisure"
const AGENCY_ROW := &"agency_row"


static func default_unlocked() -> Array[StringName]:
	var out: Array[StringName] = [MAIN_STREET]
	return out


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = [MAIN_STREET, PARK_LEISURE, AGENCY_ROW]
	return out


static func gated_ids() -> Array[StringName]:
	var out: Array[StringName] = [PARK_LEISURE, AGENCY_ROW]
	return out


static func info(id: StringName) -> Dictionary:
	## Catalog for DistrictGateUI: title, unlock requirements, contents list.
	match id:
		PARK_LEISURE:
			return {
				"id": PARK_LEISURE,
				"title": "Парк и досуг",
				"subtitle": "Закрытый район за воротами",
				"unlock_text": "Откроется при расширении до статуса 2\nили после открытия площадки «Парк» в штабе.",
				"contents": [
					"Пикник / свидание в парке",
					"Ресторан у парка",
					"Фитнес-зал",
					"Книжный",
					"Кинотеатр",
					"Аркада «Перегруз»",
				],
			}
		AGENCY_ROW:
			return {
				"id": AGENCY_ROW,
				"title": "Ряд агентства",
				"subtitle": "Деловой квартал за барьером",
				"unlock_text": "Откроется при расширении до статуса 3\nили после открытия комнаты «Агентство» в штабе.",
				"contents": [
					"Фотостудия",
					"Барбер",
					"Офис агентства / доска расписания",
				],
			}
		MAIN_STREET:
			return {
				"id": MAIN_STREET,
				"title": "Главная улица",
				"subtitle": "Стартовый район",
				"unlock_text": "Доступен с начала игры.",
				"contents": [
					"Кафе Two Hearts",
					"Магазины (одежда, посуда, подарки)",
					"Скамейки и площадь",
					"Ворота в парк",
				],
			}
		_:
			return {
				"id": id,
				"title": str(id),
				"subtitle": "",
				"unlock_text": "Район ещё закрыт.",
				"contents": [],
			}
