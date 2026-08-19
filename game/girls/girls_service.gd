extends Node

signal girl_discovered(girl_id: StringName)
signal girl_contact_received(girl_id: StringName)
signal girl_relationship_changed(girl_id: StringName, previous_value: int, current_value: int, delta: int)
signal girl_relationship_completed(girl_id: StringName)

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


func get_relationship_max(girl_id: StringName) -> int:
	var definition: GirlDefinition = get_definition(girl_id)
	if definition == null:
		return 0
	return definition.relationship_max


func is_relationship_completed(girl_id: StringName) -> bool:
	return get_relationship(girl_id) >= get_relationship_max(girl_id) and get_definition(girl_id) != null


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
	var definition: GirlDefinition = get_definition(girl_id)
	var min_value: int = 0
	var max_value: int = 0
	if definition != null:
		min_value = definition.relationship_min
		max_value = definition.relationship_max
	if previous_value >= max_value and definition != null:
		state.relationship = max_value
		girl_relationship_changed.emit(girl_id, previous_value, max_value, delta)
		return max_value
	var next_value: int = previous_value + delta
	if definition != null:
		next_value = clampi(next_value, min_value, max_value)
	state.relationship = next_value
	if definition != null and previous_value < max_value and next_value >= max_value:
		girl_relationship_completed.emit(girl_id)
		var rating: Variant = _rating_service()
		if rating != null:
			rating.add_rating(1)
	girl_relationship_changed.emit(girl_id, previous_value, next_value, delta)
	return next_value


func get_next_date_available_at(girl_id: StringName) -> int:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return 0
	return state.next_date_available_at


func is_date_cooldown_finished(girl_id: StringName) -> bool:
	var clock: Variant = _time_service()
	if clock == null:
		return false
	return int(clock.get_game_time_minutes()) >= get_next_date_available_at(girl_id)


func set_date_cooldown(girl_id: StringName, duration_minutes: int) -> void:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return
	var clock: Variant = _time_service()
	var current_time: int = 0
	if clock != null:
		current_time = int(clock.get_game_time_minutes())
	state.next_date_available_at = current_time + maxi(0, duration_minutes)


func fill_date_progress(girl_id: StringName, progress: GirlProgress) -> void:
	var state: GirlState = get_state(girl_id)
	if state == null or progress == null:
		return
	progress.relationship = state.relationship
	progress.revealed_positive_tag_ids = _copy_tag_ids(state.revealed_positive_tag_ids)
	progress.revealed_negative_tag_ids = _copy_tag_ids(state.revealed_negative_tag_ids)
	progress.secondary_revealed = state.secondary_revealed
	progress.completed_dates = state.completed_dates


func apply_date_knowledge(girl_id: StringName, progress: GirlProgress) -> void:
	var state: GirlState = get_state(girl_id)
	if state == null or progress == null:
		return
	state.revealed_positive_tag_ids = _copy_tag_ids(progress.revealed_positive_tag_ids)
	state.revealed_negative_tag_ids = _copy_tag_ids(progress.revealed_negative_tag_ids)
	state.secondary_revealed = progress.secondary_revealed
	state.completed_dates = maxi(0, progress.completed_dates)


func _copy_tag_ids(ids: Array[StringName]) -> Array[StringName]:
	var copy: Array[StringName] = []
	for tag_id in ids:
		copy.append(tag_id)
	return copy


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


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
		return null
	return node


func _rating_service() -> Variant:
	var node: Node = get_node_or_null("/root/RatingService")
	if not is_instance_valid(node):
		push_error("RatingService autoload missing")
		return null
	return node
