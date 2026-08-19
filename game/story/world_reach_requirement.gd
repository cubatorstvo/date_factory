class_name WorldReachRequirement
extends StageRequirement


func is_met() -> bool:
	var automation: Variant = _automation_service()
	if automation == null:
		return false
	return StringName(automation.get_current_expansion_scope()) == AutomationService.SCOPE_WORLD and bool(automation.is_current_expansion_complete())


func get_current_value() -> int:
	var automation: Variant = _automation_service()
	if automation == null:
		return 0
	if StringName(automation.get_current_expansion_scope()) != AutomationService.SCOPE_WORLD:
		return 0
	return int(floor(float(automation.get_expansion_progress())))


func get_target_value() -> int:
	return int(AutomationService.WORLD_REACH_REQUIRED)


func get_description() -> String:
	return "Мировой охват"


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
