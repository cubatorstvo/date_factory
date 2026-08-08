class_name FinalCheckpointInteractable
extends Interactable
## Walk checkpoint for MODULE 21 final date phases. Spawned by FinalDateController.


var checkpoint_id: StringName = &""
var _controller: FinalDateController = null


func setup(controller: FinalDateController, id: StringName, prompt: String) -> void:
	_controller = controller
	checkpoint_id = id
	prompt_action = prompt
	interaction_enabled = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	if _controller == null or not is_instance_valid(_controller):
		return false
	return _controller.is_checkpoint_active(checkpoint_id)


func get_interaction_prompt(player: Node) -> String:
	if not can_interact(player):
		return ""
	return "[E] %s" % prompt_action


func _on_interact(player: Node) -> void:
	if not can_interact(player):
		return
	if _controller != null and is_instance_valid(_controller):
		_controller.notify_checkpoint(checkpoint_id)


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.2, 1.6)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.1, 0.0)
	add_child(shape_node)
