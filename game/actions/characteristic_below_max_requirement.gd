class_name CharacteristicBelowMaxRequirement
extends ActionRequirement

@export var characteristic_id: StringName = &""


func is_met() -> bool:
	var characteristics: Variant = _characteristic_service()
	if characteristics == null:
		return false
	return bool(characteristics.can_upgrade(characteristic_id))


func get_failure_reason() -> String:
	return "Характеристика уже максимальная"


func _characteristic_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CharacteristicService")
	if not is_instance_valid(node):
		return null
	return node
