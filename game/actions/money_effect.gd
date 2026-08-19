class_name MoneyEffect
extends ActionEffect

@export var amount: int = 0


func apply() -> void:
	var gs: Variant = _game_state()
	if gs == null:
		return
	gs.player.money += amount


func get_description() -> String:
	if amount >= 0:
		return "+%d money" % amount
	return "%d money" % amount


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
