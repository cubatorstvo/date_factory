extends Node

const BUY_ACTION_PREFIX: String = "buy_"

var _catalog: ApartmentCatalog


func _ready() -> void:
	_catalog = ApartmentCatalog.create_seed()


func get_catalog() -> ApartmentCatalog:
	if _catalog == null:
		_catalog = ApartmentCatalog.create_seed()
	return _catalog


func get_available_objects() -> Array[ApartmentObjectDefinition]:
	return get_catalog().available_objects(_story_stage())


func is_prepared() -> bool:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return true
	return apartment.prepared


func set_prepared(value: bool) -> void:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return
	apartment.prepared = value


func is_object_visible(item: ApartmentObjectDefinition) -> bool:
	if item == null or not item.enabled:
		return false
	return item.min_story_stage <= _story_stage()

func create_clean_action() -> GameAction:
	var action := GameAction.new()
	action.id = &"apartment_clean"
	action.money_cost = 0
	action.time_cost_minutes = FillerRewardCatalog.APARTMENT_CLEAN_MINUTES
	var effect := ApartmentPrepareEffect.new()
	action.effects.append(effect)
	return action


func get_accent_object_id() -> StringName:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return &""
	return apartment.accent_object_id


func has_interior_accent_reward() -> bool:
	var girls: Variant = get_node_or_null("/root/GirlsService")
	if girls == null:
		return false
	return bool(girls.has_filler_reward(FillerRewardCatalog.ID_KATYA_INTERIOR_ACCENT))


func is_first_accent_assignment() -> bool:
	return has_interior_accent_reward() and get_accent_object_id() == &""


func get_accent_reassignment_price() -> int:
	if not has_interior_accent_reward():
		return 0
	if is_first_accent_assignment():
		return 0
	var stage: int = _story_stage()
	if stage <= 2:
		return 300
	if stage == 3:
		return 600
	return 1000


func assign_accent(object_id: StringName) -> bool:
	var apartment: ApartmentState = _apartment()
	if apartment == null or object_id == &"":
		return false
	if not has_interior_accent_reward():
		return false
	if not is_object_owned(object_id):
		return false
	apartment.accent_object_id = object_id
	return true

func create_assign_accent_action(object_id: StringName) -> GameAction:
	var action := GameAction.new()
	action.id = StringName("assign_accent_%s" % String(object_id))
	action.money_cost = get_accent_reassignment_price()
	action.time_cost_minutes = 0
	var reward_req := FillerRewardUnlockedRequirement.new()
	reward_req.reward_id = FillerRewardCatalog.ID_KATYA_INTERIOR_ACCENT
	action.requirements.append(reward_req)
	var owned_req := ApartmentLocalObjectOwnedRequirement.new()
	owned_req.object_id = object_id
	action.requirements.append(owned_req)
	var effect := ApartmentAssignAccentEffect.new()
	effect.object_id = object_id
	action.effects.append(effect)
	return action


func get_owned_local_object_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return result
	for object_id in apartment.owned_local_object_ids:
		if object_id == &"":
			continue
		var item: ApartmentObjectDefinition = get_catalog().get_object(object_id)
		var local_id: StringName = object_id
		if item != null:
			local_id = item.local_object_id()
			if local_id == &"":
				local_id = item.id
		if not result.has(local_id):
			result.append(local_id)
	return result

func get_owned_object_ids() -> Array[StringName]:
	return get_owned_local_object_ids()


func get_active_local_move_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		return result
	for object_id in get_owned_object_ids():
		var local_object: DateLocalObject = catalog.find_local_object(object_id)
		if local_object == null:
			continue
		for move_id in local_object.move_ids:
			if move_id != &"" and not result.has(move_id):
				result.append(move_id)
	return result

func is_object_owned(object_id: StringName) -> bool:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return false
	return apartment.has(object_id)


func own_object(object_id: StringName) -> void:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return
	apartment.add(object_id)

func create_buy_apartment_object_action(object_id: StringName) -> GameAction:
	var action := GameAction.new()
	var item: ApartmentObjectDefinition = get_catalog().get_object(object_id)
	if item == null or not item.enabled:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(item.id)])
	action.money_cost = item.price
	action.time_cost_minutes = 0
	var not_owned := ApartmentObjectNotOwnedRequirement.new()
	not_owned.object_id = item.id
	action.requirements.append(not_owned)
	var stage := MinStoryStageRequirement.new()
	stage.min_stage = item.min_story_stage
	action.requirements.append(stage)
	var effect := ApartmentOwnObjectEffect.new()
	effect.object_id = item.id
	action.effects.append(effect)
	return action

func _story_stage() -> int:
	var gs: Variant = _game_state()
	if gs == null:
		return 1
	return int(gs.story.stage)


func _apartment() -> ApartmentState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	var progression: ProgressionState = gs.progression as ProgressionState
	if progression == null:
		return null
	return progression.apartment


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node

func _date_catalog() -> DateContentCatalog:
	var dating: Variant = get_node_or_null("/root/DatingService")
	if dating == null or not dating.has_method("get_catalog_service"):
		return null
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog
