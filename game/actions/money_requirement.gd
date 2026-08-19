class_name MoneyRequirement
extends ActionRequirement

@export var required_money: int = 0


func is_met() -> bool:
	var gs: Variant = _game_state()
	if gs == null:
		return false
	return gs.player.money >= required_money


func get_failure_reason() -> String:
	return "Недостаточно денег"


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
