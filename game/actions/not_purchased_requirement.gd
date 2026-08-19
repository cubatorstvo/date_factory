class_name NotPurchasedRequirement
extends ActionRequirement

@export var purchase_id: StringName = &""


func is_met() -> bool:
	var gs: Variant = _game_state()
	if gs == null:
		return false
	var progression: ProgressionState = gs.progression as ProgressionState
	if progression == null:
		return false
	return not progression.has(purchase_id)


func get_failure_reason() -> String:
	return "Уже куплено"


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
