class_name FactoryExpansionRequirement
extends ActionRequirement

@export var from_scope: StringName = &"city"


func is_met() -> bool:
	var automation: Variant = _automation_service()
	if automation == null:
		return false
	if StringName(automation.get_current_expansion_scope()) != from_scope:
		return false
	return bool(automation.is_current_expansion_complete()) and StringName(automation.get_next_expansion_scope()) != &""


func get_failure_reason() -> String:
	var automation: Variant = _automation_service()
	if automation == null:
		return "Фабрика недоступна"
	if StringName(automation.get_current_expansion_scope()) != from_scope:
		return "Неверный масштаб фабрики"
	if not bool(automation.is_current_expansion_complete()):
		return "Охват текущего масштаба ещё не 100%"
	if StringName(automation.get_next_expansion_scope()) == &"":
		return "Фабрика уже на максимальном масштабе"
	return ""


func _automation_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("AutomationService")
	if not is_instance_valid(node):
		return null
	return node
