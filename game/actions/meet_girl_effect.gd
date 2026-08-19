class_name MeetGirlEffect
extends ActionEffect

@export var girl_id: StringName = &""


func apply() -> void:
	var girls: Variant = _girls_service()
	if girls == null:
		return
	girls.discover_girl(girl_id)
	girls.give_contact(girl_id)


func get_description() -> String:
	var display_name: String = String(girl_id)
	var girls: Variant = _girls_service()
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null:
			display_name = definition.display_name
	return "Вы познакомились с %s.\nПолучен контакт." % display_name


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
