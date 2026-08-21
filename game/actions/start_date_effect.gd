class_name StartDateEffect
extends ActionEffect

@export var girl_id: StringName = &""
@export var date_venue_id: StringName = &""
@export var outfit_id: StringName = &""
@export var backup_outfit_id: StringName = &""
@export var express_styling: bool = false
@export var urgent_taxi: bool = false


func apply() -> void:
	var dating: Variant = _dating_service()
	if dating == null:
		return
	dating.start_date(girl_id, date_venue_id, outfit_id, {
		"backup_outfit_id": backup_outfit_id,
		"express_styling": express_styling,
		"urgent_taxi": urgent_taxi,
	})


func get_description() -> String:
	var display_name: String = String(girl_id)
	var girls: Variant = _girls_service()
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null:
			display_name = definition.display_name
	return "Свидание с %s началось." % display_name


func _dating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("DatingService")
	if not is_instance_valid(node):
		return null
	return node


func _girls_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GirlsService")
	if not is_instance_valid(node):
		return null
	return node
