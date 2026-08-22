class_name DailyActivityAvailableRequirement
extends ActionRequirement

@export var activity_key: String = ""
@export var daily_limit: int = 1
@export var failure_reason: String = "Сегодня уже использовано."


func is_met() -> bool:
	var daily: Variant = _daily()
	if daily == null:
		return false
	return bool(daily.is_available(activity_key, daily_limit))


func get_failure_reason() -> String:
	return failure_reason


func _daily() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DailyActivityService")
