class_name RivalNotDefeatedRequirement
extends ActionRequirement

@export var rival_id: StringName = &""


func is_met() -> bool:
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return false
	return rivals.is_defeated(rival_id) == false


func get_failure_reason() -> String:
	return "Этот соперник уже побеждён"


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node
