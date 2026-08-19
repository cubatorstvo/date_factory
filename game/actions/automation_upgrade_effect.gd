class_name AutomationUpgradeEffect
extends ActionEffect

@export var upgrade_id: StringName = &""


func apply() -> void:
	var automation: Variant = _automation_service()
	if automation == null:
		return
	automation.apply_upgrade(upgrade_id)


func get_description() -> String:
	return "Automation upgrade: %s" % String(upgrade_id)


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
