class_name CurrentStageFillerMaxGirlRequirement
extends GirlAccessRequirement

@export var story_stage: int = 1
@export var required_count: int = 2


func is_met(_girl_id: StringName) -> bool:
	return _count_filler_max() >= required_count


func get_description(_girl_id: StringName) -> String:
	return "Девушки этапа"


func get_progress_text(_girl_id: StringName) -> String:
	return "%d / %d" % [_count_filler_max(), required_count]


func _count_filler_max() -> int:
	var stages: Variant = _stage_service()
	if stages == null:
		return 0
	return int(stages.count_stage_filler_max(story_stage))


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node
