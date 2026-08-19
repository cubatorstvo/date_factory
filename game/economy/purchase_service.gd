extends Node

signal purchase_completed(purchase_id: StringName)

const ID_BASIC_UPGRADE: StringName = &"basic_upgrade"
const BUY_ACTION_PREFIX: String = "buy_"


func _ready() -> void:
	var actions: Variant = _action_service()
	if actions == null:
		return
	if not actions.action_executed.is_connected(_on_action_executed):
		actions.action_executed.connect(_on_action_executed)


func make_basic_upgrade() -> PurchaseDefinition:
	var definition := PurchaseDefinition.new()
	definition.id = ID_BASIC_UPGRADE
	definition.display_name = "Базовое улучшение"
	definition.description = "Первое постоянное улучшение."
	definition.price = 300
	return definition


func is_purchased(purchase_id: StringName) -> bool:
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	return progression.has(purchase_id)


func can_purchase(definition: PurchaseDefinition) -> bool:
	if definition == null:
		return false
	if is_purchased(definition.id):
		return false
	var economy: Variant = _economy_service()
	if economy == null:
		return false
	return bool(economy.can_afford(definition.price))


func create_purchase_action(definition: PurchaseDefinition) -> GameAction:
	var action := GameAction.new()
	if definition == null:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(definition.id)])
	action.money_cost = definition.price
	action.time_cost_minutes = 0
	var requirement := NotPurchasedRequirement.new()
	requirement.purchase_id = definition.id
	action.requirements.append(requirement)
	var effect := PurchaseEffect.new()
	effect.purchase_id = definition.id
	action.effects.append(effect)
	return action


func _on_action_executed(action_id: StringName, result: ActionResult) -> void:
	if result == null or not result.success:
		return
	var action_text: String = String(action_id)
	if not action_text.begins_with(BUY_ACTION_PREFIX):
		return
	var purchase_id: StringName = StringName(action_text.substr(BUY_ACTION_PREFIX.length()))
	if not is_purchased(purchase_id):
		return
	purchase_completed.emit(purchase_id)


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


func _economy_service() -> Variant:
	var node: Node = get_node_or_null("/root/EconomyService")
	if not is_instance_valid(node):
		push_error("EconomyService autoload missing")
		return null
	return node


func _action_service() -> Variant:
	var node: Node = get_node_or_null("/root/ActionService")
	if not is_instance_valid(node):
		push_error("ActionService autoload missing")
		return null
	return node
