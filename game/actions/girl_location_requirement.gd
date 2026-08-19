class_name GirlLocationRequirement
extends ActionRequirement

@export var girl_id: StringName = &""


func is_met() -> bool:
	var girls: Variant = _girls_service()
	var world: Variant = _world_service()
	if girls == null or world == null:
		return false
	var definition: GirlDefinition = girls.get_definition(girl_id)
	if definition == null:
		return false
	return definition.location_id == world.get_current_location_id()


func get_failure_reason() -> String:
	return "Девушка находится в другой локации"


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
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
