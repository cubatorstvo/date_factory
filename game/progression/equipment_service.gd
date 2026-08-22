extends Node

signal outfit_equipped(previous_outfit_id: StringName, current_outfit_id: StringName)
signal outfit_owned(outfit_id: StringName)

const BUY_ACTION_PREFIX: String = "buy_outfit_"

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


func owns_outfit(outfit_id: StringName) -> bool:
	var progression: ProgressionState = _progression()
	if progression == null:
		return outfit_id == OutfitCatalog.START_OUTFIT_ID
	return progression.owns_outfit(outfit_id)


func get_owned_outfits() -> Array:
	var result: Array[Outfit] = []
	var progression: ProgressionState = _progression()
	if progression == null:
		var start: Outfit = get_catalog().get_outfit(OutfitCatalog.START_OUTFIT_ID)
		if start != null:
			result.append(start)
		return result
	for outfit_id in progression.owned_outfit_ids:
		var outfit: Outfit = get_catalog().get_outfit(outfit_id)
		if outfit != null:
			result.append(outfit)
	return result


func get_equipped_outfit_id() -> StringName:
	return get_current_outfit_id()

func owns_dressed_outfit() -> bool:
	for outfit in get_owned_outfits():
		if outfit != null and int(outfit.get("tier")) >= 1:
			return true
	return false


func get_current_outfit_tier() -> int:
	return get_outfit_tier(get_current_outfit())


func get_outfit_tier(outfit: Outfit) -> int:
	if outfit == null:
		return 0
	return int(outfit.get("tier"))


func get_shop_outfits() -> Array[Outfit]:
	var stage: int = 1
	var stages: Variant = _stage_service()
	if stages != null:
		stage = int(stages.get_current_stage())
	return get_catalog().get_shop_outfits(stage)


func add_owned_outfit(outfit_id: StringName) -> void:
	var progression: ProgressionState = _progression()
	if progression == null:
		return
	var previous_outfit_id: StringName = get_current_outfit_id()
	progression.add_owned_outfit(outfit_id)
	outfit_owned.emit(outfit_id)
	var current_id: StringName = get_current_outfit_id()
	if current_id != previous_outfit_id:
		outfit_equipped.emit(previous_outfit_id, current_id)

func equip_outfit(outfit_id: StringName) -> bool:
	if not owns_outfit(outfit_id):
		return false
	var previous_outfit_id: StringName = get_current_outfit_id()
	if previous_outfit_id == outfit_id:
		return true
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	progression.current_outfit_id = outfit_id
	outfit_equipped.emit(previous_outfit_id, outfit_id)
	return true


func create_buy_outfit_action(outfit_id: StringName) -> GameAction:
	var action := GameAction.new()
	var outfit: Outfit = get_catalog().get_outfit(outfit_id)
	if outfit == null:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(outfit_id)])
	action.money_cost = get_effective_outfit_price(outfit_id)
	action.time_cost_minutes = 0
	var owned := OutfitNotOwnedRequirement.new()
	owned.outfit_id = outfit_id
	action.requirements.append(owned)
	var stage := MinStoryStageRequirement.new()
	stage.min_stage = outfit.min_story_stage
	action.requirements.append(stage)
	var effect := OwnOutfitEffect.new()
	effect.outfit_id = outfit_id
	action.effects.append(effect)
	if is_marina_gift_price(outfit_id):
		var clear := ClearMarinaGiftEffect.new()
		action.effects.append(clear)
	return action


func get_effective_outfit_price(outfit_id: StringName) -> int:
	var outfit: Outfit = get_catalog().get_outfit(outfit_id)
	if outfit == null:
		return 0
	if is_marina_gift_price(outfit_id):
		return 0
	return outfit.price


func is_marina_gift_price(outfit_id: StringName) -> bool:
	if owns_outfit(outfit_id):
		return false
	var girls: Variant = get_node_or_null("/root/GirlsService")
	if girls == null or not bool(girls.is_marina_free_outfit_pending()):
		return false
	for outfit in get_shop_outfits():
		if outfit != null and outfit.id == outfit_id:
			return true
	return false


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


func _stage_service() -> Variant:
	var node: Node = get_node_or_null("/root/StageService")
	if not is_instance_valid(node):
		return null
	return node
