extends Node

signal girl_discovered(girl_id: StringName)
signal girl_contact_received(girl_id: StringName)
signal girl_relationship_changed(girl_id: StringName, previous_value: int, current_value: int, delta: int)

const MEET_ACTION_PREFIX: String = "meet_"
const MEET_TIME_MINUTES: int = 30

var _catalog: GirlCatalog


func _ready() -> void:
	_catalog = GirlCatalog.create_seed()


func get_catalog() -> GirlCatalog:
	if _catalog == null:
		_catalog = GirlCatalog.create_seed()
	return _catalog


func get_definition(girl_id: StringName) -> GirlDefinition:
	return get_catalog().get_girl(girl_id)


func get_state(girl_id: StringName) -> GirlState:
	if get_definition(girl_id) == null:
		return null
	var girls: GirlsState = _girls()
	if girls == null:
		return null
	return girls.get_or_create(girl_id)


func is_discovered(girl_id: StringName) -> bool:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return false
	return state.discovered


func has_contact(girl_id: StringName) -> bool:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return false
	return state.has_contact


func get_relationship(girl_id: StringName) -> int:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return 0
	return state.relationship


func discover_girl(girl_id: StringName) -> bool:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return false
	if state.discovered:
		return false
	state.discovered = true
	girl_discovered.emit(girl_id)
	return true


func give_contact(girl_id: StringName) -> bool:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return false
	discover_girl(girl_id)
	if state.has_contact:
		return false
	state.has_contact = true
	girl_contact_received.emit(girl_id)
	return true


func change_relationship(girl_id: StringName, delta: int) -> int:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return 0
	var previous_value: int = state.relationship
	var next_value: int = previous_value + delta
	var definition: GirlDefinition = get_definition(girl_id)
	if definition != null:
		next_value = clampi(next_value, definition.relationship_min, definition.relationship_max)
	state.relationship = next_value
	girl_relationship_changed.emit(girl_id, previous_value, next_value, delta)
	return next_value


func get_girls_at_current_location() -> Array[GirlDefinition]:
	var location_id: StringName = LocationCatalog.START_LOCATION_ID
	var world: Variant = _world_service()
	if world != null:
		location_id = world.get_current_location_id()
	return get_catalog().get_girls_for_location(location_id)


func get_discovered_girls() -> Array[GirlDefinition]:
	var result: Array[GirlDefinition] = []
	for definition in get_catalog().get_all_girls():
		if is_discovered(definition.id):
			result.append(definition)
	return result


func get_contacted_girls() -> Array[GirlDefinition]:
	var result: Array[GirlDefinition] = []
	for definition in get_catalog().get_all_girls():
		if has_contact(definition.id):
			result.append(definition)
	return result


func create_meet_girl_action(girl_id: StringName) -> GameAction:
	var action := GameAction.new()
	action.id = StringName("%s%s" % [MEET_ACTION_PREFIX, String(girl_id)])
	action.time_cost_minutes = MEET_TIME_MINUTES
	action.money_cost = 0
	var not_met := GirlNotMetRequirement.new()
	not_met.girl_id = girl_id
	action.requirements.append(not_met)
	var location_req := GirlLocationRequirement.new()
	location_req.girl_id = girl_id
	action.requirements.append(location_req)
	var effect := MeetGirlEffect.new()
	effect.girl_id = girl_id
	action.effects.append(effect)
	return action


func _girls() -> GirlsState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.girls as GirlsState


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node


func _world_service() -> Variant:
	var node: Node = get_node_or_null("/root/WorldService")
	if not is_instance_valid(node):
		push_error("WorldService autoload missing")
		return null
	return node
