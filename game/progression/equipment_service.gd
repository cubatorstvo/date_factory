extends Node

signal outfit_equipped(previous_outfit_id: StringName, current_outfit_id: StringName)

const BUY_ACTION_PREFIX: String = "buy_outfit_"
const UPGRADE_ACTION_ID: StringName = &"upgrade_outfit"

var _catalog: OutfitCatalog


func _ready() -> void:
	_catalog = OutfitCatalog.new()


func get_catalog() -> OutfitCatalog:
	if _catalog == null:
		_catalog = OutfitCatalog.new()
	return _catalog


func get_current_outfit_id() -> StringName:
	var progression: ProgressionState = _progression()
	if progression == null or progression.current_outfit_id == &"":
		return OutfitCatalog.START_OUTFIT_ID
	return progression.current_outfit_id


func get_current_outfit() -> Outfit:
	return get_catalog().get_outfit(get_current_outfit_id())


func get_next_outfit() -> Outfit:
	var next_id: StringName = OutfitCatalog.next_outfit_id(get_current_outfit_id())
	if next_id == &"":
		return null
	return get_catalog().get_outfit(next_id)


func can_upgrade_outfit() -> bool:
	return get_next_outfit() != null


func owns_outfit(outfit_id: StringName) -> bool:
	return OutfitCatalog.owns_in_chain(get_current_outfit_id(), outfit_id)


func get_owned_outfits() -> Array:
	var result: Array[Outfit] = []
	for outfit_id in OutfitCatalog.chain_ids():
		if not owns_outfit(outfit_id):
			break
		var outfit: Outfit = get_catalog().get_outfit(outfit_id)
		if outfit != null:
			result.append(outfit)
	return result


func get_equipped_outfit_id() -> StringName:
	return get_current_outfit_id()


func add_owned_outfit(outfit_id: StringName) -> void:
	var progression: ProgressionState = _progression()
	if progression == null:
		return
	var previous_outfit_id: StringName = get_current_outfit_id()
	progression.add_owned_outfit(outfit_id)
	var current_id: StringName = get_current_outfit_id()
	if current_id != previous_outfit_id:
		outfit_equipped.emit(previous_outfit_id, current_id)


func equip_outfit(outfit_id: StringName) -> bool:
	if not owns_outfit(outfit_id):
		return false
	var previous_outfit_id: StringName = get_current_outfit_id()
	if previous_outfit_id == outfit_id:
		return true
	if OutfitCatalog.chain_index(outfit_id) < OutfitCatalog.chain_index(previous_outfit_id):
		return false
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	progression.current_outfit_id = outfit_id
	outfit_equipped.emit(previous_outfit_id, outfit_id)
	return true


func create_upgrade_outfit_action() -> GameAction:
	var next_outfit: Outfit = get_next_outfit()
	if next_outfit == null:
		return GameAction.new()
	return _create_set_outfit_action(next_outfit.id, UPGRADE_ACTION_ID)


func create_buy_outfit_action(outfit_id: StringName) -> GameAction:
	return _create_set_outfit_action(outfit_id, StringName("%s%s" % [BUY_ACTION_PREFIX, String(outfit_id)]))


func _create_set_outfit_action(outfit_id: StringName, action_id: StringName) -> GameAction:
	var action := GameAction.new()
	var outfit: Outfit = get_catalog().get_outfit(outfit_id)
	if outfit == null:
		return action
	action.id = action_id
	action.money_cost = outfit.price
	action.time_cost_minutes = 0
	var requirement := OutfitNotOwnedRequirement.new()
	requirement.outfit_id = outfit_id
	action.requirements.append(requirement)
	var effect := OwnOutfitEffect.new()
	effect.outfit_id = outfit_id
	action.effects.append(effect)
	return action


func _progression() -> ProgressionState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.progression as ProgressionState


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node
