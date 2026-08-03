class_name CityBuilder
extends RefCounted
## Builds the -X city district: street, locations, props, spawn points.


static func build(parent: Node3D, add_interact: Callable, box: Callable, label: Callable) -> Dictionary:
	## Returns {spots: {home_spot: [Vector3,...]}, waypoints: [Vector3,...]}
	var city := Node3D.new()
	city.name = "CityDistrict"
	parent.add_child(city)

	# Road strip along -X
	box.call(city, Vector3(52, 0.08, 10), Vector3(-30, -0.04, 0), Color(0.22, 0.22, 0.24))
	box.call(city, Vector3(52, 0.06, 2.2), Vector3(-30, 0.01, 5.5), Color(0.45, 0.45, 0.42)) # north sidewalk
	box.call(city, Vector3(52, 0.06, 2.2), Vector3(-30, 0.01, -5.5), Color(0.45, 0.45, 0.42))

	# Street lamps / signs
	for i in range(8):
		var x := -8.0 - i * 5.5
		box.call(city, Vector3(0.12, 2.4, 0.12), Vector3(x, 1.2, 4.2), Color(0.35, 0.35, 0.38))
		box.call(city, Vector3(0.4, 0.12, 0.4), Vector3(x, 2.45, 4.2), Color(1.0, 0.92, 0.55))
		box.call(city, Vector3(0.12, 2.4, 0.12), Vector3(x, 1.2, -4.2), Color(0.35, 0.35, 0.38))
		box.call(city, Vector3(0.4, 0.12, 0.4), Vector3(x, 2.45, -4.2), Color(1.0, 0.92, 0.55))

	label.call(city, Vector3(-12, 3.2, 0), "ГОРОД")

	var spots: Dictionary = {}
	var waypoints: Array = []

	_plaza(city, add_interact, box, label, spots, waypoints)
	_corner_shop(city, add_interact, box, label, spots, waypoints)
	_internet_cafe(city, add_interact, box, label, spots, waypoints)
	_gym(city, add_interact, box, label, spots, waypoints)
	_park(city, add_interact, box, label, spots, waypoints)
	_night_bar(city, add_interact, box, label, spots, waypoints)
	_bus_stop(city, add_interact, box, label, spots, waypoints)

	# Entrance home door near apartment
	add_interact.call(city, Vector3(-6.5, 0, 0), "Подъезд / Домой", "Войти домой", &"go_home", {}, &"door")

	# Cross-street waypoints
	for x in [-10.0, -16.0, -22.0, -28.0, -34.0, -40.0, -46.0]:
		waypoints.append(Vector3(x, 0.0, 1.5))
		waypoints.append(Vector3(x, 0.0, -1.5))

	return {"root": city, "spots": spots, "waypoints": waypoints}


static func _push_spot(spots: Dictionary, key: String, pos: Vector3) -> void:
	if not spots.has(key):
		spots[key] = []
	(spots[key] as Array).append(pos)


static func _plaza(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-12, 0, 0)
	box.call(city, Vector3(8, 0.1, 8), o + Vector3(0, -0.02, 0), Color(0.5, 0.48, 0.45))
	box.call(city, Vector3(1.6, 0.45, 0.5), o + Vector3(-2, 0.25, 2), Color(0.4, 0.3, 0.22)) # bench
	box.call(city, Vector3(1.6, 0.45, 0.5), o + Vector3(2, 0.25, -2), Color(0.4, 0.3, 0.22))
	box.call(city, Vector3(0.8, 1.2, 0.8), o + Vector3(0, 0.6, 0), Color(0.35, 0.55, 0.4)) # fountain-ish
	label.call(city, o + Vector3(0, 2.6, -3.5), "Площадь")
	add_interact.call(city, o + Vector3(0, 0, 2.5), "Скамейка", "Отдохнуть (+внимание)", &"city_rest", {}, &"desk")
	_push_spot(spots, "street_plaza", o + Vector3(-2.5, 0, 1.5))
	_push_spot(spots, "street_plaza", o + Vector3(2.2, 0, -1.2))
	_push_spot(spots, "street_plaza", o + Vector3(0.5, 0, 2.8))
	waypoints.append(o + Vector3(-2, 0, 0))
	waypoints.append(o + Vector3(2, 0, 1))


static func _corner_shop(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-18, 0, -6)
	box.call(city, Vector3(6, 0.15, 5), o + Vector3(0, -0.05, 0), Color(0.55, 0.4, 0.35))
	box.call(city, Vector3(6, 2.8, 0.2), o + Vector3(0, 1.4, -2.4), Color(0.7, 0.55, 0.45))
	box.call(city, Vector3(0.2, 2.8, 5), o + Vector3(-2.9, 1.4, 0), Color(0.65, 0.5, 0.4))
	box.call(city, Vector3(0.2, 2.8, 5), o + Vector3(2.9, 1.4, 0), Color(0.65, 0.5, 0.4))
	label.call(city, o + Vector3(0, 2.8, 0), "Магазин «Уголок»")
	add_interact.call(city, o + Vector3(-1.2, 0, 0.5), "Цветы со скидкой", "Купить цветок (−20%)", &"city_buy_gift", {"gift_id": "flower", "discount": 0.8}, &"shelf")
	add_interact.call(city, o + Vector3(1.2, 0, 0.5), "Конфеты", "Купить конфеты", &"city_buy_gift", {"gift_id": "candy", "discount": 0.9}, &"shelf")
	_push_spot(spots, "corner_shop", o + Vector3(0, 0, 1.5))
	_push_spot(spots, "corner_shop", o + Vector3(-1.5, 0, -0.5))
	waypoints.append(o + Vector3(0, 0, 2))


static func _internet_cafe(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-22, 0, 6)
	box.call(city, Vector3(7, 0.15, 5), o + Vector3(0, -0.05, 0), Color(0.25, 0.28, 0.35))
	box.call(city, Vector3(7, 2.6, 0.2), o + Vector3(0, 1.3, 2.4), Color(0.2, 0.45, 0.7))
	box.call(city, Vector3(0.2, 2.6, 5), o + Vector3(-3.4, 1.3, 0), Color(0.3, 0.32, 0.4))
	box.call(city, Vector3(0.2, 2.6, 5), o + Vector3(3.4, 1.3, 0), Color(0.3, 0.32, 0.4))
	label.call(city, o + Vector3(0, 2.7, 0), "Интернет-кафе")
	add_interact.call(city, o + Vector3(-1.5, 0, 0), "ПК №1", "Поработать онлайн", &"city_cafe_job", {}, &"console")
	add_interact.call(city, o + Vector3(1.5, 0, 0), "ПК №2", "Скроллить (+популярность)", &"city_cafe_scroll", {}, &"console")
	add_interact.call(city, o + Vector3(0, 0, -1.5), "Кофейня", "Купить кофе (+внимание)", &"city_coffee", {}, &"desk")
	_push_spot(spots, "internet_cafe", o + Vector3(-2, 0, 1))
	_push_spot(spots, "internet_cafe", o + Vector3(2, 0, 1))
	waypoints.append(o + Vector3(0, 0, -2.5))


static func _gym(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-30, 0, -7)
	box.call(city, Vector3(6, 0.15, 5), o + Vector3(0, -0.05, 0), Color(0.35, 0.4, 0.35))
	box.call(city, Vector3(6, 3.0, 0.2), o + Vector3(0, 1.5, -2.4), Color(0.2, 0.75, 0.4))
	label.call(city, o + Vector3(0, 2.9, 0), "Фитнес-зал")
	add_interact.call(city, o + Vector3(0, 0, 0.5), "Тренажёр", "Потренироваться", &"city_workout", {}, &"machine")
	add_interact.call(city, o + Vector3(-1.8, 0, -0.5), "Абонемент", "Купить (+макс. внимание)", &"city_gym_pass", {}, &"poster")
	_push_spot(spots, "gym_front", o + Vector3(1.5, 0, 1.2))
	_push_spot(spots, "gym_front", o + Vector3(-1.2, 0, 1.5))
	waypoints.append(o + Vector3(0, 0, 2.2))


static func _park(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-36, 0, 4)
	box.call(city, Vector3(9, 0.08, 7), o + Vector3(0, -0.02, 0), Color(0.28, 0.5, 0.3))
	box.call(city, Vector3(1.2, 1.8, 1.2), o + Vector3(-2.5, 0.9, -1.5), Color(0.25, 0.45, 0.2))
	box.call(city, Vector3(1.2, 1.8, 1.2), o + Vector3(2.5, 0.9, 1.2), Color(0.25, 0.45, 0.2))
	box.call(city, Vector3(1.8, 0.4, 0.55), o + Vector3(0, 0.25, 0), Color(0.4, 0.3, 0.2))
	label.call(city, o + Vector3(0, 2.6, -3), "Парк")
	add_interact.call(city, o + Vector3(0, 0, 1.5), "Скамейка в парке", "Посидеть", &"city_rest", {"bonus": 1.5}, &"desk")
	add_interact.call(city, o + Vector3(2, 0, -1), "Кормушка", "Покормить уток (+⭐)", &"city_park_fun", {}, &"shelf")
	_push_spot(spots, "park", o + Vector3(-1.5, 0, 0.8))
	_push_spot(spots, "park", o + Vector3(1.8, 0, -0.5))
	_push_spot(spots, "park", o + Vector3(0, 0, 2.2))
	waypoints.append(o + Vector3(-3, 0, 0))
	waypoints.append(o + Vector3(3, 0, 1))


static func _night_bar(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-44, 0, -5)
	box.call(city, Vector3(7, 0.15, 5), o + Vector3(0, -0.05, 0), Color(0.2, 0.12, 0.18))
	box.call(city, Vector3(7, 2.8, 0.2), o + Vector3(0, 1.4, -2.4), Color(0.55, 0.1, 0.35))
	label.call(city, o + Vector3(0, 2.8, 0), "Ночной бар")
	add_interact.call(city, o + Vector3(-1, 0, 0.5), "Барная стойка", "Выпить (−$ +скандал/⭐)", &"city_bar_drink", {}, &"desk")
	add_interact.call(city, o + Vector3(1.5, 0, 0.5), "Караоке", "Спеть (+⭐ +скандал)", &"city_karaoke", {}, &"console")
	_push_spot(spots, "night_bar", o + Vector3(0, 0, 1.6))
	_push_spot(spots, "night_bar", o + Vector3(-2, 0, 0.8))
	waypoints.append(o + Vector3(0, 0, 2.5))


static func _bus_stop(city: Node3D, add_interact: Callable, box: Callable, label: Callable, spots: Dictionary, waypoints: Array) -> void:
	var o := Vector3(-50, 0, 0)
	box.call(city, Vector3(5, 0.1, 4), o + Vector3(0, -0.02, 0), Color(0.4, 0.4, 0.42))
	box.call(city, Vector3(3.5, 0.08, 1.2), o + Vector3(0, 1.6, -1.2), Color(0.55, 0.55, 0.6)) # roof
	box.call(city, Vector3(0.15, 1.6, 0.15), o + Vector3(-1.6, 0.8, -1.2), Color(0.4, 0.4, 0.45))
	box.call(city, Vector3(0.15, 1.6, 0.15), o + Vector3(1.6, 0.8, -1.2), Color(0.4, 0.4, 0.45))
	label.call(city, o + Vector3(0, 2.5, 0), "Остановка")
	add_interact.call(city, o + Vector3(0, 0, 0.8), "Расписание", "Посмотреть маршруты", &"city_bus_info", {}, &"poster")
	add_interact.call(city, o + Vector3(1.5, 0, 0), "Автомат", "Купить сувенир-конфеты", &"city_buy_gift", {"gift_id": "candy", "discount": 1.0}, &"machine")
	_push_spot(spots, "bus_stop", o + Vector3(-1.2, 0, 0.5))
	_push_spot(spots, "bus_stop", o + Vector3(1.0, 0, 1.0))
	waypoints.append(o + Vector3(0, 0, 1.5))
