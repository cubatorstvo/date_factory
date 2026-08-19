class_name GirlDiscoveredRequirement
extends ActionRequirement

@export var girl_id: StringName = &""


func is_met() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return bool(girls.is_discovered(girl_id))


func get_failure_reason() -> String:
	return "Вы ещё не знакомы"


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
