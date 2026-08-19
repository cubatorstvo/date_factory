class_name DateLocationAvailableRequirement
extends ActionRequirement

@export var girl_id: StringName = &""
@export var date_location_id: StringName = &""


func is_met() -> bool:
	var dating: Variant = _dating_service()
	if dating == null:
		return false
	return bool(dating.is_date_location_available(girl_id, date_location_id))


func get_failure_reason() -> String:
	return "Это место сейчас недоступно"


func _dating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("DatingService")
	if not is_instance_valid(node):
		return null
	return node
