class_name ApartmentLocalObjectOwnedRequirement
extends ActionRequirement

@export var object_id: StringName = &""


func is_met() -> bool:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return false
	var granted: Array = apartment.get_granted_local_object_ids()
	return granted.has(object_id)


func get_failure_reason() -> String:
	return "Сначала купите этот предмет"


func _apartment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ApartmentService")
	if not is_instance_valid(node):
		return null
	return node
