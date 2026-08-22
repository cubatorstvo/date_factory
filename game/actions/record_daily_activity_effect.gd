class_name RecordDailyActivityEffect
extends ActionEffect

@export var activity_key: String = ""
@export var amount: int = 1


func apply() -> void:
	var daily: Variant = _daily()
	if daily == null:
		return
	daily.register_usage(activity_key, amount)


func get_description() -> String:
	return "Дневное использование засчитано"


func _daily() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DailyActivityService")
