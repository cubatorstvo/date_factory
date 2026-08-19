class_name LocationDoor
extends Area3D

@export var target_location_id: StringName = &""
@export var target_spawn_id: StringName = &""

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_E:
		return
	use_door()
	get_viewport().set_input_as_handled()


func use_door() -> bool:
	var service: Variant = _scene_transition()
	if service == null:
		return false
	return bool(service.transition_to_location(target_location_id, target_spawn_id))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("world_player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("world_player"):
		_player_inside = false


func _scene_transition() -> Variant:
	var node: Node = get_node_or_null("/root/SceneTransitionService")
	if not is_instance_valid(node):
		return null
	return node
