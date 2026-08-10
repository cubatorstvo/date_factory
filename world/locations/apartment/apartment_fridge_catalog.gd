extends RefCounted
class_name ApartmentFridgeCatalog
## Data-driven refrigerator catalog. Ownership is persisted through GameState story flags.

const CATEGORY_FOOD: StringName = &"food"
const CATEGORY_DRINK: StringName = &"drink"

const ITEMS: Array[Dictionary] = [
	{
		"id": &"fried_egg",
		"category": CATEGORY_FOOD,
		"name": "Яичница",
		"scene": "res://assets/props/food/meshes/Egg_Fried.fbx",
		"price": 0,
		"default_unlocked": true,
	},
	{
		"id": &"pizza",
		"category": CATEGORY_FOOD,
		"name": "Пицца",
		"scene": "res://assets/props/food/meshes/Pizza.fbx",
		"price": 120,
	},
	{
		"id": &"burger",
		"category": CATEGORY_FOOD,
		"name": "Бургер",
		"scene": "res://assets/props/food/meshes/Cheeseburger.fbx",
		"price": 180,
	},
	{
		"id": &"pancakes",
		"category": CATEGORY_FOOD,
		"name": "Блинчики",
		"scene": "res://assets/props/food/meshes/Pancakes_Stack.fbx",
		"price": 240,
	},
	{
		"id": &"steak",
		"category": CATEGORY_FOOD,
		"name": "Стейк",
		"scene": "res://assets/props/food/meshes/Steak.fbx",
		"price": 450,
	},
	{
		"id": &"water",
		"category": CATEGORY_DRINK,
		"name": "Вода",
		"scene": "res://assets/environment/interior/drinkware/Drinkware_CheapGlass.tscn",
		"price": 0,
		"default_unlocked": true,
	},
	{
		"id": &"soda",
		"category": CATEGORY_DRINK,
		"name": "Газировка",
		"scene": "res://assets/props/food/meshes/Soda.fbx",
		"price": 90,
	},
	{
		"id": &"juice",
		"category": CATEGORY_DRINK,
		"name": "Сок",
		"scene": "res://assets/props/food/meshes/Bottle1.fbx",
		"price": 160,
	},
]


static func get_definition(item_id: StringName) -> Dictionary:
	for item: Dictionary in ITEMS:
		if StringName(item.get("id", &"")) == item_id:
			return item.duplicate(true)
	return {}


static func get_player_items(game_state: Node, category: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in ITEMS:
		if StringName(item.get("category", &"")) != category:
			continue
		var row: Dictionary = item.duplicate(true)
		var item_id: StringName = row.get("id", &"")
		row["unlocked"] = is_unlocked(game_state, item_id)
		result.append(row)
	return result


static func is_unlocked(game_state: Node, item_id: StringName) -> bool:
	var definition: Dictionary = get_definition(item_id)
	if definition.is_empty():
		return false
	if bool(definition.get("default_unlocked", false)):
		return true
	if game_state == null or not game_state.has_method("get_story_flag"):
		return false
	return bool(game_state.call("get_story_flag", _unlock_flag(item_id)))


static func try_purchase(game_state: Node, item_id: StringName) -> Dictionary:
	var definition: Dictionary = get_definition(item_id)
	if definition.is_empty():
		return {"ok": false, "reason": "missing"}
	if is_unlocked(game_state, item_id):
		return {"ok": true, "already_owned": true}
	if game_state == null:
		return {"ok": false, "reason": "state"}
	if (
		not game_state.has_method("can_afford")
		or not game_state.has_method("spend_money")
		or not game_state.has_method("set_story_flag")
	):
		return {"ok": false, "reason": "state"}
	var price: int = int(definition.get("price", 0))
	if price <= 0:
		return {"ok": false, "reason": "price"}
	if not bool(game_state.call("can_afford", price)):
		return {"ok": false, "reason": "money", "price": price}
	if not bool(game_state.call("spend_money", price)):
		return {"ok": false, "reason": "money", "price": price}
	game_state.call("set_story_flag", _unlock_flag(item_id), true)
	return {"ok": true, "price": price}


static func _unlock_flag(item_id: StringName) -> StringName:
	return StringName("fridge_item_%s_owned" % String(item_id))
