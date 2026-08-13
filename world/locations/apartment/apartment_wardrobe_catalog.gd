extends RefCounted
class_name ApartmentWardrobeCatalog
## Clothing catalog for the apartment wardrobe. Ownership + equipped outfit use story flags.

const ITEMS: Array[Dictionary] = [
	{
		"id": &"casual",
		"name": "Повседневный",
		"price": 0,
		"default_unlocked": true,
	},
	{
		"id": &"business",
		"name": "Деловой",
		"price": 500,
	},
	{
		"id": &"luxury",
		"name": "Роскошный",
		"price": 2000,
	},
]

const DEFAULT_EQUIPPED: StringName = &"casual"


static func get_definition(item_id: StringName) -> Dictionary:
	for item: Dictionary in ITEMS:
		if StringName(item.get("id", &"")) == item_id:
			return item.duplicate(true)
	return {}


static func get_player_items(game_state: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var equipped: StringName = get_equipped(game_state)
	for item: Dictionary in ITEMS:
		var row: Dictionary = item.duplicate(true)
		var item_id: StringName = row.get("id", &"")
		row["unlocked"] = is_unlocked(game_state, item_id)
		row["equipped"] = item_id == equipped
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
	return bool(game_state.call("get_story_flag", _owned_flag(item_id)))


static func get_equipped(game_state: Node) -> StringName:
	if game_state == null or not game_state.has_method("get_story_flag"):
		return DEFAULT_EQUIPPED
	for item: Dictionary in ITEMS:
		var item_id: StringName = item.get("id", &"")
		if bool(game_state.call("get_story_flag", _equipped_flag(item_id))):
			if is_unlocked(game_state, item_id):
				return item_id
			# Unknown / locked equipped flag falls back to casual.
			return DEFAULT_EQUIPPED
	return DEFAULT_EQUIPPED


static func try_equip(game_state: Node, item_id: StringName) -> Dictionary:
	var definition: Dictionary = get_definition(item_id)
	if definition.is_empty():
		return {"ok": false, "reason": "missing"}
	if not is_unlocked(game_state, item_id):
		return {"ok": false, "reason": "locked"}
	if game_state == null or not game_state.has_method("set_story_flag"):
		return {"ok": false, "reason": "state"}
	for item: Dictionary in ITEMS:
		var other_id: StringName = item.get("id", &"")
		game_state.call("set_story_flag", _equipped_flag(other_id), other_id == item_id)
	return {"ok": true, "id": item_id, "name": str(definition.get("name", ""))}


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
	game_state.call("set_story_flag", _owned_flag(item_id), true)
	return {"ok": true, "price": price}


static func _owned_flag(item_id: StringName) -> StringName:
	return StringName("wardrobe_item_%s_owned" % String(item_id))


static func _equipped_flag(item_id: StringName) -> StringName:
	return StringName("wardrobe_equipped_%s" % String(item_id))
