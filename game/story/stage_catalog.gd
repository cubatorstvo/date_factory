class_name StageCatalog
extends Resource

@export var stages: Array[StageDefinition] = []


func get_stage(stage: int) -> StageDefinition:
	for definition in stages:
		if definition != null and definition.stage == stage:
			return definition
	return null


func get_all_stages() -> Array[StageDefinition]:
	var result: Array[StageDefinition] = []
	for definition in stages:
		if definition != null:
			result.append(definition)
	return result


static func create_seed() -> StageCatalog:
	var catalog := StageCatalog.new()
	var empty_effects: Array[StageEnterEffect] = []
	catalog.stages.append(_make_stage(1, "Stage 1", _make_girl_requirement(GirlCatalog.ID_ACTRESS, 10), empty_effects))
	catalog.stages.append(_make_stage(2, "Stage 2", _make_girl_requirement(GirlCatalog.ID_MINE_BOSS, 10), empty_effects))
	catalog.stages.append(_make_stage(3, "Stage 3", _make_girl_requirement(GirlCatalog.ID_MAGAZINE_EDITOR, 10), empty_effects))
	catalog.stages.append(_make_stage(4, "Stage 4", _make_girl_requirement(GirlCatalog.ID_SCIENTIST, 10), empty_effects))
	catalog.stages.append(_make_stage(5, "Stage 5", _make_girl_requirement(GirlCatalog.ID_PRESIDENT, 10), empty_effects))
	catalog.stages.append(_make_stage(6, "Stage 6", null, empty_effects))
	return catalog


static func _make_girl_requirement(girl_id: StringName, target: int) -> GirlRelationshipRequirement:
	var requirement: GirlRelationshipRequirement = GirlRelationshipRequirement.new()
	requirement.girl_id = girl_id
	requirement.target_relationship = target
	return requirement


static func _make_stage(
	stage: int,
	display_name: String,
	completion_requirement: StageRequirement,
	on_enter_effects: Array[StageEnterEffect]
) -> StageDefinition:
	var definition: StageDefinition = StageDefinition.new()
	definition.stage = stage
	definition.display_name = display_name
	definition.completion_requirement = completion_requirement
	definition.on_enter_effects = on_enter_effects.duplicate()
	return definition
