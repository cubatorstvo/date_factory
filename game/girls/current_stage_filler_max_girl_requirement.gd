class_name CurrentStageFillerMaxGirlRequirement
extends GirlAccessRequirement

@export var story_stage: int = 1
@export var required_count: int = 2


func is_met(girl_id: StringName) -> bool:
	return _count_filler_max(girl_id) >= _required_count(girl_id)


func get_description(_girl_id: StringName) -> String:
	return "Девушки этапа"


func get_progress_text(girl_id: StringName) -> String:
	return "%d / %d" % [_count_filler_max(girl_id), _required_count(girl_id)]


func _count_filler_max(girl_id: StringName) -> int:
	var stages: Variant = _stage_service()
	if stages == null:
		return 0
	return int(stages.count_stage_filler_max(_story_stage(girl_id)))


func _story_stage(girl_id: StringName) -> int:
	var definition: StageDefinition = _story_girl_definition(girl_id)
	if definition != null:
		return definition.stage
	return story_stage


func _required_count(girl_id: StringName) -> int:
	var definition: StageDefinition = _story_girl_definition(girl_id)
	if definition != null:
		return definition.required_filler_max_count
	return required_count


func _story_girl_definition(girl_id: StringName) -> StageDefinition:
	var catalog: StageCatalog = _stage_catalog()
	if catalog == null:
		return null
	var definition: StageDefinition = catalog.find_stage_for_girl(girl_id)
	if definition == null or definition.story_girl_id != girl_id:
		return null
	return definition


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
