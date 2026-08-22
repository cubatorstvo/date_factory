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


func peek_state(rival_id: StringName) -> RivalState:
	if get_definition(rival_id) == null:
		return null
	var rivals: RivalsState = _rivals()
	if rivals == null:
		return null
	var existing: Variant = rivals.rivals_by_id.get(rival_id, null)
	if existing is RivalState:
		return existing
	return null


func is_discovered(rival_id: StringName) -> bool:
	var state: RivalState = peek_state(rival_id)
	if state == null:
		return false
	return state.discovered


func is_defeated(rival_id: StringName) -> bool:
	var state: RivalState = peek_state(rival_id)
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
	var story_stage: int = 1
	var stages: Variant = _stage_service()
	if stages != null:
		story_stage = int(stages.get_current_stage())
	var result: Array[RivalDefinition] = []
	var girls: Variant = _girls_service()
	for rival in get_catalog().get_rivals_for_location(location_id):
		if rival == null:
			continue
		if not _is_available_at_story_stage(rival, story_stage):
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


func is_story_rival(rival_id: StringName) -> bool:
	var definition: RivalDefinition = get_definition(rival_id)
	if definition == null:
		return false
	return definition.linked_girl_id != &""


func is_repeatable_rival(rival_id: StringName) -> bool:
	var definition: RivalDefinition = get_definition(rival_id)
	if definition == null:
		return false
	return definition.linked_girl_id == &""


func can_challenge_now(rival_id: StringName) -> bool:
	if not is_discovered(rival_id):
		return false
	if is_story_rival(rival_id) and is_defeated(rival_id):
		return false
	var daily: Variant = get_node_or_null("/root/DailyActivityService")
	if daily == null:
		return false
	return bool(daily.is_available(daily.rival_key(rival_id), 1))


func get_challenge_available_at(rival_id: StringName) -> int:
	if is_story_rival(rival_id):
		return 0
	return get_next_challenge_available_at(rival_id)


func get_challenge_cooldown_remaining(rival_id: StringName) -> int:
	return get_challenge_cooldown_remaining_minutes(rival_id)


func get_last_challenge_completed_at(rival_id: StringName) -> int:
	var state: RivalState = peek_state(rival_id)
	if state == null:
		return 0
	return state.last_challenge_completed_at


func get_next_challenge_available_at(rival_id: StringName) -> int:
	if can_challenge_now(rival_id):
		return 0
	if is_story_rival(rival_id) and is_defeated(rival_id):
		return 0
	var clock: Variant = _time_service()
	if clock == null:
		return 0
	var minutes: int = int(clock.get_game_time_minutes())
	return (int(minutes / 1440) + 1) * 1440


func is_challenge_cooldown_finished(rival_id: StringName) -> bool:
	var clock: Variant = _time_service()
	if clock == null:
		return false
	return int(clock.get_game_time_minutes()) >= get_next_challenge_available_at(rival_id)


func get_challenge_cooldown_remaining_minutes(rival_id: StringName) -> int:
	if can_challenge_now(rival_id):
		return 0
	if is_story_rival(rival_id) and is_defeated(rival_id):
		return 0
	var clock: Variant = _time_service()
	if clock == null:
		return 0
	var minutes: int = int(clock.get_game_time_minutes())
	var next_day_start: int = (int(minutes / 1440) + 1) * 1440
	return maxi(0, next_day_start - minutes)


func mark_challenge_completed(rival_id: StringName, completed_at: int = -1) -> void:
	var state: RivalState = get_state(rival_id)
	if state == null:
		return
	var clock: Variant = _time_service()
	var recorded_at: int = completed_at
	if recorded_at < 0:
		recorded_at = 0
		if clock != null:
			recorded_at = int(clock.get_game_time_minutes())
	state.last_challenge_completed_at = maxi(1, recorded_at)
	var daily: Variant = get_node_or_null("/root/DailyActivityService")
	if daily != null:
		daily.register_usage(daily.rival_key(rival_id), 1)


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


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
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

func _is_available_at_story_stage(rival: RivalDefinition, story_stage: int) -> bool:
	if rival == null:
		return false
	var stages: Variant = _stage_service()
	if stages != null:
		var catalog: StageCatalog = stages.get_catalog() as StageCatalog
		if catalog != null:
			var definition: StageDefinition = catalog.find_stage_for_rival(rival.id)
			if definition != null:
				return definition.stage <= story_stage
	return rival.minimum_story_stage <= story_stage


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node
