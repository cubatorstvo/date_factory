class_name RecordOvertimeDayEffect
extends ActionEffect


func apply() -> void:
	var daily: Variant = _daily()
	if daily == null:
		return
	daily.register_usage(daily.KEY_WORK, 1)


func get_description() -> String:
	return "Подработка засчитана на сегодня"


func _daily() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DailyActivityService")
