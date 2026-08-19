class_name DateAvailableRequirement
extends ActionRequirement

@export var girl_id: StringName = &""


func is_met() -> bool:
	var dating: Variant = _dating_service()
	if dating == null:
		return false
	return bool(dating.can_start_date(girl_id))


func get_failure_reason() -> String:
	var dating: Variant = _dating_service()
	if dating == null:
		return "Свидание уже идёт"
	return str(dating.get_start_date_failure_reason(girl_id))


func _dating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("DatingService")
	if not is_instance_valid(node):
		return null
	return node
