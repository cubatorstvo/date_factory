extends Node

const BUY_ACTION_PREFIX: String = "buy_"
const QUALITY_MIN: int = 0
const QUALITY_MAX: int = 3

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


func get_quality() -> int:
	return clampi(get_level() - 1, QUALITY_MIN, QUALITY_MAX)


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
