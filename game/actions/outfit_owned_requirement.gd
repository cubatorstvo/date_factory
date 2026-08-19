class_name OutfitOwnedRequirement
extends ActionRequirement

@export var outfit_id: StringName = &""


func is_met() -> bool:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return false
	return bool(equipment.owns_outfit(outfit_id))


func get_failure_reason() -> String:
	return "Эта одежда ещё не куплена"


func _equipment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EquipmentService")
	if not is_instance_valid(node):
		return null
	return node
