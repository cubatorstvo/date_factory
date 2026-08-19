class_name PurchaseEffect
extends ActionEffect

@export var purchase_id: StringName = &""


func apply() -> void:
	var gs: Variant = _game_state()
	if gs == null:
		return
	var progression: ProgressionState = gs.progression as ProgressionState
	if progression == null:
		return
	progression.add(purchase_id)


func get_description() -> String:
	return "Purchased %s" % String(purchase_id)


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
