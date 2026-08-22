class_name ApartmentCatalog
extends Resource

const ID_UPGRADE_1: StringName = &"apartment__tv"
const ID_EMPEROR_CHAIR: StringName = &"apartment_emperor_chair"

@export var upgrades: Array[ApartmentUpgradeDefinition] = []


func get_upgrade(upgrade_id: StringName) -> ApartmentUpgradeDefinition:
	if upgrade_id == &"":
		return null
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null


func get_all_upgrades() -> Array[ApartmentUpgradeDefinition]:
	var result: Array[ApartmentUpgradeDefinition] = []
	for upgrade in upgrades:
		if upgrade != null:
			result.append(upgrade)
	return result


static func create_seed() -> ApartmentCatalog:
	var catalog := ApartmentCatalog.new()
	catalog.upgrades = [
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
) -> ApartmentUpgradeDefinition:
	var upgrade := ApartmentUpgradeDefinition.new()
	upgrade.id = id
	upgrade.display_name = display_name
	upgrade.description = display_name
	upgrade.price = price
	upgrade.level_granted = min_story_stage
	upgrade.min_story_stage = min_story_stage
	var granted: Array[StringName] = [id]
	upgrade.granted_local_object_ids = granted
	upgrade.required_filler_reward_id = &""
	return upgrade