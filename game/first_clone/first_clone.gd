extends Node
## First Clone one-off sequence owner (MODULE 17).
## Autoload name: FirstClone. Aggregate GameState clone counts are source of truth.
## No _process. Late rates / production owned by CloneIncremental (MODULE 18).

signal sequence_started()
signal calibration_completed()
signal clone_preview_spawned()
signal first_clone_assigned(assignment: FirstCloneTypes.Assignment)
signal first_clone_completed()

var _sequence_active: bool = false
var _awaiting_assignment: bool = false
var _assignment_committed: bool = false
var _committed_assignment: FirstCloneTypes.Assignment = FirstCloneTypes.Assignment.NONE
var _minigame: CloneCalibrationMinigame = null
var _preview_actor: FirstCloneActor = null
var _representative: FirstCloneActor = null
var _assignment_ui: CanvasLayer = null
var _player: Node = null
var _signals_connected: bool = false
var _instant_for_test: bool = false
var _reveal_token: int = 0


func _ready() -> void:
	_connect_signals()
	DfLog.info("MODULE_17", "FirstClone ready")


func set_instant_for_test(enabled: bool) -> void:
	_instant_for_test = enabled


func is_sequence_active() -> bool:
	return _sequence_active


func is_awaiting_assignment() -> bool:
	return _awaiting_assignment


func has_preview_actor() -> bool:
	return _preview_actor != null and is_instance_valid(_preview_actor)


func get_preview_actor() -> FirstCloneActor:
	return _preview_actor


func get_representative_actor() -> FirstCloneActor:
	return _representative


func get_committed_assignment() -> FirstCloneTypes.Assignment:
	return _committed_assignment


func get_machine_availability() -> FirstCloneTypes.MachineAvailability:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return FirstCloneTypes.MachineAvailability.LAB_LOCKED
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload == null or not overload.has_method("is_problem_recognized"):
		return FirstCloneTypes.MachineAvailability.OVERLOAD_NOT_RECOGNIZED
	if not bool(overload.call("is_problem_recognized")):
		return FirstCloneTypes.MachineAvailability.OVERLOAD_NOT_RECOGNIZED
	if not bool(gs.call("is_girl_conquered", FirstCloneTypes.SCIENTIST_GIRL_ID)):
		return FirstCloneTypes.MachineAvailability.SCIENTIST_NOT_COMPLETED
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("is_feature_unlocked"):
		return FirstCloneTypes.MachineAvailability.LAB_LOCKED
	if not bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)):
		return FirstCloneTypes.MachineAvailability.LAB_LOCKED
	if int(gs.call("get_total_clones")) >= 1:
		return FirstCloneTypes.MachineAvailability.ALREADY_CREATED
	if _sequence_active:
		return FirstCloneTypes.MachineAvailability.SEQUENCE_ACTIVE
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		return FirstCloneTypes.MachineAvailability.NOT_IN_LAB
	var loc_id: StringName = &""
	if "current_location_id" in world:
		loc_id = world.get("current_location_id") as StringName
	if loc_id != FirstCloneTypes.LOCATION_LABORATORY:
		return FirstCloneTypes.MachineAvailability.NOT_IN_LAB
	return FirstCloneTypes.MachineAvailability.AVAILABLE


func is_eligible() -> bool:
	return get_machine_availability() == FirstCloneTypes.MachineAvailability.AVAILABLE


func get_status() -> FirstCloneStatus:
	var status: FirstCloneStatus = FirstCloneStatus.new()
	var gs: Node = get_node_or_null("/root/GameState")
	var total: int = 0
	if gs != null:
		total = int(gs.call("get_total_clones"))
	status.clone_created = total >= 1
	status.sequence_active = _sequence_active
	status.availability = get_machine_availability()
	status.eligible = status.availability == FirstCloneTypes.MachineAvailability.AVAILABLE
	if status.clone_created:
		if gs != null and int(gs.call("get_clones_working")) >= 1:
			status.assignment = FirstCloneTypes.Assignment.WORK
		elif gs != null and int(gs.call("get_clones_dating")) >= 1:
			status.assignment = FirstCloneTypes.Assignment.DATING
		else:
			status.assignment = _committed_assignment
	else:
		status.assignment = FirstCloneTypes.Assignment.NONE
	return status


func start_sequence(player: Node = null) -> bool:
	if not is_eligible():
		return false
	if _sequence_active:
		return false
	_sequence_active = true
	_awaiting_assignment = false
	_assignment_committed = false
	_committed_assignment = FirstCloneTypes.Assignment.NONE
	_player = player
	_clear_preview()
	_minigame = CloneCalibrationMinigame.new()
	_minigame.name = "CloneCalibrationMinigame"
	add_child(_minigame)
	if not _minigame.calibration_finished.is_connected(_on_calibration_finished):
		_minigame.calibration_finished.connect(_on_calibration_finished)
	if not _minigame.calibration_aborted.is_connected(_on_calibration_aborted):
		_minigame.calibration_aborted.connect(_on_calibration_aborted)
	var ok: bool = _minigame.start(player)
	if not ok:
		_sequence_active = false
		_minigame.queue_free()
		_minigame = null
		return false
	sequence_started.emit()
	return true


func abort_sequence() -> void:
	if not _sequence_active:
		return
	if _assignment_committed:
		return
	if _minigame != null and is_instance_valid(_minigame) and not _minigame.is_finished():
		_minigame.abort_calibration()
		return
	_cleanup_incomplete_sequence()


func assign_work() -> bool:
	return _commit_assignment(FirstCloneTypes.Assignment.WORK)


func assign_dating() -> bool:
	return _commit_assignment(FirstCloneTypes.Assignment.DATING)


## Headless helper: finish calibration instantly into assignment modal state.
func complete_calibration_for_test() -> bool:
	if not _sequence_active:
		if not start_sequence(null):
			return false
	if _minigame != null and is_instance_valid(_minigame) and not _minigame.is_finished():
		_instant_for_test = true
		_minigame.force_complete_all_for_test()
		return _awaiting_assignment or has_preview_actor()
	return _awaiting_assignment


func reconstruct_representative() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if int(gs.call("get_total_clones")) < 1:
		_clear_representative()
		return
	# MODULE 19: when lab has CloneVisualizationController, it owns aggregate visuals.
	if _lab_has_clone_visualization_controller():
		_clear_representative()
		return
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		return
	var loc_id: StringName = &""
	if "current_location_id" in world:
		loc_id = world.get("current_location_id") as StringName
	if loc_id != FirstCloneTypes.LOCATION_LABORATORY:
		_clear_representative()
		return
	var marker_name: String = FirstCloneTypes.MARKER_WORK
	if int(gs.call("get_clones_working")) >= 1:
		marker_name = FirstCloneTypes.MARKER_WORK
	elif int(gs.call("get_clones_dating")) >= 1:
		marker_name = FirstCloneTypes.MARKER_DATE
	else:
		marker_name = FirstCloneTypes.MARKER_OUTPUT
	var marker: Node3D = _find_marker(marker_name)
	if marker == null:
		# Soft fallback: keep one actor under FirstClone if markers absent (tests/lab WIP).
		if _representative != null and is_instance_valid(_representative):
			return
		_representative = FirstCloneActor.new()
		_representative.name = "FirstCloneRepresentative"
		add_child(_representative)
		_representative.ensure_character()
		return
	if _representative != null and is_instance_valid(_representative):
		if _representative.get_parent() == marker:
			return
		_representative.reparent(marker)
		_representative.transform = Transform3D.IDENTITY
		return
	_representative = FirstCloneActor.new()
	_representative.name = "FirstCloneRepresentative"
	marker.add_child(_representative)
	_representative.transform = Transform3D.IDENTITY
	_representative.ensure_character()


func _connect_signals() -> void:
	if _signals_connected:
		return
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_signal("location_changed"):
		if not world.is_connected("location_changed", _on_location_changed):
			world.connect("location_changed", _on_location_changed)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.connect("clone_counts_changed", _on_clone_counts_changed)
	_signals_connected = true


func _on_clone_counts_changed(_total: int, _working: int, _dating: int, _free: int) -> void:
	# Skip during first-assignment commit so preview placement owns the representative.
	if _awaiting_assignment or _sequence_active:
		return
	reconstruct_representative()


func _on_location_changed(new_location_id: StringName, _previous_location_id: StringName) -> void:
	if new_location_id == FirstCloneTypes.LOCATION_LABORATORY:
		reconstruct_representative()
	else:
		_clear_representative()


func _on_state_reset() -> void:
	_reveal_token += 1
	_sequence_active = false
	_awaiting_assignment = false
	_assignment_committed = false
	_committed_assignment = FirstCloneTypes.Assignment.NONE
	_player = null
	if _minigame != null and is_instance_valid(_minigame):
		_minigame.queue_free()
	_minigame = null
	_close_assignment_ui()
	_clear_preview()
	_clear_representative()


func _on_calibration_finished() -> void:
	_minigame = null
	calibration_completed.emit()
	_begin_reveal()


func _on_calibration_aborted() -> void:
	_minigame = null
	_cleanup_incomplete_sequence()


func _cleanup_incomplete_sequence() -> void:
	_reveal_token += 1
	_sequence_active = false
	_awaiting_assignment = false
	_assignment_committed = false
	_committed_assignment = FirstCloneTypes.Assignment.NONE
	_close_assignment_ui()
	_clear_preview()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and int(gs.call("get_total_clones")) == 0:
		# Ensure abort leaves zero counts.
		gs.call("set_clone_counts", 0, 0, 0)
	_player = null


func _begin_reveal() -> void:
	_reveal_token += 1
	var token: int = _reveal_token
	if _instant_for_test:
		_spawn_preview_and_open_assignment()
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		_spawn_preview_and_open_assignment()
		return
	tree.create_timer(FirstCloneTypes.REVEAL_DELAY_SEC).timeout.connect(
		func() -> void:
			if token != _reveal_token:
				return
			_spawn_preview_and_open_assignment()
	)


func _spawn_preview_and_open_assignment() -> void:
	if not _sequence_active:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and int(gs.call("get_total_clones")) >= 1:
		return
	_clear_preview()
	var parent: Node = _find_marker(FirstCloneTypes.MARKER_OUTPUT)
	if parent == null:
		parent = self
	_preview_actor = FirstCloneActor.new()
	_preview_actor.name = "FirstClonePreview"
	parent.add_child(_preview_actor)
	if parent is Node3D:
		_preview_actor.transform = Transform3D.IDENTITY
	_preview_actor.ensure_character()
	_preview_actor.set_visible_presence(true)
	clone_preview_spawned.emit()
	_awaiting_assignment = true
	_open_assignment_ui()


func _commit_assignment(kind: FirstCloneTypes.Assignment) -> bool:
	if _assignment_committed:
		return false
	if not _awaiting_assignment:
		return false
	if kind != FirstCloneTypes.Assignment.WORK and kind != FirstCloneTypes.Assignment.DATING:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if int(gs.call("get_total_clones")) >= 1:
		return false
	var total: int = 1
	var working: int = 1 if kind == FirstCloneTypes.Assignment.WORK else 0
	var dating: int = 1 if kind == FirstCloneTypes.Assignment.DATING else 0
	# Atomic commit — CloneIncremental owns late rates via clone_counts_changed.
	var ok: bool = bool(gs.call("set_clone_counts", total, working, dating))
	if not ok:
		return false
	_assignment_committed = true
	_committed_assignment = kind
	_awaiting_assignment = false
	_close_assignment_ui()
	_place_assigned_actor(kind)
	first_clone_assigned.emit(kind)
	_sequence_active = false
	first_clone_completed.emit()
	return true


func _place_assigned_actor(kind: FirstCloneTypes.Assignment) -> void:
	# MODULE 19 owns aggregate lab visuals — do not leave a duplicate FirstClone body.
	if _lab_has_clone_visualization_controller():
		_clear_preview()
		_clear_representative()
		return
	var marker_name: String = FirstCloneTypes.MARKER_WORK
	if kind == FirstCloneTypes.Assignment.DATING:
		marker_name = FirstCloneTypes.MARKER_DATE
	var marker: Node3D = _find_marker(marker_name)
	var actor: FirstCloneActor = _preview_actor
	if actor == null or not is_instance_valid(actor):
		actor = FirstCloneActor.new()
		actor.name = "FirstCloneRepresentative"
		if marker != null:
			marker.add_child(actor)
		else:
			add_child(actor)
		actor.ensure_character()
	elif marker != null and actor.get_parent() != marker:
		actor.reparent(marker)
	if marker != null:
		if _instant_for_test:
			actor.transform = Transform3D.IDENTITY
		else:
			var tween: Tween = create_tween()
			tween.tween_property(actor, "transform", Transform3D.IDENTITY, FirstCloneTypes.ASSIGN_TWEEN_SEC)
	else:
		actor.transform = Transform3D.IDENTITY
	_representative = actor
	_preview_actor = null


func _open_assignment_ui() -> void:
	_close_assignment_ui()
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "FirstCloneAssignmentUI"
	layer.layer = 92
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.03, 0.55)
	root.add_child(dim)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -140)
	panel.size = Vector2(520, 280)
	root.add_child(panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)
	var title: Label = Label.new()
	title.text = FirstCloneTypes.ASSIGNMENT_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	var line: Label = Label.new()
	line.text = "Клон:\n«%s»" % FirstCloneTypes.CLONE_LINE
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(line)
	var work_btn: Button = Button.new()
	work_btn.text = FirstCloneTypes.ASSIGNMENT_WORK
	work_btn.pressed.connect(func() -> void:
		assign_work()
	)
	vbox.add_child(work_btn)
	var dating_btn: Button = Button.new()
	dating_btn.text = FirstCloneTypes.ASSIGNMENT_DATING
	dating_btn.pressed.connect(func() -> void:
		assign_dating()
	)
	vbox.add_child(dating_btn)
	add_child(layer)
	_assignment_ui = layer
	if _player != null and is_instance_valid(_player):
		if _player.has_method("enter_modal_ui"):
			_player.call("enter_modal_ui")


func _close_assignment_ui() -> void:
	if _assignment_ui != null and is_instance_valid(_assignment_ui):
		_assignment_ui.queue_free()
	_assignment_ui = null
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
		if not _sequence_active or _assignment_committed:
			_player.call("enter_gameplay")


func _clear_preview() -> void:
	if _preview_actor != null and is_instance_valid(_preview_actor):
		_preview_actor.queue_free()
	_preview_actor = null


func _clear_representative() -> void:
	if _representative != null and is_instance_valid(_representative):
		_representative.queue_free()
	_representative = null


func _lab_has_clone_visualization_controller() -> bool:
	# String/group detection avoids hard class_name parse coupling to MODULE 19.
	var tree: SceneTree = get_tree()
	if tree != null:
		var grouped: Array = tree.get_nodes_in_group("clone_visualization_controller")
		for node in grouped:
			if node != null and is_instance_valid(node):
				return true
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_current_location"):
		var loc: Node = world.call("get_current_location") as Node
		if loc != null and _node_contains_clone_visualization_controller(loc):
			return true
	if tree != null and tree.current_scene != null:
		if _node_contains_clone_visualization_controller(tree.current_scene):
			return true
	return false


func _node_contains_clone_visualization_controller(root: Node) -> bool:
	if root == null:
		return false
	if _node_is_clone_visualization_controller(root):
		return true
	var named: Node = root.find_child("CloneVisualizationController", true, false)
	return _node_is_clone_visualization_controller(named)


func _node_is_clone_visualization_controller(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var script_res: Script = node.get_script() as Script
	if script_res == null:
		return false
	var path: String = String(script_res.resource_path)
	return path.ends_with("clone_visualization_controller.gd")


func _find_marker(marker_name: String) -> Node3D:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_current_location"):
		var loc: Node = world.call("get_current_location") as Node
		if loc != null:
			var found: Node = loc.find_child(marker_name, true, false)
			if found is Node3D:
				return found as Node3D
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var scene: Node = tree.current_scene
	if scene != null:
		var n: Node = scene.find_child(marker_name, true, false)
		if n is Node3D:
			return n as Node3D
	var under_self: Node = find_child(marker_name, true, false)
	if under_self is Node3D:
		return under_self as Node3D
	return null
