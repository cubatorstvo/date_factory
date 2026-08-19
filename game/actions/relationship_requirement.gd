class_name RelationshipRequirement
extends ActionRequirement

@export var girl_id: StringName = &""
@export var minimum_relationship: int = 0


func is_met() -> bool:
	var girls: Variant = _girls_service()
	if girls == null:
		return false
	return int(girls.get_relationship(girl_id)) >= minimum_relationship


func get_failure_reason() -> String:
	return "Недостаточный уровень отношений"


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
