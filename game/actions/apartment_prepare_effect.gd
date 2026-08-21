class_name ApartmentPrepareEffect
extends ActionEffect


func apply() -> void:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return
	apartment.set_prepared(true)


func get_description() -> String:
	return "Квартира подготовлена."



func _apartment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("ApartmentService")
	if not is_instance_valid(node):
		return null
	return node
