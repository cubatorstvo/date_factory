class_name SetCityStageStageEffect
extends StageEnterEffect

@export var city_stage: int = 1


func apply() -> void:
	var world: Variant = _world_service()
	if world == null:
		return
	world.set_city_stage(city_stage)


func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node
