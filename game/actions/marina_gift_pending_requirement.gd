class_name MarinaGiftPendingRequirement
extends ActionRequirement


func is_met() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return bool(girls.is_marina_free_outfit_pending())


func get_failure_reason() -> String:
	return "Подарок Марины уже использован."


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
