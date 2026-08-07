extends RayCast3D
## Center-screen interaction query owned by Player.

signal target_changed(target: Area3D)

var _player: CharacterBody3D
var _current: Area3D = null


func setup(player: CharacterBody3D, distance: float) -> void:
	_player = player
	target_position = Vector3(0.0, 0.0, -distance)
	collide_with_areas = true
	collide_with_bodies = true
	enabled = true


func set_query_enabled(active: bool) -> void:
	enabled = active
	if not active:
		_set_current(null)


func get_current_target() -> Area3D:
	return _current


func try_interact() -> bool:
	if _current == null or _player == null:
		return false
	if not bool(_current.call("can_interact", _player)):
		return false
	_current.call("interact", _player)
	return true


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	force_raycast_update()
	var next: Area3D = null
	if is_colliding():
		next = _find_interactable(get_collider())
		if next != null and not bool(next.call("can_interact", _player)):
			next = null
	_set_current(next)


func _set_current(next: Area3D) -> void:
	if _current == next:
		return
	_current = next
	target_changed.emit(_current)


func _find_interactable(node: Object) -> Area3D:
	var current: Node = node as Node
	while current != null:
		if current is Area3D and current.has_method("can_interact") and current.has_method("interact") and current.has_method("get_interaction_prompt"):
			return current as Area3D
		current = current.get_parent()
	return null
