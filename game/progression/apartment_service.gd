extends Node

const BUY_ACTION_PREFIX: String = "buy_"

var _catalog: ApartmentCatalog


func _ready() -> void:
	_catalog = ApartmentCatalog.create_seed()


func get_catalog() -> ApartmentCatalog:
	if _catalog == null:
		_catalog = ApartmentCatalog.create_seed()
	return _catalog


func get_level() -> int:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return 1
	return apartment.level


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


func is_upgrade_visible(upgrade: ApartmentUpgradeDefinition) -> bool:
	if upgrade == null:
		return false
	if upgrade.required_filler_reward_id == &"":
		return true
	var girls: Variant = get_node_or_null("/root/GirlsService")
	if girls == null:
		return false
	return bool(girls.has_filler_reward(upgrade.required_filler_reward_id))


func create_clean_action() -> GameAction:
	var action := GameAction.new()
	action.id = &"apartment_clean"
	action.money_cost = 0
	action.time_cost_minutes = FillerRewardCatalog.APARTMENT_CLEAN_MINUTES
	var effect := ApartmentPrepareEffect.new()
	action.effects.append(effect)
	return action


func get_granted_local_object_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return result
	for upgrade in get_catalog().get_all_upgrades():
		if upgrade == null or not apartment.has(upgrade.id):
			continue
		for object_id in upgrade.granted_local_object_ids:
			if object_id != &"" and not result.has(object_id):
				result.append(object_id)
	return result


func is_upgrade_purchased(upgrade_id: StringName) -> bool:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return false
	return apartment.has(upgrade_id)


func apply_upgrade(upgrade_id: StringName, target_level: int) -> void:
	var apartment: ApartmentState = _apartment()
	if apartment == null:
		return
	apartment.level = maxi(apartment.level, target_level)
	apartment.add(upgrade_id)


func create_upgrade_action(upgrade_id: StringName) -> GameAction:
	var action := GameAction.new()
	var definition: ApartmentUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if definition == null:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(definition.id)])
	action.money_cost = definition.price
	action.time_cost_minutes = 0
	var requirement := ApartmentUpgradeNotPurchasedRequirement.new()
	requirement.upgrade_id = definition.id
	action.requirements.append(requirement)
	if definition.required_filler_reward_id != &"":
		var reward_req := FillerRewardUnlockedRequirement.new()
		reward_req.reward_id = definition.required_filler_reward_id
		action.requirements.append(reward_req)
	var effect := ApartmentUpgradeEffect.new()
	effect.upgrade_id = definition.id
	effect.target_level = definition.level_granted
	action.effects.append(effect)
	return action


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
