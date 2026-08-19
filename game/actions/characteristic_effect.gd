class_name CharacteristicEffect
extends ActionEffect

@export var characteristic_id: StringName = &""
@export var amount: int = 0


func apply() -> void:
	var service: Variant = _characteristic_service()
	if service == null:
		return
	service.add_value(characteristic_id, amount)


func get_description() -> String:
	var name_text: String = CharacteristicIds.display_name(characteristic_id)
	if amount >= 0:
		return "%s +%d" % [name_text, amount]
	return "%s %d" % [name_text, amount]


func _characteristic_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CharacteristicService")
	if not is_instance_valid(node):
		return null
	return node
