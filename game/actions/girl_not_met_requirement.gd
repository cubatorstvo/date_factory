class_name GirlNotMetRequirement
extends ActionRequirement

@export var girl_id: StringName = &""


func is_met() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return girls.is_discovered(girl_id) == false


func get_failure_reason() -> String:
	return "Вы уже знакомы"


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
