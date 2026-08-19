extends Node

signal stage_progress_changed(stage: int)
signal stage_completed(stage: int)
signal stage_changed(previous_stage: int, current_stage: int)
signal finale_reached()

const FIRST_STAGE: int = 1
const LAST_STAGE: int = 6

var _catalog: StageCatalog


func _ready() -> void:
	_catalog = StageCatalog.create_seed()
	_ensure_girls_subscription()
	_ensure_automation_subscription()


func get_catalog() -> StageCatalog:
	if _catalog == null:
		_catalog = StageCatalog.create_seed()
	_ensure_girls_subscription()
	return _catalog


func get_current_stage() -> int:
	var story: StoryState = _story()
	if story == null:
		return FIRST_STAGE
	return story.stage


func is_finale_reached() -> bool:
	var story: StoryState = _story()
	if story == null:
		return false
	return story.finale_reached


func get_current_definition() -> StageDefinition:
	return get_catalog().get_stage(get_current_stage())


func get_current_requirement() -> StageRequirement:
	var definition: StageDefinition = get_current_definition()
	if definition == null:
		return null
	return definition.completion_requirement


func can_complete_current_stage() -> bool:
	if is_finale_reached():
		return false
	var definition: StageDefinition = get_current_definition()
	if definition == null:
		return false
	var requirement: StageRequirement = definition.completion_requirement
	if requirement == null:
		return false
	return requirement.is_met()


func try_complete_current_stage() -> bool:
	if not can_complete_current_stage():
		return false
	_advance_from_completed_stage()
	return true


func force_complete_current_stage_for_dev() -> bool:
	var story: StoryState = _story()
	if story == null:
		return false
	if story.finale_reached:
		return false
	if story.stage >= FIRST_STAGE and story.stage <= LAST_STAGE:
		_advance_from_completed_stage()
		return true
	return false


func reconcile_stage_entry_state() -> void:
	var current: int = get_current_stage()
	var catalog: StageCatalog = get_catalog()
	for stage_number in range(FIRST_STAGE, current + 1):
		_apply_enter_effects(catalog.get_stage(stage_number))


func _advance_from_completed_stage() -> void:
	var story: StoryState = _story()
	if story == null:
		return
	var current_stage: int = story.stage
	if current_stage == LAST_STAGE:
		story.finale_reached = true
		stage_completed.emit(LAST_STAGE)
		finale_reached.emit()
		return
	if current_stage < LAST_STAGE:
		stage_completed.emit(current_stage)
		story.stage += 1
		_apply_enter_effects(get_current_definition())
		stage_changed.emit(current_stage, story.stage)
		try_complete_current_stage()


func _apply_enter_effects(definition: StageDefinition) -> void:
	if definition == null:
		return
	for effect in definition.on_enter_effects:
		if effect != null:
			effect.apply()


func _ensure_girls_subscription() -> void:
	var girls: Variant = _girls_service()
	if girls == null:
		call_deferred("_ensure_girls_subscription")
		return
	if girls.girl_relationship_changed.is_connected(_on_girl_relationship_changed):
		return
	girls.girl_relationship_changed.connect(_on_girl_relationship_changed)


func _on_girl_relationship_changed(_girl_id: StringName, _previous_value: int, _current_value: int, _delta: int) -> void:
	stage_progress_changed.emit(get_current_stage())
	try_complete_current_stage()

func _ensure_automation_subscription() -> void:
	var automation: Variant = _automation_service()
	if automation == null:
		call_deferred("_ensure_automation_subscription")
		return
	if automation.expansion_changed.is_connected(_on_expansion_changed):
		return
	automation.expansion_changed.connect(_on_expansion_changed)


func _on_expansion_changed() -> void:
	stage_progress_changed.emit(get_current_stage())
	try_complete_current_stage()


func _girls_service() -> Variant:
	var node: Node = get_node_or_null("/root/GirlsService")
	if not is_instance_valid(node):
		return null
	return node

func _automation_service() -> Variant:
	var node: Node = get_node_or_null("/root/AutomationService")
	if not is_instance_valid(node):
		return null
	return node


func _story() -> StoryState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.story as StoryState
