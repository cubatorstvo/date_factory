class_name UnlockAutomationStageEffect
extends StageEnterEffect


func apply() -> void:
	var automation: Variant = _automation_service()
	if automation == null:
		return
	automation.unlock()


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
