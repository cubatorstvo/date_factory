class_name GlobalExpansionEventInteractable
extends Interactable
## Optional one-time Stage6 Reach event (MODULE 20).
## Scene worker places three instances in production_area.

@export var event_kind: LateGameTypes.OptionalEvent = LateGameTypes.OptionalEvent.CUSTOMS

var _done_local: bool = false


func _ready() -> void:
	prompt_action = LateGameTypes.event_prompt(int(event_kind))
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("world_reach_changed") and not gs.is_connected("world_reach_changed", _on_state_refresh):
			gs.connect("world_reach_changed", _on_state_refresh)
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_reset):
			gs.connect("state_reset", _on_reset)
	_refresh_prompt()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge == null or not lge.has_method("is_optional_event_available"):
		return false
	return bool(lge.call("is_optional_event_available", int(event_kind)))


func get_interaction_prompt(_player: Node) -> String:
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge != null and lge.has_method("is_optional_event_completed"):
		if bool(lge.call("is_optional_event_completed", int(event_kind))):
			return ""
	if lge == null or not bool(lge.call("is_optional_event_available", int(event_kind))):
		return ""
	return "[E] %s" % LateGameTypes.event_prompt(int(event_kind))


func _on_interact(player: Node) -> void:
	if not can_interact(player):
		return
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge == null or not lge.has_method("complete_optional_event"):
		return
	if bool(lge.call("complete_optional_event", int(event_kind))):
		_done_local = true
		_refresh_prompt()


func _on_state_refresh(_a: Variant = null, _b: Variant = null) -> void:
	_refresh_prompt()


func _on_stage_changed(_a: Variant = null, _b: Variant = null) -> void:
	_refresh_prompt()


func _on_reset() -> void:
	_done_local = false
	_refresh_prompt()


func _refresh_prompt() -> void:
	prompt_action = LateGameTypes.event_prompt(int(event_kind))


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.0, 1.2)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape_node)
