class_name MoneyRequirement
extends ActionRequirement

@export var required_money: int = 0


func is_met() -> bool:
	var economy: Variant = _economy_service()
	if economy == null:
		return false
	return bool(economy.can_afford(required_money))


func get_failure_reason() -> String:
	return "Недостаточно денег"


func _economy_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EconomyService")
	if not is_instance_valid(node):
		return null
	return node
