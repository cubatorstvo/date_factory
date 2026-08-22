class_name ApartmentCatalog
extends Resource

@export var objects: Array[ApartmentObjectDefinition] = []


func get_object(object_id: StringName) -> ApartmentObjectDefinition:
	if object_id == &"":
		return null
	for item in objects:
		if item != null and item.id == object_id:
			return item
	return null


func all_objects() -> Array[ApartmentObjectDefinition]:
	var result: Array[ApartmentObjectDefinition] = []
	for item in objects:
		if item != null:
			result.append(item)
	return result


func enabled_objects() -> Array[ApartmentObjectDefinition]:
	var result: Array[ApartmentObjectDefinition] = []
	for item in objects:
		if item != null and item.enabled:
			result.append(item)
	return result


func available_objects(story_stage: int) -> Array[ApartmentObjectDefinition]:
	var indexed: Array = []
	var order: int = 0
	for item in objects:
		if item == null or not item.enabled:
			continue
		if item.min_story_stage > story_stage:
			continue
		indexed.append({"item": item, "order": order})
		order += 1
	indexed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left: ApartmentObjectDefinition = a["item"]
		var right: ApartmentObjectDefinition = b["item"]
		if left.min_story_stage != right.min_story_stage:
			return left.min_story_stage < right.min_story_stage
		return int(a["order"]) < int(b["order"])
	)
	var result: Array[ApartmentObjectDefinition] = []
	for entry in indexed:
		result.append(entry["item"])
	return result

static func create_seed() -> ApartmentCatalog:
	var catalog := ApartmentCatalog.new()
	catalog.objects = [
		_make(&"apartment__plaid", "Плед", 150, 2),
		_make(&"apartment__tv", "Телевизор", 200, 2),
		_make(&"apartment__record_player", "Проигрыватель", 250, 2),
		_make(&"apartment__no_filter_cards", "Карточки «Без фильтров»", 300, 2),
		_make(&"apartment__tea_set", "Чайный сервиз", 400, 3),
		_make(&"apartment__mini_fridge", "Мини-холодильник", 475, 3),
		_make(&"apartment__large_mirror", "Большое зеркало", 550, 3),
		_make(&"apartment__collection_display", "Витрина коллекции", 625, 3),
		_make(&"apartment__karaoke", "Караоке", 750, 4),
		_make(&"apartment__game_console", "Игровая консоль", 850, 4),
		_make(&"apartment__darts", "Дартс", 950, 4),
		_make(&"apartment__chess_table", "Шахматный столик", 1100, 4),
	]
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	price: int,
	min_story_stage: int
) -> ApartmentObjectDefinition:
	var item := ApartmentObjectDefinition.new()
	item.id = id
	item.display_name = display_name
	item.description = display_name
	item.price = price
	item.min_story_stage = min_story_stage
	item.enabled = true
	item._local_object_id = id
	return item