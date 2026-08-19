class_name FactoryExpansionEffect
extends ActionEffect

@export var target_scope: StringName = &"country"


func apply() -> void:
	var automation: Variant = _automation_service()
	if automation == null:
		return
	automation.apply_expansion(target_scope)


func get_description() -> String:
	return "Factory expansion: %s" % String(target_scope)


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
