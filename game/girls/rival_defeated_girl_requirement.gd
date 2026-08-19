class_name RivalDefeatedGirlRequirement
extends GirlAccessRequirement

@export var rival_id: StringName = &""


func is_met(_girl_id: StringName) -> bool:
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return false
	return bool(rivals.is_defeated(rival_id))


func get_description(_girl_id: StringName) -> String:
	return "Победить %s" % _rival_display_name()


func get_progress_text(_girl_id: StringName) -> String:
	if is_met(_girl_id):
		return "Выполнено"
	return "Не выполнено"


func _rival_display_name() -> String:
	var rivals: Variant = _rivals_service()
	if rivals != null:
		var definition: RivalDefinition = rivals.get_definition(rival_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return String(rival_id)


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node
