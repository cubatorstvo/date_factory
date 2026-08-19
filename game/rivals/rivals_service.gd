extends Node

signal rival_discovered(rival_id: StringName)
signal rival_defeated(rival_id: StringName)

const MEET_ACTION_PREFIX: String = "meet_rival_"

var _catalog: RivalCatalog


func _ready() -> void:
	_catalog = RivalCatalog.create_seed()


func get_catalog() -> RivalCatalog:
	if _catalog == null:
		_catalog = RivalCatalog.create_seed()
	return _catalog


func get_definition(rival_id: StringName) -> RivalDefinition:
	return get_catalog().get_rival(rival_id)


func get_state(rival_id: StringName) -> RivalState:
	if get_definition(rival_id) == null:
		return null
	var rivals: RivalsState = _rivals()
	if rivals == null:
		return null
	return rivals.get_or_create(rival_id)


func is_discovered(rival_id: StringName) -> bool:
	var state: RivalState = get_state(rival_id)
	if state == null:
		return false
	return state.discovered


func is_defeated(rival_id: StringName) -> bool:
	var state: RivalState = get_state(rival_id)
	if state == null:
		return false
	return state.defeated


func discover_rival(rival_id: StringName) -> bool:
	var state: RivalState = get_state(rival_id)
	if state == null:
		return false
	if state.discovered:
		return false
	state.discovered = true
	rival_discovered.emit(rival_id)
	return true


func defeat_rival(rival_id: StringName) -> bool:
	var state: RivalState = get_state(rival_id)
	if state == null:
		return false
	state.discovered = true
	if state.defeated:
		return false
	state.defeated = true
	rival_defeated.emit(rival_id)
	return true


func get_rivals_at_current_location() -> Array[RivalDefinition]:
	var location_id: StringName = LocationCatalog.START_LOCATION_ID
	var world: Variant = _world_service()
	if world != null:
		location_id = world.get_current_location_id()
	var result: Array[RivalDefinition] = []
	var girls: Variant = _girls_service()
	for rival in get_catalog().get_rivals_for_location(location_id):
		if rival == null:
			continue
		if rival.linked_girl_id != &"":
			if girls == null or not bool(girls.is_discovered(rival.linked_girl_id)):
				continue
		result.append(rival)
	return result

func get_discovered_rivals() -> Array[RivalDefinition]:
	var result: Array[RivalDefinition] = []
	for definition in get_catalog().get_all_rivals():
		if is_discovered(definition.id):
			result.append(definition)
	return result


func create_meet_rival_action(rival_id: StringName) -> GameAction:
	var action := GameAction.new()
	action.id = StringName("%s%s" % [MEET_ACTION_PREFIX, String(rival_id)])
	action.time_cost_minutes = 0
	action.money_cost = 0
	var not_discovered := RivalNotDiscoveredRequirement.new()
	not_discovered.rival_id = rival_id
	action.requirements.append(not_discovered)
	var location_req := RivalLocationRequirement.new()
	location_req.rival_id = rival_id
	action.requirements.append(location_req)
	var effect := DiscoverRivalEffect.new()
	effect.rival_id = rival_id
	action.effects.append(effect)
	return action


func _rivals() -> RivalsState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.rivals as RivalsState


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

func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
