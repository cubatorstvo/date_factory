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

func count_stage_filler_max(stage: int = -1) -> int:
	var target_stage: int = get_current_stage() if stage < 1 else stage
	var definition: StageDefinition = get_catalog().get_stage(target_stage)
	if definition == null:
		return 0
	var girls: Variant = _girls_service()
	if girls == null:
		return 0
	var count: int = 0
	for girl_id in definition.filler_girl_ids:
		if bool(girls.is_relationship_completed(girl_id)):
			count += 1
	return count


func format_current_stage_summary() -> String:
	var definition: StageDefinition = get_current_definition()
	if definition == null:
		return ""
	var girls: Variant = _girls_service()
	var rating: Variant = _rating_service()
	var rivals: Variant = _rivals_service()
	var current_rating: int = 0
	if rating != null:
		current_rating = int(rating.get_rating())
	var filler_max: int = count_stage_filler_max(definition.stage)
	var required_fillers: int = definition.required_filler_max_count
	var lines: PackedStringArray = PackedStringArray()
	lines.append(definition.display_name)
	lines.append("")
	if required_fillers > 0:
		lines.append("Девушки этапа: %d / %d" % [filler_max, required_fillers])
	if definition.story_girl_required_rating > 0:
		lines.append("Рейтинг: %d / %d" % [current_rating, definition.story_girl_required_rating])
	if not definition.filler_girl_ids.is_empty():
		lines.append("")
		lines.append("Девушки:")
		for girl_id in definition.filler_girl_ids:
			lines.append(_format_girl_progress_line(girls, girl_id))
	if definition.story_girl_id != &"":
		lines.append("")
		lines.append("Story:")
		lines.append(_format_story_girl_line(girls, definition.story_girl_id, filler_max, required_fillers, current_rating, definition.story_girl_required_rating))
	var rival_ids: Array[StringName] = []
	rival_ids.append_array(definition.ordinary_rival_ids)
	if definition.story_rival_id != &"":
		rival_ids.append(definition.story_rival_id)
	if not rival_ids.is_empty():
		lines.append("")
		lines.append("Соперники:")
		for rival_id in rival_ids:
			lines.append(_format_rival_line(girls, rivals, definition, rival_id))
	return "\n".join(lines)


func _format_girl_progress_line(girls: Variant, girl_id: StringName) -> String:
	var display_name: String = String(girl_id)
	var relationship: int = 0
	var relationship_max: int = 0
	var completed: bool = false
	if girls != null:
		var girl: GirlDefinition = girls.get_definition(girl_id) as GirlDefinition
		if girl != null and not girl.display_name.is_empty():
			display_name = girl.display_name
		relationship = int(girls.get_relationship(girl_id))
		relationship_max = int(girls.get_relationship_max(girl_id))
		completed = bool(girls.is_relationship_completed(girl_id))
	if completed:
		return "%s — MAX" % display_name
	return "%s — %d / %d" % [display_name, relationship, relationship_max]


func _format_story_girl_line(girls: Variant, girl_id: StringName, filler_max: int, required_fillers: int, current_rating: int, required_rating: int) -> String:
	var display_name: String = String(girl_id)
	var discovered: bool = false
	if girls != null:
		var girl: GirlDefinition = girls.get_definition(girl_id) as GirlDefinition
		if girl != null and not girl.display_name.is_empty():
			display_name = girl.display_name
		discovered = bool(girls.is_discovered(girl_id))
	if discovered:
		return "%s — открыта" % display_name
	var gated: bool = required_fillers > filler_max or current_rating < required_rating
	if gated:
		return "%s — закрыта" % display_name
	return "%s — доступна" % display_name


func _format_rival_line(girls: Variant, rivals: Variant, definition: StageDefinition, rival_id: StringName) -> String:
	var display_name: String = String(rival_id)
	var linked_girl_id: StringName = &""
	if rivals != null:
		var rival: RivalDefinition = rivals.get_definition(rival_id) as RivalDefinition
		if rival != null:
			if not rival.display_name.is_empty():
				display_name = rival.display_name
			linked_girl_id = rival.linked_girl_id
		if bool(rivals.is_defeated(rival_id)):
			return "%s — побеждён" % display_name
	if linked_girl_id != &"":
		var discovered: bool = girls != null and bool(girls.is_discovered(linked_girl_id))
		if not discovered:
			var girl_name: String = String(linked_girl_id)
			if girls != null:
				var girl: GirlDefinition = girls.get_definition(linked_girl_id) as GirlDefinition
				if girl != null and not girl.display_name.is_empty():
					girl_name = girl.display_name
			return "%s — появится после знакомства с %s" % [display_name, girl_name]
		return "%s — доступен" % display_name
	if get_current_stage() >= definition.stage:
		return "%s — доступен" % display_name
	return "%s — закрыт" % display_name


func _rating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RatingService")
	if not is_instance_valid(node):
		return null
	return node


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node


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
