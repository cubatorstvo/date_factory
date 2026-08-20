extends Node

signal location_unlocked(location_id: StringName)
signal location_changed(previous_location_id: StringName, current_location_id: StringName)
signal city_stage_changed(previous_city_stage: int, current_city_stage: int)

var _catalog: LocationCatalog


func _ready() -> void:
	_catalog = LocationCatalog.create_seed()


func get_catalog() -> LocationCatalog:
	if _catalog == null:
		_catalog = LocationCatalog.create_seed()
	return _catalog


func get_current_location_id() -> StringName:
	var world: WorldState = _world()
	if world == null:
		return LocationCatalog.START_LOCATION_ID
	return world.current_location_id


func get_current_location() -> LocationDefinition:
	return get_catalog().get_location(get_current_location_id())


func is_location_unlocked(location_id: StringName) -> bool:
	var world: WorldState = _world()
	if world == null:
		return false
	return world.has_unlocked(location_id)


func unlock_location(location_id: StringName) -> bool:
	var world: WorldState = _world()
	if world == null:
		return false
	if not world.add_unlocked(location_id):
		return false
	location_unlocked.emit(location_id)
	return true


func can_enter_location(location_id: StringName) -> bool:
	if get_catalog().get_location(location_id) == null:
		return false
	return is_location_unlocked(location_id)


func get_city_stage() -> int:
	var world: WorldState = _world()
	if world == null:
		return 1
	return clampi(world.city_stage, 1, CityProgressionService.MAX_CITY_STAGE)


func set_city_stage(target_stage: int) -> bool:
	var world: WorldState = _world()
	if world == null:
		return false
	var next_stage: int = clampi(target_stage, 1, CityProgressionService.MAX_CITY_STAGE)
	next_stage = maxi(world.city_stage, next_stage)
	if next_stage == world.city_stage:
		return false
	var previous_stage: int = world.city_stage
	world.city_stage = next_stage
	city_stage_changed.emit(previous_stage, next_stage)
	return true


func enter_location(location_id: StringName) -> bool:
	if not can_enter_location(location_id):
		return false
	var world: WorldState = _world()
	if world == null:
		return false
	var previous_location_id: StringName = world.current_location_id
	world.current_location_id = location_id
	location_changed.emit(previous_location_id, location_id)
	return true


func _world() -> WorldState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.world as WorldState
