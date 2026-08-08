class_name FirstCloneMachineInteractable
extends Interactable
## Physical first-clone machine entry in laboratory (MODULE 17).
## Placed in laboratory.tscn at story_point_clone_machine.

var _busy: bool = false


func _ready() -> void:
	prompt_action = FirstCloneTypes.MACHINE_PROMPT
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()
	_connect_signals()
	_refresh_presence()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	if _busy:
		return false
	var fc: Node = get_node_or_null("/root/FirstClone")
	if fc == null:
		return false
	var avail: int = int(fc.call("get_machine_availability"))
	if avail == int(FirstCloneTypes.MachineAvailability.ALREADY_CREATED):
		return true
	if avail != int(FirstCloneTypes.MachineAvailability.AVAILABLE):
		return false
	if player == null or not player.has_method("get_control_mode"):
		return true
	var mode: Variant = player.call("get_control_mode")
	return int(mode) == int(PlayerController.ControlMode.GAMEPLAY)


func get_interaction_prompt(_player: Node) -> String:
	var fc: Node = get_node_or_null("/root/FirstClone")
	if fc != null:
		var avail: int = int(fc.call("get_machine_availability"))
		if avail == int(FirstCloneTypes.MachineAvailability.ALREADY_CREATED):
			return FirstCloneTypes.MACHINE_DONE_PROMPT
	if can_interact(_player):
		return "[E] %s" % FirstCloneTypes.MACHINE_PROMPT
	return ""


func _on_interact(player: Node) -> void:
	if _busy:
		return
	var fc: Node = get_node_or_null("/root/FirstClone")
	if fc == null:
		return
	var avail: int = int(fc.call("get_machine_availability"))
	if avail == int(FirstCloneTypes.MachineAvailability.ALREADY_CREATED):
		return
	if not can_interact(player):
		return
	_busy = true
	var started: bool = bool(fc.call("start_sequence", player))
	if not started:
		_busy = false
		return
	if fc.has_signal("first_clone_completed") and not fc.is_connected("first_clone_completed", _on_sequence_done):
		fc.connect("first_clone_completed", _on_sequence_done)
	# Abort path: sequence ends without completion signal when aborted mid-calibration.
	if fc.has_signal("sequence_started"):
		pass
	_watch_sequence_end(fc)


func _watch_sequence_end(fc: Node) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		_busy = false
		return
	# Poll lightly via timer until sequence inactive (abort or complete).
	while is_inside_tree() and _busy:
		await tree.create_timer(0.2).timeout
		if fc == null or not is_instance_valid(fc):
			break
		if not bool(fc.call("is_sequence_active")) and not bool(fc.call("is_awaiting_assignment")):
			break
	_busy = false
	_refresh_presence()


func _on_sequence_done() -> void:
	_busy = false
	_refresh_presence()


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = get_node_or_null("Collision") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.6, 2.2, 1.6)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.1, 0.0)
	add_child(shape_node)


func _connect_signals() -> void:
	var fc: Node = get_node_or_null("/root/FirstClone")
	if fc != null:
		if fc.has_signal("first_clone_completed") and not fc.is_connected("first_clone_completed", _on_sequence_done):
			fc.connect("first_clone_completed", _on_sequence_done)
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_signal("problem_recognized"):
		if not overload.is_connected("problem_recognized", _on_presence_changed):
			overload.connect("problem_recognized", _on_presence_changed)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.connect("clone_counts_changed", _on_clone_counts_changed)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_signal("location_changed"):
		if not world.is_connected("location_changed", _on_location_changed):
			world.connect("location_changed", _on_location_changed)


func _refresh_presence() -> void:
	var world: Node = get_node_or_null("/root/World")
	var in_lab: bool = false
	if world != null and "current_location_id" in world:
		in_lab = (world.get("current_location_id") as StringName) == FirstCloneTypes.LOCATION_LABORATORY
	visible = in_lab
	monitorable = in_lab


func _on_presence_changed(_a: Variant = null, _b: Variant = null) -> void:
	_refresh_presence()


func _on_clone_counts_changed(_total: int, _working: int, _dating: int, _free: int) -> void:
	_refresh_presence()


func _on_feature_unlocked(_feature: Variant) -> void:
	_refresh_presence()


func _on_location_changed(_new_location_id: StringName, _previous_location_id: StringName) -> void:
	_refresh_presence()


func _on_state_reset() -> void:
	_busy = false
	_refresh_presence()
