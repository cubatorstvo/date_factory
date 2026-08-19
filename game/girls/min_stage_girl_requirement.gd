class_name MinStageGirlRequirement
extends GirlAccessRequirement

@export var minimum_stage: int = 1


func is_met(_girl_id: StringName) -> bool:
	var stage: Variant = _stage_service()
	if stage == null:
		return false
	return int(stage.get_current_stage()) >= minimum_stage


func get_description(_girl_id: StringName) -> String:
	return "Этап игры"


func get_progress_text(_girl_id: StringName) -> String:
	var current_stage: int = 0
	var stage: Variant = _stage_service()
	if stage != null:
		current_stage = int(stage.get_current_stage())
	return "Stage %d / %d" % [current_stage, minimum_stage]


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node
