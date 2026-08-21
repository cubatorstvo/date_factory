class_name ClearMarinaGiftEffect
extends ActionEffect


func apply() -> void:
	var girls: Variant = _girls_service()
	if girls == null:
		return
	girls.clear_marina_free_outfit_pending()


func get_description() -> String:
	return "Подарок Марины использован."


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
