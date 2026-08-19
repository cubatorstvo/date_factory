extends Node

signal action_executed(action_id: StringName, result: ActionResult)

var _catalog: GameActionCatalog


func _ready() -> void:
	_catalog = GameActionCatalog.create_test_catalog()


func get_action(id: StringName) -> GameAction:
	if _catalog == null:
		_catalog = GameActionCatalog.create_test_catalog()
	return _catalog.find(id)


func can_execute(action: GameAction) -> bool:
	return get_failure_reason(action).is_empty()


func get_failure_reason(action: GameAction) -> String:
	if action == null:
		return "Действие не задано"
	for requirement in action.requirements:
		if requirement == null:
			continue
		if not requirement.is_met():
			return requirement.get_failure_reason()
	var gs: Variant = _game_state()
	if gs == null:
		return "GameState autoload missing"
	if gs.player.money < action.money_cost:
		return "Недостаточно денег"
	return ""


func execute(action: GameAction) -> ActionResult:
	var result := ActionResult.new()
	if action == null:
		result.success = false
		result.failure_reason = "Действие не задано"
		return result
	result.action_id = action.id
	var reason: String = get_failure_reason(action)
	if not reason.is_empty():
		result.success = false
		result.failure_reason = reason
		return result
	var gs: Variant = _game_state()
	gs.player.money -= action.money_cost
	var applied: Array[String] = []
	for effect in action.effects:
		if effect == null:
			continue
		effect.apply()
		applied.append(effect.get_description())
	var clock: Variant = _time_service()
	if clock != null:
		clock.advance_time(action.time_cost_minutes)
	result.success = true
	result.failure_reason = ""
	result.time_spent_minutes = action.time_cost_minutes
	result.money_spent = action.money_cost
	result.applied_effects = applied
	action_executed.emit(action.id, result)
	return result


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
		return null
	return node
