class_name AutomationUpgradeNotPurchasedRequirement
extends ActionRequirement

@export var upgrade_id: StringName = &""


func is_met() -> bool:
	var automation: Variant = _automation_service()
	if automation == null:
		return false
	return not bool(automation.is_upgrade_purchased(upgrade_id))


func get_failure_reason() -> String:
	return "Уже куплено"


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
