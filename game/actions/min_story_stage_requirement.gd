class_name MinStoryStageRequirement
extends ActionRequirement

@export var min_stage: int = 1


func is_met() -> bool:
	var stages: Variant = _stage_service()
	if stages == null:
		return false
	return int(stages.get_current_stage()) >= min_stage


func get_failure_reason() -> String:
	return "Доступно с главы %d" % min_stage


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node
