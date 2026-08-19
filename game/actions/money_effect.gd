class_name MoneyEffect
extends ActionEffect

@export var amount: int = 0


func apply() -> void:
	var economy: Variant = _economy_service()
	if economy == null:
		return
	if amount > 0:
		economy.add_money(amount)
	elif amount < 0:
		economy.spend_money(-amount)


func get_description() -> String:
	if amount >= 0:
		return "+%d money" % amount
	return "%d money" % amount


func _economy_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EconomyService")
	if not is_instance_valid(node):
		return null
	return node
