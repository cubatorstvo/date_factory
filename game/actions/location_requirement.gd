class_name LocationRequirement
extends ActionRequirement

@export var required_location_id: StringName = &""


func is_met() -> bool:
	var world: Variant = _world_service()
	if world == null:
		return false
	return world.get_current_location_id() == required_location_id


func get_failure_reason() -> String:
	return "Действие недоступно в этой локации"


func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node
