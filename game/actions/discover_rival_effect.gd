class_name DiscoverRivalEffect
extends ActionEffect

@export var rival_id: StringName = &""


func apply() -> void:
	var rivals: Variant = _rivals_service()
	if rivals == null:
		return
	rivals.discover_rival(rival_id)


func get_description() -> String:
	var display_name: String = String(rival_id)
	var rivals: Variant = _rivals_service()
	if rivals != null:
		var definition: RivalDefinition = rivals.get_definition(rival_id)
		if definition != null:
			display_name = definition.display_name
	return "Вы встретили %s." % display_name


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node
