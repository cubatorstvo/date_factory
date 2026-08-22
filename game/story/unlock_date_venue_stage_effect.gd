class_name UnlockDateVenueStageEffect
extends StageEnterEffect

@export var date_venue_id: StringName = &""


func apply() -> void:
	var world: Variant = _world_service()
	if world == null:
		return
	world.unlock_date_venue(date_venue_id)


func _world_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("WorldService")
	if not is_instance_valid(node):
		return null
	return node
