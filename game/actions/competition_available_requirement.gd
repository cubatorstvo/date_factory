class_name CompetitionAvailableRequirement
extends ActionRequirement

@export var competition_id: StringName = &""


func is_met() -> bool:
	var competitions: Variant = _competition_service()
	if competitions == null:
		return false
	return bool(competitions.can_start_competition(competition_id))


func get_failure_reason() -> String:
	var competitions: Variant = _competition_service()
	if competitions == null:
		return "Соревнование не найдено"
	return str(competitions.get_failure_reason(competition_id))


func _competition_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CompetitionService")
	if not is_instance_valid(node):
		return null
	return node
