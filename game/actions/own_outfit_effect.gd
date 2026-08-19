class_name OwnOutfitEffect
extends ActionEffect

@export var outfit_id: StringName = &""


func apply() -> void:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return
	equipment.add_owned_outfit(outfit_id)


func get_description() -> String:
	return "Одежда куплена: %s" % String(outfit_id)


func _equipment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EquipmentService")
	if not is_instance_valid(node):
		return null
	return node
