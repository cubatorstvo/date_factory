class_name MinStoryStageGirlRequirement
extends GirlAccessRequirement

@export var minimum_story_stage: int = 1


func is_met(girl_id: StringName) -> bool:
	var stages: Variant = _stage_service()
	if stages == null:
		return false
	return int(stages.get_current_stage()) >= _required_story_stage(girl_id)


func get_description(_girl_id: StringName) -> String:
	return "Этап сюжета"


func get_progress_text(girl_id: StringName) -> String:
	var current_stage: int = 0
	var stages: Variant = _stage_service()
	if stages != null:
		current_stage = int(stages.get_current_stage())
	return "Stage %d / %d" % [current_stage, _required_story_stage(girl_id)]


func _required_story_stage(girl_id: StringName) -> int:
	var catalog: StageCatalog = _stage_catalog()
	if catalog != null:
		var definition: StageDefinition = catalog.find_stage_for_girl(girl_id)
		if definition != null:
			return definition.stage
	return minimum_story_stage


func _stage_catalog() -> StageCatalog:
	var stages: Variant = _stage_service()
	if stages == null:
		return null
	return stages.get_catalog() as StageCatalog


func _stage_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("StageService")
	if not is_instance_valid(node):
		return null
	return node
