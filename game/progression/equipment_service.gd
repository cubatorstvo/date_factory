extends Node

signal outfit_equipped(previous_outfit_id: StringName, current_outfit_id: StringName)

const BUY_ACTION_PREFIX: String = "buy_outfit_"

var _catalog: OutfitCatalog


func _ready() -> void:
	_catalog = OutfitCatalog.new()


func get_catalog() -> OutfitCatalog:
	if _catalog == null:
		_catalog = OutfitCatalog.new()
	return _catalog


func owns_outfit(outfit_id: StringName) -> bool:
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	return progression.owns_outfit(outfit_id)


func get_owned_outfits() -> Array:
	var result: Array[Outfit] = []
	var progression: ProgressionState = _progression()
	if progression == null:
		return result
	for outfit_id in progression.owned_outfit_ids:
		var outfit: Outfit = get_catalog().get_outfit(outfit_id)
		if outfit != null:
			result.append(outfit)
	return result


func get_equipped_outfit_id() -> StringName:
	var progression: ProgressionState = _progression()
	if progression == null:
		return OutfitCatalog.START_OUTFIT_ID
	if progression.equipped_outfit_id == &"":
		return OutfitCatalog.START_OUTFIT_ID
	return progression.equipped_outfit_id


func add_owned_outfit(outfit_id: StringName) -> void:
	var progression: ProgressionState = _progression()
	if progression == null:
		return
	progression.add_owned_outfit(outfit_id)


func equip_outfit(outfit_id: StringName) -> bool:
	if not owns_outfit(outfit_id):
		return false
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	var previous_outfit_id: StringName = progression.equipped_outfit_id
	if previous_outfit_id == outfit_id:
		return true
	progression.equipped_outfit_id = outfit_id
	outfit_equipped.emit(previous_outfit_id, outfit_id)
	return true


func create_buy_outfit_action(outfit_id: StringName) -> GameAction:
	var action := GameAction.new()
	var outfit: Outfit = get_catalog().get_outfit(outfit_id)
	if outfit == null:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(outfit_id)])
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
