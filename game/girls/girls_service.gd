extends Node

signal girl_discovered(girl_id: StringName)
signal girl_contact_received(girl_id: StringName)
signal girl_relationship_changed(girl_id: StringName, previous_value: int, current_value: int, delta: int)
signal girl_relationship_completed(girl_id: StringName)
signal girl_access_changed(girl_id: StringName)

const MEET_ACTION_PREFIX: String = "meet_"
const MEET_TIME_MINUTES: int = 30

var _catalog: GirlCatalog
var _reward_catalog: FillerRewardCatalog
var knowledge_rng: RandomNumberGenerator


func _ready() -> void:
	_catalog = GirlCatalog.create_seed()
	_reward_catalog = FillerRewardCatalog.create_seed()
	_connect_girl_access_signals()


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


func peek_state(girl_id: StringName) -> GirlState:
	if get_definition(girl_id) == null:
		return null
	var girls: GirlsState = _girls()
	if girls == null:
		return null
	var existing: Variant = girls.girls_by_id.get(girl_id, null)
	if existing is GirlState:
		return existing
	return null


func is_discovered(girl_id: StringName) -> bool:
	var state: GirlState = peek_state(girl_id)
	if state == null:
		return false
	return state.discovered


func has_contact(girl_id: StringName) -> bool:
	var state: GirlState = peek_state(girl_id)
	if state == null:
		return false
	return state.has_contact


func get_relationship(girl_id: StringName) -> int:
	var state: GirlState = peek_state(girl_id)
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

func get_home_city_girl_count() -> int:
	var total: int = 0
	for girl in get_catalog().get_all_girls():
		if girl != null and girl.counts_toward_home_city_coverage:
			total += 1
	return total


func get_home_city_completed_count() -> int:
	var completed: int = 0
	var girls: GirlsState = _girls()
	for girl in get_catalog().get_all_girls():
		if girl == null or not girl.counts_toward_home_city_coverage:
			continue
		var existing: GirlState = null
		if girls != null:
			var raw: Variant = girls.girls_by_id.get(girl.id, null)
			if raw is GirlState:
				existing = raw
		if existing != null and existing.relationship >= girl.relationship_max:
			completed += 1
	return completed


func get_home_city_coverage_percent() -> float:
	var total: int = get_home_city_girl_count()
	if total <= 0:
		return 0.0
	return 100.0 * float(get_home_city_completed_count()) / float(total)


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
	apply_initial_known_tags(girl_id)
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
		grant_filler_reward_for_girl(girl_id)
	girl_relationship_changed.emit(girl_id, previous_value, next_value, delta)
	return next_value


func get_filler_reward_catalog() -> FillerRewardCatalog:
	if _reward_catalog == null:
		_reward_catalog = FillerRewardCatalog.create_seed()
	return _reward_catalog


func has_filler_reward(reward_id: StringName) -> bool:
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	return progression.has_filler_reward(reward_id)


func get_filler_reward_for_girl(girl_id: StringName) -> FillerRewardDefinition:
	return get_filler_reward_catalog().get_reward_for_girl(girl_id)


func grant_filler_reward_for_girl(girl_id: StringName) -> bool:
	var reward: FillerRewardDefinition = get_filler_reward_for_girl(girl_id)
	if reward == null:
		return false
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	if not progression.add_filler_reward(reward.id):
		return false
	if reward.id == FillerRewardCatalog.ID_MARINA_FREE_OUTFIT:
		progression.marina_free_outfit_pending = true
	elif reward.id == FillerRewardCatalog.ID_EVA_READ_PEOPLE:
		apply_eva_retro_reveal()
	return true


func is_marina_free_outfit_pending() -> bool:
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	return progression.marina_free_outfit_pending and has_filler_reward(FillerRewardCatalog.ID_MARINA_FREE_OUTFIT)


func clear_marina_free_outfit_pending() -> void:
	var progression: ProgressionState = _progression()
	if progression == null:
		return
	progression.marina_free_outfit_pending = false


func get_effective_initial_known_tag_count(girl_id: StringName) -> int:
	var profile: GirlProfile = _date_girl(girl_id)
	var count: int = 0
	if profile != null:
		count = profile.initial_known_tag_count
	if has_filler_reward(FillerRewardCatalog.ID_EVA_READ_PEOPLE):
		count += FillerRewardCatalog.EVA_INITIAL_KNOWN_TAG_BONUS
	return maxi(0, count)


func apply_initial_known_tags(girl_id: StringName, rng: RandomNumberGenerator = null) -> int:
	var state: GirlState = get_state(girl_id)
	if state == null:
		return 0
	if not state.revealed_positive_tag_ids.is_empty() or not state.revealed_negative_tag_ids.is_empty():
		return 0
	return reveal_random_unknown_tags(girl_id, get_effective_initial_known_tag_count(girl_id), rng)


func apply_eva_retro_reveal(rng: RandomNumberGenerator = null) -> void:
	var girls: GirlsState = _girls()
	if girls == null:
		return
	for girl in get_catalog().get_all_girls():
		if girl == null:
			continue
		var existing: Variant = girls.girls_by_id.get(girl.id, null)
		if not (existing is GirlState):
			continue
		var state: GirlState = existing
		if not state.discovered:
			continue
		if state.relationship >= girl.relationship_max:
			continue
		reveal_random_unknown_tags(girl.id, 1, rng)


func reveal_random_unknown_tags(girl_id: StringName, count: int, rng: RandomNumberGenerator = null) -> int:
	if count <= 0:
		return 0
	var state: GirlState = get_state(girl_id)
	var profile: GirlProfile = _date_girl(girl_id)
	var catalog: DateContentCatalog = _date_catalog()
	if state == null or profile == null or catalog == null:
		return 0
	var unknown: Array[StringName] = []
	for tag in catalog.enabled_tags():
		if tag == null:
			continue
		if state.revealed_positive_tag_ids.has(tag.id) or state.revealed_negative_tag_ids.has(tag.id):
			continue
		unknown.append(tag.id)
	var generator: RandomNumberGenerator = rng
	if generator == null:
		generator = knowledge_rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var revealed: int = 0
	while revealed < count and not unknown.is_empty():
		var index: int = generator.randi_range(0, unknown.size() - 1)
		var tag_id: StringName = unknown[index]
		unknown.remove_at(index)
		if profile.prefers_tag(tag_id) > 0:
			state.revealed_positive_tag_ids.append(tag_id)
		else:
			state.revealed_negative_tag_ids.append(tag_id)
		revealed += 1
	_normalize_girl_knowledge(girl_id)
	return revealed


func force_complete_filler_for_dev(girl_id: StringName) -> bool:
	if get_filler_reward_for_girl(girl_id) == null:
		return false
	discover_girl(girl_id)
	give_contact(girl_id)
	var max_value: int = get_relationship_max(girl_id)
	var current: int = get_relationship(girl_id)
	if current >= max_value:
		return grant_filler_reward_for_girl(girl_id)
	change_relationship(girl_id, max_value - current)
	return has_filler_reward(get_filler_reward_for_girl(girl_id).id)


func reset_filler_reward_for_dev(girl_id: StringName) -> bool:
	var reward: FillerRewardDefinition = get_filler_reward_for_girl(girl_id)
	if reward == null:
		return false
	var progression: ProgressionState = _progression()
	if progression == null:
		return false
	progression.remove_filler_reward(reward.id)
	if reward.id == FillerRewardCatalog.ID_MARINA_FREE_OUTFIT:
		progression.marina_free_outfit_pending = false
	var state: GirlState = get_state(girl_id)
	if state != null:
		state.relationship = maxi(0, get_relationship_max(girl_id) - 1)
	return true


func _date_girl(girl_id: StringName) -> GirlProfile:
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		return null
	return catalog.find_girl(girl_id)


func _date_catalog() -> DateContentCatalog:
	var dating: Variant = get_node_or_null("/root/DatingService")
	if dating == null or not dating.has_method("get_catalog_service"):
		return null
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog


func _progression() -> ProgressionState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.progression as ProgressionState


func fill_date_progress(girl_id: StringName, progress: GirlProgress) -> void:
	var state: GirlState = peek_state(girl_id)
	if state == null or progress == null:
		return
	progress.relationship = state.relationship
	progress.revealed_positive_tag_ids = _copy_tag_ids(state.revealed_positive_tag_ids)
	progress.revealed_negative_tag_ids = _copy_tag_ids(state.revealed_negative_tag_ids)
	progress.completed_dates = state.completed_dates
	progress.last_date_situation_ids = _copy_tag_ids(state.last_date_situation_ids)


func apply_date_knowledge(girl_id: StringName, progress: GirlProgress) -> void:
	var state: GirlState = get_state(girl_id)
	if state == null or progress == null:
		return
	state.revealed_positive_tag_ids = _copy_tag_ids(progress.revealed_positive_tag_ids)
	state.revealed_negative_tag_ids = _copy_tag_ids(progress.revealed_negative_tag_ids)
	state.completed_dates = maxi(0, progress.completed_dates)
	state.last_date_situation_ids = _copy_tag_ids(progress.last_date_situation_ids)
	_normalize_girl_knowledge(girl_id)


func _copy_tag_ids(ids: Array[StringName]) -> Array[StringName]:
	var copy: Array[StringName] = []
	for tag_id in ids:
		copy.append(tag_id)
	return copy


func _normalize_girl_knowledge(girl_id: StringName) -> void:
	var state: GirlState = peek_state(girl_id)
	var profile: GirlProfile = _date_girl(girl_id)
	var catalog: DateContentCatalog = _date_catalog()
	if state == null or profile == null or catalog == null:
		return
	var progress := GirlProgress.new()
	progress.revealed_positive_tag_ids = _copy_tag_ids(state.revealed_positive_tag_ids)
	progress.revealed_negative_tag_ids = _copy_tag_ids(state.revealed_negative_tag_ids)
	progress.normalize_deduced_knowledge(profile, catalog)
	state.revealed_positive_tag_ids = _copy_tag_ids(progress.revealed_positive_tag_ids)
	state.revealed_negative_tag_ids = _copy_tag_ids(progress.revealed_negative_tag_ids)


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
	var action: GameAction = GameAction.new()
	action.id = StringName("%s%s" % [MEET_ACTION_PREFIX, String(girl_id)])
	action.time_cost_minutes = MEET_TIME_MINUTES
	action.money_cost = 0
	var availability: GirlMeetAvailableRequirement = GirlMeetAvailableRequirement.new()
	availability.girl_id = girl_id
	action.requirements.append(availability)
	var effect: MeetGirlEffect = MeetGirlEffect.new()
	effect.girl_id = girl_id
	action.effects.append(effect)
	return action


func can_meet_girl(girl_id: StringName) -> bool:
	var definition: GirlDefinition = get_definition(girl_id)
	if definition == null:
		return false
	var world: Variant = _world_service()
	if world == null:
		return false
	if definition.location_id != world.get_current_location_id():
		return false
	if is_discovered(girl_id):
		return false
	for requirement in definition.meet_requirements:
		if requirement == null:
			continue
		if not requirement.is_met(girl_id):
			return false
	return true


func get_meet_requirements_status(girl_id: StringName) -> Array[RequirementStatus]:
	var definition: GirlDefinition = get_definition(girl_id)
	if definition == null:
		var empty: Array[RequirementStatus] = []
		return empty
	return build_requirement_status_list(girl_id, definition.meet_requirements)


func get_meet_failure_reason(girl_id: StringName) -> String:
	var definition: GirlDefinition = get_definition(girl_id)
	if definition == null:
		return "Девушка не найдена"
	var world: Variant = _world_service()
	var current_location: StringName = &""
	if world != null:
		current_location = world.get_current_location_id()
	if definition.location_id != current_location:
		return "Девушка находится в другой локации"
	if is_discovered(girl_id):
		return "Вы уже знакомы"
	for requirement in definition.meet_requirements:
		if requirement == null:
			continue
		if not requirement.is_met(girl_id):
			return "%s: %s" % [requirement.get_description(girl_id), requirement.get_progress_text(girl_id)]
	return ""


func build_requirement_status_list(
	girl_id: StringName,
	requirements: Array[GirlAccessRequirement]
) -> Array[RequirementStatus]:
	var result: Array[RequirementStatus] = []
	for requirement in requirements:
		if requirement == null:
			continue
		var status: RequirementStatus = RequirementStatus.new()
		status.description = requirement.get_description(girl_id)
		status.progress_text = requirement.get_progress_text(girl_id)
		status.is_met = requirement.is_met(girl_id)
		result.append(status)
	return result


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


func _stage_service() -> Variant:
	var node: Node = get_node_or_null("/root/StageService")
	if not is_instance_valid(node):
		push_error("StageService autoload missing")
		return null
	return node


func _rivals_service() -> Variant:
	var node: Node = get_node_or_null("/root/RivalsService")
	if not is_instance_valid(node):
		push_error("RivalsService autoload missing")
		return null
	return node


func _connect_girl_access_signals() -> void:
	var rating: Variant = _rating_service()
	if rating != null and not rating.rating_changed.is_connected(_on_rating_changed):
		rating.rating_changed.connect(_on_rating_changed)
	var stage: Variant = _stage_service()
	if stage != null and not stage.stage_changed.is_connected(_on_stage_changed):
		stage.stage_changed.connect(_on_stage_changed)
	var rivals: Variant = _rivals_service()
	if rivals != null and not rivals.rival_defeated.is_connected(_on_rival_defeated):
		rivals.rival_defeated.connect(_on_rival_defeated)
	var world: Variant = _world_service()
	if world != null and world.has_signal("city_stage_changed") and not world.city_stage_changed.is_connected(_on_city_stage_changed):
		world.city_stage_changed.connect(_on_city_stage_changed)


func _on_rating_changed(_previous_rating: int, _current_rating: int, _delta: int) -> void:
	_emit_girl_access_changed_for_catalog()


func _on_stage_changed(_previous_stage: int, _current_stage: int) -> void:
	_emit_girl_access_changed_for_catalog()


func _on_rival_defeated(_rival_id: StringName) -> void:
	_emit_girl_access_changed_for_catalog()


func _on_city_stage_changed(_previous_city_stage: int, _current_city_stage: int) -> void:
	_emit_girl_access_changed_for_catalog()


func _emit_girl_access_changed_for_catalog() -> void:
	for definition in get_catalog().get_all_girls():
		if definition != null:
			girl_access_changed.emit(definition.id)
