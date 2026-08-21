extends Node

signal tutorial_requested(definition: TutorialDefinition)
signal milestone_requested(definition: MilestoneDefinition)
signal message_closed

var _catalog: GuidanceCatalog = GuidanceCatalog.new()
var _queue: Array[Dictionary] = []
var _active_kind: StringName = &""
var _active_id: StringName = &""


func _ready() -> void:
	_connect_sources()


func get_catalog() -> GuidanceCatalog:
	return _catalog


func request_tutorial(tutorial_id: StringName) -> bool:
	return _enqueue(&"tutorial", tutorial_id)


func request_milestone(milestone_id: StringName) -> bool:
	return _enqueue(&"milestone", milestone_id)


func dismiss_current() -> void:
	if _active_id == &"":
		return
	var guidance: GuidanceState = _guidance_state()
	if guidance != null:
		if _active_kind == &"tutorial":
			guidance.mark_tutorial_seen(_active_id)
		elif _active_kind == &"milestone":
			guidance.mark_milestone_seen(_active_id)
	_active_kind = &""
	_active_id = &""
	message_closed.emit()
	_present_next()


func has_active_message() -> bool:
	return _active_id != &"" or not _queue.is_empty()


func get_active_kind() -> StringName:
	return _active_kind


func get_active_id() -> StringName:
	return _active_id


func on_playthrough_reset() -> void:
	_queue.clear()
	_active_kind = &""
	_active_id = &""


func _connect_sources() -> void:
	var stages: Variant = _stage_service()
	if stages != null:
		if stages.has_signal("stage_changed") and not stages.stage_changed.is_connected(_on_stage_changed):
			stages.stage_changed.connect(_on_stage_changed)
		if stages.has_signal("finale_reached") and not stages.finale_reached.is_connected(_on_finale_reached):
			stages.finale_reached.connect(_on_finale_reached)
	var automation: Variant = _automation_service()
	if automation != null and automation.has_signal("automation_unlocked"):
		if not automation.automation_unlocked.is_connected(_on_automation_unlocked):
			automation.automation_unlocked.connect(_on_automation_unlocked)


func _on_stage_changed(_previous_stage: int, current_stage: int) -> void:
	var milestone_id: StringName = _catalog.milestone_for_stage_enter(current_stage)
	if milestone_id != &"":
		request_milestone(milestone_id)


func _on_finale_reached() -> void:
	request_milestone(GuidanceCatalog.ID_WORLD_REACHED)


func _on_automation_unlocked() -> void:
	call_deferred("_request_factory_intro")


func _request_factory_intro() -> void:
	request_tutorial(GuidanceCatalog.ID_FACTORY_INTRO)


func _enqueue(kind: StringName, id: StringName) -> bool:
	if id == &"":
		return false
	var guidance: GuidanceState = _guidance_state()
	if guidance != null:
		if kind == &"tutorial" and guidance.has_seen_tutorial(id):
			return false
		if kind == &"milestone" and guidance.has_seen_milestone(id):
			return false
	if _active_kind == kind and _active_id == id:
		return false
	for item in _queue:
		if StringName(item.get("kind", &"")) == kind and StringName(item.get("id", &"")) == id:
			return false
	var entry: Dictionary = {
		"kind": kind,
		"id": id,
	}
	_queue.append(entry)
	_present_next()
	return true


func _present_next() -> void:
	if _active_id != &"":
		return
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		var kind: StringName = StringName(entry.get("kind", &""))
		var id: StringName = StringName(entry.get("id", &""))
		var guidance: GuidanceState = _guidance_state()
		if guidance != null:
			if kind == &"tutorial" and guidance.has_seen_tutorial(id):
				continue
			if kind == &"milestone" and guidance.has_seen_milestone(id):
				continue
		if kind == &"tutorial":
			var tutorial: TutorialDefinition = _catalog.get_tutorial(id)
			if tutorial == null:
				continue
			_active_kind = kind
			_active_id = id
			tutorial_requested.emit(tutorial)
			return
		if kind == &"milestone":
			var milestone: MilestoneDefinition = _catalog.get_milestone(id)
			if milestone == null:
				continue
			_active_kind = kind
			_active_id = id
			milestone_requested.emit(milestone)
			return


func _guidance_state() -> GuidanceState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.guidance as GuidanceState


func _game_state() -> Variant:
	return _tree_node("GameState")


func _stage_service() -> Variant:
	return _tree_node("StageService")


func _automation_service() -> Variant:
	return _tree_node("AutomationService")


func _tree_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null(node_name)
	if not is_instance_valid(node):
		return null
	return node
