class_name GirlRelationshipRequirement
extends StageRequirement

@export var girl_id: StringName = &""
@export var target_relationship: int = 0


func is_met() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return int(girls.get_relationship(girl_id)) >= target_relationship


func get_current_value() -> int:
	var girls: Variant = _girls_service()
	if girls == null:
		return 0
	return int(girls.get_relationship(girl_id))


func get_target_value() -> int:
	return target_relationship


func get_description() -> String:
	var girls: Variant = _girls_service()
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id) as GirlDefinition
		if definition != null:
			return "Отношения с %s" % definition.display_name
	return "Отношения с %s" % String(girl_id)


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
