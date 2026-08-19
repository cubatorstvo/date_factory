class_name ApartmentUpgradeEffect
extends ActionEffect

@export var upgrade_id: StringName = &""
@export var target_level: int = 1


func apply() -> void:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return
	apartment.apply_upgrade(upgrade_id, target_level)


func get_description() -> String:
	return "Квартира: уровень %d" % target_level


func _apartment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ApartmentService")
	if not is_instance_valid(node):
		return null
	return node
