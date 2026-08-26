class_name CareerCapitalRequirement
extends ActionRequirement


func is_met() -> bool:
	var required: int = WorkService.get_next_career_capital_requirement()
	if required <= 0:
		return false
	var player: PlayerState = _player()
	if player == null:
		return false
	return player.capital >= required


func get_failure_reason() -> String:
	return "Недостаточно Capital."


func _player() -> PlayerState:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node.player as PlayerState
