extends Node

signal automation_unlocked
signal clones_changed(total_clones: int)
signal allocation_changed(work_allocation_percent: int)
signal production_changed
signal upgrade_purchased(upgrade_id: StringName)
signal expansion_changed

const BUY_ACTION_PREFIX: String = "buy_"
const EXPAND_ACTION_PREFIX: String = "expand_factory_"
const INITIAL_CLONES: int = 10
const BASE_WORK_INCOME_PER_CLONE_PER_HOUR: float = 100.0
const BASE_DATING_PER_CLONE_PER_HOUR: float = 0.1
const UNIT_EPSILON: float = 0.000000001
const SCOPE_CITY: StringName = &"city"
const SCOPE_COUNTRY: StringName = &"country"
const SCOPE_WORLD: StringName = &"world"
const CITY_REACH_REQUIRED: float = 100.0
const COUNTRY_REACH_REQUIRED: float = 1000.0
const WORLD_REACH_REQUIRED: float = 10000.0
const CITY_TO_COUNTRY_COST: int = 10000
const COUNTRY_TO_WORLD_COST: int = 1000000
const CLONE_SCALE_FACTOR: int = 10

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

func get_current_expansion_scope() -> StringName:
	var state: AutomationState = _state()
	if state == null:
		return SCOPE_CITY
	return state.current_expansion_scope


func get_expansion_progress() -> float:
	var state: AutomationState = _state()
	if state == null:
		return 0.0
	return state.expansion_progress


func get_required_expansion_progress(scope: StringName = &"") -> float:
	var resolved: StringName = scope
	if resolved == &"":
		resolved = get_current_expansion_scope()
	if resolved == SCOPE_COUNTRY:
		return COUNTRY_REACH_REQUIRED
	if resolved == SCOPE_WORLD:
		return WORLD_REACH_REQUIRED
	return CITY_REACH_REQUIRED


func get_expansion_percent() -> float:
	var required: float = get_required_expansion_progress()
	if required <= 0.0:
		return 0.0
	return minf(100.0, 100.0 * get_expansion_progress() / required)


func is_current_expansion_complete() -> bool:
	return get_expansion_progress() + UNIT_EPSILON >= get_required_expansion_progress()


func get_next_expansion_scope() -> StringName:
	var scope: StringName = get_current_expansion_scope()
	if scope == SCOPE_CITY:
		return SCOPE_COUNTRY
	if scope == SCOPE_COUNTRY:
		return SCOPE_WORLD
	return &""


func get_previous_expansion_scope(target_scope: StringName) -> StringName:
	if target_scope == SCOPE_COUNTRY:
		return SCOPE_CITY
	if target_scope == SCOPE_WORLD:
		return SCOPE_COUNTRY
	return &""


func get_expansion_cost(target_scope: StringName) -> int:
	if target_scope == SCOPE_COUNTRY:
		return CITY_TO_COUNTRY_COST
	if target_scope == SCOPE_WORLD:
		return COUNTRY_TO_WORLD_COST
	return 0


func get_expansion_action_label(target_scope: StringName) -> String:
	if target_scope == SCOPE_COUNTRY:
		return "РАСШИРИТЬ ДО МАСШТАБОВ СТРАНЫ"
	if target_scope == SCOPE_WORLD:
		return "РАСШИРИТЬ ДО МАСШТАБОВ МИРА"
	return ""


func get_scope_display_name(scope: StringName = &"") -> String:
	var resolved: StringName = scope
	if resolved == &"":
		resolved = get_current_expansion_scope()
	if resolved == SCOPE_COUNTRY:
		return "Страна"
	if resolved == SCOPE_WORLD:
		return "Мир"
	return "Город"


func can_expand() -> bool:
	return get_next_expansion_scope() != &"" and is_current_expansion_complete()


func get_expansion_rate_per_hour() -> float:
	if is_current_expansion_complete():
		return 0.0
	return get_dating_production_per_hour()


func get_expansion_percent_per_hour() -> float:
	var required: float = get_required_expansion_progress()
	if required <= 0.0:
		return 0.0
	return 100.0 * get_expansion_rate_per_hour() / required


func apply_expansion(target_scope: StringName) -> void:
	var state: AutomationState = _state()
	if state == null:
		return
	if get_previous_expansion_scope(target_scope) != state.current_expansion_scope:
		return
	if not is_current_expansion_complete():
		return
	if get_expansion_cost(target_scope) <= 0:
		return
	state.current_expansion_scope = target_scope
	state.expansion_progress = 0.0
	state.total_clones *= CLONE_SCALE_FACTOR
	clones_changed.emit(state.total_clones)
	expansion_changed.emit()
	production_changed.emit()


func create_expansion_action(target_scope: StringName) -> GameAction:
	var action := GameAction.new()
	var from_scope: StringName = get_previous_expansion_scope(target_scope)
	if from_scope == &"" or get_expansion_cost(target_scope) <= 0:
		return action
	action.id = StringName("%s%s" % [EXPAND_ACTION_PREFIX, String(target_scope)])
	action.money_cost = get_expansion_cost(target_scope)
	action.time_cost_minutes = 0
	var requirement := FactoryExpansionRequirement.new()
	requirement.from_scope = from_scope
	action.requirements.append(requirement)
	var effect := FactoryExpansionEffect.new()
	effect.target_scope = target_scope
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
	var dating_rate: float = get_dating_production_per_hour()
	var dating_delta: float = dating_rate * float(delta_minutes) / 60.0
	var previous_progress: float = state.expansion_progress
	var required_progress: float = get_required_expansion_progress()
	state.expansion_progress = minf(previous_progress + maxf(0.0, dating_delta), required_progress)
	var expansion_changed_now: bool = not is_equal_approx(state.expansion_progress, previous_progress)
	var dating_split: Dictionary = _split_units(
		state.dating_progress_fraction,
		dating_rate,
		delta_minutes
	)
	var dating_whole: int = int(dating_split["whole"])
	state.dating_progress_fraction = float(dating_split["fraction"])
	if dating_whole > 0:
		var rating: Variant = _rating_service()
		if rating != null:
			rating.add_rating(dating_whole)
		produced = true
	if produced or work_whole > 0 or dating_whole > 0 or expansion_changed_now:
		production_changed.emit()
	elif float(work_split["fraction"]) > 0.0 or float(dating_split["fraction"]) > 0.0:
		production_changed.emit()
	if expansion_changed_now:
		expansion_changed.emit()


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

func _rating_service() -> Variant:
	var node: Node = get_node_or_null("/root/RatingService")
	if not is_instance_valid(node):
		push_error("RatingService autoload missing")
		return null
	return node
