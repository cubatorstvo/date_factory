class_name FinalSignalInteractable
extends Interactable
## Entry point for MODULE 21 final date: answer the alien signal.


func _ready() -> void:
	prompt_action = "Ответить на внеземной сигнал"
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_refresh):
			gs.connect("stage_changed", _on_refresh)
		if gs.has_signal("girl_conquered") and not gs.is_connected("girl_conquered", _on_girl_conquered):
			gs.connect("girl_conquered", _on_girl_conquered)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_refresh):
			gs.connect("state_reset", _on_refresh)
	_refresh_prompt()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	var controller: FinalDateController = _ensure_controller()
	if controller == null:
		return false
	return controller.can_start_final_date()


func get_interaction_prompt(_player: Node) -> String:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)):
		return "Финал завершён"
	var controller: FinalDateController = _ensure_controller()
	if controller != null and controller.is_attempt_active():
		return ""
	if controller == null or not controller.can_start_final_date():
		return ""
	return "[E] Ответить на внеземной сигнал"


func _on_interact(player: Node) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)):
		return
	var controller: FinalDateController = _ensure_controller()
	if controller == null:
		return
	controller.start_final_date(player)


func _ensure_controller() -> FinalDateController:
	var host: Node = _find_location_root()
	if host == null:
		host = self
	var existing: Node = host.find_child("FinalDateController", true, false)
	if existing is FinalDateController:
		return existing as FinalDateController
	if existing != null and existing.has_method("start_final_date"):
		return existing as FinalDateController
	var controller := FinalDateController.new()
	controller.name = "FinalDateController"
	host.add_child(controller)
	return controller


func _find_location_root() -> Node:
	var n: Node = self
	while n != null:
		if n is WorldLocation:
			return n
		if String(n.name) == "final_location":
			return n
		n = n.get_parent()
	var tree: SceneTree = get_tree()
	if tree != null:
		return tree.current_scene
	return null


func _on_girl_conquered(girl_id: StringName) -> void:
	if girl_id == FinalDateTypes.GIRL_ID:
		_refresh_prompt()


func _on_refresh(_a: Variant = null, _b: Variant = null) -> void:
	_refresh_prompt()


func _refresh_prompt() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_girl_conquered", FinalDateTypes.GIRL_ID)):
		prompt_action = "Финал завершён"
	else:
		prompt_action = "Ответить на внеземной сигнал"


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("Collision") as CollisionShape3D
	if shape_node == null:
		shape_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.2, 1.4)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.1, 0.0)
	add_child(shape_node)
