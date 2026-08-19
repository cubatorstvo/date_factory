class_name RivalLocationRequirement
extends ActionRequirement

@export var rival_id: StringName = &""


func is_met() -> bool:
	var rivals: Variant = _rivals_service()
	var world: Variant = _world_service()
	if rivals == null or world == null:
		return false
	var definition: RivalDefinition = rivals.get_definition(rival_id)
	if definition == null:
		return false
	return definition.location_id == world.get_current_location_id()


func get_failure_reason() -> String:
	return "Соперник находится в другой локации"


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node


func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node
