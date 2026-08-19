extends Node

signal automation_unlocked
signal clones_changed(total_clones: int)
signal allocation_changed(work_allocation_percent: int)
signal production_changed
signal upgrade_purchased(upgrade_id: StringName)

const BUY_ACTION_PREFIX: String = "buy_"
const INITIAL_CLONES: int = 10
const BASE_WORK_INCOME_PER_CLONE_PER_HOUR: float = 100.0
const BASE_DATING_PER_CLONE_PER_HOUR: float = 0.1
const UNIT_EPSILON: float = 0.000000001

var _catalog: AutomationCatalog


func _ready() -> void:
	_catalog = AutomationCatalog.create_seed()
	var clock: Variant = _time_service()
	if clock != null and not clock.time_advanced.is_connected(_on_time_advanced):
		clock.time_advanced.connect(_on_time_advanced)


func get_catalog() -> AutomationCatalog:
	if _catalog == null:
		_catalog = AutomationCatalog.create_seed()
	return _catalog


func is_unlocked() -> bool:
	var state: AutomationState = _state()
	return state != null and state.unlocked


func get_total_clones() -> int:
	var state: AutomationState = _state()
	if state == null:
		return 0
	return state.total_clones


func get_work_allocation_percent() -> int:
	var state: AutomationState = _state()
	if state == null:
		return 50
	return state.work_allocation_percent


func get_dating_allocation_percent() -> int:
	return 100 - get_work_allocation_percent()


func get_work_clones() -> float:
	return float(get_total_clones()) * float(get_work_allocation_percent()) / 100.0


func get_dating_clones() -> float:
	return float(get_total_clones()) * float(get_dating_allocation_percent()) / 100.0


func get_work_multiplier() -> float:
	var result: float = 1.0
	var state: AutomationState = _state()
	if state == null:
		return result
	for upgrade_id in state.purchased_upgrade_ids:
		var definition: AutomationUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
		if definition == null:
			continue
		result *= definition.work_multiplier
	return result


func get_dating_multiplier() -> float:
	var result: float = 1.0
	var state: AutomationState = _state()
	if state == null:
		return result
	for upgrade_id in state.purchased_upgrade_ids:
		var definition: AutomationUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
		if definition == null:
			continue
		result *= definition.dating_multiplier
	return result


func get_work_income_per_hour() -> float:
	return get_work_clones() * BASE_WORK_INCOME_PER_CLONE_PER_HOUR * get_work_multiplier()


func get_dating_production_per_hour() -> float:
	return get_dating_clones() * BASE_DATING_PER_CLONE_PER_HOUR * get_dating_multiplier()


func get_completed_auto_dates() -> int:
	var state: AutomationState = _state()
	if state == null:
		return 0
	return state.completed_auto_dates


func get_dating_progress_fraction() -> float:
	var state: AutomationState = _state()
	if state == null:
		return 0.0
	return state.dating_progress_fraction


func get_work_income_fraction() -> float:
	var state: AutomationState = _state()
	if state == null:
		return 0.0
	return state.work_income_fraction


func is_upgrade_purchased(upgrade_id: StringName) -> bool:
	var state: AutomationState = _state()
	if state == null:
		return false
	return state.has(upgrade_id)


func set_work_allocation_percent(percent: int) -> void:
	var state: AutomationState = _state()
	if state == null:
		return
	var next_percent: int = clampi(percent, 0, 100)
	if state.work_allocation_percent == next_percent:
		return
	state.work_allocation_percent = next_percent
	allocation_changed.emit(next_percent)


func unlock() -> void:
	var state: AutomationState = _state()
	if state == null or state.unlocked:
		return
	state.unlocked = true
	automation_unlocked.emit()


func grant_initial_clones() -> void:
	var state: AutomationState = _state()
	if state == null or state.initial_clones_granted:
		return
	state.total_clones += INITIAL_CLONES
	state.initial_clones_granted = true
	clones_changed.emit(state.total_clones)


func apply_upgrade(upgrade_id: StringName) -> void:
	var state: AutomationState = _state()
	if state == null or state.has(upgrade_id):
		return
	var definition: AutomationUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if definition == null:
		return
	state.add(upgrade_id)
	if definition.extra_clones > 0:
		state.total_clones += definition.extra_clones
		clones_changed.emit(state.total_clones)
	upgrade_purchased.emit(upgrade_id)


func create_upgrade_action(upgrade_id: StringName) -> GameAction:
	var action := GameAction.new()
	var definition: AutomationUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if definition == null:
		return action
	action.id = StringName("%s%s" % [BUY_ACTION_PREFIX, String(definition.id)])
	action.money_cost = definition.price
	action.time_cost_minutes = 0
	var requirement := AutomationUpgradeNotPurchasedRequirement.new()
	requirement.upgrade_id = definition.id
	action.requirements.append(requirement)
	var effect := AutomationUpgradeEffect.new()
	effect.upgrade_id = definition.id
	action.effects.append(effect)
	return action


func _on_time_advanced(delta_minutes: int, _previous_game_time: int, _current_game_time: int) -> void:
	if delta_minutes <= 0 or not is_unlocked():
		return
	var state: AutomationState = _state()
	if state == null:
		return
	var produced: bool = false
	var work_split: Dictionary = _split_units(
		state.work_income_fraction,
		get_work_income_per_hour(),
		delta_minutes
	)
	var work_whole: int = int(work_split["whole"])
	state.work_income_fraction = float(work_split["fraction"])
	if work_whole > 0:
		var economy: Variant = _economy_service()
		if economy != null:
			economy.add_money(work_whole)
		produced = true
	var dating_split: Dictionary = _split_units(
		state.dating_progress_fraction,
		get_dating_production_per_hour(),
		delta_minutes
	)
	var dating_whole: int = int(dating_split["whole"])
	state.dating_progress_fraction = float(dating_split["fraction"])
	if dating_whole > 0:
		state.completed_auto_dates += dating_whole
		produced = true
	if produced or work_whole > 0 or dating_whole > 0:
		production_changed.emit()
	elif float(work_split["fraction"]) > 0.0 or float(dating_split["fraction"]) > 0.0:
		production_changed.emit()


func _split_units(current_fraction: float, units_per_hour: float, delta_minutes: int) -> Dictionary:
	var total: float = current_fraction + units_per_hour * float(delta_minutes) / 60.0
	var whole: int = int(floor(total + UNIT_EPSILON))
	var fraction: float = total - float(whole)
	if fraction < UNIT_EPSILON:
		fraction = 0.0
	elif fraction >= 1.0 - UNIT_EPSILON:
		whole += 1
		fraction = 0.0
	return {
		"whole": maxi(0, whole),
		"fraction": maxf(0.0, fraction),
	}


func _state() -> AutomationState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.automation as AutomationState


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


func _economy_service() -> Variant:
	var node: Node = get_node_or_null("/root/EconomyService")
	if not is_instance_valid(node):
		push_error("EconomyService autoload missing")
		return null
	return node
